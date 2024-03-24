# CuNNy corrector/trainer
# Copyright (c) 2024 cunnyplapper
# SPDX-License-Identifier: 	LGPL-3.0-or-later
import os
import sys
import argparse
import torch
import torch.nn as nn
import torch.nn.functional as F
import itertools
import pickle
import tqdm
from torch.utils.tensorboard import SummaryWriter
from collections import OrderedDict
from multiprocessing import Pool
from torchvision import transforms
from torcheval.metrics.functional import peak_signal_noise_ratio as psnr
from PIL import Image

# epochs
E = 500
# batch size
B = 64
# learning rate
LR = 0.0001
# max learning rate with OneCycleLR
MAX_LR = 0.001
# weight decay
W = 0.001

def split(l, v):
    return [list(g) for k, g in itertools.groupby(l, lambda x: x != v) if k]

argvs = split(sys.argv[1:], '++')
gargv, argv = argvs if len(argvs) == 2 else ([], *argvs)

parser = argparse.ArgumentParser()
parser.add_argument('data', type=str)
parser.add_argument('-R', '--rgb', action='store_true')
gargs = parser.parse_args(gargv)

RGB = gargs.rgb

parser = argparse.ArgumentParser()
parser.add_argument('N', type=int)
parser.add_argument('D', type=int)
parser.add_argument('-s', '--suffix', type=str, default=None)
parser.add_argument('-e', '--epochs', type=int, default=E)
parser.add_argument('-b', '--batch', type=int, default=B)
parser.add_argument('-l', '--lr', type=float, default=LR)
parser.add_argument('-L', '--max-lr', type=float, default=MAX_LR)
parser.add_argument('-w', '--weight-decay', type=float, default=W)
parser.add_argument('-C', '--crelu', action='store_true')
parser.add_argument('-2', '--l2', action='store_true')
parser.add_argument('-q', '--quant', action='store_true')
allargs = [parser.parse_args(args) for args in split(argv, '+')]

hascuda = torch.cuda.is_available()
torch.multiprocessing.set_sharing_strategy('file_system')
dev = torch.device('cuda' if hascuda else 'cpu')
if hascuda:
    torch.backends.cuda.matmul.allow_tf32 = True
    torch.backends.cuda.matmul.allow_bf16_reduced_precision_reduction = True
    torch.backends.cudnn.allow_tf32 = True
    torch.backends.cudnn.benchmark = True

def load(dir, file, variants):
    fn = os.path.join(dir, file)
    if not os.path.exists(fn):
        fn = fn.replace('png', 'jpg')
    out = []
    with Image.open(fn) as img:
        for v in variants:
            out += [img.convert(v)]
    return out

def loadall(pool, dir, files, transform, variants):
    vs = ((dir, file, variants) for file in files)
    return [list(map(lambda x: transform(x).to(dev), imgs))
            for imgs in list(pool.starmap(load, vs))]

class Dataset(torch.utils.data.Dataset):
    def __init__(self, dirx, dirz, dirtrue, transform):
        self.files = os.listdir(dirtrue)
        with Pool() as pool:
            if RGB:
                self.x, xl = zip(*loadall(
                    pool, dirx, self.files, transform, ['RGB', 'L']))
            else:
                self.x = [x[0] for x in loadall(
                    pool, dirx, self.files, transform, ['L'])]
                xl = self.x
            self.y = [F.interpolate(
                x.unsqueeze(dim=0), scale_factor=2, mode='bilinear',
                align_corners=False).squeeze(dim=0) for x in xl]
            self.z = [x[0] for x in loadall(
                pool, dirz, self.files, transform, ['L'])] if dirz else None
            self.true = [x[0] for x in loadall(
                pool, dirtrue, self.files, transform, ['L'])]

    def __len__(self):
        return len(self.files)

    def __getitem__(self, idx):
        return self.x[idx], self.y[idx], self.z[idx] if self.z else \
               torch.empty(0), self.true[idx], self.files[idx]

FSR = f'{gargs.data}/easu'
rcas = False
if not os.path.isdir(FSR):
    FSR = next(
        (f'{gargs.data}/{f}' for f in os.listdir(f'{gargs.data}')
         if f.startswith('rcas-')), None)
    if FSR:
        rcas = True

transform = transforms.Compose([transforms.ToTensor()])
dataset = Dataset(f'{gargs.data}/64', FSR, f'{gargs.data}/128', transform)

for args in allargs:
    # internal convolutions
    N  = args.N
    # feature layers/depth
    D = args.D
    E = args.epochs
    B = args.batch
    LR = args.lr
    MAX_LR = args.max_lr
    CRELU = args.crelu
    W = args.weight_decay
    QUANT = args.quant

    dataloader = torch.utils.data.DataLoader(dataset, batch_size=B, shuffle=True)

    def act(x):
        if QUANT:
            a = 0.01
            relu = lambda x: torch.clamp(x, 0., 1.0) + a * F.relu(x - 1.0)
        else:
            relu = F.relu
        if CRELU:
            # negated seems to train smoother
            return torch.cat((relu(x), -relu(-x)), dim=1)
        else:
            return relu(x)

    class Net(nn.Module):
        def __init__(self):
            super(Net, self).__init__()
            M = 2 if CRELU else 1
            if RGB:
                self.fancyluma = nn.Conv2d(3, 1, 1, padding=1)
            self.cin = nn.Conv2d(1, D, 3, padding='same')
            self.conv = nn.ModuleList()
            for i in range(N):
                c = nn.Conv2d(M * D, D, 3, padding='same')
                if CRELU:
                    nn.init.xavier_normal_(
                        c.weight, gain=nn.init.calculate_gain('linear'))
                else:
                    nn.init.kaiming_normal_(
                        c.weight, mode='fan_out', nonlinearity='relu')
                nn.init.zeros_(c.bias)
                self.conv.append(c)
            self.cout = nn.Conv2d(M * D, 4, 3, padding='same')
            if CRELU:
                nn.init.xavier_normal_(
                   self.cin.weight, gain=nn.init.calculate_gain('linear'))
            else:
                nn.init.kaiming_normal_(
                   self.cin.weight, mode='fan_out', nonlinearity='relu')
            nn.init.xavier_normal_(
               self.cout.weight, gain=nn.init.calculate_gain('tanh'))
            nn.init.zeros_(self.cin.bias)
            nn.init.zeros_(self.cout.bias)

        def forward(self, x, y, z):
            if RGB:
                x = self.fancyluma(x)
            x = act(self.cin(x))
            for conv in self.conv:
                x = act(conv(x))
            x = F.tanh(self.cout(x))
            x = F.pixel_shuffle(x, 2)
            if FSR:
                x = torch.add(x, z)
            else:
                x = torch.add(x, y)
            return torch.clamp(x, 0., 1.)

    model = Net()
    if hascuda:
        model = model.to(dev, memory_format=torch.channels_last)
    loss_fn = nn.MSELoss() if args.l2 else nn.L1Loss()
    opt = torch.optim.AdamW(
        model.parameters(), lr=LR, weight_decay=args.weight_decay)

    fn = ''
    suf = (
        ('RCAS-' if rcas else 'BILINEAR-' if FSR is None else '') +
        ('RGB-' if RGB else '') +
        (args.suffix + '-' if args.suffix else '')
    )
    version = f'{N}x{D}{"C" if CRELU else ""}-{suf}'

    i = 0
    while os.path.exists((fn := f'models/{version}{i}.pickle')):
        i += 1

    def fwd(model, x, y, z, true, train):
        opt.zero_grad(True)
        pred = model(x, y, z)
        loss = loss_fn(pred, true)
        if train:
            loss.backward()
        return pred, loss

    def run_epoch(model, dev, epoch, fwd_fn, sched, writer, train):
        nloss = 0
        runloss = 0.
        for i, (x, y, z, true, files) in enumerate(dataloader):
            pred, loss = fwd_fn(model, x.to(dev), y.to(dev), z.to(dev),
                                true.to(dev), train)
            if train:
                opt.step()
                sched.step()
            runloss += loss
            nloss += 1
            lasty = y
            lastz = z
        with torch.no_grad():
            avgl = runloss / nloss
            if writer and (epoch % 20 == 0 or epoch == E - 1):
                diff = true[0] - pred[0]
                norm = lambda x: torch.clamp(x / 0.2, 0., 1.)
                diff = torch.cat((norm(-torch.min(diff, torch.tensor(0))),
                                  norm(torch.max(diff, torch.tensor(0))),
                                  torch.zeros_like(diff)))
                imgs = (lasty, lastz, pred, true)
                writer.add_images(
                    'imgs',
                    torch.stack(tuple(x[0].expand(3, -1, -1)
                                      for x in imgs if len(x[0]) > 0) +
                                (diff,)),
                    global_step=epoch)
            if writer:
                writer.add_scalar('L', avgl, epoch + 1)
                psnrv = psnr(pred, true)
                writer.add_scalar('psnr', psnrv, epoch + 1)
        return avgl

    def run(model, dev=dev, *, name, epochs, compile, train):
        if train:
            model = model.train()
        else:
            model = model.eval()
        writer = SummaryWriter(name, flush_secs=1) if name else None
        fwd_fn = torch.compile(fwd, mode=('max-autotune' if hascuda else
                                          'default')) if compile else fwd
        sched = torch.optim.lr_scheduler.OneCycleLR(
            opt, max_lr=MAX_LR, steps_per_epoch=len(dataloader),
            epochs=epochs) if train else None
        def impl():
            epoch = 0
            for i in (t := tqdm.trange(epochs)):
                loss = run_epoch(model, dev, epoch, fwd_fn, sched, writer,
                                 train)
                t.set_description(f'L: {loss:.5f}')
                epoch += 1
        if train:
            impl()
        else:
            with torch.no_grad():
                impl()
        if writer:
            writer.flush()

    writer_name = fn.replace('models/', 'runs/')

    print(f'training {fn}')
    with torch.autocast('cuda' if hascuda else 'cpu', dtype=torch.bfloat16):
        run(model, name=writer_name, epochs=E, compile=True, train=True)

    sd = OrderedDict()

    sd['quant'] = QUANT

    for k, v in model.state_dict().items():
        sd[k] = v.cpu().numpy() if hasattr(v, 'numpy') else v
    if rcas:
        sd['sharpness'] = float(FSR.replace(f'{gargs.data}/rcas-', ''))
    sd['crelu'] = CRELU

    with open(fn, 'wb') as f:
        pickle.dump(sd, f, protocol=pickle.HIGHEST_PROTOCOL)
    with open('test/last.txt', 'w') as f:
        f.write(fn)

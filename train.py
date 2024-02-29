# CuNNy corrector/trainer
# Copyright (c) 2024 cunnyplapper
# SPDX-License-Identifier: LGPL-3.0-only
import os
import sys
import argparse
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.utils
from torchvision import transforms
from torcheval.metrics.functional import peak_signal_noise_ratio as psnr
from PIL import Image

dev = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# epochs
E = 500
# batch size
B = 64
# learning rate
LR = 0.00007
# max learning rate (with OneCycleLR)
MAX_LR = 0.003

parser = argparse.ArgumentParser()
parser.add_argument('N', type=int)
parser.add_argument('D', type=int)
parser.add_argument('-s', '--suffix', type=str, default=None)
parser.add_argument('-e', '--epochs', type=int, default=E)
parser.add_argument('-b', '--batch', type=int, default=B)
parser.add_argument('-l', '--lr', type=float, default=LR)
parser.add_argument('-L', '--max-lr', type=float, default=MAX_LR)
args = parser.parse_args()

# internal convolutions
N  = args.N
# feature layers/depth
D = args.D
E = args.epochs
B = args.batch
LR = args.lr
MAX_LR = args.max_lr

class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.up = nn.Conv2d(1, D, 3, padding='same')
        self.conv = nn.Sequential()
        for i in range(N):
            c = nn.Conv2d(D, D, 3, padding='same')
            nn.init.kaiming_normal_(
                c.weight, mode='fan_out', nonlinearity='relu')
            nn.init.zeros_(c.bias)
            self.conv.append(c)
            self.conv.append(nn.ReLU())
        self.down = nn.Conv2d(D, 4, 3, padding='same')
        nn.init.kaiming_normal_(
            self.up.weight, mode='fan_out', nonlinearity='relu')
        nn.init.xavier_normal_(
           self.down.weight, gain=nn.init.calculate_gain('tanh'))
        nn.init.zeros_(self.up.bias)
        nn.init.zeros_(self.down.bias)

    def forward(self, x, y):
        x = F.relu(self.up(x))
        x = self.conv(x)
        x = F.tanh(self.down(x))
        x = F.pixel_shuffle(x, 2)
        x = torch.add(x, y)
        return torch.clamp(x, 0., 1.)

def load(dir, file, transform):
    fn = os.path.join(dir, file)
    if not os.path.exists(fn):
        fn = fn.replace('png', 'jpg')
    return transform(Image.open(fn).convert('L')).to(dev)

class Dataset(torch.utils.data.Dataset):
    def __init__(self, dirx, diry, dirtrue, transform):
        self.files = os.listdir(dirtrue)
        self.x = [load(dirx, file, transform) for file in self.files]
        if diry:
            self.y = [load(diry, file, transform) for file in self.files]
        else:
            self.y = [F.interpolate(x.unsqueeze(dim=0), scale_factor=2, mode='bilinear',
                                    align_corners=False).squeeze(dim=0) for x in self.x]
        self.true = [load(dirtrue, file, transform) for file in self.files]

    def __len__(self):
        return len(self.files)

    def __getitem__(self, idx):
        return self.x[idx], self.y[idx], self.true[idx], self.files[idx]

transform = transforms.Compose([transforms.ToTensor()])
fsr = 'in/easu'
rcas = False
if not os.path.isdir(fsr):
    folder = next((f for f in os.listdir('in') if f.startswith('rcas-')), None)
    if folder:
        fsr = 'in/' + next(f for f in os.listdir('in') if 'rcas-' in f)
        rcas = True
    else:
        fsr = None
dataset = Dataset('in/64', fsr, 'in/128', transform)
dataloader = torch.utils.data.DataLoader(dataset, batch_size=B, shuffle=True)

model = Net().to(dev)
loss_fn = nn.L1Loss()
opt = torch.optim.AdamW(model.parameters(), lr=LR)
sched = torch.optim.lr_scheduler.OneCycleLR(
    opt, max_lr=MAX_LR, steps_per_epoch=len(dataloader), epochs=E)

idx = 0
nloss = 0
runloss = 0.

@torch.compile
def fwd(x, y):
    return model(x, y)

def train():
    global idx, runloss, nloss
    for i, (x, y, true, files) in enumerate(dataloader):
        opt.zero_grad()
        pred = fwd(x, y)
        loss = loss_fn(pred, true)
        loss.backward()
        opt.step()
        sched.step()
        runloss += loss
        nloss += 1
    with torch.no_grad():
        psnrv = psnr(pred, true)
        print(f'[{idx + 1}/{E}] L: {(runloss / nloss):.5f} '
              f'| psnr: {psnrv:.3f} ')
    nloss = 0
    runloss = 0.
    idx += 1

with torch.autocast(device_type='cuda', dtype=torch.bfloat16):
    for i in range(E):
        train()

i = 0
fn = ''
suf = (('RCAS-' if rcas else 'BILINEAR-' if fsr is None else '')
    + (args.suffix + '-' if args.suffix else ''))
while os.path.exists((fn := f'models/{N}x{D}-{suf}{i}.pt')):
    i += 1
sd = model.state_dict()
if rcas:
    sd['sharpness'] = float(fsr.replace('in/rcas-', ''))
torch.save(sd, fn)
print(f'saved to {fn}')
with open('test/last.txt', 'w') as f:
    f.write(fn)

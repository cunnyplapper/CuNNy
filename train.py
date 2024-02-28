# CuNNy corrector/trainer
# Copyright (c) 2024 cunnyplapper
# SPDX-License-Identifier: LGPL-3.0-only
import os
import sys
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.utils
from torchvision import transforms
from torcheval.metrics.functional import peak_signal_noise_ratio as psnr
from PIL import Image

dev = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# internal convolutions
N  = int(sys.argv[1])
# feature layers/depth
D = int(sys.argv[2]) // 4 * 4
# epochs
E = 1000
# batch size
B = 64
# learning rate
LR = 0.00005
# max learning rate (with OneCycleLR)
MAX_LR = 0.003

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
    return transform(Image.open(os.path.join(dir, file)).convert('L')).to(dev)

class Dataset(torch.utils.data.Dataset):
    def __init__(self, dirx, diry, dirtrue, transform):
        self.files = os.listdir(dirtrue)
        self.x = [load(dirx, file, transform) for file in self.files]
        self.y = [load(diry, file, transform) for file in self.files]
        self.true = [load(dirtrue, file, transform) for file in self.files]

    def __len__(self):
        return len(self.files)

    def __getitem__(self, idx):
        return self.x[idx], self.y[idx], self.true[idx]

transform = transforms.Compose([transforms.ToTensor()])
rcas_path = 'in/rcas'
rcas = os.path.isdir(rcas_path)
dataset = Dataset('in/64', rcas_path if rcas else 'in/easu', 'in/128',
                  transform)
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
    for i, (x, y, true) in enumerate(dataloader):
        opt.zero_grad()
        pred = fwd(x, y)
        loss = loss_fn(pred, true)
        loss.backward()
        opt.step()
        sched.step()
        runloss += loss
        nloss += 1
    with torch.no_grad():
        print(f'[{idx + 1}/{E}] L: {(runloss / nloss):.7f} '
              f'| psnr: {psnr(pred, true):.7f} ')
    nloss = 0
    runloss = 0.
    idx += 1

with torch.autocast(device_type='cuda', dtype=torch.bfloat16):
    for i in range(E):
        train()

i = 0
fn = ''
suf = ('RCAS-' if rcas else '') + (sys.argv[3] + '-' if len(sys.argv) > 3 else '')
while os.path.exists((fn := f'models/{N}x{D}-{suf}{i}.pt')):
    i += 1
torch.save(model.state_dict(), fn)
print(f'saved to {fn}')

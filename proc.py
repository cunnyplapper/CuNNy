import os
import sys
import argparse
from random import choices, randint, random, uniform
from subprocess import run
from multiprocessing import Pool

parser = argparse.ArgumentParser()
parser.add_argument('in_', type=str)
parser.add_argument('out', type=str)
parser.add_argument('-f', '--fsr', nargs='?', const=True)
parser.add_argument('-d', '--distort', action='store_true')
parser.add_argument('-y', '--luma', action='store_true')
parser.add_argument('-s', '--sharpen', action='store_true')
parser.add_argument('-b', '--box-only', action='store_true')
parser.add_argument('-r', '--raw-hr', action='store_true')
parser.add_argument('-p', '--pure', action='store_true')
args = parser.parse_args()

def c(*v):
    v, w = zip(*v) if isinstance(v[0], tuple) else (v, None)
    return choices(v, weights=w)[0]

def mkdir(dir):
    assert(not os.path.isdir(dir))
    os.mkdir(dir)

mkdir(args.out)
hr = f'{args.out}/128'
mkdir(hr)
lr = f'{args.out}/64'
mkdir(lr)

if args.fsr:
    if isinstance(args.fsr, str):
        run(['./scripts/build.sh', f'-DSHARPNESS={args.fsr}'])
        fsr = f'{args.out}/rcas-{args.fsr}'
    else:
        fsr = f'{args.out}/easu'
    mkdir(fsr)
    gray = f'{args.out}/gray'
    mkdir(gray)

def resize(file):
    s = ['magick', f'{args.in_}/{file}']
    if args.luma:
        s += ['-colorspace', 'Gray']
    s += ['-rotate', f'{randint(0, 3) * 90}']
    s += c(['-flop'], [])
    if not args.raw_hr:
        s += ['-modulate', f'100,100,{randint(0, 200)}']
        s += [c('-level', '+level'), f'{randint(0, 20)}%']
    s += [f'{hr}/{file}']
    shr = s
    run(s)
    s = ['magick', f'{hr}/{file}']
    if not args.pure:
        blur = uniform(0.1, 1.0 if args.sharpen else 0.5)
        s += c((['-gaussian-blur', f'3x{blur:.1f}'], 1),
               ([], 9))
        s += c((['-sharpen', f'3x{uniform(0.1, 1.0):.1f}'], 1),
               ([], 9))
    box = 'Hermite' if args.sharpen else 'Box'
    filter = box if args.box_only else c((box, 5), ('CatRom', 5))
    s += ['-filter', filter, '-resize', '50%']
    if args.distort:
        if random() < 0.8:
            s += ['-format', 'jpg', '-quality', f'{randint(80, 95)}']
            file = file.replace('.png', '.jpg')
    s += [f'{lr}/{file}']
    slr = s
    run(s)
    if args.fsr:
        if not args.luma:
            png = file.replace('.jpg', '.png')
            run(['magick', f'{lr}/{file}', '-colorspace', 'Gray',
                 f'{gray}/{png}'])
            file = png
        run(['./scripts/fsr', f'{gray}/{file}', f'{fsr}/{file}',
             f'{1 if isinstance(args.fsr, str) else 0}'])
    return shr, slr

files = os.listdir(sys.argv[1])
hrs = ''
lrs = ''
with Pool() as pool:
    for hr, lr in pool.map(resize, files):
        hrs += ' '.join(hr) + '\n'
        lrs += ' '.join(lr) + '\n'

with open(args.out + '/hr.txt', 'w') as f:
    f.write(hrs)
with open(args.out + '/lr.txt', 'w') as f:
    f.write(lrs)

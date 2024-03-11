# converts the CuNNy model to an MagpieFX effect
# this code sucks, maybe tidy up one day™..
import sys
import numpy as np
import pickle
from collections import OrderedDict
from pathlib import Path

with open(sys.argv[1], 'rb') as f:
    m = pickle.load(f)

shader = ''
N = sum(1 for x in m.keys() if 'conv' in x and 'weight' in x)
D = next(m[x] for x in m if 'cin' in x and 'weight' in x).shape[0]
RGB = 'fancyluma.weight' in m
stem = Path(sys.argv[1]).stem
version = stem[:stem.rfind('-')]
usercas = 'RCAS' in stem
usefsr = 'BILINEAR' not in stem
crelu = m['crelu']

# TODO: replace suffix system with something better
assert('NVL' in version)

# thanks vim
openbr = '{'
closebr = '}'

def S(txt, end='\n'):
    global shader
    shader += txt + end

def fmt(v):
    return f'{v:.3e}' # enough for fp16

def weight(ws, x, y, ich, och, d, iidx, oidx):
    s = f'\tr += '
    w = [fmt(v.item()) for v in ws[(4*oidx):(4*(1+oidx)), (4*iidx):(4*(1+iidx)),
                                   y, x].swapaxes(0, 1).flatten()]
    wflat = ", ".join(w)
    l = f's{iidx}_{y * d + x}'
    if len(w) > 4:
        s += f'mul({l}, M4({wflat}));\n'
    else:
        s += f'V4({wflat}) * {l};\n'
    return s

header = """//!MAGPIE EFFECT
//!VERSION 4
//!SORT_NAME __SORT__

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
Texture2D OUTPUT;

__FSR__
//!SAMPLER
//!FILTER POINT
SamplerState SP;

//!SAMPLER
//!FILTER LINEAR
SamplerState SL;

"""

imgs = {}
def allocimgs(ins, n):
    global header, imgs
    out = []
    for name, ref in imgs.items():
        if len(out) == n:
            break
        if ref == 0:
            out += [name]
            imgs[name] += 1
    for i in range(len(out), n):
        name = f't{len(imgs)}'
        header += f'//!TEXTURE\n'
        header += f'//!WIDTH INPUT_WIDTH\n'
        header += f'//!HEIGHT INPUT_HEIGHT\n'
        header += f'//!FORMAT R8G8B8A8_SNORM\n'
        header += f'Texture2D {name};\n'
        header += f'\n'
        imgs[name] = 1
        out += [name]
    for inv in ins:
        if inv in imgs:
            imgs[inv] -= 1
    return out

npass = (2 if usercas else 1) if usefsr else 0
def prelude(ps, ins, loadfn=False, save=None, upscale=None, multiout=False,
            signed=False):
    global header, npass
    npass += 1
    S(f'//!PASS {npass}')
    S(f'//!DESC CuNNy-{version}-{ps}')
    if upscale:
        S(f'//!STYLE PS')
    else:
        S(f'//!BLOCK_SIZE 8')
        S(f'//!NUM_THREADS 64')
    S(f'//!IN ' + ', '.join(ins))
    if save:
        save = allocimgs(ins, len(save))
        S(f'//!OUT {", ".join(save)}')
        S('#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)')
        S('#define V4 min16float4')
        S('#define M4 min16float4x4')
    else:
        S(f'//!OUT OUTPUT')
    if loadfn:
        for i, inv in enumerate(ins):
            fn = f'O({inv}, float2(x, y))'
            if inv == 'INPUT':
                if RGB:
                    lw = ', '.join([fmt(v.item())
                                    for v in m['fancyluma.weight'].flatten()])
                    lb = fmt(m['fancyluma.bias'].item())
                    fn = f'(dot(float3({lw}), {fn}.rgb) + {lb})'
                else:
                    fn = f'dot(float3(0.299, 0.587, 0.114), {fn}.rgb)'
            S(f'#define l{i}(x, y) {fn}')
    if upscale:
        S(f'float4 Pass{npass}(float2 pos) {openbr}')
        S(f'\tfloat2 pt = float2(GetInputPt());')
    return save

def write(ps, k, actfn, ins):
    ws = m[k+'weight']
    sz = ws.shape
    crelup = crelu and ins != ['INPUT']
    if crelup:
        ws = ws.reshape(sz[0], -1, 4, sz[2], sz[3])
        half = ws.shape[1] // 2
        ws = np.dstack((ws[:, :half], ws[:, half:])).reshape(sz)
    och = sz[0]
    ich = sz[1]
    d = sz[2]
    texs = [f'{ps}_{oidx}' for oidx in range(och // 4)]
    texs = prelude(ps, ins, loadfn=True, save=texs, multiout=True,
                   signed=(ps == 'out'))
    global shader
    start = len(shader)
    S(f'void Pass{npass}(uint2 blockStart, uint3 tid) {openbr}')
    S(f'\tfloat2 pt = float2(GetInputPt());')
    S('\tuint2 gxy = Rmp8x8(tid.x) + blockStart;')
    S('\tuint2 size = GetInputSize();')
    S('\tif (gxy.x >= size.x || gxy.y >= size.y) {')
    S('\t\treturn;')
    S('\t}')
    S('\tfloat2 pos = (gxy + 0.5) * pt;')
    cent = d // 2
    stype = 'V4' if not ins == ['INPUT'] else 'min16float'
    vs = []
    for iidx in range(0, max(ich // 4, 1), 2 if crelup else 1):
        i = 0
        for y in range(d):
            for x in range(d):
                v = f's{iidx}_{i}'
                S(f'\t{stype} {v} = l{iidx // (2 if crelup else 1)}({x - cent}.0, {y - cent}.0);')
                vs += [v]
                i += 1
        if not crelup:
            continue
        i = 0
        for y in range(d):
            for x in range(d):
                v = f's{iidx + 1}_{i}'
                S(f'\t{stype} {v} = -max(-s{iidx}_{i}, 0.0);')
                vs += [v]
                i += 1
        i = 0
        for y in range(d):
            for x in range(d):
                S(f'\ts{iidx}_{i} = max(s{iidx}_{i}, 0.0);')
                i += 1
    wfns = ''
    for oidx in range(och // 4):
        wfns += f'float4 f{oidx}(float2 pt, float2 pos, {", ".join(f"{stype} {v}" for v in vs)}) {openbr}\n'
        wfns += f'\tV4 r = 0.0;\n'
        for iidx in range(max(ich // 4, 1)):
            for y in range(d):
                for x in range(d):
                    wfns += weight(ws, x, y, ich, och, d, iidx, oidx)
        bn = k + 'bias'
        if bn in m:
            b = [fmt(v.item()) for v in m[bn][4*oidx:4*(oidx+1)]]
            wfns += f'\tr += V4({", ".join(b)});\n'
        wfns += f'\treturn {actfn.replace("X", f"r")};\n'
        wfns += closebr + '\n'
        S(f'\t{texs[oidx]}[gxy] = f{oidx}(pt, pos, {", ".join(vs)});')
    S(f'{closebr}\n')
    shader = shader[:start] + wfns + shader[start:]
    return texs

easu = """// FSR mpv | modified
// Copyright (c) 2021 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// FidelityFX FSR v1.0.2 by AMD
// ported to mpv by agyild

//!PASS 1
//!DESC CuNNy-EASU
//!STYLE PS
//!IN INPUT
//!OUT easu

float GetLuma(float3 rgb) {
	return dot(float3(0.299, 0.587, 0.114), rgb);
}

float APrxLoRcpF1(float a) {
	return asfloat(uint(0x7ef07ebb) - asuint(a));
}

float APrxLoRsqF1(float a) {
	return asfloat(uint(0x5f347d74) - (asuint(a) >> uint(1)));
}

float AMin3F1(float x, float y, float z) {

	return min(x, min(y, z));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z));
}

void tap(inout float aC, inout float aW, float2 off, float2 dir, float2 len,
         float lob, float clp, float c){
	float2 v;
	v.x = (off.x * ( dir.x)) + (off.y * dir.y);
	v.y = (off.x * (-dir.y)) + (off.y * dir.x);
	v *= len;
	float d2 = v.x * v.x + v.y * v.y;
	d2 = min(d2, clp);
	float wB = float(2.0 / 5.0) * d2 + -1.0;

	float wA = lob * d2 + -1.0;
	wB *= wB;
	wA *= wA;
	wB = float(25.0 / 16.0) * wB + float(-(25.0 / 16.0 - 1.0));
	float w = wB * wA;
	aC += c * w;
	aW += w;
}

void set(inout float2 dir, inout float len, float2 pp, bool biS, bool biT,
         bool biU, bool biV, float lA, float lB, float lC, float lD, float lE){

	float w = 0.0;
	if (biS)
		w = (1.0 - pp.x) * (1.0 - pp.y);
	if (biT)
		w =        pp.x  * (1.0 - pp.y);
	if (biU)
		w = (1.0 - pp.x) *        pp.y;

	if (biV)
		w =        pp.x  *        pp.y;
	float dc = lD - lC;
	float cb = lC - lB;
	float lenX = max(abs(dc), abs(cb));
	lenX = APrxLoRcpF1(lenX);
	float dirX = lD - lB;
	lenX = clamp(abs(dirX) * lenX, 0.0, 1.0);
	lenX *= lenX;
	float ec = lE - lC;

	float ca = lC - lA;
	float lenY = max(abs(ec), abs(ca));
	lenY = APrxLoRcpF1(lenY);
	float dirY = lE - lA;
	lenY = clamp(abs(dirY) * lenY, 0.0, 1.0);
	lenY *= lenY;
	dir += float2(dirX, dirY) * w;
	len += dot(float2(w, w), float2(lenX, lenY));
}

float4 Pass1(float2 pos) {
	float2 pt = float2(GetInputPt());
	float2 size = float2(GetInputSize());
	float4 pix = float4(0.0, 0.0, 0.0, 1.0);
	float2 pp = pos * size - float2(0.5, 0.5);
	float2 fp = floor(pp);
	pp -= fp;
	float b = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(0.5, -0.5)) * pt), 0).rgb);
	float c = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(1.5, -0.5)) * pt), 0).rgb);
	float e = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(-0.5, 0.5)) * pt), 0).rgb);
	float f = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 0.5, 0.5)) * pt), 0).rgb);
	float g = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 1.5, 0.5)) * pt), 0).rgb);
	float h = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 2.5, 0.5)) * pt), 0).rgb);
	float i = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(-0.5, 1.5)) * pt), 0).rgb);
	float j = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 0.5, 1.5)) * pt), 0).rgb);
	float k = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 1.5, 1.5)) * pt), 0).rgb);
	float l = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 2.5, 1.5)) * pt), 0).rgb);
	float n = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(0.5, 2.5) ) * pt), 0).rgb);
	float o = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(1.5, 2.5) ) * pt), 0).rgb);
	float4 bczzL = float4(b, c, 0.0, 0.0);
	float4 ijfeL = float4(i, j, f, e);
	float4 klhgL = float4(k, l, h, g);
	float4 zzonL = float4(0.0, 0.0, o, n);
	float bL = bczzL.x;
	float cL = bczzL.y;
	float iL = ijfeL.x;
	float jL = ijfeL.y;
	float fL = ijfeL.z;
	float eL = ijfeL.w;
	float kL = klhgL.x;
	float lL = klhgL.y;
	float hL = klhgL.z;
	float gL = klhgL.w;
	float oL = zzonL.z;
	float nL = zzonL.w;
	float2 dir = float2(0.0, 0.0);
	float len = 0.0;
	set(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	set(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	set(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	set(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	float2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
	dir *= float2(dirR, dirR);
	len = len * 0.5;
	len *= len;
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	float2 len2 = float2(1.0 + (stretch - 1.0) * len, 1.0 + -0.5 * len);
	float lob = 0.5 + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	float clp = APrxLoRcpF1(lob);
	float aC = 0.0;
	float aW = 0.0;
	tap(aC, aW, float2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL);
	tap(aC, aW, float2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL);
	tap(aC, aW, float2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL);
	tap(aC, aW, float2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL);
	tap(aC, aW, float2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL);
	tap(aC, aW, float2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL);
	tap(aC, aW, float2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL);
	tap(aC, aW, float2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL);
	tap(aC, aW, float2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL);
	tap(aC, aW, float2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL);
	tap(aC, aW, float2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL);
	tap(aC, aW, float2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL);
	pix.r = aC / aW;
	float min1 = min(AMin3F1(fL, gL, jL), kL);
	float max1 = max(AMax3F1(fL, gL, jL), kL);
	pix.r = clamp(pix.r, min1, max1);
	pix.r = clamp(pix.r, 0.0, 1.0);
	return pix;
}
"""

rcas = """//!PASS 2
//!DESC CuNNy-RCAS
//!STYLE PS
//!IN easu
//!OUT rcas

// CuNNy: do not change unless changed during training as well
#define SHARPNESS __SHARPNESS__
#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0))

float APrxMedRcpF1(float a) {
	float b = asfloat(uint(0x7ef19fff) - asuint(a));
	return b * (-b * a + 2.0);
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z)); 
}


float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

float4 Pass2(float2 pos) {
	float2 pt = float2(GetInputPt());
	float2 size = float2(GetInputSize());
	float3 bde = easu.Gather(SP, pos + pt * float2(-0.5, -0.5), 0).xyz;
	float b = bde.z;
	float d = bde.x;
	float e = bde.y;
	float2 fh = easu.Gather(SP, pos + pt * float2(0.5, 0.5), 0).zx;
	float f = fh.x;
	float h = fh.y;
	float mn1L = min(AMin3F1(b, d, f), h);
	float mx1L = max(AMax3F1(b, d, f), h);
	float2 peakC = float2(1.0, -1.0 * 4.0);
	float hitMinL = min(mn1L, e) / (4.0 * mx1L);
	float hitMaxL = (peakC.x - max(mx1L, e)) / (4.0 * mn1L + peakC.y);
	float lobeL = max(-hitMinL, hitMaxL);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(lobeL, 0.0)) * exp2(-clamp(float(SHARPNESS), 0.0, 2.0));
	float nz = 0.25 * b + 0.25 * d + 0.25 * f + 0.25 * h - e;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(b, d, e), f, h) - AMin3F1(AMin3F1(b, d, e), f, h)), 0.0, 1.0);
	nz = -0.5 * nz + 1.0;
	lobe *= nz;
	float rcpL = APrxMedRcpF1(4.0 * lobe + 1.0);
	float4 pix = float4(0.0, 0.0, 0.0, 1.0);
	pix.r = float((lobe * b + lobe * d + lobe * h + lobe * f + e) * rcpL);
	return pix;
}
"""

lgpl = """
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3.0 of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

S(f'// CuNNy {version.replace("-", " ")}')
S(f'// Copyright (c) 2024 cunnyplapper')
S(lgpl, end='')
S('/* ------------------------------------------------------------------- */\n')
header = shader + header
shader = ''

if usefsr:
    fsrtex = 'easu'
    S(easu)
if usercas:
    fsrtex = 'rcas'
    S(rcas.replace('__SHARPNESS__', '2.0'))

texs = ['INPUT']
nconv = 1
relu = 'max(X, 0.0)' if not crelu else 'X'
for k_ in m:
    suf = 'weight'
    if not k_.endswith(suf):
        continue
    k_ = k_[:-len(suf)]
    k = k_
    pref = '_orig_mod.'
    if k.startswith(pref):
        k = k[len(pref):-1]
    if k.startswith('cin'):
        texs = write('in', k_, relu, texs)
    elif k.startswith('conv'):
        texs = write(f'conv{nconv}', k_, relu, texs)
        nconv += 1
    elif k.startswith('cout'):
        texs = write('out', k_, 'tanh(X)', texs)

fsrhdrbase = """//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
//!FORMAT R8_UNORM
Texture2D """

fsrhdr = fsrhdrbase + 'easu;\n'
if usercas:
    fsrhdr += '\n' + fsrhdrbase + 'rcas;\n'

suf = version[version.rfind("NVL")+3:].replace('-', '')
suf += '-' if suf != '' else ''
shader = header \
    .replace('__SORT__', f'CuNNy-{suf}D{D:02}N{N:02}') \
    .replace('__FSR__', fsrhdr if usefsr else '') + shader
prelude('shuffle', [*texs, 'INPUT'] + ([fsrtex] if usefsr else []), upscale=2)
S('\tstatic const float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};')
S('\tstatic const float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};')
S(f'\tfloat4 r = 0.0;')
S(f'\tfloat2 size = float2(GetInputSize());')
S(f'\tfloat2 f = frac(pos * size);')
S(f'\tfloat3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);')
S(f'\tint2 i = int2(f * 2.0);')
S(f'\tr.r = {texs[0]}.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];')
if usefsr:
    S(f'\tr.r += {fsrtex}.SampleLevel(SP, pos, 0).r;')
else:
    S(f'\tr.r += yuv.r;')
S(f'\tr.a = 1.0;')
S(f'\tr.r = clamp(r, 0.0, 1.0);')
S(f'\tfloat3 px = mul(yuv2rgb, float3(r.r, yuv.yz));')
S(f'\treturn float4(px, 1.0);')
S(f'{closebr}')

fp = f'test/CuNNy-{stem}.hlsl'
with open(fp, 'w') as f:
    f.write(shader)
print(fp)

# converts the CuNNy model to an mpv usershader
import numpy as np
import sys
import pickle
from pathlib import Path

with open(sys.argv[1], 'rb') as f:
    m = pickle.load(f)

shader = ''
N = sum(1 for x in m.keys() if 'conv' in x and 'weight' in x)
D = next(m[x] for x in m if 'in' in x and 'weight' in x).shape[0]
RGB = 'fancyluma.weight' in m
stem = Path(sys.argv[1]).stem
version = stem[:stem.rfind('-')]
usercas = 'RCAS' in stem
usefsr = 'BILINEAR' not in stem
assert(not RGB)
crelu = m['crelu']

# thanks vim
openbr = '{'
closebr = '}'

def S(txt, end='\n'):
    global shader
    shader += txt + end

def fmt(v):
    return f'{v:.3e}' # enough for fp16

def weight(ws, x, y, ich, och, d, iidx, oidx, l):
    cent = d // 2
    s = f'\tr{oidx} += '
    w = [fmt(v.item()) for v in ws[(4*oidx):(4*(1+oidx)), (4*iidx):(4*(1+iidx)),
                                   y, x].swapaxes(0, 1).flatten()]
    s += (f'{"M4" if len(w) > 4 else "V4"}({", ".join(w)}) * {l};')
    return s

def rectdim(n):
    for i in range(int(n ** 0.5), 0, -1):
        d, m = divmod(n, i)
        if m == 0:
            return d, i

def swizzle(n, i):
    w, h = rectdim(n)
    return i % w, i // w

def prelude(ps, ins, nouts=1, ch=4, loadfn=False, save=None):
    S(f'')
    S(f'//!DESC CuNNy-{version}-{ps}')
    S(f'//!HOOK LUMA')
    shuffle = ps == 'out-shuffle'
    w, h = (2, 2) if shuffle else rectdim(nouts)
    S(f'//!COMPUTE {8 * w} {8 * h} 8 8')
    if shuffle:
        if ins[1] != 'LUMA':
            S(f'//!BIND LUMA')
        save = False
    for inv in ins:
        S(f'//!BIND {inv[0]}')
        if save:
            if inv[0] != 'LUMA':
                S(f'//!BIND LUMA')
            S(f'//!SAVE {save}')
    ins = [ins[0]] if shuffle else ins
    S(f'//!WIDTH LUMA.w' + (f' {w} *' if w > 1 else ''))
    S(f'//!HEIGHT LUMA.h' + (f' {h} *' if h > 1 else ''))
    S(f'//!COMPONENTS {ch}')
    S(f'//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *')
    S(f'#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable')
    S(f'#ifdef GL_EXT_shader_explicit_arithmetic_types_float16')
    S(f'#\tdefine V4 f16vec4')
    S(f'#\tdefine M4 f16mat4')
    S(f'#\tdefine F float16_t')
    S(f'#else')
    S(f'#\tdefine V4 vec4')
    S(f'#\tdefine M4 mat4')
    S(f'#\tdefine F float')
    S(f'#endif')
    if loadfn:
        assert(len(ins) == 1)
        inv = ins[0]
        for i in range(inv[1]):
            iw, ih = rectdim(inv[1])
            if iw % 2 == 0 and ih % 2 == 0:
                break
            x, y = swizzle(inv[1], i)
            v = (f'texelFetch({inv[0]}_raw, clamp(pos + ivec2(x, y), ivec2(0), sz)'
                 f' * ivec2({iw}, {ih}) + ivec2({x}, {y}), 0)')
            if inv[0] == 'LUMA':
                S(f'#define l{i}(x, y) F({v}.r)')
            else:
                S(f'#define l{i}(x, y) V4({v})')

def write(ps, k, actfn, ins):
    shuffle = ps == 'out-shuffle'
    assert(len(ins) == (2 if shuffle else 1))
    inv = ins[0]
    ws = m[k+'weight']
    sz = ws.shape
    crelup = crelu and inv[0] != 'LUMA'
    if crelup:
        ws = ws.reshape(sz[0], -1, 4, sz[2], sz[3])
        half = ws.shape[1] // 2
        ws = np.dstack((ws[:, :half], ws[:, half:])).reshape(sz)
    och = sz[0]
    ich = sz[1]
    d = sz[2]
    tex = f'{ps}'
    crelup = crelu and inv[0] != 'LUMA'
    nouts = och // 4
    prelude(ps, ins, nouts, loadfn=True, save=tex)
    stype = 'F' if inv[0] == 'LUMA' else 'V4'
    ssz = 8 + d - 1
    nins = max(ich // 4 // (2 if crelup else 1), 1)
    S(f'shared {stype} g[{nins}][{ssz}][{ssz}];')
    global shader
    start = len(shader)
    S(f'void hook() {openbr}')
    S(f'\tivec2 xy = ivec2(gl_LocalInvocationID.xy);')
    S(f'\tivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;')
    w, h = (2, 2) if shuffle else rectdim(nouts)
    S(f'\tivec2 opos = pos * ivec2({w}, {h});')
    iw, ih = rectdim(inv[1])
    gather = iw % 2 == 0 and ih % 2 == 0
    if not gather:
        S(f'\tivec2 sz = ivec2(LUMA_size) - ivec2(1);')
    S(f'\tvec2 pt = {inv[0]}_pt;')
    S(f'\t#pragma optionNV(unroll all)')
    S(f'\tfor (int y = 0; y < {ssz}; y += 8) {openbr}')
    S(f'\t\tint ay = xy.y + y;')
    S(f'\t\tif (ay >= {ssz}) break;')
    S(f'\t\t#pragma optionNV(unroll all)')
    S(f'\t\tfor (int x = 0; x < {ssz}; x += 8) {openbr}')
    S(f'\t\t\tint ax = xy.x + x;')
    S(f'\t\t\tif (ax >= {ssz}) break;')
    cent = d // 2
    if gather:
        i = 0
        S('\t\t\tvec2 p;')
        for y in range(0, ih, 2):
            for x in range(0, iw, 2):
                S(f'\t\t\tp = vec2((pos + ivec2(x - {cent}, y - {cent}))'
                  f' * ivec2({iw}, {ih}) + ivec2({x + 1}, {y + 1}))'
                  f' * {inv[0]}_pt;')
                for j, c in enumerate('rgba'):
                    S(f'\t\t\t{stype} s{c}{i} ='
                      f' {stype}({inv[0]}_gather(p, {j}));')
                for j, c in enumerate('wzxy'):
                    S(f'\t\t\tg[{i * 4 + j}][ay][ax] ='
                      f' {stype}(sr{i}.{c}, sg{i}.{c}, sb{i}.{c}, sa{i}.{c});')
                i += 1
    else:
        for iidx in range(0, nins):
            S(f'\t\t\tg[{iidx}][ay][ax] = l{iidx}(x - {cent}, y - {cent});')
    S(f'\t\t{closebr}\n\t{closebr}')
    S(f'\tbarrier();')
    S(f'\t{stype} s[{d}][{d}][{2 if crelup else 1}];')
    for oidx in range(nouts):
        S(f'\tV4 r{oidx} = V4(0.0);')
    for iidx in range(0, max(ich // 4, 1), 2 if crelup else 1):
        for y in range(d):
            for x in range(d):
                for i in range(2 if crelup else 1):
                    s = f'g[{iidx // (2 if crelup else 1)}][xy.y+{y}][xy.x+{x}]'
                    if crelup:
                        s = (f'max({s}, {stype}(0.0))' if i == 0 else
                             f'-max(-{s}, {stype}(0.0))')
                    S(f'\ts[{y}][{x}][{i}] = {s};')
        for y in range(d):
            for x in range(d):
                for i in range(2 if crelup else 1):
                    l = f's[{y}][{x}][{i}]'
                    for oidx in range(nouts):
                        S(weight(ws, x, y, ich, och, d, iidx + i, oidx, l))
    for oidx in range(nouts):
        bn = k + 'bias'
        if bn in m:
            b = [fmt(v.item()) for v in m[bn][4*oidx:4*(oidx+1)]]
            S(f'\tr{oidx} += V4({", ".join(b)});')
        if actfn:
            S(f'\tr{oidx} = {actfn.replace("X", f"r{oidx}")};')
        x, y = swizzle(nouts, oidx)
        if shuffle:
            break
        S(f'\timageStore(out_image, opos + ivec2({x}, {y}), vec4(r{oidx}));')
    if shuffle:
        base = ins[1][0]
        S(f'\tvec2 opt = 0.5 * LUMA_pt;')
        S(f'\tvec2 fpos = (vec2(opos) + vec2(0.5)) * opt;')
        for y in range(2):
            for x in range(2):
                c = 'xyzw'[y * 2 + x]
                S(f'\timageStore(out_image, opos + ivec2({x}, {y}), '
                  f'vec4(r0.{c} + {base}_tex(fpos + vec2({x}.0, {y}.0) * opt).r,'
                         ' 0.0, 0.0, 1.0));')
    S(f'{closebr}')
    return [(tex, nouts)]

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

//!DESC CuNNy-__VER__-EASU
//!HOOK LUMA
//!BIND LUMA
//!SAVE easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
//!COMPONENTS 1

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxLoRsqF1(float a) {
	return uintBitsToFloat(uint(0x5f347d74) - (floatBitsToUint(a) >> uint(1)));
}

float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z));
}

void tap(inout float aC, inout float aW, vec2 off, vec2 dir, vec2 len,
         float lob, float clp, float c){
	vec2 v;
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

void set(inout vec2 dir, inout float len, vec2 pp, bool biS, bool biT,
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
	dir += vec2(dirX, dirY) * w;
	len += dot(vec2(w), vec2(lenX, lenY));
}

vec4 hook() {
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	vec2 pp = LUMA_pos * LUMA_size - vec2(0.5);
	vec2 fp = floor(pp);
	pp -= fp;
#if (defined(LUMA_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec4 bczzL = LUMA_gather(vec2((fp + vec2(1.0, -1.0)) * LUMA_pt), 0);
	vec4 ijfeL = LUMA_gather(vec2((fp + vec2(0.0,  1.0)) * LUMA_pt), 0);
	vec4 klhgL = LUMA_gather(vec2((fp + vec2(2.0,  1.0)) * LUMA_pt), 0);
	vec4 zzonL = LUMA_gather(vec2((fp + vec2(1.0,  3.0)) * LUMA_pt), 0);
#else
	float b = LUMA_tex(vec2((fp + vec2(0.5, -0.5)) * LUMA_pt)).r;
	float c = LUMA_tex(vec2((fp + vec2(1.5, -0.5)) * LUMA_pt)).r;
	float e = LUMA_tex(vec2((fp + vec2(-0.5, 0.5)) * LUMA_pt)).r;
	float f = LUMA_tex(vec2((fp + vec2( 0.5, 0.5)) * LUMA_pt)).r;
	float g = LUMA_tex(vec2((fp + vec2( 1.5, 0.5)) * LUMA_pt)).r;
	float h = LUMA_tex(vec2((fp + vec2( 2.5, 0.5)) * LUMA_pt)).r;
	float i = LUMA_tex(vec2((fp + vec2(-0.5, 1.5)) * LUMA_pt)).r;
	float j = LUMA_tex(vec2((fp + vec2( 0.5, 1.5)) * LUMA_pt)).r;
	float k = LUMA_tex(vec2((fp + vec2( 1.5, 1.5)) * LUMA_pt)).r;
	float l = LUMA_tex(vec2((fp + vec2( 2.5, 1.5)) * LUMA_pt)).r;
	float n = LUMA_tex(vec2((fp + vec2(0.5, 2.5) ) * LUMA_pt)).r;
	float o = LUMA_tex(vec2((fp + vec2(1.5, 2.5) ) * LUMA_pt)).r;
	vec4 bczzL = vec4(b, c, 0.0, 0.0);
	vec4 ijfeL = vec4(i, j, f, e);
	vec4 klhgL = vec4(k, l, h, g);
	vec4 zzonL = vec4(0.0, 0.0, o, n);
#endif
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
	vec2 dir = vec2(0.0);
	float len = 0.0;
	set(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	set(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	set(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	set(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	vec2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
	dir *= vec2(dirR);
	len = len * 0.5;
	len *= len;
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	vec2 len2 = vec2(1.0 + (stretch - 1.0) * len, 1.0 + -0.5 * len);
	float lob = 0.5 + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	float clp = APrxLoRcpF1(lob);
	float aC = 0.0;
	float aW = 0.0;
	tap(aC, aW, vec2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL);
	tap(aC, aW, vec2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL);
	tap(aC, aW, vec2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL);
	tap(aC, aW, vec2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL);
	tap(aC, aW, vec2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL);
	tap(aC, aW, vec2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL);
	tap(aC, aW, vec2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL);
	tap(aC, aW, vec2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL);
	tap(aC, aW, vec2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL);
	tap(aC, aW, vec2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL);
	tap(aC, aW, vec2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL);
	tap(aC, aW, vec2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL);
	pix.r = aC / aW;
	float min1 = min(AMin3F1(fL, gL, jL), kL);
	float max1 = max(AMax3F1(fL, gL, jL), kL);
	pix.r = clamp(pix.r, min1, max1);
	pix.r = clamp(pix.r, 0.0, 1.0);
	return pix;
}
"""

rcas = """//!DESC CuNNy-__VER__-RCAS
//!HOOK LUMA
//!BIND easu
//!SAVE rcas
//!WIDTH easu.w
//!HEIGHT easu.h
//!COMPONENTS 1

// CuNNy: do not change unless changed during training as well
#define SHARPNESS __SHARPNESS__
#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0))

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + 2.0);
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z)); 
}


float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

vec4 hook() {
#if (defined(easu_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec3 bde = easu_gather(easu_pos + easu_pt * vec2(-0.5), 0).xyz;
	float b = bde.z;
	float d = bde.x;
	float e = bde.y;
	vec2 fh = easu_gather(easu_pos + easu_pt * vec2(0.5), 0).zx;
	float f = fh.x;
	float h = fh.y;
#else
	float b = easu_texOff(vec2( 0.0, -1.0)).r;
	float d = easu_texOff(vec2(-1.0,  0.0)).r;
	float e = easu_tex(easu_pos).r;
	float f = easu_texOff(vec2(1.0, 0.0)).r;
	float h = easu_texOff(vec2(0.0, 1.0)).r;
#endif
	float mn1L = min(AMin3F1(b, d, f), h);
	float mx1L = max(AMax3F1(b, d, f), h);
	vec2 peakC = vec2(1.0, -1.0 * 4.0);
	float hitMinL = min(mn1L, e) / (4.0 * mx1L);
	float hitMaxL = (peakC.x - max(mx1L, e)) / (4.0 * mn1L + peakC.y);
	float lobeL = max(-hitMinL, hitMaxL);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(lobeL, 0.0)) * exp2(-clamp(float(SHARPNESS), 0.0, 2.0));
	float nz = 0.25 * b + 0.25 * d + 0.25 * f + 0.25 * h - e;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(b, d, e), f, h) - AMin3F1(AMin3F1(b, d, e), f, h)), 0.0, 1.0);
	nz = -0.5 * nz + 1.0;
	lobe *= nz;
	float rcpL = APrxMedRcpF1(4.0 * lobe + 1.0);
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
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

basetex = 'LUMA'
if usefsr:
    basetex = 'easu'
    S(easu.replace("__VER__", version))

if 'RCAS' in stem:
    basetex = 'rcas'
    S(rcas.replace("__VER__", version)
          .replace('__SHARPNESS__', str(m['sharpness'])))

texs = [('LUMA', 1)]
nconv = 1
relu = 'max(X, 0.0)' if not crelu else None
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
        texs = write('out-shuffle', k_, 'tanh(X)', texs + [(basetex, 1)])

fp = f'test/CuNNy-{stem}.glsl'
with open(fp, 'w') as f:
    f.write(shader)
print(fp)

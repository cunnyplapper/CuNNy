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

def weight(ws, x, y, ich, och, d, iidx, oidx):
    cent = d // 2
    s = f'\tr += '
    w = [fmt(v.item()) for v in ws[(4*oidx):(4*(1+oidx)), (4*iidx):(4*(1+iidx)),
                                   y, x].swapaxes(0, 1).flatten()]
    s += (f'{"M4" if len(w) > 4 else "V4"}'
          f'({", ".join(w)}) * s{iidx}[y+{y}][x+{x}];\n')
    return s

def prelude(ps, ins, nouts=1, ch=4, loadfn=False, save=None, upscale=None):
    S(f'')
    S(f'//!DESC CuNNy-{version}-{ps}')
    S(f'//!HOOK LUMA')
    if save:
        S(f'//!COMPUTE {8 * nouts} 8 8 8')
    for inv in ins:
        S(f'//!BIND {inv[0]}')
        if save:
            if inv[0] != 'LUMA':
                S(f'//!BIND LUMA')
            S(f'//!SAVE {save}')
    S(f'//!WIDTH LUMA.w' + (f' {upscale} *' if upscale else '') +
      (f' {nouts} *' if nouts > 1 else ''))
    S(f'//!HEIGHT LUMA.h' + (f' {upscale} *' if upscale else ''))
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
            v = (f'texelFetch({inv[0]}_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz)'
                 f' * ivec2({inv[1]}, 1) + ivec2({i}, 0), 0)')
            if inv[0] == 'LUMA':
                S(f'#define l{i}(x, y) F({v}.r)')
            else:
                S(f'#define l{i}(x, y) V4({v})')
    if upscale:
        S(f'vec4 hook() {openbr}')

def write(ps, k, actfn, ins):
    assert(len(ins) == 1)
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
    for iidx in range(0, nins):
        S(f'shared {stype} s{iidx * (2 if crelup else 1)}[{ssz}][{ssz}];')
        if crelup:
            S(f'shared {stype} s{iidx * 2 + 1}[{ssz}][{ssz}];')
    global shader
    start = len(shader)
    S(f'void hook() {openbr}')
    S(f'\tivec2 xy = ivec2(gl_LocalInvocationID.xy);')
    S(f'\tivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;')
    S(f'\tivec2 ipos = pos;')
    S(f'\tivec2 opos = pos * ivec2({nouts}, 1);')
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
    for iidx in range(0, nins):
        S(f'\t\t\ts{iidx * (2 if crelup else 1)}[ay][ax] = '
          f'l{iidx}(x - {cent}, y - {cent});')
    for iidx in range(0, nins):
        if not crelup:
            break
        S(f'\t\t\ts{iidx * 2 + 1}[ay][ax] = -max(-s{iidx * 2}[ay][ax], {stype}(0.0));')
        S(f'\t\t\ts{iidx * 2}[ay][ax] = max(s{iidx * 2}[ay][ax], {stype}(0.0));')
    S(f'\t\t{closebr}\n\t{closebr}')
    S(f'\tbarrier();')
    wfns = ''
    for oidx in range(nouts):
        wfns += f'vec4 f{oidx}(int x, int y) {openbr}\n'
        wfns += '\tV4 r = V4(0.0);\n'
        for iidx in range(max(ich // 4, 1)):
            for y in range(d):
                for x in range(d):
                    wfns += weight(ws, x, y, ich, och, d, iidx, oidx)
        bn = k + 'bias'
        if bn in m:
            b = [fmt(v.item()) for v in m[bn][4*oidx:4*(oidx+1)]]
            wfns += f'\tr += V4({", ".join(b)});\n'
        wfns += f'\treturn {actfn.replace("X", "vec4(r)")};\n'
        wfns += f'{closebr}\n'
        S(f'\tvec4 r{oidx} = f{oidx}(xy.x, xy.y);')
    for oidx in range(nouts):
        S(f'\timageStore(out_image, opos + ivec2({oidx}, 0), r{oidx});')
    S(f'{closebr}')
    shader = shader[:start] + wfns + shader[start:]
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

//!DESC CuNNy-EASU
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

rcas = """//!DESC CuNNy-RCAS
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

fsrtex = 'LUMA'
if usefsr:
    fsrtex = 'easu'
    S(easu)

if 'RCAS' in stem:
    fsrtex = 'rcas'
    S(rcas.replace('__SHARPNESS__', str(m['sharpness'])))

texs = [('LUMA', 1)]
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

prelude('shuffle', [texs[0], (fsrtex, 1)], ch=1, upscale=2)
S(f'\tvec4 r = vec4(0.0);')
S(f'\tvec2 f = fract(out_pos * out_size);')
S(f'\tivec2 i = ivec2(f * vec2(2.0));')
S(f'\tr.r = out_tex((vec2(0.5) - f) * out_pt + out_pos)[2*i.y + i.x];')
S(f'\tr.r += {fsrtex}_tex({fsrtex}_pos).r;')
S(f'\tr.a = 1.0;')
S(f'\treturn clamp(r, 0.0, 1.0);')
S(f'{closebr}')

fp = f'test/CuNNy-{stem}.glsl'
with open(fp, 'w') as f:
    f.write(shader)
print(fp)

// CuNNy 4x4C RCAS
// Copyright (c) 2024 cunnyplapper

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
/* ------------------------------------------------------------------- */

// FSR mpv | modified
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

//!DESC CuNNy-RCAS
//!HOOK LUMA
//!BIND easu
//!SAVE rcas
//!WIDTH easu.w
//!HEIGHT easu.h
//!COMPONENTS 1

// CuNNy: do not change unless changed during training as well
#define SHARPNESS 2.0
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


//!DESC CuNNy-4x4C-RCAS-in
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND LUMA
//!SAVE in
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) F(texelFetch(LUMA_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0).r)
shared F s0[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += V4(3.380e-02, 2.261e-03, -1.297e-02, -2.548e-01) * s0[y+0][x+0];
	r += V4(-4.893e-01, 3.915e-01, -9.432e-03, 3.193e-01) * s0[y+0][x+1];
	r += V4(-2.559e-01, -7.073e-03, 2.897e-02, -2.510e-01) * s0[y+0][x+2];
	r += V4(2.045e-02, 6.234e-02, 5.684e-01, -1.754e-02) * s0[y+1][x+0];
	r += V4(-4.753e-02, -1.790e-02, 1.106e-01, 1.819e-01) * s0[y+1][x+1];
	r += V4(2.767e-02, -4.398e-01, -1.038e-01, 7.862e-02) * s0[y+1][x+2];
	r += V4(-1.230e-02, -3.186e-02, 1.256e-02, -2.952e-03) * s0[y+2][x+0];
	r += V4(2.043e-02, 9.765e-02, -6.562e-01, -6.589e-02) * s0[y+2][x+1];
	r += V4(-4.145e-03, -4.372e-02, 4.785e-02, -6.998e-02) * s0[y+2][x+2];
	r += V4(1.041e-02, -4.187e-02, 4.730e-02, 1.752e-03);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = LUMA_pt;
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			s0[ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}

//!DESC CuNNy-4x4C-RCAS-conv1
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND in
//!BIND LUMA
//!SAVE conv1
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(in_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-2.493e-01, -6.063e-01, 5.985e-01, -2.002e-01, 4.670e-03, -1.252e-01, 1.691e-02, 7.083e-01, 1.898e-02, -1.335e-01, -1.314e-01, -4.424e-01, -2.372e-03, 1.910e-01, -5.951e-03, -5.769e-03) * s0[y+0][x+0];
	r += M4(-1.233e-01, -7.758e-01, -1.674e-01, -1.300e+00, -1.896e-01, -3.758e-01, -4.365e-01, -4.596e-01, 8.742e-02, 9.229e-01, 1.825e-01, 9.352e-01, -1.029e-01, 1.774e-01, 4.044e-01, 6.707e-01) * s0[y+0][x+1];
	r += M4(-2.308e-01, 3.240e-01, -3.947e-01, 1.668e-01, -1.724e-01, 4.519e-02, 1.880e-01, 1.550e-01, 6.129e-01, 2.820e-01, -6.347e-03, -5.775e-02, 8.618e-02, -1.352e-01, 1.650e-01, -2.590e-02) * s0[y+0][x+2];
	r += M4(-4.570e-01, -1.469e+00, 2.885e-01, -3.598e+00, -3.712e-02, -1.507e-01, 3.609e-01, -6.493e-01, -3.529e-02, -2.202e-02, -1.808e-01, 1.589e-01, 5.281e-02, -4.150e-01, -3.527e-01, -4.132e-01) * s0[y+1][x+0];
	r += M4(5.300e-01, -2.568e+00, 2.058e+00, -4.017e-01, -4.225e-01, -3.240e-01, 2.110e-02, 1.606e-01, 1.535e-02, -1.426e-01, 1.062e-01, 1.363e-01, -6.108e-02, 9.959e-01, -8.478e-02, 2.752e-01) * s0[y+1][x+1];
	r += M4(5.895e-01, 9.978e-01, -2.805e-01, -4.228e-01, 1.205e-01, 1.395e-02, -3.017e-01, -2.541e-03, -3.253e-01, -1.294e-01, -7.298e-02, -1.567e-01, 4.527e-02, -1.673e-01, -1.007e-01, -1.794e-01) * s0[y+1][x+2];
	r += M4(8.929e-01, -2.940e+00, 5.829e+00, 1.857e+00, 1.146e-01, -1.240e-02, 1.411e-01, -3.110e-01, -1.196e-02, -1.044e-02, 1.610e-02, -8.630e-02, -3.578e-02, 7.095e-03, -2.575e-02, 2.116e-01) * s0[y+2][x+0];
	r += M4(1.016e+01, 7.978e-02, 1.159e+01, 4.635e+00, 3.171e-01, 8.989e-02, 4.771e-02, 8.264e-02, 4.626e-02, 3.027e-02, -1.777e-02, 9.368e-02, 3.808e-02, -7.411e-02, 5.134e-01, -4.876e-01) * s0[y+2][x+1];
	r += M4(1.478e+00, 3.338e-01, 1.722e+00, -5.676e-01, -3.045e-02, 9.381e-02, -8.137e-02, 4.616e-02, 1.941e-03, 8.997e-03, -6.261e-02, 4.233e-02, -1.023e-01, -1.661e-01, 5.333e-01, -1.697e-01) * s0[y+2][x+2];
	r += M4(2.083e-02, 6.753e-02, -1.869e-01, 1.028e-01, 1.163e-02, 2.188e-01, 2.105e-02, 5.371e-01, 2.191e-02, -1.218e-01, -1.406e-01, -3.252e-01, 1.344e-02, 1.564e-02, -9.167e-02, -1.214e-01) * s1[y+0][x+0];
	r += M4(-1.366e-01, -1.953e-01, 2.447e-02, -6.811e-02, -7.986e-02, -3.900e-01, -3.485e-01, -4.926e-01, 1.879e-01, 8.028e-01, 4.131e-01, 2.503e-01, -9.451e-02, 9.539e-02, 3.311e-01, 6.045e-01) * s1[y+0][x+1];
	r += M4(7.766e-03, 6.110e-02, -3.404e-02, -3.035e-02, -1.694e-01, 2.043e-02, 1.770e-01, 1.539e-01, 3.529e-01, -1.061e-01, 1.264e-01, -1.873e-01, 3.180e-02, -1.327e-01, 3.141e-02, -3.500e-02) * s1[y+0][x+2];
	r += M4(2.050e-01, -1.515e-01, 2.951e-01, 4.968e-02, -1.101e-01, -2.939e-01, 3.622e-01, 5.896e-02, -2.672e-02, 3.128e-02, -1.616e-01, 2.066e-01, 7.398e-02, -3.196e-01, -2.873e-01, -6.757e-01) * s1[y+1][x+0];
	r += M4(3.273e-01, -1.344e-01, -5.198e-02, 6.128e-02, 1.884e-01, 3.329e-01, 1.128e-01, 1.036e-01, 5.781e-02, -1.997e-01, 1.141e-01, -1.899e-01, 3.092e-02, 1.028e+00, 1.251e-01, 3.133e-01) * s1[y+1][x+1];
	r += M4(3.269e-02, 1.310e-01, -1.058e-01, -1.044e-01, 2.134e-02, -7.679e-02, -3.602e-01, -7.864e-03, -7.212e-02, -2.392e-02, -7.364e-02, -5.593e-02, 9.506e-02, -2.649e-01, -1.877e-02, -2.362e-01) * s1[y+1][x+2];
	r += M4(7.379e-02, 9.931e-02, -9.190e-02, -1.587e-01, 2.817e-02, -5.100e-02, 1.626e-01, -3.414e-02, -1.309e-03, -1.622e-02, 5.299e-02, -5.850e-02, -7.809e-02, 8.140e-04, -2.346e-01, 2.518e-01) * s1[y+2][x+0];
	r += M4(1.253e-01, 1.294e-01, 1.966e-01, 3.207e-02, 2.852e-01, -1.877e-01, 2.966e-01, 4.554e-02, 3.195e-02, 4.519e-02, -9.021e-02, 1.003e-01, 7.281e-02, -1.915e-01, -1.222e-01, -2.834e-01) * s1[y+2][x+1];
	r += M4(8.937e-02, -5.695e-02, 1.627e-01, 1.198e-01, -8.849e-02, 1.141e-01, -6.055e-02, 5.821e-03, 3.358e-02, 3.796e-02, -1.006e-01, 2.753e-02, -1.354e-01, -6.612e-02, -1.068e-01, 5.864e-02) * s1[y+2][x+2];
	r += V4(4.986e-01, -5.224e-02, 2.765e-02, -1.973e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = in_pt;
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}

//!DESC CuNNy-4x4C-RCAS-conv2
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv1
//!BIND LUMA
//!SAVE conv2
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv1_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.331e-02, 1.323e-01, -1.731e-02, -1.143e-01, -3.845e-03, 6.425e-02, -1.283e-01, -3.509e-02, 5.894e-01, 1.062e-01, 1.212e-01, 1.850e-01, -2.731e-01, -1.076e-01, -1.672e-01, -1.441e-01) * s0[y+0][x+0];
	r += M4(8.575e-02, 2.279e-01, 1.597e-01, -6.164e-02, 7.536e-02, -6.439e-02, -4.754e-02, -1.213e-01, -1.991e-01, 5.703e-02, -1.044e-01, 4.229e-01, 9.828e-02, 1.220e-01, -1.050e-01, -4.027e-02) * s0[y+0][x+1];
	r += M4(1.544e-02, -2.240e-02, 1.062e-02, -4.802e-02, 1.270e-02, -9.100e-02, -1.940e-02, -6.810e-02, 2.994e-02, 8.336e-02, -3.789e-02, 6.323e-02, -1.539e-01, -1.592e-01, -2.777e-02, -4.580e-02) * s0[y+0][x+2];
	r += M4(2.993e-01, 9.751e-02, 3.836e-03, 2.931e-01, 5.065e-02, -6.884e-03, -7.929e-02, 5.976e-03, -8.417e-02, 1.866e-01, -4.058e-01, -7.690e-02, -3.889e-01, 3.894e-02, 1.169e-01, 8.564e-03) * s0[y+1][x+0];
	r += M4(-2.430e-01, 1.304e-01, 2.378e-02, 8.611e-02, 1.276e-01, -2.965e-02, 2.920e-02, -1.928e-02, 1.420e-01, -1.133e-01, -5.314e-01, 3.928e-01, 1.921e-01, -1.047e-01, -2.163e-02, 8.933e-01) * s0[y+1][x+1];
	r += M4(-1.437e-02, -3.425e-02, -9.271e-02, 1.151e-01, 3.248e-03, -3.983e-02, 2.155e-02, 4.202e-03, -2.344e-01, 2.286e-01, 9.494e-02, -7.797e-03, 1.261e-01, -1.017e-01, -2.113e-02, -7.489e-02) * s0[y+1][x+2];
	r += M4(-8.274e-02, -7.155e-03, -1.986e-02, -1.731e-01, 9.793e-02, 9.320e-02, 8.694e-03, 7.881e-02, -9.918e-03, -3.369e-02, 9.337e-02, 9.796e-02, -5.583e-02, -9.713e-02, 2.528e-01, 2.146e-02) * s0[y+2][x+0];
	r += M4(7.691e-03, 1.666e-01, -3.794e-02, 6.592e-02, 2.908e-02, -8.872e-02, 9.388e-01, 7.586e-02, 2.512e-02, -1.466e-01, -5.485e-02, -1.259e-01, -1.295e-01, 2.259e-02, 1.947e-01, -9.975e-03) * s0[y+2][x+1];
	r += M4(-4.832e-02, 3.400e-02, -4.883e-02, -6.707e-02, 1.477e-01, -1.163e-01, -6.574e-02, 1.104e-03, 1.630e-02, -9.965e-03, 2.969e-02, -8.584e-03, 1.736e-01, -9.662e-02, 9.214e-02, 1.266e-01) * s0[y+2][x+2];
	r += M4(8.798e-01, 7.379e-01, -4.552e-01, -6.105e-01, 2.666e-01, 4.975e-02, 1.821e-01, 2.260e-01, -3.056e-01, -5.313e-02, -1.647e-01, -2.470e-01, 1.085e-03, 7.247e-02, -2.404e-02, -9.776e-02) * s1[y+0][x+0];
	r += M4(4.258e-01, 1.476e+00, 2.953e-02, -6.387e-01, -3.421e-01, 2.408e-02, 8.327e-02, 1.136e-01, 5.016e-01, 1.510e-01, 1.774e-02, -3.370e-01, 5.059e-01, 2.866e-01, 1.629e-01, -3.669e-02) * s1[y+0][x+1];
	r += M4(-2.397e-01, 6.371e-01, 7.756e-01, -1.501e-01, -1.162e-01, 3.818e-03, 9.542e-02, 1.261e-01, 1.898e-01, 5.777e-02, 4.643e-02, -5.876e-02, -3.478e-01, 1.268e-01, 1.015e-02, 3.405e-02) * s1[y+0][x+2];
	r += M4(1.082e+00, 7.707e-01, -2.689e+00, 2.089e+00, 4.888e-01, -4.343e-02, 7.594e-02, 3.177e-01, -2.495e-01, -5.111e-02, 5.423e-01, 2.888e-02, 1.325e-01, -7.254e-02, 8.527e-02, -7.235e-02) * s1[y+1][x+0];
	r += M4(2.216e-02, 1.233e+00, -6.233e-01, 4.444e-01, -2.863e-01, 1.265e-01, -3.235e-02, 2.190e-01, 7.002e-02, -7.151e-02, -4.817e-01, 1.368e-01, 6.901e-01, 3.871e-02, 3.829e-02, 7.949e-01) * s1[y+1][x+1];
	r += M4(-1.619e-01, 7.401e-01, -9.566e-02, 1.289e-01, -8.156e-02, 3.696e-02, -2.454e-01, -5.287e-03, -2.489e-02, -8.038e-02, 1.192e-01, -7.935e-02, -5.879e-01, 1.402e-01, 1.507e-01, 1.768e-01) * s1[y+1][x+2];
	r += M4(-1.495e-01, 2.033e-01, -7.309e-01, -4.692e-01, -3.552e-02, 1.069e-01, -4.130e-01, -5.589e-02, 1.450e-01, -3.600e-02, -1.707e-03, 1.221e-01, 1.798e-01, 9.749e-02, -2.132e-02, -1.945e-02) * s1[y+2][x+0];
	r += M4(-1.352e+00, 2.687e-01, -4.152e-01, -4.977e-01, -6.623e-01, 2.653e-02, 2.920e-01, -7.795e-01, -1.160e-01, -5.426e-02, -3.624e-02, 2.313e-02, 1.204e-01, 6.447e-02, -1.999e-03, -2.808e-02) * s1[y+2][x+1];
	r += M4(-2.714e-01, 2.238e-01, -4.229e-01, -2.416e-01, 3.781e-01, -1.413e-01, -1.763e-01, -3.140e-01, 1.547e-01, 8.378e-04, 1.440e-01, 1.013e-01, -3.535e-01, -4.228e-02, -2.772e-01, -3.973e-01) * s1[y+2][x+2];
	r += V4(5.599e-02, 3.153e-02, 1.703e-02, -1.940e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv1_pt;
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}

//!DESC CuNNy-4x4C-RCAS-conv3
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE conv3
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(3.264e-02, 4.405e-03, 1.491e-01, 1.180e-01, 2.857e-02, 4.188e-02, -1.026e-01, -4.336e-02, -4.546e-02, -1.421e-01, 2.444e-01, 7.882e-02, -7.641e-02, 2.241e-01, -2.102e-01, 1.067e-02) * s0[y+0][x+0];
	r += M4(7.595e-02, -1.051e-01, 1.337e-01, 6.470e-02, -1.490e-01, -2.313e-02, -3.248e-01, -1.821e-01, 4.362e-02, -1.938e-01, 1.678e-01, 4.899e-02, -2.655e-02, -3.789e-02, 1.844e-01, 2.271e-01) * s0[y+0][x+1];
	r += M4(5.810e-02, -2.252e-02, 5.218e-02, 9.606e-02, 7.257e-02, -3.440e-02, 3.430e-04, -7.650e-02, 6.324e-03, 1.305e-02, -3.582e-03, 3.505e-02, 8.500e-02, -2.127e-02, 7.746e-02, 2.559e-02) * s0[y+0][x+2];
	r += M4(6.249e-02, -2.998e-01, 3.369e-01, 2.900e-01, 6.151e-02, 1.439e-01, 9.317e-02, -5.177e-02, -1.340e-01, 3.447e-01, 3.187e-02, -1.154e-01, 6.469e-02, 3.387e-02, -2.114e-01, -1.057e-01) * s0[y+1][x+0];
	r += M4(1.461e-01, -1.365e-01, -5.809e-02, -4.131e-02, -2.710e-01, 4.509e-02, 1.021e-01, 2.915e-01, 3.724e-01, 1.023e-01, -1.956e-01, 1.211e-01, -7.258e-01, 1.600e-02, 3.667e-01, -3.599e-01) * s0[y+1][x+1];
	r += M4(1.581e-01, -4.454e-03, -8.821e-02, -3.521e-02, 1.348e-02, 1.032e-03, 9.156e-02, 1.285e-01, -9.860e-02, 7.839e-02, -1.491e-02, 1.062e-01, 2.305e-01, -5.941e-02, -8.617e-02, -6.302e-02) * s0[y+1][x+2];
	r += M4(-1.662e-02, -1.237e-01, -1.500e-01, -6.196e-02, 5.630e-02, -2.082e-02, 7.920e-02, -6.438e-03, -5.987e-02, 4.080e-02, -5.526e-02, -1.083e-02, 3.893e-02, 1.597e-01, 1.062e-01, 1.052e-01) * s0[y+2][x+0];
	r += M4(1.883e-01, -1.851e-01, -2.750e-01, -1.606e-01, 4.840e-02, -3.786e-02, 1.030e-01, 7.527e-03, 5.588e-02, -3.965e-02, 7.527e-02, 1.028e-01, -2.280e-01, 1.333e-01, 9.641e-02, -1.056e-01) * s0[y+2][x+1];
	r += M4(2.881e-02, -4.156e-02, -6.568e-02, -6.324e-02, 5.952e-02, -1.076e-02, -1.658e-02, -8.497e-02, -1.112e-01, -4.006e-03, 6.458e-03, -1.345e-01, 1.372e-01, -3.921e-02, -8.283e-02, 8.327e-02) * s0[y+2][x+2];
	r += M4(1.537e-01, -1.016e-01, -2.927e-02, 9.205e-02, 9.212e-02, 2.478e-01, -1.884e-01, 1.440e-02, -2.875e-02, -1.119e-02, 5.909e-01, -4.436e-02, -8.566e-02, 1.606e-01, -4.604e-01, -1.466e-01) * s1[y+0][x+0];
	r += M4(1.890e-01, -8.417e-04, 1.382e-01, 9.146e-02, -3.135e-01, -4.900e-02, -2.957e-01, -2.789e-01, -3.824e-03, -1.012e-02, 4.640e-01, 2.421e-01, -8.911e-02, -9.688e-02, 2.262e-01, -9.861e-03) * s1[y+0][x+1];
	r += M4(4.407e-02, -5.476e-02, 8.045e-02, -9.189e-02, -1.507e-01, 1.650e-01, 9.830e-02, 1.305e-02, 2.993e-02, -9.528e-02, 1.363e-01, 1.209e-01, 1.405e-01, -6.973e-02, -4.414e-02, -1.852e-01) * s1[y+0][x+2];
	r += M4(4.224e-03, -4.770e-01, 4.066e-01, -1.606e-02, -3.877e-01, -1.287e+00, 7.055e-01, 1.255e+00, -1.635e-01, 5.598e-01, 5.593e-02, -1.538e-01, 6.919e-04, -3.094e-02, -1.374e-01, 3.164e-02) * s1[y+1][x+0];
	r += M4(2.538e-01, 6.750e-02, 6.764e-02, 1.719e-01, -4.352e-01, 7.961e-01, 2.764e-01, 3.763e-01, 2.510e-01, 8.313e-02, 2.357e-01, 5.332e-01, -6.858e-01, 3.387e-01, 4.111e-01, 1.814e-01) * s1[y+1][x+1];
	r += M4(2.764e-01, 1.201e-02, -2.198e-01, -3.367e-01, -1.960e-01, -1.888e-01, -5.953e-03, -2.569e-02, 8.216e-02, 8.373e-02, 1.295e-01, 4.482e-01, 5.043e-01, -1.802e-01, -2.342e-01, -5.438e-02) * s1[y+1][x+2];
	r += M4(-1.895e-01, 1.197e-03, -1.782e-01, -1.773e-01, -6.061e-01, -8.409e-01, 9.851e-02, 1.286e-01, -1.128e-02, 1.548e-01, 1.223e-01, 6.607e-02, 2.036e-01, -5.992e-02, -4.296e-02, -1.566e-01) * s1[y+2][x+0];
	r += M4(3.350e-01, -8.658e-02, -1.909e-01, 4.407e-02, -5.446e-01, 4.124e-01, 3.076e-01, -9.927e-02, -1.553e-03, 1.036e-01, 2.509e-01, 4.422e-01, -4.302e-02, 4.036e-02, -1.821e-01, -5.316e-01) * s1[y+2][x+1];
	r += M4(4.544e-02, 1.444e-02, -1.966e-01, -3.857e-01, 6.128e-03, -1.436e-02, 5.160e-03, -3.715e-02, -3.419e-02, 1.308e-01, 7.288e-02, 1.623e-01, 1.090e-01, -5.966e-02, -1.917e-01, -1.995e-01) * s1[y+2][x+2];
	r += V4(-2.863e-02, -1.712e-02, -3.661e-02, -3.989e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv2_pt;
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}

//!DESC CuNNy-4x4C-RCAS-conv4
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv3
//!BIND LUMA
//!SAVE conv4
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-6.924e-02, -1.102e-01, -2.717e-01, 1.680e-01, -1.529e-02, 1.061e-02, -5.121e-02, 1.087e-01, 1.907e-02, -1.120e-01, -1.323e-01, 7.726e-02, 9.058e-02, -7.884e-02, -5.753e-02, -5.352e-02) * s0[y+0][x+0];
	r += M4(-3.664e-02, -1.305e-01, -3.484e-02, 6.030e-02, -6.185e-02, -8.973e-02, 4.829e-02, 1.655e-01, 2.240e-03, -1.274e-01, 3.467e-01, 4.363e-02, 2.607e-03, 1.282e-01, 5.943e-01, 1.000e-01) * s0[y+0][x+1];
	r += M4(7.005e-02, -7.957e-02, -5.557e-02, 8.431e-02, -5.581e-02, -7.824e-01, 1.406e-02, 1.146e-01, -3.959e-02, -8.921e-02, 1.248e-01, 5.442e-02, 3.650e-02, 3.609e-02, -3.580e-02, -4.841e-02) * s0[y+0][x+2];
	r += M4(-2.321e-01, 9.683e-02, -2.045e-01, 3.611e-01, 1.445e-03, -2.134e-02, 5.407e-02, -6.041e-02, -1.773e-02, -1.298e-01, 9.820e-02, -5.462e-02, 1.395e-02, -9.544e-02, -1.668e-01, 1.844e-01) * s0[y+1][x+0];
	r += M4(5.458e-01, -5.831e-01, 5.754e-01, -1.827e-01, 1.257e-01, 1.466e-02, -3.300e-02, -2.529e-01, 3.464e-01, 3.734e-01, -1.089e-01, -2.059e-01, 1.105e+00, 7.441e-01, -7.044e-01, -2.725e-01) * s0[y+1][x+1];
	r += M4(4.024e-02, -1.919e-01, 2.113e-01, -1.033e-01, 4.527e-02, -4.701e-02, 7.019e-02, -2.274e-01, 2.589e-01, 2.498e-01, -8.476e-02, -1.228e-01, -1.279e-01, 1.122e-01, -2.273e-01, 2.899e-01) * s0[y+1][x+2];
	r += M4(-7.868e-03, -1.679e-02, -4.956e-02, 1.402e-01, 1.001e-02, 1.265e-02, 4.353e-03, -2.025e-02, 4.054e-02, -6.904e-02, -6.020e-02, 1.446e-01, -1.911e-02, -1.313e-01, 7.274e-02, -1.857e-02) * s0[y+2][x+0];
	r += M4(-5.111e-02, 9.975e-02, 2.500e-02, -1.600e-01, 1.072e-02, 1.262e-02, 2.372e-02, -4.128e-02, 2.300e-01, 1.121e-02, 2.539e-02, -2.550e-02, 2.340e-01, -9.866e-02, -1.618e-01, 2.588e-01) * s0[y+2][x+1];
	r += M4(-5.599e-02, 5.766e-02, -9.155e-02, 6.949e-02, -2.086e-03, -5.601e-03, 5.333e-02, -4.541e-02, -1.834e-02, 5.066e-02, -1.959e-01, 2.765e-01, 3.992e-02, -1.890e-01, 3.303e-01, -2.253e-01) * s0[y+2][x+2];
	r += M4(-1.344e-02, -9.565e-02, -7.606e-02, 9.201e-02, -2.929e-02, -6.592e-02, -2.522e-02, 8.923e-02, -5.254e-04, -1.916e-02, 2.054e-02, -2.612e-02, -2.278e-02, 2.684e-03, -1.212e-01, 1.150e-01) * s1[y+0][x+0];
	r += M4(1.507e-02, -3.508e-01, -1.286e-01, 9.044e-02, 1.038e-02, -2.881e-01, 4.801e-02, 6.768e-02, -6.678e-03, -1.289e-02, 8.448e-03, -1.776e-02, -8.062e-02, -5.403e-02, 3.018e-02, 1.996e-01) * s1[y+0][x+1];
	r += M4(2.976e-03, -8.173e-02, 8.103e-02, 1.831e-02, 1.515e-02, -1.065e-01, 9.074e-03, 9.910e-02, -1.468e-02, -1.739e-02, -5.400e-02, -3.122e-03, 3.846e-02, 3.739e-04, 4.782e-02, -3.534e-02) * s1[y+0][x+2];
	r += M4(-2.223e-02, -1.402e-01, -1.639e-02, 1.038e-02, -8.118e-03, -4.269e-02, -2.221e-02, 1.552e-02, 3.163e-02, -5.319e-03, -4.349e-02, -3.949e-02, -9.253e-02, -4.954e-02, 1.649e-02, 1.739e-01) * s1[y+1][x+0];
	r += M4(2.315e-01, -1.322e-01, 2.396e-01, -4.280e-02, 8.108e-02, -4.024e-02, 6.663e-03, -1.317e-01, -5.142e-02, 1.402e-01, -3.550e-02, 4.792e-02, 6.016e-03, 4.248e-02, -1.462e-01, -2.944e-02) * s1[y+1][x+1];
	r += M4(7.597e-02, -5.595e-02, 1.593e-01, -2.408e-01, 2.289e-01, -3.779e-01, 2.476e-01, -1.303e-01, -7.341e-03, 2.816e-02, -1.545e-01, 6.665e-02, -5.479e-02, -5.455e-02, 4.113e-02, 5.917e-02) * s1[y+1][x+2];
	r += M4(6.274e-02, 3.068e-03, -4.046e-03, -6.419e-02, 1.321e-02, 6.557e-03, 2.667e-02, -8.658e-02, 1.986e-03, -4.333e-02, -9.048e-03, 3.851e-02, -4.242e-02, 4.245e-03, 3.187e-02, -3.270e-02) * s1[y+2][x+0];
	r += M4(-3.586e-02, 2.472e-02, 5.529e-02, -1.047e-01, 3.918e-02, -1.501e-02, 2.019e-02, -5.971e-02, 8.928e-03, 4.759e-02, -7.115e-02, 1.228e-01, -4.461e-03, -4.091e-02, 1.207e-02, 4.712e-02) * s1[y+2][x+1];
	r += M4(3.529e-02, 1.799e-02, -9.009e-02, 7.106e-02, 5.687e-02, 5.849e-02, -5.838e-02, -9.466e-02, -2.842e-01, 3.471e-03, -2.973e-01, 5.878e-01, 2.468e-02, -1.285e-02, 8.448e-02, -1.166e-01) * s1[y+2][x+2];
	r += V4(1.933e-02, -3.384e-02, 1.358e-02, -3.350e-03);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv3_pt;
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}

//!DESC CuNNy-4x4C-RCAS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv4
//!BIND LUMA
//!SAVE out
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-8.387e-02, -2.131e-02, -9.635e-03, 1.680e-02, 3.405e-03, -1.056e-02, -5.036e-04, -2.875e-04, -1.223e-02, 7.070e-03, 1.887e-02, 8.956e-03, -1.370e-01, 5.048e-02, 5.276e-02, -9.855e-03) * s0[y+0][x+0];
	r += M4(-9.239e-02, -1.509e-02, -1.543e-01, -7.641e-02, -1.197e-02, 3.196e-02, -2.988e-02, -1.919e-02, -1.222e-02, 4.619e-03, 1.201e-02, 2.180e-02, -6.167e-02, -3.550e-01, 2.152e-01, 2.112e-01) * s0[y+0][x+1];
	r += M4(-1.631e-02, -9.819e-02, 1.238e-02, -5.530e-02, 3.003e-03, -4.602e-02, 4.650e-02, 8.756e-03, 3.120e-02, -1.346e-02, -7.859e-03, -9.563e-03, -2.979e-02, -3.048e-02, -7.266e-02, -4.090e-02) * s0[y+0][x+2];
	r += M4(5.252e-02, -8.228e-02, 7.910e-02, -3.497e-02, 2.175e-02, 6.158e-03, 3.033e-02, -3.151e-02, 1.785e-02, -1.375e-02, -9.052e-04, -2.297e-02, 3.807e-03, 1.181e-01, -5.480e-01, 8.496e-02) * s0[y+1][x+0];
	r += M4(6.556e-02, 3.867e-01, 2.844e-01, 5.255e-01, -4.029e-02, -7.158e-02, 1.411e-01, 1.525e-01, 2.692e-01, 2.161e-01, 9.011e-02, 1.149e-01, 1.091e+00, 6.583e-01, 4.121e-02, -7.363e-01) * s0[y+1][x+1];
	r += M4(1.769e-02, -7.123e-02, 3.056e-03, 2.120e-02, 6.812e-02, 1.646e-01, -1.146e-01, 8.336e-03, 6.755e-02, 1.633e-01, -5.820e-02, 6.724e-03, -6.291e-02, 2.236e-01, -1.929e-01, -6.245e-02) * s0[y+1][x+2];
	r += M4(-3.329e-02, 2.229e-02, -1.533e-01, -9.945e-02, 8.269e-02, -5.729e-02, 4.334e-02, -3.699e-02, 9.506e-03, -7.284e-03, -4.178e-02, -1.561e-02, -1.284e-01, -7.656e-03, -5.559e-02, 4.425e-03) * s0[y+2][x+0];
	r += M4(-5.642e-02, -1.260e-02, -2.278e-01, -7.196e-02, -2.396e-01, 1.267e-01, -4.321e-01, -1.127e-01, -2.565e-01, 4.796e-02, -1.105e-01, 5.290e-03, -2.998e-01, -2.039e-01, 1.552e-01, 1.941e-01) * s0[y+2][x+1];
	r += M4(2.232e-02, 8.282e-04, 7.149e-04, -1.237e-01, 1.659e-02, -1.523e-01, 1.538e-01, -4.543e-02, 3.402e-02, -2.261e-01, 1.626e-01, -3.517e-02, -2.760e-02, -2.046e-01, 3.871e-02, -6.946e-02) * s0[y+2][x+2];
	r += M4(3.977e-01, -3.787e-01, 7.043e-03, -2.499e-01, 1.112e-02, -2.155e-02, -1.467e-04, -1.971e-02, -9.633e-02, 4.940e-02, 6.396e-02, 5.480e-03, -2.048e-02, 2.345e-02, 3.706e-02, 1.425e-02) * s1[y+0][x+0];
	r += M4(-6.475e-01, 1.490e-01, -1.271e-01, -2.794e-01, -4.405e-02, -2.301e-02, -2.847e-02, -2.834e-03, -1.597e-01, -1.137e-01, 7.458e-03, 1.653e-01, -3.083e-02, -8.203e-03, -3.042e-02, 5.338e-02) * s1[y+0][x+1];
	r += M4(5.137e-02, -6.862e-02, -1.161e-02, 1.440e-01, 4.016e-03, -3.293e-02, 2.887e-02, 6.229e-03, 2.009e-02, -9.265e-02, -1.374e-02, -1.450e-02, 3.968e-02, -1.477e-02, 1.275e-02, -3.586e-02) * s1[y+0][x+2];
	r += M4(-2.999e-01, -1.098e-01, 3.977e-01, -3.487e-01, -8.723e-02, -1.132e-02, -6.202e-02, -5.033e-02, 1.204e-01, 6.477e-03, -2.134e-01, 4.162e-03, -8.528e-03, -5.922e-02, -2.519e-02, -2.224e-02) * s1[y+1][x+0];
	r += M4(1.909e-01, 4.873e-01, -3.377e-01, 1.223e+00, -1.442e-01, -1.354e-01, 3.590e-02, -2.872e-02, 2.174e-01, 6.991e-01, 6.825e-02, 1.736e-01, 2.381e-01, 2.725e-01, 1.365e-01, 1.506e-01) * s1[y+1][x+1];
	r += M4(2.297e-01, 3.140e-03, 1.479e-01, -1.499e-01, 1.311e-01, 3.533e-02, -3.877e-02, 1.923e-02, 1.919e-01, 5.614e-02, -6.611e-02, -1.748e-01, -1.729e-02, 5.576e-02, -2.717e-02, 5.152e-02) * s1[y+1][x+2];
	r += M4(-1.816e-02, 6.707e-02, -3.680e-01, 6.695e-02, 6.915e-03, -2.391e-02, -1.086e-02, 1.096e-02, 8.983e-03, -2.547e-02, -7.335e-02, -2.920e-02, 2.394e-02, -5.119e-04, -6.319e-02, -6.977e-02) * s1[y+2][x+0];
	r += M4(-1.788e-02, -1.220e-02, -8.394e-02, -2.649e-01, -3.115e-01, 1.943e-02, -5.145e-01, -1.713e-01, -1.735e-01, 1.867e-01, -5.332e-01, -5.440e-02, -1.890e-01, 4.919e-02, -1.025e-01, 3.414e-02) * s1[y+2][x+1];
	r += M4(-7.644e-02, -1.310e-01, 2.269e-02, -1.695e-01, 4.358e-02, -1.715e-01, 1.735e-01, -1.664e-01, -1.521e-02, -1.549e-01, 1.821e-01, -1.605e-01, 3.616e-02, -1.290e-01, 4.708e-02, -7.714e-02) * s1[y+2][x+2];
	r += V4(2.357e-03, 1.140e-04, 2.883e-03, 2.795e-04);
	return tanh(vec4(r));
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv4_pt;
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}

//!DESC CuNNy-4x4C-RCAS-shuffle
//!HOOK LUMA
//!BIND out
//!BIND rcas
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
vec4 hook() {
	vec4 r = vec4(0.0);
	vec2 f = fract(out_pos * out_size);
	ivec2 i = ivec2(f * vec2(2.0));
	r.r = out_tex((vec2(0.5) - f) * out_pt + out_pos)[2*i.y + i.x];
	r.r += rcas_tex(rcas_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

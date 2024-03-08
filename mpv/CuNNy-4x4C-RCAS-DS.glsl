// CuNNy 4x4C RCAS DS
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


//!DESC CuNNy-4x4C-RCAS-DS-in
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
	r += V4(-2.389e-02, -1.580e-03, -4.606e-02, 1.605e-02) * s0[y+0][x+0];
	r += V4(-7.374e-03, -4.711e-02, -6.018e-02, 9.369e-03) * s0[y+0][x+1];
	r += V4(1.912e-02, -9.554e-02, 1.034e-02, -6.888e-04) * s0[y+0][x+2];
	r += V4(7.541e-02, 4.443e-02, 4.853e-02, -2.338e-02) * s0[y+1][x+0];
	r += V4(-4.148e-01, -7.480e-01, 5.653e-01, -8.453e-03) * s0[y+1][x+1];
	r += V4(-4.146e-01, 8.274e-01, -7.770e-02, -1.480e-03) * s0[y+1][x+2];
	r += V4(-5.846e-02, -2.323e-02, -6.121e-02, -5.815e-01) * s0[y+2][x+0];
	r += V4(5.293e-01, 8.214e-02, 1.395e-03, -2.918e-04) * s0[y+2][x+1];
	r += V4(2.866e-01, -3.266e-02, -3.432e-02, 1.077e-02) * s0[y+2][x+2];
	r += V4(1.279e-03, -5.182e-03, -8.739e-03, 8.560e-03);
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

//!DESC CuNNy-4x4C-RCAS-DS-conv1
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
	r += M4(5.891e-02, -1.157e-01, -2.764e-01, -2.251e-01, -1.011e-03, 1.114e-01, 8.300e-02, 3.749e-01, 1.850e-02, -1.001e-01, -3.545e-01, 9.359e-02, 1.090e+00, -1.362e-01, 1.076e+00, 1.548e-01) * s0[y+0][x+0];
	r += M4(-1.786e-01, 3.398e-01, 3.991e-01, -4.077e-01, 8.415e-02, 1.587e-01, 1.866e-01, -8.561e-02, -4.569e-02, -2.781e-02, 7.355e-02, 1.583e-01, 3.198e-01, 1.003e+00, -1.901e+00, -2.792e+00) * s0[y+0][x+1];
	r += M4(1.411e-02, 7.646e-02, 5.270e-02, -1.289e-02, 8.869e-03, 3.955e-02, 5.477e-02, -1.121e-01, -1.716e-01, 1.079e-01, 1.318e-01, 1.427e-02, -2.836e+00, -2.565e+00, -2.020e+00, 4.970e-01) * s0[y+0][x+2];
	r += M4(1.523e-01, 4.298e-01, -4.257e-01, -1.530e-01, -8.309e-02, 6.206e-02, 5.873e-01, -4.294e-01, 7.679e-02, 1.112e-02, -1.590e-02, 1.099e-01, 3.824e-01, 4.007e-01, -1.583e-01, 8.894e-02) * s0[y+1][x+0];
	r += M4(5.109e-01, 4.628e-02, -3.270e-01, -1.933e-01, 4.687e-01, 5.139e-01, 5.615e-01, -1.241e+00, -3.061e-01, 6.294e-02, 3.068e-01, 8.754e-02, -2.101e-01, 3.615e+00, -1.625e+00, -2.333e+00) * s0[y+1][x+1];
	r += M4(-7.070e-02, -2.611e-01, 2.051e-01, 9.248e-03, -1.106e-01, -1.917e-01, -1.797e-02, 2.476e-01, -4.631e-01, -2.259e-02, 3.328e-01, -4.001e-01, -1.264e+01, 8.732e+00, -1.847e+00, -3.157e+00) * s0[y+1][x+2];
	r += M4(-1.035e-01, -6.117e-02, 4.342e-02, 5.465e-02, 1.236e-01, 6.356e-01, -2.756e-01, -2.205e-01, 1.802e-01, -8.409e-03, -1.068e-01, 2.549e-01, 6.471e-01, -1.600e+00, -7.252e-01, -8.938e-01) * s0[y+2][x+0];
	r += M4(-3.003e-01, -6.095e-02, -1.434e-01, 1.929e-01, -6.035e-01, 3.223e-01, -2.934e-01, -2.259e-01, 1.915e-01, -1.220e-01, 1.643e-02, -2.629e-01, -1.566e+00, 2.299e+00, -2.467e-01, 4.239e-01) * s0[y+2][x+1];
	r += M4(-1.303e-01, -1.150e-01, 1.027e-01, 1.254e-01, 1.023e-01, -5.846e-02, 1.948e-01, 4.232e-01, -1.026e-02, -1.065e-04, -9.905e-02, -8.898e-02, -5.172e+00, 2.382e+00, 2.251e+00, 1.113e+00) * s0[y+2][x+2];
	r += M4(-7.941e-02, -2.379e-01, -4.645e-01, 3.151e-02, -2.351e-02, -3.765e-02, 4.418e-03, 3.143e-01, -5.706e-03, -5.598e-01, -7.858e-01, 4.748e-01, -1.476e-02, 4.470e-02, 9.018e-02, -5.342e-02) * s1[y+0][x+0];
	r += M4(-2.065e-01, -3.079e-01, -4.936e-01, -2.387e-01, -1.470e-01, -3.575e-01, -2.320e-01, 5.918e-01, 1.234e-01, -1.515e-01, 1.074e-01, 4.071e-02, 1.455e-01, 1.196e-01, 1.015e-01, 1.399e-01) * s1[y+0][x+1];
	r += M4(6.996e-02, 5.694e-02, 1.047e-01, -7.735e-02, -3.846e-02, 6.869e-02, 3.414e-02, -1.415e-01, -3.044e-01, 2.032e-01, -8.667e-02, 8.929e-01, -1.547e-01, -9.372e-02, -2.434e-01, 1.127e-01) * s1[y+0][x+2];
	r += M4(1.067e-01, -5.280e-01, -3.400e-01, 4.485e-02, -4.646e-02, -7.553e-01, 9.008e-02, 2.941e-01, -3.355e-01, -2.921e-01, -7.064e-02, 7.938e-01, -9.914e-02, 9.227e-02, -6.904e-02, 8.818e-02) * s1[y+1][x+0];
	r += M4(3.602e-01, -2.650e-01, -6.816e-01, 3.637e-01, 1.067e-01, -3.141e-01, -2.541e-01, 2.303e-01, 8.627e-01, -7.075e-02, 3.777e-01, -1.838e+00, 5.655e-02, 2.156e-01, 6.323e-02, 2.196e-02) * s1[y+1][x+1];
	r += M4(-1.636e-01, -2.104e-01, 2.260e-01, -5.722e-01, -7.787e-02, 3.109e-02, 1.671e-01, -4.268e-01, 9.108e-02, 5.043e-01, 9.765e-01, -6.695e-01, -3.512e-01, 1.609e-01, -1.201e-01, 2.116e-01) * s1[y+1][x+2];
	r += M4(1.883e-01, 4.117e-01, 1.792e-01, -1.585e-01, 9.252e-01, -3.758e-01, 3.400e-02, -7.619e-03, -4.356e-01, 8.043e-02, -2.868e-01, 3.159e-02, -1.197e-02, -6.980e-02, 7.836e-02, -1.739e-02) * s1[y+2][x+0];
	r += M4(-1.835e-02, 5.468e-01, -5.627e-02, -6.162e-02, -3.866e-01, 1.043e+00, -1.360e-01, -2.978e-01, 2.540e+00, -2.698e+00, 1.444e-01, 1.558e-01, 6.884e-02, 5.416e-02, 1.035e-02, 5.123e-02) * s1[y+2][x+1];
	r += M4(-1.014e-01, 1.179e-01, 4.042e-02, -1.618e-01, 1.462e-02, -4.243e-02, -1.375e-01, 1.039e-01, 6.024e-01, -1.571e-01, -1.610e-01, -7.205e-01, 2.197e-02, 1.048e-01, 1.535e-01, 1.288e-01) * s1[y+2][x+2];
	r += V4(-1.168e-02, 1.436e-01, -1.153e-02, 3.571e-01);
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

//!DESC CuNNy-4x4C-RCAS-DS-conv2
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
	r += M4(-2.066e-01, -9.454e-02, -3.559e-01, -1.814e-01, 9.158e-02, -2.769e-02, 3.033e-02, 4.229e-02, -1.107e-01, 6.676e-02, 2.440e-02, -1.565e-01, 1.181e-02, -2.591e-02, 5.823e-02, -2.237e-01) * s0[y+0][x+0];
	r += M4(1.122e-01, 6.754e-02, 8.998e-02, -5.291e-02, -1.244e-01, -1.616e-01, -4.707e-02, 1.210e-01, 2.399e-01, 1.431e-01, 9.937e-02, -1.390e-02, 4.377e-02, -5.472e-02, 1.318e-01, -6.759e-02) * s0[y+0][x+1];
	r += M4(-1.120e-03, 3.625e-02, -1.010e-01, 1.265e-01, 5.048e-02, 2.885e-02, -4.350e-02, 1.162e-02, -3.124e-02, 3.718e-03, -6.572e-02, 6.213e-02, -4.282e-03, 1.200e-02, -5.563e-02, 3.419e-02) * s0[y+0][x+2];
	r += M4(-1.518e-01, -8.522e-02, -4.989e-01, -5.507e-01, 2.237e-01, -2.144e-01, -3.322e-02, 8.890e-02, -1.272e-01, 2.128e-01, -2.448e-01, -1.934e-01, 1.515e-01, -2.542e-01, -3.608e-01, 1.599e-01) * s0[y+1][x+0];
	r += M4(-6.240e-01, 2.799e-01, -9.977e-01, 2.784e-01, 4.723e-02, -3.681e-01, -1.933e-01, -1.453e-01, 1.082e-01, 3.535e-02, 4.627e-01, -1.981e-01, -3.200e-01, -1.093e-01, 5.733e-02, -3.291e-01) * s0[y+1][x+1];
	r += M4(1.196e-01, -6.475e-02, -1.589e-01, 2.047e-01, 1.870e-01, -1.788e-01, -1.313e-01, 1.307e-01, -1.091e-01, 1.319e-01, -3.428e-01, 7.095e-02, 9.572e-02, 7.967e-03, -1.248e-01, -2.049e-02) * s0[y+1][x+2];
	r += M4(-2.222e-01, -1.120e-01, 3.034e-02, 3.018e-03, -7.394e-02, -9.920e-02, 4.743e-02, -1.519e-01, -1.834e-01, 1.129e-02, -5.967e-02, 3.106e-02, -2.522e-02, -3.292e-01, 3.446e-02, 7.424e-02) * s0[y+2][x+0];
	r += M4(-2.227e-01, -1.670e-01, 1.333e-01, 2.822e-01, -2.101e-01, -1.947e-01, 5.936e-02, -2.785e-02, -1.721e-01, 7.927e-02, -1.163e-01, -2.542e-02, 2.419e-01, -2.855e-01, 1.412e-01, 1.766e-01) * s0[y+2][x+1];
	r += M4(-2.609e-01, -4.193e-02, 5.821e-02, -8.583e-02, 4.473e-02, -1.023e-01, 1.875e-02, 5.959e-02, 1.953e-01, 2.846e-02, -1.656e-01, -2.810e-03, -5.184e-02, -9.303e-02, 2.168e-01, 1.709e-02) * s0[y+2][x+2];
	r += M4(-2.281e-01, -1.155e-01, -6.231e-02, -4.098e-01, 1.461e-01, -2.907e-02, 1.025e-01, 8.564e-02, -5.764e-02, 4.866e-02, -1.947e-02, 2.664e-01, -6.142e-02, 2.851e-03, -6.658e-02, -1.788e-01) * s1[y+0][x+0];
	r += M4(-6.755e-02, -8.443e-02, 5.128e-01, -8.056e-01, -2.329e-01, -1.681e-01, -1.314e-01, -1.249e-02, 7.306e-02, 1.317e-01, -1.134e-01, 4.040e-01, 7.649e-02, -2.642e-02, 7.985e-02, -4.233e-02) * s1[y+0][x+1];
	r += M4(3.141e-01, -1.532e-02, -1.692e-01, 4.383e-02, 3.498e-02, -3.248e-03, -2.863e-01, 4.075e-02, -1.670e-01, 4.407e-03, 4.651e-02, 1.269e-02, 4.500e-03, 4.065e-03, -1.341e-01, 9.606e-02) * s1[y+0][x+2];
	r += M4(-2.733e-01, -1.841e-01, -1.675e-01, -4.502e-01, 2.647e-01, -1.968e-01, 3.564e-02, 1.797e-01, 1.334e-01, 2.739e-01, -2.833e-01, -7.194e-02, -4.508e-02, -2.174e-01, -3.625e-01, 2.641e-04) * s1[y+1][x+0];
	r += M4(-7.942e-01, 3.429e-01, -4.532e-01, -7.072e-02, -5.527e-01, -3.621e-01, -2.517e-01, -3.873e-01, -3.311e-01, 1.340e-01, -2.712e-01, -1.353e-01, -4.601e-01, -1.195e-01, 1.048e-01, -5.432e-01) * s1[y+1][x+1];
	r += M4(2.988e-01, -1.659e-01, 6.121e-02, 1.915e-01, 4.053e-02, -1.587e-01, -8.617e-02, 5.067e-02, 4.045e-02, 2.043e-01, -6.777e-01, 1.621e-01, 1.733e-01, 7.220e-04, -2.736e-01, 6.762e-02) * s1[y+1][x+2];
	r += M4(-7.441e-02, -6.371e-02, 4.740e-03, -1.546e-02, -4.067e-02, -8.772e-02, 4.043e-02, -3.276e-02, -4.716e-01, 4.904e-01, 3.992e-01, 1.499e-01, -2.907e-01, -3.426e-01, 8.834e-02, 1.191e-01) * s1[y+2][x+0];
	r += M4(-2.046e-01, -2.005e-01, 1.202e-01, 1.272e-01, 8.692e-02, -1.685e-01, 1.033e-01, 1.831e-01, -3.453e-01, 6.087e-01, 7.031e-02, -2.716e-01, 2.500e-01, -2.739e-01, 1.164e-01, 2.222e-01) * s1[y+2][x+1];
	r += M4(3.158e-02, -6.730e-02, 4.536e-03, 8.470e-02, -8.849e-02, -9.181e-02, 4.441e-02, -3.267e-02, 9.719e-02, 1.353e-01, -2.095e-01, 1.294e-01, -1.328e-01, -1.184e-01, 1.694e-01, -8.188e-03) * s1[y+2][x+2];
	r += V4(-6.569e-03, -3.900e-01, 2.080e-03, 2.128e-03);
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

//!DESC CuNNy-4x4C-RCAS-DS-conv3
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
	r += M4(-2.379e-01, -1.824e-01, -5.006e-02, 7.414e-02, 1.513e+00, 2.801e-01, 7.597e-03, -1.012e+00, 2.625e-02, -3.254e-02, -8.968e-02, 1.554e-01, 1.653e-01, 2.110e-01, -3.654e-02, -4.619e-02) * s0[y+0][x+0];
	r += M4(-6.541e-01, 5.186e-02, -3.753e-02, -2.376e-01, -3.273e-01, 9.795e-01, 7.297e-01, -4.568e+00, 2.660e-01, -9.689e-02, -1.446e-01, 3.827e-01, 3.135e-01, 3.906e-02, -2.881e-01, 9.963e-02) * s0[y+0][x+1];
	r += M4(-1.333e-01, 5.920e-02, -6.018e-02, -3.402e-02, -3.015e-01, -4.943e-02, 1.508e-01, 1.171e+00, 6.499e-02, -5.673e-02, -4.344e-02, 1.076e-01, 8.731e-02, 1.121e-01, -7.652e-03, -3.800e-01) * s0[y+0][x+2];
	r += M4(3.238e-02, 1.210e-01, -1.111e-01, 3.677e-02, 1.534e+00, -7.515e-01, -2.300e-01, -1.198e-01, -6.402e-02, 1.802e-01, 2.937e-02, -2.147e-01, -1.363e-02, -5.387e-02, 7.457e-02, 1.753e-02) * s0[y+1][x+0];
	r += M4(-1.320e-01, -3.185e-01, 1.080e-01, 2.642e-02, 1.204e+00, 3.515e-01, -2.461e+00, -1.032e+00, 8.472e-02, -4.811e-02, -3.968e-02, -5.245e-01, -4.227e-01, 5.767e-01, 4.522e-02, -8.529e-02) * s0[y+1][x+1];
	r += M4(4.421e-02, -2.738e-03, 7.968e-03, 3.699e-02, -1.742e-01, -1.603e+00, 1.278e-01, 2.201e-01, -4.937e-02, -6.310e-02, 1.636e-01, 2.569e-01, 1.743e-01, 4.458e-01, -9.934e-02, -5.701e-03) * s0[y+1][x+2];
	r += M4(-1.084e-01, -8.197e-03, 5.549e-02, 1.070e-02, 1.230e-02, -1.009e+00, 2.102e-02, -5.089e-02, 1.300e-02, 1.377e-01, 2.247e-02, -2.096e-01, 1.382e-01, 5.825e-02, -6.829e-02, -4.551e-02) * s0[y+2][x+0];
	r += M4(-2.518e-02, 3.748e-02, 2.788e-02, -4.042e-02, 2.402e-01, -3.066e-01, -2.177e-01, 1.024e-01, 3.381e-02, 3.498e-01, -2.213e-01, -2.989e-01, 6.435e-02, 2.776e-02, 1.778e-02, 9.955e-02) * s0[y+2][x+1];
	r += M4(8.067e-02, 2.381e-02, -2.553e-02, 2.718e-02, 2.728e-01, -2.362e-01, -3.226e-01, 2.492e-01, 5.110e-02, -5.940e-02, 6.188e-02, 1.352e-01, -3.690e-02, 1.918e-01, 3.378e-02, -3.242e-02) * s0[y+2][x+2];
	r += M4(8.755e-02, 2.447e-02, -2.073e-01, -4.046e-02, -7.198e-02, -6.227e-02, -1.741e-02, -7.642e-02, 5.161e-02, 1.258e-01, -4.309e-02, -1.372e-01, 3.140e-01, 1.514e-01, 8.715e-02, -7.487e-02) * s1[y+0][x+0];
	r += M4(-3.041e-01, 1.919e-01, -2.109e-01, -4.053e-01, 1.286e-02, 1.409e-01, 7.584e-02, -8.703e-02, 7.599e-02, -4.334e-02, -1.587e-01, 2.746e-01, 3.407e-02, -7.044e-02, -5.607e-02, 3.996e-02) * s1[y+0][x+1];
	r += M4(-4.438e-02, 6.807e-02, -1.013e-01, -6.672e-02, 4.578e-02, -7.765e-02, -4.474e-02, 1.728e-01, 9.412e-03, -3.294e-02, -2.285e-03, -6.152e-02, -7.808e-03, -2.304e-02, 5.455e-03, -1.887e-01) * s1[y+0][x+2];
	r += M4(4.805e-01, 5.449e-01, -2.067e-01, -2.402e-01, 3.681e-02, 2.263e-02, -3.362e-03, 1.105e-01, -1.520e-01, 6.682e-02, 2.476e-01, -1.265e-01, -1.830e-01, -4.483e-01, 2.952e-01, 1.509e-01) * s1[y+1][x+0];
	r += M4(-3.135e-01, 1.295e-01, 3.148e-02, -1.721e-01, 7.563e-02, -6.419e-02, -1.144e-01, 5.603e-02, -1.503e-01, -2.075e-01, 2.748e-01, -1.892e-02, -4.346e-01, 9.581e-02, 3.135e-01, 3.172e-01) * s1[y+1][x+1];
	r += M4(1.526e-01, 1.219e-01, -2.057e-01, -8.567e-02, -1.020e-01, -1.184e-01, 8.296e-02, -1.132e-01, -5.007e-04, 1.188e-03, 4.160e-02, 1.567e-01, 2.309e-01, 1.708e-02, -3.913e-02, 1.897e-01) * s1[y+1][x+2];
	r += M4(-4.182e-02, 1.180e-02, 1.669e-01, 2.559e-02, -2.556e-02, -2.093e-02, 5.393e-02, 8.461e-03, -1.284e-01, -2.840e-02, 1.633e-01, -1.283e-01, 1.405e-01, -1.192e-01, -4.692e-02, 3.332e-02) * s1[y+2][x+0];
	r += M4(-1.067e-01, 2.775e-01, 4.333e-02, -7.172e-02, 1.913e-03, 1.351e-01, -5.356e-03, -1.086e-01, -2.192e-01, 3.163e-01, -9.861e-02, -1.520e-01, -6.315e-02, -1.727e-01, 3.945e-02, 1.246e-01) * s1[y+2][x+1];
	r += M4(1.652e-01, 8.323e-02, -1.567e-01, -3.308e-02, -1.085e-02, 6.005e-02, -1.618e-02, 1.908e-02, 5.376e-02, -1.703e-02, 6.552e-04, -9.105e-03, 5.570e-02, -8.892e-03, -3.418e-02, -4.196e-03) * s1[y+2][x+2];
	r += V4(-2.557e-02, 6.454e-02, 1.765e-02, -3.449e-02);
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

//!DESC CuNNy-4x4C-RCAS-DS-conv4
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
	r += M4(-3.380e-02, 3.945e-02, 1.062e-01, 6.711e-02, 2.142e-02, -3.455e-02, -1.167e-01, 9.181e-02, 6.316e-02, -1.019e-01, -9.625e-02, 1.195e-02, -9.438e-02, -4.334e-02, 2.458e-02, 8.945e-02) * s0[y+0][x+0];
	r += M4(-2.896e-02, -3.157e-02, -8.523e-02, 3.351e-01, 3.173e-02, -1.078e-01, -1.914e-01, 1.558e-01, -7.373e-02, 8.219e-02, 1.333e-01, -2.845e-01, 2.369e-02, -6.637e-03, 3.073e-02, 2.508e-01) * s0[y+0][x+1];
	r += M4(5.301e-02, -3.135e-02, -2.670e-02, 1.435e-01, 8.620e-03, 1.870e-02, -1.001e-01, -1.258e-01, 1.169e-02, 2.077e-02, 1.392e-02, -8.192e-02, -3.388e-02, -3.513e-03, -1.284e-01, -9.009e-02) * s0[y+0][x+2];
	r += M4(8.718e-02, -4.639e-01, -3.383e-02, -4.852e-02, -1.294e-01, -4.016e-02, -1.504e-01, -8.815e-02, 1.666e-01, -1.953e-01, -1.222e-01, 1.862e-02, 1.658e-03, -4.464e-01, -1.502e-01, -1.237e-01) * s0[y+1][x+0];
	r += M4(-7.158e-02, 1.919e-01, 3.972e-01, 1.871e-01, 2.282e-01, -1.183e-01, -1.050e-01, -2.121e-02, -1.344e-01, 1.880e-01, -2.040e-01, -4.138e-02, 5.942e-01, -4.517e-01, -8.585e-01, 5.319e-02) * s0[y+1][x+1];
	r += M4(4.674e-02, 8.383e-04, -5.860e-02, -1.079e-02, -1.072e-01, 6.642e-02, 7.980e-03, 7.578e-02, -1.401e-01, 3.603e-03, -4.779e-02, 2.126e-01, -4.780e-02, 1.276e-02, 2.833e-02, 1.187e-01) * s0[y+1][x+2];
	r += M4(9.328e-02, -1.574e-01, 2.401e-02, -8.590e-02, -2.636e-02, -6.050e-03, -4.071e-02, 1.395e-02, -1.841e-01, 3.154e-01, -2.203e-01, 2.044e-02, -1.377e-01, 3.190e-01, 3.893e-02, -5.362e-02) * s0[y+2][x+0];
	r += M4(3.213e-01, -1.014e-01, 5.306e-02, 1.390e-02, 9.330e-02, 5.710e-02, -1.329e-02, -1.557e-02, -1.337e-01, 1.550e-01, -4.583e-02, -2.358e-01, 3.272e-01, 8.330e-02, -7.388e-02, -1.587e-01) * s0[y+2][x+1];
	r += M4(5.321e-02, -9.108e-03, 1.270e-02, -6.902e-03, 2.236e-02, -3.716e-02, -2.889e-02, -1.586e-02, 4.417e-02, -1.220e-01, -2.251e-02, -1.140e-01, -1.279e-02, 4.164e-02, 8.984e-03, 1.807e-02) * s0[y+2][x+2];
	r += M4(1.313e-02, -1.569e-03, 8.291e-02, -9.483e-03, 1.161e-01, -2.929e-01, -9.452e-02, 1.921e-01, 8.653e-03, -2.272e-02, -7.372e-02, 1.144e-01, 1.621e-02, -2.441e-02, -1.048e-01, 1.202e-01) * s1[y+0][x+0];
	r += M4(2.332e-02, -4.505e-02, -1.306e-02, 7.451e-02, 2.958e-01, -3.345e-01, -2.744e-01, 6.140e-01, 4.935e-02, 4.708e-02, -7.398e-02, -3.366e-01, -1.763e-02, -2.170e-02, -8.828e-02, 1.336e-01) * s1[y+0][x+1];
	r += M4(3.161e-02, -8.786e-03, -2.303e-02, 1.113e-01, -3.516e-03, -1.002e-02, -1.660e-02, -3.234e-03, -8.502e-03, -2.252e-02, -5.491e-02, -5.726e-02, -5.409e-03, 1.295e-03, -4.182e-02, -1.777e-02) * s1[y+0][x+2];
	r += M4(9.133e-03, -1.110e-01, 3.961e-02, -7.615e-03, 1.453e-01, -5.423e-01, -2.397e-01, 3.600e-02, 8.120e-02, -1.121e-01, -1.105e-01, -2.426e-02, -6.637e-02, -1.396e-01, -1.451e-01, -3.897e-02) * s1[y+1][x+0];
	r += M4(-3.137e-02, 3.353e-02, 1.328e-01, 1.838e-02, 3.642e-01, -2.507e-01, -1.320e-01, -4.958e-02, -5.615e-02, 1.949e-01, 2.299e-01, 5.428e-02, 2.124e-01, -2.200e-01, -2.753e-01, 1.257e-02) * s1[y+1][x+1];
	r += M4(1.013e-01, -7.005e-02, -2.453e-02, 1.182e-01, 5.961e-02, -2.162e-03, -6.139e-02, 5.343e-02, -1.468e-01, -2.649e-02, -4.941e-02, 1.592e-01, -3.041e-02, 3.372e-02, 2.767e-03, -5.667e-02) * s1[y+1][x+2];
	r += M4(-4.799e-02, 3.597e-02, -3.397e-02, 6.897e-03, 1.914e-02, 8.451e-02, -1.134e-02, 1.652e-02, -1.701e-02, 5.139e-02, -7.108e-02, -9.127e-03, -4.308e-03, -3.867e-02, 2.040e-02, -7.710e-03) * s1[y+2][x+0];
	r += M4(9.638e-02, 1.392e-02, 2.912e-02, -3.386e-02, 1.832e-01, 4.017e-02, 4.674e-02, -4.930e-02, 4.714e-02, -6.665e-02, -2.732e-02, -4.534e-02, 7.346e-02, 1.003e-01, -3.678e-02, 1.266e-02) * s1[y+2][x+1];
	r += M4(1.387e-01, -5.921e-02, 5.478e-03, -8.493e-03, 1.818e-01, -1.916e-02, 2.102e-02, 9.741e-03, 6.211e-02, -1.265e-01, -2.813e-02, -5.322e-03, -2.857e-02, 4.379e-02, -2.433e-02, 3.063e-03) * s1[y+2][x+2];
	r += V4(-3.528e-03, 1.209e-02, -2.564e-02, -1.286e-02);
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

//!DESC CuNNy-4x4C-RCAS-DS-out
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
	r += M4(1.871e-01, -1.135e-01, 3.807e-02, -1.291e-01, -3.037e-02, 5.115e-02, -3.771e-02, 3.033e-02, -2.445e-02, -2.102e-02, -7.082e-03, -1.384e-02, -3.045e-02, 1.225e-02, 4.309e-03, 2.041e-02) * s0[y+0][x+0];
	r += M4(-6.062e-01, 4.494e-01, 3.495e-02, 5.530e-01, 1.996e-01, -9.046e-02, 1.138e-01, -9.499e-02, 1.247e-01, 1.470e-01, -1.347e-01, -4.581e-02, 2.245e-02, -1.587e-02, 4.457e-02, -1.368e-03) * s0[y+0][x+1];
	r += M4(2.290e-01, -1.766e-01, 1.968e-01, 8.794e-02, 1.115e-01, 3.234e-01, -3.105e-03, 1.483e-01, 5.875e-02, 1.225e-01, 5.910e-02, 3.424e-02, 3.276e-02, 4.200e-02, -1.804e-02, 2.344e-02) * s0[y+0][x+2];
	r += M4(4.099e-02, -3.289e-02, 6.372e-02, -4.300e-02, -6.279e-03, -2.330e-02, 1.654e-02, 2.157e-02, -3.041e-02, 2.970e-02, -8.173e-02, -2.361e-02, -8.569e-02, 4.193e-02, -1.724e-01, -2.739e-03) * s0[y+1][x+0];
	r += M4(1.115e-01, 1.812e-01, -6.534e-01, -7.053e-02, -4.374e-02, 3.186e-02, -3.155e-02, -4.538e-02, 1.288e-01, -2.488e-01, 5.336e-01, 1.666e-01, 5.097e-01, 2.813e-01, 1.147e-01, -3.174e-03) * s0[y+1][x+1];
	r += M4(3.712e-02, 1.575e-01, 6.628e-02, -1.806e-01, -4.682e-02, -8.364e-02, 8.268e-02, 8.811e-02, 2.727e-01, 4.742e-01, 1.906e-01, 4.709e-01, -9.673e-02, 9.860e-03, -6.766e-02, -1.293e-01) * s0[y+1][x+2];
	r += M4(1.292e-02, 1.583e-02, 4.698e-02, -2.131e-02, -3.215e-03, 5.451e-03, -3.926e-03, -5.883e-04, 2.983e-02, -3.033e-02, 1.105e-01, 2.704e-02, -1.337e-01, -1.827e-02, 2.107e-02, 8.275e-02) * s0[y+2][x+0];
	r += M4(-7.758e-02, -4.237e-02, 4.518e-03, 6.534e-02, -2.014e-02, -3.669e-02, 4.307e-02, 2.093e-02, -7.858e-02, 7.785e-02, -2.559e-01, -1.285e-01, -2.339e-01, -3.545e-01, 2.993e-01, 4.897e-02) * s0[y+2][x+1];
	r += M4(3.518e-03, -2.520e-02, -2.327e-02, 5.176e-03, -2.107e-02, -2.684e-02, -5.390e-02, -4.086e-02, -2.003e-02, -3.193e-02, 4.084e-02, 8.457e-03, -8.750e-02, -1.324e-01, -1.066e-02, 1.468e-01) * s0[y+2][x+2];
	r += M4(1.296e-02, 3.186e-03, 6.471e-03, -4.831e-02, 3.175e-02, -6.090e-03, -7.376e-03, -3.928e-02, -3.829e-03, -7.836e-03, -5.573e-03, -1.628e-02, 1.965e-03, -4.649e-02, -1.919e-02, -2.308e-02) * s1[y+0][x+0];
	r += M4(7.233e-03, 9.703e-02, 8.338e-02, 7.115e-02, -9.405e-02, -7.903e-03, -8.508e-02, 9.839e-02, 3.444e-02, 1.059e-01, -4.571e-02, 2.709e-02, 5.061e-02, 8.230e-02, -1.498e-04, -2.161e-02) * s1[y+0][x+1];
	r += M4(1.089e-01, 4.237e-02, 5.550e-02, 1.294e-01, 2.550e-01, 4.763e-01, 8.711e-03, 1.099e-02, -2.213e-02, -8.231e-02, 3.000e-02, -2.814e-02, 7.745e-03, 1.460e-02, 8.974e-03, 2.996e-02) * s1[y+0][x+2];
	r += M4(2.764e-03, -1.224e-02, 1.594e-02, 4.090e-02, -4.118e-02, -2.522e-02, 4.170e-02, 1.146e-02, -5.333e-02, 2.498e-02, -7.690e-02, -5.235e-03, -8.862e-02, 2.268e-02, -3.640e-02, -4.538e-02) * s1[y+1][x+0];
	r += M4(-4.586e-02, -6.705e-03, -1.867e-01, -1.287e-02, -7.788e-02, -5.554e-02, 6.810e-02, -1.057e-01, 7.983e-02, -1.513e-01, 2.642e-01, 6.429e-02, 3.800e-01, 1.615e-02, 2.059e-01, 1.981e-01) * s1[y+1][x+1];
	r += M4(5.418e-02, -1.703e-02, 4.488e-02, -1.918e-01, -3.975e-01, -1.996e-01, 1.412e-01, 5.779e-01, 8.814e-02, 1.942e-01, 1.348e-02, 1.247e-01, -1.700e-01, 1.003e-01, -1.300e-01, -9.451e-02) * s1[y+1][x+2];
	r += M4(5.709e-03, -3.966e-03, 2.228e-02, -2.081e-03, 1.452e-02, 9.084e-03, -3.362e-02, -2.395e-03, 2.601e-02, -3.187e-03, 6.422e-02, 4.382e-02, 3.355e-02, 1.728e-02, -4.913e-03, 5.210e-02) * s1[y+2][x+0];
	r += M4(-1.117e-02, 4.258e-03, -4.171e-03, -1.185e-02, 2.208e-02, -1.501e-02, -5.417e-03, -9.781e-03, -3.808e-02, 3.174e-02, -1.472e-01, -8.823e-02, -1.155e-01, -1.260e-01, 1.509e-01, -1.372e-01) * s1[y+2][x+1];
	r += M4(-1.655e-02, -7.010e-03, -1.243e-02, 3.104e-02, 3.384e-02, 8.819e-02, -1.665e-01, -1.230e-01, 3.000e-02, -2.097e-03, 3.552e-02, -1.356e-03, -9.344e-02, -4.345e-02, -6.517e-02, 1.804e-01) * s1[y+2][x+2];
	r += V4(5.732e-03, 4.408e-03, 6.729e-03, 6.605e-03);
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

//!DESC CuNNy-4x4C-RCAS-DS-shuffle
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

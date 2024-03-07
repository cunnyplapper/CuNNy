// CuNNy 2x4C RCAS
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


//!DESC CuNNy-2x4C-RCAS-in
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) F(texelFetch(LUMA_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0).r)
shared F s0[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += V4(-2.853e-01, 8.107e-03, 3.815e-01, -2.868e-03) * s0[y+0][x+0];
	r += V4(-3.829e-01, 2.018e-02, -1.564e-01, 2.142e-02) * s0[y+0][x+1];
	r += V4(4.398e-02, 4.450e-03, 1.061e-01, -1.973e-02) * s0[y+0][x+2];
	r += V4(5.463e-01, 1.664e-02, -9.697e-02, 2.301e-02) * s0[y+1][x+0];
	r += V4(1.171e-01, -6.251e-01, -1.324e-01, -6.217e-01) * s0[y+1][x+1];
	r += V4(-2.885e-02, 2.633e-02, -3.939e-02, 5.565e-01) * s0[y+1][x+2];
	r += V4(-1.334e-02, 7.574e-03, 7.349e-02, -1.667e-02) * s0[y+2][x+0];
	r += V4(-3.119e-02, 1.853e-03, 2.881e-02, 1.239e-01) * s0[y+2][x+1];
	r += V4(3.479e-02, 8.512e-05, 3.307e-02, -6.306e-02) * s0[y+2][x+2];
	r += V4(-2.798e-03, 7.196e-03, -6.356e-04, 1.514e-03);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-2x4C-RCAS-conv1
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(in_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(1.675e-01, 1.873e-01, 1.001e-01, 2.183e-01, 7.967e-01, -8.487e-03, -1.683e-02, -3.573e-01, 3.225e-02, 9.362e-02, 6.340e-02, 1.250e-01, 2.112e-02, 1.605e-01, 4.485e-04, 7.315e-02) * s0[y+0][x+0];
	r += M4(-8.779e-03, 1.153e-01, -1.527e-02, -2.173e-01, 1.811e-01, -3.106e+00, 4.826e-01, -2.026e-01, 1.296e-01, 1.252e-01, 1.186e-01, 1.428e-01, 2.468e-01, 2.638e-01, 5.879e-02, 2.386e-01) * s0[y+0][x+1];
	r += M4(1.704e-01, 6.128e-02, 9.011e-03, 8.273e-02, -1.343e-02, 6.116e-01, -1.655e-01, 1.137e+00, 1.703e-01, 1.013e-01, -1.588e-03, -6.212e-02, 3.367e-02, -1.650e-01, 2.416e-04, -2.314e-03) * s0[y+0][x+2];
	r += M4(1.775e-02, -3.890e-02, 2.349e-02, 2.960e-02, 2.353e+00, -4.538e-01, -4.174e-02, 6.396e-01, -1.644e-01, -1.578e-01, -9.401e-02, -2.456e-01, -7.688e-02, 3.457e-01, 2.309e-01, 2.054e-02) * s0[y+1][x+0];
	r += M4(-1.176e-01, 1.106e-01, -2.404e-01, -3.170e-01, -4.861e+00, -3.403e+00, 4.992e+00, -7.909e+00, -1.892e-01, -5.450e-01, -2.013e-01, 3.431e-02, 1.660e-01, -2.303e-01, -7.157e-01, -4.534e-01) * s0[y+1][x+1];
	r += M4(4.356e-01, 2.647e-01, 3.447e-01, 2.071e-01, -9.225e-02, 1.003e+00, 5.317e-02, -4.376e-01, 1.571e-01, 4.268e-01, -3.312e-02, 2.056e-01, 9.154e-02, -1.001e-01, 9.243e-02, 3.877e-01) * s0[y+1][x+2];
	r += M4(2.533e-02, 8.569e-02, 6.855e-02, 3.065e-02, 1.273e+00, 4.847e-01, 4.520e-02, -3.630e-01, -1.127e-04, 9.499e-03, -4.415e-02, 1.603e-02, -3.001e-01, -1.821e-01, -1.072e-01, 7.550e-02) * s0[y+2][x+0];
	r += M4(-9.311e-01, -2.476e-01, -2.437e-01, -3.369e-01, 3.028e-01, -1.037e-02, 1.016e-01, -1.344e+00, -1.439e-01, 1.715e-01, 1.401e-01, -1.450e-01, 7.496e-02, -1.965e-01, -4.117e-02, 1.010e-01) * s0[y+2][x+1];
	r += M4(-4.130e-01, -1.635e-01, -4.226e-02, 1.065e-01, 9.900e-01, 8.516e-01, -1.188e-01, -3.696e-01, 8.627e-02, -1.455e-01, -6.503e-02, 9.782e-02, 7.006e-02, -1.075e-01, 2.765e-02, 6.533e-02) * s0[y+2][x+2];
	r += M4(1.323e-01, -8.227e-02, 8.391e-02, 2.724e-01, -8.725e-02, -1.744e-02, -4.625e-02, -1.870e-01, 1.370e-01, 2.879e-01, 1.342e-01, 8.374e-02, 2.231e-01, -3.292e-01, 2.944e-02, 3.238e-01) * s1[y+0][x+0];
	r += M4(-2.662e-01, 3.272e-01, -4.939e-02, -3.623e-01, 2.796e-02, -1.144e-01, -5.896e-02, 2.264e-01, 5.358e-01, 5.098e-01, 7.202e-02, 8.555e-02, 1.549e-01, 1.186e-01, 3.083e-02, 2.920e-01) * s1[y+0][x+1];
	r += M4(7.690e-02, 3.847e-03, -1.805e-02, -3.598e-02, 1.717e-02, 2.084e-01, -2.131e-01, 9.126e-02, 1.920e-01, 1.722e-01, 2.107e-02, -8.718e-02, -9.812e-02, -7.105e-02, -2.311e-02, -1.842e-01) * s1[y+0][x+2];
	r += M4(7.780e-02, -8.423e-02, 7.076e-03, 1.147e-01, 1.117e-03, -7.255e-02, -2.268e-01, -3.232e-02, -2.785e-01, -8.727e-02, -1.213e-01, -4.310e-01, 1.066e+00, 2.114e-02, -4.226e-02, 5.829e-01) * s1[y+1][x+0];
	r += M4(-3.241e-02, -3.795e-01, -2.183e-01, -1.680e-01, 3.824e-02, 7.203e-03, -2.507e-01, -1.471e-03, -3.850e-02, -4.989e-01, -2.607e-01, 8.643e-02, -3.975e-01, 3.083e-02, -2.953e-01, -6.315e-01) * s1[y+1][x+1];
	r += M4(-5.195e-02, -1.920e-01, 5.904e-01, 5.154e-01, 1.336e-01, 5.493e-02, -1.157e-01, -4.578e-02, 5.914e-01, 8.348e-01, 5.407e-02, 5.279e-01, -9.007e-03, 1.790e-02, 4.092e-02, 1.449e-01) * s1[y+1][x+2];
	r += M4(1.626e-01, 3.997e-02, 2.311e-02, 5.787e-02, -2.725e-01, -4.244e-02, 7.732e-02, -1.576e-01, -1.899e-01, -1.295e-01, -8.051e-02, 1.941e-02, 5.174e-01, 3.504e-02, -7.570e-02, 5.309e-02) * s1[y+2][x+0];
	r += M4(-5.293e-01, -3.842e-01, -3.497e-02, 9.834e-03, 1.115e-01, 4.612e-03, -1.695e-01, -1.637e-03, 5.097e-01, -3.781e-02, 1.135e-01, -1.869e-01, 4.243e-02, 1.302e-02, -3.391e-02, -1.244e-02) * s1[y+2][x+1];
	r += M4(1.206e-01, -1.528e-01, -4.374e-02, -4.725e-02, 4.387e-02, -6.083e-02, -1.228e-02, 1.607e-01, 3.396e-01, 5.273e-01, 8.826e-02, 3.596e-01, -1.238e-01, 8.359e-04, -3.493e-02, -1.076e-01) * s1[y+2][x+2];
	r += V4(4.468e-03, -1.470e-02, -5.126e-01, -1.078e-02);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-2x4C-RCAS-conv2
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv1_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-4.921e-02, -2.826e-02, -8.579e-02, -1.014e-02, 3.131e-02, 8.755e-02, -8.985e-04, -1.069e-01, -5.515e-01, -1.820e-02, -3.310e-01, 6.244e-01, 8.118e-02, 5.532e-02, 1.074e-01, 2.198e-01) * s0[y+0][x+0];
	r += M4(-2.157e-01, 2.301e-02, -1.670e-01, -3.691e-02, 9.514e-02, -1.157e-02, 1.576e-01, -5.515e-02, 1.686e+00, -1.700e-01, -4.110e-01, 2.785e-01, 5.435e-01, 4.337e-01, 1.073e-01, 1.612e-02) * s0[y+0][x+1];
	r += M4(-1.341e-02, 9.516e-02, -9.707e-03, -7.788e-02, 8.930e-02, 6.086e-03, 5.115e-02, 6.232e-02, -4.918e-01, 6.239e-01, -1.234e-01, 3.733e-01, 3.825e-02, -3.967e-02, -1.334e-03, 6.615e-02) * s0[y+0][x+2];
	r += M4(6.846e-03, 3.000e-02, 1.160e-02, -5.009e-01, -2.446e-02, 7.156e-02, 1.236e-01, -1.411e-01, 8.237e-01, -8.697e-01, 2.349e+00, -1.983e+00, -1.284e-01, 1.899e-01, 9.882e-01, -1.000e-01) * s0[y+1][x+0];
	r += M4(6.138e-01, -2.401e-02, -2.093e-02, -4.503e-01, -4.652e-02, -2.723e-02, 2.212e-01, -2.318e-01, 8.666e+00, -2.126e+00, -7.497e-01, -3.528e+00, -2.470e-01, 3.430e-01, 6.313e-02, 3.339e-01) * s0[y+1][x+1];
	r += M4(1.694e-01, -8.067e-02, -4.453e-03, -1.304e-01, -2.329e-01, 2.646e-01, 1.371e-02, 7.222e-02, 5.718e+00, -4.121e-01, 1.051e-01, 6.648e-01, -5.872e-02, 9.790e-02, 2.863e-02, 5.645e-02) * s0[y+1][x+2];
	r += M4(-3.821e-02, 2.353e-02, 8.338e-02, -6.494e-02, -1.077e-02, 6.985e-03, -1.188e-04, -1.411e-01, 7.216e-03, -1.202e-01, 3.467e-02, 7.697e-01, 3.807e-03, 1.851e-02, 5.859e-02, -2.061e-03) * s0[y+2][x+0];
	r += M4(-1.616e-01, 1.978e-01, 2.654e-03, -6.836e-02, -2.146e-03, -1.717e-01, -1.332e-01, -8.228e-02, -3.596e-01, 1.136e+00, -5.318e-01, 5.097e-01, -1.213e-01, 1.021e-02, -2.943e-02, 3.810e-02) * s0[y+2][x+1];
	r += M4(-1.860e-01, -7.400e-02, 1.551e-03, -1.057e-01, 4.500e-02, -2.863e-02, 3.748e-02, 9.296e-02, -1.750e-01, 4.623e-01, 1.222e-02, 3.482e-01, 3.444e-02, 8.223e-02, 4.860e-03, 3.456e-02) * s0[y+2][x+2];
	r += M4(-3.886e-02, -5.403e-02, -7.070e-02, -2.987e-02, 4.175e-02, 6.023e-02, -4.300e-02, 2.199e-03, 4.226e-02, -9.074e-03, -1.731e-03, -3.493e-02, 1.362e-01, 8.994e-02, 1.174e-01, -6.909e-02) * s1[y+0][x+0];
	r += M4(-2.510e-01, -1.470e-01, -1.753e-01, 1.085e-01, 3.722e-02, 1.896e-01, 2.238e-02, 6.215e-02, -5.522e-02, 4.037e-03, -5.772e-02, 4.074e-02, 2.823e-01, 2.006e-01, 1.519e-01, -3.232e-01) * s1[y+0][x+1];
	r += M4(8.756e-02, 1.080e-01, 3.018e-02, -8.424e-02, 2.579e-01, 1.852e-01, 4.494e-02, 1.629e-02, 2.927e-02, 4.523e-02, 4.110e-02, -6.686e-02, 6.189e-02, -7.348e-02, -2.060e-03, 1.636e-01) * s1[y+0][x+2];
	r += M4(5.819e-03, 6.023e-02, -1.203e-01, 8.964e-02, -2.704e-01, 1.281e-02, 8.840e-02, -8.434e-03, -3.210e-02, 3.359e-02, -2.294e-02, 7.202e-02, -3.978e-02, -8.730e-02, 4.198e-01, -1.242e-01) * s1[y+1][x+0];
	r += M4(2.255e-01, 1.011e-01, 5.252e-02, 7.488e-04, -3.623e-01, -3.545e-01, 2.202e-01, 5.488e-01, -1.943e-02, -2.998e-01, 1.660e-02, -8.416e-02, -1.266e-01, -4.070e-01, 2.466e-01, -1.630e-01) * s1[y+1][x+1];
	r += M4(-1.753e-02, 2.073e-01, -2.738e-02, -2.143e-02, -4.589e-01, 1.716e-01, -4.108e-02, 2.850e-02, 6.904e-02, -8.641e-02, -1.165e-02, 6.274e-02, 7.786e-02, 4.850e-02, -4.428e-02, 4.579e-01) * s1[y+1][x+2];
	r += M4(4.548e-03, -3.137e-02, 1.501e-02, 3.697e-02, -1.236e-03, -4.315e-02, -1.121e-01, 1.860e-02, -1.342e-02, -6.758e-03, -1.942e-02, -2.699e-02, 9.447e-03, 9.372e-02, 3.453e-02, -1.739e-01) * s1[y+2][x+0];
	r += M4(-3.684e-02, 1.284e-01, -1.429e-02, 2.448e-02, 3.042e-01, -5.958e-01, -2.527e-02, 4.357e-01, 7.853e-02, 2.822e-01, 2.429e-02, 2.080e-02, -2.339e-01, -4.938e-02, 7.202e-02, -1.978e-01) * s1[y+2][x+1];
	r += M4(-8.374e-02, 1.062e-01, 1.849e-02, -9.253e-02, 1.567e-01, -1.519e-01, 1.961e-02, -5.131e-02, -9.497e-02, 3.217e-02, 1.042e-04, 4.355e-02, -1.403e-02, 1.007e-01, 1.906e-02, -1.378e-02) * s1[y+2][x+2];
	r += V4(1.225e-02, 5.089e-03, 1.200e-02, -9.065e-04);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-2x4C-RCAS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE out
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(6.427e-02, 3.108e-03, 4.529e-02, 2.243e-02, -2.783e-02, 3.674e-02, -2.851e-02, 1.329e-02, -3.389e-02, 2.421e-02, -1.058e-02, 9.131e-04, -4.488e-02, -1.259e-02, -5.528e-02, 8.129e-02) * s0[y+0][x+0];
	r += M4(-7.105e-03, 5.153e-02, -4.390e-02, -1.551e-02, 2.813e-02, -1.008e-01, 8.852e-02, 1.507e-03, -3.248e-02, -6.213e-02, -4.201e-02, -1.158e-02, 6.205e-02, 2.235e-01, 6.170e-02, -8.562e-02) * s0[y+0][x+1];
	r += M4(5.917e-03, 1.826e-02, 1.418e-02, 1.336e-02, -4.209e-02, -2.699e-02, -2.729e-02, -3.284e-02, -1.049e-01, -1.177e-01, -3.148e-02, -9.850e-02, 5.052e-02, -2.182e-01, -1.006e-02, 1.447e-02) * s0[y+0][x+2];
	r += M4(1.356e-01, -1.022e-01, 5.503e-02, -4.076e-02, 1.013e-01, 4.162e-02, 1.216e-01, 8.577e-02, 5.883e-03, 4.943e-02, -8.541e-04, 6.608e-02, 4.173e-01, -2.173e-01, 2.114e-01, -1.870e-01) * s0[y+1][x+0];
	r += M4(1.499e-01, 4.153e-01, 7.674e-02, 2.160e-01, -1.545e-01, -1.054e-01, -1.500e-01, -1.558e-01, 5.075e-02, -1.213e-01, 1.413e-01, -1.116e-01, -8.748e-01, 6.430e-01, -4.054e-01, 7.418e-01) * s0[y+1][x+1];
	r += M4(1.825e-02, -4.725e-02, 2.607e-02, -3.650e-03, 6.811e-02, 6.237e-02, 3.173e-02, 5.263e-02, 8.722e-02, 2.744e-01, 2.211e-02, 2.646e-01, 6.385e-01, -5.898e-02, 3.957e-01, -2.428e-01) * s0[y+1][x+2];
	r += M4(4.168e-03, 1.271e-02, 1.060e-01, -6.361e-02, 1.606e-02, -1.425e-02, 2.802e-02, -9.519e-03, 4.677e-03, 1.208e-02, -8.538e-03, 1.443e-02, 3.373e-02, -4.897e-02, 2.549e-01, -1.626e-01) * s0[y+2][x+0];
	r += M4(-4.557e-02, -1.509e-02, 6.454e-02, 2.452e-01, 5.917e-02, 6.712e-02, -7.707e-03, 1.959e-02, -1.118e-02, 1.049e-03, -8.730e-02, -6.163e-02, 5.166e-02, 1.660e-02, -4.489e-01, 2.761e-01) * s0[y+2][x+1];
	r += M4(1.692e-02, -1.918e-02, -8.885e-03, -5.231e-02, -3.665e-02, -2.977e-02, -2.493e-03, -9.810e-03, -4.198e-02, -8.320e-02, -6.571e-02, -9.491e-02, -2.766e-01, -2.535e-02, 9.936e-02, 3.288e-03) * s0[y+2][x+2];
	r += M4(-1.136e-01, 1.289e-02, 1.398e-01, -3.574e-02, -2.037e-02, -7.053e-02, 7.983e-02, -4.978e-02, 7.013e-02, 2.124e-02, 6.060e-02, -2.793e-02, -2.058e-02, -1.582e-02, -1.668e-03, 1.318e-02) * s1[y+0][x+0];
	r += M4(-2.510e-01, -3.188e-01, 2.862e-01, 3.252e-01, -4.612e-01, -1.908e-01, 3.058e-01, 3.018e-01, -1.539e-01, 2.087e-02, -4.439e-02, 1.392e-01, 1.620e-02, -2.030e-02, 1.180e-02, -2.278e-02) * s1[y+0][x+1];
	r += M4(5.212e-02, 6.699e-03, -4.276e-02, 8.090e-02, -5.521e-02, -1.837e-01, -6.821e-02, 1.356e-01, 1.044e-01, 6.161e-03, -1.686e-01, -2.071e-01, -4.993e-02, -3.386e-02, -2.319e-02, -3.008e-02) * s1[y+0][x+2];
	r += M4(4.464e-01, -2.427e-01, -3.158e-01, -1.541e-01, 2.842e-01, -7.544e-02, 1.009e-01, -4.395e-02, 4.213e-02, -5.212e-02, -2.263e-02, 1.051e-02, 8.311e-02, 1.203e-03, 6.162e-02, -2.643e-02) * s1[y+1][x+0];
	r += M4(8.169e-01, 1.370e+00, -7.235e-01, -6.307e-01, 3.457e-03, 4.149e-01, -7.960e-01, -2.854e-01, 2.919e-01, 2.531e-01, 2.607e-01, -3.422e-02, -7.985e-02, 1.222e-02, -5.728e-02, 4.174e-02) * s1[y+1][x+1];
	r += M4(-2.881e-02, -4.719e-03, 4.126e-02, -2.738e-01, 1.841e-01, 1.401e-01, 1.602e-01, -1.735e-01, 5.293e-01, 5.788e-01, 7.539e-01, 1.011e+00, 1.018e-01, 8.870e-02, 5.497e-02, 5.261e-02) * s1[y+1][x+2];
	r += M4(-1.690e-01, 1.196e-01, 9.227e-02, -3.914e-03, -8.033e-04, 3.379e-02, 9.652e-02, -5.797e-02, -8.429e-03, -9.328e-03, 8.276e-02, -4.274e-02, -1.448e-03, 2.778e-02, 1.953e-02, 4.091e-02) * s1[y+2][x+0];
	r += M4(-4.368e-01, -5.737e-01, 3.331e-01, 2.914e-01, -8.893e-02, -2.075e-02, 3.917e-02, 2.437e-01, -3.701e-02, -1.112e-02, -1.745e-02, 2.547e-01, -3.828e-03, -3.074e-02, -5.681e-03, -3.943e-02) * s1[y+2][x+1];
	r += M4(3.024e-02, -1.574e-01, 6.279e-02, 1.597e-01, 1.482e-02, -6.314e-02, -1.289e-02, -5.178e-02, 2.027e-02, -3.345e-02, 6.166e-02, -9.874e-02, -4.701e-02, -5.505e-02, -1.368e-02, -1.126e-02) * s1[y+2][x+2];
	r += V4(-3.288e-03, -3.301e-03, -2.388e-03, -2.536e-03);
	return tanh(vec4(r));
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-2x4C-RCAS-shuffle
//!HOOK LUMA
//!BIND out
//!BIND rcas
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
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

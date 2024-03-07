// CuNNy 8x4C RCAS DS
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


//!DESC CuNNy-8x4C-RCAS-DS-in
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
	r += V4(6.616e-02, -2.499e-02, -1.655e-04, 1.904e-01) * s0[y+0][x+0];
	r += V4(2.802e-01, 3.033e-01, -2.546e-03, 3.751e-01) * s0[y+0][x+1];
	r += V4(-2.819e-02, -1.004e-02, -6.646e-03, -1.683e-01) * s0[y+0][x+2];
	r += V4(-1.694e-01, -6.035e-01, -1.238e-02, 1.194e-01) * s0[y+1][x+0];
	r += V4(1.257e-01, 2.059e-01, 6.846e-01, -5.363e-01) * s0[y+1][x+1];
	r += V4(9.163e-03, 5.577e-02, -1.714e-02, -3.653e-02) * s0[y+1][x+2];
	r += V4(1.083e-01, 8.893e-02, 8.130e-04, 4.850e-02) * s0[y+2][x+0];
	r += V4(-5.094e-01, -5.606e-02, -2.103e-02, 2.834e-03) * s0[y+2][x+1];
	r += V4(1.353e-01, 3.377e-02, -3.332e-04, -1.014e-02) * s0[y+2][x+2];
	r += V4(-2.975e-02, -3.117e-02, -7.965e-03, -3.132e-05);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv1
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
	r += M4(-9.501e-02, 6.545e-02, 2.993e-01, 1.761e-01, -7.054e-02, 1.999e-01, -6.422e-02, 1.014e-01, 6.628e-03, -5.512e-02, -2.764e-02, 2.722e-01, 3.532e-02, -7.352e-02, -2.954e-01, -9.644e-02) * s0[y+0][x+0];
	r += M4(7.028e-02, -1.102e-01, -2.061e-01, 4.995e-01, -1.665e-01, 9.093e-02, -1.239e-02, 4.122e-01, -1.104e-01, -2.741e-01, 9.767e-02, 2.558e-01, 5.400e-02, 9.832e-02, 9.363e-02, -5.225e-01) * s0[y+0][x+1];
	r += M4(-6.362e-03, -1.396e-01, -9.739e-02, 1.429e-01, -2.529e-01, 7.205e-02, 7.751e-02, -1.045e-01, 5.728e-02, -1.163e-01, 4.908e-02, 2.120e-01, 1.934e-01, -6.008e-02, 3.220e-03, -5.145e-02) * s0[y+0][x+2];
	r += M4(1.015e-01, 3.281e-01, -5.108e-02, -3.268e-02, 7.056e-02, 1.599e-01, 3.539e-01, 1.487e-01, -1.772e-01, 4.862e-03, -5.502e-02, 2.000e-03, -9.692e-02, -1.127e-02, 4.068e-01, 3.924e-02) * s0[y+1][x+0];
	r += M4(5.600e-01, 1.708e-02, 2.438e-01, -1.199e-01, -5.631e-02, 2.035e-01, 8.042e-02, 2.307e-01, -2.152e-01, -8.712e-02, 1.572e-01, -1.895e-01, 7.621e-02, -7.056e-01, 3.524e-02, 5.879e-01) * s0[y+1][x+1];
	r += M4(-1.489e-01, 2.808e-01, -5.492e-02, -5.440e-02, 5.488e-01, -1.716e-01, 1.652e-02, 7.635e-02, 3.247e-01, 5.226e-02, 1.007e-02, -3.443e-01, -4.873e-01, 2.703e-02, -7.186e-02, -2.429e-01) * s0[y+1][x+2];
	r += M4(2.123e-02, -1.343e-01, 2.362e-01, -7.952e-02, 1.749e-02, 1.726e-02, -1.551e-01, 8.833e-03, -1.867e-01, 2.087e-01, 3.393e-01, 7.876e-03, 9.235e-02, -1.154e-01, -2.140e-01, -3.986e-02) * s0[y+2][x+0];
	r += M4(-2.076e-02, 4.535e-02, 1.149e-01, -7.140e-03, -2.674e-01, 8.707e-02, -2.016e-01, 1.491e-01, -4.889e-02, 1.278e-01, 2.852e-01, -1.685e-01, 2.189e-01, -2.358e-01, 1.467e-01, -4.576e-02) * s0[y+2][x+1];
	r += M4(1.482e-02, -2.881e-02, 3.007e-03, -2.795e-02, 2.826e-01, 6.872e-03, 1.926e-01, 4.992e-02, 2.475e-01, 1.291e-01, -1.179e-01, -2.765e-02, 1.440e-01, -2.549e-02, 5.244e-02, 8.887e-03) * s0[y+2][x+2];
	r += M4(1.872e-01, -3.705e-01, 2.940e-01, -1.445e-01, -2.455e-02, -1.054e-01, -1.639e-01, -1.801e-02, -3.492e-01, 8.546e-02, 2.252e+00, 2.366e+00, -2.718e-02, 1.724e-01, -1.530e-01, 5.448e-02) * s1[y+0][x+0];
	r += M4(1.096e-01, -2.096e-01, -4.450e-03, 5.881e-01, -6.836e-02, 1.431e-01, -8.960e-02, -7.280e-02, -2.629e+00, -3.432e+00, 6.333e-01, 3.570e+00, -1.590e-01, 2.693e-01, 3.836e-02, -3.001e-01) * s1[y+0][x+1];
	r += M4(-2.701e-01, -6.156e-02, -4.197e-02, 1.917e-02, 1.502e-02, 1.075e-01, 6.227e-02, -2.035e-01, -7.908e-01, -1.691e-02, -4.598e-01, -7.607e-01, 1.302e-01, 9.483e-02, 4.885e-02, 3.648e-02) * s1[y+0][x+2];
	r += M4(-1.520e-01, 1.833e-01, -2.761e-01, -1.055e-01, 6.444e-02, -2.721e-01, -3.148e-01, -1.128e-01, -2.367e+00, -6.926e-01, -2.699e+00, -3.985e+00, 3.577e-02, 8.182e-02, 4.156e-01, 1.280e-01) * s1[y+1][x+0];
	r += M4(-9.922e-03, 3.302e-02, -1.083e-01, 4.209e-02, -1.266e-02, -8.417e-01, 5.019e-01, 5.062e-02, -6.031e+00, -4.500e+00, -4.650e-01, -4.092e-01, -3.505e-02, -2.999e-01, -1.073e-01, 5.772e-01) * s1[y+1][x+1];
	r += M4(1.863e-02, 1.026e-01, -1.718e-01, -2.473e-01, 7.120e-01, -1.236e-01, 4.742e-02, -3.881e-02, 3.928e-01, 1.126e-01, -1.394e-01, -1.268e-01, -2.686e-01, 5.065e-02, -2.069e-03, -1.528e-02) * s1[y+1][x+2];
	r += M4(-7.721e-02, 1.915e-02, 1.597e-01, 6.167e-03, -1.103e-01, 1.769e-01, -1.933e-01, 1.006e-01, -1.872e+00, -2.741e+00, 3.784e+00, -2.260e+00, -5.022e-02, 2.148e-01, -2.502e-01, 1.928e-01) * s1[y+2][x+0];
	r += M4(4.396e-02, -6.308e-02, -2.149e-03, 4.605e-02, -4.341e-02, -1.845e-01, -2.657e-02, -6.895e-02, -3.431e+00, -1.596e+00, 9.359e-01, -1.048e+00, 1.043e-01, 2.242e-01, 1.348e-01, 7.015e-02) * s1[y+2][x+1];
	r += M4(-1.470e-01, 3.898e-02, -1.630e-02, 1.922e-02, 9.632e-02, -1.242e-01, 6.101e-02, -9.251e-02, -3.840e-01, 1.171e+00, 5.166e-01, 8.658e-01, 3.700e-01, 3.093e-02, -9.770e-03, -4.623e-02) * s1[y+2][x+2];
	r += V4(6.938e-02, -8.711e-02, -3.250e-01, 2.703e-02);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv2
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
	r += M4(-3.749e-01, -6.395e-01, -3.315e-01, 1.342e-02, -1.075e-01, -5.505e-02, -1.362e-01, 3.863e-02, -4.064e-02, -2.605e-01, 8.445e-02, -1.273e-01, -1.923e-02, -2.326e-01, 8.149e-03, 9.012e-02) * s0[y+0][x+0];
	r += M4(-9.210e-02, -2.008e-01, -7.446e-02, -7.096e-02, -8.749e-02, 9.784e-02, -1.507e-01, 1.189e-01, -3.115e-02, -2.433e-02, -4.515e-02, -4.380e-01, -1.254e-01, -7.887e-02, -1.035e-01, 1.500e-01) * s0[y+0][x+1];
	r += M4(1.074e-03, -2.800e-02, -8.081e-02, -1.449e-02, 6.271e-02, 1.554e-01, -1.158e-01, -1.128e-01, -9.066e-03, 2.003e-02, -3.093e-01, -2.702e-01, 2.267e-02, 6.860e-02, 4.541e-02, -6.110e-02) * s0[y+0][x+2];
	r += M4(-4.283e-01, 3.117e-01, -7.130e-01, 6.069e-01, -1.074e-01, 2.563e-01, -1.496e-01, 2.470e-01, 1.254e-01, 7.630e-02, 9.553e-02, -1.927e-01, -1.999e-03, -3.748e-01, 1.919e-01, -7.444e-03) * s0[y+1][x+0];
	r += M4(8.732e-02, -5.818e-02, 1.493e-01, 2.898e-01, 2.242e-01, 1.699e-01, 2.623e-02, -1.723e-01, -3.210e-01, -2.291e-01, -4.674e-01, 8.543e-02, -6.713e-03, -3.593e-01, 4.938e-01, 1.299e-01) * s0[y+1][x+1];
	r += M4(-2.848e-02, 4.135e-02, -3.350e-02, 2.629e-02, 1.176e-01, -2.010e-01, 7.678e-02, 1.179e-01, -1.326e-01, 1.239e-01, 1.999e-01, -1.260e-01, 7.781e-02, -1.231e-01, 1.953e-01, 1.574e-01) * s0[y+1][x+2];
	r += M4(7.910e-01, 1.507e-01, -3.172e-01, 1.874e-01, -2.130e-01, 7.979e-02, 1.293e-01, 3.446e-01, -6.820e-02, -5.229e-02, 9.668e-02, -7.853e-02, 8.897e-01, -1.153e-01, 2.569e-01, -6.643e-01) * s0[y+2][x+0];
	r += M4(3.619e-02, -5.117e-02, -4.102e-02, 3.018e-02, 3.722e-01, -6.333e-02, -3.428e-01, -1.790e-01, 2.881e-01, 8.271e-02, -2.448e-01, -5.600e-02, -1.292e-02, 2.142e-01, 1.100e-01, -2.715e-02) * s0[y+2][x+1];
	r += M4(-4.096e-03, -7.946e-03, -5.235e-02, -1.581e-02, 4.733e-02, 4.658e-02, -2.744e-01, -7.247e-02, 1.593e-01, 1.569e-02, -6.894e-02, -6.320e-02, 2.046e-01, 2.599e-02, -2.487e-01, -6.856e-02) * s0[y+2][x+2];
	r += M4(3.153e-02, 5.252e-01, -4.756e-01, -1.094e-03, -5.970e-02, -1.258e-01, -5.606e-02, 1.990e-02, 4.406e-02, -9.106e-02, 7.306e-02, -4.201e-02, 5.664e-02, 7.842e-03, -1.774e-01, 8.684e-02) * s1[y+0][x+0];
	r += M4(9.690e-04, 2.667e-02, -1.987e-01, -9.338e-02, -1.626e-01, -2.352e-01, -1.755e-01, 1.606e-01, -6.815e-02, 4.699e-02, 1.096e-01, -1.652e-01, -1.763e-01, -1.086e-01, 1.894e-02, 1.407e-01) * s1[y+0][x+1];
	r += M4(-2.303e-02, 5.001e-02, 4.335e-02, 1.943e-04, 4.769e-02, -5.215e-02, -2.562e-03, -6.977e-02, -4.688e-02, 4.611e-02, -2.697e-01, -1.840e-01, 1.410e-02, 2.437e-01, -9.979e-02, -6.043e-02) * s1[y+0][x+2];
	r += M4(3.539e-02, -4.338e-01, -3.699e-01, 3.907e-01, 1.824e-02, 6.074e-01, -1.806e-01, 3.325e-01, 2.506e-01, -3.005e-02, 1.134e-01, -5.811e-02, 1.380e-01, 1.117e-01, -2.060e-01, 5.371e-02) * s1[y+1][x+0];
	r += M4(1.033e-01, -9.221e-02, 3.364e-01, 3.706e-01, -8.416e-03, 5.439e-01, 2.644e-01, -1.069e-01, -2.705e-01, -3.048e-01, -3.486e-01, 3.219e-01, 1.355e-01, -4.527e-01, 1.715e-01, 2.136e-01) * s1[y+1][x+1];
	r += M4(6.518e-02, 6.844e-03, -1.034e-02, 4.790e-02, -6.882e-03, -1.049e-01, -1.110e-01, -9.596e-02, -8.191e-02, 1.953e-01, 2.004e-01, -1.739e-02, 1.529e-01, -1.972e-02, 2.310e-01, 1.981e-01) * s1[y+1][x+2];
	r += M4(-2.252e-01, -3.382e-02, -2.513e-01, 1.495e-01, -1.880e-01, 2.866e-02, -2.562e-01, 2.251e-01, -1.188e-01, 4.476e-02, 9.161e-02, -9.624e-03, 5.858e-01, -2.390e-01, -1.966e-01, -2.782e-01) * s1[y+2][x+0];
	r += M4(1.084e-02, -1.680e-02, -1.824e-01, -3.665e-02, -4.313e-01, 8.425e-02, 2.677e-01, -1.798e-01, 1.006e-01, 1.158e-02, -2.071e-01, -1.505e-01, 2.053e-01, -2.681e-01, -2.603e-01, -1.798e-01) * s1[y+2][x+1];
	r += M4(-2.502e-02, -8.488e-03, -3.665e-02, -4.937e-02, -1.587e-02, 9.595e-02, -8.852e-02, -6.131e-02, 1.849e-01, -9.836e-02, -3.487e-03, -7.539e-02, 7.466e-02, -1.278e-02, -8.517e-02, 1.705e-02) * s1[y+2][x+2];
	r += V4(-8.179e-02, 8.507e-02, -9.011e-02, -1.618e-01);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv3
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
	r += M4(9.472e-03, 3.768e-02, 5.233e-02, -8.837e-02, -7.361e-02, 2.643e-02, -1.221e-01, 4.487e-02, 1.106e-01, -9.932e-02, 1.298e-01, -3.235e-02, 3.149e-02, 3.646e-02, 2.016e-01, -1.108e-01) * s0[y+0][x+0];
	r += M4(7.115e-02, 3.832e-01, -2.841e-01, 8.808e-02, -1.350e-02, -4.038e-02, 8.752e-02, -8.113e-02, -4.472e-02, -5.214e-02, 1.678e-01, -8.706e-02, -2.331e-01, -3.105e-01, -1.541e-01, -4.049e-01) * s0[y+0][x+1];
	r += M4(-1.590e-01, 1.150e-01, 2.489e-01, 6.513e-02, 1.767e-02, 1.076e-02, -1.862e-02, -2.076e-03, 5.506e-02, 9.243e-02, -1.071e-01, 6.206e-02, -6.274e-02, -4.800e-02, 1.030e-01, -1.649e-01) * s0[y+0][x+2];
	r += M4(-4.074e-02, -1.689e-01, -1.300e-02, -1.223e-01, 2.396e-01, -7.146e-02, 1.599e-01, 8.299e-02, -2.312e-01, -3.609e-01, -4.664e-02, -3.725e-01, 1.919e-01, -9.734e-02, 2.729e-01, -4.043e-01) * s0[y+1][x+0];
	r += M4(4.521e-01, -7.187e-01, -3.832e-02, 1.172e-01, -1.270e-01, 4.968e-02, 3.771e-01, 1.203e-01, -1.986e-01, -4.036e-01, 5.059e-01, -1.244e-01, -7.456e-01, -3.484e-01, -9.702e-01, -1.917e+00) * s0[y+1][x+1];
	r += M4(4.613e-01, 7.380e-02, -7.677e-03, -1.396e-01, -3.388e-01, 1.285e-01, -5.574e-02, -4.925e-02, 2.050e-01, -2.172e-02, 1.323e-01, -1.951e-01, 3.152e-01, 3.779e-01, -1.391e-01, -1.874e-01) * s0[y+1][x+2];
	r += M4(7.890e-03, 6.500e-02, -3.058e-02, -6.268e-02, -3.291e-01, -1.191e-01, -1.137e-02, 3.034e-01, -1.826e-01, 7.744e-01, -6.780e-02, -4.322e-01, 2.004e-01, 2.046e-01, -8.950e-03, -2.909e-01) * s0[y+2][x+0];
	r += M4(2.389e-01, -2.466e-02, 1.205e-01, -1.352e-02, -5.396e-01, 4.663e-01, -1.277e-02, -2.606e-01, 3.439e-01, 3.396e-01, -2.569e-01, 2.703e-01, -4.662e-01, -1.299e-01, -1.142e-01, 3.505e-01) * s0[y+2][x+1];
	r += M4(9.549e-02, 7.473e-02, -1.082e-02, -2.094e-02, 1.303e-01, 3.348e-02, -3.997e-02, 7.271e-02, -5.248e-02, 1.901e-02, -1.339e-02, 2.938e-02, -2.620e-01, 1.388e-01, 1.384e-01, 4.695e-02) * s0[y+2][x+2];
	r += M4(6.873e-03, -3.438e-02, 1.471e-01, -1.006e-01, 1.495e-02, 3.343e-02, -1.080e-02, 3.169e-02, 4.965e-02, 8.737e-02, -8.782e-02, -6.013e-02, -1.335e-01, 3.495e-04, 9.739e-02, -1.421e-01) * s1[y+0][x+0];
	r += M4(-7.106e-02, 8.858e-02, -2.920e-01, 7.074e-02, 1.259e-01, -1.026e-01, 1.469e-01, -6.080e-02, 9.914e-03, 9.613e-02, -2.503e-02, -2.709e-03, -1.959e-01, -8.520e-02, -2.092e-01, -4.950e-02) * s1[y+0][x+1];
	r += M4(-1.965e-01, -2.654e-02, 1.264e-01, 1.383e-02, 2.985e-02, -1.156e-02, -8.789e-03, 3.495e-03, 1.124e-01, -4.713e-02, -1.079e-01, -1.439e-02, 6.834e-02, -7.700e-02, 1.233e-02, -1.043e-01) * s1[y+0][x+2];
	r += M4(-2.643e-01, -2.514e-01, -2.991e-02, -4.696e-02, 2.920e-01, 6.050e-02, -5.130e-02, -9.306e-02, 4.326e-02, 1.202e-01, 1.802e-01, -2.215e-01, 1.490e-01, -1.139e-01, -2.717e-02, -1.935e-01) * s1[y+1][x+0];
	r += M4(-7.481e-01, -6.973e-01, 2.152e-01, 2.449e-01, 2.357e-01, -3.482e-02, 3.238e-01, -8.232e-02, -2.050e-02, -2.627e-01, 1.082e+00, -9.901e-02, -2.605e-01, 1.304e-01, -2.987e-01, -4.543e-01) * s1[y+1][x+1];
	r += M4(-8.916e-02, 1.229e-01, -1.942e-01, -6.181e-02, -1.856e-01, 6.221e-02, -1.311e-02, -7.266e-02, 6.724e-02, -1.088e-01, -4.331e-02, -1.017e-01, 1.502e-01, 2.249e-01, 1.315e-01, -1.956e-01) * s1[y+1][x+2];
	r += M4(-4.393e-03, 1.223e-01, -7.215e-02, -1.163e-01, -6.570e-02, -3.566e-02, 4.032e-02, 7.185e-02, -5.646e-02, -2.015e-01, -1.048e-01, -2.871e-01, 1.640e-01, 9.875e-02, -6.966e-02, -2.608e-01) * s1[y+2][x+0];
	r += M4(-1.053e-01, 1.278e-01, -3.214e-02, 2.236e-02, 8.693e-02, 5.573e-01, -8.133e-02, -2.834e-01, -1.741e-01, 1.601e-02, -9.799e-02, 2.053e-01, -1.497e-01, -3.247e-01, 7.421e-02, 2.033e-01) * s1[y+2][x+1];
	r += M4(9.018e-02, 4.343e-02, 4.770e-03, 7.935e-03, 2.299e-01, 1.233e-01, -1.247e-01, 1.643e-01, -3.210e-03, 8.067e-02, -3.015e-02, 4.327e-02, -3.032e-03, -5.830e-03, 1.072e-01, 6.237e-02) * s1[y+2][x+2];
	r += V4(-5.798e-02, -4.353e-02, -7.480e-03, -9.694e-02);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv4
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(2.905e-02, -7.576e-02, 1.753e-01, 7.184e-02, 6.142e-03, 2.557e-03, -1.939e-01, 4.680e-02, 4.151e-04, 6.455e-02, -1.728e-01, -3.013e-02, 1.041e-01, -8.621e-02, 1.382e-01, 7.088e-02) * s0[y+0][x+0];
	r += M4(5.373e-02, 1.535e-01, -1.170e-01, -3.058e-01, 4.100e-02, -8.616e-02, 2.226e-01, -2.165e-01, 2.675e-02, -4.360e-01, 3.137e-01, 2.788e-01, 5.049e-02, 1.485e-01, -4.857e-02, -8.094e-02) * s0[y+0][x+1];
	r += M4(-7.014e-02, 1.114e-01, 1.117e-01, 3.224e-02, 5.020e-02, -5.279e-02, -8.285e-02, 1.340e-01, 8.051e-03, -1.667e-01, -1.670e-02, 5.602e-02, 6.429e-02, -8.031e-03, 1.181e-01, -1.827e-02) * s0[y+0][x+2];
	r += M4(6.875e-02, -6.434e-02, -1.121e-03, -1.302e-01, 1.121e-01, 8.471e-02, -1.835e-01, 3.736e-02, -5.253e-01, 2.245e-02, -8.581e-01, 3.625e-01, 1.556e-01, -1.873e-01, 4.643e-02, -3.474e-01) * s0[y+1][x+0];
	r += M4(9.867e-02, 4.397e-02, 2.978e-02, 1.249e-01, -4.492e-01, -3.290e-01, 5.689e-02, 9.246e-01, 8.971e-02, 1.688e-01, 3.038e-01, 5.795e-02, 4.699e-01, 4.598e-01, 2.519e-02, 6.865e-01) * s0[y+1][x+1];
	r += M4(-4.410e-02, -4.700e-02, -3.633e-02, -3.625e-01, 1.153e-01, 3.148e-02, 3.612e-01, 3.121e-01, 6.446e-02, -4.354e-01, -3.321e-02, 9.612e-02, 1.971e-01, -3.139e-01, -2.335e-01, -2.481e-02) * s0[y+1][x+2];
	r += M4(2.550e-02, 4.402e-02, -1.533e-01, -4.803e-02, -1.480e-02, 3.743e-02, -1.135e-01, -8.880e-02, -6.464e-02, -6.247e-02, -2.524e-01, -2.078e-01, -1.661e-02, 7.149e-02, -2.964e-01, -6.427e-02) * s0[y+2][x+0];
	r += M4(9.147e-03, -7.101e-02, -3.278e-02, -1.949e-01, -3.053e-03, -2.256e-02, -1.124e-01, -2.076e-01, -2.131e-02, -5.258e-02, 6.124e-01, 3.349e-01, 1.862e-01, -3.042e-02, 1.993e-01, -8.846e-02) * s0[y+2][x+1];
	r += M4(4.681e-02, 2.823e-02, -7.781e-02, 3.233e-03, 5.857e-02, -1.273e-02, -7.589e-02, -1.226e-01, 3.502e-02, 1.252e-01, 8.324e-02, 2.637e-02, 6.421e-02, 1.326e-01, 1.162e-01, -1.157e-02) * s0[y+2][x+2];
	r += M4(7.254e-02, 7.354e-02, 2.660e-02, 9.029e-02, 1.008e-01, -2.054e-03, 9.981e-02, -2.087e-02, -4.220e-03, -2.550e-02, -1.157e-01, 9.992e-02, -6.207e-03, -7.126e-02, 1.304e-01, -4.254e-03) * s1[y+0][x+0];
	r += M4(-2.147e-02, -2.183e-01, 2.692e-02, -1.194e-02, 2.144e-01, -1.022e-01, 3.721e-01, -1.170e-01, -2.591e-02, 4.382e-02, -1.379e-01, -1.367e-01, -3.465e-02, 1.115e-01, -1.119e-01, -3.069e-02) * s1[y+0][x+1];
	r += M4(4.294e-02, -1.634e-01, 2.773e-02, 1.902e-01, 1.693e-01, 8.000e-02, -3.489e-02, -1.091e-01, -4.093e-02, 1.495e-01, -8.911e-02, -9.727e-02, -1.808e-02, 7.666e-02, 1.011e-01, 1.648e-02) * s1[y+0][x+2];
	r += M4(-3.817e-02, 1.974e-01, -4.345e-01, 9.065e-02, 5.714e-02, 6.538e-02, -1.029e-01, -1.336e-01, -2.633e-02, -1.478e-01, 5.674e-02, -1.961e-01, 2.487e-02, -4.989e-02, 1.039e-01, -1.853e-01) * s1[y+1][x+0];
	r += M4(1.053e-01, -3.995e-01, -1.201e-01, 3.737e-01, -4.700e-02, -4.343e-01, 1.858e-01, 1.168e-01, 9.595e-02, 5.842e-01, 3.593e-01, -3.071e-01, 8.671e-02, 1.633e-01, 1.664e-02, 2.160e-01) * s1[y+1][x+1];
	r += M4(7.654e-02, -2.214e-01, 9.408e-02, 3.358e-02, 3.215e-02, 2.934e-01, 8.124e-02, -1.714e-01, -7.196e-02, 1.313e-01, -1.402e-01, 1.204e-01, 1.191e-01, -5.853e-01, -2.551e-02, -1.382e-01) * s1[y+1][x+2];
	r += M4(6.762e-02, 1.735e-02, -6.067e-02, -1.057e-01, 7.067e-03, -2.301e-02, -1.362e-01, -2.700e-02, -1.120e-01, -1.970e-01, 1.258e-01, 6.616e-02, 2.876e-02, 5.104e-03, -1.684e-02, 1.274e-02) * s1[y+2][x+0];
	r += M4(4.534e-02, -1.657e-01, 9.000e-02, -3.096e-01, -1.202e-02, -1.474e-03, -6.157e-02, -1.212e-01, -1.833e-02, 9.273e-02, 3.506e-01, 2.588e-01, 1.548e-01, 1.447e-01, 1.745e-01, 3.377e-01) * s1[y+2][x+1];
	r += M4(4.999e-02, -3.104e-02, 1.245e-01, -7.773e-02, 1.030e-02, -1.397e-01, -1.116e-01, -2.369e-01, -1.627e-02, 2.414e-01, 4.866e-02, 2.933e-01, 1.577e-01, 3.971e-03, 2.222e-01, 1.002e-01) * s1[y+2][x+2];
	r += V4(-4.849e-01, 2.265e-02, 1.683e-02, -1.056e-01);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv5
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv4
//!BIND LUMA
//!SAVE conv5
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
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.512e-01, -2.907e-01, -1.185e-02, -3.814e-01, -5.295e-02, -5.383e-02, -1.101e-01, 3.890e-02, -4.867e-02, -1.811e-01, 2.347e-02, -1.043e-01, 7.353e-02, -6.703e-02, -1.745e-02, 6.115e-03) * s0[y+0][x+0];
	r += M4(-3.405e-01, 2.028e-01, -4.952e-01, 3.584e-03, -3.146e-02, -2.998e-01, 8.418e-02, -7.829e-02, -1.621e-01, -2.377e-01, -6.674e-02, 2.329e-01, -2.312e-01, -6.954e-02, 5.757e-02, -1.954e-01) * s0[y+0][x+1];
	r += M4(-7.071e-01, -1.098e+00, 5.036e-01, -1.944e-01, -8.485e-02, 3.898e-02, -3.264e-02, -3.551e-02, -1.233e-01, -1.128e-01, 1.027e-03, 1.901e-02, 1.561e-01, 2.971e-01, -1.345e-01, -4.056e-02) * s0[y+0][x+2];
	r += M4(-8.307e-01, -5.561e-01, -5.128e-01, -4.713e-01, 1.736e-01, 2.645e-01, -5.872e-02, 3.471e-02, -1.343e-01, 1.344e-01, -6.430e-02, -1.515e-02, -7.800e-02, -2.524e-02, 7.456e-02, -1.975e-01) * s0[y+1][x+0];
	r += M4(-1.310e+00, -8.548e-01, -2.369e+00, 1.400e+00, 7.088e-02, 3.786e-01, -3.600e-01, -4.673e-03, -1.872e-01, -2.280e-01, -3.133e-01, -1.067e-01, 3.611e-01, -5.909e-01, 3.246e-01, -1.315e-01) * s0[y+1][x+1];
	r += M4(-4.245e-01, -6.408e-01, 7.817e-01, 1.075e+00, 7.496e-02, -1.722e-01, 1.449e-01, 2.349e-01, -4.955e-02, -1.424e-01, -2.559e-03, 2.104e-01, 1.341e-01, -9.957e-02, -1.412e-02, -2.959e-01) * s0[y+1][x+2];
	r += M4(1.133e-01, -6.222e-01, 3.550e-02, -3.686e-01, 8.278e-02, -1.637e-01, -6.629e-02, 1.327e-01, 1.480e-03, -7.739e-02, 2.683e-02, 4.266e-02, 4.057e-02, 9.639e-03, 1.876e-02, -6.865e-02) * s0[y+2][x+0];
	r += M4(3.116e-01, -8.781e-01, -1.626e-01, -6.387e-01, -1.022e-01, 9.956e-02, -1.037e-01, 1.240e-01, -2.929e-01, 9.587e-02, 3.151e-02, 3.416e-02, 1.499e-01, -1.519e-01, 4.693e-02, -5.841e-02) * s0[y+2][x+1];
	r += M4(4.293e-01, -1.077e+00, -2.253e-01, -7.185e-01, 5.051e-02, -1.040e-01, 2.280e-04, 7.103e-02, -9.170e-02, -5.092e-02, 8.227e-02, -8.443e-02, -1.184e-02, -3.067e-02, 4.124e-02, -2.025e-02) * s0[y+2][x+2];
	r += M4(4.978e-02, 6.404e-02, 1.325e-01, 4.868e-02, -9.434e-02, -9.438e-02, -1.626e-01, -1.470e-01, 2.012e-03, -4.869e-02, -3.752e-02, -2.192e-03, -3.868e-02, -1.198e-01, 9.493e-02, -8.654e-02) * s1[y+0][x+0];
	r += M4(-4.692e-02, 3.057e-01, -5.997e-02, -2.403e-01, -1.268e-01, -2.322e-01, -3.465e-02, -9.450e-02, 5.978e-02, -1.608e-01, 8.863e-02, 8.028e-02, -1.931e-01, -2.964e-01, 1.263e-01, -2.827e-01) * s1[y+0][x+1];
	r += M4(1.361e-02, -1.479e-01, 1.889e-02, 6.048e-02, -3.536e-02, -7.578e-02, -1.222e-02, -7.416e-02, 1.447e-01, -8.595e-02, 3.323e-03, 1.311e-01, -8.680e-02, -1.690e-05, -5.320e-02, -1.137e-01) * s1[y+0][x+2];
	r += M4(-7.621e-02, -2.378e-01, 1.675e-01, -1.254e-01, 7.207e-01, 1.941e-01, -1.716e-02, -1.453e-01, 5.114e-02, 1.807e-01, -1.684e-01, 1.118e-01, -5.430e-02, 3.633e-02, 4.484e-02, -1.853e-01) * s1[y+1][x+0];
	r += M4(-6.811e-02, -2.228e-02, -3.026e-01, 6.184e-01, -1.075e-01, 2.382e-01, -4.620e-01, 2.753e-01, 7.337e-02, -1.567e-01, -2.404e-01, -3.248e-01, 2.348e-01, -4.416e-01, 3.264e-01, 3.927e-02) * s1[y+1][x+1];
	r += M4(9.720e-02, 1.011e-01, 2.785e-02, 7.206e-02, -1.599e-01, 1.548e-01, 1.851e-01, -5.141e-02, 2.418e-01, -3.572e-01, -9.045e-02, 2.938e-01, -1.069e-01, 1.605e-02, 2.152e-02, -1.330e-01) * s1[y+1][x+2];
	r += M4(2.129e-02, 2.286e-02, 2.849e-02, -8.402e-02, -7.491e-02, -1.616e-01, -2.003e-01, 1.050e-01, 2.878e-02, -2.948e-02, 1.824e-02, 7.007e-02, 1.297e-02, 9.221e-02, 1.315e-02, -4.414e-02) * s1[y+2][x+0];
	r += M4(8.330e-02, 5.274e-02, -5.558e-02, -6.494e-02, -2.009e-02, -3.594e-02, -2.143e-01, 1.055e-01, -3.699e-02, 1.548e-01, -1.372e-02, 1.047e-01, -6.238e-03, -7.602e-02, 8.815e-02, -6.800e-02) * s1[y+2][x+1];
	r += M4(-1.109e-01, -1.032e-02, -3.885e-02, -1.323e-01, -3.640e-02, 4.691e-02, -4.283e-02, -7.260e-02, 3.794e-02, 1.114e-02, 4.734e-02, 1.169e-02, -1.051e-02, -1.389e-02, 2.952e-02, -2.391e-02) * s1[y+2][x+2];
	r += V4(-6.852e-02, 5.331e-02, -4.501e-02, -1.992e-02);
	return vec4(r);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv6
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv5
//!BIND LUMA
//!SAVE conv6
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
#define l0(x, y) V4(texelFetch(conv5_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.588e-02, -3.684e-02, 7.304e-02, 1.522e-01, -8.202e-03, 1.805e-02, 5.734e-02, -3.049e-02, -6.323e-02, -1.097e-01, 7.103e-02, -4.967e-02, 2.095e-02, 2.793e-02, 1.156e-01, 1.274e-01) * s0[y+0][x+0];
	r += M4(1.299e-01, -3.154e-01, 1.835e-01, -4.494e-02, 2.199e-02, -6.904e-02, 8.348e-02, 1.381e-04, -9.212e-02, 1.102e-01, -1.944e-01, 3.477e-01, 2.495e-01, 2.733e-02, -6.482e-02, -1.892e-01) * s0[y+0][x+1];
	r += M4(-9.304e-02, -2.245e-01, 2.918e-01, 4.361e-03, 4.110e-02, 1.791e-02, -5.749e-02, -4.676e-02, -5.873e-02, 2.463e-02, -2.256e-02, 7.118e-03, 1.586e-01, 1.176e-01, -9.607e-02, -1.704e-02) * s0[y+0][x+2];
	r += M4(-1.946e-01, -3.585e-02, -4.470e-03, 5.864e-02, 1.106e-01, 4.429e-03, -7.294e-02, 5.464e-02, -4.134e-02, 7.773e-02, 1.601e-01, 8.581e-02, -1.508e-01, 4.033e-02, 1.734e-01, 1.623e-01) * s0[y+1][x+0];
	r += M4(-3.573e-01, -1.120e-01, 2.784e-01, -2.803e-01, 5.406e-01, 4.804e-02, 3.428e-01, 1.620e-02, 5.330e-01, -7.413e-01, -3.082e-03, 1.809e-01, 2.000e-01, -6.559e-02, 4.696e-01, -6.808e-02) * s0[y+1][x+1];
	r += M4(1.372e-01, -7.521e-02, 1.624e-01, -1.697e-02, 1.093e-02, 7.656e-02, -1.803e-01, 4.227e-02, 3.395e-01, 2.016e-01, -4.131e-01, 9.385e-02, -3.149e-01, -5.984e-02, 7.217e-02, -3.309e-02) * s0[y+1][x+2];
	r += M4(-1.253e-01, -5.541e-02, -1.386e-01, 2.663e-02, 1.119e-01, 5.877e-02, 2.819e-02, -1.724e-02, -1.995e-02, -8.057e-02, 1.314e-01, -1.118e-01, -8.402e-02, -8.325e-02, -1.017e-02, 2.560e-02) * s0[y+2][x+0];
	r += M4(3.118e-01, 1.954e-04, 3.296e-01, 3.328e-02, -1.448e-02, -1.577e-01, 2.309e-01, 3.277e-02, -5.274e-01, -6.279e-02, -2.675e-01, -1.220e-01, 4.930e-01, 6.692e-02, 3.758e-01, 8.215e-02) * s0[y+2][x+1];
	r += M4(-2.552e-01, -7.489e-02, -2.222e-01, -7.404e-02, -6.665e-02, -2.792e-03, -1.305e-01, -1.917e-02, -2.617e-01, -6.548e-02, -8.188e-02, -4.391e-02, 5.349e-02, -5.975e-02, 9.764e-02, -4.667e-02) * s0[y+2][x+2];
	r += M4(-6.709e-02, 1.978e-02, -5.687e-02, 2.387e-02, -1.431e-01, -2.755e-01, -3.593e-02, -4.641e-01, -1.642e-03, -4.615e-02, 1.494e-02, 9.196e-02, 2.144e-02, -1.181e-01, -4.019e-02, -1.821e-01) * s1[y+0][x+0];
	r += M4(-1.025e-01, -7.236e-02, 1.020e-01, 1.052e-01, -1.322e-01, -3.859e-01, 9.589e-02, -2.234e-01, 8.030e-02, 1.015e-01, -1.601e-01, 1.985e-01, -1.259e-01, -5.425e-02, -1.314e-01, -3.105e-01) * s1[y+0][x+1];
	r += M4(-9.616e-02, -1.507e-01, 7.695e-02, 6.530e-02, -2.162e-02, -6.887e-02, 1.418e-02, -8.513e-02, 9.516e-04, 5.325e-02, -1.362e-01, 7.034e-02, -6.295e-03, 1.233e-01, -3.937e-02, 2.670e-02) * s1[y+0][x+2];
	r += M4(-5.803e-02, -2.454e-02, 7.787e-02, 4.110e-02, 8.336e-02, -1.078e-01, -1.024e-01, 4.326e-01, -4.686e-02, 1.566e-02, -3.252e-01, 7.531e-02, -4.550e-02, 1.475e-01, 1.583e-01, 3.134e-01) * s1[y+1][x+0];
	r += M4(-1.608e-01, -2.107e-01, 2.592e-01, -2.329e-01, 5.090e-01, 2.329e-01, 4.483e-01, 9.924e-02, 3.487e-01, -4.543e-01, 2.429e-01, -1.110e-01, 9.169e-02, -3.882e-01, -3.583e-01, 2.871e-01) * s1[y+1][x+1];
	r += M4(1.549e-01, 1.467e-01, -5.028e-02, 4.554e-02, -1.399e-02, 8.204e-02, -2.165e-01, 9.398e-02, 1.304e-01, -1.978e-02, -1.946e-02, -9.337e-03, -1.646e-01, 2.262e-02, 6.397e-02, 8.029e-02) * s1[y+1][x+2];
	r += M4(-7.304e-02, 1.071e-02, 5.999e-03, 4.514e-03, -1.496e-01, 6.720e-02, -1.006e-01, -9.640e-02, -1.415e-01, 2.663e-02, -4.019e-02, -7.642e-02, 6.898e-02, -9.164e-02, 7.028e-02, 5.092e-02) * s1[y+2][x+0];
	r += M4(1.047e-01, -7.088e-02, 2.820e-01, 1.093e-01, -1.038e-01, -1.436e-01, 2.433e-01, 2.900e-02, -6.281e-02, -3.225e-02, 4.852e-02, 2.723e-02, -6.051e-02, 1.058e-01, -1.353e-01, 7.835e-02) * s1[y+2][x+1];
	r += M4(-4.689e-02, -1.851e-02, -6.589e-02, 1.260e-02, -4.965e-02, 2.227e-02, -9.857e-02, 1.260e-02, -2.422e-01, -8.624e-02, -9.229e-02, -1.338e-02, 2.197e-01, 1.020e-01, -5.893e-02, -2.904e-03) * s1[y+2][x+2];
	r += V4(-6.463e-03, -5.590e-02, 3.917e-02, -1.198e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv5_pt;
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv7
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv6
//!BIND LUMA
//!SAVE conv7
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
#define l0(x, y) V4(texelFetch(conv6_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-3.171e-02, 4.097e-02, 9.203e-02, -1.155e-01, 1.544e-02, 1.160e-01, 3.578e-02, -2.808e-03, -3.880e-02, -5.641e-02, -3.236e-02, 2.952e-02, 1.148e-02, -4.940e-02, -1.472e-02, 1.750e-02) * s0[y+0][x+0];
	r += M4(-7.331e-02, -1.747e-01, 1.091e-01, 1.015e-01, 1.087e-01, 2.463e-01, -2.524e-02, -6.057e-02, -9.912e-03, -1.520e-01, -2.904e-02, 9.631e-03, -5.901e-02, -8.033e-02, -2.499e-02, -2.325e-02) * s0[y+0][x+1];
	r += M4(-2.798e-02, -1.794e-01, -2.596e-02, 8.980e-04, 4.188e-02, 7.212e-02, 4.753e-03, 1.949e-02, 2.527e-02, 2.227e-02, -5.665e-02, 4.207e-02, -2.663e-02, 7.891e-02, -4.480e-02, -1.568e-02) * s0[y+0][x+2];
	r += M4(7.939e-02, -2.364e-02, 1.274e-01, 6.639e-02, 2.656e-02, -8.870e-02, 1.412e-01, 2.620e-01, -1.113e-01, 1.220e-01, -1.288e-01, -1.508e-01, 7.083e-03, 9.515e-02, 4.211e-02, -2.845e-02) * s0[y+1][x+0];
	r += M4(-1.678e-01, 2.451e-02, 2.783e-01, -7.247e-03, 5.769e-01, 3.000e-02, -2.133e-02, 9.146e-02, 8.388e-02, 1.709e-03, -2.605e-02, -1.156e-02, -1.554e-01, -1.646e-01, -2.453e-01, 2.751e-01) * s0[y+1][x+1];
	r += M4(-3.897e-02, -9.453e-02, 3.714e-02, -8.727e-02, 9.503e-02, 8.721e-02, 5.902e-02, 4.234e-02, 1.262e-02, 1.489e-01, -1.260e-03, -3.662e-02, 7.194e-03, -1.674e-01, 1.109e-02, 2.578e-02) * s0[y+1][x+2];
	r += M4(6.844e-02, 3.087e-03, -3.589e-02, -5.875e-03, 4.244e-02, 2.460e-02, -1.273e-03, -6.614e-02, -4.916e-02, -1.959e-02, -7.375e-03, 7.495e-02, 9.499e-02, 1.780e-02, 3.529e-02, 1.880e-02) * s0[y+2][x+0];
	r += M4(5.030e-02, -3.941e-03, 5.998e-02, 4.814e-02, 1.627e-01, 5.204e-02, -3.808e-02, -5.816e-02, -3.218e-02, 4.363e-03, -8.823e-02, -5.574e-02, 1.846e-01, -2.215e-01, 2.518e-01, -5.614e-01) * s0[y+2][x+1];
	r += M4(1.790e-03, 4.500e-02, 5.091e-02, -5.834e-02, 5.894e-02, -3.014e-02, 1.947e-02, 7.403e-02, 1.910e-03, -2.690e-02, -6.812e-02, 9.069e-02, -1.146e-01, -1.909e-01, -1.127e-01, -7.384e-02) * s0[y+2][x+2];
	r += M4(9.862e-04, 3.707e-02, 1.411e-01, 3.460e-03, -1.184e-01, 1.939e-01, 5.505e-02, -1.734e-01, -4.774e-02, -1.300e-01, 9.833e-02, 1.044e-02, 3.836e-03, -9.080e-02, -2.135e-03, 5.599e-02) * s1[y+0][x+0];
	r += M4(9.987e-03, -9.347e-01, 1.444e-01, 9.075e-02, 3.414e-02, 3.525e-01, -3.207e-02, -1.215e-01, 1.102e-01, -4.911e-01, 1.998e-02, -1.309e-02, -1.978e-02, -1.825e-01, -4.604e-02, 1.440e-01) * s1[y+0][x+1];
	r += M4(-1.090e-01, -3.035e-01, -8.763e-02, 8.006e-02, 4.075e-02, 7.531e-02, -1.183e-02, -4.094e-03, 5.892e-02, 5.201e-02, 2.271e-02, 7.029e-02, 2.960e-02, 4.957e-02, -3.576e-02, -2.775e-03) * s1[y+0][x+2];
	r += M4(6.255e-02, -2.466e-02, 1.920e-02, 2.820e-01, -1.340e-01, 5.780e-02, 5.742e-02, 1.821e-01, 1.043e-02, -5.659e-03, 1.799e-02, -8.307e-01, 2.613e-02, -1.474e-02, 1.176e-03, -5.701e-02) * s1[y+1][x+0];
	r += M4(-1.546e-01, 1.051e-01, 3.174e-01, 3.385e-02, 6.619e-01, 4.376e-01, 1.746e-02, 3.841e-02, 4.230e-01, -1.862e-01, 7.084e-02, 5.760e-02, -1.815e-01, -2.517e-01, -2.830e-01, 1.303e-01) * s1[y+1][x+1];
	r += M4(-7.009e-02, -1.882e-01, 1.585e-02, -4.357e-02, -5.549e-03, 1.870e-01, -2.334e-03, -6.403e-03, -7.035e-03, 2.074e-01, 1.029e-01, -1.915e-02, -9.536e-02, -7.329e-02, -8.163e-02, 3.357e-02) * s1[y+1][x+2];
	r += M4(3.687e-02, 4.501e-03, -5.531e-03, -6.111e-03, 4.775e-02, 1.266e-02, 1.014e-02, -4.406e-02, -9.497e-02, 5.676e-02, -2.324e-02, -2.126e-02, -2.045e-02, 5.414e-03, 8.214e-03, -4.043e-02) * s1[y+2][x+0];
	r += M4(5.118e-02, -3.094e-02, 1.295e-01, 1.178e-01, 7.171e-02, -1.340e-02, -1.252e-01, 2.231e-02, -1.587e-01, -8.176e-02, -1.795e-02, -1.648e-01, -3.709e-02, -5.383e-02, 3.003e-02, 3.969e-02) * s1[y+2][x+1];
	r += M4(-1.710e-02, 3.989e-02, 8.818e-02, -1.144e-01, 2.053e-02, 9.483e-03, -4.555e-02, 1.072e-01, 7.058e-02, -2.790e-02, -2.875e-02, 1.233e-01, -5.297e-02, -5.036e-02, -1.015e-01, -5.501e-02) * s1[y+2][x+2];
	r += V4(-6.323e-02, -4.846e-02, -1.023e-01, 1.574e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv6_pt;
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-conv8
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv7
//!BIND LUMA
//!SAVE conv8
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
#define l0(x, y) V4(texelFetch(conv7_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(4.386e-02, -3.328e-03, -1.864e-03, -1.871e-02, 3.772e-02, 6.143e-03, 2.218e-03, -9.706e-02, -1.591e-02, -6.380e-03, 1.894e-02, -3.092e-02, 7.062e-04, 1.197e-02, 1.716e-02, -1.965e-02) * s0[y+0][x+0];
	r += M4(-7.819e-03, 4.800e-03, 2.702e-02, -6.684e-02, -1.156e-01, -9.150e-02, -1.411e-01, -1.005e-01, -1.152e-02, -2.155e-02, -2.132e-02, -5.529e-02, 9.665e-03, 8.074e-04, -1.257e-02, -7.175e-02) * s0[y+0][x+1];
	r += M4(7.469e-03, 6.910e-02, 1.997e-01, -2.959e-02, 2.345e-03, 5.761e-02, 7.419e-02, -9.349e-02, -6.726e-02, -1.628e-02, -1.002e-01, 8.367e-03, 1.902e-02, -8.102e-02, -1.431e-01, -1.643e-02) * s0[y+0][x+2];
	r += M4(-3.187e-02, 1.771e-02, -6.140e-03, 1.911e-02, 1.620e-02, 4.028e-02, -4.234e-02, 1.284e-01, -1.724e-02, 3.882e-02, -8.545e-03, 6.426e-02, 2.252e-02, -8.021e-03, -7.908e-04, 7.652e-04) * s0[y+1][x+0];
	r += M4(7.888e-02, 1.382e-02, -7.312e-02, 2.327e-01, -3.055e-01, 3.981e-01, 4.701e-01, 2.744e-01, 6.869e-02, 1.249e-01, 1.107e-01, 2.842e-01, 7.767e-03, 6.047e-02, 2.603e-02, -9.006e-02) * s0[y+1][x+1];
	r += M4(1.348e-01, -2.590e-01, 1.257e+00, -5.116e-01, 2.831e-01, 2.063e-02, 8.486e-02, 1.431e-01, 8.699e-02, -6.178e-02, -8.105e-02, 7.989e-01, -2.662e-01, 5.039e-02, -2.339e-01, -2.564e-02) * s0[y+1][x+2];
	r += M4(-8.464e-04, -7.024e-03, -1.096e-02, -1.309e-02, -2.559e-02, -9.950e-02, -5.408e-02, 1.765e-02, -1.888e-02, 3.172e-02, -4.011e-02, 5.072e-03, 2.681e-02, 5.328e-03, 1.765e-02, -1.979e-02) * s0[y+2][x+0];
	r += M4(7.593e-02, -1.481e-01, 5.924e-02, -1.277e-01, -2.007e-01, -7.715e-01, 8.108e-02, 1.609e-01, 7.501e-02, -1.452e-01, 7.220e-02, -1.515e-02, 4.164e-02, 3.642e-02, -7.723e-03, -4.076e-02) * s0[y+2][x+1];
	r += M4(-1.142e-01, -1.445e-01, -1.522e-02, -6.158e-02, 1.763e-01, -2.193e-01, -5.865e-02, 1.165e-01, 1.067e-01, 6.112e-01, -6.847e-02, -6.765e-02, -6.295e-02, 1.780e-01, -9.614e-02, -1.244e-01) * s0[y+2][x+2];
	r += M4(1.233e-02, 4.586e-03, 3.799e-02, -1.886e-02, 1.463e-02, -7.417e-04, -4.678e-03, -3.603e-02, 1.075e-02, 8.086e-03, 2.240e-02, -6.211e-03, 1.923e-02, -3.894e-02, -1.671e-02, 1.385e-02) * s1[y+0][x+0];
	r += M4(9.799e-03, -1.756e-02, 4.472e-02, -9.448e-02, -2.802e-02, -5.460e-02, -6.320e-02, -6.995e-02, 6.091e-03, -1.692e-02, -3.745e-02, -2.252e-02, -9.658e-02, -2.981e-02, -7.383e-02, -1.685e-01) * s1[y+0][x+1];
	r += M4(-5.183e-03, 6.068e-02, 9.500e-02, -8.651e-02, -1.956e-02, -1.714e-03, -1.551e-02, -6.424e-02, 2.418e-04, -4.008e-02, -1.089e-01, -3.555e-02, -5.864e-02, -5.237e-02, -9.421e-02, -9.292e-03) * s1[y+0][x+2];
	r += M4(-1.001e-02, 1.098e-02, 2.416e-03, 9.644e-04, -3.031e-02, -1.938e-02, -1.389e-01, 1.247e-01, -2.773e-02, 8.697e-03, 4.040e-02, 5.053e-02, 4.932e-03, -1.714e-02, 1.150e-02, 2.416e-02) * s1[y+1][x+0];
	r += M4(9.892e-02, 5.506e-02, -1.191e-01, 1.609e-01, 2.667e-02, 2.920e-01, 2.167e-01, 3.281e-01, 1.231e-01, 1.151e-01, 6.812e-02, 1.872e-01, 9.007e-02, 4.712e-02, -2.416e-01, 1.691e-02) * s1[y+1][x+1];
	r += M4(-7.726e-03, -1.034e-01, 2.777e-01, -2.682e-01, 2.136e-02, -1.194e-02, -2.728e-01, 8.142e-02, -2.485e-02, -7.730e-02, -4.269e-02, 2.823e-01, -9.318e-01, -7.445e-02, -1.441e-01, -3.113e-01) * s1[y+1][x+2];
	r += M4(2.113e-02, 1.463e-02, -5.946e-03, -1.838e-02, -3.333e-02, -9.818e-03, -2.911e-02, -9.191e-03, -2.419e-02, -4.627e-02, -1.094e-02, -8.102e-03, 2.982e-02, -4.446e-02, 3.916e-02, -3.722e-02) * s1[y+2][x+0];
	r += M4(5.300e-02, 8.082e-02, 2.761e-02, -1.124e-01, 3.488e-03, -5.288e-01, 2.074e-01, 5.904e-02, 4.479e-02, -2.252e-01, 1.212e-02, -1.822e-02, -1.801e-02, -7.005e-02, -3.475e-02, -7.642e-02) * s1[y+2][x+1];
	r += M4(-8.872e-02, 1.174e-01, -3.847e-02, -5.465e-02, 2.686e-01, 8.127e-02, -9.349e-02, 1.528e-01, -1.303e-01, 1.112e-01, -1.212e-01, -9.167e-02, -8.921e-02, 1.058e-01, -1.238e-01, 5.050e-02) * s1[y+2][x+2];
	r += V4(2.697e-02, -2.620e-02, 1.365e-02, 1.493e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv7_pt;
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv8
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
#define l0(x, y) V4(texelFetch(conv8_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(9.498e-02, 9.258e-03, -1.240e-02, 2.153e-02, -8.885e-03, 2.393e-02, -1.460e-01, -6.622e-02, 8.703e-03, -2.496e-02, 9.836e-03, -7.654e-03, 9.676e-03, 2.816e-02, 3.034e-03, 1.376e-02) * s0[y+0][x+0];
	r += M4(6.171e-02, 1.672e-01, -1.187e-01, -1.091e-01, -3.470e-01, -2.098e-01, 2.274e-01, -2.768e-02, 1.348e-02, 9.255e-02, -1.536e-02, 2.085e-02, 7.135e-02, 4.330e-03, 7.695e-02, 2.132e-02) * s0[y+0][x+1];
	r += M4(2.223e-02, 1.500e-02, 3.171e-04, -1.993e-02, -2.124e-02, -1.638e-01, -6.470e-02, 1.343e-01, -2.699e-02, -7.039e-02, 1.728e-02, -8.560e-03, -4.456e-02, -2.620e-02, 6.443e-03, 2.984e-02) * s0[y+0][x+2];
	r += M4(-3.017e-02, 8.701e-03, 1.221e-01, -2.501e-02, -6.568e-02, -4.995e-02, 3.515e-03, -6.045e-02, -3.579e-02, 9.910e-02, -3.285e-02, 3.432e-02, 1.315e-02, 1.190e-01, -2.422e-02, 6.658e-02) * s0[y+1][x+0];
	r += M4(-8.375e-02, -4.915e-03, 2.163e-01, 4.020e-01, 1.862e-01, 3.916e-02, -2.706e-01, -5.850e-03, -2.392e-02, -3.139e-01, 1.314e-01, -4.738e-02, -2.627e-01, -4.678e-01, -4.424e-01, -4.771e-01) * s0[y+1][x+1];
	r += M4(-5.019e-02, -1.434e-01, -8.699e-03, -3.593e-02, 3.458e-03, 1.334e-01, 1.607e-02, -2.091e-01, 1.168e-02, 1.450e-01, -2.977e-02, 6.763e-02, 1.272e-01, 2.433e-01, 5.271e-03, -4.706e-02) * s0[y+1][x+2];
	r += M4(-2.091e-03, 1.777e-02, -6.411e-02, 4.248e-03, -9.250e-03, -1.446e-02, 7.730e-04, -6.090e-04, 2.269e-03, -6.078e-02, 3.997e-02, -1.335e-03, -9.795e-03, -2.981e-02, 1.226e-02, 3.773e-02) * s0[y+2][x+0];
	r += M4(-1.971e-02, -4.211e-02, -1.018e-01, -1.367e-01, -1.144e-02, 1.511e-02, 3.646e-02, 1.945e-02, 6.056e-02, 1.211e-01, 4.047e-02, 5.089e-02, 6.840e-03, 3.653e-02, 5.049e-02, -5.514e-02) * s0[y+2][x+1];
	r += M4(4.885e-03, 1.600e-02, -7.775e-03, -3.063e-02, -2.142e-02, -4.789e-02, -2.402e-03, -3.576e-04, 8.643e-03, 8.471e-03, 1.825e-02, 4.576e-02, -6.271e-03, -3.567e-02, 4.248e-03, 9.129e-02) * s0[y+2][x+2];
	r += M4(-1.052e-02, 9.564e-04, 7.093e-02, 3.676e-02, -5.288e-02, 2.005e-02, -9.063e-02, -8.112e-02, -1.362e-02, -2.352e-02, 2.353e-02, -1.626e-02, 2.739e-02, 2.529e-02, -1.375e-02, 1.017e-02) * s1[y+0][x+0];
	r += M4(-3.840e-02, 2.835e-01, -1.111e-01, -9.007e-02, -2.689e-01, -3.435e-01, 5.581e-02, -2.323e-02, 8.745e-02, 1.616e-02, -6.591e-02, -3.070e-02, 3.664e-02, 1.664e-02, 5.131e-02, -6.225e-04) * s1[y+0][x+1];
	r += M4(5.785e-02, -2.228e-02, -9.526e-03, 3.193e-02, -2.516e-02, -3.913e-02, -2.793e-03, 4.602e-02, -1.557e-02, 1.508e-02, 1.060e-02, 6.653e-03, -6.323e-02, -3.948e-02, -7.388e-03, 1.818e-02) * s1[y+0][x+2];
	r += M4(6.088e-02, 4.190e-02, -1.659e-02, 1.946e-02, -2.156e-02, -2.610e-02, -3.383e-02, -2.777e-02, -3.613e-02, 2.644e-01, -1.060e-01, 1.077e-01, 5.036e-03, 6.872e-02, 5.047e-02, 6.218e-02) * s1[y+1][x+0];
	r += M4(-2.721e-01, 2.748e-01, -1.329e-01, 6.645e-01, 1.812e-02, -1.786e-02, -2.228e-02, -8.095e-02, 4.894e-01, -8.784e-01, 3.975e-01, -4.500e-01, -4.461e-01, -4.208e-01, -1.952e-01, -1.685e-01) * s1[y+1][x+1];
	r += M4(4.492e-02, -1.284e-01, 6.277e-02, -2.358e-01, -1.623e-02, 1.837e-02, 1.753e-03, 4.601e-02, -1.648e-01, 1.233e-01, -1.013e-01, 8.008e-02, 1.536e-01, 4.321e-02, 5.521e-02, 8.024e-04) * s1[y+1][x+2];
	r += M4(-1.735e-02, 2.581e-02, -1.034e-02, 2.423e-02, -1.598e-02, -3.773e-02, 1.619e-02, 1.805e-03, 1.346e-02, -4.760e-02, -6.337e-03, 7.841e-02, 2.241e-03, -4.553e-02, 4.404e-02, 6.858e-04) * s1[y+2][x+0];
	r += M4(-3.607e-02, -3.797e-02, -2.178e-01, -1.679e-01, 1.524e-02, 3.899e-02, 9.724e-03, 2.906e-02, 1.372e-01, 4.427e-02, 4.062e-01, -3.169e-01, 6.893e-02, 8.080e-02, -8.790e-02, -4.034e-02) * s1[y+2][x+1];
	r += M4(-2.937e-02, 8.498e-03, -3.473e-03, 1.191e-02, -8.214e-03, -1.766e-02, -1.379e-02, -1.482e-02, 3.156e-02, -7.511e-03, -8.100e-02, 5.121e-02, -2.603e-02, 1.371e-02, 4.096e-02, 2.665e-02) * s1[y+2][x+2];
	r += V4(-7.586e-03, -8.515e-03, -4.629e-03, -5.539e-03);
	return tanh(vec4(r));
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv8_pt;
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-8x4C-RCAS-DS-shuffle
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

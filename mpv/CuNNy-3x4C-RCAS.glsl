// CuNNy 3x4C RCAS
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


//!DESC CuNNy-3x4C-RCAS-in
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
	r += V4(-2.333e-03, 1.835e-01, -1.086e-01, 6.796e-02) * s0[y+0][x+0];
	r += V4(-5.612e-02, 4.677e-01, -4.766e-02, -3.037e-01) * s0[y+0][x+1];
	r += V4(-1.462e-02, -1.821e-01, 3.857e-01, -1.169e-02) * s0[y+0][x+2];
	r += V4(-1.894e-02, -2.243e-01, 1.821e-01, 1.182e-02) * s0[y+1][x+0];
	r += V4(7.714e-01, -4.695e-01, -6.191e-01, -1.276e-01) * s0[y+1][x+1];
	r += V4(-2.128e-02, 2.239e-01, 2.163e-01, 6.257e-02) * s0[y+1][x+2];
	r += V4(-2.704e-02, 6.854e-02, -6.682e-02, 1.137e-01) * s0[y+2][x+0];
	r += V4(3.625e-02, -5.467e-02, 9.105e-02, 1.741e-01) * s0[y+2][x+1];
	r += V4(-2.880e-02, -1.266e-02, -3.533e-02, 1.264e-01) * s0[y+2][x+2];
	r += V4(-1.000e-02, 1.171e-03, -7.211e-04, -1.686e-02);
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


//!DESC CuNNy-3x4C-RCAS-conv1
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
	r += M4(-7.946e-03, 1.010e-01, 2.042e-02, 4.408e-02, 8.002e-02, -1.771e-01, -1.292e-02, 6.439e-02, 3.243e-01, -3.128e-01, 1.267e-02, 8.466e-02, 1.252e-01, 1.854e-01, 1.322e-02, -1.637e-01) * s0[y+0][x+0];
	r += M4(1.573e-01, -6.697e-02, -7.607e-02, -6.713e-02, -6.041e-02, 2.776e-01, -1.044e-02, -4.667e-01, -3.141e-01, -2.010e-01, -6.458e-02, -2.761e-01, -6.569e-02, 2.648e-01, 9.601e-03, -7.494e-02) * s0[y+0][x+1];
	r += M4(-4.700e-02, -7.585e-02, -2.408e-01, 4.188e-02, 2.061e-01, 2.602e-01, -8.846e-02, -2.769e-01, 3.715e-01, -9.148e-02, -1.019e-01, -3.512e-01, -9.376e-02, -3.726e-01, -1.058e-01, -1.412e-01) * s0[y+0][x+2];
	r += M4(1.575e-01, -1.938e-01, 1.132e-02, -1.053e-02, 4.111e-01, -2.219e-01, 1.898e-02, -3.193e-02, 2.434e-01, -4.950e-01, 4.538e-02, 1.615e-01, -4.464e-01, 9.761e-02, 1.467e-02, 1.265e-01) * s0[y+1][x+0];
	r += M4(-2.173e-01, -9.000e-02, -1.841e-01, -7.412e-02, 4.552e-01, 6.309e-02, -1.754e-02, -7.400e-02, 7.882e-01, -2.161e-01, -1.098e-01, 1.244e+00, -4.416e-01, -2.520e-02, 7.869e-02, 2.059e-01) * s0[y+1][x+1];
	r += M4(-6.394e-03, 1.882e-01, -2.910e-01, 1.223e-01, 1.133e-02, -5.563e-02, 1.157e-01, 8.046e-02, 1.966e-02, 1.320e-01, 2.900e-01, -1.727e-01, 8.429e-01, -3.306e-03, -1.862e-04, -1.682e-01) * s0[y+1][x+2];
	r += M4(1.384e-01, -1.189e-01, -5.299e-02, -1.193e-01, 3.142e-03, -9.783e-02, -7.339e-02, -1.248e-01, -1.171e-01, -3.669e-04, -6.275e-02, 1.737e-02, 1.762e-01, -3.604e-02, -4.773e-02, -4.109e-02) * s0[y+2][x+0];
	r += M4(-1.152e-01, -1.317e-01, 2.021e-02, 1.369e-01, -1.135e-01, 1.635e-01, 1.490e-01, 2.698e-01, -1.869e-01, -3.822e-01, -1.724e-01, 2.645e-01, -1.277e-01, -8.308e-03, 8.902e-03, -9.589e-02) * s0[y+2][x+1];
	r += M4(-4.026e-02, 9.433e-02, -2.768e-02, -2.167e-02, -2.537e-01, -1.537e-01, 4.215e-03, 7.512e-02, -1.173e-01, -1.315e-02, -9.167e-02, 1.047e-01, -1.357e-01, 5.072e-02, 4.013e-02, 7.232e-02) * s0[y+2][x+2];
	r += M4(-1.910e-01, 8.734e-01, 1.268e-01, 7.398e-01, -5.078e-02, -6.680e-02, 6.982e-03, 1.165e-01, 1.983e-01, -2.139e-01, 2.765e-02, -1.707e-02, 4.494e-01, 1.846e-02, 2.541e-02, -2.496e-01) * s1[y+0][x+0];
	r += M4(1.100e+00, -1.168e+00, -9.741e+00, -1.080e-01, -4.122e-01, 3.119e-01, -6.691e-03, 1.502e-01, -5.158e-01, -1.636e-01, -4.856e-02, 5.463e-02, -2.756e-01, 4.036e-01, -1.371e-01, 3.155e-01) * s1[y+0][x+1];
	r += M4(-8.517e-01, 1.028e+00, -6.984e+00, 3.177e-01, 1.229e-01, -1.149e-02, -4.884e-02, 1.488e-01, 1.190e-01, -3.221e-03, -4.560e-02, -8.340e-02, -9.656e-02, -4.913e-01, -3.263e-01, -4.632e-02) * s1[y+0][x+2];
	r += M4(-6.870e-01, 1.031e+00, 1.673e-01, -4.490e-01, 1.008e-01, -2.013e-01, 2.857e-02, -1.704e-01, 8.329e-02, -3.249e-01, 7.399e-02, -4.508e-01, -3.271e-01, -5.060e-02, 2.720e-03, 3.059e-01) * s1[y+1][x+0];
	r += M4(-9.318e-01, -1.178e+00, -1.519e+01, -9.849e-01, -4.782e-01, 2.979e-01, -2.052e-02, -2.160e-01, 5.228e-01, 2.886e-01, 3.583e-02, 3.567e-01, -4.778e-01, -5.282e-02, 5.090e-02, -1.326e-02) * s1[y+1][x+1];
	r += M4(-1.013e+00, 4.662e-01, -8.282e+00, -1.925e-01, 1.220e-01, 2.585e-02, 2.615e-01, -5.922e-01, -1.029e-01, 6.724e-02, 1.460e-01, 9.740e-02, 8.847e-01, 1.516e-01, -5.471e-03, -3.408e-01) * s1[y+1][x+2];
	r += M4(-6.869e-01, 1.268e+00, 2.448e-02, -4.323e-01, -1.339e-01, -1.449e-01, -6.500e-02, -3.308e-01, -1.950e-02, -5.918e-01, -7.414e-03, -2.134e-01, 1.346e-01, -6.808e-02, -4.350e-02, -1.969e-02) * s1[y+2][x+0];
	r += M4(-1.032e+00, 1.150e+00, 2.163e-02, -6.230e-01, -3.773e-01, -3.721e-01, 1.181e-01, 1.561e-01, -3.674e-01, -3.023e-01, -4.217e-02, -2.735e-01, -1.534e-01, 1.120e-02, 2.351e-02, -1.610e-02) * s1[y+2][x+1];
	r += M4(-3.517e-01, 6.303e-01, -3.365e-02, 2.847e-01, -1.676e-01, -1.783e-01, -2.721e-02, 6.616e-02, -2.588e-01, 7.243e-02, -1.080e-01, 1.714e-01, -1.632e-02, 3.482e-03, 9.956e-03, 6.342e-02) * s1[y+2][x+2];
	r += V4(-6.446e-03, 2.896e-02, 5.087e-01, -1.247e-02);
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


//!DESC CuNNy-3x4C-RCAS-conv2
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
	r += M4(8.265e-02, 1.744e-02, 1.379e-01, -4.022e-03, -1.782e-01, -1.251e-01, 4.216e-02, -3.536e-03, 2.986e-02, 2.620e-02, 7.340e-02, 2.006e-02, 2.922e-02, 4.460e-02, 1.919e-01, -2.365e-02) * s0[y+0][x+0];
	r += M4(-4.349e-02, -1.846e-01, -4.990e-02, 1.723e-01, 7.152e-02, 6.928e-02, 4.609e-02, 1.871e-01, -5.726e-02, -5.389e-02, -6.568e-02, 8.540e-03, -1.213e-01, -2.368e-01, -4.793e-03, 1.636e-01) * s0[y+0][x+1];
	r += M4(-4.107e-02, -6.970e-02, 6.757e-03, 1.116e-01, 6.417e-02, 2.747e-02, 3.989e-02, 1.756e-01, 2.255e-02, 3.058e-02, 1.695e-02, 9.183e-04, 8.058e-02, -4.220e-03, -8.520e-02, 1.080e-01) * s0[y+0][x+2];
	r += M4(-1.186e-01, -1.884e-02, 3.096e-01, -8.937e-03, 5.139e-02, 1.462e-02, -3.164e-01, 5.618e-02, -9.133e-02, -2.261e-02, -9.450e-02, 1.105e-02, 1.145e-01, 8.273e-02, 3.467e-01, -1.898e-03) * s0[y+1][x+0];
	r += M4(4.614e-01, 2.587e-01, -5.615e-01, -2.552e-01, 6.809e-03, -4.206e-02, 2.626e-01, -5.758e-01, 2.114e-01, 6.650e-02, -6.365e-02, -2.153e-01, 4.407e-02, -3.621e-02, -3.848e-01, -4.312e-02) * s0[y+1][x+1];
	r += M4(2.549e-01, 1.537e-02, -1.382e-01, 1.469e-01, -1.968e-01, 6.419e-03, 1.013e-01, 2.462e-01, -4.036e-02, -2.498e-02, 4.934e-02, -3.360e-02, 1.732e-01, 1.668e-02, 7.851e-02, 1.440e-01) * s0[y+1][x+2];
	r += M4(-8.247e-03, 5.862e-02, -6.893e-02, -1.157e-01, 1.328e-01, 6.821e-03, -1.471e-01, 7.571e-02, 3.920e-02, 2.012e-03, -3.357e-02, -1.508e-02, -8.355e-02, -3.765e-02, 2.329e-01, -7.064e-02) * s0[y+2][x+0];
	r += M4(-3.665e-01, -1.911e-02, 1.470e-01, 1.116e-01, 1.110e-01, -1.158e-01, 1.705e-01, 4.173e-02, 1.117e-02, -1.040e-02, 3.943e-02, 9.030e-03, -4.325e-01, -1.636e-01, -1.610e-01, -1.981e-01) * s0[y+2][x+1];
	r += M4(-4.281e-02, 5.651e-02, -2.569e-01, -7.834e-02, 5.530e-02, -1.513e-03, 7.544e-02, 1.626e-01, -3.099e-02, -5.828e-03, 1.543e-03, 3.643e-02, -4.160e-02, -7.462e-02, -2.260e-02, -7.544e-02) * s0[y+2][x+2];
	r += M4(5.442e-02, -4.906e-02, -1.679e-01, 1.328e-01, -3.082e-02, 7.499e-03, 7.101e-02, 2.643e-02, 6.900e-01, 1.766e-01, 2.037e-02, 6.193e-01, 4.458e-02, 4.383e-02, 1.611e-01, -6.183e-02) * s1[y+0][x+0];
	r += M4(3.036e-01, -2.397e-01, -1.918e-01, 2.640e-01, 2.237e-01, -4.744e-02, -3.094e-02, 2.117e-01, -5.985e-01, -3.347e-01, -7.711e-02, -8.027e-01, -8.093e-02, -1.248e-01, -3.479e-02, 1.771e-01) * s1[y+0][x+1];
	r += M4(1.743e-01, -2.711e-01, 3.289e-02, 4.920e-02, -6.134e-02, 4.736e-02, 3.016e-02, 2.169e-01, -1.344e+00, -3.950e-01, 4.156e-01, 6.607e-02, 2.387e-02, -3.642e-02, -3.149e-02, 5.299e-02) * s1[y+0][x+2];
	r += M4(1.039e-01, -1.325e-02, 1.041e-01, -2.944e-02, 4.359e-02, -2.217e-04, 3.175e-01, 1.066e-01, 1.632e+00, 1.050e+01, -2.657e+00, -3.750e+00, -3.196e-02, -5.600e-02, 6.151e-01, 5.734e-02) * s1[y+1][x+0];
	r += M4(5.033e-01, 3.058e-01, -6.219e-01, -2.680e-01, 4.558e-01, 3.848e-02, -2.203e-01, -4.810e-01, 1.116e+00, 7.808e+00, -2.258e+00, 1.327e+00, 8.297e-02, 3.218e-02, -3.755e-01, -4.921e-02) * s1[y+1][x+1];
	r += M4(2.737e-01, -2.541e-01, -1.012e-01, -1.243e-01, -3.213e-01, -5.042e-02, 1.537e-01, 3.932e-01, -5.324e-01, 2.819e-01, 7.711e-01, 2.520e-02, 1.810e-01, 3.934e-02, -1.303e-01, 1.040e-01) * s1[y+1][x+2];
	r += M4(6.248e-02, -2.057e-02, 3.047e-03, -5.625e-02, -6.776e-02, 4.128e-02, 8.373e-02, -2.000e-02, -9.223e-01, 1.193e+00, 8.437e-01, 9.366e-01, -2.024e-01, 1.776e-01, 2.933e-01, -1.212e-01) * s1[y+2][x+0];
	r += M4(2.143e-02, 2.297e-02, -6.987e-03, 2.415e-01, -4.491e-01, -2.835e-02, -1.093e-01, 7.170e-02, -4.799e-01, -2.939e-01, 7.814e-01, 1.686e+00, -6.111e-02, 1.362e-01, -1.020e-01, -2.665e-01) * s1[y+2][x+1];
	r += M4(3.464e-01, -5.044e-02, -1.356e-01, -1.348e-01, -1.541e-01, -1.010e-02, -2.951e-02, 1.385e-02, -1.881e-01, -4.570e-01, 2.028e-01, 7.774e-01, 4.402e-03, 1.088e-01, -5.940e-02, -8.159e-02) * s1[y+2][x+2];
	r += V4(-3.613e-02, -7.869e-04, 3.653e-02, 7.886e-02);
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


//!DESC CuNNy-3x4C-RCAS-conv3
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
	r += M4(-1.261e-02, -1.320e-01, -1.036e-01, 6.616e-02, 3.797e-02, 2.248e-01, 1.619e-01, -3.377e-02, 1.890e-01, -5.503e-02, -5.457e-02, -1.134e-01, -1.461e-01, 2.216e-02, 5.193e-02, -3.942e-03) * s0[y+0][x+0];
	r += M4(1.665e-01, 4.250e-02, -7.392e-02, 4.003e-02, -2.838e-01, 3.790e-03, 1.401e-01, 6.540e-02, 1.782e-01, 7.624e-02, -1.162e-02, -1.375e-01, -2.574e-02, -6.909e-02, 1.239e-02, -2.170e-02) * s0[y+0][x+1];
	r += M4(2.720e-02, 6.828e-03, -2.972e-02, 1.591e-02, -4.045e-01, -9.868e-02, 9.219e-02, 6.746e-04, 9.367e-02, 7.154e-02, -5.759e-03, 2.822e-02, -2.667e-02, -1.441e-02, -2.580e-02, -5.145e-02) * s0[y+0][x+2];
	r += M4(1.163e-01, -3.654e-01, -1.479e-01, -1.033e-01, -5.411e-01, 3.714e-01, 6.526e-02, 6.270e-01, -1.208e-01, -4.323e-02, -1.055e-01, 5.523e-02, 1.338e-01, 1.392e-01, 1.695e-01, -1.554e-01) * s0[y+1][x+0];
	r += M4(-3.966e-01, -8.569e-02, -5.169e-02, -2.307e-01, -2.377e-01, 9.028e-01, 3.721e-01, 7.006e-01, -2.332e-01, 2.310e-01, 1.274e-01, -1.015e-01, 1.162e-01, 6.487e-02, -1.275e-01, 1.219e-01) * s0[y+1][x+1];
	r += M4(-2.658e-02, -9.032e-03, 7.320e-03, -2.788e-02, -9.210e-02, -7.830e-01, -4.905e-01, 6.444e-01, -4.852e-01, -1.549e-01, 1.841e-01, 5.103e-01, 1.561e-03, -8.057e-02, 2.124e-02, 2.562e-02) * s0[y+1][x+2];
	r += M4(1.141e-01, -2.272e-01, -1.420e-01, -1.609e-02, -9.692e-02, 1.675e-01, 2.529e-01, 5.139e-02, 3.335e-02, 1.660e-02, 5.801e-02, -4.606e-02, -1.138e-01, 1.819e-01, -5.588e-03, 3.937e-02) * s0[y+2][x+0];
	r += M4(2.842e-01, -1.160e-01, -1.907e-02, 2.093e-01, -1.047e-01, 1.101e-01, 1.401e-01, -1.127e-02, 7.180e-02, -4.384e-02, 3.650e-03, -6.562e-03, -1.046e-01, 9.921e-04, -6.076e-02, 4.176e-02) * s0[y+2][x+1];
	r += M4(-3.899e-02, -8.557e-02, 4.091e-02, 1.759e-01, 9.818e-02, 6.157e-02, -8.311e-02, -2.842e-01, 1.212e-01, -6.283e-03, 1.035e-01, 9.849e-02, -3.492e-02, -6.091e-02, -5.485e-02, 1.616e-02) * s0[y+2][x+2];
	r += M4(-1.333e-01, 5.686e-02, 1.204e-02, 7.520e-02, 1.141e-01, -1.111e-02, -3.430e-03, -6.544e-02, -7.120e-03, 3.448e-01, 2.100e-01, -7.739e-02, -1.834e-03, 1.705e-01, 8.366e-02, -2.248e-02) * s1[y+0][x+0];
	r += M4(1.381e-03, 2.026e-01, 1.267e-01, -1.685e-01, -2.202e-01, 6.861e-03, 5.165e-02, -1.134e-01, 2.082e-01, -2.666e-01, -1.208e-01, 1.489e-01, 1.977e-01, 2.919e-01, 9.498e-02, 3.785e-02) * s1[y+0][x+1];
	r += M4(4.820e-02, -1.215e-01, -1.007e-02, 5.815e-02, -1.089e-01, 1.249e-02, 3.729e-02, 3.460e-02, 1.129e-01, 9.448e-02, -5.093e-02, -3.301e-02, 9.829e-02, -2.932e-02, -9.054e-02, 2.866e-02) * s1[y+0][x+2];
	r += M4(-1.907e-01, 6.588e-02, 4.140e-02, 1.895e-01, -1.313e-01, -3.057e-02, -8.500e-02, 1.772e-01, -2.518e-02, 4.972e-02, 5.114e-02, -1.112e-01, 4.917e-02, 7.795e-02, 7.274e-03, -4.231e-02) * s1[y+1][x+0];
	r += M4(-5.983e-02, 3.818e-01, 6.064e-02, 5.574e-03, -4.802e-01, 1.581e-01, 2.477e-01, -7.419e-02, -4.756e-01, -3.289e-02, -1.081e-01, 2.445e-01, -2.683e-02, 1.801e-01, -1.104e-01, 1.104e-03) * s1[y+1][x+1];
	r += M4(1.113e-02, -1.025e-01, -3.456e-02, -2.768e-02, -6.816e-02, -9.415e-02, 1.051e-02, 1.098e-01, -2.065e-01, 5.095e-03, 1.595e-01, 1.478e-01, -1.690e-01, -2.413e-01, 1.772e-01, 6.118e-01) * s1[y+1][x+2];
	r += M4(2.342e-02, -2.136e-02, 3.401e-02, 7.518e-02, 1.895e-02, 1.014e-02, 8.277e-02, -4.139e-02, 1.425e-02, -3.453e-02, -3.852e-02, -5.205e-02, 1.051e-02, 3.650e-02, -8.318e-03, -5.320e-02) * s1[y+2][x+0];
	r += M4(-5.456e-02, 9.123e-02, -8.348e-03, -3.815e-02, 8.305e-02, -1.254e-01, 7.121e-02, 8.911e-02, 1.716e-01, -9.322e-02, 2.411e-02, 2.855e-02, -2.314e-02, -3.376e-03, -9.098e-03, -3.226e-02) * s1[y+2][x+1];
	r += M4(-6.111e-02, -1.310e-02, -2.587e-02, -6.828e-03, 8.261e-02, 4.605e-02, -3.174e-02, -1.781e-01, 5.316e-02, -1.670e-02, -5.444e-02, -4.478e-03, 4.867e-02, -4.768e-02, 1.119e-01, 1.467e-01) * s1[y+2][x+2];
	r += V4(1.825e-02, -1.309e-02, -1.936e-02, -1.631e-02);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-3x4C-RCAS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv3
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
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(1.612e-02, 1.246e-02, 1.743e-02, -2.097e-02, -1.656e-01, 1.836e-02, -2.066e-02, 3.241e-02, 3.782e-01, -2.685e-01, -1.434e-01, -2.370e-01, -5.365e-02, -8.715e-02, 7.452e-03, -2.657e-02) * s0[y+0][x+0];
	r += M4(-6.109e-02, -8.032e-02, -6.288e-02, -9.492e-03, 1.418e-01, 3.729e-02, 1.109e-01, 5.617e-02, -6.740e-01, 2.800e-01, -3.018e-01, 7.651e-02, -2.426e-01, -8.671e-02, 9.045e-02, 1.275e-01) * s0[y+0][x+1];
	r += M4(-1.094e-02, -1.223e-02, 1.250e-02, -3.431e-02, 7.207e-02, 7.849e-02, 3.460e-02, 8.923e-02, 1.857e-01, -4.435e-02, 1.744e-01, -1.031e-01, 1.162e-01, 3.471e-02, -1.772e-02, 1.443e-02) * s0[y+0][x+2];
	r += M4(1.704e-01, 5.661e-02, 9.507e-02, 6.635e-02, -5.562e-01, 2.517e-01, -4.528e-01, 1.402e-02, 3.623e-01, 1.226e-01, 1.066e+00, 1.478e-02, 4.449e-01, 7.516e-03, 2.056e-01, -5.314e-02) * s0[y+1][x+0];
	r += M4(1.139e-01, 1.147e-01, 6.012e-02, 4.552e-04, 7.269e-01, -3.312e-01, 2.408e-01, -7.051e-02, 1.897e-01, -8.508e-01, -5.449e-01, 9.918e-02, 9.677e-02, 7.988e-01, -6.504e-01, 8.104e-02) * s0[y+1][x+1];
	r += M4(-2.427e-02, 5.163e-02, -1.429e-02, 5.851e-02, -2.741e-01, -9.674e-02, -9.102e-04, -9.509e-02, -3.682e-01, 4.385e-01, -1.198e-01, 2.931e-01, 8.978e-02, -1.395e-01, 1.081e-01, -3.226e-01) * s0[y+1][x+2];
	r += M4(1.213e-01, 5.637e-02, 2.210e-01, 1.234e-01, 2.686e-01, 2.398e-02, 3.739e-02, 2.823e-01, -1.733e-01, 9.659e-02, -3.743e-01, 1.386e-01, -4.995e-02, -1.443e-02, -1.409e-03, -1.128e-01) * s0[y+2][x+0];
	r += M4(-1.776e-02, 1.039e-02, 1.068e-01, 1.379e-01, 1.958e-01, -3.132e-01, 8.262e-01, -5.215e-01, 1.098e-01, 6.665e-02, 3.856e-01, -4.885e-01, -1.411e-01, -1.630e-02, 1.448e-01, 3.790e-01) * s0[y+2][x+1];
	r += M4(-2.084e-03, -9.474e-03, -1.150e-02, 3.966e-02, -5.174e-02, 2.397e-01, -2.262e-01, 2.925e-01, 2.283e-02, 2.407e-03, -2.148e-01, 1.848e-01, 5.039e-02, -3.343e-02, 5.266e-02, 2.569e-02) * s0[y+2][x+2];
	r += M4(5.540e-02, -1.332e-04, 5.910e-02, -9.810e-02, -4.484e-02, -4.103e-03, 4.381e-02, 4.730e-02, 3.056e-02, -1.115e-03, -5.655e-02, -9.970e-02, -4.238e-02, 1.416e-02, -8.282e-02, -5.242e-02) * s1[y+0][x+0];
	r += M4(-4.253e-01, -1.990e-01, 1.720e-01, 2.184e-01, 1.101e-01, 1.229e-01, 9.836e-02, 1.171e-01, -1.927e-01, -2.410e-01, -6.372e-02, -8.764e-02, 1.800e-02, -6.973e-02, 7.401e-02, -2.859e-03) * s1[y+0][x+1];
	r += M4(7.049e-03, -1.516e-01, 3.320e-04, 9.654e-02, 7.153e-02, 6.878e-02, 1.242e-03, 4.677e-02, 1.629e-03, 1.192e-02, 5.419e-03, 2.857e-03, 1.425e-02, 2.903e-02, -8.044e-03, 2.700e-02) * s1[y+0][x+2];
	r += M4(1.772e-01, 9.161e-03, -1.090e-01, 8.307e-02, -9.036e-02, -9.608e-02, -2.558e-01, -2.027e-01, 2.513e-01, 2.005e-01, 3.791e-01, 3.717e-01, 2.212e-01, 9.242e-03, 2.416e-01, 1.509e-01) * s1[y+1][x+0];
	r += M4(8.263e-01, 5.931e-01, -4.151e-01, -5.957e-01, 1.519e-01, 1.616e-01, -1.036e-01, -5.652e-02, -2.044e-01, -2.416e-01, -1.121e-01, -1.978e-01, 1.059e-01, 3.154e-01, -1.116e-01, 6.587e-02) * s1[y+1][x+1];
	r += M4(-1.811e-01, 2.703e-01, 4.826e-03, 5.394e-03, -1.119e-01, -8.946e-02, -1.150e-02, -1.173e-01, -1.670e-03, 4.840e-02, 9.307e-03, 6.761e-02, -5.260e-02, -1.102e-01, 2.709e-02, -8.032e-02) * s1[y+1][x+2];
	r += M4(4.395e-03, 4.659e-02, 4.395e-01, 9.617e-02, 7.985e-02, 4.287e-02, 1.096e-01, 5.693e-02, -7.960e-02, -3.170e-02, -5.631e-02, -4.039e-02, -4.796e-02, -4.349e-03, -2.727e-02, -7.605e-02) * s1[y+2][x+0];
	r += M4(-3.196e-01, -2.387e-01, 7.915e-02, 5.034e-01, 1.072e-02, -3.691e-04, 2.397e-01, 2.037e-01, 5.989e-02, 2.609e-02, -9.108e-02, -9.888e-02, 3.409e-02, -4.208e-02, 2.105e-01, 1.636e-01) * s1[y+2][x+1];
	r += M4(1.825e-01, 4.614e-02, -1.047e-01, -1.955e-01, 4.554e-02, 4.602e-02, -8.717e-03, 8.288e-02, -1.223e-02, 1.353e-02, 8.593e-03, 3.045e-02, 2.022e-02, 4.042e-02, -3.273e-02, 2.830e-02) * s1[y+2][x+2];
	r += V4(-1.295e-03, -1.585e-03, -1.151e-03, -1.484e-03);
	return tanh(vec4(r));
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-3x4C-RCAS-shuffle
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

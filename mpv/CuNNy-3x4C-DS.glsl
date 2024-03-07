// CuNNy 3x4C DS
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


//!DESC CuNNy-3x4C-DS-in
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
vec4 f0(F s0_0, F s0_1, F s0_2, F s0_3, F s0_4, F s0_5, F s0_6, F s0_7, F s0_8) {
	V4 r = V4(0.0);
	r += V4(3.661e-01, 5.824e-02, -1.511e-02, 1.362e-02) * s0_0;
	r += V4(8.449e-02, 1.798e-02, 3.702e-02, 2.340e-03) * s0_1;
	r += V4(-8.075e-03, -7.202e-02, 4.720e-04, 2.097e-02) * s0_2;
	r += V4(-2.093e-02, 2.413e-02, -2.486e-01, 2.900e-02) * s0_3;
	r += V4(1.824e-01, -6.943e-01, -2.743e-01, -6.149e-01) * s0_4;
	r += V4(-7.398e-02, 1.870e-01, 5.676e-02, -4.639e-02) * s0_5;
	r += V4(-1.382e-02, -6.811e-02, 7.051e-01, 2.308e-02) * s0_6;
	r += V4(-5.424e-02, 1.661e-01, -2.303e-01, -2.071e-02) * s0_7;
	r += V4(2.802e-02, 3.820e-01, -2.676e-02, 3.989e-02) * s0_8;
	r += V4(-5.354e-03, -3.027e-03, -1.008e-03, 1.472e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = LUMA_pt;
	F s0_0 = l0(-1, -1);
	F s0_1 = l0(0, -1);
	F s0_2 = l0(1, -1);
	F s0_3 = l0(-1, 0);
	F s0_4 = l0(0, 0);
	F s0_5 = l0(1, 0);
	F s0_6 = l0(-1, 1);
	F s0_7 = l0(0, 1);
	F s0_8 = l0(1, 1);
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8));
}


//!DESC CuNNy-3x4C-DS-conv1
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(5.647e-02, 1.686e-02, -1.041e-02, -1.265e-01, 1.014e-01, -5.517e-01, 1.559e-01, 1.896e-01, 1.685e-02, -4.768e-02, 3.976e-02, 6.048e-02, 4.688e-01, 7.778e-01, 2.577e-01, -7.276e-02) * s0_0;
	r += M4(-1.588e-02, 3.721e-02, 6.619e-02, 4.391e-02, -1.689e-01, -5.099e-01, 3.507e-01, 1.205e-01, 3.240e-01, -7.027e-01, -4.913e-01, -3.802e-01, -7.374e-01, -1.801e-01, -1.209e+00, -1.554e+00) * s0_1;
	r += M4(2.292e-04, -6.712e-02, 7.255e-02, 1.406e-01, 5.289e-02, 1.394e-01, 9.011e-02, -3.408e-03, -4.728e-01, -1.101e-01, -6.649e-02, 5.659e-03, 7.841e-02, 2.853e-01, -7.974e-01, -3.780e-01) * s0_2;
	r += M4(-5.619e-02, -5.472e-02, -4.667e-02, 9.337e-02, 3.668e-01, -3.916e-01, 2.939e-01, 1.519e-01, -4.235e-02, 4.868e-02, -7.016e-02, 3.391e-02, -3.648e-01, 7.796e-01, 1.023e+00, -2.572e+00) * s0_3;
	r += M4(-2.997e-02, -9.499e-02, -2.025e-01, 2.251e-01, -1.308e-01, 1.089e-01, -5.693e-02, -9.211e-01, 1.035e-01, -1.873e-01, -3.774e-01, -4.956e-02, -2.480e+00, 4.696e-01, -3.176e-01, -3.369e+00) * s0_4;
	r += M4(1.332e-01, 1.124e-02, 2.049e-01, -1.190e-01, 5.927e-02, 5.402e-04, 2.789e-01, 1.689e-01, 4.732e-01, -7.105e-02, -2.403e-01, -3.166e-01, 1.180e+00, -1.847e-01, 4.885e-01, -1.493e+00) * s0_5;
	r += M4(2.256e-02, 1.059e-01, -2.856e-02, 8.114e-02, -1.444e-01, 4.811e-02, 4.964e-02, -9.644e-02, 9.831e-02, 1.045e-01, -1.274e-01, -5.832e-02, -8.052e-01, -2.762e-01, 1.414e-01, -5.019e-01) * s0_6;
	r += M4(9.476e-02, 6.797e-02, -2.486e-01, -6.416e-02, -2.171e-01, -4.139e-02, 3.877e-01, 1.606e-01, -1.012e-01, 4.776e-02, -1.958e-01, 9.003e-02, -2.139e+00, -8.242e-01, -3.668e-01, -1.566e+00) * s0_7;
	r += M4(1.906e-01, 1.744e-01, 3.811e-01, 3.222e-01, 2.510e-02, 1.487e-01, -8.979e-03, 1.929e-02, -1.505e-02, 1.059e-01, -4.773e-02, 5.169e-02, 1.268e+00, 9.175e-01, 1.148e+00, -1.321e-01) * s0_8;
	r += M4(-3.440e-01, 1.541e-02, -2.291e-01, 3.297e-01, -4.438e-03, 1.091e+00, -5.332e-01, 3.721e-01, -8.763e-02, -1.695e-01, 9.200e-02, 7.082e-02, 5.550e-02, -1.463e-01, -5.911e-03, 2.254e-02) * s1_0;
	r += M4(-8.554e-01, 1.033e+00, 6.169e-02, -9.309e-02, 3.632e-02, 2.744e-01, -1.086e-01, 3.225e-01, -2.899e-02, 1.106e+00, 9.798e-02, 3.378e-02, 1.023e-01, -2.581e-01, 2.602e-01, -3.271e-02) * s1_1;
	r += M4(3.516e-01, -1.226e-01, -3.153e-01, 1.689e-01, -1.708e-02, 5.928e-02, 7.678e-03, 1.587e-02, 4.119e-01, 3.132e-01, 4.888e-01, 4.265e-01, 1.508e-02, 2.178e-02, -1.783e-01, 1.282e-01) * s1_2;
	r += M4(-6.847e-01, 1.275e+00, -3.978e-01, 2.100e-01, 2.368e-01, 2.163e-01, -2.476e-01, 1.665e-01, -6.949e-02, -1.638e-01, 8.327e-02, -1.804e-02, -3.389e-01, 1.994e-01, 2.591e-02, 1.607e-01) * s1_3;
	r += M4(3.362e+00, 3.429e+00, -4.680e-01, 3.626e+00, -4.888e-01, -2.356e-01, -5.965e-01, -5.605e-01, -6.080e-01, -3.295e-02, 3.453e-01, 2.355e-01, -1.675e-01, 1.241e-01, -1.697e-01, -1.844e-01) * s1_4;
	r += M4(1.737e+00, 1.149e+00, 9.230e-01, 2.112e+00, -4.450e-02, -1.412e-01, 1.891e-01, 1.143e-01, -1.379e-01, 9.119e-02, 4.386e-01, 2.416e-01, 3.870e-02, 4.527e-02, -3.649e-03, -5.527e-02) * s1_5;
	r += M4(1.670e-01, 7.390e-01, -1.005e+00, 2.058e-01, 8.740e-02, 1.678e-01, -4.256e-01, -9.790e-02, 1.528e-01, 1.942e-02, 1.507e-02, -1.038e-01, -1.927e-01, 1.654e-02, 2.348e-01, 2.842e-01) * s1_6;
	r += M4(4.608e+00, 2.583e-01, -7.586e-01, 1.855e+00, 1.562e-01, -1.364e-01, -1.174e-01, 1.101e-01, -2.357e-01, -1.101e-01, 3.298e-01, 1.024e-01, -2.979e-01, 2.364e-01, -3.920e-02, 1.687e-01) * s1_7;
	r += M4(2.513e+00, -1.392e-01, 4.043e-02, 1.049e+00, 1.274e-01, -1.015e-02, -1.371e-01, -1.299e-01, -1.689e-01, 6.039e-03, 3.790e-01, 1.333e-01, 5.758e-02, -1.140e-01, -2.446e-03, -8.596e-02) * s1_8;
	r += V4(-2.414e-01, 5.453e-02, -1.584e-03, -1.649e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = in_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-3x4C-DS-conv2
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-1.958e-03, -1.453e-02, -9.448e-02, 6.822e-03, 1.527e-02, 3.768e-03, 2.579e-02, -2.173e-02, -2.450e-01, -1.718e-01, -1.638e-02, -1.464e-01, 4.288e-01, 3.216e-01, 1.565e-02, -6.479e-02) * s0_0;
	r += M4(1.049e-01, -2.394e-02, -2.088e-01, -8.224e-02, -1.265e-01, -1.107e-01, 5.685e-02, -1.906e-01, -2.116e-01, 5.395e-02, 5.134e-02, 8.475e-02, 7.335e-01, 4.479e-01, 4.624e-02, 1.247e-01) * s0_1;
	r += M4(-7.999e-02, 1.168e-01, -8.261e-03, 4.886e-02, 1.285e-02, -1.976e-02, 1.736e-02, -2.842e-01, 1.257e-01, 1.400e-01, 5.028e-02, -3.272e-02, 3.444e-01, 2.097e-01, 2.163e-02, 4.325e-01) * s0_2;
	r += M4(-6.418e-02, 4.393e-02, -6.403e-02, 5.509e-02, -4.325e-01, -2.858e-01, -5.097e-02, -1.456e-01, -8.941e-03, -3.449e-02, -1.211e-02, 7.802e-02, -2.875e-02, -7.841e-02, -6.370e-02, 2.689e-01) * s0_3;
	r += M4(-7.417e-02, -1.646e-01, -3.271e-01, -9.790e-02, -6.009e-01, -3.726e-01, -4.762e-02, -3.415e-01, -8.280e-02, -4.430e-02, -1.630e-01, -2.645e-01, 4.200e-03, -6.231e-01, -1.718e-01, -1.155e-01) * s0_4;
	r += M4(7.776e-02, 1.040e-01, -7.446e-02, 3.048e-02, -7.250e-01, -7.415e-02, 1.387e-02, -2.717e-01, -2.554e-01, 4.443e-02, -3.882e-03, 7.644e-02, 6.738e-01, 2.145e-01, 3.422e-02, 1.026e-01) * s0_5;
	r += M4(3.002e-02, 3.749e-02, -6.073e-02, -4.217e-02, -3.602e-01, -2.904e-01, 2.144e-02, -1.079e-01, -2.920e-01, -8.035e-02, -1.515e-03, 3.199e-02, -1.424e-01, -9.337e-02, -5.984e-02, -5.545e-02) * s0_6;
	r += M4(-6.661e-02, -1.072e-02, -5.124e-02, 7.823e-02, -3.544e-01, -2.854e-01, 5.270e-03, -3.115e-01, 3.113e-03, -2.865e-02, 3.899e-03, -4.346e-02, -2.691e-01, -1.429e-01, -2.240e-03, -1.373e-01) * s0_7;
	r += M4(4.326e-02, -3.462e-02, -5.142e-03, -2.377e-02, -3.371e-01, -2.796e-01, -7.583e-02, -3.765e-01, -1.450e-02, -6.573e-03, -4.806e-02, 1.358e-01, 2.878e-01, 2.627e-01, 5.948e-02, 1.866e-01) * s0_8;
	r += M4(-9.446e-02, -7.312e-02, -1.615e-01, -5.251e-02, -9.413e-04, 1.992e-03, -2.846e-02, 4.832e-02, 2.124e-02, -4.999e-02, -1.029e-01, -2.008e-02, -4.877e-03, 4.572e-02, 5.188e-02, -1.492e-01) * s1_0;
	r += M4(1.639e-01, -7.217e-03, -4.138e-01, 1.202e-01, -2.913e-02, 2.685e-02, 2.685e-02, 1.606e-01, -9.217e-02, 7.365e-02, 2.268e-02, 8.633e-02, 8.647e-02, 1.036e-02, 7.888e-02, -2.430e-01) * s1_1;
	r += M4(9.719e-03, 1.389e-01, 1.185e-02, 1.332e-01, -4.657e-03, 6.257e-02, 3.528e-02, 9.064e-02, -1.016e-01, -9.457e-02, 6.566e-02, 1.772e-01, -4.096e-02, -1.130e-01, 1.312e-02, -7.340e-02) * s1_2;
	r += M4(-4.548e-02, 3.515e-02, -1.219e-01, 2.288e-02, 2.443e-02, 3.301e-02, -3.386e-02, 4.255e-03, -1.782e-01, 4.501e-02, -5.601e-02, -1.064e-01, -2.351e-01, -1.578e-01, 3.506e-02, 3.266e-01) * s1_3;
	r += M4(3.441e-01, 1.839e-01, -5.217e-01, 7.214e-02, 7.661e-02, 4.434e-03, -1.742e-02, -2.783e-01, 4.712e-01, 1.782e-01, -6.523e-02, 4.339e-02, -2.831e-02, -8.257e-01, -1.831e-01, -6.555e-02) * s1_4;
	r += M4(2.668e-01, 1.064e-01, -1.392e-01, 9.696e-03, -2.334e-02, 1.667e-01, -6.365e-02, -5.998e-02, 7.171e-02, 1.986e-01, -7.580e-02, 2.832e-02, 4.746e-02, -1.631e-01, 6.720e-02, -7.338e-02) * s1_5;
	r += M4(-5.780e-02, 2.733e-02, -8.548e-02, -2.955e-02, 5.405e-03, -8.996e-03, -6.611e-03, -2.988e-02, 4.250e-01, 1.519e-01, 7.495e-02, 1.442e-02, -7.015e-02, -2.285e-02, 2.717e-02, -3.821e-02) * s1_6;
	r += M4(-9.711e-02, -5.984e-02, -6.725e-02, 6.849e-03, 1.163e-02, -1.461e-02, -1.100e-02, -3.885e-02, -2.435e-01, 2.032e-03, -1.502e-01, 1.726e-01, -2.310e-01, -2.422e-01, 1.052e-01, -1.646e-01) * s1_7;
	r += M4(-8.983e-02, -9.206e-02, -7.154e-02, -9.644e-02, 9.840e-02, 1.908e-01, -5.261e-02, 3.838e-02, 6.855e-02, 1.041e-02, 1.369e-02, -1.381e-01, -1.713e-01, -1.057e-01, -3.215e-03, -7.391e-04) * s1_8;
	r += V4(-3.269e-03, -4.083e-03, 3.104e-01, 2.767e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv1_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-3x4C-DS-conv3
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(6.162e-02, -8.165e-03, -1.032e-01, 6.569e-02, -4.063e-02, -9.102e-03, 1.382e-01, -1.175e-02, 5.958e-02, -2.967e-02, 2.021e-02, 7.950e-02, -1.357e-02, -4.071e-02, -9.533e-03, 1.229e-01) * s0_0;
	r += M4(1.204e-01, -6.809e-03, -1.868e-01, -1.749e-01, 2.378e-03, 2.491e-02, -2.744e-01, -1.332e-01, -1.020e-01, 9.170e-04, -8.127e-03, -3.120e-02, -5.019e-04, -2.563e-03, 1.761e-02, -3.772e-02) * s0_1;
	r += M4(-5.127e-02, -1.308e-02, 6.877e-02, -6.742e-02, 7.758e-02, -1.513e-02, 4.863e-02, 2.218e-02, 4.431e-02, 3.070e-02, 1.277e-02, -9.496e-02, -3.906e-02, -1.007e-02, -1.961e-02, 8.351e-02) * s0_2;
	r += M4(4.052e-02, 5.675e-02, 2.273e-03, 5.242e-02, 1.046e-01, -5.043e-02, -2.646e-01, 6.126e-02, -8.816e-02, 3.503e-02, -3.499e-02, -8.876e-02, -1.496e-02, 1.016e-01, -2.438e-01, -5.368e-02) * s0_3;
	r += M4(-1.519e-01, 7.598e-03, 1.542e+00, -6.152e-01, -1.179e-01, -3.537e-02, 1.160e+00, 2.667e-01, 1.548e-01, 6.056e-02, -2.266e-03, 7.697e-03, 2.511e-01, -2.422e-02, 3.820e-01, 4.727e-02) * s0_4;
	r += M4(7.608e-03, 3.076e-02, -5.856e-02, 1.450e-01, 1.451e-01, 1.318e-01, 1.088e-01, -9.308e-02, -7.167e-02, -9.274e-02, -1.279e-02, 1.459e-01, -9.549e-02, -5.511e-02, -1.741e-01, -1.212e-01) * s0_5;
	r += M4(2.479e-02, 5.980e-02, -5.103e-02, 9.591e-02, -7.102e-02, 1.927e-02, 8.342e-02, -7.066e-02, 4.283e-02, 4.313e-02, 3.713e-04, -2.207e-02, -7.112e-03, 9.058e-02, -1.189e-01, -3.670e-02) * s0_6;
	r += M4(1.313e-01, 5.485e-01, -3.135e-01, -2.188e-01, -4.158e-02, -2.941e-01, 1.622e-01, 6.609e-02, -6.485e-02, -1.168e-01, 3.288e-02, 4.813e-02, 2.759e-03, 3.252e-01, -4.507e-02, -2.806e-01) * s0_7;
	r += M4(5.873e-02, 6.635e-02, -4.886e-02, -1.578e-02, 2.293e-02, 1.094e-01, -1.163e-02, -1.269e-02, 4.354e-02, 8.626e-02, -1.185e-02, -5.923e-02, -2.945e-02, -1.423e-01, -4.072e-03, 7.509e-03) * s0_8;
	r += M4(7.289e-02, -1.436e-02, -2.067e-02, 8.625e-02, -1.694e-01, 3.764e-03, 7.202e-03, -8.382e-02, -3.898e-01, 3.094e-02, 4.020e-01, -1.471e-01, -5.063e-02, -1.144e-02, -1.475e-02, 2.759e-02) * s1_0;
	r += M4(6.165e-02, -1.020e-02, -5.603e-02, -2.525e-02, 1.055e-01, 4.695e-02, 8.578e-02, 4.577e-04, 1.722e-01, 3.439e-02, 4.816e-01, 1.603e-01, -1.301e-02, -9.217e-02, 4.613e-02, -9.346e-03) * s1_1;
	r += M4(7.558e-02, 2.499e-03, 4.060e-02, 2.021e-02, 1.094e-01, 2.259e-02, -8.200e-02, 4.235e-02, 8.256e-01, 1.101e-01, 5.476e-01, -8.249e-02, -1.290e-01, -3.536e-02, -2.325e-03, 3.398e-02) * s1_2;
	r += M4(5.915e-02, 5.164e-02, 4.869e-03, 2.507e-02, -3.313e-02, -1.219e-01, 3.028e-02, 5.941e-02, -5.027e-01, -3.842e-01, 5.087e-01, 1.950e-01, -3.595e-02, 7.270e-02, -2.198e-02, -6.965e-02) * s1_3;
	r += M4(1.445e-02, 2.696e-02, 2.685e-02, -2.468e-01, 4.914e-02, -9.211e-02, -3.957e-02, 2.666e-01, 9.735e-01, -1.371e+00, 1.260e+00, 1.800e+00, 1.804e-01, 9.743e-02, -1.074e-01, -1.691e-01) * s1_4;
	r += M4(-4.726e-02, -8.189e-02, 1.776e-02, 5.093e-02, 1.612e-01, 6.860e-02, -9.293e-03, -5.437e-03, 8.831e-01, -6.007e-01, 1.475e+00, 1.602e+00, 1.500e-01, 5.844e-02, 8.105e-02, 2.959e-02) * s1_5;
	r += M4(7.107e-02, 6.734e-02, -4.087e-02, 3.485e-02, -1.738e-01, -9.472e-02, 3.604e-02, -3.277e-02, -1.515e-01, -6.992e-01, 9.287e-01, -4.060e-02, 2.048e-02, 1.189e-01, -5.134e-03, -8.762e-02) * s1_6;
	r += M4(1.032e-01, 1.956e-01, -5.491e-02, -1.896e-01, -1.515e-01, -3.434e-01, 9.651e-02, 2.881e-01, -7.580e-01, -1.413e+00, 2.232e+00, 1.197e+00, 1.638e-01, 3.276e-01, -2.656e-02, -3.338e-01) * s1_7;
	r += M4(1.956e-03, -3.881e-02, 4.487e-02, -2.503e-02, -1.295e-01, -1.267e-03, -8.929e-02, 1.732e-01, -4.410e-01, -8.704e-01, 1.215e+00, 8.312e-01, 1.357e-01, 8.193e-02, 6.119e-03, -2.878e-01) * s1_8;
	r += V4(7.152e-03, -5.241e-04, 4.601e-03, -9.111e-04);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv2_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-3x4C-DS-out
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(5.211e-02, 4.730e-03, -1.060e-01, -2.430e-02, -1.770e-01, 3.848e-02, -2.321e-01, 2.574e-03, 5.479e-03, -2.606e-02, -9.093e-03, -2.402e-02, 4.765e-02, 1.753e-02, 3.519e-02, 1.154e-02) * s0_0;
	r += M4(3.057e-01, 1.948e-01, -6.909e-02, -1.418e-01, 1.169e+00, 3.679e-01, 4.640e-01, -1.964e-02, -1.371e-01, -6.904e-02, 2.547e-03, 8.307e-03, 2.956e-02, 1.209e-01, 2.669e-02, 7.388e-02) * s0_1;
	r += M4(-1.027e-01, 6.874e-03, 2.694e-02, -2.056e-03, -1.606e-01, 3.934e-01, -1.767e-01, -6.168e-03, 2.821e-02, 7.308e-03, -8.644e-03, 5.594e-03, -3.917e-02, -6.353e-02, -1.181e-02, -1.714e-02) * s0_2;
	r += M4(-5.842e-01, 3.276e-01, 1.162e-01, 2.995e-01, -2.590e-02, 4.898e-02, -2.086e-01, 4.556e-02, -1.682e-02, -2.599e-02, 1.965e-03, -1.215e-02, -8.875e-02, 6.393e-03, -6.215e-02, -1.709e-03) * s0_3;
	r += M4(7.195e-02, -1.338e+00, 8.244e-01, 5.582e-02, -2.251e-01, -3.410e-01, 2.891e-02, -3.831e-01, -5.791e-02, -6.372e-02, -2.854e-01, -1.799e-01, -9.078e-02, -1.831e-01, -3.458e-02, -8.664e-02) * s0_4;
	r += M4(-1.870e-01, 2.098e-01, -1.473e-01, 3.502e-01, 4.734e-02, 2.598e-02, -1.294e-01, -6.676e-02, 3.333e-03, 2.765e-02, 3.405e-02, -3.583e-02, 2.251e-02, 4.294e-02, -4.929e-03, -4.364e-03) * s0_5;
	r += M4(2.466e-01, 5.816e-02, -1.366e-01, 1.959e-01, -1.874e-02, -1.990e-02, 4.256e-02, -1.461e-02, -1.473e-03, 2.378e-03, 9.738e-03, -5.065e-03, 3.157e-02, -2.690e-02, 1.909e-02, -6.964e-03) * s0_6;
	r += M4(3.023e-01, 3.224e-01, 1.727e-01, -5.329e-01, 3.273e-02, -1.239e-02, 1.323e-01, 3.896e-02, 1.647e-02, -1.352e-02, 6.812e-02, 1.640e-02, 5.970e-02, 5.179e-02, 3.541e-03, -1.660e-02) * s0_7;
	r += M4(-6.704e-02, 3.137e-02, -1.314e-01, 1.394e-01, -1.573e-02, 1.604e-02, -5.809e-03, 1.195e-01, -6.842e-03, 7.024e-03, -1.572e-02, 4.118e-02, -4.602e-03, 2.495e-02, -3.459e-03, 2.555e-02) * s0_8;
	r += M4(-2.249e-02, -1.567e-03, 8.940e-03, -4.490e-03, 9.016e-02, 2.612e-02, 4.256e-02, 3.225e-02, -8.090e-03, 1.400e-02, -4.870e-02, 4.947e-03, 3.413e-02, 9.831e-02, 9.884e-02, 3.422e-03) * s1_0;
	r += M4(2.535e-03, -1.853e-02, -3.898e-02, -3.767e-03, -8.520e-02, 6.478e-02, -3.165e-02, 1.065e-02, -1.299e-01, 1.690e-02, -7.300e-02, -8.399e-02, 1.758e-01, -2.251e-01, 1.558e-01, 1.184e-01) * s1_1;
	r += M4(-4.087e-04, -4.608e-03, 2.129e-02, -5.545e-03, 2.688e-02, -7.722e-03, 2.274e-02, 1.967e-02, 6.274e-02, -1.232e-01, 8.895e-03, -1.132e-04, -1.083e-01, 2.105e-01, -6.145e-02, 9.429e-03) * s1_2;
	r += M4(2.719e-03, 1.542e-02, -5.355e-02, 9.399e-03, -8.609e-02, -2.556e-03, 2.194e-03, -3.799e-03, -2.429e-02, 1.620e-03, -1.933e-02, 8.420e-03, -3.032e-02, 8.643e-02, -3.681e-01, 7.614e-02) * s1_3;
	r += M4(3.490e-02, 2.513e-02, 9.462e-02, -1.267e-02, -9.703e-02, -2.054e-01, -1.426e-01, -9.947e-02, -3.477e-01, -2.174e-01, -3.560e-01, -8.202e-02, 1.912e-01, -3.788e-01, -2.387e-01, -1.124e+00) * s1_4;
	r += M4(-6.139e-03, 1.525e-03, -2.177e-02, 3.010e-02, -1.931e-02, 2.740e-02, 2.292e-02, -1.255e-02, 1.022e-01, -5.309e-02, 1.072e-01, -2.958e-01, -4.654e-02, 2.996e-01, -1.329e-01, 1.929e-01) * s1_5;
	r += M4(-7.234e-03, -2.600e-02, 1.992e-02, -2.169e-02, 1.336e-02, -1.901e-02, -2.270e-02, -5.494e-03, 4.623e-03, 9.632e-03, 3.003e-03, 6.611e-03, 5.445e-03, -2.552e-02, 1.214e-01, -3.505e-03) * s1_6;
	r += M4(-8.965e-04, 2.056e-02, -2.802e-02, 3.469e-02, 8.501e-02, 3.256e-02, 6.102e-02, -3.449e-02, 2.270e-02, -5.703e-03, 4.943e-02, -4.554e-02, 1.604e-02, 7.274e-03, 2.582e-01, 1.715e-01) * s1_7;
	r += M4(-1.285e-02, -1.701e-02, -1.596e-02, -3.600e-02, 2.456e-02, 6.421e-02, -6.789e-03, 5.323e-02, -5.402e-02, -1.895e-02, -4.103e-02, 9.229e-02, -9.129e-03, -1.399e-02, -6.494e-02, 9.041e-02) * s1_8;
	r += V4(9.876e-04, 1.016e-03, 9.083e-04, 9.174e-04);
	return vec4(tanh(r));
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv3_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-3x4C-DS-shuffle
//!HOOK LUMA
//!BIND out
//!BIND easu
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
	r.r += easu_tex(easu_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

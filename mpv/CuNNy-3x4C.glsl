// CuNNy 3x4C
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


//!DESC CuNNy-3x4C-in
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
	r += V4(3.927e-02, -4.902e-03, -1.206e-01, -9.856e-01) * s0[y+0][x+0];
	r += V4(-3.265e-01, -9.880e-03, 1.020e-01, 3.019e-02) * s0[y+0][x+1];
	r += V4(4.353e-02, 1.895e-02, -1.683e-02, 1.037e-02) * s0[y+0][x+2];
	r += V4(-3.312e-01, 5.645e-01, -1.543e-01, 4.969e-02) * s0[y+1][x+0];
	r += V4(2.140e-01, -5.560e-02, 6.450e-01, -8.353e-03) * s0[y+1][x+1];
	r += V4(-1.977e-01, -2.496e-02, 5.862e-02, 6.875e-03) * s0[y+1][x+2];
	r += V4(1.831e-01, -5.600e-01, -1.027e-01, -1.470e-03) * s0[y+2][x+0];
	r += V4(4.267e-01, 6.714e-02, -2.944e-01, 1.241e-02) * s0[y+2][x+1];
	r += V4(4.158e-03, 3.216e-03, 4.984e-03, -6.212e-03) * s0[y+2][x+2];
	r += V4(-2.858e-02, 2.010e-03, -1.823e-02, 1.497e-02);
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


//!DESC CuNNy-3x4C-conv1
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
	r += M4(3.333e-02, -3.330e-01, 2.389e-01, 4.212e-02, 1.537e-01, -8.665e-02, -3.162e-02, -2.048e-02, -3.096e-02, 6.063e-03, -3.487e-01, -5.583e-03, -3.262e-02, -3.226e-02, -2.060e-02, -3.982e-02) * s0[y+0][x+0];
	r += M4(2.453e-02, -2.014e-01, -1.415e-01, 5.873e-02, -3.933e-02, 1.890e-01, 1.134e-02, 3.348e-01, 1.336e-01, -9.193e-02, -3.843e-02, -1.312e-01, 3.254e-02, 1.661e-02, 2.245e-01, 4.920e-01) * s0[y+0][x+1];
	r += M4(-5.996e-02, -7.544e-02, 1.252e-02, -3.431e-02, -5.513e-02, 2.150e-01, 9.641e-01, 4.089e-01, -3.250e-02, 1.652e-01, 7.093e-02, -6.961e-02, 2.326e-02, 1.697e-02, 5.451e-01, -3.483e-01) * s0[y+0][x+2];
	r += M4(7.856e-02, 5.722e-01, -6.926e-01, 1.061e-01, 2.881e-01, 2.745e-01, -3.292e-01, -1.051e-01, -8.113e-02, -1.648e-01, 1.461e-02, 1.122e-01, -4.014e-01, 4.530e-02, 6.321e-03, 6.971e-01) * s0[y+1][x+0];
	r += M4(-3.531e-01, -5.090e-01, 8.707e-02, 2.498e-01, -5.254e-01, 4.729e-03, -1.595e-01, 7.358e-02, -1.615e-01, -4.187e-01, 1.708e-01, 1.116e-01, -9.186e-02, 3.162e-01, 5.214e-01, -4.863e-01) * s0[y+1][x+1];
	r += M4(-1.698e-02, 2.569e-01, 7.056e-02, -8.202e-02, 4.154e-01, -3.154e-02, 8.626e-01, 8.840e-03, 1.548e-01, 2.716e-01, 1.583e-01, -1.421e-01, -1.915e-01, 1.411e+00, -8.870e-01, -2.204e-01) * s0[y+1][x+2];
	r += M4(-3.421e-01, -2.547e-02, 4.679e-03, -1.811e-01, -1.411e-01, -1.313e-02, -6.458e-02, -1.409e-01, -2.920e-01, -4.753e-02, 1.062e-01, 7.413e-02, 6.139e-01, -5.375e-01, 3.687e-01, 2.769e-01) * s0[y+2][x+0];
	r += M4(2.646e-01, 2.465e-01, 9.979e-02, -1.348e-01, 1.036e-02, -2.804e-02, -6.094e-02, -2.234e-01, -3.280e-01, 2.217e-01, -1.361e-01, -2.823e-02, 5.185e-01, 1.886e+00, -3.048e-01, -1.215e+00) * s0[y+2][x+1];
	r += M4(3.347e-01, 5.042e-02, -7.348e-02, -1.091e-01, 2.349e-01, 1.984e-01, 1.119e-02, -6.377e-02, 9.785e-01, 2.254e-01, -9.231e-03, -2.844e-01, -9.623e-01, 7.819e+00, -2.161e+00, -1.262e+01) * s0[y+2][x+2];
	r += M4(3.128e-03, -3.312e-01, 8.762e-02, 2.913e-01, 1.374e-01, -9.558e-02, 9.523e-02, -1.401e-01, -9.032e-03, 7.502e-02, -4.169e-01, 1.455e-01, -7.598e-04, -2.137e-02, 3.882e-02, -2.793e-02) * s1[y+0][x+0];
	r += M4(3.390e-02, -7.415e-02, 1.194e-01, -4.631e-02, -8.808e-02, -3.507e-01, 1.799e-01, -1.713e-01, 1.421e-01, -8.418e-02, -2.356e-01, -5.724e-02, -1.303e-02, 1.353e-01, -9.267e-02, 2.819e-03) * s1[y+0][x+1];
	r += M4(-5.169e-02, 7.928e-02, 2.886e-01, -4.821e-02, 3.274e-03, -3.431e-02, -4.028e-01, -2.284e-01, -2.900e-02, 7.766e-02, -2.590e-02, -9.371e-02, 8.414e-03, 6.010e-02, -3.046e-02, 4.396e-03) * s1[y+0][x+2];
	r += M4(1.385e-01, 5.530e-01, -5.996e-01, -8.513e-02, 3.119e-01, 1.900e-01, -2.139e-01, -2.192e-02, -8.885e-02, -6.131e-02, 3.456e-02, 4.089e-01, 9.029e-02, 9.410e-02, 3.445e-02, -1.311e-01) * s1[y+1][x+0];
	r += M4(-4.574e-01, -4.986e-01, 4.094e-01, -1.040e-02, -4.309e-01, 4.468e-02, -6.110e-01, 5.429e-01, -3.623e-01, -2.883e-01, 6.652e-01, -3.470e-02, -9.419e-02, -2.635e-01, 5.367e-02, 1.563e-01) * s1[y+1][x+1];
	r += M4(1.970e-01, 3.252e-01, 2.214e-01, 2.165e-01, -1.197e-01, -2.357e-01, -2.809e-01, 3.170e-01, 1.625e-01, 1.724e-01, 1.038e-01, -1.371e-01, 1.567e-01, -1.889e-01, 1.888e-01, -7.474e-02) * s1[y+1][x+2];
	r += M4(-4.183e-01, -1.678e-02, -3.907e-02, -1.307e-01, -8.523e-02, 1.010e-03, -1.797e-02, -5.920e-02, -2.646e-01, -2.518e-01, 1.693e-01, -1.085e-01, 9.937e-02, 3.454e-02, 4.074e-02, 2.725e-04) * s1[y+2][x+0];
	r += M4(2.020e-01, 2.316e-01, -1.006e-01, -3.060e-01, 7.767e-02, 1.883e-01, -5.020e-02, -8.991e-02, -2.127e-01, 1.114e-01, -9.007e-02, -8.235e-02, -6.523e-03, 4.117e-03, -7.495e-02, 1.532e-02) * s1[y+2][x+1];
	r += M4(5.440e-01, 1.976e-01, -1.332e-02, -4.032e-02, 1.350e-01, 1.932e-01, 5.455e-02, -5.246e-02, 7.012e-01, 2.803e-01, -6.213e-02, -2.010e-01, -1.938e-01, 2.045e-01, -1.806e-01, -2.521e-02) * s1[y+2][x+2];
	r += V4(7.647e-03, 4.403e-03, -1.004e-02, -2.883e-02);
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


//!DESC CuNNy-3x4C-conv2
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
	r += M4(4.587e-02, -4.410e-02, 1.684e-01, -2.707e-01, -8.667e-02, 4.804e-02, 3.066e-02, -7.586e-02, -7.740e-02, 5.721e-02, -5.870e-02, -4.431e-02, 1.297e-02, -4.871e-02, 8.865e-02, 4.618e-02) * s0[y+0][x+0];
	r += M4(-6.223e-02, 9.995e-02, -8.385e-03, 4.534e-03, 3.580e-02, -2.840e-01, 2.923e-01, -2.558e-02, -6.958e-02, -3.160e-02, 6.519e-04, -4.758e-02, 1.276e-01, -1.528e-01, 2.232e-01, 1.225e-02) * s0[y+0][x+1];
	r += M4(1.201e-01, -1.652e-01, 8.696e-02, -6.913e-02, -5.359e-02, -7.034e-02, 6.090e-02, -8.875e-02, -2.881e-02, -2.015e-01, 9.782e-02, 9.246e-03, 6.003e-02, -3.922e-02, 2.924e-01, 8.939e-02) * s0[y+0][x+2];
	r += M4(-1.136e-01, 1.274e-01, 7.583e-02, -3.331e-01, 1.426e-02, 8.759e-02, -1.503e-01, -9.885e-02, -1.073e-01, -3.539e-02, 4.377e-02, -5.387e-02, -3.675e-03, -1.925e-02, 1.492e-01, 1.075e-01) * s0[y+1][x+0];
	r += M4(-9.018e-02, 2.338e-01, 1.310e-01, 8.192e-03, -7.680e-01, 3.872e-01, 7.820e-02, -8.432e-02, 2.849e-02, 2.001e-01, -2.144e-01, -2.604e-01, 2.832e-01, -4.951e-01, 1.197e-01, -1.048e-01) * s0[y+1][x+1];
	r += M4(4.238e-02, -7.994e-02, 1.286e-02, -8.842e-02, -8.520e-02, 2.816e-02, 4.403e-02, -1.838e-02, 8.919e-02, 4.314e-02, -7.660e-02, 1.154e-01, -2.153e-01, -3.213e-01, 1.626e-01, -2.031e-01) * s0[y+1][x+2];
	r += M4(1.158e-02, 2.674e-02, 7.447e-02, 2.301e-01, 9.685e-04, 1.329e-01, -2.805e-01, -2.267e-01, -5.348e-02, -6.944e-02, -2.341e-01, -2.375e-01, 1.430e-01, 8.019e-02, -9.543e-02, -5.262e-02) * s0[y+2][x+0];
	r += M4(3.417e-02, 1.255e-02, 9.094e-02, 2.764e-01, -1.949e-02, -1.416e-02, -8.463e-02, -3.205e-01, -4.864e-03, -4.458e-02, -4.271e-02, -4.163e-01, 3.397e-02, 9.750e-03, 1.146e-01, 1.722e-01) * s0[y+2][x+1];
	r += M4(5.602e-03, -2.658e-02, -6.169e-02, -1.013e-02, 2.209e-02, 1.145e-01, -1.116e-01, -2.570e-02, 1.111e-01, -8.935e-02, -4.917e-02, 1.714e-01, -2.098e-01, 3.243e-01, -3.846e-02, -1.256e-01) * s0[y+2][x+2];
	r += M4(7.832e-01, -5.137e-01, -1.117e-01, 1.516e-01, -7.479e-02, -6.330e-03, 8.002e-02, -1.193e-01, -4.524e-02, 5.482e-02, -3.290e-02, 3.368e-03, -5.677e-02, 6.521e-03, -9.223e-03, -4.357e-02) * s1[y+0][x+0];
	r += M4(-1.406e-01, -2.372e-01, 2.418e-01, -1.710e-01, 7.287e-02, -2.449e-01, 3.730e-01, 1.759e-02, -3.144e-02, 4.372e-04, -2.145e-02, -4.382e-02, 3.766e-03, -1.566e-01, 5.383e-02, -2.785e-02) * s1[y+0][x+1];
	r += M4(-9.511e-02, -3.262e-02, 1.676e-02, -2.136e-01, -2.355e-02, -2.116e-01, 3.146e-01, 5.405e-02, 7.197e-03, -1.009e-01, -8.947e-02, -3.749e-03, -5.816e-03, 1.805e-02, -2.925e-02, -8.252e-02) * s1[y+0][x+2];
	r += M4(2.424e-01, -3.281e-01, -1.328e-01, -1.223e-01, 4.842e-04, -2.418e-02, 2.904e-02, 4.222e-03, -1.514e-02, 1.775e-01, 6.242e-02, -5.680e-02, -6.867e-02, 1.460e-01, -9.719e-02, -8.990e-02) * s1[y+1][x+0];
	r += M4(-1.515e-01, -3.321e-01, 2.271e-01, -2.728e-01, -2.344e-01, 1.512e-01, -7.324e-01, -6.154e-01, 6.225e-04, 3.443e-01, 1.163e-01, 1.700e-01, 1.249e-01, -6.599e-02, -1.626e-01, -1.196e-01) * s1[y+1][x+1];
	r += M4(-1.901e-01, 2.846e-01, 2.806e-02, -1.676e-01, 2.220e-01, -2.086e-01, -6.311e-03, 7.546e-02, 7.155e-02, 2.446e-01, -3.876e-01, 1.962e-01, 8.812e-02, -2.507e-02, 9.970e-02, -7.646e-02) * s1[y+1][x+2];
	r += M4(4.392e-02, 3.617e-02, -8.134e-02, 3.633e-02, -3.845e-02, -1.213e-01, -6.550e-02, -2.780e-01, 3.198e-02, 1.719e-01, -3.972e-01, -2.482e-01, -2.769e-02, 7.936e-02, -6.304e-02, -1.054e-01) * s1[y+2][x+0];
	r += M4(-1.516e-02, 3.295e-02, -3.590e-02, 1.426e-01, 2.946e-02, -1.121e-01, -3.521e-01, -4.529e-01, -4.298e-03, 4.696e-01, 2.085e-01, 1.631e-01, 1.714e-02, -4.781e-02, -1.151e-01, -3.701e-01) * s1[y+2][x+1];
	r += M4(-8.640e-02, 4.672e-02, 9.688e-03, -1.009e-01, 7.252e-02, -1.692e-01, 1.713e-03, 1.632e-03, -3.578e-03, 1.055e-02, 5.746e-02, 3.190e-01, 5.424e-02, 7.161e-02, -9.391e-02, -8.703e-02) * s1[y+2][x+2];
	r += V4(1.438e-03, -2.836e-02, 8.309e-03, -1.004e-02);
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


//!DESC CuNNy-3x4C-conv3
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
	r += M4(-1.545e-01, 8.042e-02, 6.362e-02, -2.350e-01, 2.590e-02, -9.061e-02, -1.057e-01, -5.170e-02, 1.551e-02, -3.128e-02, -6.175e-03, -2.819e-02, 5.951e-02, -4.403e-02, -7.392e-03, 1.965e-02) * s0[y+0][x+0];
	r += M4(3.393e-02, 2.227e-01, 2.641e-01, -2.320e-01, -4.281e-02, 1.460e-02, 1.895e-01, -2.134e-01, 2.591e-03, 5.463e-02, -5.776e-02, -1.068e-01, 1.667e-01, -7.523e-02, -6.427e-01, 3.636e-01) * s0[y+0][x+1];
	r += M4(-2.207e-02, 1.397e-01, 8.800e-02, -2.361e-01, 2.293e-02, -8.702e-02, 1.976e-02, -4.070e-02, 3.202e-02, -1.276e-02, 1.173e-01, -4.488e-02, 5.858e-02, -1.311e-01, -2.530e-01, 2.612e-01) * s0[y+0][x+2];
	r += M4(-7.557e-01, 4.521e-01, -8.490e-03, -2.212e-01, -1.558e-01, -6.073e-02, -1.942e-02, 3.581e-02, -2.757e-02, 1.994e-02, -2.357e-02, 4.305e-02, 1.544e-01, -6.564e-02, 1.447e-03, 1.375e-02) * s0[y+1][x+0];
	r += M4(-4.028e-01, -2.682e-01, 5.644e-01, -5.522e-01, -2.881e-01, 1.192e-01, 3.252e-01, -1.714e-01, -2.284e-01, -1.140e-01, -2.075e-01, -7.934e-02, 4.054e-01, -1.121e-01, -1.276e-01, 2.232e-01) * s0[y+1][x+1];
	r += M4(-2.783e-01, 4.602e-01, 3.082e-02, -2.959e-01, -3.857e-02, 1.144e-01, -1.095e-02, -9.094e-02, 1.209e-01, -5.529e-02, 1.753e-01, -5.823e-02, 1.403e-01, -3.467e-01, 1.338e-04, 1.454e-01) * s0[y+1][x+2];
	r += M4(-3.928e-01, 2.427e-01, 8.906e-02, -1.149e-01, 9.556e-02, -1.340e-01, -6.714e-02, 6.372e-02, 4.824e-02, -3.498e-02, -7.785e-02, 2.156e-02, 4.238e-02, -3.664e-02, 3.178e-02, -1.056e-02) * s0[y+2][x+0];
	r += M4(3.694e-02, 4.134e-02, 2.347e-02, 1.333e-01, -4.317e-02, 1.171e-01, 6.105e-02, -5.253e-02, 1.806e-02, -1.505e-02, 1.140e-01, 7.297e-03, -1.392e-02, -1.788e-02, -7.693e-02, 5.415e-03) * s0[y+2][x+1];
	r += M4(-1.138e-01, 1.112e-01, -7.105e-02, -1.238e-02, -2.883e-03, -4.760e-02, -1.255e-01, 6.917e-02, -1.601e-03, -6.330e-02, 8.749e-03, 1.062e-02, 3.276e-02, 5.602e-02, -2.183e-02, -4.989e-03) * s0[y+2][x+2];
	r += M4(2.777e-02, -7.451e-02, -1.014e-01, 4.710e-03, -1.794e-02, -5.005e-03, 1.012e-01, -1.066e-01, 1.946e-01, -1.016e-01, -1.945e-01, 9.253e-02, -4.551e-02, 5.609e-02, 7.239e-02, -6.472e-02) * s1[y+0][x+0];
	r += M4(3.503e-02, 6.368e-02, -7.027e-02, -9.395e-02, -1.278e-02, 6.060e-02, 4.070e-02, -1.632e-01, 1.943e-01, 5.929e-02, -1.036e-01, 3.280e-03, 2.009e-02, 3.999e-02, -4.149e-02, 1.799e-02) * s1[y+0][x+1];
	r += M4(7.394e-02, -1.071e-01, 1.212e-03, 2.555e-02, 1.942e-02, 2.073e-02, 1.350e-01, -1.255e-01, 5.443e-02, -4.053e-03, -5.541e-02, 1.179e-01, 2.680e-02, 4.561e-02, -6.555e-02, 3.882e-02) * s1[y+0][x+2];
	r += M4(-3.380e-02, 1.376e-02, -5.350e-02, 5.261e-02, -1.990e-01, 1.091e-01, 2.110e-01, -9.985e-02, 1.633e-01, 4.750e-02, 4.323e-02, 1.391e-01, 2.850e-02, -7.870e-02, 5.738e-03, 1.187e-02) * s1[y+1][x+0];
	r += M4(-3.625e-01, -1.694e-01, -8.377e-02, -3.496e-01, -4.362e-01, -2.778e-02, 3.999e-01, -1.237e-01, -5.137e-01, -4.200e-01, -2.221e-01, 3.485e-01, -1.131e-02, 1.815e-01, 1.697e-01, -9.351e-02) * s1[y+1][x+1];
	r += M4(1.313e-01, -9.568e-02, 9.098e-02, 6.274e-02, -1.316e-01, 1.639e-01, 3.618e-02, -4.627e-02, 2.966e-01, -3.097e-01, 1.602e-03, 2.570e-01, 5.917e-02, -2.144e-01, 9.059e-02, 6.766e-02) * s1[y+1][x+2];
	r += M4(9.253e-02, -9.059e-02, -6.453e-02, 5.622e-02, -2.201e-02, -5.476e-02, -5.192e-02, 4.038e-02, 6.419e-02, 7.743e-02, 3.186e-02, -5.471e-02, -3.276e-02, -1.480e-02, 1.744e-02, 8.218e-04) * s1[y+2][x+0];
	r += M4(-7.864e-03, -2.719e-02, 1.016e-02, 1.038e-01, 1.937e-01, 2.181e-01, -4.261e-02, -7.220e-02, 8.503e-02, 2.923e-01, 1.130e-01, -1.357e-01, -2.889e-02, 1.032e-01, 5.477e-02, -4.873e-02) * s1[y+2][x+1];
	r += M4(7.357e-02, -1.587e-01, -6.280e-02, 7.748e-02, 5.219e-03, 4.542e-03, -8.813e-02, 4.153e-02, -1.834e-02, 1.284e-01, 6.389e-02, -9.862e-02, -2.749e-02, 1.337e-01, 1.656e-02, -8.221e-02) * s1[y+2][x+2];
	r += V4(-2.983e-03, -5.162e-04, 2.958e-04, -8.296e-04);
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


//!DESC CuNNy-3x4C-out
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
	r += M4(2.717e-02, -6.857e-02, -1.751e-02, -5.366e-02, -6.988e-02, 6.727e-02, -1.338e-02, -9.756e-02, -1.308e-02, -5.336e-02, -1.158e-02, 4.504e-02, -1.086e-02, 4.411e-02, 1.723e-02, 5.313e-03) * s0[y+0][x+0];
	r += M4(-1.907e-02, 1.263e-01, 1.302e-01, 1.238e-01, 8.391e-02, -6.344e-01, 1.486e-01, -1.145e-02, 1.178e-01, 2.397e-01, -1.228e-01, -4.556e-02, 4.494e-03, -1.256e-01, 2.258e-02, -4.854e-03) * s0[y+0][x+1];
	r += M4(2.942e-02, -1.139e-02, -1.184e-02, 4.711e-02, -1.091e-01, 2.313e-01, -6.620e-02, 1.366e-02, 4.069e-02, 2.231e-01, -5.221e-02, -5.409e-02, 6.418e-03, 9.293e-02, 5.222e-03, 4.253e-02) * s0[y+0][x+2];
	r += M4(-6.385e-02, -2.051e-02, -1.299e-02, -3.266e-02, -5.463e-03, 1.549e-02, -3.486e-01, 1.035e-01, 2.843e-01, -1.821e-01, 2.666e-01, -1.519e-01, -2.923e-02, 1.662e-01, -3.046e-02, 1.257e-01) * s0[y+1][x+0];
	r += M4(-3.145e-02, -5.862e-02, -1.731e-01, -3.531e-02, 2.486e-01, -2.042e-01, -2.543e-01, -1.294e+00, -1.210e+00, 1.691e-01, -3.372e-01, 5.723e-01, -2.900e-01, -4.290e-01, -2.939e-01, -4.114e-01) * s0[y+1][x+1];
	r += M4(-8.724e-03, -3.012e-02, 4.385e-02, -6.738e-02, -1.694e-01, 1.122e-01, -1.444e-01, 2.270e-01, 6.166e-02, -4.801e-01, 1.559e-01, 5.074e-02, 7.527e-02, 7.964e-03, 5.812e-02, 4.209e-03) * s0[y+1][x+2];
	r += M4(-4.399e-03, -4.867e-03, 1.877e-03, -1.553e-02, -7.941e-02, -2.346e-02, 9.302e-02, -3.425e-03, 2.199e-02, -1.875e-03, 1.228e-01, -9.589e-02, 5.837e-02, -2.528e-02, 4.117e-02, 4.536e-02) * s0[y+2][x+0];
	r += M4(-1.631e-02, -2.493e-02, 1.995e-02, -3.673e-03, -1.165e-01, -1.058e-01, 1.506e-01, 1.968e-01, 1.558e-01, 1.412e-01, -2.714e-01, 2.033e-01, 4.836e-02, 1.035e-01, 3.382e-02, -3.095e-02) * s0[y+2][x+1];
	r += M4(7.351e-03, 1.007e-02, -3.206e-03, 1.689e-02, 4.264e-02, -3.770e-02, -1.337e-02, -6.572e-03, -4.423e-02, 1.051e-01, 6.619e-02, 1.902e-02, -1.062e-02, 8.736e-03, 6.427e-03, 4.209e-02) * s0[y+2][x+2];
	r += M4(8.742e-02, -1.137e-01, -5.430e-02, -5.665e-02, -1.862e-02, 4.930e-03, 1.006e-02, 5.701e-03, 2.756e-02, -1.928e-04, -8.293e-03, -2.923e-03, 4.794e-02, -7.990e-02, -5.412e-02, 1.128e-02) * s1[y+0][x+0];
	r += M4(-4.483e-01, 2.221e-01, 1.916e-01, 2.510e-01, -9.384e-02, -6.167e-02, 5.765e-02, 3.777e-02, 1.233e-02, 3.965e-02, 2.803e-02, 1.040e-02, 3.077e-01, 1.186e-01, -1.545e-01, -1.777e-01) * s1[y+0][x+1];
	r += M4(1.001e-01, -6.194e-02, -9.887e-02, 6.061e-02, 3.845e-02, 2.978e-03, 9.391e-03, 4.719e-02, 2.486e-02, 2.252e-02, 5.614e-03, 2.549e-02, -7.934e-02, 1.255e-01, 3.893e-02, -7.205e-02) * s1[y+0][x+2];
	r += M4(1.122e-01, -1.523e-01, 8.518e-02, -2.105e-01, -5.424e-02, 8.569e-02, -8.368e-02, 2.028e-02, 3.496e-03, 3.178e-02, 3.529e-02, 2.695e-02, -5.353e-02, 1.085e-01, 1.899e-01, 1.247e-01) * s1[y+1][x+0];
	r += M4(8.747e-02, 5.840e-01, -1.277e+00, -1.013e-01, -9.956e-02, -2.204e-01, -2.553e-01, -2.567e-01, -1.636e-01, -1.734e-01, -1.544e-01, -9.966e-02, -7.605e-01, -1.282e+00, 1.787e-01, -4.357e-01) * s1[y+1][x+1];
	r += M4(2.599e-02, 5.572e-02, 1.052e-01, -4.601e-01, 2.246e-02, 2.779e-02, 5.979e-02, -2.443e-02, 7.620e-04, -3.885e-02, 1.529e-02, -4.900e-02, -1.223e-01, 6.337e-02, -6.908e-02, 4.038e-01) * s1[y+1][x+2];
	r += M4(-4.265e-02, 5.724e-02, -8.755e-02, -2.047e-02, 9.326e-03, -7.409e-04, 2.621e-02, 3.216e-02, 6.457e-03, -2.329e-02, 1.861e-02, -4.512e-03, 2.354e-02, -6.889e-02, 1.802e-01, -8.651e-03) * s1[y+2][x+0];
	r += M4(-1.325e-01, -1.279e-01, 1.354e-01, 1.165e-01, 4.860e-04, 1.526e-02, 4.655e-02, -3.963e-03, 3.307e-02, 1.772e-02, 1.639e-02, -1.137e-02, 5.149e-02, 1.333e-01, 5.716e-02, 2.853e-02) * s1[y+2][x+1];
	r += M4(1.132e-02, -4.508e-02, -4.909e-03, 5.871e-02, -1.156e-02, -1.740e-02, -1.902e-02, 1.959e-02, 1.411e-02, 3.717e-02, 1.118e-02, 2.230e-02, 1.532e-02, -4.085e-02, -5.483e-02, 5.070e-02) * s1[y+2][x+2];
	r += V4(-1.406e-03, -1.387e-03, -1.171e-03, -1.092e-03);
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


//!DESC CuNNy-3x4C-shuffle
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

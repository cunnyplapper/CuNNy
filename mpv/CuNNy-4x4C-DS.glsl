// CuNNy 4x4C DS
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


//!DESC CuNNy-4x4C-DS-in
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
	r += V4(-6.132e-01, 1.089e-03, -1.947e-02, 5.261e-02) * s0[y+0][x+0];
	r += V4(-1.959e-02, -3.908e-02, 3.358e-02, 3.578e-01) * s0[y+0][x+1];
	r += V4(2.435e-02, 1.645e-04, -1.325e-02, -2.065e-01) * s0[y+0][x+2];
	r += V4(4.878e-01, 1.277e-02, 1.085e-01, 1.199e-01) * s0[y+1][x+0];
	r += V4(1.603e-01, -2.001e-02, -5.371e-01, 2.141e-01) * s0[y+1][x+1];
	r += V4(-3.652e-02, 6.705e-01, 4.749e-02, -1.902e-01) * s0[y+1][x+2];
	r += V4(7.204e-03, -1.181e-02, 5.298e-01, -1.664e-01) * s0[y+2][x+0];
	r += V4(-3.954e-02, -7.649e-03, -1.139e-01, 1.148e-02) * s0[y+2][x+1];
	r += V4(1.240e-02, -3.072e-02, -2.909e-02, -5.078e-02) * s0[y+2][x+2];
	r += V4(1.393e-04, -1.358e-02, 2.917e-03, -5.444e-02);
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


//!DESC CuNNy-4x4C-DS-conv1
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
	r += M4(2.110e-02, -8.168e-03, -4.787e-03, 4.016e-02, 2.702e-01, -7.788e-02, 3.022e-01, 7.612e-02, 4.858e-01, -1.342e-01, 1.152e-01, 4.955e-02, -1.183e-02, 1.377e-01, 1.712e-01, 3.701e-01) * s0[y+0][x+0];
	r += M4(2.208e-03, 1.177e-01, 1.277e-01, 3.472e-01, 4.755e-03, -8.276e-02, 3.794e-02, -7.219e-02, 8.419e-01, -1.810e-01, -7.485e-02, -5.299e-02, 1.062e-01, 2.125e-02, -1.596e-03, 2.108e-01) * s0[y+0][x+1];
	r += M4(5.928e-02, -7.202e-02, -5.512e-02, -2.042e-01, 2.492e-02, 9.887e-02, -1.007e-02, -1.563e-02, -1.258e-01, -2.975e-01, 1.602e-01, -1.818e-01, -3.220e-02, 6.422e-03, -1.403e-02, 2.471e-02) * s0[y+0][x+2];
	r += M4(9.250e-02, 8.872e-02, 1.255e-01, 3.060e-01, 3.208e-02, -2.744e-01, 4.909e-02, -2.612e-01, -1.095e-01, -5.884e-02, -3.058e-02, 1.402e-02, -1.109e-01, 4.397e-01, 1.303e-01, 9.171e-02) * s0[y+1][x+0];
	r += M4(1.847e-01, 1.548e-01, 1.446e-01, 3.239e-02, -9.612e-02, 1.143e-01, 5.015e-02, 6.034e-02, 3.163e-01, 1.114e+00, -4.263e-01, 3.715e-01, -2.530e-01, 2.907e-01, -1.860e-01, 1.234e-01) * s0[y+1][x+1];
	r += M4(4.397e-01, -2.454e-01, 1.018e-01, -2.350e-01, -8.287e-02, -8.216e-02, -3.117e-04, -1.277e-01, -1.091e-01, 1.843e-01, 7.265e-02, 2.231e-01, -1.388e-01, 1.782e-01, 2.138e-02, -2.618e-01) * s0[y+1][x+2];
	r += M4(-4.843e-02, -9.373e-03, 7.784e-02, 5.125e-02, -6.567e-02, -6.992e-02, 1.961e-01, 1.772e-01, -1.360e-01, 8.063e-02, 1.118e-01, 5.066e-02, -2.911e-01, 1.796e-01, 2.349e-01, 2.007e-01) * s0[y+2][x+0];
	r += M4(3.020e-01, 1.813e-01, 1.330e-01, -2.197e-01, -4.801e-02, -5.969e-02, 7.994e-02, -1.036e-01, -1.047e-01, -2.889e-01, 1.009e-01, 5.452e-02, -4.480e-02, -2.996e-01, -1.372e-02, -2.145e-01) * s0[y+2][x+1];
	r += M4(1.872e-01, 7.094e-01, -1.840e+00, 8.666e-02, 1.618e-02, 1.211e-01, 9.371e-03, 5.469e-02, -1.859e-02, 6.625e-02, 7.592e-02, -1.592e-03, 7.845e-02, 2.029e-01, 2.336e-02, 1.192e-01) * s0[y+2][x+2];
	r += M4(9.807e-02, -1.784e-02, -2.871e-02, -3.098e-02, -3.221e+00, -3.004e+00, 2.492e+00, 1.217e+00, 4.728e-02, -1.185e-01, 6.557e-02, 2.746e-02, 8.528e-02, 2.254e-01, 2.368e-01, 5.254e-01) * s1[y+0][x+0];
	r += M4(-1.655e-01, 1.215e-01, 1.452e-01, 4.200e-01, -4.144e-01, -7.157e-01, -7.472e-01, 3.935e-01, -4.811e-01, 1.401e-01, -2.967e-01, -2.183e-01, 1.194e-01, -7.286e-02, 2.888e-02, 1.225e-02) * s1[y+0][x+1];
	r += M4(-3.034e-02, 1.210e-01, -2.091e-01, -5.393e-02, 1.655e-02, 4.825e-01, 5.007e-02, 2.727e-01, -1.446e-01, -5.613e-01, 8.022e-01, -3.994e-01, 7.150e-02, -4.853e-02, -1.770e-02, -6.462e-02) * s1[y+0][x+2];
	r += M4(1.587e-02, 1.264e-01, 9.217e-02, 2.195e-01, -8.367e+00, -7.212e+00, 7.113e+00, 4.837e+00, 1.451e-01, 8.493e-02, -1.125e-01, -1.959e-01, -7.889e-02, 2.849e-01, 9.732e-02, -9.546e-02) * s1[y+1][x+0];
	r += M4(-1.025e+00, 2.358e-01, 7.913e-02, 2.556e-02, -1.917e-01, -1.232e-01, -1.361e+00, 1.165e+00, 4.666e-02, 3.902e-01, -2.017e-01, 1.678e-02, 5.957e-02, 9.028e-02, 2.518e-01, 2.645e-01) * s1[y+1][x+1];
	r += M4(-3.750e-01, -2.527e-01, 2.213e-01, -3.830e-01, -3.147e-01, -2.394e-02, 6.581e-02, -5.440e-01, -2.435e-01, -5.115e-02, 9.848e-02, -2.658e-01, -1.802e-01, 1.351e-01, -7.097e-02, -1.123e-01) * s1[y+1][x+2];
	r += M4(2.379e-02, 1.217e-01, 8.493e-02, 1.470e-01, -1.428e+00, -2.237e+00, 2.855e+00, 1.466e+00, -1.026e-01, 5.460e-02, 6.714e-02, 7.490e-02, -3.388e-01, 4.721e-02, 2.979e-01, -9.782e-04) * s1[y+2][x+0];
	r += M4(9.839e-02, -4.108e-02, 5.926e-02, -2.926e-01, 8.853e-01, -2.673e-01, -3.461e-01, 3.712e-01, -8.528e-03, -7.829e-02, -1.085e-03, -1.184e-01, 2.001e-01, -2.666e-01, 3.102e-01, -2.852e-01) * s1[y+2][x+1];
	r += M4(5.368e-02, 1.190e-01, -3.271e-01, 4.855e-02, 1.508e-01, 5.466e-01, 3.893e-02, 1.787e-01, 7.983e-05, 1.959e-02, 6.233e-02, -4.983e-02, 1.188e-01, 9.310e-02, -6.298e-02, 2.569e-01) * s1[y+2][x+2];
	r += V4(-5.188e-02, 7.979e-02, -4.282e-01, 6.765e-02);
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


//!DESC CuNNy-4x4C-DS-conv2
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
	r += M4(-3.998e-02, 2.503e-02, 1.125e-02, 2.110e-02, -8.330e-02, 5.606e-02, -3.906e-02, -7.518e-02, 4.733e-01, 3.371e-02, -1.032e+00, 6.576e-02, 4.122e-03, -1.095e-01, 1.324e-02, 1.788e-02) * s0[y+0][x+0];
	r += M4(5.340e-02, 2.642e-01, -1.470e-02, -3.276e-02, 4.429e-01, -2.842e-01, 3.211e-02, 3.396e-01, -9.341e-01, -1.006e+00, -1.273e+00, -2.388e-01, 5.144e-02, 1.422e-01, 1.057e-01, 1.134e-01) * s0[y+0][x+1];
	r += M4(-5.385e-02, 6.116e-02, 5.740e-02, 7.609e-02, -3.686e-02, -1.130e-03, -1.600e-01, -2.349e-01, 1.250e+00, 2.263e-01, -3.397e-01, -8.458e-01, -1.084e-01, -5.613e-02, 1.206e-01, 2.192e-02) * s0[y+0][x+2];
	r += M4(1.596e-01, -4.881e-02, 1.519e-02, 1.591e-02, -3.470e-01, 2.588e-01, 5.290e-01, 1.486e-01, 1.705e+00, -1.519e+00, -2.907e+00, 1.028e+00, -3.035e-01, 1.011e-01, -2.607e-01, -1.406e-01) * s0[y+1][x+0];
	r += M4(-2.380e-01, -2.424e-01, 2.055e-01, -7.883e-02, 1.725e-01, -3.317e-02, 3.692e-01, 6.416e-02, 8.842e-01, -1.196e+00, -2.174e+00, 2.741e+00, 3.781e-01, -3.075e-01, -3.543e-01, -2.720e-01) * s0[y+1][x+1];
	r += M4(-8.825e-02, -1.698e-02, -8.276e-02, -4.944e-02, -7.109e-02, 1.302e-01, 1.052e-01, 1.432e-01, 1.393e+00, -2.338e-02, -6.013e-01, -1.096e+00, -8.380e-02, 1.119e-01, -1.576e-01, -4.382e-02) * s0[y+1][x+2];
	r += M4(4.665e-02, -1.274e-01, 3.488e-02, -4.258e-02, -7.114e-02, 1.339e-02, -9.978e-02, -4.505e-02, 4.125e-01, -1.827e+00, -1.818e+00, -6.999e-01, -1.289e-01, 1.588e-01, 2.903e-01, 1.165e-01) * s0[y+2][x+0];
	r += M4(2.526e-01, -7.402e-01, -5.682e-01, -2.588e-01, -2.322e-02, 1.935e-01, 1.723e-01, 7.483e-03, -2.080e-01, -6.932e-01, -1.659e+00, 1.009e+00, 5.808e-02, -1.121e-01, -2.783e-01, 3.701e-03) * s0[y+2][x+1];
	r += M4(-1.468e-01, -4.927e-03, -4.483e-02, -2.241e-01, 6.232e-02, 1.089e-01, -2.435e-02, 1.313e-02, 3.616e-01, -9.599e-02, -1.251e-01, -1.123e+00, -2.235e-02, -3.238e-02, 1.919e-01, -2.994e-02) * s0[y+2][x+2];
	r += M4(-1.344e-01, -1.563e-01, 1.240e-01, 1.035e-01, 9.833e-02, 1.992e-01, 1.029e-01, -7.946e-03, -1.968e-01, 1.821e-01, 2.676e-02, -7.982e-02, 4.440e-02, -6.036e-01, -2.641e-01, -1.013e-01) * s1[y+0][x+0];
	r += M4(5.684e-01, 4.200e-02, 5.898e-02, 1.652e-01, 5.489e-01, -7.193e-02, 6.482e-02, 3.447e-01, 1.849e-01, -4.316e-02, 1.525e-01, 1.579e-01, -4.475e-02, 3.582e-02, 5.146e-02, 1.442e-01) * s1[y+0][x+1];
	r += M4(6.462e-01, 4.881e-02, 8.802e-02, 2.235e-02, -3.175e-01, -8.593e-02, -7.135e-02, -9.696e-02, -3.493e-02, -4.608e-02, -8.556e-02, -8.873e-02, 3.716e-01, 3.010e-01, 2.881e-01, 2.599e-01) * s1[y+0][x+2];
	r += M4(-4.615e-02, -5.639e-01, -1.001e-01, -3.035e-01, -2.157e-01, -8.173e-02, 2.690e-01, -1.911e-02, 7.787e-02, 3.864e-02, 2.061e-01, 2.216e-01, 1.515e-02, 7.664e-01, -4.414e-01, -1.215e-01) * s1[y+1][x+0];
	r += M4(1.960e-02, -5.578e-01, -2.238e-01, -4.133e-01, 2.760e-01, -1.705e-01, -1.546e-01, -6.671e-01, 1.975e-01, -1.168e-01, -2.978e-01, -1.580e-02, 3.632e-01, 1.168e+00, -1.636e-01, -6.626e-01) * s1[y+1][x+1];
	r += M4(3.500e-01, 7.448e-02, -4.830e-01, -6.168e-01, -2.496e-01, -1.699e-02, 1.043e-01, 3.673e-01, -1.109e-01, 5.010e-02, 6.609e-02, 2.093e-02, -1.581e-01, 4.340e-01, -2.069e-01, 3.154e-01) * s1[y+1][x+2];
	r += M4(-2.619e-01, -2.901e-01, 1.384e-01, -7.426e-02, 5.055e-02, 8.892e-02, 3.164e-02, 1.637e-01, -1.364e-01, -7.895e-02, -9.890e-02, -1.657e-01, -5.293e-01, 4.707e-01, 2.977e-01, 1.014e-01) * s1[y+2][x+0];
	r += M4(4.481e-01, -5.112e-01, -8.193e-01, -5.917e-01, -8.599e-02, 5.144e-01, 2.842e-01, 2.476e-01, 6.261e-02, -6.617e-02, -3.160e-02, 4.045e-03, 1.664e-02, -1.887e-01, -2.874e-01, 4.483e-01) * s1[y+2][x+1];
	r += M4(4.490e-01, -2.125e-01, -5.332e-02, -5.643e-01, 6.653e-02, 1.170e-01, 6.222e-02, 3.575e-01, -1.520e-02, 7.242e-02, 8.764e-02, 5.049e-03, -1.352e-01, -2.763e-01, 3.092e-01, -2.988e-01) * s1[y+2][x+2];
	r += V4(1.034e-02, -1.581e-02, -1.254e-02, 4.404e-03);
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


//!DESC CuNNy-4x4C-DS-conv3
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
	r += M4(1.120e-01, -3.443e-02, 7.876e-02, -7.590e-02, -4.795e-02, 1.968e-01, 4.529e-02, 2.843e-01, 1.305e-01, -1.089e-01, 1.637e-01, -1.200e-01, -1.896e-02, 4.357e-02, -3.367e-02, 1.578e-02) * s0[y+0][x+0];
	r += M4(1.713e-01, 2.344e-01, 1.287e-02, -7.015e-02, -1.784e-01, 6.693e-02, -8.163e-02, 3.654e-01, 5.028e-03, -1.590e-01, 2.030e-01, -6.824e-03, -7.058e-02, -1.494e-01, -2.593e-01, 8.249e-02) * s0[y+0][x+1];
	r += M4(4.735e-02, -5.929e-02, -7.918e-02, -1.620e-02, -1.757e-01, 1.702e-01, 1.690e-01, 2.072e-01, 3.030e-02, -6.599e-02, 7.844e-02, -4.718e-03, -6.612e-02, 5.559e-02, -3.083e-02, -4.358e-02) * s0[y+0][x+2];
	r += M4(8.833e-02, -7.854e-02, 2.382e-01, -5.520e-01, 8.228e-03, -2.852e-02, 1.716e-02, 2.149e-01, -9.328e-02, 3.466e-01, 2.506e-01, -3.640e-01, 1.691e-02, 9.678e-02, -5.806e-02, 3.200e-01) * s0[y+1][x+0];
	r += M4(2.902e-01, -2.449e-01, -4.460e-01, 1.357e-01, -2.995e-02, 3.492e-01, 3.127e-01, 3.452e-01, -3.910e-01, 2.525e-01, -7.599e-03, -1.557e-01, 1.252e-02, -7.770e-02, -3.837e-01, 7.749e-02) * s0[y+1][x+1];
	r += M4(-3.094e-02, 8.087e-02, -6.699e-02, -1.655e-01, 5.211e-02, 1.991e-01, 2.907e-01, 2.315e-01, 1.820e-02, 9.706e-02, 1.325e-01, -2.505e-02, -4.780e-02, 7.078e-02, 3.926e-02, 2.825e-02) * s0[y+1][x+2];
	r += M4(-9.774e-05, -9.347e-02, 4.801e-02, -9.758e-02, 2.526e-02, 1.504e-01, 9.888e-02, 1.702e-01, -5.161e-02, 1.802e-01, -2.909e-02, -3.115e-02, -3.393e-02, -2.345e-01, -9.988e-02, -1.625e-01) * s0[y+2][x+0];
	r += M4(1.918e-01, -3.290e-01, 2.576e-02, -2.221e-01, -2.029e-01, 3.722e-01, -1.435e-02, 2.336e-01, -3.563e-01, 6.441e-02, -8.367e-02, -7.093e-02, 4.455e-01, -3.172e-01, -6.003e-03, -1.894e-01) * s0[y+2][x+1];
	r += M4(4.571e-01, -4.002e-02, 1.685e-01, -1.750e-02, -3.253e-01, 2.337e-01, 1.464e-01, 1.178e-01, -1.590e-01, 4.955e-02, 5.197e-02, -5.814e-02, 8.461e-02, 5.967e-03, 6.660e-03, -3.941e-02) * s0[y+2][x+2];
	r += M4(2.257e-04, 1.275e-01, 1.595e-02, 1.010e-02, 2.429e-02, 1.263e-02, 7.092e-02, -8.713e-02, 8.356e-02, 1.691e-01, -1.362e-01, 2.014e-01, -1.401e-01, 1.265e-01, -9.539e-02, 3.119e-02) * s1[y+0][x+0];
	r += M4(-6.321e-02, 3.365e-01, 4.702e-02, 2.734e-02, 1.610e-01, -1.991e-01, -6.169e-02, 5.161e-02, 1.044e-02, -2.346e-01, 2.881e-01, 1.018e-01, -2.217e-01, 2.825e-02, -2.144e-01, 2.691e-03) * s1[y+0][x+1];
	r += M4(-2.989e-02, -1.983e-02, -1.111e-01, 1.073e-02, 6.860e-02, 4.230e-02, 8.658e-02, -2.543e-02, 2.185e-01, 5.194e-02, 6.101e-02, 2.195e-02, -3.155e-02, -2.499e-02, -4.347e-02, -2.004e-02) * s1[y+0][x+2];
	r += M4(6.478e-02, 1.186e-03, 1.391e-01, -2.079e-01, 5.324e-02, -1.753e-01, -1.795e-02, -1.099e-01, 1.050e-01, 5.433e-02, 2.146e-01, -3.052e-01, -2.607e-01, 3.030e-01, -3.205e-01, 2.863e-01) * s1[y+1][x+0];
	r += M4(5.347e-02, -3.143e-01, 1.312e-01, 3.178e-01, 3.367e-01, 2.042e-02, 1.105e-01, 1.982e-02, -5.366e-01, -2.174e-02, 6.308e-01, -1.952e-01, -1.007e-01, -4.760e-02, -7.793e-01, -5.302e-02) * s1[y+1][x+1];
	r += M4(-1.733e-01, -7.216e-02, -9.106e-02, -6.779e-02, -1.126e-01, 1.156e-01, 1.224e-01, 7.739e-02, 4.467e-01, -5.354e-02, 1.571e-01, -3.425e-02, -2.493e-01, -1.235e-03, -4.971e-02, -3.213e-02) * s1[y+1][x+2];
	r += M4(-1.877e-02, 1.548e-02, -5.690e-02, 1.141e-02, 6.220e-03, 1.023e-02, 2.087e-02, -1.415e-01, 1.031e-02, -5.258e-02, -4.946e-02, 9.160e-02, 2.001e-02, 8.821e-02, -4.193e-03, 5.721e-02) * s1[y+2][x+0];
	r += M4(-1.057e-01, -1.457e-01, -4.914e-02, -1.029e-01, 2.644e-01, -1.238e-01, -8.895e-02, -1.229e-02, -2.681e-01, -4.554e-02, 1.860e-02, 1.013e-01, -8.261e-02, 8.994e-02, 1.106e-02, 2.863e-03) * s1[y+2][x+1];
	r += M4(2.455e-01, -6.093e-03, 4.761e-02, -3.130e-02, 1.096e-01, 4.553e-03, -1.246e-02, -1.947e-02, 1.420e-01, -2.373e-02, 4.898e-02, -1.044e-03, -7.461e-02, 6.192e-02, 2.171e-03, 9.213e-03) * s1[y+2][x+2];
	r += V4(-1.929e-02, 6.676e-03, 2.080e-02, 3.155e-03);
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


//!DESC CuNNy-4x4C-DS-conv4
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
	r += M4(4.150e-01, -3.017e-01, 5.580e-02, 2.613e-01, 1.464e-03, -2.010e-02, 4.765e-02, 1.368e-02, 1.431e-02, 2.502e-02, 3.507e-02, 2.973e-02, 4.871e-02, 4.578e-02, -4.432e-02, -3.060e-02) * s0[y+0][x+0];
	r += M4(-4.088e-01, -1.259e-01, -1.923e-01, 5.782e-01, -8.826e-02, 1.617e-02, 6.000e-03, -2.541e-02, -7.290e-02, 5.565e-02, -2.289e-02, 2.607e-01, 1.224e-02, -6.009e-02, 2.030e-02, 2.792e-02) * s0[y+0][x+1];
	r += M4(-1.886e-02, -4.690e-02, 2.755e-02, 6.664e-02, -1.250e-01, -1.230e-01, 1.392e-01, 7.338e-02, -4.643e-03, -4.566e-02, 4.783e-02, -6.111e-02, 3.536e-02, 5.842e-02, -1.646e-01, 2.179e-02) * s0[y+0][x+2];
	r += M4(5.527e-01, 5.799e-02, -1.805e-01, -1.556e-01, 3.779e-02, 8.235e-02, 3.859e-02, -5.330e-02, -2.209e-01, -7.939e-02, 1.174e-01, 2.389e-01, -7.002e-02, -2.583e-02, 4.310e-03, 4.686e-02) * s0[y+1][x+0];
	r += M4(-5.860e-01, -2.391e-01, -1.422e-01, 8.123e-01, 1.116e-01, 1.169e-01, -1.597e-01, -5.135e-02, 2.681e-01, -2.932e-01, -2.627e-01, -1.947e-01, 5.058e-02, 2.522e-02, 3.299e-02, -2.926e-02) * s0[y+1][x+1];
	r += M4(2.216e-02, -2.542e-02, -7.172e-02, 3.348e-02, -1.202e-01, -8.373e-02, 4.307e-02, 1.248e-01, -1.142e-02, 1.340e-01, 2.072e-01, -1.431e-01, -6.767e-02, -3.115e-02, 1.077e-01, 1.214e-01) * s0[y+1][x+2];
	r += M4(-1.449e-02, -1.948e-01, 7.796e-02, 2.320e-01, 6.494e-03, -7.843e-02, 7.543e-03, 3.916e-02, 1.148e-03, -7.392e-03, 1.362e-02, 8.738e-03, 7.160e-02, -1.211e-02, -2.973e-02, -4.698e-02) * s0[y+2][x+0];
	r += M4(-2.158e-02, 5.915e-03, -9.142e-02, 1.372e-01, 3.474e-02, 1.002e-01, -6.628e-02, -1.453e-02, 3.565e-02, 1.662e-01, -1.026e-01, -5.739e-02, -3.098e-01, -1.172e-01, 1.236e-01, 2.650e-01) * s0[y+2][x+1];
	r += M4(1.135e-02, -2.142e-02, -4.933e-02, 8.173e-02, 8.133e-02, 1.146e-01, -1.253e-01, -5.033e-02, -8.660e-02, -8.906e-02, 3.284e-02, 1.845e-01, 7.020e-03, -1.090e-01, 1.759e-01, -4.558e-02) * s0[y+2][x+2];
	r += M4(1.251e-02, -1.025e-01, 1.126e-01, 8.257e-02, 1.294e-01, -3.009e-02, 3.490e-02, 4.872e-02, -1.247e-02, 8.046e-02, 1.392e-02, -5.863e-02, 1.479e-02, 5.002e-02, -3.510e-03, -4.854e-02) * s1[y+0][x+0];
	r += M4(-8.687e-02, -5.405e-02, -4.933e-02, -1.520e-02, -4.213e-02, -1.022e-01, 4.685e-02, 9.145e-02, -2.165e-01, -2.806e-02, 7.269e-02, -4.228e-02, -5.214e-04, -6.504e-02, 4.635e-02, -1.403e-01) * s1[y+0][x+1];
	r += M4(-1.763e-02, -1.823e-02, -7.105e-02, 8.558e-03, -8.592e-02, -1.620e-01, 5.732e-02, 8.463e-02, 1.043e-01, -1.175e-01, 8.732e-02, -1.278e-01, -2.578e-02, 2.281e-03, 3.785e-02, -6.638e-02) * s1[y+0][x+2];
	r += M4(2.241e-01, 2.715e-01, 2.220e-02, -1.153e-01, 1.166e-01, 2.839e-02, -8.027e-02, -2.271e-01, -7.708e-02, -1.033e-01, 1.193e-02, 7.796e-02, -9.908e-02, -4.846e-02, 7.654e-03, 4.383e-02) * s1[y+1][x+0];
	r += M4(-1.168e-01, 1.516e-01, -3.041e-01, 2.054e-01, 8.574e-01, 9.145e-02, -2.200e-02, 4.577e-01, 3.215e-01, -9.934e-02, -2.029e-01, -5.219e-01, 4.206e-01, 1.221e+00, -6.833e-02, -6.309e-01) * s1[y+1][x+1];
	r += M4(9.839e-02, 7.668e-02, -9.291e-02, -1.539e-01, -5.217e-02, 9.352e-02, 1.666e-02, 3.159e-02, 2.613e-01, 1.893e-01, 1.826e-01, -6.040e-01, -9.091e-02, -5.846e-02, -9.949e-02, 7.582e-01) * s1[y+1][x+2];
	r += M4(-6.123e-02, -5.674e-02, 4.663e-02, 7.790e-02, 2.942e-02, -1.159e-01, 7.803e-02, 1.743e-01, 1.053e-01, -2.452e-02, -3.900e-02, -8.466e-02, 7.041e-02, 1.458e-02, -1.163e-02, -2.925e-02) * s1[y+2][x+0];
	r += M4(9.648e-02, 9.425e-02, -5.564e-02, -1.094e-01, -1.221e-01, -9.819e-02, -9.116e-03, 1.934e-01, -8.276e-02, 7.616e-03, -1.204e-02, -2.389e-02, -4.265e-01, -1.616e-01, 1.837e-02, 4.188e-01) * s1[y+2][x+1];
	r += M4(2.494e-02, 3.345e-02, -3.439e-03, -2.522e-02, 1.249e-01, -3.124e-02, -3.524e-03, -9.849e-02, 3.181e-02, -4.416e-03, 5.839e-02, -1.060e-01, 3.252e-01, -1.772e-01, 1.402e-01, -2.090e-01) * s1[y+2][x+2];
	r += V4(-1.636e-03, 1.958e-03, -7.917e-05, -2.893e-03);
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


//!DESC CuNNy-4x4C-DS-out
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
	r += M4(-3.771e-02, -2.504e-03, 2.157e-02, 3.702e-02, 2.705e-01, 5.450e-03, 2.055e-02, -9.222e-02, 4.933e-03, -2.848e-03, 5.286e-02, 4.579e-03, 1.044e-02, -1.429e-03, -5.270e-03, -4.953e-03) * s0[y+0][x+0];
	r += M4(-3.474e-02, 4.358e-02, 1.411e-01, 2.376e-02, -5.996e-01, 2.025e-01, 3.101e-01, 4.625e-01, -1.545e-02, 2.652e-02, 4.994e-02, 1.194e-01, -4.797e-02, 3.741e-02, -3.863e-03, 4.103e-03) * s0[y+0][x+1];
	r += M4(1.457e-01, -2.608e-01, 8.816e-02, 1.070e-01, 8.145e-02, -5.004e-01, 2.421e-02, 3.922e-02, -2.216e-02, -7.153e-02, 1.339e-02, -1.163e-02, -6.955e-04, -9.342e-02, 3.169e-02, 1.324e-02) * s0[y+0][x+2];
	r += M4(5.045e-02, -1.165e-02, -1.046e-02, -2.492e-02, 4.655e-02, 2.786e-02, -1.536e-02, -3.070e-02, 2.647e-02, 9.113e-02, -1.078e-01, 1.485e-02, 3.964e-03, -2.689e-02, 1.086e-01, 2.126e-02) * s0[y+1][x+0];
	r += M4(-1.661e-01, 2.192e-01, -4.250e-01, 1.295e-01, 6.895e-01, 1.789e-01, -5.897e-01, -4.819e-01, -1.075e-02, -1.004e-01, -1.398e-01, -2.092e-01, 3.606e-01, 2.076e-01, 5.117e-02, 1.981e-01) * s0[y+1][x+1];
	r += M4(3.027e-01, -6.535e-02, 4.344e-02, -7.030e-01, 1.592e-01, 7.338e-01, 3.440e-01, 1.841e-01, 1.132e-01, 1.881e-01, -3.793e-02, -4.886e-02, 4.733e-03, 1.688e-01, -9.355e-02, -1.743e-01) * s0[y+1][x+2];
	r += M4(5.551e-03, 1.379e-02, 1.480e-02, -1.708e-03, -5.326e-03, 2.478e-02, 5.675e-02, 1.128e-02, -4.646e-02, -4.340e-02, 1.792e-03, -1.772e-03, 1.772e-02, 2.729e-02, -6.446e-02, -1.084e-02) * s0[y+2][x+0];
	r += M4(-1.166e-01, -5.233e-02, -2.620e-02, 6.806e-02, -3.038e-01, -1.816e-01, 1.714e-01, 8.839e-02, -5.660e-02, 3.847e-02, -1.120e-02, 3.930e-02, -1.792e-01, -9.623e-02, 6.481e-02, -6.705e-02) * s0[y+2][x+1];
	r += M4(3.295e-02, -1.616e-03, 2.777e-01, 2.261e-01, 1.131e-01, -1.144e-01, -1.919e-02, 1.349e-01, 3.855e-02, -5.980e-02, 1.382e-01, 9.950e-02, 6.283e-02, -7.154e-03, 1.357e-01, 2.294e-01) * s0[y+2][x+2];
	r += M4(-5.327e-03, 1.917e-03, 3.371e-02, 1.942e-02, 2.656e-02, 2.437e-03, 2.064e-02, 9.338e-03, -3.426e-02, 1.084e-01, -5.292e-02, -9.688e-03, -1.078e-01, 1.216e-02, 7.115e-03, 2.924e-02) * s1[y+0][x+0];
	r += M4(-4.150e-02, 1.474e-02, 9.162e-02, 6.447e-02, 2.621e-02, 4.448e-02, 2.952e-02, 3.889e-02, 3.078e-01, -3.355e-02, -1.362e-01, -1.563e-01, 4.715e-04, -1.548e-01, -3.430e-02, -4.135e-02) * s1[y+0][x+1];
	r += M4(3.812e-02, -7.657e-02, 8.364e-02, 1.115e-01, -3.200e-02, -1.282e-02, -2.385e-02, -2.165e-02, -8.471e-02, -6.469e-02, 8.624e-03, -1.140e-01, -2.469e-02, -9.775e-02, -1.847e-02, -7.845e-02) * s1[y+0][x+2];
	r += M4(9.720e-02, 3.803e-02, 1.110e-02, 7.408e-04, 1.050e-02, -1.237e-02, 5.959e-02, 1.381e-02, -3.290e-01, 1.977e-01, -1.805e-01, 2.588e-01, -1.767e-03, -2.224e-02, -3.576e-02, 1.395e-02) * s1[y+1][x+0];
	r += M4(6.852e-02, 1.294e-01, -3.623e-01, -7.197e-02, 7.414e-02, 5.758e-02, 1.325e-02, 6.210e-02, 1.208e-01, -1.071e+00, 8.855e-01, -2.596e-01, 1.352e-01, 2.286e-01, 3.159e-01, 1.316e-01) * s1[y+1][x+1];
	r += M4(4.542e-02, 5.418e-02, -1.587e-01, -4.523e-01, 1.547e-01, 2.302e-01, 8.128e-02, 1.319e-01, -2.242e-01, 4.242e-01, -1.836e-01, 3.961e-01, 2.643e-02, -1.259e-01, -5.963e-02, -9.598e-02) * s1[y+1][x+2];
	r += M4(-2.523e-02, -1.332e-02, 1.309e-02, 5.874e-03, 3.101e-02, 2.473e-02, -7.982e-03, -1.201e-03, 1.309e-01, -3.316e-03, 4.206e-02, 1.073e-01, 5.498e-02, 2.911e-02, -7.255e-02, -7.626e-02) * s1[y+2][x+0];
	r += M4(-1.478e-01, -7.404e-02, 8.383e-02, 1.910e-02, -1.363e-01, -6.616e-02, -8.072e-02, -6.375e-02, 1.092e-01, 1.463e-01, -1.950e-01, -5.213e-01, -1.220e-01, -2.280e-02, -1.597e-01, -3.252e-02) * s1[y+2][x+1];
	r += M4(3.642e-02, -3.695e-02, 1.903e-01, 2.705e-01, 9.998e-02, 3.582e-02, 1.567e-01, 1.333e-01, 6.631e-02, 5.869e-02, -2.487e-02, 1.713e-01, 1.323e-01, 6.958e-02, 2.056e-01, 9.763e-02) * s1[y+2][x+2];
	r += V4(4.459e-04, 5.610e-04, 3.269e-04, 4.564e-04);
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


//!DESC CuNNy-4x4C-DS-shuffle
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

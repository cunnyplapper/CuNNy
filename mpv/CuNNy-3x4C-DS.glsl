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

//!DESC CuNNy-3x4C-DS-EASU
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) F(LUMA_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * LUMA_pt).r)
shared F g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
			g[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	F s[3][3][1];
	V4 r0 = V4(0.0);
	s[0][0][0] = g[0][xy.y+0][xy.x+0];
	s[0][1][0] = g[0][xy.y+0][xy.x+1];
	s[0][2][0] = g[0][xy.y+0][xy.x+2];
	s[1][0][0] = g[0][xy.y+1][xy.x+0];
	s[1][1][0] = g[0][xy.y+1][xy.x+1];
	s[1][2][0] = g[0][xy.y+1][xy.x+2];
	s[2][0][0] = g[0][xy.y+2][xy.x+0];
	s[2][1][0] = g[0][xy.y+2][xy.x+1];
	s[2][2][0] = g[0][xy.y+2][xy.x+2];
	r0 += V4(-5.360e-01, 1.918e-01, -3.327e-02, 5.338e-04) * s[0][0][0];
	r0 += V4(1.440e-01, 6.504e-01, -9.507e-03, -5.018e-02) * s[0][1][0];
	r0 += V4(-1.092e-01, -2.959e-01, -1.564e-02, 5.027e-02) * s[0][2][0];
	r0 += V4(9.659e-02, -5.261e-02, 2.449e-02, -4.910e-02) * s[1][0][0];
	r0 += V4(1.284e-01, 1.900e-01, 8.143e-01, -6.350e-01) * s[1][1][0];
	r0 += V4(-5.522e-02, -4.242e-01, -2.900e-02, 1.974e-02) * s[1][2][0];
	r0 += V4(-6.617e-02, 2.611e-03, -4.118e-02, 2.241e-01) * s[2][0][0];
	r0 += V4(-8.438e-02, -1.597e-01, 1.224e-02, 5.685e-01) * s[2][1][0];
	r0 += V4(4.940e-02, 8.197e-02, -1.763e-02, -1.179e-01) * s[2][2][0];
	r0 += V4(3.726e-03, -1.033e-01, -1.163e-02, 2.173e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(in_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * in_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
			g[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	V4 s[3][3][2];
	V4 r0 = V4(0.0);
	s[0][0][0] = max(g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][0][1] = -max(-g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][1][0] = max(g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][1][1] = -max(-g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][2][0] = max(g[0][xy.y+0][xy.x+2], V4(0.0));
	s[0][2][1] = -max(-g[0][xy.y+0][xy.x+2], V4(0.0));
	s[1][0][0] = max(g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][0][1] = -max(-g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][1][0] = max(g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][1][1] = -max(-g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][2][0] = max(g[0][xy.y+1][xy.x+2], V4(0.0));
	s[1][2][1] = -max(-g[0][xy.y+1][xy.x+2], V4(0.0));
	s[2][0][0] = max(g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][0][1] = -max(-g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][1][0] = max(g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][1][1] = -max(-g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][2][0] = max(g[0][xy.y+2][xy.x+2], V4(0.0));
	s[2][2][1] = -max(-g[0][xy.y+2][xy.x+2], V4(0.0));
	r0 += M4(8.559e-01, -1.553e-02, 7.168e-01, 4.046e-02, -1.160e-01, -7.157e-02, 1.538e-01, -8.780e-02, -1.746e-01, -2.055e-01, -1.007e-01, -1.276e-01, 2.529e-01, 6.267e-03, 1.540e-02, -1.695e-01) * s[0][0][0];
	r0 += M4(-9.061e-02, -6.469e-02, 7.383e-02, 1.213e-02, -7.828e-02, -1.225e-02, 9.071e-02, 3.343e-02, 1.663e+00, 3.762e-03, -1.922e+00, 1.124e+00, 1.037e-01, 3.917e-02, 1.384e-01, -2.251e-01) * s[0][0][1];
	r0 += M4(2.478e-01, -1.509e-01, -6.691e-01, 2.470e-01, 1.499e-01, -8.715e-02, 1.209e-01, 1.928e-01, -7.545e-02, -2.054e-02, -2.092e-02, 9.306e-02, -1.979e-01, -1.023e-01, 5.522e-01, 6.927e-01) * s[0][1][0];
	r0 += M4(-1.738e-01, -1.477e-01, -4.561e-02, 2.718e-02, 6.429e-02, -1.026e-01, 1.442e-01, 8.125e-02, -2.057e+00, -6.652e-01, 1.184e+00, 3.146e+00, -2.404e-01, -4.466e-01, 9.824e-01, 3.037e-01) * s[0][1][1];
	r0 += M4(1.031e+00, 4.756e-01, 4.172e-01, -5.216e-01, 1.311e-01, -4.481e-02, 5.055e-03, 2.060e-02, 1.805e-02, -3.003e-01, 1.556e-01, 2.006e-01, -3.427e-01, -4.307e-01, 3.873e-02, 3.451e-01) * s[0][2][0];
	r0 += M4(-2.259e-02, -5.781e-02, 1.148e-01, -8.832e-02, 1.152e-01, -1.023e-01, -6.355e-02, -6.598e-02, 3.152e-01, 3.350e-01, -3.989e-01, 4.492e-01, -5.762e-01, -6.153e-01, -2.180e-01, 5.020e-01) * s[0][2][1];
	r0 += M4(5.369e-01, -5.576e-02, -1.207e+00, -3.510e-02, 9.942e-01, 5.684e-01, -1.007e+00, -5.910e-02, -1.460e-01, 3.582e-01, -2.800e-01, -2.221e-01, 3.263e-01, -6.923e-02, -1.703e-01, -6.059e-02) * s[1][0][0];
	r0 += M4(1.042e-01, 1.345e-01, -2.202e-01, 1.216e-02, 4.347e-01, 5.879e-01, -2.959e-01, -1.851e-01, 7.072e-01, 1.322e+00, 4.450e-01, 1.011e+00, 1.938e-01, -1.495e-01, -7.689e-02, -2.627e-01) * s[1][0][1];
	r0 += M4(-1.766e-01, -1.447e+00, -6.628e-01, -9.907e-01, -3.124e-01, -1.920e-01, -1.890e-01, -5.338e-02, -1.706e-02, 4.008e-02, 1.814e-01, -1.938e-01, -2.718e-01, 5.826e-01, -4.734e-01, 2.086e-01) * s[1][1][0];
	r0 += M4(-3.759e-02, 4.067e-01, 1.911e-01, -1.742e-01, 3.682e-02, -1.978e-02, 1.007e-01, -2.754e-01, -4.567e+00, -2.677e+00, 1.701e+00, 5.023e+00, -1.733e-01, 3.086e-01, -4.728e-01, -4.310e-01) * s[1][1][1];
	r0 += M4(8.158e-01, -5.993e-01, -5.317e-01, -8.290e-02, -2.646e-01, 9.835e-02, -3.974e-02, 6.329e-02, -9.126e-02, 1.034e-01, 8.517e-02, -1.184e-01, -3.734e-02, 1.450e-01, 2.474e-01, 8.340e-03) * s[1][2][0];
	r0 += M4(2.023e-01, 1.699e-01, 1.435e-01, 2.447e-01, -1.667e-01, 1.841e-01, 5.456e-02, -6.333e-02, -1.820e+00, -9.472e-01, 4.872e-01, 1.542e+00, 8.531e-03, -1.612e-02, 1.744e-01, -3.114e-01) * s[1][2][1];
	r0 += M4(7.552e-01, 3.199e-01, 3.727e-01, -3.678e-01, 3.330e-01, 6.465e-01, -2.026e-01, -1.480e-01, 1.135e-01, 1.880e-01, 3.493e-02, -7.959e-02, -8.422e-02, 1.858e-01, -9.403e-02, 2.326e-02) * s[2][0][0];
	r0 += M4(-1.055e-01, 2.978e-01, -5.116e-02, -2.081e-01, 3.699e-02, 2.959e-01, -1.867e-01, -2.164e-01, 5.643e-01, 1.593e+00, -4.185e-01, 7.613e-01, 6.093e-02, 2.842e-01, -4.519e-02, -7.441e-02) * s[2][0][1];
	r0 += M4(4.153e-01, -6.339e-01, -7.205e-01, -6.299e-01, -2.541e-01, -3.232e-01, -3.134e-03, 3.154e-01, 1.030e-01, 2.839e-01, 2.783e-01, 1.833e-01, 3.252e-01, -1.376e-01, 1.673e-02, -1.665e-01) * s[2][1][0];
	r0 += M4(1.851e-01, 1.962e-01, -1.435e-01, -1.261e-01, 4.957e-01, -1.809e-01, -1.394e-01, 1.874e-02, -1.999e+00, -1.950e+00, -1.467e+00, 2.565e+00, 3.869e-02, -2.220e-01, 3.036e-02, -6.833e-02) * s[2][1][1];
	r0 += M4(3.762e+00, 2.091e+00, 8.413e-01, -3.117e+00, -3.947e-02, -7.544e-02, 3.083e-03, -2.971e-02, 1.558e-01, -4.282e-02, -2.510e-01, 2.135e-01, 1.331e-01, -5.043e-02, -5.050e-02, -8.495e-02) * s[2][2][0];
	r0 += M4(4.537e-01, 7.577e-02, -2.256e-01, -1.207e-01, -1.723e-02, -3.056e-02, -5.904e-02, 1.208e-01, 8.239e-02, -4.293e-01, -7.408e-01, 3.896e-01, 1.392e-02, 2.826e-02, -9.107e-02, -7.696e-02) * s[2][2][1];
	r0 += V4(1.333e-01, 7.777e-02, -7.012e-02, -3.770e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv1_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv1_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
			g[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	V4 s[3][3][2];
	V4 r0 = V4(0.0);
	s[0][0][0] = max(g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][0][1] = -max(-g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][1][0] = max(g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][1][1] = -max(-g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][2][0] = max(g[0][xy.y+0][xy.x+2], V4(0.0));
	s[0][2][1] = -max(-g[0][xy.y+0][xy.x+2], V4(0.0));
	s[1][0][0] = max(g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][0][1] = -max(-g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][1][0] = max(g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][1][1] = -max(-g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][2][0] = max(g[0][xy.y+1][xy.x+2], V4(0.0));
	s[1][2][1] = -max(-g[0][xy.y+1][xy.x+2], V4(0.0));
	s[2][0][0] = max(g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][0][1] = -max(-g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][1][0] = max(g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][1][1] = -max(-g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][2][0] = max(g[0][xy.y+2][xy.x+2], V4(0.0));
	s[2][2][1] = -max(-g[0][xy.y+2][xy.x+2], V4(0.0));
	r0 += M4(-2.081e-02, 1.058e-01, 1.045e-01, -2.995e-02, 3.586e-02, 2.725e-01, -3.668e-02, -6.390e-02, -3.158e-02, -1.185e-01, 2.886e-02, 8.375e-03, -1.005e-01, -1.711e-01, -2.188e-02, -5.538e-03) * s[0][0][0];
	r0 += M4(7.387e-02, -7.202e-02, 1.124e-01, -1.255e-01, 1.821e-01, 1.685e-01, -1.436e-01, 1.772e-01, -9.513e-02, 9.412e-02, 4.356e-02, 6.441e-02, 1.958e-01, -3.612e-01, 5.694e-02, -1.712e-01) * s[0][0][1];
	r0 += M4(2.838e-02, 1.842e-01, 1.596e-01, 5.445e-02, 1.169e-01, 1.472e-01, -3.343e-01, -1.820e-01, -5.700e-02, -5.613e-02, 4.410e-02, -4.733e-02, -2.389e-02, 1.383e-01, 4.338e-02, 1.519e-01) * s[0][1][0];
	r0 += M4(-2.628e-01, -9.349e-02, -2.742e-02, 2.124e-02, 4.229e-01, 2.481e-01, -9.603e-02, 1.094e-01, 4.785e-02, 2.329e-01, 3.927e-02, -1.025e-02, 1.676e-01, 1.767e-01, -3.881e-03, -3.213e-01) * s[0][1][1];
	r0 += M4(1.598e-01, 3.060e-01, 1.657e-01, 5.884e-02, -2.537e-01, -1.715e-01, -1.493e-01, -6.635e-02, -1.499e-01, -1.654e-01, 1.243e-02, 1.242e-02, 4.596e-02, 1.251e-01, 9.302e-02, 6.978e-05) * s[0][2][0];
	r0 += M4(2.297e-02, 1.172e-01, -2.080e-02, 1.162e-02, 8.765e-02, -1.454e-01, 1.924e-01, 1.713e-02, -3.066e-02, 1.275e-01, 1.072e-01, 7.171e-02, 2.076e-01, 2.192e-01, 1.313e-01, 8.478e-02) * s[0][2][1];
	r0 += M4(-1.077e-01, 2.425e-01, -1.733e-02, 1.091e-01, 7.397e-02, -7.564e-02, -2.035e-01, 8.271e-02, 4.596e-03, -7.642e-02, -3.845e-02, -2.143e-01, -3.741e-02, 2.362e-01, -5.548e-04, -1.346e-01) * s[1][0][0];
	r0 += M4(-2.420e-01, 2.209e-02, -2.068e-01, 1.683e-02, 1.157e-01, -1.304e-01, -1.754e-01, -7.360e-02, -5.571e-03, 2.822e-01, 3.132e-02, 4.649e-03, -1.262e-02, 3.991e-01, 1.795e-01, -6.493e-01) * s[1][0][1];
	r0 += M4(2.351e-01, 2.252e-01, 1.528e-01, 1.135e-01, -4.822e-01, -3.604e-01, 5.434e-02, 3.409e-01, 4.728e-02, -2.222e-01, -1.635e-01, -5.834e-01, -1.762e-01, -7.414e-02, -3.653e-01, -1.226e-02) * s[1][1][0];
	r0 += M4(-3.042e-01, -2.345e-01, -1.588e-01, -8.521e-02, -3.282e-01, -4.123e-01, 1.724e-01, 2.989e-01, 4.361e-01, 1.979e-01, -7.435e-02, 2.842e-01, -4.189e-02, 6.387e-01, -2.861e-01, -2.509e-01) * s[1][1][1];
	r0 += M4(2.803e-01, 1.162e-01, 2.298e-01, 1.506e-01, -9.377e-02, -3.503e-03, -2.861e-01, -3.076e-01, -2.976e-01, -5.418e-01, -2.601e-01, 6.811e-02, 1.694e-01, 1.112e-01, 2.610e-01, 7.475e-02) * s[1][2][0];
	r0 += M4(-2.139e-01, -5.772e-02, 3.934e-02, 2.919e-01, 6.255e-01, -4.402e-03, 3.174e-01, -3.878e-01, 2.048e-01, -1.163e-01, 8.532e-02, 1.044e-01, 2.685e-01, 7.840e-02, 6.173e-02, -5.498e-03) * s[1][2][1];
	r0 += M4(5.161e-02, 1.862e-01, 2.456e-01, 4.133e-02, 1.932e-02, 3.850e-02, 5.246e-02, -4.723e-02, -7.069e-02, -4.232e-02, -1.213e-01, -6.343e-02, 4.785e-02, 6.166e-02, 8.510e-02, 8.817e-02) * s[2][0][0];
	r0 += M4(9.588e-02, 2.389e-02, 2.298e-02, 7.221e-02, 3.218e-02, -3.137e-02, -2.326e-02, 4.709e-02, 3.210e-02, 1.792e-01, 2.777e-02, 1.136e-01, 1.229e-01, 6.642e-02, 2.367e-01, -2.979e-03) * s[2][0][1];
	r0 += M4(2.261e-01, 1.333e-01, -1.194e-01, 1.722e-02, -1.395e-01, 1.484e-01, 1.694e-01, -8.437e-02, -2.501e-01, -1.813e-01, -2.221e-01, 1.410e-01, -2.181e-02, 1.707e-01, -1.214e-02, 8.310e-02) * s[2][1][0];
	r0 += M4(-1.480e-01, 1.265e-01, -1.272e-01, 1.587e-01, 4.759e-02, -1.689e-02, 1.762e-01, -1.024e-01, 1.801e-01, -3.973e-02, 8.994e-02, 1.042e-01, 1.604e-01, 5.993e-02, 7.609e-02, 1.569e-01) * s[2][1][1];
	r0 += M4(2.048e-01, -1.527e-01, -1.921e-02, -1.645e-01, -1.180e-01, 1.450e-01, -4.848e-02, -2.306e-03, -4.637e-01, -1.528e-02, -4.248e-01, 2.552e-01, 1.558e-01, -1.167e-01, 1.538e-01, -5.410e-02) * s[2][2][0];
	r0 += M4(-1.320e-02, -1.305e-01, -7.624e-02, 1.642e-02, 1.882e-01, -8.262e-02, 9.183e-02, -1.499e-01, 2.854e-02, -1.080e-02, -2.797e-02, 9.020e-02, 1.958e-01, -1.523e-01, 3.523e-02, -1.433e-01) * s[2][2][1];
	r0 += V4(4.928e-02, 4.865e-03, 1.837e-02, -1.224e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv2_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
			g[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	V4 s[3][3][2];
	V4 r0 = V4(0.0);
	s[0][0][0] = max(g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][0][1] = -max(-g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][1][0] = max(g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][1][1] = -max(-g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][2][0] = max(g[0][xy.y+0][xy.x+2], V4(0.0));
	s[0][2][1] = -max(-g[0][xy.y+0][xy.x+2], V4(0.0));
	s[1][0][0] = max(g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][0][1] = -max(-g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][1][0] = max(g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][1][1] = -max(-g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][2][0] = max(g[0][xy.y+1][xy.x+2], V4(0.0));
	s[1][2][1] = -max(-g[0][xy.y+1][xy.x+2], V4(0.0));
	s[2][0][0] = max(g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][0][1] = -max(-g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][1][0] = max(g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][1][1] = -max(-g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][2][0] = max(g[0][xy.y+2][xy.x+2], V4(0.0));
	s[2][2][1] = -max(-g[0][xy.y+2][xy.x+2], V4(0.0));
	r0 += M4(-1.719e-02, -1.013e-01, -1.567e-01, -7.300e-02, 4.230e-02, -3.016e-03, 2.702e-02, -1.650e-02, -1.372e-01, -8.571e-02, -9.791e-02, 5.134e-03, -1.929e-01, -4.880e-02, -1.047e-01, 5.945e-02) * s[0][0][0];
	r0 += M4(-3.250e-01, -6.570e-02, -9.152e-02, -3.388e-02, 1.333e-01, 8.691e-02, 2.484e-01, 6.450e-02, -1.757e-01, 1.361e-02, -2.036e-01, 7.145e-03, 3.206e-02, -4.610e-02, -9.963e-03, -2.311e-02) * s[0][0][1];
	r0 += M4(6.314e-02, 8.667e-02, 5.873e-02, -1.874e-02, 4.684e-03, 4.241e-02, -5.794e-03, 2.610e-02, -8.275e-02, 7.457e-02, -3.629e-03, -9.308e-03, -2.081e-01, -8.081e-02, -6.633e-01, 1.056e-01) * s[0][1][0];
	r0 += M4(9.353e-02, 6.371e-02, -4.663e-01, -1.675e-01, 1.664e-01, -4.417e-02, 1.860e-01, 3.429e-02, -4.463e-01, -1.636e-01, -1.928e-01, 1.652e-01, 1.675e-01, 6.865e-02, 2.627e-01, 3.354e-02) * s[0][1][1];
	r0 += M4(1.891e-02, 1.213e-01, 5.829e-02, 3.322e-02, -5.945e-02, -5.914e-02, -7.787e-02, 8.917e-03, 1.608e-02, -5.186e-02, -8.869e-02, -3.404e-02, -1.354e-01, -3.306e-02, -7.007e-02, 5.460e-02) * s[0][2][0];
	r0 += M4(-8.857e-02, -3.605e-02, -9.845e-02, 1.687e-02, -1.729e-01, 6.970e-03, -3.038e-02, 1.783e-01, 5.358e-02, 8.911e-02, -1.427e-01, -7.828e-02, 4.298e-02, 1.272e-02, 1.005e-01, -2.006e-03) * s[0][2][1];
	r0 += M4(8.875e-02, -4.821e-01, 2.803e-01, 5.924e-02, 2.083e-02, 1.024e-02, -3.003e-02, -8.748e-03, 1.344e-02, -2.302e-02, 1.832e-01, 3.208e-02, 1.109e-01, 5.712e-02, 1.693e-01, 4.006e-02) * s[1][0][0];
	r0 += M4(5.020e-01, -1.321e-01, -7.652e-02, -2.643e-02, -1.747e-01, 1.566e-01, 9.731e-02, -3.696e-02, 1.299e-01, 1.680e-02, 4.113e-01, 6.184e-02, -3.822e-02, -6.920e-02, 1.885e-01, 6.041e-02) * s[1][0][1];
	r0 += M4(4.062e-02, -4.156e-01, -2.793e-01, -6.753e-02, -1.532e-01, -2.650e-02, 5.469e-02, 4.016e-02, -4.006e-02, 3.866e-02, 1.664e-01, 9.529e-02, 1.290e-02, -1.221e-01, -5.664e-01, 9.062e-02) * s[1][1][0];
	r0 += M4(-8.591e-01, -2.358e-01, 2.998e-01, 1.130e+00, 8.276e-01, 2.465e-01, 1.805e+00, -1.248e+00, 4.647e-01, -1.849e-02, 7.149e-02, -5.994e-01, 1.548e-01, 1.793e-01, -6.047e-01, -2.174e-01) * s[1][1][1];
	r0 += M4(-9.108e-02, -1.610e-02, 1.419e-01, 3.946e-02, 3.656e-02, 1.190e-02, -4.070e-02, -6.242e-02, 1.638e-02, -7.398e-02, -5.792e-02, -2.113e-02, -3.688e-02, -3.066e-02, -3.019e-02, -3.598e-02) * s[1][2][0];
	r0 += M4(-2.585e-01, -7.062e-02, 1.453e-01, 1.564e-01, 3.975e-01, 2.367e-01, -7.829e-02, -3.944e-01, 1.659e-01, 8.423e-02, 7.739e-02, 3.968e-02, -7.991e-02, -1.803e-01, -1.146e-02, -4.101e-02) * s[1][2][1];
	r0 += M4(-5.981e-02, 1.161e-02, -1.271e-01, -5.264e-02, -2.441e-02, 4.109e-02, -9.927e-02, -2.185e-02, -4.301e-02, 1.480e-02, 4.505e-02, 1.679e-02, -1.284e-01, 4.429e-02, -5.550e-02, -7.286e-02) * s[2][0][0];
	r0 += M4(1.402e-01, 4.200e-02, 1.470e-01, 4.098e-02, 1.762e-01, 5.823e-02, -2.124e-01, 3.500e-03, 8.093e-02, -8.529e-03, -9.549e-02, -7.483e-02, -3.977e-02, 3.552e-02, -1.505e-02, -4.624e-02) * s[2][0][1];
	r0 += M4(-5.507e-02, -7.887e-02, 3.669e-03, 8.569e-02, 4.360e-02, -1.061e-01, 1.022e-01, 6.830e-04, 1.424e-01, 6.549e-02, -1.686e-02, -1.140e-01, 3.351e-01, -5.051e-02, -2.997e-02, 5.617e-02) * s[2][1][0];
	r0 += M4(5.367e-02, -3.461e-02, 1.503e-01, 2.080e-01, 1.156e+00, 1.734e-02, -3.857e-01, -3.041e-01, -1.358e-01, -8.130e-02, -1.991e-01, 2.351e-02, 1.372e-01, 9.307e-03, 1.833e-01, 1.238e-01) * s[2][1][1];
	r0 += M4(-1.978e-03, 7.032e-02, 1.020e-02, 4.477e-02, -2.212e-02, 2.205e-02, -4.400e-02, 4.325e-03, -3.372e-02, -3.606e-02, 6.539e-03, 1.192e-02, 1.500e-01, 6.117e-02, 6.692e-02, -3.006e-02) * s[2][2][0];
	r0 += M4(3.061e-02, 5.050e-02, 9.231e-02, 4.087e-02, 7.080e-02, -3.386e-02, 1.499e-01, -1.381e-01, 9.994e-02, -1.270e-02, -3.220e-02, -9.349e-02, -3.836e-02, 6.763e-02, 3.628e-02, 7.104e-02) * s[2][2][1];
	r0 += V4(3.674e-02, 4.356e-03, -1.748e-02, -1.862e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv3
//!BIND easu
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
#define l0(x, y) V4(conv3_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv3_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
			g[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	V4 s[3][3][2];
	V4 r0 = V4(0.0);
	s[0][0][0] = max(g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][0][1] = -max(-g[0][xy.y+0][xy.x+0], V4(0.0));
	s[0][1][0] = max(g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][1][1] = -max(-g[0][xy.y+0][xy.x+1], V4(0.0));
	s[0][2][0] = max(g[0][xy.y+0][xy.x+2], V4(0.0));
	s[0][2][1] = -max(-g[0][xy.y+0][xy.x+2], V4(0.0));
	s[1][0][0] = max(g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][0][1] = -max(-g[0][xy.y+1][xy.x+0], V4(0.0));
	s[1][1][0] = max(g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][1][1] = -max(-g[0][xy.y+1][xy.x+1], V4(0.0));
	s[1][2][0] = max(g[0][xy.y+1][xy.x+2], V4(0.0));
	s[1][2][1] = -max(-g[0][xy.y+1][xy.x+2], V4(0.0));
	s[2][0][0] = max(g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][0][1] = -max(-g[0][xy.y+2][xy.x+0], V4(0.0));
	s[2][1][0] = max(g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][1][1] = -max(-g[0][xy.y+2][xy.x+1], V4(0.0));
	s[2][2][0] = max(g[0][xy.y+2][xy.x+2], V4(0.0));
	s[2][2][1] = -max(-g[0][xy.y+2][xy.x+2], V4(0.0));
	r0 += M4(4.843e-02, 2.345e-02, -1.569e-02, -1.978e-03, -1.265e-01, -6.018e-02, 1.570e-02, 2.813e-02, -1.331e-02, -9.064e-05, -3.179e-03, -2.164e-02, 4.602e-02, -1.439e-02, 1.678e-02, -1.234e-02) * s[0][0][0];
	r0 += M4(4.179e-02, -1.919e-02, 8.820e-03, -2.029e-02, -1.007e-02, -1.681e-03, 3.851e-04, 9.634e-03, -2.130e-02, -5.762e-03, -4.595e-03, -9.739e-03, 5.383e-02, 1.200e-03, -5.572e-02, -6.104e-03) * s[0][0][1];
	r0 += M4(3.274e-02, 7.443e-02, -3.167e-03, -6.664e-03, -3.584e-01, -2.035e-01, 6.350e-02, 8.326e-02, 1.814e-02, -1.150e-02, 2.362e-02, 3.870e-02, -3.285e-02, 8.982e-02, 9.733e-03, 4.701e-02) * s[0][1][0];
	r0 += M4(-1.634e-01, 7.736e-02, 3.764e-03, 7.592e-02, -2.721e-02, -5.554e-02, -2.631e-02, -5.359e-02, 2.913e-02, -1.540e-03, 9.555e-03, 1.745e-02, -4.110e-03, 2.183e-01, -3.473e-02, -2.936e-02) * s[0][1][1];
	r0 += M4(-4.237e-02, -5.718e-02, -3.551e-03, -6.384e-03, 1.145e-01, 1.452e-02, 2.559e-02, 3.359e-02, 2.436e-02, 3.430e-02, 4.250e-04, -1.173e-02, -3.367e-02, -9.134e-02, -5.465e-03, 6.439e-03) * s[0][2][0];
	r0 += M4(3.308e-03, -1.616e-01, 2.552e-02, -6.773e-03, 3.622e-03, 1.044e-02, 1.385e-02, 2.289e-02, 4.654e-03, 1.084e-02, -1.230e-02, -1.776e-02, -8.009e-03, -1.260e-01, 1.886e-02, -5.451e-03) * s[0][2][1];
	r0 += M4(4.871e-02, -1.382e-02, 6.246e-02, 1.069e-02, 4.260e-01, -6.713e-02, 1.333e-01, -1.148e-01, 1.810e-02, -2.973e-03, -2.643e-02, -2.973e-03, 1.313e-01, 2.197e-03, 5.073e-02, -2.313e-02) * s[1][0][0];
	r0 += M4(-1.773e-02, -1.323e-02, 1.959e-02, -1.219e-02, 1.294e-03, -1.703e-02, -1.389e-02, -3.091e-02, -2.602e-03, -1.629e-03, -4.260e-02, 2.618e-03, 4.039e-02, -4.200e-02, 1.899e-01, -2.145e-02) * s[1][0][1];
	r0 += M4(-2.620e-01, -5.992e-02, -7.550e-02, 4.582e-02, -4.463e-01, 9.718e-01, -8.535e-01, 2.313e-01, 3.545e-01, 2.910e-01, -5.854e-05, -1.578e-02, 4.652e-02, 3.250e-01, -2.018e-02, 1.577e-01) * s[1][1][0];
	r0 += M4(-2.848e-02, -3.344e-03, -3.194e-01, -4.941e-02, 6.805e-02, 6.934e-02, 5.042e-02, 6.032e-02, 2.764e-01, 1.489e-01, 1.489e-01, 1.472e-02, -2.286e-01, 1.741e-01, -3.835e-02, 5.020e-01) * s[1][1][1];
	r0 += M4(-4.057e-03, -1.249e-01, -6.518e-02, -1.283e-01, 3.511e-01, -2.966e-01, 2.576e-01, -2.882e-01, -3.440e-02, 4.533e-02, 3.943e-02, 2.585e-02, -3.653e-02, -1.999e-01, -1.002e-01, -2.017e-01) * s[1][2][0];
	r0 += M4(-2.383e-02, -4.874e-02, -3.524e-02, -2.686e-01, -6.278e-03, 1.589e-02, -2.224e-02, -1.455e-02, -4.754e-02, 6.888e-02, -1.824e-02, 6.097e-02, 2.595e-04, -2.183e-01, -3.552e-02, -2.627e-01) * s[1][2][1];
	r0 += M4(1.943e-02, -1.303e-02, 7.153e-02, -1.576e-02, -6.324e-02, -8.385e-03, 4.548e-02, -9.155e-02, -1.013e-01, 6.860e-02, -6.234e-02, 2.287e-02, -4.290e-02, -3.232e-02, -4.460e-02, -2.920e-02) * s[2][0][0];
	r0 += M4(-2.410e-03, 4.315e-03, -2.191e-02, -2.246e-03, 2.897e-02, 3.103e-02, 2.472e-02, 2.456e-02, 1.403e-04, -1.194e-02, 2.021e-02, -1.358e-02, -1.946e-02, -2.251e-02, -3.504e-02, -2.063e-02) * s[2][0][1];
	r0 += M4(7.669e-02, 7.739e-02, -5.885e-02, 5.162e-02, -1.568e-01, -9.014e-02, -1.422e-01, 3.643e-01, -1.819e-01, -2.510e-01, 4.697e-01, 2.193e-01, 2.274e-02, -2.908e-02, -2.109e-01, -6.721e-02) * s[2][1][0];
	r0 += M4(-9.994e-04, -8.517e-03, 4.297e-02, -2.363e-02, -5.495e-02, -5.408e-02, -3.239e-02, -4.140e-02, -5.669e-03, 1.093e-02, 1.378e-01, 1.174e-01, -9.173e-03, -1.888e-03, -1.470e-01, -6.193e-02) * s[2][1][1];
	r0 += M4(7.306e-04, 2.948e-02, 1.894e-02, -4.515e-03, 2.351e-02, -2.265e-02, 1.909e-01, -6.710e-02, -3.137e-02, -9.447e-02, -6.644e-02, 1.411e-01, 4.738e-02, 8.911e-02, 3.982e-02, -1.466e-01) * s[2][2][0];
	r0 += M4(-7.092e-03, -1.788e-02, -2.960e-02, 5.653e-04, 7.370e-03, 9.824e-03, 1.437e-02, 3.058e-02, -3.196e-03, -7.252e-03, -2.040e-02, 2.879e-02, 1.162e-02, 5.510e-03, 2.755e-02, -5.620e-02) * s[2][2][1];
	r0 += V4(3.908e-03, 5.595e-03, 4.257e-03, 6.027e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

// CuNNy 8x4C
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

//!DESC CuNNy-8x4C-EASU
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


//!DESC CuNNy-8x4C-in
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
	r0 += V4(-2.918e-02, -4.117e-01, 7.832e-01, -2.954e-02) * s[0][0][0];
	r0 += V4(-9.976e-02, -2.321e-01, 3.358e-03, -4.499e-02) * s[0][1][0];
	r0 += V4(-4.278e-01, -1.179e-01, -6.785e-03, 4.103e-01) * s[0][2][0];
	r0 += V4(7.588e-02, -2.627e-01, -2.076e-03, 8.666e-02) * s[1][0][0];
	r0 += V4(-8.214e-02, 9.283e-01, -2.070e-03, -9.897e-02) * s[1][1][0];
	r0 += V4(5.801e-01, 1.101e-01, 7.499e-04, 2.623e-01) * s[1][2][0];
	r0 += V4(-2.680e-02, 2.912e-02, -4.622e-03, -3.012e-02) * s[2][0][0];
	r0 += V4(4.392e-02, 2.052e-04, -1.174e-03, 4.197e-02) * s[2][1][0];
	r0 += V4(-1.352e-02, -1.207e-02, 2.905e-03, -7.998e-02) * s[2][2][0];
	r0 += V4(-4.285e-02, 4.224e-02, -9.609e-03, -2.139e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv1
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
	r0 += M4(1.108e-01, -4.186e-01, 3.445e-02, -1.841e-01, -6.627e-02, 1.606e-01, -8.386e-02, 2.564e-01, 1.468e-02, 3.810e-02, -6.520e-02, 1.621e-01, -2.741e-02, -2.879e-01, 4.291e-02, -4.076e-01) * s[0][0][0];
	r0 += M4(-1.757e-01, -2.998e-01, 1.169e-01, -3.346e-01, 6.028e-03, 1.364e-01, -1.027e-01, 2.328e-01, -1.188e-01, 4.113e-01, -7.894e-01, -4.126e-01, 5.675e-01, -3.341e-01, -1.998e-02, 8.094e-01) * s[0][0][1];
	r0 += M4(1.769e-02, -1.030e-01, 3.568e-02, 4.725e-02, 2.858e-01, -1.076e-01, -3.369e-01, -5.605e-01, 2.581e-02, -9.947e-02, -1.607e-01, -3.252e-01, 1.250e-01, -5.330e-01, -1.805e-01, -3.367e-01) * s[0][1][0];
	r0 += M4(-2.608e-01, -9.133e-02, 2.740e-02, -1.832e-03, 4.548e-01, -2.566e-01, -1.365e-01, -4.467e-01, -5.793e-01, -5.111e-01, -3.351e-01, 1.921e-01, -7.871e-01, -1.272e+00, -3.116e-01, 1.564e+00) * s[0][1][1];
	r0 += M4(-3.216e-01, -2.783e-01, -9.273e-02, -3.379e-01, 8.177e-02, -3.316e-01, 7.480e-02, 2.716e-02, 1.216e-01, -3.121e-01, -7.971e-02, -6.095e-02, 2.847e-02, -3.371e-01, 9.631e-02, -2.358e-01) * s[0][2][0];
	r0 += M4(-1.315e-01, -4.913e-01, -1.654e-02, -1.728e-01, -1.212e-01, -7.492e-02, 2.582e-02, -2.297e-01, -2.222e+00, 4.558e-01, 1.631e-02, 9.094e-01, -2.369e-01, -1.567e-01, -5.472e-02, -2.840e-01) * s[0][2][1];
	r0 += M4(3.610e-01, -4.604e-01, -1.801e-01, -5.411e-01, -8.940e-02, 2.122e-01, -1.542e-01, 2.865e-01, -8.716e-02, 2.786e-01, -1.447e-01, 2.065e-01, -5.813e-02, 4.477e-01, -2.879e-01, 4.487e-01) * s[1][0][0];
	r0 += M4(1.550e-01, 2.094e-01, 1.248e-02, 4.484e-01, -1.362e-01, 2.666e-01, -1.335e-01, 3.565e-01, -6.305e-01, 3.922e-01, 1.594e+00, 1.297e+00, 2.457e+00, 2.735e+00, -2.679e+00, -1.757e+00) * s[1][0][1];
	r0 += M4(2.185e-01, 6.654e-01, 2.862e-01, 2.636e-01, 7.545e-02, 5.731e-01, -9.184e-01, 6.842e-01, 1.869e-01, 2.413e-01, -2.549e-01, -3.201e-02, 1.085e-01, 1.781e-01, 8.657e-02, 1.272e-02) * s[1][1][0];
	r0 += M4(2.619e-01, 6.916e-01, 7.251e-02, 1.067e-01, -5.522e-01, 5.257e-01, -7.860e-01, 2.919e-01, -7.374e-01, 2.391e+00, 4.003e-01, -1.591e-01, 2.066e-01, -1.323e-01, 6.731e-01, 1.115e+00) * s[1][1][1];
	r0 += M4(-6.021e-02, -4.037e-01, -2.764e-02, 2.427e-01, 1.364e-01, -1.702e-01, 3.904e-01, -1.089e+00, 4.266e-01, -4.482e-02, 2.167e-01, 1.946e-01, 1.667e-01, 3.421e-01, 6.275e-02, 1.393e-01) * s[1][2][0];
	r0 += M4(-5.178e-02, -2.846e-01, -9.880e-03, 5.837e-02, 2.545e-01, -3.973e-01, 4.391e-01, -9.824e-01, 1.208e+00, 3.958e+00, -1.228e+00, -1.629e-01, -9.685e-01, 1.160e+00, -2.062e-01, 9.996e-01) * s[1][2][1];
	r0 += M4(4.125e-02, 8.539e-02, -4.278e-01, -4.553e-01, 2.491e-02, -4.948e-02, 4.563e-02, 5.428e-02, 8.659e-03, -4.750e-02, -7.235e-03, 1.077e-01, -7.461e-02, -1.035e-01, 2.152e-01, -6.563e-02) * s[2][0][0];
	r0 += M4(3.320e-01, 2.183e-01, 5.015e-02, 7.120e-02, 1.592e-02, -8.559e-02, 1.499e-01, 9.644e-03, 1.032e-01, -1.565e+00, 3.754e-02, 8.816e-01, 1.425e+00, 1.785e+00, 1.332e+00, 8.010e-02) * s[2][0][1];
	r0 += M4(4.856e-01, 1.053e-01, -1.076e-01, 4.486e-01, -6.427e-02, -3.204e-02, 5.059e-01, 1.556e-01, -5.618e-02, -1.026e-01, 1.498e-01, 3.174e-02, 1.045e-01, -1.426e-02, 2.966e-01, 2.503e-02) * s[2][1][0];
	r0 += M4(5.150e-02, 4.256e-02, -7.831e-02, 1.309e-01, 5.149e-02, -1.160e-01, 4.495e-01, 2.398e-01, 2.697e+00, -1.408e+00, -1.421e+00, -8.393e-01, -1.791e+00, 9.673e-01, -4.991e-01, -6.882e-01) * s[2][1][1];
	r0 += M4(2.127e-01, -6.688e-02, 2.828e-02, 1.620e-01, -2.595e-01, 4.057e-02, 4.086e-01, -2.114e-01, 1.594e-01, 1.812e-01, 7.259e-02, 2.794e-02, 1.301e-01, 9.887e-02, 5.167e-02, -8.133e-02) * s[2][2][0];
	r0 += M4(-9.638e-02, 3.816e-02, -2.639e-03, -4.437e-02, 1.133e-01, -6.947e-03, 6.672e-01, 4.926e-02, 7.709e+00, 1.223e+01, -7.641e+00, 4.867e-01, -2.929e-01, -2.972e-01, -6.578e-01, 5.531e-01) * s[2][2][1];
	r0 += V4(-3.968e-01, -1.814e-02, -1.030e-02, 1.127e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv2
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
	r0 += M4(4.336e-02, -6.745e-02, 9.570e-03, -9.362e-04, -4.840e-02, 1.101e-01, 1.827e-02, 1.255e-02, 3.254e-01, 7.022e-02, 2.928e-02, -1.081e-01, -8.850e-02, -3.957e-01, -2.023e-01, -1.519e-01) * s[0][0][0];
	r0 += M4(-3.624e-02, -1.133e-01, 2.607e-02, -3.026e-02, -2.297e-02, 1.100e-01, 9.919e-02, 2.842e-02, -2.075e-01, -4.878e-01, -1.813e-01, -3.834e-02, -7.187e-02, 5.532e-02, -1.578e-02, 5.641e-02) * s[0][0][1];
	r0 += M4(-1.845e-02, -2.408e-01, 7.460e-02, 6.458e-02, -4.675e-02, -1.447e-01, 2.450e-01, 9.335e-02, 2.485e-01, -4.527e-01, -3.310e-01, -6.097e-01, 1.880e-02, 3.103e-02, -2.962e-01, -4.137e-02) * s[0][1][0];
	r0 += M4(1.210e-02, -2.357e-01, 1.052e-01, -7.353e-03, 8.074e-02, -1.423e-01, -4.908e-02, 9.119e-02, -3.697e-02, -6.965e-01, -1.044e-01, -1.951e-01, 1.553e-01, 1.659e-01, 2.544e-01, 2.114e-01) * s[0][1][1];
	r0 += M4(7.974e-02, 1.509e-01, -1.486e-02, 5.983e-02, 2.911e-02, -4.664e-04, 8.716e-02, 6.488e-02, 2.201e-02, -3.469e-02, -1.437e-01, -1.013e-02, -3.919e-03, -2.302e-01, -8.337e-02, -2.061e-01) * s[0][2][0];
	r0 += M4(6.956e-02, 8.990e-02, -9.188e-02, -7.857e-02, 1.716e-01, 2.670e-02, -3.618e-02, -3.352e-02, -4.949e-02, -4.290e-02, 1.623e-02, 1.712e-01, -1.894e-02, -2.606e-02, -9.720e-02, -5.905e-02) * s[0][2][1];
	r0 += M4(3.458e-03, -1.436e-01, -1.365e-01, 2.679e-01, 1.074e-01, -2.843e-01, -2.986e-02, -1.115e-02, 5.618e-01, 8.571e-02, -6.760e-02, -9.239e-02, 2.207e-01, 2.336e-01, -7.425e-02, -6.562e-02) * s[1][0][0];
	r0 += M4(5.728e-02, -2.666e-01, -2.153e-01, 7.948e-02, 5.613e-01, 4.098e-01, 1.163e-01, 2.424e-03, 2.422e-02, -3.037e-01, -1.268e-01, 3.103e-02, -2.690e-01, -1.699e-01, -1.901e-01, -7.994e-02) * s[1][0][1];
	r0 += M4(1.065e-01, -1.555e-01, 5.312e-02, 6.391e-01, 6.417e-03, -7.546e-01, -6.647e-01, -6.014e-01, -6.336e-02, 7.661e-01, 4.401e-01, -6.629e-02, 2.475e-01, 4.209e-01, -1.285e+00, -3.316e-01) * s[1][1][0];
	r0 += M4(2.778e-01, 8.050e-02, 1.623e-01, 6.466e-01, 8.528e-01, -5.356e-02, 7.495e-02, 2.060e-01, -8.381e-01, 9.370e-02, 1.811e-01, -3.069e-01, 4.299e-01, 3.521e-01, -2.609e-01, 2.066e-01) * s[1][1][1];
	r0 += M4(-2.267e-03, 2.069e-01, -2.348e-01, 1.385e-01, -1.508e-01, -2.161e-01, 1.161e-01, 2.041e-03, 3.007e-01, 4.474e-01, 1.365e-01, 1.097e-01, -1.806e-02, -2.583e-02, 1.953e-01, -3.530e-02) * s[1][2][0];
	r0 += M4(3.688e-02, 2.024e-01, -1.918e-02, 1.839e-01, 1.248e-01, 4.958e-01, 2.630e-01, 4.642e-01, -9.436e-03, 1.981e-01, -2.065e-01, 3.221e-02, -3.804e-02, -4.453e-02, 3.350e-01, 5.470e-02) * s[1][2][1];
	r0 += M4(-6.943e-02, 1.414e-01, 3.022e-02, 3.743e-02, -5.751e-01, -2.896e-01, -5.644e-02, -3.852e-02, 5.415e-02, -3.812e-02, -1.038e-01, -6.715e-02, -1.604e-01, -1.519e-01, 1.978e-03, -3.410e-03) * s[2][0][0];
	r0 += M4(1.556e-01, 2.549e-01, -9.802e-02, -6.288e-02, -4.622e-02, 1.655e-01, 1.126e-01, 1.377e-01, -7.822e-02, -6.252e-02, -2.189e-02, -1.603e-02, 6.157e-02, 7.449e-02, -7.980e-02, -6.104e-02) * s[2][0][1];
	r0 += M4(1.775e-01, -2.028e-02, -4.507e-02, 2.040e-01, -2.859e-01, -7.573e-01, 5.454e-02, 1.194e-01, 1.246e-01, 4.189e-01, 4.907e-03, 1.354e-01, -4.880e-02, 1.122e-01, -1.337e-01, -9.230e-02) * s[2][1][0];
	r0 += M4(2.059e-01, 1.213e-01, -1.815e-01, 3.076e-01, 3.002e-01, -1.078e-01, 3.248e-01, 1.880e-01, -1.209e-01, 1.416e-01, -8.144e-02, 4.317e-02, -5.434e-02, 5.719e-01, 5.505e-02, 5.901e-02) * s[2][1][1];
	r0 += M4(-2.166e-02, 9.711e-03, 1.057e-01, -3.871e-02, -1.116e-01, 1.300e-02, -4.996e-01, -4.618e-02, 7.842e-03, -8.663e-02, 1.856e-01, -4.366e-03, 2.120e-01, -8.748e-02, -1.132e-01, -9.931e-02) * s[2][2][0];
	r0 += M4(-1.449e-01, -1.779e-01, 9.993e-02, -2.783e-01, -3.654e-02, 2.289e-01, -1.383e-01, 1.137e-01, -2.030e-02, -2.588e-01, 4.013e-02, -1.103e-01, 1.956e-02, -6.580e-02, -3.322e-03, -8.298e-02) * s[2][2][1];
	r0 += V4(-5.847e-02, 2.006e-02, 2.646e-01, 1.221e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv3
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
	r0 += M4(3.669e-02, 5.015e-02, 1.516e-02, 2.788e-02, -8.093e-02, 1.631e-02, -1.965e-01, 1.052e-02, 1.407e-01, -3.801e-02, -3.192e-01, 9.317e-03, -6.955e-02, 4.107e-02, -7.443e-02, -3.125e-02) * s[0][0][0];
	r0 += M4(1.343e-01, 5.554e-03, -4.548e-02, -3.776e-03, -1.123e-01, -3.852e-02, 1.688e-01, 6.566e-02, 2.202e-01, -8.985e-04, -1.208e-01, -7.984e-02, -2.509e-02, 3.546e-02, -1.665e-02, -6.916e-02) * s[0][0][1];
	r0 += M4(6.076e-02, -3.006e-02, -4.179e-01, 1.011e-01, -1.632e-02, -1.500e-02, -3.278e-02, -1.595e-01, 4.507e-02, 6.005e-02, 1.202e-01, 1.694e-01, 4.281e-02, -5.393e-02, -1.522e-01, 2.662e-01) * s[0][1][0];
	r0 += M4(6.758e-02, -4.208e-02, -2.466e-02, 3.544e-02, -1.398e-01, -2.234e-02, 3.231e-01, -9.649e-02, 2.762e-02, 2.542e-02, 7.724e-02, -1.329e-02, 8.763e-02, -4.826e-02, -2.277e-01, 1.689e-01) * s[0][1][1];
	r0 += M4(8.501e-03, -7.367e-03, -1.239e-01, 2.596e-01, 5.893e-03, -3.266e-02, -2.537e-01, 5.427e-02, -6.460e-03, 1.876e-02, -1.178e-01, -4.416e-02, 4.336e-02, -4.004e-02, 1.074e-01, -1.075e-01) * s[0][2][0];
	r0 += M4(-7.530e-02, 5.478e-02, -6.067e-02, -4.486e-02, 3.037e-02, -3.815e-02, -1.049e-01, 8.521e-02, 5.060e-02, -2.886e-02, -1.455e-01, 7.544e-02, 5.810e-02, -1.841e-02, 1.085e-01, -1.077e-01) * s[0][2][1];
	r0 += M4(-3.241e-02, 7.325e-02, -3.746e-02, -8.192e-02, -7.305e-02, 1.393e-02, -3.566e-01, -3.155e-03, -6.284e-02, 5.455e-03, 1.585e-01, 4.601e-02, 1.685e-01, 1.407e-01, -5.859e-02, -2.194e-01) * s[1][0][0];
	r0 += M4(2.882e-02, 6.813e-02, -2.131e-01, 5.681e-03, -9.067e-02, -8.609e-02, -1.567e-01, 3.514e-02, 9.808e-02, -3.148e-02, 2.510e-01, -5.361e-02, 1.507e-01, 1.313e-01, -2.366e-01, -4.673e-02) * s[1][0][1];
	r0 += M4(2.018e-01, 5.339e-01, 5.476e-02, -4.492e-01, -3.350e-01, -3.230e-01, -6.463e-01, 4.494e-02, -1.487e-01, -3.306e-01, -6.049e-01, 1.257e+00, 4.238e-02, 6.505e-01, 4.073e-01, -3.898e-01) * s[1][1][0];
	r0 += M4(6.240e-01, 1.623e-01, 3.681e-01, -4.381e-02, -4.310e-01, -4.109e-01, -4.980e-01, -2.553e-02, -2.509e-01, -3.316e-01, -6.035e-01, 3.678e-01, -1.447e-01, 7.598e-01, 5.644e-01, -3.252e-01) * s[1][1][1];
	r0 += M4(8.569e-02, 1.400e-01, -3.359e-02, 1.116e-02, -6.371e-02, -1.406e-02, -3.161e-02, -2.944e-01, 5.015e-03, -1.544e-02, 1.032e-01, -1.556e-01, 1.597e-01, -1.196e-02, -9.490e-02, 5.254e-01) * s[1][2][0];
	r0 += M4(1.228e-01, 1.382e-01, -9.282e-02, 3.854e-02, -3.477e-02, 5.483e-03, 1.785e-01, -4.498e-01, 1.767e-02, -8.267e-02, 2.848e-02, -1.340e-01, 2.471e-01, -5.420e-02, -9.740e-03, 3.534e-01) * s[1][2][1];
	r0 += M4(1.817e-02, -1.666e-02, -8.756e-02, 6.067e-02, -4.281e-02, 4.652e-02, -4.376e-02, -6.288e-02, -5.574e-02, 2.389e-02, 9.608e-02, -1.333e-01, 1.634e-01, -3.485e-02, 4.919e-02, 1.273e-01) * s[2][0][0];
	r0 += M4(1.765e-02, -3.357e-02, -4.083e-02, 8.951e-02, -2.928e-02, -4.290e-03, 6.670e-02, 8.031e-02, -3.281e-02, -7.559e-02, 3.031e-02, -3.208e-02, -5.272e-02, 2.352e-02, 1.560e-01, 1.898e-01) * s[2][0][1];
	r0 += M4(7.681e-02, -3.714e-02, 1.513e-01, 7.579e-03, 3.713e-03, -9.666e-02, -1.940e-01, 5.437e-02, 1.571e-01, -4.553e-02, 1.363e-01, -6.244e-02, -5.748e-02, 2.698e-01, -3.625e-02, -1.134e-01) * s[2][1][0];
	r0 += M4(3.148e-02, -2.619e-02, -1.034e-02, -1.481e-01, 3.214e-02, -1.210e-01, -1.190e-02, -1.458e-01, 5.973e-02, -3.125e-02, 1.710e-02, -7.737e-02, 3.207e-01, -1.567e-01, 3.884e-02, 1.157e-02) * s[2][1][1];
	r0 += M4(-4.885e-02, -1.435e-02, -1.998e-01, 5.691e-02, -9.567e-02, -4.703e-02, -7.111e-02, -6.154e-02, 1.127e-01, 6.430e-03, 2.566e-02, -1.629e-02, 9.224e-02, 8.245e-02, -7.349e-02, -7.321e-03) * s[2][2][0];
	r0 += M4(-1.732e-01, 3.752e-02, -1.362e-01, 7.306e-02, -5.246e-02, -2.806e-02, 4.701e-02, 4.899e-02, 6.073e-02, 6.641e-03, 4.514e-02, 2.840e-02, 2.068e-02, 2.262e-01, -6.542e-02, -5.557e-02) * s[2][2][1];
	r0 += V4(4.871e-01, -8.259e-01, 7.109e-02, -1.061e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv4
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
#define l0(x, y) V4(conv3_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv3_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(-7.027e-02, 2.734e-02, 6.236e-02, 5.803e-02, 6.846e-01, -7.443e-01, 3.822e-01, -1.877e-01, 1.996e-02, -3.440e-02, -9.636e-02, -6.576e-04, 1.379e-02, 3.192e-03, -1.273e-01, 1.471e-02) * s[0][0][0];
	r0 += M4(-8.411e-02, -3.479e-02, 5.483e-02, 1.187e-01, -1.326e-01, 1.753e-01, 8.159e-03, -1.440e-01, -4.418e-02, 2.310e-02, 2.188e-03, 2.929e-03, 1.485e-01, -2.626e-03, -2.413e-02, 3.134e-01) * s[0][0][1];
	r0 += M4(-3.299e-02, 3.933e-02, -1.586e-01, -1.694e-01, -8.682e-01, -2.933e-01, 5.701e-01, -9.119e-01, -6.227e-02, 1.617e-02, -6.138e-02, 1.789e-01, -5.103e-02, 3.789e-02, -1.500e-01, 1.397e-01) * s[0][1][0];
	r0 += M4(-5.412e-02, -1.713e-01, -1.201e-02, -6.227e-02, -3.036e-02, -8.669e-02, -1.678e-01, 8.129e-02, -9.888e-03, -6.787e-03, -3.308e-02, -4.477e-02, 3.156e-02, -1.510e-02, -5.112e-02, 4.366e-02) * s[0][1][1];
	r0 += M4(1.440e-01, 3.689e-02, -4.784e-02, -2.631e-02, -1.317e-01, 1.726e-01, -1.541e-04, 2.865e-01, -1.028e-02, 1.897e-02, -4.610e-02, 3.385e-02, -2.457e-02, -3.052e-02, -2.988e-02, 8.648e-02) * s[0][2][0];
	r0 += M4(-1.264e-02, 6.060e-03, 1.148e-01, -2.725e-01, 1.178e-01, -2.058e-02, -2.300e-02, -4.309e-02, 3.926e-02, 8.145e-03, -1.038e-02, -2.638e-02, -1.887e-02, -4.683e-02, 3.468e-02, -5.216e-02) * s[0][2][1];
	r0 += M4(-1.183e-01, 5.394e-01, -6.810e-02, 1.418e-01, -1.369e-01, -6.195e-01, 1.146e+00, 4.153e-01, -2.078e-01, 2.006e-01, -1.421e-01, -2.811e-02, -4.777e-01, -3.566e-01, -1.364e-02, -1.037e-01) * s[1][0][0];
	r0 += M4(-7.270e-01, 1.259e+00, -1.294e-02, 7.159e-02, -1.506e-01, 2.403e-01, -6.690e-02, 9.552e-02, 1.166e-02, 1.747e-01, -1.488e-01, -1.664e-01, -3.336e-02, -1.352e-01, 2.163e-01, 5.484e-01) * s[1][0][1];
	r0 += M4(-4.464e-01, 6.054e-03, 3.367e-01, -3.626e-01, -1.942e+00, 1.558e-01, 4.668e+00, 2.156e+00, -3.471e-01, -1.213e-01, 2.770e-02, 4.291e-01, -3.810e-01, 7.124e-02, -2.038e-01, -5.564e-01) * s[1][1][0];
	r0 += M4(-1.632e+00, 3.313e-01, 5.252e-01, 8.340e-02, 2.306e-02, -1.852e-03, 5.293e-01, 3.590e-01, -4.526e-01, 7.739e-02, -2.103e-01, 3.973e-01, 2.124e-01, -3.346e-02, -2.299e-02, -3.373e-01) * s[1][1][1];
	r0 += M4(2.967e-02, -6.911e-03, -1.247e-01, 9.133e-02, -3.463e-01, 1.778e-01, 6.188e-01, -2.050e+00, 9.253e-02, -3.132e-02, 5.678e-02, -5.226e-01, 6.665e-02, -3.845e-02, 6.665e-02, 5.223e-02) * s[1][2][0];
	r0 += M4(-1.586e-01, 1.580e-01, -3.944e-03, 5.619e-01, 2.036e-01, -1.255e-01, -7.593e-02, 6.643e-02, 9.278e-02, -3.089e-02, -1.279e-02, 4.289e-02, 2.620e-02, -1.610e-03, 8.130e-02, -7.697e-02) * s[1][2][1];
	r0 += M4(9.983e-02, -2.618e-01, -6.058e-02, -1.181e-02, -6.578e-01, -1.637e+00, 1.610e-01, -8.608e-01, -1.042e-01, 4.783e-02, -9.573e-02, 4.130e-02, -7.084e-02, 1.854e-01, -1.406e-03, -1.674e-01) * s[2][0][0];
	r0 += M4(-2.051e-01, 2.929e-01, 6.681e-02, -1.247e-01, 1.997e-01, -2.023e-01, -8.621e-02, -7.633e-02, 1.074e-01, -3.955e-01, -3.901e-02, 6.152e-02, 1.224e-01, 4.111e-01, 1.349e-01, 1.294e-01) * s[2][0][1];
	r0 += M4(3.608e-01, -3.682e-01, 8.911e-02, -8.522e-02, 1.371e-02, -5.215e-01, 6.507e-01, -1.432e-02, -2.932e-01, -4.828e-02, -2.189e-01, -2.886e-01, -8.615e-02, 1.530e-01, -3.925e-02, -1.249e-01) * s[2][1][0];
	r0 += M4(1.087e-01, 6.883e-02, 1.443e-01, -1.479e-01, 2.526e-01, -2.195e-02, -9.949e-02, 1.112e-02, -4.221e-01, 3.250e-02, -1.938e-01, 9.547e-02, 1.189e-01, 1.310e-01, 1.935e-01, -2.368e-01) * s[2][1][1];
	r0 += M4(-8.222e-02, -8.480e-02, 1.849e-02, 2.343e-02, 1.622e-01, -2.682e-02, 1.597e-01, 1.140e-01, -1.673e-01, 7.645e-02, -2.068e-01, 8.262e-02, 1.436e-01, 4.814e-02, -5.083e-02, 2.333e-01) * s[2][2][0];
	r0 += M4(-4.133e-01, -1.221e-02, -9.005e-02, -8.294e-03, -3.426e-01, 9.582e-02, -1.055e-02, -7.723e-02, -1.471e-01, 1.931e-02, -1.361e-02, 3.373e-02, -1.932e-02, 1.043e-01, -3.944e-02, 2.662e-02) * s[2][2][1];
	r0 += V4(2.395e-01, 8.061e-02, 2.479e-02, 3.879e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv5
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv4_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(4.043e-02, -3.302e-02, -3.315e-02, 1.126e-02, -1.295e-02, -4.764e-04, 2.591e-02, -4.480e-02, -7.722e-02, 1.070e-02, 9.446e-02, -1.833e-02, -1.284e-01, 7.213e-02, 2.959e-02, 1.845e-01) * s[0][0][0];
	r0 += M4(-8.534e-02, 1.379e-01, 1.361e-01, 1.128e-01, 1.916e-02, -3.770e-02, -4.018e-03, -3.342e-02, 7.079e-03, 1.150e-01, -4.502e-02, 2.931e-04, -5.765e-02, 1.080e-01, 2.301e-02, 5.224e-02) * s[0][0][1];
	r0 += M4(-7.873e-03, 5.785e-02, -2.447e-01, 6.371e-02, -7.140e-02, 1.732e-01, -1.744e-01, -1.171e-02, 9.703e-03, 1.819e-01, -7.345e-02, 1.714e-01, 2.930e-01, -2.043e-01, -1.249e-01, -4.169e-01) * s[0][1][0];
	r0 += M4(1.304e-02, 2.692e-01, -5.268e-02, 1.264e-01, 2.380e-01, -4.727e-02, -3.564e-01, -6.548e-02, -5.047e-02, 3.111e-01, -1.909e-01, 3.714e-01, 1.662e-01, -1.912e-01, -4.927e-02, -3.389e-01) * s[0][1][1];
	r0 += M4(-9.754e-02, -9.151e-02, -8.716e-03, 3.278e-02, -5.334e-01, 1.111e-01, 2.726e-02, 2.822e-01, 6.764e-02, -8.098e-02, 3.292e-02, -1.596e-01, -1.265e-01, -1.463e-01, 4.684e-02, 2.623e-02) * s[0][2][0];
	r0 += M4(-4.979e-03, 8.205e-02, 9.516e-03, 7.469e-03, 8.175e-02, -1.879e-01, -2.514e-01, 1.548e-01, 6.427e-03, -8.134e-02, 5.801e-02, -6.219e-02, -1.469e-01, -1.613e-01, 3.357e-02, 3.368e-03) * s[0][2][1];
	r0 += M4(1.471e-01, -1.046e-01, -5.688e-02, -3.276e-01, -7.709e-02, 6.476e-02, 5.835e-02, -1.393e-03, 9.223e-03, 1.900e-01, 2.255e-02, -1.700e-01, -1.632e-01, -1.925e-01, -6.710e-02, 5.594e-01) * s[1][0][0];
	r0 += M4(1.159e-01, 9.759e-02, 6.102e-02, -1.997e-01, -5.114e-02, -2.580e-02, 2.124e-02, 4.850e-02, -2.424e-01, 4.784e-01, 2.524e-02, -1.666e-02, -4.048e-02, -2.853e-01, -1.214e-01, 3.350e-01) * s[1][0][1];
	r0 += M4(5.477e-01, -1.603e-01, -7.947e-01, -3.488e-01, 3.204e-01, -1.757e-01, -1.938e-01, -2.786e-01, 5.376e-01, -9.850e-01, 6.378e-01, 1.923e-01, 2.449e-01, -1.004e-01, -1.228e-02, -2.766e-01) * s[1][1][0];
	r0 += M4(6.737e-01, -6.631e-02, -3.584e-01, -1.899e-01, 5.112e-01, -3.004e-01, -3.151e-01, -2.724e-01, 5.904e-01, -2.823e-01, 1.443e-01, -9.730e-02, 6.503e-02, -1.668e-01, 4.516e-02, 3.159e-01) * s[1][1][1];
	r0 += M4(-7.979e-02, -3.741e-02, 5.119e-02, 1.107e-02, -1.802e-01, 9.782e-02, 2.337e-01, 2.672e-02, 2.289e-01, 5.254e-01, 1.074e-01, -6.489e-02, -2.221e-02, 2.016e-02, -3.461e-02, 1.178e-01) * s[1][2][0];
	r0 += M4(-7.885e-02, 1.267e-01, 1.174e-01, 3.874e-02, 1.942e-01, -1.098e-01, 1.929e-01, -7.999e-02, 7.465e-03, 2.744e-01, -7.405e-02, -3.216e-01, 1.538e-01, -4.734e-03, -1.136e-01, -1.274e-01) * s[1][2][1];
	r0 += M4(-8.127e-02, 6.246e-02, 3.551e-02, 9.908e-02, -5.027e-02, 6.421e-02, 1.520e-02, 5.650e-02, 2.433e-01, -6.393e-02, -1.006e-01, -4.266e-02, 3.132e-02, -6.003e-02, -4.421e-02, 5.349e-02) * s[2][0][0];
	r0 += M4(-4.031e-02, 1.556e-01, 6.961e-02, 1.629e-01, -7.167e-02, 5.880e-02, 3.255e-02, 1.189e-01, 2.201e-01, 4.093e-02, 6.012e-03, -2.378e-01, 2.031e-02, -1.205e-01, -3.704e-02, -2.939e-02) * s[2][0][1];
	r0 += M4(-8.873e-02, -8.650e-02, -4.170e-02, 1.026e-03, -3.443e-02, 4.401e-03, -1.088e-02, -7.268e-02, -1.986e-01, 8.364e-02, 1.067e-01, 1.551e-01, 6.017e-02, 4.356e-02, -3.016e-02, -8.575e-03) * s[2][1][0];
	r0 += M4(-1.811e-01, 3.703e-02, 2.117e-02, 6.559e-02, -5.356e-02, -2.641e-02, 1.439e-03, 7.628e-02, -1.251e-01, 1.123e-01, -2.074e-01, 2.563e-01, -1.052e-02, -1.056e-01, -9.106e-02, 3.538e-02) * s[2][1][1];
	r0 += M4(9.061e-03, 1.197e-01, 6.078e-03, -9.406e-02, 3.180e-02, -4.091e-02, -7.965e-03, -6.453e-02, -2.125e-02, 2.200e-03, 7.755e-02, 6.306e-02, 1.539e-01, 4.018e-02, -6.505e-02, 2.528e-02) * s[2][2][0];
	r0 += M4(-5.516e-02, -3.032e-02, 3.046e-02, -3.067e-02, -1.020e-01, 2.159e-02, -7.771e-04, 2.596e-01, 1.804e-01, 2.423e-01, -1.969e-01, -8.234e-02, 1.454e-01, 3.304e-02, -9.890e-02, -1.149e-01) * s[2][2][1];
	r0 += V4(1.362e-01, -3.044e-02, -5.868e-02, -1.611e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv6
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv5_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv5_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(3.632e-02, 2.031e-02, 1.716e-02, -5.923e-02, 2.170e-02, 8.165e-02, 1.726e-01, 5.645e-02, 2.898e-02, -8.357e-02, -1.202e-02, -1.173e-01, -3.485e-02, -8.003e-02, -5.746e-02, -6.428e-02) * s[0][0][0];
	r0 += M4(8.030e-02, 1.586e-01, 7.496e-02, -9.231e-02, -4.319e-02, -3.556e-02, 4.452e-03, 4.931e-02, 3.823e-02, -3.679e-02, 1.443e-02, -1.982e-02, 4.404e-02, 3.763e-02, 5.434e-02, -9.755e-02) * s[0][0][1];
	r0 += M4(2.748e-02, 2.539e-01, -3.348e-02, -7.391e-03, -7.886e-04, -1.256e-02, -2.529e-01, -2.192e-01, -2.685e-02, 1.026e-01, -2.311e-01, 3.939e-02, -1.108e-01, 1.754e-01, -4.626e-02, 3.598e-01) * s[0][1][0];
	r0 += M4(8.858e-02, -1.293e-01, 7.851e-02, -1.855e-01, 5.050e-02, -1.632e-01, 1.061e-01, -1.994e-01, 1.946e-02, 1.676e-01, -2.823e-01, 4.105e-02, -5.214e-02, 4.022e-01, -2.202e-02, 1.518e-01) * s[0][1][1];
	r0 += M4(5.483e-02, 2.099e-02, 6.125e-02, -6.143e-02, 1.317e-02, 1.663e-01, 1.536e-01, 1.670e-01, -1.026e-02, 7.859e-02, 8.957e-02, 2.381e-01, 3.444e-02, -6.320e-02, 1.111e-01, 1.852e-01) * s[0][2][0];
	r0 += M4(-4.825e-03, 4.484e-02, -2.864e-02, 7.563e-02, -1.986e-02, -2.085e-02, 3.566e-02, 7.997e-02, 7.189e-03, -1.535e-02, -7.288e-02, -3.939e-03, -7.254e-02, 1.385e-01, -9.797e-02, 1.457e-01) * s[0][2][1];
	r0 += M4(-1.093e-01, -1.816e-01, 5.324e-03, 1.478e-01, -6.799e-02, 8.854e-04, 1.562e-01, 1.337e-01, -6.521e-02, 6.556e-02, 4.276e-03, 1.597e-02, -1.072e-01, -4.520e-01, -3.643e-01, 1.650e-01) * s[1][0][0];
	r0 += M4(-8.063e-02, -9.520e-02, -2.592e-02, 1.063e-01, -1.096e-01, -1.781e-01, -1.248e-01, 6.345e-02, -4.875e-02, 2.275e-01, 8.830e-02, 3.431e-02, -6.156e-02, -1.065e-01, -4.350e-02, 1.309e-01) * s[1][0][1];
	r0 += M4(-1.936e-01, -7.946e-02, 3.181e-01, -1.983e-01, -8.521e-02, 4.084e-02, -1.363e-01, 4.129e-01, -8.179e-01, -1.642e-01, 4.475e-02, -1.704e-01, -2.253e-02, 2.002e-01, 5.943e-01, 2.036e-01) * s[1][1][0];
	r0 += M4(-1.604e-01, -1.656e-01, 1.976e-01, -2.785e-01, -1.927e-02, 3.653e-01, -3.397e-01, 1.937e-01, -5.911e-01, -2.861e-03, -6.393e-01, 2.396e-02, 8.086e-02, 1.986e-01, 3.469e-01, -2.201e-01) * s[1][1][1];
	r0 += M4(1.826e-02, -1.596e-01, 1.023e-01, -2.744e-01, -3.382e-02, 1.304e-01, 2.496e-01, 1.087e-01, -2.843e-02, -5.346e-02, -1.340e-01, -3.454e-02, -1.054e-01, -1.040e-01, 2.181e-02, 6.997e-02) * s[1][2][0];
	r0 += M4(6.875e-02, -7.172e-02, 5.900e-02, -2.903e-01, -5.211e-03, 1.363e-01, -3.347e-02, 2.101e-01, 1.983e-02, -1.757e-01, -8.864e-02, -2.352e-01, 5.628e-02, -1.359e-02, 4.094e-03, -1.265e-01) * s[1][2][1];
	r0 += M4(1.409e-02, 7.691e-02, 9.818e-02, 1.053e-01, 1.024e-01, 1.763e-01, 8.920e-02, -4.985e-02, 8.706e-04, 6.720e-02, 1.911e-02, -3.979e-02, -5.938e-02, -5.535e-02, 1.806e-02, -1.255e-01) * s[2][0][0];
	r0 += M4(-6.614e-02, -9.569e-03, -4.657e-02, 1.103e-01, 9.259e-02, 2.863e-02, 7.963e-02, -7.203e-02, 5.236e-02, 1.422e-02, 7.886e-02, -6.470e-02, -4.403e-02, 2.787e-02, -5.358e-03, 9.025e-02) * s[2][0][1];
	r0 += M4(-1.179e-01, -1.042e-01, 1.508e-01, 5.233e-02, 1.456e-01, 3.345e-01, -7.873e-03, -1.712e-01, 1.123e-01, -1.013e-01, 2.284e-02, -1.174e-01, -1.775e-01, 1.780e-01, -1.650e-01, 1.671e-01) * s[2][1][0];
	r0 += M4(-1.866e-01, -1.043e-01, 6.081e-02, 1.636e-01, 1.067e-01, 1.240e-01, -9.843e-02, -1.223e-01, 9.009e-02, -1.206e-01, 5.073e-02, -2.516e-02, -9.547e-02, -1.509e-03, 7.560e-02, 1.005e-01) * s[2][1][1];
	r0 += M4(-5.791e-02, -1.812e-02, 6.167e-02, 9.772e-02, 3.476e-02, -2.580e-02, 1.028e-01, -8.528e-02, 2.119e-02, -3.334e-02, -4.368e-02, 9.636e-03, -7.793e-02, 6.130e-02, -2.390e-01, 1.241e-01) * s[2][2][0];
	r0 += M4(-1.314e-01, 2.227e-02, 2.368e-03, 1.663e-01, 7.886e-02, 1.165e-01, -1.593e-02, 3.596e-02, 1.173e-02, -1.142e-02, 4.819e-02, 3.866e-03, -5.531e-02, -4.186e-03, 1.008e-02, 1.123e-01) * s[2][2][1];
	r0 += V4(6.344e-03, 5.968e-03, -2.896e-02, 6.388e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv7
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv6_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv6_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(4.643e-02, -4.993e-02, -1.048e-02, -1.149e-01, -7.590e-02, -9.205e-02, -2.643e-02, -1.319e-01, 3.259e-02, 3.143e-02, 2.383e-02, -1.821e-02, 1.127e-02, -3.923e-02, -9.122e-02, 1.798e-01) * s[0][0][0];
	r0 += M4(3.644e-02, -7.261e-02, -2.760e-02, -2.322e-02, 1.425e-02, 1.585e-02, 3.717e-02, -4.573e-02, 3.259e-02, -4.782e-03, 5.737e-02, 2.971e-03, 8.452e-03, 1.174e-02, -2.948e-02, 2.140e-02) * s[0][0][1];
	r0 += M4(9.879e-02, 3.779e-01, 3.096e-01, -2.397e-01, 1.160e-01, 3.060e-01, 2.510e-01, -1.670e-01, 4.436e-02, -7.513e-02, -4.967e-02, 5.494e-02, -8.024e-02, -1.668e-01, -1.364e-01, 8.783e-02) * s[0][1][0];
	r0 += M4(-3.257e-02, 9.697e-02, 2.498e-02, 9.789e-02, 2.715e-02, 1.076e-02, -1.980e-02, 3.869e-02, -4.290e-02, -1.593e-01, -1.782e-01, 3.311e-01, 2.632e-02, 1.907e-01, 1.251e-01, -1.092e-01) * s[0][1][1];
	r0 += M4(3.486e-02, 1.075e-01, 2.036e-01, 7.033e-03, 4.079e-02, 1.463e-01, 2.056e-01, -1.933e-02, -7.304e-03, -4.698e-02, -2.060e-02, 2.885e-02, -3.493e-02, -3.102e-02, -7.945e-02, 8.928e-03) * s[0][2][0];
	r0 += M4(2.381e-02, 8.179e-02, 2.710e-02, 8.876e-03, 6.058e-03, -1.295e-01, -5.420e-02, 5.232e-03, 7.255e-03, -6.597e-02, -9.671e-02, -6.519e-02, -1.762e-02, 1.855e-01, 9.346e-02, -6.533e-03) * s[0][2][1];
	r0 += M4(-1.111e-01, -3.822e-02, 1.990e-02, 3.514e-02, 9.254e-02, -3.690e-02, 1.267e-01, 3.208e-02, -5.918e-02, 9.699e-04, 1.121e-01, -1.232e-01, -5.292e-02, -1.175e-01, -5.936e-02, -9.801e-02) * s[1][0][0];
	r0 += M4(-1.811e-01, 7.675e-03, 7.526e-02, -5.151e-02, 1.643e-02, -4.837e-03, -2.052e-02, 1.038e-02, -2.146e-01, -4.818e-02, 1.857e-01, -2.523e-01, 1.009e-01, -7.408e-02, 4.237e-02, -1.754e-01) * s[1][0][1];
	r0 += M4(5.137e-01, 8.805e-02, -3.644e-01, 1.224e-01, -2.674e-02, 1.039e-01, -2.330e-01, 3.273e-01, -1.717e-01, 3.079e-02, -8.598e-03, -1.509e-01, 1.890e-01, 5.832e-01, 2.442e-02, 8.081e-02) * s[1][1][0];
	r0 += M4(5.717e-01, 5.088e-02, -2.998e-01, -3.065e-01, -1.213e-01, -1.479e-01, -2.915e-02, -8.649e-02, -2.736e-01, 3.883e-01, -1.900e-01, -4.388e-01, 3.330e-01, 5.371e-01, 1.910e-01, 1.532e-01) * s[1][1][1];
	r0 += M4(-6.461e-02, -1.724e-01, -1.846e-01, 5.163e-02, 1.434e-01, 3.389e-01, 5.034e-01, 8.307e-02, 2.488e-02, 3.482e-02, 2.455e-02, -3.916e-02, -3.353e-02, -2.332e-01, -2.300e-01, 7.321e-02) * s[1][2][0];
	r0 += M4(-1.485e-02, -2.512e-01, -1.393e-01, 2.196e-02, -4.065e-02, 1.183e-01, 1.528e-01, -3.284e-02, -1.992e-02, -6.957e-02, 1.825e-01, -1.616e-01, 7.686e-02, -8.317e-02, 3.611e-02, 8.382e-02) * s[1][2][1];
	r0 += M4(1.863e-02, 4.234e-02, 6.182e-02, -5.854e-02, 1.018e-01, 2.814e-02, 7.252e-02, -7.239e-02, 1.073e-02, 2.120e-03, -1.243e-02, 2.430e-02, 9.627e-02, 4.089e-02, 7.095e-02, 4.199e-02) * s[2][0][0];
	r0 += M4(-1.265e-01, -2.624e-02, -2.643e-02, 5.422e-03, -2.281e-02, -1.084e-02, 7.395e-04, 1.860e-02, 1.717e-02, -1.642e-02, 2.378e-02, 2.598e-02, 1.994e-02, 1.480e-03, 3.383e-02, -7.418e-03) * s[2][0][1];
	r0 += M4(5.494e-02, 1.403e-01, 3.457e-02, -4.247e-02, 1.509e-01, 1.418e-01, 1.492e-01, -6.650e-02, -5.983e-02, -1.686e-01, -1.072e-01, 6.163e-02, -2.750e-02, 3.941e-02, 6.243e-02, -1.628e-02) * s[2][1][0];
	r0 += M4(-1.625e-01, -3.380e-02, -1.916e-01, -4.111e-02, 5.104e-02, -2.442e-02, 3.382e-02, 4.508e-02, -1.135e-01, -1.755e-01, -1.303e-01, 1.473e-01, 6.567e-02, 5.386e-02, -8.415e-03, -3.677e-03) * s[2][1][1];
	r0 += M4(4.944e-04, 3.413e-02, 1.413e-02, -3.700e-02, -2.773e-02, 5.913e-02, 8.812e-03, -1.758e-02, -1.940e-02, -3.414e-02, -2.705e-02, -1.597e-02, -1.080e-02, -5.582e-02, -7.676e-02, -2.044e-02) * s[2][2][0];
	r0 += M4(-8.276e-02, -4.817e-02, -6.247e-02, -1.494e-02, -4.017e-02, -5.490e-02, 5.927e-02, 7.886e-02, -8.395e-02, -7.400e-02, -1.049e-02, -2.402e-02, 5.690e-02, 5.370e-02, 8.758e-02, -2.829e-02) * s[2][2][1];
	r0 += V4(-4.669e-02, -2.259e-02, -1.340e-02, -2.453e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-conv8
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv7_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv7_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(-1.485e-02, -1.171e-01, 1.445e-02, 2.370e-02, 5.243e-02, 6.713e-02, 1.257e-02, 7.666e-03, -8.233e-02, -2.607e-01, 2.884e-02, 1.223e-01, -3.577e-02, -1.966e-02, 8.770e-03, -9.002e-03) * s[0][0][0];
	r0 += M4(-2.214e-02, -8.189e-02, 1.175e-02, 1.502e-02, 6.725e-02, 6.159e-02, -3.230e-02, -7.074e-02, -6.470e-02, -1.589e-01, 8.188e-03, 7.106e-02, -7.886e-02, -5.138e-02, 1.587e-02, 3.332e-02) * s[0][0][1];
	r0 += M4(6.846e-02, -4.971e-01, -7.627e-02, 3.203e-01, -1.909e-02, 9.861e-02, 1.335e-02, -7.488e-02, -9.798e-03, -1.909e-01, -4.904e-02, 2.592e-01, 5.945e-02, -6.531e-02, 5.935e-02, 1.429e-02) * s[0][1][0];
	r0 += M4(2.091e-02, -1.310e-01, 3.091e-02, 6.950e-02, 3.176e-02, 3.042e-02, -9.602e-03, -4.576e-02, 3.553e-03, -3.791e-02, -4.159e-02, 1.454e-01, -3.196e-02, -3.584e-02, -3.787e-02, 2.666e-02) * s[0][1][1];
	r0 += M4(4.524e-02, -2.958e-02, 3.147e-03, 2.278e-01, -2.851e-02, 1.764e-02, -3.506e-02, -6.024e-02, 4.870e-02, 1.605e-02, 2.105e-02, 8.742e-02, -4.468e-02, -1.146e-02, -2.361e-04, 3.628e-02) * s[0][2][0];
	r0 += M4(1.994e-02, 2.316e-02, 1.897e-02, 2.243e-02, 2.119e-02, 2.838e-02, -2.176e-02, -2.065e-02, 2.313e-03, -8.581e-03, 1.493e-02, 2.976e-03, -5.994e-02, -2.576e-02, -4.177e-03, 1.451e-02) * s[0][2][1];
	r0 += M4(1.118e-02, 1.710e-01, 1.258e-01, -5.302e-03, -2.666e-01, -5.488e-01, -1.772e-01, 3.659e-01, 4.555e-02, 1.743e-01, 3.076e-01, 2.062e-02, 4.264e-03, -7.487e-02, 1.378e-01, 2.580e-02) * s[1][0][0];
	r0 += M4(-4.568e-02, 2.656e-03, 4.317e-02, -6.181e-03, -8.565e-02, -4.104e-02, -1.711e-01, 5.748e-02, 4.293e-02, 8.836e-02, 2.402e-01, -3.030e-02, -8.725e-03, -3.724e-02, 1.743e-01, 2.889e-02) * s[1][0][1];
	r0 += M4(-6.467e-01, -2.998e-01, -2.362e-01, 4.148e-01, 6.975e-02, 2.813e-01, 7.756e-02, 5.471e-01, -3.320e-01, -1.814e-01, 1.185e-01, -6.113e-01, 2.931e-01, 6.868e-01, -2.285e-01, -3.365e-01) * s[1][1][0];
	r0 += M4(-3.155e-01, -1.736e-01, -3.254e-01, 1.184e-01, -3.938e-02, -2.660e-02, 3.236e-02, 1.925e-01, 2.941e-02, 2.353e-02, 7.415e-02, -3.135e-01, 3.445e-02, 2.787e-01, -1.775e-01, -7.975e-02) * s[1][1][1];
	r0 += M4(-5.892e-02, 4.852e-04, 3.402e-03, -9.580e-02, 5.086e-03, -1.447e-02, -5.482e-02, -6.274e-02, -1.312e-02, 2.666e-02, 1.296e-02, 5.009e-02, 6.649e-02, -2.338e-02, 1.470e-01, -2.125e-01) * s[1][2][0];
	r0 += M4(5.150e-02, 6.679e-03, 9.701e-02, 5.752e-02, -2.050e-05, -1.412e-02, -4.364e-02, 2.280e-02, -7.906e-03, 2.380e-02, 2.517e-02, -6.858e-04, 3.368e-02, -8.370e-03, 3.879e-02, -1.101e-01) * s[1][2][1];
	r0 += M4(9.538e-03, -2.913e-02, -1.953e-01, 7.084e-03, -7.218e-02, 1.719e-01, 7.482e-01, -1.990e-04, 5.644e-02, 2.453e-02, 3.677e-02, -1.101e-03, -3.074e-02, 3.809e-02, 2.824e-01, -5.081e-02) * s[2][0][0];
	r0 += M4(-2.036e-03, 1.544e-02, -9.364e-03, 1.427e-02, 4.221e-02, 7.598e-02, 1.808e-01, -7.886e-02, -2.439e-02, -2.411e-02, 1.008e-01, 4.141e-02, 1.191e-02, -3.037e-02, 2.016e-01, 1.839e-03) * s[2][0][1];
	r0 += M4(-1.127e-01, -1.545e-02, -7.526e-03, -6.552e-02, 2.513e-01, 2.339e-02, 2.927e-03, 5.818e-02, 1.237e-02, 4.165e-03, -7.554e-02, 9.717e-03, 7.416e-02, 2.657e-02, 6.450e-02, 1.481e-02) * s[2][1][0];
	r0 += M4(-4.888e-04, 3.203e-02, -1.914e-01, -7.116e-02, 5.660e-02, 4.436e-02, 9.659e-02, -7.333e-02, -1.556e-02, -2.708e-02, 3.302e-02, 8.644e-02, 1.322e-01, 2.174e-02, 1.693e-02, -1.841e-02) * s[2][1][1];
	r0 += M4(2.888e-02, 1.571e-02, -5.202e-02, 8.669e-03, 1.769e-02, -1.965e-03, -2.329e-02, 2.185e-02, 4.422e-03, 4.380e-03, 1.201e-02, -1.991e-02, -2.124e-02, -1.666e-02, 7.882e-02, -8.330e-03) * s[2][2][0];
	r0 += M4(-7.626e-03, 9.889e-03, 7.358e-02, -2.925e-02, -2.207e-02, -3.729e-03, -2.495e-02, -2.760e-02, 3.205e-02, -6.755e-03, -8.463e-03, 2.232e-02, 1.505e-02, -1.060e-02, 1.553e-03, 2.549e-02) * s[2][2][1];
	r0 += V4(-3.624e-03, -6.485e-03, -1.568e-02, 9.735e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv8
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
#define l0(x, y) V4(conv8_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv8_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(-2.077e-02, 3.760e-02, 9.620e-03, -2.719e-02, 8.724e-03, -1.027e-03, 2.284e-02, 1.553e-02, -3.236e-02, 1.211e-02, -3.087e-02, 7.104e-03, 2.190e-02, -6.449e-03, 3.267e-02, 1.553e-02) * s[0][0][0];
	r0 += M4(8.462e-03, 4.026e-02, 1.680e-02, -4.818e-02, 7.622e-03, -6.807e-03, 1.373e-02, 3.478e-02, -2.831e-03, -1.251e-02, -4.162e-02, -1.837e-02, -1.574e-02, 1.376e-02, 5.462e-02, -1.425e-02) * s[0][0][1];
	r0 += M4(-2.934e-02, -8.673e-02, -3.764e-03, 5.380e-02, 9.808e-03, -8.507e-03, 3.412e-02, 2.058e-03, 3.156e-01, 1.113e-01, 9.536e-02, -5.073e-02, 6.087e-02, -2.669e-02, 2.451e-02, 1.888e-02) * s[0][1][0];
	r0 += M4(-7.138e-02, -1.269e-01, 1.357e-01, 1.324e-01, 6.421e-02, -1.545e-02, 2.373e-02, -3.407e-02, 1.352e-01, 1.173e-01, -6.517e-03, -2.217e-02, 3.721e-02, -1.006e-01, 4.603e-02, 8.840e-02) * s[0][1][1];
	r0 += M4(-2.773e-03, 1.303e-02, -1.763e-02, -2.811e-02, 4.700e-02, -4.675e-02, 5.003e-02, 4.726e-02, 2.810e-02, 6.879e-02, 3.713e-02, 1.140e-01, 1.559e-02, -6.388e-03, 2.162e-02, -1.053e-03) * s[0][2][0];
	r0 += M4(5.188e-02, -5.720e-02, 1.534e-02, 3.436e-02, 6.042e-02, -1.521e-03, 4.236e-02, 2.236e-02, -3.817e-02, -2.637e-02, 1.676e-02, 4.610e-03, 2.539e-02, 9.398e-04, 3.049e-02, 6.203e-03) * s[0][2][1];
	r0 += M4(-1.045e-01, -4.467e-02, -1.368e-01, -3.119e-02, 1.259e-02, 2.929e-04, -2.617e-02, 3.322e-02, -4.406e-02, 3.793e-02, -4.632e-02, -2.205e-03, -6.704e-02, 5.438e-02, -1.096e-01, -1.081e-02) * s[1][0][0];
	r0 += M4(-9.768e-02, 3.481e-02, -1.792e-01, 1.559e-02, -1.307e-02, 7.325e-03, 1.923e-03, 2.019e-02, -5.540e-02, -4.565e-03, -3.066e-02, -3.599e-02, -3.936e-02, 8.806e-02, -2.399e-01, 1.741e-02) * s[1][0][1];
	r0 += M4(2.497e-01, 1.140e-01, 2.027e-01, 4.212e-02, 1.192e-02, 1.074e-02, -2.007e-01, -2.709e-01, 1.023e-01, -1.489e-01, 4.503e-01, 1.587e-01, -4.358e-02, -5.107e-01, -2.450e-02, -4.161e-01) * s[1][1][0];
	r0 += M4(8.330e-01, 1.255e-01, 1.106e-01, -3.041e-01, 9.007e-02, -1.820e-01, -2.280e-01, -2.783e-01, 1.870e-02, -9.054e-02, 2.407e-01, 1.293e-01, 1.353e-02, -2.147e-01, -1.023e-01, -5.605e-01) * s[1][1][1];
	r0 += M4(-6.814e-02, 6.611e-03, -5.438e-02, 2.455e-02, -9.630e-03, -6.425e-02, -4.949e-02, -2.145e-01, -7.733e-03, 1.125e-01, -7.871e-02, 2.245e-02, -4.968e-02, 7.003e-02, -4.164e-02, 1.566e-02) * s[1][2][0];
	r0 += M4(-1.122e-01, 3.485e-01, -1.763e-01, -1.424e-01, -9.986e-02, -1.465e-01, -6.300e-04, -2.310e-01, -5.816e-02, 1.702e-03, -9.781e-02, -1.183e-02, 1.210e-04, 3.001e-02, -2.056e-02, 1.924e-02) * s[1][2][1];
	r0 += M4(2.276e-02, -5.097e-02, 8.179e-02, 3.503e-02, -1.239e-02, 3.249e-02, -5.383e-02, -5.975e-02, 1.328e-02, -2.182e-02, 2.275e-02, 2.458e-02, 3.241e-02, -4.749e-03, 4.955e-02, 2.482e-02) * s[2][0][0];
	r0 += M4(1.937e-03, -4.896e-02, 6.211e-02, 5.478e-02, 9.329e-03, 4.087e-02, -1.601e-02, -2.240e-02, 1.229e-02, -1.319e-02, 2.803e-02, 3.378e-02, 2.193e-03, -3.061e-02, 9.371e-02, 3.512e-02) * s[2][0][1];
	r0 += M4(2.286e-03, 5.456e-02, -7.916e-02, -4.580e-02, -9.478e-02, -1.220e-01, 1.831e-01, 1.533e-01, 3.362e-02, 7.209e-02, -8.130e-02, -8.087e-02, 1.910e-02, 6.717e-03, 2.931e-02, -1.353e-01) * s[2][1][0];
	r0 += M4(1.657e-02, 4.842e-02, -1.022e-01, -1.249e-01, -2.758e-01, -2.735e-01, 6.152e-01, 1.047e-01, -4.567e-04, 3.158e-02, -7.642e-02, -5.624e-02, -2.146e-02, -7.516e-03, 2.666e-02, 3.819e-02) * s[2][1][1];
	r0 += M4(9.122e-03, 1.932e-02, 1.968e-02, 1.978e-02, -1.767e-02, -2.034e-02, 2.519e-03, 3.431e-02, -9.119e-03, -1.204e-03, 1.954e-02, 3.609e-02, 2.318e-03, -1.941e-02, -1.832e-02, 1.388e-02) * s[2][2][0];
	r0 += M4(1.043e-02, 9.636e-03, -6.890e-03, -5.346e-02, -1.818e-02, -2.081e-01, 1.234e-03, 2.503e-01, 3.560e-03, 6.040e-04, 2.471e-03, -5.285e-03, -5.707e-03, -3.714e-03, -3.283e-03, 8.249e-03) * s[2][2][1];
	r0 += V4(-2.237e-04, 1.007e-03, 5.207e-04, 1.776e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

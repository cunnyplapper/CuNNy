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

//!DESC CuNNy-3x4C-EASU
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
	r0 += V4(1.023e-01, 4.963e-02, 3.378e-02, 7.541e-03) * s[0][0][0];
	r0 += V4(1.499e-01, -7.024e-01, -3.115e-01, 2.814e-02) * s[0][1][0];
	r0 += V4(1.758e-01, 3.111e-03, 2.350e-01, 3.988e-03) * s[0][2][0];
	r0 += V4(-1.450e-01, -5.715e-02, -5.550e-02, 2.856e-02) * s[1][0][0];
	r0 += V4(-3.746e-01, 7.012e-01, -6.099e-01, -6.273e-01) * s[1][1][0];
	r0 += V4(2.736e-02, 6.339e-03, 6.475e-01, 1.563e-02) * s[1][2][0];
	r0 += V4(2.850e-02, 3.379e-03, 2.069e-02, 1.327e-03) * s[2][0][0];
	r0 += V4(-1.140e-01, -2.278e-04, 7.652e-02, 1.576e-02) * s[2][1][0];
	r0 += V4(1.479e-02, -3.459e-03, -3.912e-02, 8.337e-03) * s[2][2][0];
	r0 += V4(2.043e-02, 1.430e-03, 3.953e-04, 5.735e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
	r0 += M4(1.638e-01, -4.415e-02, -2.519e-01, 9.461e-02, 4.028e-02, 4.553e-02, -1.750e-01, 1.382e-01, -9.442e-02, -1.225e-01, 3.437e-04, -2.277e-01, 3.033e+00, -2.565e-01, 1.888e+00, -1.194e+00) * s[0][0][0];
	r0 += M4(1.159e-01, -4.150e-02, -1.374e-01, -3.146e-02, 1.450e-01, 3.281e-02, -1.386e-02, 1.849e-01, -4.345e-02, -3.306e-01, 1.156e-01, -2.468e-01, 2.187e-01, 2.258e-02, 9.427e-02, 3.766e-02) * s[0][0][1];
	r0 += M4(3.395e-01, -2.723e-01, 5.490e-01, 1.773e-01, 3.061e-01, 1.806e-01, -1.924e-01, 2.644e-03, -5.684e-01, -6.467e-01, 2.629e-02, 2.243e-02, 5.530e+00, -3.982e+00, -1.747e+00, -4.593e+00) * s[0][1][0];
	r0 += M4(1.160e-01, 1.156e-02, 1.193e-01, -1.197e-01, 3.330e-01, 7.610e-02, 8.053e-03, 1.418e-01, -4.334e-01, -5.176e-01, 3.125e-01, -2.438e-01, 1.979e-01, 1.083e-01, -7.404e-02, -1.442e-01) * s[0][1][1];
	r0 += M4(2.667e-01, 1.643e-01, 5.254e-01, -2.394e-01, -2.448e-01, -1.705e-01, 2.547e-02, 7.405e-02, -6.456e-02, -1.119e-01, -2.998e-01, 2.666e-01, -7.288e-01, 7.479e-01, -3.248e+00, -2.492e+00) * s[0][2][0];
	r0 += M4(-3.200e-02, 5.342e-02, -1.543e-01, 4.074e-01, 4.927e-02, -1.701e-01, 6.387e-01, -1.585e-01, 5.806e-02, -4.358e-02, 1.335e-02, 1.526e-01, -2.338e-01, 2.727e-02, 4.261e-02, -1.167e-01) * s[0][2][1];
	r0 += M4(2.520e-01, -1.215e-01, -1.829e-01, 1.395e-02, -2.607e-01, -1.956e-01, -3.877e-01, -2.804e-01, 2.507e-01, 7.012e-01, 5.080e-01, 4.355e-01, 8.551e+00, -3.933e-01, -8.547e-01, -1.758e-01) * s[1][0][0];
	r0 += M4(-2.528e-02, 1.514e-01, -2.177e-01, -2.618e-01, -6.365e-01, -1.331e-01, -4.545e-01, -1.330e-01, -6.154e-01, 1.606e+00, -3.363e-01, 3.654e-01, -1.646e-01, -4.935e-02, 2.720e-02, 2.941e-02) * s[1][0][1];
	r0 += M4(-1.376e+00, 9.988e-02, 2.834e-01, 5.248e-02, -1.733e-01, 5.301e-01, -3.416e-01, 2.512e-01, 7.256e-01, 8.620e-02, -8.448e-01, -5.293e-01, 1.691e+01, -3.348e+00, -3.800e+00, -9.150e+00) * s[1][1][0];
	r0 += M4(-6.057e-02, -2.296e-01, 9.865e-02, 9.326e-02, -6.796e-01, 8.315e-01, 1.141e+00, 4.285e-01, 4.389e-01, 4.493e-01, 4.531e-01, -5.531e-01, -1.484e-01, -6.323e-02, -1.470e-01, 7.340e-02) * s[1][1][1];
	r0 += M4(2.303e-01, 1.994e-01, 4.089e-01, -4.372e-01, -3.213e-01, -5.684e-01, -2.159e-01, 7.277e-02, 2.354e-02, 5.771e-02, 8.776e-02, -2.691e-01, 5.687e+00, 4.922e-01, -4.857e-01, -2.145e+00) * s[1][2][0];
	r0 += M4(-2.835e-02, 5.079e-02, 2.536e-01, -6.972e-01, -2.329e-01, -5.571e-01, 7.988e-01, -7.544e-02, -4.504e-02, 8.038e-02, -5.679e-02, -1.432e-01, -2.645e-02, -2.316e-01, -1.578e-01, 1.753e-02) * s[1][2][1];
	r0 += M4(-2.976e-01, 1.444e-01, -2.337e-01, -1.720e-01, 2.883e-01, 7.947e-02, -8.004e-02, -1.182e-01, 1.180e-02, -8.772e-02, 2.153e-01, 2.568e-01, 1.921e+00, -1.306e+00, 5.208e-01, -1.135e-01) * s[2][0][0];
	r0 += M4(-9.643e-02, 1.002e-01, -8.370e-02, -1.052e-01, -3.534e-01, 2.892e-01, -3.701e-01, -1.501e-01, -5.723e-01, 4.759e-01, -1.583e-01, 3.467e-01, 6.388e-02, 8.258e-02, -3.101e-02, 4.407e-02) * s[2][0][1];
	r0 += M4(-1.794e-01, 3.935e-02, -5.259e-02, 3.346e-01, 1.217e+00, 1.507e-02, -7.831e-03, -9.708e-02, 3.937e-01, -6.645e-02, 9.887e-02, 1.390e-01, 8.537e+00, -2.602e+00, -1.186e+00, -1.147e+00) * s[2][1][0];
	r0 += M4(-5.272e-02, 1.864e-02, -1.424e-01, 3.143e-01, -4.051e-01, -4.132e-01, -3.869e-01, -3.171e-01, 1.218e-01, -7.784e-02, 1.146e-01, 2.569e-01, 1.423e-01, 1.223e-01, 9.273e-02, 1.084e-03) * s[2][1][1];
	r0 += M4(2.612e-02, -3.129e-02, -2.064e-02, 6.387e-01, 2.762e-01, 1.002e-01, 3.409e-01, 3.025e-01, -8.586e-02, -3.650e-02, -8.955e-02, -1.150e-01, 2.175e+00, -6.317e-01, -7.980e-02, -1.525e+00) * s[2][2][0];
	r0 += M4(5.691e-02, -2.180e-02, 2.578e-01, 3.696e-01, 3.299e-02, 1.241e-02, 1.710e-02, 2.990e-01, 1.223e-02, -1.398e-02, 6.714e-02, -4.171e-02, 5.395e-02, -3.661e-02, 1.302e-01, 3.402e-02) * s[2][2][1];
	r0 += V4(2.004e-02, -3.503e-03, -9.727e-03, -8.051e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
	r0 += M4(2.631e-03, -1.076e-01, 2.469e-01, -8.706e-02, -2.703e-02, -2.109e-01, 1.114e-01, -4.586e-03, -1.292e-01, 2.105e-01, -1.939e-01, 3.643e-02, -2.862e-01, 2.153e-01, -1.745e-01, -7.197e-02) * s[0][0][0];
	r0 += M4(1.895e-01, 1.399e-02, 2.303e-01, -6.254e-02, -5.576e-02, -7.691e-02, 4.224e-02, -4.618e-02, 5.399e-03, -5.634e-02, -1.450e-01, 4.411e-02, 1.360e-01, -1.127e-01, -1.778e-02, 1.071e-01) * s[0][0][1];
	r0 += M4(2.283e-01, -1.334e-02, -5.440e-01, 6.982e-02, -1.470e-01, -2.117e-01, -3.109e-01, -1.207e-01, -3.801e-01, 4.253e-03, 2.388e-01, -1.359e-01, -3.747e-01, 3.266e-02, 2.763e-02, 7.992e-02) * s[0][1][0];
	r0 += M4(-6.013e-01, 4.427e-01, -3.097e-01, 4.113e-02, -7.213e-02, -2.134e-01, -3.018e-01, 2.959e-02, -6.995e-02, -3.664e-02, -9.673e-02, 6.811e-02, 3.818e-01, -2.423e-01, -1.775e-01, 3.244e-01) * s[0][1][1];
	r0 += M4(1.636e-01, -3.940e-02, -1.167e-01, -6.736e-02, 4.069e-02, -1.553e-01, -4.933e-01, 2.224e-01, -1.975e-01, 5.294e-02, -1.092e+00, 3.725e-01, -8.376e-02, 5.884e-02, -1.185e-01, -2.427e-02) * s[0][2][0];
	r0 += M4(-3.565e-01, 2.144e-01, 1.335e-01, -7.202e-03, 7.068e-03, 6.151e-03, -2.315e-01, -5.348e-02, -8.442e-02, 3.553e-02, 3.827e-02, -5.841e-02, 5.606e-01, -1.558e-01, -4.097e-02, -6.470e-02) * s[0][2][1];
	r0 += M4(1.138e-02, -2.035e-02, -1.390e-02, 4.455e-02, 1.294e-01, -9.528e-02, 5.009e-02, 1.077e-01, 2.117e-01, 3.585e-01, 1.795e-01, -2.114e-01, -3.641e-01, -3.018e-01, -2.606e-02, 1.076e-01) * s[1][0][0];
	r0 += M4(5.367e-01, -3.825e-01, 4.382e-02, 9.281e-02, -3.157e-02, 1.166e-01, 7.056e-02, -2.644e-02, -2.301e-01, 2.822e-01, 3.042e-02, -1.231e-01, 2.401e-01, -6.699e-01, -5.620e-02, 3.271e-01) * s[1][0][1];
	r0 += M4(1.442e-01, 1.304e-01, -3.272e-01, 6.884e-01, 1.642e-01, -9.358e-01, 1.743e-01, 6.877e-02, 4.469e-01, -2.881e-01, 6.430e-01, -4.767e-01, -1.216e-01, 5.813e-02, -9.086e-02, -4.291e-01) * s[1][1][0];
	r0 += M4(-1.083e+00, 1.333e-01, -2.863e-01, 6.181e-01, 1.527e-01, -3.747e-02, 2.536e-01, -2.243e-01, 5.603e-02, -4.154e-02, 1.736e-01, -4.700e-01, 8.144e-01, -4.795e-01, -8.668e-01, 1.506e-01) * s[1][1][1];
	r0 += M4(1.830e-01, -8.769e-02, -8.225e-02, 8.700e-02, -4.717e-01, -2.933e-03, -2.213e-01, 6.900e-01, -3.874e-02, -6.876e-02, -6.581e-02, -4.876e-02, -2.143e-01, 1.057e-01, -7.708e-02, -7.790e-02) * s[1][2][0];
	r0 += M4(-3.173e-01, -2.147e-01, 1.008e-01, 2.457e-01, -3.212e-01, 1.133e-01, 3.432e-01, 2.354e-01, -3.417e-02, 5.649e-02, -2.949e-01, -2.304e-02, 4.834e-01, 7.277e-02, -1.714e-01, 2.748e-02) * s[1][2][1];
	r0 += M4(-2.126e-03, 4.547e-02, -1.170e-02, -1.862e-02, 6.022e-02, 3.266e-03, -9.601e-02, 3.073e-02, 1.013e-01, 1.499e-01, -1.280e-02, 6.734e-02, -8.663e-02, -1.431e-01, 7.257e-02, -1.508e-01) * s[2][0][0];
	r0 += M4(4.072e-01, 1.193e-01, 1.409e-01, -6.102e-03, -6.003e-02, 2.126e-01, -2.717e-02, -3.340e-02, -1.578e-01, 1.364e-01, 7.771e-02, 6.244e-02, 3.487e-01, -2.498e-01, -6.371e-03, 7.002e-02) * s[2][0][1];
	r0 += M4(1.237e-01, -1.722e-01, 1.226e-01, 2.848e-02, 1.487e-03, 6.199e-02, 1.342e-01, 1.376e-01, 4.269e-01, 3.754e-02, -2.330e-02, -1.446e-01, -2.725e-01, 2.018e-01, -1.083e-01, 4.456e-03) * s[2][1][0];
	r0 += M4(7.354e-01, -1.968e-01, -1.204e-01, 2.075e-02, 5.350e-02, 6.625e-02, 3.277e-02, 6.760e-02, -9.151e-02, 1.282e-04, 7.308e-02, 3.470e-02, 3.247e-01, 5.816e-02, -2.215e-02, 1.642e-01) * s[2][1][1];
	r0 += M4(8.902e-02, 4.793e-02, 4.699e-02, -6.419e-02, 2.589e-01, -3.570e-02, 6.092e-02, 2.036e-01, -1.126e-01, -1.185e-01, 1.674e-01, 6.511e-02, -2.732e-01, 5.464e-02, -6.629e-02, -2.077e-02) * s[2][2][0];
	r0 += M4(3.061e-01, 2.073e-01, 1.364e-01, -7.870e-02, 1.294e-01, -4.289e-02, -4.223e-02, -5.519e-02, -1.208e-01, -2.271e-02, -4.318e-02, 7.199e-02, 2.114e-01, 9.444e-02, 9.118e-02, 6.391e-02) * s[2][2][1];
	r0 += V4(-4.157e-03, -2.888e-03, 1.128e-02, 3.058e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
	r0 += M4(1.063e-01, -4.945e-02, -6.567e-02, 1.667e-02, 2.181e-01, -1.382e-01, -1.655e-01, 2.925e-02, -6.387e-01, 3.086e-01, 2.881e-01, -2.759e-02, 6.635e-02, -4.242e-02, -5.847e-02, 9.363e-03) * s[0][0][0];
	r0 += M4(-3.697e-03, -3.968e-02, -6.743e-02, 8.423e-02, 6.723e-02, -1.722e-02, -2.302e-02, 4.042e-03, 4.822e-02, -4.615e-02, -5.310e-02, 2.335e-02, -7.815e-02, 1.736e-01, 1.191e-01, -1.812e-01) * s[0][0][1];
	r0 += M4(-1.634e-01, 7.015e-02, 7.349e-02, -2.545e-02, 8.308e-02, -1.552e-02, 1.232e-01, -2.725e-02, -3.701e-01, 4.541e-01, 2.182e-01, -1.321e-01, 1.528e-01, -5.017e-02, 2.726e-02, -2.911e-02) * s[0][1][0];
	r0 += M4(2.129e-03, 8.236e-02, -4.460e-02, -4.957e-02, 1.007e-03, -7.443e-03, 4.777e-02, -5.336e-02, 2.759e-03, 3.495e-02, 6.822e-02, -2.846e-02, 6.721e-02, 1.631e-02, 2.139e-01, -2.506e-01) * s[0][1][1];
	r0 += M4(7.444e-02, -4.506e-02, -1.047e-01, 6.987e-02, 1.054e-01, -1.488e-01, -3.405e-02, -7.056e-02, 5.606e-02, 3.301e-03, -2.063e-02, -7.238e-03, 8.764e-02, -1.073e-01, -1.830e-03, 5.447e-02) * s[0][2][0];
	r0 += M4(1.150e-01, -1.538e-01, -5.773e-02, 7.141e-02, 4.867e-02, -7.153e-02, -3.532e-02, 5.466e-02, 1.478e-02, -3.784e-02, 1.056e-03, -6.911e-03, -8.721e-02, -2.082e-02, 1.144e-01, -1.571e-01) * s[0][2][1];
	r0 += M4(-3.467e-01, 5.774e-02, 1.831e-01, 4.604e-02, 3.824e-02, 6.726e-03, -1.605e-01, 1.798e-02, -7.561e-01, 6.074e-01, 7.324e-01, -3.540e-01, 8.228e-02, 3.780e-03, 3.137e-02, -5.921e-02) * s[1][0][0];
	r0 += M4(-9.497e-02, -6.249e-02, 1.265e-01, 7.898e-02, -1.194e-01, 1.964e-02, 1.418e-01, 5.415e-02, 6.190e-02, -2.924e-02, 2.111e-02, -3.091e-02, -3.671e-02, 2.446e-01, 1.047e-01, -3.013e-01) * s[1][0][1];
	r0 += M4(-3.031e-01, 4.932e-01, 2.358e-01, -2.298e-01, -3.541e-01, 6.481e-02, -1.862e-01, 3.309e-01, -2.043e-01, 3.249e-01, 2.627e-01, -3.770e-01, 3.273e-01, -2.660e-01, -4.170e-01, 1.499e-01) * s[1][1][0];
	r0 += M4(-1.939e-01, 2.468e-01, 4.039e-02, -1.821e-01, -1.460e-01, 1.100e-01, -1.290e-01, -5.762e-02, 1.065e-01, -3.312e-02, -1.285e-01, 4.057e-03, 2.822e-01, -4.616e-01, -4.405e-01, 2.060e-01) * s[1][1][1];
	r0 += M4(-3.544e-02, 5.749e-02, 1.126e-01, -1.998e-01, -2.939e-01, 1.006e-01, 3.097e-02, -9.247e-02, -7.367e-02, 1.270e-01, 5.816e-02, -1.724e-01, -8.978e-03, -2.271e-01, -7.815e-04, 1.310e-01) * s[1][2][0];
	r0 += M4(-8.391e-02, 5.916e-02, -2.279e-02, 7.169e-02, -1.052e-01, 3.534e-02, 1.826e-02, 7.697e-02, -3.625e-02, -9.107e-02, 5.806e-02, -5.775e-03, -9.858e-02, -4.722e-01, 9.628e-02, 9.210e-02) * s[1][2][1];
	r0 += M4(4.191e-02, -3.830e-02, 1.059e-01, 8.203e-02, 6.853e-02, -5.150e-04, 1.568e-02, -2.169e-02, -3.858e-01, 2.474e-01, 5.410e-01, -1.962e-01, 9.725e-02, -9.644e-02, -1.213e-01, 8.521e-02) * s[2][0][0];
	r0 += M4(1.214e-01, -5.421e-02, -1.071e-01, 7.348e-02, 1.634e-02, -1.677e-02, 7.499e-02, 2.959e-02, 1.346e-01, -1.516e-01, -1.655e-01, 1.352e-01, -5.678e-02, 9.546e-02, 3.136e-02, -1.312e-01) * s[2][0][1];
	r0 += M4(2.359e-02, 9.739e-02, 2.065e-01, -4.959e-01, -2.920e-01, 2.268e-01, 2.666e-01, -2.927e-01, -7.028e-01, 5.723e-01, 7.284e-01, -5.348e-01, -4.012e-03, -7.495e-02, -1.899e-01, 2.153e-01) * s[2][1][0];
	r0 += M4(1.630e-02, -1.011e-02, 1.255e-01, -1.194e-01, -8.042e-02, 1.112e-01, 2.001e-01, -2.075e-01, 1.800e-02, -8.780e-02, -9.704e-02, 1.675e-01, -1.581e-01, 2.906e-02, -1.711e-01, 9.077e-02) * s[2][1][1];
	r0 += M4(-6.578e-03, -1.511e-02, -6.714e-02, 1.205e-01, -4.246e-02, 8.346e-02, 6.874e-02, -3.603e-01, -9.839e-02, 2.687e-01, 1.724e-01, -4.195e-01, 2.715e-02, -7.593e-02, -1.057e-01, 2.632e-01) * s[2][2][0];
	r0 += M4(5.508e-02, -1.356e-02, -3.226e-02, -4.714e-02, 9.804e-02, 4.615e-02, -1.704e-02, -9.367e-02, -8.119e-03, -4.579e-02, -4.430e-02, 1.255e-01, -2.339e-01, -7.413e-02, -2.557e-02, 2.967e-01) * s[2][2][1];
	r0 += V4(-3.335e-02, 3.894e-02, 3.723e-02, -3.172e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-out-shuffle
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
	r0 += M4(-7.885e-02, -1.098e-02, -2.065e-03, 4.285e-02, -3.280e-03, 3.716e-02, 1.762e-02, 3.354e-02, -3.400e-02, -4.138e-02, -6.898e-03, -2.883e-02, -1.606e-01, 1.509e-01, 1.257e-01, 5.339e-02) * s[0][0][0];
	r0 += M4(-8.369e-03, 4.564e-04, 7.904e-03, 4.123e-03, -9.009e-02, 4.628e-02, 6.861e-02, 4.578e-02, -6.140e-02, 1.585e-02, -1.522e-03, -1.628e-04, -3.225e-03, 3.337e-02, 2.144e-02, 2.126e-02) * s[0][0][1];
	r0 += M4(1.861e-01, 1.239e-01, -7.279e-02, -5.376e-02, 6.819e-03, -1.987e-02, -1.974e-02, -2.032e-02, 6.036e-02, 6.778e-02, -1.311e-02, 7.381e-03, 8.820e-02, -3.445e-01, 4.244e-02, 1.006e-01) * s[0][1][0];
	r0 += M4(2.801e-02, 3.194e-02, -1.583e-02, 4.167e-03, -1.355e-01, -1.663e-01, 3.635e-02, 8.545e-02, 2.273e-01, 1.038e-01, -3.692e-02, -2.956e-02, -7.068e-03, -3.058e-02, -4.690e-02, -4.016e-02) * s[0][1][1];
	r0 += M4(-3.464e-02, 1.058e-03, -3.543e-03, -5.076e-02, -5.233e-03, -7.589e-03, 5.798e-03, 7.478e-03, -4.063e-02, -4.830e-02, -7.563e-03, -2.280e-02, -5.409e-02, 2.342e-02, 1.162e-02, 1.640e-02) * s[0][2][0];
	r0 += M4(-2.205e-02, -2.913e-02, 1.728e-03, -6.313e-03, -1.746e-03, 1.868e-02, -1.429e-02, 1.208e-02, -3.958e-02, -8.716e-02, 1.624e-02, -1.667e-02, -4.583e-03, -9.996e-03, 2.057e-02, 4.436e-03) * s[0][2][1];
	r0 += M4(1.968e-01, -1.206e-02, 1.518e-01, -1.377e-02, 1.882e-01, 1.744e-01, 1.951e-01, 2.007e-01, 1.490e-02, -4.259e-03, -6.851e-03, -3.796e-02, 3.701e-01, 3.748e-01, -1.558e-01, 3.642e-01) * s[1][0][0];
	r0 += M4(6.610e-02, 4.561e-02, 6.860e-02, 3.644e-02, 3.466e-01, 1.694e-01, 2.329e-01, 1.958e-01, -1.027e-01, 5.670e-02, -1.001e-01, 3.896e-02, 1.925e-01, 2.002e-01, 1.362e-01, 1.838e-01) * s[1][0][1];
	r0 += M4(-2.892e-01, 2.926e-01, 4.225e-01, 6.738e-01, 5.472e-02, 1.153e-01, 1.048e-01, 1.255e-01, 2.940e-01, 2.613e-01, 2.584e-01, 2.548e-01, 4.600e-01, 2.536e-01, 2.871e-01, -4.750e-01) * s[1][1][0];
	r0 += M4(2.231e-01, 2.349e-01, 2.456e-01, 2.560e-01, -4.448e-02, 7.562e-01, -2.359e-01, 3.143e-01, 3.729e-01, -2.344e-02, 9.097e-01, 4.385e-01, 1.092e-01, 9.190e-02, 1.014e-01, 6.988e-02) * s[1][1][1];
	r0 += M4(-2.210e-03, -1.658e-01, -1.664e-02, 7.202e-02, -8.033e-03, -4.498e-03, -3.436e-03, -9.622e-03, -6.854e-02, -2.824e-02, -1.290e-01, -5.480e-02, -4.249e-02, 1.613e-02, -9.595e-02, 4.199e-02) * s[1][2][0];
	r0 += M4(-4.881e-02, -1.461e-02, -7.220e-02, -2.217e-02, 6.922e-02, -1.429e-01, 6.201e-02, -1.209e-01, -5.877e-02, -1.301e-01, -1.153e-01, 3.732e-03, -2.402e-02, -9.673e-03, -4.968e-02, -2.593e-02) * s[1][2][1];
	r0 += M4(6.730e-03, 5.345e-03, -1.331e-02, -3.083e-02, 3.597e-03, 6.947e-02, -2.709e-02, 5.747e-02, -1.579e-02, -9.075e-03, -1.531e-02, 6.382e-03, -9.480e-02, -4.550e-02, -9.302e-03, 3.383e-02) * s[2][0][0];
	r0 += M4(-2.291e-03, 2.383e-02, -2.258e-02, 2.521e-02, 6.614e-02, 1.460e-01, -1.587e-01, 7.838e-02, -1.184e-04, -4.502e-02, 4.145e-04, 1.833e-02, -5.849e-02, -2.718e-02, -1.321e-02, 1.912e-02) * s[2][0][1];
	r0 += M4(9.057e-02, 4.584e-02, -1.475e-01, -1.640e-02, -4.485e-02, -1.221e-01, -4.343e-02, -1.311e-01, -7.680e-02, -6.084e-02, 2.861e-02, 1.053e-02, -4.100e-02, -9.312e-02, 8.563e-02, 1.110e-03) * s[2][1][0];
	r0 += M4(-2.619e-02, -5.506e-02, -9.367e-03, -5.376e-02, -2.657e-02, -7.544e-02, -1.527e-01, -1.372e-01, 6.911e-03, -5.947e-03, -5.822e-02, -1.355e-01, -2.964e-02, -4.419e-02, 3.621e-02, -7.695e-03) * s[2][1][1];
	r0 += M4(-1.847e-02, 3.505e-02, 3.887e-02, 4.399e-02, 3.393e-02, 2.182e-02, 2.166e-02, 5.904e-03, 5.042e-02, 4.247e-02, 7.349e-02, 4.619e-02, 5.969e-02, 2.901e-02, 4.254e-02, -1.660e-03) * s[2][2][0];
	r0 += M4(2.423e-02, 1.361e-02, 2.480e-02, 4.191e-04, 3.852e-02, 3.700e-02, 5.357e-02, -5.148e-03, 4.704e-02, 7.967e-02, 9.687e-02, 1.546e-02, 3.699e-02, 2.949e-02, 3.834e-02, 2.470e-02) * s[2][2][1];
	r0 += V4(-1.308e-03, -1.229e-03, -1.271e-03, -1.248e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

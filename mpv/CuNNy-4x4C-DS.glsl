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

//!DESC CuNNy-4x4C-DS-EASU
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) F(texelFetch(LUMA_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0).r)
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
	r0 += V4(-6.046e-02, -8.122e-02, -2.179e-02, 4.692e-02) * s[0][0][0];
	r0 += V4(5.128e-01, -1.209e-01, -2.524e-02, -1.733e-01) * s[0][1][0];
	r0 += V4(3.760e-01, 1.633e-01, -1.320e-02, -1.363e-01) * s[0][2][0];
	r0 += V4(3.071e-02, 6.620e-01, 2.685e-02, -1.735e-01) * s[1][0][0];
	r0 += V4(-7.464e-02, -4.448e-01, 5.092e-01, 6.778e-01) * s[1][1][0];
	r0 += V4(-8.163e-01, -2.200e-01, 1.826e-02, -1.844e-01) * s[1][2][0];
	r0 += V4(2.811e-02, -1.851e-01, -4.537e-02, -1.240e-01) * s[2][0][0];
	r0 += V4(-7.903e-02, 2.493e-01, 2.512e-01, -1.041e-01) * s[2][1][0];
	r0 += V4(8.444e-02, 3.853e-03, -4.100e-02, 1.719e-02) * s[2][2][0];
	r0 += V4(2.765e-03, -2.340e-02, -1.450e-02, 1.359e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(in_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(9.615e-04, 1.909e-02, -4.645e-02, -2.783e-01, -2.255e-02, -1.087e-01, 1.576e-01, -1.675e-01, 5.817e-02, -1.204e-01, -3.688e-02, 2.214e-02, -1.714e-01, -3.650e-01, 8.742e-02, -4.971e-01) * s[0][0][0];
	r0 += M4(-1.273e-02, -1.027e-01, 2.802e-02, -1.509e-01, -6.935e-02, -1.970e-01, 1.536e-02, -1.243e-01, -8.723e-01, -2.688e+00, 1.224e-01, 1.465e+00, -1.272e-01, -4.952e-01, -4.400e-02, -2.476e-01) * s[0][0][1];
	r0 += M4(6.518e-02, 4.680e-02, 9.003e-02, -2.086e-02, 5.215e-02, 2.484e-01, -1.744e-01, 7.983e-02, 1.742e-01, 4.576e-02, 8.949e-02, 3.137e-01, -2.065e-01, 2.033e-02, 4.951e-01, -4.225e-01) * s[0][1][0];
	r0 += M4(-3.603e-02, 9.768e-02, 1.412e-01, -5.846e-02, 2.547e-02, 2.983e-01, 4.911e-02, -7.446e-02, -7.812e-01, 8.790e-02, 1.467e+00, 7.214e+00, -2.737e-01, -1.482e-01, 1.621e-01, -2.257e-02) * s[0][1][1];
	r0 += M4(-5.117e-02, -3.018e-02, -3.343e-02, 4.277e-02, 1.669e-01, 1.540e-01, -1.191e-01, 3.303e-01, 2.806e-01, 2.393e-01, -6.654e-02, -8.040e-02, -8.371e-02, 2.185e-01, 3.253e-02, -1.764e-01) * s[0][2][0];
	r0 += M4(-4.799e-02, -5.480e-02, -1.450e-02, -1.971e-03, 1.454e-01, 2.881e-01, -7.096e-02, 1.105e-01, -1.784e+00, 2.548e-01, 5.178e+00, 1.357e+00, 1.398e-02, 1.860e-01, 7.579e-02, 1.554e-01) * s[0][2][1];
	r0 += M4(-6.000e-02, -4.769e-01, -3.769e-01, 1.720e-03, 1.336e-01, -1.132e-01, 3.994e-01, -2.939e-01, 9.985e-02, -4.286e-01, -9.755e-02, 8.533e-02, -1.348e-02, -6.487e-01, -9.897e-02, -7.998e-02) * s[1][0][0];
	r0 += M4(-1.052e-01, -1.426e-01, 2.583e-01, -3.252e-01, -8.194e-03, -3.579e-01, 2.346e-01, -2.239e-01, -5.582e-01, -2.481e+00, 9.478e-01, 2.176e+00, -1.358e-02, -6.581e-01, 2.784e-02, -5.285e-02) * s[1][0][1];
	r0 += M4(2.227e-01, -8.945e-02, -4.226e-01, -4.006e-02, -7.685e-02, -8.703e-02, -9.330e-01, 1.576e-01, 1.354e-01, 7.507e-03, -3.666e-02, 5.324e-02, 4.327e-01, 8.587e-01, 6.816e-01, -3.554e-01) * s[1][1][0];
	r0 += M4(-4.045e-02, -9.626e-03, -5.534e-02, -3.729e-01, -2.368e-01, 1.211e-01, -2.095e-01, -5.282e-03, -2.770e+00, 1.423e+00, 3.231e+00, 5.596e+00, 2.269e-01, 7.979e-01, -7.548e-02, 2.026e-01) * s[1][1][1];
	r0 += M4(-3.481e-02, 3.916e-02, 6.813e-02, 2.806e-02, 9.151e-02, -1.033e-01, -9.066e-02, 5.266e-01, 4.123e-02, 8.591e-02, 1.174e-01, 5.368e-02, 1.106e-01, -2.979e-01, -3.665e-01, -1.944e-01) * s[1][2][0];
	r0 += M4(-3.022e-02, -2.419e-04, 1.210e-01, 8.187e-02, -5.224e-02, 9.941e-02, 1.752e-01, 4.817e-02, -5.579e-01, -9.389e-03, 7.252e+00, 1.697e+00, 1.231e-01, -2.280e-01, 8.124e-02, 1.318e-01) * s[1][2][1];
	r0 += M4(6.177e-02, -2.585e-01, 6.966e-02, 1.291e-01, 5.212e-02, -4.033e-02, 1.762e-01, -9.440e-02, 4.836e-02, -7.465e-02, 2.036e-01, 1.099e-02, -7.691e-02, 9.346e-02, 3.857e-01, -1.394e-01) * s[2][0][0];
	r0 += M4(2.595e-02, -2.677e-01, 5.941e-01, -7.984e-02, -3.210e-02, -2.075e-01, 1.790e-02, -2.282e-02, -5.076e-01, -1.065e-01, 3.598e-01, -2.224e-01, 4.683e-03, 4.268e-02, 2.666e-01, 6.034e-02) * s[2][0][1];
	r0 += M4(8.735e-03, 1.373e-01, -1.373e-03, 7.669e-02, -7.410e-02, 4.565e-02, 4.457e-02, -2.008e-01, 5.369e-02, 8.479e-02, -6.360e-03, -1.068e-01, 1.546e-01, -1.154e-01, -5.480e-01, -1.028e-01) * s[2][1][0];
	r0 += M4(-2.159e-01, 2.281e-01, 1.778e-01, 2.444e-01, -1.946e-02, -2.222e-01, 1.608e-01, -1.978e-01, -6.725e-01, 1.168e+00, -3.649e-01, 4.102e-01, 7.792e-02, -1.401e-01, -5.489e-01, 9.221e-02) * s[2][1][1];
	r0 += M4(2.646e-02, 2.142e-02, -1.513e-02, -2.515e-02, -5.932e-02, 7.446e-02, -3.662e-01, 1.320e-01, 5.062e-04, 3.996e-02, -2.759e-02, -9.747e-02, -7.553e-02, -6.400e-02, 2.783e-01, -1.589e-02) * s[2][2][0];
	r0 += M4(7.301e-02, 4.387e-02, 2.071e-01, -9.074e-02, -6.412e-02, -7.541e-02, -3.220e-01, 2.245e-01, -4.543e-01, -1.982e-01, 1.361e+00, -8.185e-01, -2.653e-02, -3.331e-02, 1.401e-01, 1.236e-01) * s[2][2][1];
	r0 += V4(-5.649e-01, -1.487e-02, -6.948e-02, -4.317e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv1_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(8.542e-01, -1.794e-01, 6.571e-02, -7.421e-01, -3.083e-02, -1.603e-01, 7.610e-02, 1.506e-01, -1.592e-01, 1.143e-01, -1.153e-01, -5.189e-02, -3.607e-02, -2.528e-02, -2.601e-02, 9.200e-02) * s[0][0][0];
	r0 += M4(3.096e-01, 1.235e-01, -5.200e-02, 8.805e-02, 2.476e-02, -7.505e-02, 9.212e-03, 1.359e-01, -5.598e-02, -1.933e-02, -7.584e-02, 5.240e-02, 3.994e-02, 1.271e-01, -1.274e-01, 5.195e-02) * s[0][0][1];
	r0 += M4(1.243e+00, 3.403e-01, -2.025e-01, -8.766e-01, 2.377e-01, 1.183e-01, -1.990e-01, 1.224e-01, 4.331e-01, -2.867e-01, -2.349e-01, 3.904e-01, 9.172e-02, -2.139e-02, -4.668e-02, -1.067e-01) * s[0][1][0];
	r0 += M4(-2.603e-01, 3.313e-02, 1.893e-01, -7.076e-02, 3.076e-01, 3.111e-01, -8.572e-02, -8.369e-02, -7.923e-02, -1.565e-01, -1.865e-01, 4.200e-03, 5.549e-01, 6.327e-02, 5.773e-02, -1.000e-01) * s[0][1][1];
	r0 += M4(9.392e-02, -4.084e-02, -2.058e-02, -6.391e-02, 2.849e-01, 1.033e-01, 1.111e-01, 8.686e-02, -2.560e-01, 9.855e-02, 3.401e-01, -2.311e-01, -1.214e-01, 2.563e-02, 4.959e-02, 9.527e-02) * s[0][2][0];
	r0 += M4(-1.450e-01, -6.901e-02, 1.415e-02, 4.080e-02, 2.288e-01, 1.087e-01, 1.452e-01, -2.535e-02, -1.548e-02, -9.026e-02, -2.286e-02, -3.462e-02, 1.610e-01, -1.230e-02, -7.644e-03, 3.978e-02) * s[0][2][1];
	r0 += M4(1.533e+00, 4.690e-01, 4.191e-01, -1.350e+00, -4.044e-02, -1.049e-02, -8.263e-03, -2.259e-02, -2.763e-01, 4.603e-01, -3.498e-02, -3.662e-01, -1.458e-01, 3.813e-01, -2.930e-01, -4.581e-01) * s[1][0][0];
	r0 += M4(-1.604e-01, -4.417e-01, 1.937e-02, 2.990e-01, -6.689e-02, -1.627e-01, 2.563e-02, 5.633e-02, -1.510e-01, 4.372e-01, -2.567e-01, -3.976e-01, -1.671e-01, -5.859e-02, -2.405e-01, -3.910e-01) * s[1][0][1];
	r0 += M4(1.870e+00, -6.730e-01, -7.719e-01, -2.134e+00, 3.019e-02, -6.705e-01, -3.069e-01, -3.298e-01, 1.448e-01, 5.802e-01, 6.529e-01, -5.225e-01, 2.292e-01, -2.160e-01, 4.505e-01, -2.830e-01) * s[1][1][0];
	r0 += M4(4.547e-02, -4.830e-03, -1.260e-02, -3.547e-01, 1.637e-01, -6.607e-02, -3.488e-01, -4.335e-01, -6.907e-02, 3.704e-01, 2.617e-01, -3.969e-01, 8.574e-01, -4.395e-01, 5.014e-01, 5.861e-02) * s[1][1][1];
	r0 += M4(1.548e+00, 7.101e-01, -2.667e-01, -1.598e-01, 2.154e-01, -4.499e-02, -3.462e-01, 4.655e-01, 2.502e-01, -3.205e-02, 2.024e-02, -1.142e-01, -1.431e-01, 4.771e-02, -1.981e-01, 6.271e-02) * s[1][2][0];
	r0 += M4(1.955e-01, 7.713e-02, 1.829e-01, 3.059e-02, -4.387e-01, -2.171e-01, 1.023e-01, 1.856e-01, -2.635e-03, -1.584e-02, -2.036e-02, -1.190e-01, 1.928e-01, -2.167e-02, -4.223e-02, 8.642e-02) * s[1][2][1];
	r0 += M4(1.908e-02, 6.202e-01, 1.550e-01, 2.175e-02, -5.243e-02, 2.496e-01, 7.802e-03, -1.353e-01, 1.780e-02, 2.009e-01, 3.114e-01, 4.386e-02, -1.431e-01, 3.419e-01, 2.397e-01, 8.276e-02) * s[2][0][0];
	r0 += M4(1.199e-02, -1.418e-01, 2.551e-01, -1.152e-02, -8.960e-02, 3.992e-01, -5.603e-02, -1.614e-01, -3.748e-02, 2.026e-01, 1.194e-01, 2.855e-02, -1.160e-01, 1.751e-01, 2.494e-01, -1.177e-02) * s[2][0][1];
	r0 += M4(1.658e-01, 5.673e-01, -2.535e-01, -2.326e-01, -1.470e-01, 1.695e-01, 4.953e-01, 1.019e-01, -1.206e-01, 2.545e-01, 2.796e-01, 1.471e-01, -2.226e-01, -1.129e-02, 2.147e-01, -9.771e-04) * s[2][1][0];
	r0 += M4(-4.259e-02, 1.743e-01, -2.814e-01, 1.276e-01, -2.335e-01, 2.693e-01, 6.240e-01, -8.520e-02, -1.102e-01, 1.150e-01, 2.144e-01, 1.359e-01, -5.165e-02, -3.199e-01, -2.620e-01, -6.052e-02) * s[2][1][1];
	r0 += M4(-1.570e-02, 3.865e-01, -4.254e-01, 1.954e-01, 8.014e-02, -1.694e-01, -2.101e-01, 9.643e-02, -1.788e-02, -5.551e-02, -1.326e-01, 1.276e-02, -5.703e-02, -4.782e-02, 4.171e-02, -3.894e-02) * s[2][2][0];
	r0 += M4(4.064e-02, 1.280e-01, -3.876e-01, -4.731e-02, -1.461e-01, -2.462e-01, 5.380e-01, -4.310e-02, -4.701e-02, -9.463e-02, 1.161e-01, 6.241e-02, 1.037e-01, -1.234e-03, -2.354e-01, -1.511e-01) * s[2][2][1];
	r0 += V4(-4.018e-02, 3.142e-02, 1.563e-02, -7.807e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(-6.157e-02, 1.482e-01, -1.146e-01, 1.665e-01, 2.262e-01, -4.566e-02, 8.639e-02, -8.016e-02, 7.306e-02, -1.558e-01, -1.573e-02, 8.258e-02, 1.647e-01, -5.670e-02, 6.959e-02, -8.472e-02) * s[0][0][0];
	r0 += M4(-8.382e-03, -1.676e-02, -4.334e-02, 2.436e-02, 5.847e-02, 4.822e-02, 9.254e-02, -1.208e-01, -2.556e-02, -5.700e-02, 3.593e-02, -8.847e-02, 8.129e-02, 2.113e-02, -1.240e-01, 2.352e-01) * s[0][0][1];
	r0 += M4(2.193e-01, 1.060e-01, -8.006e-02, 1.657e-02, 1.826e-02, -5.979e-02, -3.037e-01, 4.676e-01, 2.112e-01, -4.276e-01, 3.731e-02, 2.541e-01, -1.437e-01, 1.602e-01, -9.349e-02, -1.588e-01) * s[0][1][0];
	r0 += M4(5.579e-02, -1.013e-01, -6.672e-03, -8.039e-03, 4.246e-03, 1.489e-01, 3.731e-02, 3.484e-02, 4.553e-02, 1.136e-01, 3.428e-02, -2.620e-02, 1.133e-02, 1.568e-01, -3.311e-01, 1.609e-01) * s[0][1][1];
	r0 += M4(-6.609e-02, 1.147e-01, -1.186e-02, 2.011e-02, 3.001e-01, -1.547e-01, -3.034e-01, 1.357e-01, 9.114e-02, -2.893e-01, -9.704e-02, -2.194e-02, 7.299e-02, 1.512e-01, -5.285e-02, -8.374e-02) * s[0][2][0];
	r0 += M4(-2.252e-02, -4.723e-02, -5.946e-03, 4.777e-02, 1.403e-01, -3.554e-02, -4.806e-02, 1.623e-02, -5.103e-03, -9.539e-02, 3.298e-02, -1.017e-01, 2.153e-01, 7.334e-02, -1.915e-01, 1.345e-01) * s[0][2][1];
	r0 += M4(3.548e-01, -2.018e-01, 1.866e-01, -3.408e-01, -2.266e-02, 1.822e-02, -5.248e-02, 1.144e-01, 2.272e-01, -1.733e-01, -4.372e-02, 1.496e-01, 4.382e-02, 9.256e-02, 1.655e-02, -5.877e-02) * s[1][0][0];
	r0 += M4(7.694e-02, 3.313e-03, -1.383e-02, -3.155e-01, -3.533e-02, 3.668e-02, -1.911e-02, 8.090e-02, -8.502e-02, -6.375e-02, 5.744e-02, 8.868e-02, -5.520e-02, -1.072e-01, -1.434e-01, 2.280e-01) * s[1][0][1];
	r0 += M4(-9.979e-02, -2.052e-02, 1.523e-01, -2.686e-01, 2.010e-01, -1.571e-01, -1.553e-01, 2.072e-01, 2.407e-01, 3.747e-02, -3.740e-01, 1.636e-01, 2.173e-02, 2.417e-02, 4.829e-01, 3.299e-01) * s[1][1][0];
	r0 += M4(-1.053e-01, 9.938e-02, -1.194e-01, -2.122e-01, 7.146e-02, -3.816e-02, 1.014e-01, 9.235e-02, 1.843e-01, 1.358e-01, -5.602e-02, 1.995e-02, 6.470e-02, -4.156e-01, 5.940e-01, 2.627e-01) * s[1][1][1];
	r0 += M4(1.856e-01, -1.778e-01, 4.686e-02, -1.184e-01, 1.422e-01, -2.690e-01, -8.624e-02, -2.453e-01, 5.384e-02, -1.870e-01, -7.726e-02, 2.207e-03, 1.241e-01, -1.542e-01, 1.168e-01, -2.945e-01) * s[1][2][0];
	r0 += M4(-2.628e-02, 7.928e-02, -9.006e-02, 2.920e-02, -1.664e-01, -2.035e-01, 1.156e-01, -1.885e-01, 5.493e-02, -1.611e-01, 1.632e-01, -2.138e-01, 9.023e-02, -4.980e-01, 1.906e-01, -1.382e-02) * s[1][2][1];
	r0 += M4(-4.012e-03, -6.042e-02, 1.031e-01, -4.188e-02, 5.689e-02, -2.997e-02, 5.019e-02, -4.886e-02, 6.079e-02, -3.116e-02, -6.115e-04, -1.510e-02, -1.999e-01, 1.310e-01, -1.062e-02, 5.785e-03) * s[2][0][0];
	r0 += M4(-1.616e-01, 8.478e-02, -1.433e-02, -1.198e-01, 2.565e-02, 2.106e-02, -4.261e-02, -4.790e-02, 1.125e-02, 3.691e-02, -2.976e-02, 2.924e-02, -2.446e-01, 1.380e-01, -1.802e-01, 2.725e-01) * s[2][0][1];
	r0 += M4(1.011e-01, 2.300e-01, -2.446e-01, -1.696e-02, 4.332e-02, -6.132e-02, -8.132e-02, 6.250e-03, 5.328e-02, -1.061e-01, 5.046e-02, -1.076e-01, 2.781e-01, -1.274e-01, 2.038e-01, -2.105e-01) * s[2][1][0];
	r0 += M4(-5.748e-02, 2.302e-01, -1.219e-01, -1.962e-01, -1.469e-03, -7.401e-03, 1.431e-01, -2.923e-01, 1.908e-02, -5.018e-02, 5.813e-02, -7.880e-02, 8.598e-02, -1.889e-01, 2.109e-01, 3.477e-03) * s[2][1][1];
	r0 += M4(9.737e-02, -1.353e-01, 9.365e-02, -4.643e-02, -6.516e-03, 5.332e-02, -1.565e-01, 9.532e-02, -1.548e-02, -1.610e-02, -4.677e-02, -4.879e-02, 2.799e-02, -5.107e-02, 4.810e-02, -9.515e-02) * s[2][2][0];
	r0 += M4(3.846e-02, 1.130e-01, 4.186e-03, -7.913e-03, -1.918e-02, 5.375e-02, -2.351e-02, -9.595e-02, 5.144e-03, 3.963e-02, -3.367e-03, -5.534e-02, 5.718e-03, -2.763e-01, 1.096e-01, -3.776e-02) * s[2][2][1];
	r0 += V4(-6.691e-03, 2.719e-02, 1.360e-02, -1.208e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(3.417e-02, 7.548e-02, -7.319e-03, 1.996e-02, -3.506e-02, 8.824e-02, -2.742e-02, -8.361e-03, 3.319e-02, -1.023e-01, 6.485e-03, 4.410e-02, 2.496e-02, -1.315e-02, 3.991e-02, -3.168e-02) * s[0][0][0];
	r0 += M4(-7.506e-02, -2.205e-02, 9.105e-02, 7.581e-02, 7.694e-02, 5.315e-02, 2.559e-02, -2.615e-02, -1.260e-02, 7.320e-02, -5.310e-02, -6.863e-02, -8.720e-03, 3.198e-02, 5.336e-03, -2.526e-03) * s[0][0][1];
	r0 += M4(8.785e-02, 1.230e-01, -7.702e-02, 4.327e-02, 4.390e-02, 2.378e-02, -9.723e-02, 1.024e-01, -2.869e-01, -1.214e-01, 2.501e-02, -9.436e-02, -4.660e-02, 3.915e-03, 4.901e-02, -8.912e-02) * s[0][1][0];
	r0 += M4(-5.839e-02, 9.156e-02, -1.499e-01, 1.829e-02, -1.183e-01, -4.449e-02, -3.968e-02, 5.435e-02, -2.679e-01, 3.376e-02, -3.409e-02, -1.897e-02, 2.003e-01, -9.698e-02, -7.824e-02, 8.156e-02) * s[0][1][1];
	r0 += M4(6.521e-02, 7.351e-02, -2.537e-02, 2.762e-02, 6.066e-02, 1.127e-01, 7.239e-02, -1.540e-02, 6.537e-02, 3.871e-02, -1.155e-02, -4.295e-03, -1.740e-02, -5.919e-03, 6.244e-02, -6.244e-02) * s[0][2][0];
	r0 += M4(4.955e-01, 3.839e-02, 4.867e-02, 8.646e-03, 5.186e-02, -1.412e-02, -1.425e-02, -2.938e-03, 1.437e-01, 1.363e-01, 5.734e-02, -5.723e-02, 9.172e-02, 2.863e-02, -2.572e-02, 1.384e-02) * s[0][2][1];
	r0 += M4(-1.622e-06, -2.434e-02, 1.656e-01, -1.061e-02, -2.874e-02, -2.590e-02, 1.685e-01, 1.053e-01, 2.781e-02, -1.626e-02, -1.479e-01, -8.968e-02, 6.189e-02, 3.192e-02, -1.066e-02, -2.316e-02) * s[1][0][0];
	r0 += M4(2.119e-01, -2.130e-01, -1.503e-01, 2.465e-01, 4.438e-02, 7.506e-02, 6.325e-02, 1.785e-02, -4.073e-02, -1.070e-01, -3.389e-01, 5.027e-02, -5.247e-03, -9.834e-02, 1.205e-01, 2.427e-02) * s[1][0][1];
	r0 += M4(-1.525e-01, -2.842e-01, -2.992e-02, -3.412e-02, 1.596e-03, -1.927e-01, -2.568e-01, -5.416e-02, -3.213e-01, 1.555e-01, -2.728e-01, 5.697e-01, -2.659e-02, 1.440e-01, 3.377e-02, -1.073e-01) * s[1][1][0];
	r0 += M4(-4.513e-01, -2.883e-01, -2.377e-01, 2.934e-01, 9.764e-03, -1.805e-01, -1.285e-01, 1.523e-01, -4.384e-01, -1.343e-01, -5.372e-01, -3.969e-02, 4.492e-02, 4.832e-01, 7.816e-02, -3.034e-01) * s[1][1][1];
	r0 += M4(6.999e-02, -1.043e-01, 6.357e-02, -1.423e-01, -5.348e-02, -4.236e-02, 1.233e-01, 5.902e-04, -9.746e-02, -1.123e-01, 4.013e-02, -3.043e-02, 4.076e-02, 8.283e-02, 4.143e-02, -1.853e-02) * s[1][2][0];
	r0 += M4(6.113e-01, 6.190e-01, 1.064e-01, -1.341e+00, -1.192e-01, -1.129e-01, 1.140e-02, 2.101e-03, -9.639e-02, -8.869e-02, 1.269e-01, -2.086e-02, 4.133e-02, 4.601e-02, 1.116e-01, -1.112e-01) * s[1][2][1];
	r0 += M4(2.869e-03, 4.847e-03, -1.511e-02, 3.270e-02, 3.405e-02, 1.353e-01, 1.176e-02, -4.162e-02, -3.358e-02, -3.922e-02, 8.423e-02, 1.775e-02, -2.460e-02, -2.880e-03, -4.515e-02, 2.952e-02) * s[2][0][0];
	r0 += M4(9.075e-02, 2.901e-01, -1.545e-01, -2.341e-01, -4.994e-02, -8.077e-02, 6.523e-02, 7.467e-02, 4.627e-02, 1.010e-01, 9.458e-02, -8.741e-02, -9.640e-02, -4.651e-02, 3.681e-02, 4.164e-02) * s[2][0][1];
	r0 += M4(1.077e-01, 1.046e-01, 5.139e-02, -4.355e-02, 1.563e-01, 1.255e-01, -8.035e-02, -3.577e-02, 6.091e-02, -7.288e-03, -8.209e-02, -1.254e-01, 1.652e-01, 2.044e-01, 5.049e-02, -1.411e-01) * s[2][1][0];
	r0 += M4(4.536e-01, 5.018e-01, 7.069e-01, 2.182e-01, -8.044e-03, -8.862e-02, -7.215e-02, 1.979e-02, 3.056e-01, 3.135e-01, -4.457e-02, -2.413e-01, 3.113e-01, 2.510e-01, 2.514e-02, -2.497e-01) * s[2][1][1];
	r0 += M4(4.272e-02, 1.009e-01, 1.023e-02, 3.708e-03, 1.068e-01, 1.110e-01, 1.114e-01, -5.144e-02, 7.464e-03, -5.272e-03, 2.101e-03, 1.268e-02, 3.181e-02, 6.994e-02, -1.391e-02, -1.551e-02) * s[2][2][0];
	r0 += M4(-9.165e-02, 2.666e-01, -1.464e-01, 1.912e-01, -4.856e-02, -1.536e-02, -1.259e-02, 1.209e-01, 1.405e-01, 1.367e-01, 1.213e-01, -6.189e-02, 1.095e-01, 8.917e-02, 8.229e-02, -7.746e-02) * s[2][2][1];
	r0 += V4(5.819e-03, 3.983e-03, 5.893e-03, -7.401e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-4x4C-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv4
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
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(-2.228e-02, -1.520e-02, -6.746e-03, -1.329e-02, -8.402e-02, -2.989e-03, -2.583e-02, 2.800e-02, -2.487e-02, -2.433e-03, -2.377e-02, -2.095e-02, 1.860e-01, 8.136e-02, 1.083e-01, 2.738e-02) * s[0][0][0];
	r0 += M4(-9.520e-02, 5.549e-03, 6.071e-02, 2.858e-02, -3.228e-02, -7.202e-03, 4.298e-02, 2.044e-02, -2.563e-01, 1.538e-01, 3.986e-03, 1.274e-01, -8.224e-02, 1.603e-02, 4.796e-03, 3.179e-02) * s[0][0][1];
	r0 += M4(4.700e-02, 4.743e-02, -2.108e-02, -1.227e-02, 7.717e-02, -3.135e-02, 5.352e-02, 8.562e-03, -6.431e-02, -7.748e-02, 6.665e-02, 3.479e-02, 1.929e-01, -4.522e-02, 1.119e-01, 1.742e-01) * s[0][1][0];
	r0 += M4(-2.163e-01, -1.951e-01, 2.970e-02, 9.121e-02, -1.474e-02, -2.900e-01, 8.088e-02, 3.011e-03, 7.109e-01, -3.332e-01, -8.153e-04, -1.782e-01, -1.181e-01, -1.440e-01, -5.844e-03, 8.581e-05) * s[0][1][1];
	r0 += M4(-9.607e-03, -3.329e-02, -3.224e-02, -5.810e-02, 5.623e-03, 2.487e-02, 4.838e-02, 4.578e-02, -2.600e-02, -1.488e-02, -6.995e-03, 5.139e-02, -3.357e-02, 1.145e-01, 8.392e-03, 2.399e-02) * s[0][2][0];
	r0 += M4(9.449e-02, 2.679e-02, -1.676e-03, 2.181e-03, -5.213e-02, 1.415e-01, -6.288e-04, 7.346e-02, -1.952e-01, 9.760e-02, 1.251e-02, -3.189e-02, 7.702e-02, 1.651e-03, 3.991e-02, 1.957e-02) * s[0][2][1];
	r0 += M4(1.499e-01, 9.576e-02, 1.350e-03, 4.997e-03, 5.313e-02, 6.907e-02, -1.533e-03, 3.918e-02, -4.254e-02, 5.267e-03, 1.596e-02, 4.209e-02, 2.979e-01, 8.004e-02, -3.782e-02, 6.131e-02) * s[1][0][0];
	r0 += M4(5.845e-01, -1.741e-02, 4.355e-02, -7.955e-02, 3.466e-01, 5.300e-02, -8.340e-02, -8.231e-02, -1.578e-01, 1.333e-01, -3.096e-01, 1.585e-01, 2.378e-02, 6.421e-02, -6.966e-02, 2.717e-02) * s[1][0][1];
	r0 += M4(7.883e-02, 9.116e-02, -5.962e-05, -1.636e-02, -4.014e-01, -2.067e-01, -1.861e-01, -1.102e-01, 2.701e-02, -5.262e-02, -7.565e-02, -8.153e-02, 4.425e-01, 3.080e-01, 5.303e-02, -6.148e-01) * s[1][1][0];
	r0 += M4(4.894e-01, 1.387e+00, -1.333e-01, 2.883e-01, -3.974e-01, -1.443e-01, -6.663e-01, -7.477e-01, 2.321e-01, -5.178e-01, 1.325e+00, -2.571e-01, 9.296e-02, -6.667e-03, -7.714e-02, -1.609e-01) * s[1][1][1];
	r0 += M4(4.140e-03, 6.095e-02, 3.106e-02, 4.880e-02, 1.319e-01, -7.776e-02, 8.816e-02, -1.605e-02, 2.167e-02, 6.675e-03, 2.092e-02, -5.447e-02, -7.495e-02, 1.519e-01, -3.823e-02, 2.066e-01) * s[1][2][0];
	r0 += M4(1.028e-02, -1.294e-01, 1.297e-01, -5.303e-02, 1.460e-01, 9.144e-02, 7.227e-03, 2.871e-02, -1.434e-01, -3.748e-02, -1.943e-01, 3.256e-01, -2.665e-02, -3.907e-03, 8.130e-02, 2.489e-02) * s[1][2][1];
	r0 += M4(-2.070e-02, -3.480e-02, 9.307e-02, 4.184e-02, -2.473e-02, 2.405e-02, -1.025e-02, 4.334e-02, -4.099e-03, -2.300e-02, -4.976e-02, -4.177e-02, -4.992e-02, 1.568e-02, 1.180e-01, -6.091e-03) * s[2][0][0];
	r0 += M4(-1.399e-01, 2.255e-02, 8.225e-02, -6.170e-03, -1.107e-01, -5.842e-03, 9.697e-02, 9.902e-03, 1.405e-02, 4.924e-03, 2.500e-02, 5.773e-02, 1.576e-02, 1.830e-02, 3.908e-02, 5.089e-02) * s[2][0][1];
	r0 += M4(-2.358e-01, -7.385e-02, -3.932e-02, 7.733e-02, 1.646e-01, 5.238e-02, -1.999e-02, -7.124e-02, 8.859e-02, 7.251e-02, 3.028e-02, 4.760e-03, -1.983e-01, -5.496e-02, 5.320e-02, 3.037e-01) * s[2][1][0];
	r0 += M4(-3.077e-01, -2.121e-01, -4.800e-02, 3.928e-01, 1.304e-01, -3.799e-02, 1.106e-01, 9.058e-02, 1.340e-01, 1.227e-01, -1.606e-01, -1.925e-01, -1.318e-01, -1.090e-02, -5.925e-02, 6.513e-03) * s[2][1][1];
	r0 += M4(2.851e-02, -7.690e-02, 2.607e-02, 4.178e-03, -4.065e-02, 3.009e-02, 1.616e-02, 1.955e-03, 6.456e-03, 3.614e-02, -2.741e-02, -2.729e-03, 7.691e-02, -3.456e-02, -9.588e-03, -2.557e-03) * s[2][2][0];
	r0 += M4(9.204e-02, -4.092e-02, 9.920e-02, -6.531e-02, -7.007e-02, 1.063e-03, -2.708e-02, 6.786e-02, 3.895e-02, 1.215e-01, -5.481e-02, -3.673e-02, 3.059e-02, -4.333e-02, 1.560e-02, -1.677e-02) * s[2][2][1];
	r0 += V4(-5.853e-05, -6.768e-05, 2.982e-04, 2.983e-04);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

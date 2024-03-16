// CuNNy 4x4C
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

//!DESC CuNNy-4x4C-EASU
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


//!DESC CuNNy-4x4C-in
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
	r0 += V4(2.729e-02, 4.928e-01, 4.376e-03, -1.644e-03) * s[0][0][0];
	r0 += V4(2.359e-02, 8.422e-02, 7.275e-03, 1.297e-02) * s[0][1][0];
	r0 += V4(1.437e-01, -8.260e-04, 6.629e-03, 4.136e-04) * s[0][2][0];
	r0 += V4(5.336e-02, -6.613e-02, 2.646e-01, 2.833e-03) * s[1][0][0];
	r0 += V4(-7.095e-01, -6.027e-01, 3.037e-01, 3.351e-04) * s[1][1][0];
	r0 += V4(5.527e-01, 3.177e-02, -2.174e-02, 1.046e-02) * s[1][2][0];
	r0 += V4(-1.870e-02, -3.210e-02, -5.656e-01, 2.772e-02) * s[2][0][0];
	r0 += V4(4.065e-02, 4.550e-02, -4.968e-02, -8.042e-01) * s[2][1][0];
	r0 += V4(-9.490e-02, 3.330e-02, 4.758e-02, 2.707e-02) * s[2][2][0];
	r0 += V4(-1.690e-02, -1.363e-02, -3.552e-02, 1.181e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-4x4C-conv1
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
	r0 += M4(-6.746e-02, -2.481e-01, 2.993e-02, 3.407e-01, 2.380e-02, 2.458e-02, 6.515e-02, -8.130e-02, -1.376e-01, -5.212e-02, 2.260e-02, 7.154e-02, -5.230e-01, 7.580e-01, -3.427e+00, -2.142e-01) * s[0][0][0];
	r0 += M4(1.881e-01, -1.302e-02, -1.071e-01, -9.082e-02, 7.355e-03, 3.340e-02, -1.667e-02, -5.715e-03, -3.945e-02, -3.363e-02, 1.279e-01, 1.440e-01, 8.211e-02, -2.452e-01, -4.420e-02, 3.904e-02) * s[0][0][1];
	r0 += M4(-2.666e-01, 1.357e-01, -2.561e-02, 4.667e-01, -6.339e-04, 5.094e-02, -1.066e-01, -1.740e-02, 1.845e-02, 2.755e-01, 6.353e-01, 2.386e-02, 5.781e+00, 4.462e+00, -1.697e+00, -7.983e+00) * s[0][1][0];
	r0 += M4(1.691e-02, 1.606e-01, 1.053e-01, 2.004e-01, -3.414e-02, -5.208e-02, -1.018e-01, 2.470e-02, -1.760e-01, 3.880e-01, 5.053e-01, -2.673e-01, 5.534e-01, -1.702e-01, 4.656e-02, -3.284e-02) * s[0][1][1];
	r0 += M4(-1.711e-01, -1.471e-01, -1.112e-02, 2.709e-03, -9.299e-02, 2.832e-02, 2.209e-01, 1.654e-01, 3.523e-01, 3.495e-01, -3.799e-01, -2.807e-01, 2.764e+00, 1.836e+00, -2.018e+00, -1.482e+00) * s[0][2][0];
	r0 += M4(-2.665e-03, -3.960e-02, -1.305e-02, 2.767e-02, -6.703e-02, -2.419e-02, 3.918e-02, -2.545e-02, 1.966e-01, -1.995e-01, -2.763e-01, -1.077e+00, 2.468e-01, 2.588e-01, 1.031e-01, 2.764e-01) * s[0][2][1];
	r0 += M4(-2.811e-01, 2.814e-01, -1.113e-01, -5.237e-02, 1.717e-02, -1.696e-02, -4.286e-02, -1.372e-01, 9.302e-03, 6.708e-02, -1.013e-02, -5.724e-02, -5.019e-01, -8.057e-01, -1.703e+00, 1.664e+00) * s[1][0][0];
	r0 += M4(-4.367e-01, 2.370e-01, -1.444e-01, -1.343e-02, 1.367e-02, -5.096e-02, -1.948e-01, -9.742e-02, 1.361e-01, 8.712e-02, 8.459e-03, -7.981e-02, 8.527e-02, -3.213e-01, -1.635e-01, 7.173e-02) * s[1][0][1];
	r0 += M4(4.587e-01, -6.536e-01, -6.309e-01, -3.681e-01, 2.376e-01, -4.329e-01, -3.318e-02, 1.971e-01, -1.576e-01, 1.688e-01, 3.544e-01, 1.534e-01, 2.287e+00, 5.403e+00, -4.528e-01, 3.705e-01) * s[1][1][0];
	r0 += M4(7.175e-01, -6.416e-01, -1.035e+00, -1.156e+00, 2.390e-01, -5.608e-01, 6.776e-01, 3.935e-01, -4.902e-01, 2.354e-01, 1.515e-01, 2.361e-01, 1.003e-01, 4.233e-01, -8.600e-02, -3.531e-03) * s[1][1][1];
	r0 += M4(-4.238e-02, 8.619e-02, 1.186e-01, 1.831e-01, 2.027e-01, 4.688e-02, -5.634e-02, -2.122e-01, 1.433e-01, -8.153e-02, 3.578e-01, 5.915e-02, -4.785e-01, 2.147e+00, 4.243e-01, -3.229e-01) * s[1][2][0];
	r0 += M4(-1.875e-02, -1.032e-01, 1.097e-02, 5.672e-02, 5.899e-01, 6.323e-01, -2.102e-01, -5.525e-01, 2.841e-01, -3.324e-03, -1.567e-01, -1.167e-01, 1.652e-01, -1.343e-01, -9.224e-02, -1.739e-01) * s[1][2][1];
	r0 += M4(6.994e-03, 9.701e-02, 2.593e-01, -2.095e-01, -1.012e-01, 4.582e-02, 4.320e-02, 1.856e-01, -8.266e-03, 1.350e-02, 1.481e-02, -1.103e-02, 1.194e-01, -2.594e-01, 8.046e-01, -1.074e-01) * s[2][0][0];
	r0 += M4(-8.318e-02, 2.920e-01, 5.293e-01, 1.239e-02, -1.798e-01, 3.709e-02, 1.730e-01, 1.304e-01, 4.089e-02, -1.416e-02, -1.292e-01, -3.216e-02, 6.886e-03, -4.355e-02, 4.157e-02, -2.684e-01) * s[2][0][1];
	r0 += M4(-1.133e-01, 1.867e-01, 2.909e-01, 3.156e-01, -5.314e-03, -5.657e-03, 3.040e-01, -4.169e-01, -3.701e-02, 1.457e-01, 8.125e-02, 4.599e-01, -6.472e-01, -3.454e-02, -1.058e-01, 5.555e-02) * s[2][1][0];
	r0 += M4(-2.156e-01, -8.646e-02, 3.408e-01, 2.486e-01, 4.820e-01, 2.300e-01, 4.985e-01, -1.958e-01, -1.120e-01, 6.776e-02, 2.009e-01, 4.574e-01, 5.117e-02, 1.948e-01, 1.072e-01, 7.055e-02) * s[2][1][1];
	r0 += M4(9.366e-02, 3.524e-01, 4.022e-02, 4.389e-03, -6.276e-01, 8.414e-02, 4.904e-01, 3.653e-01, 1.060e-01, -1.886e-01, -2.240e-01, -2.378e-01, -5.891e-01, -9.834e-03, -5.593e-01, 2.050e-01) * s[2][2][0];
	r0 += M4(-3.334e-02, -1.447e-02, 2.692e-02, -1.683e-04, -5.526e-01, 7.759e-01, 2.021e-01, 4.517e-01, -3.585e-02, -5.645e-01, -2.126e-01, -1.987e-01, -6.068e-02, 8.048e-03, 2.910e-02, 4.114e-02) * s[2][2][1];
	r0 += V4(3.235e-01, 1.659e-03, 3.308e-02, -1.593e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-4x4C-conv2
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
	r0 += M4(3.236e-01, 1.251e-02, -3.292e-02, 2.009e-02, 2.364e-01, 3.726e-01, 8.417e-02, -3.454e-02, 6.116e-02, -2.582e-02, -2.295e-02, 5.640e-03, -2.666e-01, -1.101e-02, 1.259e-02, -1.821e-01) * s[0][0][0];
	r0 += M4(2.094e-01, 1.136e-01, -4.741e-02, -6.778e-02, 5.096e-02, -1.040e-02, 4.140e-02, 3.024e-02, 1.398e-01, 1.269e-01, 2.267e-02, 5.527e-02, 3.002e-01, 4.321e-02, -9.692e-02, 1.297e-01) * s[0][0][1];
	r0 += M4(5.108e-01, -4.677e-01, -6.348e-01, 1.401e-01, 4.910e-01, 7.446e-02, 3.316e-01, -3.236e-01, -2.527e-01, -3.430e-01, 1.483e-01, -7.360e-02, 2.880e-01, -2.521e-02, -1.450e-01, -9.428e-03) * s[0][1][0];
	r0 += M4(2.728e-01, -3.696e-01, -5.323e-01, -1.190e-02, 2.744e-01, -2.496e-01, 2.185e-01, -2.007e-01, -2.511e-01, -1.401e-01, 2.427e-01, -5.035e-02, 5.126e-01, 1.515e-01, 3.296e-01, 1.695e-01) * s[0][1][1];
	r0 += M4(-3.642e-01, 1.753e-01, -2.346e-01, 1.297e-01, 1.719e-01, 8.165e-02, 9.999e-02, -3.517e-02, -1.462e-01, -3.491e-02, 9.247e-02, 1.950e-01, -7.868e-02, 2.785e-02, -2.136e-01, 3.160e-02) * s[0][2][0];
	r0 += M4(-2.310e-01, 1.526e-01, -2.105e-01, 2.047e-01, 3.663e-02, -2.886e-01, 4.971e-02, -1.215e-01, -4.002e-01, 2.670e-01, 6.109e-03, 2.193e-01, 2.262e-01, -7.298e-02, -2.771e-01, 1.352e-01) * s[0][2][1];
	r0 += M4(1.626e-01, -8.740e-02, -3.533e-02, -1.464e-01, 4.125e-01, 4.419e-01, 1.109e-01, -2.417e-01, -6.092e-03, -2.192e-01, -5.310e-02, -1.606e-01, -4.128e-01, 8.442e-02, 1.422e-01, -1.933e-01) * s[1][0][0];
	r0 += M4(5.622e-02, -1.203e-01, -2.482e-02, -5.336e-02, 1.664e-01, -8.242e-02, 1.135e-01, -1.043e-01, -1.862e-01, 2.742e-03, -8.687e-02, -1.064e-01, 1.496e-01, -3.893e-02, 2.559e-02, 1.397e-01) * s[1][0][1];
	r0 += M4(2.764e-01, -2.231e-01, -1.866e-01, -5.926e-01, -5.587e-03, -3.974e-01, 8.167e-02, 1.892e-01, 5.430e-01, 2.489e-01, 9.491e-02, 1.667e-01, -3.518e-01, -9.188e-02, -1.346e-01, -1.335e-01) * s[1][1][0];
	r0 += M4(2.588e-01, 5.792e-02, -1.424e-01, -4.951e-01, -2.898e-01, -6.635e-01, 4.811e-02, 8.428e-02, 1.224e-01, 8.329e-01, 5.512e-02, 5.215e-01, -2.651e-01, -3.996e-01, 2.969e-03, 9.540e-01) * s[1][1][1];
	r0 += M4(-1.211e-01, 4.567e-01, -1.450e-01, 1.396e-02, 1.251e-01, -9.156e-02, 2.220e-02, 6.425e-02, 1.297e-02, 2.615e-01, -1.138e-02, 1.584e-01, -8.048e-02, -5.677e-02, -4.410e-02, -2.495e-01) * s[1][2][0];
	r0 += M4(-7.424e-02, 3.600e-01, -1.392e-01, -1.041e-02, -4.308e-02, -3.271e-01, 9.568e-03, -1.228e-01, 1.028e-01, 8.069e-01, 7.734e-02, 1.023e-01, -9.936e-02, -5.627e-01, -3.540e-02, -1.023e-01) * s[1][2][1];
	r0 += M4(-2.852e-01, -2.134e-01, -3.916e-02, -4.178e-02, 1.511e-01, 1.677e-01, -1.284e-02, -1.314e-01, -1.960e-02, -1.831e-01, 4.118e-03, 1.175e-01, -8.727e-02, -1.871e-01, 4.617e-02, -9.380e-02) * s[2][0][0];
	r0 += M4(-2.292e-01, -1.989e-01, -6.022e-02, 1.980e-02, 3.216e-02, -1.132e-01, -3.093e-02, -2.368e-01, -7.303e-02, 1.906e-01, 3.868e-02, 1.439e-01, 3.112e-02, -4.895e-01, -3.104e-02, -2.926e-01) * s[2][0][1];
	r0 += M4(-3.485e-01, 5.162e-02, -2.595e-02, 2.507e-01, 1.460e-01, -1.616e-01, 4.564e-02, -1.583e-01, -9.506e-02, -1.396e-01, -3.395e-02, -1.063e-02, -9.236e-02, -1.030e-01, 6.585e-02, -1.399e-01) * s[2][1][0];
	r0 += M4(-2.056e-01, -6.856e-02, -2.938e-03, 2.543e-01, 1.475e-02, -3.330e-01, 2.137e-02, -2.038e-01, 1.060e-01, 2.687e-01, 1.087e-02, 6.850e-02, -3.171e-01, -9.240e-01, 4.494e-02, -4.121e-02) * s[2][1][1];
	r0 += M4(-2.001e-02, 2.231e-01, -5.527e-02, 2.007e-01, 3.063e-02, 9.158e-02, 4.161e-03, 5.195e-02, -1.007e-01, -5.256e-02, -1.562e-02, -4.845e-02, 4.414e-03, 4.596e-02, 4.763e-03, 4.309e-02) * s[2][2][0];
	r0 += M4(-2.444e-02, 2.133e-01, -4.231e-02, 1.528e-01, -1.052e-01, -1.318e-02, 2.375e-03, -4.652e-02, 2.693e-01, 2.676e-01, -2.830e-02, 1.886e-01, -2.192e-01, -1.818e-01, -5.779e-03, 1.168e-01) * s[2][2][1];
	r0 += V4(1.379e-02, -5.701e-02, -6.700e-01, -1.748e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-4x4C-conv3
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
	r0 += M4(-9.903e-02, 3.886e-03, -1.444e-02, -1.184e-01, 1.401e-01, 6.125e-02, 3.650e-02, 1.176e-01, -8.955e-04, 2.537e-01, -5.778e-04, 1.281e-01, -1.994e-01, 3.223e-02, -2.097e-02, -4.475e-02) * s[0][0][0];
	r0 += M4(-1.362e-01, 1.228e-01, -5.545e-03, -6.254e-02, -9.458e-02, 1.695e-01, 8.172e-03, -6.763e-02, -1.087e-02, -2.296e-02, 2.390e-03, -1.255e-02, -3.332e-02, -1.567e-02, 4.641e-02, 9.916e-03) * s[0][0][1];
	r0 += M4(-3.741e-01, 7.245e-02, 1.436e-01, -1.998e-02, -2.923e-01, 1.704e-01, 1.663e-01, 8.300e-02, -3.059e-01, 3.071e-01, 2.208e-01, -2.007e-01, 5.708e-02, 3.074e-01, -1.984e-01, 7.851e-02) * s[0][1][0];
	r0 += M4(-1.042e-01, -1.256e-01, 8.980e-03, -3.764e-04, -3.180e-01, -3.635e-02, 1.679e-02, -7.670e-02, 5.235e-02, 2.213e-02, -4.570e-03, -1.400e-03, 7.438e-02, 1.275e-01, -1.528e-03, 2.238e-02) * s[0][1][1];
	r0 += M4(-2.346e-01, -7.312e-02, 4.126e-02, -7.379e-03, -6.495e-02, -1.851e-01, 5.567e-02, -2.823e-02, -2.694e-01, -1.970e-01, 3.380e-01, -1.726e-01, -2.988e-01, -1.344e-01, -7.445e-02, -1.591e-01) * s[0][2][0];
	r0 += M4(8.932e-02, 8.353e-03, -3.086e-02, -1.906e-02, -6.898e-03, -2.250e-02, -2.725e-02, -2.510e-02, -6.470e-02, 1.876e-02, 2.040e-03, 2.899e-02, -1.343e-01, 5.612e-03, -2.701e-03, 6.980e-02) * s[0][2][1];
	r0 += M4(7.449e-02, 1.304e-01, 6.096e-02, -9.413e-02, -2.170e-01, 2.899e-01, 5.513e-02, -5.795e-02, -5.014e-01, -7.951e-01, -9.515e-03, -6.904e-01, 1.084e-01, -1.674e-01, 2.349e-02, 8.515e-02) * s[1][0][0];
	r0 += M4(-6.654e-03, 1.346e-01, 2.605e-02, 1.654e-02, -1.801e-02, 8.668e-02, -5.493e-02, -1.666e-02, 7.931e-02, -9.253e-02, -8.853e-02, -1.687e-02, 4.399e-02, -1.411e-01, 4.892e-03, -2.522e-02) * s[1][0][1];
	r0 += M4(1.306e-01, -7.035e-01, -1.304e-02, 1.151e-01, -5.569e-01, 5.490e-03, 9.302e-02, -3.347e-01, 1.439e+00, 7.155e-01, -4.226e-01, 3.617e-01, 1.506e-02, 7.439e-01, 2.186e-01, 6.555e-01) * s[1][1][0];
	r0 += M4(-4.391e-01, -4.072e-01, -1.311e-01, -3.978e-01, -1.963e-01, 7.110e-03, -3.470e-02, -3.350e-01, -4.859e-02, -6.221e-02, 7.321e-02, 7.725e-02, 2.184e-01, 5.801e-01, 1.818e-01, 5.059e-01) * s[1][1][1];
	r0 += M4(5.293e-01, 5.201e-02, -1.528e-01, -8.108e-02, -2.763e-02, -1.405e-01, 3.929e-02, -1.426e-02, 5.744e-01, -1.307e-01, 7.798e-02, -3.636e-01, -4.237e-01, -1.860e-01, -1.732e-01, -1.645e-01) * s[1][2][0];
	r0 += M4(-7.182e-02, 9.570e-02, 8.763e-02, 1.909e-01, -1.003e-01, 2.673e-02, 9.310e-02, 8.010e-02, 1.704e-01, -7.026e-03, -2.240e-02, -1.371e-01, -1.789e-01, -1.308e-01, -1.721e-01, -1.636e-01) * s[1][2][1];
	r0 += M4(-9.595e-02, 9.420e-02, -1.729e-02, -7.453e-02, -1.010e-01, -8.183e-02, -2.649e-02, -9.496e-02, 7.405e-01, -4.122e-01, 8.500e-01, 4.586e-01, 8.160e-02, -4.175e-02, -3.884e-02, -4.218e-02) * s[2][0][0];
	r0 += M4(4.683e-02, -9.253e-02, 2.332e-02, -1.480e-02, -5.802e-02, 2.395e-02, -2.120e-03, -6.959e-03, -4.774e-02, 3.864e-02, 3.772e-02, 9.569e-03, -1.731e-03, 6.302e-03, 3.108e-02, 2.861e-02) * s[2][0][1];
	r0 += M4(-3.649e-02, -1.174e-01, 1.685e-01, 3.596e-02, -2.386e-01, -1.359e-02, 5.923e-02, 1.121e-01, 1.035e+00, 1.856e+00, 1.055e+01, 7.375e+00, 6.795e-02, 1.030e-01, 2.989e-02, 3.725e-02) * s[2][1][0];
	r0 += M4(4.842e-01, -2.822e-01, 3.336e-02, 1.969e-02, 7.771e-02, 1.284e-02, -1.112e-01, 2.593e-02, 3.837e-03, 3.685e-02, -6.616e-02, -1.900e-02, -3.408e-01, 9.636e-02, 1.265e-01, -1.057e-02) * s[2][1][1];
	r0 += M4(-3.387e-01, 6.722e-03, 1.056e-03, 6.679e-03, 2.026e-01, -1.167e-01, 9.107e-02, -5.734e-02, -9.619e-02, 1.121e-01, -3.607e-01, -1.819e-01, -1.187e-01, 3.748e-02, -3.976e-02, 2.395e-02) * s[2][2][0];
	r0 += M4(2.612e-01, 8.472e-02, 4.005e-02, 1.122e-01, 2.307e-01, -7.790e-03, -2.955e-02, -1.018e-01, -1.280e-01, 3.210e-02, 6.045e-02, 2.283e-02, -2.920e-01, -4.949e-03, 3.127e-02, 7.093e-02) * s[2][2][1];
	r0 += V4(3.421e-02, -2.179e-02, 3.347e-03, 2.604e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-4x4C-conv4
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
	r0 += M4(-1.169e-01, -3.512e-02, -7.913e-02, -6.991e-02, -1.407e-02, 7.446e-02, -1.424e-02, -2.039e-02, -1.008e-01, 2.402e-02, -5.341e-02, 2.717e-03, 1.336e-01, -1.934e-02, 9.302e-02, 1.155e-01) * s[0][0][0];
	r0 += M4(2.030e-02, -4.893e-03, -5.700e-02, 5.230e-03, -5.604e-02, 1.051e-01, -1.990e-02, -3.935e-02, 3.720e-03, -3.512e-01, -7.839e-02, -1.366e-02, 4.969e-02, -8.241e-03, 9.449e-02, -6.983e-03) * s[0][0][1];
	r0 += M4(1.106e-01, 2.319e-01, 1.023e-01, 8.922e-02, 1.005e-03, 1.431e-01, -3.367e-02, -2.096e-02, 3.234e-02, 1.037e-01, 2.776e-02, 1.020e-01, 4.727e-03, -2.723e-01, -2.655e-02, -7.305e-02) * s[0][1][0];
	r0 += M4(1.004e-01, 1.703e-01, 5.594e-02, 1.675e-01, 6.088e-02, 4.465e-02, 6.567e-02, 6.063e-02, 4.229e-01, -1.446e-01, 9.517e-02, 1.071e-01, -3.248e-01, -1.869e-01, -1.372e-01, -2.995e-01) * s[0][1][1];
	r0 += M4(-1.642e-02, -3.236e-02, -2.875e-02, -2.200e-02, 1.731e-01, 1.304e-01, -7.198e-04, 1.636e-01, 6.572e-02, -3.125e-02, -5.545e-02, 6.571e-02, -1.256e-01, -6.598e-03, -1.599e-01, -7.107e-02) * s[0][2][0];
	r0 += M4(9.389e-03, -5.872e-02, 3.056e-02, 1.586e-02, 2.655e-02, 1.180e-01, 3.644e-02, -7.742e-03, -5.225e-01, 1.551e-02, 2.513e-01, -4.236e-01, 2.235e-02, -2.325e-02, -2.803e-01, 2.306e-02) * s[0][2][1];
	r0 += M4(-2.148e-02, -1.610e-01, -5.676e-02, 2.106e-02, 1.066e-01, -1.033e-01, -1.967e-03, 3.488e-02, -1.014e-01, -1.538e-01, -8.075e-02, -4.269e-02, 3.368e-02, 2.104e-01, 1.132e-01, 5.446e-02) * s[1][0][0];
	r0 += M4(7.114e-02, -1.616e-01, -6.925e-02, 6.517e-02, -7.278e-02, -2.212e-01, -3.087e-02, -4.286e-02, 3.901e-02, 1.807e-01, -5.275e-02, -9.264e-02, 1.220e-01, 3.061e-01, 1.286e-01, 6.969e-02) * s[1][0][1];
	r0 += M4(2.730e-01, -5.532e-02, 1.479e-01, 3.061e-01, -4.591e-01, -2.749e-01, 4.310e-02, 2.432e-01, 1.120e-02, -2.173e-01, 1.423e-02, 1.939e-01, -1.572e-01, 3.094e-01, -2.401e-02, -7.682e-02) * s[1][1][0];
	r0 += M4(8.058e-01, -6.341e-03, 2.405e+00, 2.990e-01, 2.443e-01, -8.102e-02, 9.615e-02, 5.254e-01, -8.168e-01, -3.119e-01, -2.980e-01, -9.119e-01, -1.152e+00, 3.202e-01, -2.104e-02, -4.111e-01) * s[1][1][1];
	r0 += M4(-3.895e-02, 3.924e-02, 2.505e-03, -7.053e-02, 6.242e-01, -3.049e-01, 1.362e-01, 6.348e-01, 8.554e-02, -1.649e-01, 5.463e-02, 1.464e-01, -1.673e-01, 3.536e-01, -5.175e-02, -2.009e-01) * s[1][2][0];
	r0 += M4(7.786e-02, 6.289e-02, -6.099e-04, 1.045e-02, 2.524e-01, -1.730e-01, 8.081e-02, 3.057e-01, 3.171e-01, 2.935e-01, 2.535e-01, 5.167e-02, -4.325e-01, 1.704e-01, -8.883e-02, -3.304e-01) * s[1][2][1];
	r0 += M4(2.550e-02, -1.730e-02, -1.126e-02, 5.233e-02, -9.772e-02, -9.272e-03, -2.949e-02, -6.470e-02, -1.075e-01, -1.626e-02, -3.846e-03, -7.588e-02, 1.483e-01, 3.614e-02, 3.909e-03, 1.033e-01) * s[2][0][0];
	r0 += M4(3.447e-01, 3.067e-03, -2.669e-02, 1.820e-03, -3.440e-02, -6.431e-02, -1.181e-02, -5.507e-03, -9.274e-02, -6.199e-02, 2.387e-02, 6.363e-02, 1.285e-01, 4.875e-02, 1.362e-02, 4.798e-02) * s[2][0][1];
	r0 += M4(-1.909e-02, 9.678e-02, 2.453e-02, -3.701e-02, 3.481e-02, -4.473e-02, -1.136e-02, -7.460e-02, -4.704e-02, 2.669e-02, 3.139e-03, 6.533e-02, -1.853e-02, 2.555e-02, -1.055e-02, -8.601e-02) * s[2][1][0];
	r0 += M4(4.834e-01, 1.590e-02, 2.196e-02, 4.209e-02, 5.603e-02, -1.181e-02, 8.191e-03, 2.570e-02, 5.801e-01, -2.822e-01, 6.873e-02, 4.685e-01, 6.307e-02, -2.849e-02, 3.245e-02, -4.895e-02) * s[2][1][1];
	r0 += M4(1.957e-02, 3.553e-02, 2.386e-03, -8.893e-03, 1.978e-01, 3.428e-02, 6.469e-02, 1.679e-01, 6.786e-03, 4.286e-02, 1.921e-02, 2.837e-02, -2.237e-02, -9.892e-02, -4.475e-02, -1.897e-02) * s[2][2][0];
	r0 += M4(-4.564e-02, -8.087e-03, -1.314e-02, -2.066e-02, -4.245e-02, 8.782e-02, -2.413e-03, -4.302e-02, 3.624e-01, 2.197e-01, 1.299e-01, 1.341e-01, -6.696e-02, -1.315e-01, -1.143e-02, -6.470e-02) * s[2][2][1];
	r0 += V4(9.996e-05, -2.093e-02, -1.904e-03, -5.940e-04);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-4x4C-out-shuffle
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
#define l0(x, y) V4(conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv4_pt))
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
	r0 += M4(-1.244e-02, -1.861e-02, 4.096e-02, 1.654e-02, 3.415e-02, -2.440e-02, -5.173e-03, -6.080e-03, 1.052e-01, 1.036e-02, 3.047e-02, 1.464e-02, -6.121e-02, -2.620e-02, -4.756e-02, -4.310e-02) * s[0][0][0];
	r0 += M4(4.131e-04, -1.827e-03, 6.098e-05, 2.729e-03, -1.679e-02, 6.924e-03, -1.225e-02, 9.400e-04, 1.077e-02, 1.527e-02, 1.210e-02, 1.344e-03, -1.900e-02, 1.545e-03, -2.523e-02, -1.803e-02) * s[0][0][1];
	r0 += M4(-1.616e-02, -7.739e-02, 2.443e-02, 3.626e-02, -4.441e-03, 6.169e-02, -4.387e-02, -2.623e-02, -1.848e-02, 2.925e-02, -1.303e-02, -1.691e-02, -4.834e-02, -5.382e-03, 1.309e-02, 2.752e-02) * s[0][1][0];
	r0 += M4(-1.175e-01, 1.134e-03, 7.793e-02, 6.469e-02, 1.055e-01, 1.737e-01, -1.217e-01, -6.036e-02, -6.807e-03, -3.373e-02, 2.106e-03, -4.929e-04, 4.163e-02, -2.446e-02, -6.622e-02, -7.299e-02) * s[0][1][1];
	r0 += M4(-3.696e-02, 9.908e-03, -2.093e-02, 2.692e-03, 4.250e-03, -2.113e-02, 3.015e-02, 5.976e-03, -2.026e-02, -3.125e-03, -7.702e-04, 4.822e-03, 5.602e-02, 1.285e-02, 3.730e-03, -4.267e-03) * s[0][2][0];
	r0 += M4(1.224e-02, -8.618e-02, 9.677e-03, 4.603e-02, 5.399e-02, 3.628e-02, 9.476e-03, -2.388e-02, -7.135e-03, -8.210e-03, -5.670e-04, -2.632e-03, 8.080e-03, 3.268e-02, -1.232e-02, -2.707e-02) * s[0][2][1];
	r0 += M4(9.018e-02, -4.349e-02, -6.814e-02, -5.749e-02, 3.254e-02, -2.196e-02, 7.953e-02, -3.894e-02, 7.419e-01, -1.363e-01, 7.454e-02, -2.389e-01, 5.427e-02, -9.591e-02, 1.144e-01, -1.636e-03) * s[1][0][0];
	r0 += M4(-1.877e-02, -6.543e-03, -2.899e-02, -8.671e-03, 1.371e-01, -1.694e-01, 2.293e-01, -5.558e-02, 3.411e-02, 1.126e-02, -3.204e-02, 4.448e-04, -2.342e-02, -3.836e-02, 6.012e-04, -1.318e-02) * s[1][0][1];
	r0 += M4(-3.682e-01, -5.920e-02, -3.722e-01, -3.314e-01, -6.884e-02, 5.329e-02, -2.393e-02, 1.571e-01, 6.324e-02, 2.008e-01, -8.578e-02, -1.428e-01, 3.705e-01, 6.664e-01, 1.509e-01, 4.390e-01) * s[1][1][0];
	r0 += M4(-1.993e-01, -1.096e-01, -3.918e-01, -1.587e-01, -8.327e-01, 1.220e-01, 1.490e-01, 7.559e-01, 1.431e-01, 8.939e-02, 3.307e-02, -7.355e-02, 2.474e-01, 1.957e-01, 3.546e-01, 2.384e-01) * s[1][1][1];
	r0 += M4(4.424e-02, -6.238e-02, 2.606e-02, -1.123e-02, 3.232e-02, -2.292e-02, 5.537e-03, -5.959e-02, 3.198e-02, 5.651e-02, -2.870e-02, -9.175e-03, -1.896e-02, -5.019e-02, 5.089e-02, -4.454e-02) * s[1][2][0];
	r0 += M4(9.644e-02, 2.776e-02, 8.836e-02, -1.459e-01, 1.331e-01, -3.204e-01, 1.063e-01, -1.125e-01, -1.641e-02, 2.777e-02, -2.690e-02, 6.231e-03, -9.844e-02, -2.297e-02, -5.113e-02, 6.877e-02) * s[1][2][1];
	r0 += M4(-2.266e-02, -1.270e-02, 7.056e-02, -3.675e-02, -1.029e-02, 1.410e-02, -1.297e-03, 1.835e-02, -1.584e-02, -6.141e-01, 1.218e+00, -2.731e-01, 1.038e-03, 8.304e-02, -1.150e-01, -2.929e-02) * s[2][0][0];
	r0 += M4(-2.162e-03, 1.172e-02, 2.525e-03, 3.928e-03, 2.720e-02, -2.110e-02, 6.422e-03, -7.860e-02, 2.772e-02, 1.016e-02, 7.356e-02, 3.236e-02, -2.323e-02, -5.812e-03, -3.836e-02, -1.564e-02) * s[2][0][1];
	r0 += M4(-3.261e-02, -6.713e-03, -8.623e-02, 9.692e-02, 2.676e-02, -4.920e-03, -1.245e-02, -1.840e-02, -1.667e-01, -1.916e-01, 7.642e-02, 4.747e-01, -6.398e-02, -9.353e-02, 9.408e-02, 1.254e-01) * s[2][1][0];
	r0 += M4(2.859e-03, -1.030e-04, 1.542e-03, -2.344e-02, 1.421e-01, 1.389e-01, -3.087e-01, -1.082e-01, 4.922e-03, -1.260e-02, 7.071e-02, 8.130e-02, -2.232e-02, -5.604e-02, 1.001e-02, -2.334e-02) * s[2][1][1];
	r0 += M4(2.711e-02, -1.710e-02, 2.696e-02, -5.207e-02, -8.634e-03, -9.947e-03, 1.938e-03, -1.214e-02, -2.049e-02, 9.365e-03, 3.973e-02, 1.134e-01, 7.093e-03, 8.782e-03, -7.137e-03, -7.596e-03) * s[2][2][0];
	r0 += M4(-2.007e-03, -8.525e-03, 4.992e-03, 2.849e-02, -5.286e-02, 2.612e-02, 7.434e-02, 3.310e-02, -1.361e-02, 5.338e-03, -1.857e-02, 3.799e-03, 1.903e-02, 2.379e-02, -1.513e-02, 1.306e-03) * s[2][2][1];
	r0 += V4(7.191e-06, 3.729e-06, 6.010e-07, -1.320e-04);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

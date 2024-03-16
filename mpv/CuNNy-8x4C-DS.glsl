// CuNNy 8x4C DS
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

//!DESC CuNNy-8x4C-DS-EASU
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


//!DESC CuNNy-8x4C-DS-in
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
	r0 += V4(-2.167e-02, 2.531e-01, 1.811e-01, -2.880e-02) * s[0][0][0];
	r0 += V4(-5.614e-01, -4.160e-03, 8.775e-02, 3.512e-02) * s[0][1][0];
	r0 += V4(-9.876e-03, 3.236e-04, -3.387e-02, -2.826e-02) * s[0][2][0];
	r0 += V4(2.523e-01, -1.006e-01, 7.246e-01, 8.187e-02) * s[1][0][0];
	r0 += V4(-1.693e-02, -4.812e-01, -3.874e-03, 9.160e-01) * s[1][1][0];
	r0 += V4(-1.093e-01, 1.751e-02, 1.798e-02, -3.679e-01) * s[1][2][0];
	r0 += V4(3.828e-02, 5.287e-02, -6.615e-02, -6.642e-02) * s[2][0][0];
	r0 += V4(4.603e-01, 2.055e-01, 4.817e-02, -1.545e-01) * s[2][1][0];
	r0 += V4(-2.868e-02, 2.490e-02, -2.719e-02, -3.877e-01) * s[2][2][0];
	r0 += V4(2.264e-03, 3.461e-03, -2.419e-02, -5.049e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv1
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
	r0 += M4(3.465e-02, -1.500e-01, 1.081e-01, -2.881e-01, 1.720e-01, -1.619e-01, 4.537e-02, -1.428e-01, -1.383e-01, 4.944e-02, -9.336e-02, 3.522e-03, -7.964e-01, -3.299e-02, -2.023e-01, 2.772e-01) * s[0][0][0];
	r0 += M4(9.421e-02, -3.018e-01, 1.027e-01, -3.070e-01, -2.368e-01, -9.070e-02, 6.996e-02, 9.132e-02, -4.467e-01, 3.648e-01, -1.008e-01, 3.120e-01, -7.646e-02, -6.107e-01, -2.153e-01, 1.455e-01) * s[0][0][1];
	r0 += M4(-3.239e-01, 2.243e-01, 8.963e-02, -1.889e-01, 3.743e-01, -1.231e+00, 3.078e-01, -2.289e-01, 1.382e-01, 1.317e-01, 6.261e-02, -4.525e-01, 1.695e-02, 3.759e-01, -2.380e-01, 8.403e-01) * s[0][1][0];
	r0 += M4(-1.564e-01, -3.130e-01, 9.627e-02, 1.911e-01, 1.713e-01, 1.644e-01, 1.592e-01, -2.987e-01, 1.500e-01, 1.728e-01, 1.139e+00, 7.801e-01, 8.638e-01, -3.038e-01, -2.244e-01, 7.053e-01) * s[0][1][1];
	r0 += M4(2.291e-01, -2.155e-01, 3.716e-02, 1.121e-02, -4.688e-01, 2.544e-01, 1.086e-01, -5.688e-01, -2.359e-01, -5.360e-02, 2.586e-01, 2.315e-01, 2.301e-03, 9.011e-02, -5.010e-02, -2.487e-01) * s[0][2][0];
	r0 += M4(6.759e-02, 2.907e-01, -1.870e-01, -2.568e-02, -7.210e-02, -3.623e-01, 2.935e-02, -4.273e-01, -4.603e-01, -9.641e-02, -3.167e-01, 4.201e+00, 2.450e-01, -3.682e-02, -7.521e-03, -1.835e-01) * s[0][2][1];
	r0 += M4(1.152e-01, -3.022e-01, -3.916e-01, 7.100e-02, 3.577e-01, -1.518e-01, 3.136e-01, -1.839e-03, 1.433e-01, 1.938e-02, 9.061e-02, 3.628e-02, -5.841e-01, 3.945e-01, -1.566e-01, 2.816e-02) * s[1][0][0];
	r0 += M4(9.500e-02, -6.099e-01, -3.624e-01, 2.457e-01, 4.384e-01, 3.200e-01, 6.362e-02, 2.066e-01, -1.319e+00, -2.445e-01, 2.270e-01, 5.376e-01, -8.481e-02, -5.675e-01, -6.851e-02, 4.554e-02) * s[1][0][1];
	r0 += M4(-7.643e-01, 1.226e+00, -3.463e-02, -3.361e-01, 8.731e-01, 3.672e-01, -3.198e-01, -3.693e-01, 2.429e-01, -2.235e-01, -4.129e-02, 3.958e-01, 4.663e-02, 1.928e+00, 5.287e-01, -8.314e-02) * s[1][1][0];
	r0 += M4(-1.255e-01, 1.347e-01, -8.988e-03, -4.982e-01, -2.186e-01, -2.527e-01, 4.256e-02, -1.589e-01, 3.172e-01, -5.722e-01, -4.775e-01, 9.734e-01, 8.381e-01, -2.541e-01, 1.089e+00, -2.716e-01) * s[1][1][1];
	r0 += M4(-7.126e-01, 2.993e-01, 1.323e-01, 2.820e-02, 6.753e-01, 6.210e-01, -3.702e-01, -4.434e-01, 3.017e-02, 9.264e-02, 3.252e-01, 2.493e-01, 1.686e-02, -9.622e-02, -2.158e-03, 1.240e-01) * s[1][2][0];
	r0 += M4(-1.434e-01, -5.419e-01, 2.390e-01, -7.848e-03, -2.893e-01, -3.510e-01, -1.473e-01, -8.877e-02, 5.141e-01, -8.863e-01, -2.786e+00, 2.697e+00, 3.469e-01, 2.289e-01, -2.097e-01, 7.601e-02) * s[1][2][1];
	r0 += M4(-9.872e-02, -3.223e-01, 5.397e-02, 2.595e-02, -7.840e-02, 3.336e-01, 1.968e-01, 6.970e-02, -6.385e-02, 6.856e-02, 3.747e-02, -3.045e-02, -8.960e-02, 4.718e-01, 6.435e-02, -1.284e-01) * s[2][0][0];
	r0 += M4(-1.927e-01, 1.096e-01, -6.680e-02, 6.811e-02, -3.430e-02, 4.738e-01, 9.483e-02, 6.270e-02, 5.797e-01, 2.340e-01, -1.867e-01, -1.188e-02, -5.278e-02, 2.221e-01, 6.275e-02, -1.067e-01) * s[2][0][1];
	r0 += M4(-1.097e-01, 2.953e-01, 9.302e-02, -1.164e-01, 3.865e-01, -2.578e-01, -2.730e-01, -3.008e-01, -5.533e-02, -2.743e-02, 1.247e-01, 1.744e-01, -2.231e-01, -2.777e-01, -1.440e-01, 6.560e-02) * s[2][1][0];
	r0 += M4(-3.934e-02, -1.708e-01, 1.782e-01, -4.916e-02, -3.386e-01, 2.651e-01, -1.120e-01, -7.050e-02, -1.770e-01, 1.421e-01, -2.078e-01, 5.183e-01, 8.956e-02, -3.234e-01, -3.084e-01, 5.200e-02) * s[2][1][1];
	r0 += M4(-5.193e-02, 1.036e-03, -1.115e-02, 7.959e-02, -8.468e-03, -6.179e-01, -1.409e-01, -1.893e-01, -6.979e-02, -5.413e-02, 1.795e-01, 9.769e-02, 1.288e-02, -1.076e-01, -1.725e-02, -6.109e-02) * s[2][2][0];
	r0 += M4(-2.177e-03, -2.605e-01, -8.219e-02, -1.357e-02, -2.554e-02, 6.545e-02, -2.311e-01, -1.432e-01, 5.008e-01, -6.800e-01, 1.101e-01, 5.754e-01, -5.507e-02, 5.921e-02, -3.382e-02, -6.992e-02) * s[2][2][1];
	r0 += V4(8.073e-02, -7.570e-02, -8.386e-01, 5.661e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv2
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
	r0 += M4(2.741e-01, -1.951e-02, 2.204e-01, 1.901e-01, -8.565e-02, -1.890e-02, 2.911e-02, -4.018e-02, 1.346e-01, 7.487e-01, -4.073e-02, 1.134e+00, -3.295e-02, -2.070e-01, -8.644e-03, -1.801e-01) * s[0][0][0];
	r0 += M4(-1.036e-02, -7.638e-02, -1.944e-01, -1.074e-02, -4.039e-01, 1.582e-01, -2.105e-01, -4.882e-01, -2.940e-01, -1.585e-01, -9.627e-02, -1.037e-01, 1.822e-01, -2.738e-01, -3.456e-01, -1.097e-01) * s[0][0][1];
	r0 += M4(1.972e-01, 5.371e-01, 5.020e-01, 4.093e-01, -2.439e-02, 1.335e-01, 3.686e-02, -6.958e-02, 5.848e-01, 2.208e+00, 3.473e-01, 2.550e+00, 2.862e-01, 5.848e-02, -2.457e-01, -1.583e-01) * s[0][1][0];
	r0 += M4(-7.441e-02, 7.235e-02, 2.175e-01, 7.054e-02, 1.071e-01, 9.745e-01, -1.607e+00, -5.792e-01, -1.880e-01, 4.424e-01, 1.835e-01, 4.243e-02, 1.112e-01, -4.853e-01, 1.499e-01, -3.910e-01) * s[0][1][1];
	r0 += M4(4.597e-01, 1.011e-01, -6.279e-02, 3.364e-02, 5.112e-03, 6.004e-02, 2.363e-02, 2.281e-02, 2.207e+00, 7.847e-01, -1.822e+00, 8.697e-01, -1.264e-01, 9.544e-03, 1.674e-01, -9.984e-02) * s[0][2][0];
	r0 += M4(8.857e-02, 8.132e-02, -1.101e-01, 7.357e-03, 6.539e-01, 7.077e-01, -1.146e+00, 4.307e-02, 2.222e-01, -1.848e-01, -1.277e-01, -4.315e-02, -5.926e-02, 2.889e-02, 1.058e-01, 2.926e-03) * s[0][2][1];
	r0 += M4(-3.857e-01, 3.749e-01, 1.419e-01, 1.197e-01, 1.167e-01, 1.485e-01, 5.652e-02, -4.814e-03, 3.191e+00, 1.226e+00, 3.150e-01, 2.216e+00, 2.448e-01, 2.648e-01, -7.072e-02, -4.955e-02) * s[1][0][0];
	r0 += M4(9.911e-02, 1.314e-01, 9.460e-02, 1.304e-01, 1.068e+00, 1.780e-01, -7.079e-01, -3.810e-01, 4.205e-01, 1.443e-01, 9.215e-02, -7.631e-02, 4.464e-02, 2.606e-01, 4.557e-01, 3.057e-01) * s[1][0][1];
	r0 += M4(-1.091e+00, 7.495e-01, 1.976e-01, 1.638e-01, -1.412e-01, -3.116e-01, -9.343e-02, 1.577e-01, 5.543e-01, -1.188e+00, 1.639e-01, 4.398e+00, -4.058e-01, 1.008e+00, 1.414e-01, 4.206e-01) * s[1][1][0];
	r0 += M4(-4.201e-01, -2.495e-01, 3.190e-01, -5.343e-02, 1.513e+00, 3.757e-01, -2.541e+00, -3.047e-01, -3.293e-01, -4.731e-01, -1.754e-01, 5.273e-01, -8.459e-01, 5.887e-01, 1.705e+00, 1.328e+00) * s[1][1][1];
	r0 += M4(-5.530e-03, -3.615e-01, -1.815e-01, -2.356e-03, -4.267e-02, -5.091e-02, 6.110e-02, -3.756e-03, 1.661e+00, -1.098e+00, -2.487e+00, 1.714e+00, 2.237e-01, -2.994e-02, -2.480e-01, -1.194e-01) * s[1][2][0];
	r0 += M4(1.226e-01, 4.333e-02, -1.859e-01, -7.246e-03, 3.479e-01, 8.244e-01, -8.235e-01, 3.826e-02, -2.698e-01, -1.348e-01, 1.850e-01, 7.494e-02, 1.162e-01, -6.248e-02, 4.222e-01, -7.528e-02) * s[1][2][1];
	r0 += M4(2.451e-01, -3.443e-02, 1.278e-01, -4.450e-02, -5.871e-02, -1.390e-02, 2.006e-02, -1.004e-02, -5.790e-01, 5.157e-01, 8.629e-02, -5.665e-01, -4.354e-03, -2.790e-02, 1.539e-01, 6.491e-02) * s[2][0][0];
	r0 += M4(3.206e-02, 8.130e-02, -1.625e-02, -1.123e-04, -4.321e-01, 8.095e-02, 1.509e-01, -4.062e-02, -4.724e-02, -9.784e-02, 7.322e-03, -5.759e-02, 5.796e-02, 8.251e-03, 4.147e-01, 4.360e-01) * s[2][0][1];
	r0 += M4(-2.537e-01, -2.479e-01, 2.277e-01, -1.051e-01, 2.817e-02, 3.074e-02, 3.178e-02, 8.964e-03, 6.155e-01, 6.564e-01, 9.768e-02, -2.420e-01, 3.493e-01, -2.344e-01, 3.640e-03, 1.784e-01) * s[2][1][0];
	r0 += M4(2.020e-01, -1.154e-01, -6.062e-02, 6.912e-02, 1.112e-01, -6.603e-02, -2.755e-01, 2.399e-01, 2.751e-01, -7.528e-02, 1.294e-01, -1.990e-02, 1.941e+00, -2.193e-01, 8.345e-01, 2.020e+00) * s[2][1][1];
	r0 += M4(-8.432e-02, -3.514e-01, -2.143e-01, 8.870e-02, -1.209e-02, -6.842e-03, -3.006e-02, -7.653e-03, 4.602e-01, 8.749e-01, -1.358e+00, 5.828e-02, -3.692e-01, -3.057e-01, 1.874e-03, -4.675e-02) * s[2][2][0];
	r0 += M4(-5.351e-02, -1.422e-02, -4.233e-02, 5.693e-03, 9.322e-02, 1.776e-01, 7.682e-02, 3.311e-02, 1.714e-02, 1.484e-01, -1.420e-01, -9.655e-02, -4.181e-01, -3.294e-01, 2.512e-01, -1.604e-01) * s[2][2][1];
	r0 += V4(-1.860e-01, -3.662e-01, 1.107e-01, 4.725e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv3
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
	r0 += M4(-1.165e-01, -2.791e-01, -6.314e-02, 8.836e-02, -3.814e-02, -1.440e-01, -2.124e-02, -1.829e-02, -1.170e-01, 1.418e-01, -2.745e-02, -3.227e-01, 6.604e-02, 9.233e-02, 4.179e-02, 1.657e-01) * s[0][0][0];
	r0 += M4(7.788e-02, -1.779e-02, 3.223e-02, -5.273e-02, -2.264e-02, 3.637e-02, -1.694e-02, 6.812e-02, -3.263e-02, 1.148e-01, -3.818e-02, -2.862e-01, 9.736e-03, 1.252e-01, 9.445e-02, 1.520e-01) * s[0][0][1];
	r0 += M4(-3.647e-01, -5.098e-01, -2.290e-01, 3.536e-01, 4.341e-02, -2.939e-01, 3.550e-02, -3.208e-02, -1.240e-01, -1.386e-01, 4.103e-02, -1.103e-01, 9.397e-02, 3.156e-01, -9.391e-02, 1.064e-01) * s[0][1][0];
	r0 += M4(1.568e-01, -3.393e-01, -1.019e-01, 2.218e-01, -3.998e-02, -1.498e-01, 2.351e-02, -1.598e-01, -2.827e-01, 1.354e-01, 1.865e-01, 1.175e-01, 2.468e-01, 1.114e-01, -6.682e-02, 1.411e-01) * s[0][1][1];
	r0 += M4(-2.609e-01, -1.587e-01, -1.113e-01, 8.900e-02, -7.168e-02, -1.188e-01, -2.751e-02, 6.269e-02, 2.343e-01, -1.241e-01, -4.671e-02, 1.482e-01, -3.854e-01, 4.804e-02, -1.107e-01, -2.335e-01) * s[0][2][0];
	r0 += M4(2.512e-01, -5.701e-02, -4.258e-03, 1.853e-01, 1.976e-02, -1.302e-01, 4.287e-02, -8.081e-02, 2.724e-01, -3.041e-02, -1.421e-01, -3.129e-03, -2.740e-01, -3.165e-02, -6.518e-02, -3.488e-01) * s[0][2][1];
	r0 += M4(-4.526e-02, -1.959e-01, -2.680e-01, -2.426e-01, 3.841e-01, -3.889e-02, 5.502e-02, 8.507e-02, -1.376e-01, 7.257e-02, -1.004e-01, -1.466e-01, 6.216e-02, -1.764e-01, 7.774e-02, 2.553e-01) * s[1][0][0];
	r0 += M4(1.419e-01, 6.415e-03, 6.914e-02, 3.328e-02, 1.531e-01, 2.985e-01, 5.659e-02, -2.683e-01, -2.942e-02, 3.311e-02, -2.466e-03, -3.092e-01, -2.943e-03, -1.754e-01, -5.502e-02, 1.694e-01) * s[1][0][1];
	r0 += M4(2.068e-01, -1.192e-01, -7.357e-01, 2.158e-01, 4.172e-01, 6.191e-01, -3.585e-01, 4.388e-01, -3.207e-03, 5.724e-01, -1.946e-01, 1.572e-02, -7.390e-01, -7.028e-02, 9.696e-01, 2.408e-01) * s[1][1][0];
	r0 += M4(7.788e-02, 1.133e-01, -2.575e-01, 3.253e-01, -4.865e-01, 7.340e-01, -2.968e-01, -2.202e-01, -7.544e-01, 1.083e+00, -3.000e-02, 3.753e-01, 5.530e-02, -6.855e-01, 3.851e-01, 7.598e-01) * s[1][1][1];
	r0 += M4(-1.656e-01, -6.465e-01, 4.626e-02, 4.873e-01, 3.006e-01, -1.392e-01, 1.110e-01, 1.966e-01, -9.588e-02, -4.023e-02, 4.885e-01, -3.855e-03, 8.393e-02, 3.643e-01, -2.399e-01, 1.864e-01) * s[1][2][0];
	r0 += M4(2.075e-01, -1.819e-01, 5.790e-01, 8.917e-02, -1.538e-01, 4.668e-02, 1.810e-01, 1.636e-01, 4.555e-02, -1.276e-01, 1.788e-01, -5.107e-02, -2.741e-01, 2.512e-02, -5.410e-01, 7.436e-02) * s[1][2][1];
	r0 += M4(-3.662e-01, -6.961e-02, -3.751e-02, 1.379e-01, 1.883e-01, -2.234e-01, 1.843e-01, 2.010e-01, 4.053e-03, 2.763e-01, -8.642e-03, -2.381e-02, -9.671e-03, 2.568e-02, 8.530e-02, 1.337e-02) * s[2][0][0];
	r0 += M4(6.334e-02, 8.278e-02, -8.709e-02, 3.739e-02, 2.129e-02, -1.460e-01, 2.803e-01, -3.421e-02, 2.155e-02, 1.811e-01, -1.857e-01, -1.372e-01, 8.198e-02, -6.732e-02, 1.332e-01, -1.701e-02) * s[2][0][1];
	r0 += M4(-2.651e-01, -1.850e-02, -1.924e-01, -2.941e-02, 2.497e-01, -3.545e-02, -2.037e-01, 1.623e-01, -1.820e-01, -1.125e-01, 3.287e-01, -2.863e-01, 1.464e-01, -2.579e-01, 5.318e-01, 1.721e-01) * s[2][1][0];
	r0 += M4(2.685e-01, 1.387e-01, 1.175e-02, -8.781e-02, -6.074e-01, 1.604e-02, -1.920e-01, 1.659e-01, -4.458e-01, -9.606e-02, -9.248e-02, -3.361e-01, 2.624e-02, 1.389e-02, 2.676e-01, -7.570e-02) * s[2][1][1];
	r0 += M4(-8.418e-02, -1.473e-01, 1.577e-01, 2.656e-02, 2.707e-01, 9.613e-02, -3.082e-01, -1.013e-01, -4.540e-02, 9.514e-02, 1.020e-01, -2.049e-03, 2.167e-01, 1.915e-01, -3.264e-01, -6.783e-02) * s[2][2][0];
	r0 += M4(1.677e-01, -1.460e-01, 3.252e-01, -7.516e-02, -4.266e-03, 1.206e-01, -2.176e-01, -2.346e-02, -1.865e-01, 1.919e-01, 1.777e-01, -1.195e-01, 2.068e-02, 2.116e-01, -4.640e-01, 1.886e-02) * s[2][2][1];
	r0 += V4(7.466e-02, -8.036e-02, 8.134e-04, 1.935e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv4
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
	r0 += M4(-1.295e-01, 1.068e-01, 1.510e-01, -1.581e-03, -2.253e-02, 5.641e-02, -1.273e-01, -1.456e-01, 1.821e-01, -4.233e-01, 1.241e-01, -9.326e-03, -6.478e-02, -4.386e-02, 4.811e-02, -1.300e-01) * s[0][0][0];
	r0 += M4(3.407e-02, -1.168e-01, -1.869e-01, -7.935e-02, -2.011e-02, -1.426e-02, -4.479e-02, -2.282e-01, -2.714e-01, 3.431e-01, 4.157e-01, 2.920e-01, 3.574e-02, -7.933e-03, 4.437e-02, 3.814e-02) * s[0][0][1];
	r0 += M4(1.273e-02, -2.659e-01, -3.263e-03, -2.562e-01, 3.359e-01, -2.053e-01, -8.620e-02, -4.494e-02, -1.648e-01, 3.161e-01, 2.082e-05, -4.216e-02, 2.298e-01, -9.478e-02, 9.942e-03, -6.506e-02) * s[0][1][0];
	r0 += M4(4.317e-01, -1.638e-01, -3.991e-02, 5.514e-02, 2.368e-01, -2.466e-01, -3.967e-02, -1.892e-01, -5.372e-01, 5.022e-01, 4.758e-01, 1.000e-01, -2.817e-01, 1.265e-01, 3.760e-02, -1.529e-01) * s[0][1][1];
	r0 += M4(1.398e-01, -1.657e-03, -4.001e-02, 1.488e-02, 2.208e-02, -5.769e-02, 2.313e-02, 5.727e-02, -2.723e-02, -8.780e-02, -8.192e-02, -1.317e-01, 1.082e-02, 1.514e-02, 1.352e-01, 6.068e-02) * s[0][2][0];
	r0 += M4(-1.324e-02, -4.689e-02, -4.631e-02, 3.171e-02, -1.742e-02, 7.303e-02, 8.262e-02, -1.589e-02, 1.525e-02, -4.870e-02, 4.621e-02, -6.092e-02, -8.912e-02, 6.424e-02, 3.123e-02, -1.470e-01) * s[0][2][1];
	r0 += M4(5.115e-02, -2.276e-01, 7.142e-02, -7.009e-02, 2.418e-01, 1.056e-01, -6.085e-01, 9.372e-02, 1.089e-01, -3.821e-01, 1.859e-02, -8.999e-02, -8.979e-02, 3.774e-02, -1.973e-01, 3.491e-02) * s[1][0][0];
	r0 += M4(5.342e-02, -2.362e-01, -2.862e-01, 1.434e-01, 1.119e-01, 2.346e-02, -3.223e-01, -4.647e-02, -7.093e-02, 2.336e-01, 2.886e-01, 2.771e-01, -1.408e-01, 1.410e-02, 7.727e-02, -4.267e-02) * s[1][0][1];
	r0 += M4(5.768e-01, -4.134e-01, -3.830e-02, 5.762e-02, 6.210e-01, 3.905e-01, -3.639e-01, 2.821e-01, -1.066e-01, 7.532e-03, 4.309e-01, -2.534e-01, 1.627e-01, 1.665e-01, -5.273e-01, -9.959e-02) * s[1][1][0];
	r0 += M4(4.503e-01, -5.176e-01, -4.052e-01, -2.994e-01, 2.501e-01, 7.096e-01, 2.010e-01, 8.182e-01, -3.460e-01, 1.791e-01, 1.001e+00, -7.605e-01, 3.276e-01, -2.844e-01, -9.317e-01, 3.230e-02) * s[1][1][1];
	r0 += M4(-1.546e-01, 8.274e-02, -2.881e-02, 1.830e-01, 1.800e-02, 1.352e-01, -1.591e-01, 9.573e-02, 2.847e-02, -9.952e-02, -3.037e-01, 1.096e-01, -6.302e-02, 1.597e-01, 4.744e-02, -1.794e-01) * s[1][2][0];
	r0 += M4(2.427e-01, 3.129e-02, -1.299e-01, 1.652e-01, -1.449e-02, 1.580e-01, 7.551e-02, -2.391e-03, -5.557e-02, 4.004e-02, 1.129e-02, 4.945e-02, 2.589e-01, 7.627e-02, -3.115e-01, -1.890e-01) * s[1][2][1];
	r0 += M4(-2.873e-02, 2.343e-02, -2.930e-02, -3.706e-02, -4.478e-02, -7.413e-02, 4.124e-02, 1.193e-01, -1.378e-01, -4.822e-02, -9.533e-02, 1.331e-01, -3.143e-02, 1.388e-02, 1.469e-01, 4.901e-02) * s[2][0][0];
	r0 += M4(1.029e-02, -1.892e-03, 8.971e-02, 2.962e-02, -7.392e-02, 5.554e-03, 2.466e-01, 8.807e-02, 1.835e-02, 1.933e-02, 6.031e-02, -1.111e-01, -4.779e-02, -2.450e-02, 1.456e-01, -9.947e-03) * s[2][0][1];
	r0 += M4(-2.566e-01, 6.806e-02, 1.424e-01, -4.968e-02, -1.721e-01, -4.346e-03, 1.826e-01, -2.699e-01, -2.165e-01, 1.437e-02, -8.006e-02, -1.064e-01, 5.610e-02, 7.007e-02, 2.577e-01, -3.461e-01) * s[2][1][0];
	r0 += M4(-1.207e-01, -1.792e-01, -3.618e-01, 1.919e-01, 7.980e-02, 6.885e-03, 5.632e-01, -7.843e-01, -1.440e-01, -1.348e-03, 3.069e-02, -2.495e-01, -3.154e-01, 1.475e-02, 1.385e-01, -2.392e-01) * s[2][1][1];
	r0 += M4(-1.581e-01, -1.262e-02, 1.653e-01, -1.346e-01, 1.352e-01, -1.196e-01, -1.427e-01, -1.383e-01, 1.327e-03, -2.031e-02, -5.382e-03, -9.123e-02, 4.634e-03, -3.048e-03, 2.125e-01, -1.103e-01) * s[2][2][0];
	r0 += M4(-2.793e-02, 5.209e-02, 7.344e-02, 7.871e-02, 1.567e-01, -1.488e-01, 1.238e-01, -2.822e-01, 7.365e-02, -1.696e-02, 1.118e-02, -1.069e-01, -1.627e-01, -6.340e-02, 4.992e-02, -2.359e-01) * s[2][2][1];
	r0 += V4(-4.933e-02, 1.233e-02, 3.963e-02, 1.732e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv5
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
	r0 += M4(4.956e-03, 1.214e-01, -5.994e-02, 2.462e-01, 1.333e-01, 9.178e-02, 2.618e-03, 3.344e-02, 2.637e-02, 1.107e-01, -3.863e-03, -6.864e-03, -7.155e-02, 5.625e-02, -7.654e-02, 8.767e-02) * s[0][0][0];
	r0 += M4(7.314e-03, 1.168e-01, 5.905e-02, 8.215e-02, 3.564e-03, -4.146e-02, 4.273e-02, 2.627e-02, -6.513e-02, 1.792e-01, 6.577e-03, 1.345e-01, -2.786e-02, -6.177e-03, -3.326e-02, 1.198e-01) * s[0][0][1];
	r0 += M4(-2.251e-01, -2.455e-01, -8.391e-02, 2.036e-01, 3.034e-02, -8.504e-02, 7.781e-02, 6.820e-02, -2.154e-01, -1.508e-01, -1.300e-01, 5.207e-02, 8.701e-03, 1.673e-01, -4.332e-02, 7.906e-03) * s[0][1][0];
	r0 += M4(-5.805e-02, -2.243e-01, 4.706e-02, -4.868e-03, -5.825e-03, -1.043e-01, 2.725e-02, 6.616e-02, -9.664e-02, -1.890e-01, -1.101e-01, -3.293e-03, -4.643e-02, 1.036e-01, -2.361e-02, 1.409e-01) * s[0][1][1];
	r0 += M4(-1.685e-01, -3.017e-02, 9.167e-03, 7.857e-02, 3.651e-03, 1.974e-02, -2.994e-02, -5.026e-02, -1.192e-01, -2.281e-02, -7.486e-02, 3.018e-02, 2.318e-02, -1.065e-01, 6.334e-02, 4.772e-02) * s[0][2][0];
	r0 += M4(-1.885e-02, 1.622e-02, 3.957e-02, -2.518e-02, -6.001e-02, 2.122e-02, 3.191e-03, -3.476e-02, -4.831e-02, -4.580e-02, 1.276e-02, 8.822e-02, 3.176e-02, -1.333e-01, 5.408e-03, 7.019e-02) * s[0][2][1];
	r0 += M4(-4.228e-01, 7.013e-02, -1.228e-01, 2.455e-01, 4.798e-02, 1.075e-01, 6.662e-02, -1.174e-01, -1.140e-01, -5.627e-02, 3.716e-03, 3.053e-02, -2.467e-01, -1.489e-01, -6.101e-02, 1.717e-02) * s[1][0][0];
	r0 += M4(-1.607e-01, 1.074e-01, -4.705e-02, 2.282e-01, -1.268e-01, 1.607e-01, -1.093e-01, -4.999e-02, -2.931e-01, -3.671e-02, -2.027e-02, 2.920e-01, -1.084e-03, -2.549e-01, 3.464e-02, 1.895e-01) * s[1][0][1];
	r0 += M4(1.459e-01, 6.928e-01, 6.774e-02, -2.979e-01, -6.286e-01, -8.925e-02, -3.537e-01, -2.059e-01, 2.478e-01, 5.120e-01, -1.771e-02, -5.421e-02, 4.425e-02, 1.860e-01, 4.112e-01, 7.379e-01) * s[1][1][0];
	r0 += M4(4.305e-01, 1.459e-01, 6.258e-02, -3.251e-01, -4.516e-01, -5.972e-02, -1.191e-01, -4.893e-01, -1.034e-01, 1.025e+00, 5.296e-02, -4.020e-01, 2.854e-01, -1.044e-01, 4.379e-01, 8.366e-01) * s[1][1][1];
	r0 += M4(-9.282e-02, 9.770e-02, -6.565e-02, 6.429e-02, -2.608e-01, -1.559e-01, -1.325e-01, 7.155e-02, 7.446e-02, 1.814e-01, 4.369e-02, -6.214e-02, 1.328e-01, -6.791e-02, 1.756e-01, -2.130e-02) * s[1][2][0];
	r0 += M4(3.960e-02, -2.518e-01, -1.178e-01, -5.563e-02, -2.280e-01, -5.800e-02, -6.392e-03, 2.446e-02, 5.089e-03, 5.823e-02, -8.765e-02, 2.156e-02, 6.234e-02, 1.418e-02, 2.725e-01, -8.755e-02) * s[1][2][1];
	r0 += M4(-5.433e-02, -4.945e-03, -2.039e-01, -3.947e-02, 1.765e-01, 5.962e-02, -1.827e-01, 4.743e-02, -2.050e-03, 1.077e-01, 1.737e-02, -3.681e-02, -1.675e-02, 1.294e-01, -1.158e-02, 4.151e-02) * s[2][0][0];
	r0 += M4(-2.198e-01, -5.426e-02, 2.288e-01, -1.997e-01, 5.043e-02, -1.170e-01, 2.131e-02, -2.385e-01, -1.308e-01, -7.488e-02, 8.003e-02, -2.018e-02, -8.159e-02, 2.242e-02, 1.480e-01, -5.198e-02) * s[2][0][1];
	r0 += M4(-2.396e-01, -1.943e-01, -2.573e-01, 3.776e-02, -3.786e-01, -3.352e-01, 2.604e-01, 3.428e-01, 8.584e-02, 1.981e-01, -2.678e-02, -7.174e-03, -1.616e-01, -1.776e-01, 3.154e-01, 7.447e-02) * s[2][1][0];
	r0 += M4(-5.806e-02, -3.324e-01, -7.943e-02, 1.995e-01, -5.891e-02, -1.916e-01, -4.873e-01, -2.971e-01, -1.169e-01, 1.988e-01, 3.455e-01, 9.498e-02, -2.511e-01, -9.045e-02, 5.254e-01, -6.112e-02) * s[2][1][1];
	r0 += M4(-1.207e-01, -4.663e-02, -2.651e-01, 1.058e-01, -4.925e-01, -1.284e-01, -2.300e-02, -9.385e-03, 1.285e-01, 2.230e-02, -3.005e-02, 1.224e-01, 4.820e-02, -9.650e-02, 3.442e-02, 1.774e-01) * s[2][2][0];
	r0 += M4(5.578e-02, -2.663e-02, -3.167e-02, -1.771e-02, -1.401e-01, -2.564e-01, -4.519e-02, 3.170e-03, -1.558e-02, -8.752e-02, -1.021e-02, 2.554e-01, 1.105e-02, -9.847e-02, 9.594e-02, 1.247e-01) * s[2][2][1];
	r0 += V4(-1.391e-03, 2.871e-02, -2.235e-01, 1.337e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv6
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
	r0 += M4(3.100e-01, -3.095e-02, 2.367e-01, -3.689e-02, -1.100e-01, -5.124e-03, -1.520e-01, 2.603e-02, -1.361e-01, 1.776e-02, -5.190e-02, -9.042e-05, 5.396e-02, -4.857e-02, 5.668e-02, -3.845e-02) * s[0][0][0];
	r0 += M4(7.886e-02, 4.280e-02, 3.773e-02, 3.643e-02, -1.760e-02, 4.040e-02, -2.876e-01, 2.620e-01, -1.627e-01, -4.938e-02, -1.301e-01, -2.236e-01, -9.138e-02, -7.446e-02, -7.938e-02, 5.603e-02) * s[0][0][1];
	r0 += M4(-1.450e-01, -2.389e-02, -2.675e-02, 3.838e-01, 1.190e-01, 8.420e-03, 2.125e-01, -1.509e-01, 2.537e-01, -1.046e-01, 1.559e-01, 2.210e-01, -1.441e-01, 5.898e-02, -2.404e-01, -1.984e-01) * s[0][1][0];
	r0 += M4(-2.647e-02, -1.681e-02, -2.586e-03, 8.923e-02, 2.163e-01, 1.634e-01, 2.079e-01, 2.569e-01, 3.316e-03, -6.925e-02, -1.618e-01, 5.006e-02, -3.121e-01, 2.184e-01, -2.437e-01, 2.929e-01) * s[0][1][1];
	r0 += M4(-1.848e-03, 1.222e-01, -3.122e-02, -1.106e-01, 1.378e-02, -7.331e-02, 7.513e-03, 1.668e-02, 1.108e-02, -3.664e-02, 5.108e-02, 6.094e-02, 1.325e-02, -2.559e-02, 1.396e-01, -4.972e-03) * s[0][2][0];
	r0 += M4(-8.699e-04, 5.070e-02, -4.732e-02, -2.821e-02, -1.143e-01, -4.981e-02, -2.583e-01, -7.029e-02, 8.133e-03, 4.049e-02, 1.059e-03, -1.616e-02, 1.087e-01, -7.009e-02, 1.523e-01, 3.470e-01) * s[0][2][1];
	r0 += M4(5.632e-01, -6.791e-02, 1.613e-01, -1.567e-01, -1.517e-01, 5.421e-02, -6.625e-03, 8.431e-02, -2.868e-01, -3.602e-02, 6.448e-02, -1.330e-01, 4.863e-02, 1.739e-01, 3.185e-03, -2.106e-02) * s[1][0][0];
	r0 += M4(1.630e-01, -7.956e-02, 6.255e-02, -9.523e-02, 2.226e-01, 2.526e-02, 2.264e-02, 4.285e-01, -2.880e-01, 1.236e-01, -9.993e-02, -5.645e-02, 1.542e-01, 1.111e-01, -1.107e-01, 2.147e-01) * s[1][0][1];
	r0 += M4(-3.933e-02, 4.808e-01, 5.032e-01, 2.796e-01, -8.668e-02, -4.476e-03, 2.047e-01, -1.461e-01, 5.059e-01, -4.931e-01, 7.098e-01, 1.733e-01, 2.908e-01, -1.481e-01, 2.509e-01, 6.280e-01) * s[1][1][0];
	r0 += M4(8.923e-02, 1.757e-01, 7.936e-03, 6.126e-02, -6.935e-01, 9.375e-01, 8.674e-01, 2.529e-01, 4.853e-01, -6.426e-01, 4.036e-01, 7.287e-02, 5.428e-01, -6.044e-01, 6.593e-01, 1.030e+00) * s[1][1][1];
	r0 += M4(-2.230e-02, 4.738e-01, -2.837e-02, -5.929e-02, 5.176e-02, -1.183e-01, 5.625e-02, -1.336e-02, -2.206e-01, -5.851e-02, 3.015e-01, -1.165e-01, -6.168e-02, 5.070e-03, -2.267e-01, -2.052e-01) * s[1][2][0];
	r0 += M4(-6.816e-02, -6.323e-02, 8.030e-02, -5.708e-02, 1.909e-01, 1.562e-01, -4.366e-01, 3.532e-01, -9.987e-02, 9.126e-02, 4.522e-02, -1.198e-01, 1.033e-01, -6.575e-02, 3.116e-01, 2.139e-01) * s[1][2][1];
	r0 += M4(2.801e-01, 1.906e-01, -1.333e-01, 1.401e-01, -8.763e-02, -1.165e-01, 9.448e-02, -8.961e-02, 6.662e-02, -1.392e-01, 7.500e-02, -2.763e-02, 2.325e-02, -1.163e-01, 1.757e-02, -5.728e-02) * s[2][0][0];
	r0 += M4(5.746e-02, 7.281e-02, -1.621e-02, 1.539e-01, 6.875e-02, -8.717e-02, -8.509e-02, -5.627e-03, -2.987e-02, -7.973e-02, 5.166e-02, -2.344e-02, 1.213e-01, -1.683e-01, 1.734e-01, -3.885e-02) * s[2][0][1];
	r0 += M4(-1.615e-01, -1.375e-01, -4.392e-01, -4.623e-02, 7.055e-02, -4.825e-02, 8.628e-02, -7.299e-02, 7.567e-02, -1.466e-01, -5.600e-03, -9.562e-03, -7.688e-02, 3.203e-01, -6.976e-02, 1.204e-01) * s[2][1][0];
	r0 += M4(-1.106e-01, 1.083e-01, 4.438e-02, -9.343e-02, -1.505e-02, -1.119e-02, -1.804e-01, -1.124e-01, -8.570e-02, 9.714e-02, 4.374e-02, -4.918e-02, 1.310e-01, 8.346e-02, -5.866e-04, 4.759e-01) * s[2][1][1];
	r0 += M4(1.066e-01, 2.782e-01, -1.125e-01, -8.128e-02, -4.257e-02, -2.629e-02, -1.982e-02, 3.582e-02, 2.969e-02, 9.286e-02, 7.491e-03, -2.293e-02, -8.227e-02, 1.421e-01, -1.328e-01, 3.830e-02) * s[2][2][0];
	r0 += M4(2.064e-02, 1.297e-03, -1.040e-01, 3.891e-02, -2.984e-03, -7.050e-04, 7.082e-02, -7.019e-02, 7.809e-02, 9.101e-03, -3.921e-02, 5.126e-02, -2.301e-02, 2.042e-01, -9.399e-02, 2.629e-01) * s[2][2][1];
	r0 += V4(-3.565e-02, -5.881e-02, 4.155e-02, -7.178e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv7
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
	r0 += M4(2.876e-02, -3.186e-02, -5.657e-02, 1.642e-02, -4.248e-02, -1.626e-01, -9.587e-02, 4.587e-02, -2.143e-02, 8.480e-03, 2.327e-02, -2.349e-02, 2.014e-02, -4.742e-02, -2.104e-02, -1.004e-02) * s[0][0][0];
	r0 += M4(1.188e-02, -6.992e-02, -5.765e-02, -1.061e-02, -2.628e-02, -2.510e-01, -2.344e-01, 4.252e-02, -1.789e-02, 2.198e-02, 3.375e-02, -2.610e-02, -5.414e-03, 6.979e-02, -3.553e-02, -4.410e-02) * s[0][0][1];
	r0 += M4(-5.797e-02, 1.294e-01, 2.777e-01, -1.833e-02, -9.594e-02, -2.668e-01, 1.560e-01, -2.338e-01, -2.794e-03, -3.306e-02, -2.379e-01, 4.751e-02, 3.723e-02, 7.325e-02, 7.012e-02, -6.455e-02) * s[0][1][0];
	r0 += M4(-2.869e-02, 1.220e-01, 1.369e-01, -1.852e-01, -1.347e-01, -1.115e-01, 3.057e-01, -2.686e-01, 9.963e-03, -1.248e-01, -7.780e-02, 1.678e-01, 2.421e-02, 1.605e-01, 1.125e-02, 7.148e-02) * s[0][1][1];
	r0 += M4(8.667e-02, -9.282e-02, -6.157e-02, 3.863e-01, 3.649e-02, 1.304e-01, -8.790e-02, -1.423e-01, 2.289e-02, 4.287e-02, 6.760e-02, -1.158e-01, 1.735e-02, 1.900e-02, -2.013e-02, 1.043e-01) * s[0][2][0];
	r0 += M4(1.450e-03, -6.561e-02, 8.383e-02, 1.161e-01, 8.374e-02, 7.087e-02, -1.826e-01, 1.499e-01, 2.875e-02, 1.463e-02, 1.091e-01, -1.028e-01, 3.475e-02, 3.700e-02, -4.145e-02, 1.675e-01) * s[0][2][1];
	r0 += M4(8.037e-02, 8.764e-02, -1.151e-02, -4.796e-02, -1.575e-03, -3.040e-02, -6.647e-02, -6.268e-02, -8.622e-02, -9.981e-02, 2.871e-02, -4.141e-02, 6.560e-02, -2.568e-01, -8.428e-02, -7.644e-02) * s[1][0][0];
	r0 += M4(7.540e-02, 5.494e-02, -1.156e-01, -5.283e-02, -7.641e-02, -2.370e-01, 5.666e-03, 3.022e-02, -1.328e-01, -6.812e-02, 2.215e-01, 1.593e-02, -5.926e-02, -1.774e-01, -1.832e-02, -5.328e-02) * s[1][0][1];
	r0 += M4(-6.224e-02, 3.596e-01, 3.786e-01, 4.666e-01, -5.488e-01, 1.319e-01, 3.542e-01, 1.831e-01, 1.979e-01, 4.493e-01, -6.621e-01, -4.952e-01, 7.857e-02, 3.317e-01, 1.968e-01, -4.392e-01) * s[1][1][0];
	r0 += M4(-1.417e-01, 1.333e-01, 2.954e-01, 2.202e-01, -7.872e-01, -4.052e-02, 3.736e-01, 6.518e-02, 3.473e-01, 2.222e-01, -4.657e-01, -3.447e-01, 2.074e-01, 4.038e-01, 2.797e-01, -3.171e-01) * s[1][1][1];
	r0 += M4(2.630e-01, -1.680e-01, 2.235e-01, 3.740e-01, 3.716e-02, 1.636e-02, -9.399e-02, 1.023e-01, 5.491e-02, 2.975e-02, 6.007e-03, 6.467e-02, 8.432e-02, 7.449e-02, -2.646e-01, -1.519e-01) * s[1][2][0];
	r0 += M4(4.455e-02, -4.357e-02, 2.548e-01, 3.845e-01, 3.174e-01, 1.255e-01, -1.510e-01, 6.741e-02, 2.816e-02, -5.502e-02, 1.184e-01, 1.304e-02, 7.302e-02, 1.478e-01, -3.017e-01, -1.704e-01) * s[1][2][1];
	r0 += M4(-5.675e-02, 2.911e-02, 7.935e-02, 1.700e-02, -1.128e-02, -7.935e-02, -8.723e-02, -2.899e-03, -7.400e-02, -8.700e-02, -5.481e-02, 4.236e-02, 2.417e-02, -1.073e-02, -1.338e-02, 7.067e-03) * s[2][0][0];
	r0 += M4(-3.447e-02, 1.006e-02, 2.133e-02, -9.802e-03, 3.849e-02, -7.038e-02, 1.539e-01, 3.260e-02, 2.032e-02, -7.399e-02, 1.821e-02, 3.800e-02, -1.853e-02, 3.242e-02, 8.394e-02, 2.616e-02) * s[2][0][1];
	r0 += M4(8.776e-02, 4.924e-02, -2.173e-01, -1.536e-01, 8.006e-02, -6.198e-02, -4.552e-02, -6.848e-02, 9.343e-02, -6.054e-02, -2.066e-01, -6.080e-02, -5.802e-02, -6.858e-02, 1.192e-01, 7.503e-02) * s[2][1][0];
	r0 += M4(8.312e-03, -2.988e-02, 1.464e-02, -3.093e-02, -2.231e-03, -9.543e-02, 9.638e-02, -2.078e-02, 3.610e-02, -1.296e-02, -1.156e-01, -8.862e-02, -1.018e-01, -7.643e-02, 1.098e-01, 1.012e-01) * s[2][1][1];
	r0 += M4(1.946e-01, 1.654e-01, -1.507e-01, -1.519e-01, 7.007e-02, 1.630e-02, -1.466e-02, -8.745e-02, 2.893e-02, 3.134e-02, -4.663e-02, -7.794e-04, -6.268e-02, -1.838e-02, 8.374e-02, -5.383e-02) * s[2][2][0];
	r0 += M4(1.301e-01, 6.154e-02, -1.314e-01, -6.767e-02, 1.725e-01, 6.235e-02, -6.175e-02, -1.111e-01, 5.947e-02, 3.786e-02, 4.514e-03, -5.053e-02, -7.945e-02, -5.318e-02, -1.591e-02, -1.981e-02) * s[2][2][1];
	r0 += V4(5.887e-02, 4.459e-02, -4.250e-02, -4.825e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv8
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
	r0 += M4(2.082e-02, -6.038e-02, 7.206e-02, 7.984e-02, -8.121e-03, 3.460e-02, -3.522e-02, -3.066e-02, 1.054e-03, 2.004e-01, -1.971e-02, -9.973e-03, 4.066e-02, -2.892e-02, 1.377e-02, 3.571e-02) * s[0][0][0];
	r0 += M4(8.819e-02, -2.339e-01, -4.729e-03, 1.210e-01, -1.833e-02, 4.237e-02, -9.248e-03, -2.746e-02, -3.517e-03, 1.490e-02, 7.906e-03, 3.351e-03, 8.172e-03, 4.018e-03, 2.006e-02, 7.623e-02) * s[0][0][1];
	r0 += M4(1.324e-01, 1.125e-01, 2.744e-01, 3.736e-02, -3.434e-03, 1.863e-02, -7.066e-02, -6.518e-02, 5.183e-02, 2.194e-01, 1.012e-01, -1.748e-02, -6.565e-02, -1.010e-01, -4.236e-02, -3.728e-03) * s[0][1][0];
	r0 += M4(8.047e-02, 8.779e-02, 3.471e-01, 7.391e-02, 3.334e-02, 5.000e-02, -9.402e-02, -4.952e-02, -4.702e-02, 3.082e-02, 8.214e-02, -7.474e-02, -3.430e-02, -3.687e-02, -3.124e-02, -3.365e-02) * s[0][1][1];
	r0 += M4(2.076e-02, 1.777e-02, 1.832e-02, -3.881e-03, 4.236e-02, 4.236e-02, -1.194e-02, -7.187e-02, 6.238e-02, -1.180e-02, 2.803e-03, -1.510e-01, 5.125e-04, -1.188e-02, -1.797e-02, 5.060e-02) * s[0][2][0];
	r0 += M4(5.708e-02, 4.323e-02, 8.813e-03, 4.645e-02, 4.739e-02, 1.763e-02, -1.171e-02, -1.588e-03, 4.004e-02, 3.095e-02, 2.860e-02, -5.807e-02, 4.702e-02, 4.985e-02, -6.637e-03, -1.390e-02) * s[0][2][1];
	r0 += M4(1.704e-01, -2.377e-02, -8.050e-02, 2.901e-03, -1.244e-01, 4.766e-02, -1.654e-02, 1.504e-02, -2.820e-02, 3.117e-01, -3.279e-01, -1.964e-01, 1.284e-01, -7.019e-02, -5.387e-02, 1.459e-01) * s[1][0][0];
	r0 += M4(1.386e-01, -9.716e-02, -1.735e-01, 2.512e-01, -8.188e-02, -3.028e-02, 7.769e-02, -2.763e-02, -3.899e-02, -1.288e-02, 4.158e-02, -4.883e-02, 1.577e-01, -3.357e-02, -3.369e-02, -7.582e-03) * s[1][0][1];
	r0 += M4(3.329e-01, 1.394e-01, -4.284e-01, -1.925e-01, -4.776e-01, 1.106e-01, -6.325e-02, 3.050e-03, 1.156e-01, 6.895e-01, -3.357e-01, 1.830e+00, -2.568e-01, -8.892e-01, -5.254e-01, 1.234e-01) * s[1][1][0];
	r0 += M4(3.795e-01, 7.685e-04, -4.278e-01, -7.749e-01, -5.438e-01, 1.564e-01, 8.921e-02, -1.918e-01, 9.400e-02, 1.656e-01, 4.109e-02, 1.897e-02, -2.418e-01, -1.763e-01, -3.464e-01, 2.183e-01) * s[1][1][1];
	r0 += M4(-1.790e-02, -1.135e-02, -1.133e-01, 1.003e-01, -6.569e-02, 9.223e-02, 2.151e-01, -2.324e-01, 3.576e-02, -1.263e-01, -7.912e-03, -1.275e-01, -4.237e-02, 4.187e-02, 5.179e-02, -7.002e-02) * s[1][2][0];
	r0 += M4(3.921e-02, 2.204e-02, -1.254e-01, 7.318e-02, -4.145e-02, 3.552e-02, 1.626e-01, -1.978e-01, -4.798e-02, 3.549e-02, 3.739e-02, -1.636e-01, -9.155e-02, 2.523e-02, 7.996e-02, -1.135e-01) * s[1][2][1];
	r0 += M4(1.753e-02, -4.460e-03, 1.805e-02, -3.490e-02, -7.107e-04, 1.551e-02, 8.099e-03, -6.009e-04, -2.663e-02, 1.242e-01, -1.638e-01, 8.602e-03, 8.122e-02, -1.619e-01, 1.558e-01, 4.316e-02) * s[2][0][0];
	r0 += M4(2.863e-02, -3.753e-02, 2.178e-04, 5.867e-02, 4.815e-02, -1.170e-02, -9.582e-03, -9.136e-03, -1.837e-02, -5.466e-03, -9.443e-03, 1.901e-02, -7.558e-03, 2.191e-02, 7.246e-02, -6.605e-02) * s[2][0][1];
	r0 += M4(-5.586e-02, 3.038e-03, 2.242e-01, -3.382e-02, 3.210e-02, 3.519e-02, -5.329e-02, 1.235e-01, 2.636e-02, 7.932e-02, 3.381e-02, -1.198e-01, 1.059e-01, -2.228e-02, -9.757e-02, 2.906e-01) * s[2][1][0];
	r0 += M4(-1.052e-01, -3.485e-02, 2.436e-01, 4.943e-02, 1.493e-01, 1.561e-02, -2.822e-01, 1.019e-01, -6.910e-02, 1.089e-03, 1.605e-01, -1.774e-01, -8.086e-02, 4.794e-02, 1.754e-01, 2.485e-01) * s[2][1][1];
	r0 += M4(6.213e-02, 2.755e-02, -2.880e-02, 5.432e-02, 1.022e-02, -1.022e-02, 4.866e-02, -1.818e-01, 7.922e-02, -2.682e-02, -7.749e-02, 9.178e-02, 4.916e-02, 5.812e-02, 9.846e-03, -1.154e-01) * s[2][2][0];
	r0 += M4(5.090e-02, 2.550e-02, -3.225e-02, -2.918e-02, -3.530e-02, -2.827e-02, 3.770e-02, -7.253e-02, -1.615e-02, 8.941e-03, -9.144e-03, 8.824e-02, -3.871e-03, 3.357e-02, 8.765e-02, -1.580e-01) * s[2][2][1];
	r0 += V4(7.847e-03, -2.557e-02, -3.792e-03, 2.177e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-out-shuffle
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
	r0 += M4(-6.584e-02, -7.470e-03, -4.003e-02, -2.387e-02, -1.214e-02, -1.240e-03, 5.152e-03, 3.881e-03, 7.862e-02, 3.888e-03, -1.186e-01, 2.225e-02, 4.147e-02, 2.030e-02, 1.235e-02, 9.126e-03) * s[0][0][0];
	r0 += M4(-2.314e-02, 8.467e-04, -1.412e-02, -4.722e-02, 9.279e-03, 4.791e-03, 1.734e-02, -4.836e-03, 2.583e-02, -6.090e-04, -3.399e-04, 6.134e-03, -9.748e-03, 3.742e-02, 6.715e-02, 3.509e-02) * s[0][0][1];
	r0 += M4(-4.053e-02, -8.606e-02, -1.085e-02, -1.716e-02, 4.846e-02, 1.942e-02, 3.038e-02, 2.731e-02, 2.529e-01, 2.541e-01, -9.350e-02, -2.036e-01, -5.334e-04, 7.490e-03, -3.197e-03, -1.886e-02) * s[0][1][0];
	r0 += M4(-1.509e-01, -1.178e-01, 8.472e-02, 9.945e-02, 6.015e-02, 1.327e-02, 1.742e-02, 1.824e-02, 3.457e-02, 7.779e-02, -1.654e-02, -1.206e-02, -1.063e-03, -2.285e-02, -7.102e-02, -7.055e-02) * s[0][1][1];
	r0 += M4(-1.438e-02, -2.481e-02, -1.242e-02, -1.776e-02, 1.042e-02, 5.554e-02, 5.006e-04, 1.236e-02, -3.798e-02, 3.337e-02, -6.390e-02, -7.689e-02, -1.117e-02, -1.001e-02, -1.605e-03, 1.308e-03) * s[0][2][0];
	r0 += M4(-2.018e-02, -8.457e-02, -3.222e-02, -2.592e-02, 1.898e-02, 5.881e-02, 4.304e-03, 1.067e-02, -3.236e-02, -4.917e-02, -3.440e-03, -6.349e-03, -1.236e-02, 3.997e-02, -2.508e-02, 5.920e-03) * s[0][2][1];
	r0 += M4(-2.883e-02, -2.980e-03, -8.857e-02, -4.520e-03, 8.075e-02, -1.059e-02, -2.045e-02, -2.650e-02, 3.623e-02, 2.057e-02, -3.652e-02, -3.930e-03, 9.790e-02, 2.228e-02, 9.662e-02, 3.235e-02) * s[1][0][0];
	r0 += M4(2.961e-02, -2.227e-02, -3.037e-01, -2.632e-02, 1.051e-02, 4.328e-02, -7.056e-02, 1.224e-02, 2.046e-02, 1.819e-02, -8.566e-03, -2.142e-02, 1.559e-01, -6.113e-02, -3.170e-02, -4.644e-02) * s[1][0][1];
	r0 += M4(1.763e-01, 1.419e-02, 1.340e-01, -4.910e-02, -3.940e-01, -8.674e-02, -2.033e-01, -1.031e-01, 2.181e-01, 1.067e-01, 1.233e-01, 2.290e-02, 6.967e-02, 1.538e-01, 5.333e-02, 1.188e-01) * s[1][1][0];
	r0 += M4(3.871e-01, 2.838e-01, -2.432e-02, -3.760e-01, -2.376e-01, -1.730e-01, -6.222e-02, -1.468e-01, 1.789e-01, 3.982e-02, 2.609e-01, 1.567e-01, -2.304e-01, 4.635e-01, 5.789e-02, 3.473e-01) * s[1][1][1];
	r0 += M4(-3.305e-02, 1.035e-01, -5.100e-02, 4.325e-02, 1.443e-02, -1.098e-02, 1.069e-02, 1.121e-02, -2.304e-02, 1.184e-01, -7.953e-02, 5.386e-03, 2.966e-03, -1.553e-02, -7.291e-03, -8.221e-03) * s[1][2][0];
	r0 += M4(-2.415e-02, 1.304e-01, -5.214e-02, 2.497e-02, 2.616e-02, -8.130e-02, 4.114e-02, 3.673e-02, -1.876e-02, 1.256e-01, -7.115e-02, 4.628e-02, 1.111e-01, -1.199e-01, 6.996e-02, -3.821e-02) * s[1][2][1];
	r0 += M4(6.941e-02, 5.046e-03, 1.031e-01, 2.648e-02, 7.364e-02, 9.667e-03, 1.567e-01, 1.736e-02, 4.839e-03, 1.392e-03, 9.905e-02, 2.801e-02, 1.640e-02, 5.687e-03, 4.543e-02, 8.165e-03) * s[2][0][0];
	r0 += M4(-3.128e-03, -9.581e-03, 1.932e-01, 3.364e-02, 5.286e-02, 7.603e-03, 1.218e-01, 4.438e-02, 4.275e-02, -4.364e-03, 8.911e-02, 2.460e-02, 8.262e-03, -4.096e-02, 1.265e-01, -5.310e-02) * s[2][0][1];
	r0 += M4(-3.033e-02, 8.439e-02, -2.073e-02, 6.307e-02, -4.113e-02, 6.764e-02, -2.104e-01, 7.651e-02, -4.406e-02, 2.552e-03, -8.595e-03, 9.355e-02, 7.918e-03, 7.033e-03, 2.009e-02, 6.532e-02) * s[2][1][0];
	r0 += M4(-9.204e-02, -3.004e-02, -7.831e-02, 1.510e-01, 2.704e-02, 5.926e-02, -1.006e-01, 3.503e-02, -1.014e-02, 5.774e-02, -2.989e-02, 3.783e-02, -3.359e-02, 6.363e-03, -2.451e-01, 1.679e-01) * s[2][1][1];
	r0 += M4(-7.888e-04, -4.455e-02, -6.315e-03, 4.074e-03, -5.879e-03, 3.702e-03, 2.548e-03, 2.888e-02, -6.862e-03, -3.462e-02, 2.690e-02, 6.049e-03, -1.946e-04, -9.491e-03, 7.599e-04, -2.821e-02) * s[2][2][0];
	r0 += M4(1.129e-02, -4.578e-02, 4.333e-02, -3.821e-02, 1.797e-02, 9.460e-03, 1.940e-02, -5.858e-02, -3.272e-03, -1.530e-02, -4.263e-03, 1.210e-02, 2.850e-02, 5.385e-02, 7.153e-02, 2.934e-04) * s[2][2][1];
	r0 += V4(-1.440e-03, -9.481e-04, -7.401e-04, -1.238e-04);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

// CuNNy 2x4C
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

//!DESC CuNNy-2x4C-EASU
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


//!DESC CuNNy-2x4C-in
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
	r0 += V4(3.464e-01, -3.397e-03, -3.699e-02, -1.526e-03) * s[0][0][0];
	r0 += V4(3.516e-01, -2.238e-02, 2.740e-02, 8.336e-04) * s[0][1][0];
	r0 += V4(-1.057e-01, 2.683e-02, -8.420e-02, -1.131e-02) * s[0][2][0];
	r0 += V4(-3.101e-03, -6.230e-01, -1.959e-01, -4.247e-02) * s[1][0][0];
	r0 += V4(-1.982e-01, 6.660e-01, 5.090e-01, 6.390e-01) * s[1][1][0];
	r0 += V4(5.087e-02, -4.797e-02, 1.567e-01, -1.100e-02) * s[1][2][0];
	r0 += V4(-3.457e-01, 6.909e-02, -1.946e-02, 5.310e-02) * s[2][0][0];
	r0 += V4(-1.704e-01, -8.026e-02, -1.343e-01, -6.621e-01) * s[2][1][0];
	r0 += V4(7.390e-02, 1.386e-02, -4.531e-02, 3.054e-02) * s[2][2][0];
	r0 += V4(-3.517e-03, -2.146e-03, -2.680e-02, 1.334e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-conv1
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
	r0 += M4(1.149e-01, -5.461e-02, -4.386e-03, 3.485e-02, -1.528e-01, 8.280e-02, -6.913e-02, 1.342e-01, 2.803e-01, -5.414e-02, 1.666e-01, -1.265e-01, 3.151e-02, -1.353e-01, -8.087e-02, 2.300e-01) * s[0][0][0];
	r0 += M4(7.579e-02, -2.360e-02, 1.947e-02, -1.947e-02, -1.897e-01, 1.560e-01, 1.281e-01, -6.435e-02, 5.171e-01, -1.167e-01, -3.350e-01, 9.637e-02, -5.712e-02, -6.291e-02, -1.148e-01, -1.840e-01) * s[0][0][1];
	r0 += M4(-1.255e-01, 1.084e-01, -3.713e-02, 2.069e-02, 1.318e-01, -3.076e-01, -9.628e-02, 2.053e-01, -1.846e-01, 1.841e-01, -3.933e-02, -1.893e-01, 1.086e+00, -2.624e-01, 3.859e-01, -8.925e-02) * s[0][1][0];
	r0 += M4(-8.896e-02, -2.345e-02, -1.808e-02, 7.632e-02, -3.154e-02, -1.545e-01, -2.324e-01, -4.164e-03, 2.755e-02, -2.154e-01, -1.136e-02, -4.723e-02, 2.859e-02, 1.167e-02, 1.890e-01, -5.176e-01) * s[0][1][1];
	r0 += M4(2.808e-02, 3.029e-02, -5.025e-03, 7.845e-02, 1.092e-01, -3.462e-02, 3.198e-02, -2.916e-01, -4.256e-02, -8.527e-02, -1.168e-01, 1.960e-01, 2.502e-01, 4.600e-01, 2.536e-01, -7.160e-02) * s[0][2][0];
	r0 += M4(2.150e-03, 4.859e-02, 2.196e-02, -8.913e-02, -5.343e-03, -3.878e-02, -7.302e-02, -1.438e-01, -1.606e-01, -8.937e-02, -2.354e-01, 3.168e-02, 1.055e-02, -1.026e-01, 1.375e-01, 2.175e-02) * s[0][2][1];
	r0 += M4(-1.644e-01, 1.284e-01, -5.493e-03, 7.167e-02, 2.751e-02, -4.478e-02, 4.476e-02, 5.645e-02, -2.391e-01, -6.767e-02, -7.910e-02, -1.005e-01, -4.609e-01, 2.531e-01, 7.024e-03, 3.089e-01) * s[1][0][0];
	r0 += M4(-1.840e-01, 9.202e-02, -4.666e-02, 1.252e-02, 8.185e-02, -2.569e-02, 2.452e-01, -2.798e-01, -5.039e-01, -1.054e-01, -4.288e-01, 6.855e-01, 3.398e-02, 7.173e-01, 5.670e-02, 1.287e-01) * s[1][0][1];
	r0 += M4(2.188e-01, -2.150e-01, -1.164e-01, -2.065e-01, -5.954e-01, 3.054e-01, -1.314e-01, 6.402e-01, -2.206e-01, 3.182e-01, -2.489e-01, 2.233e-01, -2.192e-01, -1.934e-01, 1.985e-01, -2.242e-01) * s[1][1][0];
	r0 += M4(5.431e-02, -3.315e-01, -8.081e-02, 5.962e-02, -5.067e-01, 6.035e-01, -7.520e-01, 3.134e-01, 2.938e-01, 1.558e+00, 7.056e-01, 3.313e-01, 4.385e-01, -2.549e-01, 3.683e-01, 4.654e-01) * s[1][1][1];
	r0 += M4(-5.032e-02, -4.688e-01, -8.066e-01, 1.563e-01, 3.430e-01, -3.174e-01, 2.568e-01, -7.026e-01, -5.067e-02, 1.657e-01, 9.934e-02, 1.465e-01, -9.289e-02, 1.662e-01, 1.411e-01, -2.637e-01) * s[1][2][0];
	r0 += M4(-6.030e-02, 3.217e-01, 7.530e-02, -6.363e-02, 1.622e-01, -4.088e-01, 4.245e-01, -1.793e-01, -1.270e-01, -3.603e-02, 4.972e-02, -1.417e-01, 7.154e-02, -4.811e-01, -2.502e-02, 3.520e-01) * s[1][2][1];
	r0 += M4(1.266e-02, 1.503e-02, 1.942e-02, 2.135e-02, 5.793e-02, -6.336e-02, -1.076e-01, 5.892e-02, 1.147e-01, -9.805e-02, 1.404e-01, -6.146e-02, 4.383e-02, 1.909e-01, 3.431e-01, -1.878e-02) * s[2][0][0];
	r0 += M4(2.563e-02, 9.283e-02, 4.698e-02, 4.795e-02, 1.746e-01, -1.836e-02, -8.267e-02, -1.283e-01, -2.443e-01, -1.340e-01, 9.360e-02, 1.466e-01, 5.137e-01, 2.913e-01, 2.804e-01, -6.702e-02) * s[2][0][1];
	r0 += M4(-2.759e-01, -2.722e-01, -5.490e-01, 2.654e-02, 2.588e-01, -3.233e-01, 4.033e-01, -1.125e-01, 2.502e-01, -8.911e-02, 6.409e-02, -1.871e-01, 3.298e-02, 3.331e-02, -2.288e-02, 4.719e-02) * s[2][1][0];
	r0 += M4(-6.707e-01, -5.046e-01, -4.092e-01, 3.647e-02, 4.276e-01, 7.190e-02, 6.230e-01, -1.293e-01, 3.555e-02, 2.454e-01, 1.392e-01, -6.036e-01, 3.135e-01, 2.266e-01, 2.014e-01, 2.495e-01) * s[2][1][1];
	r0 += M4(1.773e-01, 1.018e-01, 1.144e-01, -6.201e-02, 1.570e-01, 8.463e-02, -1.280e-01, -4.507e-01, 5.612e-02, -2.316e-01, 2.708e-02, 1.338e-01, -1.722e-01, 4.390e-02, -7.613e-02, 1.849e-02) * s[2][2][0];
	r0 += M4(-4.493e-02, 1.620e-01, 4.238e-03, -3.818e-01, 1.353e-01, -1.801e-01, 2.127e-01, 5.338e-02, 1.123e-01, -3.329e-01, -2.763e-01, -1.493e-04, -8.969e-02, 5.435e-02, 2.220e-01, 1.587e-01) * s[2][2][1];
	r0 += V4(5.269e-03, -8.997e-03, -1.448e-02, 5.661e-05);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-conv2
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
	r0 += M4(1.388e-02, 5.243e-02, 2.669e-02, -7.145e-03, -1.287e-02, 2.055e-01, -4.116e-03, -1.386e-01, 5.129e-02, 9.874e-02, 3.278e-01, -1.005e-01, -1.665e-02, -4.162e-02, -2.105e-02, 8.209e-02) * s[0][0][0];
	r0 += M4(3.461e-02, 1.695e-01, -7.470e-02, 1.937e-01, 3.051e-02, 2.259e-02, 4.836e-02, -7.634e-02, 4.292e-02, -1.779e-02, 7.477e-02, -3.232e-02, 5.738e-04, 7.260e-02, -6.924e-02, 1.198e-02) * s[0][0][1];
	r0 += M4(3.489e-02, 8.083e-03, -7.360e-02, -1.309e-02, 2.698e-02, 2.023e-01, -7.527e-02, 4.272e-02, 4.404e-01, -2.378e-01, 4.643e-01, -1.967e-01, -3.731e-02, 1.149e-02, -4.939e-02, -4.896e-02) * s[0][1][0];
	r0 += M4(5.779e-01, 6.609e-01, 2.716e-02, 7.506e-02, 1.825e-01, -1.053e-01, -9.287e-02, -6.334e-02, 1.061e-01, 1.419e-02, 1.108e-02, -6.047e-02, 1.394e-01, -2.846e-01, 3.329e-01, -6.989e-02) * s[0][1][1];
	r0 += M4(1.091e-01, 1.673e-02, 5.915e-02, 4.186e-03, -2.555e-03, 6.097e-02, -2.197e-01, -1.290e-02, 1.250e-01, 4.287e-02, -5.154e-02, -9.023e-02, -5.092e-02, -1.025e-01, 1.202e-01, 1.264e-02) * s[0][2][0];
	r0 += M4(-1.215e-01, 3.990e-01, -5.918e-01, 1.694e-01, 1.086e-01, 9.402e-02, 1.423e-01, 2.782e-02, 8.759e-02, -4.286e-02, 5.462e-02, 3.781e-02, 7.359e-02, -8.177e-02, 8.057e-02, 1.708e-03) * s[0][2][1];
	r0 += M4(7.064e-02, 9.747e-02, 7.151e-02, 6.207e-03, 6.033e-02, -2.007e-01, 3.467e-01, -5.129e-01, -1.315e-02, -7.788e-02, 2.072e-01, -3.750e-01, 5.498e-02, 5.875e-02, -8.819e-03, 3.718e-02) * s[1][0][0];
	r0 += M4(2.782e-02, 7.202e-02, 1.694e-01, -1.252e-02, 6.736e-02, -1.292e-01, -3.426e-02, -2.286e-01, -9.691e-02, 5.315e-02, 1.489e-01, 1.782e-01, -1.890e-02, 5.089e-02, 3.067e-03, -1.329e+00) * s[1][0][1];
	r0 += M4(-3.128e-01, 9.496e-02, -3.229e-01, 1.544e-03, 2.072e-01, -6.930e-02, -1.673e-01, 9.201e-02, -1.019e+00, 2.486e-01, 2.853e-01, -4.875e-01, 1.909e-01, 2.762e-02, -5.371e-01, 6.787e-03) * s[1][1][0];
	r0 += M4(1.214e-01, -2.279e-01, -1.046e-01, -4.399e-02, 3.356e-01, -7.358e-01, 8.459e-02, -4.780e-01, -3.057e-02, -1.275e-01, 2.495e-01, -2.881e-01, 2.841e-01, 2.781e-02, 4.861e-02, -8.146e-03) * s[1][1][1];
	r0 += M4(-1.811e-01, 1.320e-01, -2.890e-01, 1.392e-01, 1.070e-01, -9.156e-02, 1.680e-02, 3.080e-02, 1.246e-01, -1.348e-01, 1.080e-01, -1.381e-01, 1.196e-01, -1.789e-01, 4.849e-01, 6.279e-02) * s[1][2][0];
	r0 += M4(-1.941e-02, 7.148e-02, -7.349e-02, 4.259e-02, -3.029e-02, -1.955e-01, 1.165e-01, 1.899e-01, 4.970e-02, -4.399e-02, 8.435e-03, -4.364e-02, -3.998e-02, -5.059e-02, -5.765e-02, -5.864e-02) * s[1][2][1];
	r0 += M4(3.397e-03, -8.042e-02, 1.157e-01, -1.397e-01, 2.996e-02, 3.989e-02, -9.670e-02, -8.536e-02, 3.910e-02, -3.272e-01, 6.674e-02, -3.408e-02, 4.114e-02, -6.623e-02, 1.294e-01, -9.368e-02) * s[2][0][0];
	r0 += M4(1.459e-02, -5.014e-02, 1.099e-01, -1.177e-02, -2.570e-02, 9.959e-02, -8.849e-02, 5.216e-02, 3.234e-02, -9.265e-02, 9.276e-02, -9.200e-02, 1.875e-02, -9.326e-02, -1.200e-02, -1.448e-01) * s[2][0][1];
	r0 += M4(7.172e-02, -2.882e-02, -1.831e-01, 1.819e-01, -4.541e-02, 1.426e-01, -5.110e-02, 1.053e-01, 8.559e-02, -4.219e-01, 6.653e-02, -3.038e-01, -7.122e-02, 3.888e-01, -3.578e-02, 1.232e-01) * s[2][1][0];
	r0 += M4(-3.095e-02, 1.756e-01, -1.797e-01, 1.404e-01, -7.294e-02, 3.096e-01, -7.898e-02, 2.006e-01, 8.400e-02, -2.835e-01, 1.010e-01, -1.753e-01, -1.742e-02, 6.511e-02, -9.089e-02, 1.651e-01) * s[2][1][1];
	r0 += M4(4.788e-03, -2.549e-02, 3.264e-02, 8.373e-04, -4.241e-02, 8.294e-02, -1.672e-03, -1.527e-02, -2.606e-02, -5.074e-02, 1.023e-01, -6.471e-02, 6.195e-03, 1.318e-01, 6.262e-02, -5.720e-02) * s[2][2][0];
	r0 += M4(-4.493e-02, 7.108e-02, -4.294e-02, -2.510e-02, -3.211e-02, 1.470e-01, -3.846e-02, 7.704e-02, 4.358e-02, -9.067e-02, 5.894e-02, 1.551e-03, -1.079e-02, 1.381e-01, -5.890e-02, 4.734e-02) * s[2][2][1];
	r0 += V4(-1.899e-03, -3.680e-03, 1.934e-03, -2.038e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv2
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
#define l0(x, y) V4(conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv2_pt))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(-3.852e-03, 1.365e-02, 2.402e-02, -1.051e-02, -2.576e-02, -1.819e-02, -2.777e-02, 1.694e-02, -5.213e-02, -1.172e-03, 1.747e-02, 4.630e-02, -1.369e-02, -1.847e-03, 5.421e-03, 6.388e-03) * s[0][0][0];
	r0 += M4(-1.229e-02, 3.145e-03, 1.171e-02, -2.590e-03, 1.268e-01, -5.699e-02, -1.430e-01, -4.780e-03, -1.512e-02, -1.285e-04, 2.174e-02, 2.763e-02, -6.759e-03, -2.740e-02, -1.055e-02, 3.939e-02) * s[0][0][1];
	r0 += M4(-2.716e-02, -1.046e-02, 6.746e-02, 8.517e-02, -2.990e-04, 4.139e-02, -1.066e-02, -3.945e-02, 4.223e-02, 9.301e-02, 1.329e-02, 4.633e-02, 4.962e-02, 1.312e-02, 6.647e-02, -3.351e-03) * s[0][1][0];
	r0 += M4(-1.400e-02, -1.852e-02, -3.333e-02, -1.252e-02, 1.012e-01, 3.076e-01, -1.597e-01, -2.407e-01, 2.631e-02, 9.076e-03, 3.616e-02, 1.413e-02, -1.382e-01, 1.243e-01, 1.110e-01, -3.035e-03) * s[0][1][1];
	r0 += M4(4.165e-02, 8.238e-03, -2.595e-02, -7.335e-03, 1.937e-02, -1.021e-02, 1.566e-02, 1.995e-02, 2.880e-04, -5.803e-02, 1.870e-02, -5.648e-03, -2.072e-03, -1.787e-02, 3.827e-02, 7.037e-02) * s[0][2][0];
	r0 += M4(1.531e-02, -5.794e-04, 2.014e-02, 9.268e-03, -5.828e-04, -1.175e-02, 6.864e-02, 4.356e-02, 3.284e-03, 3.891e-03, -6.235e-04, 1.423e-02, 2.376e-02, -4.595e-03, -2.749e-02, 6.561e-02) * s[0][2][1];
	r0 += M4(2.529e-01, -4.691e-02, -3.057e-01, -1.335e-01, 1.517e-03, -1.575e-02, -3.733e-02, -7.253e-02, 3.985e-01, -1.086e-01, 1.189e-01, -8.082e-02, 1.862e-02, -6.831e-03, -1.136e-02, -1.604e-02) * s[1][0][0];
	r0 += M4(6.391e-03, -1.609e-02, -7.554e-02, -3.970e-02, -4.404e-01, -4.212e-02, 2.097e-01, -5.753e-03, 6.088e-02, 9.978e-03, -3.601e-02, -3.674e-02, 2.080e-01, -1.616e-01, 1.987e-01, -1.482e-01) * s[1][0][1];
	r0 += M4(4.852e-01, 8.067e-01, -4.043e-02, -1.458e-01, -1.012e-01, -4.042e-02, -1.761e-02, 8.266e-02, -7.805e-01, 4.758e-01, -3.037e-01, 2.644e-01, 4.923e-02, 7.136e-02, -2.894e-02, 4.203e-02) * s[1][1][0];
	r0 += M4(1.571e-01, 1.665e-01, 2.008e-01, 1.084e-01, -4.092e-01, -7.637e-01, 4.913e-01, 4.990e-01, -1.742e-01, -8.241e-02, -9.530e-02, -3.308e-02, -5.566e-01, 6.074e-01, -7.692e-01, 5.020e-01) * s[1][1][1];
	r0 += M4(-5.897e-02, -7.140e-02, 6.654e-02, 1.404e-02, 3.137e-02, 4.115e-02, 2.972e-02, 2.639e-02, 1.908e-01, -8.226e-02, 4.911e-02, -7.827e-02, 2.719e-02, -1.827e-02, -3.623e-02, -1.577e-01) * s[1][2][0];
	r0 += M4(-1.360e-02, -2.365e-02, -2.747e-02, 1.363e-02, -1.980e-02, -1.302e-02, -6.822e-02, 1.567e-01, 4.724e-02, 1.934e-02, 2.421e-02, -2.714e-02, 1.411e-01, -3.721e-01, 1.629e-01, -3.848e-01) * s[1][2][1];
	r0 += M4(-6.518e-01, -5.069e-02, 5.949e-01, 8.150e-02, -3.037e-03, 9.708e-04, 1.195e-02, 2.825e-02, -4.966e-02, -9.013e-03, 2.002e-01, -6.198e-02, -1.188e-02, 4.562e-03, -4.032e-03, 1.793e-03) * s[2][0][0];
	r0 += M4(-2.179e-02, 5.419e-03, 9.225e-03, 2.033e-02, 5.460e-02, -3.095e-02, 1.843e-02, 3.286e-02, -1.813e-02, -7.531e-03, 3.600e-02, 9.939e-03, 3.522e-03, 5.814e-02, -3.699e-03, -3.686e-02) * s[2][0][1];
	r0 += M4(-4.034e-01, -8.809e-01, 3.975e-01, 9.842e-01, 2.249e-02, 1.774e-02, -9.992e-02, -8.325e-02, 2.896e-02, 6.982e-02, -4.443e-01, 3.369e-01, 5.621e-03, -1.401e-02, 4.838e-02, 5.079e-03) * s[2][1][0];
	r0 += M4(7.807e-03, -2.690e-02, -8.423e-02, -5.035e-02, 8.810e-02, 1.447e-01, -2.764e-01, -2.457e-01, 1.837e-02, -2.234e-03, -5.384e-02, -3.959e-02, -2.304e-02, -7.351e-02, -4.449e-02, 1.761e-01) * s[2][1][1];
	r0 += M4(3.026e-02, -4.293e-02, 1.805e-02, -3.551e-02, -4.728e-03, 1.628e-02, 2.174e-02, 2.335e-02, -2.894e-02, -2.135e-02, 1.392e-01, -3.884e-02, -1.188e-02, -2.020e-02, -1.930e-02, -3.044e-03) * s[2][2][0];
	r0 += M4(6.485e-04, -4.635e-03, 1.386e-02, -4.759e-02, -6.193e-03, 8.025e-03, 3.475e-02, -1.715e-02, -1.003e-02, 1.260e-02, 1.298e-02, 4.156e-02, 6.825e-03, 5.280e-02, 2.117e-02, -1.339e-02) * s[2][2][1];
	r0 += V4(6.502e-05, -1.302e-04, 3.004e-04, 5.779e-05);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

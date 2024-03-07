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
	r += V4(7.551e-02, 2.417e-01, -2.726e-02, -7.518e-02) * s0[y+0][x+0];
	r += V4(-6.113e-01, -1.488e-01, 2.529e-01, 1.274e-01) * s0[y+0][x+1];
	r += V4(3.663e-01, 6.904e-02, -1.358e-01, -4.513e-02) * s0[y+0][x+2];
	r += V4(-7.559e-02, 2.358e-01, 1.978e-01, 5.454e-01) * s0[y+1][x+0];
	r += V4(2.939e-01, -5.605e-01, 6.965e-01, -2.643e-01) * s0[y+1][x+1];
	r += V4(-3.395e-02, -1.473e-01, -2.129e-01, -2.003e-02) * s0[y+1][x+2];
	r += V4(1.319e-02, 2.064e-01, -1.733e-01, 5.086e-02) * s0[y+2][x+0];
	r += V4(-2.044e-02, -8.835e-02, -2.237e-01, -8.351e-02) * s0[y+2][x+1];
	r += V4(-5.034e-03, 9.487e-02, -8.130e-02, 2.427e-01) * s0[y+2][x+2];
	r += V4(-4.408e-03, 4.194e-03, -5.285e-02, -2.938e-02);
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
	r += M4(-8.231e-02, 1.085e-02, -6.137e-02, 1.528e-01, 8.714e-02, -1.260e-01, 3.217e-02, 5.803e-02, 3.821e-02, -8.820e-02, -2.153e-01, -5.347e-01, 2.355e-01, 1.916e-02, -5.638e-02, 4.446e-01) * s0[y+0][x+0];
	r += M4(-8.279e-02, -1.472e-01, -4.129e-01, -1.334e-01, 9.322e-03, 1.856e+00, 1.616e-01, 4.612e-01, -1.008e-01, -3.375e-01, 1.293e-01, -5.979e-01, 6.210e-02, -4.615e-02, 1.419e-01, 6.371e-02) * s0[y+0][x+1];
	r += M4(-2.297e-02, -1.665e-01, 1.303e-01, -2.250e-01, -1.677e-02, 1.071e-01, -5.787e-01, 8.004e-02, 4.924e-02, -3.164e-01, 2.227e-01, -3.291e-01, 5.587e-02, -1.896e-01, -2.200e-01, -7.303e-02) * s0[y+0][x+2];
	r += M4(-3.992e-02, -1.877e-01, 3.669e-03, -3.120e-01, -5.527e-01, 1.714e-01, 2.639e-01, -3.349e-01, -2.768e-02, 2.899e-02, 1.812e-01, -3.021e-01, 1.016e-01, -1.267e-01, -2.534e-01, 8.274e-02) * s0[y+1][x+0];
	r += M4(-3.380e-02, -1.599e-02, -7.621e-01, 7.195e-01, -7.068e-02, 6.422e-02, 1.800e-01, 2.381e-02, 2.571e-02, -2.119e-01, -4.161e-01, 5.526e-01, 8.135e-01, 1.291e-01, 1.166e-01, -8.657e-02) * s0[y+1][x+1];
	r += M4(-9.305e-03, -3.270e-01, -7.323e-01, -3.547e-01, -1.045e-01, 1.773e-01, -5.569e-01, 2.709e-01, -9.385e-02, -2.963e-03, 3.994e-03, -7.302e-02, -8.263e-02, -1.631e-01, 1.768e-01, 1.175e-01) * s0[y+1][x+2];
	r += M4(-2.603e-02, 3.232e-02, 6.909e-03, -8.809e-03, -4.683e-02, -1.306e-02, -1.159e-01, -1.881e-01, -1.036e-01, -1.052e-03, -1.219e-01, -4.519e-02, 2.643e-01, -3.294e-02, 6.246e-02, 1.291e-01) * s0[y+2][x+0];
	r += M4(-7.256e-02, -1.096e-01, -3.873e-03, -5.780e-01, 1.671e-01, 4.367e-02, -8.133e-02, -2.350e-01, 2.920e-01, 2.274e-02, 2.134e-01, -1.080e-01, -5.533e-02, -1.483e-01, -6.528e-02, 2.217e-01) * s0[y+2][x+1];
	r += M4(-1.777e-01, -5.669e-02, -2.932e-01, -1.918e-01, 3.972e-02, -4.560e-02, -1.391e-01, 3.420e-02, -9.706e-02, -1.160e-01, -9.106e-02, 7.367e-02, -5.710e-02, -4.359e-02, -3.099e-03, -1.230e-01) * s0[y+2][x+2];
	r += M4(5.070e-02, 1.691e-01, -1.707e-02, 3.170e-02, 7.885e-02, -5.609e-02, -2.676e-02, -1.118e-01, 1.692e-02, -1.004e-01, -1.871e-01, -6.348e-01, 1.722e-01, -7.630e-02, -1.720e-01, 4.512e-01) * s1[y+0][x+0];
	r += M4(-3.642e-02, -7.437e-02, -3.574e-01, -4.112e-01, -8.032e-02, 1.091e-01, 1.197e-01, 2.892e-01, -1.450e-01, -1.388e+00, -9.865e-03, -5.058e-01, 9.827e-02, 1.224e-01, 5.332e-01, -3.481e-01) * s1[y+0][x+1];
	r += M4(2.806e-02, -1.655e-01, 2.368e-01, -2.262e-01, -5.514e-02, 1.013e-01, -5.014e-01, 2.305e-01, 6.457e-03, -3.187e-01, 1.838e-01, -3.686e-01, 1.174e-01, -6.006e-01, -5.023e-02, -3.165e-02) * s1[y+0][x+2];
	r += M4(4.542e-02, -4.567e-02, -1.329e-01, -2.607e-01, -2.207e-01, 1.858e-01, 2.939e-01, -1.616e-01, 1.486e-01, 3.520e-03, 1.695e-01, -3.070e-01, 2.491e-02, -1.293e-01, -3.163e-01, -2.077e-01) * s1[y+1][x+0];
	r += M4(4.213e-02, 3.291e-01, 2.378e-01, 7.166e-01, -1.680e-01, -1.692e-02, -1.505e-01, -1.469e-01, 3.411e-02, -1.706e-01, -1.372e-01, 6.842e-01, 7.888e-01, 1.455e-01, 1.801e-01, -4.461e-01) * s1[y+1][x+1];
	r += M4(2.527e-02, -1.845e-01, 1.694e-01, -1.619e-01, -2.838e-02, 1.548e-01, -6.449e-01, 6.954e-02, -9.783e-02, -2.179e-02, -5.205e-01, -2.350e-01, -4.501e-02, -3.077e-01, 5.417e-01, 9.398e-01) * s1[y+1][x+2];
	r += M4(1.949e-02, 9.733e-02, -3.101e-02, -3.260e-02, -2.220e-02, -3.760e-03, -3.301e-02, -1.431e-01, -3.853e-02, -1.956e-02, -1.508e-01, -1.504e-01, 2.253e-01, -6.686e-02, 4.210e-02, 5.775e-02) * s1[y+2][x+0];
	r += M4(-3.625e-02, 1.561e-02, 3.493e-01, -1.600e-01, 1.906e-01, 6.179e-02, 9.842e-02, -3.748e-01, 2.910e-01, 2.531e-02, 2.621e-01, -4.955e-02, -1.434e-04, -1.069e-01, -2.107e-01, 2.597e-01) * s1[y+2][x+1];
	r += M4(-1.793e-01, 9.097e-03, -1.153e-01, -6.023e-02, 5.920e-02, -4.619e-02, -7.580e-03, 9.501e-02, -5.861e-02, -1.304e-01, -1.445e-01, 1.307e-01, -4.819e-02, 2.908e-02, 4.348e-02, 4.136e-02) * s1[y+2][x+2];
	r += V4(4.147e-02, 5.582e-01, -1.691e-02, -5.258e-02);
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
	r += M4(6.042e-02, 1.756e-02, -3.152e-02, 6.374e-02, -5.287e-02, 3.196e-02, -1.006e-02, 4.523e-02, 1.588e-03, -2.239e-02, -7.948e-03, -1.918e-02, -1.526e-03, 5.622e-02, 1.162e-02, -4.223e-02) * s0[y+0][x+0];
	r += M4(3.505e-03, -6.755e-02, 1.552e-01, -1.535e-01, -2.027e-02, -7.940e-03, 7.116e-03, -4.495e-03, 1.144e-02, -1.736e-01, 4.544e-02, 2.045e-01, 2.093e-01, -3.160e-02, -3.283e-02, -1.068e-01) * s0[y+0][x+1];
	r += M4(4.654e-02, -4.248e-02, -1.646e-01, 1.842e-01, 9.570e-02, -1.514e-01, 2.243e-02, -1.199e-01, 2.026e-01, -1.835e-01, 3.408e-02, 1.617e-02, -1.567e-01, 2.287e-01, -6.237e-02, 2.332e-01) * s0[y+0][x+2];
	r += M4(-1.150e-01, 2.969e-02, -7.484e-02, 3.005e-02, 1.039e-01, -5.083e-02, -1.215e-02, 2.400e-02, 1.123e-01, -1.363e-01, 5.527e-01, -2.841e-02, -4.163e-02, -4.479e-02, -2.151e-02, 4.718e-02) * s0[y+1][x+0];
	r += M4(1.154e-01, 4.847e-02, -8.799e-02, -9.450e-02, 2.564e-01, -1.663e-01, -5.105e-02, -2.350e-02, -4.483e-01, -8.630e-02, 1.130e-01, 1.227e-01, -1.230e+00, 7.410e-01, 1.948e-01, -3.838e-01) * s0[y+1][x+1];
	r += M4(4.089e-02, -2.839e-02, 3.419e-01, -3.901e-01, -2.161e-01, 1.454e-01, -5.253e-02, 1.555e-01, -3.914e-02, -5.863e-02, 6.657e-02, 4.291e-02, -9.949e-02, -1.407e-02, 4.420e-02, 3.329e-01) * s0[y+1][x+2];
	r += M4(4.506e-02, -2.312e-02, 1.278e-01, -2.482e-03, -7.779e-03, -1.556e-02, -4.651e-03, -1.014e-01, 1.046e-01, -2.945e-01, -1.077e-01, 3.623e-01, -7.403e-02, -8.948e-02, -1.834e-01, 1.670e-01) * s0[y+2][x+0];
	r += M4(-9.847e-02, 4.656e-02, -2.007e-01, -1.098e-02, -1.593e-01, 2.155e-01, 4.104e-02, -4.717e-01, 8.675e-04, -5.098e-01, -3.226e-01, 2.027e-01, 2.801e-01, 8.288e-02, 5.069e-01, 9.268e-02) * s0[y+2][x+1];
	r += M4(-3.533e-02, 1.193e-01, -1.057e-01, 1.411e-01, 6.163e-02, 1.534e-01, -6.305e-04, 2.498e-01, 7.585e-03, 1.252e-01, 7.348e-02, -4.287e-01, 5.924e-02, -3.238e-01, 8.091e-02, -1.743e-01) * s0[y+2][x+2];
	r += M4(3.811e-02, -1.563e-01, -1.042e-01, -1.805e-01, 5.869e-01, -4.584e-01, 2.460e-01, -4.277e-01, 1.449e-01, -8.970e-02, -6.552e-02, -1.153e-01, 1.038e-01, -9.950e-02, 4.598e-02, -1.259e-02) * s1[y+0][x+0];
	r += M4(1.985e-01, 3.349e-01, -3.523e-01, -2.414e-01, -4.728e-01, -3.835e-01, 2.153e-01, -3.502e-01, 1.223e-01, -7.373e-02, -6.988e-02, 7.345e-02, 1.052e-01, -1.929e-01, -2.430e-02, -1.201e-01) * s1[y+0][x+1];
	r += M4(-1.336e-01, 2.846e-01, -2.575e-01, -7.068e-01, 1.249e-01, -4.403e-01, 1.145e-02, -2.000e-01, -1.054e-03, 1.959e-02, -1.222e-02, 5.923e-02, 1.272e-01, -1.370e-02, 2.920e-03, 1.466e-01) * s1[y+0][x+2];
	r += M4(-6.194e-01, 2.690e-01, -1.019e-01, -4.941e-01, -1.011e-01, -1.218e-01, -5.433e-01, -5.804e-01, 2.646e-01, -9.937e-02, 3.545e-01, -3.683e-01, 3.647e-02, -1.313e-01, -3.839e-02, 2.046e-01) * s1[y+1][x+0];
	r += M4(-8.798e-01, 6.420e-01, 1.899e+00, -8.175e-04, -1.927e+00, -1.315e+00, -4.580e-01, 3.704e-01, 2.470e-02, -2.976e-01, 9.923e-02, 5.042e-01, -9.446e-01, 2.647e-01, 4.992e-02, -5.944e-01) * s1[y+1][x+1];
	r += M4(-2.620e+00, -1.127e+00, 2.165e+00, -1.507e-01, -3.809e-01, 2.881e-01, -5.009e-01, -1.733e+00, -3.800e-02, 1.145e-01, 3.411e-02, 6.417e-02, 1.911e-01, -5.254e-01, 9.449e-02, 5.326e-02) * s1[y+1][x+2];
	r += M4(-7.390e-02, -2.020e-01, 6.262e-01, -2.640e-01, -1.137e-01, -1.174e-01, -1.312e+00, -1.346e+00, -3.527e-01, 2.564e-01, -1.998e-01, -2.365e-01, -1.140e-01, 6.500e-02, -2.398e-01, 9.299e-02) * s1[y+2][x+0];
	r += M4(2.483e-01, 1.014e+00, 1.343e+00, -4.278e-01, 1.164e+00, -1.580e+00, -3.918e+00, 1.874e+00, -2.481e-01, 6.334e-01, -3.617e-01, 2.073e-01, 9.423e-02, 3.428e-01, 3.018e-01, -1.144e-01) * s1[y+2][x+1];
	r += M4(1.264e+00, -8.980e-01, 3.843e+00, 3.032e-01, 9.648e-02, -6.167e-01, -2.199e+00, -2.490e+00, 1.273e-03, -1.293e-03, 2.898e-02, 2.846e-02, 9.754e-03, 4.620e-02, 8.039e-02, -2.178e-02) * s1[y+2][x+2];
	r += V4(-4.735e-02, -7.410e-02, 5.845e-02, 1.777e-01);
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
	r += M4(-7.367e-02, -2.021e-01, 7.563e-03, 8.627e-02, 7.450e-02, 8.961e-02, -6.416e-02, 5.852e-03, -1.487e-01, 1.038e-01, 3.880e-02, 1.556e-02, -3.460e-02, -2.253e-01, 1.498e-01, 1.250e-01) * s0[y+0][x+0];
	r += M4(9.735e-02, -1.588e-01, 3.729e-02, -1.431e-01, 1.479e-01, 2.694e-01, -2.003e-01, -1.441e-01, -3.774e-01, 2.080e-01, -1.018e-01, -3.848e-03, 1.994e-02, -2.647e-01, 6.924e-03, 2.057e-01) * s0[y+0][x+1];
	r += M4(-8.464e-02, -4.228e-02, -2.375e-02, -4.790e-02, -9.879e-02, 1.759e-02, 1.411e-01, -5.490e-02, 1.990e-01, 8.383e-02, -8.378e-02, -2.189e-02, -1.207e-02, -2.607e-02, -2.958e-02, 9.154e-02) * s0[y+0][x+2];
	r += M4(-1.861e-02, -9.146e-02, 1.140e-01, 1.251e-01, 1.035e-01, -1.184e-01, -6.743e-02, -1.040e-01, -4.951e-02, -1.074e-02, -4.886e-02, -9.788e-02, -5.910e-02, 2.740e-01, -3.369e-03, -2.588e-01) * s0[y+1][x+0];
	r += M4(1.095e-01, 1.579e-01, -1.601e-01, 9.632e-01, 5.711e-02, -2.468e-02, -4.111e-01, 6.113e-02, -2.741e-01, -3.400e-01, -3.188e-01, -1.422e-01, 1.724e-02, 1.509e-01, 1.205e-01, -1.815e-01) * s0[y+1][x+1];
	r += M4(-3.660e-02, 2.249e-04, -7.955e-02, 2.187e-01, -1.235e-01, 2.786e-02, 2.510e-01, -5.272e-02, 1.032e-01, -1.460e-02, 3.371e-01, -1.350e-02, -2.402e-01, 6.465e-03, -2.966e-01, 2.146e-01) * s0[y+1][x+2];
	r += M4(2.484e-02, 2.253e-01, 1.685e-01, -2.341e-01, -3.681e-01, -2.065e-01, -1.097e-01, 3.064e-01, -1.975e-02, -6.522e-02, -2.412e-02, 9.062e-02, -4.760e-02, -1.082e-01, -1.112e-02, 1.179e-01) * s0[y+2][x+0];
	r += M4(3.141e-02, -1.338e-01, -3.037e-01, -5.215e-01, -2.939e-01, -9.207e-02, -9.453e-02, 9.852e-02, -5.560e-02, 3.548e-02, 1.113e-01, 4.349e-02, -4.032e-02, 6.431e-03, 4.878e-02, 2.795e-03) * s0[y+2][x+1];
	r += M4(1.875e-01, 3.628e-02, 1.322e-01, -2.589e-01, -2.099e-02, -2.260e-02, 3.529e-02, 1.441e-01, -4.521e-02, -9.423e-03, -1.556e-01, -9.975e-02, -6.153e-02, 9.442e-02, 2.150e-02, -9.054e-02) * s0[y+2][x+2];
	r += M4(-5.017e-02, 4.460e-02, -1.789e-02, 4.923e-03, -1.211e-03, -2.182e-01, -5.755e-02, 6.614e-02, -1.061e-01, -3.445e-01, 1.358e-01, -9.591e-02, 2.416e-01, -2.089e-01, -2.915e-02, -4.896e-02) * s1[y+0][x+0];
	r += M4(1.232e-01, 9.598e-02, -8.967e-02, -1.215e-01, 3.673e-02, -1.274e-01, -2.136e-02, -9.688e-03, -7.468e-01, -1.843e-01, -1.475e-01, -8.475e-01, 7.117e-02, -1.646e-01, -8.951e-02, 1.190e-01) * s1[y+0][x+1];
	r += M4(-7.250e-02, 3.296e-02, 9.488e-02, -4.936e-02, -1.947e-01, -7.495e-02, 1.559e-01, 1.163e-01, 5.060e-01, 1.691e-01, 2.713e-01, -7.035e-01, 2.037e-02, -5.755e-02, -9.591e-03, 2.758e-02) * s1[y+0][x+2];
	r += M4(-8.602e-02, -1.181e-02, 6.715e-02, -4.632e-02, -1.733e-01, 1.103e-01, 9.425e-02, 1.727e-02, -8.880e-02, 2.667e-01, 4.911e-02, -3.916e-01, 3.547e-01, 4.223e-01, 1.749e-01, -8.329e-01) * s1[y+1][x+0];
	r += M4(2.370e-01, 1.731e-01, -2.922e-01, -1.271e-02, 1.874e-01, -6.408e-02, -2.496e-01, 4.074e-03, 1.324e-02, -8.186e-02, -4.338e-01, -7.012e-01, -5.002e-01, 2.065e-01, 8.351e-01, -1.287e-01) * s1[y+1][x+1];
	r += M4(-9.888e-02, 1.236e-01, 1.610e-01, -5.275e-02, -6.855e-02, -4.575e-02, 1.650e-01, 1.008e-01, 3.430e-01, -3.701e-02, 2.257e-01, -2.965e-01, 6.416e-02, 8.374e-02, 1.432e-01, -9.744e-02) * s1[y+1][x+2];
	r += M4(-1.763e-01, -2.085e-01, 4.475e-02, 3.993e-02, -6.109e-02, -2.565e-02, -6.290e-02, -1.209e-01, 7.037e-02, -1.054e-01, -1.146e-01, 1.774e-01, 2.700e-01, -1.848e-01, -2.763e-01, 5.806e-02) * s1[y+2][x+0];
	r += M4(-3.009e-01, -5.879e-01, -3.721e-01, 1.373e-01, 3.934e-02, 1.254e-02, 3.002e-02, -2.649e-01, -1.673e-01, 1.367e-02, 1.271e-01, 2.912e-01, -1.622e-01, 8.707e-02, 3.305e-02, 1.110e-01) * s1[y+2][x+1];
	r += M4(7.257e-02, -7.081e-02, 3.110e-01, -9.358e-02, 6.919e-02, -3.894e-02, 7.744e-02, -1.214e-01, -8.879e-02, -5.501e-02, -1.193e-01, 9.575e-02, -2.271e-02, 8.747e-02, 7.263e-02, -1.228e-01) * s1[y+2][x+2];
	r += V4(5.335e-02, 8.837e-03, -5.539e-03, 1.480e-02);
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
	r += M4(-4.042e-02, -4.280e-03, -1.691e-02, -2.441e-02, -2.404e-02, 5.334e-02, -3.134e-05, 1.635e-02, -4.545e-03, 8.041e-02, -2.909e-03, 1.033e-02, 1.565e-02, -1.691e-02, -8.849e-03, -3.479e-02) * s0[y+0][x+0];
	r += M4(-1.106e-01, 3.895e-02, -1.002e-02, 2.953e-03, -3.967e-02, -9.782e-02, 6.239e-02, -1.197e-02, 1.836e-01, -1.255e-01, 8.015e-02, -3.268e-02, -3.692e-02, 5.943e-02, 8.016e-02, -2.841e-02) * s0[y+0][x+1];
	r += M4(-1.128e-01, -7.203e-02, -4.623e-03, 1.642e-02, -4.815e-02, -1.060e-02, -7.432e-02, -2.299e-02, 3.569e-03, 3.174e-01, -1.810e-01, -7.232e-02, -2.044e-02, -4.175e-02, -5.552e-02, -4.458e-02) * s0[y+0][x+2];
	r += M4(-5.848e-02, -6.357e-02, -8.858e-02, -7.157e-02, -1.377e-02, 4.784e-02, -8.374e-03, 1.382e-02, 1.733e-01, 1.313e-01, 1.999e-01, 4.301e-02, 4.659e-03, -5.714e-02, -6.426e-02, -7.301e-02) * s0[y+1][x+0];
	r += M4(1.233e-01, 1.735e-01, 3.005e-01, -2.265e-01, 1.394e-01, -8.045e-02, 9.714e-02, -2.575e-01, -2.884e-01, -2.842e-01, -4.330e-01, -7.276e-01, 1.987e-01, 8.391e-02, 2.411e-01, -3.642e-01) * s0[y+1][x+1];
	r += M4(1.274e-01, -2.510e-01, -9.519e-04, -3.921e-02, -3.766e-02, -1.753e-01, -5.476e-02, 8.258e-03, 3.350e-01, 5.761e-01, -8.732e-02, 4.588e-02, -1.246e-03, -7.838e-02, -1.509e-01, -3.919e-02) * s0[y+1][x+2];
	r += M4(-5.541e-02, 6.207e-03, -5.075e-03, -3.757e-02, 5.723e-03, -5.344e-03, -4.333e-02, 2.059e-02, -8.119e-02, 9.337e-03, -3.185e-02, -1.472e-03, 4.727e-02, -3.225e-02, -1.523e-02, 1.389e-02) * s0[y+2][x+0];
	r += M4(6.958e-02, -1.304e-02, -6.953e-02, -1.431e-01, 4.895e-02, 1.650e-02, 9.114e-02, 3.408e-02, 7.583e-02, -6.433e-02, 4.771e-02, -4.408e-02, 4.716e-02, 3.681e-02, 6.710e-02, -7.929e-02) * s0[y+2][x+1];
	r += M4(8.425e-02, -2.983e-02, -2.019e-03, -5.604e-02, 1.929e-02, -3.609e-02, 1.789e-02, -1.274e-02, -7.700e-03, 1.480e-01, -1.240e-01, -5.503e-02, 3.649e-02, -6.792e-03, -3.474e-02, -3.534e-02) * s0[y+2][x+2];
	r += M4(1.714e-02, 4.372e-03, -1.212e-02, -2.226e-02, 3.588e-02, 2.816e-02, 4.846e-03, -2.835e-02, -4.943e-02, 1.721e-02, 4.420e-03, 4.767e-02, 3.554e-01, -1.275e-01, 8.809e-02, -2.153e-01) * s1[y+0][x+0];
	r += M4(-4.092e-02, 8.944e-02, -1.659e-01, 2.266e-02, 4.087e-02, 8.378e-03, 5.899e-02, -2.750e-02, -6.577e-02, -4.378e-02, 2.777e-02, -3.625e-02, -5.655e-01, 1.792e+00, 7.717e-02, 7.853e-02) * s1[y+0][x+1];
	r += M4(-2.931e-02, -8.001e-02, 5.669e-02, -4.129e-03, 3.549e-02, 6.662e-03, -2.600e-02, -3.356e-02, -3.399e-03, -2.546e-02, 1.167e-02, -2.668e-02, 7.635e-02, -4.696e-02, -1.080e-01, -1.495e-01) * s1[y+0][x+2];
	r += M4(2.392e-02, 6.041e-02, -1.278e-02, -8.114e-04, 5.824e-02, 2.863e-02, -4.224e-02, -2.653e-02, -5.186e-02, -1.022e-01, -1.089e-01, -7.651e-02, 7.062e-02, -4.968e-02, -7.432e-02, 9.391e-03) * s1[y+1][x+0];
	r += M4(-3.839e-01, 4.983e-02, -5.794e-02, -3.619e-01, -5.868e-02, -3.490e-03, 2.121e-01, -1.861e-01, 1.046e-02, 1.294e-01, 1.536e-01, -1.569e-01, 1.928e-01, 9.028e-02, 1.541e-01, -2.101e-01) * s1[y+1][x+1];
	r += M4(5.242e-02, -1.616e-01, 3.552e-02, -2.724e-02, -4.217e-03, -1.547e-02, -1.752e-01, -3.332e-02, 1.415e-04, -8.393e-02, -9.390e-02, -9.092e-03, -5.544e-02, -5.550e-02, -1.997e-01, -7.299e-02) * s1[y+1][x+2];
	r += M4(1.150e-02, 2.645e-02, 2.578e-02, 7.828e-03, 1.248e-01, -2.755e-02, -2.167e-02, -7.839e-02, 6.558e-03, 9.095e-03, 5.450e-02, 3.181e-02, 4.945e-02, -3.162e-02, 3.256e-02, 5.962e-03) * s1[y+2][x+0];
	r += M4(-8.063e-02, 4.054e-03, -2.530e-01, -1.460e-01, 4.003e-01, 6.706e-02, -4.373e-01, -2.066e-01, -1.749e-03, -3.350e-02, 2.477e-02, -2.917e-02, -1.769e-02, 8.134e-02, 4.888e-02, -7.618e-02) * s1[y+2][x+1];
	r += M4(-1.903e-02, 5.756e-03, 4.324e-02, -4.505e-02, 4.213e-01, -2.052e-01, 8.179e-02, -1.934e-01, 1.840e-02, -7.878e-03, 2.777e-02, -2.733e-02, 7.115e-02, -2.217e-02, -4.586e-02, -3.281e-02) * s1[y+2][x+2];
	r += V4(5.329e-03, -5.449e-03, 1.428e-02, -6.487e-03);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-4x4C-out
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
	r += M4(7.277e-03, -1.872e-03, 2.759e-02, -5.113e-02, -1.764e-02, 4.826e-02, -9.639e-02, -1.155e-01, -1.470e-02, 8.831e-03, 4.042e-02, 1.494e-02, -1.685e-02, -3.178e-02, 6.720e-02, 4.285e-02) * s0[y+0][x+0];
	r += M4(-3.109e-02, -4.968e-02, 6.364e-02, 1.229e-01, 1.500e-02, 9.354e-02, -5.865e-02, -1.039e-02, 1.489e-01, 3.674e-02, -3.472e-02, 2.909e-03, 1.508e-01, 1.794e-01, -7.815e-02, 1.196e-02) * s0[y+0][x+1];
	r += M4(-1.873e-02, -3.965e-03, -1.251e-02, -1.197e-02, 2.326e-02, -3.009e-02, -1.666e-03, -3.312e-03, 6.819e-03, 7.538e-02, 1.030e-02, -5.277e-03, -4.029e-02, -5.689e-02, 1.101e-01, 4.573e-02) * s0[y+0][x+2];
	r += M4(-6.766e-02, -3.262e-02, -2.934e-02, 7.888e-02, -3.614e-01, 6.719e-01, -4.757e-02, 4.912e-01, 3.128e-02, 1.273e-01, -7.999e-02, 7.180e-02, -4.620e-02, -3.426e-02, -1.062e-01, -1.297e-01) * s0[y+1][x+0];
	r += M4(2.900e-01, 1.003e-01, -2.934e-02, -2.333e-01, 1.549e-01, -4.078e-01, 1.495e-01, -3.210e-02, -3.091e-01, -2.570e-01, 8.286e-02, -1.238e-01, 5.840e-01, 2.788e-01, 8.311e-01, 5.918e-01) * s0[y+1][x+1];
	r += M4(-7.714e-02, 7.311e-02, -2.978e-02, 6.763e-02, -4.739e-02, 2.428e-02, 1.510e-02, -8.812e-03, -4.979e-03, -1.690e-01, -1.068e-02, 2.823e-04, 7.005e-02, 3.428e-01, -1.066e-01, 1.628e-01) * s0[y+1][x+2];
	r += M4(4.282e-02, 1.388e-02, -1.667e-02, -3.676e-02, -1.136e-01, -2.085e-03, -3.510e-01, 3.819e-01, -3.879e-02, -3.098e-02, 3.520e-02, 1.699e-02, 4.394e-02, -3.147e-02, 1.734e-02, -2.334e-03) * s0[y+2][x+0];
	r += M4(-1.111e-01, -4.454e-02, 7.764e-02, 5.910e-02, -4.676e-02, 4.462e-02, 8.106e-02, -2.105e-01, 1.047e-01, 1.552e-02, -5.314e-02, -2.355e-02, 1.951e-02, 8.916e-02, -3.994e-03, -5.427e-02) * s0[y+2][x+1];
	r += M4(9.518e-03, -4.015e-02, -4.647e-02, -1.650e-02, 1.143e-02, -3.163e-02, -5.959e-03, -5.220e-04, -2.133e-02, 5.886e-02, 5.003e-03, -1.856e-02, -4.743e-02, -6.713e-02, -2.902e-02, -1.460e-02) * s0[y+2][x+2];
	r += M4(-1.370e-02, -3.936e-02, 3.747e-02, -2.505e-02, 3.746e-02, -1.397e-03, -4.238e-02, -3.193e-02, -7.686e-02, 4.870e-02, 1.947e-02, -1.424e-02, -4.134e-02, 2.637e-02, 3.412e-02, 2.960e-02) * s1[y+0][x+0];
	r += M4(-1.232e-01, -6.287e-03, 1.978e-01, 1.733e-01, -2.502e-02, 2.103e-02, 2.590e-02, -6.521e-03, 1.178e-01, 9.418e-02, -6.984e-02, 5.025e-02, 5.880e-02, -3.227e-02, -5.005e-02, -3.480e-02) * s1[y+0][x+1];
	r += M4(-2.508e-02, -1.509e-01, 5.514e-03, 8.327e-02, 1.762e-02, -5.004e-04, -2.370e-02, -2.856e-03, -3.997e-03, 3.573e-02, 1.319e-02, 1.088e-03, -4.649e-02, -2.609e-02, 5.260e-02, 4.099e-02) * s1[y+0][x+2];
	r += M4(1.055e-01, 1.673e-02, -2.766e-01, 7.828e-03, -1.182e-01, -1.329e-02, 1.707e-01, 9.037e-02, -4.580e-01, 5.058e-01, -4.372e-01, 3.089e-01, -8.853e-02, 1.478e-02, -1.656e-01, -2.725e-02) * s1[y+1][x+0];
	r += M4(7.185e-01, 4.190e-01, -4.463e-01, -6.231e-01, -1.386e-02, -1.304e-01, -1.496e-02, 8.538e-02, -1.073e-01, -4.493e-01, 2.233e-01, -2.124e-01, 3.396e-01, 2.911e-02, 4.191e-01, 9.937e-02) * s1[y+1][x+1];
	r += M4(-2.945e-02, 3.420e-01, 1.018e-02, -1.751e-01, -2.188e-02, -1.124e-02, 4.752e-02, 1.670e-02, -3.406e-02, -1.032e-01, -3.428e-02, 1.136e-02, 2.245e-02, 2.104e-01, -1.529e-01, 9.316e-03) * s1[y+1][x+2];
	r += M4(-9.152e-02, -2.080e-02, 1.500e-01, -4.963e-02, 5.622e-02, 2.176e-02, -9.448e-02, -1.416e-02, -4.567e-02, -1.125e-01, -1.342e-01, 1.529e-01, 9.857e-03, 5.951e-04, 7.048e-03, 2.975e-02) * s1[y+2][x+0];
	r += M4(-2.675e-01, -2.468e-01, 1.343e-01, 2.578e-01, -2.003e-02, 3.820e-02, -2.192e-02, -9.448e-02, 4.926e-02, 1.266e-01, -7.114e-02, -3.066e-02, -3.421e-02, -8.983e-03, -7.549e-03, -7.045e-02) * s1[y+2][x+1];
	r += M4(6.788e-02, -3.147e-02, -6.094e-02, -1.455e-02, 1.302e-02, -1.894e-02, -2.226e-03, -1.620e-02, 6.135e-04, 3.331e-02, 2.758e-03, -3.320e-02, -4.107e-02, -5.914e-02, 1.582e-02, 5.000e-02) * s1[y+2][x+2];
	r += V4(5.476e-03, 5.511e-03, 5.080e-03, 5.427e-03);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-4x4C-shuffle
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

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
#define l0(x, y) F(texelFetch(LUMA_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0).r)
shared F s0[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += V4(-1.200e-03, 1.315e-02, -1.562e-02, 8.830e-03) * s0[y+0][x+0];
	r += V4(-4.650e-02, -2.153e-01, -1.547e-01, 2.047e-02) * s0[y+0][x+1];
	r += V4(4.637e-02, -4.506e-01, 1.735e-02, -7.324e-01) * s0[y+0][x+2];
	r += V4(-3.041e-02, -4.479e-02, -3.430e-01, 4.130e-03) * s0[y+1][x+0];
	r += V4(6.136e-01, 1.930e-01, 3.879e-01, 4.587e-03) * s0[y+1][x+1];
	r += V4(-5.918e-01, 5.025e-01, 3.514e-01, 2.865e-02) * s0[y+1][x+2];
	r += V4(3.119e-02, 5.789e-02, -1.038e-01, -6.463e-04) * s0[y+2][x+0];
	r += V4(-2.266e-02, -2.562e-02, -5.554e-02, -4.211e-04) * s0[y+2][x+1];
	r += V4(-7.261e-05, -3.186e-02, -6.214e-03, 3.130e-03) * s0[y+2][x+2];
	r += V4(1.612e-03, 2.482e-05, -1.348e-02, 7.786e-03);
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
#define l0(x, y) V4(texelFetch(in_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.057e-01, 7.636e-01, -1.159e-01, -9.175e-02, -2.253e-01, 1.353e-01, 5.750e-02, -1.563e-01, -6.397e-03, 7.029e-02, -9.693e-02, 3.137e-02, 1.312e-02, -5.637e-01, 2.526e-01, 3.555e-01) * s0[y+0][x+0];
	r += M4(1.542e-02, -3.704e-01, 1.107e-01, -1.083e-01, -1.274e-01, 3.731e-02, 5.172e-02, -6.527e-02, 3.499e-01, -3.000e-01, -3.322e-01, 1.819e-01, -2.281e-01, 1.366e-01, 4.016e-01, 5.586e-01) * s0[y+0][x+1];
	r += M4(2.154e-02, 5.578e-02, -8.189e-02, -3.656e-01, -3.225e-01, 5.448e-02, -6.763e-02, -8.525e-02, 4.697e-01, 1.786e-02, -2.398e-01, -8.796e-02, 2.407e-01, 3.533e-01, 3.201e-01, -2.245e-02) * s0[y+0][x+2];
	r += M4(-2.248e-01, -3.024e-01, 1.047e+00, 2.333e-01, -4.893e-01, 4.873e-01, 5.477e-02, -3.066e-01, 1.529e-01, -3.444e-02, -1.258e-01, -9.986e-02, 4.097e+00, -2.103e+00, 8.428e-01, -1.523e+00) * s0[y+1][x+0];
	r += M4(-1.900e-01, 3.799e-01, 4.266e-01, 2.822e-02, 4.562e-02, 3.109e-01, 3.222e-02, -3.941e-01, -4.384e-01, 9.731e-02, 2.425e-01, -2.923e-01, -1.422e+00, -5.092e-02, 9.284e-02, 1.079e+00) * s0[y+1][x+1];
	r += M4(3.966e-01, 6.718e-02, -1.516e-01, 1.723e-01, 2.419e-01, -2.449e-02, -6.127e-02, 2.041e-02, 1.558e-01, 1.828e-01, -2.921e-01, 2.487e-01, -7.613e-01, 1.210e-01, -2.958e-01, 2.889e-01) * s0[y+1][x+2];
	r += M4(2.414e-01, -1.752e-01, 5.176e-01, 2.399e-01, 4.971e-01, -1.267e-01, 4.786e-01, 7.730e-02, -1.192e-01, -1.106e-02, 1.733e-01, 4.153e-02, 1.158e+01, 5.132e-01, -4.066e+00, -1.424e+01) * s0[y+2][x+0];
	r += M4(7.715e-03, -1.152e-02, -7.465e-02, 6.611e-02, 8.209e-01, -2.016e-01, 3.438e-01, -2.174e-01, 1.792e-01, 8.565e-02, 9.732e-03, 2.265e-02, 9.795e-01, -9.442e-01, 1.288e+00, -1.028e+01) * s0[y+2][x+1];
	r += M4(-2.629e-01, 1.090e-01, -2.901e-01, -1.489e-01, -2.487e-01, 2.016e-01, -2.527e-01, 1.020e-02, -4.318e-02, 1.964e-02, -2.509e-01, -1.023e-01, -7.732e-01, -3.546e-01, 2.918e-01, -5.676e-01) * s0[y+2][x+2];
	r += M4(3.007e-01, -4.030e-02, -6.507e-02, -1.778e-02, 2.933e-02, -5.411e-01, 1.922e-01, 4.955e-02, -3.444e-02, -2.906e-02, -8.835e-02, -7.100e-02, 1.616e-01, -6.816e-02, -5.412e-02, 5.890e-02) * s1[y+0][x+0];
	r += M4(1.132e-01, -1.059e+00, 2.747e-02, 5.872e-02, -6.252e-02, -2.114e-01, 2.251e-02, 3.585e-01, 4.627e-02, -2.377e-02, -2.511e-01, 6.269e-01, 1.655e-01, -4.816e-02, 3.850e-02, -1.145e-02) * s1[y+0][x+1];
	r += M4(-1.115e-01, 8.680e-02, -5.876e-02, 3.282e-01, -3.128e-01, -1.817e-02, -5.080e-02, 2.319e-01, 4.677e-01, 1.276e-01, -1.616e-01, -2.877e-01, 1.486e-01, -1.681e-02, 2.097e-02, 1.047e-01) * s1[y+0][x+2];
	r += M4(1.804e-02, -5.334e-02, -3.096e-01, -1.130e-01, 6.568e-02, 3.094e-01, 4.063e-01, -1.983e-01, 2.102e-01, -1.611e-02, 5.401e-01, -3.228e-02, -1.750e-01, 1.487e-01, 1.528e-01, -1.658e-02) * s1[y+1][x+0];
	r += M4(-4.228e-01, 2.379e-01, -1.459e-02, -7.538e-02, -8.866e-02, 2.294e-01, 1.324e-01, 7.807e-02, -4.523e-01, -2.913e-01, 4.716e-01, 1.330e-02, -2.568e-01, 5.013e-02, -3.277e-01, -2.161e-01) * s1[y+1][x+1];
	r += M4(3.260e-01, 7.551e-02, -1.851e-01, 3.211e-01, 2.401e-01, -8.412e-02, -1.317e-01, 1.250e-02, 2.103e-01, 1.013e-01, -3.003e-01, 1.219e-01, -2.627e-02, 3.110e-02, -5.223e-02, 8.743e-03) * s1[y+1][x+2];
	r += M4(2.658e-02, 9.837e-02, -1.045e-01, -1.392e-01, 6.310e-02, -7.055e-02, -5.760e-01, -1.278e-01, -1.678e-02, 7.995e-03, 3.765e-01, 5.997e-02, -6.800e-02, 1.695e-02, 7.188e-02, 4.767e-02) * s1[y+2][x+0];
	r += M4(-5.556e-02, 1.939e-01, -1.671e-01, -1.275e-01, 2.028e-01, -1.818e-01, 1.986e-01, 2.071e-01, 2.478e-01, 1.986e-02, 1.641e-01, 1.243e-01, -1.706e-02, -3.492e-02, 2.885e-02, -1.091e-01) * s1[y+2][x+1];
	r += M4(-2.804e-01, 9.106e-02, -3.433e-01, -7.683e-02, -2.842e-01, 1.919e-01, -1.521e-01, -1.978e-01, 1.650e-02, 3.767e-02, -2.960e-01, -2.988e-02, 1.723e-01, -4.788e-02, 1.997e-02, 1.067e-01) * s1[y+2][x+2];
	r += V4(2.244e-02, 1.297e-02, -2.971e-02, -1.642e-02);
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
#define l0(x, y) V4(texelFetch(conv1_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(3.565e-02, 6.762e-02, -9.645e-02, -3.161e-02, -2.145e-03, -3.956e-02, 2.613e-02, -1.940e-02, 2.329e-01, 6.669e-02, 3.288e-04, -1.616e-01, -3.359e-02, 1.021e-01, -6.660e-01, 1.008e-01) * s0[y+0][x+0];
	r += M4(1.184e-01, 5.973e-03, -1.345e-01, 1.055e-01, 7.143e-02, 1.781e-02, -1.979e-02, 4.309e-02, -2.989e-01, -1.176e-01, 1.450e-01, -4.735e-02, 7.232e-02, -5.581e-01, 1.577e-01, 1.817e-01) * s0[y+0][x+1];
	r += M4(-5.003e-03, 6.628e-02, -8.130e-02, 3.405e-02, 2.549e-02, 7.739e-04, -1.212e-02, 4.772e-02, -7.736e-02, -1.087e-02, 8.946e-02, 1.441e-01, -7.936e-02, -1.014e-02, 1.595e-01, 4.605e-02) * s0[y+0][x+2];
	r += M4(2.290e-01, 8.339e-02, 7.078e-02, 5.135e-02, 2.124e-01, -2.908e-02, 1.223e-01, -1.127e-01, 1.656e-01, 1.184e-02, 6.055e-02, -2.120e-01, 6.849e-01, -7.592e-01, 8.758e-01, 6.133e-02) * s0[y+1][x+0];
	r += M4(-3.545e-01, -1.023e-01, 1.466e-01, -3.983e-01, 1.002e-01, 2.332e-01, -1.994e-01, -2.439e-01, -2.451e-02, -6.717e-02, 5.183e-02, 2.326e-01, -3.352e-02, -4.821e-02, 1.587e+00, -5.437e-01) * s0[y+1][x+1];
	r += M4(-1.824e-03, -6.714e-02, -4.909e-02, 5.409e-02, -2.628e-02, 7.300e-02, -2.979e-02, 3.816e-02, -6.151e-02, -1.744e-02, 3.600e-02, 3.174e-01, 5.528e-03, 4.155e-02, 6.688e-03, 3.172e-01) * s0[y+1][x+2];
	r += M4(1.917e-01, 5.846e-02, -1.659e-02, -3.727e-02, 1.910e-01, 9.571e-02, -1.066e-01, 7.079e-03, 8.511e-04, -8.534e-02, 5.977e-02, -7.251e-02, 5.752e-01, -3.018e-01, 2.156e-01, -1.488e-01) * s0[y+2][x+0];
	r += M4(1.128e-01, 7.537e-02, 1.656e-02, -7.410e-02, 7.235e-02, -1.734e-01, -4.047e-03, -9.623e-02, -8.802e-02, 2.658e-02, -1.046e-02, 1.188e-01, 5.098e-01, -2.909e-01, 2.037e-01, -4.709e-01) * s0[y+2][x+1];
	r += M4(-5.237e-02, -4.591e-02, -2.372e-02, 6.859e-02, 2.876e-02, 7.136e-03, -7.898e-03, 9.791e-02, -2.125e-02, -4.576e-02, 7.153e-02, -2.105e-02, -6.848e-02, -1.107e-01, 2.173e-01, 3.748e-01) * s0[y+2][x+2];
	r += M4(-4.217e-02, -4.758e-02, -4.428e-02, -1.384e-02, 5.225e-04, -1.302e-01, 9.244e-02, 1.047e-01, 1.050e-02, -1.361e-02, 2.585e-02, 2.668e-02, 4.406e-02, -2.046e-02, 2.595e-03, 2.806e-02) * s1[y+0][x+0];
	r += M4(-1.454e-02, -1.620e-02, -1.144e-01, 3.509e-02, 8.652e-02, -2.300e-01, 1.334e-01, 1.294e-01, 2.028e-02, 1.983e-01, -7.196e-02, -3.332e-01, 6.473e-02, -1.263e-02, 1.716e-02, 4.204e-02) * s1[y+0][x+1];
	r += M4(-3.772e-06, 3.755e-02, -8.277e-02, -1.507e-02, 6.148e-02, -1.343e-01, 5.133e-02, 4.069e-02, -1.283e-01, 2.243e-01, -2.486e-01, 2.017e-01, 9.422e-06, -1.250e-02, -1.565e-02, 4.992e-03) * s1[y+0][x+2];
	r += M4(3.471e-01, 6.284e-02, 2.962e-05, 1.135e-01, 1.082e-01, -4.521e-01, 6.001e-01, 2.568e-01, -5.549e-03, 1.165e-01, -1.548e-01, -5.152e-02, 3.625e-01, 7.615e-02, -1.087e-02, -1.118e-01) * s1[y+1][x+0];
	r += M4(-6.349e-01, 1.377e-01, -4.249e-01, -9.726e-01, 3.798e-01, -7.842e-01, -3.230e-01, -1.567e-01, 1.990e-01, 4.490e-01, -2.911e-01, -2.986e-01, -5.426e-02, 4.920e-02, 7.384e-03, -1.458e-01) * s1[y+1][x+1];
	r += M4(-1.190e-01, -2.182e-02, -5.100e-02, 3.246e-01, 2.979e-01, -5.070e-01, 2.632e-01, -6.846e-02, -1.861e-01, 5.190e-01, -4.590e-01, 2.863e-01, -1.532e-02, 2.751e-02, -8.407e-03, 5.075e-02) * s1[y+1][x+2];
	r += M4(1.004e-01, 2.103e-02, 3.278e-01, -3.640e-02, 2.374e-01, 2.520e-02, 1.747e-01, -2.544e-01, -7.601e-02, -2.793e-02, 4.660e-02, 8.770e-02, 3.330e-01, 7.306e-02, -1.939e-01, -2.594e-01) * s1[y+2][x+0];
	r += M4(4.081e-02, 3.926e-01, 2.509e-01, -1.043e-01, -1.400e-01, 1.090e-01, 1.543e-01, -5.956e-01, -1.309e-02, -1.940e-01, -5.648e-02, 1.017e-01, -4.799e-02, -6.616e-02, -1.139e-02, 1.111e-01) * s1[y+2][x+1];
	r += M4(9.256e-02, -4.941e-02, 2.137e-01, 3.580e-02, 3.124e-02, -4.721e-02, 5.578e-02, 1.464e-01, -5.644e-02, -1.911e-01, 1.266e-02, -4.852e-02, 1.206e-02, -1.217e-02, 1.769e-02, 7.502e-03) * s1[y+2][x+2];
	r += V4(2.152e-04, -1.007e-02, 5.162e-03, 8.813e-03);
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

//!DESC CuNNy-2x4C-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE out
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
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-2.764e-04, 1.162e-02, -7.577e-03, 4.214e-03, -8.481e-02, -2.407e-02, 8.325e-02, 1.481e-02, 2.452e-02, -2.023e-02, 2.319e-02, -2.602e-02, -7.517e-03, -2.120e-02, -1.892e-03, -6.009e-03) * s0[y+0][x+0];
	r += M4(8.484e-02, -3.333e-03, -1.487e-02, -2.347e-02, -1.289e-01, -2.186e-01, 1.147e-01, 1.265e-01, -6.138e-02, -4.037e-02, 1.003e-02, 3.249e-02, -8.314e-03, 8.461e-03, -2.308e-02, -2.632e-02) * s0[y+0][x+1];
	r += M4(-6.391e-03, 5.581e-02, 2.564e-02, 2.151e-02, -1.861e-02, -4.827e-03, -6.276e-02, 3.467e-03, 2.007e-04, 2.742e-02, -1.506e-02, 1.057e-02, 1.307e-02, 1.426e-02, -1.945e-03, -1.524e-03) * s0[y+0][x+2];
	r += M4(-1.209e-02, 1.070e-02, 6.014e-04, -3.518e-03, 4.273e-01, -4.372e-02, -1.931e-01, -4.135e-02, 1.989e-02, -6.279e-02, 2.085e-02, -9.752e-03, 6.098e-02, -8.183e-02, 9.209e-02, -5.754e-02) * s0[y+1][x+0];
	r += M4(2.072e-01, 2.742e-03, 2.803e-01, 2.228e-02, 3.076e-01, 8.138e-01, -3.368e-01, -3.906e-01, -3.156e-02, 1.167e-01, -1.072e-01, -5.734e-02, 5.915e-02, 2.134e-01, 9.176e-02, 2.378e-01) * s0[y+1][x+1];
	r += M4(-1.208e-01, 6.411e-02, -1.401e-01, 9.911e-02, 3.580e-02, -3.437e-02, 6.654e-02, -3.329e-02, -6.799e-03, -5.650e-02, 3.587e-02, 2.033e-02, -1.562e-02, 3.252e-03, 3.243e-03, 4.534e-02) * s0[y+1][x+2];
	r += M4(-1.261e-02, -2.055e-02, -5.614e-03, 1.574e-03, -1.018e-01, -5.859e-03, 7.249e-02, -1.470e-01, 4.705e-03, 1.228e-02, -6.379e-04, -1.761e-02, 9.695e-03, 2.452e-03, -8.781e-03, -3.799e-02) * s0[y+2][x+0];
	r += M4(-2.970e-02, -1.260e-02, -1.064e-02, -1.326e-02, -1.405e-01, -2.504e-01, -3.399e-02, 2.687e-01, -7.056e-02, -2.232e-02, -4.687e-03, 7.593e-02, -9.905e-03, -1.000e-02, -3.947e-02, 9.012e-03) * s0[y+2][x+1];
	r += M4(2.818e-02, 2.982e-02, 6.922e-03, 2.094e-02, 7.226e-02, 7.549e-02, 1.018e-01, -1.328e-02, 4.501e-02, -1.145e-02, 3.548e-02, -2.901e-02, 1.196e-02, 1.548e-02, 8.373e-05, -1.788e-02) * s0[y+2][x+2];
	r += M4(2.100e-03, -1.150e-01, 2.819e-02, -1.339e-02, 6.065e-03, -2.058e-02, -3.658e-03, -1.812e-02, -4.404e-02, -4.847e-02, 6.566e-02, -2.088e-02, 9.515e-03, 1.802e-02, -2.133e-02, -1.276e-02) * s1[y+0][x+0];
	r += M4(-1.076e-01, 4.448e-02, -1.140e-02, 1.547e-03, -6.347e-02, -3.268e-02, 9.913e-03, -3.513e-03, -2.432e-01, -1.645e-01, 9.255e-02, 1.657e-01, 2.626e-02, -8.420e-02, -3.114e-02, -3.849e-02) * s1[y+0][x+1];
	r += M4(4.896e-02, -1.298e-03, 1.099e-02, 4.132e-02, 5.033e-03, 4.787e-03, -1.526e-02, 1.408e-02, 2.286e-03, -6.783e-02, -9.807e-03, 2.349e-03, -4.952e-02, 9.400e-02, 2.244e-03, -9.972e-03) * s1[y+0][x+2];
	r += M4(1.929e-01, -7.425e-02, 1.499e-01, -1.703e-01, 1.048e-03, -8.557e-02, 4.510e-02, -2.821e-02, 3.272e-01, 1.159e-01, -1.792e-01, -2.919e-03, -3.358e-02, 4.603e-02, 2.260e-02, 5.401e-02) * s1[y+1][x+0];
	r += M4(2.052e-01, 4.566e-01, 9.620e-02, 4.522e-01, 3.734e-02, 1.768e-01, -9.167e-02, 6.517e-02, 4.850e-01, 5.410e-01, -6.777e-01, -5.877e-01, 5.682e-01, -1.111e-01, 4.284e-01, -8.558e-02) * s1[y+1][x+1];
	r += M4(-2.240e-02, -1.167e-02, 1.911e-02, -2.066e-02, -1.946e-02, -5.700e-02, 5.073e-02, -2.543e-02, -3.067e-02, 1.483e-01, 3.093e-02, -2.112e-01, -4.072e-01, 2.437e-01, -2.764e-01, 3.097e-01) * s1[y+1][x+2];
	r += M4(5.118e-02, -1.198e-02, 3.560e-02, -3.423e-02, 7.302e-03, 9.124e-03, -1.811e-02, -2.481e-02, -7.701e-02, 4.196e-02, 5.749e-02, -6.025e-03, 2.815e-02, 5.033e-03, -1.342e-02, 2.216e-02) * s1[y+2][x+0];
	r += M4(-7.280e-02, 1.299e-02, -6.978e-02, 4.257e-02, -9.840e-02, -4.323e-02, 1.467e-02, 4.244e-02, -4.111e-01, -2.600e-01, 3.807e-01, 4.074e-01, -9.546e-02, -3.245e-02, 1.495e-01, -1.164e-01) * s1[y+2][x+1];
	r += M4(2.208e-02, 8.237e-03, 1.148e-02, -2.044e-02, 4.745e-02, -5.951e-03, 1.165e-02, -1.077e-02, 1.470e-01, -1.189e-01, -7.287e-02, -3.967e-02, 4.299e-02, 6.893e-03, -1.239e-01, 7.631e-02) * s1[y+2][x+2];
	r += V4(-1.858e-03, -1.975e-03, -1.446e-03, -1.548e-03);
	return tanh(vec4(r));
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

//!DESC CuNNy-2x4C-shuffle
//!HOOK LUMA
//!BIND out
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
vec4 hook() {
	vec4 r = vec4(0.0);
	vec2 f = fract(out_pos * out_size);
	ivec2 i = ivec2(f * vec2(2.0));
	r.r = out_tex((vec2(0.5) - f) * out_pt + out_pos)[2*i.y + i.x];
	r.r += easu_tex(easu_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

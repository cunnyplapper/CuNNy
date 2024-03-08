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
	r += V4(-1.026e-02, 6.805e-03, 2.764e-03, -9.201e-04) * s0[y+0][x+0];
	r += V4(-3.768e-03, 6.690e-02, -1.352e-02, -1.148e-03) * s0[y+0][x+1];
	r += V4(-2.288e-01, -1.213e-01, 9.326e-03, 4.841e-02) * s0[y+0][x+2];
	r += V4(-1.962e-02, 1.107e-01, 6.074e-05, 2.649e-02) * s0[y+1][x+0];
	r += V4(2.646e-01, 2.873e-02, -6.966e-01, -9.582e-03) * s0[y+1][x+1];
	r += V4(-3.603e-01, -6.863e-01, 7.051e-01, -8.470e-01) * s0[y+1][x+2];
	r += V4(-3.823e-02, -6.727e-03, -8.327e-03, -3.452e-03) * s0[y+2][x+0];
	r += V4(1.152e-02, 1.402e-01, 8.537e-02, 3.317e-03) * s0[y+2][x+1];
	r += V4(-1.797e-01, 2.592e-01, -8.275e-02, 3.656e-02) * s0[y+2][x+2];
	r += V4(-1.232e-02, 9.790e-02, -2.944e-03, 9.295e-03);
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
#define l0(x, y) V4(texelFetch(in_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(3.343e-01, 2.349e-01, 1.044e+00, -1.416e-01, 2.198e-01, -4.562e-02, 1.658e-01, 3.713e-02, -1.017e-01, 2.679e-03, -6.753e-02, 1.790e-01, 5.412e-02, 2.600e+00, 1.431e+00, 1.446e-01) * s0[y+0][x+0];
	r += M4(8.864e-02, -5.541e-01, 1.694e+00, 5.352e-01, 2.446e-01, 2.145e-01, -2.020e-02, 3.350e-01, 3.000e-01, 8.064e-01, -2.803e-01, 3.963e-01, 6.801e-01, 1.186e+00, 1.158e+00, -5.517e-01) * s0[y+0][x+1];
	r += M4(-4.983e-01, -1.028e+00, -2.876e-01, 3.439e-01, 2.143e-01, 7.569e-01, 3.184e-01, 1.693e-01, 5.951e-01, 7.598e-01, 3.268e-01, 1.327e-01, 2.661e-01, -7.822e-01, 5.914e-01, 1.185e-01) * s0[y+0][x+2];
	r += M4(-1.440e+00, -1.431e-01, 1.923e-01, -9.382e-01, 5.302e-02, 3.046e-02, -4.573e-02, -1.713e-01, 2.349e-01, 6.468e-02, -1.785e-01, 1.713e-01, 1.146e+00, 1.059e+00, 1.592e+00, -3.669e+00) * s0[y+1][x+0];
	r += M4(-1.218e+00, 8.048e-01, 1.938e+00, 6.850e-01, -4.087e-01, -1.246e-01, -3.453e-01, 1.645e-01, 4.267e-01, -3.202e-01, 5.449e-01, 4.585e-01, 5.774e-01, 2.705e+00, -3.652e+00, -4.372e+00) * s0[y+1][x+1];
	r += M4(-1.164e+00, -1.385e-02, -2.328e+00, 2.576e-01, 7.291e-02, -4.935e-01, -3.976e-01, -6.138e-02, 1.604e-01, -7.051e-01, -4.920e-01, -8.809e-01, 2.050e-02, -1.636e+00, -1.955e+00, -1.553e+00) * s0[y+1][x+2];
	r += M4(-2.035e+00, 1.169e+00, -5.023e-01, -2.531e-01, -9.058e-02, -4.238e-02, -5.549e-02, -1.100e-01, -2.786e-02, -7.069e-02, -5.144e-02, 6.266e-02, -1.785e+00, 1.085e+00, 8.306e-01, -1.653e+00) * s0[y+2][x+0];
	r += M4(9.563e-01, -1.388e-01, 5.539e-01, 1.748e-01, -1.843e-01, 5.164e-02, 6.487e-02, -4.728e-02, -4.424e-01, -2.744e-01, -2.053e-01, 2.051e-01, 1.173e+00, 6.164e-01, 2.010e+00, -2.593e+00) * s0[y+2][x+1];
	r += M4(4.165e-01, 7.033e-01, -6.176e-01, -8.847e-01, -1.737e-01, -4.367e-02, 1.384e-01, 1.711e-02, -3.768e-01, 3.807e-02, -1.697e-02, -2.918e-01, 1.175e-01, -1.388e-02, 4.325e-01, -1.003e+00) * s0[y+2][x+2];
	r += M4(2.392e-01, 1.236e-01, -6.938e-03, 1.528e-01, 1.013e-01, 6.074e-03, 2.448e-01, 3.418e-02, 2.669e-01, -2.726e-02, 2.842e-01, -2.581e-02, -8.730e-02, 2.989e-02, -3.525e-03, -1.906e-02) * s1[y+0][x+0];
	r += M4(-1.811e-01, -6.572e-02, -1.451e-01, -1.766e-01, 6.475e-02, 3.669e-01, -3.767e-02, 6.675e-01, 6.444e-02, -8.937e-02, 2.809e-01, 1.863e-01, 8.933e-02, 4.090e-01, -7.308e-02, 2.887e-02) * s1[y+0][x+1];
	r += M4(-5.573e-02, -1.694e-01, 1.114e-02, 7.796e-03, 2.026e-01, 5.700e-01, 2.708e-01, 3.057e-01, 2.272e-01, 4.355e-02, 4.971e-01, 3.603e-01, 1.697e-01, 1.763e-02, 8.873e-02, 2.424e-02) * s1[y+0][x+2];
	r += M4(4.176e-02, 1.112e-01, 7.397e-02, 3.821e-02, 9.311e-03, 3.138e-02, -2.001e-01, 2.151e-02, 5.734e-01, 2.007e-01, -1.685e-01, -7.641e-02, 1.042e-01, -6.593e-02, -1.297e-01, 1.248e-02) * s1[y+1][x+0];
	r += M4(1.457e-02, 3.198e-02, -1.172e-01, -1.161e-01, 7.536e-02, -2.303e-01, 1.426e-01, -4.063e-01, -6.853e-01, 1.743e-01, 6.657e-01, 1.991e-02, 2.300e-02, -1.915e-01, -2.855e-01, -1.719e-01) * s1[y+1][x+1];
	r += M4(6.788e-02, 8.515e-02, 2.046e-01, 1.972e-01, 1.674e-01, -3.853e-01, -8.524e-02, -1.735e-01, -4.605e-01, -3.247e-01, -1.011e+00, 1.918e-01, -9.950e-02, 4.377e-02, 2.264e-01, 5.371e-02) * s1[y+1][x+2];
	r += M4(-1.880e-01, -2.111e-02, -7.724e-02, 1.869e-04, 1.827e-02, -3.392e-02, -1.140e-01, -1.105e-02, 4.352e-01, -1.582e-01, 1.924e-02, -1.236e-01, -6.903e-02, -9.941e-02, 1.204e-01, -4.736e-02) * s1[y+2][x+0];
	r += M4(1.258e-02, -2.485e-01, -3.438e-02, -2.718e-01, 9.103e-02, -8.142e-02, 2.695e-02, 2.232e-02, 6.533e-02, 9.451e-03, -4.219e-02, 1.498e-02, -1.694e-01, -2.858e-02, 1.649e-01, 1.288e-02) * s1[y+2][x+1];
	r += M4(-2.621e-03, 8.120e-02, 6.604e-02, 1.634e-02, -1.212e-01, 4.848e-02, 5.511e-02, -1.972e-01, -1.276e-01, 1.597e-01, -3.183e-01, -1.860e-01, -1.264e-01, -1.426e-01, -1.694e-01, 6.015e-02) * s1[y+2][x+2];
	r += V4(-1.028e-01, -2.873e-02, -3.186e-02, -3.301e-02);
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
#define l0(x, y) V4(texelFetch(conv1_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-4.917e-03, 3.444e-02, -5.437e-02, 1.809e-01, -1.270e-01, -6.690e-03, -6.722e-02, 6.053e-02, 2.126e-02, 9.531e-02, -1.548e-01, -3.388e-01, 9.659e-02, -2.539e-02, 6.665e-02, -2.745e-01) * s0[y+0][x+0];
	r += M4(1.199e-01, -3.684e-02, -4.728e-02, -3.064e-02, -1.236e-01, 1.168e-01, -1.067e-02, -5.689e-02, 3.204e-02, -1.089e-01, 5.456e-02, -2.606e-02, 1.233e-02, -2.418e-01, 1.854e-02, -1.527e-01) * s0[y+0][x+1];
	r += M4(-7.566e-02, -1.017e-01, -4.951e-02, -1.160e-01, 1.764e-02, 3.197e-02, 7.470e-02, -3.105e-02, 6.532e-03, 5.190e-02, -2.021e-02, 2.509e-02, -7.031e-02, 3.625e-02, -2.033e-02, 2.009e-01) * s0[y+0][x+2];
	r += M4(-3.740e-01, -2.099e-01, -4.041e-01, -1.203e-01, 2.269e-01, 7.226e-02, -2.233e-01, 2.177e-01, 4.418e-01, 2.214e-01, 4.511e-01, -1.090e-01, -1.746e-01, 2.189e-01, 9.130e-01, 7.809e-02) * s0[y+1][x+0];
	r += M4(-9.672e-02, 4.903e-01, 6.244e-01, -1.063e-01, -4.671e-01, -7.892e-02, -7.695e-02, 2.783e-01, 2.586e-01, 1.710e-01, -2.495e-01, 2.120e-02, 4.406e-01, 5.699e-02, 2.076e-01, -8.271e-01) * s0[y+1][x+1];
	r += M4(2.056e-01, 1.387e-01, 8.534e-03, -3.791e-01, -4.143e-02, 4.649e-02, 6.373e-02, 1.589e-01, -8.035e-02, -9.249e-02, 7.629e-04, -3.040e-02, 1.859e-01, 1.178e-01, -9.848e-02, 4.825e-03) * s0[y+1][x+2];
	r += M4(1.107e-03, -1.020e-01, 1.417e-02, -3.390e-01, 3.139e-02, 1.844e-02, -2.001e-01, 2.493e-01, 2.588e-01, -2.901e-01, -1.201e-01, 6.069e-02, -4.132e-02, -1.197e-02, 7.139e-02, 1.431e-01) * s0[y+2][x+0];
	r += M4(2.588e-01, 2.282e-01, -9.446e-02, 7.708e-02, -5.462e-01, -5.024e-01, -1.602e-01, 3.757e-01, -3.852e-01, -2.337e-01, 1.102e-01, 3.905e-02, -1.923e-01, -3.156e-01, -1.112e-01, -3.122e-03) * s0[y+2][x+1];
	r += M4(-8.032e-02, -8.607e-02, 3.122e-02, -2.070e-01, 6.817e-02, -9.178e-02, 1.459e-02, 9.140e-02, 2.188e-02, 6.765e-02, 8.387e-03, -1.843e-04, -8.905e-02, -1.457e-01, -5.767e-02, -8.273e-03) * s0[y+2][x+2];
	r += M4(9.048e-02, 1.160e-01, 7.444e-02, 1.413e-01, 6.515e-02, -1.616e-01, -1.020e-01, -1.636e-01, 1.028e-02, -8.712e-02, -9.222e-02, -3.022e-01, 2.646e-01, 9.882e-02, 1.342e-01, 2.866e-01) * s1[y+0][x+0];
	r += M4(-9.789e-02, 5.307e-02, -3.531e-02, 2.775e-01, -1.756e-02, -2.338e-01, -5.551e-02, -1.580e-01, -1.435e-01, -5.613e-02, 4.501e-02, 8.862e-02, -1.158e-01, 3.009e-01, 1.104e-02, 1.811e-01) * s1[y+0][x+1];
	r += M4(-1.331e-01, 6.427e-02, -2.196e-01, -9.242e-02, 1.114e-01, -1.126e-01, 8.276e-02, 1.626e-02, -6.087e-02, -1.043e-02, -4.104e-02, 1.673e-01, -1.400e-02, 7.927e-02, 4.795e-02, -1.636e-01) * s1[y+0][x+2];
	r += M4(-1.161e-01, -1.503e-02, -7.329e-02, 1.630e-01, 3.064e-02, -1.074e-01, 5.898e-02, -8.574e-02, 4.206e-02, 2.327e-02, 1.665e-01, 3.916e-01, 1.681e-01, -1.460e-01, 5.332e-01, 4.350e-01) * s1[y+1][x+0];
	r += M4(2.450e-01, 2.261e-01, 2.738e-01, -8.911e-02, -3.030e-01, 4.131e-01, -3.293e-01, -1.813e-01, 3.086e-01, 1.863e-01, -5.789e-01, -2.842e-01, 3.807e-01, -2.725e-01, 2.880e-01, 1.146e-02) * s1[y+1][x+1];
	r += M4(2.012e-01, 5.048e-02, -2.331e-01, -2.752e-01, -9.831e-02, -1.892e-01, 1.204e-01, 3.741e-02, -2.066e-01, -1.657e-01, 3.237e-02, 3.259e-01, 2.801e-01, 1.213e-01, -9.866e-02, -2.309e-01) * s1[y+1][x+2];
	r += M4(9.647e-02, -2.428e-02, -3.794e-02, -1.155e-01, 1.219e-01, 2.512e-01, 3.994e-01, 3.718e-01, -2.241e-01, -1.226e-01, -1.453e-01, -6.323e-02, 5.281e-03, -1.353e-01, -4.030e-02, -8.968e-02) * s1[y+2][x+0];
	r += M4(-1.116e-01, -1.409e-01, -1.986e-02, 2.568e-01, -4.235e-01, -6.131e-01, -1.813e-01, 8.062e-02, -1.332e-01, -1.909e-01, -2.457e-02, -1.702e-02, -4.953e-02, -7.986e-02, -1.140e-01, 9.835e-03) * s1[y+2][x+1];
	r += M4(-9.738e-02, -8.277e-02, 1.681e-02, -3.262e-02, -1.304e-01, 8.859e-02, 1.215e-01, 7.466e-03, 1.082e-01, 4.554e-02, 8.545e-02, 1.779e-02, -1.792e-01, -1.252e-01, 1.561e-02, 5.285e-02) * s1[y+2][x+2];
	r += V4(-6.403e-04, 3.528e-02, -4.098e-03, -1.854e-02);
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
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(7.070e-03, -7.645e-03, 1.006e-01, -3.117e-02, -1.636e-01, 4.282e-02, 1.526e-01, -2.638e-01, 7.700e-02, -1.577e-02, -2.461e-02, 5.067e-02, 4.779e-02, -1.292e-01, -2.098e-04, 2.012e-01) * s0[y+0][x+0];
	r += M4(-1.094e-01, -3.647e-01, 7.132e-01, -1.665e-01, 1.358e-02, 7.995e-02, 9.725e-02, -7.307e-03, 4.316e-02, 1.378e-01, -6.066e-02, -2.145e-01, 6.809e-02, -2.047e-01, 1.371e-01, 3.694e-01) * s0[y+0][x+1];
	r += M4(2.486e-02, -3.930e-03, -4.182e-02, 1.022e-01, 6.258e-02, 2.268e-03, 1.088e-01, -7.964e-02, 9.740e-02, -4.296e-02, -1.038e-01, -2.359e-02, -4.622e-02, 8.323e-02, 8.055e-02, 3.348e-02) * s0[y+0][x+2];
	r += M4(-1.558e-01, 4.171e-03, -4.358e-02, -3.804e-01, -6.934e-02, 2.475e-02, -2.234e-03, 6.983e-02, -6.861e-02, -2.208e-01, -2.150e-02, -2.494e-02, -1.139e-01, 1.425e-01, 2.094e-01, -2.686e-01) * s0[y+1][x+0];
	r += M4(-1.411e-01, -1.251e-01, -5.738e-02, 3.696e-01, 3.467e-01, 2.462e-02, -2.538e-01, 2.881e-01, -1.852e-01, 3.475e-01, -9.063e-04, 2.906e-01, -1.735e-01, 2.056e-01, -6.860e-02, -6.584e-01) * s0[y+1][x+1];
	r += M4(6.915e-02, 8.839e-02, 7.625e-02, -1.313e-01, -3.263e-02, -2.840e-02, 7.911e-03, 4.550e-02, -1.499e-01, -5.145e-02, 1.648e-03, -1.242e-02, 6.191e-01, -1.157e-01, 2.108e-02, -1.592e-01) * s0[y+1][x+2];
	r += M4(-2.104e-01, -4.816e-02, -1.910e-01, 1.700e-01, -1.513e-02, -7.051e-02, 6.415e-03, -1.708e-01, 1.561e-02, 1.303e-01, 4.833e-02, -3.268e-02, 8.554e-02, 2.654e-01, -5.343e-02, 1.568e-01) * s0[y+2][x+0];
	r += M4(-6.130e-02, -1.189e-01, -8.765e-02, 1.944e-01, 1.112e-01, 1.100e-01, -5.720e-02, -1.561e-01, -2.547e-02, -7.350e-02, 2.531e-01, -2.896e-01, -8.144e-01, 5.020e-02, -2.884e-01, 3.967e-01) * s0[y+2][x+1];
	r += M4(-1.013e-01, 3.406e-02, -2.700e-02, 7.251e-02, 1.801e-02, -4.214e-02, 7.449e-02, -1.207e-01, 1.982e-02, -2.569e-02, 5.062e-02, -3.336e-04, 2.890e-02, -1.694e-01, -7.720e-02, 1.695e-01) * s0[y+2][x+2];
	r += M4(-2.040e-02, 8.190e-02, -1.486e-02, -1.818e-01, -2.153e-01, -2.629e-01, 9.072e-03, 2.422e-01, 6.625e-02, -1.879e-01, 2.387e-02, 1.704e-01, 3.466e-03, -4.907e-02, -1.343e-03, 9.073e-02) * s1[y+0][x+0];
	r += M4(-1.187e-01, -5.970e-02, 5.327e-02, 9.690e-02, -4.556e-01, 2.279e-01, 8.769e-02, 1.461e-01, 1.593e-02, 2.830e-01, -6.212e-02, -9.501e-02, 2.365e-02, -8.402e-02, -1.251e-02, 2.889e-02) * s1[y+0][x+1];
	r += M4(2.127e-02, 4.309e-02, -4.162e-02, 2.857e-02, -4.435e-02, -4.464e-02, 4.966e-02, 1.074e-01, 2.361e-02, 4.996e-02, 4.091e-02, 7.705e-02, -1.210e-02, 2.133e-02, -9.715e-03, -5.093e-02) * s1[y+0][x+2];
	r += M4(5.825e-03, 5.183e-01, -1.081e-01, -3.838e-01, 1.862e-02, -4.382e-01, 2.999e-01, -1.001e-01, -1.430e-02, -4.141e-01, 1.961e-02, 2.453e-01, -2.665e-02, -6.985e-03, 8.140e-02, -2.259e-01) * s1[y+1][x+0];
	r += M4(-1.149e-01, -2.690e-02, -7.185e-02, 2.100e-01, 7.805e-01, 2.610e-01, -2.728e-01, -1.111e-01, 1.352e-01, 1.249e+00, 1.536e-02, 8.064e-01, -9.095e-02, 2.128e-01, 1.407e-01, -5.737e-01) * s1[y+1][x+1];
	r += M4(1.475e-01, -2.354e-02, -1.152e-02, -4.409e-03, -3.410e-02, 4.707e-02, 2.833e-01, -1.120e-01, -1.369e-01, 3.033e-01, -6.660e-01, 2.913e-02, 1.145e-01, -5.944e-02, 8.244e-02, -7.934e-02) * s1[y+1][x+2];
	r += M4(-6.639e-02, 2.002e-01, -2.047e-01, -1.599e-01, 1.837e-02, -1.996e-01, 7.216e-02, 1.460e-01, 2.058e-01, -1.596e-02, 4.663e-02, 2.939e-01, -7.242e-02, 3.456e-02, 1.547e-02, -1.802e-01) * s1[y+2][x+0];
	r += M4(-9.157e-02, 2.243e-03, -5.918e-01, 5.477e-02, 2.589e-03, 8.274e-02, 1.799e-01, 8.381e-02, 3.041e-01, -3.903e-03, 7.012e-01, 2.140e-02, -3.641e-02, -5.973e-02, -3.520e-01, 8.902e-02) * s1[y+2][x+1];
	r += M4(4.680e-02, -2.848e-02, -7.357e-02, 3.978e-02, 5.286e-02, 2.245e-03, 1.039e-01, -1.021e-01, -4.228e-02, 1.450e-01, 3.733e-01, 1.024e-01, 2.823e-02, -1.629e-02, -2.389e-01, 8.868e-02) * s1[y+2][x+2];
	r += V4(-6.740e-03, -2.527e-02, 1.344e-03, 2.127e-02);
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
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(2.522e-02, -1.529e-02, -3.981e-02, -9.355e-03, -8.383e-02, 5.865e-02, -2.860e-02, 1.273e-02, -5.243e-02, 4.334e-02, -1.371e-03, 8.187e-02, 3.613e-03, -6.394e-03, 1.094e-02, -2.407e-02) * s0[y+0][x+0];
	r += M4(7.791e-02, -5.799e-02, 5.074e-02, -5.517e-02, 1.411e-01, -7.864e-02, 7.574e-02, -8.018e-02, 1.149e-01, -6.074e-02, 3.892e-02, 1.239e-02, 9.364e-02, -6.314e-02, -4.839e-02, -1.010e-01) * s0[y+0][x+1];
	r += M4(-1.924e-02, -2.560e-03, 2.389e-03, 8.464e-03, -2.034e-01, 6.915e-02, -4.943e-02, -2.936e-02, -1.475e-02, -2.240e-02, -4.809e-02, -5.848e-02, -1.593e-02, -1.396e-03, 3.677e-02, 2.129e-02) * s0[y+0][x+2];
	r += M4(6.272e-02, -9.478e-02, -4.481e-02, 2.306e-01, 1.526e-01, -1.361e-01, -1.415e-02, -7.417e-04, -3.405e-02, 6.119e-02, 2.398e-01, 4.792e-02, -1.314e-01, 1.606e-01, 2.819e-03, -3.245e-04) * s0[y+1][x+0];
	r += M4(1.842e-01, -3.765e-01, 7.248e-02, 1.213e-01, -2.492e-01, 2.647e-01, -6.319e-02, 3.076e-01, 1.334e-02, -8.668e-02, -1.733e-01, 4.947e-02, 2.131e-01, -1.880e-01, -1.591e-01, 1.986e-01) * s0[y+1][x+1];
	r += M4(-7.153e-02, -1.530e-02, -8.105e-03, -4.163e-02, -6.373e-02, -1.745e-01, -9.109e-01, -9.980e-01, 2.276e-02, 7.599e-03, 6.606e-02, 1.760e-02, -6.909e-02, 4.260e-02, 1.279e-01, 1.422e-02) * s0[y+1][x+2];
	r += M4(-2.685e-02, -1.987e-01, 1.006e-01, -9.205e-02, 1.146e-02, -2.790e-02, 5.787e-02, 3.063e-03, -6.086e-02, 3.772e-02, 1.972e-02, 3.376e-02, -3.796e-02, 4.665e-02, -5.364e-02, -4.077e-03) * s0[y+2][x+0];
	r += M4(1.213e-02, -1.703e-01, 2.021e-01, 1.592e-03, -1.201e-01, -4.822e-02, 1.334e-01, 1.095e-02, 1.109e-02, -2.313e-02, -4.222e-02, -4.481e-02, 6.505e-03, -1.396e-01, 5.944e-02, -7.083e-02) * s0[y+2][x+1];
	r += M4(-3.298e-03, 7.803e-03, -3.332e-02, 1.035e-02, 2.552e-01, 2.902e-01, -4.106e-01, -7.679e-02, 2.934e-02, -3.813e-03, 1.340e-02, -1.900e-03, 4.776e-02, 3.918e-02, -1.259e-02, -2.186e-02) * s0[y+2][x+2];
	r += M4(-1.234e-01, 1.902e-01, 4.993e-02, 1.208e-01, -2.159e-02, 1.182e-02, -3.139e-02, 3.350e-02, -1.762e-01, 3.777e-01, -5.464e-02, -1.784e-02, -4.137e-02, 1.318e-02, -1.587e-01, -2.139e-01) * s1[y+0][x+0];
	r += M4(1.312e-01, -1.829e-01, 2.849e-01, 1.028e-01, 8.036e-02, -3.308e-02, 1.279e-02, -6.712e-02, 3.799e-01, 1.071e+00, -2.626e-01, -4.457e-01, 8.673e-02, -2.481e-02, -3.798e-01, -4.879e-01) * s1[y+0][x+1];
	r += M4(1.154e-02, -1.050e-02, -2.940e-02, -3.366e-02, 2.863e-02, -4.738e-02, 2.590e-02, 1.041e-02, -3.680e-02, 1.315e-01, 8.513e-02, 1.018e-01, -9.385e-02, -5.875e-02, -3.890e-02, -1.081e-01) * s1[y+0][x+2];
	r += M4(-4.546e-01, 3.330e-01, -1.949e-01, 1.567e-01, -1.112e-01, 9.297e-02, 8.472e-02, 1.671e-02, 6.314e-02, 8.293e-02, 1.971e-01, 1.765e-01, -2.808e-01, 3.807e-01, -1.336e-01, 1.489e-01) * s1[y+1][x+0];
	r += M4(2.568e-01, -5.624e-02, 2.013e-02, 6.378e-02, 9.802e-02, -7.728e-02, -4.089e-01, 1.880e-01, -2.086e-01, 1.141e-01, -1.130e-02, 3.544e-01, 3.157e-01, -5.176e-01, -5.688e-01, 4.110e-01) * s1[y+1][x+1];
	r += M4(-3.661e-02, 1.611e-02, 8.814e-02, 2.034e-02, -6.274e-02, -6.409e-03, 8.917e-02, 3.748e-02, -7.587e-02, 1.507e-02, 7.509e-02, -4.223e-02, -2.784e-01, 2.425e-01, 1.300e-01, 3.239e-02) * s1[y+1][x+2];
	r += M4(-1.234e-01, 7.536e-02, -6.433e-02, 2.489e-02, -8.614e-03, 4.171e-02, 7.137e-02, 2.509e-02, -1.115e-02, -5.972e-02, 1.116e-01, -3.081e-02, -8.421e-02, 7.003e-02, -1.051e-02, 1.846e-02) * s1[y+2][x+0];
	r += M4(5.564e-02, -6.812e-02, 7.840e-02, -5.248e-03, -1.360e-01, -6.461e-02, 1.360e-02, -4.816e-02, 2.853e-02, -6.142e-02, 9.597e-02, -6.097e-02, -5.797e-03, -2.798e-01, 1.895e-01, -7.153e-02) * s1[y+2][x+1];
	r += M4(3.638e-02, -9.168e-03, 1.453e-02, 3.467e-03, 5.554e-02, 7.446e-02, 1.128e-02, 5.223e-03, -1.616e-02, 8.276e-02, -2.056e-02, -9.519e-03, -6.316e-03, 2.029e-01, -5.409e-02, 4.111e-02) * s1[y+2][x+2];
	r += V4(5.395e-03, -1.879e-03, 1.449e-02, -3.613e-03);
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(3.575e-02, 1.323e-02, -8.769e-02, -4.912e-02, 1.561e-01, 5.431e-02, 4.377e-02, -1.344e-01, -4.626e-02, -9.296e-03, 5.432e-02, 3.125e-02, 3.559e-02, 2.228e-02, -5.290e-02, -2.302e-02) * s0[y+0][x+0];
	r += M4(1.646e-02, 1.166e-02, -1.283e-02, -8.664e-02, 2.150e-01, -2.193e-01, 1.266e-02, 9.119e-04, -3.816e-02, -6.144e-02, -1.903e-03, 2.874e-02, 3.126e-02, 3.125e-02, 4.891e-02, -1.066e-02) * s0[y+0][x+1];
	r += M4(1.803e-03, -6.522e-03, -5.787e-03, -1.050e-02, -3.664e-02, 1.509e-01, -2.228e-02, 3.821e-02, -3.620e-03, 1.018e-03, -1.143e-02, -8.124e-04, -5.854e-03, 2.253e-03, -7.304e-03, 1.682e-02) * s0[y+0][x+2];
	r += M4(-2.900e-01, -1.184e-01, 2.265e-01, 7.423e-02, -5.488e-01, 7.239e-02, 7.366e-02, 3.115e-01, -2.231e-02, 5.210e-02, -1.124e-01, 5.035e-03, 6.616e-02, 1.383e-02, -1.047e-01, -1.726e-03) * s0[y+1][x+0];
	r += M4(-2.407e-02, -1.304e-01, 2.531e-02, 2.572e-01, 4.268e-01, -2.403e-01, 4.352e-01, -1.868e-01, -1.743e-01, -1.802e-01, -2.358e-01, -2.510e-01, 3.987e-01, 3.410e-01, 1.760e-01, -4.256e-02) * s0[y+1][x+1];
	r += M4(1.263e-02, 6.744e-03, 1.814e-02, -2.550e-02, -1.828e-02, 2.017e-02, -7.159e-02, 3.057e-02, 3.259e-02, -3.559e-02, 2.441e-02, -6.536e-02, -6.214e-02, 3.666e-02, -4.460e-03, 9.201e-02) * s0[y+1][x+2];
	r += M4(-1.532e-02, 1.649e-02, -1.529e-02, -9.647e-03, 9.029e-02, -1.623e-02, -1.302e-01, -4.144e-03, 7.836e-02, 1.470e-02, -1.851e-02, 2.913e-03, -3.018e-01, -7.970e-02, 3.272e-01, 9.057e-02) * s0[y+2][x+0];
	r += M4(2.931e-02, 1.289e-02, 6.117e-02, 3.553e-02, -9.324e-02, 2.360e-02, 2.420e-02, -7.108e-03, -4.240e-03, 6.469e-02, 4.343e-02, -1.230e-02, -4.611e-02, -2.953e-01, 3.751e-01, 5.959e-01) * s0[y+2][x+1];
	r += M4(-6.290e-03, -1.388e-03, 1.869e-02, 3.287e-02, 1.275e-02, -1.081e-02, 3.382e-02, 7.897e-03, -6.275e-03, -2.473e-02, 8.636e-03, 3.070e-02, 5.764e-02, 7.033e-02, 3.662e-03, 8.864e-03) * s0[y+2][x+2];
	r += M4(2.616e-01, 1.500e-02, -1.158e-01, -1.006e-01, 7.651e-02, 1.557e-02, -7.734e-02, -5.378e-02, -2.356e-02, -9.706e-03, 1.026e-01, 1.619e-02, -1.531e-02, 1.910e-02, -4.269e-02, 6.828e-03) * s1[y+0][x+0];
	r += M4(-7.737e-02, -5.652e-02, 6.329e-02, -3.237e-02, -1.708e-02, 6.716e-02, -1.189e-02, -2.387e-02, 8.515e-03, -1.979e-01, 8.666e-02, 9.790e-02, 6.437e-02, 1.706e-02, 2.166e-02, -5.799e-02) * s1[y+0][x+1];
	r += M4(-2.294e-03, 5.369e-02, -3.694e-02, -2.149e-02, 1.751e-02, -1.011e-02, 1.289e-02, -7.843e-03, -3.381e-02, 1.499e-02, -2.703e-03, -1.431e-02, -9.132e-03, 6.533e-03, -8.793e-03, 1.714e-02) * s1[y+0][x+2];
	r += M4(-2.407e-01, -3.506e-01, 5.762e-01, -4.249e-02, -4.111e-01, -1.116e-01, 2.353e-01, 1.125e-01, -4.067e-02, -9.840e-03, -1.423e-01, 1.187e-02, -3.826e-03, 5.871e-02, -1.791e-01, -3.917e-02) * s1[y+1][x+0];
	r += M4(-2.873e-01, 3.841e-01, -4.971e-01, 3.772e-01, 4.117e-02, -3.154e-01, 3.966e-02, 1.732e-01, -4.678e-02, -2.474e-01, -1.900e-01, -5.449e-01, 2.318e-01, 1.646e-01, 2.651e-01, 1.101e-01) * s1[y+1][x+1];
	r += M4(1.058e-01, -1.155e-01, 8.640e-02, -8.182e-02, -4.407e-02, 2.399e-02, -9.789e-03, -1.498e-02, -2.667e-02, -8.511e-03, -4.191e-02, -1.167e-02, -1.593e-02, 2.950e-02, -1.758e-02, 4.038e-02) * s1[y+1][x+2];
	r += M4(-4.327e-02, 1.077e-01, -1.480e-01, -2.318e-02, 9.619e-02, 2.545e-02, -6.051e-02, -3.699e-02, 8.082e-02, 1.796e-02, -3.572e-02, -4.991e-02, -2.173e-01, -6.470e-02, 1.431e-01, 8.765e-02) * s1[y+2][x+0];
	r += M4(-1.559e-02, -3.448e-02, -1.309e-02, 2.568e-01, -4.460e-02, 6.591e-02, -3.614e-02, -5.864e-02, -1.561e-02, 4.145e-02, 6.519e-02, -2.584e-02, 1.026e-01, -9.644e-02, 7.750e-02, 1.491e-01) * s1[y+2][x+1];
	r += M4(2.802e-02, -7.858e-03, 6.213e-02, -5.921e-02, 1.806e-02, -6.910e-03, 4.941e-03, 3.568e-03, 9.970e-03, -1.935e-02, -5.427e-03, 2.604e-02, -9.102e-03, 5.872e-02, -1.372e-02, -1.085e-02) * s1[y+2][x+2];
	r += V4(4.288e-03, 4.197e-03, 3.060e-03, 3.212e-03);
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

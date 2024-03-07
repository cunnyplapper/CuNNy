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
	r += V4(-1.191e-02, 5.380e-01, -4.100e-02, -9.613e-03) * s0[y+0][x+0];
	r += V4(-2.593e-04, 1.651e-02, -7.396e-02, 9.011e-03) * s0[y+0][x+1];
	r += V4(2.003e-03, -1.925e-02, 1.189e-01, -8.210e-03) * s0[y+0][x+2];
	r += V4(-2.474e-02, -5.667e-01, 3.398e-02, 4.905e-01) * s0[y+1][x+0];
	r += V4(-4.899e-03, 4.666e-03, 5.367e-01, -5.176e-01) * s0[y+1][x+1];
	r += V4(-5.075e-03, 1.947e-02, -4.018e-01, 1.915e-02) * s0[y+1][x+2];
	r += V4(6.466e-01, 2.435e-02, 1.825e-02, -8.808e-02) * s0[y+2][x+0];
	r += V4(-2.147e-02, -1.521e-02, -1.116e-02, 1.135e-01) * s0[y+2][x+1];
	r += V4(-1.339e-02, -5.651e-03, -1.798e-01, -8.393e-03) * s0[y+2][x+2];
	r += V4(-9.293e-03, 3.958e-03, -2.411e-03, -1.341e-03);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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
	r += M4(-6.561e-03, -9.095e-02, -7.348e-02, 3.981e-02, -3.430e-03, -1.822e-02, 3.497e-02, -2.212e-03, -7.705e-02, -5.075e-02, -7.016e-01, -5.869e-02, -5.016e-02, -4.143e-03, -2.179e-01, 6.220e-02) * s0[y+0][x+0];
	r += M4(4.822e-02, -5.792e-02, -3.364e-02, 7.650e-03, -6.768e-02, 6.883e-02, 7.934e-02, 5.615e-02, -1.460e-01, -5.131e-02, -1.933e-02, 1.269e-01, 1.709e-04, -2.666e-01, 1.477e-01, 3.304e-02) * s0[y+0][x+1];
	r += M4(-1.099e-01, 1.410e-02, -2.907e-02, 1.516e-01, -6.452e-03, -1.332e-01, 1.321e-02, 6.760e-02, 6.672e-03, -8.976e-04, -2.482e-02, 7.857e-03, 1.382e-01, -3.531e-01, 1.502e-01, -6.904e-02) * s0[y+0][x+2];
	r += M4(1.308e-01, 4.894e-03, 5.232e-02, 5.258e-02, 1.243e-01, 1.800e-03, 1.265e-01, -1.170e-01, 3.494e-01, 1.290e-01, -6.772e-01, -4.265e-01, 4.069e-01, 1.180e-01, 2.377e-01, -1.003e-01) * s0[y+1][x+0];
	r += M4(8.364e-02, 8.640e-02, -3.071e-02, -1.333e-01, 5.181e-01, 2.220e-02, 1.815e-01, -1.773e-01, -2.961e-01, -1.994e-02, 1.715e-01, -3.401e-03, 6.387e-01, -1.123e-01, 5.526e-01, -9.424e-01) * s0[y+1][x+1];
	r += M4(-8.727e-02, 1.100e-01, 1.743e-01, -1.047e-01, 3.678e-01, -2.368e-01, 6.419e-02, 8.491e-02, 2.571e-03, 7.394e-02, 8.243e-03, -7.813e-02, 1.264e-01, -6.389e-01, -3.955e-01, 7.832e-01) * s0[y+1][x+2];
	r += M4(-8.874e-04, 8.757e-03, 2.418e-03, -1.661e-02, -1.239e-02, -1.533e-02, -1.782e-01, 1.037e-01, -2.026e-01, -1.008e-02, 5.977e-02, 9.316e-02, -1.340e-01, -8.338e-02, -2.607e-01, 2.203e-02) * s0[y+2][x+0];
	r += M4(-4.870e-02, -6.800e-02, 2.667e-02, -2.729e-02, -2.058e-01, -2.070e-01, 1.575e-01, -5.907e-02, 1.677e-01, 1.332e-01, -9.173e-02, 4.244e-02, -3.312e-01, 4.284e-02, -4.059e-01, -1.983e-01) * s0[y+2][x+1];
	r += M4(-2.014e-02, -6.105e-02, -9.568e-02, 7.915e-02, -3.230e-01, -2.939e-01, 5.378e-02, -2.113e-01, -1.824e-02, -4.640e-02, 1.994e-02, 9.401e-02, -4.691e-02, -8.116e-02, -2.998e-02, 2.250e-01) * s0[y+2][x+2];
	r += M4(-3.432e-01, 1.332e-01, 1.783e+00, -2.630e-01, -1.946e-02, -2.397e-02, 5.844e-03, -3.519e-02, -4.561e-01, 4.329e-01, -3.248e-01, -1.263e-01, -1.493e-01, 1.250e-01, -7.919e-02, 1.848e-01) * s1[y+0][x+0];
	r += M4(-4.224e+00, -4.505e-01, 9.079e-01, -2.641e+00, -8.980e-02, 5.884e-02, -2.230e-02, -4.650e-02, 3.208e-01, -3.486e-01, 2.741e-01, -8.613e-03, -1.786e-01, -1.943e-01, -6.936e-02, 5.025e-01) * s1[y+0][x+1];
	r += M4(-4.631e+00, -2.784e+00, -4.944e+00, 3.957e+00, 4.125e-02, 5.940e-02, -4.382e-02, 6.146e-02, 6.424e-02, -1.215e-02, 4.503e-02, -1.755e-01, -3.717e-01, 4.832e-02, -9.483e-02, 3.759e-02) * s1[y+0][x+2];
	r += M4(5.160e-02, -3.278e-01, -1.083e-01, -5.229e-01, 2.282e-01, -1.071e-01, 1.022e-02, -1.529e-01, -1.426e-01, 2.310e-01, 4.173e-01, -4.586e-01, 1.397e-01, 7.892e-02, 1.483e-01, -1.572e-01) * s1[y+1][x+0];
	r += M4(-1.055e-01, -3.074e-02, -1.168e+00, -3.618e-01, 2.060e-03, 4.343e-01, 1.396e-01, -1.727e-01, -1.365e-01, 2.908e-02, 3.271e-01, -2.608e-01, 4.540e-01, 6.797e-01, 2.912e-01, -6.853e-02) * s1[y+1][x+1];
	r += M4(1.857e-02, -1.066e+00, 7.655e-01, 1.529e+00, -2.980e-01, 3.401e-01, -5.026e-02, 6.615e-02, 1.321e-01, 6.249e-02, 3.210e-02, -1.567e-01, -5.181e-01, -3.721e-01, -6.241e-01, 9.413e-01) * s1[y+1][x+2];
	r += M4(-1.783e-01, -2.051e-02, 4.721e-01, -9.066e-02, 9.403e-03, -4.514e-02, -3.171e-01, 6.534e-02, 4.752e-02, -1.316e-01, 1.569e-01, 3.683e-01, -4.439e-02, -4.030e-02, -3.984e-01, 3.702e-02) * s1[y+2][x+0];
	r += M4(3.790e-01, 4.980e-01, -9.708e-02, 3.027e-01, -1.931e-01, -1.521e-01, 2.642e-01, 4.389e-01, 6.979e-02, -2.354e-02, -2.793e-02, 7.415e-02, -3.827e-02, 1.235e-01, -2.754e-01, 3.579e-01) * s1[y+2][x+1];
	r += M4(4.272e-01, 6.229e-01, 1.667e-01, -4.941e-02, -1.555e-01, -4.333e-01, 6.269e-01, 4.733e-01, -1.658e-02, -1.650e-01, -1.945e-02, 8.075e-03, -3.673e-02, -3.694e-01, -1.600e-01, 3.356e-01) * s1[y+2][x+2];
	r += V4(-3.046e-03, 5.958e-03, 7.724e-03, -1.593e-02);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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
	r += M4(6.346e-02, -1.038e-01, -2.004e-03, -4.654e-02, 7.690e-02, -1.250e-02, -1.029e-01, -4.298e-02, -1.419e-02, 9.481e-02, -1.716e-01, -1.670e-02, -1.876e-02, 9.999e-02, 1.079e-01, 1.380e-01) * s0[y+0][x+0];
	r += M4(6.287e-02, 8.835e-02, -9.162e-03, 1.129e-01, 1.355e-01, -1.044e-02, -7.767e-01, -1.267e-01, -6.907e-02, 1.852e-01, -2.279e-01, -5.702e-02, -9.945e-02, 6.315e-02, -1.223e-02, -9.746e-02) * s0[y+0][x+1];
	r += M4(8.151e-03, 1.720e-02, -1.130e-01, -1.951e-01, 2.283e-01, 1.715e-02, -1.051e-01, 4.349e-02, -2.427e-01, -1.155e-01, 4.755e-02, -2.914e-01, -4.097e-02, 3.420e-03, 6.059e-03, -7.570e-02) * s0[y+0][x+2];
	r += M4(-1.307e-02, -1.130e-01, -7.389e-03, 2.063e-02, -2.080e-01, 2.631e-01, -1.655e-01, -1.131e-01, -1.452e-01, 2.568e-01, -5.148e-02, 3.426e-02, -1.105e-01, 7.813e-01, -2.772e-01, 4.036e-01) * s0[y+1][x+0];
	r += M4(1.873e-03, 5.106e-01, -3.111e-01, -2.468e-01, -5.645e-01, 2.662e-01, -8.158e-01, -7.104e-01, -3.794e-01, 2.725e-01, -4.111e-01, -2.903e-01, -7.558e-01, 1.754e-01, -1.986e-01, -5.996e-01) * s0[y+1][x+1];
	r += M4(-8.430e-02, 1.851e-01, -1.430e-01, -2.607e-01, -2.957e-01, 1.997e-01, -1.139e-01, -3.799e-01, -4.124e-02, -1.960e-01, -2.376e-01, -2.920e-01, -2.204e-01, 9.043e-02, -2.125e-01, -2.081e-01) * s0[y+1][x+2];
	r += M4(2.909e-03, -2.089e-02, 5.687e-02, 2.316e-02, -1.803e-01, 2.686e-01, -3.797e-02, 7.355e-02, -4.973e-02, 1.024e-01, -1.803e-02, 6.409e-03, 3.116e-01, -2.342e-01, 1.227e-01, 1.699e-01) * s0[y+2][x+0];
	r += M4(-4.952e-01, 2.132e-01, 1.800e-02, -1.657e-01, 3.664e-01, -1.734e-01, -5.094e-02, 9.543e-02, -2.081e-01, 2.683e-01, -5.999e-02, -8.150e-02, 3.999e-01, -1.130e-01, -1.229e-01, 1.132e-01) * s0[y+2][x+1];
	r += M4(-2.153e-01, 8.765e-02, 3.099e-02, -1.248e-01, 8.695e-02, 2.352e-02, 1.386e-01, 8.594e-02, 2.545e-01, -3.562e-01, -1.538e-01, -1.635e-01, 1.890e-01, -8.508e-02, 8.813e-02, 1.475e-01) * s0[y+2][x+2];
	r += M4(-9.688e-02, -8.683e-02, -1.713e-01, -2.339e-01, 1.007e-02, -3.676e-02, -3.467e-02, -5.818e-02, 3.373e-02, -9.922e-02, 4.332e-02, -2.010e-02, -1.808e-03, -2.992e-02, 5.492e-02, 1.651e-02) * s1[y+0][x+0];
	r += M4(4.126e-01, 1.580e-03, -2.116e-01, 2.406e-01, -5.626e-03, 6.810e-02, -7.000e-02, 3.259e-02, 1.720e-01, 2.069e-01, -4.160e-02, 2.063e-01, -4.350e-03, 5.827e-02, 1.420e-01, 2.855e-02) * s1[y+0][x+1];
	r += M4(-2.574e-02, 1.077e-01, -2.627e-01, -7.882e-02, 1.302e-02, -1.474e-02, 1.144e-02, -6.316e-02, -1.063e-02, -1.116e-02, 7.135e-02, 3.827e-02, -3.943e-02, -2.313e-03, -1.162e-01, -3.172e-01) * s1[y+0][x+2];
	r += M4(1.958e-01, -5.080e-01, 1.392e-01, -2.398e-01, -1.543e-02, 3.153e-02, -3.172e-02, 7.564e-03, 9.275e-02, -2.513e-01, 1.621e-01, -9.062e-02, -4.484e-02, 2.652e-01, -1.726e-01, 4.759e-02) * s1[y+1][x+0];
	r += M4(-8.258e-02, 2.715e-01, 1.666e-01, 1.411e-01, -4.318e-03, 1.589e-01, -1.747e-02, -9.442e-02, 5.530e-02, 2.797e-01, 1.025e-01, 1.889e-01, -3.233e-01, -1.439e-01, -4.659e-01, -3.078e-01) * s1[y+1][x+1];
	r += M4(2.359e-02, 2.833e-01, -4.932e-02, 2.256e-01, -1.082e-01, 4.779e-02, -1.508e-01, -1.451e-01, 4.347e-03, -1.091e-01, 2.333e-02, 8.115e-02, -2.166e-01, 1.850e-01, -2.003e-01, -4.469e-01) * s1[y+1][x+2];
	r += M4(-4.909e-03, -6.059e-02, 3.468e-02, -8.696e-02, -9.497e-02, 1.512e-02, 2.601e-02, -3.952e-02, -1.098e-01, 5.916e-02, -2.225e-02, -3.083e-02, 3.382e-02, 2.296e-02, 3.476e-02, 6.183e-02) * s1[y+2][x+0];
	r += M4(-8.074e-02, 9.810e-02, -1.071e-01, -1.036e-01, -2.438e-02, 5.077e-03, 8.690e-02, 9.564e-02, -6.983e-02, -2.440e-02, 5.148e-02, -4.935e-03, 2.085e-01, -1.567e-01, 1.440e-01, 1.315e-01) * s1[y+2][x+1];
	r += M4(-1.228e-01, 2.045e-01, -1.061e-01, -2.656e-02, 2.334e-02, -7.199e-02, 7.242e-02, 3.773e-02, 1.860e-01, -2.424e-02, -3.767e-02, 6.629e-02, 2.727e-02, -6.625e-02, 7.642e-02, -1.917e-02) * s1[y+2][x+2];
	r += V4(-1.140e-02, 1.459e-02, -8.287e-03, -1.605e-02);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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
	r += M4(-4.014e-02, 7.097e-02, -3.876e-03, 1.353e-01, 5.123e-02, 2.571e-02, -3.126e-03, -1.920e-02, -2.399e-02, -2.170e-02, -4.614e-02, -2.598e-02, -1.304e-01, -1.858e-03, 8.171e-03, -5.818e-03) * s0[y+0][x+0];
	r += M4(5.802e-01, 1.378e-01, -2.458e-01, -3.148e-01, 1.372e-02, 1.007e-01, 3.499e-02, 1.177e-01, -6.714e-02, -4.596e-03, 3.799e-01, 1.032e-01, 6.091e-02, -5.617e-02, -6.506e-02, -1.900e-02) * s0[y+0][x+1];
	r += M4(-1.103e-01, 2.654e-01, -2.136e-03, -4.014e-02, 2.590e-02, -1.497e-02, -2.484e-02, -8.434e-02, -1.017e-01, -1.274e-01, 5.662e-02, 3.497e-01, 1.635e-02, -1.448e-01, 3.916e-02, -4.541e-02) * s0[y+0][x+2];
	r += M4(7.680e-03, 2.122e-01, 3.481e-03, 1.085e-01, -1.401e-03, 4.478e-02, 5.350e-03, 7.935e-02, 4.155e-02, -2.041e-02, 1.205e-01, -5.344e-03, -1.764e-01, 3.907e-01, -2.529e-01, 1.040e-01) * s0[y+1][x+0];
	r += M4(-1.121e+00, -9.894e-01, 6.277e-01, 1.667e-01, -2.332e-01, -2.974e-01, -2.882e-01, -3.233e-01, 4.708e-01, 1.594e-01, -1.073e+00, -1.879e-01, 1.171e+00, -8.546e-01, 8.854e-01, -2.130e-01) * s0[y+1][x+1];
	r += M4(1.277e-02, -3.101e-01, 7.082e-03, 3.799e-01, -2.898e-02, -1.057e-02, 8.359e-03, -1.402e-02, 2.567e-01, 5.801e-01, -1.812e-01, -9.812e-01, -2.475e-01, 5.724e-01, -1.554e-01, 2.515e-01) * s0[y+1][x+2];
	r += M4(2.585e-03, -8.822e-02, 5.685e-03, -1.958e-02, -1.370e-02, -4.911e-02, 2.683e-02, -3.700e-02, 4.524e-03, -1.839e-02, -6.492e-02, -9.077e-02, -3.358e-02, -6.670e-02, -8.912e-02, 2.194e-01) * s0[y+2][x+0];
	r += M4(2.979e-01, 2.099e-01, -2.065e-01, -2.270e-01, -4.482e-03, -2.079e-02, 2.985e-02, -4.568e-03, -1.460e-01, -5.537e-02, 4.053e-01, 1.236e-01, -6.208e-03, 7.841e-02, 3.755e-01, -6.816e-01) * s0[y+2][x+1];
	r += M4(-7.137e-02, 8.407e-02, -2.877e-02, 7.498e-04, -4.681e-03, -9.731e-03, 8.508e-03, 5.759e-02, -5.206e-02, -1.668e-01, 1.218e-01, 3.916e-01, 1.625e-02, -1.945e-02, -1.187e-01, 2.115e-01) * s0[y+2][x+2];
	r += M4(4.501e-02, 7.531e-02, 5.791e-03, 8.296e-02, 2.734e-02, 1.075e-02, -1.925e-02, 2.828e-02, 1.485e-02, -1.204e-02, -1.850e-02, -1.800e-02, -4.030e-02, -5.722e-03, 1.920e-02, 1.312e-02) * s1[y+0][x+0];
	r += M4(4.609e-02, -6.393e-02, -2.046e-02, -1.314e-01, -2.034e-01, 2.230e-01, 5.600e-02, 6.426e-02, 1.684e-02, 4.472e-02, 4.538e-02, 4.343e-02, -1.358e-02, -4.419e-03, -3.491e-02, 5.188e-03) * s1[y+0][x+1];
	r += M4(-1.324e-02, 7.593e-02, 3.560e-03, 3.596e-02, 4.326e-01, -4.123e-01, 3.862e-02, -5.139e-02, -6.204e-03, 2.155e-02, -2.523e-02, -5.487e-03, 1.697e-02, -6.207e-02, 9.184e-04, -6.184e-02) * s1[y+0][x+2];
	r += M4(2.456e-02, 4.379e-02, -7.894e-03, 3.470e-02, 1.165e-02, -6.317e-02, 3.777e-02, -3.067e-02, 1.452e-02, -6.213e-02, 2.715e-02, 1.472e-03, 5.773e-03, 1.160e-02, -1.191e-02, -4.196e-02) * s1[y+1][x+0];
	r += M4(-3.010e-01, -3.271e-01, -2.533e-01, -3.101e-01, -5.410e-01, 2.408e-02, -8.613e-01, 5.917e-02, -1.932e-01, 1.491e-02, -2.397e-01, -7.180e-02, 2.783e-01, 2.197e-01, 3.134e-01, 2.705e-01) * s1[y+1][x+1];
	r += M4(2.164e-02, -4.647e-02, -1.591e-02, -4.523e-02, 5.605e-01, -4.078e-01, 7.286e-01, -9.105e-01, 1.412e-02, -1.081e-01, 1.084e-02, -1.057e-01, -3.788e-02, 9.180e-02, -2.352e-03, 1.025e-01) * s1[y+1][x+2];
	r += M4(-1.541e-02, -3.169e-02, 2.756e-02, -2.193e-02, -1.725e-02, 1.128e-02, 5.308e-03, -2.213e-02, -1.911e-02, -3.268e-02, 2.112e-02, -6.332e-02, 1.523e-02, 3.196e-02, -2.545e-02, 4.124e-02) * s1[y+2][x+0];
	r += M4(2.760e-02, -2.198e-02, 2.503e-02, -1.422e-02, 1.026e-02, -1.287e-01, 7.100e-02, -2.216e-02, -1.445e-02, -2.045e-02, 2.263e-02, 9.588e-02, -2.429e-02, 9.741e-03, -4.602e-02, -5.168e-02) * s1[y+2][x+1];
	r += M4(-1.520e-02, 1.048e-02, 8.187e-03, 5.009e-02, -1.206e-01, -4.864e-02, 5.716e-02, 6.164e-02, -2.496e-02, -1.133e-02, -8.470e-05, 1.249e-02, 3.415e-02, -5.599e-03, 9.292e-03, -2.743e-02) * s1[y+2][x+2];
	r += V4(1.807e-03, 2.006e-03, 1.498e-03, 1.541e-03);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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

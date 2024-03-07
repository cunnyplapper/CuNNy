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
	r += V4(-1.886e-02, 1.247e-02, 1.535e-02, -1.938e-02) * s0[y+0][x+0];
	r += V4(5.441e-02, -3.331e-03, 4.802e-03, 3.250e-02) * s0[y+0][x+1];
	r += V4(-4.178e-02, 2.541e-03, -1.906e-02, 1.103e-03) * s0[y+0][x+2];
	r += V4(-4.268e-01, 2.253e-02, -1.865e-02, -1.161e-01) * s0[y+1][x+0];
	r += V4(6.510e-01, -8.765e-03, -6.908e-01, -5.566e-01) * s0[y+1][x+1];
	r += V4(-4.528e-03, -1.077e-04, 2.694e-01, 1.336e-02) * s0[y+1][x+2];
	r += V4(-1.294e-01, -7.505e-01, 1.991e-02, 6.813e-01) * s0[y+2][x+0];
	r += V4(-4.347e-02, -1.482e-02, 1.043e-01, -3.504e-02) * s0[y+2][x+1];
	r += V4(2.593e-02, 2.036e-02, 3.177e-01, 4.827e-03) * s0[y+2][x+2];
	r += V4(-7.283e-02, 8.784e-03, -3.335e-03, -3.521e-03);
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
	r += M4(2.226e-02, -3.823e-02, -3.903e-02, 5.464e-02, 3.943e-01, 6.604e-01, -1.571e-01, -9.977e-02, -1.539e-01, -1.265e-01, -1.220e-01, 2.452e-02, -2.436e-02, 4.308e-02, 2.854e-02, 5.494e-02) * s0[y+0][x+0];
	r += M4(-1.178e-01, 1.059e-01, 1.392e-01, -5.107e-02, 2.696e+00, 2.708e+00, -1.230e+00, -1.526e+00, 3.134e-01, -3.076e-02, 6.762e-02, -1.481e-01, 2.028e-01, -6.845e-02, 2.380e-02, 3.363e-01) * s0[y+0][x+1];
	r += M4(-1.711e-01, 3.450e-02, 3.654e-02, -4.099e-01, -2.115e+00, 1.461e+00, -1.187e+00, -2.804e+00, 1.984e-01, 2.128e-02, 1.142e-02, -6.686e-02, -3.195e-01, 1.008e-01, 4.586e-02, -7.231e-02) * s0[y+0][x+2];
	r += M4(-1.886e-01, -1.505e-01, -9.332e-03, -5.137e-02, 6.417e-01, 8.519e-02, -2.576e-02, -3.820e-01, 4.762e-01, 2.491e-02, 1.148e-01, 2.358e-01, 8.988e-02, -5.138e-03, -6.359e-02, -1.457e-01) * s0[y+1][x+0];
	r += M4(-2.714e-01, 2.799e-01, -7.117e-02, 6.648e-01, -5.560e-01, 1.295e+00, -8.592e+00, 2.338e-01, 5.424e-01, -3.101e-01, -1.617e-01, -1.215e+00, -2.328e-01, -7.518e-01, 1.064e-01, -6.920e-01) * s0[y+1][x+1];
	r += M4(-3.156e-01, 2.235e-01, 7.585e-02, -3.242e-01, -3.703e+00, 2.882e+00, -7.749e+00, -1.624e+00, 1.842e-01, 1.674e-01, -1.138e-02, -1.404e-01, 2.555e-01, -3.074e-01, -5.706e-02, -2.937e-01) * s0[y+1][x+2];
	r += M4(4.741e-01, 1.746e-01, 1.793e-01, -2.104e-01, 8.141e-02, 1.356e+00, 2.198e-01, -7.245e-01, 8.304e-02, 2.118e-01, -2.194e-02, 3.494e-02, -8.910e-02, -1.280e-01, -6.687e-02, 9.616e-02) * s0[y+2][x+0];
	r += M4(2.039e-01, -5.234e-02, 7.387e-01, -4.998e-01, -2.670e-01, 2.452e+00, -1.269e+00, -1.029e+00, -1.024e-01, -1.830e-01, -7.856e-02, -2.578e-01, -3.218e-01, -1.381e-01, 1.030e-01, 1.647e-01) * s0[y+2][x+1];
	r += M4(-3.458e-01, 3.621e-01, -1.084e-01, -6.013e-02, -7.081e-01, 2.377e+00, -1.367e+00, -1.643e+00, -1.050e-01, -5.794e-02, 4.893e-02, 1.373e-01, 1.348e-01, -8.012e-02, -7.253e-02, -5.357e-02) * s0[y+2][x+2];
	r += M4(-5.399e-02, 1.661e-02, -2.868e-03, 6.641e-02, 3.058e-02, 3.129e-02, 5.399e-02, 6.794e-02, -2.006e-01, -8.802e-02, -1.924e-01, 3.506e-01, 8.241e-02, 7.368e-02, 3.871e-02, 1.745e-04) * s1[y+0][x+0];
	r += M4(1.546e-01, 1.345e-01, 1.009e-01, -2.601e-02, 1.584e-01, -1.398e-02, -8.081e-02, 3.181e-02, -2.931e-02, 8.331e-02, -3.248e-02, 1.409e-01, 4.339e-01, 2.428e-01, 2.358e-02, 3.662e-01) * s1[y+0][x+1];
	r += M4(-1.913e-01, -3.092e-02, 5.160e-02, -2.053e-01, -1.381e-01, -6.431e-02, 3.137e-02, 4.052e-02, 3.338e-02, 1.023e-01, 4.404e-03, -1.325e-01, -4.483e-01, 5.996e-03, 2.198e-02, 5.661e-01) * s1[y+0][x+2];
	r += M4(1.358e-02, -1.948e-01, -1.178e-02, -1.763e-01, 1.209e-01, 2.500e-02, -1.160e-01, -4.049e-02, -1.891e-01, -8.093e-04, 2.953e-01, 7.286e-01, 2.881e-01, 1.007e-01, -1.079e-01, -2.412e-01) * s1[y+1][x+0];
	r += M4(3.467e-01, 9.396e-01, -2.324e-01, 4.565e-01, 8.395e-03, -2.586e-01, -8.129e-02, -2.227e-01, -4.517e-01, -3.821e-01, -1.341e-01, -1.468e-01, 2.253e-03, -5.102e-02, 6.874e-02, -3.993e-01) * s1[y+1][x+1];
	r += M4(-1.312e-01, -3.856e-02, -1.247e-02, 5.748e-02, -2.640e-01, 1.355e-01, -1.910e-01, -2.485e-01, -1.539e-01, -2.801e-04, -1.672e-02, 8.902e-02, -1.000e-01, 2.436e-01, 3.934e-01, -7.148e-02) * s1[y+1][x+2];
	r += M4(9.196e-02, 2.583e-02, 1.127e-01, 7.875e-02, -1.040e-01, -5.985e-02, -1.834e-01, 1.418e-02, 1.021e-01, -6.952e-03, -1.528e-02, 1.607e-01, 5.613e-02, 1.268e-02, -1.435e-01, -1.026e-01) * s1[y+2][x+0];
	r += M4(5.318e-01, -4.246e-01, 2.373e-01, -2.509e-01, -7.969e-02, 7.541e-02, -2.479e-01, 1.841e-01, -3.733e-01, -8.585e-02, 5.595e-02, -1.405e-01, -1.932e-01, 4.424e-01, -1.931e-01, -9.288e-02) * s1[y+2][x+1];
	r += M4(-1.715e-01, 2.196e-01, -4.732e-02, 1.604e-01, 1.274e-01, -3.122e-01, 5.582e-02, 7.156e-03, 7.593e-02, -1.390e-01, 2.385e-03, 8.032e-02, 3.013e-01, 8.646e-02, -6.250e-02, -2.425e-01) * s1[y+2][x+2];
	r += V4(-9.221e-02, 6.627e-02, -5.323e-01, 2.664e-02);
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
	r += M4(1.825e-01, 8.190e-02, 1.012e-01, 1.051e-01, -1.468e-02, 8.260e-02, -5.037e-02, 6.386e-03, 5.052e-01, 6.771e-02, -9.073e-01, 1.137e+00, 2.044e-01, 6.975e-02, 1.130e-01, 8.929e-02) * s0[y+0][x+0];
	r += M4(4.558e-02, -1.224e-01, -3.516e-02, 1.379e-01, -1.246e-02, 1.017e-01, -5.205e-03, -2.842e-01, 8.626e-01, 8.127e-01, -1.854e+00, -1.196e+00, -1.004e-01, 5.518e-02, -1.686e-01, -1.561e-02) * s0[y+0][x+1];
	r += M4(-6.958e-03, -2.405e-02, 9.668e-02, -1.684e-01, 6.604e-02, 1.583e-02, -1.327e-01, -7.784e-02, 1.503e-01, 5.133e-02, -1.285e+00, -5.575e-01, -2.064e-02, 1.135e-02, -1.191e-01, -1.205e-01) * s0[y+0][x+2];
	r += M4(1.265e-01, 1.088e-01, 2.900e-02, 2.139e-01, -1.733e-01, -2.609e-01, -9.467e-02, -2.660e-01, 8.819e-01, -1.078e+00, -1.444e-01, 1.064e+00, -1.202e-01, 1.776e-01, -1.883e-01, -3.506e-01) * s0[y+1][x+0];
	r += M4(1.543e-01, 2.393e-01, -3.275e-01, 4.293e-01, 4.648e-01, -7.396e-02, -5.344e-01, -1.640e-01, -1.412e+00, 9.532e-02, -9.478e-01, -1.945e-01, 4.756e-01, 2.541e-01, -8.998e-01, -2.903e-01) * s0[y+1][x+1];
	r += M4(-6.522e-02, -4.196e-02, -1.503e-02, 3.583e-02, 3.195e-01, -1.545e-02, -9.540e-02, 1.309e-02, 2.618e-01, 2.922e-02, -9.087e-01, 8.436e-01, 2.806e-01, -1.898e-03, 4.324e-02, 1.009e-01) * s0[y+1][x+2];
	r += M4(3.324e-01, 9.882e-02, 2.911e-02, 3.092e-01, 1.068e-02, -2.465e-01, 6.712e-02, 3.054e-01, -3.270e-02, -6.024e-02, -2.906e-01, -3.945e-01, -2.314e-02, -6.305e-01, 1.057e-01, 2.181e-01) * s0[y+2][x+0];
	r += M4(-1.635e-01, -3.439e-03, 5.795e-02, 1.880e-01, -2.764e-01, -2.388e-01, 2.742e-02, -1.413e-01, 1.059e-01, -1.153e-01, -1.965e-01, 3.707e-02, -1.413e-01, -2.173e-01, 1.718e-01, 2.073e-01) * s0[y+2][x+1];
	r += M4(2.755e-03, 7.142e-02, -4.226e-02, 1.028e-01, 2.896e-01, 7.425e-02, 6.745e-02, 1.583e-01, 6.236e-01, -1.692e-01, -3.677e-01, 1.885e-02, -2.687e-03, 2.562e-01, 4.110e-03, -1.463e-02) * s0[y+2][x+2];
	r += M4(2.349e-01, -8.439e-03, 4.257e-02, 2.201e-01, -3.577e-02, 1.179e-01, -9.890e-02, -2.232e-02, 1.138e-01, 6.915e-02, -3.699e-02, 1.402e-01, 5.741e-02, -5.069e-03, 8.150e-02, 3.761e-02) * s1[y+0][x+0];
	r += M4(4.776e-02, -2.161e-01, 2.494e-01, 2.112e-01, 9.438e-02, 1.168e-01, -1.444e-01, -2.529e-01, -3.136e-01, -3.274e-02, 3.750e-01, -4.283e-01, -8.810e-02, -1.005e-02, 1.699e-02, 1.067e-01) * s1[y+0][x+1];
	r += M4(-3.849e-02, -8.964e-02, 1.150e-01, -6.967e-04, 1.151e-01, 3.195e-02, -1.224e-01, -3.255e-02, -4.807e-02, -1.305e-02, 9.201e-02, 7.497e-02, -6.363e-03, -2.764e-02, -3.777e-02, 5.303e-02) * s1[y+0][x+2];
	r += M4(1.597e-01, 3.273e-01, -1.245e-01, 6.773e-02, -1.321e-01, -3.128e-01, -3.222e-03, -1.460e-01, -3.350e-03, 1.801e-03, 2.046e-02, 9.009e-02, -2.496e-01, 1.682e-01, -1.178e-01, -2.446e-01) * s1[y+1][x+0];
	r += M4(-1.386e-01, 6.251e-01, -4.834e-01, 6.104e-01, 4.704e-01, -1.486e-02, -8.933e-02, -2.673e-01, -4.625e-01, 8.432e-01, -8.767e-02, 1.636e-01, 2.861e-01, 2.614e-01, -4.915e-01, 2.331e-01) * s1[y+1][x+1];
	r += M4(1.619e-01, -5.316e-02, -3.218e-02, -1.769e-01, 2.454e-01, 5.062e-02, -1.335e-01, -1.822e-02, 6.685e-03, -7.344e-02, -2.201e-01, 1.528e-01, 6.705e-02, 1.928e-02, 5.484e-02, -6.102e-03) * s1[y+1][x+2];
	r += M4(-3.720e-02, 8.240e-03, -2.678e-03, 2.660e-01, 1.797e-01, 1.204e-01, 7.226e-03, 2.645e-01, 7.355e-02, -2.426e-01, -4.315e-02, -9.952e-03, -1.374e-02, -1.395e-01, 5.716e-02, -2.855e-03) * s1[y+2][x+0];
	r += M4(-3.300e-01, 1.332e-01, -9.382e-03, -2.825e-02, -3.367e-01, -1.758e-01, -6.759e-02, 2.209e-03, -1.235e-01, -2.612e-01, 3.553e-02, -4.142e-02, -8.813e-02, -1.268e-01, 1.967e-01, 1.280e-01) * s1[y+2][x+1];
	r += M4(3.461e-02, 4.433e-02, -1.271e-02, -9.659e-02, 2.748e-01, 2.660e-03, 6.519e-03, 6.013e-02, 4.988e-02, -2.640e-02, -1.350e-02, -1.908e-02, -7.403e-02, 1.228e-01, 3.129e-04, 5.877e-02) * s1[y+2][x+2];
	r += V4(-3.080e-01, 1.635e-01, 4.351e-01, 1.675e-01);
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
	r += M4(-1.150e-01, -4.245e-02, -1.168e-01, -4.453e-02, 1.136e-01, -1.263e-01, -1.063e-01, -1.792e-01, -1.106e-01, -5.351e-03, -4.557e-02, 5.595e-02, 3.522e-02, 3.852e-02, -5.274e-03, 9.273e-02) * s0[y+0][x+0];
	r += M4(-1.696e-01, -1.950e-01, -2.602e-01, -4.128e-01, 1.063e-01, 7.011e-02, 2.804e-02, 1.948e-01, 1.206e-02, -6.240e-02, -8.541e-02, -1.112e-01, 1.218e-01, -3.696e-02, 1.268e-01, 2.319e-01) * s0[y+0][x+1];
	r += M4(3.521e-02, 1.009e-02, 2.900e-02, 1.629e-01, -1.174e-01, 7.935e-02, 4.849e-02, 3.080e-01, 1.223e-01, 1.658e-01, 1.353e-01, 6.326e-02, 1.509e-01, -2.231e-01, 1.140e-01, 1.473e-01) * s0[y+0][x+2];
	r += M4(1.900e-01, 1.759e-01, -4.057e-01, -3.365e-01, 6.370e-03, 3.085e-02, 4.319e-02, 1.030e-01, -1.195e-01, 1.978e-01, -1.624e-01, 4.666e-01, -4.227e-02, 9.210e-02, -4.027e-02, 2.229e-01) * s0[y+1][x+0];
	r += M4(-4.171e-01, 8.519e-01, -2.267e-01, 1.391e-01, 1.059e-01, -2.182e-01, 1.861e-01, -1.117e-01, -2.347e-01, -4.819e-01, -2.106e-01, -8.189e-01, 1.326e-01, -7.653e-01, -2.773e-01, 3.910e-01) * s0[y+1][x+1];
	r += M4(-1.543e-01, 1.963e-02, -6.190e-02, -4.257e-02, -3.936e-01, 3.191e-01, -5.306e-01, -3.664e-01, 1.098e-02, 1.076e-01, 1.546e-01, 3.233e-02, 1.290e-01, 3.906e-02, -1.361e-01, -2.134e-01) * s0[y+1][x+2];
	r += M4(-1.210e-02, -2.526e-02, -4.242e-02, -2.169e-02, -1.643e-02, -1.467e-02, 1.641e-03, -1.765e-02, 2.801e-02, 7.456e-02, -3.642e-01, -1.146e-01, 5.750e-02, 5.963e-02, -1.448e-01, -3.203e-02) * s0[y+2][x+0];
	r += M4(1.566e-01, 7.930e-02, 6.105e-02, 2.185e-02, 4.767e-02, 7.750e-03, -2.611e-02, 3.480e-02, -2.375e-02, -1.591e-01, 7.642e-01, 6.297e-01, -6.224e-02, 1.402e-01, -3.853e-01, -1.009e-01) * s0[y+2][x+1];
	r += M4(9.820e-02, -3.561e-02, -3.745e-02, 1.148e-01, -2.586e-02, -1.223e-02, -2.582e-02, -2.091e-02, 2.387e-01, -2.140e-02, 3.121e-02, -3.271e-02, 4.189e-01, -1.734e-01, 1.197e-01, 1.922e-01) * s0[y+2][x+2];
	r += M4(-3.645e-02, -7.163e-02, -6.933e-02, 1.510e-01, 1.096e-01, 3.623e-04, -9.509e-02, -8.913e-02, -2.392e-01, 9.692e-02, -2.839e-02, 2.079e-01, -3.481e-02, -6.632e-03, 4.344e-02, 7.131e-02) * s1[y+0][x+0];
	r += M4(1.489e-01, -2.530e-01, 5.672e-02, -7.778e-02, -2.715e-01, 3.161e-02, 1.278e-04, 8.006e-01, -4.335e-01, -1.591e-01, -4.434e-01, -2.921e-01, -5.319e-02, 6.004e-02, 1.139e-01, 6.514e-01) * s1[y+0][x+1];
	r += M4(1.869e-01, 5.675e-02, 1.228e-01, 6.705e-02, 8.252e-02, 6.995e-01, 4.912e-01, 4.927e-01, -1.181e-01, 2.804e-01, 5.245e-02, 1.876e-01, -7.848e-02, 1.878e-01, 5.773e-02, -3.254e-02) * s1[y+0][x+2];
	r += M4(1.008e-01, 2.317e-02, -1.118e-01, -1.108e-01, 8.561e-02, 1.090e-01, -3.294e-02, 4.640e-02, -6.675e-01, 2.371e-01, -2.350e-01, 1.158e+00, -8.281e-02, -8.528e-02, 6.772e-02, 2.170e-01) * s1[y+1][x+0];
	r += M4(-2.379e-01, 2.825e-01, 7.021e-02, 4.317e-01, 1.520e-02, 4.292e-02, -3.517e-02, -1.218e-01, -1.870e+00, -1.787e+00, -7.139e-01, -1.486e+00, -3.810e-02, -1.783e-01, -1.579e-01, 2.460e-01) * s1[y+1][x+1];
	r += M4(6.783e-02, -1.260e-01, 9.873e-02, -7.742e-03, -4.708e-01, 4.331e-01, -1.577e-01, -2.767e-01, -9.529e-03, -1.929e-01, 1.483e-01, 1.349e-01, 1.457e-01, -9.988e-02, -7.064e-02, -7.591e-02) * s1[y+1][x+2];
	r += M4(2.075e-01, -9.715e-02, 1.575e-01, 1.304e-01, 1.267e-01, 2.392e-02, -4.857e-02, -5.575e-02, 1.825e-01, 2.256e-01, -3.899e-01, -4.706e-01, -7.367e-02, 5.355e-02, 4.224e-02, -2.965e-02) * s1[y+2][x+0];
	r += M4(5.138e-01, -1.776e-01, -1.425e-01, 3.372e-02, -9.080e-02, 1.348e-02, -1.356e-02, 6.684e-02, -1.157e+00, 4.816e-01, 1.015e+00, 3.537e-01, -1.793e-01, 2.202e-01, -3.160e-01, -1.372e-01) * s1[y+2][x+1];
	r += M4(2.862e-01, -1.274e-01, -3.172e-02, 7.641e-02, 9.254e-02, -1.087e-01, 1.470e-01, -3.535e-03, -1.829e-02, 3.653e-01, -5.828e-01, -6.593e-02, 9.517e-02, -3.169e-02, -2.871e-03, 1.514e-01) * s1[y+2][x+2];
	r += V4(2.767e-02, 5.629e-02, 2.417e-02, 1.647e-02);
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
	r += M4(-1.096e-01, -9.399e-02, 1.537e-01, 6.441e-02, -1.359e-02, -1.097e-01, -9.987e-02, -1.155e-01, -4.813e-02, -1.364e-01, 1.392e-01, 1.764e-03, -4.977e-02, -1.199e-02, -3.976e-02, 4.155e-02) * s0[y+0][x+0];
	r += M4(2.294e-01, 2.033e-01, -3.304e-01, 6.851e-01, 7.645e-02, -2.469e-01, 1.637e-01, -4.629e-01, -4.841e-01, -1.851e-01, 1.061e-01, -2.858e-01, -8.913e-02, 4.307e-02, -2.051e-02, 5.533e-02) * s0[y+0][x+1];
	r += M4(-3.217e-01, 9.757e-02, -3.255e-02, 8.666e-02, 3.793e-01, 7.180e-02, 4.087e-02, -7.385e-02, 5.708e-02, -1.785e-01, -2.609e-02, -2.072e-01, -1.630e-01, -1.301e-01, 6.936e-02, -1.626e-01) * s0[y+0][x+2];
	r += M4(1.075e-01, -6.241e-02, 5.988e-03, -1.887e-01, 1.730e-01, -2.638e-01, 6.750e-02, 1.355e-01, -2.043e-01, -3.162e-01, 1.482e-01, -9.656e-02, 9.920e-03, 4.956e-02, 2.593e-01, -5.184e-02) * s0[y+1][x+0];
	r += M4(1.387e-02, -1.253e-01, -2.470e-01, 2.535e-01, 3.457e-01, -2.615e-01, -7.219e-01, 4.168e-02, -1.764e-01, -7.777e-01, 3.261e-01, 7.304e-02, 1.675e-04, -3.824e-01, -2.507e-01, 3.358e-01) * s0[y+1][x+1];
	r += M4(-2.584e-01, -1.335e-01, 1.877e-02, -7.826e-03, -3.353e-02, -4.585e-02, -1.646e-02, -1.724e-02, 2.705e-01, -3.381e-01, -1.325e-03, -1.714e-01, -2.978e-01, 1.347e-01, 9.467e-02, -3.350e-01) * s0[y+1][x+2];
	r += M4(-2.698e-02, 6.716e-02, -8.844e-02, 1.811e-01, 2.812e-02, -1.674e-01, -1.193e-02, 1.712e-01, 9.208e-02, -1.381e-01, 1.451e-01, -2.602e-02, -1.635e-01, 6.552e-03, -4.319e-02, -1.230e-04) * s0[y+2][x+0];
	r += M4(1.580e-01, 1.070e-02, 4.176e-02, -9.120e-02, 1.370e-01, 1.193e-01, -1.072e-01, -6.563e-02, -2.096e-01, 9.420e-02, -1.911e-01, -1.567e-01, -1.357e-01, -4.949e-01, 5.957e-01, 3.534e-01) * s0[y+2][x+1];
	r += M4(-1.233e-01, 4.556e-02, -6.083e-02, 7.567e-02, -2.006e-01, 3.099e-02, -2.017e-01, 1.460e-02, -1.928e-01, -1.034e-01, -1.561e-01, 1.847e-01, 3.100e-01, 2.154e-03, 2.156e-01, -2.157e-01) * s0[y+2][x+2];
	r += M4(-3.952e-02, -2.705e-01, 3.292e-01, -5.190e-02, -1.750e-01, -2.240e-01, -4.596e-02, -4.658e-02, 1.679e-01, 1.957e-01, -1.479e-01, 1.294e-01, -7.600e-02, -2.754e-02, 1.467e-01, -6.595e-02) * s1[y+0][x+0];
	r += M4(-6.676e-01, -1.673e-01, 1.516e-01, 1.567e-01, -1.499e-01, -1.519e-01, 7.016e-02, -1.791e-01, 3.963e-02, 2.384e-01, 2.546e-01, -2.783e-01, -1.174e-02, 3.613e-02, -8.005e-02, 2.914e-01) * s1[y+0][x+1];
	r += M4(-5.621e-01, -1.740e-03, 4.765e-02, -2.318e-02, -1.705e-01, -6.358e-02, 6.091e-02, 8.774e-03, 3.662e-01, 1.401e-01, -3.309e-02, 2.562e-01, -1.109e-01, -4.823e-02, -9.498e-02, 7.016e-02) * s1[y+0][x+2];
	r += M4(2.495e-01, -3.639e-01, 4.222e-01, -3.129e-01, -2.881e-03, -5.086e-01, 2.939e-01, 3.959e-03, -1.753e-01, -1.879e-01, -2.896e-02, -2.457e-02, 1.079e-01, 1.411e-01, 8.364e-02, -4.608e-02) * s1[y+1][x+0];
	r += M4(-4.625e-01, -1.757e-01, 5.774e-02, 2.027e-01, 2.092e-01, -3.865e-01, -5.099e-01, -2.738e-01, 1.745e-01, -1.920e-01, -2.566e-01, 4.990e-01, 4.402e-01, -4.425e-01, -5.176e-01, 4.470e-01) * s1[y+1][x+1];
	r += M4(-6.046e-01, -1.462e-01, 1.973e-01, -1.093e-01, -5.244e-01, -2.506e-01, -7.625e-02, 6.769e-03, 3.584e-01, -6.948e-02, -1.104e-02, 5.177e-02, -1.277e-01, 2.414e-01, -2.815e-02, -1.784e-01) * s1[y+1][x+2];
	r += M4(-1.050e-01, 4.821e-02, -3.595e-02, 9.025e-02, -1.052e-01, -1.848e-01, 1.459e-01, 1.087e-01, 1.345e-01, -1.376e-01, 6.409e-02, 2.460e-03, -3.576e-02, 6.572e-02, -2.427e-01, 1.482e-02) * s1[y+2][x+0];
	r += M4(-4.517e-02, 6.956e-03, 7.552e-02, -1.403e-02, 1.659e-01, 1.460e-01, 6.539e-02, 3.517e-02, 1.206e-01, 2.293e-01, -2.782e-01, -1.724e-01, 1.283e-01, -3.990e-01, 5.475e-01, 3.513e-01) * s1[y+2][x+1];
	r += M4(-9.413e-02, 9.621e-02, -1.033e-01, -1.167e-01, -1.002e-01, 7.197e-03, -3.544e-02, -1.558e-01, 1.551e-02, 1.301e-02, -6.019e-02, 2.174e-01, 2.659e-01, 1.161e-01, 3.023e-01, -7.913e-02) * s1[y+2][x+2];
	r += V4(3.635e-03, 8.065e-02, -2.813e-02, 8.120e-02);
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
	r += M4(2.115e-01, 5.554e-02, -1.383e-01, -1.791e-01, 2.295e-01, -4.539e-02, -2.091e-02, 1.271e-01, 6.266e-02, 6.224e-02, -1.213e-02, -3.292e-02, -2.882e-01, 7.765e-02, 2.538e-02, -1.385e-01) * s0[y+0][x+0];
	r += M4(6.939e-02, -4.550e-02, 1.422e-01, -4.793e-02, -2.053e-01, -3.513e-02, 9.323e-02, -1.603e-01, 8.287e-01, -9.567e-02, -2.627e-01, 3.234e-01, 3.831e-01, 9.696e-02, -2.031e-01, 4.681e-02) * s0[y+0][x+1];
	r += M4(4.447e-02, -5.071e-02, -3.684e-02, -1.290e-02, -2.899e-01, 3.360e-01, 1.650e-01, -7.479e-02, 9.091e-02, -2.144e-01, -2.132e-01, 3.342e-02, 5.117e-02, -1.624e-01, -8.637e-03, 2.885e-02) * s0[y+0][x+2];
	r += M4(4.835e-01, -3.839e-02, -4.524e-01, -4.337e-02, -1.745e-01, -9.913e-02, 7.581e-02, 1.741e-01, -8.765e-02, -5.007e-02, -2.076e-01, 1.249e-01, 1.839e-01, -7.860e-02, 8.824e-03, 4.073e-01) * s0[y+1][x+0];
	r += M4(1.915e-01, -1.220e-02, 5.024e-02, 1.057e-02, 1.562e-01, -5.813e-01, 2.078e-01, -1.301e-01, 2.926e-01, -3.115e-01, -2.104e-01, -1.089e-01, 7.569e-02, 1.618e-01, -5.650e-01, -1.592e-01) * s0[y+1][x+1];
	r += M4(-8.491e-02, 7.162e-02, -2.703e-02, -2.147e-01, 1.310e-01, -8.554e-02, 1.186e-01, 9.956e-02, 7.988e-02, 6.123e-02, -2.476e-01, 1.121e-01, -2.986e-01, 1.431e-01, 6.861e-02, 2.228e-02) * s0[y+1][x+2];
	r += M4(-2.297e-01, -1.587e-01, -6.203e-02, 2.027e-01, -6.383e-02, -9.870e-02, 2.091e-01, 2.183e-01, -4.015e-02, 2.258e-02, -1.676e-01, 1.247e-01, -9.533e-03, 9.456e-02, -2.298e-01, -9.626e-02) * s0[y+2][x+0];
	r += M4(1.011e-01, 6.113e-02, 6.687e-02, -1.411e-01, -2.588e-01, 6.959e-02, 2.438e-01, 1.639e-01, -1.233e-01, 9.415e-03, -2.659e-01, 1.704e-01, 1.098e-02, 1.058e-01, 1.342e-01, -1.227e-01) * s0[y+2][x+1];
	r += M4(1.261e-02, -1.108e-01, 1.414e-01, 8.655e-02, 2.912e-02, 3.734e-03, -1.578e-01, -1.778e-01, 1.200e-01, -4.127e-02, -3.671e-02, -1.960e-02, -2.565e-02, 1.019e-01, 2.328e-01, 1.079e-01) * s0[y+2][x+2];
	r += M4(2.212e-01, 1.038e-01, -9.032e-02, -2.369e-02, 8.765e-02, -1.005e-01, -1.249e-01, -1.097e-01, 2.516e-02, 1.648e-03, -8.421e-02, -1.705e-02, -2.547e-01, 5.447e-02, 3.480e-02, -4.816e-02) * s1[y+0][x+0];
	r += M4(3.613e-01, -2.868e-01, 1.161e-02, 9.154e-02, -1.068e-01, 5.891e-02, 6.409e-04, -2.531e-01, 6.125e-01, -2.691e-01, -2.227e-01, 2.146e-01, 3.174e-01, 2.335e-01, -1.287e-01, 6.802e-02) * s1[y+0][x+1];
	r += M4(-5.154e-02, 1.359e-02, 3.562e-02, -1.051e-03, -4.599e-02, 1.718e-01, 2.105e-01, -7.268e-02, -6.713e-02, -2.204e-01, 9.200e-03, 2.429e-02, 7.959e-02, -7.591e-02, 6.023e-02, -2.993e-02) * s1[y+0][x+2];
	r += M4(1.455e-01, -1.018e-03, -1.329e-01, -1.567e-01, -7.034e-02, 2.097e-02, -1.460e-01, -1.907e-01, -7.902e-02, -1.822e-01, 1.047e-02, 2.377e-01, -1.346e-02, -1.744e-01, 1.581e-01, 5.849e-01) * s1[y+1][x+0];
	r += M4(3.466e-01, 1.175e-01, -2.692e-01, -1.086e-01, 4.447e-01, -5.566e-01, 1.123e-02, -3.015e-01, 2.305e-01, -5.098e-01, -3.133e-01, -1.678e-02, -1.472e-01, 3.302e-01, -2.336e-01, -4.323e-02) * s1[y+1][x+1];
	r += M4(-9.577e-02, 7.848e-02, -5.625e-02, 1.174e-02, 2.427e-01, 3.538e-02, 2.688e-01, -2.039e-01, -1.289e-01, -8.794e-02, -6.794e-02, 1.956e-01, -1.890e-01, 1.337e-01, 5.456e-02, -1.268e-02) * s1[y+1][x+2];
	r += M4(-1.255e-01, -7.205e-02, -3.545e-01, -1.217e-02, 2.347e-02, 1.304e-01, -5.067e-03, 6.636e-02, 4.286e-03, 1.160e-02, 8.075e-03, 1.480e-01, 7.689e-03, -9.719e-02, 1.398e-01, 1.160e-01) * s1[y+2][x+0];
	r += M4(6.781e-02, -3.989e-02, -7.964e-02, -3.451e-01, 1.190e-02, 5.239e-02, -1.466e-01, -2.124e-01, -1.528e-01, 6.323e-02, -2.085e-01, 2.122e-01, -1.289e-01, 1.581e-01, 4.903e-01, 6.892e-02) * s1[y+2][x+1];
	r += M4(7.976e-02, -7.105e-02, 8.693e-02, 8.431e-02, 9.489e-02, -6.905e-02, 8.714e-02, -2.226e-01, -1.033e-01, 4.567e-02, -4.696e-02, 7.399e-02, -4.398e-02, 1.891e-01, 1.470e-01, -1.032e-01) * s1[y+2][x+2];
	r += V4(-1.360e-02, -1.382e-01, 8.711e-03, 2.288e-02);
	return vec4(r);
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv5_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-8.562e-02, 1.343e-01, 2.096e-01, 6.852e-02, 3.995e-02, 1.077e-01, -5.845e-02, -1.926e-02, -5.153e-02, 2.944e-02, -1.222e-01, 7.678e-02, 4.706e-02, -1.641e-02, -3.169e-02, 6.935e-02) * s0[y+0][x+0];
	r += M4(-1.298e-01, 2.264e-02, 1.519e-01, 7.937e-02, 4.015e-02, -2.794e-02, -8.218e-02, -3.405e-02, -6.505e-02, -1.475e-01, -2.998e-01, 4.406e-02, 6.755e-02, 4.092e-02, -3.452e-02, -5.046e-02) * s0[y+0][x+1];
	r += M4(-1.731e-01, -3.882e-02, -1.548e-01, 6.763e-02, 3.140e-02, 5.016e-02, 1.046e-01, -1.006e-02, -8.915e-02, 8.748e-03, -2.380e-01, 1.863e-02, -7.984e-02, 3.067e-02, -2.378e-01, -4.796e-03) * s0[y+0][x+2];
	r += M4(9.907e-02, 2.495e-01, 1.643e-01, -4.462e-02, -1.579e-01, 8.818e-02, -6.738e-01, -2.544e-01, -4.069e-02, 1.292e-01, -9.456e-02, -2.025e-02, 8.422e-02, -7.710e-02, 3.671e-02, -2.148e-01) * s0[y+1][x+0];
	r += M4(4.021e-01, 1.942e-01, -5.171e-03, -4.187e-01, 1.166e-01, 9.795e-02, -3.455e-01, -2.979e-01, 9.313e-02, -5.215e-03, 1.516e-01, -6.312e-02, -2.762e-01, -5.670e-02, 6.060e-02, -7.616e-02) * s0[y+1][x+1];
	r += M4(-3.990e-03, 2.042e-01, 8.365e-03, 3.965e-02, 3.154e-01, 2.169e-01, 2.365e-01, -7.942e-02, -2.156e-01, -3.302e-02, -1.577e-01, 6.038e-02, 2.654e-01, -2.764e-01, -2.975e-02, -1.806e-02) * s0[y+1][x+2];
	r += M4(4.173e-02, 9.723e-02, -8.493e-02, 3.229e-02, -7.268e-02, -9.011e-02, -1.154e-01, 1.970e-01, 4.448e-02, -5.044e-02, -1.797e-02, 4.404e-02, -1.836e-02, -4.355e-02, -1.428e-02, -2.880e-02) * s0[y+2][x+0];
	r += M4(1.300e-01, 6.465e-01, 2.842e-01, 8.285e-02, 5.735e-01, -4.425e-01, -8.519e-02, 2.920e-01, 1.296e-01, -9.852e-02, -1.289e-02, -7.291e-03, 3.250e-01, 5.868e-02, 9.778e-02, 1.018e-01) * s0[y+2][x+1];
	r += M4(-3.195e-01, 1.256e-01, -1.264e-01, 9.791e-02, 1.518e-01, 2.779e-02, 8.886e-02, -1.366e-02, 1.478e-02, 3.377e-02, -3.284e-02, -1.010e-02, -9.675e-02, -2.262e-02, -1.003e-01, 1.760e-02) * s0[y+2][x+2];
	r += M4(-2.057e-02, 3.857e-02, -6.344e-02, -3.582e-02, 3.723e-02, 1.143e-02, -5.290e-02, -3.485e-02, -9.143e-02, 2.814e-01, -6.443e-02, -2.486e-01, -1.024e-02, 1.626e-01, -3.122e-01, -2.358e-02) * s1[y+0][x+0];
	r += M4(-5.647e-02, -6.334e-02, -7.783e-02, 8.449e-02, -2.296e-02, 3.509e-02, -1.045e-01, -5.892e-02, -1.723e-01, -3.311e-01, -2.353e-01, 1.078e-01, 6.890e-02, -4.754e-02, 3.803e-01, -4.216e-02) * s1[y+0][x+1];
	r += M4(-1.191e-02, 2.529e-02, 1.091e-01, -2.597e-02, 9.426e-03, 3.648e-02, 4.727e-02, -4.761e-03, -1.387e-01, -7.127e-03, -3.581e-01, 5.312e-02, -3.695e-03, -5.307e-02, -2.244e-01, 5.533e-02) * s1[y+0][x+2];
	r += M4(1.092e-03, 1.796e-01, -2.894e-02, -6.477e-02, -1.957e-01, -7.812e-03, -3.704e-01, -3.269e-01, -3.144e-01, 5.410e-01, -3.274e-01, 1.938e-01, -2.516e-02, -2.313e-01, -1.763e-01, -2.787e-01) * s1[y+1][x+0];
	r += M4(2.276e-01, 8.571e-02, 1.451e-01, -3.237e-01, -4.481e-02, 1.088e-01, 1.821e-01, -2.378e-01, -2.138e-01, -1.050e-01, 4.189e-01, -3.097e-01, 1.376e-01, 2.309e-01, 4.155e-01, -2.373e-02) * s1[y+1][x+1];
	r += M4(1.315e-01, 1.924e-01, -6.229e-02, 1.865e-02, -5.588e-02, 1.177e-01, 1.202e-01, -3.070e-02, -5.123e-03, 2.711e-03, -6.157e-03, 3.570e-02, 1.370e-01, -2.197e-01, -2.725e-01, 3.482e-02) * s1[y+1][x+2];
	r += M4(-6.196e-03, 1.491e-01, -9.735e-02, 1.489e-02, -1.484e-01, -8.866e-02, -4.823e-02, 1.652e-01, -8.373e-02, 2.352e-01, -7.855e-02, 1.371e-01, -1.817e-01, 2.563e-01, -6.451e-02, 4.729e-02) * s1[y+2][x+0];
	r += M4(1.776e-01, 3.015e-02, 1.036e-01, 1.770e-01, 4.186e-01, -4.192e-01, 2.353e-02, 2.315e-01, 2.750e-01, -4.777e-01, -9.858e-02, 3.113e-02, 2.842e-01, 1.646e-01, 1.069e-01, 1.868e-01) * s1[y+2][x+1];
	r += M4(1.106e-02, -1.308e-01, -1.145e-01, 5.058e-02, 1.528e-01, -4.259e-02, -7.741e-03, 8.394e-03, 2.352e-01, -6.631e-03, 8.271e-02, -6.760e-02, 1.826e-02, -8.732e-02, -1.853e-01, 5.169e-02) * s1[y+2][x+2];
	r += V4(-1.898e-02, -3.058e-02, -1.821e-02, -6.042e-03);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv6_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.112e-01, -1.313e-01, -3.096e-01, 1.506e-01, -9.008e-02, 4.019e-02, -7.868e-02, -5.012e-02, -6.294e-02, 1.693e-02, 9.816e-03, 2.246e-02, 3.934e-02, 4.114e-02, -7.347e-03, 3.850e-02) * s0[y+0][x+0];
	r += M4(2.583e-01, -5.781e-01, 2.198e-02, -3.186e-01, 7.490e-02, 2.451e-01, 1.639e-01, -2.737e-01, -1.486e-03, 1.010e-01, 1.312e-02, 2.453e-02, -5.788e-02, 1.502e-02, -2.687e-02, -6.940e-02) * s0[y+0][x+1];
	r += M4(-2.940e-02, 6.195e-02, 4.775e-02, 2.238e-03, 1.170e-01, -5.549e-01, -3.154e-01, -7.556e-02, 1.273e-01, 6.858e-02, 1.154e-01, -8.350e-02, 1.065e-01, -2.506e-01, -1.953e-01, 5.029e-02) * s0[y+0][x+2];
	r += M4(-1.412e-01, 1.103e-01, -1.747e-04, 1.835e-01, -6.865e-02, 6.471e-02, -3.080e-03, 9.282e-02, -1.120e-01, 1.240e-01, 3.135e-01, -7.265e-02, 2.203e-02, 3.660e-02, 4.639e-02, -5.896e-02) * s0[y+1][x+0];
	r += M4(4.735e-01, 8.047e-02, 1.174e-01, 2.754e-01, 1.530e-02, 2.076e-01, 6.309e-01, 4.748e-01, -1.900e-01, -2.572e-02, -6.735e-01, 6.402e-01, -1.938e-01, 4.282e-03, 4.839e-02, 1.956e-01) * s0[y+1][x+1];
	r += M4(1.930e-01, 3.025e-02, 5.018e-02, -2.843e-02, 1.736e-01, -8.844e-02, -1.148e-01, 1.178e-01, 2.307e-01, 1.382e-01, 1.641e-01, -1.237e-01, -3.620e-01, 3.153e-01, 1.076e-01, 3.604e-01) * s0[y+1][x+2];
	r += M4(-3.701e-02, 1.578e-02, -1.253e-02, -4.558e-02, -9.952e-02, 3.266e-02, 6.356e-02, -1.116e-03, -1.001e-01, -4.184e-02, -2.013e-01, -1.990e-01, 3.481e-02, 3.389e-03, 3.526e-03, -8.582e-02) * s0[y+2][x+0];
	r += M4(9.242e-02, -6.357e-03, 1.626e-01, -2.529e-01, 9.240e-03, 1.974e-02, 1.172e-01, -1.616e-01, -5.474e-02, 1.192e-01, 1.720e-01, 1.319e-02, -1.798e-01, 8.086e-02, 1.833e-02, 1.251e-01) * s0[y+2][x+1];
	r += M4(1.937e-02, 1.894e-02, 8.273e-02, -6.239e-02, -1.582e-02, 3.551e-02, 4.921e-02, -8.762e-02, 9.153e-02, -2.380e-02, 1.327e-02, -1.878e-01, -6.381e-02, 2.942e-02, 1.296e-02, 3.919e-02) * s0[y+2][x+2];
	r += M4(-2.180e-01, -9.736e-03, -9.800e-02, 3.277e-02, -3.081e-02, -2.380e-02, -7.397e-02, 5.409e-02, 5.623e-03, -1.232e-02, 1.027e-02, 1.312e-02, 5.322e-02, 6.018e-02, 1.645e-02, -2.740e-02) * s1[y+0][x+0];
	r += M4(3.739e-01, -2.296e-01, 1.258e-02, -2.059e-01, 3.852e-02, -3.819e-02, -1.333e-01, -6.004e-03, -6.273e-02, 7.902e-02, 5.919e-02, -4.211e-02, 2.893e-02, -2.404e-02, 2.992e-01, -3.018e-01) * s1[y+0][x+1];
	r += M4(-2.946e-02, -1.069e-01, -4.922e-02, 2.335e-02, 2.529e-01, -3.111e-01, -9.323e-03, -6.224e-02, -4.507e-02, 5.660e-02, 2.032e-02, -5.599e-04, 1.745e-01, -2.489e-01, -2.626e-02, -8.884e-02) * s1[y+0][x+2];
	r += M4(-1.548e-01, 1.165e-01, 9.540e-02, 2.011e-01, -1.470e-01, 2.695e-02, -2.149e-03, 1.588e-01, 8.856e-02, -1.793e-02, 7.069e-02, 2.080e-02, 8.960e-02, -4.280e-02, 1.731e-02, -1.943e-01) * s1[y+1][x+0];
	r += M4(3.042e-01, 6.926e-02, 3.129e-01, -2.890e-02, 1.179e-01, 1.777e-01, 4.678e-01, 2.893e-01, -3.383e-01, 4.481e-02, -3.545e-01, 3.314e-01, 8.611e-02, -2.509e-01, -3.851e-01, -3.389e-01) * s1[y+1][x+1];
	r += M4(1.377e-02, -6.427e-02, -8.973e-02, 4.179e-02, 1.402e-01, -4.008e-03, -2.654e-02, 2.025e-02, -5.408e-02, 1.683e-01, 4.551e-02, 6.052e-02, -4.632e-01, 2.211e-01, -2.689e-02, -1.545e-02) * s1[y+1][x+2];
	r += M4(-2.348e-02, -2.306e-02, 4.411e-03, -1.412e-04, -1.518e-02, 8.562e-03, 2.873e-02, 5.931e-03, -1.202e-02, -1.164e-02, -6.588e-02, -3.404e-02, 7.779e-02, -9.902e-02, -8.935e-02, -5.249e-02) * s1[y+2][x+0];
	r += M4(6.197e-02, -3.109e-02, 1.051e-01, -7.888e-02, 7.066e-02, -3.016e-02, 2.893e-02, -1.762e-01, -9.997e-02, 8.284e-02, 5.317e-02, -1.804e-02, 4.138e-02, -8.799e-02, -2.204e-01, 7.033e-02) * s1[y+2][x+1];
	r += M4(1.734e-02, 9.435e-03, 4.347e-02, 2.943e-02, 3.591e-02, 1.525e-02, 5.375e-02, -7.362e-02, -8.909e-02, 1.731e-02, -5.730e-03, -1.881e-02, 4.711e-02, -8.359e-02, -2.349e-01, -1.625e-02) * s1[y+2][x+2];
	r += V4(1.289e-02, -2.168e-02, 1.502e-02, -1.832e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv7_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-7.866e-03, 5.171e-02, 8.336e-02, 1.254e-02, -7.414e-02, -5.960e-02, 3.430e-03, 5.233e-02, 1.026e-02, -2.238e-02, 5.862e-02, 1.851e-02, 1.061e-02, 1.010e-02, -1.159e-02, -6.278e-02) * s0[y+0][x+0];
	r += M4(1.519e-01, 1.431e-01, -1.929e-01, -3.719e-01, 1.032e-01, 2.174e-01, -1.548e-01, -1.983e-01, -4.112e-02, -3.431e-01, 2.575e-01, 2.345e-01, 6.951e-02, -2.562e-01, 3.321e-02, 2.127e-02) * s0[y+0][x+1];
	r += M4(9.740e-02, 3.235e-02, -5.693e-02, -4.260e-02, 5.383e-02, -7.057e-03, -4.681e-02, -6.370e-02, -3.671e-02, -6.547e-03, 9.091e-02, 1.812e-01, 1.607e-02, -2.462e-02, 2.084e-02, 1.372e-01) * s0[y+0][x+2];
	r += M4(-2.345e-02, -6.567e-02, -6.399e-02, -8.990e-04, -9.281e-03, -1.354e-01, 1.489e-01, 6.237e-02, -2.003e-02, 7.890e-02, 4.490e-02, -6.751e-02, 1.406e-03, -8.328e-02, -4.687e-02, 4.895e-02) * s0[y+1][x+0];
	r += M4(-4.765e-01, -7.992e-02, 2.124e-01, -3.213e-02, 3.072e-01, -1.661e-01, -4.150e-01, 4.758e-01, 1.870e-01, 2.397e-01, 2.964e-01, -8.194e-02, -3.312e-01, 1.116e-01, -4.031e-01, -7.910e-02) * s0[y+1][x+1];
	r += M4(9.582e-02, -1.592e-02, -6.202e-02, 6.414e-02, 2.857e-02, -1.902e-02, 1.432e-02, 7.608e-02, -1.762e-01, 4.165e-02, -2.565e-02, -1.730e-01, 2.959e-01, -3.359e-02, -3.466e-01, 2.160e-02) * s0[y+1][x+2];
	r += M4(-3.051e-02, 1.022e-01, -2.660e-03, -3.577e-02, -1.353e-04, 1.595e-01, 4.782e-03, -9.107e-03, 3.522e-02, -3.442e-02, -8.430e-02, -4.549e-02, -6.474e-02, 7.229e-03, 4.608e-02, 2.728e-02) * s0[y+2][x+0];
	r += M4(6.955e-02, 4.138e-02, -3.057e-01, -2.504e-01, -2.664e-01, 8.429e-02, 1.261e-01, -1.634e-01, 1.119e-01, -6.364e-02, -1.647e-01, 5.561e-03, -1.743e-01, -1.081e-01, 2.798e-01, 8.680e-02) * s0[y+2][x+1];
	r += M4(1.090e-01, 1.158e-02, -5.987e-02, 2.319e-03, 1.440e-01, 1.281e-02, -1.649e-02, 2.477e-02, -3.209e-02, -2.223e-02, 1.110e-03, 8.721e-03, -1.333e-01, -1.126e-02, 2.900e-01, 1.763e-01) * s0[y+2][x+2];
	r += M4(1.239e-02, 4.602e-02, -1.720e-02, -6.774e-02, -8.878e-02, 2.756e-02, 2.675e-02, 6.599e-02, -1.215e-02, -1.017e-01, 2.661e-02, 5.522e-02, 3.489e-02, -5.791e-02, 1.312e-03, -6.248e-02) * s1[y+0][x+0];
	r += M4(1.470e-01, 6.079e-02, -1.838e-01, -3.022e-01, 4.463e-02, 2.588e-01, -1.480e-01, -2.289e-01, -7.225e-02, -3.762e-01, 1.672e-01, 1.884e-01, 2.582e-02, -3.748e-01, 1.395e-01, 1.876e-01) * s1[y+0][x+1];
	r += M4(8.893e-02, -2.817e-03, -4.351e-02, -1.542e-02, 5.928e-02, 1.384e-02, -7.691e-02, -9.660e-02, -7.009e-02, -2.649e-02, 8.775e-02, 1.867e-01, 2.438e-02, -5.447e-03, 1.142e-01, 2.242e-01) * s1[y+0][x+2];
	r += M4(3.231e-03, -6.620e-02, 3.747e-02, 1.031e-01, -1.436e-01, -2.493e-01, 6.415e-02, 6.969e-02, -1.008e-01, -1.434e-01, 1.176e-01, 1.818e-01, 4.364e-02, -1.447e-02, -4.937e-02, -1.860e-02) * s1[y+1][x+0];
	r += M4(-1.341e-01, -9.559e-02, 1.323e-01, 3.005e-01, -1.713e-02, -1.715e-01, 6.716e-02, 5.645e-01, -8.703e-02, 1.285e-01, 1.830e-01, 1.401e-01, -2.407e-01, -2.233e-02, -1.048e-01, -1.145e-03) * s1[y+1][x+1];
	r += M4(-4.822e-02, -9.059e-02, -1.133e-02, 1.353e-01, 1.391e-01, -1.262e-03, 2.142e-02, 5.903e-02, -4.168e-01, -8.370e-02, 1.480e-01, 9.609e-02, 1.214e-01, -8.808e-03, -2.072e-01, -6.443e-02) * s1[y+1][x+2];
	r += M4(-4.455e-02, 6.465e-02, 4.167e-03, -1.630e-02, -3.244e-02, 2.162e-01, -1.992e-02, -4.828e-02, -8.744e-02, -2.842e-02, 1.010e-01, 3.564e-02, 6.589e-03, -1.880e-02, -2.203e-02, -5.141e-03) * s1[y+2][x+0];
	r += M4(-1.256e-01, 2.719e-02, -1.054e-02, -1.336e-01, -1.997e-01, 1.014e-01, -1.642e-01, -3.701e-01, -1.632e-02, -5.339e-02, 2.144e-01, 1.509e-01, -1.224e-01, -5.379e-03, 1.402e-01, 3.188e-02) * s1[y+2][x+1];
	r += M4(6.372e-02, 1.586e-02, 8.565e-02, 5.975e-02, 1.666e-01, 5.920e-03, -1.323e-01, -2.961e-02, -1.323e-01, 2.558e-02, 2.542e-01, 8.031e-02, 5.179e-02, -6.961e-03, 5.776e-02, 6.147e-02) * s1[y+2][x+2];
	r += V4(-1.513e-03, -4.599e-03, 1.902e-03, 9.256e-03);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}


//!DESC CuNNy-8x4C-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv8
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
#define l0(x, y) V4(texelFetch(conv8_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(3.161e-02, 2.850e-02, 3.528e-02, 5.878e-04, -5.355e-03, -1.905e-02, -3.238e-04, -8.385e-05, 4.338e-02, 3.111e-02, -1.155e-02, 9.893e-03, 6.905e-02, -3.136e-02, -1.605e-02, -1.949e-03) * s0[y+0][x+0];
	r += M4(5.631e-02, -7.945e-02, -2.955e-03, 2.195e-02, 2.601e-03, 2.992e-03, -7.100e-03, -3.013e-02, 3.442e-01, 1.880e-01, -1.948e-01, -1.882e-01, 1.795e-01, 2.123e-01, -9.286e-02, -1.179e-01) * s0[y+0][x+1];
	r += M4(-1.890e-02, 2.982e-02, -1.015e-02, -1.850e-02, 5.652e-02, -3.354e-02, 4.691e-02, 2.003e-02, 1.890e-02, 3.612e-02, 3.832e-02, -5.161e-02, -5.031e-04, 5.011e-03, 3.606e-02, 8.843e-04) * s0[y+0][x+2];
	r += M4(-1.802e-01, 1.046e-02, -1.204e-01, 3.069e-02, 2.643e-02, 2.650e-02, 1.641e-02, 3.942e-03, -6.665e-02, 2.313e-02, -6.989e-02, -2.269e-03, 1.072e-01, 5.156e-02, 4.236e-02, -1.244e-02) * s0[y+1][x+0];
	r += M4(2.075e-01, -2.056e-01, 1.853e-01, -2.486e-01, -2.860e-02, -1.411e-04, -4.379e-02, 1.611e-02, 1.958e-01, -3.487e-02, 4.645e-01, 1.401e-01, -3.877e-01, -3.252e-01, -6.330e-02, -4.061e-02) * s0[y+1][x+1];
	r += M4(-6.958e-02, -1.857e-02, -6.519e-02, 4.298e-02, 2.684e-02, -1.043e-02, 8.865e-02, -6.494e-02, -1.338e-02, -1.533e-02, -8.608e-02, -2.050e-02, 7.237e-03, 7.902e-02, -1.070e-02, -3.183e-02) * s0[y+1][x+2];
	r += M4(3.822e-02, 4.359e-03, -1.837e-02, 1.457e-02, 3.330e-02, 7.825e-03, 3.876e-02, 1.954e-02, 2.747e-02, 1.199e-02, -2.703e-03, 2.269e-02, -7.056e-02, -2.094e-02, 6.996e-03, -3.632e-02) * s0[y+2][x+0];
	r += M4(6.706e-02, 4.302e-02, 1.532e-01, 3.229e-03, -1.415e-01, -6.457e-02, -1.019e-01, -5.171e-02, 8.911e-02, 5.652e-02, 1.492e-01, 5.105e-02, -1.323e-01, -1.083e-01, -2.105e-01, -1.418e-01) * s0[y+2][x+1];
	r += M4(1.483e-02, 1.694e-02, -4.883e-04, -1.839e-03, -4.467e-02, -5.266e-02, -9.222e-02, -5.774e-02, 2.107e-02, 1.820e-02, 3.031e-02, 5.167e-03, -2.790e-02, -3.444e-02, -4.909e-02, 4.562e-02) * s0[y+2][x+2];
	r += M4(-3.545e-02, 5.115e-02, 4.293e-02, -1.053e-02, 2.392e-02, -2.312e-02, 8.070e-04, -8.301e-03, -4.822e-02, 1.216e-02, 8.153e-03, 1.230e-02, 2.291e-02, -1.789e-02, 5.630e-03, -1.296e-02) * s1[y+0][x+0];
	r += M4(1.204e-01, -1.999e-01, 2.917e-02, 5.649e-02, -3.370e-02, 4.677e-02, 2.880e-02, -1.377e-02, 8.667e-02, -5.358e-02, -5.115e-02, -4.178e-02, 3.961e-02, 2.691e-02, 1.812e-02, -1.463e-03) * s1[y+0][x+1];
	r += M4(-2.026e-03, -2.432e-03, 2.057e-02, -4.470e-03, 9.984e-02, -2.285e-02, 3.498e-02, 5.351e-02, -3.090e-02, -1.188e-02, 7.886e-03, -1.593e-02, 1.451e-02, -1.062e-02, 1.566e-02, 1.509e-02) * s1[y+0][x+2];
	r += M4(-1.177e-01, -3.075e-02, -2.361e-01, 2.264e-02, 9.835e-03, 4.405e-02, -2.971e-02, -4.869e-03, -6.366e-02, 1.571e-02, -5.870e-02, 2.769e-02, 3.766e-02, 5.151e-02, 1.108e-02, 9.832e-03) * s1[y+1][x+0];
	r += M4(2.408e-01, -1.842e-01, 2.179e-01, -4.900e-01, 4.598e-01, 9.248e-03, -3.799e-01, -1.959e-01, 3.182e-01, 1.175e-01, 3.787e-01, 8.942e-02, -2.077e-01, -2.568e-01, -9.695e-02, -1.102e-01) * s1[y+1][x+1];
	r += M4(-7.864e-02, 4.692e-02, -9.942e-02, 5.698e-02, -7.525e-02, 4.499e-01, -5.920e-02, -3.486e-01, -3.511e-02, -2.957e-02, -6.703e-02, 4.166e-03, 1.126e-02, 3.665e-02, 1.646e-02, -4.393e-02) * s1[y+1][x+2];
	r += M4(1.635e-02, -8.291e-03, 3.359e-02, -1.210e-02, 2.836e-02, 3.417e-03, 7.933e-02, 2.333e-03, 2.526e-02, 2.034e-02, -1.740e-02, 1.090e-02, -4.276e-02, -3.621e-02, 4.212e-03, 1.270e-02) * s1[y+2][x+0];
	r += M4(6.117e-02, 7.976e-03, 1.431e-01, 3.524e-02, -3.378e-01, -1.027e-01, 9.144e-03, -3.520e-02, 5.760e-02, 3.747e-02, 1.587e-01, 7.983e-02, -7.844e-02, -1.159e-01, -1.831e-01, -2.503e-01) * s1[y+2][x+1];
	r += M4(1.872e-02, 2.315e-02, 6.982e-03, 1.715e-02, -4.318e-02, -1.841e-01, -1.203e-01, 1.234e-01, 2.266e-02, 1.764e-02, 1.405e-02, -1.212e-02, -4.211e-02, -1.191e-02, -4.456e-02, 3.710e-02) * s1[y+2][x+2];
	r += V4(-3.834e-04, 1.512e-03, -3.837e-04, 1.630e-03);
	return tanh(vec4(r));
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}


//!DESC CuNNy-8x4C-shuffle
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

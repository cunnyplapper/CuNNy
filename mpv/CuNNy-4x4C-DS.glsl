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
	r0 += V4(-5.291e-02, -9.963e-03, 7.643e-02, -2.749e-02) * s[0][0][0];
	r0 += V4(6.982e-02, 2.409e-02, -3.873e-01, 2.476e-01) * s[0][1][0];
	r0 += V4(-2.924e-02, -1.129e-01, -5.018e-01, 5.550e-01) * s[0][2][0];
	r0 += V4(1.827e-01, 3.162e-02, -7.983e-02, 1.946e-02) * s[1][0][0];
	r0 += V4(7.363e-01, -1.616e-01, 2.171e-01, -1.889e-02) * s[1][1][0];
	r0 += V4(-6.373e-02, 6.311e-01, -1.170e-01, -7.593e-01) * s[1][2][0];
	r0 += V4(-5.553e-02, 4.089e-02, 1.125e-02, 4.758e-03) * s[2][0][0];
	r0 += V4(-3.008e-02, -2.995e-02, -2.084e-02, -3.600e-02) * s[2][1][0];
	r0 += V4(9.798e-04, -9.769e-03, 1.707e-02, 3.357e-02) * s[2][2][0];
	r0 += V4(-1.205e-02, -4.677e-03, 7.483e-01, -2.270e-02);
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
	r0 += M4(-1.090e-02, 9.712e-02, 1.422e-02, -1.042e-01, -2.935e-01, -1.201e-01, 3.149e-01, 1.357e-01, -2.506e-02, -3.893e-02, 8.221e-02, -1.265e-01, -6.092e-02, -1.714e-01, 3.954e-01, -4.013e-01) * s[0][0][0];
	r0 += M4(5.792e-01, 4.031e-01, 1.723e+00, -6.471e-01, -5.339e-01, -8.985e-01, 2.291e+00, 2.317e+00, -1.058e-01, -4.457e-03, -6.731e-01, -5.149e-01, -8.788e-02, -6.449e-02, -8.021e-02, 1.460e-01) * s[0][0][1];
	r0 += M4(-3.168e-02, -2.588e-01, -2.822e-01, 2.920e-01, 1.023e-01, 2.187e-01, -1.461e-01, -1.726e-01, 1.186e-01, 1.220e-01, -1.378e-03, 3.669e-02, 1.033e-01, 2.310e-01, -6.393e-02, -1.776e-01) * s[0][1][0];
	r0 += M4(1.341e+00, -2.242e+00, -9.453e-01, 2.748e+00, 2.851e-01, -2.589e-01, -7.024e-01, 2.802e-01, 5.662e-01, -5.737e-02, -2.404e-01, 1.498e-01, 1.204e-01, 1.511e-01, -7.195e-02, -2.200e-01) * s[0][1][1];
	r0 += M4(7.265e-02, -1.204e-01, 3.310e-01, 1.666e-01, -1.116e-01, -3.033e-02, 2.033e-01, -2.347e-02, -9.659e-02, -3.505e-02, -1.094e-01, -5.403e-02, -5.009e-02, -4.496e-02, 6.896e-03, -9.456e-02) * s[0][2][0];
	r0 += M4(1.200e+00, -1.103e+00, -1.231e+00, 3.201e+00, 4.818e-02, 3.228e-02, 7.514e-02, 3.960e-01, -2.611e-01, -1.236e-01, -5.929e-01, 5.967e-01, -7.157e-02, -1.059e-02, -1.900e-01, -6.904e-02) * s[0][2][1];
	r0 += M4(1.936e-02, 1.447e-02, -1.919e-01, -1.060e-01, -9.715e-03, -7.288e-02, 3.104e-01, 2.202e-01, 1.055e-02, 1.597e-01, -2.380e-01, 8.431e-02, 2.968e-01, 4.079e-01, -3.291e-01, 1.428e-01) * s[1][0][0];
	r0 += M4(5.903e-01, 8.735e-01, 2.356e-01, -4.713e-02, 9.147e-01, -4.074e-01, 2.515e+00, 1.435e+00, 6.292e-02, 2.254e-01, -1.167e-01, -2.224e+00, 4.418e-02, 1.518e-01, -2.814e-01, -2.839e-01) * s[1][0][1];
	r0 += M4(-1.795e-01, -6.447e-01, -4.345e-01, 5.513e-02, 4.760e-01, 6.742e-01, 5.359e-02, 1.367e-01, 5.543e-02, -5.723e-01, -2.920e-01, 3.977e-01, 4.484e-01, -4.186e-01, -7.944e-01, 8.037e-01) * s[1][1][0];
	r0 += M4(-3.247e-02, -4.437e+00, 5.635e-02, 7.430e+00, 1.652e+00, -2.231e-01, -5.290e-01, 2.913e-01, -2.854e-01, -8.940e-01, -1.227e+00, -1.904e+00, 2.640e-01, -2.806e-01, 1.092e-01, 4.424e-01) * s[1][1][1];
	r0 += M4(1.684e-01, 1.778e-01, 5.867e-02, 2.506e-01, 1.941e-01, -6.261e-02, -7.889e-02, -1.713e-01, 2.823e-01, -5.331e-02, 1.578e-01, 1.006e-01, 2.262e-01, -1.082e-01, -6.618e-02, -1.948e-01) * s[1][2][0];
	r0 += M4(-7.043e-01, -2.862e+00, -1.643e-01, 3.465e+00, 1.230e-01, 8.374e-02, 3.216e-02, 9.272e-02, -1.465e-01, 5.218e-01, -1.635e-01, -4.656e-01, 2.457e-01, -8.656e-02, 6.917e-02, -1.379e-01) * s[1][2][1];
	r0 += M4(1.018e-01, 2.675e-02, 4.038e-02, -3.929e-02, -1.003e-01, 2.991e-02, -9.378e-02, -3.005e-02, -3.369e-01, -1.454e-01, 1.489e-01, 1.200e-01, -6.193e-01, -2.375e-02, -1.199e-01, 2.070e-01) * s[2][0][0];
	r0 += M4(-7.754e-01, -8.967e-05, -7.063e-01, -9.126e-01, 5.134e+00, -2.278e-01, -6.868e-01, -1.561e+00, 5.598e-01, 8.138e-01, 6.530e-01, -8.687e-01, -1.113e+00, -3.699e-02, 5.506e-01, -8.717e-02) * s[2][0][1];
	r0 += M4(2.719e-01, -2.197e-01, -7.251e-02, 4.742e-02, -4.937e-01, -1.115e-01, -2.250e-01, -8.276e-02, 4.699e-01, 2.348e-01, 8.223e-02, -1.417e-01, -3.781e-01, 3.902e-02, -2.802e-02, 1.771e-01) * s[2][1][0];
	r0 += M4(6.910e+00, -3.534e+00, -4.007e-01, -1.113e+00, -7.832e-01, -1.353e+00, -4.255e-01, -2.643e-01, 1.710e+00, -4.680e-01, 2.022e-02, -1.564e+00, -4.516e-01, -2.346e-02, 6.013e-01, 1.056e-01) * s[2][1][1];
	r0 += M4(5.481e-02, 3.808e-01, 2.333e-01, -1.204e-02, -4.094e-02, -3.305e-01, -1.472e-01, 2.625e-03, -2.082e-01, -9.120e-02, -1.201e-01, -2.839e-03, 1.187e-02, -1.968e-01, -1.160e-01, -8.260e-02) * s[2][2][0];
	r0 += M4(4.443e+00, -3.211e+00, -1.514e+00, -1.072e+00, 1.494e-01, 2.549e-01, -5.834e-01, -5.287e-02, -7.719e-01, -1.002e+00, 3.245e-01, -3.732e-01, -5.625e-02, -1.388e-01, -4.126e-02, -1.404e-01) * s[2][2][1];
	r0 += V4(-2.452e-01, 2.979e-01, 2.466e-01, -3.542e-01);
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
	r0 += M4(-1.155e-01, 7.690e-02, -1.030e-01, -1.187e-01, -5.895e-03, -1.652e-01, 1.421e-01, 2.589e-01, 4.652e-02, 4.132e-02, -9.136e-02, -1.775e-01, 2.664e-02, -3.536e-03, 1.330e-02, -5.181e-03) * s[0][0][0];
	r0 += M4(9.290e-02, 1.524e-01, 1.582e-02, -5.983e-02, 1.486e-02, -3.367e-03, -2.336e-02, 4.493e-02, 1.383e-01, 4.247e-03, -1.144e-01, -1.243e-01, -7.744e-02, -7.354e-02, -4.315e-03, -3.545e-02) * s[0][0][1];
	r0 += M4(-2.143e-01, 6.643e-02, 2.685e-01, 2.487e-01, -2.594e-01, -5.149e-02, 4.894e-01, 1.350e-01, -6.139e-02, 6.366e-02, 2.173e-01, 1.586e-01, -1.226e-01, -3.294e-02, 2.163e-01, -7.154e-02) * s[0][1][0];
	r0 += M4(2.493e-01, 2.821e-01, 3.676e-01, 1.413e-01, -1.388e-01, 6.872e-02, 2.733e-01, -2.627e-01, -9.427e-02, -3.826e-03, 1.998e-01, -6.767e-02, -3.820e-02, 4.138e-02, 1.793e-01, -6.555e-03) * s[0][1][1];
	r0 += M4(-8.286e-02, 7.056e-02, -7.011e-02, 1.214e-01, -1.788e-01, -4.038e-02, 3.310e-02, 1.215e-01, 5.371e-02, 4.752e-02, -1.421e-01, 1.192e-02, -6.760e-02, -2.475e-02, 7.656e-03, -3.277e-02) * s[0][2][0];
	r0 += M4(-4.491e-02, 2.112e-01, -3.474e-02, 3.370e-01, -1.810e-01, 2.442e-02, 2.046e-03, 2.705e-02, 2.294e-02, -1.973e-03, -8.864e-02, 6.261e-02, -7.775e-02, 1.970e-02, -5.432e-02, -9.153e-03) * s[0][2][1];
	r0 += M4(8.405e-02, -5.266e-02, -7.581e-02, 5.108e-02, -1.015e+00, 2.102e-04, -4.463e-01, -1.200e-01, 9.441e-02, 4.543e-02, 1.512e-01, -9.496e-02, 6.826e-02, -2.132e-01, 4.684e-02, 7.120e-02) * s[1][0][0];
	r0 += M4(2.804e-01, 4.857e-02, 1.762e-01, 5.315e-02, -8.692e-02, 7.676e-01, -5.956e-01, -4.307e-01, 3.990e-02, 4.230e-02, -1.635e-05, 2.646e-01, -2.318e-01, 5.077e-03, 1.672e-01, 6.668e-02) * s[1][0][1];
	r0 += M4(-2.297e-01, -6.387e-01, 6.073e-02, 1.480e-01, -3.114e-01, -8.892e-01, 1.564e-01, -2.274e-01, -1.520e-02, 7.322e-02, -3.795e-01, 1.457e-01, -2.764e-01, 2.115e-01, -7.872e-02, 8.114e-02) * s[1][1][0];
	r0 += M4(3.813e-01, 8.115e-02, 1.401e-01, 3.916e-01, 3.446e-01, -1.424e-01, 1.628e-01, 1.430e-02, 1.064e-01, 1.225e-01, -3.464e-01, 2.558e-01, -2.368e-01, 1.904e-01, -3.332e-01, 2.221e-01) * s[1][1][1];
	r0 += M4(1.072e-01, -3.362e-02, -1.155e-01, -2.753e-02, -1.277e-01, 4.893e-02, 1.110e-01, -6.266e-01, 2.455e-01, 2.483e-02, 3.989e-02, -7.816e-02, 1.982e-01, -7.363e-03, -1.251e-01, -6.757e-02) * s[1][2][0];
	r0 += M4(4.629e-01, 6.004e-02, 1.095e-01, 2.797e-02, -8.741e-02, 9.463e-02, -1.523e-01, 4.619e-03, 1.918e-01, 2.696e-02, 2.415e-01, -1.206e-01, 1.151e-01, -2.685e-02, 6.172e-02, -2.005e-01) * s[1][2][1];
	r0 += M4(6.413e-02, -1.027e-01, 6.749e-02, 4.812e-02, 4.680e-02, -1.271e-01, 1.337e-01, -1.321e-02, 3.232e-01, -2.191e-02, 2.939e-01, 8.090e-02, 7.994e-02, -2.070e-02, 6.548e-01, -9.398e-03) * s[2][0][0];
	r0 += M4(-1.889e-02, -3.883e-02, 5.013e-02, 7.016e-02, 2.975e-01, 1.835e-01, 4.456e-01, 2.137e-02, -1.398e-01, -3.369e-01, 3.712e-02, 5.928e-02, -2.778e-01, -1.143e-01, -7.776e-02, 1.885e-01) * s[2][0][1];
	r0 += M4(-2.000e-01, 3.674e-02, -2.036e-01, -9.517e-02, -4.803e-01, -1.940e-01, -9.413e-02, -1.665e-01, 5.421e-02, 3.869e-01, -2.846e-01, 3.066e-02, -7.815e-02, 6.315e-01, 2.546e-01, 9.070e-02) * s[2][1][0];
	r0 += M4(-9.649e-02, 1.606e-01, 4.340e-02, 5.649e-02, -7.839e-02, -9.656e-02, 1.195e-01, 1.573e-01, -2.939e-01, 2.152e-01, -3.809e-01, 1.710e-01, -8.596e-01, -5.523e-02, -3.129e-01, 4.170e-01) * s[2][1][1];
	r0 += M4(-4.858e-02, 1.435e-01, -1.217e-01, 7.463e-02, 3.690e-02, 4.362e-02, 1.627e-01, -2.706e-01, 6.926e-02, -2.102e-02, -4.069e-02, 1.662e-01, 1.083e-01, -4.425e-02, 8.647e-02, -2.695e-02) * s[2][2][0];
	r0 += M4(-1.567e-02, 6.866e-02, -3.211e-03, 4.342e-02, 6.636e-03, -8.179e-02, 2.994e-02, -5.447e-02, 7.788e-03, 6.839e-03, 1.161e-03, 7.342e-02, 1.106e-01, 5.045e-02, -2.894e-02, 3.244e-02) * s[2][2][1];
	r0 += V4(2.106e-02, 3.240e-02, 6.523e-02, -1.740e-02);
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
	r0 += M4(-6.387e-02, 1.741e-01, -3.324e-01, -1.685e-01, -1.285e-01, 6.905e-02, -3.347e-01, 1.264e-01, 5.719e-03, -6.858e-02, -6.580e-02, -5.278e-02, 7.308e-03, 7.745e-02, -2.502e-01, 1.287e-02) * s[0][0][0];
	r0 += M4(-1.492e-02, 4.334e-02, -1.597e-01, 1.605e-01, -5.764e-02, -2.483e-02, -1.204e-01, -3.467e-02, -3.881e-02, -3.090e-03, 3.085e-01, -1.345e-01, -6.337e-02, 9.788e-02, 1.495e-01, 7.813e-02) * s[0][0][1];
	r0 += M4(-3.323e-02, 6.738e-01, -1.734e-01, -4.026e-01, 4.964e-01, -1.932e-01, -5.098e-01, 7.392e-03, 2.998e-01, -1.059e-01, -8.724e-02, 1.461e-02, -7.078e-02, 2.087e-01, 3.164e-02, -3.291e-01) * s[0][1][0];
	r0 += M4(8.814e-02, 9.154e-02, 4.197e-02, 6.035e-02, 5.404e-01, -5.086e-02, -3.349e-01, -3.917e-03, 1.093e-01, 4.491e-02, -3.730e-02, -3.959e-01, -6.829e-02, -1.127e-01, 1.077e-01, 1.470e-01) * s[0][1][1];
	r0 += M4(-2.391e-01, 5.352e-01, -9.189e-02, -3.732e-01, 2.221e-03, -1.382e-01, 1.499e-01, -5.179e-02, 9.787e-02, 3.254e-02, -1.155e-01, -8.754e-02, 6.239e-02, 1.524e-01, -1.149e-01, -1.600e-01) * s[0][2][0];
	r0 += M4(-6.455e-02, 1.772e-01, -7.267e-02, -1.511e-02, -4.893e-02, 1.475e-01, -9.540e-02, -2.017e-01, 8.750e-01, -2.566e-01, 2.427e-01, -4.920e-01, 2.234e-02, -1.511e-03, -1.683e-02, 2.241e-02) * s[0][2][1];
	r0 += M4(-1.116e-01, 1.659e-01, -4.467e-01, -8.535e-03, -1.163e-01, 2.813e-01, -7.479e-01, 4.085e-01, 2.827e-02, 7.498e-02, -1.018e-01, 1.255e-01, 1.831e-02, 1.298e-01, -5.775e-01, 1.294e-01) * s[1][0][0];
	r0 += M4(1.625e-02, -1.912e-02, 6.474e-02, -5.633e-03, 7.549e-02, 3.639e-02, -3.115e-01, 7.605e-02, -3.221e-02, 5.277e-02, 6.309e-01, -4.157e-02, 1.620e-01, -1.101e-01, -5.393e-02, -7.466e-02) * s[1][0][1];
	r0 += M4(6.621e-02, 7.211e-01, -5.382e-02, -3.291e-01, 1.880e-01, 3.685e-01, -1.509e-01, 1.854e-01, 1.510e-01, 3.623e-01, -1.414e-02, 2.794e-02, 2.579e-01, 5.710e-01, -4.435e-01, -2.109e-01) * s[1][1][0];
	r0 += M4(-2.195e-01, 2.002e-02, -6.093e-02, -5.609e-01, 5.182e-01, 2.082e-01, 6.549e-03, 5.888e-01, 1.170e-01, 5.288e-01, 6.566e-01, -4.063e-02, 1.250e-01, -1.598e-01, 8.302e-02, 4.658e-01) * s[1][1][1];
	r0 += M4(-1.683e-01, 3.808e-01, -3.150e-01, -4.874e-01, -1.137e-01, -4.024e-01, 3.684e-01, -1.015e-01, -1.021e-01, 2.744e-01, -1.888e-01, -5.140e-02, -2.192e-02, 3.603e-01, -3.118e-01, -1.851e-01) * s[1][2][0];
	r0 += M4(-5.290e-02, 6.667e-02, -1.538e-02, 2.231e-02, 3.331e-02, -7.247e-02, -7.251e-02, -3.920e-01, -3.962e-01, 2.589e-01, 2.429e-01, -4.391e-02, -2.335e-02, 7.786e-02, -1.092e-01, 8.374e-02) * s[1][2][1];
	r0 += M4(-1.519e-01, -1.849e-01, -1.344e-01, 1.471e-01, -9.563e-02, -5.946e-02, 2.984e-01, 1.610e-01, 6.085e-02, 2.115e-02, -1.376e-02, -3.714e-02, -4.033e-02, -2.030e-01, -3.925e-03, 2.155e-02) * s[2][0][0];
	r0 += M4(-8.023e-03, -5.533e-02, -2.942e-02, 2.933e-03, -4.171e-02, 5.132e-02, 2.235e-02, 2.919e-03, -4.218e-02, 3.425e-01, -6.873e-02, 2.373e-02, 1.728e-02, 2.549e-02, 2.939e-02, 1.074e-02) * s[2][0][1];
	r0 += M4(-1.153e-01, 1.184e-02, -1.705e-01, -2.733e-02, 1.336e-02, 5.264e-03, 4.052e-01, -3.768e-02, 5.640e-02, -9.947e-02, -1.101e-01, -1.751e-01, -1.547e-01, 1.716e-02, -2.167e-02, -3.116e-01) * s[2][1][0];
	r0 += M4(-3.032e-02, 9.342e-02, -5.299e-02, 6.623e-02, -1.995e-02, 7.090e-02, -2.518e-02, -1.119e-01, 8.402e-02, -2.177e-01, 2.306e-01, 1.227e-01, 1.030e-01, -2.607e-02, -1.802e-02, 4.857e-03) * s[2][1][1];
	r0 += M4(-1.909e-01, 1.106e-02, 1.810e-02, 9.449e-04, 1.134e-01, -2.160e-01, 1.858e-01, -1.287e-01, 6.764e-04, 2.819e-02, -1.408e-01, 7.105e-02, -1.024e-01, -8.755e-02, 7.022e-03, -1.115e-01) * s[2][2][0];
	r0 += M4(-3.397e-02, -1.333e-02, 6.860e-02, 6.502e-02, 2.658e-02, 4.359e-02, -1.663e-02, -1.173e-01, 6.228e-02, 2.173e-01, -2.108e-02, -7.624e-03, -3.765e-02, -3.423e-02, 4.531e-02, -4.495e-02) * s[2][2][1];
	r0 += V4(-1.611e-01, -3.602e-02, 2.323e-02, -5.681e-03);
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
	r0 += M4(1.627e-01, 2.060e-01, 8.291e-04, 3.004e-01, 1.715e-02, 3.538e-02, -3.624e-02, 3.427e-02, 2.854e-02, -7.838e-02, 3.772e-02, -1.624e-01, 8.180e-02, 5.716e-02, -2.111e-02, 7.705e-02) * s[0][0][0];
	r0 += M4(3.379e-02, 5.977e-03, -1.037e-02, -5.779e-02, 4.923e-02, 1.773e-01, -5.558e-02, 7.451e-02, 1.691e-02, -5.705e-02, -6.635e-03, 8.904e-03, -7.199e-02, -1.232e-01, 8.367e-02, 2.629e-02) * s[0][0][1];
	r0 += M4(6.764e-02, 2.979e-01, 3.711e-02, 2.724e-01, -3.690e-03, 1.349e-04, 4.248e-02, 1.170e-01, -2.943e-02, 2.787e-02, 1.285e-01, 1.452e-01, 7.650e-02, 1.499e-01, 8.266e-03, 2.881e-02) * s[0][1][0];
	r0 += M4(-1.184e-03, -4.809e-03, 4.518e-02, -3.310e-02, 1.752e-02, -1.741e-01, 8.466e-02, 9.546e-02, 5.808e-03, 2.407e-02, 2.028e-02, 6.909e-02, 7.874e-02, 2.111e-01, -2.693e-02, 2.881e-01) * s[0][1][1];
	r0 += M4(3.145e-02, 1.973e-01, -1.155e-01, 2.457e-01, 1.582e-02, -3.996e-02, 5.762e-02, 4.985e-02, -6.556e-02, -1.111e-02, -1.234e-02, 2.088e-03, 5.629e-02, -6.611e-02, 1.374e-02, -1.699e-01) * s[0][2][0];
	r0 += M4(-2.280e-02, 6.885e-05, -5.286e-03, 2.301e-02, -7.593e-02, 1.626e-01, -2.088e-02, -4.619e-02, -6.786e-02, -1.023e-01, 2.255e-02, -1.166e-02, -1.503e-02, -4.945e-02, 6.567e-02, -6.431e-02) * s[0][2][1];
	r0 += M4(1.081e-01, -7.012e-01, -3.196e-01, 3.764e-01, 7.010e-02, -1.037e-01, -6.658e-03, -8.099e-02, 1.362e-01, 3.169e-02, -5.556e-02, -3.126e-01, 1.665e-01, 6.039e-01, -2.998e-01, 2.037e-01) * s[1][0][0];
	r0 += M4(1.142e-01, -9.247e-04, -4.158e-02, -1.414e-01, 1.202e-01, 1.801e-02, 1.518e-01, -9.888e-02, 2.869e-02, 7.354e-02, -3.795e-02, -1.511e-02, 1.079e-01, 2.568e-01, -2.254e-01, 6.007e-02) * s[1][0][1];
	r0 += M4(-3.845e-01, -2.593e+00, 9.137e-01, 2.405e-01, 5.459e-02, 1.753e-01, -2.488e-01, 1.576e-01, 3.525e-01, 1.814e-02, -2.589e-01, 1.339e-01, -5.826e-02, -1.027e+00, 2.166e-02, 1.273e-01) * s[1][1][0];
	r0 += M4(-1.720e-02, -1.232e-01, -8.084e-03, 1.903e-01, -2.842e-01, -8.965e-01, -9.264e-02, -8.911e-01, 1.832e-01, 1.577e-01, -2.329e-01, 1.465e-01, 4.782e-03, -1.749e-01, -2.436e-01, 2.231e-01) * s[1][1][1];
	r0 += M4(4.184e-01, -1.648e-01, 6.307e-02, 3.377e-01, 1.190e-01, 1.650e-02, -1.374e-02, 1.848e-01, 3.135e-01, 1.793e-01, -8.026e-02, -6.107e-01, -2.904e-02, 1.024e-01, 5.292e-03, 5.750e-02) * s[1][2][0];
	r0 += M4(1.291e-01, 2.594e-02, -7.402e-02, 1.243e-02, 3.408e-01, -1.894e-01, 1.097e-01, -1.318e-01, 2.065e-01, 1.244e-01, -1.146e-01, 2.037e-01, 7.594e-02, 1.092e-01, 3.787e-02, 1.898e-01) * s[1][2][1];
	r0 += M4(-5.464e-02, -3.383e-01, -3.678e-01, 3.826e-01, 2.346e-02, -1.691e-02, -1.401e-02, 1.974e-03, 7.640e-02, 1.129e-01, 1.717e-02, -1.584e-02, -2.489e-02, -5.134e-03, -5.184e-02, 2.393e-03) * s[2][0][0];
	r0 += M4(-1.065e-01, -2.108e-02, 3.389e-02, 5.913e-02, 4.685e-02, 2.973e-02, 1.312e-01, 1.244e-03, 1.192e-02, -1.271e-02, 1.011e-02, 1.453e-02, 2.166e-02, -1.909e-02, -9.091e-02, -9.248e-02) * s[2][0][1];
	r0 += M4(-1.315e-01, -1.915e+00, 5.147e-01, 1.663e-01, 1.069e-01, 3.944e-02, -1.832e-01, -7.476e-03, 1.366e-01, 4.450e-02, 3.719e-01, 6.248e-02, 7.678e-04, 3.467e-01, -1.724e-01, 5.081e-02) * s[2][1][0];
	r0 += M4(1.344e-01, -1.907e-02, 1.860e-01, -3.385e-02, 1.392e-01, 7.039e-02, 3.819e-02, -4.922e-03, -3.325e-02, -1.331e-01, -9.602e-02, -2.899e-02, 3.850e-02, 3.012e-01, -3.575e-01, 1.863e-03) * s[2][1][1];
	r0 += M4(-1.205e-02, 1.388e-01, -5.133e-02, 4.700e-01, 5.302e-02, 1.947e-01, -1.278e-01, 9.515e-02, -5.253e-01, -6.529e-02, -9.732e-02, 8.872e-02, -6.677e-02, 7.765e-02, -6.165e-02, 3.865e-02) * s[2][2][0];
	r0 += M4(-1.685e-01, -5.729e-02, -1.516e-02, -7.203e-02, 1.169e-01, 2.299e-01, -3.137e-02, 1.353e-01, 2.773e-02, 1.943e-01, -5.344e-02, 1.044e-01, -2.097e-02, 5.859e-02, -1.970e-02, 4.876e-02) * s[2][2][1];
	r0 += V4(8.999e-03, -3.035e-02, -2.330e-03, 7.083e-03);
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
	r0 += M4(-1.106e-01, -5.725e-02, -3.699e-02, 4.703e-02, 1.186e-01, -5.969e-03, 6.295e-03, -2.700e-02, 1.082e-01, 1.931e-02, -1.553e-03, -1.721e-02, -1.658e-01, -4.356e-02, 4.847e-02, 3.952e-02) * s[0][0][0];
	r0 += M4(7.598e-02, 2.240e-02, -7.629e-02, -3.368e-02, 3.289e-02, 6.210e-03, 1.352e-02, -1.605e-02, 2.447e-01, -5.681e-02, 7.547e-02, -7.251e-02, -5.833e-02, -6.056e-03, -2.458e-02, -1.955e-03) * s[0][0][1];
	r0 += M4(3.284e-02, 2.056e-01, -1.986e-02, -1.182e-02, 2.080e-02, 9.595e-02, -4.332e-02, 1.570e-02, -5.786e-02, 7.731e-02, 3.480e-02, 5.139e-02, -5.228e-02, -9.241e-02, 8.772e-02, 1.110e-01) * s[0][1][0];
	r0 += M4(-5.164e-02, 2.852e-02, -2.863e-02, -5.142e-02, -8.443e-02, -4.211e-02, 5.384e-03, 3.127e-02, -4.123e-01, 1.225e-01, 2.730e-02, 2.006e-01, 2.787e-02, -1.852e-02, 2.796e-02, -1.499e-04) * s[0][1][1];
	r0 += M4(1.257e-01, -7.299e-03, 7.318e-02, -8.631e-03, -2.443e-02, 1.218e-02, -7.077e-03, -3.137e-02, -6.091e-03, -4.516e-02, 8.814e-05, -6.908e-03, 1.127e-02, -3.020e-02, 5.886e-03, 3.923e-03) * s[0][2][0];
	r0 += M4(-6.070e-03, -1.977e-02, -6.214e-03, -3.082e-02, -3.791e-03, -1.306e-02, -3.955e-03, 4.134e-03, 1.180e-01, -5.333e-02, 3.388e-02, 3.424e-02, 5.273e-03, -1.644e-03, 1.903e-05, -2.283e-04) * s[0][2][1];
	r0 += M4(1.081e-01, -1.805e-02, 2.627e-01, -9.270e-02, 2.265e-02, -3.277e-03, 1.241e-02, 7.425e-03, -1.009e-01, -8.761e-03, 4.183e-02, 1.733e-02, 3.174e-01, -4.795e-03, -1.022e-02, -4.764e-02) * s[1][0][0];
	r0 += M4(-1.762e-02, -5.407e-02, 1.333e-01, -2.325e-02, -7.104e-02, 1.217e-02, -3.235e-02, 3.521e-02, 1.613e-01, -1.243e-01, 1.978e-01, -8.376e-02, 1.401e-01, 2.493e-02, 1.608e-02, -1.431e-02) * s[1][0][1];
	r0 += M4(-3.479e-01, 1.779e-02, -5.983e-02, 7.131e-01, -1.968e-01, -2.822e-01, -2.192e-01, -3.081e-01, -2.917e-02, -1.856e-01, -1.440e-01, -1.082e-01, 1.083e-03, 5.723e-01, -1.482e-01, 6.413e-02) * s[1][1][0];
	r0 += M4(6.707e-03, 8.194e-02, -1.574e-02, 1.763e-01, -8.963e-02, -1.841e-01, -1.631e-01, -2.170e-01, -2.590e-02, 3.018e-01, -8.370e-01, -1.294e-01, 3.632e-02, 1.479e-01, 5.701e-02, 7.976e-02) * s[1][1][1];
	r0 += M4(1.539e-01, 2.205e-02, 1.353e-01, -7.344e-02, -1.356e-02, 7.202e-02, -5.317e-02, 2.484e-02, 2.300e-02, 7.836e-02, 4.034e-02, 3.969e-02, 1.072e-01, -9.059e-02, 8.716e-02, -4.183e-02) * s[1][2][0];
	r0 += M4(4.855e-03, -2.874e-02, -1.653e-03, -9.133e-03, 1.081e-04, 3.181e-03, -1.723e-03, -2.557e-02, 1.125e-01, 1.275e-01, 9.495e-02, -1.757e-01, 7.935e-03, 3.609e-03, 2.422e-02, 2.887e-02) * s[1][2][1];
	r0 += M4(8.533e-02, 4.192e-02, -5.917e-02, 2.093e-02, -1.370e-02, -1.814e-02, 8.960e-02, -1.428e-02, 2.324e-02, 1.241e-02, 1.638e-03, 3.284e-02, -1.155e-01, -3.451e-02, -1.503e-02, -8.376e-02) * s[2][0][0];
	r0 += M4(-2.325e-03, 2.408e-03, -1.095e-02, 1.150e-02, 8.753e-03, -1.907e-04, 8.379e-03, 1.063e-02, -5.578e-02, -6.608e-04, 1.936e-02, -4.348e-02, -3.023e-02, -3.481e-02, 6.519e-02, 5.535e-03) * s[2][0][1];
	r0 += M4(1.675e-01, 8.847e-02, 2.713e-02, -1.825e-01, -3.136e-02, -2.837e-02, 3.121e-02, 5.041e-02, -4.851e-03, 3.101e-03, 4.505e-02, -2.945e-02, -4.248e-03, -2.008e-02, -1.522e-02, 2.466e-01) * s[2][1][0];
	r0 += M4(9.722e-03, 8.438e-03, 1.972e-02, 1.630e-02, -1.095e-02, -4.666e-03, -9.259e-03, -2.907e-02, -1.455e-01, -1.306e-01, 1.692e-01, 1.851e-01, 1.472e-02, -3.408e-02, 1.514e-02, 3.485e-02) * s[2][1][1];
	r0 += M4(-8.305e-02, 2.140e-02, 6.559e-03, 1.460e-01, -3.259e-02, -4.435e-02, -1.652e-02, 4.358e-02, -1.386e-02, -2.838e-02, -1.164e-02, 6.713e-03, 2.260e-02, 1.357e-03, 6.044e-02, -7.247e-02) * s[2][2][0];
	r0 += M4(7.938e-03, 1.027e-02, 6.724e-03, -1.053e-02, -1.941e-02, -2.156e-02, -1.065e-02, -4.136e-03, -2.382e-02, -1.155e-01, 3.468e-02, 6.103e-02, -6.178e-03, 3.307e-02, -3.548e-03, 2.923e-02) * s[2][2][1];
	r0 += V4(-1.565e-03, -1.374e-03, -1.126e-03, -1.022e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

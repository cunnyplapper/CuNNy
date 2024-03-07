// CuNNy 2x4C DS
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


//!DESC CuNNy-2x4C-DS-in
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
	r += V4(4.945e-02, 2.857e-02, 1.151e-02, 2.639e-03) * s0[y+0][x+0];
	r += V4(-1.336e-01, -1.673e-01, 7.282e-02, 5.149e-01) * s0[y+0][x+1];
	r += V4(7.716e-02, 3.745e-02, -7.740e-02, -6.619e-02) * s0[y+0][x+2];
	r += V4(-1.160e-01, 6.660e-01, -3.145e-02, -2.243e-02) * s0[y+1][x+0];
	r += V4(5.612e-01, -1.741e-01, -3.115e-02, 1.845e-01) * s0[y+1][x+1];
	r += V4(1.492e-01, -5.631e-02, -4.497e-01, 2.337e-02) * s0[y+1][x+2];
	r += V4(5.446e-02, -1.150e-01, 3.370e-02, -1.649e-03) * s0[y+2][x+0];
	r += V4(-1.603e-03, -1.209e-01, -9.685e-03, -2.102e-02) * s0[y+2][x+1];
	r += V4(-7.325e-01, 4.210e-02, 1.053e-01, -1.982e-02) * s0[y+2][x+2];
	r += V4(-1.042e-03, -4.879e-02, 6.120e-03, -9.492e-03);
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


//!DESC CuNNy-2x4C-DS-conv1
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
	r += M4(-7.468e-02, 4.565e-01, -9.873e-02, -1.655e-01, -7.352e-02, 7.187e-02, -1.062e-01, -2.870e-02, 1.846e-01, -4.522e-01, -2.085e-01, 7.584e-02, -8.295e-02, 1.326e-02, -4.871e-02, 3.473e-02) * s0[y+0][x+0];
	r += M4(-1.646e-01, 2.751e-01, 3.216e-02, -8.109e-02, 9.244e-03, 5.932e-04, 4.067e-02, 8.665e-03, -5.378e-01, 3.176e-01, 5.204e-01, -3.700e-01, 1.314e-01, -9.594e-02, 4.637e-02, -5.023e-03) * s0[y+0][x+1];
	r += M4(1.330e-02, 6.055e-02, 9.843e-02, -3.685e-02, -1.675e-01, -1.025e-02, 8.903e-02, 5.904e-02, 4.226e-01, -2.474e-02, 9.647e-02, 2.588e-01, -6.816e-02, 3.400e-02, -6.546e-02, 6.963e-03) * s0[y+0][x+2];
	r += M4(-4.472e-02, 5.259e-02, 3.389e-01, -2.045e-02, 2.778e-02, -8.616e-02, 4.672e-02, 3.419e-02, -4.757e-01, -1.151e+00, 1.212e+00, -1.694e+00, 2.584e-01, -6.946e-02, 6.035e-02, 1.480e-02) * s0[y+1][x+0];
	r += M4(-2.381e-02, -8.222e-02, -3.936e-01, 3.564e-01, -1.578e-01, -2.313e-02, 2.034e-02, -2.237e-01, -1.223e+00, -2.046e-03, 5.731e-01, -1.228e+00, 2.624e-02, -1.704e-02, 3.038e-01, -1.062e-01) * s0[y+1][x+1];
	r += M4(-1.563e-01, 1.895e-01, 5.893e-02, 2.782e-02, 7.211e-01, -4.667e-01, 6.694e-02, 2.183e-01, -2.230e-01, 1.782e-01, 2.132e-01, -3.977e-01, -2.319e-01, 1.564e-01, 5.499e-02, -1.990e-01) * s0[y+1][x+2];
	r += M4(8.945e-02, -8.432e-02, 1.299e-02, 5.768e-02, -4.699e-02, 3.914e-02, -7.006e-02, 9.205e-02, -4.680e-01, 4.828e-01, -4.536e-01, -2.795e-01, -1.319e-01, 4.895e-02, 1.708e-01, 3.932e-02) * s0[y+2][x+0];
	r += M4(-2.083e-01, 9.695e-02, 3.096e-01, -1.477e-01, -3.721e-01, 2.916e-01, -1.686e-01, -3.789e-01, -5.043e-01, -4.054e-02, 5.095e-01, 6.266e-01, 2.634e-01, -4.976e-02, -1.111e-01, 3.036e-01) * s0[y+2][x+1];
	r += M4(1.140e-01, -1.724e-01, -5.981e-02, -4.789e-02, 9.240e-02, -3.715e-02, -4.390e-01, 3.781e-01, 5.574e-01, -4.280e-01, -2.519e-01, 6.992e-01, -1.813e-01, -1.964e-01, -1.313e-01, 2.782e-01) * s0[y+2][x+2];
	r += M4(-2.806e-01, 1.605e-01, 8.793e-01, 1.898e-01, -5.598e-02, 8.255e-04, 8.162e-02, 4.233e-02, 1.771e-01, 6.960e-02, 3.486e-01, -1.929e-01, -5.003e-01, 1.626e-01, 3.278e-01, 5.141e-02) * s1[y+0][x+0];
	r += M4(1.431e-04, 5.285e-02, 2.647e-01, -3.341e-01, 7.014e-02, -6.898e-02, 3.584e-01, -1.280e-01, -2.643e-01, 3.076e-01, -8.014e-02, -2.999e-02, 3.603e-01, 2.531e-01, 5.494e-01, -1.602e-01) * s1[y+0][x+1];
	r += M4(-1.073e-02, 6.519e-02, 3.147e-02, -2.377e-02, -4.072e-02, 6.889e-02, 9.944e-02, -1.142e-01, 9.482e-02, -6.597e-02, -7.190e-02, 5.509e-02, 2.280e-01, 2.331e-01, 5.622e-01, 1.752e-01) * s1[y+0][x+2];
	r += M4(3.488e-01, -1.450e-01, 3.113e-01, -1.329e-01, 7.042e-02, -4.064e-02, -2.126e-02, -1.166e-02, 1.722e-02, 4.322e-02, 2.308e-01, -4.997e-03, 9.932e-01, -6.335e-01, 8.833e-01, 1.340e+00) * s1[y+1][x+0];
	r += M4(5.723e-01, -5.368e-01, -5.102e-01, 2.050e-01, 6.391e-02, 6.663e-02, -6.680e-03, 1.775e-02, 3.637e-01, -3.584e-01, -1.518e-01, 1.537e-01, 2.395e+00, -1.011e-01, -6.430e-01, 2.687e+00) * s1[y+1][x+1];
	r += M4(-2.016e-01, 1.721e-01, 6.247e-02, -5.583e-03, -4.880e-02, -1.074e-01, 7.147e-02, 1.689e-01, -2.647e-01, 1.186e-01, -9.716e-02, -1.985e-02, 1.407e+00, 5.356e-01, -3.130e-01, 2.317e-01) * s1[y+1][x+2];
	r += M4(6.811e-02, -2.886e-02, -1.890e-01, 6.864e-02, 1.811e-02, 2.936e-02, 1.656e-03, -1.366e-02, -2.587e-01, 6.477e-03, -1.647e-01, -6.543e-02, 5.306e-01, -3.390e-01, 7.080e+00, 1.020e+00) * s1[y+2][x+0];
	r += M4(-1.775e-02, 2.921e-02, 2.949e-02, 4.535e-02, -9.034e-03, 5.507e-02, -1.407e-01, -2.285e-01, -3.014e-01, -2.323e-01, 2.489e-02, 2.891e-02, 1.196e+00, 2.242e+00, -1.523e+00, 5.715e+00) * s1[y+2][x+1];
	r += M4(5.254e-02, -5.009e-02, -2.570e-02, 1.910e-02, -9.107e-02, -6.706e-02, 1.265e-01, 4.632e-03, 2.350e-01, -2.079e-01, 4.975e-02, -5.764e-02, 1.712e+00, -3.841e-01, -1.629e+00, 3.233e+00) * s1[y+2][x+2];
	r += V4(2.902e-02, 6.998e-03, -9.106e-02, -1.082e-02);
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


//!DESC CuNNy-2x4C-DS-conv2
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
	r += M4(-1.205e-01, 1.008e-01, 9.503e-03, -1.504e-02, 4.729e-02, 1.255e-01, 2.506e-02, 1.267e-01, -2.782e-01, -5.140e-02, 2.026e-03, -3.090e-02, -4.117e-02, -2.418e-02, -3.777e-02, -1.488e-02) * s0[y+0][x+0];
	r += M4(-5.358e-02, -9.424e-02, 3.401e-02, 8.980e-02, -9.985e-02, -1.401e-01, -5.319e-02, -1.782e-01, -4.229e-01, 8.058e-02, -3.919e-02, 1.588e-01, 7.790e-02, 7.739e-02, -8.721e-02, -2.601e-02) * s0[y+0][x+1];
	r += M4(5.181e-02, 2.493e-02, 7.495e-02, 1.152e-01, -3.215e-02, -5.898e-02, 5.096e-02, -2.953e-02, -3.273e-01, 7.596e-01, -1.126e-01, 1.841e-01, 2.639e-02, 5.863e-02, -3.880e-02, -2.682e-02) * s0[y+0][x+2];
	r += M4(-5.409e-02, 1.224e-02, -5.582e-02, -9.680e-02, -2.515e-02, 2.181e-01, -1.807e-02, -1.373e-02, -3.079e-01, -3.051e-01, -4.671e-02, -6.870e-01, 4.634e-02, 7.768e-02, -1.640e-02, 4.319e-02) * s0[y+1][x+0];
	r += M4(2.007e-01, 1.614e-01, -1.361e-01, -1.416e-01, 2.899e-01, 1.194e-01, -2.845e-01, 1.854e-01, -8.290e-02, 9.744e-01, 1.956e-02, 4.669e-01, -1.421e-01, -6.914e-02, -1.822e-01, 3.653e-02) * s0[y+1][x+1];
	r += M4(-1.125e-01, 7.016e-02, -3.630e-02, -3.049e-01, -1.102e-01, 1.043e-01, 1.251e-01, -1.910e-02, -1.700e+00, -1.535e-01, 6.655e+00, -9.035e-01, -4.358e-02, -1.642e-01, -1.137e-01, -3.082e-02) * s0[y+1][x+2];
	r += M4(-1.746e-01, 4.558e-02, 2.083e-02, -1.610e-01, -1.241e-01, 3.925e-02, 2.613e-02, -1.894e-01, -2.000e-01, -9.040e-02, -2.031e-02, -1.900e-01, 4.504e-02, -1.054e-02, 1.876e-02, 9.643e-02) * s0[y+2][x+0];
	r += M4(3.626e-01, -1.685e-01, 2.892e-02, 1.819e-01, -2.506e-02, -7.205e-02, 3.513e-02, -3.057e-01, 1.570e-01, 1.577e-01, 8.000e-02, 2.559e-01, 3.946e-02, 3.921e-02, -2.149e-02, 1.005e-03) * s0[y+2][x+1];
	r += M4(-1.616e-01, -1.788e-02, 6.236e-02, -2.294e-01, -2.466e-01, -7.858e-02, -7.844e-03, -1.910e-01, -2.388e-01, 6.975e-02, -3.918e-02, -5.724e-02, 5.113e-02, -1.487e-02, -1.373e-02, 1.098e-01) * s0[y+2][x+2];
	r += M4(-1.561e-01, 1.780e-01, 3.852e-02, -1.026e-01, -6.044e-02, 8.186e-01, -9.108e-02, 3.806e-01, 1.896e-02, 1.861e-02, 1.740e-02, -1.452e-02, 1.529e-02, -7.196e-02, 3.076e-02, 6.700e-02) * s1[y+0][x+0];
	r += M4(5.158e-02, 6.732e-02, 8.663e-02, 4.040e-01, -2.753e-01, -6.494e-01, -2.815e-02, 5.717e-01, 1.836e-02, 1.836e-02, 8.221e-03, 1.001e-01, -2.039e-01, -5.295e-01, 9.634e-03, 1.488e-01) * s1[y+0][x+1];
	r += M4(2.658e-01, -8.030e-01, 9.270e-02, 4.676e-01, -6.384e-02, -1.592e-01, -6.129e-03, 1.215e-01, 7.354e-03, 8.095e-02, -1.562e-02, -2.160e-02, 8.795e-03, -2.085e-02, -1.017e-01, -2.056e-01) * s1[y+0][x+2];
	r += M4(9.354e-02, 9.270e-02, -3.800e-02, -1.294e-01, -1.314e-01, 3.544e-01, -7.048e-02, -1.793e-01, 5.819e-02, -1.809e-02, -2.727e-02, -7.281e-02, -1.592e-01, -3.248e-02, 2.292e-02, -2.650e-01) * s1[y+1][x+0];
	r += M4(-3.037e-01, 9.007e-01, -2.227e-01, 5.293e-01, 5.801e-01, -3.291e-01, -2.164e-01, 3.237e-02, 3.177e-01, 6.017e-02, 2.217e-02, 2.958e-01, 2.822e-01, -4.852e-01, -2.981e+00, 2.464e-01) * s1[y+1][x+1];
	r += M4(-1.159e-01, -8.348e-01, -2.702e+00, 1.680e-01, -1.252e-01, 2.729e-01, 7.835e-02, -3.143e-01, -8.876e-02, -7.770e-02, -1.421e-01, -2.779e-01, 1.026e-01, -2.069e-01, -1.491e+00, -3.112e-01) * s1[y+1][x+2];
	r += M4(-1.403e-01, 1.129e-01, 5.163e-03, -2.245e-01, -2.752e-02, 2.802e-01, 6.253e-02, -3.879e-02, -6.040e-02, 4.283e-02, 1.124e-02, -5.453e-02, -1.644e-02, 5.057e-02, -2.609e-02, 1.001e-01) * s1[y+2][x+0];
	r += M4(1.909e-01, -6.631e-02, 9.019e-02, -7.804e-02, 1.378e-01, -2.192e-01, -4.510e-02, -2.409e-02, 1.538e-01, -8.796e-02, 2.569e-02, 8.432e-02, -4.798e-02, -8.862e-02, -1.571e+00, 2.220e-01) * s1[y+2][x+1];
	r += M4(-4.064e-01, -3.259e-02, 3.660e-02, -4.055e-01, -7.272e-02, -9.077e-02, 7.718e-02, -1.229e-01, 6.911e-02, 5.167e-04, 6.760e-03, -4.184e-02, 2.127e-01, -1.224e-03, -1.577e-01, 1.479e-01) * s1[y+2][x+2];
	r += V4(1.107e-02, -6.778e-03, 1.228e-01, 3.137e-02);
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


//!DESC CuNNy-2x4C-DS-out
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
	r += M4(-5.188e-02, 1.038e-01, 8.401e-02, 1.626e-01, 1.749e-01, 3.678e-02, -1.027e-02, -9.005e-02, -5.383e-02, 2.680e-02, 2.508e-02, 4.552e-02, -8.596e-02, -2.971e-02, 5.241e-02, 6.559e-02) * s0[y+0][x+0];
	r += M4(2.432e-01, -7.061e-02, -6.328e-03, 4.720e-03, -3.336e-02, 5.970e-02, -7.446e-02, -1.474e-02, -1.339e-02, -5.536e-02, -5.498e-03, 7.647e-03, 1.334e-02, -8.731e-02, -1.171e-01, -9.788e-02) * s0[y+0][x+1];
	r += M4(-4.758e-02, 1.529e-01, -1.519e-01, -1.529e-01, -1.347e-02, 3.729e-02, -1.655e-02, -1.264e-02, 3.763e-02, 5.243e-03, 2.985e-02, -5.214e-03, -3.112e-02, 5.375e-03, -5.303e-03, -2.939e-02) * s0[y+0][x+2];
	r += M4(2.666e-01, 9.306e-02, -2.185e-01, 1.021e-02, -1.024e-01, -4.412e-01, 1.216e-01, -1.049e-01, -1.028e-02, 2.690e-02, -8.904e-02, -1.922e-02, -1.119e-02, -1.796e-02, -9.094e-02, -7.039e-02) * s0[y+1][x+0];
	r += M4(-9.355e-01, -1.571e-01, -2.868e-01, -7.198e-01, -6.839e-02, 1.002e-01, 1.501e-02, 6.764e-02, -2.578e-02, -4.860e-02, -2.769e-02, -7.251e-02, 1.830e-01, 9.774e-02, 3.955e-01, 1.656e-01) * s0[y+1][x+1];
	r += M4(2.056e-01, -2.826e-01, 4.142e-01, 4.413e-01, -1.628e-01, -4.185e-02, -1.260e-01, 7.788e-02, 2.814e-02, 1.124e-02, 3.659e-02, 1.060e-02, -1.597e-01, -7.287e-02, -1.795e-01, 1.363e-02) * s0[y+1][x+2];
	r += M4(-9.070e-02, -1.714e-01, 3.331e-01, -3.898e-02, 1.267e-01, 4.755e-02, 8.813e-02, -1.791e-01, 5.759e-03, 9.349e-05, 1.224e-02, 2.764e-02, -3.172e-02, 2.066e-02, -8.581e-02, -1.535e-02) * s0[y+2][x+0];
	r += M4(5.627e-02, 1.332e-01, -1.694e-01, 5.527e-01, -4.968e-02, 5.416e-02, -7.883e-02, 1.665e-01, 5.806e-03, 1.269e-03, -8.534e-03, -2.801e-02, -1.672e-02, -5.787e-02, -9.665e-02, -1.206e-01) * s0[y+2][x+1];
	r += M4(2.666e-01, 1.088e-01, 5.212e-02, -3.164e-01, 4.359e-03, 1.398e-02, -2.770e-02, -3.796e-02, -2.396e-03, 1.485e-03, -5.134e-04, 4.655e-03, 3.360e-02, 1.901e-02, 2.072e-02, -2.638e-02) * s0[y+2][x+2];
	r += M4(1.294e-01, 6.374e-02, 7.653e-02, 1.297e-02, 9.046e-02, -1.188e-02, -3.199e-02, -9.204e-02, -1.850e+00, -1.320e+00, -1.212e+00, -6.603e-01, 1.055e-02, -1.901e-03, 1.472e-02, -1.782e-02) * s1[y+0][x+0];
	r += M4(-2.055e-01, -3.604e-02, 7.912e-02, 1.134e-01, 7.014e-02, 7.005e-02, -7.938e-02, -3.920e-02, -1.648e+00, -1.202e+00, -8.346e-01, -8.149e-01, 2.725e-01, 9.356e-02, -1.132e-01, -7.297e-02) * s1[y+0][x+1];
	r += M4(6.140e-02, -4.676e-02, 4.577e-02, 4.750e-02, -4.462e-02, 5.043e-02, -7.477e-04, -4.780e-03, 4.190e-02, -9.318e-01, -6.351e-02, -5.973e-01, -6.018e-02, 1.323e-01, -6.959e-02, -7.446e-02) * s1[y+0][x+2];
	r += M4(-5.719e-02, -3.374e-02, -1.092e-03, 3.328e-02, -1.615e-01, -1.715e-03, -4.883e-03, 6.959e-02, -1.820e+00, -2.034e+00, -6.848e-01, -1.419e+00, -2.557e-01, 1.265e-01, -1.815e-02, 1.489e-01) * s1[y+1][x+0];
	r += M4(-1.215e-01, -8.325e-02, -5.566e-01, -3.355e-01, 1.755e-01, -2.376e-01, 1.665e-01, -1.411e-01, -2.311e+00, -1.646e+00, -1.735e+00, -5.490e-01, -1.039e-01, -6.621e-01, 5.488e-01, -4.052e-02) * s1[y+1][x+1];
	r += M4(1.660e-01, 1.151e-01, 1.968e-01, -4.066e-02, -1.958e-01, 7.250e-02, -2.240e-01, 7.075e-02, -9.022e-02, -1.083e+00, 2.391e-01, -8.705e-01, -2.183e-01, -1.688e-02, -1.699e-01, 2.539e-01) * s1[y+1][x+2];
	r += M4(5.755e-02, 9.419e-03, 6.765e-02, 2.921e-03, 4.430e-02, 8.034e-03, 4.945e-03, 1.886e-02, 2.923e-01, 2.222e-01, -1.482e+00, -1.005e+00, 5.334e-02, 2.419e-02, -1.584e-01, 2.910e-02) * s1[y+2][x+0];
	r += M4(-3.107e-02, 3.000e-02, 1.034e-01, 1.261e-01, 5.033e-02, 2.919e-02, 1.961e-01, 2.265e-02, 3.168e-01, 3.643e-01, -1.071e+00, -1.408e+00, 1.862e-01, 7.139e-02, -1.014e-01, -4.033e-01) * s1[y+2][x+1];
	r += M4(-3.036e-02, -4.213e-02, -3.618e-02, 1.383e-02, -6.324e-02, -3.629e-03, -8.994e-02, 5.739e-02, -1.901e-01, 6.785e-02, -2.846e-01, -3.239e-01, -1.896e-02, 8.376e-02, -2.972e-02, 5.205e-02) * s1[y+2][x+2];
	r += V4(2.998e-03, 3.836e-03, 3.017e-03, 3.370e-03);
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
	memoryBarrierShared();
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-2x4C-DS-shuffle
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

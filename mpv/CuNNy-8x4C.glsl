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
	r += V4(2.017e-02, -1.532e-02, -7.505e-02, -2.661e-02) * s0[y+0][x+0];
	r += V4(7.668e-02, -1.126e-02, -7.955e-02, 3.623e-01) * s0[y+0][x+1];
	r += V4(3.392e-01, 4.001e-02, -1.973e-02, -6.706e-01) * s0[y+0][x+2];
	r += V4(-2.865e-02, -2.892e-02, -5.697e-02, 4.376e-02) * s0[y+1][x+0];
	r += V4(2.055e-02, 7.813e-01, 5.281e-01, 4.244e-01) * s0[y+1][x+1];
	r += V4(-3.892e-01, 1.166e-01, 4.308e-02, -9.165e-02) * s0[y+1][x+2];
	r += V4(3.320e-03, 2.292e-02, -1.319e-01, -4.660e-02) * s0[y+2][x+0];
	r += V4(-1.025e-02, -9.109e-02, -1.911e-01, 2.763e-03) * s0[y+2][x+1];
	r += V4(-2.995e-02, -9.601e-03, -9.497e-02, -2.821e-02) * s0[y+2][x+2];
	r += V4(3.550e-02, -1.164e-02, 3.962e-03, 7.153e-02);
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
	r += M4(1.920e-02, 1.512e-01, -1.762e-01, 2.158e-01, 1.429e-02, -7.528e-02, -7.699e-02, -9.295e-03, 1.736e-01, 2.834e-01, -5.065e-02, 4.177e-02, -9.488e-02, 1.496e-01, -1.342e-02, -3.275e-02) * s0[y+0][x+0];
	r += M4(1.638e-01, -4.623e-02, 9.681e-02, -4.502e-01, -5.055e-01, -9.923e-02, -1.403e-01, -2.824e-01, -1.902e-01, -2.688e-02, -4.708e-02, -6.648e-01, 1.178e-02, 1.170e-02, 1.012e-01, -3.535e-02) * s0[y+0][x+1];
	r += M4(-6.672e-02, -1.294e-01, -4.065e-01, 1.748e-01, -7.987e-02, -1.971e-02, -4.414e-01, -1.374e-01, -4.112e-02, 1.347e-01, -4.550e-01, 1.772e-01, 1.189e-01, -4.298e-02, -6.235e-02, -9.767e-02) * s0[y+0][x+2];
	r += M4(-2.913e-01, -1.625e-02, 1.943e-01, -2.072e-01, -9.546e-02, -4.237e-01, -7.897e-04, -1.262e-01, -8.723e-02, -8.643e-01, -5.313e-02, 5.871e-02, 2.705e-01, -6.861e-01, 7.056e-02, 5.776e-01) * s0[y+1][x+0];
	r += M4(3.596e-01, 3.051e-01, -1.694e-01, -3.173e-01, 2.528e-02, 1.518e-01, 1.297e-01, -2.587e-02, 4.148e-01, 4.300e-01, 9.026e-02, 2.783e-01, -1.310e-02, 1.037e-01, -6.281e-03, -4.347e-01) * s0[y+1][x+1];
	r += M4(-4.578e-01, -6.972e-02, 6.095e-02, 1.657e-01, -3.837e-01, 5.342e-03, 3.021e-01, -1.165e-01, -2.262e-01, -5.599e-03, 4.814e-01, 1.302e-01, -3.037e-01, 6.612e-02, 2.128e-01, 6.211e-02) * s0[y+1][x+2];
	r += M4(-1.128e-01, -1.438e-01, -2.482e-02, 1.538e-01, 4.870e-02, -1.581e-02, -7.782e-02, 1.062e-01, 5.322e-02, 2.998e-01, 5.994e-02, -1.619e-01, 9.083e-02, -2.494e-01, -1.060e-01, -2.218e-01) * s0[y+2][x+0];
	r += M4(3.712e-01, -8.755e-02, -1.731e-03, 1.538e-01, -1.081e-01, -5.456e-02, 1.430e-01, 8.096e-02, -2.588e-01, 5.579e-02, -7.675e-02, 2.744e-01, -9.608e-02, -4.774e-02, 2.157e-01, 1.106e-01) * s0[y+2][x+1];
	r += M4(-1.193e-02, -3.462e-02, -2.427e-01, 1.288e-01, 3.501e-02, 5.877e-03, 1.691e-01, 1.658e-01, 9.485e-02, -5.340e-02, 1.225e-01, -2.758e-01, 6.997e-02, 1.515e-02, -1.080e-01, 4.536e-02) * s0[y+2][x+2];
	r += M4(-6.222e-02, 2.646e-01, -1.708e-01, 2.430e-01, -1.394e+00, -1.365e+00, -1.090e+00, -1.651e+00, 1.042e-01, 2.827e-01, -4.816e-02, 1.352e-01, 8.786e-03, -5.382e-02, 1.210e-01, -2.317e-01) * s1[y+0][x+0];
	r += M4(5.188e-02, -2.735e-02, -3.031e-02, -3.283e-01, -2.259e+00, -7.870e-01, -3.735e-01, -2.205e+00, -3.181e-01, -1.818e-01, -1.049e-01, -6.560e-01, -9.135e-02, -9.972e-02, -1.628e-01, 1.759e-01) * s1[y+0][x+1];
	r += M4(-3.440e-02, -1.847e-01, -8.228e-02, -9.037e-02, -1.037e+00, -1.851e-01, -1.302e+00, 1.095e+00, -1.222e-01, -9.845e-02, -2.920e-01, 5.299e-02, 1.418e-02, -7.804e-02, -3.852e-01, 2.101e-02) * s1[y+0][x+2];
	r += M4(2.835e-01, 1.025e-01, 4.397e-01, -3.348e-02, -3.519e-01, -1.191e+00, -1.381e+00, -6.977e-01, -5.604e-02, -3.932e-01, -2.493e-03, -5.397e-02, -8.619e-02, -1.795e-01, -7.347e-02, 3.060e-01) * s1[y+1][x+0];
	r += M4(3.185e-01, 3.832e-01, 4.631e-01, 1.432e-02, 3.136e-01, 9.327e-02, -1.391e+00, 3.514e-01, 3.726e-01, 2.421e-01, -2.229e-01, 3.487e-01, 1.103e-01, 8.834e-02, 3.856e-01, -8.829e-01) * s1[y+1][x+1];
	r += M4(-2.569e-01, -8.302e-02, 1.172e-01, 8.465e-02, -7.624e-01, -3.638e-01, -5.595e-01, 1.040e+00, -9.105e-02, -2.332e-02, 6.660e-01, 2.112e-01, -2.804e-01, 1.066e-02, 4.455e-01, -7.426e-02) * s1[y+1][x+2];
	r += M4(-4.269e-01, -2.160e-01, 9.781e-02, 2.202e-01, -4.608e-02, -7.055e-01, -1.016e+00, 4.624e-01, -6.805e-02, 1.464e-01, 6.580e-02, 7.441e-02, 2.094e-01, 9.189e-02, -2.070e-02, -1.819e-01) * s1[y+2][x+0];
	r += M4(1.782e-02, -1.190e-01, -2.636e-01, 2.170e-01, -6.239e-01, -2.477e-01, 2.076e-01, 6.989e-01, 1.005e-02, -6.406e-02, -1.401e-01, 7.145e-02, 3.693e-02, -4.943e-02, 6.697e-02, 1.122e-01) * s1[y+2][x+1];
	r += M4(7.323e-02, 5.811e-02, 3.987e-02, -1.158e-02, -7.899e-01, -3.611e-02, 1.452e-01, 9.813e-01, 1.260e-01, -1.170e-02, 6.562e-02, -2.594e-01, 1.057e-01, -1.087e-02, -1.164e-01, 5.475e-02) * s1[y+2][x+2];
	r += V4(-1.747e-02, 2.287e-02, 5.709e-02, 2.616e-01);
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
	r += M4(1.052e+00, 9.757e-02, -3.360e-01, 2.444e-01, 1.254e-01, 2.358e-01, 1.608e-02, 1.689e-01, 1.553e-02, 1.731e-02, 1.494e-01, -6.578e-02, -1.412e-01, 7.473e-02, 8.388e-03, -2.138e-02) * s0[y+0][x+0];
	r += M4(7.183e-02, -4.560e-02, -1.793e+00, 3.627e-01, -1.751e-01, -1.948e-01, 2.703e-02, 5.948e-02, 2.874e-01, 5.809e-02, 3.447e-01, -1.010e-01, 1.668e-02, 3.799e-03, 6.318e-01, 1.778e-02) * s0[y+0][x+1];
	r += M4(-2.745e-01, -1.424e-01, 4.278e-02, 2.403e-01, 1.931e+00, 2.038e-01, -1.802e-01, 3.042e-01, -6.257e-02, 1.007e-03, -5.530e-02, 6.614e-02, -7.656e-04, 1.152e-01, 7.679e-02, 4.922e-03) * s0[y+0][x+2];
	r += M4(1.293e+00, -6.336e-01, 7.299e-01, 3.995e-01, -8.815e-03, 7.481e-02, 2.700e-02, -1.680e-01, 9.937e-02, 2.962e-01, 1.544e-01, -7.787e-01, -4.423e-02, 1.877e-01, -1.519e-02, 9.647e-02) * s0[y+1][x+0];
	r += M4(2.245e+00, 2.959e-01, -1.366e+00, -6.096e-01, -9.391e-02, 3.415e-01, 1.600e-01, -1.348e-02, 3.447e-01, 1.715e-01, 2.729e-01, -2.568e-01, 5.901e-01, -2.893e-02, -3.597e-02, -1.212e-01) * s0[y+1][x+1];
	r += M4(-1.526e-01, -1.116e-01, 2.697e-01, -2.227e-01, 7.671e-01, -8.834e-01, -6.817e-02, 7.986e-03, -1.444e-01, 6.528e-02, -1.948e-01, 7.968e-02, -2.282e-01, 2.201e-02, -5.047e-01, -1.142e-01) * s0[y+1][x+2];
	r += M4(7.892e-02, -3.975e-01, -5.222e-02, -4.919e-02, -5.249e-02, 2.101e-02, -1.517e-02, 1.771e-01, 4.653e-02, -3.514e-01, 2.452e-02, 1.189e-01, 2.676e-02, 1.001e-02, 3.980e-02, 2.207e-01) * s0[y+2][x+0];
	r += M4(-2.372e-02, -8.150e-01, 4.806e-01, -1.469e-01, -2.307e-02, 1.161e-02, -4.949e-02, -5.585e-01, 2.740e-02, -5.502e-02, -1.059e-01, -1.503e-01, 7.852e-02, -3.605e-01, -7.940e-02, -2.098e-01) * s0[y+2][x+1];
	r += M4(-5.118e-02, 2.274e-01, -1.846e-02, -5.864e-02, 9.649e-02, 1.734e-01, -9.071e-03, 1.748e-01, 2.432e-02, -8.655e-02, -1.311e-01, -4.587e-02, -3.047e-02, -7.949e-02, 7.642e-02, -1.353e-01) * s0[y+2][x+2];
	r += M4(-8.577e-02, -6.423e-02, -1.178e-02, 2.351e-02, -7.377e-04, 4.314e-03, 4.884e-02, 7.814e-03, -1.311e-01, 1.744e-02, -2.508e-01, -3.450e-02, -8.432e-02, 1.966e-02, 1.859e-01, -1.031e-01) * s1[y+0][x+0];
	r += M4(-2.356e-01, -3.201e-01, 1.091e-02, 3.372e-02, -1.043e-01, -5.653e-02, 7.937e-02, -1.695e-02, 4.651e-02, -4.703e-02, 8.708e-02, -2.437e-01, 3.416e-02, -1.113e-01, 8.866e-01, -3.498e-02) * s1[y+0][x+1];
	r += M4(5.758e-02, 1.018e-01, -1.471e-02, 2.383e-01, -1.757e-01, 1.043e-01, 4.256e-01, 2.027e-01, 3.714e-02, 3.564e-02, 5.621e-02, -5.689e-02, 4.456e-02, 2.066e-01, -2.145e-02, 1.259e-01) * s1[y+0][x+2];
	r += M4(-4.187e-02, -4.942e-01, 1.215e-01, 2.912e-01, 6.704e-02, 2.542e-02, -6.862e-02, 1.941e-02, 5.352e-02, 1.805e-01, -2.142e-01, -1.670e-01, 1.871e-03, 1.233e-01, -5.025e-02, -4.559e-02) * s1[y+1][x+0];
	r += M4(2.830e-01, -4.105e-02, -1.233e-01, -5.207e-01, -9.980e-02, -1.494e-02, -3.612e-02, -2.060e-01, 6.073e-02, 4.284e-03, 2.742e-01, 1.628e-01, 6.836e-01, -2.574e-01, -1.107e-01, -4.130e-01) * s1[y+1][x+1];
	r += M4(-1.261e-01, 2.467e-02, -7.453e-02, -2.803e-01, 5.074e-01, -3.298e-01, 8.468e-03, 5.782e-01, 3.422e-02, -2.063e-02, -1.722e-01, -1.371e-01, -2.043e-01, 5.529e-02, -3.217e-01, -1.863e-01) * s1[y+1][x+2];
	r += M4(3.694e-02, 5.855e-02, 6.530e-04, 1.934e-01, 7.045e-03, -3.441e-02, -5.143e-03, 3.038e-02, 3.611e-02, -6.311e-02, 1.104e-01, 7.537e-03, 6.823e-02, -3.024e-02, 6.203e-02, 2.806e-01) * s1[y+2][x+0];
	r += M4(5.686e-02, -2.263e-01, -1.495e-01, 1.207e-01, -1.403e-02, -4.487e-02, -7.530e-03, -2.074e-01, -2.647e-02, -8.622e-02, -2.197e-03, 5.032e-02, 3.446e-01, -5.795e-01, -1.162e-01, -3.829e-01) * s1[y+2][x+1];
	r += M4(-7.874e-02, -6.980e-02, -7.965e-02, -2.177e-01, 1.763e-02, 2.128e-01, 7.300e-02, 1.179e-01, 5.804e-03, -3.833e-02, -1.188e-01, -1.716e-01, -3.328e-02, -7.355e-02, 5.962e-02, -1.849e-01) * s1[y+2][x+2];
	r += V4(-5.616e-02, -5.009e-01, -6.832e-02, 2.113e-01);
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
	r += M4(-8.796e-02, -8.490e-02, 2.635e-04, 3.739e-02, 6.271e-02, -1.830e-01, -6.711e-02, -2.214e-01, 3.266e-02, -7.280e-02, 5.703e-04, 3.920e-02, 1.324e-02, -2.888e-01, -1.294e-01, -1.722e-01) * s0[y+0][x+0];
	r += M4(2.046e-01, -4.271e-01, 2.338e-02, 6.919e-02, 7.638e-03, 2.929e-01, 1.354e-01, -5.063e-01, 1.368e-01, 6.005e-02, -1.920e-03, -3.008e-02, 6.637e-01, -3.159e-02, 4.995e-02, 1.172e-01) * s0[y+0][x+1];
	r += M4(2.261e-01, 5.102e-02, 6.586e-02, -2.912e-04, -2.459e-01, -1.744e-01, 4.329e-01, -4.841e-02, -1.616e-01, 1.507e-02, 7.501e-03, 2.506e-02, 1.616e-01, 5.171e-02, -4.040e-01, -1.132e-01) * s0[y+0][x+2];
	r += M4(-5.686e-02, -2.172e-01, -6.202e-02, -7.795e-02, 5.111e-02, -1.220e-01, 3.381e-02, -1.254e-01, 1.392e-01, -2.123e-01, -9.844e-02, -1.287e-01, 8.601e-02, 2.801e-01, 3.190e-02, 2.062e-02) * s0[y+1][x+0];
	r += M4(5.346e-01, -6.984e-01, -2.822e-01, 3.039e-02, 1.008e-01, -3.024e-01, -8.271e-03, -1.743e-01, 8.523e-02, -1.579e-01, -3.178e-03, -3.037e-02, 4.751e-01, 2.288e-01, 1.441e-01, 1.614e-02) * s0[y+1][x+1];
	r += M4(1.219e-01, 1.700e-01, -4.411e-01, -5.293e-02, 1.422e-01, 3.304e-01, -6.427e-01, -8.407e-02, -9.407e-02, -3.502e-02, -1.246e-01, 4.257e-02, -1.033e-01, -4.655e-01, 8.926e-01, 3.168e-02) * s0[y+1][x+2];
	r += M4(8.719e-02, 7.100e-02, 1.155e-01, -3.621e-02, -4.022e-02, -5.133e-02, 6.289e-02, -1.218e-03, -1.189e-01, -4.019e-02, 5.899e-02, -1.066e-01, 9.042e-02, 5.455e-02, 7.008e-02, 1.756e-02) * s0[y+2][x+0];
	r += M4(-1.591e-01, 2.227e-01, -9.814e-02, -3.176e-02, -9.601e-03, 1.576e-01, -2.008e-02, -4.349e-02, -4.513e-01, -2.366e-01, -1.704e-01, 3.428e-01, -7.713e-02, -2.077e-02, -4.818e-02, 7.226e-02) * s0[y+2][x+1];
	r += M4(-4.264e-02, 9.690e-02, -2.984e-02, -1.700e-02, -1.314e-02, -1.033e-02, 5.053e-02, -4.458e-02, 5.850e-02, -5.107e-02, 8.284e-02, -5.008e-02, 3.302e-02, -2.358e-02, 1.561e-01, 1.976e-02) * s0[y+2][x+2];
	r += M4(-9.182e-02, 9.645e-02, 5.561e-02, 7.168e-02, 7.121e-02, -9.513e-02, -3.769e-02, -2.574e-01, 2.459e-02, -9.396e-02, -1.283e-02, 6.767e-02, 1.780e-02, -4.425e-01, -8.730e-02, -1.242e-01) * s1[y+0][x+0];
	r += M4(-4.618e-02, -7.987e-02, 4.417e-02, 1.685e-01, -1.987e-01, 6.513e-01, 1.328e-01, -1.333e-01, 1.229e-02, 2.615e-01, 2.437e-02, 3.033e-02, 2.108e-01, 6.662e-02, -2.417e-03, 1.763e-02) * s1[y+0][x+1];
	r += M4(1.102e-01, -3.772e-02, 5.757e-02, -9.971e-03, -2.387e-01, -3.213e-01, 4.025e-01, -1.409e-01, -1.450e-01, 5.525e-02, 4.491e-02, 4.481e-02, -7.396e-02, -2.918e-01, -2.432e-01, -8.290e-02) * s1[y+0][x+2];
	r += M4(-1.045e-02, -2.968e-01, -4.973e-02, -1.294e-01, 1.218e-01, -3.077e-03, 3.614e-02, -1.343e-01, 3.232e-01, -2.079e-01, -9.551e-02, -3.348e-01, -5.496e-02, -4.050e-02, 7.206e-02, 1.473e-02) * s1[y+1][x+0];
	r += M4(6.102e-01, -3.330e-01, -2.691e-01, 2.031e-01, 1.670e-01, -3.408e-01, -1.800e-02, -9.328e-02, 5.017e-01, 1.234e-01, 5.530e-02, -2.173e-01, -2.403e-02, 2.067e-01, 1.325e-02, 1.780e-02) * s1[y+1][x+1];
	r += M4(-2.554e-01, 1.477e-01, -6.157e-01, 5.265e-02, 9.668e-02, 2.356e-01, -5.476e-01, -1.007e-01, 2.861e-01, 2.021e-01, 4.101e-02, 3.927e-02, -5.605e-01, -5.044e-01, 5.394e-01, 5.220e-02) * s1[y+1][x+2];
	r += M4(9.202e-02, 2.402e-02, 9.595e-02, 2.705e-02, -4.968e-02, -2.368e-02, 2.449e-02, -2.052e-02, 1.772e-01, -1.085e-01, 1.356e-02, -1.545e-02, -9.683e-02, 3.960e-03, 4.658e-02, 1.110e-01) * s1[y+2][x+0];
	r += M4(-9.934e-02, 3.997e-02, -2.797e-02, -2.330e-02, -1.493e-02, 1.231e-01, -8.283e-02, -4.714e-02, 5.686e-01, 3.534e-01, -2.085e-01, -1.111e-01, -3.330e-01, -1.015e-01, 5.867e-02, 8.344e-02) * s1[y+2][x+1];
	r += M4(1.313e-01, 7.395e-02, 1.025e-01, -1.904e-02, -2.194e-02, -8.270e-03, 8.228e-02, -3.561e-02, 2.551e-01, 1.766e-01, 1.848e-02, -2.488e-02, -1.695e-01, -1.096e-01, 9.916e-02, 1.101e-02) * s1[y+2][x+2];
	r += V4(1.962e-02, 3.626e-02, -4.405e-03, 5.272e-01);
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
	r += M4(-2.353e-02, 1.749e-01, -1.233e-01, 1.208e-01, 2.581e-02, 1.126e-01, -1.096e-01, -1.201e-02, -1.790e-01, -2.140e-01, 7.461e-02, -1.845e-01, 5.460e-02, 7.144e-03, 7.251e-02, 2.153e-02) * s0[y+0][x+0];
	r += M4(5.613e-02, -3.529e-02, -2.646e-02, 1.087e-01, 1.370e-01, 1.012e-01, -1.548e-01, -2.487e-02, -1.033e-01, 6.475e-02, -7.926e-02, -4.214e-01, -6.543e-02, -1.562e-01, 7.791e-02, -5.824e-02) * s0[y+0][x+1];
	r += M4(-9.792e-02, 4.679e-02, 3.359e-02, 6.241e-02, 1.212e-01, 1.248e-02, -2.948e-02, -5.018e-02, 1.125e-01, 1.037e-01, 6.528e-02, -3.319e-02, -5.392e-02, -4.827e-02, 2.178e-01, -1.997e-01) * s0[y+0][x+2];
	r += M4(2.969e-03, 2.092e-01, -9.177e-03, -1.919e-02, -3.133e-02, 8.423e-02, -1.099e-01, 7.425e-02, 1.113e-01, -6.037e-02, -2.348e-01, 1.743e-01, -3.019e-02, -4.493e-02, 1.892e-01, -2.941e-02) * s0[y+1][x+0];
	r += M4(-6.656e-01, 5.254e-01, -2.666e-01, -3.787e-01, 3.147e-01, 3.658e-01, 5.527e-01, -1.322e-01, -2.293e-01, -1.401e-01, 2.669e-01, 9.587e-01, -3.662e-01, 7.116e-02, -4.560e-01, 6.750e-02) * s0[y+1][x+1];
	r += M4(2.359e-01, 1.689e-01, -3.201e-02, -6.895e-02, -2.026e-01, 9.055e-02, -1.410e-01, 1.846e-02, -5.056e-03, 3.099e-01, -4.773e-03, -3.001e-02, 4.819e-01, 8.569e-02, -1.250e-01, 2.632e-01) * s0[y+1][x+2];
	r += M4(2.677e-02, 1.642e-02, 1.401e-02, 2.447e-02, 1.071e-02, -5.316e-02, -2.479e-02, 9.737e-02, -1.993e-02, -1.490e-01, -3.750e-02, 5.150e-02, -5.263e-02, -2.900e-01, 5.317e-02, -1.003e-01) * s0[y+2][x+0];
	r += M4(-7.988e-02, 3.065e-01, 1.347e-01, -2.924e-02, 1.968e-01, -4.971e-02, 7.042e-03, 6.963e-02, 1.283e-01, 2.709e-02, 4.407e-02, -8.482e-02, 3.585e-02, 7.841e-02, -7.761e-02, 1.056e-01) * s0[y+2][x+1];
	r += M4(9.068e-02, 1.304e-01, -3.150e-03, -4.586e-01, -1.323e-01, 4.953e-02, 1.041e-01, 5.449e-01, -8.353e-04, 8.861e-02, 4.584e-02, 1.880e-01, 1.009e-02, 3.030e-01, 6.555e-02, -8.367e-03) * s0[y+2][x+2];
	r += M4(-1.189e-01, 9.418e-04, -2.949e-01, 2.882e-02, -4.446e-03, 7.788e-02, -1.723e-01, 5.966e-02, -5.686e-02, -1.802e-01, -3.642e-02, -4.633e-02, -4.149e-02, -8.393e-03, 4.413e-02, 2.312e-01) * s1[y+0][x+0];
	r += M4(-3.161e-02, -8.993e-02, 7.407e-03, -7.494e-02, 1.522e-02, 1.577e-01, -1.374e-01, 1.529e-01, -1.392e-01, 4.874e-02, -9.805e-02, -2.026e-01, -3.936e-01, -1.351e-01, -7.473e-01, 8.725e-02) * s1[y+0][x+1];
	r += M4(1.023e-01, -1.406e-02, -8.021e-03, -1.077e-01, -2.772e-02, -1.147e-02, 4.193e-02, 4.684e-02, -2.277e-02, 7.098e-02, 1.201e-02, 1.224e-01, 1.019e-01, 7.943e-02, 5.482e-02, -1.260e-01) * s1[y+0][x+2];
	r += M4(2.379e-01, 1.672e-01, -1.481e-01, 1.559e-01, 5.769e-02, 3.053e-02, -7.617e-02, 2.591e-02, -7.685e-02, -4.554e-02, 1.635e-01, -1.849e-01, -2.287e-03, -2.764e-01, -6.348e-01, -3.396e-01) * s1[y+1][x+0];
	r += M4(-3.833e-01, 3.330e-01, -1.782e-01, 3.877e-01, 1.555e-01, 4.077e-01, 6.898e-01, -2.300e-01, -2.350e-02, -2.184e-01, 4.414e-01, 2.859e-01, -1.252e+00, -6.311e-01, -1.844e+00, -1.016e+00) * s1[y+1][x+1];
	r += M4(1.823e-01, -1.103e-01, -6.420e-02, 2.549e-01, -3.467e-01, 2.953e-01, -9.831e-02, -9.092e-02, 3.564e-03, 2.906e-01, -3.602e-03, -9.322e-02, 2.077e+00, 9.775e-01, -1.258e+00, -1.183e+00) * s1[y+1][x+2];
	r += M4(1.328e-01, 1.113e-02, 5.074e-02, -9.099e-02, -7.313e-02, -8.065e-02, -7.697e-02, -4.652e-02, -3.533e-02, -1.180e-01, 1.091e-02, -1.960e-01, 1.123e-01, 2.686e-01, 9.335e-02, 8.067e-03) * s1[y+2][x+0];
	r += M4(-1.353e-01, 1.724e-01, 1.100e-01, 1.124e-01, 1.606e-01, -2.035e-02, 7.635e-02, 4.558e-03, 1.164e-02, 1.841e-01, 1.442e-01, -5.238e-01, -3.159e-01, 1.111e+00, -3.257e-01, -1.163e-01) * s1[y+2][x+1];
	r += M4(6.729e-02, 2.333e-01, 1.225e-02, -1.401e-01, -9.180e-02, -3.673e-02, 3.816e-02, 4.716e-01, -1.238e-02, 1.784e-01, 6.703e-02, 3.654e-02, -4.459e-01, -6.702e-01, -6.327e-01, 1.428e+00) * s1[y+2][x+2];
	r += V4(2.453e-02, -9.512e-02, 5.733e-02, -3.454e-02);
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
	r += M4(-3.977e-02, -3.192e-03, -2.606e-02, -5.840e-02, -1.493e-02, -3.670e-02, -3.779e-02, 1.529e-01, 9.453e-03, 6.341e-02, 5.945e-02, 4.410e-02, 4.462e-02, 1.213e-01, 1.145e-01, -1.470e-01) * s0[y+0][x+0];
	r += M4(4.870e-03, -1.540e-02, -6.562e-02, 2.669e-02, -2.464e-02, 1.052e-01, 1.950e-02, 1.259e-02, -5.511e-03, 2.664e-03, 7.297e-02, 1.136e-01, 7.611e-02, -1.209e-01, 2.665e-01, 3.478e-02) * s0[y+0][x+1];
	r += M4(1.783e-02, -1.005e-01, 4.832e-02, 9.498e-03, -6.567e-03, -2.078e-02, -1.674e-02, -3.964e-02, 3.315e-02, 2.493e-02, -1.800e-02, 6.487e-02, 2.121e-02, -3.581e-02, 1.315e-01, 2.393e-02) * s0[y+0][x+2];
	r += M4(-6.867e-02, 8.722e-02, -6.506e-02, 1.685e-01, -2.722e-02, -5.970e-02, 1.517e-01, 1.386e-01, -5.466e-02, 1.042e-01, -9.390e-02, -1.215e-01, 3.802e-02, 3.578e-01, -9.241e-02, -6.777e-01) * s0[y+1][x+0];
	r += M4(-3.111e-02, -4.948e-01, 9.327e-02, 2.272e-02, 5.358e-01, -6.324e-02, -2.410e-01, -3.623e-01, 2.312e-01, -1.784e-02, 1.644e-01, 2.571e-01, 4.237e-02, -3.640e-01, 2.031e-01, -3.076e-01) * s0[y+1][x+1];
	r += M4(4.947e-02, -1.293e-01, 1.407e-02, 5.264e-02, -6.614e-02, 9.637e-02, 5.915e-03, 1.811e-01, 3.115e-01, 1.024e-01, 5.847e-02, -6.854e-02, 5.071e-02, 6.961e-02, 8.822e-02, -5.850e-02) * s0[y+1][x+2];
	r += M4(-2.409e-01, 4.027e-01, 3.544e-02, 6.986e-03, -8.921e-02, 1.636e-01, -1.411e-01, 1.470e-01, 7.594e-02, -1.026e-02, 9.348e-02, 6.373e-03, -2.319e-02, 7.200e-02, -6.435e-02, -6.089e-03) * s0[y+2][x+0];
	r += M4(-4.493e-01, -2.844e-01, 1.015e-01, -6.893e-02, 7.735e-02, -1.253e-01, 2.408e-01, -6.845e-02, 4.462e-01, -2.295e-01, 1.126e-02, 1.976e-01, 9.060e-02, -1.189e-01, 1.075e-01, -1.021e-01) * s0[y+2][x+1];
	r += M4(-1.011e-01, 1.400e-02, 3.748e-02, -1.139e-02, -1.650e-01, 8.020e-02, -1.927e-02, 6.106e-03, 5.215e-01, 2.708e-01, -5.710e-01, -3.305e-01, 1.064e-03, 1.239e-01, -4.126e-02, -2.189e-02) * s0[y+2][x+2];
	r += M4(-8.519e-03, -7.978e-02, 3.650e-02, -1.445e-02, -4.989e-02, 2.587e-01, 3.550e-02, 6.758e-02, 1.678e-02, -1.666e-02, -2.466e-02, 3.692e-02, 4.128e-02, -2.981e-04, 2.974e-03, -8.083e-02) * s1[y+0][x+0];
	r += M4(-1.126e-01, 5.064e-02, -1.246e-01, 8.818e-02, 2.965e-01, -8.377e-03, -3.738e-02, -1.333e-01, -1.269e-02, 5.153e-02, -6.605e-03, 2.894e-02, -7.492e-02, -1.871e-01, 1.406e-01, 1.439e-03) * s1[y+0][x+1];
	r += M4(-1.099e-02, 6.369e-03, -6.485e-03, -1.080e-01, -2.317e-02, 3.802e-02, -1.292e-01, 1.317e-01, 4.006e-02, 2.250e-02, -1.120e-01, 4.142e-02, 2.358e-03, 5.819e-02, -5.745e-02, -1.471e-02) * s1[y+0][x+2];
	r += M4(-6.223e-02, -9.272e-03, -8.425e-03, 3.718e-01, 2.056e-01, -4.380e-01, 1.627e-01, -1.204e-01, 5.772e-02, 9.929e-02, -1.784e-02, -2.715e-02, -1.996e-02, 2.392e-01, -1.134e-01, -2.516e-01) * s1[y+1][x+0];
	r += M4(-1.277e-01, -1.038e-01, 4.786e-02, 3.372e-01, 3.689e-01, -6.675e-02, 2.602e-01, -6.309e-02, 3.715e-01, -6.561e-02, 1.770e-01, -1.411e-01, -7.188e-03, -5.958e-01, 6.159e-01, 7.798e-03) * s1[y+1][x+1];
	r += M4(1.050e-01, 1.663e-01, -1.470e-01, -3.780e-02, -2.300e-01, -1.152e-01, 3.648e-01, 1.390e-01, 2.132e-01, -9.482e-02, -1.952e-03, 6.035e-02, 6.685e-02, 6.107e-02, 3.152e-02, 5.713e-02) * s1[y+1][x+2];
	r += M4(1.472e-01, 4.310e-03, 4.440e-01, 2.627e-01, 2.728e-02, -1.414e-02, 2.763e-02, -1.578e-01, -9.313e-03, 7.734e-02, -6.764e-02, 3.495e-02, -3.085e-02, 1.364e-01, -2.299e-01, -3.051e-01) * s1[y+2][x+0];
	r += M4(-2.260e-01, 1.114e-01, 2.230e-01, 3.199e-01, -3.663e-01, 3.585e-01, -3.771e-01, -5.456e-01, 5.683e-01, -8.786e-01, 9.155e-02, -2.266e-01, 1.353e-01, -2.549e-01, -1.626e-01, -2.143e-01) * s1[y+2][x+1];
	r += M4(-1.315e-01, 2.553e-01, -4.656e-02, -1.097e-02, 2.440e-02, -1.391e-01, 1.475e-01, 3.451e-02, -4.408e-02, -4.532e-03, -1.283e-01, -1.441e-01, -9.506e-02, 4.159e-02, -4.599e-02, -4.901e-02) * s1[y+2][x+2];
	r += V4(1.702e-01, 2.083e-02, -7.154e-02, -1.071e-03);
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv5_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(3.306e-01, -5.998e-02, 3.277e-02, 1.548e-02, -2.660e-03, 3.071e-02, -2.835e-02, -1.066e-01, -1.086e-01, 1.508e-01, -1.636e-03, -7.002e-02, 1.132e-01, -9.781e-02, 4.569e-02, 1.548e-02) * s0[y+0][x+0];
	r += M4(5.490e-01, 1.031e-01, -1.251e-01, 1.494e-03, -1.499e-01, -2.509e-02, -9.921e-02, -7.234e-02, -5.513e-02, 1.765e-01, -3.950e-02, 1.846e-02, 3.149e-01, 3.652e-01, -1.108e-01, -2.752e-02) * s0[y+0][x+1];
	r += M4(1.517e-01, -1.451e-01, -3.864e-02, -2.440e-02, -8.988e-02, -9.835e-02, -4.494e-02, 2.814e-03, -2.043e-02, -6.622e-02, -9.944e-02, -5.776e-02, 7.304e-02, 5.968e-02, -1.482e-01, -2.796e-02) * s0[y+0][x+2];
	r += M4(-2.482e-01, 1.787e-01, -3.726e-01, -3.710e-01, -5.975e-02, -7.355e-02, -1.740e-01, -1.411e-01, -3.017e-01, 5.032e-02, 5.994e-02, 1.129e+00, -2.205e-02, 1.473e-01, -3.499e-02, -4.043e-02) * s0[y+1][x+0];
	r += M4(-4.756e-01, 3.469e-01, 2.895e-01, -2.277e-01, 1.161e-01, 6.502e-01, 3.105e-01, 1.884e-01, 2.881e-02, 3.434e-01, 2.405e-02, -9.952e-02, -6.470e-02, 1.263e-01, -9.870e-02, -2.012e-01) * s0[y+1][x+1];
	r += M4(3.965e-02, -1.524e-01, -6.152e-02, -5.689e-03, -1.541e-02, -1.604e-01, -6.090e-02, 5.399e-02, -2.468e-01, -1.218e-01, -1.147e-01, 2.043e-02, -3.022e-02, -7.270e-02, 5.357e-02, -3.266e-02) * s0[y+1][x+2];
	r += M4(4.092e-02, -1.244e-01, 5.605e-02, -5.957e-02, -3.430e-02, 2.294e-02, 3.358e-02, -2.853e-02, -6.479e-02, -8.010e-02, -4.484e-02, 4.707e-04, 2.152e-02, -3.298e-03, 1.821e-01, 1.722e-01) * s0[y+2][x+0];
	r += M4(4.240e-02, 1.649e-01, -1.400e-01, -8.511e-03, -3.292e-02, 4.460e-02, -1.127e-01, -7.382e-02, -2.455e-01, 2.854e-02, -3.453e-01, -3.333e-03, -4.749e-02, 3.800e-01, 7.042e-02, -6.008e-02) * s0[y+2][x+1];
	r += M4(-7.405e-02, -1.142e-01, -8.741e-03, -2.471e-02, 2.537e-02, -1.709e-01, 2.844e-02, -4.119e-02, -7.203e-02, 7.203e-02, -7.033e-02, -8.991e-04, -4.598e-02, -7.247e-02, 5.533e-02, 2.498e-02) * s0[y+2][x+2];
	r += M4(1.802e-01, -1.763e-01, 1.335e-01, 2.521e-02, -1.157e-01, 3.215e-01, -3.291e-01, -1.044e-01, -7.016e-02, 1.750e-03, 5.520e-03, -5.606e-02, 1.213e-01, -2.237e-02, 1.431e-01, -6.180e-02) * s1[y+0][x+0];
	r += M4(4.654e-01, 2.031e-01, -1.629e-01, -7.642e-02, -1.508e-01, -2.226e-01, -5.197e-02, -2.723e-02, -3.178e-01, 1.593e-01, 4.748e-02, 5.913e-02, 2.008e-01, 3.016e-01, -2.569e-02, -1.284e-01) * s1[y+0][x+1];
	r += M4(-5.747e-03, -1.245e-01, -2.054e-02, -3.433e-02, -4.161e-03, -3.376e-03, -3.589e-02, -9.133e-03, -1.862e-02, -1.181e-01, -8.260e-02, -5.372e-02, 3.039e-01, -9.345e-02, -7.747e-02, 3.174e-02) * s1[y+0][x+2];
	r += M4(-2.898e-01, 7.236e-02, -4.893e-01, -5.595e-01, -3.994e-01, 4.177e-01, -4.978e-01, -2.706e-01, 1.477e-01, 6.614e-02, 1.770e-02, 1.490e-01, -1.976e-01, 1.484e-02, -1.235e-02, 1.754e-02) * s1[y+1][x+0];
	r += M4(-5.587e-01, 3.754e-01, 1.938e-01, -4.437e-01, 3.633e-01, 1.653e-01, 1.756e-01, 3.198e-01, 2.745e-01, 3.964e-01, 1.340e-03, -1.954e-02, 1.696e-01, -1.223e-01, -2.293e-01, 1.702e-02) * s1[y+1][x+1];
	r += M4(-4.714e-02, -9.232e-02, -7.380e-02, -5.907e-04, -3.422e-01, 3.360e-02, 5.883e-02, 6.427e-02, -1.558e-01, -6.369e-02, -1.958e-01, -9.588e-04, -1.788e-01, 6.759e-03, 2.371e-01, -7.365e-02) * s1[y+1][x+2];
	r += M4(2.935e-02, -2.106e-01, 1.480e-01, -2.946e-01, -1.232e-01, 2.566e-01, -1.227e-01, 3.094e-02, -7.640e-02, 1.009e-01, -1.438e-01, -2.269e-01, 1.744e-02, -1.889e-01, 1.676e-01, 9.544e-02) * s1[y+2][x+0];
	r += M4(-1.843e-03, 1.829e-01, -8.405e-02, -1.148e-01, -1.480e-01, 1.498e-01, -1.935e-01, -8.684e-02, -1.746e-01, 7.365e-02, -2.105e-01, -1.401e-01, -1.290e-01, 4.833e-01, -1.394e-01, -5.364e-02) * s1[y+2][x+1];
	r += M4(-1.190e-01, -6.832e-02, 1.877e-02, -2.902e-02, 1.086e-01, 2.566e-02, -3.511e-02, 2.922e-02, -1.214e-01, -3.146e-02, -2.866e-02, -1.908e-02, -2.339e-01, 1.631e-01, 9.071e-02, -1.385e-02) * s1[y+2][x+2];
	r += V4(-5.098e-02, 2.536e-02, -3.185e-02, 2.148e-01);
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv6_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-3.638e-02, -5.117e-02, 7.025e-02, 5.011e-02, 1.936e-03, 5.237e-02, -7.848e-03, 2.792e-03, 2.392e-02, -6.637e-03, -1.983e-04, 6.932e-03, -3.378e-02, -9.570e-02, 5.809e-02, 6.868e-03) * s0[y+0][x+0];
	r += M4(4.407e-02, -6.405e-02, -2.313e-02, 1.024e-01, 1.324e-01, 5.979e-02, -6.790e-02, 4.405e-02, 7.341e-03, -3.198e-01, 2.289e-01, 4.992e-02, 3.767e-02, 9.509e-02, -4.063e-02, 3.972e-02) * s0[y+0][x+1];
	r += M4(-7.291e-02, 3.695e-02, 2.453e-02, 3.015e-02, 5.705e-02, 4.647e-02, -4.567e-02, 1.198e-01, -3.578e-02, 7.251e-02, -2.112e-02, 1.784e-01, -4.907e-02, -1.695e-02, 4.821e-02, -1.568e-01) * s0[y+0][x+2];
	r += M4(-1.275e-01, -1.694e-01, 1.372e-01, 7.008e-02, -8.863e-02, -2.770e-02, 1.364e-01, 6.049e-02, 1.242e-01, 1.624e-01, -5.673e-02, -2.203e-01, 5.139e-02, -5.964e-02, -6.700e-02, 3.399e-02) * s0[y+1][x+0];
	r += M4(6.623e-02, 6.240e-02, -2.673e-01, -2.899e-01, -2.826e-01, 6.638e-02, -2.185e-01, -2.816e-01, 6.714e-02, -5.137e-01, -1.339e-01, -2.294e-01, 1.968e-01, -4.682e-02, -3.723e-01, -6.044e-02) * s0[y+1][x+1];
	r += M4(-1.081e-01, 4.164e-02, 4.624e-02, -6.889e-02, -5.847e-02, 8.669e-02, -9.009e-02, -4.678e-01, -6.611e-01, -1.244e-02, 2.794e-01, -2.977e-01, 1.942e-01, -6.892e-02, -4.041e-02, 2.064e-01) * s0[y+1][x+2];
	r += M4(2.868e-02, 9.576e-02, -4.999e-02, 6.942e-03, 2.502e-02, 9.818e-02, -1.478e-02, 4.341e-02, 4.248e-02, -9.808e-02, 1.919e-01, -2.199e-02, -5.729e-02, -6.717e-02, 3.490e-02, -2.260e-02) * s0[y+2][x+0];
	r += M4(3.262e-01, 9.441e-02, -2.255e-01, -1.067e-01, 1.840e-01, 2.549e-02, -1.069e-01, -3.421e-02, 1.048e-02, -1.372e-01, 3.564e-01, -7.713e-03, -1.801e-01, -7.303e-03, 8.473e-02, 1.023e-01) * s0[y+2][x+1];
	r += M4(8.352e-02, 3.079e-02, -6.740e-02, 2.152e-02, 1.191e-01, 1.482e-02, -7.036e-02, 3.137e-02, -1.559e-01, -2.302e-02, -1.826e-02, -1.131e-02, -1.323e-01, -4.788e-02, 1.118e-01, -1.004e-01) * s0[y+2][x+2];
	r += M4(-1.057e-01, -9.499e-02, 1.441e-01, -5.285e-02, 1.304e-01, 8.663e-02, -1.060e-01, -2.361e-02, -9.002e-02, -6.331e-03, 1.091e-01, 2.843e-02, -4.277e-02, 1.187e-01, -2.046e-01, 3.667e-02) * s1[y+0][x+0];
	r += M4(-1.013e-01, -3.186e-02, 7.352e-02, -2.226e-02, 6.330e-02, -2.517e-02, -8.210e-02, 6.958e-02, -5.388e-02, -4.671e-02, 1.544e-01, 8.953e-02, 3.387e-01, 1.292e-01, -4.775e-01, 1.430e-01) * s1[y+0][x+1];
	r += M4(2.060e-02, 3.114e-02, -2.249e-02, -4.433e-02, 1.457e-02, 2.914e-02, -1.384e-02, 1.754e-01, 1.880e-01, 1.228e-01, -1.343e-01, 5.218e-02, 7.358e-02, 6.094e-02, -2.234e-01, -2.263e-01) * s1[y+0][x+2];
	r += M4(-7.541e-02, -3.218e-01, 2.132e-01, 1.177e-01, -6.540e-02, -1.592e-01, 1.334e-01, -3.785e-02, 4.068e-02, -8.169e-03, 9.936e-02, 3.051e-02, -3.576e-02, -2.613e-01, -4.350e-01, -5.308e-02) * s1[y+1][x+0];
	r += M4(5.140e-01, 1.113e-01, -3.364e-01, 5.732e-02, -1.012e+00, 3.080e-02, -1.112e-01, -4.258e-02, -8.947e-02, -3.020e-01, -5.209e-02, -2.076e-01, 1.199e-01, -1.316e+00, -6.838e-01, -7.406e-02) * s1[y+1][x+1];
	r += M4(-1.321e-01, 4.359e-02, 1.291e-02, -1.298e-01, -1.323e-01, -5.402e-02, 1.935e-02, -3.800e-01, -1.697e-01, 1.947e-01, 6.858e-03, -2.612e-01, -4.442e-02, -2.045e-01, -2.538e-01, -2.135e-01) * s1[y+1][x+2];
	r += M4(9.383e-02, 2.773e-01, -3.252e-01, -1.525e-01, 5.159e-02, 2.933e-02, -2.066e-02, 1.275e-02, 7.202e-02, 1.644e-02, 7.195e-02, 2.104e-02, -9.921e-04, -1.136e-01, -1.634e-01, -1.042e-01) * s1[y+2][x+0];
	r += M4(3.651e-01, 6.624e-02, -2.328e-01, -4.364e-01, 7.381e-02, -1.643e-02, -9.154e-02, -5.065e-02, 9.731e-02, -9.442e-02, 2.546e-01, 1.187e-01, -1.124e-01, 1.401e-01, -2.311e-01, 4.115e-02) * s1[y+2][x+1];
	r += M4(2.075e-01, 3.494e-02, -1.151e-01, -1.549e-01, 5.142e-02, 3.977e-02, -3.286e-02, 4.089e-02, -6.151e-02, -2.410e-02, 3.332e-02, 1.663e-01, -4.012e-03, -8.513e-02, -2.134e-02, -2.771e-01) * s1[y+2][x+2];
	r += V4(5.966e-03, 2.063e-02, 6.348e-02, -1.413e-02);
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv7_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-2.136e-02, 2.227e-02, 3.840e-02, -5.447e-02, 3.960e-03, 6.378e-03, -1.140e-02, -2.181e-02, -3.822e-02, 4.317e-02, 2.150e-02, -4.934e-02, 1.634e-01, -1.354e-01, -4.564e-04, 1.282e-01) * s0[y+0][x+0];
	r += M4(1.393e-01, 1.063e-01, -7.545e-03, 7.064e-04, 1.352e-02, 1.390e-02, 1.648e-02, 9.337e-04, 1.659e-01, -3.330e-02, -3.088e-02, 1.274e-01, 2.011e-01, 8.935e-03, -1.509e-01, 2.360e-01) * s0[y+0][x+1];
	r += M4(3.353e-02, -4.065e-02, 4.484e-04, 4.936e-02, -6.812e-03, 9.437e-03, -4.923e-02, -1.913e-02, 4.037e-02, -2.744e-02, -7.908e-03, 6.166e-02, 4.628e-02, 3.336e-02, 3.233e-02, 4.401e-02) * s0[y+0][x+2];
	r += M4(3.736e-03, -9.646e-02, 3.330e-01, -5.858e-02, 2.682e-02, -2.609e-04, -1.950e-02, 2.566e-02, -7.915e-02, -1.266e-01, 4.370e-01, 1.250e-01, 5.029e-01, 4.471e-01, -1.145e+00, 3.114e-01) * s0[y+1][x+0];
	r += M4(-1.661e-01, -2.251e-02, -1.997e-01, 2.543e-01, 4.407e-02, 1.194e-01, -2.436e-01, -2.495e-01, -7.407e-01, -3.544e-01, -3.370e-02, -5.268e-01, 7.299e-02, -8.324e-02, -1.455e-01, 5.061e-01) * s0[y+1][x+1];
	r += M4(-9.162e-03, 3.974e-02, -3.870e-02, -8.264e-02, 1.217e-02, 3.907e-02, 6.763e-02, -4.663e-02, -5.395e-02, 3.161e-02, -1.284e-01, -1.274e-01, 5.007e-02, 5.396e-02, -8.225e-02, 8.756e-02) * s0[y+1][x+2];
	r += M4(9.293e-03, -7.998e-02, 1.490e-01, 2.824e-02, 4.653e-02, -5.724e-02, -3.309e-02, -4.130e-02, 2.161e-02, 9.859e-02, -1.944e-02, 2.848e-02, -1.900e-01, 1.259e-01, -1.010e-01, -1.948e-01) * s0[y+2][x+0];
	r += M4(-2.888e-02, 1.136e-01, -9.790e-02, -1.787e-02, -5.076e-02, 2.359e-01, -1.274e-01, 4.251e-02, 1.450e-01, -3.412e-01, 8.552e-02, 3.562e-02, 7.661e-04, -1.027e-01, -3.777e-02, -7.071e-02) * s0[y+2][x+1];
	r += M4(1.908e-03, -5.311e-02, 4.941e-03, -2.530e-02, 1.730e-02, -6.684e-02, 1.746e-02, 1.921e-02, -2.006e-02, 6.576e-02, 2.232e-02, -9.563e-02, -2.015e-02, 8.442e-02, -6.337e-02, -7.520e-02) * s0[y+2][x+2];
	r += M4(-1.691e-01, 3.725e-02, 9.923e-02, -7.833e-02, -3.575e-02, 1.191e-02, 2.675e-03, -7.497e-02, -5.730e-02, 4.090e-02, 3.000e-02, 7.094e-04, 1.777e-02, -1.170e-01, 5.827e-02, 2.618e-02) * s1[y+0][x+0];
	r += M4(1.824e-01, 1.199e-01, -5.779e-02, -2.626e-02, -8.774e-02, 1.628e-02, 7.086e-02, -7.255e-02, 8.445e-02, 2.371e-02, 3.258e-02, -1.422e-02, 5.377e-02, 2.566e-02, -4.047e-02, 6.754e-02) * s1[y+0][x+1];
	r += M4(2.363e-02, -1.750e-02, 1.906e-02, 3.624e-02, -6.389e-02, -8.911e-02, -1.638e-02, -3.130e-02, -7.495e-03, -3.169e-02, -4.954e-04, 9.925e-03, 1.800e-02, 6.035e-02, 8.018e-03, -3.858e-02) * s1[y+0][x+2];
	r += M4(2.256e-01, -1.698e-01, 3.687e-01, -3.232e-01, 6.181e-02, -7.116e-02, -3.946e-02, -1.008e-01, -3.197e-03, -3.104e-02, 1.836e-01, 8.335e-02, 4.299e-02, 4.794e-02, -1.420e-01, -2.085e-03) * s1[y+1][x+0];
	r += M4(-2.319e-01, -4.235e-01, -1.372e-01, 6.794e-01, 2.955e-01, 2.240e-01, -5.293e-01, -8.229e-01, -3.788e-01, -1.274e-01, -7.021e-02, -1.796e-01, 1.017e-01, 6.011e-02, 2.125e-02, -2.314e-02) * s1[y+1][x+1];
	r += M4(-2.550e-02, -2.821e-02, -4.038e-02, 1.333e-02, 4.493e-02, -3.255e-02, 1.511e-01, -3.135e-02, -6.258e-02, -1.192e-01, 1.090e-02, -1.904e-02, 3.448e-02, 6.952e-02, 2.520e-03, 1.163e-02) * s1[y+1][x+2];
	r += M4(1.909e-01, -4.402e-01, 2.788e-01, 1.388e-01, 1.343e-01, -3.417e-01, 8.625e-02, -9.595e-02, 1.847e-02, 8.657e-02, -1.070e-01, -2.301e-02, -5.049e-02, -2.912e-02, 1.081e-01, -5.923e-02) * s1[y+2][x+0];
	r += M4(1.167e-01, -1.218e-01, -2.936e-02, -1.179e-01, -6.510e-02, 5.261e-01, 2.964e-02, 6.140e-02, 9.223e-02, -7.084e-02, -9.970e-02, 3.233e-02, -9.035e-03, -6.953e-03, 4.581e-02, 4.225e-02) * s1[y+2][x+1];
	r += M4(9.367e-03, -3.371e-02, 1.710e-02, -3.781e-02, 2.526e-02, -1.332e-01, 3.872e-02, 1.046e-01, 1.894e-02, -5.438e-02, 2.466e-02, -6.963e-02, -1.346e-02, 6.036e-02, -2.415e-02, 2.331e-04) * s1[y+2][x+2];
	r += V4(-8.779e-03, 1.746e-02, -3.646e-03, 6.848e-03);
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv8_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-3.789e-03, 2.006e-03, -2.107e-02, -8.392e-03, -3.872e-02, 1.411e-02, -2.590e-02, 4.652e-03, -5.013e-02, 1.047e-02, -7.120e-03, 1.922e-02, 2.657e-02, 1.376e-02, 6.068e-03, 1.384e-02) * s0[y+0][x+0];
	r += M4(-1.141e-01, -7.775e-02, 3.309e-02, -7.454e-03, 1.104e-01, -6.418e-03, -1.585e-03, -1.162e-02, -7.885e-02, -9.448e-02, 8.568e-02, -1.224e-02, 8.723e-02, 5.777e-02, -2.109e-02, -1.935e-02) * s0[y+0][x+1];
	r += M4(1.139e-02, -4.583e-02, 7.118e-03, 3.105e-02, -2.272e-02, 5.280e-02, 2.371e-02, 1.528e-02, 8.184e-02, -1.193e-01, 4.925e-02, 5.385e-02, -2.048e-02, 3.929e-02, -2.801e-04, -3.412e-03) * s0[y+0][x+2];
	r += M4(-1.461e-01, 2.850e-02, -9.989e-02, -2.832e-02, -1.715e-02, -2.743e-02, -8.266e-02, -3.358e-02, 1.768e-02, -2.447e-02, -5.089e-02, -4.222e-02, -9.839e-02, 1.414e-02, 3.894e-02, 3.725e-02) * s0[y+1][x+0];
	r += M4(-2.140e-01, -3.725e-01, 3.575e-02, -6.599e-02, -1.526e-01, -1.083e-01, -1.072e-01, -2.047e-01, -1.638e-01, 4.433e-02, -4.311e-01, -1.231e-01, -2.628e-01, -3.369e-01, -1.516e-02, -1.246e-02) * s0[y+1][x+1];
	r += M4(2.220e-01, 2.183e-01, 8.060e-02, 9.209e-02, -9.416e-04, -2.738e-02, -7.551e-02, -2.232e-02, 1.752e-01, -1.408e-01, 1.868e-01, -3.214e-01, -4.992e-05, -2.667e-02, -2.750e-02, 7.846e-03) * s0[y+1][x+2];
	r += M4(-2.533e-02, -2.033e-02, 1.364e-02, -2.651e-02, -3.572e-03, 2.404e-03, 1.547e-02, -5.778e-03, 6.929e-04, 8.116e-03, 2.425e-02, 8.400e-03, 2.640e-02, 1.947e-02, -3.747e-02, 2.847e-02) * s0[y+2][x+0];
	r += M4(2.087e-01, 1.779e-01, -2.569e-01, -4.080e-02, 3.888e-02, 2.685e-02, 2.782e-02, 5.352e-02, 5.877e-02, 5.087e-03, 1.172e-01, 4.567e-02, -6.075e-03, -4.926e-03, -1.023e-01, -2.002e-01) * s0[y+2][x+1];
	r += M4(2.912e-02, 8.212e-02, 8.232e-02, -7.337e-02, 1.981e-02, 2.972e-02, 3.764e-02, 4.333e-02, -1.301e-02, 2.096e-02, 1.304e-02, 1.716e-02, -2.728e-02, -8.475e-03, -3.378e-03, 2.595e-02) * s0[y+2][x+2];
	r += M4(-5.550e-02, 1.973e-03, -2.218e-02, -6.521e-03, -7.468e-02, 6.122e-02, -4.767e-02, 2.466e-02, -6.196e-02, 8.515e-03, -6.368e-03, 1.082e-02, 9.204e-02, -2.707e-04, -2.263e-02, -3.370e-02) * s1[y+0][x+0];
	r += M4(-2.052e-01, -1.343e-01, 7.188e-02, 7.739e-02, 3.718e-01, -3.376e-01, 4.773e-02, -1.289e-01, -6.571e-02, -1.421e-01, 5.423e-02, 1.253e-02, 5.931e-02, 6.817e-02, 3.004e-03, -8.578e-03) * s1[y+0][x+1];
	r += M4(5.124e-02, -5.841e-02, -6.028e-03, 2.875e-03, -1.080e-01, 1.646e-01, -2.807e-03, -1.799e-02, 2.403e-03, 3.055e-02, 2.752e-02, 6.011e-02, -1.408e-02, 3.120e-02, -1.173e-03, -1.661e-02) * s1[y+0][x+2];
	r += M4(-7.595e-02, 1.107e-03, -1.564e-01, -1.796e-02, -3.397e-02, 1.344e-02, -1.142e-01, 2.216e-02, 1.831e-02, -3.313e-02, -4.965e-02, -2.376e-02, -1.517e-01, 2.733e-02, -3.213e-02, 4.749e-02) * s1[y+1][x+0];
	r += M4(-7.927e-02, -1.997e-01, -8.987e-02, -2.786e-01, -1.333e-01, -1.821e-01, 1.756e-01, -4.580e-01, -1.013e-01, -1.057e-02, -3.701e-01, -2.829e-01, -6.497e-02, -2.354e-01, -9.681e-02, -2.280e-01) * s1[y+1][x+1];
	r += M4(5.554e-02, 1.085e-01, 1.587e-01, 2.142e-01, -8.595e-03, -4.270e-02, -1.837e-01, 1.065e-01, 3.528e-02, 1.225e-02, 1.681e-02, -7.042e-02, -2.700e-03, 1.670e-03, -4.513e-02, -2.414e-02) * s1[y+1][x+2];
	r += M4(-1.219e-02, -2.033e-02, 1.918e-02, -2.751e-02, -2.068e-02, -5.240e-03, 1.519e-03, -2.093e-03, 1.947e-02, 1.527e-02, 1.649e-02, -7.254e-03, 7.637e-04, 1.568e-02, -2.338e-02, 2.970e-02) * s1[y+2][x+0];
	r += M4(6.078e-02, 4.975e-02, -4.097e-02, 3.161e-02, 5.331e-02, 2.300e-02, -4.768e-04, 3.661e-02, 1.793e-02, 2.108e-02, 1.096e-01, 9.497e-02, -5.298e-02, -7.251e-02, -4.895e-02, -9.643e-02) * s1[y+2][x+1];
	r += M4(2.540e-02, 4.608e-02, 4.606e-02, 4.472e-03, 7.700e-03, 3.702e-02, 5.596e-02, 3.186e-02, -4.536e-03, 1.442e-03, -1.778e-02, 3.451e-02, -5.494e-03, -8.954e-03, -2.385e-03, 1.359e-02) * s1[y+2][x+2];
	r += V4(-3.238e-04, -2.930e-04, 2.747e-03, 2.677e-03);
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

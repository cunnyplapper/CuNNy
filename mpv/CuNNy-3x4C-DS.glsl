// CuNNy 3x4C DS
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


//!DESC CuNNy-3x4C-DS-in
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
	r += V4(5.293e-01, -3.245e-03, 2.267e-01, 9.571e-02) * s0[y+0][x+0];
	r += V4(-2.113e-01, -4.219e-05, 6.607e-01, 4.209e-01) * s0[y+0][x+1];
	r += V4(-1.219e-02, -6.050e-03, -6.692e-02, -4.924e-02) * s0[y+0][x+2];
	r += V4(-1.513e-01, -3.449e-02, -5.032e-02, -5.835e-01) * s0[y+1][x+0];
	r += V4(-1.995e-01, 5.773e-01, -3.341e-02, 6.490e-02) * s0[y+1][x+1];
	r += V4(5.156e-02, -1.592e-02, 1.147e-03, 1.631e-02) * s0[y+1][x+2];
	r += V4(-3.022e-02, 2.495e-02, 3.408e-03, 4.847e-02) * s0[y+2][x+0];
	r += V4(6.362e-02, -6.114e-02, -6.931e-04, -3.582e-02) * s0[y+2][x+1];
	r += V4(-3.330e-02, 8.721e-03, 5.033e-03, 2.240e-02) * s0[y+2][x+2];
	r += V4(-8.974e-03, -4.733e-01, -1.426e-02, -4.259e-03);
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

//!DESC CuNNy-3x4C-DS-conv1
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
	r += M4(1.263e-01, 1.113e-01, 3.369e-03, -6.615e-02, 1.205e+00, 4.851e-01, 2.513e-01, -2.104e-01, -8.904e-03, -1.110e-01, 1.027e-01, -7.421e-03, -3.138e-01, -1.080e-01, -2.511e-01, -5.932e-02) * s0[y+0][x+0];
	r += M4(4.073e-01, 3.852e-01, 9.217e-02, -5.952e-02, 1.006e+00, 6.289e-01, 1.005e+00, 8.211e-01, -4.343e-02, 3.881e-03, -7.051e-02, 6.667e-02, -2.897e-02, 9.435e-03, 7.229e-03, -2.258e-01) * s0[y+0][x+1];
	r += M4(-1.921e-01, -5.750e-02, 4.971e-02, 4.870e-02, 1.074e+00, -3.017e-01, 3.432e-01, 2.243e-01, 1.839e-03, 2.768e-02, 2.886e-02, -9.933e-02, -2.338e-01, 2.117e-01, -1.833e-01, 2.742e-01) * s0[y+0][x+2];
	r += M4(-3.098e-01, -2.751e-02, -2.023e-01, -2.000e-01, 1.407e+00, 5.597e-01, -3.884e-01, 5.071e-01, -1.269e-01, 1.881e-01, -4.682e-02, 5.647e-02, 2.134e-01, 5.436e-02, 1.572e-02, 1.292e-01) * s0[y+1][x+0];
	r += M4(-3.181e-02, -5.799e-01, 1.299e-01, -1.199e+00, -7.227e-01, -1.751e-01, -2.220e+00, 1.552e+00, 4.170e-01, -7.669e-02, 2.154e-01, 2.056e-01, 1.978e-01, -9.201e-02, -8.475e-02, -4.347e-01) * s0[y+1][x+1];
	r += M4(7.555e-02, -3.592e-01, 6.690e-02, 2.743e-01, 3.126e-01, -3.250e-01, -2.220e-01, 3.967e-01, -4.029e-03, 7.615e-02, -1.044e-01, 5.757e-02, 6.317e-01, -7.093e-01, 4.684e-01, -1.847e-01) * s0[y+1][x+2];
	r += M4(-1.107e-01, 1.062e-01, 2.351e-01, 1.283e-01, 1.098e+00, 3.051e-01, -1.514e-01, -6.591e-02, 3.184e-02, -3.653e-02, -7.479e-02, -4.485e-02, -4.530e-02, 4.714e-02, 8.860e-02, 5.113e-03) * s0[y+2][x+0];
	r += M4(2.820e-01, -1.336e-01, 3.468e-01, 8.130e-02, 2.366e-01, -5.922e-02, -6.328e-01, -6.704e-03, -7.674e-02, 6.084e-02, -6.555e-02, 4.402e-04, 6.376e-02, 9.302e-02, -2.839e-01, 3.505e-01) * s0[y+2][x+1];
	r += M4(-1.558e-01, -7.893e-01, 5.356e-01, 8.185e-01, 1.278e-01, -4.339e-01, 5.256e-01, -1.895e-01, 1.773e-02, -4.514e-02, 5.032e-02, 5.758e-02, -5.923e-02, -3.663e-01, 2.765e-03, 1.941e-01) * s0[y+2][x+2];
	r += M4(1.421e-01, 3.815e-02, 1.868e-02, 5.716e-02, 3.599e-02, 4.969e-02, -1.899e-01, -8.555e-02, 6.726e-01, -2.125e-01, 1.463e-01, -2.642e-02, -3.879e-01, -1.582e-02, -1.333e-01, 1.456e-01) * s1[y+0][x+0];
	r += M4(2.128e-01, 7.294e-02, 1.428e-01, 2.505e-03, 4.687e-02, 9.309e-02, 1.145e-01, -1.297e-01, 1.413e-01, 3.484e-01, -1.903e-01, 6.675e-01, 1.151e-02, 8.228e-02, 1.627e-02, -4.125e-01) * s1[y+0][x+1];
	r += M4(3.246e-02, -1.196e-01, -7.495e-02, 5.472e-02, 4.954e-02, -2.155e-02, 1.780e-02, 5.384e-02, 3.675e-01, 6.916e-01, 3.284e-01, 7.957e-02, -1.753e-01, -1.889e-01, -5.382e-02, 7.525e-02) * s1[y+0][x+2];
	r += M4(-3.470e-01, -2.126e-01, -1.918e-01, -6.889e-02, 1.701e-01, 4.213e-02, 3.258e-01, -4.678e-01, -1.655e-01, 6.045e-01, -1.191e+00, -1.758e+00, 1.973e-01, 1.528e-01, 1.792e-01, 2.803e-01) * s1[y+1][x+0];
	r += M4(-3.150e-01, -4.096e-01, 1.558e-01, -2.416e-01, -8.586e-01, -3.096e-01, -7.200e-01, 4.771e-03, 4.068e-01, -8.804e-02, -1.337e+00, -4.489e-01, -2.182e-01, 2.621e-01, 1.958e-01, -1.121e-01) * s1[y+1][x+1];
	r += M4(-1.719e-01, 6.714e-01, -4.717e-01, 1.362e-01, 9.060e-02, 9.900e-02, -2.998e-02, 1.861e-01, -3.408e-01, -1.839e+00, -3.140e-02, 1.186e+00, 1.634e-01, 1.113e-02, 4.128e-01, -1.415e-01) * s1[y+1][x+2];
	r += M4(9.767e-02, 3.821e-02, 2.783e-03, 1.596e-01, 1.602e-01, -3.194e-02, 2.374e-02, 1.615e-01, 2.401e-01, 6.796e+00, -1.398e+00, 1.154e+00, 9.283e-02, -1.213e-01, 5.674e-02, -6.960e-02) * s1[y+2][x+0];
	r += M4(3.421e-02, 1.603e-01, -3.147e-01, 1.438e-02, -3.786e-02, 4.626e-02, 1.577e-01, 1.263e-01, -4.375e+00, 1.749e+01, -3.351e+00, 4.597e-01, -1.747e-01, -5.534e-02, -4.614e-01, 2.731e-01) * s1[y+2][x+1];
	r += M4(-1.410e-01, 3.495e-01, -1.413e-01, -2.565e-01, -1.468e-02, -8.376e-02, 1.018e-01, -6.353e-02, -3.042e+00, 9.796e+00, -3.812e+00, 2.434e-02, 1.103e-01, 3.114e-01, -1.062e-01, 1.696e-02) * s1[y+2][x+2];
	r += V4(-1.509e-01, -2.362e-02, -7.272e-02, -1.372e-01);
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

//!DESC CuNNy-3x4C-DS-conv2
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
	r += M4(-8.616e-02, 9.986e-02, 4.083e-02, 1.883e-01, 2.352e-01, -4.876e-01, -1.683e-01, -5.354e-01, 7.060e-02, -5.864e-02, 6.290e-02, 7.579e-02, -8.063e-02, 2.861e-02, -1.294e-02, -4.566e-02) * s0[y+0][x+0];
	r += M4(-2.741e-02, -6.867e-02, 8.950e-02, -7.931e-02, -6.680e-02, -1.900e-01, -6.111e-01, 1.983e-02, -4.565e-01, -4.305e-03, 1.753e-01, 1.422e-01, 2.193e-01, 1.544e-02, 1.362e-01, -9.490e-02) * s0[y+0][x+1];
	r += M4(1.683e-01, 3.479e-02, -7.914e-02, -7.052e-02, -1.216e-01, -7.485e-02, -1.379e-01, 1.468e-02, -2.649e-01, -5.507e-02, 2.750e-01, 8.211e-02, 2.241e-01, 5.771e-02, -3.282e-02, -4.344e-02) * s0[y+0][x+2];
	r += M4(-8.028e-02, 4.943e-01, -1.880e-01, 4.762e-01, -7.839e-02, -4.800e-01, -2.334e-01, -6.664e-01, -1.475e-01, 3.918e-02, -2.407e-01, 6.981e-02, 1.772e-01, -3.485e-01, 1.809e-01, -1.934e-01) * s0[y+1][x+0];
	r += M4(1.889e-01, -2.368e-01, 3.960e-01, -3.064e-01, 9.391e-02, -3.589e-01, -3.277e-01, -1.729e-01, 3.097e-01, 2.764e-01, -3.573e-01, -2.888e-01, -9.205e-02, -2.860e-01, -1.431e-01, 2.377e-01) * s0[y+1][x+1];
	r += M4(5.131e-03, 8.081e-03, 1.116e-01, 2.087e-01, -9.938e-02, -5.160e-02, -2.666e-01, 1.187e-01, 1.076e-01, -2.007e-01, 3.368e-01, -8.263e-02, -2.056e-01, 1.805e-02, -1.859e-01, 1.382e-01) * s0[y+1][x+2];
	r += M4(9.399e-02, 1.219e-01, 7.026e-02, 1.860e-01, 3.254e-01, -8.031e-01, -1.108e-01, -6.663e-01, -1.174e-01, -8.863e-02, -5.581e-02, -1.630e-01, -2.174e-03, -2.231e-02, -2.301e-02, -9.448e-02) * s0[y+2][x+0];
	r += M4(-2.080e-01, 3.792e-02, 2.678e-01, -2.852e-03, 4.155e-01, -3.760e-01, -3.894e-01, 1.826e-01, 3.368e-01, -5.382e-02, 6.201e-02, 1.408e-01, 3.910e-02, 4.394e-03, -3.443e-02, 9.718e-02) * s0[y+2][x+1];
	r += M4(7.054e-02, -4.591e-02, 3.214e-01, 7.924e-02, -2.059e-01, -9.864e-02, -2.646e-01, 1.275e-01, -7.134e-02, -3.062e-02, -1.481e-01, -7.206e-02, 4.691e-02, -6.214e-02, 8.771e-02, 2.242e-02) * s0[y+2][x+2];
	r += M4(-1.218e-01, -1.207e-01, -1.605e-02, 4.559e-02, 3.012e-02, -1.099e-01, 1.186e-02, -1.932e-02, -7.198e-02, 2.109e-01, -6.812e-02, 2.723e-01, -5.047e-02, 5.913e-02, -5.914e-02, 8.663e-02) * s1[y+0][x+0];
	r += M4(1.024e-01, -1.626e-01, 1.739e-01, -1.115e-01, -1.092e-01, 2.298e-02, -1.205e-02, 7.484e-02, -3.369e-01, -1.653e-01, 7.409e-02, -8.384e-02, -6.662e-02, -5.848e-02, 1.347e-01, -1.424e-01) * s1[y+0][x+1];
	r += M4(1.353e-01, 6.239e-02, -2.148e-01, -9.703e-02, -1.538e-02, -3.969e-02, 9.148e-02, 4.151e-02, -8.369e-02, -6.356e-02, 8.864e-02, 1.263e-01, -4.265e-02, 3.611e-02, -1.450e-01, 1.030e-01) * s1[y+0][x+2];
	r += M4(-4.600e-03, 2.427e-01, 5.154e-02, 4.683e-01, -5.592e-02, -1.238e-02, -1.845e-01, -6.190e-02, -2.488e-01, 2.869e-01, -1.734e-01, 3.056e-01, -2.565e-02, 1.071e-01, 1.800e-01, 2.929e-01) * s1[y+1][x+0];
	r += M4(1.403e-01, -5.185e-01, 4.617e-01, -4.494e-01, 7.169e-02, -8.056e-03, 3.212e-01, 2.410e-01, -4.194e-01, 1.941e-01, -2.015e-01, -2.842e-01, -2.064e-01, -1.813e-01, 5.797e-01, 1.496e-02) * s1[y+1][x+1];
	r += M4(-3.541e-03, 6.808e-02, 3.898e-02, 3.573e-01, -8.195e-02, -7.659e-02, 1.186e-01, 7.499e-02, 9.110e-02, -1.792e-01, 2.046e-01, 1.241e-03, -2.874e-01, -1.257e-02, -1.274e-01, -2.021e-01) * s1[y+1][x+2];
	r += M4(3.912e-01, -1.630e-01, -1.092e-01, -2.531e-01, 4.718e-02, -1.021e-01, 1.685e-02, -1.105e-01, -8.035e-03, -2.764e-01, -5.016e-04, -3.077e-01, -1.156e-01, 2.959e-01, -1.991e-01, 2.315e-01) * s1[y+2][x+0];
	r += M4(1.763e-01, -1.334e-01, -2.732e-02, -3.075e-02, -1.198e-01, 1.209e-02, 1.241e-01, 2.740e-01, 2.699e-01, -2.144e-01, 1.207e-01, 1.431e-01, -3.266e-01, -5.246e-03, 2.358e-01, -6.087e-02) * s1[y+2][x+1];
	r += M4(2.580e-01, -6.908e-02, 8.216e-02, 1.635e-01, -3.495e-02, -1.674e-02, 4.741e-02, -5.140e-02, 3.464e-02, -5.765e-02, -1.170e-01, 4.435e-03, 3.433e-01, 8.123e-03, -2.130e-01, -4.480e-02) * s1[y+2][x+2];
	r += V4(7.676e-03, 5.109e-03, -1.970e-02, -2.595e-02);
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

//!DESC CuNNy-3x4C-DS-conv3
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
	r += M4(-4.775e-02, -3.131e-02, 7.749e-02, -3.275e-02, -5.160e-03, -1.884e-02, -9.296e-03, -1.327e-02, -1.568e-01, 7.830e-02, 1.009e-01, -1.017e-02, -4.472e-02, -3.329e-02, -3.388e-02, -4.698e-02) * s0[y+0][x+0];
	r += M4(7.772e-03, -2.737e-02, 6.095e-02, -3.856e-02, -1.230e-02, -1.058e-01, -5.391e-02, -3.346e-02, 1.004e-01, -7.113e-02, -2.549e-01, -6.295e-02, 8.521e-02, -1.433e-02, -7.272e-02, 8.986e-03) * s0[y+0][x+1];
	r += M4(5.164e-02, -3.559e-02, 2.859e-02, -7.983e-02, -5.408e-02, 2.443e-01, 3.538e-02, -2.852e-02, 1.876e-02, 7.954e-02, 1.852e-01, -9.249e-02, 2.302e-01, -2.289e-01, -1.034e-01, -5.114e-02) * s0[y+0][x+2];
	r += M4(1.223e-01, -1.101e-02, -1.959e-02, -3.846e-02, -1.046e-02, 1.237e-01, -1.506e-01, 1.615e-01, 2.067e-01, 8.211e-02, -1.579e-01, 1.872e-01, 1.509e-01, -2.056e-01, 8.070e-02, -1.450e-01) * s0[y+1][x+0];
	r += M4(-3.429e-01, 2.365e-01, 1.861e-01, 5.687e-03, -1.091e-01, -2.354e-01, -2.220e-01, 8.468e-01, -1.136e+00, -3.007e-01, -3.714e-01, -1.794e-01, 3.544e-02, 2.551e-02, -1.681e-01, -7.447e-01) * s0[y+1][x+1];
	r += M4(4.357e-02, 1.314e-01, 7.836e-02, -5.660e-02, 6.383e-04, -5.448e-01, 3.929e-02, 8.018e-01, 2.378e-01, -9.312e-02, -7.208e-02, -1.381e-01, 2.437e-01, 9.117e-02, 1.529e-01, 3.580e-02) * s0[y+1][x+2];
	r += M4(3.992e-02, -3.948e-02, -6.254e-02, -4.844e-02, 5.616e-02, 1.060e-01, 2.842e-01, -2.529e-02, 6.382e-02, 8.238e-02, 7.497e-02, -1.406e-02, -8.814e-02, -2.532e-02, -1.902e-01, 6.372e-03) * s0[y+2][x+0];
	r += M4(-1.653e-01, -5.697e-02, 5.361e-02, -5.059e-02, -3.657e-01, -3.994e-01, -2.342e-01, 9.530e-02, -1.391e-01, -7.524e-02, -1.832e-02, 6.943e-03, 2.381e-01, 8.133e-02, -1.343e-01, -2.338e-01) * s0[y+2][x+1];
	r += M4(5.537e-03, 1.667e-02, 6.926e-03, -4.883e-02, 1.985e-01, -7.908e-02, -2.627e-01, -5.601e-02, 3.570e-02, 4.970e-02, 3.796e-02, -7.851e-02, 1.549e-01, 1.028e-01, 7.010e-02, -1.073e-01) * s0[y+2][x+2];
	r += M4(-4.401e-02, -1.360e-01, -7.332e-02, 1.274e-01, 1.463e-02, 3.214e-02, 1.528e-01, -2.170e-02, -1.368e-02, -1.204e-02, -6.439e-02, -2.261e-02, -4.137e-02, -4.898e-02, -1.189e-01, -2.087e-02) * s1[y+0][x+0];
	r += M4(1.725e-01, -3.695e-01, 1.130e-01, -2.469e-02, 2.581e-03, -1.300e-01, -1.944e-02, 2.088e-02, 1.257e-01, -5.192e-02, -2.804e-01, -4.302e-02, 4.383e-02, 4.726e-02, 4.944e-02, -1.951e-02) * s1[y+0][x+1];
	r += M4(-5.265e-02, -2.856e-01, 5.436e-02, -1.186e-01, -1.224e-01, 6.564e-02, 4.378e-01, 4.143e-02, -2.847e-02, 4.613e-02, 2.670e-02, -7.112e-02, 7.207e-02, -1.303e-01, -7.223e-02, 2.887e-02) * s1[y+0][x+2];
	r += M4(1.159e+00, -7.927e-03, -1.061e-01, -8.471e-02, 7.296e-02, 2.399e-01, -4.696e-02, 9.541e-02, -5.977e-02, -4.100e-02, -1.658e-01, 8.432e-02, 1.168e-02, -2.940e-01, -5.736e-03, -7.251e-02) * s1[y+1][x+0];
	r += M4(-1.722e-01, 4.262e-01, -3.371e-01, 4.010e-01, -1.187e-01, -2.136e-01, -2.302e-01, 3.464e-01, -7.235e-03, -7.696e-02, -2.190e-01, 1.248e-01, 1.927e-01, 9.053e-02, 2.320e-01, -3.660e-01) * s1[y+1][x+1];
	r += M4(-2.537e-02, 2.743e-01, 2.939e-01, -2.200e-01, 2.489e-01, -3.778e-02, -1.028e-01, -1.813e-01, -2.784e-02, -2.815e-01, -1.784e-03, -1.716e-03, 4.044e-02, 1.969e-01, 7.262e-02, -1.610e-01) * s1[y+1][x+2];
	r += M4(-6.231e-02, 3.764e-02, 1.655e-02, -1.519e-01, 9.943e-02, 1.199e-01, 2.889e-01, -9.533e-02, 1.053e-02, 3.758e-02, 2.056e-01, -1.856e-03, -9.804e-02, -1.141e-01, -3.377e-01, 6.231e-02) * s1[y+2][x+0];
	r += M4(-9.617e-02, -5.380e-01, 8.121e-02, -4.480e-02, -2.056e-01, 3.780e-03, -2.459e-01, 1.626e-01, -1.397e-01, -1.898e-01, 1.354e-01, -1.047e-01, 2.222e-01, -9.253e-02, -1.190e-01, -1.947e-01) * s1[y+2][x+1];
	r += M4(2.731e-02, -2.053e-01, -1.145e-01, 3.382e-01, 2.399e-01, 1.233e-01, -2.391e-01, -2.464e-02, -1.604e-02, -2.276e-02, 3.188e-02, -3.081e-02, 5.530e-02, -1.174e-02, 4.780e-02, -1.352e-01) * s1[y+2][x+2];
	r += V4(6.239e-03, -1.710e-02, -1.077e-02, 4.720e-02);
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

//!DESC CuNNy-3x4C-DS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv3
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
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-5.971e-02, -6.943e-02, -4.277e-02, 2.322e-03, -4.589e-02, -1.530e-02, -4.106e-03, 1.120e-03, 2.137e-02, 1.666e-02, 1.545e-03, -7.370e-03, 5.214e-02, 1.041e-02, -1.161e-02, -7.350e-03) * s0[y+0][x+0];
	r += M4(6.880e-02, 4.490e-01, -8.238e-02, -1.483e-02, 9.891e-02, 4.564e-02, 6.618e-02, 3.971e-02, 3.630e-02, 2.872e-03, 2.317e-02, 9.492e-03, 4.968e-02, 3.356e-02, 4.456e-02, 3.935e-03) * s0[y+0][x+1];
	r += M4(1.156e-01, -3.577e-01, 1.697e-01, -2.699e-02, -3.664e-02, -2.718e-03, -2.249e-02, 1.547e-03, 2.478e-02, 6.028e-02, -1.023e-02, 1.437e-02, -1.308e-02, 4.295e-02, -2.743e-02, 8.645e-03) * s0[y+0][x+2];
	r += M4(3.056e-01, -1.945e-01, 1.284e-01, -2.391e-01, -2.740e-02, -5.609e-02, -8.422e-02, -5.171e-02, 5.497e-02, 3.430e-02, 4.121e-02, 4.906e-02, 5.353e-02, 8.152e-02, 1.278e-01, 8.960e-02) * s0[y+1][x+0];
	r += M4(-1.154e+00, 5.019e-01, -4.935e-01, 1.013e+00, 6.878e-02, 8.126e-02, 6.727e-02, 4.740e-02, -1.783e-01, -7.521e-02, -1.051e-01, -8.190e-02, -3.398e-01, -3.164e-01, -3.577e-01, -2.467e-01) * s0[y+1][x+1];
	r += M4(5.655e-01, -2.672e-01, 3.549e-01, -7.366e-01, -5.422e-03, -5.976e-03, 8.153e-03, -1.653e-02, 2.048e-02, -5.398e-02, 2.885e-02, 8.672e-03, 8.423e-02, 4.205e-02, 7.544e-02, 1.099e-02) * s0[y+1][x+2];
	r += M4(6.354e-02, -9.155e-02, 2.958e-01, -8.329e-02, 1.668e-02, 2.752e-02, 3.343e-02, 8.760e-03, -3.650e-03, -2.354e-02, 2.420e-02, -1.654e-02, -7.949e-03, -2.863e-02, -2.061e-02, -1.897e-02) * s0[y+2][x+0];
	r += M4(1.210e-01, 7.066e-02, -3.620e-01, 1.306e-01, 8.564e-03, 2.413e-02, 6.274e-02, 6.519e-02, 8.680e-02, 4.995e-02, 2.197e-02, 5.551e-02, 4.259e-02, 7.837e-02, 5.250e-02, 2.852e-02) * s0[y+2][x+1];
	r += M4(-1.132e-01, 1.606e-01, 1.253e-01, 3.760e-01, 3.885e-03, -2.993e-02, -3.413e-02, -1.906e-02, -3.148e-02, 2.404e-02, -6.892e-03, -6.636e-03, -3.932e-03, -1.704e-02, 2.553e-02, 5.197e-02) * s0[y+2][x+2];
	r += M4(1.422e-02, -1.209e-03, -1.688e-02, -1.110e-03, -2.882e-02, -7.592e-02, 3.548e-02, -4.861e-02, 6.757e-02, 9.352e-03, -1.934e-03, -8.149e-03, 2.019e-02, -5.407e-02, -7.332e-02, -5.326e-02) * s1[y+0][x+0];
	r += M4(1.341e-01, 6.876e-02, 3.367e-02, 1.704e-03, -2.705e-01, -2.144e-01, 1.208e-01, 9.640e-02, 1.168e-01, 1.212e-01, -1.950e-01, -1.911e-02, -3.007e-01, -2.350e-01, -2.009e-02, -1.283e-01) * s1[y+0][x+1];
	r += M4(2.883e-02, 1.130e-01, 1.723e-02, 3.182e-02, 2.026e-02, 1.184e-03, -3.926e-02, 8.627e-02, 1.151e-01, 2.244e-01, -7.150e-02, -1.968e-01, -3.724e-02, -9.430e-02, -2.920e-05, 5.375e-02) * s1[y+0][x+2];
	r += M4(4.761e-02, 2.132e-02, 4.179e-02, 1.207e-02, 2.125e-01, -2.589e-01, 3.798e-02, -1.557e-01, 3.899e-02, -4.987e-02, 1.196e-01, 3.576e-02, -6.245e-02, 6.238e-02, 3.073e-02, 2.666e-02) * s1[y+1][x+0];
	r += M4(-2.060e-01, -4.652e-02, -4.138e-02, 3.917e-02, 2.364e-01, 7.403e-01, -8.235e-01, -2.032e-01, -9.240e-01, 2.828e-02, 2.497e-01, 2.569e-01, -8.079e-01, -8.825e-01, -8.510e-01, -7.929e-01) * s1[y+1][x+1];
	r += M4(3.327e-02, -1.118e-01, 3.358e-03, -4.541e-02, 1.041e-02, -5.238e-02, 8.052e-02, -3.682e-01, 2.096e-02, -7.917e-01, 3.467e-01, 4.862e-01, -1.151e-01, -1.178e-01, -4.854e-02, -1.695e-01) * s1[y+1][x+2];
	r += M4(3.123e-02, 1.699e-02, 6.183e-02, 2.670e-02, -9.154e-02, 2.456e-02, -4.867e-02, -1.439e-01, -1.940e-02, -6.439e-03, 5.188e-02, -5.098e-02, 5.296e-02, -2.933e-02, -1.655e-02, 3.973e-02) * s1[y+2][x+0];
	r += M4(3.069e-02, -2.473e-02, -2.842e-02, -3.763e-02, -1.274e-01, -1.763e-01, 3.408e-01, 4.014e-01, 2.437e-01, 2.940e-01, -4.580e-01, 2.857e-01, -1.487e-02, 1.130e-01, -2.592e-01, -2.898e-01) * s1[y+2][x+1];
	r += M4(1.604e-02, 8.532e-02, 5.559e-02, 8.893e-02, -4.576e-02, -1.008e-01, -6.480e-02, -8.296e-03, 5.179e-02, 2.603e-02, 5.386e-03, -6.309e-01, -3.293e-02, -8.117e-02, -7.404e-02, -6.468e-02) * s1[y+2][x+2];
	r += V4(6.170e-03, 5.539e-03, 6.672e-03, 5.905e-03);
	return tanh(vec4(r));
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

//!DESC CuNNy-3x4C-DS-shuffle
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

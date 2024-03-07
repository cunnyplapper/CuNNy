// CuNNy 8x4C DS
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


//!DESC CuNNy-8x4C-DS-in
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
vec4 f0(F s0_0, F s0_1, F s0_2, F s0_3, F s0_4, F s0_5, F s0_6, F s0_7, F s0_8) {
	V4 r = V4(0.0);
	r += V4(-9.150e-02, 3.041e-01, -9.317e-02, -5.042e-02) * s0_0;
	r += V4(-3.076e-01, -3.917e-02, 8.079e-02, -2.388e-01) * s0_1;
	r += V4(9.339e-02, 1.765e-01, -6.561e-02, 1.619e-01) * s0_2;
	r += V4(2.902e-01, -5.120e-02, 1.064e-01, 4.369e-02) * s0_3;
	r += V4(2.483e-01, 8.562e-03, 8.064e-01, -4.658e-01) * s0_4;
	r += V4(-1.724e-01, 2.167e-01, 4.767e-02, -8.597e-03) * s0_5;
	r += V4(-1.283e-01, -8.952e-02, -8.799e-02, -4.361e-02) * s0_6;
	r += V4(-2.065e-01, -1.384e-01, 1.125e-01, 6.298e-01) * s0_7;
	r += V4(6.234e-02, -3.516e-02, -6.425e-02, -4.065e-02) * s0_8;
	r += V4(2.482e-03, -2.358e-01, -1.593e-02, 3.074e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = LUMA_pt;
	F s0_0 = l0(-1, -1);
	F s0_1 = l0(0, -1);
	F s0_2 = l0(1, -1);
	F s0_3 = l0(-1, 0);
	F s0_4 = l0(0, 0);
	F s0_5 = l0(1, 0);
	F s0_6 = l0(-1, 1);
	F s0_7 = l0(0, 1);
	F s0_8 = l0(1, 1);
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8));
}


//!DESC CuNNy-8x4C-DS-conv1
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-3.635e-01, -1.877e-01, -2.998e-01, 1.931e-01, 8.245e-02, -2.314e-01, -1.007e-01, 4.746e-02, 3.216e-02, -3.619e-02, -1.457e-01, 2.070e-01, 1.186e-01, 1.852e-01, -1.038e-01, -2.789e-02) * s0_0;
	r += M4(2.275e-01, -4.997e-01, 1.406e-01, -4.419e-01, 5.945e-02, -1.619e-01, -1.130e-01, 4.982e-02, 9.319e-02, -9.708e-02, -9.731e-03, -1.272e-01, 1.788e-01, 3.448e-01, 7.096e-02, 1.835e-02) * s0_1;
	r += M4(2.139e-01, -2.621e-01, 1.175e-01, -3.804e-01, 3.820e-02, -1.323e-01, 1.372e-01, -1.269e-01, 3.441e-02, -2.239e-02, 1.072e-01, 1.542e-01, -1.260e-01, 1.572e-01, -2.483e-02, 5.343e-02) * s0_2;
	r += M4(-1.973e-01, -3.600e-01, 2.651e-01, -6.246e-01, -2.709e-02, 2.047e-02, -4.909e-03, 2.113e-01, 2.251e-01, -2.269e-01, 2.693e-02, 1.674e-01, 4.317e-01, 3.730e-01, -5.211e-01, -1.591e-01) * s0_3;
	r += M4(2.881e-01, 2.479e-01, -1.073e-01, 4.926e-01, 1.657e-01, 1.433e-02, -1.550e-01, -2.196e-02, 2.196e-01, 7.832e-01, -2.059e-02, 5.694e-02, -5.209e-01, -5.832e-02, 7.426e-01, -2.321e-01) * s0_4;
	r += M4(4.666e-01, 3.237e-01, -3.967e-01, -8.042e-01, 5.896e-02, 1.581e-01, 2.860e-02, -1.902e-02, 1.676e-01, -9.617e-03, -5.076e-01, 5.285e-02, -3.643e-03, -5.210e-02, 1.074e-01, 2.445e-01) * s0_5;
	r += M4(1.593e-01, 6.506e-02, -2.145e-01, -2.644e-01, 1.676e-01, 1.229e-01, -6.496e-03, 6.204e-02, -2.939e-01, -1.102e-01, 1.636e-01, 7.872e-02, 4.088e-02, 1.016e-01, -6.861e-02, -5.589e-02) * s0_6;
	r += M4(-1.913e-01, -3.661e-01, 3.431e-01, 5.159e-01, -2.249e-01, 5.128e-02, -2.706e-02, -8.786e-02, 2.352e-01, 1.853e-01, 4.349e-01, -5.038e-02, -1.223e-01, -2.195e-01, 2.007e-01, 2.061e-01) * s0_7;
	r += M4(-3.689e-01, -1.203e-02, 7.114e-01, -1.870e-01, -2.264e-02, 1.256e-01, 1.589e-01, 1.450e-01, 6.214e-02, -1.543e-02, 2.219e-03, -4.952e-02, 6.839e-02, 3.608e-02, 1.105e-01, -1.537e-01) * s0_8;
	r += M4(5.117e-02, -9.259e-02, -2.100e-01, 3.005e-02, 1.482e-01, -1.807e-01, -7.469e-02, -3.100e-02, 2.421e-01, -1.352e-01, 7.101e-01, 3.402e-01, 9.340e-02, -1.219e-01, 5.030e-02, 3.729e-02) * s1_0;
	r += M4(-8.013e-02, -4.224e-01, 7.268e-02, -3.974e-02, 5.472e-03, -1.234e-01, -6.576e-02, 6.124e-02, 7.428e-01, 9.768e-01, -1.615e-02, 1.174e+00, -6.647e-02, 3.964e-01, -1.006e-02, 1.625e-01) * s1_1;
	r += M4(3.885e-01, -1.527e-01, 1.331e-01, 5.981e-02, 9.415e-02, -2.357e-01, 1.084e-01, -2.506e-02, 4.147e-01, -6.130e-01, 1.002e-01, 9.449e-01, -2.049e-01, 6.000e-02, -9.579e-02, -3.486e-02) * s1_2;
	r += M4(-2.578e-01, -1.126e-01, -1.305e-01, -2.425e-01, -1.528e-01, 3.578e-02, 6.468e-04, 7.907e-02, -4.052e-01, 2.887e-01, 4.310e-02, 5.552e-01, 4.870e-01, 3.000e-01, -5.474e-01, 8.125e-02) * s1_3;
	r += M4(4.600e-02, 3.157e-01, -4.061e-01, 2.387e-01, 1.233e-01, 6.860e-02, -1.531e-02, -2.536e-02, -2.795e+00, 2.495e+00, -1.503e+00, 2.686e+00, -3.939e-01, -3.932e-01, 4.264e-01, -1.247e-01) * s1_4;
	r += M4(1.338e-01, 1.210e-01, -2.398e-02, 1.923e-02, -4.854e-02, 1.352e-01, -2.778e-01, 3.517e-02, 3.291e-01, 7.283e-01, -2.332e+00, 2.789e-01, -3.813e-02, 1.509e-01, -3.117e-01, 2.111e-01) * s1_5;
	r += M4(6.607e-02, -3.379e-02, -1.421e-01, -1.310e-01, 1.947e-01, 1.236e-01, 4.943e-02, -1.446e-02, -8.063e-01, -4.095e-01, -1.270e-01, 3.736e-01, 3.365e-02, 2.469e-02, -6.553e-03, -2.287e-02) * s1_6;
	r += M4(-2.803e-01, -2.418e-01, 8.805e-02, 1.434e-01, -2.861e-01, -1.062e-01, 9.633e-03, 2.388e-02, -6.404e-01, 1.076e+00, 1.098e+00, 4.624e-01, -2.134e-01, -9.656e-02, 6.754e-03, 1.272e-01) * s1_7;
	r += M4(-1.088e-01, -1.302e-02, 4.806e-01, -2.085e-02, 1.105e-01, -2.820e-02, 1.045e-01, -1.235e-01, 1.346e-01, -5.873e-01, -4.130e-01, 6.221e-01, -2.788e-02, 1.388e-02, 3.957e-01, -7.178e-02) * s1_8;
	r += V4(-6.667e-01, -1.465e-01, -4.463e-02, 3.037e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = in_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv2
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-6.311e-01, -5.276e-02, 1.201e-01, -1.235e-01, -8.583e-02, 4.914e-02, -2.349e-02, 1.656e-01, -6.973e-01, 4.164e-01, 2.284e-01, 1.940e-01, -2.686e-02, -6.260e-02, -4.331e-02, -1.226e-01) * s0_0;
	r += M4(5.222e-01, 6.567e-01, 3.705e-01, 3.330e-01, 1.803e-01, 3.653e-02, -2.325e-02, -1.247e-01, 5.380e-02, -7.735e-02, 6.914e-02, 5.879e-01, 8.866e-02, 9.657e-02, 1.646e-01, 1.822e-01) * s0_1;
	r += M4(-4.652e-01, 1.322e-01, 1.560e+00, 1.561e-02, 1.521e-01, 1.913e-02, 2.191e-01, 8.562e-02, -1.360e-01, 1.544e-01, 1.453e-01, 1.358e-01, -1.717e-01, -1.520e-01, 5.531e-02, -1.874e-01) * s0_2;
	r += M4(8.908e-02, -4.682e-01, 1.648e-01, 6.598e-01, -5.103e-02, -3.271e-01, -2.106e-01, 2.270e-01, -3.374e-01, 5.284e-01, 3.268e-02, -1.544e-02, -1.441e-01, 2.276e-02, -1.445e-01, 2.267e-01) * s0_3;
	r += M4(-1.321e+00, -1.659e+00, 2.403e+00, 5.233e-01, 1.624e-01, -4.495e-01, -1.252e-02, -9.478e-01, 3.400e-01, 3.799e-01, -2.834e-01, 2.386e-01, -6.991e-02, -2.378e-01, -2.316e-01, -2.801e-01) * s0_4;
	r += M4(-2.103e-01, 4.360e-01, 1.789e+00, 1.251e+00, 1.676e-01, -4.187e-02, 5.221e-01, 2.320e-01, -2.808e-02, -1.698e-01, 2.813e-01, 7.005e-02, -9.411e-02, 2.049e-01, -3.802e-02, -3.348e-02) * s0_5;
	r += M4(5.365e-02, -8.949e-01, -4.465e-01, 7.497e-01, 2.244e-01, -3.459e-02, 2.993e-02, 4.073e-02, 1.805e-02, -1.960e-02, -3.557e-02, 5.573e-02, 2.914e-02, -8.893e-03, 9.653e-03, 3.259e-01) * s0_6;
	r += M4(-1.323e+00, -9.673e-01, 2.233e+00, 3.728e-01, -1.389e-01, 6.385e-02, -3.114e-02, -3.222e-01, -1.284e-01, -5.639e-03, 5.324e-02, -4.728e-02, -1.338e-01, -4.055e-02, 5.960e-02, 2.659e-01) * s0_7;
	r += M4(4.963e-01, 4.435e-01, 1.757e-01, 7.241e-01, 1.166e-01, 2.392e-01, -2.940e-01, 7.547e-02, 1.999e-02, -2.929e-02, -1.339e-01, -1.488e-01, -8.245e-02, 7.076e-02, 4.010e-02, 2.137e-02) * s0_8;
	r += M4(-3.516e-01, -6.564e-02, -7.307e-02, 9.500e-02, -1.604e-02, 1.438e-01, 1.112e-02, 6.404e-03, 2.446e-01, -5.646e-01, 3.116e-02, -1.320e-01, 4.472e-01, -3.735e-01, -5.939e-02, -3.540e-01) * s1_0;
	r += M4(9.116e-02, -2.837e-03, 1.851e-01, 2.336e-02, 4.242e-01, -1.187e-01, -3.771e-02, -9.757e-02, -6.017e-02, -6.035e-01, -6.932e-01, -5.226e-02, -1.141e+00, 1.109e-01, 1.020e+00, -7.186e-02) * s1_1;
	r += M4(-1.912e-01, -7.459e-02, 2.484e-02, -9.515e-02, 4.016e-01, -2.100e-02, 2.505e-01, 1.636e-01, -1.545e-02, -1.525e-02, -4.435e-01, -1.392e-01, -6.907e-02, -4.758e-01, -4.666e-02, -4.010e-01) * s1_2;
	r += M4(3.668e-02, 4.297e-01, -3.076e-02, 1.194e-01, 1.445e-02, -7.522e-02, -2.018e-01, 3.085e-02, -2.052e-01, -1.317e-01, -7.344e-02, -3.001e-01, 3.365e-01, -7.113e-01, -9.944e-02, -1.457e-01) * s1_3;
	r += M4(6.113e-01, -2.642e-01, -9.039e-02, -1.850e-01, -7.053e-02, -6.885e-01, 2.900e-01, -3.849e-01, 2.826e-01, -1.548e-01, -4.739e-01, -1.723e-01, -8.184e-01, -1.175e+00, 4.665e-01, -5.060e-01) * s1_4;
	r += M4(1.067e-01, 2.671e-01, 2.234e-01, 1.001e-01, -1.638e-01, -8.593e-02, 4.579e-01, 3.683e-01, -3.301e-01, -2.153e-01, 3.677e-01, -3.758e-02, -7.908e-01, -9.492e-01, 2.666e-01, 9.536e-02) * s1_5;
	r += M4(-4.356e-02, 6.874e-02, 1.454e-01, 1.035e-01, 3.106e-01, 1.775e-02, -1.798e-01, 2.108e-01, 6.549e-02, 2.962e-02, 4.502e-03, -2.236e-02, -1.280e-01, -2.155e-01, 1.689e-01, 2.574e-02) * s1_6;
	r += M4(-3.840e-02, 1.025e-01, -8.786e-02, 5.874e-02, -2.347e-01, -1.264e-01, 1.203e-01, -1.556e-01, -3.098e-02, 2.184e-02, 1.742e-02, -4.974e-02, -5.758e-01, -9.660e-01, 4.758e-01, 1.670e-01) * s1_7;
	r += M4(-3.628e-02, -1.897e-01, -2.035e-01, -8.186e-02, 2.108e-01, 5.039e-01, -4.473e-01, 3.790e-02, -4.679e-02, 7.967e-02, 1.459e-01, -1.190e-01, -6.987e-02, -7.514e-01, -6.387e-01, -1.521e-01) * s1_8;
	r += V4(1.405e-01, 8.774e-02, 2.757e-02, 3.969e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv1_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv3
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-3.852e-02, -1.927e-01, 5.235e-02, -1.786e-02, 4.163e-02, 3.939e-02, 9.462e-02, 1.808e-02, -8.512e-02, -2.225e-01, -5.720e-02, -4.448e-02, -5.239e-02, -1.086e-01, 3.962e-02, 4.786e-02) * s0_0;
	r += M4(5.486e-02, -2.673e-01, -4.538e-03, -2.681e-02, -3.913e-02, 3.706e-01, 1.254e-01, -6.317e-03, 6.822e-02, -7.925e-02, 4.209e-03, -1.548e-01, 1.428e-01, 1.543e-02, 8.292e-02, 1.955e-01) * s0_1;
	r += M4(7.813e-02, -4.203e-02, 8.000e-02, 1.184e-01, -2.006e-01, 9.121e-02, -3.622e-02, 5.765e-02, 4.476e-02, -6.860e-02, -2.015e-02, 2.039e-01, 3.244e-02, -1.201e-01, 9.416e-02, 3.726e-02) * s0_2;
	r += M4(1.949e-01, -2.094e-02, 1.451e-01, 1.476e-01, -2.977e-03, 1.912e-01, -3.902e-02, 7.935e-02, 2.412e-01, 5.521e-01, 3.822e-02, 1.604e-01, 2.388e-01, 3.682e-01, 1.782e-01, -1.289e-02) * s0_3;
	r += M4(6.450e-02, -3.657e-02, -7.304e-03, 2.571e-01, -4.802e-01, -6.860e-01, 8.512e-02, -1.298e-01, -7.644e-02, 4.166e-01, -2.665e-01, -1.215e-01, -2.193e-01, -4.207e-01, 1.950e-01, -2.576e-02) * s0_4;
	r += M4(-2.751e-01, 1.284e-01, -5.043e-01, 6.367e-02, -3.568e-01, 1.843e-03, 5.918e-01, -5.107e-01, -1.881e-01, 5.934e-02, -1.863e-01, -4.363e-01, 3.886e-01, -6.343e-02, 2.313e-01, 7.644e-01) * s0_5;
	r += M4(5.896e-02, 2.586e-01, 9.349e-02, -5.353e-02, -6.584e-03, -3.843e-02, 5.094e-02, 4.049e-03, 1.934e-02, 1.134e-01, 2.244e-02, 6.218e-02, -7.831e-02, 1.499e-01, -1.391e-01, 3.261e-02) * s0_6;
	r += M4(-1.882e-01, 5.164e-02, -4.420e-02, -3.186e-02, 3.499e-02, 8.205e-03, -5.120e-02, 1.558e-01, -1.708e-01, -7.788e-02, 1.481e-01, 2.955e-01, -6.164e-02, 8.734e-02, 4.079e-02, -1.544e-01) * s0_7;
	r += M4(-3.447e-01, 5.097e-02, -3.237e-01, -3.883e-01, -1.044e-01, 3.296e-02, 2.143e-01, 7.596e-02, -1.192e-01, -9.157e-02, -1.021e-01, -2.312e-01, 1.194e-01, 1.797e-01, 6.928e-02, -2.279e-01) * s0_8;
	r += M4(6.074e-02, -2.105e-02, 1.047e-01, -5.861e-02, 1.134e-01, -4.124e-02, 1.747e-01, 1.933e-02, -1.994e-01, -2.609e-01, 1.044e-01, 1.363e-01, -2.219e-03, -3.348e-01, 4.613e-02, 6.200e-02) * s1_0;
	r += M4(6.419e-02, -7.976e-02, -3.334e-02, 5.125e-02, 1.113e-01, 3.519e-01, -3.830e-02, -1.736e-02, 1.343e-01, -1.958e-01, -2.572e-02, -2.827e-02, 2.165e-01, 1.559e-01, 1.391e-02, 1.151e-01) * s1_1;
	r += M4(-5.022e-02, 1.172e-01, 2.375e-02, -4.175e-03, -7.527e-02, 7.195e-02, 3.084e-01, -2.891e-01, 1.266e-03, -4.478e-02, -1.170e-02, 2.742e-02, 1.192e-01, -3.739e-01, 3.447e-01, 1.425e-01) * s1_2;
	r += M4(1.848e-01, 2.607e-01, 6.749e-02, 2.037e-02, -8.793e-02, 1.682e-01, -4.753e-02, -5.540e-02, 3.740e-01, 1.983e-01, 5.558e-01, -3.445e-01, 2.310e-01, 3.103e-01, 2.339e-01, -6.426e-02) * s1_3;
	r += M4(-1.052e-01, -1.489e-01, 4.726e-01, 1.028e-01, -4.172e-01, -5.543e-01, 7.831e-02, 9.249e-02, 5.215e-01, -2.811e-02, 2.753e-01, 4.525e-01, -2.833e-01, -3.921e-01, -9.082e-02, -1.989e-02) * s1_4;
	r += M4(-3.081e-01, 1.080e-01, -4.870e-01, -7.037e-02, -9.666e-02, -1.100e-01, 4.505e-01, -6.933e-01, -1.160e-02, 1.140e-01, -1.686e-01, -2.315e-01, 7.394e-01, -1.168e-01, 1.898e-01, 4.971e-01) * s1_5;
	r += M4(3.136e-02, 3.728e-01, -1.503e-02, -2.642e-02, 1.755e-02, -2.780e-02, -3.896e-02, -9.777e-02, 2.591e-01, 2.211e-01, -1.375e-01, 4.174e-02, -8.587e-02, 4.895e-02, -1.305e-01, 6.478e-02) * s1_6;
	r += M4(-4.166e-01, -1.381e-01, 8.125e-02, 1.521e-01, 4.216e-02, -6.121e-02, -9.313e-02, 4.482e-02, -3.782e-02, 1.750e-01, 1.437e-02, 1.298e-01, -1.514e-01, 2.602e-02, -6.610e-02, -8.553e-02) * s1_7;
	r += M4(-4.194e-01, -8.503e-02, -2.149e-01, -3.917e-01, 7.182e-02, 3.699e-03, -9.266e-02, -2.711e-02, -1.532e-01, -1.612e-02, -1.097e-01, -9.562e-02, 9.559e-02, 1.222e-01, -3.797e-01, -1.143e-01) * s1_8;
	r += V4(-6.138e-02, -3.291e-02, 3.543e-02, -4.489e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv2_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv4
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(3.975e-01, -3.212e-02, -6.256e-02, 3.855e-01, -4.761e-02, 5.496e-02, 2.909e-02, -2.442e-02, -1.454e-01, 5.400e-02, -1.294e-01, -2.379e-02, -8.066e-02, 3.756e-02, -2.282e-01, -2.455e-01) * s0_0;
	r += M4(7.073e-03, -1.764e-01, 2.646e-01, -2.293e-01, 1.719e-01, 1.537e-01, -8.048e-02, 1.422e-01, 4.746e-02, 8.482e-02, -1.917e-01, -3.305e-02, 7.954e-02, 2.777e-01, 1.220e-01, -1.428e-02) * s0_1;
	r += M4(-5.340e-02, 1.957e-01, -1.135e-01, 5.841e-02, 5.780e-03, -7.552e-02, -1.291e-01, 1.155e-01, -9.377e-02, -2.712e-02, -1.111e-01, 5.350e-02, 1.520e-01, 4.250e-02, 1.414e-02, -6.030e-02) * s0_2;
	r += M4(9.211e-02, 2.502e-02, 3.662e-03, -1.502e-02, 1.186e-01, -3.204e-02, -3.445e-01, 9.772e-02, 4.076e-01, -2.770e-02, -1.457e-02, 2.900e-01, -1.159e-01, 6.152e-02, 7.961e-02, -3.576e-01) * s0_3;
	r += M4(3.128e-01, 4.260e-01, 2.486e-01, -2.288e-02, 9.277e-01, 8.764e-02, 3.922e-01, -2.667e-01, 6.778e-01, -6.862e-01, -2.032e-01, 2.123e-01, 1.584e-01, -4.248e-01, 6.872e-03, -7.105e-01) * s0_4;
	r += M4(-2.013e-01, 2.257e-01, -7.318e-02, 2.729e-01, 1.362e-01, 6.924e-02, -6.780e-02, 2.678e-01, 3.262e-02, -3.745e-01, 7.041e-02, 4.862e-02, 3.090e-02, -2.100e-01, 1.642e-01, -1.486e-01) * s0_5;
	r += M4(-4.145e-02, -1.243e-01, 1.211e-01, 3.701e-01, -5.142e-02, 5.100e-02, 6.167e-03, 1.036e-01, -8.733e-02, 7.730e-02, -2.979e-01, -2.577e-02, -2.120e-01, -1.006e-02, 1.249e-03, -2.585e-01) * s0_6;
	r += M4(-1.661e-01, -6.001e-03, -3.070e-02, 2.046e-01, 7.882e-03, 1.595e-01, -1.735e-01, 4.321e-01, 4.401e-02, -1.163e-01, 1.819e-01, -2.144e-02, -2.905e-01, 7.791e-02, -1.095e-01, -1.737e-01) * s0_7;
	r += M4(3.117e-02, -4.360e-02, 1.714e-01, -5.673e-02, -6.438e-02, 1.343e-01, 3.407e-02, 7.483e-02, -6.568e-02, -1.287e-01, -8.349e-03, -1.215e-01, 3.252e-02, 9.505e-02, -5.996e-02, 8.058e-02) * s0_8;
	r += M4(3.260e-01, 4.304e-02, -2.049e-01, 1.439e-01, 1.416e-01, -2.253e-02, -5.571e-02, -5.369e-02, -3.672e-01, -1.739e-01, 6.263e-03, -1.411e-01, -1.875e-01, -7.703e-02, 1.888e-02, -3.065e-02) * s1_0;
	r += M4(1.535e-01, -1.012e-01, 1.279e-02, -2.600e-01, 1.907e-01, -5.685e-02, -3.078e-01, 2.794e-02, 2.711e-02, 1.930e-01, 6.112e-02, -1.650e-01, -7.919e-02, 4.614e-01, 2.623e-01, 2.447e-01) * s1_1;
	r += M4(4.335e-02, 1.093e-01, -1.136e-01, 5.258e-02, -9.788e-02, -1.568e-01, -1.484e-01, -6.667e-02, 2.879e-02, -3.411e-02, -1.194e-01, -6.948e-02, 8.034e-02, -1.081e-01, 7.179e-02, -1.133e-01) * s1_2;
	r += M4(7.464e-02, 1.204e-02, 2.025e-01, -4.335e-01, 1.894e-01, -1.508e-01, -3.815e-01, -1.108e-02, 6.077e-02, 1.025e-01, 1.446e-01, -4.695e-03, 1.875e-01, 2.477e-01, 4.684e-01, 3.676e-01) * s1_3;
	r += M4(-4.219e-02, 1.284e-02, 3.623e-01, -4.874e-01, 6.363e-01, 6.519e-02, 5.674e-01, -4.658e-01, 4.316e-01, -2.844e-01, -2.753e-01, 7.077e-02, 4.424e-01, -3.917e-01, 1.055e-02, -3.341e-01) * s1_4;
	r += M4(-2.135e-01, 6.451e-01, -1.529e-01, 2.236e-01, 1.626e-01, 4.892e-01, -1.469e-01, -1.709e-02, 3.338e-02, -8.958e-02, 1.080e-01, 1.282e-02, 4.324e-02, -2.883e-01, 1.164e-01, -3.904e-02) * s1_5;
	r += M4(3.846e-02, 4.383e-02, -6.090e-02, 1.646e-01, -1.508e-01, -4.650e-02, -1.414e-01, -1.129e-01, -7.876e-02, 4.461e-02, -1.921e-01, 5.621e-02, -1.026e-01, 1.250e-01, 4.160e-01, -1.736e-02) * s1_6;
	r += M4(8.252e-02, -2.362e-02, -2.717e-01, -4.280e-02, -1.691e-01, -6.355e-02, -2.024e-01, -7.841e-02, 4.049e-02, 8.662e-02, 1.409e-01, 2.051e-01, -2.097e-01, 1.823e-01, -2.424e-02, 6.394e-02) * s1_7;
	r += M4(1.655e-01, -8.026e-02, -7.581e-03, 8.860e-02, -7.183e-02, 1.428e-01, -1.433e-01, -9.769e-02, -9.820e-02, -7.494e-02, -5.844e-02, -9.699e-02, -1.717e-01, -6.882e-02, -1.754e-02, 4.287e-02) * s1_8;
	r += V4(2.013e-02, 1.914e-02, -4.287e-02, -1.445e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv3_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv5
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(4.442e-02, -1.098e-02, 3.853e-02, -4.619e-02, -3.118e-01, 1.330e-01, 2.231e-01, 1.833e-01, 1.108e-01, -1.210e-01, 9.705e-02, -1.214e-02, -3.976e-02, -3.560e-02, -5.336e-02, -4.176e-02) * s0_0;
	r += M4(8.837e-02, 9.060e-02, -2.935e-02, 4.033e-02, 7.690e-02, -2.501e-01, 2.347e-01, 9.515e-02, 4.507e-01, -4.245e-01, 1.379e-01, 1.401e-01, 2.078e-02, 6.480e-02, -5.600e-02, 1.524e-01) * s0_1;
	r += M4(-5.082e-03, 5.456e-03, -2.994e-02, -1.825e-02, 1.714e-02, 1.773e-02, -4.114e-02, 7.266e-02, 2.360e-01, -3.277e-03, 2.903e-02, 4.632e-02, 4.012e-02, 6.355e-02, -5.303e-02, 5.001e-02) * s0_2;
	r += M4(3.084e-03, -8.958e-03, -9.650e-02, -2.522e-01, -5.837e-01, -2.583e-01, 1.384e-01, 7.972e-01, 5.084e-01, -4.658e-01, 6.140e-02, 2.002e-01, -1.157e-01, -3.707e-03, -9.825e-02, -2.473e-01) * s0_3;
	r += M4(-2.256e-01, 4.296e-01, -5.669e-01, 1.398e-01, 5.306e-01, -3.564e-01, 4.692e-01, 2.922e-01, 2.875e-01, 4.064e-02, 2.541e-01, -2.265e-02, 2.021e-01, -9.270e-02, -9.062e-01, -7.085e-01) * s0_4;
	r += M4(6.452e-02, -1.240e-01, -5.004e-02, 4.219e-02, 1.103e-01, -1.253e-01, 7.416e-02, 1.774e-01, 1.772e-02, 3.764e-01, 3.320e-01, -4.422e-02, 2.066e-02, 2.588e-01, -6.764e-02, 1.275e-01) * s0_5;
	r += M4(7.464e-02, 7.873e-02, -2.804e-02, -5.674e-02, 2.149e-01, -2.590e-01, 2.735e-01, 2.442e-01, 2.145e-02, -8.336e-02, 2.945e-02, -3.436e-03, 1.870e-01, 1.332e-01, -8.575e-02, -2.325e-03) * s0_6;
	r += M4(-1.263e-02, -7.934e-02, -7.639e-02, 1.143e-01, 4.858e-01, 1.111e-01, 1.384e-01, 3.713e-01, 1.766e-01, 1.756e-01, 4.192e-01, 6.567e-02, 2.361e-02, 8.190e-02, -5.896e-02, 7.659e-02) * s0_7;
	r += M4(3.150e-02, 1.498e-01, 1.466e-01, 7.214e-02, 2.623e-02, -3.301e-01, 2.391e-02, 5.571e-03, 6.983e-02, -2.064e-01, -4.599e-02, 8.747e-02, 5.208e-02, -1.509e-01, -7.685e-02, 3.565e-02) * s0_8;
	r += M4(4.604e-02, -3.054e-02, 5.615e-02, 6.731e-02, -9.946e-02, 8.520e-02, -1.876e-02, 1.018e-01, 1.472e-01, -1.527e-01, -4.421e-02, 6.343e-02, -1.646e-01, 1.643e-01, 7.253e-02, -9.074e-02) * s1_0;
	r += M4(8.342e-02, 7.299e-02, -4.581e-02, 3.193e-01, -9.007e-02, -8.715e-03, -8.076e-02, -5.852e-02, 1.413e-01, -3.828e-02, 1.638e-02, -6.327e-02, -1.526e-01, 2.118e-01, 1.672e-01, 2.542e-01) * s1_1;
	r += M4(1.409e-01, -9.573e-02, -1.378e-01, 9.650e-02, 1.195e-03, -2.812e-02, -9.047e-02, -4.531e-02, 4.494e-02, 9.588e-02, -1.324e-02, -1.104e-03, 1.440e-02, 1.574e-02, 6.816e-02, 4.240e-02) * s1_2;
	r += M4(7.017e-01, -6.951e-02, 2.724e-01, 4.334e-01, -4.061e-02, 1.447e-02, -1.279e-01, 3.800e-01, 3.176e-01, -4.747e-02, -6.528e-02, 5.688e-02, -2.185e-01, 1.564e-01, 2.379e-01, -5.298e-02) * s1_3;
	r += M4(2.571e-01, 4.275e-01, -8.784e-01, 4.095e-02, 1.422e-01, -2.881e-01, -2.783e-02, 1.383e-01, 1.889e-01, 3.818e-01, -2.398e-01, 4.540e-02, 1.950e-01, -6.213e-01, -2.020e-01, -2.245e-01) * s1_4;
	r += M4(2.251e-01, 1.085e-01, -4.797e-01, 9.412e-02, -1.872e-02, -1.247e-02, -2.953e-02, -8.098e-03, -5.377e-02, 7.915e-02, -1.003e-01, -7.083e-02, 1.763e-01, -6.930e-03, -1.257e-01, -5.595e-02) * s1_5;
	r += M4(4.509e-01, -1.743e-01, -3.910e-02, 7.131e-02, 1.552e-01, -3.152e-01, -1.671e-01, 5.751e-02, 2.396e-03, 8.417e-02, -1.485e-01, -7.191e-02, 5.854e-02, 1.355e-01, 1.200e-01, 6.344e-02) * s1_6;
	r += M4(2.326e-01, 1.819e-01, -2.439e-01, 7.176e-02, 9.106e-02, 2.911e-01, 1.449e-01, 6.700e-02, 1.671e-01, 6.844e-02, -2.865e-02, 3.234e-02, 1.581e-01, -5.571e-02, -2.103e-02, -8.934e-02) * s1_7;
	r += M4(-1.432e-02, 1.021e-01, -1.248e-01, 1.012e-01, -5.840e-02, 4.531e-02, 2.963e-02, -3.132e-02, 7.531e-02, -6.889e-02, -1.343e-01, -6.120e-02, 1.363e-01, -2.278e-02, -1.554e-02, 1.883e-03) * s1_8;
	r += V4(-3.036e-02, 4.759e-02, 1.149e-04, -1.011e-01);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv4_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv6
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-1.552e-01, -1.010e-01, -4.823e-02, -2.528e-02, 9.056e-02, -2.961e-02, 2.242e-02, -5.812e-03, -8.370e-02, -9.368e-02, -2.429e-01, 1.454e-01, -1.272e-01, 8.721e-02, 3.019e-02, -5.708e-02) * s0_0;
	r += M4(-2.322e-01, 1.273e-01, -2.056e-01, -7.546e-02, 7.173e-02, -4.529e-02, -2.429e-02, 8.781e-02, -5.602e-02, -1.757e-01, -3.252e-01, 1.809e-01, 2.955e-01, 1.640e-01, 2.235e-01, -1.509e-01) * s0_1;
	r += M4(2.575e-01, 1.167e-01, 2.485e-01, -1.653e-01, 2.390e-02, 1.839e-02, 1.133e-01, -1.396e-02, -4.886e-02, -2.387e-02, -5.663e-02, 1.210e-01, 5.551e-02, 2.575e-01, 1.059e-01, -1.699e-01) * s0_2;
	r += M4(-4.004e-03, -4.333e-02, -8.541e-02, -1.417e-02, -9.597e-02, 1.057e-01, 1.873e-01, 8.525e-02, -2.101e-01, -1.028e-01, -3.842e-01, 2.114e-01, 1.249e-01, 9.764e-02, 4.238e-01, -5.361e-02) * s0_3;
	r += M4(5.194e-01, 8.189e-02, 1.723e-01, -1.113e+00, 1.732e-01, 4.863e-01, -9.781e-02, 1.720e-01, -5.167e-01, -1.566e-01, -4.133e-01, 6.826e-02, 5.912e-01, 5.328e-01, 2.297e-01, 6.854e-01) * s0_4;
	r += M4(1.284e-01, -2.370e-01, -1.177e-01, -3.301e-02, 6.072e-02, 4.059e-02, 6.162e-02, 2.806e-02, -5.850e-02, -1.995e-02, 2.072e-02, 6.385e-02, -5.252e-02, 6.686e-01, -5.609e-01, 3.831e-01) * s0_5;
	r += M4(-7.803e-02, -1.028e-01, -8.653e-02, -1.054e-02, 2.799e-02, -5.448e-02, 5.163e-02, -3.364e-02, -7.672e-02, -2.046e-01, -1.989e-01, 2.781e-02, 2.778e-02, 2.788e-01, 2.302e-01, -1.002e-01) * s0_6;
	r += M4(-8.765e-03, -1.165e-01, 1.381e-02, -2.505e-02, -3.767e-02, 1.790e-01, 1.665e-01, 2.992e-03, -4.450e-02, -2.685e-01, -2.653e-01, 1.146e-01, 5.606e-02, 9.971e-01, 1.859e-01, 6.293e-02) * s0_7;
	r += M4(-1.769e-01, 1.142e-01, -2.114e-01, 6.633e-02, 3.635e-02, 7.025e-02, 1.026e-01, 2.214e-02, -2.035e-01, -1.227e-01, -2.132e-01, 1.845e-01, 3.000e-01, 4.733e-01, -5.192e-02, -2.412e-01) * s0_8;
	r += M4(-2.773e-02, 1.959e-02, -2.701e-02, -1.328e-02, 2.513e-05, -2.652e-01, -2.551e-01, -4.325e-02, 1.228e-01, 7.738e-02, 1.718e-01, -4.019e-02, -2.811e-02, -9.973e-03, -9.447e-02, 3.010e-02) * s1_0;
	r += M4(2.605e-02, 3.363e-02, -6.163e-03, 3.771e-02, -1.059e-01, -2.906e-01, -4.424e-01, 9.255e-02, 1.516e-01, 7.934e-02, -1.095e-01, 8.210e-02, -5.457e-02, -6.445e-02, 5.908e-02, -2.119e-02) * s1_1;
	r += M4(1.137e-01, -5.746e-02, 5.436e-02, -6.895e-03, 1.849e-01, -1.161e-01, -1.018e-02, -1.787e-01, 2.318e-01, 1.149e-01, 2.192e-01, -2.042e-02, -2.027e-01, -2.725e-02, -1.396e-01, 2.538e-02) * s1_2;
	r += M4(6.498e-02, -2.392e-02, -3.852e-02, -1.328e-02, -1.864e-01, -2.136e-01, -1.234e-01, 5.463e-02, -2.553e-02, 1.134e-01, -5.474e-02, -4.376e-02, 3.285e-02, -1.150e-01, -1.893e-02, 1.338e-02) * s1_3;
	r += M4(-1.394e-01, 1.305e-01, 1.664e-01, -1.932e-01, -2.327e-01, 3.051e-01, -5.002e-01, 6.505e-01, -1.626e-01, -1.878e-01, -2.509e-01, 1.450e-01, 9.680e-02, -8.817e-03, 6.529e-02, 4.170e-01) * s1_4;
	r += M4(-7.706e-02, 2.030e-01, 4.053e-01, 2.979e-02, 6.365e-02, -2.901e-01, -2.243e-02, -4.089e-02, 4.550e-02, -1.401e-01, 1.386e-01, -2.196e-02, -2.880e-01, 1.968e-01, -3.330e-01, 2.529e-01) * s1_5;
	r += M4(6.917e-03, -4.184e-02, -7.590e-02, 1.311e-02, -4.800e-02, -2.143e-01, -2.356e-01, -7.699e-02, 1.440e-01, 3.206e-02, 1.161e-01, -1.184e-01, -4.425e-02, 6.763e-02, 1.617e-03, 1.614e-02) * s1_6;
	r += M4(1.603e-02, -2.143e-01, -1.826e-02, -3.749e-02, -4.296e-02, -1.577e-01, -2.192e-01, -8.307e-02, 8.811e-02, -1.363e-01, 4.087e-02, -3.852e-03, -1.560e-01, 2.537e-01, -1.323e-01, 1.106e-01) * s1_7;
	r += M4(6.997e-02, -3.934e-02, 1.013e-01, 1.458e-02, 5.800e-02, -1.316e-01, -4.877e-02, -9.139e-02, -5.703e-02, 6.325e-02, 4.796e-02, 2.739e-02, 1.132e-01, 1.994e-02, 4.709e-02, -7.251e-02) * s1_8;
	r += V4(-7.039e-02, -8.336e-03, -3.354e-02, 3.799e-02);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv5_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv7
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(7.164e-02, 2.732e-02, -6.192e-02, 3.664e-02, -5.217e-02, -1.194e-03, 5.737e-03, -8.027e-02, 2.465e-02, 1.661e-02, -1.395e-02, 5.714e-02, -2.223e-02, 7.446e-02, -7.781e-02, 4.887e-02) * s0_0;
	r += M4(-3.465e-04, -2.082e-02, -1.300e-02, -4.281e-02, -2.134e-01, -5.716e-02, -2.353e-01, 7.793e-02, 5.303e-02, 4.653e-02, 1.292e-01, 1.203e-01, 6.838e-02, -8.958e-02, -5.008e-03, 1.120e-01) * s0_1;
	r += M4(-8.802e-02, 1.655e-02, 1.199e-02, -4.528e-02, 9.847e-02, -2.569e-02, 1.545e-01, 1.014e-01, 8.520e-02, -9.449e-02, 6.314e-02, -7.071e-02, 4.448e-02, -5.837e-02, -7.633e-02, 7.358e-03) * s0_2;
	r += M4(4.700e-02, -8.567e-03, 3.043e-02, 1.131e-03, -4.702e-02, 1.385e-01, 2.168e-02, 1.413e-01, -7.528e-02, 4.340e-02, 1.151e-02, 3.048e-02, 7.926e-02, -2.417e-01, -1.821e-01, 7.119e-03) * s0_3;
	r += M4(-1.420e-01, -1.016e-01, -5.272e-01, 1.625e-02, -7.821e-01, 8.610e-02, 1.899e-01, -6.557e-01, 4.092e-01, 3.545e-01, -1.203e-01, 3.707e-01, 4.022e-01, -5.551e-01, -6.170e-01, -8.178e-01) * s0_4;
	r += M4(-1.823e-02, 1.607e-01, -9.066e-02, 9.262e-02, 5.953e-03, 2.276e-03, 1.616e-01, -6.971e-02, -2.244e-01, -8.813e-03, 7.400e-02, 7.639e-02, -1.465e-01, 2.191e-01, -4.352e-01, -7.098e-02) * s0_5;
	r += M4(-2.185e-02, -3.366e-02, -4.939e-03, -1.759e-01, 5.006e-03, -3.584e-03, -7.952e-02, -5.835e-02, -7.460e-02, -3.269e-02, -4.773e-02, -4.373e-02, 1.291e-01, -3.061e-02, 1.452e-01, 2.746e-02) * s0_6;
	r += M4(3.719e-01, -7.276e-02, -2.660e-03, 5.933e-02, 4.595e-02, -1.368e-02, -6.991e-02, 3.822e-02, -2.506e-02, 6.298e-02, 5.571e-02, 3.553e-01, 6.302e-02, -8.596e-02, 1.117e-01, -1.558e-01) * s0_7;
	r += M4(1.779e-01, -5.333e-03, -5.312e-02, -1.083e-02, -3.304e-02, -3.502e-02, -3.389e-02, 2.833e-02, -8.978e-02, 8.324e-02, 8.222e-02, -7.812e-03, -3.236e-02, 7.055e-02, 5.317e-02, -7.730e-02) * s0_8;
	r += M4(-2.809e-02, 4.691e-02, 1.187e-01, 3.611e-02, -1.234e-02, 5.249e-03, -1.768e-02, -9.421e-02, 4.707e-02, 3.510e-02, 2.720e-02, 6.856e-02, 9.156e-03, 3.673e-02, 8.250e-03, 3.356e-02) * s1_0;
	r += M4(-2.809e-03, 8.008e-02, 1.359e-01, -3.894e-02, -1.903e-01, 1.125e-01, 4.734e-02, 6.574e-02, 4.032e-02, -2.281e-02, 1.499e-01, 2.363e-02, 7.589e-02, 1.654e-02, 1.012e-01, 6.940e-02) * s1_1;
	r += M4(-1.516e-01, 1.156e-01, 2.278e-01, 5.426e-02, -1.985e-02, 4.442e-02, 1.132e-01, 1.268e-01, 8.931e-02, -1.445e-01, -1.429e-01, -1.274e-01, 5.896e-02, -7.824e-02, -2.969e-02, -5.308e-02) * s1_2;
	r += M4(-2.194e-02, 1.544e-02, 3.870e-02, 3.771e-02, -4.666e-02, -4.240e-02, -1.298e-01, 1.032e-02, 1.621e-02, 6.227e-05, 3.140e-02, 1.461e-02, -3.215e-02, 1.031e-02, 4.719e-02, 2.403e-02) * s1_3;
	r += M4(-1.646e-01, -1.752e-02, -1.039e-01, -4.006e-02, -5.747e-01, 2.112e-01, 9.226e-02, -1.282e-01, 3.350e-01, -1.007e-01, -6.322e-02, 7.238e-02, 1.073e-01, -3.670e-01, -3.951e-01, -7.008e-02) * s1_4;
	r += M4(-3.162e-01, 2.296e-01, 1.147e-01, 1.055e-01, -5.905e-03, 7.411e-02, 5.241e-02, -2.334e-02, 1.522e-01, -4.821e-02, -8.662e-02, -4.329e-03, -1.728e-01, 1.441e-01, -8.038e-02, 6.286e-02) * s1_5;
	r += M4(-4.278e-02, 1.066e-01, 1.209e-01, 6.074e-02, 9.172e-02, 9.963e-03, 9.290e-03, 3.008e-02, 1.412e-02, -2.427e-03, 1.441e-02, 2.655e-02, 2.085e-02, -3.804e-02, 6.273e-03, -4.426e-02) * s1_6;
	r += M4(-2.112e-02, 2.054e-01, 1.175e-01, 5.759e-02, 3.114e-02, 1.848e-02, -2.120e-02, 5.319e-02, -6.237e-02, -5.174e-02, -3.171e-02, -8.428e-02, 9.941e-02, -3.429e-02, -3.823e-02, -8.828e-02) * s1_7;
	r += M4(-2.562e-02, 8.576e-02, 5.879e-02, 6.770e-02, -1.674e-02, -3.892e-02, -1.052e-02, 2.734e-02, 2.578e-03, -7.986e-03, 3.119e-03, -3.966e-02, 1.146e-01, 5.294e-03, 5.611e-04, 5.731e-02) * s1_8;
	r += V4(-7.392e-03, 1.102e-02, 7.402e-03, 5.508e-03);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv6_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-conv8
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-3.114e-02, 3.980e-02, -6.661e-04, -1.170e-02, 4.369e-02, 2.388e-02, -3.772e-02, 8.797e-03, 1.794e-02, -8.512e-02, 1.355e-02, -7.536e-02, -2.217e-01, 3.987e-03, 7.756e-02, 1.028e-01) * s0_0;
	r += M4(-3.882e-02, -1.064e-02, -6.656e-02, 8.033e-02, -4.850e-02, 1.810e-03, 1.873e-01, 4.723e-02, 6.218e-02, 7.983e-03, -4.490e-02, 1.236e-02, -3.815e-02, 1.350e-01, -2.227e-01, -4.061e-02) * s0_1;
	r += M4(1.281e-02, -1.739e-02, -6.812e-02, 1.661e-02, 8.767e-02, -1.969e-02, -2.495e-02, -2.948e-02, -3.214e-03, 2.028e-02, 4.181e-02, -2.315e-02, -1.509e-01, -2.091e-02, 3.050e-02, 6.827e-02) * s0_2;
	r += M4(-1.915e-01, 9.196e-03, 7.726e-02, 1.015e-01, -9.336e-02, 7.568e-03, 2.814e-03, 5.019e-02, 1.960e-01, -2.826e-02, -6.981e-02, -1.162e-02, 3.147e-01, -6.497e-02, -7.057e-02, -1.628e-01) * s0_3;
	r += M4(-5.463e-02, -4.675e-02, 3.721e-01, -1.981e-01, 2.169e-01, -4.482e-01, 4.910e-02, -5.484e-01, -4.720e-01, 1.406e-01, -4.473e-02, -5.452e-02, 2.638e-01, -1.060e-01, 2.247e-01, -4.431e-02) * s0_4;
	r += M4(4.939e-02, 1.968e-03, -4.669e-02, 2.469e-02, 5.604e-02, 8.567e-02, 2.654e-02, -1.952e-01, 5.266e-03, -6.301e-02, -2.232e-02, 9.394e-02, -3.014e-02, -2.844e-02, 2.937e-02, -6.042e-02) * s0_5;
	r += M4(-2.181e-02, 1.331e-02, -5.228e-02, 3.336e-02, -1.897e-01, 3.940e-02, 9.364e-02, 9.551e-02, 2.763e-01, -6.670e-02, -1.441e-01, -8.031e-02, 5.314e-03, -2.079e-02, 1.205e-02, -2.887e-02) * s0_6;
	r += M4(2.001e-02, -1.949e-02, -1.733e-01, 4.219e-02, -1.929e-01, 4.391e-02, -1.196e-01, 1.066e-01, 1.714e-01, -1.470e-01, 2.052e-01, -2.427e-01, 2.571e-02, 1.716e-02, 8.335e-02, -4.921e-02) * s0_7;
	r += M4(3.259e-02, 1.796e-03, -5.569e-02, -2.670e-02, -7.392e-02, 5.583e-02, -1.588e-02, 8.423e-02, 9.204e-02, -2.543e-02, -2.142e-01, -2.163e-02, -2.428e-02, 3.574e-03, 5.660e-02, 2.453e-02) * s0_8;
	r += M4(-3.749e-02, 4.381e-02, 5.985e-02, -2.334e-02, -3.478e-02, 6.273e-02, -3.600e-02, 1.249e-02, 2.149e-02, -3.060e-02, -1.569e-02, -5.415e-03, 2.462e-02, -4.985e-02, -2.347e-02, 5.062e-04) * s1_0;
	r += M4(7.092e-03, 3.992e-02, -1.345e-02, 1.032e-01, -1.348e-01, -3.876e-02, 1.460e-01, 2.509e-02, 8.696e-03, 3.698e-02, -5.937e-02, 1.759e-02, 3.278e-02, 2.903e-02, 4.582e-03, -8.196e-02) * s1_1;
	r += M4(-6.391e-02, -1.429e-02, -2.869e-02, 7.371e-03, 1.031e-01, 1.037e-02, -5.141e-02, -8.802e-03, -3.890e-02, -6.964e-03, -1.209e-02, 2.601e-02, -2.019e-02, -1.118e-02, 7.954e-02, -3.442e-02) * s1_2;
	r += M4(-1.554e-01, -1.950e-01, 1.425e-01, 5.554e-02, -3.813e-01, -1.452e-02, 8.560e-02, 1.100e-01, 2.531e-01, 7.055e-02, -1.038e-01, -1.538e-02, 1.345e-01, -1.519e-01, 4.133e-02, -9.208e-02) * s1_3;
	r += M4(-5.431e-02, 7.765e-02, 1.028e+00, -5.694e-01, 1.395e-01, -2.017e-01, 3.199e-01, -1.483e-01, -1.821e-01, -5.247e-02, 3.879e-02, 4.125e-02, 7.994e-02, -7.961e-02, -3.388e-01, 2.036e-01) * s1_4;
	r += M4(5.164e-02, -4.936e-02, -1.811e-01, 1.100e-01, 1.494e-01, 7.645e-02, -4.568e-02, -8.635e-02, 8.517e-02, -2.761e-02, -4.409e-02, -2.810e-02, -6.346e-02, 9.537e-03, 1.881e-01, -8.024e-02) * s1_5;
	r += M4(-9.889e-02, 2.473e-02, -1.478e-02, 4.186e-02, 3.741e-02, -5.891e-03, -1.354e-01, 6.640e-02, 4.745e-02, 7.496e-02, -8.700e-02, 3.629e-02, 4.830e-03, -2.230e-02, 6.217e-02, -2.289e-02) * s1_6;
	r += M4(-1.543e-02, 7.176e-02, -3.563e-01, 9.825e-02, 6.422e-02, -1.384e-02, -1.567e-01, 7.656e-03, 8.813e-02, -2.152e-01, 2.943e-01, -1.470e-01, -1.454e-02, -3.580e-02, 2.220e-01, -4.109e-02) * s1_7;
	r += M4(3.217e-02, -2.431e-02, -5.800e-02, -5.342e-02, 2.322e-02, 4.876e-02, 2.407e-02, -6.248e-02, -2.589e-02, 1.145e-02, -1.980e-02, 2.631e-02, 4.943e-03, 4.888e-04, 1.975e-02, 2.578e-02) * s1_8;
	r += V4(1.162e-03, -2.538e-04, -3.402e-03, -8.477e-04);
	return vec4(r);
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv7_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-out
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
vec4 f0(V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = V4(0.0);
	r += M4(-1.043e-01, -1.354e-02, 3.766e-02, 1.254e-02, -2.769e-03, -1.075e-02, 3.494e-02, 1.725e-02, -1.678e-01, 8.428e-02, 1.028e-01, 5.921e-02, 2.659e-02, 1.104e-02, -4.889e-04, -5.388e-03) * s0_0;
	r += M4(-8.668e-02, -1.585e-01, 1.368e-01, 8.386e-02, -1.587e-01, -5.489e-02, 3.968e-02, 4.216e-02, -4.978e-04, -3.428e-01, 7.690e-02, 8.344e-02, 5.476e-02, 3.195e-02, -7.009e-03, -3.189e-03) * s0_1;
	r += M4(6.129e-02, -5.166e-02, 1.971e-02, 8.571e-02, 3.090e-02, -1.274e-01, 8.858e-02, 8.041e-02, -5.570e-03, 3.535e-02, -2.191e-02, -7.878e-03, -8.049e-03, 3.777e-02, -1.242e-02, -5.145e-03) * s0_2;
	r += M4(-8.837e-02, 5.454e-02, -2.271e-01, -2.791e-04, -1.361e-02, 5.192e-02, 5.210e-03, 2.179e-02, -8.659e-04, -4.005e-02, -2.983e-01, 1.388e-02, 1.346e-01, -1.124e-02, -1.027e-01, -5.644e-02) * s0_3;
	r += M4(8.769e-01, 3.486e-01, 1.561e-01, -1.324e-01, 2.993e-01, 1.105e-01, -4.512e-02, -8.047e-03, 1.765e-01, 2.125e-01, -2.180e-02, -3.839e-01, 5.211e-01, 5.971e-01, 7.127e-03, -7.088e-02) * s0_4;
	r += M4(-1.018e-01, 2.843e-01, -1.236e-01, -1.470e-01, -9.632e-02, 1.544e-02, -4.531e-02, -1.453e-01, -3.628e-02, -2.004e-02, -4.038e-02, -1.240e-02, -3.062e-02, 8.609e-02, -5.609e-02, 5.829e-03) * s0_5;
	r += M4(-2.136e-02, -2.040e-02, -9.501e-02, 6.044e-03, -1.732e-02, -2.382e-02, -8.457e-02, -1.235e-02, -5.359e-03, 1.565e-02, -4.554e-02, -2.810e-02, -7.780e-02, 2.064e-02, 6.797e-03, -2.514e-02) * s0_6;
	r += M4(-1.538e-01, -6.553e-02, 1.919e-01, -2.244e-02, -8.089e-02, -1.920e-02, 1.010e-02, -5.188e-02, -4.330e-02, -4.049e-02, -1.986e-02, -1.805e-02, -1.304e-01, -9.573e-02, 1.198e-01, 2.445e-01) * s0_7;
	r += M4(-3.277e-03, -5.229e-02, -2.683e-02, 1.059e-01, 4.035e-02, 2.428e-02, -6.906e-02, -4.359e-02, 1.303e-02, 1.432e-02, -9.494e-03, -2.084e-02, 2.568e-02, -1.398e-02, -1.640e-02, -2.204e-02) * s0_8;
	r += M4(-8.636e-02, -1.931e-02, 1.828e-02, 2.258e-03, -4.808e-02, 7.993e-02, 5.905e-02, 5.409e-02, -3.064e-02, -2.077e-03, 3.115e-02, -6.269e-03, -1.179e-01, -2.108e-02, -4.757e-03, 6.362e-03) * s1_0;
	r += M4(2.424e-02, -6.704e-02, 1.532e-02, 3.577e-02, 2.571e-01, -1.983e-01, -4.110e-02, -1.001e-01, -1.601e-02, -7.575e-02, 3.160e-02, 6.545e-02, -1.189e-01, 2.050e-02, 2.124e-02, 5.797e-02) * s1_1;
	r += M4(8.817e-03, 2.016e-04, 1.006e-02, -8.057e-03, 2.620e-02, -2.048e-01, 9.843e-02, -2.269e-02, 1.826e-02, 3.460e-02, 2.851e-03, -7.774e-04, -3.399e-03, 1.035e-02, -2.618e-02, 7.146e-03) * s1_2;
	r += M4(-1.420e-02, -3.034e-02, -1.283e-01, -3.546e-02, -1.565e-01, 1.606e-01, -1.792e-01, 1.587e-01, -1.827e-02, -1.758e-02, -1.476e-01, -1.985e-02, 9.839e-02, -9.921e-02, -3.377e-02, -1.189e-01) * s1_3;
	r += M4(4.345e-01, 2.860e-01, 1.445e-01, -2.165e-02, 3.627e-01, -4.932e-01, 9.003e-01, -1.201e-01, 1.526e-01, 1.238e-01, -1.304e-01, -2.725e-01, 1.820e-01, 7.536e-01, -1.202e-01, 3.939e-01) * s1_4;
	r += M4(-3.053e-02, 1.395e-01, -4.997e-02, 9.618e-03, -1.314e-01, -1.866e-01, -1.323e-01, -1.643e-01, -3.891e-02, -9.796e-04, -1.685e-02, -5.875e-03, -2.054e-02, -5.623e-02, 3.403e-04, -7.655e-02) * s1_5;
	r += M4(-1.044e-02, -4.083e-03, -4.539e-02, -4.354e-02, 8.785e-03, -3.574e-02, -9.329e-03, 2.842e-02, -1.860e-02, 6.138e-03, -3.181e-02, -2.331e-02, -3.918e-02, 2.744e-02, -1.056e-01, -3.353e-02) * s1_6;
	r += M4(-1.160e-01, -3.913e-02, 9.646e-02, 6.865e-02, 1.882e-02, 2.704e-02, -7.533e-02, -2.419e-01, -5.946e-02, -3.404e-02, 1.247e-02, 3.476e-02, -7.127e-02, -8.745e-02, -1.985e-02, 4.786e-02) * s1_7;
	r += M4(3.242e-02, 4.634e-03, 1.304e-02, 9.090e-02, 3.237e-02, 7.788e-02, -5.986e-03, -3.927e-02, 2.704e-02, 6.175e-03, -1.157e-02, -2.326e-02, 7.859e-03, -1.004e-03, -2.400e-03, -1.215e-02) * s1_8;
	r += V4(6.540e-04, 7.113e-04, -6.372e-04, -6.574e-04);
	return vec4(tanh(r));
	
}
void hook() {
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + ivec2(gl_LocalInvocationID.xy);
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	vec2 pt = conv8_pt;
	V4 s0_0 = l0(-1, -1);
	V4 s0_1 = l0(0, -1);
	V4 s0_2 = l0(1, -1);
	V4 s0_3 = l0(-1, 0);
	V4 s0_4 = l0(0, 0);
	V4 s0_5 = l0(1, 0);
	V4 s0_6 = l0(-1, 1);
	V4 s0_7 = l0(0, 1);
	V4 s0_8 = l0(1, 1);
	V4 s1_0 = -max(-s0_0, V4(0.0));
	V4 s1_1 = -max(-s0_1, V4(0.0));
	V4 s1_2 = -max(-s0_2, V4(0.0));
	V4 s1_3 = -max(-s0_3, V4(0.0));
	V4 s1_4 = -max(-s0_4, V4(0.0));
	V4 s1_5 = -max(-s0_5, V4(0.0));
	V4 s1_6 = -max(-s0_6, V4(0.0));
	V4 s1_7 = -max(-s0_7, V4(0.0));
	V4 s1_8 = -max(-s0_8, V4(0.0));
	s0_0 = max(s0_0, V4(0.0));
	s0_1 = max(s0_1, V4(0.0));
	s0_2 = max(s0_2, V4(0.0));
	s0_3 = max(s0_3, V4(0.0));
	s0_4 = max(s0_4, V4(0.0));
	s0_5 = max(s0_5, V4(0.0));
	s0_6 = max(s0_6, V4(0.0));
	s0_7 = max(s0_7, V4(0.0));
	s0_8 = max(s0_8, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0(s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8));
}


//!DESC CuNNy-8x4C-DS-shuffle
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

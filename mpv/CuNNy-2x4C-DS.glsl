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
	r += V4(-2.912e-02, -5.751e-02, -3.081e-03, 5.072e-01) * s0[y+0][x+0];
	r += V4(1.706e-02, 8.086e-02, 2.693e-02, -4.444e-01) * s0[y+0][x+1];
	r += V4(-2.146e-02, -5.291e-02, -4.965e-02, -1.094e-02) * s0[y+0][x+2];
	r += V4(3.887e-02, -7.894e-02, -8.203e-02, -2.203e-02) * s0[y+1][x+0];
	r += V4(4.658e-01, 5.545e-01, 4.665e-01, -9.256e-02) * s0[y+1][x+1];
	r += V4(-5.655e-03, 6.427e-02, 4.165e-02, 7.616e-02) * s0[y+1][x+2];
	r += V4(-2.717e-02, -1.809e-02, 9.302e-02, 3.926e-03) * s0[y+2][x+0];
	r += V4(8.938e-04, -5.015e-02, -5.129e-01, 3.679e-02) * s0[y+2][x+1];
	r += V4(-1.553e-02, -3.180e-03, 9.675e-03, -4.040e-02) * s0[y+2][x+2];
	r += V4(-7.000e-03, -2.417e-01, 8.025e-03, -1.242e-02);
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
	r += M4(-4.217e-02, 7.674e-02, 8.485e-02, -2.100e-02, 6.107e-02, 7.930e-02, 6.881e-02, -1.646e-01, -1.214e-01, -1.248e-01, -4.155e-01, -4.189e-01, -2.750e-03, -7.978e-03, 7.788e-02, -3.669e-03) * s0[y+0][x+0];
	r += M4(-1.177e-01, 6.863e-02, 1.000e-02, 1.376e-01, -4.920e-02, 4.873e-02, -8.294e-02, -1.703e-01, 1.082e-02, 1.283e-01, -2.693e-01, -9.740e-01, -1.813e-02, 5.101e-02, -3.370e-02, -1.940e-02) * s0[y+0][x+1];
	r += M4(7.398e-02, 1.829e-02, -1.690e-01, 6.309e-02, -3.696e-01, -1.265e-01, -5.462e-03, -1.723e-02, 7.962e-02, -1.103e-03, 2.627e-01, -1.382e-02, -6.117e-02, -9.436e-02, -4.454e-02, 6.325e-02) * s0[y+0][x+2];
	r += M4(-1.528e-02, -2.093e-01, -1.185e-01, -3.674e-02, -1.061e-01, 3.096e-01, -6.248e-02, 3.974e-02, 4.652e-02, 2.282e-01, 4.004e-02, -5.970e-02, -2.581e-02, -1.504e-01, -1.511e-01, -1.782e-02) * s0[y+1][x+0];
	r += M4(-5.348e-02, -1.138e-01, 3.213e-01, 4.852e-02, -1.948e-01, -4.522e-01, 3.343e-01, 8.464e-01, 3.240e-02, 4.729e-02, -3.148e-01, -5.735e-02, 7.346e-03, -4.175e-01, -5.971e-01, -6.499e-01) * s0[y+1][x+1];
	r += M4(-1.353e-01, -1.589e-02, 5.715e-02, -7.668e-03, -2.196e-01, 1.028e-01, -5.823e-02, -2.150e-01, -2.572e-01, 1.163e-01, -5.217e-03, -1.462e-01, 1.845e-01, -5.584e-02, 5.136e-01, 8.340e-03) * s0[y+1][x+2];
	r += M4(9.103e-03, 2.991e-01, -9.022e-02, -1.695e-01, 3.976e-02, -1.559e-01, 2.003e-01, 5.300e-02, -9.107e-03, 4.606e-02, 8.020e-02, 5.021e-02, -4.044e-02, -6.323e-02, 7.565e-05, 7.925e-02) * s0[y+2][x+0];
	r += M4(-1.647e-01, 4.127e-02, -1.012e-02, 3.065e-02, 1.701e-01, -2.608e-02, -2.912e-01, -2.250e-01, -9.382e-03, 1.405e-02, -2.530e-02, -4.314e-02, -1.968e-01, 2.253e-01, -5.182e-01, -4.822e-01) * s0[y+2][x+1];
	r += M4(-1.772e-01, -2.231e-01, -9.870e-02, 1.707e-01, -6.366e-02, 1.938e-01, -5.533e-02, -2.000e-01, 8.722e-03, 2.188e-02, 3.307e-02, 6.590e-02, -2.419e-01, 2.764e-01, 3.071e-01, -1.188e-01) * s0[y+2][x+2];
	r += M4(-2.248e-02, 7.756e-01, 2.641e+00, 1.504e+00, 4.438e-02, -7.299e-02, 5.578e-02, -6.714e-02, -4.316e-02, 6.197e-01, 4.300e-01, 1.187e-01, 5.583e-03, 1.193e-02, 7.969e-03, -7.529e-02) * s1[y+0][x+0];
	r += M4(9.451e-02, -8.982e-01, 4.841e+00, 4.939e+00, -1.356e-01, -8.339e-02, -1.304e-01, -1.654e-01, 3.035e-02, 5.282e-01, 1.841e-01, -3.293e-01, -6.397e-03, 1.353e-02, 2.704e-02, 2.097e-02) * s1[y+0][x+1];
	r += M4(-3.888e-02, -1.727e-01, 2.371e+00, 2.085e+00, -3.183e-01, -1.066e-01, 1.799e-01, 7.962e-02, 5.641e-01, -1.780e-01, -2.007e-01, 2.815e-01, -6.467e-02, -7.860e-02, -5.052e-02, 3.745e-02) * s1[y+0][x+2];
	r += M4(2.943e-02, -2.425e+00, 1.444e+00, 4.501e+00, -1.131e-01, 1.424e-01, -3.896e-01, -1.304e-01, 4.156e-02, -3.084e-02, 3.740e-01, 3.680e-01, -2.356e-03, 8.858e-02, 4.740e-03, -4.941e-02) * s1[y+1][x+0];
	r += M4(8.711e-01, -3.441e+00, 2.345e+00, 5.542e+00, -1.547e-01, -1.601e-01, 2.310e-01, 2.686e-01, -3.788e-02, -4.841e-01, 3.311e-01, 8.607e-01, 3.514e-02, 3.109e-01, 1.284e-01, 1.596e-01) * s1[y+1][x+1];
	r += M4(1.966e+00, -9.205e-01, 2.648e+00, 3.144e+00, -2.126e-03, 1.316e-01, 5.719e-02, -9.491e-02, -8.891e-02, -4.421e-01, -2.911e-01, 2.426e-01, 2.408e-01, -3.584e-01, -1.625e-03, 4.678e-01) * s1[y+1][x+2];
	r += M4(1.663e-01, 1.405e+00, 2.813e+00, 1.925e+00, 4.217e-02, -2.149e-02, 3.638e-01, 1.631e-01, -2.409e-04, -6.628e-02, -3.738e-02, -1.181e-01, 4.749e-03, -2.198e-02, 1.262e-01, 7.766e-02) * s1[y+2][x+0];
	r += M4(-2.069e-02, -4.053e-01, 3.603e+00, 4.139e+00, 1.342e-01, 6.899e-02, -2.392e-01, -2.339e-01, 5.725e-02, 7.984e-02, -3.637e-02, -6.674e-02, 7.564e-03, -1.439e-01, 2.705e-01, 2.436e-01) * s1[y+2][x+1];
	r += M4(7.452e-01, 1.234e+00, 1.704e+00, 1.754e-01, -9.254e-02, 1.402e-01, -3.879e-02, -1.267e-01, 1.099e-01, 3.094e-02, 1.342e-02, -1.227e-01, 7.601e-02, -5.275e-01, -1.549e-01, 6.038e-01) * s1[y+2][x+2];
	r += V4(3.964e-01, -7.053e-03, 3.330e-02, -6.100e-03);
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
	r += M4(1.351e-02, -4.695e-02, 4.157e-02, -3.299e-02, -6.599e-02, 1.311e-01, -1.572e-01, 2.502e-02, 6.107e-02, -1.144e-01, 6.972e-02, 8.024e-02, -1.958e-01, 1.474e-01, -1.092e-01, -1.924e-01) * s0[y+0][x+0];
	r += M4(-3.634e-03, 8.180e-02, -5.465e-02, -4.844e-02, 9.637e-04, -9.033e-02, 9.101e-03, 3.305e-01, -1.103e-02, -2.659e-02, 6.670e-03, 9.679e-02, 4.092e-01, 6.099e-02, -9.599e-02, -4.523e-02) * s0[y+0][x+1];
	r += M4(-2.732e-02, -3.466e-02, -5.479e-03, 5.637e-02, -1.573e-01, -8.284e-02, -2.664e-02, 2.379e-01, 1.378e-01, -3.567e-02, 2.202e-02, -5.782e-02, 2.247e-01, 3.491e-02, -1.151e-01, 1.150e-03) * s0[y+0][x+2];
	r += M4(-1.207e-02, -1.525e-02, -3.980e-02, 1.007e-01, 1.355e-01, -1.980e-02, -1.468e-01, -2.479e-01, -1.657e-01, -3.816e-02, 4.530e-02, 2.646e-01, -1.385e-01, 9.385e-02, -1.182e-01, -2.408e-01) * s0[y+1][x+0];
	r += M4(8.982e-02, 2.282e-03, -5.925e-02, -1.143e-01, 8.849e-02, 1.939e-01, 3.174e-01, 1.328e-01, 1.880e-01, -3.818e-01, 1.937e-01, -2.263e-01, 2.307e-01, -2.443e-02, 1.881e-01, 4.457e-02) * s0[y+1][x+1];
	r += M4(-6.760e-02, 1.993e-02, 2.119e-02, 1.548e-02, 2.979e-01, -5.765e-01, 5.048e-01, 3.916e-01, -2.805e-02, 1.174e-01, -7.010e-02, -2.195e-01, 2.597e-01, -2.829e-01, 5.147e-02, 2.056e-01) * s0[y+1][x+2];
	r += M4(-1.028e-02, 5.546e-02, -2.147e-02, -6.793e-02, 8.715e-02, 1.058e-02, -7.603e-02, -2.629e-01, -5.439e-02, 7.044e-03, -6.443e-02, -1.832e-02, -4.648e-02, 2.148e-02, 1.394e-01, -3.565e-03) * s0[y+2][x+0];
	r += M4(-2.929e-02, -7.068e-02, 3.082e-02, 8.472e-02, -6.373e-02, -2.048e-01, 2.078e-01, -3.721e-01, -5.980e-03, 4.691e-02, -2.901e-01, -1.028e-01, -3.876e-02, -2.452e-01, 1.055e-01, -1.548e-03) * s0[y+2][x+1];
	r += M4(3.427e-02, 9.729e-03, 7.553e-03, 1.203e-02, -2.007e-01, -3.498e-02, 2.157e-01, 1.132e-01, 1.645e-01, -2.552e-02, -1.823e-01, -1.618e-01, -1.411e-01, -1.690e-01, 1.505e-01, 1.637e-01) * s0[y+2][x+2];
	r += M4(-9.789e-02, -1.067e+00, 1.811e+00, 4.099e-02, -4.581e-02, 1.284e-01, -2.915e-02, -3.111e-02, 8.892e-02, -1.347e-01, 5.604e-02, 1.339e-01, -5.710e-02, 6.372e-02, -9.050e-02, -7.589e-02) * s1[y+0][x+0];
	r += M4(3.995e-01, -6.754e-01, 9.334e-01, 3.205e-01, 9.398e-02, -6.455e-03, 1.712e-02, 4.602e-02, -9.623e-02, -1.080e-01, 2.519e-02, 8.560e-02, 1.548e-01, 1.163e-01, 1.199e-01, -8.281e-02) * s1[y+0][x+1];
	r += M4(7.234e-01, -3.730e-01, 7.443e-01, 1.505e-01, -1.151e-01, -3.373e-02, -2.675e-02, 2.163e-01, -3.685e-02, -1.704e-02, -8.374e-02, -5.227e-02, -8.414e-02, -5.959e-03, 6.327e-02, 9.912e-02) * s1[y+0][x+2];
	r += M4(-9.298e-01, 1.458e+00, 2.729e+00, -2.179e+00, 6.054e-02, 1.022e-01, -5.707e-02, -1.194e-01, -3.809e-02, -8.021e-02, -1.272e-02, 4.099e-01, -1.265e-03, 1.479e-01, 4.065e-02, -3.890e-01) * s1[y+1][x+0];
	r += M4(-1.040e+00, 4.146e-01, 1.598e+00, -9.876e-01, 5.720e-02, -2.824e-04, 2.718e-01, 8.083e-02, -4.248e-01, 6.474e-02, -5.988e-01, 1.446e-01, 3.125e-01, -3.503e-01, 4.967e-02, 3.252e-01) * s1[y+1][x+1];
	r += M4(6.260e-01, -5.808e-01, 1.050e+00, -3.274e-01, -1.945e-01, -4.706e-02, 8.863e-02, 5.332e-01, 8.557e-03, 1.704e-01, 1.037e-01, -2.694e-01, 2.970e-01, -4.111e-01, 3.096e-01, 1.909e-01) * s1[y+1][x+2];
	r += M4(5.556e-01, 5.020e-01, 1.620e+00, -1.626e+00, 9.457e-02, -5.186e-02, 6.848e-03, -1.286e-01, -5.732e-02, 1.177e-02, -1.028e-01, 2.688e-01, 7.426e-02, 1.644e-02, 3.824e-02, -3.753e-01) * s1[y+2][x+0];
	r += M4(6.610e-01, -4.321e-01, 1.256e+00, -4.828e-01, 9.979e-02, 7.798e-02, 7.252e-02, -2.375e-01, 1.244e-02, 1.255e-01, -1.647e-01, 6.329e-02, -4.670e-02, -3.018e-01, 2.529e-01, -3.174e-01) * s1[y+2][x+1];
	r += M4(4.640e-01, -7.581e-01, 6.116e-01, -6.088e-02, -1.046e-01, 1.039e-01, 2.021e-01, 1.594e-01, 1.213e-01, -1.393e-01, -1.813e-01, -2.203e-01, -1.543e-01, -4.682e-03, 1.879e-01, 1.521e-01) * s1[y+2][x+2];
	r += V4(9.427e-03, -3.060e-03, 4.080e-02, -4.764e-03);
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
	r += M4(2.241e-02, -6.590e-03, -4.826e-03, -1.208e-02, 5.922e-02, -4.439e-03, 1.032e-01, -9.451e-03, 5.234e-02, 2.134e-02, 4.739e-02, 1.812e-02, -2.818e-03, -1.728e-02, 7.222e-03, -1.455e-02) * s0[y+0][x+0];
	r += M4(-7.961e-03, 2.899e-02, 2.752e-02, 3.686e-02, -2.068e-01, -1.294e-01, 1.226e-02, 1.645e-01, -3.543e-02, 1.887e-02, 2.266e-02, 5.526e-02, 3.408e-01, 1.941e-02, -1.717e-01, -9.448e-02) * s0[y+0][x+1];
	r += M4(2.364e-04, -1.406e-02, -7.392e-03, -1.516e-02, -5.232e-02, -3.645e-02, -3.377e-02, -5.294e-02, -6.315e-04, -2.676e-02, 6.010e-03, -6.334e-03, -1.489e-01, 1.459e-01, -4.117e-02, -1.113e-01) * s0[y+0][x+2];
	r += M4(-3.509e-02, -1.291e-02, 1.831e-02, -8.699e-03, 3.748e-02, 1.135e-01, -2.417e-01, -1.496e-02, 8.295e-03, 1.278e-02, -5.727e-03, -3.021e-03, -1.248e-01, 1.826e-02, -1.052e-01, -1.290e-02) * s0[y+1][x+0];
	r += M4(2.043e-02, 4.673e-03, -3.311e-02, 1.159e-02, -1.309e-01, -2.280e-01, -5.190e-01, -8.149e-01, -2.086e-01, -8.520e-02, -1.636e-01, -8.659e-02, 1.773e-01, -3.448e-01, 9.135e-01, -1.144e-02) * s0[y+1][x+1];
	r += M4(1.899e-02, 1.097e-02, 6.854e-03, -1.126e-02, -2.643e-02, 5.610e-02, -4.882e-02, 6.093e-02, 9.023e-02, -1.338e-02, 3.682e-02, -2.888e-02, -4.092e-01, -1.189e-02, -3.252e-01, 4.836e-01) * s0[y+1][x+2];
	r += M4(7.289e-02, 3.143e-02, 3.103e-02, 3.674e-02, -5.187e-02, 3.498e-03, 1.397e-01, 9.783e-02, 5.180e-02, -3.772e-03, 6.538e-02, 1.188e-02, 3.873e-02, -2.985e-02, 9.787e-03, 7.312e-03) * s0[y+2][x+0];
	r += M4(-1.918e-01, -7.098e-02, -1.263e-01, -7.300e-02, -3.130e-02, -3.275e-02, 1.067e-01, 1.964e-01, 6.420e-03, 2.192e-02, -7.738e-02, -1.384e-02, 5.377e-03, -1.946e-02, -1.929e-01, -2.261e-01) * s0[y+2][x+1];
	r += M4(5.262e-02, -2.921e-03, 6.410e-02, 1.604e-02, 1.885e-02, -3.846e-02, 1.424e-02, -3.059e-02, 4.556e-02, 5.372e-02, 6.662e-02, 3.685e-02, 5.773e-02, 1.072e-01, -6.402e-02, -6.470e-02) * s0[y+2][x+2];
	r += M4(-6.169e-02, -5.467e-02, 1.616e-01, 4.492e-02, -4.598e-02, -4.628e-02, 1.009e-02, 7.788e-03, -1.462e-02, 2.210e-02, -6.768e-02, 9.131e-03, 2.317e-02, -1.256e-02, 1.521e-02, 3.358e-04) * s1[y+0][x+0];
	r += M4(-2.319e-01, -1.752e-01, 9.294e-02, 2.293e-01, 1.144e-03, 7.039e-02, -1.537e-02, 4.062e-02, 1.671e-01, 8.911e-02, -4.149e-02, -6.814e-02, -3.948e-02, 1.206e-02, -2.516e-02, 1.617e-02) * s1[y+0][x+1];
	r += M4(6.955e-03, -6.595e-03, -4.320e-02, -2.490e-02, 1.731e-02, -4.143e-02, 4.121e-02, -7.205e-03, -2.784e-02, -6.967e-04, 1.530e-02, -3.675e-02, 3.629e-02, 9.629e-03, -1.059e-02, -4.001e-02) * s1[y+0][x+2];
	r += M4(8.075e-01, -8.518e-02, -1.889e-01, -2.754e-01, 7.827e-02, 2.515e-02, 2.538e-02, -2.824e-02, -3.110e-01, 4.694e-02, -1.519e-01, 3.019e-02, 1.576e-02, 1.760e-02, 5.053e-02, 2.387e-02) * s1[y+1][x+0];
	r += M4(-1.505e-01, 1.030e+00, -5.814e-01, -2.743e-01, -2.590e-01, -9.657e-02, -1.671e-01, -4.034e-02, -4.860e-01, -9.827e-01, 3.655e-02, -3.272e-01, 8.504e-02, -1.333e-02, 3.181e-03, -4.066e-02) * s1[y+1][x+1];
	r += M4(3.322e-02, -1.568e-01, 5.282e-03, -1.353e-01, 5.246e-02, -2.326e-02, -1.705e-03, -6.861e-02, -3.830e-02, 8.433e-02, -6.271e-03, 1.538e-01, -6.957e-02, 1.054e-02, -3.180e-02, 2.473e-02) * s1[y+1][x+2];
	r += M4(-1.528e-01, -2.164e-01, 5.254e-01, -2.416e-01, 4.114e-02, 5.342e-02, 2.306e-02, 5.726e-02, 5.722e-02, -2.841e-02, -5.505e-03, 3.961e-02, 3.253e-02, 1.248e-02, -4.195e-03, -7.085e-03) * s1[y+2][x+0];
	r += M4(-4.773e-01, -2.280e-01, -4.256e-01, 5.582e-01, 6.504e-03, -2.044e-02, -2.154e-02, -3.767e-02, 1.203e-01, 7.186e-02, -1.765e-01, -3.853e-01, -5.424e-02, -1.622e-02, 1.499e-02, 4.031e-03) * s1[y+2][x+1];
	r += M4(3.271e-02, -6.045e-02, 7.057e-02, -1.079e-01, 1.610e-02, 3.299e-02, 5.286e-02, 4.478e-02, 1.500e-02, 1.132e-01, -1.700e-02, 1.116e-01, 2.887e-02, -3.760e-03, 1.951e-02, 2.118e-02) * s1[y+2][x+2];
	r += V4(-8.518e-05, 6.216e-06, -1.083e-04, -8.464e-05);
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

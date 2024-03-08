// CuNNy 2x4C RCAS DS
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

//!DESC CuNNy-RCAS
//!HOOK LUMA
//!BIND easu
//!SAVE rcas
//!WIDTH easu.w
//!HEIGHT easu.h
//!COMPONENTS 1

// CuNNy: do not change unless changed during training as well
#define SHARPNESS 2.0
#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0))

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + 2.0);
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z)); 
}


float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

vec4 hook() {
#if (defined(easu_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec3 bde = easu_gather(easu_pos + easu_pt * vec2(-0.5), 0).xyz;
	float b = bde.z;
	float d = bde.x;
	float e = bde.y;
	vec2 fh = easu_gather(easu_pos + easu_pt * vec2(0.5), 0).zx;
	float f = fh.x;
	float h = fh.y;
#else
	float b = easu_texOff(vec2( 0.0, -1.0)).r;
	float d = easu_texOff(vec2(-1.0,  0.0)).r;
	float e = easu_tex(easu_pos).r;
	float f = easu_texOff(vec2(1.0, 0.0)).r;
	float h = easu_texOff(vec2(0.0, 1.0)).r;
#endif
	float mn1L = min(AMin3F1(b, d, f), h);
	float mx1L = max(AMax3F1(b, d, f), h);
	vec2 peakC = vec2(1.0, -1.0 * 4.0);
	float hitMinL = min(mn1L, e) / (4.0 * mx1L);
	float hitMaxL = (peakC.x - max(mx1L, e)) / (4.0 * mn1L + peakC.y);
	float lobeL = max(-hitMinL, hitMaxL);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(lobeL, 0.0)) * exp2(-clamp(float(SHARPNESS), 0.0, 2.0));
	float nz = 0.25 * b + 0.25 * d + 0.25 * f + 0.25 * h - e;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(b, d, e), f, h) - AMin3F1(AMin3F1(b, d, e), f, h)), 0.0, 1.0);
	nz = -0.5 * nz + 1.0;
	lobe *= nz;
	float rcpL = APrxMedRcpF1(4.0 * lobe + 1.0);
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	pix.r = float((lobe * b + lobe * d + lobe * h + lobe * f + e) * rcpL);
	return pix;
}


//!DESC CuNNy-2x4C-RCAS-DS-in
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
	r += V4(-1.513e-01, 1.306e-01, -2.936e-02, -2.616e-02) * s0[y+0][x+0];
	r += V4(1.897e-02, -7.154e-03, 4.876e-01, -1.780e-02) * s0[y+0][x+1];
	r += V4(2.279e-01, 1.111e-01, -4.563e-05, 5.892e-03) * s0[y+0][x+2];
	r += V4(-2.918e-01, 7.139e-02, 5.616e-02, 4.756e-01) * s0[y+1][x+0];
	r += V4(2.581e-01, -7.177e-01, -5.333e-01, 3.317e-02) * s0[y+1][x+1];
	r += V4(1.067e-01, 1.339e-01, 3.991e-03, -3.948e-03) * s0[y+1][x+2];
	r += V4(-1.286e-01, 1.121e-01, -4.672e-03, 3.447e-01) * s0[y+2][x+0];
	r += V4(-2.714e-02, 1.140e-01, 2.775e-02, -4.304e-02) * s0[y+2][x+1];
	r += V4(-1.242e-02, 3.308e-02, -7.407e-03, -9.428e-03) * s0[y+2][x+2];
	r += V4(-1.542e-02, 5.326e-03, -9.040e-04, -8.293e-03);
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

//!DESC CuNNy-2x4C-RCAS-DS-conv1
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
	r += M4(8.310e-02, -8.130e-03, 8.864e-03, -9.097e-02, -1.204e-01, 1.919e-01, 9.771e-02, -8.082e-02, -1.130e-01, -6.057e-03, -3.460e-02, -4.076e-02, -1.450e-02, -5.282e-02, -9.898e-02, 3.193e-02) * s0[y+0][x+0];
	r += M4(-1.870e-02, -8.681e-02, 2.410e-01, 7.376e-02, 3.107e-01, -1.532e-01, 1.592e-01, 1.462e-01, 6.780e-02, -2.942e-02, -2.436e-01, -5.903e-02, -3.556e-02, -2.788e-02, 4.775e-01, -1.691e-01) * s0[y+0][x+1];
	r += M4(1.478e-01, 3.002e-01, -1.042e-01, -5.734e-02, -3.942e-01, -2.210e-01, 2.350e-01, 1.480e-01, 6.346e-02, 5.096e-02, -1.062e-01, -9.206e-02, -2.059e-02, 1.803e-01, -5.894e-02, -1.863e-01) * s0[y+0][x+2];
	r += M4(3.352e-01, 4.312e-02, -5.433e-02, 4.086e-02, 7.715e-01, -9.584e-02, -2.500e-01, -2.627e-01, -2.574e-01, 2.257e-01, 2.723e-01, -2.765e-02, 2.217e-01, -1.018e-01, -3.326e-02, 9.737e-03) * s0[y+1][x+0];
	r += M4(8.423e-02, -2.998e-01, 5.601e-02, 1.301e-01, 7.246e-01, 6.855e-01, -7.162e-01, 9.210e-01, 1.333e-01, 6.019e-01, 2.748e-01, 1.192e+00, -1.681e-01, 2.326e-02, -4.038e-01, -1.425e-01) * s0[y+1][x+1];
	r += M4(-2.367e-01, 1.109e-01, -2.778e-02, -8.951e-02, 3.725e-01, -8.533e-01, -7.680e-03, 1.809e-01, -5.995e-01, -3.769e-01, 4.672e-02, -1.228e-02, 2.445e-01, -1.788e-01, -2.077e-01, -1.230e-01) * s0[y+1][x+2];
	r += M4(5.254e-01, -1.901e-01, -3.523e-02, -1.626e-01, 4.673e-01, -6.214e-03, -3.331e-01, -9.841e-02, -1.724e-01, 3.375e-01, 7.363e-01, -6.300e-02, 7.918e-03, -3.765e-02, 6.366e-02, -2.949e-02) * s0[y+2][x+0];
	r += M4(-2.342e-01, 4.445e-01, 1.265e-01, 7.992e-02, 1.830e-01, -1.294e-01, -7.826e-02, 1.216e-02, 1.589e-01, 4.501e-02, 2.764e-01, -4.981e-02, -2.397e-01, 1.948e-01, 2.337e-01, 3.212e-02) * s0[y+2][x+1];
	r += M4(9.382e-02, -6.406e-02, -1.751e-02, -3.375e-02, -2.104e-01, 2.416e-01, 4.653e-02, -4.960e-03, -2.782e-01, -3.701e-01, 9.516e-03, 5.913e-02, 3.826e-02, -1.154e-02, 9.011e-02, -4.618e-02) * s0[y+2][x+2];
	r += M4(4.673e-03, -4.862e-02, -8.614e-02, -5.788e-02, 2.746e-02, 1.460e-01, 2.059e-01, -1.238e-01, -9.482e-02, 2.945e-02, 5.779e-02, -1.473e-02, -5.888e-02, 2.121e-01, 3.802e-01, -7.980e-02) * s1[y+0][x+0];
	r += M4(-3.653e-02, -1.036e-01, 1.950e-01, 6.706e-02, 3.056e-01, -2.907e-01, 2.050e-01, 1.603e-01, 1.190e-01, 1.209e-01, -1.272e-01, -2.161e-02, 1.953e+00, -6.826e-01, 2.640e+00, 1.277e+00) * s1[y+0][x+1];
	r += M4(3.722e-02, 2.923e-01, -1.848e-01, -6.281e-02, -1.190e-01, -2.668e-01, 1.655e-01, 1.224e-01, -1.414e-01, 4.237e-02, -1.685e-01, -5.410e-02, 7.286e-01, -4.344e-01, 4.168e+00, -2.385e+00) * s1[y+0][x+2];
	r += M4(3.339e-01, 6.266e-02, -6.470e-02, 6.335e-02, 5.840e-01, 3.283e-02, -6.690e-02, -1.665e-01, -4.041e-01, -1.705e-01, -3.218e-01, 6.228e-04, 1.259e-01, -9.994e-02, 2.323e-01, -6.567e-02) * s1[y+1][x+0];
	r += M4(-2.929e-01, -3.447e-01, -9.288e-03, 1.012e-01, -1.949e-01, 5.019e-01, -3.701e-01, 4.578e-01, 4.366e-01, 1.275e-01, 2.726e-02, 3.135e-01, -1.086e+00, 4.132e-01, 1.382e+00, 1.101e+00) * s1[y+1][x+1];
	r += M4(1.326e-01, 4.502e-01, -1.034e-01, -1.263e-01, 1.640e-01, -7.122e-01, -6.302e-02, 1.587e-01, -2.117e-01, -1.169e-01, 3.499e-02, -3.384e-02, 2.754e-01, -4.433e+00, 3.046e+00, 1.110e-01) * s1[y+1][x+2];
	r += M4(4.487e-01, -2.097e-01, -1.570e-01, -1.538e-01, 5.605e-01, -2.590e-02, -2.979e-01, -7.635e-02, -4.339e-01, 9.595e-03, 2.861e-01, -5.506e-02, 3.775e-01, 8.513e-02, 1.982e-01, -5.911e-02) * s1[y+2][x+0];
	r += M4(-3.390e-01, 4.357e-01, 1.018e-01, 9.019e-02, -2.082e-02, -1.509e-01, -4.659e-02, 5.449e-02, 6.274e-01, -2.843e-01, 5.224e-02, -6.884e-02, -9.253e-01, -6.266e-02, -1.052e+00, 2.316e-01) * s1[y+2][x+1];
	r += M4(3.585e-02, -3.562e-03, -4.531e-02, -6.366e-02, -1.197e-01, 1.671e-01, -4.309e-02, 1.022e-02, 3.464e-01, -2.900e-01, -4.292e-02, 5.920e-02, -4.886e-01, -2.434e-01, 4.680e-01, -1.517e-01) * s1[y+2][x+2];
	r += V4(1.046e-03, 1.601e-03, -1.677e-03, 4.717e-01);
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

//!DESC CuNNy-2x4C-RCAS-DS-conv2
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
	r += M4(-2.385e-02, -1.140e-01, -1.856e-02, 1.381e-01, -1.236e-01, 4.693e-01, -2.178e-01, -3.502e-01, -2.570e-02, -1.578e-01, 1.058e-01, 9.989e-02, -2.963e-02, -1.742e-01, 9.518e-02, 2.998e-02) * s0[y+0][x+0];
	r += M4(1.948e-01, -4.053e-01, 8.600e-02, 5.114e-01, 9.152e-02, 4.582e-01, -8.427e-03, -1.651e-01, -6.648e-02, 1.329e-01, 9.225e-02, -1.370e-01, -1.662e-02, 7.922e-02, -7.202e-02, 2.044e-02) * s0[y+0][x+1];
	r += M4(1.048e-03, -1.561e-01, -1.540e-01, 7.117e-03, 1.345e-03, 2.202e-01, 1.783e-01, 2.419e-02, -2.044e-02, -1.239e-01, -1.086e-01, -2.596e-02, 2.876e-02, 1.320e-01, -1.375e-03, -7.397e-02) * s0[y+0][x+2];
	r += M4(7.357e-02, 2.383e-02, -3.031e-02, -1.452e-01, -3.410e-01, 6.840e-02, -1.135e-01, -2.783e-01, 9.646e-02, 2.586e-02, 5.023e-02, 7.712e-02, 2.880e-01, 7.539e-02, -1.072e-01, 1.258e-01) * s0[y+1][x+0];
	r += M4(-1.292e-02, 2.036e-02, 5.059e-01, -7.702e-02, -2.363e-01, -3.229e-01, -8.579e-02, -3.971e-01, -3.026e-01, 6.567e-02, 2.169e-01, 9.332e-03, -3.543e-01, -8.834e-02, 1.605e-01, 2.931e-02) * s0[y+1][x+1];
	r += M4(-9.231e-02, 3.008e-01, -3.035e-01, -1.031e-01, 2.800e-01, -8.218e-02, 1.012e+00, -4.649e-02, -1.496e-01, 4.140e-01, 3.076e-03, 1.920e-01, 1.677e-02, -6.492e-02, -7.985e-03, -5.720e-02) * s0[y+1][x+2];
	r += M4(-1.026e-01, 2.950e-02, -1.771e-02, 4.302e-04, -2.087e-01, -3.493e-01, 3.938e-02, 6.465e-01, 1.092e-01, 5.849e-02, -2.952e-02, -1.646e-01, 5.197e-02, 8.667e-02, -2.037e-01, -2.113e-01) * s0[y+2][x+0];
	r += M4(1.108e-01, 2.236e-01, 6.244e-02, -2.305e-01, -1.322e-01, -3.643e-01, -1.581e-01, 5.019e-01, -1.335e-01, -1.548e-01, 7.257e-02, 2.546e-01, 2.737e-02, 3.931e-02, 2.005e-01, 1.707e-02) * s0[y+2][x+1];
	r += M4(-1.284e-01, -2.373e-02, -3.043e-02, 9.864e-02, 2.146e-01, -1.218e-01, 6.848e-02, 7.236e-02, -5.772e-04, -2.053e-01, 5.637e-02, -1.513e-01, -7.593e-02, -7.087e-02, -1.385e-02, 1.304e-01) * s0[y+2][x+2];
	r += M4(1.676e-01, -1.060e-01, 8.434e-02, 1.736e-01, 1.223e-01, 6.369e-02, 5.990e-02, 5.071e-02, -4.311e-02, -3.185e-02, 5.404e-02, 4.188e-02, 1.783e-02, -7.718e-01, 6.832e-01, 1.093e+00) * s1[y+0][x+0];
	r += M4(2.173e-01, -5.371e-01, -2.851e-02, 3.270e-01, 2.008e-02, 2.588e-01, 1.391e-01, -8.068e-02, -4.695e-02, 2.263e-01, -9.114e-02, -1.460e-01, 3.057e-01, 1.287e+00, 2.479e-01, -1.164e+00) * s1[y+0][x+1];
	r += M4(-7.520e-02, -1.178e-01, -6.088e-02, 1.071e-01, -1.099e-01, 9.735e-02, -6.723e-03, -1.908e-02, -5.868e-02, -3.953e-02, 6.941e-03, 4.852e-02, 3.359e-01, -1.675e-01, 1.799e-01, 7.914e-01) * s1[y+0][x+2];
	r += M4(-2.248e-01, -1.333e-01, 1.536e-01, -1.274e-01, 6.162e-02, -2.984e-02, 4.847e-02, -1.626e-01, -9.743e-02, -1.499e-02, 1.490e-01, 2.025e-02, 5.841e-01, -1.623e-01, -4.910e-01, -2.615e+00) * s1[y+1][x+0];
	r += M4(3.687e-01, 6.705e-01, 1.642e-01, 2.666e-01, -2.318e-01, -1.047e-01, 4.161e-03, -3.727e-01, 4.079e-02, 5.397e-01, -7.381e-01, -3.468e-01, -2.183e+00, -3.411e+00, -1.756e+00, -5.652e+00) * s1[y+1][x+1];
	r += M4(-3.146e-01, 1.925e-01, -9.784e-02, 8.181e-02, 3.197e-04, 5.664e-02, 4.256e-02, -1.634e-02, 3.447e-01, 9.195e-01, 2.422e-01, -2.773e-02, 9.965e-01, -1.948e+00, 1.057e+00, -2.858e-01) * s1[y+1][x+2];
	r += M4(-2.338e-01, 1.403e-01, -3.741e-03, -5.000e-02, 8.512e-02, -9.693e-02, 2.574e-01, 2.823e-01, -7.056e-02, -7.749e-02, 1.667e-01, -9.443e-03, 5.201e-01, 4.771e-01, 1.530e-01, -5.361e-01) * s1[y+2][x+0];
	r += M4(4.069e-01, 8.649e-02, -9.486e-02, -5.478e-01, -2.032e-01, -1.679e-01, 3.107e-02, 2.811e-01, -3.094e-01, -2.908e-01, -3.233e-01, 6.844e-01, -9.611e-01, -1.037e+00, 4.922e-01, 1.253e+00) * s1[y+2][x+1];
	r += M4(-1.605e-01, 2.289e-01, 2.914e-02, -1.255e-01, 7.564e-03, -8.427e-02, -7.103e-03, 5.752e-02, 4.687e-01, -4.963e-01, 2.145e-01, 3.407e-01, 9.817e-01, 2.693e-02, -4.248e-02, -1.131e-01) * s1[y+2][x+2];
	r += V4(1.482e-02, -7.250e-03, -1.207e-02, -5.481e-03);
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

//!DESC CuNNy-2x4C-RCAS-DS-out
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
	r += M4(3.877e-01, -3.701e-01, 1.490e-02, -9.550e-02, -3.308e-02, 1.002e-03, 2.194e-03, -1.442e-03, 1.870e-02, -2.906e-02, 3.104e-02, -1.846e-02, 2.894e-02, -1.152e-03, -5.441e-02, -7.199e-03) * s0[y+0][x+0];
	r += M4(-1.831e-01, 2.317e-01, -1.650e-01, -1.116e-01, 7.511e-02, 2.636e-02, 5.041e-02, 2.818e-02, -5.502e-02, -2.668e-02, -2.182e-02, 6.876e-03, 2.124e-01, 1.324e-01, 2.240e-02, -4.775e-02) * s0[y+0][x+1];
	r += M4(2.581e-02, -4.740e-02, -2.385e-02, -1.866e-02, -1.027e-02, 6.320e-04, -4.524e-03, 1.498e-02, 2.362e-02, 6.923e-03, 1.743e-02, 2.414e-03, 2.524e-03, 1.019e-01, -4.040e-02, -2.468e-02) * s0[y+0][x+2];
	r += M4(2.770e-01, -3.187e-01, 6.903e-01, -5.605e-01, 1.403e-01, -4.712e-02, -7.934e-02, -5.548e-02, -3.525e-03, 4.742e-03, -8.619e-02, -3.413e-02, -3.727e-02, -4.810e-02, 8.588e-02, -4.182e-03) * s0[y+1][x+0];
	r += M4(-2.153e-01, 1.774e-01, -1.277e-01, 6.113e-01, 4.542e-01, 5.859e-01, 1.136e-01, 7.170e-02, 1.063e-01, 5.501e-02, 3.125e-02, -5.871e-02, 9.316e-02, 1.133e-01, 3.684e-01, 3.589e-01) * s0[y+1][x+1];
	r += M4(6.189e-02, -3.699e-02, 1.219e-01, -2.656e-02, -4.697e-02, -7.925e-03, -3.027e-02, -1.748e-02, -2.156e-02, 3.326e-02, -1.490e-02, 1.311e-02, -2.822e-02, -2.254e-02, -2.458e-03, 1.013e-01) * s0[y+1][x+2];
	r += M4(5.145e-02, 2.706e-02, -7.924e-03, -8.480e-03, -7.381e-02, 2.823e-02, 7.552e-02, -8.893e-03, -6.699e-03, -2.173e-02, 6.043e-02, 1.063e-03, 4.674e-03, 1.141e-02, -1.759e-02, 1.971e-03) * s0[y+2][x+0];
	r += M4(6.418e-02, -2.412e-02, -7.738e-02, -1.675e-01, -4.727e-02, -1.558e-01, 2.427e-01, 2.712e-01, -4.168e-02, -2.520e-02, -1.975e-04, 5.774e-02, 3.134e-02, 1.600e-02, 2.434e-03, -6.265e-03) * s0[y+2][x+1];
	r += M4(-3.644e-02, 2.740e-02, -5.192e-02, -2.031e-02, 9.166e-03, 3.220e-02, -2.058e-02, 4.744e-02, -3.482e-03, -1.860e-02, -3.429e-03, 7.223e-03, -8.879e-03, 1.360e-02, 3.483e-02, 3.110e-02) * s0[y+2][x+2];
	r += M4(-2.132e-03, -2.634e-02, -1.295e-02, -3.539e-02, 3.288e-02, 1.004e-02, -1.076e-01, -1.378e-02, -3.541e-02, 9.286e-03, 9.697e-02, -7.548e-03, -2.378e-02, 2.468e-02, -3.450e-02, -1.975e-02) * s1[y+0][x+0];
	r += M4(1.902e-02, 3.748e-02, -1.599e-01, -9.817e-02, 1.776e-01, 1.531e-01, -4.311e-02, -1.221e-01, 6.159e-02, -1.685e-01, -8.073e-02, 7.201e-03, 1.065e-01, -1.172e-02, 2.472e-01, 1.219e-01) * s1[y+0][x+1];
	r += M4(-2.922e-02, -2.662e-02, -2.843e-03, -5.054e-02, -2.470e-02, 2.083e-02, -2.579e-03, -1.936e-02, 2.282e-02, 7.702e-02, 5.639e-02, 1.419e-02, 5.968e-03, 5.312e-02, -5.841e-02, 3.872e-02) * s1[y+0][x+2];
	r += M4(5.395e-03, -3.209e-02, 5.274e-02, -9.083e-03, -3.842e-02, -3.718e-02, 1.175e-01, -2.049e-02, -3.662e-01, 2.788e-01, -3.623e-01, 1.822e-01, 7.754e-02, 2.903e-02, -6.195e-02, 2.186e-02) * s1[y+1][x+0];
	r += M4(2.847e-02, 4.487e-03, 3.380e-01, 2.518e-01, 1.869e-01, 1.401e-01, 3.000e-01, 3.744e-01, 8.458e-01, -7.592e-01, 5.292e-01, -6.705e-01, 7.091e-01, 5.467e-01, -1.538e-02, -9.545e-02) * s1[y+1][x+1];
	r += M4(2.615e-03, -1.180e-03, -1.058e-03, 8.031e-02, -6.207e-02, -3.873e-03, -4.260e-02, 1.376e-02, -2.920e-01, 1.987e-01, -2.094e-01, 1.141e-01, -5.411e-02, 1.583e-01, -1.593e-02, -2.555e-02) * s1[y+1][x+2];
	r += M4(1.256e-02, 1.137e-02, -1.729e-02, 1.055e-03, -1.502e-02, -1.500e-03, -2.964e-03, 1.777e-02, 7.540e-02, -9.709e-03, -6.488e-02, 1.155e-01, -9.597e-02, 3.792e-02, 2.488e-02, 3.650e-02) * s1[y+2][x+0];
	r += M4(2.262e-02, 1.777e-02, -1.052e-01, -8.617e-02, 1.413e-02, 7.829e-04, 9.693e-02, 4.366e-02, -9.895e-02, -2.353e-02, 3.789e-01, -2.862e-01, -2.243e-01, -2.280e-01, 3.050e-01, 1.987e-01) * s1[y+2][x+1];
	r += M4(-5.537e-03, 2.838e-02, -2.195e-02, -2.877e-02, -1.111e-02, -6.676e-03, -3.153e-02, 1.816e-02, 4.140e-02, -4.000e-02, -9.072e-02, 9.705e-02, 1.719e-04, -1.305e-01, 2.431e-03, 1.195e-01) * s1[y+2][x+2];
	r += V4(5.146e-04, 4.193e-04, 5.064e-04, 3.788e-04);
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

//!DESC CuNNy-2x4C-RCAS-DS-shuffle
//!HOOK LUMA
//!BIND out
//!BIND rcas
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
	r.r += rcas_tex(rcas_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

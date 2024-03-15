// CuNNy 8x4C RCAS DS
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

//!DESC CuNNy-8x4C-RCAS-DS-EASU
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

//!DESC CuNNy-8x4C-RCAS-DS-RCAS
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


//!DESC CuNNy-8x4C-RCAS-DS-in
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
#define l0(x, y) F(texelFetch(LUMA_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0).r)
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
	r0 += V4(1.360e-01, 4.267e-02, 7.174e-02, 3.892e-03) * s[0][0][0];
	r0 += V4(1.827e-01, -1.671e-01, -4.042e-02, 1.938e-01) * s[0][1][0];
	r0 += V4(9.679e-03, 6.665e-02, -4.619e-02, -5.823e-01) * s[0][2][0];
	r0 += V4(3.057e-01, -2.368e-02, 4.904e-01, 2.560e-03) * s[1][0][0];
	r0 += V4(-6.152e-01, -6.015e-01, 1.980e-01, 4.187e-01) * s[1][1][0];
	r0 += V4(-1.136e-01, 3.096e-01, 3.431e-02, -2.937e-02) * s[1][2][0];
	r0 += V4(2.742e-02, -2.791e-02, 1.579e-01, -2.150e-02) * s[2][0][0];
	r0 += V4(6.120e-02, 2.217e-01, -1.206e-01, 8.078e-03) * s[2][1][0];
	r0 += V4(-1.513e-02, 1.600e-01, -1.278e-03, 1.858e-02) * s[2][2][0];
	r0 += V4(-1.655e-02, 4.003e-02, -3.603e-02, -7.602e-04);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv1
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
#define l0(x, y) V4(texelFetch(in_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(1.636e-02, 8.610e-02, 4.517e-03, -9.104e-02, -8.561e-02, -3.986e-01, 5.767e-02, -3.007e-02, -1.700e-02, 6.052e-02, 1.765e-02, -4.176e-02, -1.301e-01, -1.165e-01, 5.781e-02, -1.184e-02) * s[0][0][0];
	r0 += M4(-2.912e-02, -7.913e-02, 6.528e-03, 3.606e-02, -2.367e-01, -3.857e-01, 7.712e-02, 1.870e-01, -2.307e-01, -1.860e-01, -2.485e-01, -4.227e-01, -1.317e-02, -1.326e-01, 5.239e-02, -1.024e-01) * s[0][0][1];
	r0 += M4(-1.208e-01, -9.293e-02, 2.335e-01, 3.178e-01, 5.459e-01, -8.860e-01, 6.218e-02, -2.087e-01, -5.337e-02, -1.165e-02, -1.169e-01, 1.449e-01, -2.070e-03, 1.577e-01, 4.787e-02, -3.840e-03) * s[0][1][0];
	r0 += M4(-5.756e-01, -3.569e-01, 1.538e-01, 8.566e-02, 2.611e-01, 1.124e-02, 6.008e-02, 6.378e-02, -4.099e-01, -1.297e+00, -4.534e-01, 1.391e-01, 1.184e-01, 4.710e-01, -1.664e-03, -3.295e-02) * s[0][1][1];
	r0 += M4(1.907e-01, 1.760e-01, -1.323e-01, -2.138e-01, 4.038e-01, -1.580e-01, 1.376e-02, -5.221e-02, -8.875e-03, 1.517e-01, 2.462e-01, -8.692e-02, -1.192e-01, -8.711e-02, -5.216e-02, 2.694e-02) * s[0][2][0];
	r0 += M4(4.388e-01, 1.550e-01, -1.148e-01, -1.923e-01, 2.076e-01, -1.125e-01, -6.638e-03, -1.192e-02, -5.017e-01, -6.363e-02, 1.854e+00, 2.459e+00, -8.564e-02, -2.651e-02, 7.433e-03, -4.967e-02) * s[0][2][1];
	r0 += M4(2.144e-01, -9.989e-02, 3.733e-02, 6.726e-03, -6.192e-02, -1.403e-01, 5.395e-02, 2.288e-01, -1.665e-01, -1.616e-02, -3.262e-03, 3.964e-02, -2.544e-01, -2.260e-01, -7.520e-02, -3.270e-01) * s[1][0][0];
	r0 += M4(1.684e-01, -5.322e-02, 7.027e-03, -1.479e-01, -8.031e-02, -4.951e-02, 2.842e-01, 6.684e-01, 2.242e-01, 1.835e-01, -2.043e-01, -6.242e-02, -3.039e-02, -2.448e-01, -1.331e-01, 9.711e-02) * s[1][0][1];
	r0 += M4(5.258e-01, 4.586e-02, -7.815e-01, 3.379e-01, 5.605e-01, 1.822e-01, -5.333e-01, -1.762e-01, 2.885e-01, -8.549e-02, 3.297e-01, 9.884e-02, 7.210e-02, -2.607e-01, 2.273e-01, 4.373e-02) * s[1][1][0];
	r0 += M4(3.373e-01, 4.169e-01, -5.256e-01, -1.016e-01, -1.342e-01, 1.840e-01, -5.723e-01, -2.207e-01, 9.175e-01, -2.825e-02, 2.283e+00, 1.047e+00, 8.501e-01, 1.080e+00, 3.955e-01, 1.919e-02) * s[1][1][1];
	r0 += M4(-2.801e-01, 1.122e-02, 2.227e-01, 3.792e-02, -9.516e-02, -8.798e-03, 1.205e-01, -4.521e-02, -2.614e-03, -4.789e-03, 2.824e-01, 2.410e-02, 1.391e-01, -8.229e-02, 1.745e-02, 3.069e-02) * s[1][2][0];
	r0 += M4(-3.426e-01, -4.661e-02, 4.510e-01, -1.742e-01, -3.191e-01, -1.337e-01, 3.954e-02, -1.081e-01, -1.630e+00, -3.348e-01, 3.368e+00, 4.033e+00, 3.602e-01, -5.538e-02, 4.774e-02, 7.641e-02) * s[1][2][1];
	r0 += M4(1.684e-01, -4.361e-03, 1.228e-01, 6.971e-02, -1.313e-01, 1.112e-01, -9.033e-02, 1.240e-03, -9.860e-02, 2.182e-02, -9.547e-02, -5.748e-02, -3.799e-01, -1.772e-02, -3.320e-01, -7.744e-01) * s[2][0][0];
	r0 += M4(1.987e-01, -2.750e-02, 1.130e-01, 1.329e-01, -6.264e-02, 3.630e-03, -1.077e-01, 3.685e-02, -3.988e-03, -8.034e-02, -1.499e-01, 3.969e-01, -3.545e-01, -4.808e-02, -8.737e-02, 1.949e-01) * s[2][0][1];
	r0 += M4(1.213e-01, 1.675e-01, -8.008e-02, -1.078e-01, 2.668e-01, 6.370e-02, 2.756e-01, 5.740e-02, 1.932e-01, 4.515e-03, 1.373e-01, 9.774e-03, -3.051e-03, 1.090e-02, 2.339e-01, -1.788e-01) * s[2][1][0];
	r0 += M4(9.050e-02, 5.518e-03, -4.834e-02, -2.815e-01, -1.910e-02, -3.167e-02, 1.403e-01, -1.407e-02, -7.532e-02, -1.751e-01, -2.740e-01, 5.953e-01, 3.111e-01, 9.652e-02, -1.651e-01, 1.767e-03) * s[2][1][1];
	r0 += M4(-3.179e-02, 4.582e-02, -6.446e-02, -1.558e-01, 5.464e-02, -2.887e-02, -4.358e-02, -2.620e-02, -3.138e-02, -1.243e-01, 3.963e-02, -1.062e-02, -1.372e-01, -5.708e-02, -8.276e-02, -4.382e-02) * s[2][2][0];
	r0 += M4(-1.833e-02, 3.830e-02, -7.685e-02, 1.318e-02, -2.538e-02, -2.556e-02, -7.135e-02, 1.898e-02, -6.701e-01, -8.319e-02, 2.915e-01, 7.488e-01, 1.394e-01, 6.132e-02, 3.775e-02, -8.903e-02) * s[2][2][1];
	r0 += V4(-2.458e-02, 1.044e-01, -4.941e-01, 1.614e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv2
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
#define l0(x, y) V4(texelFetch(conv1_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(1.226e-02, 3.879e-01, -5.563e-02, -2.213e-02, 1.103e-02, -1.206e-01, -6.895e-03, -1.024e-01, -1.281e-01, -2.885e-01, 8.663e-02, 9.918e-02, 1.091e-01, -1.058e-01, -1.720e-01, 1.000e-01) * s[0][0][0];
	r0 += M4(1.938e-01, 1.382e-01, 1.478e-02, 2.470e-01, -4.423e-04, -6.901e-02, 2.336e-05, -5.723e-02, -1.087e-01, -1.459e-01, 6.448e-02, 1.606e-01, 7.203e-02, 1.093e-01, -6.796e-02, 3.134e-02) * s[0][0][1];
	r0 += M4(-2.247e-02, -2.927e-01, -1.676e-01, -3.869e-02, -1.116e-01, 7.625e-02, -9.222e-02, 4.408e-02, -2.418e-01, 5.184e-01, -2.972e-01, 1.069e-01, 1.412e-02, 6.068e-01, 2.826e-02, -4.050e-01) * s[0][1][0];
	r0 += M4(6.592e-02, -3.858e-01, 8.488e-02, 1.618e-02, -2.327e-02, 1.135e-01, -5.552e-02, 3.693e-02, -1.121e-01, 4.215e-01, -2.627e-01, 1.622e-01, 7.194e-02, -3.525e-01, 7.127e-02, -2.226e-02) * s[0][1][1];
	r0 += M4(-7.484e-03, 7.456e-02, 1.288e-02, -9.666e-02, -1.652e-02, 1.715e-02, 1.622e-03, 2.641e-02, -1.084e-01, 5.909e-02, 1.553e-02, -2.057e-01, -1.112e-01, -6.729e-02, 3.438e-02, -1.808e-01) * s[0][2][0];
	r0 += M4(1.591e-02, -2.185e-02, -7.403e-02, 6.693e-03, 8.676e-03, -1.481e-02, -6.973e-03, 1.243e-02, -9.888e-02, 7.348e-02, 4.358e-02, -2.279e-01, -1.472e-01, -2.739e-02, -1.543e-01, 1.784e-01) * s[0][2][1];
	r0 += M4(-2.086e-01, -3.465e-01, 4.810e-01, -2.350e-02, -6.143e-02, 1.080e-01, -1.563e-01, -1.810e-01, -1.515e-01, 8.508e-02, -4.309e-02, 3.180e-02, 8.468e-02, 2.388e-01, 1.003e-01, -3.112e-01) * s[1][0][0];
	r0 += M4(1.732e-02, 2.862e-01, 3.286e-02, 1.465e-01, -3.217e-02, 6.170e-02, -1.353e-01, -1.688e-01, -1.086e-01, 1.064e-02, 8.238e-02, 1.850e-02, -1.796e-02, 9.206e-03, -1.853e-02, -3.277e-02) * s[1][0][1];
	r0 += M4(-1.266e-01, -2.913e-01, -4.508e-01, -1.066e-01, 3.785e-01, 9.561e-01, 3.621e-02, -2.636e-01, -1.081e+00, -1.598e-01, 6.770e-01, 4.694e-01, -2.018e-01, -3.627e-01, 7.913e-02, 3.862e-02) * s[1][1][0];
	r0 += M4(-1.169e-01, -2.658e-01, -8.252e-01, 6.292e-02, 1.538e-01, 4.509e-03, 2.341e-01, -1.740e-01, -6.394e-01, -4.647e-02, 6.224e-01, 5.058e-01, -7.536e-02, 7.717e-02, -1.038e-01, 1.614e-01) * s[1][1][1];
	r0 += M4(1.742e-03, -1.357e-03, -1.296e-01, 1.333e-01, -2.930e-02, 1.633e-01, -1.097e-01, 3.987e-02, -1.302e-01, -2.825e-01, -3.626e-01, 1.621e-01, -1.898e-01, -6.028e-01, -5.578e-01, 1.860e-01) * s[1][2][0];
	r0 += M4(6.279e-02, 1.854e-01, 1.957e-01, -1.155e-01, 3.208e-02, -2.654e-02, 6.602e-02, -9.202e-03, -1.245e-01, -3.335e-01, -4.539e-01, 8.224e-02, -2.510e-01, 5.231e-02, 1.908e-01, 1.905e-03) * s[1][2][1];
	r0 += M4(3.365e-02, -2.244e-01, -9.155e-02, -4.580e-02, 1.750e-02, 2.446e-01, -2.079e-02, -4.148e-01, -8.719e-02, 1.601e-01, -1.350e-01, -1.845e-01, 1.257e-01, 7.621e-02, 4.811e-02, 8.375e-02) * s[2][0][0];
	r0 += M4(-2.913e-02, -8.503e-02, -8.723e-02, -4.668e-01, 9.060e-02, 1.116e-01, -2.990e-02, -3.018e-01, -5.641e-02, 5.256e-02, -7.486e-02, -2.257e-01, 9.777e-02, -2.660e-02, 1.081e-02, 2.065e-01) * s[2][0][1];
	r0 += M4(1.569e-01, 1.631e-01, 1.715e-02, -1.893e-01, -1.488e-01, 3.167e-01, 5.315e-01, 2.393e-02, -2.842e-01, -4.095e-02, 2.104e-02, -3.002e-01, 8.557e-02, -3.231e-01, 5.496e-02, 2.088e-03) * s[2][1][0];
	r0 += M4(1.468e-01, -4.252e-03, -1.393e-01, -2.874e-01, 2.721e-02, -1.067e-01, 7.350e-02, 1.343e-01, -1.256e-01, -5.309e-02, 7.825e-02, -1.928e-01, 1.437e-01, 1.672e-02, -1.130e-01, 1.129e-01) * s[2][1][1];
	r0 += M4(-2.364e-02, 2.936e-02, 9.108e-02, 3.693e-02, 7.683e-02, -3.271e-01, -4.284e-01, 8.292e-02, -7.246e-02, 3.927e-02, 7.394e-02, -3.767e-02, -1.248e-01, 2.412e-01, -3.013e-02, 2.780e-01) * s[2][2][0];
	r0 += M4(2.189e-02, 1.949e-01, 1.959e-01, -4.647e-02, 8.356e-02, 6.711e-03, -5.371e-02, 1.520e-01, -3.628e-02, 4.340e-02, -1.798e-02, 8.779e-02, -7.223e-02, -1.396e-02, 1.394e-02, 9.350e-02) * s[2][2][1];
	r0 += V4(2.344e-01, -2.948e-02, 6.081e-02, 1.023e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv3
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
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(-9.978e-02, 8.206e-02, 3.418e-02, 1.142e-01, 4.857e-02, 2.287e-02, -1.124e-01, 1.321e-01, -5.077e-02, -1.387e-01, -6.043e-02, -1.015e-01, 8.716e-03, -4.970e-02, -9.934e-02, 4.662e-02) * s[0][0][0];
	r0 += M4(1.270e-02, -8.658e-02, 2.413e-01, -4.724e-01, 8.564e-02, -1.583e-01, -6.077e-03, -2.320e-01, -1.456e-01, -1.952e-01, 7.582e-02, -1.368e-02, 1.973e-02, -7.693e-03, 8.180e-02, -7.457e-02) * s[0][0][1];
	r0 += M4(1.696e-01, 9.058e-02, 2.437e-02, -1.136e-02, -1.693e-01, 2.490e-01, 1.751e-02, 3.465e-01, 1.108e-01, -7.537e-02, -1.033e-01, -1.942e-01, 3.418e-02, -3.266e-01, -5.187e-02, -2.666e-01) * s[0][1][0];
	r0 += M4(-1.148e+00, 5.501e-01, 2.696e-01, 7.255e-01, -1.401e-01, -6.758e-02, -8.014e-02, -1.113e-01, 2.566e-01, -2.084e-01, 1.674e-01, -3.295e-01, 6.133e-02, -1.555e-01, 5.552e-02, 1.686e-02) * s[0][1][1];
	r0 += M4(-3.585e-03, -3.752e-02, 4.869e-02, -1.957e-02, -1.224e-02, 7.104e-02, 4.333e-02, 1.213e-01, -5.265e-04, -6.667e-02, 3.036e-02, -2.179e-01, 6.586e-02, -1.392e-01, 3.651e-02, -2.685e-01) * s[0][2][0];
	r0 += M4(-9.882e-01, 1.721e-01, 3.267e-01, 2.172e-01, 9.525e-02, -1.977e-01, 3.899e-02, -1.264e-01, -8.506e-02, 1.945e-01, 2.469e-02, 8.477e-02, 9.224e-02, 1.085e-01, -4.854e-02, 1.165e-01) * s[0][2][1];
	r0 += M4(1.408e-01, 5.019e-02, 3.970e-02, -1.068e-01, -2.040e-02, 2.051e-01, -3.511e-01, 4.162e-01, 1.489e-01, -2.397e-01, -2.395e-01, -3.851e-01, -1.767e-02, -1.849e-01, 5.931e-02, -4.329e-02) * s[1][0][0];
	r0 += M4(-2.135e-01, 9.810e-02, -1.495e-01, 4.371e-01, 3.096e-02, -9.087e-02, 7.291e-02, -3.749e-02, -5.825e-02, -2.393e-01, 2.203e-01, -9.711e-02, 4.216e-02, 2.186e-03, 4.584e-02, 6.951e-02) * s[1][0][1];
	r0 += M4(-3.682e-01, -9.541e-02, -4.027e-01, 1.663e-01, 2.564e-02, 1.910e-01, -1.224e-01, 1.655e-01, -1.233e-01, 9.512e-01, -3.151e-01, -2.979e-01, 9.031e-02, 2.174e-02, 1.940e-01, -1.710e-01) * s[1][1][0];
	r0 += M4(-1.757e+00, -2.007e+00, -8.687e-01, -1.984e-01, 7.703e-02, -5.641e-01, 4.637e-01, -8.201e-01, -1.908e-01, 5.215e-01, 5.251e-01, -9.293e-02, 5.132e-01, 9.611e-01, -1.001e-01, 1.601e-02) * s[1][1][1];
	r0 += M4(-5.022e-02, 3.776e-02, -2.659e-03, -1.170e-01, 3.824e-02, 2.002e-01, -1.077e-01, 2.098e-01, 1.420e-01, -2.464e-02, -2.884e-01, -2.245e-02, 1.839e-01, -1.799e-01, -2.884e-01, -1.067e-01) * s[1][2][0];
	r0 += M4(-1.888e+00, 4.277e-01, 1.909e+00, -1.905e+00, 1.081e-01, -1.755e-01, -6.068e-02, -1.184e-01, 2.372e-01, 9.991e-02, 1.478e-01, -4.079e-02, 1.897e-01, 2.809e-01, -1.261e-01, -1.153e-01) * s[1][2][1];
	r0 += M4(8.318e-03, -1.418e-01, 9.102e-02, 3.896e-02, 9.498e-02, 3.528e-01, -6.556e-03, 2.055e-01, 4.131e-02, -8.628e-04, -1.208e-01, -5.475e-02, 1.793e-02, 1.019e-01, 9.092e-02, -8.217e-04) * s[2][0][0];
	r0 += M4(-2.018e-01, 5.177e-01, 1.039e-02, 6.245e-01, 3.940e-02, -9.107e-02, 3.946e-02, -5.753e-02, -1.315e-02, -3.302e-03, -3.800e-03, 1.839e-02, 1.576e-03, 1.844e-01, 1.431e-02, 2.329e-01) * s[2][0][1];
	r0 += M4(6.439e-02, 6.852e-02, -2.206e-01, -6.311e-02, 9.040e-02, 3.095e-01, 1.402e-01, 1.477e-01, -2.169e-02, 8.047e-02, -1.657e-01, -1.816e-01, -9.474e-02, -2.008e-01, -1.028e-02, -1.212e-01) * s[2][1][0];
	r0 += M4(2.962e-02, 3.776e-01, -3.705e-01, 4.479e-01, 4.860e-02, -4.657e-01, 2.491e-01, -7.745e-02, -1.232e-01, 6.165e-02, 2.992e-02, -1.350e-01, 2.094e-02, 1.807e-02, 1.169e-03, -2.153e-02) * s[2][1][1];
	r0 += M4(3.423e-03, -7.481e-02, 1.792e-01, 1.087e-01, 5.870e-02, 2.933e-01, 2.889e-04, -5.599e-02, -1.647e-02, -1.514e-01, -1.444e-01, -2.974e-02, -6.867e-02, -1.067e-01, 8.353e-02, -2.390e-02) * s[2][2][0];
	r0 += M4(-2.981e-01, -3.632e-01, 1.078e+00, -1.940e-01, 2.673e-01, -6.656e-02, 5.192e-02, -5.189e-02, -5.395e-02, -9.721e-02, -1.376e-01, -5.128e-02, -6.727e-02, -2.217e-02, 6.257e-02, -1.071e-01) * s[2][2][1];
	r0 += V4(-9.020e-02, -6.700e-02, 2.744e-01, -1.997e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv4
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
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
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
	r0 += M4(-4.541e-01, -5.496e-02, -7.764e-02, -1.604e-01, 1.284e-01, 4.521e-02, -1.415e-02, 9.144e-02, -3.538e-01, -1.754e-01, -2.226e-01, 3.288e-01, -2.427e-01, -1.915e-01, 6.528e-02, -2.059e-03) * s[0][0][0];
	r0 += M4(-3.279e-01, -1.834e-01, -6.124e-02, -2.591e-01, 7.856e-02, 4.682e-02, -1.047e-01, -1.277e-01, -1.161e-01, -1.183e-01, 3.152e-02, 1.522e-01, -2.822e-01, -5.323e-03, -1.373e-01, -2.251e-02) * s[0][0][1];
	r0 += M4(2.699e-02, -2.163e-01, 1.638e-01, -8.671e-03, -6.707e-02, -5.851e-02, 6.997e-03, -2.725e-01, -4.103e-01, 2.375e-01, -3.119e-02, -5.295e-01, 1.606e-02, 8.656e-02, -8.151e-02, -1.345e-02) * s[0][1][0];
	r0 += M4(-2.296e-01, -1.501e-01, 2.173e-01, -2.356e-01, -1.729e-01, 8.647e-02, 1.841e-01, -4.725e-01, -1.379e-01, 1.886e-01, -1.342e-02, -3.714e-01, -5.647e-02, 4.222e-02, 2.846e-02, 4.150e-02) * s[0][1][1];
	r0 += M4(2.320e-01, 4.422e-02, -1.489e-01, 6.224e-02, -7.617e-02, 1.927e-03, -6.864e-02, -1.234e-01, -2.615e-02, -9.127e-02, -1.135e-01, -4.604e-02, 9.213e-02, -1.052e-01, 1.602e-01, -1.934e-03) * s[0][2][0];
	r0 += M4(4.599e-02, -4.116e-02, 1.330e-01, -6.957e-02, -8.024e-02, 7.989e-03, -1.226e-01, -1.126e-01, 8.087e-02, -1.223e-01, -9.887e-02, 8.615e-02, -1.402e-01, -7.738e-02, -8.133e-02, -1.210e-03) * s[0][2][1];
	r0 += M4(3.439e-01, 8.212e-01, 4.983e-01, 5.951e-02, -2.939e-01, -2.183e-01, -2.252e-01, 5.749e-02, 9.021e-02, 4.581e-03, -1.439e-01, -1.624e-01, -1.005e-02, 1.359e-01, -1.907e-01, -8.423e-02) * s[1][0][0];
	r0 += M4(2.124e-01, 1.743e-01, 2.960e-02, 3.537e-01, -1.517e-02, -1.024e-01, -1.323e-01, 1.098e-01, 9.274e-02, 4.541e-02, 1.132e-01, -2.396e-01, 1.709e-01, 2.080e-01, 2.168e-01, 2.073e-01) * s[1][0][1];
	r0 += M4(-1.256e-01, 1.419e+00, -2.737e-01, -1.992e-01, 2.647e-01, 3.769e-01, 4.575e-01, 3.963e-01, 1.234e-01, 1.579e-01, -2.979e-01, 8.959e-02, -4.220e-01, 1.308e-01, -8.114e-01, -1.470e-01) * s[1][1][0];
	r0 += M4(-1.107e-01, 7.044e-01, -1.142e-01, -1.939e-01, 5.416e-01, 3.061e-01, 1.032e+00, 8.776e-01, 3.443e-01, 2.471e-01, -4.836e-01, 1.774e-01, -2.177e-01, 3.167e-02, -5.493e-01, 1.635e-01) * s[1][1][1];
	r0 += M4(-5.659e-03, -4.716e-02, -1.000e-01, 7.736e-02, 5.173e-03, -1.846e-01, -8.674e-02, 2.965e-02, -6.256e-03, -7.251e-02, -3.603e-01, 2.483e-02, -1.122e-01, -3.321e-02, 8.022e-02, 2.426e-01) * s[1][2][0];
	r0 += M4(9.155e-02, -6.860e-02, 1.507e-02, 1.391e-02, -6.511e-02, -1.421e-02, -6.115e-02, -3.717e-02, -1.642e-01, -2.070e-01, -1.255e-01, 9.280e-02, 8.263e-02, -1.417e-02, 1.328e-01, -1.920e-02) * s[1][2][1];
	r0 += M4(-4.319e-02, 3.227e-01, 2.032e-02, 2.647e-01, -1.030e-01, -8.032e-02, -1.694e-01, 4.977e-02, 1.750e-01, 8.095e-04, -2.999e-02, 1.688e-01, 1.642e-01, -1.079e-02, 3.311e-01, -2.250e-01) * s[2][0][0];
	r0 += M4(-1.636e-01, -2.508e-02, -5.629e-02, 5.067e-02, 8.920e-02, 4.516e-02, -9.672e-03, 6.693e-02, 1.264e-01, 7.656e-02, 1.832e-01, 8.730e-03, -4.000e-02, -1.576e-02, 2.801e-02, -1.297e-01) * s[2][0][1];
	r0 += M4(1.095e-01, 6.100e-01, 3.556e-01, 3.404e-01, -9.437e-02, -6.157e-02, -7.310e-02, -1.109e-01, 1.415e-01, 1.551e-02, -4.430e-02, 2.218e-01, -3.701e-01, -2.882e-01, -3.723e-01, -1.174e-01) * s[2][1][0];
	r0 += M4(1.774e-01, 3.156e-01, 3.218e-01, 2.343e-01, -1.189e-01, 7.347e-02, -1.803e-01, -3.753e-02, 1.945e-01, 1.110e-01, 1.362e-01, -2.618e-03, -3.545e-01, -1.255e-01, -1.586e-01, -2.611e-01) * s[2][1][1];
	r0 += M4(-9.416e-02, -1.862e-01, -9.205e-02, -7.354e-02, 1.174e-01, 5.914e-02, 2.991e-03, 7.021e-02, -1.988e-01, 3.562e-02, -2.745e-01, 4.541e-02, -3.137e-01, 1.775e-01, -2.953e-01, -1.629e-01) * s[2][2][0];
	r0 += M4(3.405e-02, -1.278e-01, -2.346e-02, 7.552e-02, 1.721e-02, 8.568e-02, -4.955e-02, -9.946e-03, 4.861e-02, -1.054e-01, -1.165e-01, -8.430e-02, -8.746e-02, 2.698e-02, 9.169e-02, 6.105e-02) * s[2][2][1];
	r0 += V4(-1.416e-01, 2.906e-02, 7.605e-02, -3.927e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv5
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
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(1.362e-01, 1.097e-01, 1.162e-01, -1.236e-01, 2.169e-01, 3.214e-02, -7.116e-02, -5.052e-03, 4.336e-02, 3.551e-02, -1.374e-01, 1.645e-01, -3.525e-02, -8.323e-03, -1.503e-01, 7.107e-02) * s[0][0][0];
	r0 += M4(-4.748e-02, 1.266e-02, 2.802e-01, -1.380e-01, -4.849e-02, 3.047e-02, -1.255e-01, -6.373e-02, 9.873e-02, -6.595e-03, -1.772e-01, 5.596e-02, 4.534e-03, 5.789e-03, -1.053e-01, 1.053e-01) * s[0][0][1];
	r0 += M4(-2.076e-01, -1.017e-01, 1.703e-01, -1.098e-01, 8.434e-01, 3.043e-02, -7.880e-02, 1.184e-01, 1.807e-01, -3.119e-01, -4.457e-02, 1.508e-01, 1.465e-01, 6.123e-02, -1.792e-01, 2.276e-02) * s[0][1][0];
	r0 += M4(-7.000e-02, -1.483e-01, -5.117e-02, 1.224e-01, 3.021e-02, 2.050e-01, -1.627e-01, 1.003e-01, 1.380e-01, -1.139e-01, -2.828e-01, 1.557e-01, -6.568e-02, 1.567e-02, -1.061e-02, -1.405e-02) * s[0][1][1];
	r0 += M4(-3.094e-01, 2.920e-01, 2.172e-01, -6.502e-02, 3.601e-01, -7.623e-02, -4.589e-02, -1.459e-01, -2.584e-02, -2.192e-01, -1.864e-02, 1.295e-01, 1.539e-01, -1.887e-01, -1.161e-01, 6.074e-02) * s[0][2][0];
	r0 += M4(1.421e-01, 9.956e-02, 6.362e-02, -1.097e-01, -4.552e-02, 4.422e-02, -1.012e-01, -8.132e-02, -2.322e-02, -1.278e-01, -9.503e-02, 5.518e-02, -8.758e-02, -1.758e-01, 5.790e-02, 9.938e-02) * s[0][2][1];
	r0 += M4(9.140e-02, 5.375e-02, 1.930e-01, -1.913e-01, -5.350e-02, -1.619e-01, 2.436e-02, 2.474e-01, -1.416e-04, 2.194e-01, 2.655e-01, 5.874e-01, -7.534e-02, 2.173e-01, -7.499e-02, -3.799e-02) * s[1][0][0];
	r0 += M4(-4.762e-02, 8.032e-02, 8.539e-03, -2.368e-01, 1.353e-02, -2.628e-01, 4.416e-02, 5.123e-02, -2.122e-01, 1.986e-01, -2.605e-03, 3.224e-01, 7.422e-02, 6.113e-02, -1.296e-02, 3.277e-02) * s[1][0][1];
	r0 += M4(6.755e-02, -4.186e-01, 4.041e-02, -1.701e-01, 7.912e-01, -2.293e-01, 6.148e-01, 1.501e-01, -6.035e-01, 1.308e-02, 3.156e-01, 5.274e-02, -6.089e-01, 1.716e-01, -1.036e-01, 5.059e-01) * s[1][1][0];
	r0 += M4(1.903e-01, -2.571e-01, -8.497e-03, 2.833e-01, 2.577e-01, -2.128e-01, 6.384e-01, 1.259e-01, -2.670e-01, -5.126e-03, 1.577e-01, 3.495e-01, -6.828e-02, -2.659e-02, 7.839e-02, 2.290e-01) * s[1][1][1];
	r0 += M4(5.062e-01, 3.216e-01, -8.029e-02, -5.178e-02, -1.586e-01, 5.550e-01, -6.255e-02, -5.337e-02, 4.453e-02, -4.463e-01, -2.984e-02, -1.301e-02, -4.268e-01, -1.716e-01, -8.929e-02, -1.533e-01) * s[1][2][0];
	r0 += M4(7.225e-02, 4.137e-01, 3.794e-02, -1.760e-01, -2.366e-01, 3.525e-01, -7.584e-02, 1.584e-01, -2.778e-02, -1.372e-01, -2.353e-02, -2.278e-01, 1.326e-02, -1.071e-01, -4.794e-02, -9.705e-02) * s[1][2][1];
	r0 += M4(3.760e-01, -1.526e-01, 1.360e-01, -5.647e-01, -5.525e-02, 4.917e-02, -2.395e-02, 1.017e-02, 2.048e-02, 1.152e-01, 1.877e-01, 2.006e-01, -1.825e-01, 5.767e-02, 9.253e-03, 3.797e-02) * s[2][0][0];
	r0 += M4(-2.270e-02, 5.067e-02, -1.751e-01, -8.796e-02, -4.384e-03, -1.016e-01, -1.243e-01, -1.695e-01, -2.200e-03, 1.194e-01, 2.432e-01, 2.725e-01, 6.969e-02, -5.710e-02, 3.600e-02, -9.518e-02) * s[2][0][1];
	r0 += M4(-3.927e-02, -2.033e-01, -5.511e-01, 1.677e-01, -7.723e-02, 1.538e-01, -2.551e-01, -4.343e-01, 1.715e-01, 4.222e-02, 5.879e-01, 5.104e-01, -1.520e-01, 3.489e-01, 2.792e-01, 4.361e-01) * s[2][1][0];
	r0 += M4(-2.163e-02, -1.446e-01, -4.172e-01, -2.673e-01, -7.782e-03, 7.070e-02, 2.133e-02, -3.529e-01, 5.463e-02, 5.305e-02, 4.133e-01, 1.697e-01, -4.599e-02, 5.883e-03, -1.691e-01, 2.989e-01) * s[2][1][1];
	r0 += M4(-2.666e-01, 6.035e-01, -3.256e-01, -8.109e-02, 8.324e-03, 1.893e-02, 5.806e-02, 5.909e-02, 1.715e-02, -2.846e-01, -6.807e-02, -1.757e-01, 8.878e-02, -2.639e-01, 1.168e-01, -3.906e-02) * s[2][2][0];
	r0 += M4(-7.500e-02, 2.702e-01, 9.786e-02, 1.221e-01, 4.496e-02, -6.337e-02, 2.418e-02, 1.629e-01, 3.660e-02, -1.713e-01, 4.714e-02, -1.750e-01, 3.721e-02, -5.771e-02, -2.569e-01, -1.102e-01) * s[2][2][1];
	r0 += V4(1.406e-02, -3.653e-02, 2.288e-02, 3.387e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv6
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
#define l0(x, y) V4(texelFetch(conv5_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(3.893e-02, -5.162e-02, 4.943e-02, -1.614e-02, 1.362e-01, -1.248e-01, 1.986e-02, -5.027e-02, 6.728e-02, -1.528e-03, -1.776e-02, 2.452e-02, 4.428e-02, -1.839e-02, -7.616e-02, 1.215e-01) * s[0][0][0];
	r0 += M4(-3.083e-02, 3.765e-02, 5.014e-02, 1.916e-02, -3.210e-03, -1.185e-01, 7.731e-02, 2.020e-01, 2.216e-02, 3.866e-02, 1.801e-02, -6.472e-02, 6.420e-02, 6.418e-02, 4.647e-03, -9.437e-04) * s[0][0][1];
	r0 += M4(-5.813e-02, 5.850e-02, -4.291e-02, 6.320e-02, -1.372e-01, -1.644e-01, 2.015e-01, 3.486e-01, -3.087e-01, 2.635e-01, -8.977e-02, 5.335e-01, -1.082e-01, 1.003e-01, 4.543e-03, 5.711e-02) * s[0][1][0];
	r0 += M4(-1.468e-01, 1.459e-01, 3.352e-02, 7.684e-02, -2.542e-02, -4.157e-01, 9.403e-02, 4.868e-01, -1.694e-01, 8.314e-02, 4.137e-03, 2.862e-01, -6.842e-02, 1.376e-02, -4.776e-02, 2.323e-01) * s[0][1][1];
	r0 += M4(2.064e-02, -7.108e-03, 7.544e-02, 2.932e-02, -1.144e-02, -7.974e-04, 7.149e-02, 8.660e-02, 1.214e-01, 1.245e-01, 2.358e-01, 1.126e-02, -3.607e-03, -1.946e-01, -7.818e-02, 2.065e-01) * s[0][2][0];
	r0 += M4(-7.393e-03, 1.641e-01, 2.190e-02, -5.593e-02, 3.510e-02, -1.020e-01, 5.241e-02, 5.028e-02, 9.254e-03, 1.472e-01, 3.342e-02, -6.800e-02, 3.478e-03, -1.587e-01, 2.570e-01, 2.532e-01) * s[0][2][1];
	r0 += M4(-3.910e-02, 3.462e-02, 3.830e-02, -4.238e-02, -8.478e-03, 6.199e-03, 3.188e-02, -1.169e-01, 1.000e-01, 1.431e-01, -9.096e-02, -8.184e-02, -1.402e-02, -9.543e-02, -9.960e-02, 2.248e-01) * s[1][0][0];
	r0 += M4(-1.889e-02, -3.657e-02, -1.035e-02, -6.321e-02, 1.095e-02, -5.557e-02, 2.472e-02, 4.946e-02, 6.372e-02, 1.004e-01, -5.682e-02, -1.076e-01, -4.196e-02, -3.358e-02, 8.176e-02, 3.424e-02) * s[1][0][1];
	r0 += M4(-3.057e-01, 3.258e-01, 1.197e-01, -8.721e-02, 1.454e-01, 2.302e-01, 4.440e-01, 1.608e-01, -7.042e-02, 3.373e-03, -3.927e-02, 9.686e-03, -4.410e-01, -1.409e-01, 4.578e-01, -1.157e-01) * s[1][1][0];
	r0 += M4(-2.757e-01, -1.500e-02, -7.544e-02, 2.744e-01, -7.439e-02, 3.933e-01, 4.580e-01, -6.002e-02, -2.685e-01, -3.986e-01, -4.952e-03, 6.026e-01, -2.446e-01, -1.914e-01, 8.655e-02, -1.424e-02) * s[1][1][1];
	r0 += M4(-1.598e-03, -2.441e-03, -2.249e-02, 3.206e-03, -2.712e-02, 2.012e-01, -2.224e-01, -2.906e-01, 1.719e-02, -3.632e-03, 5.757e-01, 1.262e-01, -9.943e-02, -9.851e-02, -6.030e-01, 9.256e-02) * s[1][2][0];
	r0 += M4(7.030e-02, 3.956e-02, -3.018e-01, -2.042e-01, -5.720e-02, 7.006e-02, -2.985e-01, -2.508e-02, -1.497e-02, -1.422e-01, 2.113e-01, 1.205e-01, -1.392e-01, -6.991e-02, 5.840e-03, 2.010e-01) * s[1][2][1];
	r0 += M4(-5.597e-02, 4.003e-02, 1.273e-02, -1.997e-01, 5.203e-03, 2.364e-03, 8.970e-02, -1.441e-01, 9.504e-02, -2.770e-02, -3.439e-03, -3.257e-02, -8.502e-02, 7.203e-02, -4.032e-02, -2.697e-02) * s[2][0][0];
	r0 += M4(-8.089e-02, 4.422e-02, 1.523e-01, -1.094e-01, -5.721e-02, 2.350e-03, 8.003e-02, -5.886e-02, 7.482e-02, -3.328e-02, 6.772e-02, -1.613e-01, -7.446e-02, 5.023e-02, 1.953e-02, -6.481e-03) * s[2][0][1];
	r0 += M4(-3.048e-01, -1.414e-01, 1.097e-02, -1.968e-01, -3.851e-02, -1.104e-01, 9.591e-02, 6.589e-02, 1.074e-01, 6.429e-02, 2.906e-02, -5.920e-02, -3.842e-02, 5.411e-03, -1.169e-01, 5.169e-02) * s[2][1][0];
	r0 += M4(-1.582e-01, -1.168e-01, -2.850e-02, -1.075e-01, -1.101e-01, -9.937e-02, 1.126e-01, 1.231e-01, 4.804e-02, 1.800e-01, 2.731e-02, -1.851e-01, -1.255e-01, 1.453e-03, -5.786e-02, 1.242e-01) * s[2][1][1];
	r0 += M4(-2.240e-02, -1.034e-01, -7.849e-02, 6.532e-02, 4.843e-02, -2.176e-02, 1.219e-01, -1.625e-02, -2.586e-02, 1.789e-02, 1.663e-01, -1.716e-02, -4.060e-03, -5.168e-02, -2.744e-01, 6.005e-02) * s[2][2][0];
	r0 += M4(3.809e-02, -7.871e-02, -6.330e-02, 8.410e-02, -4.619e-02, -6.210e-02, 1.434e-02, 1.080e-01, -8.904e-03, 1.154e-01, -1.092e-01, -1.167e-01, -8.298e-02, -9.094e-04, -1.133e-02, 9.737e-02) * s[2][2][1];
	r0 += V4(-2.302e-01, -1.420e-02, 6.275e-02, 3.266e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv7
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
#define l0(x, y) V4(texelFetch(conv6_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(1.133e-01, 2.170e-01, 1.110e-01, 2.366e-02, 6.444e-02, 1.715e-03, 7.005e-03, -4.217e-02, -3.397e-02, 4.511e-02, -8.328e-02, -1.952e-01, 9.692e-02, 4.114e-02, 3.192e-02, -2.439e-01) * s[0][0][0];
	r0 += M4(1.671e-03, 1.031e-02, 1.161e-02, -1.558e-02, 1.954e-02, 4.403e-02, -1.835e-04, 3.516e-02, -2.228e-02, -1.073e-01, 3.689e-02, 2.689e-02, 7.725e-02, 2.856e-02, 5.754e-02, -3.652e-03) * s[0][0][1];
	r0 += M4(-1.308e-01, 3.034e-01, 2.176e-01, -2.576e-02, 8.514e-02, 2.100e-02, 1.297e-02, -2.485e-02, 3.094e-02, -6.545e-02, -4.004e-02, 2.611e-03, -1.235e-02, 4.800e-02, -1.421e-01, -3.102e-01) * s[0][1][0];
	r0 += M4(4.114e-02, 4.037e-02, -6.178e-03, -3.326e-02, 5.318e-02, 5.487e-02, 8.852e-02, 1.036e-01, 1.266e-01, -6.585e-02, -1.269e-01, 1.051e-01, -3.321e-02, 2.846e-02, -3.284e-02, -4.638e-02) * s[0][1][1];
	r0 += M4(-5.856e-03, 8.811e-02, 9.869e-02, 4.065e-02, 3.797e-02, -1.413e-03, 6.616e-02, -1.064e-02, 7.070e-03, -1.504e-02, -3.672e-02, -7.363e-03, 6.438e-02, 2.420e-02, 2.502e-02, -6.567e-02) * s[0][2][0];
	r0 += M4(7.412e-03, 3.553e-02, -3.677e-02, -5.133e-02, -6.344e-02, -7.312e-03, 3.886e-02, -6.337e-02, -3.280e-03, 3.053e-02, -2.695e-02, -4.572e-04, 2.255e-02, 3.243e-02, 1.563e-02, -1.759e-02) * s[0][2][1];
	r0 += M4(-1.167e-01, -2.791e-02, 8.233e-02, -3.633e-02, 6.861e-02, -8.280e-02, -5.436e-02, -5.490e-02, -2.082e-02, -3.164e-01, -4.366e-01, -1.246e-01, -9.065e-02, 2.163e-03, -5.080e-02, 1.972e-01) * s[1][0][0];
	r0 += M4(-3.739e-03, -1.102e-01, -4.236e-02, 8.062e-03, -5.415e-02, -8.200e-02, -1.205e-01, -2.511e-01, -1.549e-01, -3.389e-01, -1.491e-01, 4.737e-02, -5.159e-02, -4.408e-02, -1.091e-02, 4.710e-03) * s[1][0][1];
	r0 += M4(-1.104e+00, 1.361e-01, 2.646e-01, 2.360e-01, -6.977e-02, 2.340e-01, 9.084e-02, 3.936e-01, -1.458e-02, 6.763e-02, -3.549e-01, -1.597e-01, 1.810e-01, 2.540e-01, -3.933e-01, 6.556e-01) * s[1][1][0];
	r0 += M4(-4.973e-01, 2.536e-02, -1.785e-01, 1.615e-01, -3.429e-01, 2.635e-01, 8.469e-02, 6.342e-02, 8.086e-02, 6.771e-02, -7.055e-02, -1.548e-01, -7.678e-02, 1.812e-01, 2.217e-02, 3.272e-01) * s[1][1][1];
	r0 += M4(-1.774e-01, 8.977e-02, 4.735e-01, 1.448e-01, -4.413e-02, 9.785e-02, 1.685e-01, -7.951e-03, 3.212e-02, 1.166e-03, -1.365e-01, 1.429e-02, -5.802e-02, 9.742e-02, 5.067e-01, 7.405e-02) * s[1][2][0];
	r0 += M4(1.879e-02, 3.519e-02, 2.137e-01, 1.181e-01, -1.851e-01, 2.888e-02, -1.958e-02, -1.515e-01, 3.942e-02, 1.474e-02, -1.563e-01, -2.726e-02, -4.944e-02, 8.225e-02, 2.279e-01, 5.236e-02) * s[1][2][1];
	r0 += M4(-5.032e-03, 1.280e-01, 1.049e-01, -5.773e-02, -1.477e-02, -8.614e-02, -1.052e-01, 3.101e-02, 6.470e-02, -2.795e-02, -8.705e-02, 2.339e-02, -1.255e-01, -4.431e-02, -2.381e-02, 4.725e-02) * s[2][0][0];
	r0 += M4(5.183e-02, 1.499e-02, 4.480e-02, 8.533e-03, -7.757e-02, -1.558e-01, -8.538e-02, -7.788e-02, -9.023e-02, -9.939e-02, -1.351e-01, 1.863e-01, -1.059e-02, -2.685e-02, -6.297e-03, 5.556e-02) * s[2][0][1];
	r0 += M4(-1.207e-01, 3.751e-01, 4.118e-01, -3.916e-02, 6.411e-02, -1.313e-01, -6.550e-02, -3.821e-02, 1.456e-02, 6.035e-03, 5.067e-02, -9.452e-03, -7.158e-02, 4.958e-02, 8.962e-02, -1.326e-01) * s[2][1][0];
	r0 += M4(-2.742e-02, 8.306e-02, 1.541e-01, 4.411e-02, 1.681e-01, -2.169e-01, 1.558e-01, -2.770e-01, 6.339e-02, -6.711e-03, -3.086e-02, 8.034e-02, -6.714e-02, -2.973e-02, 1.298e-02, -6.518e-02) * s[2][1][1];
	r0 += M4(-9.915e-03, 9.288e-02, 1.166e-01, 7.006e-02, -6.460e-02, 6.815e-03, 5.534e-02, 4.477e-02, 2.410e-02, 5.757e-02, -3.427e-03, -1.378e-02, -3.173e-02, -8.115e-03, 2.248e-01, -2.401e-02) * s[2][2][0];
	r0 += M4(-4.615e-03, -3.226e-02, -1.493e-01, -1.114e-02, -5.449e-02, -7.184e-02, 6.020e-02, -7.941e-02, -2.508e-02, 1.342e-02, 2.317e-02, 5.517e-04, -1.374e-02, -3.024e-02, -2.112e-02, 7.935e-03) * s[2][2][1];
	r0 += V4(-1.325e-01, -6.079e-03, 5.121e-03, 1.826e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-conv8
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
#define l0(x, y) V4(texelFetch(conv7_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(3.148e-03, -3.837e-02, -2.367e-02, 8.265e-02, 1.052e-02, -1.365e-01, -1.971e-02, -2.557e-02, -2.199e-02, 2.967e-01, -2.632e-02, -1.892e-01, -5.419e-02, -3.174e-03, 8.866e-03, 2.753e-02) * s[0][0][0];
	r0 += M4(2.117e-02, -4.582e-02, -5.569e-03, 8.284e-02, -1.206e-02, -4.105e-02, -4.089e-02, 2.910e-02, -7.304e-03, 1.576e-01, 3.796e-02, -1.036e-01, -3.308e-02, -2.868e-03, -1.478e-02, 3.029e-02) * s[0][0][1];
	r0 += M4(-4.080e-02, 1.130e-01, -8.462e-03, 4.432e-02, 1.119e-02, -4.813e-01, -6.853e-02, 8.132e-02, 3.076e-03, 3.292e-02, -1.115e-01, -7.026e-03, -8.211e-02, -3.486e-01, -9.749e-03, -2.638e-01) * s[0][1][0];
	r0 += M4(-1.482e-02, 2.284e-02, -1.120e-02, 7.256e-02, 4.527e-02, -8.023e-02, 3.595e-02, 4.653e-02, -2.707e-02, -1.646e-02, -3.598e-02, -8.843e-03, 4.410e-02, -1.880e-02, 3.461e-02, 3.236e-02) * s[0][1][1];
	r0 += M4(2.995e-02, -1.067e-02, 3.826e-03, 1.121e-02, 1.369e-02, -1.821e-01, 3.662e-02, 1.045e-01, -1.465e-02, 8.439e-03, 2.408e-02, 7.157e-03, -8.559e-02, 6.421e-02, -7.984e-02, -3.083e-03) * s[0][2][0];
	r0 += M4(4.901e-02, 1.455e-02, 3.363e-02, -4.041e-03, 1.502e-02, -6.231e-02, 8.691e-03, 6.482e-02, -6.436e-03, 4.818e-02, 2.637e-02, -2.394e-02, 1.161e-02, -9.781e-03, -1.582e-02, 3.190e-02) * s[0][2][1];
	r0 += M4(-5.478e-03, 5.432e-02, -2.435e-02, -1.040e-01, -4.753e-02, 2.394e-01, -1.120e-01, -9.636e-02, -1.593e-02, -4.677e-01, 2.482e-01, 6.430e-01, 2.633e-02, -1.009e-01, 4.523e-02, -2.805e-02) * s[1][0][0];
	r0 += M4(-1.888e-02, 8.585e-02, -4.124e-02, -1.356e-01, -1.444e-02, 1.027e-01, 7.030e-02, -2.673e-02, 2.141e-02, -3.506e-01, -2.181e-02, 2.427e-01, -2.872e-03, -4.872e-02, -3.520e-02, -3.603e-02) * s[1][0][1];
	r0 += M4(-2.612e-02, -4.608e-01, 2.105e-02, -5.495e-01, 1.239e-01, 4.838e-01, -8.142e-01, -1.166e-01, 2.181e-01, -1.137e-02, -1.277e-01, -3.960e-02, -1.486e+00, -2.339e-01, -1.113e+00, 1.477e-02) * s[1][1][0];
	r0 += M4(1.297e-01, -2.095e-01, 1.206e-01, -2.940e-01, 2.981e-03, 1.963e-01, -1.372e-01, -8.407e-02, 1.213e-01, -1.264e-01, -7.602e-03, 6.716e-03, -1.304e-01, -1.983e-01, -9.403e-02, 2.252e-01) * s[1][1][1];
	r0 += M4(-3.240e-02, -4.025e-02, -5.067e-02, -8.127e-03, -1.293e-01, 2.331e-01, 8.931e-02, 4.601e-02, -5.212e-02, 1.171e-02, -3.244e-02, 4.974e-02, 4.317e-02, -1.118e-01, 1.265e-01, -6.605e-02) * s[1][2][0];
	r0 += M4(-1.330e-02, -9.254e-02, 1.240e-01, 7.084e-02, -7.048e-02, 1.346e-01, 1.185e-02, -4.143e-02, -4.168e-02, -8.912e-02, 4.773e-02, 5.519e-02, 8.420e-02, 3.338e-02, 7.204e-02, -4.450e-02) * s[1][2][1];
	r0 += M4(-9.351e-02, -1.098e-02, -3.028e-02, -8.220e-02, 2.033e-02, -3.933e-02, -6.740e-02, -8.319e-03, -1.194e-01, 5.137e-02, 1.775e-02, 3.168e-02, 1.266e-02, 2.992e-02, -1.767e-02, -1.208e-01) * s[2][0][0];
	r0 += M4(-1.898e-02, -1.502e-02, -3.674e-02, -6.116e-02, -1.497e-02, 2.349e-02, -2.279e-02, -3.360e-02, 1.523e-02, 6.237e-02, 1.575e-02, -4.738e-02, -5.970e-02, 9.531e-02, -5.638e-02, -8.447e-02) * s[2][0][1];
	r0 += M4(8.864e-02, 2.564e-01, 1.696e-01, -1.198e-01, -3.604e-01, 1.861e-01, -1.042e-01, 7.538e-02, 2.484e-01, -8.325e-02, 1.834e-01, 3.061e-02, 1.135e-01, 1.244e-02, 8.822e-02, 5.598e-02) * s[2][1][0];
	r0 += M4(7.587e-04, 1.426e-01, 1.103e-01, 6.186e-03, -2.336e-01, -4.037e-02, -1.363e-01, 7.009e-03, 9.514e-02, 1.745e-02, 1.082e-01, -2.292e-02, 8.709e-02, 4.406e-02, 1.397e-01, -6.202e-03) * s[2][1][1];
	r0 += M4(8.866e-02, 5.202e-02, -4.217e-02, -1.223e-02, 9.643e-02, 4.003e-02, 4.502e-03, -8.132e-02, 2.146e-02, -1.446e-02, -2.512e-03, 5.118e-02, -1.633e-01, 3.945e-02, -7.495e-02, 7.971e-03) * s[2][2][0];
	r0 += M4(5.946e-02, 1.588e-02, 4.483e-03, -5.543e-05, 8.225e-02, -3.873e-02, 9.121e-03, -4.202e-02, -2.507e-02, 3.155e-02, -5.915e-03, -7.829e-03, 9.918e-03, -2.531e-02, 1.213e-02, -3.983e-02) * s[2][2][1];
	r0 += V4(-6.648e-03, 1.495e-03, -4.109e-03, 8.915e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv8
//!BIND rcas
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
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
#define l0(x, y) V4(texelFetch(conv8_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(-4.247e-01, 3.174e-01, -7.972e-02, 1.370e-01, -5.750e-03, -2.341e-02, 1.371e-02, -2.538e-03, -8.265e-02, -1.305e-01, 2.285e-02, 1.577e-01, -1.814e-02, -6.756e-02, -2.355e-02, -1.667e-02) * s[0][0][0];
	r0 += M4(-6.302e-02, 5.275e-02, -2.775e-02, 4.858e-03, -4.829e-03, -2.248e-02, -1.027e-02, -3.300e-03, 7.706e-02, -6.545e-02, 3.447e-02, 2.740e-02, -1.136e-02, -3.453e-02, -8.280e-03, 2.108e-02) * s[0][0][1];
	r0 += M4(1.509e-01, 4.443e-01, 1.311e-02, 8.938e-02, 3.349e-02, 1.444e-02, -1.174e-02, -4.456e-03, -1.294e-01, 3.853e-01, -1.157e-01, -5.704e-02, -1.061e-01, 4.739e-02, 3.732e-03, 2.977e-02) * s[0][1][0];
	r0 += M4(2.900e-01, -2.327e-02, 5.799e-02, 1.577e-02, 1.288e-02, -2.787e-02, 1.778e-02, -2.186e-04, -7.791e-02, 1.695e-01, -9.001e-02, -5.335e-02, -1.616e-02, 8.472e-02, -1.592e-02, -5.367e-02) * s[0][1][1];
	r0 += M4(9.296e-02, -1.048e-01, 3.186e-02, 6.845e-03, -3.837e-03, 4.893e-02, -2.331e-05, 1.187e-02, -7.949e-03, -7.154e-02, -3.048e-02, 5.431e-03, -1.086e-02, -6.942e-02, 4.965e-02, 5.673e-02) * s[0][2][0];
	r0 += M4(-1.775e-02, 7.660e-02, 2.265e-02, -4.044e-02, -2.056e-02, 2.141e-02, -1.481e-03, 4.994e-03, -9.737e-03, -2.552e-02, -3.480e-02, -6.222e-03, -1.542e-02, -5.856e-02, 1.409e-02, 3.729e-02) * s[0][2][1];
	r0 += M4(-5.015e-02, 3.606e-01, -5.488e-01, 3.467e-01, -4.346e-02, 4.038e-02, -5.893e-02, -2.010e-02, 4.064e-01, -3.296e-01, 2.183e-01, -5.349e-01, 1.076e-01, -9.816e-03, 7.689e-02, -7.251e-02) * s[1][0][0];
	r0 += M4(4.052e-02, 5.857e-02, -3.231e-02, 8.188e-02, -1.203e-01, 1.070e-01, 6.408e-02, -7.953e-03, -7.786e-02, -7.446e-02, 5.294e-02, -1.227e-01, 1.236e-01, -2.482e-02, 9.223e-02, -5.334e-02) * s[1][0][1];
	r0 += M4(-1.208e-01, -5.176e-01, 1.867e-01, 1.792e-01, -1.324e-01, -3.481e-01, 1.440e-01, -6.519e-02, -2.920e-01, 5.797e-01, -1.176e-01, 1.064e+00, -4.906e-01, -2.183e-01, -3.139e-01, -1.580e-02) * s[1][1][0];
	r0 += M4(-2.173e-01, -3.057e-01, 1.927e-01, -2.422e-01, 3.269e-02, -4.274e-01, 1.880e-01, 1.033e-01, 6.175e-02, 2.270e-01, 2.025e-01, 5.490e-01, -6.757e-01, -9.749e-02, -4.756e-01, 6.612e-02) * s[1][1][1];
	r0 += M4(1.239e-03, 4.761e-02, 5.263e-02, -1.323e-01, -2.581e-02, 1.278e-01, -2.924e-02, 1.564e-01, 1.146e-01, -4.782e-02, 7.908e-02, -9.820e-02, 1.062e-01, 2.217e-02, 3.047e-02, -2.860e-02) * s[1][2][0];
	r0 += M4(1.132e-02, -8.914e-02, -9.793e-03, 1.226e-01, -7.446e-03, 1.917e-01, -4.475e-02, 5.745e-02, -1.153e-02, 1.102e-02, 1.423e-02, 3.870e-02, 1.822e-01, -1.812e-01, 3.893e-02, -2.772e-01) * s[1][2][1];
	r0 += M4(4.236e-03, -9.982e-02, 2.061e-01, 1.109e-01, 2.886e-02, 1.795e-02, 2.024e-02, 3.432e-02, -4.598e-02, -7.460e-02, 5.486e-03, -1.275e-01, 2.332e-02, 6.470e-03, 6.372e-02, 1.032e-02) * s[2][0][0];
	r0 += M4(-2.633e-02, -1.082e-02, 6.155e-02, 3.968e-02, 2.843e-01, 5.688e-03, -2.132e-01, 7.485e-03, 2.923e-02, 1.157e-02, -6.324e-02, -3.395e-02, 7.726e-03, 2.893e-02, 3.025e-02, -6.346e-03) * s[2][0][1];
	r0 += M4(1.178e-01, 8.372e-02, -5.583e-02, -2.474e-01, 5.871e-02, 3.497e-02, -5.286e-02, -1.082e-01, 9.505e-03, 5.623e-03, -2.355e-01, -8.655e-02, 8.144e-02, 8.569e-02, -1.640e-01, -5.757e-02) * s[2][1][0];
	r0 += M4(4.581e-02, 2.582e-03, -8.508e-03, -6.610e-03, 1.254e-01, 3.135e-01, -1.274e-01, -5.372e-01, 2.465e-03, 2.677e-03, -1.057e-01, -8.472e-02, 5.586e-02, -2.694e-03, -1.131e-01, -8.763e-03) * s[2][1][1];
	r0 += M4(-5.469e-03, 4.751e-02, 6.953e-03, 1.062e-01, -4.262e-02, 1.519e-03, -9.903e-04, 4.202e-02, -3.503e-02, -3.767e-03, 2.971e-02, -1.366e-02, -3.753e-02, -3.625e-03, -5.526e-03, -5.396e-02) * s[2][2][0];
	r0 += M4(2.441e-02, 3.602e-02, 1.302e-02, -1.075e-02, -2.402e-02, -6.585e-03, -1.212e-02, 1.008e-01, -2.740e-02, 1.228e-02, -1.837e-02, -2.231e-02, -9.301e-02, -5.189e-02, 3.613e-02, -1.838e-02) * s[2][2][1];
	r0 += V4(6.332e-03, 5.112e-03, 5.692e-03, 4.708e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + rcas_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + rcas_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + rcas_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + rcas_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

// CuNNy 3x4C RCAS DS
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

//!DESC CuNNy-3x4C-RCAS-DS-EASU
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

//!DESC CuNNy-3x4C-RCAS-DS-RCAS
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


//!DESC CuNNy-3x4C-RCAS-DS-in
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
	r0 += V4(-6.567e-02, -2.593e-02, 1.198e-01, -1.272e-03) * s[0][0][0];
	r0 += V4(2.918e-04, 3.423e-01, 2.247e-01, 6.097e-01) * s[0][1][0];
	r0 += V4(7.690e-02, -2.710e-02, -1.117e-02, -4.885e-03) * s[0][2][0];
	r0 += V4(3.419e-01, -2.412e-02, -5.757e-01, -6.934e-01) * s[1][0][0];
	r0 += V4(-5.262e-01, 4.546e-01, -1.965e-01, 7.334e-02) * s[1][1][0];
	r0 += V4(3.346e-02, -1.259e-02, 4.230e-02, -4.665e-04) * s[1][2][0];
	r0 += V4(-3.074e-01, 1.117e-02, 8.909e-02, 4.285e-02) * s[2][0][0];
	r0 += V4(5.138e-01, -2.445e-02, 4.690e-02, -3.668e-02) * s[2][1][0];
	r0 += V4(-7.241e-02, -4.911e-03, 9.460e-02, 9.081e-03) * s[2][2][0];
	r0 += V4(-3.341e-04, -1.187e-02, 2.887e-02, 6.415e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-RCAS-DS-conv1
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
	r0 += M4(2.199e-01, 3.406e-01, -1.883e-01, 6.065e-03, -2.962e-03, -4.530e-02, 4.242e-02, 5.641e-02, 8.919e-02, -3.728e-02, -3.799e-01, -9.596e-03, -1.945e-02, -3.626e-02, 6.693e-02, -1.149e-02) * s[0][0][0];
	r0 += M4(1.243e-01, 1.131e-01, -1.066e-01, -1.793e-02, -1.274e-01, -4.153e-01, -9.299e-01, -1.795e+00, 6.230e-02, 6.614e-02, -1.597e-01, -5.415e-02, -2.783e-02, -8.564e-02, -2.644e-02, 3.552e-03) * s[0][0][1];
	r0 += M4(-2.946e-01, 8.341e-01, -1.292e-01, 2.779e-01, 2.836e-01, -1.915e-02, -3.396e-03, 5.356e-02, 8.081e-02, 4.834e-01, 2.825e-01, 1.984e-01, -1.636e-01, -1.483e-01, 7.563e-02, -7.104e-02) * s[0][1][0];
	r0 += M4(-4.993e-01, 1.160e+00, 1.145e-01, 2.355e-01, -8.377e-01, 1.556e+00, -1.599e-01, -2.316e+00, 5.872e-02, 8.138e-01, 2.954e-02, 1.934e-01, -2.164e-01, -2.153e-01, 2.772e-01, -6.631e-02) * s[0][1][1];
	r0 += M4(3.775e-01, -7.953e-01, -6.701e-01, -5.388e-02, -3.741e-02, 3.381e-02, 2.183e-01, 2.048e-01, -2.950e-01, 5.539e-01, 4.992e-01, 1.377e-01, 1.899e-01, -3.849e-01, -2.305e-01, -2.261e-01) * s[0][2][0];
	r0 += M4(1.274e-01, -9.644e-02, 1.187e-01, 7.084e-02, -1.799e-02, 2.410e+00, 1.361e+00, -8.899e-03, -1.808e-01, 3.555e-01, -3.211e-02, -1.448e-01, 1.500e-01, -3.760e-01, -1.910e-01, -6.302e-02) * s[0][2][1];
	r0 += M4(-1.997e-01, 1.617e-01, 3.817e-01, 1.582e-01, -1.353e-03, -1.018e-01, 2.153e-01, -1.026e-02, -4.072e-01, -4.407e-01, -9.972e-02, 5.138e-03, 2.437e-01, 2.559e-01, 7.079e-02, 1.432e-02) * s[1][0][0];
	r0 += M4(3.415e-01, -3.528e-01, -3.843e-01, -8.042e-02, -2.389e-01, 2.260e+00, -5.228e+00, -2.396e+00, -3.045e-01, -4.166e-01, -1.983e-01, -8.896e-02, 2.627e-01, 2.740e-01, 4.036e-02, -9.217e-02) * s[1][0][1];
	r0 += M4(-4.034e-01, -1.254e+00, 3.269e-01, -5.066e-02, -2.678e-01, -9.206e-02, -4.438e-01, 1.510e-01, 5.634e-01, -7.041e-02, -3.136e-01, -5.254e-01, -3.550e-01, 2.615e-02, -6.181e-02, -1.444e-03) * s[1][1][0];
	r0 += M4(-5.836e-02, -5.020e-01, -2.000e-01, -4.565e-01, -5.354e+00, 8.919e-01, -1.672e+01, -2.732e+00, 3.336e-01, 1.295e-01, 2.847e-01, -1.469e-01, -4.522e-01, 1.865e-02, -3.204e-02, 1.282e-02) * s[1][1][1];
	r0 += M4(2.208e-01, -2.435e-01, -2.314e-02, 1.181e-01, -2.204e-01, 1.161e-01, -7.786e-02, 2.446e-01, -3.581e-01, 1.065e-01, 1.912e-01, -6.269e-01, 6.319e-01, -3.850e-01, -3.206e-01, 3.565e-01) * s[1][2][0];
	r0 += M4(-1.842e-01, 4.575e-01, 2.550e-01, -2.300e-01, -5.158e+00, 1.852e+00, -3.156e+00, -9.339e-01, -2.780e-01, -2.698e-01, -9.370e-02, -3.114e-02, 2.446e-01, 3.635e-01, 3.965e-01, -1.931e-01) * s[1][2][1];
	r0 += M4(-7.920e-03, 6.975e-02, 1.224e-03, -1.017e-01, 3.005e-01, 4.191e-02, -3.210e-02, -1.621e-02, -2.098e-01, -1.445e-01, -7.901e-02, 2.731e-02, -2.085e-02, 1.252e-01, 1.372e-01, -1.524e-02) * s[2][0][0];
	r0 += M4(1.331e-01, -9.336e-02, 5.830e-02, 9.669e-02, -1.769e+00, 4.475e+00, -9.312e-01, -2.294e+00, -1.226e-01, 9.351e-02, 2.522e-02, 8.587e-02, 1.620e-01, 3.226e-02, -9.752e-02, -1.249e-01) * s[2][0][1];
	r0 += M4(2.736e-01, 1.426e-02, 3.484e-01, 3.435e-01, -2.130e-01, 1.753e-01, -6.057e-02, 4.476e-02, 5.750e-01, -2.237e-02, 6.805e-03, 5.254e-02, -3.504e-01, 1.245e-01, 3.467e-01, 1.847e-01) * s[2][1][0];
	r0 += M4(1.195e-02, 1.639e-01, 1.760e-01, 7.649e-02, -1.184e+01, -3.310e-01, -1.449e+00, -1.263e+00, -1.839e-02, 7.116e-02, -2.931e-02, -2.025e-01, 1.035e-01, 4.118e-01, -6.595e-01, -1.474e-01) * s[2][1][1];
	r0 += M4(-1.694e-01, -4.678e-02, 8.342e-02, 5.318e-02, 8.778e-02, 5.847e-02, 5.085e-02, 1.331e-01, 1.744e-01, -1.499e-01, 1.372e-01, 3.933e-01, 3.965e-01, -2.020e-01, -2.446e-01, -4.600e-02) * s[2][2][0];
	r0 += M4(-1.832e-01, 7.386e-02, 4.284e-02, 6.699e-02, 9.154e-01, 1.397e+00, 1.459e+00, 2.660e+00, 1.903e-01, -1.520e-01, -7.640e-02, 8.855e-02, -1.600e-01, 1.210e-01, 1.802e-02, -1.704e-01) * s[2][2][1];
	r0 += V4(1.529e-02, -2.032e-02, 3.473e-03, -5.450e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-RCAS-DS-conv2
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
	r0 += M4(-7.907e-02, 2.500e-02, -2.964e-01, -1.831e-01, -1.208e-01, -2.784e-02, 1.431e-01, 2.354e-02, 7.579e-02, 1.488e-01, 3.662e-02, -5.984e-02, -1.636e-01, -1.573e-01, -3.987e-02, 7.134e-02) * s[0][0][0];
	r0 += M4(8.941e-03, 6.540e-04, 8.098e-03, 9.399e-02, -1.280e-01, 9.659e-03, -1.471e-01, -1.272e-01, -5.320e-03, 6.811e-02, -1.951e-02, 3.359e-02, -6.455e-02, -4.058e-02, -3.327e-02, -1.126e-02) * s[0][0][1];
	r0 += M4(3.486e-01, -4.692e-02, -3.844e-01, 1.008e-01, -2.549e-01, 1.965e-02, -1.577e-01, 5.821e-02, -9.994e-02, 6.654e-02, 1.766e-02, -1.566e-01, 6.849e-02, -2.578e-01, 1.599e-01, 4.272e-01) * s[0][1][0];
	r0 += M4(-9.090e-02, -9.595e-02, 1.013e-01, -3.894e-02, -1.404e-02, 4.422e-02, -2.779e-01, 8.772e-02, 1.396e-01, 3.577e-02, -8.865e-03, 6.792e-02, -7.759e-02, -6.190e-02, 1.265e-01, 1.378e-01) * s[0][1][1];
	r0 += M4(2.773e-01, -1.049e-01, -1.731e-01, 3.734e-02, 9.402e-02, -7.270e-02, 2.127e-01, 2.627e-01, -1.616e-01, -2.132e-03, -1.459e-02, -2.652e-03, -2.266e-01, -4.562e-02, 1.110e-01, 5.374e-02) * s[0][2][0];
	r0 += M4(9.519e-02, -3.280e-01, 7.076e-01, 7.614e-01, 2.176e-01, -2.066e-02, -1.009e-01, 2.834e-02, -3.891e-02, -2.720e-02, -3.046e-02, -9.224e-02, -7.107e-02, -3.477e-02, 8.947e-02, 1.294e-01) * s[0][2][1];
	r0 += M4(-9.863e-01, -2.563e-01, 2.156e-01, -1.069e-01, -2.152e-01, -2.092e-01, 3.885e-02, -1.751e-02, -3.564e-01, 1.868e-01, 4.736e-02, -3.558e-02, 2.359e-01, -4.506e-01, -1.199e-01, -1.001e-01) * s[1][0][0];
	r0 += M4(-8.187e-02, -1.811e-01, 8.487e-02, -1.193e-01, -1.431e-01, -1.866e-01, -3.672e-02, -1.227e-01, -3.283e-01, 1.610e-01, 1.893e-01, -1.179e-01, 9.738e-02, 4.301e-02, 1.648e-01, 1.501e-01) * s[1][0][1];
	r0 += M4(-4.057e-01, 3.587e-01, 4.872e-01, 7.547e-01, -3.688e-01, -1.209e-01, 9.375e-01, 2.191e-01, -4.992e-01, 2.573e-01, -4.600e-01, -5.611e-02, -6.964e-04, -6.369e-01, 1.463e-01, -1.829e-01) * s[1][1][0];
	r0 += M4(-2.401e-01, 2.706e-01, 2.416e-01, 3.994e-01, -3.753e-01, -1.697e-01, 5.378e-01, -2.016e-01, 3.646e-01, 1.758e-01, -3.721e-01, -3.874e-02, 1.757e-01, 1.014e-01, 1.228e-01, -1.854e-01) * s[1][1][1];
	r0 += M4(1.888e-01, -1.782e-02, 1.640e-01, 1.548e-01, -5.321e-01, -2.079e-02, 2.136e-01, 9.482e-02, -1.809e-02, -4.118e-02, -1.597e-01, -2.745e-01, -3.358e-02, 3.849e-02, -1.073e-02, 7.281e-02) * s[1][2][0];
	r0 += M4(6.021e-01, 3.152e-02, 6.155e-01, 9.640e-02, 1.811e-01, -1.523e-02, 7.202e-02, 9.675e-02, 2.750e-02, -1.978e-02, 1.297e-02, -9.439e-02, -1.220e-01, 3.580e-02, -8.330e-02, -1.760e-02) * s[1][2][1];
	r0 += M4(-1.647e-01, 1.274e-01, -4.559e-03, 9.351e-02, 1.980e-02, -6.727e-02, -5.062e-02, 1.449e-01, -1.053e-01, 2.175e-01, 3.174e-02, 5.774e-02, 1.967e-01, -3.453e-01, -1.214e-01, -2.255e-01) * s[2][0][0];
	r0 += M4(-1.431e-01, 1.274e-01, -4.094e-03, 1.204e-01, -7.474e-02, -8.820e-02, 6.108e-02, 1.093e-01, -2.017e-01, 1.292e-01, 5.455e-02, -6.130e-02, 6.618e-02, -2.417e-01, -1.466e-01, -6.860e-02) * s[2][0][1];
	r0 += M4(9.772e-02, 1.304e-01, 6.411e-02, 1.905e-02, -2.412e-01, 5.446e-02, -6.998e-02, 4.647e-01, -5.061e-01, 7.423e-02, 1.583e-01, 3.787e-01, -2.883e-01, -1.595e-01, -3.911e-02, 3.009e-02) * s[2][1][0];
	r0 += M4(-6.103e-02, 4.644e-02, -9.497e-02, -6.132e-02, -2.886e-01, 1.444e-01, 9.696e-02, 4.798e-01, 1.718e-01, -2.787e-02, -2.427e-01, -4.561e-01, 1.240e-02, -1.458e-02, -2.145e-01, -6.032e-02) * s[2][1][1];
	r0 += M4(5.344e-02, -2.909e-03, 1.066e-02, 8.385e-03, 1.690e-01, 7.063e-02, -1.030e-01, -2.111e-01, -5.927e-02, 5.034e-02, 1.231e-01, 2.185e-01, 9.064e-02, -2.621e-02, -2.632e-01, -1.670e-01) * s[2][2][0];
	r0 += M4(-2.690e-01, -4.175e-02, 6.957e-02, 1.521e-01, 7.494e-02, 1.757e-02, 1.478e-01, 1.544e-01, 3.714e-02, 2.704e-02, -1.101e-01, -1.880e-01, -4.004e-02, -5.669e-02, -6.528e-02, -8.719e-02) * s[2][2][1];
	r0 += V4(-3.153e-02, 1.636e-01, -3.234e-02, -7.898e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-RCAS-DS-conv3
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
	r0 += M4(1.441e-01, -1.947e-02, 1.604e-01, -2.551e-02, 6.212e-02, 3.768e-02, -1.366e-02, -4.668e-03, 1.191e-02, -3.837e-02, -2.810e-02, -1.126e-02, -1.900e-02, 1.765e-02, -6.306e-03, -1.447e-02) * s[0][0][0];
	r0 += M4(-4.971e-02, 1.575e-02, 7.340e-03, 2.505e-02, 4.300e-01, -2.448e-01, 6.952e-02, -1.411e-01, -9.534e-03, -4.227e-02, 2.267e-02, 6.243e-02, 1.265e-01, 9.623e-03, -7.330e-02, -7.007e-02) * s[0][0][1];
	r0 += M4(-3.261e-02, -3.266e-01, -1.235e-01, 1.689e-01, 6.095e-02, -1.119e-01, -2.181e-02, -2.030e-02, -6.818e-03, 8.228e-02, 1.369e-02, -2.129e-02, 1.219e-02, -4.261e-02, -4.328e-04, 4.163e-03) * s[0][1][0];
	r0 += M4(-8.910e-02, 9.111e-02, -1.374e-02, -2.196e-02, 7.455e-01, -1.340e+00, -2.436e-01, -1.744e-01, -2.644e-01, 1.799e-01, -9.413e-03, -2.242e-02, 3.003e-01, -1.813e-01, 3.202e-03, -6.757e-02) * s[0][1][1];
	r0 += M4(-8.100e-02, -5.971e-02, 8.667e-02, 8.179e-02, -4.413e-02, 3.021e-02, 2.069e-02, 4.339e-02, -1.433e-02, -1.407e-02, -8.571e-03, 6.092e-02, 2.819e-02, -1.057e-02, -7.127e-03, -2.260e-02) * s[0][2][0];
	r0 += M4(5.412e-03, 2.207e-02, -3.984e-02, -7.299e-02, 1.986e-01, -4.562e-01, 3.555e-01, 3.251e-01, -4.619e-02, -4.494e-03, 1.032e-01, 1.004e-01, 1.992e-01, -3.092e-02, -3.825e-02, 3.978e-02) * s[0][2][1];
	r0 += M4(-9.275e-03, -1.755e-02, 6.378e-01, 1.209e+00, -1.376e-01, 8.036e-02, 4.035e-02, 3.106e-02, -3.711e-02, -6.069e-02, -4.783e-03, 6.310e-02, 1.279e-01, 2.430e-02, -6.468e-02, -1.160e-01) * s[1][0][0];
	r0 += M4(-1.757e-02, 2.066e-02, 1.441e-02, -3.060e-02, 2.250e-01, -5.764e-01, 3.239e-01, 4.829e-01, -7.843e-03, -4.695e-02, -3.724e-02, 5.683e-03, 1.324e-01, -1.042e-03, -6.733e-02, -1.074e-01) * s[1][0][1];
	r0 += M4(9.290e-02, -2.022e-01, -4.344e-01, -6.206e-01, -1.079e-01, -1.055e-01, -1.182e-01, -7.658e-02, -4.017e-01, 4.092e-01, 6.626e-02, -5.692e-02, 2.097e-01, -4.658e-01, -3.823e-02, 1.101e-01) * s[1][1][0];
	r0 += M4(-8.673e-02, 3.194e-02, -7.788e-02, -2.028e-01, -1.028e-01, -2.857e+00, -9.104e-01, -5.815e-01, 6.494e-02, 3.859e-01, 2.861e-02, -3.350e-01, -2.380e-01, -3.583e-01, -2.706e-01, -1.541e-02) * s[1][1][1];
	r0 += M4(1.649e-01, 4.665e-02, -7.829e-01, 1.140e-01, 4.714e-02, 3.918e-02, 1.067e-01, -1.324e-02, -9.401e-02, 6.800e-03, 4.374e-02, 6.712e-02, -1.855e-02, 4.520e-02, -7.904e-03, -4.580e-02) * s[1][2][0];
	r0 += M4(-2.499e-02, 7.155e-03, -6.138e-03, 3.420e-02, 5.422e-02, -1.355e+00, 1.023e+00, -1.108e-01, -9.168e-03, 3.994e-02, 6.910e-02, -1.030e-02, -6.974e-02, 1.352e-02, 1.623e-01, 1.199e-01) * s[1][2][1];
	r0 += M4(-5.959e-02, 1.003e-01, 5.340e-01, -2.100e-01, 3.110e-02, -6.972e-04, 5.495e-02, -2.992e-02, -5.108e-02, 6.666e-02, -2.063e-02, -1.337e-01, -8.568e-02, -6.409e-03, -5.431e-02, 5.579e-02) * s[2][0][0];
	r0 += M4(-1.510e-02, -4.619e-03, -1.362e-03, 1.959e-02, 3.190e-01, -4.301e-01, 8.213e-03, 1.013e-01, 5.824e-02, -3.714e-05, -5.837e-02, 4.993e-02, -5.338e-02, -2.362e-02, -1.270e-03, -2.157e-03) * s[2][0][1];
	r0 += M4(7.634e-02, -1.224e-01, -5.257e-01, 9.615e-02, 5.116e-02, -3.085e-02, -1.691e-01, 9.995e-02, 1.043e-01, -3.204e-02, 2.836e-01, -3.000e-01, -9.607e-02, -5.635e-02, -8.045e-03, 3.787e-01) * s[2][1][0];
	r0 += M4(-1.811e-02, -1.453e-02, -4.888e-02, 6.019e-02, -2.032e-01, -7.868e-01, -1.269e+00, 4.972e-01, -1.777e-02, 5.384e-02, 1.265e-01, -2.456e-01, -6.165e-02, -1.099e-02, -2.371e-01, 7.814e-02) * s[2][1][1];
	r0 += M4(1.493e-03, 6.666e-02, -4.271e-01, -1.304e-01, 1.801e-02, -2.825e-02, 1.219e-01, 1.213e-02, -1.149e-01, -3.602e-03, -5.577e-02, -9.898e-02, -2.059e-02, -5.369e-03, 1.567e-01, 4.809e-02) * s[2][2][0];
	r0 += M4(-7.041e-03, 3.850e-03, -8.698e-03, -7.815e-03, -2.504e-01, -5.204e-01, 3.505e-01, 2.349e-01, 2.299e-02, 2.754e-02, -1.266e-01, -5.464e-02, -2.848e-02, 3.577e-02, 5.493e-02, -4.943e-02) * s[2][2][1];
	r0 += V4(8.482e-03, 3.137e-02, -1.215e-03, -1.987e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-RCAS-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv3
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
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(7.736e-03, -4.362e-02, 1.233e-02, 4.342e-03, 2.233e-03, 4.927e-03, -3.642e-03, 9.543e-03, -1.284e-01, 1.140e-01, -1.255e-01, 3.057e-02, 7.738e-02, -9.587e-02, 6.155e-02, -1.275e-03) * s[0][0][0];
	r0 += M4(-8.216e-03, -4.618e-02, 4.806e-02, 1.075e-01, -1.249e-02, -2.448e-02, 7.133e-04, -3.189e-03, -7.593e-02, -1.369e-01, -3.811e-02, -9.599e-02, -1.091e-01, -6.358e-02, 1.173e-01, 7.427e-02) * s[0][0][1];
	r0 += M4(-8.130e-02, 9.402e-02, -1.203e-01, -2.937e-02, -4.240e-02, -6.065e-02, -1.137e-01, -9.267e-02, 2.463e-01, -2.635e-01, 1.101e-01, -2.378e-01, -2.627e-01, 1.367e-01, -3.947e-02, 9.090e-02) * s[0][1][0];
	r0 += M4(2.147e-01, 1.164e-01, -2.607e-01, -2.333e-01, -1.249e-01, -6.370e-02, -5.444e-02, -4.674e-02, -9.400e-02, 1.537e-01, -1.196e-01, 1.899e-02, -1.331e-01, -8.771e-02, 1.186e-01, 1.540e-01) * s[0][1][1];
	r0 += M4(8.210e-03, -1.392e-01, 5.729e-02, -4.358e-02, 1.397e-02, -1.351e-02, 1.777e-02, -4.288e-02, -1.115e-01, 5.422e-02, -5.827e-02, 2.727e-02, 1.226e-01, -6.021e-02, 4.658e-02, 3.461e-02) * s[0][2][0];
	r0 += M4(-3.901e-02, 7.696e-02, 1.542e-02, -8.712e-02, 3.479e-02, -5.703e-02, 3.138e-02, 3.654e-03, 1.746e-02, -1.522e-02, 3.674e-02, -9.144e-03, 3.970e-02, -3.196e-02, 6.971e-02, 9.750e-02) * s[0][2][1];
	r0 += M4(2.704e-02, -3.171e-02, 1.837e-02, -7.423e-02, 1.367e-01, -1.450e-01, 1.905e-01, -3.411e-02, 2.539e-03, -4.118e-02, -2.356e-02, 4.321e-02, 6.528e-02, -4.110e-02, 1.235e-01, -8.631e-02) * s[1][0][0];
	r0 += M4(-1.681e-02, -4.613e-02, 2.597e-01, -2.155e-01, 6.245e-02, -1.447e-01, 1.406e-01, -2.623e-02, 5.822e-02, 4.047e-02, -1.389e-02, -2.175e-02, 4.700e-01, 1.316e-01, -2.149e-01, -7.499e-02) * s[1][0][1];
	r0 += M4(-2.489e-02, 7.333e-02, 1.589e-01, 2.853e-01, 4.824e-01, 6.182e-01, 4.544e-01, 5.170e-01, 1.964e-03, 1.381e-02, 1.810e-01, -2.026e-02, -1.077e-01, 1.613e-01, -2.607e-01, 2.290e-01) * s[1][1][0];
	r0 += M4(-7.051e-01, -3.425e-01, 4.709e-01, 8.344e-01, 1.869e-02, 4.268e-01, 7.214e-02, 3.633e-01, -7.083e-04, -3.067e-03, 3.460e-02, 1.901e-01, 9.185e-02, 6.152e-01, -7.721e-01, -4.220e-01) * s[1][1][1];
	r0 += M4(8.313e-03, -7.848e-02, -6.043e-02, -1.285e-01, -1.445e-01, 6.300e-02, -1.508e-01, 6.624e-02, -8.099e-03, -2.530e-02, -8.374e-02, 3.767e-04, 1.040e-01, -2.669e-02, 1.675e-01, -8.453e-02) * s[1][2][0];
	r0 += M4(8.034e-02, -2.998e-01, -3.329e-02, 2.191e-02, 8.081e-02, -1.223e-01, 1.882e-02, -1.066e-01, -1.106e-02, -6.962e-03, -3.489e-02, -1.662e-02, 2.665e-01, 1.455e-01, 8.932e-02, -3.486e-01) * s[1][2][1];
	r0 += M4(-5.155e-03, -2.542e-02, -4.088e-04, -2.781e-02, 2.388e-02, 5.760e-02, -2.886e-02, -7.256e-02, -1.582e-02, -5.524e-03, 1.345e-02, 7.387e-03, 6.824e-03, 3.406e-02, -2.988e-02, -1.612e-02) * s[2][0][0];
	r0 += M4(6.118e-02, -1.268e-03, -9.198e-02, 3.413e-02, 4.732e-02, 5.469e-02, -3.461e-02, -8.021e-02, -6.421e-03, -2.428e-02, 5.766e-02, 1.639e-02, -1.506e-01, 8.131e-02, -3.518e-02, 5.430e-02) * s[2][0][1];
	r0 += M4(4.536e-02, 7.791e-02, -1.195e-01, -2.214e-02, -1.283e-01, -8.955e-02, -4.929e-02, 5.022e-02, 7.635e-03, -2.169e-03, -2.899e-02, 2.179e-03, -2.999e-02, -2.127e-02, -6.915e-02, -1.514e-02) * s[2][1][0];
	r0 += M4(2.646e-01, 2.568e-01, -1.329e-01, -1.818e-01, -1.204e-01, -3.628e-02, -2.184e-01, 3.465e-02, -2.211e-03, -6.094e-04, -3.107e-02, -6.360e-02, -1.494e-01, -2.844e-01, 1.880e-01, 6.672e-02) * s[2][1][1];
	r0 += M4(-1.638e-02, -1.766e-02, -1.334e-04, -7.505e-02, 5.356e-02, -2.577e-02, 4.716e-02, -9.814e-03, -2.855e-03, -3.043e-03, 1.947e-02, 5.688e-03, 1.633e-02, 5.362e-03, 5.017e-02, -6.785e-03) * s[2][2][0];
	r0 += M4(-4.364e-02, 2.928e-02, 4.509e-02, -2.744e-02, 6.165e-02, -1.624e-03, 1.353e-01, -6.620e-02, 4.956e-03, -7.665e-03, 1.207e-02, -5.542e-03, -3.171e-02, -4.949e-02, 4.282e-02, 1.806e-01) * s[2][2][1];
	r0 += V4(1.257e-03, 2.328e-03, 1.557e-03, 2.603e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + rcas_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + rcas_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + rcas_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + rcas_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

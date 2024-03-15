// CuNNy 8x4C RCAS
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

//!DESC CuNNy-8x4C-RCAS-EASU
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

//!DESC CuNNy-8x4C-RCAS-RCAS
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


//!DESC CuNNy-8x4C-RCAS-in
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
	r0 += V4(-4.118e-01, 1.279e-02, 6.421e-02, 4.659e-02) * s[0][0][0];
	r0 += V4(2.455e-01, -1.459e-01, -9.731e-02, -5.772e-01) * s[0][1][0];
	r0 += V4(2.363e-03, -2.288e-02, 1.857e-01, 2.804e-02) * s[0][2][0];
	r0 += V4(-3.451e-01, 5.802e-01, 1.589e-01, -2.829e-01) * s[1][0][0];
	r0 += V4(5.549e-01, -3.821e-01, 5.678e-01, -2.541e-02) * s[1][1][0];
	r0 += V4(3.823e-02, -1.113e-01, -7.638e-02, 2.092e-03) * s[1][2][0];
	r0 += V4(-2.021e-02, -4.472e-02, -2.236e-01, 3.499e-02) * s[2][0][0];
	r0 += V4(2.095e-02, 1.415e-01, -4.697e-01, 2.465e-03) * s[2][1][0];
	r0 += V4(-4.606e-02, -5.897e-02, -1.614e-01, -2.864e-03) * s[2][2][0];
	r0 += V4(-6.094e-02, -3.012e-02, -4.460e-02, 6.741e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv1
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
	r0 += M4(6.158e-03, 2.608e-03, 7.094e-02, -1.352e-03, 2.809e-01, -2.123e-01, -1.015e-01, 3.556e-02, 1.389e-01, 3.098e-01, -2.758e-02, 1.507e-01, 2.313e-01, 8.643e-01, -4.882e-01, -7.230e-01) * s[0][0][0];
	r0 += M4(-1.790e-02, 6.643e-03, -1.849e-02, -1.567e-02, -3.413e-02, -2.046e-01, -1.304e-01, -4.258e-02, 1.574e-01, 1.569e-01, -3.284e-02, 1.216e-01, -3.406e-02, 1.347e-01, -9.518e-02, 7.790e-02) * s[0][0][1];
	r0 += M4(1.248e-01, -3.403e-01, 2.171e-01, -5.080e-04, 7.363e-02, 3.299e-01, 4.700e-02, -3.813e-01, 6.929e-02, -2.003e-01, 9.837e-02, -1.416e-02, -1.181e+00, 1.577e+00, 1.179e-01, -2.473e-01) * s[0][1][0];
	r0 += M4(-8.332e-02, -4.270e-01, 1.244e-01, -3.043e-01, 8.462e-02, 1.874e-02, 8.981e-02, -6.198e-01, 1.594e-01, -1.924e-01, -8.825e-02, -4.977e-02, 2.172e-02, 1.002e-01, -1.036e-01, -1.868e-02) * s[0][1][1];
	r0 += M4(6.531e-02, -1.512e-01, -2.708e-02, 1.669e-02, 1.602e-01, 1.665e-01, -2.015e-01, 7.232e-02, 1.246e-02, 7.487e-02, -1.332e-01, -6.399e-03, 3.184e-01, 1.217e+00, 3.689e-02, -7.866e-01) * s[0][2][0];
	r0 += M4(8.289e-02, 2.520e-02, 5.148e-02, 1.789e-01, 1.524e-01, -1.808e-01, -2.660e-01, -1.954e-01, -2.725e-02, -2.139e-02, -9.907e-02, -2.860e-02, -2.688e-02, 1.493e-01, 1.054e-01, 1.943e-01) * s[0][2][1];
	r0 += M4(3.751e-01, -2.030e-01, -2.411e-01, 7.643e-02, 1.358e-01, 2.333e-01, 4.443e-02, 1.704e-01, 1.195e-01, -5.958e-02, -5.216e-02, 1.538e-01, 1.844e+00, 1.210e-01, 1.122e+00, -1.809e+00) * s[1][0][0];
	r0 += M4(2.046e-01, -5.342e-02, -1.431e-01, 4.624e-02, 1.696e-01, 7.947e-02, -3.883e-02, 3.021e-01, 5.612e-01, -1.474e-01, -8.642e-02, 1.302e-01, 1.282e-01, 3.057e-01, -4.587e-03, 1.453e-01) * s[1][0][1];
	r0 += M4(1.997e-01, 2.264e-02, 6.947e-02, -8.128e-01, 5.966e-01, 5.458e-01, 2.446e-01, 3.888e-01, 2.314e-01, 3.622e-01, 6.451e-01, -1.805e-01, 9.550e-01, 3.062e+00, 3.227e+00, 4.023e+00) * s[1][1][0];
	r0 += M4(4.059e-03, 5.997e-01, 3.231e-01, -7.317e-01, 4.956e-01, 2.232e-01, 5.636e-02, 2.603e-01, 3.741e-01, 2.583e-01, 8.167e-01, -3.009e-01, 1.039e-01, -1.407e-01, 2.838e-01, 2.007e-01) * s[1][1][1];
	r0 += M4(1.288e-01, 6.714e-01, -1.885e-01, 3.837e-01, 1.103e-01, -6.637e-03, 4.980e-02, -2.388e-01, -9.698e-03, 2.563e-02, -3.638e-03, -6.579e-02, 1.996e-01, 2.115e+00, 8.609e-01, 5.957e+00) * s[1][2][0];
	r0 += M4(2.191e-01, 6.381e-01, -3.809e-01, 7.493e-02, 1.012e-02, -6.005e-02, 2.373e-01, -2.228e-01, -1.157e-02, 1.273e-02, -1.462e-01, -7.640e-02, 7.394e-02, -8.467e-02, 7.380e-02, 1.732e-02) * s[1][2][1];
	r0 += M4(-3.467e-01, -2.989e-02, 3.596e-02, 1.832e-01, -2.346e-01, -5.096e-02, 7.029e-02, 1.340e-01, 9.840e-02, -8.757e-03, -8.204e-02, -1.776e-02, -4.139e+00, 9.554e-01, 9.421e-01, -2.190e+00) * s[2][0][0];
	r0 += M4(-8.271e-03, -1.095e-01, 7.132e-02, 2.829e-01, -1.982e-01, -1.411e-01, -6.018e-02, 2.839e-01, -5.942e-04, 4.104e-03, -5.961e-02, -1.012e-01, -5.590e-02, -4.561e-02, -6.411e-02, -2.200e-02) * s[2][0][1];
	r0 += M4(-4.743e-01, 3.389e-01, 7.864e-02, -1.998e-01, -5.329e-01, 2.492e-01, 2.941e-01, 1.058e-02, -1.140e-01, -9.064e-03, 1.040e-01, 1.209e-01, -6.096e-01, 9.591e-01, 2.215e+00, 4.306e+00) * s[2][1][0];
	r0 += M4(5.469e-02, 3.021e-01, 7.651e-02, -2.243e-01, -4.220e-01, 5.997e-02, -8.386e-02, 2.516e-02, -8.755e-02, -2.856e-02, 2.170e-01, 1.898e-01, -1.617e-01, -1.805e-01, 2.198e-01, 3.788e-01) * s[2][1][1];
	r0 += M4(-2.529e-01, 9.793e-02, 6.279e-01, 8.598e-02, -2.667e-01, -1.354e-02, 3.166e-01, 1.920e-01, 4.605e-02, -2.263e-03, -4.683e-03, -8.413e-02, 1.183e+00, 1.434e+00, 1.825e+00, 2.563e+00) * s[2][2][0];
	r0 += M4(-1.881e-01, 9.757e-02, 2.728e-01, 5.486e-02, -2.046e-01, -4.862e-02, 1.648e-01, 1.567e-01, 6.535e-02, -6.674e-02, -6.774e-02, -9.399e-02, -1.304e-01, -1.424e-01, 1.269e-02, -1.200e-02) * s[2][2][1];
	r0 += V4(9.200e-02, 1.421e-01, 2.368e-02, 1.538e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv2
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
	r0 += M4(-2.718e-03, 9.309e-02, -5.962e-03, 7.295e-02, 4.503e-02, 1.559e-01, -1.420e-02, -8.988e-02, 2.745e-02, -9.080e-02, -8.441e-02, -7.239e-02, 2.593e-02, -7.566e-02, 6.619e-02, -3.774e-02) * s[0][0][0];
	r0 += M4(3.105e-02, 5.930e-02, 8.184e-03, 1.161e-01, 5.103e-02, -1.556e-01, -6.086e-02, 4.660e-02, -1.328e-01, -2.244e-01, -6.141e-02, -5.918e-02, 6.206e-03, -9.589e-02, 6.176e-02, -9.922e-02) * s[0][0][1];
	r0 += M4(-1.548e-01, 4.628e-02, 3.989e-02, -8.695e-02, 1.080e-02, 1.080e-01, -8.163e-02, -3.263e-02, 2.777e-01, 3.954e-01, -3.428e-01, -1.046e-03, 4.262e-02, -7.149e-02, 9.137e-02, 1.238e-01) * s[0][1][0];
	r0 += M4(-6.547e-02, -3.936e-02, -4.221e-03, -9.795e-02, 5.954e-02, 3.333e-01, -1.510e-01, 3.237e-02, -8.047e-02, 4.610e-01, -1.700e-02, -2.493e-01, 3.034e-02, -2.065e-01, -1.259e-02, -6.720e-04) * s[0][1][1];
	r0 += M4(-5.091e-02, -2.184e-01, -1.520e-02, -3.641e-01, 5.680e-03, -2.822e-01, 1.518e-02, 2.734e-02, 2.780e-01, -3.091e-02, -6.283e-01, -7.398e-01, 8.383e-03, 4.933e-01, 4.475e-02, 6.990e-02) * s[0][2][0];
	r0 += M4(7.322e-03, -1.919e-01, -3.055e-01, 1.539e-01, -5.716e-02, -1.332e-01, -4.775e-02, -1.343e-01, -4.813e-03, -7.479e-02, -7.601e-02, -2.049e-01, -8.664e-03, 6.761e-01, 3.526e-02, 1.003e-01) * s[0][2][1];
	r0 += M4(-2.387e-03, 8.316e-04, 5.597e-02, -1.899e-02, 1.365e-03, -1.343e-01, 5.867e-02, -7.693e-02, 1.776e-01, 2.215e-01, -8.262e-01, -3.793e-01, -1.828e-01, -7.537e-02, -1.031e-01, -5.521e-02) * s[1][0][0];
	r0 += M4(-2.588e-03, -3.106e-03, -1.315e-02, 4.621e-02, 1.733e-03, -4.710e-02, -3.476e-02, 3.229e-02, -2.085e-01, -5.148e-03, -3.607e-01, 1.033e-01, -1.793e-01, -5.108e-02, -7.470e-02, 4.163e-02) * s[1][0][1];
	r0 += M4(1.823e-01, -1.616e-01, 1.731e-01, -2.687e-01, 9.103e-02, -6.665e-01, 2.702e-01, 1.159e-01, 1.309e+00, 1.435e-01, -2.700e-01, -2.770e-01, -4.874e-01, -2.695e-01, -4.047e-01, 7.151e-02) * s[1][1][0];
	r0 += M4(9.374e-02, -9.994e-02, 1.589e-01, -3.082e-01, 3.542e-01, -1.288e-01, 5.475e-01, 9.163e-01, 7.066e-01, 4.097e-02, 4.631e-02, -1.276e-01, -5.254e-01, -3.218e-01, -3.782e-01, 2.642e-01) * s[1][1][1];
	r0 += M4(7.417e-01, 1.496e-01, 4.145e-02, -1.722e-02, 1.313e-01, 1.314e-01, -1.523e-02, 4.098e-01, 2.336e-01, -2.670e-02, -2.873e-01, 7.754e-01, -1.064e-01, -6.882e-02, -3.510e-02, 1.027e-02) * s[1][2][0];
	r0 += M4(-2.421e-01, 5.058e-02, -5.883e-02, 3.669e-01, 4.681e-02, -6.772e-02, -1.094e-01, 1.405e-01, 8.957e-02, 3.065e-02, -1.250e-01, 1.210e-01, -6.247e-02, -4.466e-02, -1.367e-01, -1.080e-01) * s[1][2][1];
	r0 += M4(-6.501e-02, -1.431e-02, -5.414e-02, -1.940e-02, -5.341e-03, 3.772e-02, -5.085e-02, 1.472e-01, 1.026e-03, -3.010e-02, -1.771e-02, -1.005e-01, 8.680e-02, -2.593e-02, -7.023e-02, 8.193e-02) * s[2][0][0];
	r0 += M4(-3.246e-02, 1.619e-02, 2.924e-02, 3.073e-02, 4.663e-02, -1.162e-01, -2.187e-01, -8.714e-02, 1.521e-01, -5.617e-02, 7.337e-02, -7.332e-02, 8.992e-02, -3.045e-02, -7.837e-02, 1.555e-01) * s[2][0][1];
	r0 += M4(1.119e-01, 6.108e-02, -1.089e-01, 2.097e-01, -4.332e-01, 1.824e-01, -2.516e-01, 2.792e-01, -6.176e-01, 4.260e-02, -7.513e-02, 7.900e-02, 3.818e-01, 1.230e-02, -1.606e-01, -1.606e-01) * s[2][1][0];
	r0 += M4(-1.763e-03, 2.098e-02, -1.595e-01, -1.672e-03, 4.193e-02, 2.057e-01, 3.950e-02, 2.420e-01, -4.336e-02, 7.851e-02, 4.909e-02, 1.140e-01, 5.720e-01, 8.774e-03, -3.698e-01, -1.519e-01) * s[2][1][1];
	r0 += M4(4.520e-02, -4.946e-02, -2.161e-01, -1.207e-01, 2.533e-03, -6.526e-02, 1.206e-01, -2.358e-01, -7.812e-02, 2.780e-02, 7.736e-02, 1.196e-01, -1.512e-02, 3.194e-03, -4.396e-02, -5.495e-02) * s[2][2][0];
	r0 += M4(-5.967e-02, -7.788e-02, 6.587e-02, -3.936e-02, -3.426e-02, -7.677e-02, 1.634e-01, -1.100e-01, -6.280e-02, -7.895e-02, 1.316e-01, -5.203e-02, -8.567e-02, -6.878e-03, 3.289e-02, -5.307e-02) * s[2][2][1];
	r0 += V4(4.580e-02, 6.323e-02, 1.109e-01, -1.135e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv3
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
	r0 += M4(6.361e-02, 8.739e-02, 1.841e-01, 1.686e-02, -7.691e-02, 3.556e-02, -1.275e-01, -7.327e-03, -8.180e-02, -9.979e-02, -6.912e-02, -6.625e-02, -5.805e-01, -2.836e-02, -1.882e-01, 1.019e-01) * s[0][0][0];
	r0 += M4(1.162e-01, -2.725e-02, 2.552e-01, 8.774e-02, 5.823e-02, 4.877e-02, -4.970e-02, 3.161e-02, 2.039e-01, 4.954e-02, 8.884e-02, 1.086e-01, -8.722e-02, -6.338e-02, 2.466e-01, 2.002e-02) * s[0][0][1];
	r0 += M4(4.620e-01, -4.535e-01, 8.067e-01, -1.972e-01, -1.304e-02, 1.653e-02, 2.540e-02, -3.967e-02, -8.763e-02, -1.383e-01, -2.471e-01, -1.353e-01, -2.341e-01, 1.267e-01, -4.658e-01, 9.748e-02) * s[0][1][0];
	r0 += M4(-3.463e-02, -1.995e-01, -6.827e-01, 8.841e-02, 7.081e-02, -3.469e-02, 1.798e-01, 7.405e-02, 1.917e+00, 4.576e-01, 6.816e-01, -3.366e-01, 2.047e-01, -4.929e-02, 1.140e-01, -6.089e-02) * s[0][1][1];
	r0 += M4(-3.417e-04, 3.445e-03, 2.842e-01, 2.416e-01, 2.016e-02, 1.483e-02, -3.986e-02, 9.409e-02, -2.021e-02, 2.229e-02, -1.442e-01, -1.422e-01, -8.476e-02, 3.669e-03, -7.358e-02, -7.811e-02) * s[0][2][0];
	r0 += M4(1.428e-01, 2.029e-02, 2.137e-02, -8.447e-02, -1.934e-02, 3.673e-02, -4.370e-02, 1.619e-02, 3.063e-01, 1.538e-01, 1.971e-02, 2.689e-01, 4.182e-02, 4.782e-03, -1.260e-01, -6.224e-02) * s[0][2][1];
	r0 += M4(-8.735e-02, 4.396e-02, -1.064e-01, 8.416e-02, 3.068e-02, -1.490e-01, 4.414e-01, -1.333e-02, 1.445e-01, -3.180e-03, 1.715e-02, 3.829e-02, -6.968e-01, 2.799e-01, -3.182e-01, 5.454e-02) * s[1][0][0];
	r0 += M4(1.095e-01, -6.014e-02, -8.711e-02, 1.119e-01, -3.306e-01, -2.163e-01, 1.184e-01, 8.071e-02, 2.990e-01, -1.099e-01, -5.401e-02, 2.554e-02, -3.280e-02, 8.298e-02, 1.913e-01, -5.830e-02) * s[1][0][1];
	r0 += M4(1.189e-01, 4.744e-01, 4.364e-01, -2.591e-01, 9.998e-02, -1.565e-02, 4.454e-02, 1.298e-01, -4.126e-02, 6.298e-01, 2.428e-01, -9.499e-02, -4.824e-01, -3.385e-02, 6.072e-01, -3.371e-01) * s[1][1][0];
	r0 += M4(8.811e-02, 8.628e-01, -5.966e-01, -1.628e-01, -4.618e-02, 2.336e-01, -5.941e-01, 1.607e-01, -1.372e-01, 1.797e+00, -1.533e+00, -3.166e-01, 2.555e-02, -3.545e-01, 1.576e-01, -5.016e-02) * s[1][1][1];
	r0 += M4(4.436e-02, -4.129e-02, -4.571e-02, -1.599e-01, -3.148e-02, 3.221e-03, -2.008e-01, -1.362e-01, 7.024e-02, -1.458e-01, 6.434e-02, -2.912e-01, -3.727e-01, 1.003e-01, 6.602e-02, 1.073e-02) * s[1][2][0];
	r0 += M4(1.450e-01, -5.401e-02, -2.516e-01, -2.243e-02, -1.094e-01, -2.923e-02, 1.150e-01, -2.764e-01, 7.183e-01, 2.781e-01, -7.985e-02, 3.160e-01, 4.533e-03, 2.556e-02, 2.470e-01, 5.624e-02) * s[1][2][1];
	r0 += M4(4.461e-02, 5.818e-02, -3.184e-02, -9.497e-03, -2.725e-01, -2.821e-01, 4.091e-01, -2.082e-01, 7.315e-02, -1.171e-01, 1.010e-01, 7.404e-04, -2.469e-01, 4.127e-01, -3.955e-01, 1.105e-01) * s[2][0][0];
	r0 += M4(2.759e-02, 4.017e-02, 1.252e-01, 1.093e-02, -4.075e-01, -1.982e-01, -1.429e-01, 8.231e-05, -1.201e-01, 6.163e-02, 1.734e-02, 1.484e-01, 1.432e-01, 2.998e-02, 3.885e-03, -9.405e-02) * s[2][0][1];
	r0 += M4(1.164e-02, -4.519e-04, -6.271e-02, -6.848e-02, 4.628e-02, 1.239e-01, 8.386e-01, -1.180e-01, -2.113e-02, 4.449e-02, -1.898e-01, -1.497e-01, -3.126e-02, 1.244e-01, -1.441e-01, 3.519e-02) * s[2][1][0];
	r0 += M4(8.277e-02, -1.223e-01, -1.461e-01, -1.994e-03, -1.032e-01, 2.325e-01, -3.811e-01, 2.398e-02, -1.199e-01, 1.292e-01, -4.157e-01, 4.111e-02, 1.245e-01, -3.410e-01, 1.487e-01, -2.722e-02) * s[2][1][1];
	r0 += M4(-7.401e-03, -7.759e-02, -8.389e-03, 1.676e-02, -2.663e-02, -9.603e-02, 4.753e-02, -6.791e-02, -5.011e-03, -6.646e-02, 4.502e-02, 7.554e-02, -7.756e-02, -1.747e-02, -7.975e-02, 8.901e-02) * s[2][2][0];
	r0 += M4(4.715e-02, -1.102e-01, 7.931e-02, 1.527e-01, -1.057e-03, -4.871e-02, 1.304e-01, -4.034e-01, 1.698e-01, -2.096e-01, 2.992e-01, 2.402e-01, 1.240e-02, 7.325e-03, -6.638e-02, -3.947e-02) * s[2][2][1];
	r0 += V4(-4.812e-02, -4.029e-02, -3.478e-02, 5.479e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv4
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
	r0 += M4(-1.597e-01, -9.483e-02, -7.524e-02, -1.224e-01, 1.106e-01, -2.251e-02, -1.010e-01, -1.556e-01, -1.110e-01, -2.429e-02, 2.240e-02, 6.884e-02, -1.267e-01, -1.445e-02, -1.276e-02, 7.082e-03) * s[0][0][0];
	r0 += M4(-4.486e-02, 6.858e-02, -2.890e-02, -9.579e-03, 7.055e-02, -9.742e-02, 2.478e-02, 7.784e-02, -1.811e-01, -9.337e-03, -6.738e-02, 3.546e-02, 8.024e-02, -4.253e-01, -7.662e-02, -4.840e-01) * s[0][0][1];
	r0 += M4(-4.086e-02, -1.160e-01, 1.316e-02, -3.233e-01, 1.738e-01, 1.516e-01, -2.462e-01, -1.369e-02, 4.175e-02, 1.032e-01, -5.598e-02, 1.137e-01, 2.124e-02, -1.576e-01, 8.128e-02, -1.323e-01) * s[0][1][0];
	r0 += M4(4.061e-02, -1.998e-01, 1.976e-01, -1.942e-01, 1.117e-02, 6.372e-02, -3.426e-02, 1.939e-01, -6.271e-02, 2.289e-01, -1.303e-01, 1.367e-01, 1.753e-01, -4.103e-01, 1.023e-02, -4.508e-01) * s[0][1][1];
	r0 += M4(3.294e-02, -6.117e-02, -6.506e-02, -1.304e-01, 9.140e-02, -6.849e-02, -1.686e-01, -6.319e-02, -4.948e-04, 6.404e-02, 2.056e-02, 7.159e-02, 6.557e-02, -1.151e-02, 2.395e-02, 5.572e-02) * s[0][2][0];
	r0 += M4(-3.418e-02, -1.328e-02, -4.216e-02, 5.044e-02, 3.786e-03, -6.837e-02, -1.501e-02, 8.673e-02, -1.302e-01, 4.742e-02, 1.241e-03, 6.915e-02, 5.047e-02, -1.707e-01, -5.675e-02, -9.212e-02) * s[0][2][1];
	r0 += M4(1.102e-01, -2.228e-01, -9.108e-02, -1.011e-01, -1.638e-02, -9.636e-03, -1.753e-01, -1.326e-01, -1.219e-01, -1.322e-01, -1.880e-01, 8.262e-02, 2.509e-01, 9.035e-02, -9.811e-02, 9.318e-02) * s[1][0][0];
	r0 += M4(-8.349e-02, 3.455e-02, 7.525e-02, -1.291e-01, -1.568e-01, -9.107e-02, -7.666e-02, -7.660e-02, -5.249e-02, -3.014e-02, -4.191e-01, -4.607e-02, 1.106e-01, -9.569e-01, -1.061e+00, 5.804e-01) * s[1][0][1];
	r0 += M4(4.890e-01, 2.620e-02, 3.011e-01, 4.091e-01, 4.374e-01, 7.490e-01, 5.723e-01, -4.922e-01, -4.264e-01, 4.070e-01, -1.258e-01, 2.187e-01, 2.353e-01, -3.246e-01, -1.188e-01, -1.050e-01) * s[1][1][0];
	r0 += M4(3.096e-01, -1.500e-02, 4.006e-02, -4.357e-02, -6.000e-02, 5.201e-01, 7.221e-01, -6.963e-01, -4.476e-01, 7.516e-01, -3.603e-01, -5.156e-02, -2.543e-01, -5.393e-01, -8.701e-01, -1.707e-01) * s[1][1][1];
	r0 += M4(-2.253e-01, -3.903e-01, 6.967e-01, -2.274e-01, 3.251e-01, 1.636e-01, -1.551e-01, -1.673e-01, -1.120e-02, 8.840e-02, 1.808e-02, 8.098e-03, -3.020e-02, -3.351e-02, 3.420e-02, -1.676e-02) * s[1][2][0];
	r0 += M4(-1.310e-01, 2.643e-02, 3.464e-02, 5.428e-02, 9.221e-02, 4.248e-02, 4.054e-02, -1.792e-01, -1.796e-01, 2.156e-01, -6.302e-02, -7.003e-03, 2.509e-01, -3.705e-01, -1.827e-01, -4.746e-01) * s[1][2][1];
	r0 += M4(1.137e-01, -1.164e-01, 4.948e-02, 9.940e-02, -8.171e-02, -2.744e-02, -1.065e-01, 1.648e-02, -2.717e-02, -8.014e-02, 5.981e-03, -1.298e-01, -1.029e-01, 1.291e-01, 2.946e-02, -7.882e-02) * s[2][0][0];
	r0 += M4(-5.222e-02, 4.526e-02, -6.083e-02, -3.122e-02, -1.237e-01, -1.123e-01, -3.100e-02, -9.344e-03, -1.553e-01, 3.397e-02, -1.967e-01, -1.929e-01, -3.158e-01, -9.155e-02, -6.623e-01, -2.745e-01) * s[2][0][1];
	r0 += M4(-3.316e-01, -6.783e-02, 8.614e-02, -8.676e-02, -1.219e-01, 6.952e-02, -1.302e-01, -7.680e-02, -3.163e-02, -1.263e-01, -8.822e-02, -1.953e-01, 1.341e-01, 3.394e-02, -6.361e-02, 9.940e-02) * s[2][1][0];
	r0 += M4(-5.490e-01, 3.095e-01, 1.825e-01, -3.019e-01, -2.575e-01, -1.128e-01, -8.181e-02, -1.919e-01, -1.218e-01, 1.540e-01, -4.581e-01, -3.975e-01, 1.054e-01, -1.090e-01, -4.465e-01, -1.680e-01) * s[2][1][1];
	r0 += M4(2.173e-01, -1.648e-01, -6.990e-02, 1.017e-01, 1.028e-01, -4.444e-03, -4.906e-02, -3.931e-02, -1.362e-01, 2.613e-03, 2.089e-03, -1.796e-02, -9.713e-02, 1.959e-02, -3.017e-02, 7.191e-02) * s[2][2][0];
	r0 += M4(7.313e-02, 1.122e-01, -4.315e-02, 6.107e-03, 1.508e-01, -1.560e-01, 8.716e-02, -2.965e-02, -2.159e-01, -6.106e-02, 5.692e-02, -8.143e-02, 1.773e-01, 1.274e-01, -2.691e-01, -4.305e-02) * s[2][2][1];
	r0 += V4(-2.326e-01, 9.936e-02, 3.534e-02, -1.565e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv5
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
	r0 += M4(1.042e-01, 1.533e-01, 8.182e-02, -5.138e-02, -2.007e-02, -5.778e-02, -8.824e-02, 1.939e-02, -1.764e-01, -9.250e-04, 1.248e-01, 2.966e-02, -1.611e-02, 6.157e-02, -9.601e-03, 4.910e-02) * s[0][0][0];
	r0 += M4(7.953e-02, 9.694e-02, 2.817e-01, -8.419e-02, 1.695e-02, 1.311e-01, 2.595e-02, 7.858e-02, -4.630e-02, -2.823e-02, -4.059e-02, 2.496e-02, 1.200e-03, 5.978e-02, 1.232e-01, -4.492e-02) * s[0][0][1];
	r0 += M4(-1.310e-01, -8.876e-02, -9.755e-02, 6.099e-02, 9.227e-02, -3.944e-02, 3.421e-02, -8.709e-02, -5.932e-03, -3.630e-02, 4.195e-01, -1.067e-02, -1.900e-01, -4.011e-02, -1.949e-01, 1.143e-01) * s[0][1][0];
	r0 += M4(1.150e-01, -2.125e-02, -2.073e-01, -2.584e-02, 3.470e-02, 3.282e-01, 2.797e-01, -3.353e-02, -1.145e-01, -1.026e-01, 6.324e-02, 1.304e-02, 1.943e-02, -2.223e-02, -1.399e-01, 2.470e-01) * s[0][1][1];
	r0 += M4(2.274e-02, 5.783e-02, 5.807e-02, -2.658e-02, -8.039e-03, 1.683e-03, 2.926e-02, 4.143e-02, 6.676e-02, 7.070e-02, 5.512e-02, 7.127e-02, 7.495e-02, -8.054e-04, -1.053e-02, -3.949e-03) * s[0][2][0];
	r0 += M4(7.509e-02, 1.135e-01, 1.859e-01, 5.593e-02, -1.154e-01, 1.047e-01, 8.565e-03, 1.630e-01, 5.776e-04, -2.128e-02, -8.320e-02, 7.495e-02, 2.403e-02, 5.740e-02, 1.033e-01, 2.207e-02) * s[0][2][1];
	r0 += M4(1.071e-01, 1.199e-01, -8.414e-02, -1.444e-02, 1.910e-01, -4.012e-03, 3.198e-01, 7.153e-02, -3.239e-01, -1.244e-01, 1.621e-01, 1.466e-01, -1.119e-01, 3.938e-02, -3.037e-01, 1.021e-04) * s[1][0][0];
	r0 += M4(-1.859e-01, 2.197e-01, 5.627e-01, -8.389e-02, 2.627e-01, 3.870e-01, 5.018e-01, 6.942e-02, -2.359e-01, -1.494e-01, -1.316e-01, 9.698e-02, 7.655e-02, 9.359e-02, 1.559e-01, -8.257e-02) * s[1][0][1];
	r0 += M4(-2.335e-01, -2.868e-01, -1.836e-01, 1.988e-01, 4.058e-01, -9.041e-02, -2.021e-01, 4.849e-01, 4.015e-01, -5.646e-01, -2.741e-01, 4.871e-01, -6.072e-01, 4.377e-02, -2.555e-01, -6.293e-02) * s[1][1][0];
	r0 += M4(-3.155e-01, 6.081e-02, -7.628e-02, 5.640e-01, 5.909e-01, 3.463e-01, 2.511e-01, 4.289e-01, 1.862e-01, -1.158e-01, -1.625e-01, 5.380e-01, -1.404e-01, 1.229e-01, 2.055e-01, 1.373e-01) * s[1][1][1];
	r0 += M4(6.476e-02, 5.773e-02, -3.859e-02, -4.800e-02, -7.057e-02, -3.015e-02, 1.372e-01, -1.127e-01, -4.399e-02, 2.070e-01, -4.563e-01, -2.122e-02, 1.286e-01, -1.431e-02, -1.399e-01, 4.332e-02) * s[1][2][0];
	r0 += M4(9.487e-02, -6.698e-02, 4.691e-01, -2.948e-02, -1.036e-01, 2.520e-01, -5.001e-02, -2.969e-02, -9.060e-02, 3.720e-02, -3.117e-01, -2.248e-02, 1.004e-01, -8.450e-02, 3.978e-02, 1.027e-01) * s[1][2][1];
	r0 += M4(-2.318e-02, -1.717e-01, 2.108e-02, -1.681e-02, -2.749e-02, 2.822e-01, 5.393e-02, 9.619e-02, 5.923e-02, 1.232e-01, 3.842e-02, 9.452e-02, 1.037e-01, 8.439e-03, -1.231e-01, 3.600e-02) * s[2][0][0];
	r0 += M4(5.887e-02, 2.623e-01, 3.058e-01, -8.017e-02, 9.839e-02, 4.620e-01, 8.145e-02, 3.607e-02, 4.105e-03, -1.255e-01, -1.214e-01, 8.129e-02, 9.299e-02, 9.020e-02, -1.671e-02, 1.653e-02) * s[2][0][1];
	r0 += M4(8.496e-03, 1.845e-01, 4.534e-03, 1.151e-01, -1.626e-01, 1.776e-01, 2.743e-02, 3.072e-02, -1.632e-01, 1.592e-01, -2.980e-01, 2.803e-01, -5.480e-02, 1.519e-01, 2.246e-01, -7.666e-03) * s[2][1][0];
	r0 += M4(-1.499e-01, 2.940e-01, -2.330e-02, -6.669e-02, -6.152e-02, 6.749e-01, 1.421e-01, 1.232e-01, -2.446e-01, 1.831e-01, -1.440e-01, 2.785e-01, -4.218e-03, 3.252e-01, 2.016e-01, 1.053e-01) * s[2][1][1];
	r0 += M4(3.769e-03, -4.990e-02, 5.354e-02, 1.839e-02, 1.382e-01, 2.387e-02, -4.210e-02, 5.583e-02, 2.819e-01, 4.963e-02, 4.215e-04, -1.071e-02, 1.071e-01, 3.485e-02, 7.429e-02, 1.033e-01) * s[2][2][0];
	r0 += M4(-1.675e-02, 2.196e-01, 2.283e-01, -6.757e-02, 1.557e-01, 3.807e-02, -7.152e-02, 9.269e-02, 1.616e-01, -3.648e-02, 1.114e-01, 3.124e-02, 1.263e-01, 1.526e-01, 8.330e-02, 7.244e-02) * s[2][2][1];
	r0 += V4(6.699e-04, 6.706e-02, 5.665e-02, -2.854e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv6
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
	r0 += M4(-9.365e-03, -8.808e-02, 9.950e-03, 1.061e-01, 1.335e-01, -6.516e-02, -9.253e-02, 1.481e-02, 3.944e-02, 9.918e-02, 1.800e-02, 1.229e-01, -8.371e-02, 1.387e-01, -3.840e-02, -2.626e-01) * s[0][0][0];
	r0 += M4(4.456e-02, 5.251e-03, 1.629e-03, 1.623e-02, 2.515e-02, -6.211e-02, -3.132e-02, -2.904e-02, 3.634e-02, 7.402e-03, -1.706e-02, -3.811e-02, -1.484e-02, -1.129e-02, 3.710e-03, -5.898e-02) * s[0][0][1];
	r0 += M4(-2.329e-01, -8.123e-02, 5.430e-02, 5.263e-03, 2.169e-01, -8.882e-03, 1.122e-01, -1.053e-01, 3.839e-01, 6.613e-02, -1.058e-01, -1.396e-01, -2.258e-01, 1.027e-01, -2.026e-01, 7.143e-02) * s[0][1][0];
	r0 += M4(-3.291e-01, 2.102e-02, 1.626e-01, 2.817e-01, 5.527e-02, 1.994e-02, -4.624e-02, -1.759e-01, -1.678e-02, -1.724e-02, -4.651e-02, -7.701e-03, 2.605e-02, -1.819e-01, -8.472e-02, 8.968e-02) * s[0][1][1];
	r0 += M4(-2.178e-02, -2.991e-02, -2.783e-02, 5.785e-02, 2.722e-01, -4.950e-02, -3.112e-02, -5.481e-02, 1.479e-01, -7.786e-02, -3.217e-02, -5.041e-02, -1.360e-02, 1.224e-01, -1.718e-02, -2.113e-01) * s[0][2][0];
	r0 += M4(-1.047e-01, 7.290e-02, 1.667e-02, 1.296e-01, -7.723e-02, 1.764e-02, 4.997e-03, -2.521e-02, 2.132e-02, -4.253e-03, -1.308e-02, -1.222e-02, 4.236e-02, 1.848e-02, 1.926e-02, -6.429e-02) * s[0][2][1];
	r0 += M4(3.695e-02, -1.919e-01, -3.202e-03, -1.207e-01, 1.717e-01, -8.082e-02, -2.161e-02, -1.106e-01, -3.328e-02, 7.726e-02, -5.874e-03, -1.078e-01, 1.232e-01, 3.487e-01, 1.971e-01, -2.191e-01) * s[1][0][0];
	r0 += M4(1.089e-01, -5.062e-02, 3.823e-02, -4.171e-02, 3.641e-02, -5.221e-02, 1.203e-01, -8.580e-02, -6.231e-02, -3.728e-02, 2.688e-02, 5.087e-02, 1.432e-01, -2.821e-02, 9.647e-02, 1.721e-02) * s[1][0][1];
	r0 += M4(-2.170e-01, 5.410e-01, -3.221e-01, -1.448e-01, -2.239e-01, -1.920e-02, 2.120e-01, -2.581e-01, -5.034e-02, 4.485e-01, 7.370e-01, 3.214e-01, 1.269e-01, 9.501e-01, -1.088e+00, 7.189e-01) * s[1][1][0];
	r0 += M4(-3.211e-01, 3.988e-01, -4.452e-01, -1.479e-01, -3.330e-01, -1.392e-01, 3.115e-01, 4.964e-02, -1.812e-01, 1.201e-01, 6.652e-02, 1.239e-01, 3.144e-02, 1.150e-01, -2.625e-01, 5.512e-01) * s[1][1][1];
	r0 += M4(-2.059e-01, 1.079e-01, 8.456e-02, -1.284e-01, 5.059e-01, -1.142e-02, -1.498e-01, -1.421e-01, -5.114e-02, -8.759e-02, 2.482e-01, 3.570e-02, -2.997e-01, 3.957e-01, 9.390e-02, -1.337e-01) * s[1][2][0];
	r0 += M4(-2.300e-01, 7.164e-02, -5.466e-02, -8.576e-02, 1.588e-01, 1.778e-02, -7.257e-02, -1.425e-01, -7.510e-03, 2.068e-02, 3.387e-02, -3.685e-02, 8.681e-04, 3.224e-02, 1.367e-01, 9.936e-02) * s[1][2][1];
	r0 += M4(2.252e-02, -7.592e-02, -3.193e-02, 1.041e-02, 1.044e-01, -1.612e-02, 9.985e-02, 2.184e-02, 4.162e-02, 1.320e-02, -1.064e-01, 1.771e-02, -5.033e-01, 4.797e-02, -3.906e-02, 1.203e-03) * s[2][0][0];
	r0 += M4(-4.706e-02, -4.940e-02, 4.392e-02, 7.475e-02, 9.865e-02, -7.246e-03, 7.302e-03, -3.214e-02, -1.665e-02, 1.585e-02, -7.009e-02, 2.219e-02, -1.968e-01, -1.429e-02, -4.583e-02, 5.786e-03) * s[2][0][1];
	r0 += M4(-9.268e-02, 1.232e-01, 1.431e-01, -1.903e-03, -2.321e-01, 1.250e-01, 2.481e-01, 1.177e-01, 3.905e-01, 1.143e-01, 9.878e-02, -2.725e-01, 3.428e-01, 5.256e-01, -3.566e-02, -5.038e-01) * s[2][1][0];
	r0 += M4(-6.774e-02, 1.221e-01, -3.809e-02, -1.218e-02, -1.204e-01, -3.305e-02, 1.399e-01, 4.005e-02, 2.089e-01, 3.536e-02, -1.631e-01, -1.189e-01, 3.125e-01, 1.225e-01, -7.177e-02, -1.743e-01) * s[2][1][1];
	r0 += M4(-1.996e-02, -1.789e-02, 1.658e-01, 6.112e-02, 7.044e-02, 5.796e-02, -1.256e-01, 1.063e-01, -4.369e-02, -1.814e-02, -3.880e-03, 7.931e-02, -6.562e-02, 3.819e-02, 1.742e-01, -1.980e-01) * s[2][2][0];
	r0 += M4(9.999e-03, -4.235e-03, 6.295e-02, 2.726e-02, 3.472e-02, 5.043e-03, 2.982e-02, 5.118e-02, -1.606e-01, 4.641e-02, -6.465e-02, -1.128e-02, -7.386e-02, -7.349e-02, 2.939e-02, -6.860e-02) * s[2][2][1];
	r0 += V4(7.418e-02, -5.674e-02, -3.827e-03, 1.812e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv7
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
	r0 += M4(5.972e-02, 3.068e-02, 1.785e-02, -8.303e-03, -5.083e-02, 1.124e-02, 6.768e-02, 3.584e-02, 8.962e-02, -1.381e-02, -2.898e-03, 3.380e-03, 4.746e-02, -7.258e-02, 2.358e-02, 3.884e-02) * s[0][0][0];
	r0 += M4(1.018e-01, 5.641e-02, 2.409e-02, 2.037e-03, -5.687e-02, -4.978e-02, 1.082e-02, -1.983e-02, 1.737e-01, 7.643e-02, 8.876e-02, -4.732e-02, 8.079e-02, -2.917e-02, 3.302e-02, -1.580e-02) * s[0][0][1];
	r0 += M4(5.519e-02, -9.229e-02, 7.118e-02, 6.379e-02, -8.156e-02, -1.516e-01, 8.579e-02, 1.372e-02, 3.370e-01, 5.493e-02, 5.328e-02, 2.627e-02, -1.211e-01, -1.161e-01, 7.990e-02, -2.874e-02) * s[0][1][0];
	r0 += M4(-1.491e-01, -1.665e-01, 6.661e-02, 1.597e-01, -1.336e-02, -1.454e-01, 4.773e-02, 7.099e-02, 2.318e-02, -5.250e-02, 1.704e-01, 1.542e-01, -8.650e-02, -2.123e-01, 1.665e-01, -2.988e-02) * s[0][1][1];
	r0 += M4(2.097e-02, 3.058e-02, -1.774e-03, -4.824e-02, 7.920e-02, 2.101e-03, 4.142e-02, -2.302e-02, 2.012e-02, -3.014e-03, 5.155e-02, 1.389e-02, -1.065e-01, -5.430e-02, -4.480e-02, -8.044e-02) * s[0][2][0];
	r0 += M4(-1.609e-02, -5.658e-02, 3.617e-02, 2.219e-02, 1.175e-01, 1.888e-03, -8.066e-03, -3.314e-02, -1.430e-02, 1.165e-03, 3.963e-02, -2.261e-02, -9.377e-02, -2.753e-02, -1.148e-02, -1.268e-01) * s[0][2][1];
	r0 += M4(2.345e-02, 1.717e-02, 4.288e-02, 2.480e-02, 1.214e-01, 5.461e-02, 1.440e-01, -3.930e-02, 9.296e-02, 8.053e-02, 6.016e-02, 1.445e-01, 1.570e-01, -2.044e-02, -1.494e-02, -7.732e-03) * s[1][0][0];
	r0 += M4(1.821e-01, 1.004e-01, 5.348e-02, -1.117e-01, 7.643e-03, 8.096e-02, 7.356e-02, -2.165e-02, 2.166e-01, 1.399e-01, 1.777e-01, 2.075e-01, 2.674e-01, 1.182e-01, 1.665e-02, -1.482e-02) * s[1][0][1];
	r0 += M4(-2.861e-01, 5.253e-02, 1.238e-01, -3.095e-02, 1.333e-01, -3.844e-02, 8.178e-01, 1.994e-02, -3.779e-01, -3.534e-01, -1.787e-01, 5.684e-01, 3.962e-02, 3.584e-01, 2.078e-01, -3.007e-02) * s[1][1][0];
	r0 += M4(-5.708e-01, 9.329e-02, 2.137e-01, -5.381e-01, 3.134e-03, 4.659e-02, 2.187e-01, -1.002e-01, -3.577e-01, -1.615e-01, 1.668e-01, 1.860e-01, -1.431e-01, 8.540e-01, 7.533e-02, -2.299e-01) * s[1][1][1];
	r0 += M4(7.293e-02, 3.418e-02, 1.297e-02, -1.361e-02, 1.608e-01, 7.648e-02, -4.114e-02, -9.608e-02, 2.511e-01, 5.723e-02, 6.754e-02, 5.811e-02, -1.483e-01, -3.556e-02, -1.228e-02, -4.027e-02) * s[1][2][0];
	r0 += M4(2.531e-01, 1.056e-02, -1.093e-02, -5.923e-02, 3.761e-01, 1.269e-01, -1.722e-01, -1.698e-01, 9.075e-02, -2.038e-02, 5.139e-02, 1.177e-01, -2.486e-01, 3.707e-02, -2.301e-02, -8.332e-02) * s[1][2][1];
	r0 += M4(2.223e-04, 9.971e-03, 2.527e-02, 3.746e-02, 2.538e-02, -3.600e-02, -7.380e-04, -1.323e-01, 6.042e-02, 2.696e-02, 1.124e-02, -7.346e-02, 3.461e-02, -3.425e-02, -7.458e-02, 8.588e-02) * s[2][0][0];
	r0 += M4(7.765e-02, 5.279e-03, 3.832e-02, 1.157e-01, -1.721e-03, -6.562e-02, -4.922e-02, -9.694e-02, 9.216e-02, 1.173e-03, 1.074e-02, 7.205e-02, 3.333e-02, -1.120e-02, -8.706e-02, 1.131e-01) * s[2][0][1];
	r0 += M4(-5.020e-02, -3.020e-02, 2.792e-03, -2.711e-03, 1.665e-01, -2.899e-02, -4.868e-02, -3.809e-01, -4.868e-02, -4.123e-02, 1.352e-01, -1.997e-01, 3.298e-02, -6.884e-03, -2.880e-02, 1.657e-01) * s[2][1][0];
	r0 += M4(-1.484e-02, 1.577e-01, 1.460e-01, 3.475e-01, 1.184e-01, -6.568e-02, -3.961e-02, -1.484e-01, -5.037e-02, -6.113e-02, 6.107e-02, -4.941e-02, 4.385e-02, -9.939e-03, -1.257e-01, -1.575e-01) * s[2][1][1];
	r0 += M4(3.027e-02, -2.926e-03, 4.242e-02, -2.196e-03, 2.808e-02, 4.745e-02, 1.661e-02, -1.026e-02, -1.945e-02, 2.168e-02, 3.159e-05, 2.891e-02, -2.442e-02, -1.035e-02, 1.880e-01, 2.007e-01) * s[2][2][0];
	r0 += M4(8.200e-02, 4.303e-02, 1.597e-01, 9.233e-02, 7.429e-02, 3.168e-02, 3.997e-03, -5.470e-02, 9.140e-03, -1.639e-02, 1.306e-02, 1.023e-02, -3.678e-02, 6.279e-02, 2.979e-01, 3.349e-01) * s[2][2][1];
	r0 += V4(-2.406e-02, 4.015e-02, 4.304e-03, -2.841e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-conv8
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
	r0 += M4(3.548e-03, -4.748e-02, 4.089e-02, 6.370e-03, 5.887e-03, 1.232e-01, -1.465e-02, 5.886e-02, -1.707e-02, 4.804e-02, 8.220e-02, -5.357e-02, -7.641e-03, -2.148e-02, 5.375e-02, 1.491e-02) * s[0][0][0];
	r0 += M4(-4.865e-03, -4.739e-02, 3.942e-02, 1.159e-02, 8.244e-03, 6.596e-02, -5.310e-02, -2.271e-02, 2.850e-02, 1.106e-01, 3.636e-02, 1.021e-01, -2.816e-02, 7.913e-02, 2.348e-01, 2.867e-02) * s[0][0][1];
	r0 += M4(-7.473e-02, -3.020e-02, -1.250e-02, 8.375e-02, 1.361e-01, 4.464e-02, -2.435e-02, -5.042e-02, 2.117e-02, 4.226e-02, -3.706e-02, 1.266e-02, -3.744e-02, 5.637e-02, 1.460e-02, 3.121e-02) * s[0][1][0];
	r0 += M4(-8.687e-02, -1.762e-02, -4.209e-03, 1.067e-01, 8.891e-02, 1.466e-02, 8.400e-02, -2.650e-01, 1.046e-01, -1.337e-01, 9.366e-03, 2.085e-02, -1.646e-01, 5.507e-02, 1.911e-01, 1.053e-01) * s[0][1][1];
	r0 += M4(3.322e-03, 2.973e-02, 1.977e-03, 5.191e-03, -4.212e-02, -9.721e-02, -4.564e-02, -2.203e-02, -1.580e-03, -4.090e-02, -2.610e-02, 4.950e-02, 2.624e-04, -1.779e-02, 1.197e-03, -3.020e-02) * s[0][2][0];
	r0 += M4(1.207e-02, 4.074e-02, 2.982e-02, 1.566e-02, -8.570e-02, -6.958e-02, -1.735e-02, -5.090e-02, -4.202e-02, 1.330e-02, -3.806e-02, 3.719e-02, -8.264e-02, 1.424e-03, -3.528e-02, 8.878e-02) * s[0][2][1];
	r0 += M4(5.334e-02, 1.502e-01, -3.579e-01, -7.001e-02, -2.578e-02, 2.666e-01, 9.141e-02, 6.622e-02, 2.769e-02, -9.302e-02, 1.855e-02, 8.187e-02, -1.756e-02, 3.061e-02, -9.888e-02, 1.777e-02) * s[1][0][0];
	r0 += M4(2.821e-02, 1.024e-01, -1.870e-01, -3.644e-02, -1.836e-03, 1.036e-01, 1.464e-01, 3.983e-02, 6.208e-02, -1.050e-01, 5.844e-01, 6.620e-02, -3.162e-02, -1.715e-02, -2.886e-01, 3.493e-02) * s[1][0][1];
	r0 += M4(3.717e-01, -4.111e-01, 2.799e-02, -5.054e-01, 3.028e-01, 2.164e-01, -2.368e-01, 2.456e-01, -3.076e-01, 3.434e-01, 1.760e-01, -7.141e-02, 2.260e-01, 8.525e-02, -2.705e-01, 1.607e-01) * s[1][1][0];
	r0 += M4(1.577e-01, -1.718e-01, -3.470e-02, -2.828e-01, 1.470e-01, 4.144e-01, 1.858e-01, 1.813e-01, -5.022e-01, 1.468e-02, -4.350e-01, -2.776e-01, 2.135e-01, -1.324e-01, -1.532e+00, 2.244e-02) * s[1][1][1];
	r0 += M4(-1.267e-01, 7.232e-02, 3.830e-02, 2.279e-02, -1.058e-01, -2.066e-01, -6.321e-02, 9.311e-02, 1.279e-01, -6.396e-02, 2.075e-02, -9.204e-02, -1.311e-01, -4.043e-02, -1.240e-02, 9.541e-02) * s[1][2][0];
	r0 += M4(5.636e-02, 4.378e-02, 2.654e-02, -4.509e-02, -4.798e-01, -1.605e-01, -4.649e-02, 2.876e-01, 2.302e-01, 1.920e-02, 5.837e-02, -1.460e-01, 3.259e-02, -7.759e-03, 7.203e-02, 1.752e-02) * s[1][2][1];
	r0 += M4(4.259e-02, -3.017e-02, 3.097e-01, 8.677e-02, -4.994e-02, -1.060e-02, 1.233e-01, -8.454e-02, 1.181e-02, -3.767e-02, -1.137e-01, 1.804e-02, -8.239e-03, -7.431e-03, 6.556e-02, -3.858e-03) * s[2][0][0];
	r0 += M4(3.630e-02, -1.350e-02, 2.069e-01, 5.046e-02, -3.866e-02, -7.704e-03, 1.136e-01, -1.398e-02, 3.604e-02, -5.112e-02, -5.265e-01, -5.065e-02, -4.496e-03, -5.072e-02, 1.930e-02, 1.342e-02) * s[2][0][1];
	r0 += M4(5.007e-03, -1.281e-01, -1.099e-01, 2.252e-01, -1.587e-01, -1.444e-02, 3.317e-01, -2.106e-01, -9.859e-03, 1.147e-02, 1.174e-01, 2.519e-02, 5.725e-02, 1.142e-02, -4.423e-03, -2.066e-02) * s[2][1][0];
	r0 += M4(-8.279e-02, -8.084e-02, -6.927e-03, 1.372e-01, -3.552e-04, 7.007e-02, 1.110e-01, -3.672e-02, -2.158e-02, 9.838e-02, 1.611e-01, 9.496e-02, 8.376e-02, -6.572e-02, -1.511e-02, 2.304e-02) * s[2][1][1];
	r0 += M4(-5.350e-02, 5.149e-02, 3.340e-02, 2.745e-02, 8.605e-02, -1.082e-01, 4.136e-02, -6.435e-02, 2.705e-02, 1.443e-02, -2.042e-02, 2.852e-02, -5.294e-02, -1.690e-02, -2.394e-03, 1.536e-02) * s[2][2][0];
	r0 += M4(-9.813e-05, 7.553e-02, -2.469e-02, 8.434e-03, -5.621e-02, -1.361e-01, 9.984e-02, 9.448e-02, 2.506e-02, -5.193e-02, 7.649e-02, 1.878e-02, -3.665e-03, -4.460e-05, 7.355e-02, -9.432e-03) * s[2][2][1];
	r0 += V4(-4.735e-03, -3.812e-03, 1.560e-02, -7.241e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-RCAS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv8
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
	r0 += M4(3.689e-01, 3.020e-01, 4.436e-02, 7.007e-02, -1.600e-03, 3.281e-04, 2.769e-02, -1.971e-02, 1.530e-02, 1.617e-02, -1.016e-02, 2.118e-02, -4.447e-02, 6.823e-03, 9.698e-03, 6.783e-03) * s[0][0][0];
	r0 += M4(2.327e-01, 2.411e-01, 2.489e-03, 7.369e-02, -5.935e-02, 3.108e-02, 1.519e-02, -2.553e-02, 2.499e-02, 4.723e-02, 2.175e-04, 1.358e-02, -5.140e-02, 1.985e-02, 1.890e-02, -2.082e-02) * s[0][0][1];
	r0 += M4(1.376e-02, -8.378e-02, 1.067e-01, 6.714e-02, -1.873e-01, -1.677e-01, -1.091e-01, -6.153e-02, 2.005e-01, 2.497e-01, -2.141e-02, 3.514e-02, 1.323e-01, 3.198e-02, 1.384e-02, 6.502e-02) * s[0][1][0];
	r0 += M4(1.700e-02, 9.276e-02, 2.635e-02, 5.188e-02, -1.784e-01, -3.685e-01, -8.297e-02, -1.106e-01, 4.016e-01, 2.186e-01, -7.349e-02, 5.985e-02, 7.836e-02, -7.218e-02, 1.566e-02, 1.294e-01) * s[0][1][1];
	r0 += M4(-9.596e-03, 4.795e-02, -4.885e-03, -4.799e-02, -1.728e-02, -5.438e-02, -1.073e-02, -3.004e-02, 1.692e-02, 1.198e-02, 2.275e-02, -4.430e-02, 2.517e-02, 8.278e-02, -1.539e-02, -5.822e-02) * s[0][2][0];
	r0 += M4(2.077e-02, 1.807e-02, -3.080e-02, -6.864e-02, -8.355e-02, -1.382e-01, -8.269e-04, -2.295e-02, -1.725e-02, 1.170e-01, 7.007e-02, -8.571e-02, 9.161e-03, 1.140e-01, -1.272e-02, -7.219e-02) * s[0][2][1];
	r0 += M4(1.343e-01, -5.060e-01, 3.896e-01, -1.037e-01, -3.285e-02, 1.626e-03, -3.989e-02, 1.998e-02, 1.906e-02, -1.355e-02, 1.616e-02, -1.923e-02, 4.063e-02, 1.570e-01, -1.036e-02, 1.107e-01) * s[1][0][0];
	r0 += M4(-1.259e-01, -2.453e-01, 1.418e-01, 1.989e-02, -9.243e-02, 6.922e-03, -1.372e-01, 8.814e-02, 2.966e-02, -4.558e-02, 2.340e-02, 3.770e-03, 8.129e-02, 2.398e-01, -2.822e-01, 1.156e-01) * s[1][0][1];
	r0 += M4(-1.686e-02, 1.111e-01, -3.606e-01, -3.174e-01, 2.549e-01, 1.459e-01, 1.665e-01, 6.456e-02, -2.968e-02, -1.556e-02, 4.581e-02, 8.376e-02, -1.647e-01, -4.100e-01, -1.576e-01, -4.075e-01) * s[1][1][0];
	r0 += M4(-8.312e-02, -1.661e-02, -1.880e-01, -4.396e-02, 6.785e-01, -2.118e-01, 4.860e-01, -3.930e-01, -1.446e-01, -1.163e-02, 3.820e-01, 6.618e-02, 1.149e-02, -2.106e-01, -3.974e-01, -8.627e-01) * s[1][1][1];
	r0 += M4(1.910e-02, 9.888e-02, -1.530e-02, 8.133e-02, -1.720e-03, 1.035e-01, -2.912e-02, 5.425e-02, 1.750e-02, 3.162e-02, 6.724e-03, 2.080e-02, 1.524e-02, 1.249e-01, 3.728e-02, 1.510e-01) * s[1][2][0];
	r0 += M4(6.066e-02, 8.749e-02, 4.136e-02, 3.765e-02, -8.778e-02, 3.257e-01, -2.000e-01, 1.284e-01, 6.226e-02, -1.155e-01, 1.679e-02, 2.399e-01, 3.796e-02, 1.499e-01, 3.006e-02, 1.252e-01) * s[1][2][1];
	r0 += M4(-4.594e-03, 5.617e-02, -4.338e-02, -1.930e-01, 3.979e-03, -1.196e-02, 2.487e-03, -1.902e-03, -9.603e-03, -1.108e-02, 1.869e-03, -5.398e-03, 3.177e-02, 2.712e-02, 2.098e-03, 3.971e-02) * s[2][0][0];
	r0 += M4(-2.933e-02, 5.698e-03, -5.194e-02, -8.569e-02, -4.212e-03, 1.387e-02, -2.844e-02, -1.612e-02, 1.639e-02, -6.081e-05, 1.437e-02, -3.306e-02, -3.478e-02, -3.660e-03, 4.497e-02, 3.619e-02) * s[2][0][1];
	r0 += M4(-8.080e-02, -1.354e-01, 2.506e-02, -1.832e-02, -7.580e-02, -4.256e-02, -7.603e-03, -1.257e-02, -1.518e-02, -1.481e-02, -9.329e-03, -1.289e-02, -4.947e-02, -3.986e-02, 2.140e-02, -1.153e-01) * s[2][1][0];
	r0 += M4(-8.086e-02, -8.618e-02, -1.322e-02, -2.533e-02, -7.153e-02, -5.995e-02, 4.609e-02, -1.097e-01, 4.649e-02, 1.685e-02, -3.198e-02, 1.277e-02, -1.185e-01, -1.440e-01, 2.354e-02, -4.817e-02) * s[2][1][1];
	r0 += M4(-1.304e-02, -8.855e-03, -4.334e-03, 3.346e-02, -2.256e-02, -4.719e-02, -3.568e-03, 6.524e-03, -3.528e-04, 7.782e-04, -1.059e-03, 1.060e-02, -2.653e-03, -1.252e-02, -6.512e-03, 8.887e-02) * s[2][2][0];
	r0 += M4(-2.509e-02, -3.924e-02, 2.868e-03, 5.226e-02, -2.810e-03, -2.839e-02, 2.409e-02, 2.769e-02, 1.550e-03, 4.749e-02, 2.412e-02, -9.096e-03, 1.098e-02, -1.014e-02, -9.631e-04, 6.909e-02) * s[2][2][1];
	r0 += V4(-2.208e-03, -1.987e-03, -8.258e-04, -1.013e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + rcas_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + rcas_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + rcas_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + rcas_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

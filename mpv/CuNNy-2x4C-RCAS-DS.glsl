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
	r += V4(9.683e-02, -2.164e-02, 4.677e-02, 1.349e-02) * s0[y+0][x+0];
	r += V4(-4.607e-01, 4.963e-01, -3.482e-01, -6.510e-02) * s0[y+0][x+1];
	r += V4(-3.237e-02, -2.717e-02, -3.784e-01, 5.738e-02) * s0[y+0][x+2];
	r += V4(1.164e-01, 5.725e-03, -1.309e-02, -2.851e-02) * s0[y+1][x+0];
	r += V4(2.109e-02, -4.912e-01, 4.504e-02, 5.605e-01) * s0[y+1][x+1];
	r += V4(1.294e-01, 3.954e-02, 5.800e-03, -5.353e-01) * s0[y+1][x+2];
	r += V4(1.303e-03, 1.206e-02, 4.044e-03, 1.404e-02) * s0[y+2][x+0];
	r += V4(-2.049e-02, 1.228e-02, -7.522e-03, -3.937e-03) * s0[y+2][x+1];
	r += V4(-1.426e-02, -2.219e-02, 4.443e-03, -1.406e-02) * s0[y+2][x+2];
	r += V4(2.314e-02, -3.568e-03, 6.087e-03, 5.477e-04);
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
	r += M4(-1.882e-02, -1.538e-01, -2.338e-02, -1.357e-01, -6.720e-02, -7.225e-02, -1.441e-01, 8.131e-02, 1.368e-01, 8.385e-01, -2.832e-01, 1.754e-01, -3.989e-02, -5.187e-02, -1.145e-02, -1.123e-01) * s0[y+0][x+0];
	r += M4(1.086e-01, -2.769e-01, -1.003e-01, 1.146e-01, 3.979e-02, -2.603e-01, 7.727e-02, 3.057e-01, 2.632e-02, 1.576e-01, 2.219e-01, -4.391e-01, -1.609e-01, -1.965e-01, -1.036e-01, 8.383e-02) * s0[y+0][x+1];
	r += M4(-1.289e-01, 3.158e-01, -7.935e-02, -1.041e-01, -1.040e-01, 3.870e-01, 6.715e-02, 1.100e-01, -2.230e-02, 1.343e-01, 1.535e-01, 5.353e-02, -5.138e-02, 6.323e-02, 1.194e-02, 1.588e-02) * s0[y+0][x+2];
	r += M4(3.803e-03, 2.379e-01, 2.977e-01, 2.802e-01, 8.158e-02, -2.705e-01, 2.326e-01, -1.323e-01, 4.416e-01, 5.882e-01, -1.055e+00, 2.125e+00, 5.828e-01, -6.263e-01, -7.572e-02, -5.407e-01) * s0[y+1][x+0];
	r += M4(2.056e-01, -1.023e-01, 1.735e-01, -3.770e-02, 2.281e-01, -9.196e-01, 2.240e-02, 2.586e-02, 2.507e-01, 1.480e-01, -1.860e+00, 1.809e+00, -1.072e-01, 1.644e-03, 1.772e-01, -3.038e-01) * s0[y+1][x+1];
	r += M4(3.876e-02, 1.865e-01, -1.750e-01, -2.881e-01, -2.839e-02, 2.279e-01, -3.016e-01, 2.608e-01, -8.761e-02, 1.904e-01, 3.480e-01, -1.245e-01, -7.133e-02, 5.572e-02, -7.201e-02, 3.748e-02) * s0[y+1][x+2];
	r += M4(-1.436e-01, 5.266e-02, -1.466e-01, -1.823e-01, 8.396e-02, -1.985e-01, -7.014e-02, -7.070e-01, -7.556e-01, -5.658e-01, -1.457e+01, -1.529e+00, 1.422e-02, -2.474e-01, 1.328e-01, -7.700e-02) * s0[y+2][x+0];
	r += M4(-1.574e+00, 2.960e-01, -7.401e-01, 2.721e-01, -1.185e-01, 6.966e-02, -2.600e-01, -8.586e-01, -4.167e+00, -1.712e+00, -1.504e+01, -5.397e-01, -3.357e-02, -3.857e-01, -1.118e-01, 2.095e-01) * s0[y+2][x+1];
	r += M4(4.893e-02, 4.046e-01, 1.810e-01, -3.268e-01, 7.814e-03, 6.152e-01, 1.412e-01, -2.478e-01, -3.103e-01, 9.381e-01, -5.447e+00, -1.225e+00, -1.223e-02, 1.840e-01, -3.170e-03, 2.039e-02) * s0[y+2][x+2];
	r += M4(-8.957e-03, -9.985e-02, -9.341e-02, 2.138e-02, -1.976e-02, -1.174e-01, -1.411e-01, -1.528e-01, -3.535e-03, -7.543e-02, -7.059e-02, -1.283e-01, -8.159e-02, 1.754e-01, 3.515e-02, 3.897e-01) * s1[y+0][x+0];
	r += M4(1.077e-01, -1.893e-01, -8.713e-02, 1.493e-01, 1.340e-01, -2.476e-01, 1.449e-02, 5.723e-02, 3.964e-02, 5.403e-02, 1.548e-01, 1.021e-01, -1.638e-01, -3.115e-01, -8.307e-02, -1.716e-01) * s1[y+0][x+1];
	r += M4(-1.442e-01, 4.013e-01, -1.268e-01, -5.708e-02, -6.698e-02, 3.647e-01, 1.106e-01, -8.209e-02, 3.669e-03, -3.755e-02, 5.165e-02, -4.361e-03, -2.331e-02, 1.761e-02, 1.174e-01, -4.882e-02) * s1[y+0][x+2];
	r += M4(-3.341e-02, 2.864e-01, 2.514e-01, 4.114e-01, 8.616e-02, 2.761e-02, 1.569e-01, 1.343e-01, 1.454e-01, -1.662e-01, 6.353e-02, 4.607e-02, 5.000e-02, 4.024e-02, -2.171e-02, 1.716e-01) * s1[y+1][x+0];
	r += M4(1.978e-01, -2.111e-01, 2.734e-01, 1.136e-01, 6.480e-01, -1.696e-01, 1.153e-01, 7.367e-01, 8.958e-02, 7.178e-03, -8.437e-02, 1.706e-01, 1.096e-01, 8.145e-01, -2.964e-01, -5.365e-01) * s1[y+1][x+1];
	r += M4(1.829e-02, 3.742e-01, -7.765e-02, -1.526e-01, -7.098e-02, 4.855e-01, -2.625e-01, -1.237e-01, 1.477e-02, 6.792e-02, -7.503e-02, -6.561e-02, 3.940e-02, -8.781e-03, 2.144e-01, -5.993e-03) * s1[y+1][x+2];
	r += M4(-1.395e-02, -1.041e-01, -7.353e-02, -3.219e-01, 9.694e-02, -1.247e-01, -1.607e-02, -1.822e-01, 2.359e-01, -1.082e-01, -3.295e-02, 2.384e-02, 4.662e-02, -8.908e-02, -3.283e-02, -1.407e-01) * s1[y+2][x+0];
	r += M4(1.230e-01, -4.067e-01, -2.822e-01, -2.314e-01, -5.743e-01, 5.227e-01, -2.017e-01, 2.542e-01, 2.002e-01, 2.704e-01, -1.760e-02, -1.124e-01, -1.800e-02, -3.564e-01, -1.821e-01, 2.922e-01) * s1[y+2][x+1];
	r += M4(-6.417e-02, 5.176e-01, 7.803e-02, 7.536e-02, 1.109e-02, 5.647e-01, 6.677e-01, -1.744e-01, 1.108e-01, -1.723e-01, 4.212e-02, -7.916e-03, 2.391e-02, 5.773e-02, 2.205e-01, -2.072e-02) * s1[y+2][x+2];
	r += V4(5.527e-01, -2.267e-02, -5.766e-03, 3.384e-03);
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
	r += M4(1.582e-02, -7.145e-02, 4.215e-02, 6.839e-02, 3.547e-01, 3.914e-02, 1.867e-01, 4.339e-01, 7.171e-02, 1.989e-01, 2.056e-01, 1.252e-02, 8.017e-02, -9.989e-02, -2.312e-02, 3.713e-02) * s0[y+0][x+0];
	r += M4(3.048e-02, -7.359e-03, -5.542e-02, -8.452e-02, 5.446e-01, -3.357e-01, -8.330e-02, 5.142e-01, 1.313e-01, 2.292e-01, 1.317e-01, 1.402e-01, -1.669e-02, 1.178e-01, -1.937e-01, -3.862e-02) * s0[y+0][x+1];
	r += M4(-2.290e-02, 6.919e-02, 2.804e-02, 5.039e-02, 1.717e-01, -8.128e-02, -5.948e-02, 2.208e-01, 2.099e-03, 8.428e-02, -2.623e-02, -1.931e-02, -6.378e-03, -3.499e-02, -7.652e-02, -3.314e-02) * s0[y+0][x+2];
	r += M4(7.713e-02, -6.472e-03, 3.533e-03, 3.736e-02, -5.613e-01, -3.785e-01, 3.856e-01, 9.691e-01, -6.190e-01, 1.166e-01, 5.725e-01, 2.150e-01, 3.915e-01, -5.762e-01, -2.516e-01, -4.187e-02) * s0[y+1][x+0];
	r += M4(-4.597e-02, -5.457e-02, -3.747e-02, 1.245e-01, -2.219e-01, -1.074e-01, -5.761e-01, -5.456e-01, -1.494e-01, -3.908e-01, 1.193e+00, -6.664e-01, 5.289e-02, 5.527e-02, -7.000e-01, 4.796e-01) * s0[y+1][x+1];
	r += M4(-3.622e-02, 2.403e-02, 3.988e-02, -1.306e-01, -7.049e-02, -1.238e-01, -1.852e-02, -4.698e-02, 8.218e-02, 7.664e-02, -3.242e-01, -8.500e-02, 7.304e-02, -2.798e-01, 6.348e-01, 3.506e-01) * s0[y+1][x+2];
	r += M4(-8.813e-02, 5.890e-02, -5.070e-02, -1.006e-01, -1.044e-01, 3.556e-02, 1.516e-01, 1.853e-01, -8.499e-02, 4.219e-01, 1.350e-02, -4.420e-02, 1.723e-02, -1.243e-01, -4.532e-01, -3.545e-01) * s0[y+2][x+0];
	r += M4(9.458e-02, -1.337e-01, 1.142e-02, 9.058e-02, -5.881e-02, 4.488e-01, -3.071e-01, -3.251e-01, 4.189e-01, -4.229e-01, 1.297e-01, 6.611e-01, -5.879e-01, 4.932e-01, -6.699e-01, -6.933e-01) * s0[y+2][x+1];
	r += M4(-2.583e-02, 1.080e-01, 2.989e-02, -4.619e-02, -1.086e-01, 2.314e-01, -8.358e-02, -3.019e-01, 3.215e-02, 1.863e-01, -3.821e-01, 1.393e-03, -2.036e-01, 2.340e-01, 2.353e-01, -4.424e-01) * s0[y+2][x+2];
	r += M4(2.992e-01, -1.441e+00, -3.352e-01, -6.587e-01, 6.507e-02, -1.027e-01, 5.779e-03, 7.924e-02, 1.985e-02, 5.920e-02, 1.348e-01, -3.987e-02, 1.042e-03, 1.955e-02, -1.139e-01, -3.967e-02) * s1[y+0][x+0];
	r += M4(2.717e-02, -7.491e-01, -3.969e-01, -1.057e+00, 9.838e-02, -7.562e-02, 1.250e-02, 2.242e-01, 5.053e-02, 6.429e-02, -4.525e-02, 7.472e-02, 1.235e-02, -2.690e-02, -5.513e-04, -3.628e-02) * s1[y+0][x+1];
	r += M4(4.816e-01, -6.365e-01, -7.241e-01, -5.440e-01, -1.139e-02, -4.493e-02, 1.733e-01, 1.265e-01, -5.064e-03, -8.884e-02, 1.346e-01, 5.753e-02, 1.000e-02, 4.402e-02, -1.084e-02, 2.343e-02) * s1[y+0][x+2];
	r += M4(5.361e+00, -1.880e-01, 1.039e-01, -2.838e-01, -5.563e-02, 6.285e-02, 1.792e-01, 1.016e-01, -1.002e-01, -8.235e-02, 1.716e-02, -1.303e-02, 2.676e-02, -8.633e-03, -5.214e-02, 2.195e-02) * s1[y+1][x+0];
	r += M4(4.418e+00, 3.486e+00, 2.998e+00, 3.019e+00, -9.703e-02, -3.311e-01, -2.710e-01, -1.978e-01, -7.503e-02, -3.213e-01, -2.204e-01, -2.607e-01, 3.065e-02, 1.908e-01, 6.616e-02, 7.341e-02) * s1[y+1][x+1];
	r += M4(3.260e-01, -2.030e-01, -1.218e+00, 9.766e-02, 2.676e-02, 2.217e-02, 3.186e-01, 3.670e-02, 1.001e-02, 1.696e-02, 6.424e-02, 3.727e-02, -5.314e-02, -3.463e-02, -3.368e-03, 5.492e-03) * s1[y+1][x+2];
	r += M4(-1.386e-01, -1.918e-01, -7.638e-01, -1.339e+00, -6.616e-02, 1.577e-01, -6.438e-02, -1.247e-01, -2.734e-03, -1.022e-01, 7.738e-03, 3.733e-02, -3.606e-03, 1.721e-02, -8.923e-03, -2.345e-02) * s1[y+2][x+0];
	r += M4(1.405e+00, -1.148e+00, 6.871e-01, 7.117e-01, -2.003e-02, 1.060e-01, -4.204e-02, 2.424e-02, 2.826e-02, -2.725e-01, 6.586e-02, 2.570e-01, 1.547e-02, 1.064e-01, -2.472e-02, -9.429e-02) * s1[y+2][x+1];
	r += M4(-2.957e-01, 2.998e-01, -3.464e-01, -7.961e-01, -4.042e-02, 2.725e-01, -3.767e-02, -1.683e-01, -1.945e-02, 3.796e-02, 4.270e-02, -3.451e-02, -5.462e-02, 1.660e-01, -5.259e-02, -1.501e-01) * s1[y+2][x+2];
	r += V4(2.119e-04, -2.910e-03, -3.193e-03, -5.813e-03);
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
	r += M4(2.774e-02, -6.837e-02, 8.633e-02, 2.376e-02, -1.760e-02, 3.222e-02, -8.749e-02, 2.198e-02, -6.044e-02, -5.714e-02, 4.426e-02, 4.857e-02, 4.084e-02, 7.122e-02, 1.015e-02, -1.424e-02) * s0[y+0][x+0];
	r += M4(-3.596e-01, -7.960e-02, 1.779e-01, 9.091e-02, -6.316e-02, -2.073e-02, -1.026e-01, -1.344e-01, -1.090e-01, 2.320e-02, 7.933e-02, 3.430e-02, 4.973e-02, -1.831e-01, 1.690e-01, 1.246e-01) * s0[y+0][x+1];
	r += M4(3.313e-02, -7.928e-02, -3.132e-02, 1.513e-01, 2.153e-02, -3.920e-02, 4.345e-02, -2.720e-02, 5.466e-02, -7.641e-02, -9.189e-03, 3.527e-02, -5.883e-02, 5.807e-02, -3.634e-02, -2.757e-03) * s0[y+0][x+2];
	r += M4(2.302e-01, -1.267e-01, 1.545e-01, -1.705e-01, -1.916e-01, 4.605e-02, 3.103e-02, 7.654e-02, 2.683e-01, -1.001e-01, 4.234e-02, -1.490e-01, -1.169e-01, 5.949e-02, 7.036e-03, 1.492e-01) * s0[y+1][x+0];
	r += M4(9.447e-03, 5.269e-01, -8.496e-01, 7.622e-02, -6.506e-01, -5.856e-01, -2.057e-01, -6.876e-02, -4.658e-01, 4.547e-01, -5.365e-01, 1.943e-01, 1.021e-01, -4.268e-01, -3.480e-02, -5.723e-01) * s0[y+1][x+1];
	r += M4(3.001e-01, 1.938e-01, 1.297e-01, -3.954e-01, 1.363e-01, -1.039e-01, 8.738e-02, -4.981e-02, 2.705e-01, -1.155e-01, 1.809e-01, -2.706e-01, -1.421e-01, 1.224e-01, -7.637e-02, 2.261e-01) * s0[y+1][x+2];
	r += M4(4.426e-02, -6.493e-03, 8.124e-02, -4.684e-02, 8.878e-02, -2.614e-02, -4.459e-02, 8.387e-03, -6.242e-02, -8.389e-03, 7.056e-02, -5.819e-02, 2.155e-02, 2.256e-02, -4.098e-02, 2.309e-02) * s0[y+2][x+0];
	r += M4(-2.244e-01, -9.805e-02, 5.117e-02, 1.116e-01, 1.961e-01, 2.368e-01, -1.719e-01, -1.507e-01, 3.924e-02, -5.605e-02, -8.833e-02, 1.829e-01, 6.641e-02, 3.668e-02, 1.116e-01, -7.001e-02) * s0[y+2][x+1];
	r += M4(-8.887e-02, -1.894e-01, 7.361e-02, 1.460e-01, -4.586e-02, 2.975e-02, 2.816e-03, -4.383e-02, -7.476e-02, -7.427e-03, 6.786e-02, 2.897e-02, 1.759e-02, 2.760e-02, -5.439e-02, 2.342e-02) * s0[y+2][x+2];
	r += M4(2.956e-03, 7.261e-03, 3.216e-02, 1.535e-02, 6.274e-02, 6.751e-02, 7.990e-04, 5.346e-03, -7.586e-02, -1.369e-02, 7.195e-02, 3.644e-02, 5.798e-02, 6.656e-02, -6.398e-02, -1.158e-02) * s1[y+0][x+0];
	r += M4(-2.982e-01, -2.196e-01, -1.339e-02, -4.845e-02, -8.179e-02, -7.814e-02, 9.488e-02, 4.128e-02, -6.352e-03, -5.074e-02, 2.313e-02, 7.241e-02, 1.093e-01, 6.714e-02, -3.014e-02, -1.171e-02) * s1[y+0][x+1];
	r += M4(-9.012e-02, -1.614e-01, -5.146e-02, -1.090e-02, -7.582e-03, -3.952e-03, -3.473e-03, 5.630e-02, 1.368e-02, -1.004e-02, 2.087e-02, 2.081e-02, 4.614e-04, 5.699e-02, -1.393e-02, -7.487e-02) * s1[y+0][x+2];
	r += M4(6.110e-02, -6.111e-02, 4.279e-02, -1.310e-02, 3.804e-02, -3.205e-02, 9.887e-02, 2.969e-02, 1.142e-01, 1.812e-01, -1.736e-01, 1.459e-02, -2.463e-01, 1.001e-02, 7.934e-02, 1.198e-01) * s1[y+1][x+0];
	r += M4(-3.284e-01, 5.685e-02, -3.540e-01, -9.127e-02, -6.569e-02, -8.410e-02, -2.998e-01, -2.027e-01, 1.351e-03, 1.897e-02, -1.584e-01, -2.677e-01, -2.281e-01, -5.390e-01, 2.189e-01, 3.689e-02) * s1[y+1][x+1];
	r += M4(2.483e-02, -2.913e-01, -3.728e-02, -2.496e-01, 3.052e-02, 8.860e-02, 4.629e-03, -4.163e-02, 6.326e-02, 1.919e-02, 6.823e-03, -7.935e-02, -8.064e-02, 1.031e-02, -2.997e-03, 1.649e-01) * s1[y+1][x+2];
	r += M4(-1.852e-02, 3.059e-02, -5.706e-03, -2.708e-02, 1.440e-02, 1.629e-02, 1.436e-02, 4.077e-03, -7.983e-02, -4.523e-02, 5.555e-02, 6.415e-02, 9.752e-02, 2.040e-02, -8.732e-02, 4.065e-03) * s1[y+2][x+0];
	r += M4(-3.432e-02, -1.081e-01, -2.411e-01, -5.257e-02, 2.326e-02, -1.996e-02, 8.478e-02, -2.135e-02, -1.080e-02, -5.787e-02, 9.788e-02, 1.012e-01, 1.732e-01, 2.109e-01, -9.395e-02, -2.258e-01) * s1[y+2][x+1];
	r += M4(-1.571e-02, 1.117e-02, 2.014e-02, -1.753e-01, -2.703e-02, 1.325e-02, -2.370e-02, 9.497e-02, -3.434e-02, -7.691e-03, 8.045e-03, 4.757e-02, 7.450e-03, 2.045e-02, -2.815e-02, 1.040e-02) * s1[y+2][x+2];
	r += V4(-4.899e-04, -4.736e-04, -1.606e-04, -6.913e-05);
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
	r.r += rcas_tex(rcas_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

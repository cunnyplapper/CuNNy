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
	r += V4(3.823e-02, 3.899e-03, -3.037e-02, -2.633e-02) * s0[y+0][x+0];
	r += V4(-4.312e-02, 2.855e-02, 6.387e-01, 6.416e-01) * s0[y+0][x+1];
	r += V4(2.056e-02, -1.908e-02, -1.559e-01, -2.953e-02) * s0[y+0][x+2];
	r += V4(-4.953e-02, -3.009e-02, 1.112e-02, 8.933e-04) * s0[y+1][x+0];
	r += V4(-3.904e-01, -5.248e-01, -3.935e-01, -1.776e-02) * s0[y+1][x+1];
	r += V4(-9.830e-02, 5.548e-01, -8.228e-02, -4.839e-03) * s0[y+1][x+2];
	r += V4(-1.230e-02, 4.434e-02, 2.786e-03, 2.076e-04) * s0[y+2][x+0];
	r += V4(4.862e-01, -8.691e-02, 2.796e-02, -3.240e-03) * s0[y+2][x+1];
	r += V4(8.264e-02, 1.846e-02, 7.434e-04, -7.797e-03) * s0[y+2][x+2];
	r += V4(-1.783e-02, 1.022e-02, -1.109e-02, -8.636e-03);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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
	r += M4(-1.492e-01, 8.824e-02, -1.136e-01, 3.500e-02, 1.625e-01, 2.491e-01, -1.620e-01, -7.741e-03, -2.396e-02, 1.090e-01, 2.820e-01, -2.852e-01, -3.676e-02, -7.175e-02, -2.104e-01, 8.995e-02) * s0[y+0][x+0];
	r += M4(-2.240e-01, 2.128e-01, -7.667e-01, 6.001e-01, -1.799e-01, -2.712e-02, -1.772e-01, -3.895e-01, -1.151e-01, 4.519e-02, 1.208e-01, 7.304e-02, 2.488e-02, 1.112e-01, -1.383e-01, -1.536e-01) * s0[y+0][x+1];
	r += M4(-1.582e-02, 5.170e-02, -2.973e-01, 7.100e-02, 1.085e-01, -3.530e-01, 4.689e-02, 2.764e-01, 9.521e-02, 9.823e-02, 1.066e-01, -5.124e-02, -8.034e-02, -4.184e-02, -1.724e-01, 1.114e-01) * s0[y+0][x+2];
	r += M4(3.057e-01, -2.779e-01, -2.127e-02, -5.810e-02, -1.018e-01, 1.123e-01, 6.958e-02, 3.285e-01, -3.077e-01, 5.109e-01, 1.145e-02, -7.312e-01, 8.813e-02, 6.965e-02, 1.876e-01, 3.366e-02) * s0[y+1][x+0];
	r += M4(-4.541e-01, -3.737e-01, 1.478e-02, 2.577e-01, 4.146e-01, 1.375e-01, -3.245e-01, -5.724e-01, 8.567e-02, 1.249e+00, 1.096e-01, -7.579e-01, -1.184e-02, 4.068e-02, 3.081e-01, -2.403e-02) * s0[y+1][x+1];
	r += M4(3.574e-01, 1.065e-01, 4.027e-02, -6.659e-02, -4.718e-02, -8.983e-03, 1.441e-01, -4.996e-02, -3.592e-01, 2.021e-01, -4.228e-02, 1.351e-01, 7.216e-03, 1.276e-01, -5.015e-02, 3.204e-02) * s0[y+1][x+2];
	r += M4(1.540e-01, -1.511e-01, 3.858e-02, 1.711e-01, 3.019e-01, -1.513e-01, 1.438e-02, -5.970e-02, 2.103e-01, 1.436e-01, 6.670e-02, -3.948e-01, -2.390e-02, -9.398e-02, 7.838e-02, 1.427e-01) * s0[y+2][x+0];
	r += M4(5.562e-01, -2.165e-01, 1.139e-01, 1.028e-01, 2.977e-01, -4.271e-02, 2.736e-01, 2.395e-01, -1.076e-01, 8.537e-02, 1.423e-01, 4.116e-01, -1.280e-01, -3.143e-02, 8.467e-02, 2.713e-01) * s0[y+2][x+1];
	r += M4(2.710e-01, -7.520e-03, 2.909e-02, 1.230e-02, -9.314e-02, 2.323e-01, 1.298e-03, -7.237e-02, -1.630e-01, 1.045e-01, 7.486e-02, -2.595e-01, 1.014e-01, 1.642e-01, 5.185e-03, 2.439e-01) * s0[y+2][x+2];
	r += M4(-2.718e-01, 4.416e-01, -2.661e-01, 1.012e-02, 2.264e-01, 3.077e-01, 1.851e-01, 2.971e-01, 8.884e-02, 1.112e-01, 3.778e-01, -1.001e-01, -4.177e-01, 2.867e-01, -8.710e-01, -8.517e-02) * s1[y+0][x+0];
	r += M4(-2.514e-01, -5.306e-01, 1.478e-01, 9.978e-01, 2.275e-02, -9.076e-01, 1.185e-01, -3.100e-01, -2.563e-02, -2.068e-01, 3.868e-01, 3.179e-01, -1.544e-01, 9.617e-01, -1.371e+00, -9.040e-01) * s1[y+0][x+1];
	r += M4(-1.709e-01, -5.449e-01, -1.013e-01, 1.441e-01, -8.037e-02, 1.362e-01, -4.016e-02, 2.053e-02, 8.093e-02, -1.950e-01, 2.742e-01, -4.378e-02, 1.948e-01, 4.995e-01, -1.030e+00, -6.540e-01) * s1[y+0][x+2];
	r += M4(-2.085e-01, 9.401e-02, -1.522e-01, -2.171e-02, -7.085e-02, 1.665e-01, 7.183e-02, 1.069e+00, 3.601e-02, -4.835e-02, 1.950e-01, 1.595e-01, -4.794e-01, -4.158e-01, 9.546e-01, -7.957e-01) * s1[y+1][x+0];
	r += M4(7.905e-02, 4.792e-02, 8.470e-02, -9.486e-02, -4.425e-03, -4.472e-01, 1.114e-01, -5.605e-01, 1.747e-01, -8.486e-01, 6.570e-01, -3.833e-01, 2.965e+00, 2.073e-01, 2.920e+00, 7.034e-01) * s1[y+1][x+1];
	r += M4(2.063e-01, -1.752e-02, -2.239e-01, -5.301e-01, 5.481e-02, 9.973e-02, 1.265e-01, 3.383e-02, -4.321e-01, -6.114e-02, -1.174e-01, -1.198e-01, 3.104e-01, -5.028e-01, 5.124e-01, -2.937e-02) * s1[y+1][x+2];
	r += M4(-4.384e-02, -4.307e-02, -4.226e-02, -7.703e-04, -5.674e-02, -1.049e-01, -4.823e-02, 3.530e-01, 5.817e-01, -1.059e-01, -2.433e-02, -1.981e-01, 2.971e+00, -4.421e-01, -4.615e-01, -2.691e+00) * s1[y+2][x+0];
	r += M4(1.941e-02, 3.398e-02, 4.329e-02, 3.895e-02, -6.268e-02, 7.945e-02, 9.718e-02, 9.547e-02, 2.127e-01, 2.854e-01, -2.668e-01, -1.652e-02, 7.428e+00, 4.491e+00, 3.673e+00, 3.312e+00) * s1[y+2][x+1];
	r += M4(-1.197e-01, 3.654e-02, -9.957e-03, 6.398e-03, -1.547e-01, 3.942e-03, -3.483e-02, -4.382e-02, -2.096e-03, 1.960e-01, 1.864e-01, -1.442e-01, 7.931e+00, 2.855e+00, -1.676e+00, -3.451e-01) * s1[y+2][x+2];
	r += V4(1.926e-02, -1.256e-01, 6.230e-03, -1.203e-01);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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
	r += M4(-6.249e-02, -8.651e-02, 9.384e-02, 4.799e-02, -3.270e-02, 2.097e-02, 1.691e-02, 1.351e-01, 1.033e-01, 1.245e-01, -4.719e-02, -1.793e-02, 1.959e-02, 2.610e-01, 2.650e-02, -4.751e-02) * s0[y+0][x+0];
	r += M4(-3.405e-01, 1.997e-01, 2.657e-01, 5.251e-02, 9.281e-03, -3.037e-02, 1.547e-02, 1.694e-01, 1.864e-02, 3.256e-03, 4.883e-02, 1.167e-02, -4.660e-02, 1.721e-01, 4.066e-02, 2.981e-01) * s0[y+0][x+1];
	r += M4(-2.302e-01, -1.893e-01, 9.651e-02, 6.272e-03, 5.288e-02, -2.447e-03, -9.557e-03, 9.509e-03, -3.650e-02, -4.872e-02, 3.446e-02, 8.798e-02, 7.512e-02, -8.507e-03, -3.136e-02, 2.201e-02) * s0[y+0][x+2];
	r += M4(9.074e-02, -7.976e-02, 2.762e-01, 1.835e-02, 1.598e-01, -3.681e-01, -5.850e-02, 3.057e-01, 9.305e-03, 1.355e-01, -3.111e-02, 2.038e-01, 2.557e-01, -2.406e-02, -9.214e-02, 8.581e-02) * s0[y+1][x+0];
	r += M4(2.821e-01, 3.071e-01, 6.313e-02, -1.781e-01, 3.382e-02, -1.352e-01, -7.060e-02, -9.342e-02, -6.531e-02, 6.044e-01, 3.020e-01, -2.733e-01, -2.478e-01, -6.110e-01, 4.743e-01, 5.633e-01) * s0[y+1][x+1];
	r += M4(4.970e-03, 7.330e-02, 1.643e-01, 1.012e-01, -7.403e-02, -1.620e-02, -7.506e-02, -1.656e-03, -5.933e-01, 1.528e-01, 2.231e-01, 1.826e-01, -1.780e-01, 2.828e-03, -9.045e-02, -4.963e-02) * s0[y+1][x+2];
	r += M4(-7.347e-03, -5.629e-02, 6.364e-02, -1.389e-02, -1.913e-01, -2.685e-02, 7.366e-02, 6.610e-02, 7.788e-02, 1.093e-01, -8.721e-02, 5.156e-02, 3.910e-02, 1.541e-02, -6.285e-02, -3.700e-02) * s0[y+2][x+0];
	r += M4(6.226e-02, 1.723e-01, -6.434e-02, -3.698e-02, -8.992e-03, 2.763e-01, -6.191e-02, -2.084e-01, -3.574e-01, -1.659e-01, 7.828e-01, 4.815e-02, -1.316e-01, 1.017e-01, -2.762e-01, 5.926e-02) * s0[y+2][x+1];
	r += M4(7.923e-02, 1.908e-02, -1.033e-01, 2.272e-02, 1.159e-01, 2.273e-02, 1.022e-01, 1.294e-02, -5.783e-01, -9.650e-02, 4.427e-01, 3.245e-02, -7.087e-02, 2.784e-02, -5.331e-02, -6.003e-03) * s0[y+2][x+2];
	r += M4(8.562e-02, -8.185e-02, 8.891e-02, -1.451e-02, -2.509e-02, -6.361e-02, -3.534e-02, 1.538e-01, -6.084e-02, 1.188e-01, 3.244e-02, -9.815e-03, 2.075e-02, 5.182e-02, -8.639e-03, -1.181e-02) * s1[y+0][x+0];
	r += M4(-6.821e-02, 2.348e-01, 1.374e-01, -3.082e-02, 8.685e-02, -1.011e-01, -9.729e-02, 1.950e-01, 1.047e-01, -1.619e-01, -7.687e-02, 1.218e-01, -1.257e-02, -6.755e-02, -2.238e-02, 3.350e-01) * s1[y+0][x+1];
	r += M4(-7.851e-02, 3.585e-02, 6.096e-02, -2.912e-02, 8.649e-02, 4.760e-02, -5.247e-02, 5.480e-02, 3.653e-02, 1.499e-01, 4.431e-02, 1.334e-01, 3.309e-02, -2.287e-02, -2.606e-02, 1.696e-02) * s1[y+0][x+2];
	r += M4(2.872e-02, -1.722e-01, 5.449e-01, -6.509e-02, 7.281e-01, -3.799e-01, -1.721e-01, 2.236e-01, 9.827e-02, 4.435e-02, -1.909e-01, 2.019e-01, 2.188e-01, -2.084e-02, -4.062e-03, -4.582e-03) * s1[y+1][x+0];
	r += M4(2.146e-02, -1.427e-01, 4.531e-01, -2.076e-01, 4.209e-01, -1.179e-01, -3.189e-01, -1.593e-01, 3.272e-01, -7.321e-02, 6.519e-02, -2.631e-01, 1.197e-01, -3.425e-01, 3.291e-01, 5.020e-01) * s1[y+1][x+1];
	r += M4(1.409e-02, 1.610e-02, 2.438e-01, 1.856e-02, -1.313e-01, 1.642e-01, -1.672e-01, 2.793e-03, -1.632e-01, -2.809e-04, 4.761e-02, 9.590e-02, -2.364e-02, 3.032e-02, -2.094e-01, -4.977e-02) * s1[y+1][x+2];
	r += M4(-5.348e-02, -4.938e-02, 2.560e-01, -1.348e-01, 1.663e-02, 7.819e-03, 1.402e-01, 1.038e-01, -2.588e-01, 1.675e-01, -5.581e-02, 1.352e-01, -1.047e-01, 2.293e-02, 1.089e-02, -2.993e-02) * s1[y+2][x+0];
	r += M4(-7.828e-02, -5.446e-02, 1.751e-01, -3.165e-02, 2.329e-01, 3.018e-01, 2.232e-01, -1.692e-01, -4.380e-02, -1.516e-01, 2.849e-01, -4.527e-02, -1.176e-01, 1.743e-01, -1.242e-01, 5.834e-02) * s1[y+2][x+1];
	r += M4(-1.425e-01, -7.346e-02, 4.209e-02, -2.357e-03, -2.592e-02, 1.574e-01, 6.671e-02, 6.553e-02, -1.888e-01, -4.227e-02, 1.057e-01, 9.674e-02, -8.183e-02, 6.896e-03, 3.027e-02, 3.633e-03) * s1[y+2][x+2];
	r += V4(3.474e-02, -4.285e-02, 7.862e-03, -2.857e-01);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
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
	r += M4(-2.005e-02, 6.189e-02, 8.794e-02, -3.452e-02, 1.120e-02, -3.668e-02, 1.057e-01, 8.897e-02, -1.839e-02, 2.427e-02, -3.692e-03, 3.330e-02, 7.339e-02, -1.471e-01, -2.045e-01, -8.908e-02) * s0[y+0][x+0];
	r += M4(1.324e-02, -1.166e-01, 3.961e-02, 3.985e-01, -4.659e-02, -1.038e-01, 1.051e-01, 7.363e-02, 1.057e-01, -5.047e-02, 4.709e-03, -3.584e-02, -1.138e-02, 7.948e-01, 3.037e-01, -1.519e+00) * s0[y+0][x+1];
	r += M4(9.428e-02, -1.759e-01, -6.447e-02, -6.265e-02, -1.258e-01, -2.831e-02, -1.203e-02, 2.151e-02, -3.441e-03, -6.864e-02, -1.246e-02, 5.842e-02, 2.615e-01, -1.302e-01, 4.337e-01, -2.697e-01) * s0[y+0][x+2];
	r += M4(-8.158e-02, 4.189e-01, 4.146e-01, 4.684e-01, -1.191e-01, 3.403e-01, 3.212e-01, 4.083e-02, 5.739e-02, -1.414e-01, -1.231e-01, 2.843e-02, -1.315e-01, -1.198e-01, -4.768e-02, -7.536e-01) * s0[y+1][x+0];
	r += M4(3.832e-01, -3.593e-01, -2.896e-01, -6.748e-01, 5.842e-01, -4.505e-01, 1.984e-02, -3.529e-01, -3.155e-01, 3.604e-01, -1.072e-02, -2.164e-01, -3.320e-01, 1.902e+00, 1.166e+00, -2.438e+00) * s0[y+1][x+1];
	r += M4(1.083e-01, -3.325e-01, 2.866e-01, 1.203e-01, 3.467e-01, -1.944e-01, 5.451e-02, -1.452e-02, -1.203e-01, -9.754e-02, -3.827e-03, 1.248e-01, -5.507e-01, 4.592e-01, 7.890e-01, -4.051e-01) * s0[y+1][x+2];
	r += M4(-2.182e-02, 2.386e-01, -9.357e-02, 2.414e-02, 7.598e-02, -6.715e-03, -1.354e-01, 6.785e-02, -2.353e-02, 4.136e-02, 5.456e-02, -1.716e-02, -3.021e-01, 2.232e-01, -1.191e-01, -1.798e-01) * s0[y+2][x+0];
	r += M4(-1.451e-01, -1.594e-01, -6.546e-01, 1.831e-01, -1.168e-01, -7.153e-02, -8.663e-02, -7.103e-02, 7.063e-02, -4.066e-02, -4.042e-02, 7.508e-02, 8.321e-03, -2.373e-01, -7.079e-01, -1.290e-01) * s0[y+2][x+1];
	r += M4(-3.774e-02, -3.344e-01, -1.603e-01, -1.688e-01, -1.408e-02, 1.329e-02, -7.173e-02, 1.570e-02, 3.999e-02, -6.641e-03, -5.650e-02, 4.267e-02, -8.654e-01, -1.030e+00, -4.269e-02, -4.498e-01) * s0[y+2][x+2];
	r += M4(-1.752e-02, -4.981e-03, -1.474e-03, -1.115e-02, -6.034e-03, 3.262e-02, -7.789e-03, 2.024e-03, 2.436e-02, -3.092e-02, -1.034e-02, -2.434e-02, 8.791e-02, -4.090e-02, -6.718e-02, 2.025e-02) * s1[y+0][x+0];
	r += M4(4.077e-03, -9.268e-02, -1.190e-02, 7.062e-02, -4.804e-02, 8.260e-03, 5.360e-02, -2.706e-02, 3.723e-02, -3.059e-02, -6.952e-02, -6.301e-02, -1.080e-01, -9.520e-02, -5.553e-02, -3.994e-02) * s1[y+0][x+1];
	r += M4(6.694e-02, -5.369e-02, -3.992e-02, -1.187e-03, 3.919e-02, 1.852e-03, -2.161e-04, -1.604e-02, -5.246e-02, -5.840e-02, -6.686e-03, 6.782e-02, -5.780e-02, 8.909e-02, -3.489e-02, 1.517e-02) * s1[y+0][x+2];
	r += M4(-1.373e-02, 5.219e-02, 6.122e-02, 1.656e-02, -3.820e-02, 5.070e-02, 1.121e-01, 3.345e-02, 1.372e-01, -1.538e-01, -1.668e-01, -1.088e-01, -7.426e-02, 8.749e-03, 1.903e-01, 1.105e-02) * s1[y+1][x+0];
	r += M4(-7.647e-02, 8.578e-02, 9.597e-02, -1.628e-02, 2.804e-02, -6.364e-02, -1.398e-01, 7.501e-02, -2.511e-01, 5.733e-01, 1.467e-01, -9.668e-01, 2.616e-01, 1.826e-01, 1.089e-01, -5.623e-02) * s1[y+1][x+1];
	r += M4(-2.359e-02, -6.194e-02, 1.536e-01, -3.611e-02, 3.162e-02, 5.895e-02, -9.560e-02, -7.887e-02, -2.862e-01, -8.627e-02, -1.167e-01, 8.031e-02, -3.699e-02, -1.666e-02, 3.830e-02, 6.305e-02) * s1[y+1][x+2];
	r += M4(-2.069e-02, 2.968e-02, -3.048e-02, 5.843e-03, 8.369e-02, -8.803e-02, -1.301e-01, -1.019e-02, 4.316e-02, -1.145e-01, 2.474e-02, -1.748e-02, -2.375e-02, 3.305e-02, -1.260e-01, -2.130e-02) * s1[y+2][x+0];
	r += M4(-5.111e-02, 2.264e-03, -4.444e-02, 7.405e-02, -2.427e-01, -7.313e-02, 2.124e-01, -1.324e-01, 1.728e-01, -1.182e-02, -1.015e-03, 7.642e-02, -5.661e-02, -5.226e-02, -6.665e-02, 4.477e-02) * s1[y+2][x+1];
	r += M4(1.145e-02, -2.975e-02, -2.588e-02, -3.946e-02, 4.806e-01, -1.028e-02, 5.965e-03, -1.540e-02, -9.302e-02, 3.790e-02, -9.962e-02, 4.833e-02, 3.723e-02, -1.113e-01, -1.350e-02, -5.031e-02) * s1[y+2][x+2];
	r += V4(4.399e-02, -2.435e-02, 2.170e-03, 9.381e-03);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-3x4C-RCAS-DS-out
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv3_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-6.624e-02, -3.111e-02, 1.149e-01, 6.512e-02, -1.840e-01, 5.099e-02, -9.314e-02, 2.984e-02, 6.366e-02, -1.680e-02, 8.922e-02, -1.045e-02, -6.860e-02, -5.780e-03, -2.643e-02, 3.074e-02) * s0[y+0][x+0];
	r += M4(-7.140e-02, -3.468e-02, 1.183e-02, 8.215e-02, 1.734e-01, -8.762e-02, -1.241e-01, -1.859e-01, -1.967e-01, -1.268e-02, -2.431e-02, 1.100e-01, 6.323e-02, 3.184e-02, -7.109e-02, -7.425e-02) * s0[y+0][x+1];
	r += M4(-1.785e-03, -3.908e-02, 1.474e-02, 1.678e-02, 5.822e-03, -8.573e-02, 1.431e-01, -1.847e-02, 8.146e-02, -2.299e-02, -4.709e-02, -7.677e-02, 1.014e-02, -4.752e-03, 3.509e-03, -3.501e-02) * s0[y+0][x+2];
	r += M4(6.860e-02, -2.832e-02, -2.237e-01, -1.431e-01, -5.668e-02, 5.938e-02, -2.274e-01, 7.882e-03, 3.157e-01, -1.106e-01, 1.636e-01, -5.287e-02, -4.168e-03, -4.944e-02, 5.684e-02, -1.094e-02) * s0[y+1][x+0];
	r += M4(-4.706e-03, 2.912e-02, -1.040e-01, -1.629e-01, 2.911e-01, -2.152e-01, 6.621e-01, -8.385e-02, 1.200e-01, 7.469e-01, -4.012e-01, 1.155e-01, -4.153e-01, -1.781e-01, -1.776e-02, 1.376e-01) * s0[y+1][x+1];
	r += M4(-6.223e-03, 4.000e-02, -1.727e-02, -3.577e-02, -1.185e-01, 1.890e-01, -2.456e-01, 1.745e-01, 1.184e-01, -1.479e-01, 1.074e-01, -2.389e-01, 8.511e-02, -1.104e-01, 5.027e-02, -3.687e-02) * s0[y+1][x+2];
	r += M4(6.183e-03, -1.113e-02, 1.315e-01, 2.329e-02, 2.083e-02, -4.175e-02, 9.938e-02, 4.358e-02, -4.457e-02, 1.509e-02, 1.215e-01, -4.164e-02, 2.348e-02, 1.813e-02, -6.341e-02, -3.651e-02) * s0[y+2][x+0];
	r += M4(-1.355e-02, -6.756e-03, -7.812e-03, 6.437e-02, 5.815e-02, 6.044e-02, 8.940e-02, 2.918e-02, -1.697e-01, -1.792e-01, -2.388e-02, 2.959e-01, 5.628e-02, 1.831e-02, -1.851e-01, -1.588e-01) * s0[y+2][x+1];
	r += M4(-1.976e-02, -9.252e-03, -1.167e-02, 1.879e-02, -3.780e-03, 9.047e-04, -1.378e-03, 3.465e-02, 2.885e-02, -5.060e-02, 3.189e-02, -1.391e-01, -1.890e-02, 1.479e-02, 3.821e-02, -1.534e-02) * s0[y+2][x+2];
	r += M4(-4.818e-01, -5.139e-02, 2.510e-01, 1.808e-01, -1.545e-01, 2.015e-03, -4.891e-02, 3.980e-02, 1.472e-01, -2.100e-02, 4.069e-02, -1.573e-02, -8.130e-02, -5.463e-02, -8.289e-02, 2.498e-02) * s1[y+0][x+0];
	r += M4(2.465e-01, -5.645e-01, 1.361e-01, 2.195e-01, -1.741e-02, -6.952e-02, -4.180e-02, -7.476e-02, -1.418e-01, 1.758e-01, -1.870e-01, -2.546e-02, 2.928e-02, 4.960e-02, 2.339e-02, -9.122e-02) * s1[y+0][x+1];
	r += M4(-1.143e-01, 8.238e-03, -7.868e-03, -1.363e-01, 3.119e-02, -4.758e-02, 4.359e-02, 7.196e-03, 4.311e-02, -8.514e-02, 4.280e-02, -4.530e-02, 9.235e-03, -2.042e-02, 2.420e-02, 7.323e-03) * s1[y+0][x+2];
	r += M4(1.714e-01, 1.409e-01, -4.982e-01, -2.950e-02, 1.229e-01, -7.108e-02, -1.362e-01, -1.499e-01, 9.048e-02, -1.189e-01, 2.421e-01, -3.708e-02, -1.793e-01, 8.231e-02, -2.215e-02, -1.769e-03) * s1[y+1][x+0];
	r += M4(1.818e-01, -3.962e-02, 1.313e-01, -7.774e-01, 4.872e-02, 2.146e-01, 2.946e-02, 1.070e-01, -1.661e-01, 2.529e-01, -6.473e-02, 3.838e-01, -2.043e-01, -5.806e-01, -2.647e-01, -2.655e-01) * s1[y+1][x+1];
	r += M4(-1.323e-01, 5.604e-02, -2.144e-01, 1.253e-01, 3.903e-03, 2.582e-02, -6.018e-02, -1.178e-01, 5.894e-02, -1.337e-01, 6.414e-02, -9.373e-02, -1.317e-02, 1.233e-02, -3.866e-02, -1.382e-01) * s1[y+1][x+2];
	r += M4(-1.436e-02, -3.083e-02, 1.380e-01, 1.992e-02, 1.596e-02, -3.794e-02, 1.631e-01, 2.569e-03, 2.301e-02, 2.463e-02, 1.275e-02, -4.114e-02, -1.611e-02, 3.916e-02, -1.353e-01, 6.149e-02) * s1[y+2][x+0];
	r += M4(3.533e-03, -3.123e-02, 7.647e-02, 8.949e-02, 1.259e-02, 3.348e-02, 3.073e-02, 1.224e-01, -5.998e-02, -5.169e-02, -1.675e-01, -2.193e-03, 3.344e-02, -5.745e-02, 2.546e-02, -2.785e-01) * s1[y+2][x+1];
	r += M4(7.360e-03, 9.670e-03, -4.356e-02, 2.137e-02, -2.883e-02, 6.620e-03, 1.850e-02, 8.847e-02, 1.084e-02, 3.255e-03, 2.244e-02, -8.618e-02, -4.089e-02, -5.271e-02, -4.581e-02, 1.237e-03) * s1[y+2][x+2];
	r += V4(7.965e-03, 8.575e-03, 6.119e-03, 6.393e-03);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-3x4C-RCAS-DS-shuffle
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

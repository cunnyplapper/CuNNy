// CuNNy 4x4C RCAS
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


//!DESC CuNNy-4x4C-RCAS-in
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
	r += V4(5.762e-01, 2.184e-02, 1.378e-02, -3.542e-02) * s0[y+0][x+0];
	r += V4(-1.985e-01, 4.050e-02, -7.105e-01, -3.578e-01) * s0[y+0][x+1];
	r += V4(-6.377e-02, -5.945e-02, 1.063e-02, -2.064e-01) * s0[y+0][x+2];
	r += V4(3.297e-02, -3.246e-02, 2.166e-05, 1.716e-01) * s0[y+1][x+0];
	r += V4(-2.136e-01, -8.066e-01, 2.303e-02, 4.014e-01) * s0[y+1][x+1];
	r += V4(8.075e-03, 3.785e-01, 8.348e-03, -2.300e-02) * s0[y+1][x+2];
	r += V4(-5.388e-02, -1.297e-02, -6.424e-04, -9.611e-02) * s0[y+2][x+0];
	r += V4(-4.398e-02, 2.664e-01, -1.469e-03, 2.003e-01) * s0[y+2][x+1];
	r += V4(8.687e-03, 2.056e-01, -1.323e-03, -5.377e-02) * s0[y+2][x+2];
	r += V4(9.365e-03, -2.348e-03, 8.248e-03, -2.323e-02);
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


//!DESC CuNNy-4x4C-RCAS-conv1
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
	r += M4(-9.554e-03, 4.948e-04, -4.505e-02, -1.094e-01, -2.879e-03, -3.408e-01, -1.611e-02, -1.568e-02, -7.202e-02, 8.965e-01, -1.675e+00, -2.358e-01, 7.693e-02, -3.705e-03, 3.839e-01, -2.927e-01) * s0[y+0][x+0];
	r += M4(1.169e-01, 5.073e-02, 3.069e-01, -4.798e-02, -1.715e-02, -3.773e-01, -3.678e-01, 7.129e-01, -2.091e-01, -2.583e-01, 1.739e+00, 4.920e-01, -2.298e-01, 5.134e-02, 9.739e-02, 1.367e-01) * s0[y+0][x+1];
	r += M4(-3.492e-03, -6.111e-02, -7.419e-02, 4.711e-02, -1.714e-01, 5.206e-02, -6.169e-02, 1.636e-01, -3.445e-01, -2.099e-01, -6.613e-01, -9.487e-02, 7.233e-02, 5.955e-02, 2.602e-01, -6.165e-02) * s0[y+0][x+2];
	r += M4(2.172e-02, -5.554e-02, 1.680e-01, 1.224e-01, 2.859e-02, 6.948e-01, -4.365e-01, 1.137e+00, -7.369e-01, -5.237e-01, -9.281e-01, 4.958e-02, -4.035e-03, -4.016e-03, 4.639e-01, -4.658e-01) * s0[y+1][x+0];
	r += M4(-7.769e-02, 2.737e-01, 6.636e-02, -4.796e-01, 7.112e-01, -1.905e-01, -3.838e-01, -5.173e-01, 7.029e-03, 2.940e-01, 1.253e+00, 5.713e-01, 3.438e-02, 1.733e-01, 7.352e-02, 2.895e-01) * s0[y+1][x+1];
	r += M4(7.447e-03, 1.186e-03, -1.757e-01, 3.701e-01, 6.646e-02, 5.513e-02, 1.083e-02, 3.259e-02, -1.490e+00, 4.186e-01, -1.433e+00, 1.902e+00, -4.189e-01, 6.523e-02, 8.055e-02, 9.172e-02) * s0[y+1][x+2];
	r += M4(-3.478e-02, -7.529e-02, 1.374e-01, 1.596e-01, -2.610e-02, -5.678e-02, -5.576e-02, 3.512e-02, 2.155e+00, -1.019e+00, -6.872e-01, 4.531e+00, 4.789e-02, -1.137e-01, 4.079e-02, -8.519e-02) * s0[y+2][x+0];
	r += M4(5.205e-02, -1.289e-01, -2.888e-01, -4.287e-01, 1.702e-01, 3.845e-02, -3.534e-02, 2.065e-01, 1.279e+01, -6.302e+00, -1.051e+00, -5.153e+00, 3.802e-03, 2.244e-02, 3.704e-02, -1.908e-01) * s0[y+2][x+1];
	r += M4(-5.770e-02, 3.877e-02, 2.802e-02, 9.474e-02, -5.799e-02, -6.616e-02, -6.509e-02, -3.952e-02, 3.705e+00, -5.022e-02, -2.226e+00, 9.014e-01, -1.789e-01, -5.698e-02, -8.987e-03, -6.145e-02) * s0[y+2][x+2];
	r += M4(-2.728e-02, 6.636e-02, 1.082e-02, -1.608e-02, -2.167e-01, 6.899e-02, -3.569e-01, -3.194e-01, 6.640e-02, 1.290e-01, -6.639e-02, 9.263e-02, 8.749e-02, 9.246e-02, 1.129e-01, -1.815e-01) * s1[y+0][x+0];
	r += M4(1.829e-01, 3.012e-01, -2.587e-02, -7.345e-02, -4.654e-01, -3.662e-02, 4.229e-01, 3.018e-01, 4.967e-02, -8.965e-02, -2.192e-01, -1.911e-03, -2.246e-01, 1.140e-01, -3.385e-01, 1.988e-01) * s1[y+0][x+1];
	r += M4(-4.370e-02, 8.997e-02, 7.911e-02, -1.292e-01, -1.548e-01, 1.442e-01, 1.342e-01, 6.478e-02, 5.374e-02, -7.737e-02, -2.628e-01, 9.897e-04, 1.240e-01, 3.870e-03, 2.380e-02, -9.693e-02) * s1[y+0][x+2];
	r += M4(-1.311e-02, -6.868e-02, 5.148e-02, -1.405e-02, -1.065e-01, 8.669e-01, 3.497e-02, 4.123e-01, 1.053e-01, 9.655e-02, -2.753e-02, -6.090e-03, 1.876e-01, -5.491e-01, 5.030e-01, -6.692e-01) * s1[y+1][x+0];
	r += M4(-2.135e-02, 6.948e-02, 3.924e-01, -1.367e-01, 5.137e-01, -2.360e-01, 1.743e-01, -6.932e-01, 2.056e-01, -1.117e-01, 2.121e-01, -1.792e-01, -2.503e-01, 1.442e-01, 5.664e-02, 4.150e-01) * s1[y+1][x+1];
	r += M4(1.981e-01, -2.660e-01, -7.062e-02, 3.138e-01, -8.764e-02, -3.796e-02, 1.146e-01, -7.507e-02, 1.419e-01, -2.301e-01, 2.843e-01, 7.307e-02, -2.688e-01, 1.694e-01, 4.884e-02, 2.284e-01) * s1[y+1][x+2];
	r += M4(-1.016e-02, 1.106e-01, -1.412e-01, 1.314e-01, -3.753e-02, 4.600e-02, -4.476e-02, -1.101e-01, -2.008e-02, 2.730e-01, -7.765e-03, -5.021e-03, 4.607e-02, -2.701e-01, -8.036e-02, -1.685e-01) * s1[y+2][x+0];
	r += M4(1.188e-01, 2.853e-01, -4.834e-01, 2.664e-01, 1.817e-01, 1.625e-01, 3.183e-02, 1.813e-01, 2.274e-01, -7.603e-02, 9.614e-02, -7.972e-02, 1.788e-02, -3.057e-01, 5.033e-02, -3.343e-01) * s1[y+2][x+1];
	r += M4(3.887e-01, 4.233e-02, -4.885e-01, 2.286e-02, -1.235e-01, -8.179e-02, -1.148e-02, -2.918e-02, 2.485e-02, 1.032e-01, 1.145e-01, 4.821e-02, -1.782e-01, -7.790e-02, -3.895e-02, -9.713e-02) * s1[y+2][x+2];
	r += V4(-4.232e-03, -1.593e-02, 5.088e-02, -2.999e-02);
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


//!DESC CuNNy-4x4C-RCAS-conv2
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
	r += M4(4.772e-01, -4.220e-02, 1.788e-02, 1.626e-01, 2.128e-01, -7.178e-03, 2.552e-02, 7.869e-02, 8.229e-02, -1.934e-02, -4.571e-02, 4.295e-03, -7.625e-02, -4.261e-02, -3.992e-02, -3.080e-02) * s0[y+0][x+0];
	r += M4(2.257e+00, -3.115e-02, 2.185e-01, -4.694e-02, 2.088e-01, 2.282e-02, 1.377e-01, 3.181e-01, 3.897e-02, 3.598e-02, -3.176e-02, 1.990e-02, -5.047e-01, 7.413e-02, 4.570e-02, 9.507e-02) * s0[y+0][x+1];
	r += M4(-1.931e-01, 2.003e-02, -1.615e-02, -5.158e-02, 1.857e-01, 1.003e-01, 2.974e-02, -2.406e-02, 5.921e-02, -1.307e-04, 1.477e-01, 5.339e-02, 2.750e-01, 4.886e-02, 1.202e-01, 1.640e-01) * s0[y+0][x+2];
	r += M4(-3.599e-02, -4.560e-01, 9.755e-02, -1.732e-01, 7.067e-02, -1.476e-01, 1.742e-01, -1.905e-02, -2.857e-02, 2.164e-02, -1.277e-01, -2.987e-01, 7.053e-02, 8.786e-02, -4.843e-02, 1.228e-01) * s0[y+1][x+0];
	r += M4(1.350e-01, -7.328e-01, -7.480e-01, -5.790e-01, 1.505e-01, 2.112e-01, 5.705e-01, 3.547e-01, 7.814e-02, -9.400e-02, -1.950e-01, 2.505e-02, 1.154e-01, 6.335e-02, 3.005e-01, 8.405e-01) * s0[y+1][x+1];
	r += M4(-1.140e-01, 7.690e-03, 3.409e-02, -1.492e-01, 3.093e-01, -3.616e-02, 3.607e-01, 3.989e-03, 2.059e-01, 2.787e-02, 5.912e-02, 1.523e-01, -1.150e-01, -5.470e-02, 3.423e-01, 4.017e-02) * s0[y+1][x+2];
	r += M4(-1.696e-01, 2.767e-02, 2.047e-01, 1.207e-01, 4.009e-02, -8.729e-03, 1.945e-01, 2.939e-01, 1.487e-01, -2.995e-01, -3.814e-01, -9.261e-02, -1.541e-01, 1.732e-04, -2.057e-01, -1.961e-01) * s0[y+2][x+0];
	r += M4(-8.124e-02, -3.720e-02, -1.268e-01, -1.837e-01, 1.541e-01, 1.916e-04, 1.980e-01, 8.887e-02, 3.324e-02, 9.844e-02, -6.502e-01, 2.920e-01, -2.091e-01, -6.637e-02, -1.578e-01, -3.302e-01) * s0[y+2][x+1];
	r += M4(6.368e-02, 1.750e-03, -7.389e-02, -1.489e-01, -8.988e-02, -6.790e-02, 2.714e-01, 8.197e-02, 1.525e-01, -1.420e-01, 2.857e-01, 3.019e-01, 2.241e-01, 1.852e-02, 3.008e-01, -1.193e-01) * s0[y+2][x+2];
	r += M4(4.816e-01, 2.329e-02, -7.096e-03, 2.124e-01, 1.248e-01, -1.914e-02, 2.816e-02, -3.279e-02, -1.497e-01, 1.564e-02, -6.638e-02, -4.354e-02, -1.488e-01, -4.089e-02, -1.672e-01, -9.136e-02) * s1[y+0][x+0];
	r += M4(2.607e-01, 5.278e-02, 1.364e-01, 2.476e-01, -1.327e-01, -4.810e-02, -2.048e-01, -1.081e-01, -9.772e-02, 3.629e-02, 1.720e-02, 5.754e-02, -3.348e-01, 4.159e-02, -2.783e-01, 6.085e-02) * s1[y+0][x+1];
	r += M4(-3.331e-03, 2.081e-02, 1.304e-01, 1.564e-01, -1.228e-01, 3.869e-02, 2.549e-01, -1.136e-02, 1.020e-01, -2.724e-03, 1.265e-01, 1.238e-01, 2.036e-01, 3.702e-02, -2.155e-01, 1.576e-01) * s1[y+0][x+2];
	r += M4(-3.162e-01, -3.194e-01, 9.938e-02, -1.843e-01, 6.473e-02, -1.772e-01, -9.287e-02, -3.084e-01, 2.474e-01, -3.016e-02, 1.444e-01, 1.087e-01, -6.173e-02, 7.818e-03, -1.424e-01, 2.221e-01) * s1[y+1][x+0];
	r += M4(-2.340e-01, -4.935e-01, -7.724e-02, -1.147e-01, -1.235e-01, 1.645e-01, -8.953e-02, 2.783e-01, -5.341e-02, -5.259e-02, 1.799e-01, 4.993e-01, 4.453e-01, 1.554e+00, 8.519e-02, 4.782e-02) * s1[y+1][x+1];
	r += M4(-5.261e-02, -5.204e-03, 2.522e-02, -3.119e-02, -2.276e-01, -3.393e-02, 1.275e-01, -3.670e-01, 2.160e-01, 3.757e-02, 9.625e-02, 1.708e-01, 2.503e-01, -7.590e-02, -1.238e-01, 2.421e-01) * s1[y+1][x+2];
	r += M4(-1.870e-01, -3.976e-02, -6.086e-02, 1.891e-02, 2.848e-02, 6.676e-03, 4.428e-02, 9.046e-02, -1.028e-01, -3.741e-02, 9.360e-02, 1.972e-01, -6.011e-02, -9.042e-02, -2.310e-01, -1.909e-01) * s1[y+2][x+0];
	r += M4(-9.454e-02, -6.856e-02, -3.447e-01, -2.979e-01, 2.360e-01, 5.598e-02, 6.215e-02, 3.408e-01, -2.621e-01, -4.324e-02, 1.446e-02, -8.370e-02, -3.614e-02, -1.630e-01, -3.438e-01, -4.814e-01) * s1[y+2][x+1];
	r += M4(9.769e-02, -5.849e-02, -4.813e-02, -1.710e-01, -2.398e-01, -4.432e-02, -1.656e-01, 1.841e-01, 1.743e-01, -9.852e-02, 7.910e-01, 8.887e-02, 3.614e-01, -1.513e-02, 2.151e-01, -8.618e-02) * s1[y+2][x+2];
	r += V4(-7.903e-03, -4.894e-01, -5.016e-02, -5.696e-02);
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


//!DESC CuNNy-4x4C-RCAS-conv3
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
	r += M4(-3.639e-02, 7.446e-03, -1.577e-02, 7.940e-02, -1.476e-01, -2.868e-01, -3.453e+00, 4.027e-01, -6.658e-02, -1.633e-01, 2.476e-02, -5.561e-02, 2.567e-02, 6.644e-02, -1.660e-02, -4.831e-02) * s0[y+0][x+0];
	r += M4(4.603e-02, -1.798e-02, 4.346e-03, 2.101e-02, 8.550e-01, -1.446e+00, -3.357e+00, 9.787e-01, -1.733e-01, -4.203e-02, 2.344e-02, -7.375e-02, 2.015e-01, 4.188e-02, 3.011e-01, -2.470e-01) * s0[y+0][x+1];
	r += M4(-1.597e-02, 1.376e-02, 3.637e-03, -1.509e-02, -4.119e-01, 8.604e-02, -4.352e-01, 3.458e-01, 2.513e-01, 6.808e-02, 6.612e-02, -2.258e-01, -3.191e-01, 8.563e-02, -1.668e-02, 1.704e-01) * s0[y+0][x+2];
	r += M4(2.688e-02, -2.328e-02, -1.971e-02, 3.183e-02, -1.168e+00, 2.609e-01, -3.951e-01, 5.656e-01, -9.999e-02, -6.224e-02, -1.861e-01, -1.607e-01, -1.003e-01, 9.529e-02, 4.588e-02, 1.625e-01) * s0[y+1][x+0];
	r += M4(1.968e-01, -1.280e-01, 2.826e-02, -3.096e-01, 2.153e+00, 3.152e+00, -1.155e-01, -4.340e-03, -4.159e-01, -3.905e-01, 2.332e-01, -2.174e-02, 4.949e-01, 7.129e-01, -1.044e-01, 2.031e-01) * s0[y+1][x+1];
	r += M4(-6.196e-02, -1.774e-04, 8.994e-03, 2.510e-04, -9.749e-01, 1.834e-02, 3.364e-02, 1.049e+00, 1.162e-01, 2.340e-02, -9.368e-03, 5.491e-02, -4.556e-01, 1.295e-01, -6.532e-03, 1.078e-01) * s0[y+1][x+2];
	r += M4(-2.092e-02, -6.325e-02, -8.517e-02, 9.234e-02, -3.966e-01, -8.190e-01, -2.200e-01, 5.569e-01, 8.814e-03, -6.210e-02, 1.646e-01, -1.398e-01, -7.980e-02, -1.788e-02, -2.746e-02, 1.158e-01) * s0[y+2][x+0];
	r += M4(-2.416e-02, -1.645e-01, 5.049e-02, -4.584e-01, 2.589e-01, 3.688e-01, -4.363e-01, -4.439e-01, -7.215e-02, -1.615e-01, 6.372e-02, 2.056e-01, 7.169e-02, 7.351e-02, -1.067e-01, -9.986e-02) * s0[y+2][x+1];
	r += M4(-7.126e-02, -9.999e-02, 1.165e-02, 1.646e-01, -4.580e-01, -2.607e-01, -6.792e-02, 7.537e-02, 1.479e-01, -1.139e-02, 8.185e-03, -1.552e-01, -2.823e-02, 5.145e-02, -6.643e-02, 2.126e-02) * s0[y+2][x+2];
	r += M4(2.276e-02, 3.538e-02, 2.885e-02, -1.009e-01, 5.638e-02, -1.689e-02, -6.908e-03, -3.674e-02, 9.282e-03, -1.097e-01, -3.514e-02, 3.462e-03, 5.865e-03, 1.382e-01, 1.295e-01, -2.943e-02) * s1[y+0][x+0];
	r += M4(2.858e-02, -6.632e-02, 4.629e-02, 1.614e-01, 6.519e-02, -1.081e-01, 6.667e-02, -3.870e-02, -4.214e-02, -6.925e-03, -1.445e-01, 1.012e-01, 3.174e-01, -1.159e-02, 1.359e-01, 1.953e-01) * s1[y+0][x+1];
	r += M4(-1.149e-01, -6.810e-04, -7.577e-02, -9.654e-02, -1.431e-01, 5.199e-02, 2.857e-02, 2.887e-02, 2.998e-01, -2.409e-02, 2.922e-02, -1.243e-01, -1.576e-01, -4.151e-03, -2.964e-02, 1.054e-01) * s1[y+0][x+2];
	r += M4(-5.310e-02, 4.198e-02, 2.301e-01, -3.828e-01, -4.459e-02, 4.354e-03, -4.570e-02, 1.560e-04, 1.672e-01, -2.054e-01, -1.459e-01, 2.863e-01, -3.625e-01, 1.141e-01, -1.694e-01, 4.288e-01) * s1[y+1][x+0];
	r += M4(4.661e-01, 1.085e-01, 1.662e-02, -9.463e-01, 1.743e-01, 2.573e-01, -1.783e-02, 7.525e-02, -2.053e-01, -1.839e-01, 5.726e-02, 3.147e-01, 3.366e-01, 4.956e-01, -6.519e-02, 1.371e-01) * s1[y+1][x+1];
	r += M4(-4.940e-01, 1.771e-01, 4.432e-02, -1.223e-01, -1.256e-01, -8.847e-02, 2.907e-02, -7.196e-02, 3.331e-01, -8.676e-02, -1.669e-02, 6.790e-02, -3.897e-01, 1.987e-02, -2.138e-02, 3.054e-03) * s1[y+1][x+2];
	r += M4(-6.352e-02, 5.437e-02, 3.698e-02, -1.935e-01, 8.489e-03, -3.422e-02, 1.285e-02, 5.676e-02, -4.851e-03, -1.773e-01, 1.237e-02, -8.556e-02, -1.199e-01, 7.393e-02, -2.068e-02, -4.687e-04) * s1[y+2][x+0];
	r += M4(1.881e-01, -1.015e-01, 1.458e-01, -3.643e-01, 1.244e-03, -1.377e-02, -5.278e-02, -3.157e-02, 5.541e-02, -7.840e-02, 7.790e-02, -1.011e-01, 6.251e-02, -1.073e-01, -1.233e-03, -1.267e-01) * s1[y+2][x+1];
	r += M4(4.406e-02, 2.010e-01, -8.297e-02, 2.958e-01, -2.848e-02, 1.167e-03, -2.937e-03, -6.464e-02, 1.323e-01, -1.341e-01, -2.123e-03, -8.341e-03, -1.340e-02, 8.964e-02, -1.392e-02, 5.830e-02) * s1[y+2][x+2];
	r += V4(-3.253e-02, 6.066e-02, 1.453e-02, -1.179e-02);
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


//!DESC CuNNy-4x4C-RCAS-conv4
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
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(2.431e-03, -2.705e-01, -9.096e-02, 1.827e-03, 3.209e-02, 1.512e-02, -3.104e-02, -3.562e-02, -3.132e-02, 6.532e-03, 5.386e-02, 5.969e-02, -1.210e-02, 6.300e-02, 1.948e-02, -9.773e-05) * s0[y+0][x+0];
	r += M4(8.055e-03, 3.241e-02, 4.061e-03, 1.578e-01, -1.366e-02, 1.004e-01, 9.226e-02, 4.771e-02, 9.046e-03, -7.594e-02, -2.974e-02, -3.358e-02, 1.799e-01, 3.244e-02, -5.432e-02, 1.871e-01) * s0[y+0][x+1];
	r += M4(-9.257e-03, 5.810e-03, 2.152e-02, -1.835e-03, -4.322e-03, 4.343e-02, -7.627e-02, 1.307e-02, 3.007e-02, 4.396e-03, 2.894e-02, 1.163e-01, -1.069e-02, 2.532e-02, -2.049e-02, 1.382e-01) * s0[y+0][x+2];
	r += M4(-4.263e-01, -4.677e-01, -8.991e-03, 2.825e-01, -2.690e-01, 4.706e-02, -1.871e-02, 1.050e-01, 3.917e-02, 5.719e-02, 9.256e-02, 1.230e-01, 7.497e-02, 1.145e-01, 9.344e-03, -3.516e-02) * s0[y+1][x+0];
	r += M4(-2.353e-01, 4.371e-01, 1.868e+00, -1.659e-01, -2.381e-01, -2.609e-01, 2.607e-01, 8.363e-02, 8.807e-02, -3.082e-01, -1.031e-01, -3.257e-01, -2.136e-01, -3.115e-01, -2.782e-02, -3.994e-01) * s0[y+1][x+1];
	r += M4(-7.758e-02, 1.492e-02, 5.483e-02, 9.430e-02, -5.149e-02, 1.796e-01, -1.822e-01, -6.763e-02, 9.938e-02, 3.715e-02, 8.267e-02, 1.811e-03, 1.360e-01, 9.249e-02, -4.750e-03, -1.627e-01) * s0[y+1][x+2];
	r += M4(1.202e-01, -2.959e-01, 8.664e-02, -5.510e-02, 8.815e-02, 3.528e-02, 4.115e-03, -5.115e-02, 1.277e-01, 7.966e-02, 6.759e-02, -1.352e-02, -2.606e-02, 2.112e-01, -3.361e-02, 1.072e-01) * s0[y+2][x+0];
	r += M4(7.037e-02, -1.077e-01, -1.547e-01, -8.707e-03, 2.738e-01, -4.314e-02, 1.490e-02, 1.564e-02, 1.560e-01, 1.097e-02, -1.446e-01, -6.477e-02, 1.467e-01, -6.137e-02, 4.675e-02, 2.803e-01) * s0[y+2][x+1];
	r += M4(6.612e-02, 8.155e-04, 3.228e-03, -2.753e-02, 1.082e-01, -5.804e-03, -4.427e-02, 4.732e-03, 1.275e-01, -3.870e-02, 3.137e-02, -1.730e-01, -7.978e-02, 5.074e-02, -7.700e-03, 1.332e-02) * s0[y+2][x+2];
	r += M4(1.625e-02, -3.961e-02, 1.215e-02, 2.417e-02, -9.650e-02, 3.519e-02, -2.663e-02, 7.932e-02, 6.004e-02, 2.194e-02, -1.574e-02, 7.049e-03, 2.779e-02, -3.032e-02, 3.230e-03, -4.359e-02) * s1[y+0][x+0];
	r += M4(6.751e-02, 5.627e-02, 2.409e-02, 9.721e-02, -1.343e-01, 8.664e-02, 7.642e-02, 1.904e-01, -4.469e-02, -4.438e-02, 2.286e-03, -3.563e-02, 3.603e-02, -4.180e-02, -1.802e-02, -7.704e-02) * s1[y+0][x+1];
	r += M4(9.814e-03, 3.937e-03, 1.939e-03, 4.216e-02, -7.235e-02, 3.908e-02, -6.957e-02, 9.106e-02, 1.557e-02, -5.349e-02, -8.701e-03, 6.577e-02, 2.466e-02, -1.437e-02, -1.213e-02, 1.997e-03) * s1[y+0][x+2];
	r += M4(-5.804e-02, 1.341e-01, -2.463e-02, -3.686e-03, -9.912e-02, 1.071e-02, -6.908e-02, -2.826e-02, -2.055e-01, 7.436e-02, 4.544e-02, 8.857e-02, 6.487e-02, 3.307e-02, 4.846e-02, 5.261e-02) * s1[y+1][x+0];
	r += M4(-1.082e-01, -4.417e-02, -5.027e-02, -1.423e-01, -2.999e-01, -7.012e-01, 2.285e-01, 4.385e-01, 2.639e-01, -4.220e-02, -1.147e-01, -1.230e-01, 1.716e-01, -2.403e-01, -9.457e-02, -4.205e-01) * s1[y+1][x+1];
	r += M4(-1.374e-02, 6.613e-02, -9.131e-02, -6.044e-02, -1.585e-01, 1.931e-01, -3.043e-01, -8.131e-02, 9.321e-02, 3.103e-01, 3.446e-02, 1.782e-01, 1.324e-01, -2.959e-02, 2.603e-02, -7.789e-02) * s1[y+1][x+2];
	r += M4(1.310e-01, -6.669e-02, 8.715e-02, 4.218e-02, 2.755e-02, -4.163e-02, -2.069e-02, -7.106e-02, 1.766e-01, 2.068e-02, -2.715e-02, -6.438e-02, 1.070e-02, 6.716e-02, -1.907e-03, 2.880e-02) * s1[y+2][x+0];
	r += M4(1.060e-01, -5.828e-02, -2.144e-02, 4.330e-03, 1.172e-02, -1.007e-01, 7.983e-02, -7.967e-02, 6.089e-01, 7.457e-04, -5.852e-02, 1.195e-01, -1.303e-02, -6.841e-02, -9.432e-02, 5.100e-02) * s1[y+2][x+1];
	r += M4(2.227e-02, 5.370e-02, -4.365e-02, -4.480e-02, 5.471e-02, 5.202e-02, -9.764e-02, 2.740e-02, 1.060e+00, 1.188e-01, -5.507e-03, 1.733e-03, 4.301e-02, -9.532e-02, 1.027e-02, -7.909e-02) * s1[y+2][x+2];
	r += V4(-1.696e-02, 1.108e-02, 3.735e-03, 4.962e-03);
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-4x4C-RCAS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv4
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
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.439e-02, 2.304e-02, -1.553e-03, 6.768e-02, -7.913e-03, -1.379e-02, 2.009e-02, -3.210e-02, -5.218e-02, -2.926e-03, -4.850e-02, -4.851e-03, -1.490e-03, 2.987e-02, -2.031e-03, 4.836e-02) * s0[y+0][x+0];
	r += M4(1.204e-01, -6.422e-02, -1.571e-01, -1.528e-01, -2.044e-02, 1.215e-02, 9.776e-02, 1.067e-01, 8.122e-03, -6.239e-03, -1.382e-02, -3.626e-02, 6.083e-02, -1.678e-02, -3.342e-02, -8.374e-02) * s0[y+0][x+1];
	r += M4(1.360e-02, 1.821e-01, 5.813e-03, -5.740e-02, -1.099e-02, -3.757e-02, 9.098e-03, 4.404e-02, -7.983e-04, -2.917e-03, -2.858e-03, 2.980e-03, -1.459e-02, 3.403e-02, -6.590e-03, -6.599e-03) * s0[y+0][x+2];
	r += M4(5.443e-02, -1.451e-02, 1.343e-01, 2.373e-03, -7.329e-03, 2.405e-02, -6.448e-02, 2.768e-02, -1.941e-02, -1.562e-01, -4.545e-02, -1.357e-01, 2.809e-03, 9.059e-02, 1.549e-02, 5.531e-02) * s0[y+1][x+0];
	r += M4(-6.734e-01, -2.386e-01, 2.136e-01, 1.978e-01, -1.324e-01, -1.218e-01, -3.118e-01, -2.715e-01, -2.184e-02, 1.048e-01, 2.111e-02, 1.121e-01, -6.998e-02, -1.597e-01, 1.086e-01, 2.875e-02) * s0[y+1][x+1];
	r += M4(5.966e-04, -3.732e-01, 1.324e-01, 3.000e-01, 2.803e-02, -3.585e-02, -2.751e-02, -1.585e-01, 2.537e-03, -1.920e-04, 8.471e-03, 7.280e-03, 7.595e-04, 4.901e-03, -3.027e-02, 1.133e-02) * s0[y+1][x+2];
	r += M4(-2.005e-02, -1.544e-02, -4.945e-02, 1.371e-02, -7.009e-03, -1.837e-02, 1.892e-02, -1.911e-02, -1.283e-02, 9.615e-03, -7.836e-03, -3.150e-02, -4.509e-02, 4.858e-03, -3.234e-02, 5.987e-02) * s0[y+2][x+0];
	r += M4(1.348e-01, 7.753e-02, -2.560e-02, -6.971e-02, 2.919e-02, 1.081e-02, 5.870e-02, 4.695e-02, -2.375e-03, -7.723e-04, -3.699e-02, 8.656e-03, 3.476e-02, -4.892e-02, -4.756e-02, -1.645e-01) * s0[y+2][x+1];
	r += M4(-3.571e-03, 7.935e-02, 6.881e-04, 2.303e-04, 2.780e-03, 1.647e-02, 1.802e-02, 4.017e-02, -3.328e-04, 1.074e-04, -2.460e-03, -1.208e-02, -1.238e-02, 1.919e-02, 1.955e-02, 3.476e-02) * s0[y+2][x+2];
	r += M4(-2.197e-02, 1.991e-02, -1.642e-02, 3.939e-02, 5.757e-02, -3.489e-02, 2.973e-02, -7.249e-03, -8.836e-02, 1.750e-01, 6.043e-02, -1.034e-01, -6.850e-02, 3.502e-02, -1.914e-02, 5.244e-02) * s1[y+0][x+0];
	r += M4(-1.740e-02, -7.413e-02, -5.655e-02, -1.314e-01, -5.430e-02, 9.008e-02, 5.403e-02, 1.402e-01, 5.450e-01, -8.820e-01, -1.245e-02, -8.827e-02, 2.190e-01, -2.997e-03, -1.581e-01, -1.451e-01) * s1[y+0][x+1];
	r += M4(-2.257e-03, 2.296e-02, 3.603e-02, 6.686e-02, -2.663e-02, 4.553e-02, 2.016e-02, 2.313e-02, -3.944e-01, 4.868e-01, -1.463e-01, 1.542e-02, -7.838e-02, -6.300e-03, 4.316e-02, -6.041e-02) * s1[y+0][x+2];
	r += M4(3.328e-02, 2.705e-02, 4.709e-02, 1.824e-03, 1.558e-01, -1.165e-01, 3.748e-02, -6.601e-02, -2.726e-01, 1.252e-01, -3.505e-01, 5.268e-01, -1.177e-01, 1.550e-01, -2.628e-02, 7.883e-02) * s1[y+1][x+0];
	r += M4(-1.968e-01, -1.367e-01, -1.175e-01, -2.131e-02, -5.379e-01, -1.882e-02, -5.031e-01, -2.576e-01, 6.317e-01, -1.553e-01, 9.586e-01, -1.370e+00, -4.033e-01, -7.066e-01, 7.346e-01, 1.607e-01) * s1[y+1][x+1];
	r += M4(3.504e-02, -2.861e-02, -2.899e-02, -9.133e-02, 7.252e-02, -4.241e-02, -5.418e-02, -2.971e-02, -1.185e-01, -1.664e-01, -3.780e-01, 4.605e-01, -3.651e-02, -2.323e-02, -1.526e-01, 2.918e-01) * s1[y+1][x+2];
	r += M4(-2.396e-02, -1.683e-02, -2.529e-02, 5.985e-03, -7.131e-02, -3.570e-03, 5.041e-02, -1.033e-01, -1.149e-02, -4.459e-02, -4.685e-02, -1.849e-01, -1.444e-02, -8.325e-02, -3.217e-02, 3.984e-02) * s1[y+2][x+0];
	r += M4(2.889e-02, 5.024e-03, -3.080e-02, -7.602e-02, 2.335e-02, 6.910e-02, -1.831e-01, 2.251e-01, -1.245e-01, -2.176e-01, 2.026e-02, 1.243e-01, 1.773e-01, 1.279e-01, -2.732e-01, -3.286e-01) * s1[y+2][x+1];
	r += M4(-1.222e-02, 2.576e-03, 1.834e-03, 4.036e-03, 1.205e-02, 2.640e-02, 7.054e-02, 2.221e-03, 1.084e-01, 1.232e-01, 1.131e-01, -1.511e-01, -3.558e-02, 6.267e-02, 2.703e-02, -2.005e-02) * s1[y+2][x+2];
	r += V4(-4.439e-04, -3.966e-04, -1.015e-04, -1.547e-04);
	return tanh(vec4(r));
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
	imageStore(out_image, opos + ivec2(0, 0), f0(xy.x, xy.y));
}


//!DESC CuNNy-4x4C-RCAS-shuffle
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

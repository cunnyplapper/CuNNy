// CuNNy 3x4C RCAS
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


//!DESC CuNNy-3x4C-RCAS-in
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
	r += V4(-3.198e-03, 1.358e-02, 2.097e-01, -3.564e-01) * s0[y+0][x+0];
	r += V4(-1.485e-02, -5.686e-01, 2.594e-01, -1.690e-03) * s0[y+0][x+1];
	r += V4(1.247e-02, 1.381e-02, 3.676e-02, 8.069e-03) * s0[y+0][x+2];
	r += V4(-6.364e-01, -2.293e-02, -1.844e-01, -2.945e-01) * s0[y+1][x+0];
	r += V4(6.617e-01, 5.831e-01, -4.486e-01, 1.387e-01) * s0[y+1][x+1];
	r += V4(-2.143e-02, -1.248e-02, 1.223e-01, -5.861e-02) * s0[y+1][x+2];
	r += V4(2.058e-03, 6.515e-03, -4.153e-02, -2.298e-01) * s0[y+2][x+0];
	r += V4(-6.301e-03, -7.388e-03, -1.750e-02, -8.411e-02) * s0[y+2][x+1];
	r += V4(5.594e-03, 9.002e-04, -3.472e-02, 4.574e-02) * s0[y+2][x+2];
	r += V4(2.949e-03, -2.481e-03, 9.203e-02, 1.973e-02);
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

//!DESC CuNNy-3x4C-RCAS-conv1
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
	r += M4(-1.294e-01, -4.117e-02, 8.466e-02, 2.355e-01, 1.293e-01, -1.340e-01, 7.248e-02, 3.215e-02, 1.640e-01, 1.967e-01, -3.345e-02, -1.538e-01, -7.884e-02, -3.521e-01, -3.168e-01, -6.069e-01) * s0[y+0][x+0];
	r += M4(-9.899e-02, 1.420e-01, -1.151e-01, 1.411e-01, 2.843e-02, 7.468e-02, 1.139e-02, 2.819e-02, -1.569e-01, -4.083e-01, -1.037e-01, -2.348e-01, -7.353e-01, 1.341e-01, 3.662e+00, -1.518e+00) * s0[y+0][x+1];
	r += M4(-2.067e-01, 3.608e-01, 5.842e-02, -2.044e-01, 2.371e-02, 2.050e-01, -4.554e-02, 7.946e-02, -2.086e-01, 1.298e-01, -7.689e-02, -1.928e-01, -1.741e+00, -1.704e+00, -1.551e+00, -5.368e+00) * s0[y+0][x+2];
	r += M4(1.522e-01, -7.144e-03, 3.791e-01, -1.235e-02, -1.594e-01, -4.884e-01, 2.562e-01, 5.996e-01, -5.196e-01, 1.956e-01, -6.106e-02, 2.791e-01, -2.782e-02, -2.203e-01, -4.064e-01, -6.118e-01) * s0[y+1][x+0];
	r += M4(4.968e-02, -7.586e-02, -7.607e-01, 4.223e-01, -8.108e-01, 7.051e-01, -3.444e-01, 8.688e-02, 3.422e-01, 1.664e-01, -5.291e-01, -1.826e-01, 3.975e-02, -2.634e+00, 4.281e+00, -1.031e+00) * s0[y+1][x+1];
	r += M4(-6.358e-01, -1.048e-02, 1.379e-01, -5.878e-01, -4.602e-01, 1.419e-01, 2.566e-02, 1.841e-01, 1.767e-01, -2.435e-02, 3.742e-02, 1.552e-01, 5.607e-01, -2.017e+00, 6.349e-01, -4.849e+00) * s0[y+1][x+2];
	r += M4(4.930e-02, -5.154e-02, -8.032e-02, -1.265e-01, -2.133e-01, 1.550e-01, 2.181e-01, 1.004e-01, 6.455e-02, 1.195e-01, 5.528e-01, 1.540e-01, -2.682e-02, -6.050e-02, -9.793e-02, 6.750e-02) * s0[y+2][x+0];
	r += M4(-1.589e-01, -1.043e-02, 9.720e-02, 1.130e-01, -3.019e-01, 3.236e-01, -2.250e-01, -6.334e-01, 3.484e-02, -1.337e-02, 6.525e-02, 1.977e-01, 2.981e-01, -1.043e+00, 1.450e+00, -5.093e-01) * s0[y+2][x+1];
	r += M4(-1.870e-01, 1.042e-01, 1.252e-02, -2.063e-01, -1.166e-01, -8.928e-02, -1.337e-02, -1.159e-02, 2.878e-01, -1.275e-01, -3.454e-03, 5.581e-02, -1.192e+00, -6.070e-01, 1.187e+00, -4.534e+00) * s0[y+2][x+2];
	r += M4(-2.002e-01, -1.620e-02, 8.172e-02, 2.587e-01, -4.624e-02, -8.916e-02, -1.020e-01, -8.211e-03, 2.078e-01, 1.343e-01, -4.349e-02, -2.651e-01, 1.163e-01, 1.287e-01, -5.495e-03, -1.273e-01) * s1[y+0][x+0];
	r += M4(-1.295e-01, 7.344e-01, -9.210e-02, 3.834e-01, -2.530e-01, 3.529e-02, -5.851e-02, -2.794e-02, 1.847e-01, -4.019e-01, -2.225e-02, 4.640e-02, 1.160e-01, -1.265e-01, -1.863e-01, -2.054e-01) * s1[y+0][x+1];
	r += M4(-1.306e-01, 1.849e-01, -6.930e-03, -3.204e-01, -2.021e-01, 2.012e-01, -4.676e-02, -1.313e-02, -1.161e-01, 4.633e-01, -6.474e-02, -9.203e-02, 1.609e-03, -1.612e-02, -3.686e-02, -1.455e-01) * s1[y+0][x+2];
	r += M4(8.451e-02, 1.771e-01, 1.110e+00, 1.437e-02, -4.250e-01, 4.894e-01, 1.393e+00, 2.359e-01, -2.783e-01, 4.030e-01, -1.256e-01, 1.699e-01, -1.176e-01, 5.807e-02, -1.756e-01, 5.275e-02) * s1[y+1][x+0];
	r += M4(1.448e-01, 6.736e-01, -2.300e-01, 7.564e-01, 2.062e-01, -8.770e-01, -3.196e-01, -2.643e-01, -1.202e-01, -2.391e-01, -5.600e-01, 1.999e-01, 2.955e-02, -7.692e-02, -8.104e-02, 1.438e-01) * s1[y+1][x+1];
	r += M4(6.622e-01, -3.069e-01, 1.149e-01, -2.855e-01, -8.063e-02, 8.843e-02, -3.119e-02, -7.515e-02, -4.376e-01, -1.919e-01, 7.719e-02, 1.329e-01, 6.449e-02, -5.373e-02, 1.014e-02, 2.754e-01) * s1[y+1][x+2];
	r += M4(-1.717e-02, -4.669e-02, -9.217e-02, -2.437e-01, -2.369e-01, 3.434e-01, 4.444e-01, -2.282e-03, 2.355e-01, 1.735e-01, 5.541e-01, 5.326e-02, -1.383e-02, -9.010e-02, -5.594e-02, 1.090e-01) * s1[y+2][x+0];
	r += M4(-2.456e-01, 2.344e-01, 8.563e-02, 1.618e-01, 1.274e+00, -1.915e-01, -2.051e-01, -4.036e-01, -2.047e-01, 2.920e-01, 6.108e-02, 6.522e-02, 1.214e-01, -1.587e-02, -9.937e-02, -1.625e-01) * s1[y+2][x+1];
	r += M4(3.204e-01, 7.460e-02, -3.911e-02, -1.470e-04, 6.453e-01, -4.057e-01, -1.865e-02, 7.957e-03, 3.520e-01, -1.119e-01, -9.852e-03, 8.948e-02, -2.818e-01, 1.333e-01, -4.912e-02, -7.206e-02) * s1[y+2][x+2];
	r += V4(5.885e-02, -2.877e-02, -5.454e-01, 2.251e-03);
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

//!DESC CuNNy-3x4C-RCAS-conv2
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
	r += M4(-4.508e-01, -3.632e-02, 2.776e-01, -3.306e-01, -4.230e-02, -2.146e-02, 1.427e-02, 1.335e-01, -1.368e-01, 1.194e-01, -7.498e-02, 3.379e-01, 1.536e-01, 3.308e-03, -1.710e-02, 1.027e-01) * s0[y+0][x+0];
	r += M4(-8.180e-02, 1.234e-02, 2.343e-01, -4.471e-01, 8.678e-03, 1.141e-02, 1.349e-01, -2.949e-02, -3.046e-01, 1.815e-01, 6.216e-02, 2.204e-02, -1.332e-01, -1.893e-02, -1.287e-01, 2.482e-01) * s0[y+0][x+1];
	r += M4(1.704e-01, -4.007e-01, -3.212e-01, 5.444e-02, 6.176e-02, -1.902e-01, -6.831e-02, 1.606e-02, 1.395e-01, 2.757e-02, -5.688e-02, -7.168e-01, -6.225e-03, 2.153e-01, 9.709e-02, 9.079e-03) * s0[y+0][x+2];
	r += M4(-4.118e-01, 8.683e-02, 1.746e-01, -5.446e-01, -1.601e-01, 8.329e-02, -4.207e-02, -1.451e-01, 6.116e-01, 1.466e-01, -2.755e-02, 5.313e-01, -3.263e-01, 4.407e-02, -2.474e-02, -5.239e-02) * s0[y+1][x+0];
	r += M4(-2.941e-01, -2.468e-02, 2.288e-02, -3.484e-01, 3.028e-01, 3.603e-01, 2.567e-01, -4.056e-01, 1.181e-01, 6.804e-02, 1.871e+00, 7.700e-01, 5.592e-01, -1.399e-01, 3.364e-01, -4.696e-01) * s0[y+1][x+1];
	r += M4(4.405e-01, 1.947e-01, -2.563e-01, -2.426e-01, 2.861e-01, 1.450e-01, -1.086e-01, 1.733e-01, 2.325e+00, -5.642e-01, 5.521e+00, -3.171e+00, -9.876e-02, -7.182e-01, -3.955e-01, -1.438e-01) * s0[y+1][x+2];
	r += M4(1.055e-02, 2.109e-01, 2.505e-01, -4.655e-01, -4.579e-02, -1.052e-02, 2.087e-02, -4.477e-02, -3.062e-01, 7.375e-02, -3.478e-02, 5.525e-02, -4.011e-02, -4.766e-02, -1.212e-02, 8.250e-03) * s0[y+2][x+0];
	r += M4(2.889e-01, 4.737e-01, 1.407e-01, -2.457e-01, 1.654e-01, -1.451e-02, 1.120e-01, -6.861e-02, 2.455e-01, -5.296e-01, -2.854e-02, 5.992e-01, -1.969e-01, 4.125e-02, 2.829e-02, 3.824e-01) * s0[y+2][x+1];
	r += M4(1.887e-01, 1.656e-01, -3.747e-02, 7.344e-02, -4.617e-03, -2.729e-01, 1.082e-01, 2.489e-02, 2.993e-01, -9.534e-01, 4.212e-01, 9.900e-01, 3.134e-02, 3.203e-01, -1.035e-01, 6.818e-02) * s0[y+2][x+2];
	r += M4(-2.148e-01, -7.821e-02, -1.301e-02, 1.303e-01, -4.094e-02, -2.424e-02, 2.433e-02, 8.391e-03, 1.727e-02, 1.411e-02, 8.937e-03, -1.703e-02, 1.179e-01, -1.087e-02, 2.068e-02, -9.982e-02) * s1[y+0][x+0];
	r += M4(1.646e-01, -5.497e-02, 2.045e-01, -1.440e-01, 5.168e-02, 2.510e-02, 5.755e-02, 1.392e-01, -2.151e-02, -2.466e-02, -7.828e-03, -4.956e-02, -1.383e-01, -5.837e-04, -1.372e-01, 2.998e-02) * s1[y+0][x+1];
	r += M4(7.180e-02, -4.364e-01, -2.368e-01, 1.372e-01, 6.934e-03, -3.144e-01, -2.023e-02, 1.003e-01, -1.899e-01, 5.796e-02, -3.902e-02, -2.480e-03, 7.264e-02, 4.460e-01, 1.378e-01, -1.499e-01) * s1[y+0][x+2];
	r += M4(-1.851e-01, 5.288e-02, 8.664e-02, -1.719e-01, -7.785e-02, -8.814e-03, -7.378e-03, 4.421e-03, 1.296e-02, 8.147e-03, 2.075e-02, 2.962e-02, -1.900e-01, 5.677e-02, -8.099e-02, 1.538e-01) * s1[y+1][x+0];
	r += M4(1.417e-01, -7.524e-02, -9.012e-02, -3.366e-01, -9.667e-02, 1.157e-01, -1.512e-02, -2.326e-01, 7.963e-02, -1.635e-02, -3.695e-02, -5.371e-02, 7.949e-01, -5.925e-02, 3.252e-01, 1.492e-01) * s1[y+1][x+1];
	r += M4(1.022e-01, 1.528e-01, -7.005e-02, 6.528e-02, -1.218e-02, 1.297e-01, -3.766e-01, 2.439e-01, 4.516e-02, 4.836e-02, 7.014e-02, 2.578e-02, -2.192e-01, -3.568e-01, 9.446e-02, 5.145e-03) * s1[y+1][x+2];
	r += M4(-6.711e-02, 5.521e-02, -7.131e-03, 2.209e-01, 4.595e-02, 1.239e-02, -1.106e-03, -5.452e-02, -7.684e-02, -6.087e-03, -8.837e-03, 5.882e-03, 1.745e-02, -5.298e-02, -2.584e-02, -9.373e-02) * s1[y+2][x+0];
	r += M4(6.352e-02, 1.929e-01, 8.259e-03, 5.628e-02, 7.718e-02, -1.072e-01, 1.003e-02, 1.653e-02, 5.347e-02, -3.332e-02, 4.795e-02, 4.258e-02, -1.113e-01, -1.216e-01, -6.206e-02, 3.176e-01) * s1[y+2][x+1];
	r += M4(3.841e-02, -4.521e-02, 9.411e-03, 3.620e-04, -6.139e-02, -1.744e-01, -2.150e-02, 2.773e-02, 5.676e-02, -4.927e-03, -2.934e-02, -5.432e-02, -4.098e-02, 6.737e-03, 3.262e-02, -6.638e-02) * s1[y+2][x+2];
	r += V4(-2.647e-02, 2.836e-02, 2.570e-02, -1.312e-02);
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

//!DESC CuNNy-3x4C-RCAS-conv3
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
	r += M4(-4.618e-02, -3.204e-02, -9.392e-03, -4.003e-02, -2.329e-02, -3.668e-02, 9.917e-02, 5.586e-02, 9.204e-02, 1.031e-01, 7.582e-02, 2.262e-03, 9.740e-03, -7.685e-02, 7.152e-02, 7.181e-02) * s0[y+0][x+0];
	r += M4(-2.765e-02, -1.240e-02, 2.421e-02, -3.333e-02, -1.065e-02, -5.293e-02, -7.010e-02, -9.033e-02, 3.510e-02, 6.484e-02, -4.861e-02, 7.219e-02, 4.365e-03, -6.410e-02, -6.504e-02, 8.435e-02) * s0[y+0][x+1];
	r += M4(-5.515e-02, -3.752e-02, -1.988e-01, -5.134e-02, -3.284e-02, -4.548e-02, 5.441e-02, -5.361e-03, 9.253e-02, 6.193e-02, -7.987e-03, -3.505e-04, -7.606e-03, -2.994e-02, -1.155e-02, -6.623e-02) * s0[y+0][x+2];
	r += M4(5.801e-02, 1.222e-02, 4.421e-02, -2.001e-02, -1.120e-01, -2.529e-01, 1.402e-01, -1.228e-01, -1.694e-01, 1.421e-01, 1.275e-01, -1.002e-02, -5.189e-02, 1.364e-02, -6.104e-02, -2.495e-01) * s0[y+1][x+0];
	r += M4(1.661e-01, 2.300e-01, 1.549e-01, 4.965e-01, -7.300e-02, -1.461e-01, -8.914e-02, -1.613e-01, 2.026e-01, 2.419e-01, -6.460e-02, 2.437e-01, 3.034e-01, 2.496e-01, 6.266e-01, -3.319e-01) * s0[y+1][x+1];
	r += M4(1.979e-01, -1.210e-02, -2.433e-01, -1.159e-01, -5.121e-02, -8.205e-02, 6.015e-02, 3.070e-02, 9.442e-02, 1.353e-01, 6.148e-02, -8.468e-03, 1.499e-01, 7.617e-02, -4.324e-01, -3.338e-01) * s0[y+1][x+2];
	r += M4(-8.811e-02, 3.812e-02, -2.376e-02, -6.404e-02, 8.231e-03, -6.360e-02, 3.120e-02, 1.245e-01, 4.382e-02, 2.826e-02, 7.906e-02, 1.931e-02, -1.512e-03, 2.053e-01, 1.064e-01, 2.986e-02) * s0[y+2][x+0];
	r += M4(-9.113e-02, 1.315e-01, 1.350e-01, 5.439e-02, 8.383e-02, -2.874e-04, -1.891e-02, -6.191e-02, -6.994e-03, 7.326e-02, -1.428e-01, -7.942e-02, 1.255e-01, 2.153e-01, -1.665e-01, 3.486e-01) * s0[y+2][x+1];
	r += M4(-4.978e-02, 7.114e-02, -5.232e-03, 3.382e-02, -5.783e-03, -6.400e-02, -4.294e-02, -2.727e-02, 1.809e-02, 2.380e-02, 4.719e-02, 4.211e-02, 9.109e-02, 1.755e-01, 6.713e-02, 2.121e-01) * s0[y+2][x+2];
	r += M4(-5.178e-02, -5.390e-02, 7.642e-02, -5.402e-02, -2.130e-01, 4.060e-01, 1.123e-01, -2.444e-02, 8.574e-02, 8.804e-02, -9.083e-02, 1.644e-01, -4.610e-03, -2.458e-03, 6.267e-02, 1.788e-04) * s1[y+0][x+0];
	r += M4(2.545e-02, -5.124e-02, -1.555e-01, -2.695e-02, -1.060e-01, -1.023e-01, -4.105e-02, 1.382e-01, -1.304e-01, 1.946e-01, -4.017e-01, 3.586e-02, 6.937e-02, 7.119e-03, 9.444e-02, -8.245e-03) * s1[y+0][x+1];
	r += M4(1.349e-03, -3.036e-02, 1.249e-01, 6.242e-02, -1.236e-01, -8.860e-02, 6.566e-02, 3.689e-02, -3.206e-04, 7.784e-02, 7.583e-02, -7.781e-02, 5.853e-02, -3.066e-02, -1.265e-01, -1.554e-02) * s1[y+0][x+2];
	r += M4(-4.529e-02, 7.858e-02, 8.764e-02, 9.314e-02, 8.022e-02, -2.056e-01, 1.431e-01, 3.430e-01, 7.814e-02, -3.340e-02, -7.753e-02, -1.759e-02, -1.333e-01, 2.883e-03, 2.087e-02, -2.511e-02) * s1[y+1][x+0];
	r += M4(4.156e-01, 4.425e-01, -2.228e-01, 1.637e-02, 1.029e-01, -1.181e-01, -2.397e-01, -9.995e-02, -7.466e-01, 1.605e+00, -4.815e-01, 2.097e-01, 1.697e-01, 2.774e-02, 1.392e-01, 7.902e-02) * s1[y+1][x+1];
	r += M4(-9.676e-03, -5.056e-02, 8.959e-02, 5.442e-03, 2.964e-04, -3.999e-02, -2.059e-01, -9.546e-02, -2.432e-02, -1.657e-02, 1.794e-01, -4.522e-02, 2.565e-02, 1.003e-02, -2.159e-01, -5.395e-02) * s1[y+1][x+2];
	r += M4(-6.272e-02, 8.250e-03, 4.973e-03, 5.689e-02, -4.480e-02, -3.386e-02, 5.923e-02, -6.831e-03, 7.069e-02, -7.837e-02, -2.594e-02, -7.938e-02, -2.164e-02, -2.238e-02, 4.363e-02, 1.933e-03) * s1[y+2][x+0];
	r += M4(-4.772e-02, 5.814e-02, 6.338e-02, 4.951e-02, 5.323e-02, -6.583e-03, -8.463e-02, -5.832e-02, -1.538e-01, -9.449e-02, -5.493e-02, -2.473e-01, 1.805e-02, -1.642e-02, -3.393e-02, 3.085e-02) * s1[y+2][x+1];
	r += M4(1.685e-02, 3.876e-02, 3.575e-02, 2.773e-02, 3.465e-03, -2.057e-02, -8.545e-02, -1.811e-02, -3.679e-02, -5.173e-02, 2.774e-02, -1.172e-01, 1.722e-02, -1.987e-03, -2.171e-02, 1.135e-02) * s1[y+2][x+2];
	r += V4(-1.654e-02, -2.788e-02, 1.753e-02, 3.384e-02);
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

//!DESC CuNNy-3x4C-RCAS-out
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
	r += M4(-1.728e-01, -4.799e-02, 9.544e-02, 1.283e-01, -2.137e-02, 4.077e-02, -6.347e-02, 4.726e-02, -3.771e-03, -1.219e-02, 3.237e-03, -2.521e-02, -2.011e-02, -2.137e-02, 8.251e-03, -4.058e-02) * s0[y+0][x+0];
	r += M4(-3.057e-01, -3.621e-02, 1.237e-01, 1.193e-01, 5.098e-01, 1.694e-01, -2.164e-01, -2.142e-01, 8.107e-02, 4.800e-02, -7.982e-02, -5.261e-02, -7.640e-02, -4.993e-02, -4.756e-02, -2.602e-04) * s0[y+0][x+1];
	r += M4(6.722e-02, -1.626e-01, -1.291e-02, 9.194e-02, 5.553e-03, 1.843e-01, 3.253e-02, -1.593e-01, -1.794e-02, 2.592e-02, -2.497e-02, -2.887e-02, -1.591e-02, -3.502e-02, 5.593e-03, 1.922e-02) * s0[y+0][x+2];
	r += M4(4.248e-01, -1.116e-01, 1.971e-02, -3.558e-01, -7.177e-02, 4.043e-02, 3.946e-02, -1.465e-02, 3.761e-02, 1.112e-01, -1.649e-02, 1.003e-01, -8.399e-02, -1.162e-02, -1.013e-01, 1.447e-02) * s0[y+1][x+0];
	r += M4(-1.306e-01, 1.083e+00, -6.048e-01, 6.231e-01, 2.439e-01, -8.800e-02, 1.197e+00, 6.515e-01, -1.333e-01, -4.816e-02, 1.267e-01, 5.511e-02, 3.155e-01, 1.354e-01, 7.773e-02, -3.123e-02) * s0[y+1][x+1];
	r += M4(2.822e-01, -1.411e-01, 1.584e-01, -4.955e-01, -1.028e-01, 3.583e-02, -8.397e-02, 5.032e-01, 1.169e-01, -3.199e-02, 5.200e-02, 3.300e-02, -1.096e-01, 3.106e-02, -6.186e-02, -1.243e-02) * s0[y+1][x+2];
	r += M4(-1.683e-01, 1.446e-02, -1.729e-01, -4.746e-02, 3.591e-02, -2.720e-02, -5.355e-03, 3.635e-02, -3.277e-02, -2.151e-02, 2.148e-02, 3.109e-03, 1.336e-02, 7.182e-03, -1.615e-02, -1.613e-04) * s0[y+2][x+0];
	r += M4(-9.155e-02, -1.450e-01, -1.921e-01, -2.487e-02, 6.045e-02, 6.822e-02, -1.166e-01, -1.770e-01, -3.101e-03, -2.717e-02, -1.105e-01, -1.700e-02, -6.274e-02, -5.247e-02, 1.616e-01, 9.377e-02) * s0[y+2][x+1];
	r += M4(-8.699e-02, -3.939e-02, 3.752e-02, -4.239e-02, -6.461e-03, 2.863e-02, 7.621e-03, -2.094e-02, -4.845e-02, -1.336e-02, 4.372e-02, -1.977e-02, 2.557e-02, 1.708e-04, -3.599e-02, 5.582e-03) * s0[y+2][x+2];
	r += M4(2.276e-02, 1.218e-02, 3.625e-02, 8.255e-02, -1.217e-02, 3.192e-02, -4.596e-03, 3.434e-02, -1.061e-01, -8.110e-02, -7.011e-02, 6.136e-02, -5.868e-02, 7.396e-02, 1.383e-02, -3.870e-02) * s1[y+0][x+0];
	r += M4(-8.642e-03, 1.869e-03, 4.871e-02, -3.372e-02, 5.749e-02, -1.347e-02, -7.394e-02, -8.947e-02, -1.610e-02, 6.682e-02, -3.429e-02, -8.562e-02, -1.379e-01, -1.817e-01, 1.460e-01, 1.671e-01) * s1[y+0][x+1];
	r += M4(1.476e-02, -1.803e-02, 4.607e-06, 1.468e-02, -2.624e-03, 8.522e-03, 8.381e-03, -2.421e-02, 1.088e-02, -2.587e-02, 4.295e-03, 1.481e-02, -1.974e-02, -1.874e-02, 2.579e-03, 9.072e-02) * s1[y+0][x+2];
	r += M4(7.269e-02, -6.715e-02, 3.083e-02, -1.023e-01, -3.723e-02, 3.806e-02, -4.245e-02, 8.925e-03, -6.347e-01, 9.436e-01, -2.017e-01, 1.421e-01, 6.920e-02, -2.690e-03, -1.958e-01, 1.442e-01) * s1[y+1][x+0];
	r += M4(-7.054e-02, 1.942e-01, -1.068e-01, 1.353e-01, 1.374e-01, -1.211e-02, 3.236e-01, 1.431e-01, 2.959e-01, -3.726e-01, 1.313e-01, 7.153e-02, 8.748e-01, 7.832e-01, -2.649e-01, -4.159e-01) * s1[y+1][x+1];
	r += M4(5.135e-02, -2.789e-02, 7.183e-03, -7.396e-02, -1.739e-02, 8.120e-03, -3.122e-02, 5.197e-02, 3.965e-02, 2.273e-02, 3.991e-02, -7.372e-02, -1.241e-01, 1.626e-01, -5.546e-02, -9.026e-02) * s1[y+1][x+2];
	r += M4(-5.849e-02, 1.715e-02, -2.401e-02, -1.795e-02, 4.601e-04, -1.510e-03, -8.504e-03, 2.226e-02, -1.097e-01, -2.068e-03, -6.583e-01, 6.696e-01, 4.817e-03, 6.518e-02, 1.771e-01, 6.158e-02) * s1[y+2][x+0];
	r += M4(-4.262e-02, -9.399e-02, -5.216e-02, 3.022e-03, 3.074e-03, -4.081e-03, -5.350e-02, -8.588e-02, 3.497e-02, 1.167e-02, 2.095e-01, -3.813e-01, -1.890e-01, -1.232e-01, 2.758e-01, 3.858e-01) * s1[y+2][x+1];
	r += M4(-3.372e-02, -2.885e-02, 2.942e-02, -7.487e-03, -9.127e-03, 6.385e-03, -1.517e-03, -2.239e-03, -4.894e-02, -1.803e-02, -6.121e-02, 3.444e-02, 9.460e-02, 6.420e-02, 3.319e-02, 1.538e-01) * s1[y+2][x+2];
	r += V4(2.339e-03, 6.589e-04, 2.394e-03, -7.672e-04);
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

//!DESC CuNNy-3x4C-RCAS-shuffle
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

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
	r += V4(-6.313e-03, -4.981e-02, -2.325e-02, -1.378e-02) * s0[y+0][x+0];
	r += V4(7.353e-02, 4.162e-01, 3.686e-01, 4.041e-02) * s0[y+0][x+1];
	r += V4(1.458e-01, -6.102e-02, 1.879e-01, -3.128e-02) * s0[y+0][x+2];
	r += V4(3.430e-02, -5.332e-01, -4.894e-02, 6.902e-02) * s0[y+1][x+0];
	r += V4(5.370e-01, 1.907e-01, -7.358e-01, -9.402e-02) * s0[y+1][x+1];
	r += V4(-2.086e-01, 1.072e-01, 8.659e-02, 4.155e-02) * s0[y+1][x+2];
	r += V4(4.853e-02, -6.686e-02, 7.992e-02, -3.142e-01) * s0[y+2][x+0];
	r += V4(-1.841e-01, -1.748e-02, 1.479e-01, -4.639e-01) * s0[y+2][x+1];
	r += V4(-3.932e-01, 1.785e-02, -4.316e-02, 2.709e-02) * s0[y+2][x+2];
	r += V4(-7.741e-02, -4.734e-02, -1.995e-02, 8.514e-03);
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
	r += M4(7.222e-02, -2.021e-01, 1.127e-02, 2.765e-01, 5.029e-02, -3.773e-02, 5.687e-02, 1.442e-01, 7.205e-02, 7.188e-02, -1.602e-03, -5.167e-02, 1.168e+00, -6.302e-01, 8.454e-01, 2.638e+00) * s0[y+0][x+0];
	r += M4(2.096e-01, -1.213e-01, -1.562e-01, 1.446e-01, 7.376e-03, 7.012e-02, 7.160e-02, -5.136e-02, 2.145e-02, 4.362e-02, -1.086e-01, -9.753e-02, 1.995e-01, -1.233e+00, 2.131e+00, -7.950e-01) * s0[y+0][x+1];
	r += M4(1.936e-01, 8.918e-02, 9.102e-02, 5.167e-02, -3.390e-02, 2.417e-01, 9.155e-02, 3.588e-02, -1.932e-03, -7.534e-02, 7.817e-02, 3.037e-02, 2.420e-01, 2.931e+00, 7.453e-01, 1.746e+00) * s0[y+0][x+2];
	r += M4(1.364e-02, -9.453e-02, -2.836e-02, 1.609e-01, -1.319e-01, -8.224e-02, -2.265e-01, -1.719e-01, -2.019e-01, 3.807e-01, 2.623e-01, -4.872e-01, -1.345e+00, 2.564e+00, 2.057e-01, -7.558e-01) * s0[y+1][x+0];
	r += M4(1.743e-01, -9.462e-02, -9.401e-02, 5.040e-01, -6.138e-01, 3.460e-01, 2.681e-01, 4.128e-01, -7.796e-01, -2.562e-01, -1.688e-01, -2.310e-01, -1.286e+00, -2.304e-01, 2.493e-01, -1.434e+00) * s0[y+1][x+1];
	r += M4(-4.643e-01, -8.915e-02, -3.382e-02, -1.184e-02, -8.130e-02, -7.095e-02, 7.857e-03, 1.295e-01, 5.061e-01, 1.386e-02, 5.192e-03, -5.428e-02, -5.058e-01, 3.652e+00, 4.198e-01, 8.178e-01) * s0[y+1][x+2];
	r += M4(2.069e-01, -3.888e-01, -2.255e-02, 2.865e-01, -1.017e-01, 2.424e-01, 1.489e-01, 1.364e-01, -3.547e-01, -3.997e-02, -8.984e-02, 6.203e-01, -6.763e-02, 3.869e-01, 2.709e-01, 4.361e-02) * s0[y+2][x+0];
	r += M4(-2.817e-01, 3.803e-01, -4.640e-03, -1.523e-01, 2.640e-01, 2.033e-01, 8.885e-02, 1.452e-01, -2.719e-02, 4.374e-01, 1.165e-01, -1.224e-02, -4.150e-01, 3.994e-01, 3.439e-01, -7.421e-02) * s0[y+2][x+1];
	r += M4(7.515e-02, 5.768e-03, -4.130e-04, 4.088e-02, -2.680e-01, 1.380e-01, -6.665e-02, -3.105e-02, -1.115e-01, 1.628e-01, -3.075e-03, 6.807e-02, -1.512e+00, 2.327e+00, 2.152e-01, -6.146e-01) * s0[y+2][x+2];
	r += M4(-1.297e-01, -1.802e-01, 5.780e-02, 3.396e-02, -3.669e-02, 9.599e-03, 5.823e-02, 7.464e-02, 1.105e-01, 1.282e-01, -2.019e-01, -8.054e-02, 1.226e-01, -2.923e-02, 1.252e-01, 1.230e-01) * s1[y+0][x+0];
	r += M4(2.340e-01, 1.315e-01, -1.141e-01, 3.127e-01, 6.783e-02, 3.694e-02, 9.986e-02, -5.227e-02, 7.780e-02, 2.145e-02, -1.543e-01, -1.427e-01, -1.377e-01, -6.920e-04, 3.889e-01, -1.715e-01) * s1[y+0][x+1];
	r += M4(-1.580e-02, 6.761e-02, 2.965e-02, -8.097e-03, -4.243e-01, 4.534e-02, 1.365e-01, -6.114e-02, 9.112e-02, -2.241e-01, 2.354e-02, -1.420e-02, 1.323e-01, -7.495e-02, 5.749e-02, -4.676e-02) * s1[y+0][x+2];
	r += M4(-1.490e-01, 8.581e-02, -2.974e-01, 5.556e-01, -1.123e-01, -1.241e-01, -3.017e-01, 2.910e-01, 4.124e-02, 3.702e-01, 4.822e-01, -5.019e-01, 1.516e-01, 5.633e-02, 9.829e-02, -4.755e-02) * s1[y+1][x+0];
	r += M4(8.787e-01, 2.955e-01, -1.444e-01, 8.189e-02, 7.148e-02, -1.491e-01, 5.068e-01, -3.293e-01, -1.649e-01, -3.755e-01, -7.807e-02, -2.226e-01, 2.035e-01, -1.455e-01, 9.914e-02, 8.368e-04) * s1[y+1][x+1];
	r += M4(-2.646e-01, 2.311e-02, -1.823e-02, 6.263e-02, -9.289e-03, -3.738e-01, -7.089e-02, 1.372e-01, 5.605e-01, -1.114e-01, -4.303e-03, -4.152e-02, 2.025e-01, 2.533e-01, 2.027e-01, -1.006e-01) * s1[y+1][x+2];
	r += M4(-1.948e-01, 3.018e-01, -3.479e-02, -4.739e-02, 2.698e-02, -3.990e-02, 9.171e-03, 1.354e-01, -1.509e-01, -3.484e-01, -1.963e-01, 8.556e-01, -5.018e-02, -1.411e-01, -6.692e-02, 1.883e-01) * s1[y+2][x+0];
	r += M4(-4.567e-02, -1.177e-02, 2.486e-02, -2.080e-01, 3.445e-01, -2.400e-02, 1.235e-01, 4.502e-01, 1.274e-01, -1.822e-01, 4.177e-02, 8.081e-02, 1.011e-02, -5.337e-02, 4.475e-02, 9.573e-03) * s1[y+2][x+1];
	r += M4(-2.829e-02, -3.384e-02, 4.724e-03, 3.866e-02, -3.622e-01, -2.240e-02, -9.706e-02, 5.685e-02, -4.181e-01, 2.685e-01, 1.073e-03, 9.889e-02, -6.535e-03, 1.918e-01, -6.862e-03, 6.681e-02) * s1[y+2][x+2];
	r += V4(3.115e-01, 5.883e-02, -2.842e-02, 1.460e-01);
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
	r += M4(9.233e-02, 1.669e-01, -1.264e-01, -6.303e-02, -1.315e-01, 1.255e-01, -1.185e-01, 1.926e-01, -2.765e-01, 4.034e-02, 5.712e-01, 3.968e-01, -4.832e-02, -1.644e-02, -1.143e-02, -2.215e-02) * s0[y+0][x+0];
	r += M4(-5.589e-02, -9.275e-02, -6.891e-02, 7.643e-03, 2.017e-01, 1.107e-01, 6.860e-02, -2.386e-01, 8.079e-01, 5.058e-01, -2.461e-01, 3.684e-01, -1.161e-02, -3.311e-02, -1.081e-01, -1.021e-01) * s0[y+0][x+1];
	r += M4(3.411e-03, 1.200e-02, 1.333e-02, 4.010e-02, -1.525e-01, -7.033e-02, -2.149e-02, 6.699e-02, 4.994e-02, 6.847e-01, 3.758e-01, 8.522e-01, -1.257e-01, -3.326e-02, -1.394e-01, 1.742e-01) * s0[y+0][x+2];
	r += M4(-2.950e-01, -3.072e-03, -6.132e-01, 1.488e-01, -2.310e-01, 1.321e-01, -2.344e-01, -3.433e-02, 3.664e-01, 1.718e-01, -2.957e-01, -5.687e-01, -1.472e-01, -1.899e-02, -9.776e-02, -1.073e-01) * s0[y+1][x+0];
	r += M4(2.181e-01, 7.805e-02, 1.126e-01, -3.479e-01, -1.509e-01, -2.699e-01, 1.045e-01, -3.461e-01, 7.175e-01, 7.305e-01, -8.811e-01, 1.184e+00, -1.138e-01, 7.640e-01, 4.025e-01, 3.795e-02) * s0[y+1][x+1];
	r += M4(-8.219e-02, 8.101e-03, -8.033e-02, 2.188e-02, 3.263e-02, -5.987e-02, 4.565e-02, 5.541e-02, -1.611e+00, -1.136e+00, -2.115e+00, 3.173e+00, 5.269e-01, 2.993e-01, 1.411e-01, -5.691e-01) * s0[y+1][x+2];
	r += M4(-3.308e-01, -3.029e-01, -5.768e-02, -5.804e-01, -1.273e-01, -2.494e-01, -1.438e-02, -3.037e-01, -1.277e-01, 2.654e-02, -2.622e-01, 1.871e-01, 2.057e-02, -6.163e-02, 1.167e-03, -5.682e-02) * s0[y+2][x+0];
	r += M4(3.243e-04, 1.410e-01, -1.018e-01, 7.738e-02, 4.006e-02, 5.940e-02, 2.860e-02, 2.559e-02, 1.702e-01, 3.226e+00, 5.517e-02, 1.663e+00, 2.391e-03, -1.931e-02, 9.734e-02, 2.066e-01) * s0[y+2][x+1];
	r += M4(2.177e-02, 4.442e-02, -3.723e-02, -6.477e-02, 1.962e-02, -1.444e-03, 3.648e-02, -4.656e-02, 3.415e-02, -1.861e-01, -7.063e-02, 5.660e-01, 1.576e-01, 2.445e-02, -1.051e-01, 3.576e-02) * s0[y+2][x+2];
	r += M4(-9.455e-03, 1.904e-01, -1.988e-01, -1.964e-01, 6.446e-01, -4.685e-01, -1.455e-01, -1.359e-01, -1.836e-02, -1.101e-01, 1.843e-01, -2.785e-02, -5.435e-02, -4.129e-02, 3.535e-02, 1.098e-01) * s1[y+0][x+0];
	r += M4(-8.704e-02, -8.828e-02, -1.179e-01, -1.646e-02, -2.230e-01, -7.926e-02, 3.580e-01, 2.988e-01, -3.691e-02, 6.787e-02, -2.476e-01, 6.279e-02, -3.565e-02, 5.027e-02, 5.158e-02, 2.415e-01) * s1[y+0][x+1];
	r += M4(-1.453e-03, -8.928e-03, -2.158e-02, 3.647e-02, -2.985e-01, -1.711e-01, -1.508e-01, 6.417e-03, -1.759e-02, 1.036e-01, -7.205e-03, -1.887e-01, -1.300e-01, 9.891e-02, -1.600e-01, -5.111e-02) * s1[y+0][x+2];
	r += M4(-1.332e-01, 3.311e-01, -5.051e-01, 2.724e-01, -4.405e-03, 5.575e-02, -1.454e-01, 4.484e-01, 1.006e-01, -2.551e-02, -1.263e-01, -8.670e-02, -1.333e-01, -2.983e-02, -2.291e-02, 3.020e-02) * s1[y+1][x+0];
	r += M4(3.235e-01, 1.089e-01, 1.032e-01, -4.111e-01, -1.596e-01, -5.948e-02, 1.925e-01, 1.205e-01, 4.979e-01, -1.673e-01, -1.713e-01, -2.417e-01, -6.522e-02, -2.635e-02, 4.698e-01, 5.924e-02) * s1[y+1][x+1];
	r += M4(-2.801e-02, 2.239e-02, -4.892e-02, -2.865e-02, 2.476e-01, 8.531e-02, -2.090e-02, 2.264e-01, -1.578e-01, -2.593e-01, -1.075e-01, 2.472e-01, 2.517e-01, 2.405e-01, -7.652e-02, -4.649e-01) * s1[y+1][x+2];
	r += M4(-3.661e-01, -3.589e-01, -2.113e-02, -3.994e-01, -1.784e-01, 2.180e-01, 1.001e-02, -8.372e-02, 1.387e-01, 7.346e-02, -2.139e-02, 9.076e-02, -3.874e-02, 3.628e-02, -1.291e-02, -4.532e-02) * s1[y+2][x+0];
	r += M4(-3.569e-04, 9.937e-02, -6.369e-02, 1.237e-01, -1.656e-01, -2.300e-01, -6.644e-02, -6.523e-02, -1.143e-01, 3.199e-01, -9.444e-02, 2.170e-01, 4.126e-02, -7.010e-02, -2.214e-02, 6.299e-02) * s1[y+2][x+1];
	r += M4(-2.364e-03, -2.514e-02, -5.963e-03, -5.205e-02, 8.800e-02, 4.773e-02, 6.172e-02, 3.216e-02, -7.213e-02, -3.796e-02, -1.434e-01, 3.229e-01, 9.153e-02, 4.578e-02, 4.119e-02, 1.217e-01) * s1[y+2][x+2];
	r += V4(2.007e-01, -5.426e-02, -3.502e-01, 1.983e-01);
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
	r += M4(-4.548e-02, 3.110e-02, -1.023e-01, -1.203e-02, -1.132e-01, -1.605e-02, 1.606e-01, -3.537e-02, -5.360e-02, -8.171e-02, -4.825e-03, 2.732e-02, 1.621e-02, 7.049e-02, 2.691e-01, 6.535e-02) * s0[y+0][x+0];
	r += M4(1.233e-02, -1.327e-01, -3.905e-01, -4.123e-02, 1.411e-01, -9.556e-02, -1.421e-01, -3.217e-01, 2.058e-01, 1.106e-01, 7.244e-02, 7.525e-02, 2.330e-01, -1.939e-01, -9.139e-02, -1.003e-01) * s0[y+0][x+1];
	r += M4(-1.091e-01, -3.494e-02, 7.325e-02, 8.890e-02, 5.286e-02, -1.705e-01, -4.330e-02, 3.141e-02, 1.130e-02, -3.315e-02, -3.846e-02, -4.453e-02, 5.552e-02, -6.764e-02, -7.236e-02, 1.753e-02) * s0[y+0][x+2];
	r += M4(7.901e-02, -1.683e-01, -2.706e-01, 1.484e-02, 8.897e-02, 1.204e-02, 6.956e-02, -3.561e-02, 9.489e-02, 4.511e-02, 3.250e-01, 1.712e-01, 6.938e-02, 2.258e-02, -3.293e-01, -6.731e-01) * s0[y+1][x+0];
	r += M4(-2.144e-02, 1.564e-01, -2.715e-01, -7.156e-01, 1.390e-01, 6.524e-02, 9.896e-02, 3.901e-01, 2.313e-01, 6.519e-01, -6.133e-01, 2.646e-01, 2.423e-01, -6.834e-01, 1.162e-01, 1.973e-03) * s0[y+1][x+1];
	r += M4(1.756e-01, 5.881e-02, 1.254e-01, -1.403e-01, 9.611e-03, -1.769e-01, -9.229e-02, -3.367e-02, 9.268e-02, 9.701e-03, 1.024e-01, 3.837e-02, 1.390e-01, -3.486e-01, 1.058e-01, 7.234e-02) * s0[y+1][x+2];
	r += M4(2.135e-02, -2.484e-02, 1.164e-01, 2.336e-01, 6.567e-02, -5.163e-02, -6.846e-02, -9.041e-02, 1.362e-01, 4.201e-03, 1.633e-01, -1.876e-01, 1.277e-01, -3.342e-02, -4.008e-02, 2.845e-01) * s0[y+2][x+0];
	r += M4(-2.359e-01, 4.105e-02, -9.911e-02, -1.135e-02, -6.212e-02, 9.009e-02, 1.624e-01, 1.638e-01, 3.664e-01, -7.534e-02, -3.865e-02, -2.678e-01, 3.687e-01, -3.664e-01, 1.191e-02, 1.043e-01) * s0[y+2][x+1];
	r += M4(-1.725e-01, 7.454e-02, -6.504e-02, -1.651e-02, 1.105e-01, -6.594e-02, -9.733e-02, -7.180e-02, 2.524e-01, -1.746e-02, -1.949e-02, 2.637e-02, 1.415e-01, -2.224e-01, 7.089e-02, -7.942e-02) * s0[y+2][x+2];
	r += M4(-1.114e-01, 1.809e-02, -9.551e-02, -5.722e-02, -7.513e-02, -1.031e-01, -1.134e-01, -1.346e-01, -6.400e-02, -7.092e-02, 2.565e-02, 1.025e-01, 6.717e-02, 5.328e-02, 6.973e-02, -1.425e-01) * s1[y+0][x+0];
	r += M4(2.553e-02, -2.262e-01, -5.651e-01, 7.550e-02, 8.493e-02, -9.189e-02, -2.045e-01, 8.403e-02, 7.186e-02, 6.285e-02, 1.967e-02, 4.297e-02, 8.475e-02, 1.673e-02, -2.627e-01, -3.866e-02) * s1[y+0][x+1];
	r += M4(1.355e-02, -5.840e-02, -5.540e-03, 2.665e-02, 2.054e-01, -4.285e-03, 2.345e-01, 1.392e-01, 6.700e-02, 3.826e-02, -1.641e-02, -5.661e-02, -3.371e-02, 8.325e-02, 5.431e-02, 7.101e-02) * s1[y+0][x+2];
	r += M4(2.279e-01, 2.251e-02, 1.626e-01, 5.246e-02, -2.877e-02, 5.261e-02, -1.510e-01, -1.046e-02, 2.592e-01, 5.502e-02, 4.315e-01, 2.123e-01, -1.721e-01, 2.409e-01, -1.811e-01, -4.414e-01) * s1[y+1][x+0];
	r += M4(-4.551e-01, -2.987e-03, 2.618e-01, -3.084e-01, -7.592e-02, 9.070e-02, 1.216e-01, 1.061e+00, 3.423e-01, 4.756e-01, -5.488e-01, 1.128e-01, -1.326e-01, -4.974e-01, -2.950e-01, 1.013e-02) * s1[y+1][x+1];
	r += M4(-1.461e-01, -9.693e-02, -6.793e-02, -1.587e-01, -2.987e-01, -1.332e-01, -1.518e-02, 9.412e-02, 9.166e-02, -7.641e-02, 5.236e-02, 4.040e-02, -4.291e-02, -1.444e-01, 1.392e-01, 9.174e-02) * s1[y+1][x+2];
	r += M4(1.333e-01, -4.540e-03, 2.907e-01, 4.721e-02, 6.084e-03, -7.068e-02, -1.440e-01, 4.662e-03, 1.567e-01, -1.068e-01, 2.859e-02, -3.299e-01, -4.354e-02, 1.057e-01, 3.552e-02, 3.579e-02) * s1[y+2][x+0];
	r += M4(-2.816e-01, 2.710e-01, 1.162e-01, 1.756e-01, -1.604e-01, 2.023e-01, 2.529e-01, 1.724e-01, 2.749e-01, 1.299e-01, 1.061e-01, -1.578e-01, 1.083e-01, -4.965e-02, -8.731e-02, -4.397e-02) * s1[y+2][x+1];
	r += M4(-1.812e-01, 1.868e-01, 1.492e-02, 1.286e-01, 5.683e-02, -5.984e-03, -1.443e-01, -9.351e-02, 1.321e-01, 1.559e-02, -7.495e-02, 2.125e-02, 6.393e-02, -5.242e-02, 1.813e-03, -1.151e-01) * s1[y+2][x+2];
	r += V4(-3.388e-01, 3.271e-01, 2.167e-02, 7.830e-03);
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
	r += M4(6.485e-02, -1.104e-01, 1.609e-01, 2.460e-02, 1.444e-01, -6.809e-02, -1.497e-02, -1.086e-01, -5.112e-03, -3.323e-02, -2.796e-02, 8.868e-02, 1.923e-01, -2.095e-01, 5.967e-02, -1.878e-01) * s0[y+0][x+0];
	r += M4(1.361e-01, -3.974e-01, 2.794e-01, -6.082e-02, -1.440e-01, 1.101e-01, -1.128e-01, 8.881e-03, 1.040e-01, -3.163e-01, 4.326e-02, -2.017e-01, 9.663e-02, 4.959e-02, -4.338e-02, -3.501e-01) * s0[y+0][x+1];
	r += M4(-2.748e-02, 2.255e-01, 2.409e-01, 3.102e-02, -9.524e-02, 1.999e-01, 4.919e-02, 2.648e-02, 1.026e-02, 7.809e-02, 1.908e-02, 5.699e-02, 3.725e-02, -1.763e-01, -2.052e-05, -2.803e-01) * s0[y+0][x+2];
	r += M4(1.859e-01, -1.645e-01, 1.378e-01, -1.946e-01, -4.417e-01, 1.655e-01, 4.633e-03, 4.389e-01, 6.049e-02, 8.790e-02, 4.273e-02, -2.935e-01, -7.323e-02, -4.901e-02, -4.943e-02, 2.435e-01) * s0[y+1][x+0];
	r += M4(-3.218e-01, -5.460e-01, 3.819e-01, -1.190e-01, -6.709e-02, 2.548e-02, 4.244e-01, -4.249e-01, -3.084e-01, 7.012e-01, -4.610e-01, 2.557e-01, -3.098e-01, -1.475e-01, 1.050e-01, 4.626e-01) * s0[y+1][x+1];
	r += M4(-4.147e-02, 2.640e-01, 3.035e-01, -1.101e-01, 1.762e-01, -7.720e-02, 3.082e-02, 7.938e-03, -6.137e-01, 1.779e-01, -1.209e-01, 9.427e-02, 9.592e-02, -6.407e-02, 3.384e-01, 1.050e-02) * s0[y+1][x+2];
	r += M4(-3.239e-01, 1.890e-01, -2.014e-02, 3.527e-01, -2.535e-01, 2.846e-01, -5.665e-02, 2.300e-01, 2.326e-01, -9.953e-02, -5.798e-02, -5.794e-02, -2.125e-01, 1.947e-01, -4.518e-02, 1.457e-01) * s0[y+2][x+0];
	r += M4(1.948e-01, -6.320e-02, 1.293e-01, -1.145e-01, 4.669e-01, -8.015e-02, 9.155e-02, 2.215e-01, -1.389e-01, 1.993e-02, 2.874e-03, 5.494e-02, -4.581e-02, -1.189e-02, 1.086e-02, 7.442e-02) * s0[y+2][x+1];
	r += M4(1.195e-01, 2.055e-01, 1.901e-01, 1.305e-01, 1.174e-01, -7.963e-02, -1.191e-02, 1.512e-03, 2.564e-02, 1.731e-02, -5.427e-02, -6.932e-02, 2.384e-01, -1.279e-01, 4.553e-02, 3.798e-02) * s0[y+2][x+2];
	r += M4(-5.922e-02, 1.150e-01, 7.633e-02, 1.984e-02, -8.202e-02, -2.050e-01, -4.251e-02, 9.621e-02, -5.505e-02, 5.668e-02, -9.394e-03, 1.387e-01, 4.009e-02, 1.559e-02, 6.229e-02, -6.100e-02) * s1[y+0][x+0];
	r += M4(1.815e-01, -2.976e-01, 3.365e-02, -1.832e-01, -2.636e-01, -2.057e-01, -8.640e-02, -1.759e-02, -5.694e-02, -2.013e-01, 9.917e-02, -4.762e-02, -1.473e-02, 3.560e-01, 2.992e-02, 3.575e-03) * s1[y+0][x+1];
	r += M4(6.714e-03, 1.238e-01, -7.938e-02, 2.073e-02, -4.635e-02, 2.221e-01, 5.200e-02, 6.629e-02, -4.595e-02, -1.786e-01, 1.157e-01, 1.251e-02, 9.957e-02, 1.110e-01, -1.341e-02, -1.286e-02) * s1[y+0][x+2];
	r += M4(1.296e-01, -2.418e-01, 7.832e-02, -7.166e-02, -1.037e+00, -3.366e-01, 1.712e-01, 9.961e-01, -1.375e-01, 2.729e-01, -4.650e-02, -1.341e-01, -5.458e-02, -5.962e-02, -2.130e-02, 2.588e-01) * s1[y+1][x+0];
	r += M4(-2.746e-02, -5.121e-01, 1.681e-02, -3.332e-01, -6.063e-01, 4.824e-02, 4.521e-01, -1.164e-01, 1.687e-01, 7.477e-01, -3.002e-01, 1.863e-01, -5.411e-01, -1.875e-01, 1.857e-01, 9.746e-01) * s1[y+1][x+1];
	r += M4(-2.613e-01, 4.658e-01, -4.788e-02, 7.747e-03, 1.987e-01, -5.801e-02, 1.691e-01, 6.066e-02, -3.607e-01, -2.064e-01, 1.512e-02, 4.435e-02, 4.566e-01, -2.629e-01, 3.350e-01, 1.253e-01) * s1[y+1][x+2];
	r += M4(-2.002e-01, 1.993e-01, 1.332e-02, 2.666e-01, -5.903e-01, 2.397e-01, -5.337e-02, 2.832e-01, 7.228e-02, -5.345e-02, -3.631e-02, 8.334e-03, -7.077e-02, 7.696e-02, -4.392e-03, 6.560e-02) * s1[y+2][x+0];
	r += M4(8.849e-02, -5.495e-02, 1.777e-01, 1.028e-01, 5.166e-01, -2.231e-01, 1.987e-01, 3.270e-02, 2.403e-01, -6.860e-02, 1.018e-02, 1.667e-02, -2.310e-01, -3.951e-02, 2.966e-02, 2.820e-02) * s1[y+2][x+1];
	r += M4(1.768e-01, -8.983e-03, 1.065e-01, 2.045e-02, 5.763e-02, 1.640e-02, -8.270e-03, -3.874e-02, 2.513e-01, -2.164e-01, -2.121e-02, -5.275e-02, 1.464e-01, -3.070e-02, 6.784e-02, 8.368e-02) * s1[y+2][x+2];
	r += V4(3.806e-02, -2.269e-01, -3.557e-01, -1.736e-01);
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
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
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
	r += M4(4.995e-02, -2.808e-01, -3.107e-01, 1.391e-01, -6.297e-03, -2.288e-02, 2.066e-01, -4.696e-02, 1.252e-03, -1.037e+00, 2.027e-01, -2.633e-01, 1.339e-01, 3.714e-02, -3.406e-02, -4.141e-02) * s0[y+0][x+0];
	r += M4(-1.304e-02, -5.344e-02, -2.292e-01, 1.316e-01, -1.523e-01, -1.933e-02, 1.296e-01, -7.002e-02, -3.192e-01, -7.581e-01, -4.135e-01, 4.297e-01, 1.049e-01, -8.617e-02, -1.549e-01, 1.497e-02) * s0[y+0][x+1];
	r += M4(-1.721e-01, -1.057e-01, 4.599e-02, 7.643e-02, 4.251e-02, -2.910e-03, 5.109e-02, 4.760e-03, 4.252e-01, 3.255e-01, 5.063e-01, 2.158e-01, -2.419e-01, 1.116e-01, 2.965e-01, -5.691e-03) * s0[y+0][x+2];
	r += M4(-2.340e-01, 3.318e-02, -2.251e-01, 3.740e-01, 6.015e-02, -5.019e-01, 1.199e-01, -1.090e-01, -5.220e-01, -1.810e+00, 1.759e+00, 7.121e-02, -9.363e-02, 4.479e-01, -3.097e-01, 4.208e-02) * s0[y+1][x+0];
	r += M4(3.878e-01, 5.312e-02, -4.385e-01, 8.433e-01, 2.214e-01, -6.609e-02, -5.272e-01, 4.984e-01, -1.248e+00, -1.066e-01, -6.342e-01, -1.380e+00, 1.199e-01, -3.000e-01, 4.360e-01, 2.636e-01) * s0[y+1][x+1];
	r += M4(2.550e-02, -8.376e-02, -1.333e-01, 1.928e-02, -2.041e-02, -1.093e-01, -1.806e-01, 9.912e-03, -6.243e-01, -1.195e-01, 5.030e-01, -2.681e-01, 2.260e-01, 1.469e-01, 9.913e-02, -4.796e-01) * s0[y+1][x+2];
	r += M4(-5.537e-02, -1.808e-02, 7.179e-03, -6.252e-03, 5.570e-02, 1.063e-02, -1.160e-01, -6.875e-02, 5.987e-01, 3.807e-01, 1.896e-01, -3.323e-02, -2.548e-02, 2.503e-01, 6.493e-02, -9.659e-02) * s0[y+2][x+0];
	r += M4(1.296e-01, -2.960e-04, -8.262e-02, -1.176e-01, 1.285e-01, 1.661e-01, -8.534e-02, -2.707e-01, -1.615e-01, -9.888e-02, 3.985e-01, -4.880e-02, 1.945e-01, -1.451e-01, 1.450e-01, 1.527e-01) * s0[y+2][x+1];
	r += M4(-4.120e-02, 2.248e-02, 1.417e-02, 7.551e-02, 5.379e-02, 5.847e-02, 8.433e-02, 2.203e-03, 2.702e-02, 4.632e-02, 3.461e-01, -8.246e-03, -2.112e-02, 1.044e-01, 1.097e-01, 6.698e-02) * s0[y+2][x+2];
	r += M4(-1.839e-02, -1.818e-01, -2.308e-01, -2.958e-03, -5.409e-02, 1.414e-01, 1.575e-01, -2.502e-03, 2.157e-01, 1.558e-01, 3.592e-01, -3.741e-02, -5.871e-02, -1.618e-01, -1.957e-01, 7.006e-02) * s1[y+0][x+0];
	r += M4(3.751e-02, 2.492e-01, 1.516e-01, -2.824e-01, -2.920e-01, 2.522e-01, 4.445e-01, -8.785e-02, 1.533e-01, -5.741e-02, -2.474e-01, 1.091e-01, -1.500e-01, -1.431e-01, -3.936e-01, 1.502e-02) * s1[y+0][x+1];
	r += M4(-5.380e-02, -3.397e-02, 6.413e-02, -1.042e-01, -4.144e-03, 7.817e-03, -7.680e-03, 9.444e-02, 3.648e-02, -1.836e-02, -2.611e-02, 4.465e-02, -2.388e-01, -8.806e-03, 1.096e-01, -1.135e-01) * s1[y+0][x+2];
	r += M4(-1.986e-01, 1.319e-01, -1.847e-01, 1.930e-01, -1.530e-02, -1.958e-01, 4.131e-01, -4.097e-02, -6.909e-02, -1.466e-01, 8.133e-02, 9.236e-02, -1.243e-01, -4.959e-02, -3.703e-01, 2.729e-01) * s1[y+1][x+0];
	r += M4(5.744e-01, 6.080e-02, -3.604e-01, -3.216e-03, 4.344e-01, 1.043e-02, 9.314e-02, 1.644e-01, -3.119e-01, -4.366e-02, -4.267e-01, -1.247e-01, 4.424e-01, -4.175e-01, 6.976e-03, 5.879e-01) * s1[y+1][x+1];
	r += M4(-1.153e-01, 2.561e-02, -7.523e-02, -2.900e-01, 2.627e-01, 4.520e-02, -2.417e-01, -1.515e-02, -8.098e-02, -7.136e-02, 9.410e-02, -4.160e-02, 1.121e-01, 9.981e-03, -2.314e-01, -3.018e-01) * s1[y+1][x+2];
	r += M4(5.164e-02, 3.718e-02, -2.038e-02, -3.726e-02, 5.571e-02, -2.393e-02, -3.246e-03, 1.101e-02, 1.501e-01, 1.360e-01, -5.429e-02, -1.013e-01, -8.278e-02, 4.720e-02, -5.657e-02, 5.554e-02) * s1[y+2][x+0];
	r += M4(3.280e-01, 9.149e-02, -8.307e-02, -2.004e-01, -1.218e-01, -6.367e-02, 8.842e-02, -1.889e-01, -1.255e-01, -4.919e-02, 2.939e-02, -2.548e-02, 3.587e-01, 2.414e-02, -2.376e-01, 2.380e-01) * s1[y+2][x+1];
	r += M4(-7.448e-02, 3.094e-02, 5.999e-02, 3.154e-02, -1.312e-02, 4.267e-02, -2.042e-02, 1.774e-01, 2.415e-02, 3.418e-02, 1.246e-01, 8.333e-02, -1.573e-02, 6.885e-02, -6.566e-02, -1.023e-01) * s1[y+2][x+2];
	r += V4(2.713e-02, 1.347e-02, -1.015e-01, -2.012e-02);
	return vec4(r);
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
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv5_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-5.500e-02, 1.132e-01, -2.344e-02, 5.759e-03, 4.909e-02, -2.681e-02, 7.828e-02, -6.649e-03, -4.010e-02, 4.897e-02, 1.378e-02, 1.472e-02, 1.501e-01, -1.567e-01, 1.121e-01, 3.393e-02) * s0[y+0][x+0];
	r += M4(2.763e-01, 3.637e-02, 6.380e-02, -7.348e-02, 4.562e-02, -9.286e-02, 3.936e-03, -1.043e-02, -2.482e-01, 1.239e-01, -1.876e-01, 1.077e-01, -1.283e-01, -4.696e-02, -2.075e-01, 6.351e-02) * s0[y+0][x+1];
	r += M4(-7.343e-02, 7.865e-02, 4.596e-02, -8.202e-02, 1.288e-01, -1.256e-01, 2.153e-01, 3.429e-02, 5.993e-02, 7.946e-02, -9.788e-02, 3.573e-02, -3.135e-03, 1.113e-02, 7.228e-03, 3.594e-02) * s0[y+0][x+2];
	r += M4(4.010e-03, 2.168e-02, -1.364e-01, 1.833e-01, 1.311e-01, -1.517e-01, 6.955e-02, -9.827e-03, 2.198e-01, -1.385e-01, 1.080e-01, -2.341e-02, 1.669e-01, -1.121e-02, 9.805e-02, 1.149e-02) * s0[y+1][x+0];
	r += M4(2.049e-01, 3.451e-01, -3.110e-01, 3.366e-02, -1.149e-01, 5.757e-02, -2.144e-01, 8.781e-02, -4.819e-01, -1.091e-01, -3.331e-01, 2.590e-01, -1.322e-01, 5.173e-01, -5.042e-01, -3.513e-01) * s0[y+1][x+1];
	r += M4(-3.002e-01, 1.166e-01, 1.759e-01, -5.735e-03, 2.413e-01, -2.841e-02, -3.389e-01, -1.077e-01, -1.596e-01, -1.505e-01, 3.206e-02, 6.820e-01, 7.982e-02, 4.895e-02, -6.823e-02, -1.749e-01) * s0[y+1][x+2];
	r += M4(-1.412e-01, 2.204e-01, -8.593e-02, 2.426e-02, -8.419e-03, -5.047e-02, 6.568e-02, -1.052e-02, 7.740e-02, 2.174e-02, 6.399e-02, -1.057e-01, 8.158e-02, -9.417e-03, -4.348e-02, -9.914e-03) * s0[y+2][x+0];
	r += M4(1.758e-01, 2.157e-01, 7.846e-02, 1.908e-01, 1.734e-01, -5.601e-02, -1.811e-01, 6.346e-02, 2.105e-01, -2.635e-01, -1.139e-02, -4.339e-02, -3.540e-03, 2.017e-01, -2.283e-02, 9.677e-02) * s0[y+2][x+1];
	r += M4(-1.358e-01, 2.450e-02, 1.597e-01, -1.318e-01, 7.399e-02, -9.543e-02, -4.473e-02, 3.763e-02, -1.958e-01, 8.932e-02, -1.222e-02, -2.278e-01, 1.039e-01, -8.812e-02, -9.150e-02, 9.312e-02) * s0[y+2][x+2];
	r += M4(-1.871e-01, 1.477e-01, 5.189e-02, -7.850e-02, -1.235e-01, 9.919e-02, -6.069e-02, 6.210e-02, 4.096e-02, -1.404e-02, 3.966e-02, 1.065e-02, 1.789e-01, -1.656e-01, 5.518e-02, 9.499e-02) * s1[y+0][x+0];
	r += M4(-1.746e-01, 2.852e-02, -7.909e-03, -8.603e-02, 1.141e-01, -2.196e-01, 4.595e-02, -2.026e-02, -2.334e-01, 1.530e-01, -1.658e-01, 5.310e-02, 3.730e-02, -2.205e-01, -1.224e-01, 1.416e-01) * s1[y+0][x+1];
	r += M4(-2.078e-01, 1.005e-01, 5.373e-02, -5.409e-02, -1.380e-01, -7.904e-02, 1.526e-01, 1.102e-02, -5.105e-02, 1.586e-01, -5.909e-02, -1.265e-01, 1.949e-01, -1.335e-01, 9.523e-02, -4.795e-03) * s1[y+0][x+2];
	r += M4(1.189e-01, -8.659e-02, 8.305e-02, -4.714e-02, -3.915e-02, -3.443e-02, 6.394e-02, -9.831e-02, 6.861e-02, -1.978e-01, 2.680e-02, 2.351e-02, -4.085e-02, -7.651e-03, 3.743e-02, 1.111e-01) * s1[y+1][x+0];
	r += M4(-1.691e-01, 3.353e-01, -3.289e-01, -1.382e-01, 8.630e-02, 3.809e-01, -2.046e-01, 7.112e-02, -3.758e-01, 8.838e-02, -1.974e-01, 1.902e-01, 2.569e-01, -5.296e-02, -2.912e-01, 1.051e-01) * s1[y+1][x+1];
	r += M4(-2.259e-01, -4.161e-02, -4.259e-02, 3.001e-01, -2.379e-01, -1.116e-02, -5.178e-01, -3.657e-01, -4.769e-01, 6.209e-02, 2.939e-01, 1.704e-01, -5.134e-02, -2.134e-01, -3.262e-02, 6.495e-02) * s1[y+1][x+2];
	r += M4(-3.609e-02, 7.848e-02, 7.075e-04, -4.684e-03, -1.256e-01, 5.687e-02, 1.796e-04, 1.873e-03, -6.465e-02, -4.316e-02, 1.686e-02, -4.143e-02, 6.350e-02, -7.985e-02, -4.995e-02, 4.184e-02) * s1[y+2][x+0];
	r += M4(1.045e-02, -5.164e-02, -2.284e-03, 9.854e-02, 2.072e-01, -4.564e-01, -1.802e-01, -8.342e-02, 1.257e-01, -3.037e-01, 4.289e-03, 4.182e-02, 5.388e-02, 3.723e-02, -2.848e-02, 1.153e-01) * s1[y+2][x+1];
	r += M4(-1.809e-01, 4.010e-02, 6.052e-02, 8.425e-02, -2.431e-01, -2.549e-01, -6.259e-02, -1.260e-01, -3.114e-01, 1.269e-01, -3.081e-02, -9.898e-02, 1.258e-01, -2.267e-01, -1.838e-02, 1.246e-01) * s1[y+2][x+2];
	r += V4(1.629e-02, -3.455e-02, -1.959e-02, 2.069e-02);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv6_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-3.885e-02, -1.044e-02, 6.937e-02, 3.599e-02, -4.992e-02, 2.651e-02, 3.455e-02, 3.478e-02, -5.839e-02, 8.328e-02, -3.968e-02, 8.731e-02, 4.151e-02, 1.394e-02, -3.351e-02, -8.290e-03) * s0[y+0][x+0];
	r += M4(1.381e-01, -5.383e-02, -2.018e-02, -6.083e-02, 1.107e-01, -1.888e-01, 3.857e-01, -1.172e-01, -2.085e-01, 8.225e-02, 2.822e-01, 1.390e-01, 2.627e-01, -3.122e-02, -1.191e-01, -1.624e-01) * s0[y+0][x+1];
	r += M4(-1.007e-02, -1.463e-02, -1.173e-02, 4.534e-02, 1.393e-02, 1.028e-02, 2.429e-02, 1.712e-01, -1.399e-01, 7.349e-02, 4.753e-03, 1.657e-01, -6.466e-02, -2.354e-02, -9.256e-03, 8.902e-02) * s0[y+0][x+2];
	r += M4(1.770e-02, 1.809e-02, -1.822e-02, -3.395e-02, -6.323e-02, -7.157e-03, 5.740e-02, 1.337e-01, -4.836e-02, -1.187e-01, 1.636e-01, 1.064e-01, 1.840e-01, -6.783e-02, 1.284e-01, -1.548e-01) * s0[y+1][x+0];
	r += M4(-3.181e-02, 8.336e-02, 1.353e-01, -3.640e-02, 3.284e-01, -3.272e-01, 4.454e-02, -4.270e-01, 2.656e-01, -4.504e-01, -1.188e-01, -1.517e-01, 1.248e-02, -3.783e-01, -5.854e-02, 2.195e-01) * s0[y+1][x+1];
	r += M4(2.612e-01, -3.010e-02, 9.789e-02, -3.215e-01, -9.586e-02, -1.169e-01, 4.040e-02, -1.948e-01, -4.573e-01, 1.363e-01, -5.343e-02, 5.015e-01, 8.801e-02, -4.215e-02, 6.830e-03, -1.756e-01) * s0[y+1][x+2];
	r += M4(2.324e-02, -2.451e-02, -4.988e-03, -3.303e-02, -1.213e-01, 4.268e-02, 1.343e-02, 9.547e-02, 5.914e-02, -6.665e-02, -4.210e-02, -6.046e-02, 1.026e-02, -5.578e-03, -1.261e-02, 9.374e-03) * s0[y+2][x+0];
	r += M4(1.228e-01, -1.987e-02, -9.848e-02, -8.265e-02, 3.657e-02, -8.373e-02, 6.395e-02, -2.182e-01, 4.586e-01, 1.589e-02, -9.236e-02, -6.563e-02, 4.139e-02, -8.212e-03, 1.010e-02, -3.191e-02) * s0[y+2][x+1];
	r += M4(7.080e-02, 4.241e-02, -7.543e-02, 1.352e-02, 2.308e-02, 1.790e-02, 1.382e-02, 4.977e-02, -2.034e-01, 8.369e-02, 5.985e-03, 3.586e-01, 3.500e-02, 2.421e-02, -2.333e-02, 2.984e-02) * s0[y+2][x+2];
	r += M4(1.707e-01, -3.365e-02, -1.320e-01, -3.672e-02, -1.508e-03, 1.246e-02, 1.405e-01, -1.994e-03, 9.323e-02, 2.628e-02, -1.316e-01, -1.115e-02, -1.060e-01, -6.090e-02, 8.052e-02, 2.619e-03) * s1[y+0][x+0];
	r += M4(2.630e-01, -3.953e-02, -4.444e-01, -1.430e-01, 1.724e-01, -1.103e-01, 8.318e-02, -5.259e-02, 1.584e-02, -1.642e-02, 1.189e-01, 2.732e-02, -1.367e-01, -5.119e-02, -1.558e-01, -3.814e-02) * s1[y+0][x+1];
	r += M4(-6.958e-02, 1.641e-02, -1.610e-01, 2.344e-02, 7.002e-02, -9.407e-02, -3.413e-02, 1.284e-01, 2.229e-02, -9.131e-03, -2.173e-02, 2.027e-02, 1.861e-02, -1.139e-01, -7.082e-02, -4.563e-02) * s1[y+0][x+2];
	r += M4(1.843e-01, -1.633e-01, 1.856e-01, -3.623e-01, -7.742e-02, -4.043e-02, 1.208e-02, 4.107e-02, 1.065e-01, -9.692e-02, 1.968e-01, -2.904e-02, 1.656e-01, -6.175e-02, 3.154e-02, -1.754e-01) * s1[y+1][x+0];
	r += M4(-1.194e-01, 3.950e-01, -1.071e+00, 2.627e-01, -1.490e-01, -1.702e-01, 2.627e-01, -8.798e-02, -2.169e-02, -4.237e-01, -6.737e-02, 1.154e-01, -2.994e-02, -1.646e-01, -6.047e-02, 5.578e-01) * s1[y+1][x+1];
	r += M4(2.872e-01, -9.938e-02, -3.790e-02, -2.163e-01, -6.582e-02, -1.957e-01, 4.382e-02, -3.484e-01, -1.112e-01, 7.905e-03, -6.474e-02, 1.088e-01, -1.667e-02, -1.478e-01, 3.765e-02, -1.224e-01) * s1[y+1][x+2];
	r += M4(-4.952e-02, 7.498e-02, -2.382e-01, 4.029e-02, -1.509e-01, 2.044e-03, 1.733e-02, 1.173e-01, 1.272e-01, -1.216e-02, -4.702e-02, -1.290e-01, 7.643e-02, -2.099e-02, -5.703e-02, -6.893e-03) * s1[y+2][x+0];
	r += M4(3.769e-01, -2.910e-01, -2.068e-01, -2.584e-01, 3.306e-02, 2.620e-02, -6.472e-02, -7.827e-02, 3.308e-01, -1.764e-02, -4.768e-02, -4.393e-02, -5.736e-02, 5.871e-02, 4.015e-03, 4.483e-02) * s1[y+2][x+1];
	r += M4(2.979e-01, 4.166e-02, -2.416e-02, -1.347e-01, -5.702e-04, 1.002e-01, 1.390e-02, 3.397e-02, 1.050e-01, -1.543e-02, 6.237e-03, 3.160e-02, -7.534e-03, 1.570e-02, -4.598e-03, 5.084e-02) * s1[y+2][x+2];
	r += V4(1.302e-02, -1.778e-02, 2.783e-02, -1.039e-03);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
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
	#define V4 f16vec4
	#define M4 f16mat4
	#define F float16_t
#else
	#define V4 vec4
	#define M4 mat4
	#define F float
#endif
#define l0(x, y) V4(texelFetch(conv7_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(1.192e-02, -6.942e-02, -1.754e-02, -7.396e-02, 7.884e-03, -1.767e-02, 2.378e-02, 3.730e-02, 1.888e-03, -8.704e-03, -1.398e-02, 6.272e-03, 1.994e-02, -9.594e-02, -8.887e-02, -6.043e-02) * s0[y+0][x+0];
	r += M4(1.350e-01, 1.057e-01, -1.197e-01, 1.349e-01, 9.730e-04, -9.379e-02, 1.616e-01, 1.957e-01, 4.319e-02, 4.210e-02, -1.967e-02, 5.090e-02, 1.916e-01, 1.495e-01, -1.870e-01, 2.095e-01) * s0[y+0][x+1];
	r += M4(2.677e-02, -3.801e-02, 5.937e-03, -1.859e-02, -9.347e-03, 1.028e-01, -6.116e-02, 1.275e-01, -1.501e-02, -2.419e-02, 7.531e-03, -3.405e-02, 1.067e-01, 1.363e-02, -6.965e-02, -4.916e-02) * s0[y+0][x+2];
	r += M4(4.530e-02, -5.825e-02, 9.126e-02, -9.448e-02, -5.701e-02, -1.054e-01, -5.276e-02, -1.069e-01, 6.882e-03, -1.208e-01, 4.501e-02, -1.073e-01, 1.641e-01, 1.657e-01, -1.216e-02, 2.141e-02) * s0[y+1][x+0];
	r += M4(1.638e-01, -1.499e-01, 1.791e-01, -2.510e-01, -2.231e-01, 1.966e-02, -2.627e-01, -5.651e-01, 4.505e-02, -4.043e-02, 6.016e-02, -2.062e-01, 2.863e-01, -5.645e-01, 1.083e-01, -1.852e-01) * s0[y+1][x+1];
	r += M4(-7.884e-02, -5.439e-03, 5.001e-02, -6.541e-02, -2.624e-02, 1.150e-01, -4.562e-02, -4.406e-02, 6.349e-02, -2.646e-02, -1.854e-02, -7.864e-02, -2.440e-03, 3.898e-02, 8.919e-02, -4.635e-02) * s0[y+1][x+2];
	r += M4(-4.690e-02, 5.168e-02, -5.188e-03, 4.134e-02, -5.404e-03, -2.313e-02, 5.283e-02, 2.228e-02, -1.999e-02, -1.413e-02, 8.766e-02, 2.888e-02, -2.578e-02, 1.900e-02, -2.169e-02, 6.692e-03) * s0[y+2][x+0];
	r += M4(2.876e-02, -2.761e-02, 8.789e-04, 2.969e-02, -3.193e-01, 5.162e-02, 1.242e-01, 7.292e-02, 6.816e-02, 6.789e-02, 2.318e-01, 8.033e-02, 9.773e-03, -3.741e-02, 2.178e-02, 5.477e-02) * s0[y+2][x+1];
	r += M4(-8.356e-03, -1.208e-02, -7.170e-03, 2.873e-03, 9.641e-02, -8.508e-02, -1.812e-02, -4.591e-02, -8.698e-02, -8.578e-02, 1.344e-01, -4.577e-02, 2.919e-02, -5.459e-02, -1.958e-02, -3.784e-02) * s0[y+2][x+2];
	r += M4(5.932e-02, -6.993e-02, -1.386e-01, -5.163e-02, -1.365e-02, -4.222e-02, 6.323e-02, -7.841e-03, -3.839e-03, -3.781e-02, -2.213e-02, -5.456e-02, 2.416e-02, -1.076e-01, -3.406e-02, -1.003e-01) * s1[y+0][x+0];
	r += M4(3.507e-01, 2.642e-01, -3.568e-01, 2.822e-01, -6.545e-03, 2.524e-02, 6.880e-02, 2.229e-01, -2.667e-02, 4.378e-02, 9.953e-02, 1.638e-01, 1.702e-01, 1.285e-01, -1.455e-01, 1.081e-01) * s1[y+0][x+1];
	r += M4(2.854e-02, -3.158e-02, 2.144e-02, -8.959e-02, -3.619e-02, 3.212e-02, -1.860e-02, 7.386e-02, -1.887e-02, -1.144e-01, 1.255e-01, -2.113e-01, 6.324e-02, -3.602e-02, 1.312e-02, -3.018e-02) * s1[y+0][x+2];
	r += M4(2.020e-02, -9.793e-02, 2.982e-03, -5.241e-02, -9.728e-02, -2.300e-01, 4.447e-02, -1.607e-01, -1.728e-02, -1.061e-01, 1.805e-02, -1.618e-01, 1.256e-01, 1.412e-01, 1.533e-02, 1.768e-02) * s1[y+1][x+0];
	r += M4(7.890e-02, -8.507e-02, 4.451e-01, -2.331e-01, -2.173e-01, 1.488e-01, 2.155e-02, -4.019e-01, -4.685e-02, 8.105e-02, -4.465e-01, -2.661e-01, 4.434e-01, -1.416e-01, 2.059e-02, -1.982e-01) * s1[y+1][x+1];
	r += M4(-1.442e-02, 6.254e-02, 4.025e-02, -7.309e-02, -2.921e-02, 7.531e-03, 2.992e-02, -1.519e-01, 3.633e-01, -1.114e-01, -8.535e-02, -1.450e-01, -6.506e-02, 2.526e-02, 3.949e-02, -8.179e-02) * s1[y+1][x+2];
	r += M4(4.562e-02, 1.244e-01, -1.936e-02, 3.646e-03, -4.480e-02, -3.242e-02, 9.337e-02, 4.693e-02, -2.570e-02, -1.026e-01, 1.752e-01, -5.325e-02, 1.647e-02, 5.823e-02, -6.375e-03, 2.437e-02) * s1[y+2][x+0];
	r += M4(2.384e-02, 6.344e-04, -2.523e-02, 6.254e-02, -2.963e-01, 9.690e-02, 9.680e-02, 1.412e-01, 1.592e-01, 7.300e-02, 3.519e-01, -1.697e-01, -3.917e-02, 1.413e-02, 3.617e-02, 8.479e-02) * s1[y+2][x+1];
	r += M4(5.994e-03, 2.245e-03, -2.470e-02, -1.250e-02, 6.413e-03, -5.632e-02, 8.281e-03, 2.048e-02, -2.700e-01, -6.839e-02, -2.018e-02, 4.209e-02, -3.035e-02, -4.101e-02, 2.263e-02, 1.922e-02) * s1[y+2][x+2];
	r += V4(-2.374e-02, 3.639e-03, -5.296e-03, 1.406e-03);
	return vec4(r);
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}


//!DESC CuNNy-8x4C-RCAS-out
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
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(-1.840e-01, 4.278e-02, -1.003e-01, -1.709e-02, 3.115e-01, -1.508e-01, 6.582e-02, -1.221e-01, -9.400e-02, 1.716e-02, -3.185e-02, -1.453e-03, 3.524e-02, -7.448e-03, 1.141e-02, -1.929e-02) * s0[y+0][x+0];
	r += M4(3.532e-01, -1.078e-01, 1.178e-01, 2.280e-03, -4.603e-02, -2.266e-01, 9.773e-02, 2.022e-01, 2.512e-01, -1.112e-01, 3.506e-02, -5.050e-02, -6.578e-02, 5.622e-02, 3.049e-02, 3.831e-02) * s0[y+0][x+1];
	r += M4(-7.010e-02, 9.742e-02, -4.748e-02, -5.724e-02, 2.108e-02, 2.249e-01, 6.903e-02, -1.787e-02, -3.405e-02, 5.429e-02, -2.044e-02, -5.651e-02, 2.362e-02, -3.488e-02, -2.058e-02, 1.225e-02) * s0[y+0][x+2];
	r += M4(4.972e-02, -4.470e-02, 4.081e-02, 7.195e-02, -1.659e-01, 2.189e-01, 1.382e-01, 3.899e-02, -8.768e-02, 7.251e-02, -1.678e-01, 4.150e-03, -1.413e-01, -7.833e-02, -1.566e-01, -3.158e-04) * s0[y+1][x+0];
	r += M4(3.929e-01, 4.073e-01, 6.477e-01, 2.773e-01, 6.111e-01, -5.176e-01, 3.479e-02, -9.625e-01, 1.454e-01, -2.851e-01, 4.034e-01, -1.846e-01, 6.230e-01, 3.269e-01, -6.244e-02, -1.775e-01) * s0[y+1][x+1];
	r += M4(-2.151e-02, 9.830e-02, 7.416e-04, 3.185e-01, -2.853e-01, 1.435e-01, -2.376e-01, 3.735e-01, -7.495e-02, 1.136e-01, -9.629e-02, 1.958e-01, -1.994e-01, 8.088e-02, -2.489e-02, -1.950e-02) * s0[y+1][x+2];
	r += M4(-2.862e-02, 3.654e-02, -8.909e-02, -3.421e-02, -2.907e-02, 8.002e-02, -1.304e-01, 2.025e-01, 2.392e-02, -1.157e-02, 4.271e-02, 7.031e-02, -1.636e-01, 1.718e-02, 3.064e-02, -6.896e-02) * s0[y+2][x+0];
	r += M4(-2.850e-02, -5.038e-02, -1.714e-03, 1.201e-02, -3.820e-02, -6.157e-02, 3.799e-01, 3.322e-02, -1.398e-02, 1.687e-03, -6.868e-02, -1.772e-01, -4.738e-01, -5.561e-01, 4.817e-01, 4.229e-01) * s0[y+2][x+1];
	r += M4(4.277e-02, 5.774e-03, -8.228e-03, -7.003e-02, 5.227e-02, -3.837e-03, -5.927e-02, -3.151e-03, 1.248e-02, 1.209e-03, 3.512e-02, 4.183e-02, 5.369e-02, -7.015e-02, -3.004e-03, 1.684e-01) * s0[y+2][x+2];
	r += M4(-1.005e-01, 6.715e-02, -5.395e-02, -1.612e-02, 2.836e-02, 7.068e-04, 4.350e-02, 2.587e-02, -3.372e-02, 1.328e-02, -9.537e-02, 1.259e-02, -2.468e-02, -1.693e-02, -2.088e-02, 1.952e-02) * s1[y+0][x+0];
	r += M4(1.792e-01, -1.569e-01, 7.447e-02, 3.293e-03, 2.306e-01, -1.871e-01, 8.674e-02, 1.107e-03, 2.393e-01, -5.041e-02, -8.175e-02, -1.191e-01, -2.243e-02, 1.363e-01, -1.495e-02, -8.156e-03) * s1[y+0][x+1];
	r += M4(-7.279e-02, 6.651e-02, -5.116e-02, -4.191e-02, -2.582e-02, 1.223e-01, -7.977e-03, -5.245e-02, -1.307e-02, 1.493e-01, -5.180e-02, -1.519e-01, 1.010e-02, -6.167e-02, -1.320e-03, 1.328e-02) * s1[y+0][x+2];
	r += M4(2.820e-02, -1.887e-02, 2.909e-02, 9.267e-02, 1.381e-02, 5.686e-02, -2.986e-02, -2.067e-02, -1.782e-01, 5.640e-02, -1.321e-01, 1.034e-03, -9.547e-02, -5.775e-02, -1.000e-01, -5.009e-02) * s1[y+1][x+0];
	r += M4(1.431e-01, 1.697e-01, 2.344e-01, -2.026e-02, -9.890e-02, -2.259e-01, 6.597e-03, -4.525e-01, -3.831e-01, -4.370e-01, 8.184e-01, 5.264e-02, 2.341e-01, 2.151e-01, 1.431e-01, 2.056e-01) * s1[y+1][x+1];
	r += M4(-1.428e-02, -8.915e-04, -3.117e-02, 1.417e-01, -2.377e-02, 1.317e-02, -4.922e-02, 2.056e-01, -1.768e-01, -3.276e-01, -1.901e-02, 5.632e-01, -7.926e-02, -3.822e-02, -2.933e-02, -5.407e-02) * s1[y+1][x+2];
	r += M4(-1.794e-02, 3.397e-02, -4.480e-02, 2.505e-02, -1.007e-02, -1.189e-02, 2.560e-02, 4.285e-02, 1.769e-02, 1.361e-02, 1.105e-02, 8.765e-02, -5.701e-02, 2.371e-02, -9.983e-02, -6.833e-02) * s1[y+2][x+0];
	r += M4(7.839e-03, -5.403e-02, 1.181e-02, -3.402e-02, 6.817e-02, 1.458e-02, 8.083e-02, 3.991e-02, 1.557e-01, 4.124e-02, -1.538e-01, -1.567e-01, -8.719e-02, -1.663e-01, 4.330e-02, 2.762e-02) * s1[y+2][x+1];
	r += M4(5.744e-03, 1.457e-02, 4.147e-03, -2.141e-02, -2.832e-03, 5.235e-03, 9.902e-04, -3.701e-02, 2.932e-02, 1.526e-01, 1.558e-02, -4.004e-02, 1.250e-02, 3.023e-02, -1.764e-02, 1.821e-02) * s1[y+2][x+2];
	r += V4(4.379e-03, 5.352e-03, 4.644e-03, 5.936e-03);
	return tanh(vec4(r));
}
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 ipos = pos;
	ivec2 opos = pos * ivec2(1, 1);
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
			s0[ay][ax] = l0(x - 1, y - 1);
			s1[ay][ax] = -max(-s0[ay][ax], V4(0.0));
			s0[ay][ax] = max(s0[ay][ax], V4(0.0));
		}
	}
	barrier();
	vec4 r0 = f0(xy.x, xy.y);
	imageStore(out_image, opos + ivec2(0, 0), r0);
}


//!DESC CuNNy-8x4C-RCAS-shuffle
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

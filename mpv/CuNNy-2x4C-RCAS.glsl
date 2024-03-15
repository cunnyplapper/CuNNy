// CuNNy 2x4C RCAS
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

//!DESC CuNNy-2x4C-RCAS-EASU
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

//!DESC CuNNy-2x4C-RCAS-RCAS
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


//!DESC CuNNy-2x4C-RCAS-in
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
	r0 += V4(7.102e-02, 3.905e-02, 1.051e-02, -8.372e-03) * s[0][0][0];
	r0 += V4(3.928e-02, -4.192e-02, -5.493e-01, 1.774e-02) * s[0][1][0];
	r0 += V4(1.198e-01, 3.640e-02, 1.310e-01, 1.201e-02) * s[0][2][0];
	r0 += V4(8.213e-02, -6.310e-02, -5.626e-02, 4.224e-02) * s[1][0][0];
	r0 += V4(-7.212e-01, 4.286e-01, 5.996e-01, -3.591e-01) * s[1][1][0];
	r0 += V4(-2.049e-02, -7.207e-01, -1.313e-01, -2.743e-01) * s[1][2][0];
	r0 += V4(1.619e-01, 2.405e-02, 4.804e-02, -1.120e-02) * s[2][0][0];
	r0 += V4(8.277e-02, 2.733e-01, -5.511e-02, 3.916e-03) * s[2][1][0];
	r0 += V4(1.252e-01, 2.802e-02, 2.672e-03, 1.430e-02) * s[2][2][0];
	r0 += V4(1.886e-02, -2.124e-03, 3.383e-03, 8.405e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-RCAS-conv1
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
	r0 += M4(1.397e-02, 1.006e-01, -1.571e-01, 2.464e-01, -2.071e-01, 1.902e-01, 2.939e-01, -3.533e-01, -9.436e-05, -7.739e-02, 1.362e-01, -1.490e-02, -1.921e+00, 2.997e-01, 5.095e+00, -8.473e+00) * s[0][0][0];
	r0 += M4(-5.634e-02, -2.403e-02, -8.028e-02, 5.118e-02, 1.990e-02, 3.722e-02, 2.348e-01, -3.371e-02, 4.276e-02, -3.919e-02, 2.293e-02, -8.973e-02, -3.307e-02, -9.570e-02, 1.591e-01, -7.298e-02) * s[0][0][1];
	r0 += M4(8.970e-02, -2.521e-01, 3.708e-01, -1.508e+00, 1.509e-01, -4.454e-01, 3.350e-01, -2.437e-01, -5.515e-02, 4.927e-03, 3.960e-02, -4.746e-02, -3.880e+00, 6.099e-01, 4.096e+00, -9.905e+00) * s[0][1][0];
	r0 += M4(-7.055e-02, -1.504e-01, 4.795e-01, -2.416e-01, 2.268e-01, -4.163e-01, 4.481e-01, -1.856e-01, 1.517e-01, 2.084e-01, -4.449e-01, 2.998e-01, -1.627e-01, 3.864e-02, -1.177e-01, -6.393e-02) * s[0][1][1];
	r0 += M4(-3.340e-01, 1.531e-01, 2.848e-02, 4.131e-02, 6.783e-02, -9.969e-02, 7.063e-02, -1.226e-01, -2.760e-02, -1.395e-02, 6.615e-02, -6.017e-02, -2.492e+00, -1.411e+00, -1.537e-01, 3.338e-01) * s[0][2][0];
	r0 += M4(-3.588e-02, 1.446e-02, -7.955e-02, -3.773e-02, 1.811e-01, 2.215e-01, 1.577e-01, -3.332e-02, 6.811e-02, 3.457e-02, -2.213e-01, 1.030e-01, -2.627e-01, 3.302e-02, -2.746e-01, 2.587e-01) * s[0][2][1];
	r0 += M4(-1.540e-02, -2.358e-01, -3.190e-02, 1.411e-01, -9.671e-02, 5.771e-01, 4.583e-02, -2.784e-01, -1.102e-02, 1.464e-01, 8.719e-02, 3.751e-02, -3.702e+00, 1.599e+00, -6.835e-01, -5.591e+00) * s[1][0][0];
	r0 += M4(3.258e-02, -6.725e-02, -3.686e-02, 1.084e-01, 5.704e-02, 5.163e-02, -5.831e-02, -3.092e-02, -1.353e-01, 8.623e-03, 9.683e-02, -2.340e-01, -4.411e-02, 7.635e-02, 1.861e-01, -9.546e-02) * s[1][0][1];
	r0 += M4(-8.744e-02, -6.620e-01, 6.895e-01, -4.147e-01, -1.143e-01, -2.970e-02, -1.896e-01, -1.794e-01, 3.269e-01, -3.899e-01, 1.284e-01, -1.399e-01, -6.651e+00, 2.079e+00, 1.585e+00, -2.868e+00) * s[1][1][0];
	r0 += M4(-9.250e-02, 2.327e-01, 2.722e-01, -4.343e-02, -1.123e-01, -4.231e-01, 6.426e-02, -1.284e-01, 3.786e-01, -1.719e-01, 3.540e-01, 2.986e-01, -4.862e-03, -9.884e-02, -1.183e-01, -1.022e-02) * s[1][1][1];
	r0 += M4(1.116e-01, 1.992e-01, 2.801e-01, 8.000e-02, 7.330e-02, 8.584e-03, -1.811e-01, -3.998e-02, 4.959e-02, 1.418e-01, -4.905e-02, -7.949e-03, -2.017e+00, -1.929e+00, -1.915e+00, -6.771e-01) * s[1][2][0];
	r0 += M4(-7.637e-03, -3.897e-01, -1.953e-01, 5.451e-02, 1.910e-01, 2.024e-01, -3.430e-02, -4.407e-03, 1.671e-02, 3.897e-01, 5.171e-01, 3.617e-01, -1.339e-01, 5.436e-03, 2.010e-01, 2.239e-03) * s[1][2][1];
	r0 += M4(3.099e-02, 6.244e-02, 3.153e-02, -1.574e-01, 5.652e-02, 2.457e-01, -3.293e-02, 8.238e-02, 7.746e-02, 4.182e-01, -1.387e-01, 2.397e-01, 1.629e+00, 2.059e+00, 6.934e-01, 1.847e+00) * s[2][0][0];
	r0 += M4(-1.496e-02, -1.914e-02, 6.408e-02, -9.670e-02, -3.060e-02, -1.521e-01, -9.391e-02, 1.236e-02, -5.653e-02, -1.876e-01, 1.030e-01, 7.761e-02, 1.149e-02, 2.893e-01, 1.191e-01, -5.706e-02) * s[2][0][1];
	r0 += M4(5.649e-02, -2.499e-01, 4.747e-02, -7.771e-02, 3.371e-02, 7.184e-02, 5.557e-02, 1.436e-01, -3.709e-01, 2.915e-01, -2.519e-01, -1.724e-01, 3.203e-01, 1.806e+00, -2.184e-01, 8.311e-01) * s[2][1][0];
	r0 += M4(-3.033e-02, 8.859e-02, 7.002e-02, 2.938e-02, 3.376e-02, 8.659e-02, 9.301e-02, 1.023e-01, -3.707e-01, -1.809e-01, -8.509e-02, -6.654e-02, -7.810e-02, -5.043e-02, -2.027e-01, 1.047e-01) * s[2][1][1];
	r0 += M4(9.595e-02, 1.267e-01, -1.129e-01, -1.032e-01, 7.659e-03, -5.796e-02, -4.686e-03, 2.595e-02, -2.468e-01, -1.967e-01, -3.874e-01, 2.317e-02, -3.303e-01, -1.333e+00, 2.858e-01, -7.691e-01) * s[2][2][0];
	r0 += M4(-4.369e-02, -1.160e-01, -6.801e-02, -9.373e-02, 4.882e-02, 1.353e-01, 4.737e-04, 6.555e-02, -7.424e-02, -1.616e-01, -9.709e-02, 9.797e-02, -4.804e-02, -1.526e-01, 1.317e-02, -5.605e-02) * s[2][2][1];
	r0 += V4(4.712e-02, 1.838e-02, -8.126e-03, -9.622e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-RCAS-conv2
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
	r0 += M4(-1.113e-02, 7.751e-03, 2.309e-02, 4.679e-02, -2.938e-02, -1.353e-03, -1.576e-02, 2.965e-02, 9.838e-02, 4.534e-03, -3.529e-02, 3.159e-02, 1.168e-01, -8.474e-03, -1.223e-01, 2.548e-01) * s[0][0][0];
	r0 += M4(4.472e-02, 1.343e-03, 2.610e-03, -2.190e-02, 2.375e-01, 5.928e-02, -1.467e-01, 2.267e-01, 5.350e-02, 1.471e-02, -5.457e-02, 1.047e-01, 8.902e-02, 2.951e-03, -3.748e-02, 2.355e-02) * s[0][0][1];
	r0 += M4(2.856e-02, 1.869e-02, -6.355e-04, 1.073e-01, -7.153e-02, 9.859e-03, 4.574e-02, -7.799e-02, 1.673e-01, 3.043e-02, 4.597e-02, 7.554e-02, 3.456e-01, -9.172e-03, -2.670e-02, 3.629e-01) * s[0][1][0];
	r0 += M4(-1.889e-01, 2.303e-02, -5.508e-02, 3.195e-02, -1.255e-01, 3.681e-04, -1.381e-03, -1.022e-01, 4.292e-02, 3.655e-02, -1.017e-01, 1.245e-01, 1.233e-01, 1.247e-02, 3.968e-02, -9.655e-03) * s[0][1][1];
	r0 += M4(4.978e-02, -1.810e-02, 1.323e-02, 2.254e-02, -8.372e-02, 7.706e-03, 1.155e-02, -7.533e-02, 3.721e-02, -3.098e-02, 8.902e-02, -7.218e-02, 3.443e-01, -7.057e-02, 2.923e-01, 1.433e-02) * s[0][2][0];
	r0 += M4(-2.861e-02, 1.329e-02, 8.184e-03, 3.238e-02, -1.057e-01, 3.092e-02, 6.264e-02, 1.678e-02, 3.025e-02, -2.474e-02, -2.436e-02, -3.471e-03, 7.937e-02, -1.506e-02, 3.075e-02, -1.994e-03) * s[0][2][1];
	r0 += M4(-8.998e-02, 1.156e-02, -3.933e-02, 3.863e-02, 5.196e-02, -1.392e-03, -1.061e-01, -2.198e-02, -1.522e-01, -3.962e-02, -9.153e-03, 8.746e-02, 2.826e-01, -3.506e-02, -6.250e-02, 1.175e-01) * s[1][0][0];
	r0 += M4(6.284e-01, -8.425e-01, 1.081e-01, -3.145e-01, 6.614e-01, -4.719e-03, 1.460e-01, 8.457e-01, 1.680e-01, -4.567e-02, -2.916e-02, -1.169e-01, -8.383e-02, -8.558e-03, 8.121e-03, 7.981e-02) * s[1][0][1];
	r0 += M4(2.990e-01, -4.648e-01, -3.112e-02, -3.213e-01, -1.419e-01, 1.559e-01, 3.946e-01, 2.293e-01, -1.637e-02, -2.747e-02, 9.199e-02, 3.052e-01, 3.274e-01, -6.826e-02, 1.281e-01, 9.651e-01) * s[1][1][0];
	r0 += M4(1.213e+00, -1.109e+00, 8.187e-02, -1.351e+00, -2.355e-01, 2.476e-01, 4.759e-01, -2.197e-01, 3.760e-01, -3.791e-02, 2.482e-02, 7.305e-02, -1.307e-01, -5.123e-03, 3.212e-03, 1.147e-01) * s[1][1][1];
	r0 += M4(-9.198e-02, -1.019e-02, -2.052e-01, 9.253e-03, 6.865e-02, -2.490e-03, -1.482e-01, -6.101e-02, -7.267e-02, -3.627e-02, -5.244e-02, -2.284e-01, -1.980e+00, -6.418e-02, 1.833e-01, 2.647e-01) * s[1][2][0];
	r0 += M4(7.115e-02, -2.786e-02, -8.403e-02, -2.543e-02, 1.077e-02, 4.534e-04, 2.249e-01, -7.783e-02, 1.004e-01, -1.986e-02, 4.307e-02, -3.414e-02, -7.798e-02, 8.667e-02, -6.338e-02, 1.760e-01) * s[1][2][1];
	r0 += M4(5.261e-02, -6.512e-03, 6.958e-02, -6.457e-02, 1.942e-02, -2.156e-02, -1.017e-02, 5.451e-02, -5.658e-01, -8.666e-03, 3.942e-01, 6.554e-02, -5.898e-02, -3.116e-02, 2.021e-01, -1.497e-01) * s[2][0][0];
	r0 += M4(4.640e-01, -1.022e+00, 2.389e-01, -5.526e-01, 2.562e-01, 1.534e-01, 1.100e-01, 1.180e-01, -1.519e-01, 2.283e-02, 2.666e-01, -2.641e-01, -2.048e-01, -2.087e-02, 9.451e-02, 8.885e-02) * s[2][0][1];
	r0 += M4(-2.549e-01, -8.922e-02, 3.497e-01, 2.078e-01, 4.571e-02, 5.219e-02, 9.097e-02, -1.137e-02, -1.513e-01, 8.859e-01, 5.293e-01, 2.694e-01, -2.380e-01, -5.434e-02, -9.871e-02, 1.989e-01) * s[2][1][0];
	r0 += M4(-1.262e-01, -1.106e+00, -1.568e-01, -1.510e-01, 3.375e-01, 7.446e-02, -1.618e-01, 3.018e-01, -2.397e-01, 3.235e-02, -1.671e-01, 2.074e-01, -3.194e-02, -4.431e-02, 2.364e-01, -2.309e-01) * s[2][1][1];
	r0 += M4(2.984e-02, -7.605e-03, -1.585e-01, -4.813e-02, -7.483e-02, -1.364e-02, 7.539e-02, 5.414e-02, -8.102e-02, 2.633e-02, 4.550e-01, -3.652e-01, 4.281e-01, 2.503e+00, 4.093e-01, 1.916e-01) * s[2][2][0];
	r0 += M4(1.108e-02, -4.619e-03, -1.179e-01, -2.255e-01, 5.192e-02, -1.900e-02, -1.153e-02, 1.519e-01, -6.957e-03, 3.235e-02, 1.064e-02, -3.946e-02, -4.561e-02, 1.040e-02, 2.590e-01, -1.410e-01) * s[2][2][1];
	r0 += V4(-1.077e-02, 2.630e-01, -2.771e-02, -1.509e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-RCAS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv2
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
#define l0(x, y) V4(texelFetch(conv2_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(2.568e-01, -3.181e-02, -4.092e-02, -4.446e-02, 6.584e-02, -7.923e-02, -2.627e-02, -4.261e-02, 1.019e-01, -1.111e-01, -3.046e-02, 8.227e-03, -3.210e-02, 2.141e-02, 4.185e-02, 2.122e-02) * s[0][0][0];
	r0 += M4(1.362e-01, -6.909e-02, 3.545e-03, -3.980e-02, -1.103e+00, 6.319e-02, 4.228e-02, 1.079e-01, 1.397e-01, -2.773e-02, -5.166e-02, -8.389e-02, 4.664e-03, 2.545e-02, -3.104e-04, 4.447e-03) * s[0][0][1];
	r0 += M4(1.641e-01, 5.371e-01, -3.427e-01, -2.265e-01, -7.565e-03, 1.841e-01, -2.038e-02, 1.959e-02, 2.152e-02, 4.583e-01, -1.696e-01, -8.641e-02, -1.333e-01, -1.065e-01, 1.018e-01, 7.067e-02) * s[0][1][0];
	r0 += M4(-1.421e-01, 1.518e-01, -4.489e-02, 1.560e-02, -1.950e+00, -1.574e+00, -3.818e-01, -7.967e-02, 3.460e-02, 1.431e-01, -1.113e-02, -3.310e-02, 7.446e-02, -4.184e-02, 3.793e-02, 1.109e-03) * s[0][1][1];
	r0 += M4(-2.232e-02, -1.101e-01, 2.159e-02, -9.220e-02, -1.837e-02, -7.007e-02, 2.942e-02, -3.250e-03, 1.051e-01, -6.337e-02, -3.783e-03, -6.329e-02, 8.024e-02, -1.668e-02, -5.218e-02, 4.692e-03) * s[0][2][0];
	r0 += M4(2.362e-02, -7.934e-02, 3.852e-02, 1.891e-02, 1.800e-02, -1.507e+00, 9.324e-02, -1.801e-01, -8.257e-03, 4.897e-02, -3.287e-02, 2.420e-02, -1.561e-02, 8.227e-02, -3.968e-02, -1.590e-02) * s[0][2][1];
	r0 += M4(-9.256e-02, -1.175e-01, 1.826e-01, -8.816e-02, -5.536e-02, 5.721e-02, 5.920e-02, 2.626e-02, 1.978e-01, -2.568e-01, 5.752e-01, -2.035e-01, -2.366e-03, -1.834e-02, -5.271e-02, -2.035e-02) * s[1][0][0];
	r0 += M4(-3.863e-02, -1.450e-01, 1.004e-01, -1.098e-01, -1.964e+00, 3.448e-01, -1.883e+00, 1.205e-02, -4.972e-02, -7.016e-02, 2.037e-01, 2.995e-02, -3.440e-02, 7.792e-03, -3.529e-02, -1.076e-02) * s[1][0][1];
	r0 += M4(-1.919e-01, -6.595e-02, 3.721e-01, 6.152e-01, -3.505e-02, -2.133e-01, -1.922e-02, -5.914e-03, -1.047e+00, -2.340e-02, -1.972e-01, 1.087e+00, -2.215e-01, 6.375e-02, -4.639e-01, -1.144e-01) * s[1][1][0];
	r0 += M4(8.522e-02, 3.237e-01, -6.700e-02, 3.115e-01, -3.221e+00, -3.394e+00, -2.495e+00, -2.608e+00, -1.956e-01, -1.086e-01, -5.342e-02, 1.729e-01, -1.913e-01, -1.822e-01, -6.519e-02, -1.384e-01) * s[1][1][1];
	r0 += M4(-2.875e-02, -1.785e-01, 1.653e-02, -2.209e-02, 1.345e-02, 8.276e-02, -1.493e-02, 1.984e-02, 1.831e-01, -3.585e-01, 2.691e-01, -1.887e-01, 1.222e-01, -1.607e-01, 1.743e-01, -2.124e-01) * s[1][2][0];
	r0 += M4(4.300e-02, -9.299e-02, 3.582e-02, -1.199e-01, 3.415e-01, -1.675e+00, 1.712e-01, -1.461e+00, 1.493e-02, -7.378e-02, 4.285e-02, -1.656e-02, 1.116e-02, -1.892e-02, 4.864e-02, 9.958e-02) * s[1][2][1];
	r0 += M4(1.256e-03, 1.237e-03, -2.204e-02, 3.028e-03, 2.600e-02, 6.687e-03, -5.907e-03, -2.926e-03, 1.924e-01, 3.263e-02, -9.912e-03, -8.437e-02, -1.926e-02, 1.080e-02, -2.900e-02, 9.002e-03) * s[2][0][0];
	r0 += M4(-3.061e-02, 5.677e-02, -3.729e-02, -1.630e-02, 9.151e-02, -2.960e-01, -1.123e+00, 8.875e-02, 4.867e-02, 2.206e-02, -2.320e-02, -1.285e-02, -3.580e-02, -9.144e-03, -4.759e-02, 3.211e-02) * s[2][0][1];
	r0 += M4(1.401e-01, 3.531e-02, 3.050e-02, -3.654e-02, 1.227e-02, 3.184e-02, 1.937e-02, -8.993e-03, 2.666e-01, 2.568e-01, -3.536e-01, -2.153e-01, 1.178e-02, 7.250e-03, 6.890e-03, 1.764e-02) * s[2][1][0];
	r0 += M4(-6.618e-02, -9.722e-02, 6.877e-03, 6.076e-02, 3.589e-01, 4.169e-01, -1.562e+00, -1.758e+00, 5.591e-02, 5.252e-02, -2.469e-02, -6.371e-02, 8.080e-02, 2.570e-02, 2.036e-03, -6.470e-02) * s[2][1][1];
	r0 += M4(-2.411e-02, 8.596e-02, -4.703e-02, -2.767e-02, 7.886e-04, 2.281e-04, -1.932e-02, -2.272e-03, -1.192e-01, 8.390e-02, -8.205e-03, 9.946e-03, 3.954e-03, -3.036e-02, 5.665e-02, -1.722e-02) * s[2][2][0];
	r0 += M4(4.800e-02, -4.969e-03, 2.127e-02, -7.690e-02, -3.510e-01, -8.155e-03, -3.784e-03, -6.712e-01, -6.030e-03, 1.947e-02, -7.847e-03, -1.208e-02, 1.393e-02, 2.099e-02, 1.097e-03, 5.687e-03) * s[2][2][1];
	r0 += V4(9.895e-04, 4.255e-04, 1.072e-03, 4.129e-04);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + rcas_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + rcas_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + rcas_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + rcas_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

// CuNNy 3x4C
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

//!DESC CuNNy-3x4C-EASU
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


//!DESC CuNNy-3x4C-in
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
	r0 += V4(1.134e-02, 6.955e-03, 1.209e-01, -8.307e-03) * s[0][0][0];
	r0 += V4(5.138e-02, -1.592e-02, -2.847e-02, -6.491e-03) * s[0][1][0];
	r0 += V4(5.344e-03, 7.256e-03, -9.936e-02, -4.985e-03) * s[0][2][0];
	r0 += V4(1.439e-02, -2.473e-02, -4.871e-01, 5.918e-01) * s[1][0][0];
	r0 += V4(-9.468e-01, 5.488e-01, 2.912e-01, -5.724e-01) * s[1][1][0];
	r0 += V4(6.058e-02, -3.286e-02, 1.968e-01, 1.751e-02) * s[1][2][0];
	r0 += V4(1.324e-02, 1.981e-02, 4.490e-01, -3.253e-02) * s[2][0][0];
	r0 += V4(3.254e-02, -5.300e-01, -3.604e-01, 2.960e-02) * s[2][1][0];
	r0 += V4(-1.675e-03, 2.194e-02, -8.739e-02, -1.416e-02) * s[2][2][0];
	r0 += V4(8.864e-03, -7.851e-04, 4.049e-03, 1.813e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-conv1
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
	r0 += M4(2.287e-01, 1.692e+00, -1.605e-01, -1.163e+00, 3.263e-03, 7.775e-02, -2.638e-01, 5.449e-01, 3.297e-02, -3.914e-01, -9.924e-02, -7.941e-02, 7.107e-02, -3.360e-01, -1.119e-01, -2.968e-02) * s[0][0][0];
	r0 += M4(-9.736e-02, 2.737e-02, -1.729e-01, -2.231e-01, 1.782e-01, 4.295e-01, 2.239e-02, 5.112e-01, 1.521e-02, -2.936e-01, -2.324e-02, -4.549e-02, 7.674e-02, 3.870e-02, -1.498e-01, -1.027e-01) * s[0][0][1];
	r0 += M4(1.341e+00, 1.899e+00, 1.010e+00, -1.389e-01, -7.679e-02, 1.137e+00, -1.084e+00, 6.227e-02, -1.403e-01, 2.301e-01, -4.059e-01, 9.886e-02, -1.995e-01, 7.097e-01, -1.567e-01, -2.667e-01) * s[0][1][0];
	r0 += M4(-3.090e-02, 1.267e-01, 5.690e-02, 2.043e-01, 4.328e-01, -8.100e-01, -2.842e-01, 4.019e-01, 5.934e-02, 2.401e-01, 3.115e-01, 2.378e-01, 3.156e-02, -4.463e-01, -2.475e-01, -5.606e-01) * s[0][1][1];
	r0 += M4(2.631e-01, 6.801e-01, -2.001e-01, 1.130e-01, 7.509e-02, 1.030e-01, -4.424e-01, -1.647e-02, -7.279e-02, 9.793e-02, -5.687e-02, -7.666e-02, -4.316e-02, 8.735e-02, -1.296e-01, -4.813e-03) * s[0][2][0];
	r0 += M4(4.942e-02, 4.174e-02, -5.350e-02, 2.049e-03, 1.105e-01, -8.440e-02, -2.989e-02, 2.231e-02, 1.957e-02, -6.924e-02, 1.819e-01, -7.234e-02, 5.723e-02, -5.215e-01, -1.224e-01, 1.221e-01) * s[0][2][1];
	r0 += M4(1.910e+00, 3.093e+00, 1.240e-01, 1.700e+00, 2.668e-01, -9.062e-02, 2.029e-01, -3.021e-02, -2.734e-01, -2.656e-01, 1.201e-01, 8.180e-02, -1.782e-01, 4.048e-02, 3.098e-01, 4.633e-01) * s[1][0][0];
	r0 += M4(4.236e-02, 1.376e-01, 1.400e-01, 1.758e-01, 1.549e-01, -1.055e-01, 8.957e-02, 4.603e-01, -2.043e-01, -3.157e-02, 2.001e-01, -5.759e-02, -1.894e-01, 2.880e-01, 1.489e-01, 2.298e-02) * s[1][0][1];
	r0 += M4(7.086e+00, -5.588e-01, -1.688e+00, 9.670e-01, 1.529e-01, -1.323e-01, 7.659e-01, -6.208e-01, -1.273e-01, 6.332e-02, 2.369e-01, 2.300e-01, 1.384e-01, 4.824e-01, 1.966e-01, -1.042e-01) * s[1][1][0];
	r0 += M4(2.995e-01, -2.556e-01, -9.399e-02, -1.589e-01, -3.672e-01, 3.962e-01, 1.651e-01, 4.032e-02, -1.321e-01, -1.300e-01, 1.975e-01, -1.231e-01, -6.768e-02, -1.318e-01, 1.586e-01, 3.955e-01) * s[1][1][1];
	r0 += M4(9.382e-01, -1.149e-01, -2.244e-01, -3.381e-02, 1.159e-01, 7.690e-02, -3.584e-02, 6.393e-02, -2.560e-01, 3.113e-01, -1.052e-01, -2.201e-01, -6.058e-01, 2.781e-01, 1.705e-01, -2.409e-02) * s[1][2][0];
	r0 += M4(-1.779e-03, 4.072e-02, 2.222e-02, -9.829e-02, -1.742e-01, 7.699e-02, 2.688e-02, -1.538e-01, -6.837e-02, 2.219e-01, 1.395e-02, 1.589e-02, -8.652e-01, -1.879e-01, 2.517e-01, -1.062e-01) * s[1][2][1];
	r0 += M4(3.220e-01, -7.403e-01, 3.493e-01, 4.116e-01, 9.583e-02, 5.777e-02, 2.675e-02, -1.720e-01, 8.843e-02, -6.668e-02, 7.802e-02, -1.228e-01, 2.163e-01, 6.726e-02, -9.582e-02, 2.919e-01) * s[2][0][0];
	r0 += M4(-6.524e-02, -7.557e-02, 2.034e-03, 1.114e-01, 1.143e-01, 7.326e-02, -2.237e-01, -1.987e-01, 1.256e-02, 1.013e-01, -1.470e-01, -6.408e-02, 2.235e-01, 7.282e-02, -8.690e-02, 7.424e-02) * s[2][0][1];
	r0 += M4(-4.303e-01, 3.736e-01, -3.729e-01, 1.053e-01, -1.496e-01, -7.740e-02, -1.258e-01, -1.007e-01, 2.495e-01, -5.702e-02, 1.082e-01, -2.659e-01, 1.615e-01, -1.872e-01, -4.529e-02, -1.314e-01) * s[2][1][0];
	r0 += M4(-1.416e-01, 5.188e-02, 6.260e-02, -1.147e-02, -6.159e-02, 1.400e-02, -4.070e-02, 3.988e-02, 8.928e-02, 1.548e-01, -3.065e-01, 1.540e-01, 1.936e-01, -6.018e-03, -4.629e-02, 3.916e-01) * s[2][1][1];
	r0 += M4(-3.957e-01, -5.044e-01, 1.796e-01, -1.026e+00, 2.751e-02, -4.902e-02, 1.417e-01, 1.615e-01, -3.623e-02, -8.754e-02, 1.819e-01, -2.246e-02, 1.939e-01, -1.978e-01, 5.131e-02, -2.806e-01) * s[2][2][0];
	r0 += M4(-3.174e-02, -7.573e-02, 3.573e-02, 8.694e-02, 1.926e-02, 5.743e-02, -2.310e-01, 2.938e-02, -1.490e-01, 1.366e-01, 9.738e-02, 1.710e-01, 1.646e-01, -1.977e-01, -7.435e-02, -1.083e-01) * s[2][2][1];
	r0 += V4(2.878e-03, -1.104e-02, -1.510e-04, 2.833e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-conv2
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
	r0 += M4(3.257e-01, -1.499e-01, -1.384e-01, 5.002e-02, 3.201e-02, 2.007e-03, 1.004e-02, 6.419e-02, -1.707e-01, 3.020e-02, 2.842e-03, 1.242e-01, 7.409e-02, 6.796e-02, 7.087e-02, -1.871e-02) * s[0][0][0];
	r0 += M4(1.997e-01, -5.162e-02, 7.424e-02, -4.405e-03, -7.873e-02, 7.364e-02, 5.405e-02, -5.589e-02, 7.143e-03, 3.834e-02, -4.111e-02, -1.098e-03, 1.044e-02, -1.017e-02, -6.678e-02, 3.309e-02) * s[0][0][1];
	r0 += M4(-2.432e-01, -1.394e-01, -3.266e-02, -1.988e-01, -5.737e-02, 5.504e-02, 5.090e-02, -9.692e-02, 4.120e-01, 8.016e-02, -2.970e-01, 4.939e-01, 3.666e-01, -7.741e-02, -2.021e-01, -1.577e-01) * s[0][1][0];
	r0 += M4(-3.018e-01, 1.062e-01, 1.490e-01, -1.865e-01, -3.295e-01, 2.343e-01, 1.714e-01, 2.669e-02, 1.332e-01, -1.776e-02, -3.212e-02, 2.399e-02, -3.214e-02, -5.948e-03, -5.561e-02, 1.651e-01) * s[0][1][1];
	r0 += M4(-6.838e-02, -5.411e-02, -1.352e-01, 1.230e-01, 1.260e-01, -1.787e-02, -1.696e-02, 1.339e-02, -4.854e-02, 5.353e-02, -5.003e-02, 9.152e-02, 1.596e-01, 1.137e-01, 3.887e-01, -6.340e-02) * s[0][2][0];
	r0 += M4(2.003e-01, -1.245e-02, 1.285e-02, 8.355e-02, 1.824e-01, -2.559e-02, 2.204e-02, -1.066e-01, -2.924e-02, 4.500e-02, 8.749e-02, -1.187e-01, 3.536e-02, -6.119e-02, 4.281e-02, -1.118e-01) * s[0][2][1];
	r0 += M4(6.832e-01, -3.288e-01, -4.917e-02, 8.004e-02, -1.209e-01, 1.996e-01, 1.538e-01, -8.958e-03, -3.285e-02, -2.569e-02, -1.462e-01, -5.525e-02, -1.294e-01, 6.568e-02, 2.940e-02, -4.028e-02) * s[1][0][0];
	r0 += M4(3.662e-01, -2.737e-01, 7.145e-02, 1.028e-01, -1.247e-01, -2.455e-02, -2.592e-01, 2.058e-01, -3.329e-01, 1.063e-01, -9.583e-03, -4.717e-02, -7.067e-02, 1.880e-02, -1.522e-02, 4.973e-02) * s[1][0][1];
	r0 += M4(1.012e-01, 7.597e-01, -2.746e-01, -2.708e-01, 1.594e-02, 3.912e-01, 9.734e-02, -1.478e-01, -6.678e-02, -1.687e-03, 9.546e-02, 2.964e-03, 4.657e-02, 1.616e-01, 2.134e-01, -3.879e-01) * s[1][1][0];
	r0 += M4(-1.029e-01, 7.793e-01, 1.392e-01, -5.273e-01, -4.714e-01, 1.358e-01, -5.267e-01, 3.072e-01, 3.034e-01, 2.968e-01, 2.763e-01, 2.077e-01, 2.485e-02, 6.540e-02, 1.523e-01, -9.983e-02) * s[1][1][1];
	r0 += M4(-5.462e-02, 2.183e-02, -3.253e-01, 2.057e-01, 1.489e-01, 7.083e-04, 1.085e-01, -2.083e-01, -2.009e-02, -6.042e-02, 5.723e-03, -1.197e-01, -7.305e-02, 2.213e-01, 6.623e-01, -1.599e-01) * s[1][2][0];
	r0 += M4(-4.694e-02, -2.148e-01, -2.510e-01, -3.796e-02, -1.131e-01, -3.325e-01, -4.576e-01, -2.049e-02, -5.393e-02, 1.281e-01, 1.431e-01, -1.349e-01, -1.077e-01, -1.451e-01, -3.057e-01, 9.107e-02) * s[1][2][1];
	r0 += M4(2.018e-02, -9.423e-02, -8.425e-02, 2.466e-01, -7.440e-02, 6.622e-02, 2.839e-02, -4.005e-02, -4.969e-02, 2.016e-02, -2.079e-02, -5.751e-03, -2.834e-02, 3.500e-02, 5.921e-02, -1.076e-02) * s[2][0][0];
	r0 += M4(-5.645e-02, -4.973e-02, 1.607e-01, 1.842e-01, -1.516e-01, -2.834e-02, -7.795e-02, -3.053e-02, 2.130e-02, 1.017e-01, -1.881e-03, -8.269e-02, 6.173e-02, -3.010e-02, -5.211e-02, 3.919e-02) * s[2][0][1];
	r0 += M4(3.681e-03, 2.202e-01, -7.356e-02, -1.821e-01, -6.150e-02, -1.258e-01, 5.726e-02, -4.306e-01, 1.893e-02, -4.158e-02, -4.873e-02, 1.825e-02, 2.358e-02, -2.692e-02, 3.634e-02, 1.371e-01) * s[2][1][0];
	r0 += M4(1.932e-01, 2.774e-01, 2.846e-01, -1.426e-01, -3.468e-01, -3.518e-02, -1.316e-01, -9.786e-02, -2.202e-01, 1.400e-01, 9.239e-02, -3.608e-01, -3.754e-02, -4.142e-02, 3.057e-02, 6.553e-02) * s[2][1][1];
	r0 += M4(-9.695e-03, -8.326e-02, -1.246e-01, -8.280e-02, -3.665e-03, -4.358e-02, 2.349e-01, -1.312e-01, -6.235e-02, -9.982e-02, -1.299e-02, -6.481e-02, 1.078e-01, -9.004e-02, -1.764e-01, 1.851e-01) * s[2][2][0];
	r0 += M4(-7.033e-04, 6.379e-02, 3.583e-01, -1.362e-01, -1.297e-01, -5.748e-01, -3.542e-01, -2.077e-01, 1.857e-02, 3.254e-02, 1.039e-01, -1.851e-01, 2.776e-02, 6.150e-02, -6.909e-02, 5.385e-02) * s[2][2][1];
	r0 += V4(6.698e-03, 9.370e-03, 1.716e-02, -1.354e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-conv3
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
	r0 += M4(4.889e-02, -2.286e-02, -5.562e-02, -4.431e-02, 6.884e-02, -1.313e-01, -1.189e-01, -1.085e-01, 1.317e-02, 1.489e-01, 6.944e-02, 2.956e-03, -1.735e-01, -3.037e-01, -9.620e-02, 2.214e-02) * s[0][0][0];
	r0 += M4(1.140e-01, 3.364e-02, -3.301e-02, -5.083e-02, -3.251e-01, -1.264e-01, 4.627e-02, -3.363e-02, 3.927e-01, 3.091e-01, 8.796e-02, -4.274e-02, 3.430e-02, 4.104e-02, -6.316e-02, -4.444e-02) * s[0][0][1];
	r0 += M4(-2.556e-02, 7.471e-02, 3.326e-02, -4.278e-02, 1.789e-01, 7.756e-02, 2.523e-02, -6.160e-02, -3.057e-01, -5.030e-03, 1.067e-01, 7.939e-02, 2.716e-01, -1.839e-01, -1.276e-01, -2.846e-02) * s[0][1][0];
	r0 += M4(-9.868e-02, 2.407e-02, -6.526e-02, -1.204e-01, 2.408e-01, 4.738e-02, 1.384e-02, 8.889e-02, -3.368e-01, 1.653e-01, 1.407e-01, -6.644e-02, -8.781e-02, 7.069e-02, 6.519e-02, -1.300e-02) * s[0][1][1];
	r0 += M4(-3.479e-02, 3.234e-02, 2.493e-02, 2.298e-02, 1.246e-01, 6.233e-02, -5.298e-02, -6.835e-02, 4.947e-03, -8.341e-02, 2.288e-02, 9.883e-02, -2.654e-01, -1.304e-01, -1.031e-01, -7.198e-02) * s[0][2][0];
	r0 += M4(-2.059e-01, -8.827e-02, 1.519e-02, -7.498e-02, -2.255e-01, -1.477e-02, -1.022e-02, -7.425e-02, 1.634e-01, -9.448e-02, -2.235e-02, 1.322e-01, 1.173e-01, 4.112e-03, -5.553e-02, 1.838e-02) * s[0][2][1];
	r0 += M4(1.830e-02, 1.909e-02, -5.514e-03, -1.477e-03, -7.004e-03, -1.345e-01, -2.665e-01, -1.690e-01, 3.381e-02, 1.209e-01, 2.631e-01, 2.271e-01, -6.918e-02, -1.142e-01, 9.850e-02, 1.787e-01) * s[1][0][0];
	r0 += M4(-2.038e-01, 9.545e-02, 3.817e-02, -1.908e-02, -1.638e-01, -1.118e-01, -2.096e-01, 9.157e-02, 4.560e-02, -1.883e-01, 1.858e-01, 2.705e-01, 6.431e-02, 1.340e-01, 5.725e-02, 7.047e-02) * s[1][0][1];
	r0 += M4(-5.216e-02, 1.183e-01, 2.510e-01, 3.311e-01, 1.655e-01, 2.725e-01, -2.990e-01, -7.135e-02, -2.735e-01, -2.963e-01, 2.641e-01, 1.069e-01, -5.779e-02, -8.574e-01, 5.103e-01, 1.239e+00) * s[1][1][0];
	r0 += M4(5.259e-01, 4.735e-01, 1.421e-01, 1.850e-01, 1.984e-02, 6.880e-02, -4.482e-01, 5.216e-01, -2.588e-02, -5.127e-01, 1.170e-01, 3.853e-02, -1.275e-01, -2.666e-01, 4.057e-02, 1.462e-01) * s[1][1][1];
	r0 += M4(-1.827e-01, -5.364e-02, 1.679e-02, 1.100e-01, 1.013e-01, -1.682e-01, 1.047e-02, 1.726e-01, -4.138e-02, 5.848e-02, 2.328e-02, -9.815e-02, -5.910e-02, 2.313e-01, -1.101e-01, -3.191e-01) * s[1][2][0];
	r0 += M4(-7.969e-02, -6.338e-02, -4.858e-01, -8.655e-01, -4.040e-02, -1.982e-01, -1.584e-02, 1.707e-01, -4.313e-02, 5.131e-02, 7.512e-03, -1.810e-02, 1.189e-01, 3.892e-02, -2.833e-02, -9.229e-02) * s[1][2][1];
	r0 += M4(-1.191e-03, -3.687e-02, -2.661e-02, 2.981e-02, 2.024e-02, 4.871e-02, 7.882e-02, -6.323e-03, -1.279e-02, -7.733e-02, -1.091e-01, 2.689e-02, -5.031e-02, -5.023e-02, -1.223e-01, -2.618e-02) * s[2][0][0];
	r0 += M4(8.166e-03, 7.417e-02, -7.294e-02, 2.977e-02, -5.137e-02, 4.536e-02, 3.942e-02, 1.951e-02, 1.695e-03, -1.351e-01, -8.374e-02, 3.091e-02, -2.651e-02, -4.512e-02, -5.847e-02, 2.283e-02) * s[2][0][1];
	r0 += M4(-2.742e-03, 2.690e-02, -5.508e-02, 7.128e-03, -2.291e-02, -6.995e-02, 1.997e-02, 1.058e-01, -1.611e-02, 8.419e-02, -1.792e-03, -1.335e-01, 3.314e-02, -7.105e-02, -2.433e-02, 1.382e-01) * s[2][1][0];
	r0 += M4(4.358e-02, 1.809e-01, 4.801e-02, -3.974e-01, -5.038e-02, -1.323e-01, -2.478e-02, 1.561e-01, 4.129e-02, -4.689e-02, -1.551e-02, 8.648e-02, 7.050e-02, 6.421e-02, -3.865e-03, -6.116e-02) * s[2][1][1];
	r0 += M4(-2.107e-02, -8.275e-02, -7.203e-02, 5.688e-02, 5.121e-02, -1.631e-02, -9.623e-03, 3.867e-02, -2.914e-02, 6.448e-03, 3.475e-02, -2.591e-02, 2.986e-02, 2.501e-01, 8.028e-02, -2.725e-01) * s[2][2][0];
	r0 += M4(-1.010e-01, 2.037e-02, -4.342e-02, -2.850e-01, 1.360e-02, 6.323e-02, -2.277e-02, -8.417e-02, 8.734e-03, 6.025e-02, 2.876e-02, -9.148e-02, -2.169e-02, -4.018e-02, 3.022e-02, -9.085e-03) * s[2][2][1];
	r0 += V4(-1.053e-03, 9.006e-03, -3.901e-03, -1.154e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-3x4C-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv3
//!BIND easu
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
	r0 += M4(-9.012e-03, -3.512e-02, -1.697e-02, -1.184e-02, -2.449e-02, -5.492e-03, -5.091e-02, -4.041e-02, 3.435e-02, -7.531e-03, 4.798e-02, 3.729e-02, -7.202e-02, 2.867e-02, -2.607e-02, -2.299e-02) * s[0][0][0];
	r0 += M4(9.240e-03, 5.167e-03, 2.786e-02, 1.626e-02, -4.195e-02, -7.395e-03, -3.293e-02, -3.674e-02, 9.357e-02, -5.803e-02, 6.713e-02, 1.387e-02, -1.163e-01, 1.199e-01, 7.590e-02, -3.180e-02) * s[0][0][1];
	r0 += M4(9.178e-02, 6.366e-02, -2.707e-02, -7.040e-02, 4.873e-02, 2.950e-02, 1.339e-01, 8.037e-02, 2.257e-02, 1.100e-01, -1.494e-01, -8.625e-02, -9.269e-02, -1.872e-01, 1.636e-01, 9.023e-02) * s[0][1][0];
	r0 += M4(-2.258e-02, 7.382e-03, -4.252e-02, -2.867e-02, 2.780e-02, -4.033e-02, 8.130e-02, 7.674e-02, -5.110e-02, 1.759e-01, -4.204e-02, 1.835e-03, -1.297e-01, -6.074e-01, 1.929e-01, 1.630e-01) * s[0][1][1];
	r0 += M4(-1.372e-02, -3.968e-02, 3.479e-02, 1.948e-02, 6.955e-02, 6.368e-02, -4.637e-02, -1.672e-02, -3.001e-02, -6.349e-02, 3.914e-02, -1.844e-03, 3.866e-02, 6.028e-02, -5.115e-02, 3.164e-02) * s[0][2][0];
	r0 += M4(-2.819e-02, -3.228e-02, 4.856e-03, 8.766e-03, -3.641e-03, 2.570e-02, -8.038e-02, -6.137e-02, -3.611e-03, -1.082e-01, 2.696e-02, 3.246e-02, -5.986e-02, 1.983e-01, -6.861e-02, 6.665e-02) * s[0][2][1];
	r0 += M4(-2.153e-01, 1.723e-01, -5.784e-02, -2.036e-02, 4.043e-02, 1.153e-01, 2.079e-02, 1.511e-01, -6.968e-02, -8.165e-02, -4.937e-02, -1.025e-01, 7.795e-02, -9.355e-03, -3.739e-02, 3.589e-02) * s[1][0][0];
	r0 += M4(-1.474e-02, 2.885e-02, -3.954e-02, -6.648e-02, 9.480e-02, -2.189e-02, 1.472e-02, 5.301e-02, -7.554e-02, -2.470e-02, -4.336e-02, -1.174e-01, 2.244e-01, 2.475e-01, -4.822e-01, 1.219e-01) * s[1][0][1];
	r0 += M4(5.312e-01, -3.043e-01, 2.291e-01, 8.506e-02, -6.253e-02, -1.361e-01, -4.072e-01, -3.649e-01, 1.160e-01, 1.284e-01, 4.442e-01, 3.874e-01, 5.959e-02, 2.466e-01, -4.621e-01, -2.959e-01) * s[1][1][0];
	r0 += M4(1.377e-01, 1.786e-01, 8.631e-02, 1.694e-01, -5.254e-01, 3.795e-02, -3.682e-01, -2.133e-01, 9.178e-01, 4.283e-01, 4.191e-01, 4.109e-01, 6.383e-01, 3.930e-01, -3.176e-01, -1.168e+00) * s[1][1][1];
	r0 += M4(-5.626e-02, 2.310e-01, -1.051e-01, 4.593e-04, 5.435e-03, -2.867e-02, 1.372e-01, -7.135e-02, 2.697e-02, 6.478e-02, -8.329e-02, 4.746e-02, -2.898e-03, -5.408e-02, 9.942e-02, -9.105e-02) * s[1][2][0];
	r0 += M4(2.032e-02, 1.983e-02, -2.132e-02, -9.230e-03, 1.195e-01, -3.916e-01, 1.419e-01, -1.088e-01, -2.900e-02, 3.936e-01, -1.880e-01, -9.507e-02, -1.133e-01, 3.239e-02, -1.587e-01, 1.236e-02) * s[1][2][1];
	r0 += M4(-1.564e-01, 2.163e-01, -2.474e-01, 3.884e-01, -7.476e-03, 3.661e-03, 1.190e-02, -2.485e-02, 4.518e-03, -9.408e-03, -6.023e-03, -1.085e-02, -2.359e-02, 1.593e-02, 4.488e-02, 2.318e-02) * s[2][0][0];
	r0 += M4(-3.772e-02, 4.553e-02, -4.372e-03, 1.601e-01, -4.134e-02, -6.999e-03, 1.924e-02, -5.966e-02, 1.249e-02, 7.643e-02, -1.911e-02, 7.532e-02, -1.896e-01, -4.286e-02, 1.577e-01, 1.052e-01) * s[2][0][1];
	r0 += M4(3.606e-01, -5.602e-01, 7.639e-01, -7.597e-01, -2.104e-02, 2.898e-02, 2.427e-01, 2.128e-01, -1.287e-02, 3.650e-02, -1.116e-01, 1.417e-02, -5.613e-02, -4.315e-02, 2.250e-01, 2.303e-01) * s[2][1][0];
	r0 += M4(-6.927e-02, -1.479e-01, 3.651e-02, -8.675e-02, 4.602e-02, 8.983e-02, -7.420e-02, 2.771e-01, -2.401e-01, -6.518e-02, 2.684e-01, 1.364e-01, -9.260e-02, -2.325e-01, 3.359e-01, 2.785e-01) * s[2][1][1];
	r0 += M4(-1.774e-01, 1.022e-01, -2.053e-01, 2.661e-01, -9.214e-03, -8.426e-02, -1.127e-02, 4.139e-02, -1.546e-02, -3.025e-02, 4.463e-02, -4.604e-02, -1.024e-03, -3.135e-02, -2.606e-02, 2.251e-02) * s[2][2][0];
	r0 += M4(-2.573e-03, 2.714e-02, 9.468e-03, 2.881e-02, -2.818e-02, -1.034e-01, 1.477e-01, -1.545e-01, -6.093e-02, -2.881e-01, 1.048e-01, 1.496e-01, 1.339e-02, -6.496e-02, -2.818e-02, -3.588e-02) * s[2][2][1];
	r0 += V4(-3.212e-04, 2.315e-04, -4.214e-04, 3.299e-04);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

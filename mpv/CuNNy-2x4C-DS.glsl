// CuNNy 2x4C DS
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

//!DESC CuNNy-2x4C-DS-EASU
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


//!DESC CuNNy-2x4C-DS-in
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
#define l0(x, y) F(LUMA_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * LUMA_pt).r)
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
	r0 += V4(3.635e-02, -2.239e-02, 1.150e-02, 6.665e-02) * s[0][0][0];
	r0 += V4(-5.960e-02, 6.671e-02, -2.795e-02, -6.686e-02) * s[0][1][0];
	r0 += V4(5.285e-02, -5.986e-01, -5.788e-03, -8.278e-03) * s[0][2][0];
	r0 += V4(2.583e-02, -3.072e-02, -5.606e-02, -5.254e-01) * s[1][0][0];
	r0 += V4(-5.767e-01, 4.681e-01, 4.035e-01, 5.332e-01) * s[1][1][0];
	r0 += V4(-1.710e-01, 1.652e-01, 2.024e-02, -1.332e-02) * s[1][2][0];
	r0 += V4(1.432e-02, 3.699e-02, 4.289e-02, 1.390e-02) * s[2][0][0];
	r0 += V4(-1.911e-03, -1.070e-01, -3.525e-01, -6.458e-03) * s[2][1][0];
	r0 += V4(4.695e-02, 5.578e-04, -4.629e-02, -5.543e-03) * s[2][2][0];
	r0 += V4(8.571e-03, 7.338e-03, 8.636e-03, -1.254e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-DS-conv1
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
#define l0(x, y) V4(in_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * in_pt))
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
	r0 += M4(8.744e-01, 6.105e-01, -2.895e+00, 9.811e-02, -2.397e-02, -9.703e-02, -4.358e-03, 3.465e-02, 3.113e-02, -2.687e-01, 7.990e-02, -2.121e-01, 8.066e-03, 2.287e-03, 6.131e-02, -2.262e-02) * s[0][0][0];
	r0 += M4(3.340e-02, -5.768e-02, -5.350e-02, 1.161e-02, 3.446e-02, -1.470e-01, 4.971e-02, -4.441e-02, -2.282e-02, -4.010e-01, 2.432e-02, -6.483e-03, 7.608e-02, 4.467e-02, -1.558e-01, -3.860e-02) * s[0][0][1];
	r0 += M4(2.188e+00, -1.326e+00, 6.534e-01, -1.967e+00, 1.534e-02, 2.236e-02, -1.668e-02, -4.479e-02, 5.879e-02, -5.603e-02, -9.823e-01, -2.822e-01, -7.828e-02, -9.554e-02, 3.232e-01, 5.625e-03) * s[0][1][0];
	r0 += M4(1.159e-01, 1.889e-02, 1.961e-02, -1.071e-02, 4.916e-02, 2.842e-02, 1.106e-02, -5.613e-02, 7.526e-02, -3.772e-01, 6.855e-01, -8.953e-02, -1.550e-01, 7.007e-02, -4.018e-03, 3.450e-01) * s[0][1][1];
	r0 += M4(-2.096e-03, 1.879e+00, -1.941e+00, 2.180e-01, 3.173e-03, 1.135e-01, -3.888e-02, 7.788e-02, 8.465e-02, -4.202e-01, -7.084e-02, -2.382e-01, -2.220e-01, -1.361e-01, -2.005e-01, 3.418e-01) * s[0][2][0];
	r0 += M4(8.987e-02, -3.674e-02, -5.147e-02, -9.173e-02, 4.009e-02, 7.038e-03, -6.443e-02, -1.207e-01, 9.595e-02, -3.663e-01, 5.662e-01, -3.679e-01, -1.665e-01, -2.180e-01, 5.527e-01, 1.547e-02) * s[0][2][1];
	r0 += M4(4.021e+00, -1.617e+00, -6.776e+00, -9.011e-01, 3.595e-02, 1.170e-01, -1.920e-01, -9.445e-02, -3.018e-01, -1.443e-01, -2.350e-01, 3.588e-01, 3.761e-02, -1.181e-01, -4.995e-02, -2.517e-02) * s[1][0][0];
	r0 += M4(2.627e-01, 5.482e-02, -8.811e-02, -2.897e-02, 1.204e-02, 1.154e-01, -4.759e-02, 2.035e-01, -2.611e-01, -2.295e-02, -3.277e-01, 8.131e-01, 1.165e-01, -2.144e-01, 3.949e-02, -2.107e-02) * s[1][0][1];
	r0 += M4(6.635e+00, -3.691e+00, -6.973e+00, -3.235e+00, -2.346e-01, -8.976e-02, 1.577e-01, 1.675e-01, -1.152e-01, 7.050e-01, -2.232e-01, -5.875e-01, -3.838e-01, 2.163e-01, -2.536e-02, 1.938e-01) * s[1][1][0];
	r0 += M4(3.366e-01, 1.182e-02, 4.273e-02, -2.285e-01, -2.880e-01, -1.456e-01, 8.796e-01, 3.080e-01, 1.366e-01, 5.881e-01, -9.700e-03, 9.958e-01, -1.198e-01, 2.627e-01, 1.583e-02, 1.229e+00) * s[1][1][1];
	r0 += M4(-1.149e+00, 3.834e-01, -4.869e+00, -1.389e+00, -3.643e-02, 9.175e-02, -2.784e-03, 1.438e-02, 3.921e-02, 7.418e-02, 4.997e-01, -1.636e-01, 7.131e-01, -3.018e-01, -1.175e+00, -3.561e-01) * s[1][2][0];
	r0 += M4(-3.179e-02, 3.868e-01, -1.045e-02, 1.605e-01, 6.213e-02, -7.608e-03, 2.007e-01, -4.087e-02, -5.275e-02, 5.657e-02, 6.142e-02, 2.753e-02, 2.536e-01, -6.119e-01, 1.861e-01, -4.048e-02) * s[1][2][1];
	r0 += M4(3.664e+00, 2.068e+00, -7.491e+00, 2.696e+00, 3.485e-02, -5.321e-01, -1.234e-03, -3.378e-01, 1.495e-02, 1.005e-01, 8.024e-02, -1.781e-03, -5.392e-03, -3.360e-03, 8.718e-02, 1.026e-02) * s[2][0][0];
	r0 += M4(8.112e-02, -2.047e-01, 2.061e-02, 6.241e-02, -8.626e-03, -3.994e-01, -3.604e-01, 3.586e-01, 8.404e-02, 1.285e-01, -2.699e-02, -1.166e-01, 3.261e-02, 7.642e-02, -1.212e-01, 3.601e-02) * s[2][0][1];
	r0 += M4(5.420e+00, 4.716e-01, -8.087e+00, -1.389e-02, 1.129e-01, 9.667e-02, -2.428e-01, -1.004e-01, -1.395e-02, -3.758e-01, 9.016e-02, 6.073e-02, 3.330e-02, 7.983e-02, 1.119e-01, -5.598e-01) * s[2][1][0];
	r0 += M4(2.612e-01, 4.486e-02, 8.193e-02, 3.241e-02, 3.953e-02, -2.914e-01, -2.992e-02, 2.687e-01, 1.409e-01, -5.967e-01, -1.485e-02, -6.016e-02, 2.223e-02, 1.322e-01, 3.552e-02, -4.161e-02) * s[2][1][1];
	r0 += M4(1.304e-01, 1.446e+00, -2.534e+00, 1.942e-01, -1.186e-02, -1.677e-01, -8.748e-03, -1.426e-04, 1.025e-02, 1.831e-01, 2.689e-02, -4.639e-02, 7.105e-03, -8.085e-03, 2.146e-01, -2.154e-01) * s[2][2][0];
	r0 += M4(-5.603e-02, -1.732e-01, -3.919e-02, 1.488e-02, 4.331e-02, -2.725e-01, 6.113e-02, -1.063e-01, 6.183e-02, 1.990e-01, -2.034e-01, -5.897e-02, -2.388e-02, -2.919e-01, 1.433e-01, -1.699e-01) * s[2][2][1];
	r0 += V4(6.755e-01, -1.255e-02, 1.923e-02, 3.136e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-DS-conv2
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
#define l0(x, y) V4(conv1_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv1_pt))
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
	r0 += M4(-2.268e-02, -1.996e-02, 6.137e-02, -5.622e-02, -4.781e-03, -1.667e-02, 7.884e-03, 8.569e-02, 2.280e-01, -1.192e-01, -1.467e-01, -3.517e-02, 3.254e-01, -1.649e-02, -2.226e-01, -1.563e-01) * s[0][0][0];
	r0 += M4(-4.772e-02, 6.147e-01, 4.240e-01, 8.768e-01, 3.957e-01, 1.248e-01, -1.968e-01, 2.425e-01, -5.287e-02, 7.069e-03, 1.672e-01, -9.519e-02, -9.595e-02, -8.473e-02, 1.100e-02, -1.010e-01) * s[0][0][1];
	r0 += M4(6.687e-02, -1.102e-02, -2.569e-02, -1.058e-01, -5.192e-02, -2.764e-01, 3.355e-02, -8.764e-02, 2.819e-01, -7.340e-02, 3.771e-02, -1.438e-02, 4.377e-01, 2.544e-01, -2.607e-01, 8.410e-02) * s[0][1][0];
	r0 += M4(-8.399e-01, 7.989e-01, -1.390e+00, 1.304e+00, 1.904e-01, -6.297e-02, 1.612e-01, -3.492e-02, -2.996e-02, -4.985e-02, 5.868e-02, -2.215e-02, 8.669e-02, 4.086e-02, -4.306e-01, 2.405e-01) * s[0][1][1];
	r0 += M4(-1.423e-02, 5.899e-02, -5.286e-02, 1.675e-01, -7.202e-02, -1.130e-01, 5.689e-02, -1.475e-02, -1.290e-01, -1.073e-01, -1.715e-02, -4.597e-02, 9.640e-02, 1.467e-01, 1.584e-02, 1.150e-01) * s[0][2][0];
	r0 += M4(1.073e+00, 9.168e-01, -9.540e-01, 4.406e-01, 3.764e-02, 9.307e-02, 7.056e-04, 1.504e-01, 3.723e-02, 4.113e-02, 2.338e-02, -1.372e-02, -2.253e-02, 1.448e-02, -1.270e-01, 4.309e-02) * s[0][2][1];
	r0 += M4(4.141e-02, 5.416e-02, -5.464e-02, -1.909e-01, 7.048e-02, -2.900e-01, -5.332e-01, -3.984e-01, 3.486e-01, 2.753e-01, -9.706e-02, 2.780e-01, 3.983e-01, 1.401e-01, 5.293e-02, 2.585e-01) * s[1][0][0];
	r0 += M4(-9.087e-01, 9.609e-01, -1.114e+00, 2.265e+00, 2.624e-01, 6.412e-02, -1.167e-01, -5.817e-02, 1.894e-01, 3.473e-02, -2.546e-01, -1.012e-01, -9.751e-02, 4.587e-02, 2.104e-02, 7.007e-02) * s[1][0][1];
	r0 += M4(-6.557e-02, -1.215e-01, -3.942e-02, 2.950e-01, 2.410e-02, 2.875e-02, 4.813e-01, -2.263e-01, 3.858e-01, 3.663e-01, -3.536e-01, -2.066e-02, 5.260e-01, 4.994e-01, -4.671e-01, 5.856e-01) * s[1][1][0];
	r0 += M4(-1.443e+00, -4.163e+00, -3.242e+00, 3.466e+00, -1.058e-01, 5.195e-02, 1.212e-01, -3.024e-01, -5.692e-02, -2.095e-01, 2.380e-01, -2.446e-01, 1.382e-01, -1.294e-01, 6.387e-01, 1.228e-01) * s[1][1][1];
	r0 += M4(3.814e-03, 3.407e-02, 2.904e-03, -1.614e-01, -9.882e-02, -1.878e-02, 1.310e-02, 9.057e-02, -1.694e-01, 2.074e-03, 2.015e-01, 2.139e-02, 4.069e-02, 1.284e-01, 1.814e-01, -1.710e-01) * s[1][2][0];
	r0 += M4(6.755e-01, 3.391e-01, -2.140e+00, 1.072e+00, -3.540e-02, 2.001e-01, 3.405e-02, 1.130e-01, 2.996e-02, -2.507e-03, -1.212e-01, 2.601e-02, -7.397e-02, -2.244e-04, -2.165e-02, -4.993e-02) * s[1][2][1];
	r0 += M4(1.138e-02, 2.137e-02, -5.896e-02, 3.361e-02, -1.052e-01, -1.498e-01, -6.109e-02, -1.032e-01, 1.653e-01, 1.501e-01, 2.263e-02, -2.106e-02, -8.102e-02, -6.318e-02, 8.078e-02, -1.019e-01) * s[2][0][0];
	r0 += M4(8.758e-01, 1.143e+00, 6.421e-02, 1.491e+00, 1.062e-01, 1.980e-01, -4.202e-02, 4.951e-02, -4.429e-02, -4.459e-03, 1.989e-02, 9.651e-02, 2.142e-02, -6.700e-02, 1.350e-02, -1.450e-03) * s[2][0][1];
	r0 += M4(-3.577e-02, 4.729e-02, 1.313e-01, 1.074e-02, -1.909e-01, 2.075e-01, -1.093e-01, -5.718e-02, 7.751e-02, 4.707e-01, 3.393e-01, 1.584e-01, -7.202e-02, 4.635e-01, 3.538e-01, -3.508e-02) * s[2][1][0];
	r0 += M4(1.101e+00, -2.261e+00, -2.247e+00, 2.191e+00, -1.408e-02, 1.676e-01, 3.078e-02, -3.790e-02, -7.054e-02, 1.294e-01, 2.663e-01, 5.245e-02, 3.073e-02, -3.971e-02, -1.284e-01, 5.075e-02) * s[2][1][1];
	r0 += M4(3.857e-02, -3.235e-02, 3.446e-02, 1.636e-02, 4.164e-02, -1.939e-02, -7.679e-02, 5.443e-02, 7.868e-03, 6.996e-02, -9.675e-03, 5.363e-02, -1.043e-01, -1.832e-02, 8.267e-02, -4.170e-03) * s[2][2][0];
	r0 += M4(4.519e-01, 2.992e-01, -1.070e-01, 7.238e-01, 4.942e-02, 9.561e-02, -4.705e-02, 9.528e-02, 5.801e-03, -4.857e-02, 7.203e-02, -1.376e-02, -4.039e-02, 1.025e-02, 1.096e-01, -5.605e-02) * s[2][2][1];
	r0 += V4(-1.083e-02, -2.665e-03, -3.122e-02, 3.253e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-2x4C-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv2
//!BIND easu
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
#define l0(x, y) V4(conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * conv2_pt))
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
	r0 += M4(-3.478e-02, -1.849e-02, -2.433e-02, -7.748e-03, 7.406e-03, -1.053e-02, 1.209e-02, 6.685e-04, -9.897e-03, -2.156e-03, 5.418e-02, 1.562e-02, -8.614e-03, 1.739e-02, 4.326e-02, 5.536e-03) * s[0][0][0];
	r0 += M4(-1.146e-02, 4.236e-02, 3.894e-02, 9.961e-03, 1.687e-02, -1.333e-01, -1.772e-01, 4.090e-03, -7.785e-03, -9.611e-03, 9.142e-03, 3.464e-03, 4.965e-02, -2.637e-02, 1.680e-02, -3.429e-02) * s[0][0][1];
	r0 += M4(6.958e-02, 4.533e-02, 2.826e-02, 5.359e-03, -2.376e-02, -3.743e-02, -1.489e-02, -6.029e-03, -1.530e-02, -2.535e-02, 6.274e-02, 9.546e-02, -2.032e-02, -3.679e-02, 4.871e-02, 6.805e-02) * s[0][1][0];
	r0 += M4(-1.036e-01, -1.324e-01, 8.445e-02, 5.506e-02, 1.443e-01, 6.619e-01, -3.037e-01, -1.421e-01, 2.670e-02, 6.315e-02, 1.274e-02, 9.486e-03, -1.655e-01, -1.745e-02, 1.304e-01, 1.052e-01) * s[0][1][1];
	r0 += M4(-3.756e-02, -1.378e-02, -1.889e-02, -4.668e-03, 3.251e-02, 3.910e-02, -5.936e-03, -1.095e-02, 3.899e-03, -5.047e-05, -6.853e-03, 1.129e-02, -3.126e-03, -1.846e-02, 1.972e-02, 3.509e-02) * s[0][2][0];
	r0 += M4(-7.788e-02, -1.247e-01, 2.976e-02, 7.217e-02, 8.590e-02, -2.421e-01, 1.081e-01, -1.898e-01, 2.067e-02, 2.957e-03, 5.885e-03, 2.619e-02, 5.943e-02, -3.943e-03, -7.049e-03, 9.796e-02) * s[0][2][1];
	r0 += M4(5.847e-02, -1.109e-02, 3.085e-02, -1.086e-02, 3.128e-02, -8.925e-03, 1.649e-02, -1.115e-02, 9.495e-02, 1.775e-03, -6.033e-03, -2.726e-02, -2.564e-02, -4.069e-03, -7.294e-02, -1.870e-02) * s[1][0][0];
	r0 += M4(-6.352e-02, 1.913e-01, -1.274e-01, 7.352e-02, -1.460e-01, -8.081e-02, 2.269e-01, -1.112e-01, 8.092e-03, -4.775e-02, 4.334e-02, -3.636e-02, 1.095e-01, -1.934e-02, 6.298e-02, -3.062e-02) * s[1][0][1];
	r0 += M4(-3.451e-03, 1.608e-01, 4.067e-02, 1.270e-01, -8.322e-03, 8.955e-03, -2.907e-02, -8.370e-03, 3.564e-01, 3.955e-01, 3.720e-02, 1.016e-02, -3.269e-02, -3.894e-02, -5.417e-02, -9.273e-02) * s[1][1][0];
	r0 += M4(1.043e+00, -3.608e-02, 1.607e-01, -3.157e-01, -5.398e-01, -3.191e-01, 3.858e-01, 9.165e-01, 1.172e-01, 2.124e-01, 1.519e-01, 2.885e-01, -3.565e-01, 2.385e-02, -7.598e-01, -2.133e-01) * s[1][1][1];
	r0 += M4(3.269e-02, -5.005e-02, -7.079e-03, -3.721e-02, 1.262e-02, 4.688e-02, 4.358e-02, 3.920e-02, -8.133e-02, -4.297e-02, -5.998e-02, -1.955e-02, -6.078e-02, -1.261e-01, -5.852e-02, -1.143e-01) * s[1][2][0];
	r0 += M4(-2.252e-01, 5.137e-01, -2.054e-01, -2.805e-02, 6.179e-02, -1.978e-01, 1.401e-01, -3.106e-02, -2.484e-02, -6.372e-02, -2.058e-02, -6.763e-02, 7.692e-02, -1.675e-01, 4.841e-02, -3.858e-01) * s[1][2][1];
	r0 += M4(-5.631e-02, 4.093e-03, -1.507e-02, 1.315e-02, -9.895e-03, -1.715e-02, -1.793e-02, -4.163e-02, -6.799e-02, 3.263e-02, -6.914e-02, 1.333e-03, 2.337e-02, -7.174e-03, 1.825e-02, 2.007e-02) * s[2][0][0];
	r0 += M4(-9.741e-02, 8.918e-02, -1.265e-01, 1.948e-01, 1.063e-01, -4.466e-03, -4.032e-02, -5.110e-02, 1.338e-02, -3.187e-03, -1.333e-02, -1.096e-02, -4.166e-02, 1.602e-02, 1.691e-03, 4.773e-03) * s[2][0][1];
	r0 += M4(2.655e-02, -2.825e-02, 3.009e-02, 5.941e-02, -2.723e-04, -4.956e-04, 6.066e-03, -2.408e-02, -5.697e-02, -1.106e-01, 7.624e-02, 1.055e-01, 1.045e-02, 1.854e-02, -4.480e-02, -3.870e-02) * s[2][1][0];
	r0 += M4(-7.221e-02, -3.670e-01, 5.958e-01, -3.205e-01, 1.581e-01, 1.554e-01, -2.413e-01, -2.646e-01, 1.696e-02, 2.624e-02, 9.931e-03, 2.973e-02, -7.869e-03, -2.359e-02, 4.728e-02, 7.543e-02) * s[2][1][1];
	r0 += M4(-4.498e-02, -3.335e-02, -1.280e-02, -4.432e-02, -4.500e-03, -1.087e-02, -1.671e-02, 2.702e-02, 4.922e-03, -6.114e-02, -2.983e-02, -1.318e-01, 1.495e-02, 3.196e-02, -3.915e-03, -3.429e-02) * s[2][2][0];
	r0 += M4(-9.745e-02, -6.844e-02, -2.780e-01, 2.338e-01, -3.801e-03, 1.061e-01, -1.013e-02, 3.364e-03, -1.666e-02, -1.226e-02, -1.335e-02, -4.340e-02, -2.559e-02, -2.777e-02, 2.984e-02, 4.603e-02) * s[2][2][1];
	r0 += V4(5.829e-03, 7.264e-03, 7.365e-03, 8.823e-03);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

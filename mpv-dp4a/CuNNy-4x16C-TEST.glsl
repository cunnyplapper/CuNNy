// CuNNy 4x16C TEST
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

//!DESC CuNNy-4x16C-TEST-EASU
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


//!DESC CuNNy-4x16C-TEST-in
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!SAVE in
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
#define l0(x, y) F(LUMA_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * LUMA_pt).r)
shared F g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
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
	V4 r1 = V4(0.0);
	V4 r2 = V4(0.0);
	V4 r3 = V4(0.0);
	s[0][0][0] = g[0][xy.y+0][xy.x+0];
	s[0][1][0] = g[0][xy.y+0][xy.x+1];
	s[0][2][0] = g[0][xy.y+0][xy.x+2];
	s[1][0][0] = g[0][xy.y+1][xy.x+0];
	s[1][1][0] = g[0][xy.y+1][xy.x+1];
	s[1][2][0] = g[0][xy.y+1][xy.x+2];
	s[2][0][0] = g[0][xy.y+2][xy.x+0];
	s[2][1][0] = g[0][xy.y+2][xy.x+1];
	s[2][2][0] = g[0][xy.y+2][xy.x+2];
	r0 += V4(5.651e-02, -2.604e-01, 4.914e-03, 1.941e-01) * s[0][0][0];
	r1 += V4(-1.720e-02, 1.548e-01, -2.457e-02, 4.914e-03) * s[0][0][0];
	r2 += V4(-1.032e-01, 4.668e-02, -7.371e-03, -1.966e-02) * s[0][0][0];
	r3 += V4(2.457e-02, -5.897e-02, 3.440e-02, -1.548e-01) * s[0][0][0];
	r0 += V4(1.376e-01, 2.555e-01, 5.651e-02, 2.457e-03) * s[0][1][0];
	r1 += V4(2.703e-02, -1.646e-01, 3.440e-02, -3.686e-02) * s[0][1][0];
	r2 += V4(2.457e-03, -6.143e-02, -6.634e-02, 1.916e-01) * s[0][1][0];
	r3 += V4(1.966e-02, -9.828e-03, -1.179e-01, .0) * s[0][1][0];
	r0 += V4(-9.828e-03, 4.914e-03, .0, -7.371e-03) * s[0][2][0];
	r1 += V4(-3.931e-02, 4.177e-02, 2.948e-02, 2.457e-03) * s[0][2][0];
	r2 += V4(5.897e-02, -1.597e-01, -7.371e-02, 7.371e-02) * s[0][2][0];
	r3 += V4(-1.597e-01, -6.143e-02, 4.177e-02, -8.600e-02) * s[0][2][0];
	r0 += V4(-5.405e-02, -1.597e-01, -5.160e-02, -1.695e-01) * s[1][0][0];
	r1 += V4(8.354e-02, 5.651e-02, -7.371e-03, 4.914e-03) * s[1][0][0];
	r2 += V4(2.432e-01, -1.474e-02, 3.931e-02, -1.130e-01) * s[1][0][0];
	r3 += V4(-1.229e-02, 2.211e-02, -5.160e-02, -8.600e-02) * s[1][0][0];
	r0 += V4(7.371e-02, 1.744e-01, -1.327e-01, -8.108e-02) * s[1][1][0];
	r1 += V4(-1.204e-01, 1.106e-01, -4.177e-02, -1.597e-01) * s[1][1][0];
	r2 += V4(-1.966e-02, -1.425e-01, -6.880e-02, 6.880e-02) * s[1][1][0];
	r3 += V4(-1.523e-01, 1.499e-01, 3.636e-01, 7.125e-02) * s[1][1][0];
	r0 += V4(7.371e-03, -1.474e-02, -9.582e-02, -2.457e-03) * s[1][2][0];
	r1 += V4(1.130e-01, 4.668e-02, 2.383e-01, -1.990e-01) * s[1][2][0];
	r2 += V4(-2.015e-01, -4.914e-03, 1.425e-01, -7.617e-02) * s[1][2][0];
	r3 += V4(1.474e-01, -2.457e-02, -1.253e-01, 1.450e-01) * s[1][2][0];
	r0 += V4(2.703e-02, 1.229e-02, 6.388e-02, -1.966e-02) * s[2][0][0];
	r1 += V4(1.474e-02, -2.064e-01, 1.179e-01, 2.457e-03) * s[2][0][0];
	r2 += V4(1.966e-02, -3.931e-02, -1.966e-02, -5.651e-02) * s[2][0][0];
	r3 += V4(9.828e-03, 4.423e-02, -5.405e-02, 5.160e-02) * s[2][0][0];
	r0 += V4(-2.211e-02, -1.966e-02, 1.351e-01, 6.388e-02) * s[2][1][0];
	r1 += V4(-2.457e-02, 5.897e-02, -1.278e-01, 3.563e-01) * s[2][1][0];
	r2 += V4(-1.966e-02, 2.703e-02, -8.108e-02, -4.914e-02) * s[2][1][0];
	r3 += V4(-8.354e-02, -4.914e-03, -7.371e-03, -4.914e-02) * s[2][1][0];
	r0 += V4(-4.914e-03, 9.828e-03, 3.194e-02, 7.371e-03) * s[2][2][0];
	r1 += V4(1.229e-02, -8.354e-02, -2.260e-01, 2.703e-02) * s[2][2][0];
	r2 += V4(1.474e-02, 3.514e-01, 4.914e-03, -1.229e-02) * s[2][2][0];
	r3 += V4(-1.081e-01, -2.211e-02, -6.634e-02, -4.914e-03) * s[2][2][0];
	r0 += V4(-3.308e-02, 8.818e-04, 6.276e-03, -1.565e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(-2.199e-04, -1.800e-02, -8.715e-03, -3.716e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
	r2 += V4(8.099e-03, 1.897e-03, 4.831e-02, -1.352e-02);
	imageStore(out_image, opos + ivec2(0, 1), vec4(r2));
	r3 += V4(3.752e-03, -1.005e-03, 4.432e-04, 2.664e-02);
	imageStore(out_image, opos + ivec2(1, 1), vec4(r3));
}

//!DESC CuNNy-4x16C-TEST-conv1
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND in
//!BIND LUMA
//!SAVE conv1
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[8][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * in_pt;
			r = in_gather(p, 0);
			g = in_gather(p, 1);
			b = in_gather(p, 2);
			a = in_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v2 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v4 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v6 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			vec4 v5 = max(-v4, vec4(0));
			v4 = max(v4, vec4(0));
			vec4 v7 = max(-v6, vec4(0));
			v6 = max(v6, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
			G[4][ay][ax] = int(packSnorm4x8(v4));
			G[5][ay][ax] = int(packSnorm4x8(v5));
			G[6][ay][ax] = int(packSnorm4x8(v6));
			G[7][ay][ax] = int(packSnorm4x8(v7));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x03FEFD05, 0x23FAFDFA, 0x0DFB05FB, 0xF203020B);
	r1 = D(r1, s[0][0][0], 0x180200F6, 0x050602FD, 0xE7FA05FE, 0x0800F802);
	r2 = D(r2, s[0][0][0], 0xDFFE00FB, 0x23FD0203, 0x0E06000D, 0xE8020A15);
	r3 = D(r3, s[0][0][0], 0xF6FEF603, 0x1D030E06, 0x03F20502, 0x0A02F8F6);
	r0 = D(r0, s[0][0][1], 0x060DF8FE, 0xE8FBFBEA, 0xEDF3F8F8, 0x08FA0006);
	r1 = D(r1, s[0][0][1], 0x0BF60002, 0x0EF80502, 0xEDEB0D0D, 0x15EAFE06);
	r2 = D(r2, s[0][0][1], 0xFA06FD02, 0x0BFD0B0A, 0xEF10FAFB, 0xFEFD0A02);
	r3 = D(r3, s[0][0][1], 0xEAED02F8, 0x1E03110A, 0x18050306, 0x2106030A);
	r0 = D(r0, s[0][0][2], 0x260EFE0D, 0x2310F60A, 0x00030605, 0x08FA05FE);
	r1 = D(r1, s[0][0][2], 0xF80B08F8, 0x02FA0EFE, 0xF202F6FE, 0xD000F306);
	r2 = D(r2, s[0][0][2], 0x030A11F0, 0xE20AFAFE, 0x0D0DEF05, 0xE3FA1EFE);
	r3 = D(r3, s[0][0][2], 0x03F60300, 0x060816F3, 0xDFFAED13, 0xF5FD00FE);
	r0 = D(r0, s[0][1][0], 0x0302FBF6, 0x00FBF603, 0x16020BFA, 0xF6EF0502);
	r1 = D(r1, s[0][1][0], 0x13FB0303, 0x0805080A, 0xF5FEF8FB, 0x0DF8FEFE);
	r2 = D(r2, s[0][1][0], 0xE30EFA05, 0x08F01502, 0x0EF303FB, 0xE00AFE08);
	r3 = D(r3, s[0][1][0], 0xF3160505, 0x03F6E3FB, 0xF208F8FB, 0x03F8FD06);
	r0 = D(r0, s[0][1][1], 0x08FE10F5, 0xFAFBFE00, 0xF30A0602, 0x1B0305FB);
	r1 = D(r1, s[0][1][1], 0x02FD190A, 0xEF00FA03, 0xEBFE1108, 0x0306F30D);
	r2 = D(r2, s[0][1][1], 0x0EF20EF6, 0x1D000AFA, 0x0BF5FD05, 0xF20E0BEB);
	r3 = D(r3, s[0][1][1], 0xF30B0802, 0x2BF50500, 0x0BFB0D03, 0x0B02FA00);
	r0 = D(r0, s[0][1][2], 0x100323F2, 0x0D000A0A, 0x020E1B02, 0x0D000300);
	r1 = D(r1, s[0][1][2], 0x0AFE1603, 0x16FBF50E, 0xF0EAE3F8, 0xF603E2FB);
	r2 = D(r2, s[0][1][2], 0x00F0E0ED, 0x280D13FE, 0xF3001DF6, 0x24052003);
	r3 = D(r3, s[0][1][2], 0x1800F5FE, 0x13EDED06, 0xE7F5FAF0, 0xED05130A);
	r0 = D(r0, s[0][2][0], 0xE5F6F306, 0xEF08F8F3, 0x0306F506, 0x0B0D000E);
	r1 = D(r1, s[0][2][0], 0x18FDFEFB, 0xFB00F508, 0x100E00FB, 0x0A0DF600);
	r2 = D(r2, s[0][2][0], 0xEAFE0200, 0x0806F80D, 0x0EFB0500, 0x05F802FE);
	r3 = D(r3, s[0][2][0], 0xE5051106, 0xFEFEF20A, 0x0BFBF3FB, 0xE30805F8);
	r0 = D(r0, s[0][2][1], 0x29FD0D00, 0xF30803F6, 0x03FA0D02, 0x190AED23);
	r1 = D(r1, s[0][2][1], 0x00061D00, 0x1DFD1E02, 0x0E06EDFE, 0x0E062102);
	r2 = D(r2, s[0][2][1], 0xEF10F30B, 0xF80508FB, 0x1BFA1D03, 0x28000EFB);
	r3 = D(r3, s[0][2][1], 0x05FBFAF8, 0x21061BFE, 0x0E10FB02, 0x00FDF2EF);
	r0 = D(r0, s[0][2][2], 0xEF032E00, 0x110E0002, 0x00F002FB, 0x06FBF602);
	r1 = D(r1, s[0][2][2], 0x08FE24FE, 0xEF11F000, 0xC40BD0FB, 0xF30013FA);
	r2 = D(r2, s[0][2][2], 0x1DFD150B, 0x02FE02FB, 0xED1103F8, 0xF6F623F6);
	r3 = D(r3, s[0][2][2], 0x2E080AF3, 0xD8150500, 0xB20A1DFD, 0xC4F819EF);
	r0 = D(r0, s[1][0][0], 0xF5F3FDFB, 0xFA10FE03, 0x06130305, 0x0EFB03FE);
	r1 = D(r1, s[1][0][0], 0x02EF0013, 0xFD030010, 0x08FAFB16, 0x08DD0624);
	r2 = D(r2, s[1][0][0], 0xFD0AFD00, 0x060803FA, 0xFE1D0306, 0xFA0EFD06);
	r3 = D(r3, s[1][0][0], 0xFAD800FE, 0x05100605, 0xF5150BFA, 0xF8EF03EF);
	r0 = D(r0, s[1][0][1], 0xFD02F820, 0x08F50A18, 0x00F60B0D, 0xFDF6030A);
	r1 = D(r1, s[1][0][1], 0xF5ED0503, 0xFA08F8FA, 0x11E203EF, 0x10F8F6DD);
	r2 = D(r2, s[1][0][1], 0x03EB02FB, 0x0BE8F6F2, 0x03EAFD10, 0x08160808);
	r3 = D(r3, s[1][0][1], 0x06EDF6F6, 0x0E030E11, 0x0E11FAD7, 0xF50D05E8);
	r0 = D(r0, s[1][0][2], 0xFB0EFDE3, 0xFE08FBDD, 0x06FDF205, 0x1B08F6FB);
	r1 = D(r1, s[1][0][2], 0xFD03082E, 0xFE11F8FE, 0x080613ED, 0x0013FAF0);
	r2 = D(r2, s[1][0][2], 0x0819F61B, 0x0B00F308, 0x03EF03EB, 0x08FE0603);
	r3 = D(r3, s[1][0][2], 0xFB15F816, 0xF2EA0BEF, 0x050600F6, 0xFB20FDF8);
	r0 = D(r0, s[1][1][0], 0xED0D0A19, 0x0B101919, 0xEFF3EBFA, 0x0303F20E);
	r1 = D(r1, s[1][1][0], 0xFDEDF803, 0xFEF8F618, 0x111DF6EA, 0xFAED10D5);
	r2 = D(r2, s[1][1][0], 0x030D1308, 0x06DF02EB, 0x0AF3F621, 0x02EA11DA);
	r3 = D(r3, s[1][1][0], 0x0B0EFA13, 0xF605FD06, 0xFB020B2B, 0x1005FAED);
	r0 = D(r0, s[1][1][1], 0xF8E51305, 0xFB130223, 0x02FA1DED, 0xEDF2023C);
	r1 = D(r1, s[1][1][1], 0x00F615DC, 0x0D0B1905, 0x0DF011E3, 0xFBEFD79E);
	r2 = D(r2, s[1][1][1], 0x02E8FAF0, 0x0210212E, 0x130A0803, 0x03003711);
	r3 = D(r3, s[1][1][1], 0x100302EF, 0xF5061E41, 0x16FDFAB7, 0x0DE2E3DA);
	r0 = D(r0, s[1][1][2], 0x0B080610, 0x0202FAED, 0xFB02F8EA, 0x03EBEF03);
	r1 = D(r1, s[1][1][2], 0x11000E0A, 0x02EF0E1D, 0xFAEF1529, 0xFAFDF00D);
	r2 = D(r2, s[1][1][2], 0xFBF50623, 0xFD18FBD4, 0x0B230619, 0xEFE723FB);
	r3 = D(r3, s[1][1][2], 0xFD0B1337, 0x08E2FA2C, 0xEB10F205, 0x0008EAD5);
	r0 = D(r0, s[1][2][0], 0x050205E8, 0x05F3FBFA, 0x0E03FDF0, 0x05000A1B);
	r1 = D(r1, s[1][2][0], 0xFBEFF5FA, 0xFB050821, 0xF0F20623, 0x05050208);
	r2 = D(r2, s[1][2][0], 0xF6050208, 0x03031B10, 0xFDFDFBE2, 0x00FE06F8);
	r3 = D(r3, s[1][2][0], 0x0EF0F50A, 0xFA00E0FE, 0xFB020B34, 0xFE0DFEF8);
	r0 = D(r0, s[1][2][1], 0xFE00FE03, 0x00100AFD, 0xFBF3314E, 0x0D100A6F);
	r1 = D(r1, s[1][2][1], 0xF0F3F2E5, 0x0002EAFE, 0xEDFDEB0A, 0xFBDD1636);
	r2 = D(r2, s[1][2][1], 0xEF00F60D, 0xF82316CF, 0x11FB0DD2, 0x10F62B16);
	r3 = D(r3, s[1][2][1], 0xFA2C03CD, 0x0328FDD5, 0x1E0E0603, 0x11E5EB61);
	r0 = D(r0, s[1][2][2], 0x1D200BFD, 0xF2F8FE02, 0x180A0B15, 0xF5020229);
	r1 = D(r1, s[1][2][2], 0x081137EA, 0x06FE131E, 0xE2FACF02, 0x00082E56);
	r2 = D(r2, s[1][2][2], 0x031B06F5, 0x1037F61E, 0xE0FE0AFA, 0x00082319);
	r3 = D(r3, s[1][2][2], 0x08030854, 0x162C1BAF, 0xF011DD0B, 0x05111D19);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x1320F0F5, 0xFB1605F8, 0x10EAFA0A, 0x0AFE0A10);
	r1 = D(r1, s[0][0][0], 0xF60EED02, 0xF5050303, 0x0ED2F605, 0xF0F8F503);
	r2 = D(r2, s[0][0][0], 0x06F31306, 0xE0EBFBEF, 0xF205EF05, 0x19E50D05);
	r3 = D(r3, s[0][0][0], 0xFDDDEAF3, 0x210D00FE, 0x0E0A16FD, 0xEA02FB16);
	r0 = D(r0, s[0][0][1], 0x06150003, 0xE0290008, 0xFDD7F002, 0xF3FEFA0B);
	r1 = D(r1, s[0][0][1], 0x0B0BF602, 0x0DF603FA, 0xFDE71DF5, 0xF50ECD02);
	r2 = D(r2, s[0][0][1], 0x0A0D1E0E, 0xC4ED0002, 0x00EF0DFB, 0xFDFA10FB);
	r3 = D(r3, s[0][0][1], 0x0610EDED, 0x0D1800FA, 0x132108FD, 0xF6E2F803);
	r0 = D(r0, s[0][0][2], 0x08E8060E, 0x00101BF6, 0x05FA0B02, 0xFDFE0302);
	r1 = D(r1, s[0][0][2], 0xF21105FB, 0x000B0A03, 0xF502E808, 0xF519DFF0);
	r2 = D(r2, s[0][0][2], 0x0EE5FBFA, 0xFA02EAFB, 0x0B0508FD, 0x03E50D05);
	r3 = D(r3, s[0][0][2], 0xEAED02FE, 0x0AD8060A, 0xF019DAFA, 0x05FBFB02);
	r0 = D(r0, s[0][1][0], 0x26F3F6F5, 0x03020310, 0x02F2FAFB, 0x0AFDFD02);
	r1 = D(r1, s[0][1][0], 0xF60AEAF2, 0x0006FE0B, 0x06FB05EF, 0xFB0000FD);
	r2 = D(r2, s[0][1][0], 0x1DFA08EB, 0xF6D50A0B, 0x0BFBFEF2, 0x2BE506F6);
	r3 = D(r3, s[0][1][0], 0xEF00FE03, 0x0605ED03, 0x0AFBF619, 0xE003F5FA);
	r0 = D(r0, s[0][1][1], 0x3FF8F2F2, 0x1BEBFA06, 0x26080D19, 0x020ADC0D);
	r1 = D(r1, s[0][1][1], 0x101B13F6, 0x15100300, 0xDCEAFD06, 0x080DF3F6);
	r2 = D(r2, s[0][1][1], 0x1DFD0B10, 0xD0020210, 0xC7ED06FE, 0x20FEFB11);
	r3 = D(r3, s[0][1][1], 0x00ED08F6, 0x13CC1000, 0x06101110, 0xE5E5FA02);
	r0 = D(r0, s[0][1][2], 0x0BE3FB05, 0xFE0810FB, 0xFE08FBF3, 0xFD0EFE05);
	r1 = D(r1, s[0][1][2], 0x02080506, 0x00F8F6FB, 0x0503F602, 0x1506E30E);
	r2 = D(r2, s[0][1][2], 0x0D0D080E, 0xE800FA00, 0x030A00FE, 0x0DFAEA00);
	r3 = D(r3, s[0][1][2], 0x0DF6ED10, 0xFB080E0D, 0xF503F0F2, 0xF3F600FE);
	r0 = D(r0, s[0][2][0], 0x0EF3FE08, 0x06FD0300, 0x0E02F805, 0x08080308);
	r1 = D(r1, s[0][2][0], 0xE2EDFB08, 0x02FBFB03, 0xF5FBF503, 0xFBF50006);
	r2 = D(r2, s[0][2][0], 0xF5FA03F3, 0x00E8110B, 0x06F60315, 0x0DF3F8F5);
	r3 = D(r3, s[0][2][0], 0xE5E7FA08, 0xFD06EF00, 0x13ED0A00, 0x10FB02FD);
	r0 = D(r0, s[0][2][1], 0x11E0EB02, 0x00F60DFD, 0xFE1016F8, 0x0AFA0605);
	r1 = D(r1, s[0][2][1], 0xEF06150B, 0xF60506F8, 0xFA030D06, 0xFB02FAFE);
	r2 = D(r2, s[0][2][1], 0xFBFDF302, 0xF3EA0DFB, 0x18FAEF0D, 0xF6F60302);
	r3 = D(r3, s[0][2][1], 0xFDFD0206, 0xE80EEDEF, 0x190AFEF6, 0x16F5FA02);
	r0 = D(r0, s[0][2][2], 0xF8EBDA08, 0xF6FB06FB, 0x0AEF0E02, 0xFB0000FB);
	r1 = D(r1, s[0][2][2], 0xF6F50BF8, 0xFBED0603, 0x0D080A00, 0xF60A0508);
	r2 = D(r2, s[0][2][2], 0xF30BF300, 0xF3FB06F8, 0x0B03EAFA, 0xF50A00FE);
	r3 = D(r3, s[0][2][2], 0xF605F806, 0x08F8FE03, 0x1508D000, 0x020AEB03);
	r0 = D(r0, s[1][0][0], 0x28FEFBF2, 0xFA0B0BF6, 0x02F0FDC9, 0xFA06FD23);
	r1 = D(r1, s[1][0][0], 0x08FD00FE, 0xFDF800FE, 0x29F2F347, 0xFB02F806);
	r2 = D(r2, s[1][0][0], 0x06FBFAD4, 0x00030E30, 0xFEFD08D8, 0x00F8FA26);
	r3 = D(r3, s[1][0][0], 0x08080BF0, 0x1113084C, 0x180313FE, 0x0A0805EA);
	r0 = D(r0, s[1][0][1], 0x0D1106E2, 0xF00502EA, 0x1EFA0519, 0x080B030D);
	r1 = D(r1, s[1][0][1], 0xF50502E0, 0x03000033, 0x34F2EB47, 0x03F3F23F);
	r2 = D(r2, s[1][0][1], 0x1D060D43, 0xF5020608, 0xD5FEFE05, 0x21F0F50B);
	r3 = D(r3, s[1][0][1], 0xC415EDFA, 0xFB19EDB9, 0x0D0DFD02, 0x05F60506);
	r0 = D(r0, s[1][0][2], 0xFEF2F3F5, 0xF2F5FB1B, 0x06FDFA03, 0xF808FA02);
	r1 = D(r1, s[1][0][2], 0xF20200E2, 0xF0FEF806, 0x02FBFBFE, 0x10F6F211);
	r2 = D(r2, s[1][0][2], 0x0B0A0A15, 0xE8EDF6EB, 0x03031624, 0x20F30DFD);
	r3 = D(r3, s[1][0][2], 0x0E03DD39, 0xF5030215, 0xED06F3FD, 0xF502F8FD);
	r0 = D(r0, s[1][1][0], 0x06FEF52E, 0x02050830, 0x03131313, 0xEF02001E);
	r1 = D(r1, s[1][1][0], 0x0A03FAD4, 0x0306FD08, 0x0505EBEF, 0x02FA0210);
	r2 = D(r2, s[1][1][0], 0x0BF2FBBA, 0x0A08060A, 0x1DFAFBFD, 0x1D05FDD2);
	r3 = D(r3, s[1][1][0], 0xF3F0E502, 0xF5F60A33, 0xF0F50BED, 0xF2F5FE19);
	r0 = D(r0, s[1][1][1], 0x2BF303EA, 0xFE03FDAF, 0x0B001DCD, 0x0EF20E18);
	r1 = D(r1, s[1][1][1], 0x1905FD0E, 0x0BE50500, 0x00F8F2D2, 0x31160AFD);
	r2 = D(r2, s[1][1][1], 0x20060E31, 0xDDFE0A19, 0x020AE26A, 0x0BF508D7);
	r3 = D(r3, s[1][1][1], 0x050D0347, 0xEADFF6CF, 0x21FD0DE3, 0xFE0A00E3);
	r0 = D(r0, s[1][1][2], 0x08050249, 0xF0FB083E, 0x00F6050A, 0x08F80506);
	r1 = D(r1, s[1][1][2], 0xF00EFDED, 0x060E0ACF, 0x10020B16, 0xFB0AF318);
	r2 = D(r2, s[1][1][2], 0xEFFBFDEB, 0xF8FDF50D, 0x0002EFFA, 0x031005D4);
	r3 = D(r3, s[1][1][2], 0xFDF0F513, 0x3FEBFE0E, 0xF608C11D, 0x0205E746);
	r0 = D(r0, s[1][2][0], 0x0002051E, 0xFE0203E5, 0xEDFDEB10, 0xF5F2FE05);
	r1 = D(r1, s[1][2][0], 0xF5EB00FD, 0x000202FA, 0x06FA08F3, 0xFDFAFBF2);
	r2 = D(r2, s[1][2][0], 0x0A0AF828, 0xE3EA00FD, 0x100003F2, 0xF606FAD8);
	r3 = D(r3, s[1][2][0], 0x05FB0300, 0xF8FDE211, 0x2006F544, 0xF80E0D16);
	r0 = D(r0, s[1][2][1], 0x03050539, 0xFA0BFA19, 0x0EF8F354, 0xEB08F61B);
	r1 = D(r1, s[1][2][1], 0xFEF00BEF, 0xFDFEFB1B, 0xFBFA0EA2, 0x060210F8);
	r2 = D(r2, s[1][2][1], 0xF8FD063C, 0xE2FDFD0A, 0xFDE7FBEF, 0x0602081E);
	r3 = D(r3, s[1][2][1], 0xF60611E5, 0x00FE2003, 0x03E01EFB, 0x02FE0DE2);
	r0 = D(r0, s[1][2][2], 0x08080818, 0xFB05FDFE, 0xFB02F615, 0x0305F813);
	r1 = D(r1, s[1][2][2], 0xFB1102DD, 0xF8130023, 0xF30005C4, 0xFD0A08E7);
	r2 = D(r2, s[1][2][2], 0xFA02FD08, 0xFD00F00A, 0x03030026, 0x00FEFEE8);
	r3 = D(r3, s[1][2][2], 0xFEF819D4, 0xFE0E0805, 0x030511FA, 0x02F805F0);
	s[0][0][0] = G[4][xy.y+0][xy.x+0]; s[0][0][1] = G[4][xy.y+0][xy.x+1];
	s[0][0][2] = G[4][xy.y+0][xy.x+2]; s[0][1][0] = G[4][xy.y+1][xy.x+0];
	s[0][1][1] = G[4][xy.y+1][xy.x+1]; s[0][1][2] = G[4][xy.y+1][xy.x+2];
	s[0][2][0] = G[4][xy.y+2][xy.x+0]; s[0][2][1] = G[4][xy.y+2][xy.x+1];
	s[0][2][2] = G[4][xy.y+2][xy.x+2]; s[1][0][0] = G[5][xy.y+0][xy.x+0];
	s[1][0][1] = G[5][xy.y+0][xy.x+1]; s[1][0][2] = G[5][xy.y+0][xy.x+2];
	s[1][1][0] = G[5][xy.y+1][xy.x+0]; s[1][1][1] = G[5][xy.y+1][xy.x+1];
	s[1][1][2] = G[5][xy.y+1][xy.x+2]; s[1][2][0] = G[5][xy.y+2][xy.x+0];
	s[1][2][1] = G[5][xy.y+2][xy.x+1]; s[1][2][2] = G[5][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x030A05F3, 0x10FD050D, 0xFDF3FA0D, 0xFBF50208);
	r1 = D(r1, s[0][0][0], 0xEF0A0AFB, 0xFEFA0300, 0xEF19E000, 0x05E80AE7);
	r2 = D(r2, s[0][0][0], 0x0BF6F303, 0x020A0610, 0x0EF2FB0E, 0xF8EBFB06);
	r3 = D(r3, s[0][0][0], 0xFDFE0A11, 0x0618151D, 0xFA13F510, 0xFB100005);
	r0 = D(r0, s[0][0][1], 0xF3E202F3, 0x000AFB03, 0x02E00602, 0x0005FA06);
	r1 = D(r1, s[0][0][1], 0xF3FDFEFE, 0x001105F8, 0xFDF500FB, 0xF8F200F2);
	r2 = D(r2, s[0][0][1], 0x18FEEAEB, 0xE0EA1305, 0x1DFDFE11, 0x180DFEFB);
	r3 = D(r3, s[0][0][1], 0xFAFA0DE8, 0x18030E00, 0x06DCFD18, 0xFB00FEFE);
	r0 = D(r0, s[0][0][2], 0xFAF308F0, 0x20FE060B, 0x06E008FA, 0xFBF60003);
	r1 = D(r1, s[0][0][2], 0xF0F60300, 0xFDF5FDF6, 0x0608F00B, 0xE8060AFD);
	r2 = D(r2, s[0][0][2], 0x20F50AE7, 0xF0FDFD00, 0x16FAFAF6, 0x000E0000);
	r3 = D(r3, s[0][0][2], 0x02000E03, 0x200EFD0D, 0xF006F811, 0x15F00302);
	r0 = D(r0, s[0][1][0], 0x000D1B05, 0x0BEAFBFD, 0xF8F3130D, 0xFDE8F6FD);
	r1 = D(r1, s[0][1][0], 0xEF2405EF, 0x000611FE, 0xFDEDF013, 0x060E0E00);
	r2 = D(r2, s[0][1][0], 0xF20AE300, 0x0D003416, 0xE71ED7F2, 0x06000315);
	r3 = D(r3, s[0][1][0], 0xE50D020E, 0xF20B21F3, 0xFE0605E5, 0x16FEF608);
	r0 = D(r0, s[0][1][1], 0xF20D1903, 0xEFEAFA08, 0xF00E0616, 0xF2190AF6);
	r1 = D(r1, s[0][1][1], 0xE7050AFE, 0x0216FA16, 0x1EE5F80E, 0x150AEF21);
	r2 = D(r2, s[0][1][1], 0x06D50615, 0xF31B08EF, 0xDFDDFE18, 0x000E0018);
	r3 = D(r3, s[0][1][1], 0xF8DFED05, 0xD000F3CA, 0x15FBEFFA, 0x160008FB);
	r0 = D(r0, s[0][1][2], 0x00F20BFD, 0x03FAFBF8, 0x1915FDF2, 0xFDF2F3EA);
	r1 = D(r1, s[0][1][2], 0xED05FB02, 0x02151603, 0xDDF80D0A, 0x05F3F806);
	r2 = D(r2, s[0][1][2], 0xED0AFB00, 0x11FAFEFA, 0xFA080510, 0x05EBFDF2);
	r3 = D(r3, s[0][1][2], 0xF0030A00, 0xEAFD0310, 0x0E18FEE2, 0x21F613FB);
	r0 = D(r0, s[0][2][0], 0x000210FA, 0x0006FEEF, 0xF600FEF5, 0xFDFD0805);
	r1 = D(r1, s[0][2][0], 0x082103FA, 0x0D00F8F6, 0xFB11F808, 0x0DFA11F6);
	r2 = D(r2, s[0][2][0], 0xF2EB0306, 0xE50013ED, 0xFEFB1002, 0xEDEA030A);
	r3 = D(r3, s[0][2][0], 0xFDFA2105, 0x10EBEFF0, 0x00050D0A, 0x160B0E08);
	r0 = D(r0, s[0][2][1], 0xE70AF61B, 0xEDF602FB, 0xED100DF8, 0x0D1900FE);
	r1 = D(r1, s[0][2][1], 0xDFE002F2, 0x08FAFA06, 0x0D0200F6, 0xF20DF305);
	r2 = D(r2, s[0][2][1], 0xE3F3FEE3, 0x0D0003FE, 0xED0DF80A, 0xEBEB10FD);
	r3 = D(r3, s[0][2][1], 0xF2FAFB06, 0x0206EB15, 0xF2F3F320, 0x0600110B);
	r0 = D(r0, s[0][2][2], 0x0E02F50A, 0x0D000010, 0xEBFE020A, 0xF2F30302);
	r1 = D(r1, s[0][2][2], 0xF506F0F6, 0x08EBF000, 0xFA0A02F5, 0x280AF610);
	r2 = D(r2, s[0][2][2], 0x0500060A, 0xF002FEFA, 0xF3F0FDF2, 0x061BFB05);
	r3 = D(r3, s[0][2][2], 0x08080605, 0x13E80802, 0x29E8FDED, 0x03FB0EF0);
	r0 = D(r0, s[1][0][0], 0x00FAE5FD, 0xF2030EFA, 0xF50A050A, 0xFAFBFB03);
	r1 = D(r1, s[1][0][0], 0x05F3F6F8, 0x050BFB03, 0xFDFEFE1E, 0xF6021B05);
	r2 = D(r2, s[1][0][0], 0xFD0502FA, 0xFEFB16EB, 0x03F8FBFD, 0x020A10FE);
	r3 = D(r3, s[1][0][0], 0xFD0308F6, 0xF8FD0B16, 0xFD05E8E7, 0x0802FA00);
	r0 = D(r0, s[1][0][1], 0xF8060303, 0x0603F3FE, 0x0006F8FB, 0xFAFA03F6);
	r1 = D(r1, s[1][0][1], 0xF6FD00E2, 0x05F3F8FB, 0x0AFA101D, 0xFEF210D5);
	r2 = D(r2, s[1][0][1], 0xFEFEEB00, 0xFDFB11F3, 0x10FEF206, 0xF6EF1303);
	r3 = D(r3, s[1][0][1], 0xFEFE1005, 0x0208FDFE, 0xFE02FEEB, 0x000010FA);
	r0 = D(r0, s[1][0][2], 0xFAFBFAFE, 0xFAFEF306, 0x030BF60A, 0xFD150203);
	r1 = D(r1, s[1][0][2], 0x020A05FD, 0x08020305, 0x00020BFA, 0x03FAFEF8);
	r2 = D(r2, s[1][0][2], 0xFE02EFFE, 0xF8050EF6, 0x02F5FD10, 0xFBF600F0);
	r3 = D(r3, s[1][0][2], 0xEDFE05E8, 0x00050D1E, 0x06F500EA, 0x0502030B);
	r0 = D(r0, s[1][1][0], 0xFD0A0BFD, 0xF305F005, 0x00F8060B, 0xF6F302FA);
	r1 = D(r1, s[1][1][0], 0x08EFF316, 0xFDF6F802, 0xFD050518, 0x0505FEFD);
	r2 = D(r2, s[1][1][0], 0x020EEF00, 0x03151BEB, 0x0202EB13, 0xE70A0E00);
	r3 = D(r3, s[1][1][0], 0xFEFB1303, 0x0EF52006, 0x11050318, 0x0AFD06F2);
	r0 = D(r0, s[1][1][1], 0xF5FA0215, 0x1002F510, 0x15FEFB16, 0x00EAFDFE);
	r1 = D(r1, s[1][1][1], 0xEAFDF8EF, 0x15020D13, 0x050BFBE7, 0x000BF511);
	r2 = D(r2, s[1][1][1], 0xFB05F5DF, 0xF6F30310, 0xEF1BF302, 0x16FB0A06);
	r3 = D(r3, s[1][1][1], 0xEAFEF3FE, 0xEFF50EEF, 0xF6FDFA11, 0xF8FDEAF3);
	r0 = D(r0, s[1][1][2], 0xF8FDF802, 0xFBF3FE0E, 0xF6050618, 0xFA0B0B0A);
	r1 = D(r1, s[1][1][2], 0xF8FD03ED, 0xFE05E7FB, 0x0B03F608, 0x1003F806);
	r2 = D(r2, s[1][1][2], 0x05FE06FD, 0xF505F511, 0x05FBFECD, 0x060A081B);
	r3 = D(r3, s[1][1][2], 0x15000818, 0x00F0021E, 0x0AF3ED00, 0x0608021B);
	r0 = D(r0, s[1][2][0], 0xF6FA1906, 0x11000216, 0x060B0003, 0xF803F3FB);
	r1 = D(r1, s[1][2][0], 0x00FB13FE, 0xF0020805, 0xF8FE05FB, 0xFBFD030A);
	r2 = D(r2, s[1][2][0], 0xF6020615, 0x00F30D10, 0xF2F20EED, 0x03021802);
	r3 = D(r3, s[1][2][0], 0xF30B0D02, 0x100800F6, 0xFA0BED1E, 0x0500FDF2);
	r0 = D(r0, s[1][2][1], 0x16F505F2, 0x0BF003F5, 0xFAF6F518, 0xFBED00FE);
	r1 = D(r1, s[1][2][1], 0xEB0E10EF, 0xF8060BF5, 0xFBFB0AF2, 0xF5FB0BF5);
	r2 = D(r2, s[1][2][1], 0xF6000B08, 0xFD000306, 0xE8FD0B06, 0x0200FD00);
	r3 = D(r3, s[1][2][1], 0x08030300, 0xF00AFBED, 0x0302F5F5, 0x00000203);
	r0 = D(r0, s[1][2][2], 0x06060BF6, 0xF0FE0508, 0x06F8FBFD, 0x0800FAF8);
	r1 = D(r1, s[1][2][2], 0xEF020800, 0xFA0A1106, 0xF00302FE, 0xFA0AF60A);
	r2 = D(r2, s[1][2][2], 0xF811EFF3, 0x0B0500FD, 0x020206FE, 0x0AFDFDFE);
	r3 = D(r3, s[1][2][2], 0xF608FAFD, 0x0606DF00, 0xFD05F605, 0xFBFB0208);
	s[0][0][0] = G[6][xy.y+0][xy.x+0]; s[0][0][1] = G[6][xy.y+0][xy.x+1];
	s[0][0][2] = G[6][xy.y+0][xy.x+2]; s[0][1][0] = G[6][xy.y+1][xy.x+0];
	s[0][1][1] = G[6][xy.y+1][xy.x+1]; s[0][1][2] = G[6][xy.y+1][xy.x+2];
	s[0][2][0] = G[6][xy.y+2][xy.x+0]; s[0][2][1] = G[6][xy.y+2][xy.x+1];
	s[0][2][2] = G[6][xy.y+2][xy.x+2]; s[1][0][0] = G[7][xy.y+0][xy.x+0];
	s[1][0][1] = G[7][xy.y+0][xy.x+1]; s[1][0][2] = G[7][xy.y+0][xy.x+2];
	s[1][1][0] = G[7][xy.y+1][xy.x+0]; s[1][1][1] = G[7][xy.y+1][xy.x+1];
	s[1][1][2] = G[7][xy.y+1][xy.x+2]; s[1][2][0] = G[7][xy.y+2][xy.x+0];
	s[1][2][1] = G[7][xy.y+2][xy.x+1]; s[1][2][2] = G[7][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x21F0FDD2, 0x02100315, 0xEF15FBF3, 0xF508083B);
	r1 = D(r1, s[0][0][0], 0x030B03AF, 0x0003FDF0, 0xEA1DFE03, 0x130E154B);
	r2 = D(r2, s[0][0][0], 0xFEFDFA52, 0x02020833, 0xF515F634, 0xF50D15DA);
	r3 = D(r3, s[0][0][0], 0x02230351, 0xFEFEFACC, 0x05F6F5F0, 0xFB021354);
	r0 = D(r0, s[0][0][1], 0x05F6F08F, 0xF5FBF674, 0x19020A2E, 0x030B053C);
	r1 = D(r1, s[0][0][1], 0xF6020294, 0x030BFA1D, 0x0E030529, 0x0A0A0011);
	r2 = D(r2, s[0][0][1], 0x08FD0A6D, 0xFE130316, 0xF2EA08DA, 0xFD0606BC);
	r3 = D(r3, s[0][0][1], 0x0A02F269, 0xE5FEFA75, 0x13F80AE3, 0xF0F5064E);
	r0 = D(r0, s[0][0][2], 0x21050EDD, 0xFBF30226, 0x0606FACC, 0xF205FB3B);
	r1 = D(r1, s[0][0][2], 0x0503F8F0, 0x02F8F64E, 0x05020613, 0xE31EF510);
	r2 = D(r2, s[0][0][2], 0x000DFE62, 0x06F502AA, 0x0AFAFDDF, 0xF310FB29);
	r3 = D(r3, s[0][0][2], 0x030AF87F, 0xF6F8FA81, 0x11FAF50B, 0x05FB08BF);
	r0 = D(r0, s[0][1][0], 0xF2FDFD1E, 0xEA05FB81, 0xF60606A9, 0xE805FD3B);
	r1 = D(r1, s[0][1][0], 0x0B0AF5FB, 0xFD02FB41, 0x061605F2, 0x00030200);
	r2 = D(r2, s[0][1][0], 0x2B0E0E31, 0xFEFA033F, 0x0B021974, 0x03000611);
	r3 = D(r3, s[0][1][0], 0xFB0B0856, 0x08F8F8E8, 0xEA02087F, 0x16F5F6D2);
	r0 = D(r0, s[0][1][1], 0xE802F2F8, 0xF300FA3C, 0xE0D4F24E, 0x00F00619);
	r1 = D(r1, s[0][1][1], 0x0D0B0EB5, 0x08FD0881, 0x031BFEBD, 0x02F200DC);
	r2 = D(r2, s[0][1][1], 0xF8F8F644, 0x03EDFA16, 0x0A16067F, 0x15E0FD11);
	r3 = D(r3, s[0][1][1], 0x00180A3F, 0xF8000BCA, 0x150506FD, 0xE5F8FB28);
	r0 = D(r0, s[0][1][2], 0x13ED03F6, 0x16F6FA7F, 0x02080508, 0x0502082E);
	r1 = D(r1, s[0][1][2], 0xED1008D7, 0xE3020A29, 0xF5F6FD10, 0xEAE000EA);
	r2 = D(r2, s[0][1][2], 0xE8EDFD28, 0xF31103DC, 0xF3F2000E, 0x0002F229);
	r3 = D(r3, s[0][1][2], 0xF2FEFB7F, 0x10FD0215, 0xFB33FEA2, 0xFBFDF60E);
	r0 = D(r0, s[0][2][0], 0x03FBF8E5, 0x06060A0D, 0x0D030351, 0x080A0352);
	r1 = D(r1, s[0][2][0], 0x0E00F24C, 0xFA02154B, 0xE7080E4C, 0xF6FB0844);
	r2 = D(r2, s[0][2][0], 0xFA02032E, 0x10EDEA06, 0x0AF5EF5A, 0xF813FA19);
	r3 = D(r3, s[0][2][0], 0xEA19085C, 0x15150397, 0x160DFB89, 0x03FBFD7F);
	r0 = D(r0, s[0][2][1], 0x05FE052E, 0xFEFA0806, 0xEA230BED, 0x200E186A);
	r1 = D(r1, s[0][2][1], 0xF5F8F5BA, 0xF3F8F5FB, 0xDAEDF01B, 0xE8E3F318);
	r2 = D(r2, s[0][2][1], 0xFDF60533, 0xFA150EDA, 0xFDE7FD75, 0x0EFDFD08);
	r3 = D(r3, s[0][2][1], 0xF2F50A7C, 0xF61B0081, 0xF2DD0515, 0xF2FB021D);
	r0 = D(r0, s[0][2][2], 0xF5FB0819, 0x13F60AB7, 0x02F510BF, 0x2C050A49);
	r1 = D(r1, s[0][2][2], 0xE2FEFE0A, 0xEA00FE18, 0xFBFDFAEA, 0xFA03FE3B);
	r2 = D(r2, s[0][2][2], 0xED1EF877, 0x110B06AF, 0x11FDF23E, 0xDAF502E5);
	r3 = D(r3, s[0][2][2], 0xDA06025E, 0xF8E503E0, 0x030A0A26, 0xEA13FE06);
	r0 = D(r0, s[1][0][0], 0xEF13ED0A, 0xFBF5F2F2, 0x0619FBF5, 0x0B08EFEF);
	r1 = D(r1, s[1][0][0], 0xF62E1D0D, 0xFDFEFA0E, 0x03081906, 0xF5CCD205);
	r2 = D(r2, s[1][0][0], 0x080A1EF8, 0x05F20A13, 0x06F3DA00, 0x0D021002);
	r3 = D(r3, s[1][0][0], 0x00163106, 0x0A1BCF0B, 0x02F8D710, 0xFEE2E7F5);
	r0 = D(r0, s[1][0][1], 0xFD0AFEFE, 0x000EEDF8, 0xFEFAF2FE, 0xFE0A0DFE);
	r1 = D(r1, s[1][0][1], 0x02130803, 0xF8FE0502, 0xFD1D0EF3, 0xFB0028FE);
	r2 = D(r2, s[1][0][1], 0x03D4DFFB, 0xFAED06FD, 0xFBFDCDFD, 0xFB0BF2EF);
	r3 = D(r3, s[1][0][1], 0x0311E7FD, 0xFB06BF02, 0xFEED0A06, 0x0DE3EB00);
	r0 = D(r0, s[1][0][2], 0xF3FAF011, 0xF80803F5, 0xFD00FB03, 0xFAFE13F6);
	r1 = D(r1, s[1][0][2], 0x000BFD06, 0x03080003, 0xF605FEFE, 0x05E813FA);
	r2 = D(r2, s[1][0][2], 0x00ED0E06, 0x00F3EA00, 0x02F3E302, 0x0005F6F8);
	r3 = D(r3, s[1][0][2], 0x0213F200, 0x080DDDFB, 0xFD023FFB, 0x08FAF503);
	r0 = D(r0, s[1][1][0], 0x0DFAF5F0, 0xF3F2FD06, 0x06023406, 0xFA150E05);
	r1 = D(r1, s[1][1][0], 0xF6442302, 0x0306FE0A, 0xFD0AF600, 0x02FDFB05);
	r2 = D(r2, s[1][1][0], 0xF2F2F0FE, 0x1106E5FB, 0xFBFDC2FD, 0xFE0EF611);
	r3 = D(r3, s[1][1][0], 0xF62820FA, 0x020BE0FD, 0xFA15CDED, 0x00F2F0F0);
	r0 = D(r0, s[1][1][1], 0x080BCF0B, 0xFA1D1DFD, 0x0303F6EB, 0xF3180BF3);
	r1 = D(r1, s[1][1][1], 0xFEFAE0FE, 0x0A430B0A, 0x0549430B, 0x08032BF2);
	r2 = D(r2, s[1][1][1], 0x02E5F5F6, 0x0E030EFA, 0xFBD7E500, 0x08FBCDFA);
	r3 = D(r3, s[1][1][1], 0x08E50613, 0xFD1EE700, 0xFDF3D708, 0x0A2BF6EF);
	r0 = D(r0, s[1][1][2], 0xF6F8E508, 0xFA11FDFD, 0xF8E5D20B, 0x060D16F3);
	r1 = D(r1, s[1][1][2], 0x020AE0FD, 0x050B02FA, 0x1111DCF8, 0x1124F303);
	r2 = D(r2, s[1][1][2], 0x1803FE06, 0xFAFE2EF2, 0x0E05030A, 0x0AF5E003);
	r3 = D(r3, s[1][1][2], 0x06F208F8, 0xFEFB0EF3, 0xFE11EDFD, 0x0BE71BFD);
	r0 = D(r0, s[1][2][0], 0xFEEA0AF6, 0xFDF0DAF8, 0xFB190AF2, 0xFD0A00EF);
	r1 = D(r1, s[1][2][0], 0xFB101E06, 0x0010EF0A, 0x100A03FE, 0x031106F2);
	r2 = D(r2, s[1][2][0], 0x0011FEFD, 0xF2FBFD05, 0x0AD2DD05, 0x0602F8FA);
	r3 = D(r3, s[1][2][0], 0x0BF8EDFE, 0xFB031503, 0xFA03F60D, 0x08F30EF3);
	r0 = D(r0, s[1][2][1], 0xFADAF0FD, 0x0DF0EBF6, 0x0DDA050B, 0xF3FB03FB);
	r1 = D(r1, s[1][2][1], 0x0524E702, 0x000D1511, 0x0D0015FA, 0x0B2316F8);
	r2 = D(r2, s[1][2][1], 0x030B23F2, 0xEF0500FE, 0x051833F3, 0x05EF29FD);
	r3 = D(r3, s[1][2][1], 0xF81BE2F8, 0xFAF3F600, 0xFD1528FA, 0x10F606F2);
	r0 = D(r0, s[1][2][2], 0x00E5E206, 0xFB16F8F8, 0xFE0D0AFE, 0x160B0BF3);
	r1 = D(r1, s[1][2][2], 0x03361BFE, 0x0A0BF305, 0x00FE26FA, 0x0B08DF08);
	r2 = D(r2, s[1][2][2], 0x0502FA05, 0xFE23DF02, 0xF3EB3003, 0x100D0502);
	r3 = D(r3, s[1][2][2], 0xF50AF2FD, 0x0DF6DDFE, 0xFEFA08F6, 0x05ED310E);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-4.094e-02, 5.586e-02, 4.295e-03, -5.920e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-2.482e-02, -2.132e-01, 2.045e-02, 1.136e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(1.121e-02, -2.160e-03, -1.321e-02, -1.247e-02);
	imageStore(out_image, opos + ivec2(0, 1), vec4(f2));
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(-1.169e-02, 7.153e-04, 1.352e-03, 8.351e-02);
	imageStore(out_image, opos + ivec2(1, 1), vec4(f3));
}

//!DESC CuNNy-4x16C-TEST-conv2
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv1
//!BIND LUMA
//!SAVE conv2
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[8][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv1_pt;
			r = conv1_gather(p, 0);
			g = conv1_gather(p, 1);
			b = conv1_gather(p, 2);
			a = conv1_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v2 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v4 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v6 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			vec4 v5 = max(-v4, vec4(0));
			v4 = max(v4, vec4(0));
			vec4 v7 = max(-v6, vec4(0));
			v6 = max(v6, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
			G[4][ay][ax] = int(packSnorm4x8(v4));
			G[5][ay][ax] = int(packSnorm4x8(v5));
			G[6][ay][ax] = int(packSnorm4x8(v6));
			G[7][ay][ax] = int(packSnorm4x8(v7));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x2B0DEF00, 0x2B07FF0F, 0x32FF00F9, 0xD600060F);
	r1 = D(r1, s[0][0][0], 0xFDFC0B04, 0x2A070BEF, 0x1900F60D, 0x0F0306F2);
	r2 = D(r2, s[0][0][0], 0x03FDFC04, 0xEBF8030B, 0x140F00F5, 0x14F10806);
	r3 = D(r3, s[0][0][0], 0x2B0E08FD, 0xF8F9FCFA, 0x2D01EE08, 0xEAFF0D06);
	r0 = D(r0, s[0][0][1], 0x31EC0A01, 0x01EC0DEC, 0x0A000DEE, 0xC907EEFA);
	r1 = D(r1, s[0][0][1], 0x3B0DF8F3, 0x3F0706F8, 0x27FDFD03, 0xEA01FCF1);
	r2 = D(r2, s[0][0][1], 0x0001F507, 0xCE060811, 0x040B06F2, 0xFA01F20F);
	r3 = D(r3, s[0][0][1], 0x01F5FF0B, 0x42FD0001, 0xF50D0BF2, 0xFCFD1400);
	r0 = D(r0, s[0][0][2], 0x290DE704, 0xB7FA0006, 0xEFFDF5F5, 0x08FCF807);
	r1 = D(r1, s[0][0][2], 0x420EFDEC, 0xB704EFEF, 0x12F614F1, 0xFFFF01EC);
	r2 = D(r2, s[0][0][2], 0xF5FD0AFA, 0xDA0FFCF9, 0xAB070606, 0x0AF604F9);
	r3 = D(r3, s[0][0][2], 0xD5FF0AF3, 0x3C01FA0D, 0x0A06FCFC, 0xE7FF0807);
	r0 = D(r0, s[0][1][0], 0x3C0E0100, 0xEFEA0DFF, 0x01F9FDFC, 0x1FFDEC0E);
	r1 = D(r1, s[0][1][0], 0xDDEAF501, 0xCFF908FF, 0x6CF801FC, 0x290A08FD);
	r2 = D(r2, s[0][1][0], 0xFAF1FDFA, 0xEE070BF2, 0xFF04FF01, 0xC9F5F6F3);
	r3 = D(r3, s[0][1][0], 0x1DE5EFFF, 0xEBEE16F8, 0xFD070E08, 0x1CF91504);
	r0 = D(r0, s[0][1][1], 0x7E151907, 0x4E080A18, 0x180D0419, 0x3FE511F8);
	r1 = D(r1, s[0][1][1], 0x30EA0E0B, 0x53071812, 0x7F24F50E, 0xDEF9EF0B);
	r2 = D(r2, s[0][1][1], 0xBEEF0000, 0xC20A030A, 0xE011FAEA, 0xEEEBE808);
	r3 = D(r3, s[0][1][1], 0x7F002418, 0x7F0D1904, 0x18190AE5, 0x8A1DC703);
	r0 = D(r0, s[0][1][2], 0x4C040EF8, 0xE8F90601, 0xEF1D1200, 0x26030806);
	r1 = D(r1, s[0][1][2], 0x37060D18, 0xEC00F1FF, 0x50FA12FA, 0xC51512FF);
	r2 = D(r2, s[0][1][2], 0xEC03E5FD, 0xADFAF9F9, 0x81FCEEFC, 0x16031803);
	r3 = D(r3, s[0][1][2], 0x0307F8FD, 0x65EB0E0F, 0xE4070DF2, 0x24EC140D);
	r0 = D(r0, s[0][2][0], 0x2311F6F5, 0xBAF9FC01, 0x0FFD0300, 0xD2EC0008);
	r1 = D(r1, s[0][2][0], 0xE80304F5, 0xD5F808F2, 0x38060DFC, 0x080101F8);
	r2 = D(r2, s[0][2][0], 0x1D15FF06, 0xB40D0003, 0xDDFCFD0A, 0x0604EFFA);
	r3 = D(r3, s[0][2][0], 0x14EFFF0A, 0x22FAFCF6, 0xBAFDF3FF, 0x06FD0E03);
	r0 = D(r0, s[0][2][1], 0x3EF60408, 0xBEF1FD0F, 0x22EAF1F6, 0xDD31F3F1);
	r1 = D(r1, s[0][2][1], 0x0403F6F2, 0xE4010404, 0x660EEFFC, 0xE30F0003);
	r2 = D(r2, s[0][2][1], 0xEF0104FF, 0xC1FC12F1, 0xDEFCEF00, 0x1F000103);
	r3 = D(r3, s[0][2][1], 0x1F15FFF9, 0x32F50407, 0xDC0DF501, 0x07FA18F9);
	r0 = D(r0, s[0][2][2], 0x31FF030A, 0xF2F8FDFF, 0x1DFFEFFF, 0xB0F20401);
	r1 = D(r1, s[0][2][2], 0x03E70812, 0xDEFC0006, 0x51F203F6, 0xEE0303FA);
	r2 = D(r2, s[0][2][2], 0xF9071208, 0xE3F8EAF3, 0xB607EEEC, 0x22F30611);
	r3 = D(r3, s[0][2][2], 0xE4070AFF, 0xADF9E70D, 0xF81106FD, 0xEFFD0B0E);
	r0 = D(r0, s[1][0][0], 0xFC0D0D01, 0x00D70815, 0x060808F8, 0xFF04FC06);
	r1 = D(r1, s[1][0][0], 0x08E8F8F5, 0xFAF6FF01, 0xFD0603FA, 0x000003F5);
	r2 = D(r2, s[1][0][0], 0x071BFF06, 0x01FA040A, 0xF90F03F3, 0x01FFFD07);
	r3 = D(r3, s[1][0][0], 0x04F80111, 0xF81CF6F6, 0xF6200A0D, 0x0AF5FAFA);
	r0 = D(r0, s[1][0][1], 0x0819F30E, 0xFCDAFD0D, 0x06030003, 0x0104FFFA);
	r1 = D(r1, s[1][0][1], 0x00DEFDF1, 0xFCEEFDFC, 0x0AFFF9FD, 0x0315060A);
	r2 = D(r2, s[1][0][1], 0x01EBFF0E, 0xF316FCF6, 0x011103FA, 0xF9FD19F8);
	r3 = D(r3, s[1][0][1], 0xFCE5F5F9, 0x0006F9FA, 0x010FF101, 0xFDFAFA07);
	r0 = D(r0, s[1][0][2], 0xFF0B0E01, 0x07F6FFFD, 0xFD0706FF, 0xF80D03FF);
	r1 = D(r1, s[1][0][2], 0xFCF9F9FD, 0x04EF0403, 0x08FFF9F2, 0x070AFD07);
	r2 = D(r2, s[1][0][2], 0xFCF5F800, 0x060EFFFF, 0x06FFFDF2, 0x0B08F5FC);
	r3 = D(r3, s[1][0][2], 0x06EC0101, 0xF9F306F8, 0xFC010D03, 0x01FAF907);
	r0 = D(r0, s[1][1][0], 0xFF1403FC, 0x12110F1C, 0xFA06FAF8, 0xF8F80D01);
	r1 = D(r1, s[1][1][0], 0x07F508FF, 0x0E0EF8F6, 0x00FF0A07, 0x040307F6);
	r2 = D(r2, s[1][1][0], 0xF800151D, 0xF2F9F61C, 0xFF19F9F6, 0x0408081C);
	r3 = D(r3, s[1][1][0], 0xF90A1216, 0x0BFFEE00, 0x1611FF11, 0xF9FDFC03);
	r0 = D(r0, s[1][1][1], 0x0100F5F2, 0xFCEBF3EB, 0xF60DFC0B, 0x07000D0F);
	r1 = D(r1, s[1][1][1], 0x0634030E, 0xE80AFD14, 0x03EAFFF1, 0xF90D0E11);
	r2 = D(r2, s[1][1][1], 0xFC0F0A0F, 0x000DFFFA, 0xF5F8F307, 0xFF0DF60D);
	r3 = D(r3, s[1][1][1], 0x07D5FF03, 0x04F1F8F5, 0xFAE403F3, 0x01F5FDFC);
	r0 = D(r0, s[1][1][2], 0x0BE8F1EF, 0x04F2FC18, 0x0EDD0AF6, 0x030806EF);
	r1 = D(r1, s[1][1][2], 0x01F6FFF8, 0xF6010A0B, 0x000AF5E3, 0xF8FAEE0D);
	r2 = D(r2, s[1][1][2], 0xF8EB0F0F, 0x04F803F5, 0xF6080EE8, 0x0107F911);
	r3 = D(r3, s[1][1][2], 0xFCF6040A, 0x010FFCEE, 0xF618EFF3, 0x000BF5FD);
	r0 = D(r0, s[1][2][0], 0xF90407EC, 0x03080B0F, 0x03FFFDE8, 0xFCFAFD01);
	r1 = D(r1, s[1][2][0], 0x01F6F307, 0x040F0DF8, 0x030700F9, 0x070800EE);
	r2 = D(r2, s[1][2][0], 0xF900040B, 0x08FF04EC, 0x070D00FA, 0xF8F90701);
	r3 = D(r3, s[1][2][0], 0x0A0A0E15, 0x00000A03, 0x0115FD0B, 0x01FFFC0B);
	r0 = D(r0, s[1][2][1], 0x00F3FDF5, 0xF8FCF6FC, 0xF9E80707, 0x08EF0A2A);
	r1 = D(r1, s[1][2][1], 0xFA060E15, 0x0000F3F3, 0x010801EB, 0xFDF504FD);
	r2 = D(r2, s[1][2][1], 0x0103F1FF, 0xFAF904FF, 0x0DF3FFEB, 0xEA0A1506);
	r3 = D(r3, s[1][2][1], 0xFAF8F914, 0x04000604, 0x01F9F80A, 0xFCFAEB15);
	r0 = D(r0, s[1][2][2], 0x03F5F8EF, 0xF5FAFFFD, 0xFFF300D7, 0xF8FDEF03);
	r1 = D(r1, s[1][2][2], 0xFDFD0404, 0x0000FDEB, 0xF90E01E7, 0xFC08FF01);
	r2 = D(r2, s[1][2][2], 0x0801FA18, 0x00080F06, 0xFA150B06, 0x01FAF504);
	r3 = D(r3, s[1][2][2], 0xF614FCFF, 0xFFF61512, 0x0EF50616, 0x0000F9FF);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x07F61C03, 0xFCDEEEF1, 0x140404FF, 0xFFF8FAFA);
	r1 = D(r1, s[0][0][0], 0x0416EB04, 0xF61B1C0A, 0xFFFD06FD, 0x04041D04);
	r2 = D(r2, s[0][0][0], 0x06FCE511, 0x070AE1F8, 0xFDFC29FA, 0x1100F604);
	r3 = D(r3, s[0][0][0], 0x0A04F2FC, 0xFA033104, 0xFCECE1EE, 0xF908E004);
	r0 = D(r0, s[0][0][1], 0xFC0B03FD, 0xFFF90311, 0xF8F60F0E, 0x0406EF00);
	r1 = D(r1, s[0][0][1], 0xFDEBF20E, 0xF807D204, 0x040D03FA, 0xFDFAF9FF);
	r2 = D(r2, s[0][0][1], 0xFDEF1500, 0xF50FF801, 0x07070F06, 0x0004FFFF);
	r3 = D(r3, s[0][0][1], 0xFDEE01FD, 0xF906F616, 0x06083104, 0xFA0DD700);
	r0 = D(r0, s[0][0][2], 0xFD0007FD, 0xFF0AF1F3, 0xFA0EEC04, 0xEF001BFF);
	r1 = D(r1, s[0][0][2], 0xEEFF2403, 0xFC0B0F0F, 0xF8F3F108, 0xFF00E5FA);
	r2 = D(r2, s[0][0][2], 0xFA000B14, 0x001615F8, 0xFCFFF303, 0xFFFC15F2);
	r3 = D(r3, s[0][0][2], 0x0D01ECF9, 0xFCFD0F12, 0x11EA0B06, 0xFFFFC511);
	r0 = D(r0, s[0][1][0], 0x01120FEE, 0x01FF2AF5, 0xEC0A060D, 0xFCE51B07);
	r1 = D(r1, s[0][1][0], 0x14030B08, 0xF9080EFC, 0x000D0300, 0xF50022F5);
	r2 = D(r2, s[0][1][0], 0x0A010D0E, 0xFF04F3FA, 0xF60116FD, 0x04F9FD07);
	r3 = D(r3, s[0][1][0], 0x0AFDF206, 0x11000E19, 0x0F0BE0F8, 0x06FDC9F1);
	r0 = D(r0, s[0][1][1], 0xFCFC08E8, 0xF5FDFCF9, 0x0E120406, 0x120D3100);
	r1 = D(r1, s[0][1][1], 0xEF030D03, 0xF906C9F2, 0x0FE50401, 0xFD240DF9);
	r2 = D(r2, s[0][1][1], 0x0DFD0A16, 0xEE071900, 0xF3041FF9, 0x1F140B04);
	r3 = D(r3, s[0][1][1], 0x0703F606, 0xF6EFDEFF, 0xF6F60DFD, 0x01F8CEFD);
	r0 = D(r0, s[0][1][2], 0x000DFFEF, 0x07FFF1F5, 0x140811EE, 0x0701150B);
	r1 = D(r1, s[0][1][2], 0x0115DD03, 0xF1FFEE11, 0x0AF32701, 0xF208F2EE);
	r2 = D(r2, s[0][1][2], 0xE306F60E, 0x03081201, 0x0603FD06, 0x04060A04);
	r3 = D(r3, s[0][1][2], 0xF9FAE4EE, 0xF1F5F907, 0x14EE0B00, 0x06FDBBF9);
	r0 = D(r0, s[0][2][0], 0x08EC1400, 0xFCF30A08, 0xFCFFFDF2, 0xFFF6F50A);
	r1 = D(r1, s[0][2][0], 0xF807F204, 0xF20023F8, 0xF20608FA, 0xFA0416F6);
	r2 = D(r2, s[0][2][0], 0xFF08E8F9, 0x0F0A26EF, 0x00F90D03, 0x08F901FC);
	r3 = D(r3, s[0][2][0], 0x03F9F9F2, 0xF9FC140F, 0x06F10012, 0xFDFDDA0F);
	r0 = D(r0, s[0][2][1], 0xFF0DFFFF, 0xF606F2FA, 0x1F1B0F12, 0xFC0808FF);
	r1 = D(r1, s[0][2][1], 0xF5F80106, 0xE8FA0314, 0x0F080611, 0x1503F903);
	r2 = D(r2, s[0][2][1], 0xE803F3FD, 0xF50B0F0F, 0x0DEB0AF2, 0xFA01F814);
	r3 = D(r3, s[0][2][1], 0x00F30306, 0xECFCF900, 0x04031601, 0x03FAD600);
	r0 = D(r0, s[0][2][2], 0x030D0E04, 0xFC070600, 0x0EFF0600, 0xFAF6CF00);
	r1 = D(r1, s[0][2][2], 0xEA00F30D, 0xFA0B260A, 0xE8F20807, 0xEA01F811);
	r2 = D(r2, s[0][2][2], 0xF101E80E, 0xF8080F08, 0x0BF3F20E, 0xF103E1EE);
	r3 = D(r3, s[0][2][2], 0xFCF9EF03, 0xEAF8FC03, 0x0AF3DEF5, 0xFF06E10A);
	r0 = D(r0, s[1][0][0], 0x0104FAF2, 0x0A0D0404, 0xF6FF0104, 0x04FAFDF3);
	r1 = D(r1, s[1][0][0], 0x00060303, 0x000F04FF, 0x01030607, 0xF90801FD);
	r2 = D(r2, s[1][0][0], 0xF50A0AFA, 0xEAFFF611, 0x0A0012FF, 0x03080DF2);
	r3 = D(r3, s[1][0][0], 0xF6F60604, 0x00000312, 0x03040318, 0x00FC08FA);
	r0 = D(r0, s[1][0][1], 0xF5FD010D, 0x00F806F2, 0x1F1C010E, 0xF5FD01F8);
	r1 = D(r1, s[1][0][1], 0xF9140701, 0xEC19EEFC, 0x04F90104, 0x0A150AFA);
	r2 = D(r2, s[1][0][1], 0xF20E04FD, 0xFF01F5F1, 0x07EEF8F5, 0xEC06FFF2);
	r3 = D(r3, s[1][0][1], 0xFFFFF60F, 0xF6FAF9F5, 0x0FFC06E7, 0x0403E701);
	r0 = D(r0, s[1][0][2], 0x08000D06, 0xFAFFFDE4, 0x04010B0A, 0x07070307);
	r1 = D(r1, s[1][0][2], 0x070DFA14, 0xEB0E01FD, 0x110AFFE4, 0xF308FD0E);
	r2 = D(r2, s[1][0][2], 0x0A03F9F8, 0x01FF0008, 0xEEF9F2EF, 0xEF12F8F8);
	r3 = D(r3, s[1][0][2], 0xF8070BEA, 0x00FD0408, 0x040004F6, 0xFCFC03FD);
	r0 = D(r0, s[1][1][0], 0xEEF30701, 0xF2FC0A2A, 0x010AFFF1, 0x03FFFAF8);
	r1 = D(r1, s[1][1][0], 0xFC19F601, 0xF211F806, 0xFCF6F5F8, 0xFF14F3F2);
	r2 = D(r2, s[1][1][0], 0xF5FAF201, 0xD3F304E8, 0x06FAFDFC, 0x110FF2E8);
	r3 = D(r3, s[1][1][0], 0xEEF5F612, 0xF5F6FC0B, 0xFCF5080F, 0xF900F215);
	r0 = D(r0, s[1][1][1], 0x1BFAFD04, 0xF2FDFD11, 0x0D3EFCCF, 0xF2EBFA15);
	r1 = D(r1, s[1][1][1], 0xE515F2EE, 0xF80401EB, 0x2B00FAF1, 0xE80A07DD);
	r2 = D(r2, s[1][1][1], 0xECF6F5E4, 0xF800FA20, 0x2E120303, 0xF3F607F6);
	r3 = D(r3, s[1][1][1], 0x01EAF812, 0xFF040419, 0x27E5FAFD, 0x0604FA01);
	r0 = D(r0, s[1][1][2], 0x06FAF908, 0x0F0101FC, 0x00110314, 0xF5FAFD0F);
	r1 = D(r1, s[1][1][2], 0xFFFC0316, 0xF91BFF0F, 0x01FFF1EE, 0x0A04F90E);
	r2 = D(r2, s[1][1][2], 0x040A03EC, 0x0E1501FD, 0xECF804DC, 0x0706040A);
	r3 = D(r3, s[1][1][2], 0x04FC01F8, 0xECFC000B, 0xF6FFFCEE, 0xF9000311);
	r0 = D(r0, s[1][2][0], 0xFD01F903, 0x0A03F608, 0x1408060D, 0x08FC0603);
	r1 = D(r1, s[1][2][0], 0xF30D0108, 0xEE190111, 0xFFF30303, 0xF3080408);
	r2 = D(r2, s[1][2][0], 0x061504FD, 0xEAFD000D, 0x07F3EFFC, 0x041C07FA);
	r3 = D(r3, s[1][2][0], 0x0B010F12, 0xECFDFCFC, 0xEFF900F6, 0x030800F5);
	r0 = D(r0, s[1][2][1], 0x0B0FF9F1, 0xFD06F9FD, 0xFC1801F5, 0x0DF300FD);
	r1 = D(r1, s[1][2][1], 0xF6180603, 0xF8200106, 0xFCECF9F3, 0xF10A0A08);
	r2 = D(r2, s[1][2][1], 0xFD0A04F8, 0xFFF308FD, 0x000608FF, 0x0D0806F6);
	r3 = D(r3, s[1][2][1], 0xFF07FD00, 0xF9F30706, 0x20F1FA08, 0x070DEF03);
	r0 = D(r0, s[1][2][2], 0x07F9FDEE, 0xFF00FAF2, 0x0BF90807, 0xFD0000EE);
	r1 = D(r1, s[1][2][2], 0x000403F1, 0xEB060A12, 0x0D03FFDE, 0x041504F6);
	r2 = D(r2, s[1][2][2], 0x080304FA, 0xFD11FD06, 0xF8FF04F6, 0x110AF9EB);
	r3 = D(r3, s[1][2][2], 0x060003F8, 0x0100040E, 0x06FCF6FC, 0xFAF304FF);
	s[0][0][0] = G[4][xy.y+0][xy.x+0]; s[0][0][1] = G[4][xy.y+0][xy.x+1];
	s[0][0][2] = G[4][xy.y+0][xy.x+2]; s[0][1][0] = G[4][xy.y+1][xy.x+0];
	s[0][1][1] = G[4][xy.y+1][xy.x+1]; s[0][1][2] = G[4][xy.y+1][xy.x+2];
	s[0][2][0] = G[4][xy.y+2][xy.x+0]; s[0][2][1] = G[4][xy.y+2][xy.x+1];
	s[0][2][2] = G[4][xy.y+2][xy.x+2]; s[1][0][0] = G[5][xy.y+0][xy.x+0];
	s[1][0][1] = G[5][xy.y+0][xy.x+1]; s[1][0][2] = G[5][xy.y+0][xy.x+2];
	s[1][1][0] = G[5][xy.y+1][xy.x+0]; s[1][1][1] = G[5][xy.y+1][xy.x+1];
	s[1][1][2] = G[5][xy.y+1][xy.x+2]; s[1][2][0] = G[5][xy.y+2][xy.x+0];
	s[1][2][1] = G[5][xy.y+2][xy.x+1]; s[1][2][2] = G[5][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xF90104E4, 0xFC0006FA, 0x0301FFE5, 0x01F90700);
	r1 = D(r1, s[0][0][0], 0x062001DA, 0x0F19F8F3, 0xFDEC0EF8, 0xFD15F5EA);
	r2 = D(r2, s[0][0][0], 0x06FC0BFA, 0xF31606E1, 0xFCF10001, 0x0B070A0E);
	r3 = D(r3, s[0][0][0], 0x040BEE01, 0x03040622, 0xEFEB1919, 0x01FFFFF9);
	r0 = D(r0, s[0][0][1], 0xFDF6FA1C, 0x0A073200, 0x0606E4F1, 0x01F90FFD);
	r1 = D(r1, s[0][0][1], 0x080BFFF2, 0x03F904F9, 0xFF00EB0B, 0xFD0000FF);
	r2 = D(r2, s[0][0][1], 0x0BEA03FA, 0x002EF9E8, 0xFF04F119, 0x040A0BEE);
	r3 = D(r3, s[0][0][1], 0x01F6FDFD, 0x04F3E814, 0x01EB031B, 0x0118FCFF);
	r0 = D(r0, s[0][0][2], 0xFDE4000A, 0xFDFFFD08, 0x000D1904, 0x0DF20015);
	r1 = D(r1, s[0][0][2], 0x0B0F18FC, 0xFDFF0FEB, 0x08FFFF06, 0x08FAF61B);
	r2 = D(r2, s[0][0][2], 0xFFF108FF, 0xFF07F807, 0x01F3E1F3, 0x01FF1DF9);
	r3 = D(r3, s[0][0][2], 0x0606FD11, 0x0BF8ECFC, 0x0BF6FA0B, 0x03F8FC04);
	r0 = D(r0, s[0][1][0], 0x0B23EF15, 0xFF1212EA, 0x0406DE14, 0xF6F612F1);
	r1 = D(r1, s[0][1][0], 0x0114FF14, 0xF6FDFCEF, 0xF9F60607, 0x0D15F600);
	r2 = D(r2, s[0][1][0], 0xF9110F07, 0x0B29E511, 0xF6E70814, 0xFAFA01F3);
	r3 = D(r3, s[0][1][0], 0xEBFDF212, 0x00000008, 0xE40A06E8, 0xF9010000);
	r0 = D(r0, s[0][1][1], 0x11E8EE22, 0x08F8FDDE, 0x2015FC0E, 0xF20803CC);
	r1 = D(r1, s[0][1][1], 0xFDC00001, 0x0FD31504, 0x12F100FC, 0xEB2AF826);
	r2 = D(r2, s[0][1][1], 0xE804E4F1, 0x002D1112, 0x1BF3FF0A, 0xF319160F);
	r3 = D(r3, s[0][1][1], 0xE127F3BB, 0x11E80F01, 0x151D060B, 0x18FCFCFD);
	r0 = D(r0, s[0][1][2], 0xF9F106FD, 0xFAFAF204, 0x1B4CE4F9, 0xF3CC0711);
	r1 = D(r1, s[0][1][2], 0xF9EE11FD, 0x010803FF, 0xF308F301, 0x181BFD1C);
	r2 = D(r2, s[0][1][2], 0xF8E819EF, 0x0834F623, 0xE512DA01, 0xF9D5FAEF);
	r3 = D(r3, s[0][1][2], 0xF8F9EEDC, 0xF20308E7, 0xFF0AF2F1, 0xFF0007F5);
	r0 = D(r0, s[0][2][0], 0xF600FDFF, 0xFA0E080E, 0xFF0101FD, 0xFD0E08F9);
	r1 = D(r1, s[0][2][0], 0x0A20FF1C, 0xFF0BFFF5, 0xFCF5010F, 0xFD0AFAF9);
	r2 = D(r2, s[0][2][0], 0x0E0D1508, 0xFD16FF16, 0xFFEF0101, 0x160F0818);
	r3 = D(r3, s[0][2][0], 0xF803230E, 0x0AF3F203, 0x0BEC00E8, 0x07FDFC04);
	r0 = D(r0, s[0][2][1], 0xE50DE7F8, 0x010EFDEE, 0x290616E7, 0x26E7E7F6);
	r1 = D(r1, s[0][2][1], 0x0DF2DD2E, 0xF51D0F0D, 0x0AEF0806, 0xFC0EFC18);
	r2 = D(r2, s[0][2][1], 0xFDF2030B, 0x010EF219, 0xF8EC0812, 0x00DE0A06);
	r3 = D(r3, s[0][2][1], 0x181D19D7, 0xF8FCF3FF, 0x04F90EEE, 0x030801EB);
	r0 = D(r0, s[0][2][2], 0x0007FCEB, 0x0B0614F9, 0x16080E15, 0xF506EC1C);
	r1 = D(r1, s[0][2][2], 0xFF03FAEE, 0xF519040E, 0x15DC0106, 0x0B0104F5);
	r2 = D(r2, s[0][2][2], 0x06EBF9EC, 0x0B0F01F1, 0x0001FD1D, 0x000600FD);
	r3 = D(r3, s[0][2][2], 0xFCFFEF0D, 0x01FDEADC, 0xEFD5FF0A, 0xFDF806FC);
	r0 = D(r0, s[1][0][0], 0x01000403, 0x060EF6FA, 0xF8060BF8, 0x040306F6);
	r1 = D(r1, s[1][0][0], 0xFCF8010A, 0xF9040B01, 0xE001F9FC, 0x06060700);
	r2 = D(r2, s[1][0][0], 0x01F80003, 0x11FCFFFC, 0xF808FAFC, 0x03F8F9FA);
	r3 = D(r3, s[1][0][0], 0xFC041108, 0xEFF50D03, 0x06FFF5EC, 0x06FF0708);
	r0 = D(r0, s[1][0][1], 0xF1EEFCF5, 0x040AF3FD, 0xF6FA0101, 0xF8F80103);
	r1 = D(r1, s[1][0][1], 0x0303FA06, 0xFA0B0400, 0xECFF0806, 0x0103ECFC);
	r2 = D(r2, s[1][0][1], 0x0DF1FAFD, 0xFD031404, 0x07F80301, 0x15FFF90E);
	r3 = D(r3, s[1][0][1], 0x07040AFA, 0x0DF2FFF9, 0xEC14F9F1, 0xF9FDFCFC);
	r0 = D(r0, s[1][0][2], 0xFD01FD06, 0xFD12FF04, 0x08F6F801, 0x0DF8F801);
	r1 = D(r1, s[1][0][2], 0xE506031C, 0x0F060AFD, 0xF504F3FD, 0xEC01FAF9);
	r2 = D(r2, s[1][0][2], 0xEAFCFDF8, 0xF2000F0D, 0x22F303F9, 0xF8FFF6FA);
	r3 = D(r3, s[1][0][2], 0x040106F5, 0x0E030AFD, 0xFAF900FC, 0x040100FC);
	r0 = D(r0, s[1][1][0], 0x18EEFC15, 0xE1F51F0E, 0xE1030DF2, 0x14F9FDF8);
	r1 = D(r1, s[1][1][0], 0x0D01FADE, 0x23FD0FFD, 0xF801F8FF, 0x00070FFF);
	r2 = D(r2, s[1][1][0], 0x18FAF9F6, 0x010FFFE5, 0x06060007, 0x0DFD06F6);
	r3 = D(r3, s[1][1][0], 0xEB1604EE, 0x0B0004FC, 0x01EC0601, 0x060301F9);
	r0 = D(r0, s[1][1][1], 0xD70AF3F6, 0xE304150A, 0xFA080E12, 0x0EF2070A);
	r1 = D(r1, s[1][1][1], 0x47FD18F5, 0xFD0EF612, 0xEB16F507, 0x0D0001FA);
	r2 = D(r2, s[1][1][1], 0x27E30BEF, 0xE00F0AF9, 0xCE0AF10F, 0x08F8F503);
	r3 = D(r3, s[1][1][1], 0xE30E0B01, 0xE71BFAD5, 0xD506F214, 0xF606FCFC);
	r0 = D(r0, s[1][1][2], 0x2003F911, 0xF30804FA, 0x0DFAFC07, 0x0A0E0D0B);
	r1 = D(r1, s[1][1][2], 0xF5F8F1F6, 0xF10800FC, 0xFFFFF6FD, 0xAFE1E0F5);
	r2 = D(r2, s[1][1][2], 0x06F9FF04, 0x030B0104, 0x04FF0FFC, 0x1603F20A);
	r3 = D(r3, s[1][1][2], 0xF6FFFAFF, 0x06030A0F, 0x24F9010B, 0xFA010007);
	r0 = D(r0, s[1][2][0], 0x06030300, 0x32ECFA0D, 0x07FFF9FF, 0x14F6EF06);
	r1 = D(r1, s[1][2][0], 0xE4FA00FA, 0xFFF9F904, 0xF1FAFAF5, 0x0601F90B);
	r2 = D(r2, s[1][2][0], 0xDEFF0EFA, 0x110308E4, 0x00FFFD0E, 0xEF120A00);
	r3 = D(r3, s[1][2][0], 0xFA00EC01, 0xE8010600, 0x0AFF0B07, 0x03FC04FA);
	r0 = D(r0, s[1][2][1], 0x20EC0D08, 0x07FD03F2, 0xF60DF80A, 0xFFEE0A03);
	r1 = D(r1, s[1][2][1], 0xEC0D08F8, 0x0FFCFFFD, 0xE806F904, 0x03EFFC08);
	r2 = D(r2, s[1][2][1], 0xF8F1FAFF, 0xF8FD0403, 0x0001F3FC, 0x0A040306);
	r3 = D(r3, s[1][2][1], 0xD6ECFF0E, 0x0E07FDFA, 0xEAF9EA0B, 0xFFFFFF01);
	r0 = D(r0, s[1][2][2], 0x04010E0B, 0x00010E08, 0x0806F6FA, 0x19F800FA);
	r1 = D(r1, s[1][2][2], 0xFAFD03EA, 0x0300F3FA, 0xEB06040A, 0xE7F10106);
	r2 = D(r2, s[1][2][2], 0xE3FA0AF1, 0x12F5FF07, 0xEF0008F5, 0x30EF08F5);
	r3 = D(r3, s[1][2][2], 0xF900FD01, 0x00FA04F3, 0xF1F6FCF5, 0x000606FF);
	s[0][0][0] = G[6][xy.y+0][xy.x+0]; s[0][0][1] = G[6][xy.y+0][xy.x+1];
	s[0][0][2] = G[6][xy.y+0][xy.x+2]; s[0][1][0] = G[6][xy.y+1][xy.x+0];
	s[0][1][1] = G[6][xy.y+1][xy.x+1]; s[0][1][2] = G[6][xy.y+1][xy.x+2];
	s[0][2][0] = G[6][xy.y+2][xy.x+0]; s[0][2][1] = G[6][xy.y+2][xy.x+1];
	s[0][2][2] = G[6][xy.y+2][xy.x+2]; s[1][0][0] = G[7][xy.y+0][xy.x+0];
	s[1][0][1] = G[7][xy.y+0][xy.x+1]; s[1][0][2] = G[7][xy.y+0][xy.x+2];
	s[1][1][0] = G[7][xy.y+1][xy.x+0]; s[1][1][1] = G[7][xy.y+1][xy.x+1];
	s[1][1][2] = G[7][xy.y+1][xy.x+2]; s[1][2][0] = G[7][xy.y+2][xy.x+0];
	s[1][2][1] = G[7][xy.y+2][xy.x+1]; s[1][2][2] = G[7][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0D000606, 0x01E8012B, 0x06F6F304, 0x03F3F806);
	r1 = D(r1, s[0][0][0], 0xFFFCF6F9, 0x06F9F815, 0x01F8FDF9, 0x03F6F914);
	r2 = D(r2, s[0][0][0], 0x030001FD, 0xFCEAFFFF, 0xFA0BF9F2, 0x000406F5);
	r3 = D(r3, s[0][0][0], 0xFA11F90B, 0x0107FCDE, 0xF3080E01, 0x0701FFFF);
	r0 = D(r0, s[0][0][1], 0x03F90E0E, 0x0DF20307, 0xFF07EC18, 0x0AF5070B);
	r1 = D(r1, s[0][0][1], 0xF8F3F1E8, 0x0701F315, 0xFCF80008, 0xEF0407EB);
	r2 = D(r2, s[0][0][1], 0x120006F6, 0x0801F9F5, 0x040A03FA, 0xFDEFFFEE);
	r3 = D(r3, s[0][0][1], 0x0BF6FF00, 0xFC0B0608, 0xF8FA00F9, 0xEC070006);
	r0 = D(r0, s[0][0][2], 0x01FCFD18, 0xF9F50801, 0xF9F9EEFF, 0xFF08FC08);
	r1 = D(r1, s[0][0][2], 0x04040600, 0x00FA07EF, 0xFDFCF50D, 0xF8F903FF);
	r2 = D(r2, s[0][0][2], 0x1506F9F1, 0xFF0A0E01, 0x1106FAF9, 0x00F60BFF);
	r3 = D(r3, s[0][0][2], 0x00F60300, 0xFA0EFFEB, 0x0100070D, 0xF2F9FD08);
	r0 = D(r0, s[0][1][0], 0x01120118, 0x06F508E8, 0x06F2FAFD, 0x06F1FFEF);
	r1 = D(r1, s[0][1][0], 0x03F60101, 0xF9FF06F8, 0x12FFFA0F, 0x0FFFFCF8);
	r2 = D(r2, s[0][1][0], 0x04FCFDEB, 0x15FA06EE, 0x07070E0D, 0xE8E8FAE4);
	r3 = D(r3, s[0][1][0], 0xE00420E1, 0xEB15FA1D, 0xF60400F8, 0x0EFF0016);
	r0 = D(r0, s[0][1][1], 0x0007FAE0, 0x08EC0303, 0xF506EB0B, 0x0801F9EC);
	r1 = D(r1, s[0][1][1], 0xF90A1103, 0xFCF501F2, 0x1515F8F3, 0xEFF90EFF);
	r2 = D(r2, s[0][1][1], 0xE7FD070E, 0xFF160A06, 0xF5110304, 0x0B0707EA);
	r3 = D(r3, s[0][1][1], 0x2403FD04, 0xF91407EA, 0x080B0114, 0xE8ECFDEA);
	r0 = D(r0, s[0][1][2], 0xFCFDFF18, 0x06EF0311, 0xE4F5FAFF, 0x01F1FAF2);
	r1 = D(r1, s[0][1][2], 0xF5F8FCF6, 0x01010000, 0xF8F80316, 0x0A00F800);
	r2 = D(r2, s[0][1][2], 0xF5FF000E, 0x0F0AF9E8, 0x150DFFFD, 0x07E30719);
	r3 = D(r3, s[0][1][2], 0x01E8071C, 0x120DFAF9, 0x0DFF060A, 0xFAF603FD);
	r0 = D(r0, s[0][2][0], 0x00FDFD0B, 0xEE01FD07, 0x08F51100, 0x00FCF6F8);
	r1 = D(r1, s[0][2][0], 0x0AFA0101, 0xF5F80011, 0x00FA0B0E, 0xFFFA040D);
	r2 = D(r2, s[0][2][0], 0x1CF80616, 0x11F8060B, 0xF50EF9FC, 0x0BF60D0E);
	r3 = D(r3, s[0][2][0], 0xFDFC0D12, 0x0D03F6FC, 0xFA00FFF6, 0x0BFA01FD);
	r0 = D(r0, s[0][2][1], 0xF201FA0F, 0xFF03070A, 0x11EFFF16, 0x0E04FAE7);
	r1 = D(r1, s[0][2][1], 0xFCF604F6, 0xFFFF060E, 0x0B010004, 0xE80100FA);
	r2 = D(r2, s[0][2][1], 0x00F8000D, 0xFA04FD0B, 0x01FA0DFC, 0x0B01F90E);
	r3 = D(r3, s[0][2][1], 0x01FAFDE7, 0xF30803F1, 0x070304F6, 0x11FF01FC);
	r0 = D(r0, s[0][2][2], 0xF908FDFA, 0x0BFDFF15, 0xEA06FCD9, 0x08F9031F);
	r1 = D(r1, s[0][2][2], 0x14000B0F, 0xF9FAFAFC, 0x08FF06FD, 0x0FFAFF01);
	r2 = D(r2, s[0][2][2], 0x08F60104, 0xFC000AF8, 0x030AF9EA, 0x03F60312);
	r3 = D(r3, s[0][2][2], 0x06FF000A, 0xFFF80606, 0x06040303, 0x01FD000A);
	r0 = D(r0, s[1][0][0], 0xF8F1F9F9, 0x0B0703EA, 0xFCF2F2EE, 0xFDF50703);
	r1 = D(r1, s[1][0][0], 0x0EF21B0A, 0xFCF30406, 0xF900FCFC, 0x0EFC0AEF);
	r2 = D(r2, s[1][0][0], 0x04060AFC, 0x0DEF01F8, 0x040D06F9, 0x00EB0D00);
	r3 = D(r3, s[1][0][0], 0x00FAFFF9, 0x0304FD08, 0x1103F5F2, 0x00FD0003);
	r0 = D(r0, s[1][0][1], 0x06F6040F, 0x00F303FD, 0xFFEAF3FC, 0x08FF0001);
	r1 = D(r1, s[1][0][1], 0xF6111912, 0xE3FA0704, 0xF9040401, 0xFAF9F60F);
	r2 = D(r2, s[1][0][1], 0xFC040800, 0xEB04F50A, 0x00FFFCFF, 0x010319FD);
	r3 = D(r3, s[1][0][1], 0x0FFD07F5, 0xFF06F500, 0x04160DFD, 0xEBF6FFF9);
	r0 = D(r0, s[1][0][2], 0x0B08F9FF, 0xFCFC04F8, 0x00EBFFEF, 0xFF0300FD);
	r1 = D(r1, s[1][0][2], 0xF3FD0BF2, 0xF3F6F307, 0xF6F503FF, 0xFDFCF100);
	r2 = D(r2, s[1][0][2], 0xF203FD08, 0xF1F5F6F9, 0x00010703, 0x08F104FC);
	r3 = D(r3, s[1][0][2], 0xFCF5F1F8, 0xFF110106, 0x010D0707, 0x01FC0001);
	r0 = D(r0, s[1][1][0], 0x01F5FF01, 0x00FF00FD, 0xFFF3DA0F, 0xF80B0FFC);
	r1 = D(r1, s[1][1][0], 0xF3FCFAFC, 0x0DF9F60A, 0xF3FCFFF6, 0xFCF90314);
	r2 = D(r2, s[1][1][0], 0xF6E70DFD, 0x00F2EB11, 0xF306FFF2, 0x00001519);
	r3 = D(r3, s[1][1][0], 0x1D00EBF3, 0x06F5F9FF, 0x0AFA0FE1, 0x01F8F9F9);
	r0 = D(r0, s[1][1][1], 0xEA030408, 0x07010800, 0x01ECF511, 0x12F1FD00);
	r1 = D(r1, s[1][1][1], 0x07ECF100, 0xF5FDF307, 0xEC00F81B, 0x070AF9F9);
	r2 = D(r2, s[1][1][1], 0x0B00030F, 0xFCFAF2F6, 0x06F91107, 0x08F51103);
	r3 = D(r3, s[1][1][1], 0xF8F2FFFA, 0x00F8F50F, 0x0A0A0D1C, 0xF601F808);
	r0 = D(r0, s[1][1][2], 0xF6060DFC, 0x08FA0BF5, 0x1C04E4F5, 0x03040B0D);
	r1 = D(r1, s[1][1][2], 0x081200FA, 0xFAF9F607, 0x1606FC04, 0xF5F8F9EF);
	r2 = D(r2, s[1][1][2], 0xFDFFF8F8, 0xF6001108, 0xFCFA0AF1, 0x04FD0EEF);
	r3 = D(r3, s[1][1][2], 0xF104F318, 0x030AF8FF, 0x0E0A06F8, 0x0306F803);
	r0 = D(r0, s[1][2][0], 0x00000DFD, 0x08FC12FF, 0xECFDD9FC, 0xF1FC0100);
	r1 = D(r1, s[1][2][0], 0x00FF01F8, 0x1203F9F3, 0xFF03F6F6, 0x0104FAF1);
	r2 = D(r2, s[1][2][0], 0x03F90101, 0xF5060EFD, 0xF8FC060A, 0x0AF50404);
	r3 = D(r3, s[1][2][0], 0x0303E401, 0x12F8F50B, 0xF6FA0A0D, 0x00FDF8FD);
	r0 = D(r0, s[1][2][1], 0x0A030DF8, 0xF3F90E0B, 0xF3F5EA01, 0xF3EC1207);
	r1 = D(r1, s[1][2][1], 0x030306FA, 0x04FAFC0B, 0xFAF6FF11, 0x0FF60001);
	r2 = D(r2, s[1][2][1], 0xF308FDEC, 0xFA070AFC, 0x0007F207, 0xE0F21801);
	r3 = D(r3, s[1][2][1], 0xFDFC0419, 0x0BFFFA01, 0xF8F300FD, 0xF3FF0003);
	r0 = D(r0, s[1][2][2], 0xF5FD0DFD, 0xF3FA08FD, 0x0BF5EF0B, 0x0603FFF3);
	r1 = D(r1, s[1][2][2], 0xEBFAFD07, 0x08FD06FF, 0xFCFDF9EC, 0xF1FC00EF);
	r2 = D(r2, s[1][2][2], 0x04F9FA0A, 0x01FA04F2, 0xFC070006, 0xFDF603F5);
	r3 = D(r3, s[1][2][2], 0x07F8FAF5, 0xFDF6F6F1, 0xF60300F8, 0x03F8FD03);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-3.562e-04, 7.482e-03, -1.069e-02, 6.968e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(1.676e-02, 2.189e-02, 2.343e-02, -8.995e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(2.176e-02, 1.075e-02, -8.457e-03, 4.574e-03);
	imageStore(out_image, opos + ivec2(0, 1), vec4(f2));
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(6.028e-03, 7.082e-03, -4.255e-03, 1.257e-01);
	imageStore(out_image, opos + ivec2(1, 1), vec4(f3));
}

//!DESC CuNNy-4x16C-TEST-conv3
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE conv3
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[8][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv2_pt;
			r = conv2_gather(p, 0);
			g = conv2_gather(p, 1);
			b = conv2_gather(p, 2);
			a = conv2_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v2 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v4 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v6 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			vec4 v5 = max(-v4, vec4(0));
			v4 = max(v4, vec4(0));
			vec4 v7 = max(-v6, vec4(0));
			v6 = max(v6, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
			G[4][ay][ax] = int(packSnorm4x8(v4));
			G[5][ay][ax] = int(packSnorm4x8(v5));
			G[6][ay][ax] = int(packSnorm4x8(v6));
			G[7][ay][ax] = int(packSnorm4x8(v7));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x2100F7F3, 0x01020614, 0x0802FF10, 0x0C03FBF6);
	r1 = D(r1, s[0][0][0], 0x02F1FA00, 0xFAF8FBE2, 0x0903000C, 0xFB0102F6);
	r2 = D(r2, s[0][0][0], 0x1201FFE9, 0x1000010E, 0x0CFB02F7, 0xF9F703FB);
	r3 = D(r3, s[0][0][0], 0x0EFEFEF6, 0x05000307, 0xF70300E8, 0xF40906FB);
	r0 = D(r0, s[0][0][1], 0x05F0000F, 0xF1FF0109, 0x11F4010E, 0x0EFDFB05);
	r1 = D(r1, s[0][0][1], 0xFF060007, 0x090203E8, 0x07F9FAF3, 0xFDF7FFE1);
	r2 = D(r2, s[0][0][1], 0x15010902, 0x17FEF9E3, 0x11FFFF14, 0x03000903);
	r3 = D(r3, s[0][0][1], 0xEF02FEE3, 0x11FF0612, 0xF7FBF807, 0xE2FF06F8);
	r0 = D(r0, s[0][0][2], 0x1E03FAF7, 0xFB03FDFB, 0x07F7031C, 0x08FDFB09);
	r1 = D(r1, s[0][0][2], 0xF603FF00, 0xFFFB07E8, 0xFBFD0702, 0xFE050AF2);
	r2 = D(r2, s[0][0][2], 0xFD02F2FA, 0x0CFDF40A, 0xFE06FE03, 0x0EF7051D);
	r3 = D(r3, s[0][0][2], 0x0308F4EE, 0x05FEFD15, 0xFF060003, 0x000A08F8);
	r0 = D(r0, s[0][1][0], 0x0AFAF800, 0x05FFFB06, 0xFE010005, 0xFB06020F);
	r1 = D(r1, s[0][1][0], 0xFB07030C, 0x00FAF4F3, 0xFDFFFB09, 0xEC0506F7);
	r2 = D(r2, s[0][1][0], 0xF6F7F9EE, 0xFAFBF20C, 0xF2050D02, 0x03FA03F9);
	r3 = D(r3, s[0][1][0], 0xECFBFFE3, 0xF40206FE, 0x080A07FA, 0xF0FF08FF);
	r0 = D(r0, s[0][1][1], 0x17FD0105, 0x0708FD0F, 0xD30605E9, 0xFD02112F);
	r1 = D(r1, s[0][1][1], 0x0C05FBF9, 0xF4FAFEFD, 0x1400E80F, 0xF8FF0514);
	r2 = D(r2, s[0][1][1], 0x060611F8, 0xECFD0018, 0x151000F0, 0x08FD01EE);
	r3 = D(r3, s[0][1][1], 0xFAF405DF, 0xEE081409, 0xFFF6FDF6, 0x150E09F0);
	r0 = D(r0, s[0][1][2], 0x02F6F205, 0xF8F8F601, 0xFB010601, 0x0FF8F80C);
	r1 = D(r1, s[0][1][2], 0xFEFAF3F2, 0x0601F605, 0xF6FEF706, 0x0E0605FD);
	r2 = D(r2, s[0][1][2], 0xF9FE0905, 0xFF01F4FE, 0xF2FDEBE7, 0x06FE0207);
	r3 = D(r3, s[0][1][2], 0x12F90602, 0x08FF0011, 0xF706F9F3, 0xFB05FDFA);
	r0 = D(r0, s[0][2][0], 0x21F9030E, 0xE0FB0108, 0x09FAF60C, 0x0C0003FD);
	r1 = D(r1, s[0][2][0], 0x14F9FA0D, 0xF705FFF4, 0x0501FAF4, 0x01FF0206);
	r2 = D(r2, s[0][2][0], 0x0900FEF9, 0x09FE00FE, 0xF4FD0814, 0xF90100F7);
	r3 = D(r3, s[0][2][0], 0x0D0505EF, 0xFFFF00F9, 0xF2FEFA05, 0xFF0303FA);
	r0 = D(r0, s[0][2][1], 0x0306F1F8, 0xEFFDFD06, 0x09FEF912, 0xF20317E9);
	r1 = D(r1, s[0][2][1], 0x0C02F7FF, 0xFB051A10, 0x06FF05F4, 0xF40201FA);
	r2 = D(r2, s[0][2][1], 0x0D0005FE, 0x0A00F7FB, 0x0006FBF9, 0x0EFF01F6);
	r3 = D(r3, s[0][2][1], 0x0A080EEC, 0x06FF000D, 0x000500F6, 0x0805FDFD);
	r0 = D(r0, s[0][2][2], 0x03FE0C02, 0xFB08F909, 0x0C00FA0C, 0xFDFE07FF);
	r1 = D(r1, s[0][2][2], 0x0300F902, 0x07FF00F8, 0xFF07F6FD, 0xF9010606);
	r2 = D(r2, s[0][2][2], 0x06FDFF0A, 0xFFFDF4FB, 0xF4FBF4FB, 0x080707F3);
	r3 = D(r3, s[0][2][2], 0x02020A0C, 0x0102FBFD, 0xFE0A0605, 0xEC0209EF);
	r0 = D(r0, s[1][0][0], 0xFFE4F402, 0xFAF300FB, 0xF9D403F8, 0xF7F10509);
	r1 = D(r1, s[1][0][0], 0x03F809FB, 0xFB06FB11, 0x000600FE, 0x0023FFFF);
	r2 = D(r2, s[1][0][0], 0x08EBFE00, 0xFDD5FD0A, 0xF7FF08F9, 0x07FE02FD);
	r3 = D(r3, s[1][0][0], 0x00F70903, 0xFFE2FDF9, 0xFA1DFFFF, 0x050D0CF9);
	r0 = D(r0, s[1][0][1], 0xF7FDFFF6, 0xF70108F4, 0x02EBF7F0, 0xF4DF0308);
	r1 = D(r1, s[1][0][1], 0x0AE8EAF6, 0xFEF2FEFD, 0x010EF012, 0xE02F1DF9);
	r2 = D(r2, s[1][0][1], 0xFFE00F01, 0xF9E6F410, 0xF6E60A01, 0xFDEFECF1);
	r3 = D(r3, s[1][0][1], 0xF3170601, 0xF9E4FDEB, 0xF31F0005, 0x01250903);
	r0 = D(r0, s[1][0][2], 0xFFFDF30C, 0xF0FE10FF, 0xF6F407FF, 0x00EF0308);
	r1 = D(r1, s[1][0][2], 0x0007F2FB, 0xF4FDFBFD, 0xFD0DE7FF, 0x03110302);
	r2 = D(r2, s[1][0][2], 0xFE0A0E00, 0xFAE4FA00, 0xF8F20E00, 0xFFE91E07);
	r3 = D(r3, s[1][0][2], 0x050EF607, 0xEBF30802, 0xF31815FA, 0xFA060E07);
	r0 = D(r0, s[1][1][0], 0x0FE80106, 0xFBF60F0F, 0x07E10506, 0x0FEEF7F4);
	r1 = D(r1, s[1][1][0], 0x01F8F6FB, 0x06FE0605, 0x0914020E, 0xF610FDFD);
	r2 = D(r2, s[1][1][0], 0x09F30507, 0x05F6010C, 0x0AE0FF00, 0xF8F30303);
	r3 = D(r3, s[1][1][0], 0xFFF8FD00, 0x07E3FB05, 0xF30A03F1, 0xFF0A0800);
	r0 = D(r0, s[1][1][1], 0x1EEBF2FA, 0x03FAF702, 0x1DF7E701, 0x0DE40903);
	r1 = D(r1, s[1][1][1], 0x06F40EFF, 0x070DF3EA, 0xFD090E0A, 0xFF09DBF2);
	r2 = D(r2, s[1][1][1], 0x1DEE0DFB, 0x11DC0003, 0xF8F70906, 0xF6DA070A);
	r3 = D(r3, s[1][1][1], 0x0119EEFA, 0x10DB17FB, 0xEB23F0FD, 0xE2F2F906);
	r0 = D(r0, s[1][1][2], 0xFA09F106, 0x0900E906, 0x10EACB06, 0xFBE42101);
	r1 = D(r1, s[1][1][2], 0xF009EF06, 0xFFE70A0A, 0x0502EEF6, 0xF90CFA00);
	r2 = D(r2, s[1][1][2], 0xFF080D05, 0xF6E3F2FE, 0x02FE0C05, 0x03DD0600);
	r3 = D(r3, s[1][1][2], 0xF916E805, 0xF4E005F8, 0x0319FDFE, 0xF31A10FF);
	r0 = D(r0, s[1][2][0], 0x01EA0DFF, 0x0DE9F9FF, 0xFA0DFFFD, 0x05E2FE08);
	r1 = D(r1, s[1][2][0], 0xFF08EFFB, 0x00F7EFFB, 0x0102EF09, 0x090501F9);
	r2 = D(r2, s[1][2][0], 0x06E9EE01, 0x06F7FA03, 0xFFE701FF, 0x0003F7FD);
	r3 = D(r3, s[1][2][0], 0x07E6FB05, 0x06F1F000, 0x061D0DF8, 0xF8140EF2);
	r0 = D(r0, s[1][2][1], 0x07EBEF01, 0x0DFA1507, 0x03090106, 0x00DD0102);
	r1 = D(r1, s[1][2][1], 0xF8F70FFF, 0xFA01F3F9, 0x0612E602, 0xF9072705);
	r2 = D(r2, s[1][2][1], 0x01EC140A, 0xFDFFF100, 0x0ADFFF12, 0xF003F9F9);
	r3 = D(r3, s[1][2][1], 0xFBF60D06, 0x02EA1702, 0x05190C03, 0xF0141CFD);
	r0 = D(r0, s[1][2][2], 0x06FFF002, 0x01DF1A02, 0x08010F05, 0x02E6FB02);
	r1 = D(r1, s[1][2][2], 0x0A07EB02, 0x03F3F009, 0x030AFDFA, 0x0603FFFD);
	r2 = D(r2, s[1][2][2], 0x050A10FA, 0x00090C07, 0xFAEC1909, 0x01F0EB05);
	r3 = D(r3, s[1][2][2], 0x000A06FA, 0x05F00D0C, 0xFD081500, 0xFA0CF0F7);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0A0A02FB, 0xF4F1FB02, 0xE9F3FFF8, 0x0901FFFA);
	r1 = D(r1, s[0][0][0], 0x00060100, 0x17FB0306, 0xF20C0AF3, 0x0FF80500);
	r2 = D(r2, s[0][0][0], 0x1EFBF8FA, 0xF408FF0A, 0xFFFF0200, 0xFBE80502);
	r3 = D(r3, s[0][0][0], 0x0DF805FD, 0x05FA01FB, 0xF9FFFF00, 0x0807FB07);
	r0 = D(r0, s[0][0][1], 0x11050303, 0xEC11FFFB, 0xFDFF0000, 0x0DFB0105);
	r1 = D(r1, s[0][0][1], 0x060805FD, 0x16F302FA, 0xFE1717FD, 0xFE0A00EB);
	r2 = D(r2, s[0][0][1], 0x0202FFFF, 0x0AF7FB03, 0x08F90205, 0x091A0100);
	r3 = D(r3, s[0][0][1], 0xEF02FE01, 0x080D05FF, 0x0605F905, 0x07FFFB02);
	r0 = D(r0, s[0][0][2], 0x0F150002, 0xFF0100F7, 0x010E02FD, 0xFD0106FE);
	r1 = D(r1, s[0][0][2], 0x010F0108, 0x0518F805, 0x0EFBFDFE, 0xFB0105F6);
	r2 = D(r2, s[0][0][2], 0xFEF90205, 0x03060003, 0xF90CF7F9, 0x0A0200FB);
	r3 = D(r3, s[0][0][2], 0xFF03FFFD, 0x02F905FD, 0x0205FFFE, 0xFBF7FAFD);
	r0 = D(r0, s[0][1][0], 0x070008F7, 0xEF0D0703, 0xE8EF06FF, 0x0DF6FD00);
	r1 = D(r1, s[0][1][0], 0x1810FEEE, 0x00F10706, 0x09FAFE12, 0x0E07F80C);
	r2 = D(r2, s[0][1][0], 0x1803EBF6, 0x0AF306F3, 0x07EEFF01, 0x20FB0202);
	r3 = D(r3, s[0][1][0], 0x05110AF2, 0x140EF3FA, 0xE0080101, 0xF106F906);
	r0 = D(r0, s[0][1][1], 0x1418E403, 0x02D4F70C, 0x200CF3FB, 0x0A0DFA07);
	r1 = D(r1, s[0][1][1], 0xF2E10E0F, 0x272606FB, 0xF00EFB10, 0xD9002100);
	r2 = D(r2, s[0][1][1], 0xF005FE03, 0xFE1DF202, 0x0F0CFE06, 0x001606FE);
	r3 = D(r3, s[0][1][1], 0x06E7F8F8, 0x07210105, 0xEAF60AF7, 0x12E7F1FD);
	r0 = D(r0, s[0][1][2], 0xFA1410FA, 0xFFF2000C, 0x00F6F907, 0x07FEFE03);
	r1 = D(r1, s[0][1][2], 0xFDFF0507, 0x0018FB07, 0xFF17FA02, 0x0CFE09F9);
	r2 = D(r2, s[0][1][2], 0xF2010303, 0xFDF6F9FD, 0xFEF902F3, 0x1502F10D);
	r3 = D(r3, s[0][1][2], 0xF4F40EF9, 0x2303F606, 0x03F60909, 0x050508F6);
	r0 = D(r0, s[0][2][0], 0x12FFFBF1, 0x0EF1F400, 0x02FD0EFE, 0x0D06F4F9);
	r1 = D(r1, s[0][2][0], 0x05060A06, 0x14FEFFFA, 0xFE0DFE00, 0x07FFF909);
	r2 = D(r2, s[0][2][0], 0x0A07FDF8, 0x090805FD, 0xEEFAFA00, 0x0DFF0706);
	r3 = D(r3, s[0][2][0], 0x0510FD09, 0x03FEFA06, 0xF3F7FB10, 0x0CFEFF0F);
	r0 = D(r0, s[0][2][1], 0x0809FD05, 0x060DF901, 0x05FBFA02, 0x12FFE408);
	r1 = D(r1, s[0][2][1], 0xE30615FD, 0x24EB07FF, 0x031007FE, 0x06E80108);
	r2 = D(r2, s[0][2][1], 0x00FAFAF4, 0xF00202F9, 0x0514FFFA, 0x0D070CF8);
	r3 = D(r3, s[0][2][1], 0x1105F9FB, 0x00020306, 0xF70D060A, 0xDF111AFE);
	r0 = D(r0, s[0][2][2], 0xFA00F4F9, 0xF7FDF606, 0xF309FA01, 0x08FD05FD);
	r1 = D(r1, s[0][2][2], 0x02F2FF07, 0x0C18F903, 0xFEFAF306, 0xFEF303FF);
	r2 = D(r2, s[0][2][2], 0x030103FF, 0x000005FB, 0xF6FE0306, 0x0506F7FA);
	r3 = D(r3, s[0][2][2], 0x02050706, 0xFDF900FF, 0xF107F803, 0xFAFEFDF2);
	r0 = D(r0, s[1][0][0], 0xFDFE06F6, 0x0009000D, 0xF900050F, 0xFB01FF03);
	r1 = D(r1, s[1][0][0], 0x0007F407, 0x03F601D2, 0xF001F624, 0x0DFD01DC);
	r2 = D(r2, s[1][0][0], 0xF8FEFD0E, 0xF10C0AFE, 0x05F7FEFE, 0x03060216);
	r3 = D(r3, s[1][0][0], 0x06FA0308, 0x00090315, 0xF4FE0D0A, 0xF4FEFF0D);
	r0 = D(r0, s[1][0][1], 0x00FBF4F1, 0x02F7FBFB, 0xF8FD07FF, 0xF608F9F7);
	r1 = D(r1, s[1][0][1], 0xFA03F801, 0x01FB0103, 0x0208F710, 0x03F4FEF4);
	r2 = D(r2, s[1][0][1], 0xFEFEE8FB, 0xFA070015, 0xFBFBF7EA, 0x00F2F120);
	r3 = D(r3, s[1][0][1], 0x0509F6EB, 0xF4FAFE01, 0xFFF4F911, 0x05FFFD07);
	r0 = D(r0, s[1][0][2], 0xF3F7FD03, 0xFE0D0109, 0x010809F8, 0x05FA0008);
	r1 = D(r1, s[1][0][2], 0xF7000502, 0xFFFE0CEC, 0x09F4F711, 0xF7F9FF03);
	r2 = D(r2, s[1][0][2], 0xFF09FBEE, 0x080502FD, 0xFF0110F7, 0x0306FD05);
	r3 = D(r3, s[1][0][2], 0xF8F7000D, 0x070608FB, 0xF701030D, 0x02030511);
	r0 = D(r0, s[1][1][0], 0xF700E326, 0xFDFBF326, 0x01FFF117, 0xF80EFD20);
	r1 = D(r1, s[1][1][0], 0x00F801F1, 0x000C00F0, 0xF8E60F17, 0x0715FEDD);
	r2 = D(r2, s[1][1][0], 0xE40103F8, 0xF101FB1D, 0x07F20535, 0xF8F90ECE);
	r3 = D(r3, s[1][1][0], 0x000707EB, 0xEA050809, 0x11FD020A, 0x0705FA06);
	r0 = D(r0, s[1][1][1], 0x06F000E9, 0xF70D10EB, 0xF309DCF3, 0x1401EB21);
	r1 = D(r1, s[1][1][1], 0x070A05F8, 0x0EF8FADF, 0xF9060734, 0x1201F8EF);
	r2 = D(r2, s[1][1][1], 0xFE02DDF9, 0x00F2E802, 0x06E4FED5, 0x01FFF9E4);
	r3 = D(r3, s[1][1][1], 0x03FAF3F9, 0x060CD035, 0x12F2071F, 0x08061E19);
	r0 = D(r0, s[1][1][2], 0xF91CEEF4, 0x01EF0908, 0x03F8F105, 0x0709F3F8);
	r1 = D(r1, s[1][1][2], 0xFDFEFDF1, 0x0900F9DB, 0x0603F815, 0xEFF900FD);
	r2 = D(r2, s[1][1][2], 0x05F906E8, 0x00FEFDF2, 0xFA050CF8, 0x11FBEE00);
	r3 = D(r3, s[1][1][2], 0xFF01F2FD, 0x07ECE909, 0xF707FB24, 0xF8FD070D);
	r0 = D(r0, s[1][2][0], 0x02000601, 0xF4FF0907, 0x01F8F9F8, 0x14F8F600);
	r1 = D(r1, s[1][2][0], 0x08FA03EC, 0xF8070CDF, 0x0102080A, 0xF8FEFF09);
	r2 = D(r2, s[1][2][0], 0xFEFB00EF, 0xFDFEF9FB, 0x03020D14, 0x0200FFEE);
	r3 = D(r3, s[1][2][0], 0x06F4FD0F, 0x06FBFFF7, 0xFBFF0210, 0xFF070708);
	r0 = D(r0, s[1][2][1], 0x05FEECEA, 0x0501E717, 0x0907FB06, 0x0607EBE4);
	r1 = D(r1, s[1][2][1], 0x0000EFEC, 0x0CF30300, 0xFE00002C, 0x0D0103F4);
	r2 = D(r2, s[1][2][1], 0x0505F4E9, 0xFBFB0002, 0x0200EA21, 0xFD0508E7);
	r3 = D(r3, s[1][2][1], 0xFE0CF3F1, 0x11F9F4FE, 0xF402FF10, 0xEB021711);
	r0 = D(r0, s[1][2][2], 0x06FE0105, 0x12070A0D, 0x000CF6FB, 0x01FDF8F7);
	r1 = D(r1, s[1][2][2], 0x0807FFEC, 0xFB01F9EF, 0x00010010, 0x020906FE);
	r2 = D(r2, s[1][2][2], 0xFEFEF400, 0xFEFB0202, 0x120201FB, 0xFB02F4FA);
	r3 = D(r3, s[1][2][2], 0x09FAFB00, 0x0A05F1F9, 0x0709101A, 0x00F31121);
	s[0][0][0] = G[4][xy.y+0][xy.x+0]; s[0][0][1] = G[4][xy.y+0][xy.x+1];
	s[0][0][2] = G[4][xy.y+0][xy.x+2]; s[0][1][0] = G[4][xy.y+1][xy.x+0];
	s[0][1][1] = G[4][xy.y+1][xy.x+1]; s[0][1][2] = G[4][xy.y+1][xy.x+2];
	s[0][2][0] = G[4][xy.y+2][xy.x+0]; s[0][2][1] = G[4][xy.y+2][xy.x+1];
	s[0][2][2] = G[4][xy.y+2][xy.x+2]; s[1][0][0] = G[5][xy.y+0][xy.x+0];
	s[1][0][1] = G[5][xy.y+0][xy.x+1]; s[1][0][2] = G[5][xy.y+0][xy.x+2];
	s[1][1][0] = G[5][xy.y+1][xy.x+0]; s[1][1][1] = G[5][xy.y+1][xy.x+1];
	s[1][1][2] = G[5][xy.y+1][xy.x+2]; s[1][2][0] = G[5][xy.y+2][xy.x+0];
	s[1][2][1] = G[5][xy.y+2][xy.x+1]; s[1][2][2] = G[5][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFF180906, 0xF9F60702, 0x18190906, 0x000801FF);
	r1 = D(r1, s[0][0][0], 0x092D0EF8, 0xF9E206F9, 0x09F1FB0A, 0x050000FE);
	r2 = D(r2, s[0][0][0], 0x02E300FF, 0xFDFAFF05, 0xFF210801, 0x0112FFFA);
	r3 = D(r3, s[0][0][0], 0x0514FFFD, 0x031406FB, 0x01E2FBFF, 0xFDF2FBFF);
	r0 = D(r0, s[0][0][1], 0xF203FDF4, 0x0DF701FD, 0x08F902E6, 0xFF02000D);
	r1 = D(r1, s[0][0][1], 0x03FEF7FA, 0x01EFFE00, 0xF9DF0200, 0x09EB0EFD);
	r2 = D(r2, s[0][0][1], 0xEEFFEEFB, 0xFAFB01F3, 0x09F9FD02, 0x00240009);
	r3 = D(r3, s[0][0][1], 0x000AFF05, 0xF41CF3FF, 0x01F70E03, 0xFEFB02F7);
	r0 = D(r0, s[0][0][2], 0xFBF7FA02, 0x05F902FE, 0xFFFD02E3, 0x060CF7FE);
	r1 = D(r1, s[0][0][2], 0x08FFF402, 0xF9F90108, 0xF1CE07F6, 0x06F910FD);
	r2 = D(r2, s[0][0][2], 0x000EFD01, 0x0DF902F8, 0xF4F4FE06, 0x02F00300);
	r3 = D(r3, s[0][0][2], 0xFBE705F7, 0x0AF406FD, 0xF415020E, 0x01FD0101);
	r0 = D(r0, s[0][1][0], 0xFEFDF902, 0xFF0F00F6, 0xFAE10001, 0xFFFF0505);
	r1 = D(r1, s[0][1][0], 0xFF01030C, 0xFEE30803, 0x05D40A05, 0xEC07EBEE);
	r2 = D(r2, s[0][1][0], 0x0702F8F0, 0xFBD50CFF, 0x0C0D0505, 0x000602F9);
	r3 = D(r3, s[0][1][0], 0x061FFF00, 0xFFF200FE, 0x0F1DFEFE, 0x0111FDFE);
	r0 = D(r0, s[0][1][1], 0xF4080E07, 0xF8DCF612, 0xEE1409F8, 0x032EFD03);
	r1 = D(r1, s[0][1][1], 0x02ECF8FF, 0xFD33F3F0, 0xF1C400FE, 0xF6F9FB07);
	r2 = D(r2, s[0][1][1], 0x0A150803, 0x12FDFDF9, 0x090FF915, 0xFFF1EEF9);
	r3 = D(r3, s[0][1][1], 0xFB070E03, 0xF419EFFE, 0xFA2C0EE6, 0x05F1080F);
	r0 = D(r0, s[0][1][2], 0x02E0DFF2, 0x03010015, 0xF9061207, 0xFD0105FB);
	r1 = D(r1, s[0][1][2], 0xF1EC00EB, 0x071E0E05, 0x08F8070A, 0xFAFFF6FA);
	r2 = D(r2, s[0][1][2], 0xF8FFF401, 0x060111FF, 0x0E0FF924, 0x011208EB);
	r3 = D(r3, s[0][1][2], 0x02F8FA02, 0xF91505F8, 0x0208EA05, 0x07F8F0FF);
	r0 = D(r0, s[0][2][0], 0x09FAF7F9, 0x07DFFDF8, 0x03FAFA09, 0x0514FE09);
	r1 = D(r1, s[0][2][0], 0x0003F702, 0xFDF7F403, 0xFAE90300, 0x0C0701FF);
	r2 = D(r2, s[0][2][0], 0xFF17010C, 0x060DFBFD, 0xFBFD06F6, 0xF1E9FBFF);
	r3 = D(r3, s[0][2][0], 0x01340E02, 0xF9FB0109, 0x00F402F7, 0xFDFEFBFF);
	r0 = D(r0, s[0][2][1], 0x05E1070D, 0x121D02F2, 0x0203FF09, 0xFF00FDF9);
	r1 = D(r1, s[0][2][1], 0xF4DC0507, 0x07EB00F9, 0x0AE9FAEF, 0xF7EAF705);
	r2 = D(r2, s[0][2][1], 0xF9FB0100, 0x05F1FEFF, 0x1419FAFA, 0xF402F810);
	r3 = D(r3, s[0][2][1], 0xFD0F0106, 0x0503FE02, 0xFF1F0207, 0xFB0FF7FF);
	r0 = D(r0, s[0][2][2], 0xFAF20C01, 0x00060703, 0xFEF6F308, 0x0106FAFF);
	r1 = D(r1, s[0][2][2], 0x06F8F3FE, 0xF30C0C03, 0x05F20105, 0x09F6EC07);
	r2 = D(r2, s[0][2][2], 0x0005FB08, 0x07FDFEF9, 0xFD1503FB, 0x051A0801);
	r3 = D(r3, s[0][2][2], 0xFB08F20A, 0x07FEFFFD, 0xFD03FF01, 0x03050A06);
	r0 = D(r0, s[1][0][0], 0xFB0710FD, 0x14FD02FB, 0x03FAFDF3, 0x09070300);
	r1 = D(r1, s[1][0][0], 0x08FD01FE, 0xFD020201, 0xE6F80106, 0x0F0301F4);
	r2 = D(r2, s[1][0][0], 0xF801FEF3, 0xF0FB030D, 0x0A05FDF9, 0x01030802);
	r3 = D(r3, s[1][0][0], 0xFBFFFA01, 0xFEFEFEFE, 0x0707020A, 0x0F000105);
	r0 = D(r0, s[1][0][1], 0xE8020FFE, 0x200EFEF7, 0x0703EF07, 0xFBFA00FF);
	r1 = D(r1, s[1][0][1], 0xEBFAF405, 0xFF0EF9EC, 0xFA0305FB, 0xF1FDF4F0);
	r2 = D(r2, s[1][0][1], 0x05FFF812, 0x1109F903, 0xFFFF0603, 0x120003F3);
	r3 = D(r3, s[1][0][1], 0xF3FFFE00, 0x1706F2FA, 0xFFFE0EF7, 0x0505030D);
	r0 = D(r0, s[1][0][2], 0x1106FAFF, 0x00FD00F0, 0xFAF8E8FD, 0x0501FA02);
	r1 = D(r1, s[1][0][2], 0xFBFAFEFE, 0x0F06EFFE, 0xF9030CF4, 0xF10700E8);
	r2 = D(r2, s[1][0][2], 0x07FAFFFA, 0xF1F6EF01, 0x0806FF03, 0x0D02F60E);
	r3 = D(r3, s[1][0][2], 0xF40803F0, 0xFDF4EFFE, 0x17020D05, 0x06050C08);
	r0 = D(r0, s[1][1][0], 0x0905EBF3, 0x0FFFFA0E, 0xFBEFE20A, 0x0FFF01FE);
	r1 = D(r1, s[1][1][0], 0xF9FBE9EC, 0x0700F901, 0xF9F6EE0F, 0xF603150D);
	r2 = D(r2, s[1][1][0], 0x0103FD01, 0xF405EEFE, 0x0EF30AF6, 0xF807F805);
	r3 = D(r3, s[1][1][0], 0xF8FA02FF, 0xF40F010C, 0xF40001FD, 0xF8F20D01);
	r0 = D(r0, s[1][1][1], 0xE1F3E212, 0xF40507F0, 0xDFEFCA11, 0x27FBF915);
	r1 = D(r1, s[1][1][1], 0xEEF3E3F0, 0x020710F9, 0x090C09FD, 0xF8F719FF);
	r2 = D(r2, s[1][1][1], 0xF3F3E608, 0xEC0CDF1A, 0x1505F2FB, 0xF1050CF4);
	r3 = D(r3, s[1][1][1], 0x0F09EE07, 0xFE090500, 0xFDFE0A15, 0x0E06FAEB);
	r0 = D(r0, s[1][1][2], 0x140D07E6, 0xF8FBF806, 0xEB07C903, 0x0606F701);
	r1 = D(r1, s[1][1][2], 0x060109F9, 0xFDFE0C10, 0xF0EF0011, 0x08F917EC);
	r2 = D(r2, s[1][1][2], 0x140A1501, 0xF4FB0609, 0x0C05110A, 0xF7F1F318);
	r3 = D(r3, s[1][1][2], 0x03F6FAEB, 0xF3F1FD1A, 0x090016FB, 0x0D061E02);
	r0 = D(r0, s[1][2][0], 0xF9F908F6, 0xF4FEFE09, 0x01F605F4, 0x0002F9FE);
	r1 = D(r1, s[1][2][0], 0x03F900FF, 0xFB100809, 0xF9FBFF09, 0x07FB02F9);
	r2 = D(r2, s[1][2][0], 0x01FB05F4, 0xF8F9F9FE, 0xFF08F301, 0x07050605);
	r3 = D(r3, s[1][2][0], 0x00F003FA, 0x08FF0300, 0x0C01060D, 0x120109FD);
	r0 = D(r0, s[1][2][1], 0xEB020D0A, 0xFDF7E616, 0x0203FDF8, 0x0EFFEFFE);
	r1 = D(r1, s[1][2][1], 0x060F12F3, 0xEFFDF400, 0xF9FD0A05, 0x1707F8EA);
	r2 = D(r2, s[1][2][1], 0x0D08F200, 0xF8060A01, 0xF6F9DA0E, 0x08F817F1);
	r3 = D(r3, s[1][2][1], 0x060206FA, 0x0C0102F7, 0x09FA0D02, 0x0E031F00);
	r0 = D(r0, s[1][2][2], 0xF9FD12EE, 0x00F9E019, 0xF9010900, 0x00FDFF06);
	r1 = D(r1, s[1][2][2], 0xF6FD0AF4, 0x0D10070C, 0xF2F71D15, 0x0CFEFBF4);
	r2 = D(r2, s[1][2][2], 0x01FFF900, 0xF8051209, 0x06FAE607, 0xF2FF1003);
	r3 = D(r3, s[1][2][2], 0x0E00F908, 0xFB081509, 0x0E02F300, 0xFD05EF08);
	s[0][0][0] = G[6][xy.y+0][xy.x+0]; s[0][0][1] = G[6][xy.y+0][xy.x+1];
	s[0][0][2] = G[6][xy.y+0][xy.x+2]; s[0][1][0] = G[6][xy.y+1][xy.x+0];
	s[0][1][1] = G[6][xy.y+1][xy.x+1]; s[0][1][2] = G[6][xy.y+1][xy.x+2];
	s[0][2][0] = G[6][xy.y+2][xy.x+0]; s[0][2][1] = G[6][xy.y+2][xy.x+1];
	s[0][2][2] = G[6][xy.y+2][xy.x+2]; s[1][0][0] = G[7][xy.y+0][xy.x+0];
	s[1][0][1] = G[7][xy.y+0][xy.x+1]; s[1][0][2] = G[7][xy.y+0][xy.x+2];
	s[1][1][0] = G[7][xy.y+1][xy.x+0]; s[1][1][1] = G[7][xy.y+1][xy.x+1];
	s[1][1][2] = G[7][xy.y+1][xy.x+2]; s[1][2][0] = G[7][xy.y+2][xy.x+0];
	s[1][2][1] = G[7][xy.y+2][xy.x+1]; s[1][2][2] = G[7][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x020201FE, 0x0605FAFE, 0x05F40803, 0x02F20808);
	r1 = D(r1, s[0][0][0], 0x01020305, 0xFD0301F7, 0xFF0A0000, 0xFA080EFB);
	r2 = D(r2, s[0][0][0], 0x0A0602FE, 0x05F4FD06, 0xFE0705FE, 0xFE05FBFF);
	r3 = D(r3, s[0][0][0], 0x030205F9, 0x03FD06FD, 0x000CF7F9, 0xFB0A0205);
	r0 = D(r0, s[0][0][1], 0x0808F6FB, 0xF8FE0206, 0xFE080908, 0xF90601FA);
	r1 = D(r1, s[0][0][1], 0xFD10FE01, 0x06EE09FB, 0xFD11F9EE, 0xFFF809FD);
	r2 = D(r2, s[0][0][1], 0x001008F6, 0xFB0DF8F4, 0xFEFE0508, 0x02FD0703);
	r3 = D(r3, s[0][0][1], 0x030A01F7, 0xFD100902, 0x0AEC0A11, 0xF40200F4);
	r0 = D(r0, s[0][0][2], 0xF705FDFA, 0x02FA05FF, 0x010DFDF2, 0x0005F903);
	r1 = D(r1, s[0][0][2], 0x0EFA020D, 0x01F1FD08, 0x06FF0207, 0x01FEFE08);
	r2 = D(r2, s[0][0][2], 0x0507F902, 0xFE09F8FE, 0x07FF09FE, 0xFA0503FD);
	r3 = D(r3, s[0][0][2], 0x0606FA02, 0x0500FE0C, 0xFD0AFAF4, 0xFEFF08FF);
	r0 = D(r0, s[0][1][0], 0x0208F615, 0xFBFAF6FB, 0xFD06FE15, 0x02FFFD0D);
	r1 = D(r1, s[0][1][0], 0xFEF808FE, 0xFD070609, 0xFA060301, 0x090F00FF);
	r2 = D(r2, s[0][1][0], 0x080DF4FF, 0x0205FE00, 0xFB000603, 0x0103020D);
	r3 = D(r3, s[0][1][0], 0x0503F6F6, 0x03F7FE07, 0x01F709F8, 0x030900F8);
	r0 = D(r0, s[0][1][1], 0x05FF0803, 0x0910F002, 0x071CF4F1, 0x09FF0AFD);
	r1 = D(r1, s[0][1][1], 0xF312EC02, 0xFDEB0305, 0x0710E8FE, 0xF0FA2EFA);
	r2 = D(r2, s[0][1][1], 0x000A0A01, 0x01FA0F07, 0x09F8F9F6, 0xFDE0E8FE);
	r3 = D(r3, s[0][1][1], 0xF8170EEE, 0x071AFB0C, 0xFE0A0CFA, 0x1200F801);
	r0 = D(r0, s[0][1][2], 0x0C00F8F3, 0x000EFA02, 0xFFFE01F8, 0x08EEF705);
	r1 = D(r1, s[0][1][2], 0x0106FE02, 0xFDF1FDF8, 0xF806FAFF, 0xFDFE0AFE);
	r2 = D(r2, s[0][1][2], 0x00FD030D, 0x02F407FF, 0xFEF7F6F1, 0x0102FFFB);
	r3 = D(r3, s[0][1][2], 0xF8110101, 0xFE0603FD, 0xF818F7FB, 0xFE0AFF0C);
	r0 = D(r0, s[0][2][0], 0x01F8FE08, 0xFDF40514, 0xF9F20207, 0xFFF70002);
	r1 = D(r1, s[0][2][0], 0x070AFE01, 0x09F301F9, 0x00FEF7F8, 0xFB01FBFB);
	r2 = D(r2, s[0][2][0], 0xFBFD0200, 0xFF030000, 0xF8FEFD12, 0x0C08FF01);
	r3 = D(r3, s[0][2][0], 0xFFFF0502, 0xF7FE05FD, 0x010EF80E, 0xFF0F0502);
	r0 = D(r0, s[0][2][1], 0xFD0500FA, 0xFAF7F102, 0x0903F308, 0x0CFBFDFF);
	r1 = D(r1, s[0][2][1], 0x0214F406, 0xFF03FD01, 0xF90DFE02, 0xFB00F602);
	r2 = D(r2, s[0][2][1], 0x05FDFDFF, 0xFE070EFE, 0xFFFE050A, 0xFA0303F4);
	r3 = D(r3, s[0][2][1], 0x0603F4FA, 0xF809F600, 0xF60CF606, 0xFE0A0503);
	r0 = D(r0, s[0][2][2], 0x03FAFF05, 0xF8F6EFFE, 0xFB06F2FA, 0xF1EEFFF8);
	r1 = D(r1, s[0][2][2], 0xFFF9F805, 0xF800FEF7, 0x0C000306, 0xFF020002);
	r2 = D(r2, s[0][2][2], 0x0106F7FD, 0x0806FD00, 0x02EBF3F9, 0x050A0E01);
	r3 = D(r3, s[0][2][2], 0x00090503, 0x02030003, 0xFB0601FE, 0xF8091609);
	r0 = D(r0, s[1][0][0], 0x32FA0F12, 0x0CFE0FFE, 0x060E290C, 0x3E0800FB);
	r1 = D(r1, s[1][0][0], 0x11FA070A, 0x27FAF90E, 0xFA021705, 0xC9F90205);
	r2 = D(r2, s[1][0][0], 0x08F4FD0C, 0x4BFF0103, 0x0A08FF05, 0xEAFA0507);
	r3 = D(r3, s[1][0][0], 0xFDFFF4FF, 0x1AFD0805, 0xC20008FB, 0xF6FA01FD);
	r0 = D(r0, s[1][0][1], 0xF9FEFE07, 0x1E070200, 0xC105FE0C, 0x56FBFD0D);
	r1 = D(r1, s[1][0][1], 0x24F00C0C, 0x25FDFEFF, 0x1FFE0C19, 0xBBFA07FA);
	r2 = D(r2, s[1][0][1], 0xB3FAEA0C, 0x2BFE1C15, 0x17FFF9FB, 0xCB07F80D);
	r3 = D(r3, s[1][0][1], 0x0EFDFFFF, 0xE400030F, 0xC209EEE6, 0xEE06EA05);
	r0 = D(r0, s[1][0][2], 0x250D030D, 0xD509F102, 0xE405EE14, 0x32FF0809);
	r1 = D(r1, s[1][0][2], 0x260E03F7, 0x5E090AFF, 0xB30100EE, 0xE9090803);
	r2 = D(r2, s[1][0][2], 0x30000A03, 0xD5F10706, 0x110306FD, 0xE2F8DD15);
	r3 = D(r3, s[1][0][2], 0xDA0705FB, 0xF406F208, 0xCC01FFFD, 0xE0F8ECF6);
	r0 = D(r0, s[1][1][0], 0xD0F60DFF, 0x0700FB03, 0x18EBF902, 0x4BF61201);
	r1 = D(r1, s[1][1][0], 0x0508080A, 0xF3FE16EF, 0x1CF30C06, 0xE602FAF7);
	r2 = D(r2, s[1][1][0], 0x1E01FF0A, 0x24FE1A0E, 0xFD05F602, 0xF1FA0000);
	r3 = D(r3, s[1][1][0], 0x1803F809, 0x56FF0209, 0xBFFDFBF6, 0x1D0CEB03);
	r0 = D(r0, s[1][1][1], 0x8908F626, 0x1CFAF9FF, 0x88F9DB1C, 0x3010E31E);
	r1 = D(r1, s[1][1][1], 0x44F6070E, 0x0109FD02, 0x07080003, 0x01F614E2);
	r2 = D(r2, s[1][1][1], 0x99E9FD06, 0x8D00DC08, 0x00EA0317, 0xADFDE903);
	r3 = D(r3, s[1][1][1], 0x0DFEF914, 0x81ECE01C, 0x17F8EFF3, 0x72F903FA);
	r0 = D(r0, s[1][1][2], 0x25020C07, 0x0E0012F0, 0xE1FA050E, 0x3AF30009);
	r1 = D(r1, s[1][1][2], 0x1D030EE8, 0x5603020A, 0x0E0C0EFF, 0xE7150FF2);
	r2 = D(r2, s[1][1][2], 0x20050103, 0xFFFAFEF9, 0x38030C0D, 0xEFF90E27);
	r3 = D(r3, s[1][1][2], 0xEB01FA0D, 0xCA00001C, 0xF1F90DFF, 0x0802F7E9);
	r0 = D(r0, s[1][2][0], 0xD3F90309, 0xE101F9FF, 0xF8091000, 0x5D09E605);
	r1 = D(r1, s[1][2][0], 0xF90007FD, 0x3601F7FE, 0x1C010201, 0x0E080CFF);
	r2 = D(r2, s[1][2][0], 0x2E03F605, 0x260307FD, 0x02FDF001, 0xE6F80CFF);
	r3 = D(r3, s[1][2][0], 0x0106FFFF, 0x1DFF0901, 0xD4FA18FF, 0x12FFF2F8);
	r0 = D(r0, s[1][2][1], 0x18FF0205, 0x98FFEC0C, 0x250F08F0, 0x3B06F705);
	r1 = D(r1, s[1][2][1], 0x42EB0CF9, 0x2FF10808, 0x29010105, 0xFD020203);
	r2 = D(r2, s[1][2][1], 0x14FBF709, 0x030001FB, 0xAF00E208, 0x24F9F800);
	r3 = D(r3, s[1][2][1], 0x3AF9EA20, 0x21FDF6FF, 0xDD071008, 0x1002ECF8);
	r0 = D(r0, s[1][2][2], 0xF005FE01, 0xFEFAFB05, 0x2300FBFD, 0x42FEFD06);
	r1 = D(r1, s[1][2][2], 0x180C07FF, 0x61E9F1F9, 0x1005FFFB, 0xFB0302FA);
	r2 = D(r2, s[1][2][2], 0x02030509, 0xFE030102, 0x07F9FF08, 0x0102F6FF);
	r3 = D(r3, s[1][2][2], 0x09060810, 0x01FAFDF2, 0x01F9E308, 0xC3060805);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-2.102e-02, -5.198e-03, -3.107e-03, -9.862e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-2.531e-03, 3.512e-03, 2.847e-03, 1.726e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(-1.821e-02, -5.214e-03, -5.871e-03, -5.490e-03);
	imageStore(out_image, opos + ivec2(0, 1), vec4(f2));
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(9.568e-03, -8.102e-04, -2.636e-03, 1.736e-03);
	imageStore(out_image, opos + ivec2(1, 1), vec4(f3));
}

//!DESC CuNNy-4x16C-TEST-conv4
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv3
//!BIND LUMA
//!SAVE conv4
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[8][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv3_pt;
			r = conv3_gather(p, 0);
			g = conv3_gather(p, 1);
			b = conv3_gather(p, 2);
			a = conv3_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v2 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v4 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v6 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			vec4 v5 = max(-v4, vec4(0));
			v4 = max(v4, vec4(0));
			vec4 v7 = max(-v6, vec4(0));
			v6 = max(v6, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
			G[4][ay][ax] = int(packSnorm4x8(v4));
			G[5][ay][ax] = int(packSnorm4x8(v5));
			G[6][ay][ax] = int(packSnorm4x8(v6));
			G[7][ay][ax] = int(packSnorm4x8(v7));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x00FCF6F5, 0x0214F106, 0xFDFFFF03, 0xF30AFF01);
	r1 = D(r1, s[0][0][0], 0x031A0606, 0xFF08FD0F, 0x070F0000, 0x0100FAFF);
	r2 = D(r2, s[0][0][0], 0xFC0AF510, 0x08F814F5, 0xF9F5F7F5, 0xF613FCFD);
	r3 = D(r3, s[0][0][0], 0x01F0F8F6, 0xF911F90E, 0x03F306F6, 0xEC050908);
	r0 = D(r0, s[0][0][1], 0x03170F06, 0xF6FE0CEB, 0x020CFF12, 0xFB05EDFB);
	r1 = D(r1, s[0][0][1], 0x01F8EDE0, 0xFD04150C, 0x06EAF0E8, 0x0AF1DCF0);
	r2 = D(r2, s[0][0][1], 0x10F8E9F5, 0x19FD0305, 0xFFFCF60F, 0xF10D140B);
	r3 = D(r3, s[0][0][1], 0x17F1FEFD, 0x0604F212, 0xFF101412, 0xEC0A09F8);
	r0 = D(r0, s[0][0][2], 0x020C03F9, 0x02FAF817, 0x03FBF8E6, 0xFC0A06EA);
	r1 = D(r1, s[0][0][2], 0xFE05082E, 0x01F308DE, 0xF307FFFD, 0xFCF3F5FF);
	r2 = D(r2, s[0][0][2], 0xFE03F1FC, 0xFA0100F5, 0xFF08FCE3, 0xF709D9FB);
	r3 = D(r3, s[0][0][2], 0x0DFAFAFD, 0xFB08FCFA, 0xFD061BF6, 0xFF0309EE);
	r0 = D(r0, s[0][1][0], 0x0400FA0C, 0x01090E17, 0xFDF601F4, 0xFD0B0010);
	r1 = D(r1, s[0][1][0], 0x030AFC19, 0xFC0DF8FD, 0x0908FD14, 0xFF2AFAFF);
	r2 = D(r2, s[0][1][0], 0xFAFCFDFB, 0x0416FDFB, 0x04FBF0E3, 0xFFF90508);
	r3 = D(r3, s[0][1][0], 0x0701FDDE, 0x0516082B, 0x03F9011A, 0xF7F2FC0D);
	r0 = D(r0, s[0][1][1], 0x06F1E2F6, 0xF9EB16D2, 0xF30A0411, 0xECFF032B);
	r1 = D(r1, s[0][1][1], 0xE30810CD, 0x01FCFE12, 0x06FB08E6, 0x0524F525);
	r2 = D(r2, s[0][1][1], 0xCD1E172B, 0xFC1211D0, 0xEE0B1B21, 0x12D3E20A);
	r3 = D(r3, s[0][1][1], 0x03FDC6F8, 0x03101FD6, 0xFEE0FD08, 0xE7FA1222);
	r0 = D(r0, s[0][1][2], 0x041004FF, 0xF80AFC17, 0x0603FAF8, 0xF1FFF310);
	r1 = D(r1, s[0][1][2], 0x100FEA18, 0xFBF008FD, 0xF7F0E90C, 0xFF20FBDE);
	r2 = D(r2, s[0][1][2], 0xF71C03F7, 0xFE13EA0A, 0x0AFFFB22, 0xF7E3EEFB);
	r3 = D(r3, s[0][1][2], 0xF5F106BD, 0xFA07F9E3, 0x04F4F92C, 0xF5FA01E9);
	r0 = D(r0, s[0][2][0], 0xFF170D03, 0x02FCFD13, 0x0000FFFB, 0x03090125);
	r1 = D(r1, s[0][2][0], 0xFF09FFFE, 0x00EE0103, 0x03090701, 0x03EC030F);
	r2 = D(r2, s[0][2][0], 0x01F800FF, 0x07F90409, 0x03EF0323, 0xFD03FDF5);
	r3 = D(r3, s[0][2][0], 0x0007F804, 0x03050110, 0xFD0101F5, 0xFDF6FD08);
	r0 = D(r0, s[0][2][1], 0x03030D01, 0xF60A1FD7, 0xFD1003F5, 0xFD160DF1);
	r1 = D(r1, s[0][2][1], 0x050F08F6, 0xFBF00109, 0xFCFFF9F4, 0xF1D716E0);
	r2 = D(r2, s[0][2][1], 0x0308F8F0, 0x011D05FD, 0xFFF1F7F0, 0xF5140409);
	r3 = D(r3, s[0][2][1], 0xFF1BFF03, 0x04EFF6FE, 0xFF080C14, 0x01FA00F2);
	r0 = D(r0, s[0][2][2], 0x00FDFFFC, 0x060DF1F7, 0x03010102, 0x060D0110);
	r1 = D(r1, s[0][2][2], 0xFEF5FC0F, 0x04FA030B, 0x09F1FB04, 0x02F3E521);
	r2 = D(r2, s[0][2][2], 0x0A04F30E, 0x06FCF2F0, 0x00FEF8F5, 0xF9301914);
	r3 = D(r3, s[0][2][2], 0x0611FE1E, 0xFB04FBF1, 0xFFFC09FA, 0xFC03F5F1);
	r0 = D(r0, s[1][0][0], 0x07FAFEFE, 0xFF01F6FC, 0x04FF01FF, 0x06FD02FD);
	r1 = D(r1, s[1][0][0], 0x07F8FCF8, 0xFA01FC03, 0xFCFDFA00, 0xFEFC0401);
	r2 = D(r2, s[1][0][0], 0xFFFFFC00, 0xF6FA0100, 0x07FEFD06, 0x020504FF);
	r3 = D(r3, s[1][0][0], 0x02FE03FD, 0x050401FF, 0xFCFAFF04, 0x16010AFC);
	r0 = D(r0, s[1][0][1], 0xF300FFFC, 0x0801FCF5, 0x03FA08FE, 0xEEFC00FC);
	r1 = D(r1, s[1][0][1], 0x0800FAFC, 0xEC0404FB, 0xF905FDFF, 0xFCF90802);
	r2 = D(r2, s[1][0][1], 0xECFF03F5, 0xF902FE01, 0x01FE0706, 0x0DFFED02);
	r3 = D(r3, s[1][0][1], 0xE9F00A04, 0x0B09EFF6, 0x16020004, 0x1601FFFA);
	r0 = D(r0, s[1][0][2], 0xF5FD0801, 0x08010401, 0x07FFFFFC, 0xFD03FCFD);
	r1 = D(r1, s[1][0][2], 0x0F000602, 0xF203FA01, 0x06010504, 0xFAFA0B01);
	r2 = D(r2, s[1][0][2], 0xF5FA0DFF, 0xFD000506, 0x0401FDFB, 0x2107F6F8);
	r3 = D(r3, s[1][0][2], 0xF103F701, 0x080101FD, 0x0FFDFDFC, 0x1504FDFE);
	r0 = D(r0, s[1][1][0], 0xFFFEFBFB, 0xFF00FEFF, 0xFF080001, 0xF8FBFF00);
	r1 = D(r1, s[1][1][0], 0x14F7FD05, 0xF803FFFF, 0x02F8FF04, 0xFF0902FD);
	r2 = D(r2, s[1][1][0], 0x03080B02, 0x09FFFC07, 0x05FB06FA, 0xFC0003FD);
	r3 = D(r3, s[1][1][0], 0xEEF7FB0A, 0x0BFA04F5, 0x08060303, 0x10FF01FD);
	r0 = D(r0, s[1][1][1], 0xFE01FAF2, 0x1417F30A, 0x0F03030A, 0x0608FD00);
	r1 = D(r1, s[1][1][1], 0x08FCFB05, 0xF2000AFD, 0xF000FEF6, 0x0C0BE6F9);
	r2 = D(r2, s[1][1][1], 0x210E060A, 0x03FBF312, 0xE908F701, 0x0304EC04);
	r3 = D(r3, s[1][1][1], 0xF5E90705, 0xF9FA0104, 0x0C09F1FE, 0x16FD0401);
	r0 = D(r0, s[1][1][2], 0xF5060603, 0x02FC0C06, 0x02F80304, 0x00FF01FC);
	r1 = D(r1, s[1][1][2], 0xF5FD02F8, 0xFD06FC02, 0x04FF04F5, 0xFBFCFD04);
	r2 = D(r2, s[1][1][2], 0x0FFC0B0D, 0x0DF609FE, 0xF0FF0D01, 0x0EF8F3F4);
	r3 = D(r3, s[1][1][2], 0xFAFFFC03, 0x09F801FC, 0x10F90102, 0x0D0200FF);
	r0 = D(r0, s[1][2][0], 0xFCFC02FE, 0x0F0501FF, 0x010500FF, 0xFCFDFFFC);
	r1 = D(r1, s[1][2][0], 0xFD01FFFF, 0x00FD03FF, 0x01FC01FF, 0xFC0AFF03);
	r2 = D(r2, s[1][2][0], 0xFA0301FE, 0x0306F7FC, 0xFDFF02FF, 0x05FF0301);
	r3 = D(r3, s[1][2][0], 0x01030201, 0x02FFFD01, 0xFD030300, 0x00FD0A01);
	r0 = D(r0, s[1][2][1], 0xFDFC06FF, 0xF505FA01, 0x03FD01FF, 0x0306FAFC);
	r1 = D(r1, s[1][2][1], 0x09FCF8FC, 0x0400FEFD, 0x0304FE00, 0xFEF8150C);
	r2 = D(r2, s[1][2][1], 0xF8FFF803, 0x0CF8FDFC, 0x01010005, 0xFC0700FA);
	r3 = D(r3, s[1][2][1], 0xFF0402F8, 0x08FEFD05, 0x00FAFDFD, 0x10FFFD02);
	r0 = D(r0, s[1][2][2], 0xFE080804, 0x03FD0208, 0x03FF0101, 0xFA00FCFE);
	r1 = D(r1, s[1][2][2], 0x06FFFD04, 0xFD04FD01, 0xF8FDFD04, 0x09F80101);
	r2 = D(r2, s[1][2][2], 0x05FCF2F8, 0x01F70602, 0xFE0102FA, 0x010402FF);
	r3 = D(r3, s[1][2][2], 0x0302FCF6, 0x07FC0303, 0xFD000001, 0x0FFF0203);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x030004FC, 0x04030A01, 0xFD060C05, 0x04FDFAFD);
	r1 = D(r1, s[0][0][0], 0x0108160F, 0x02FFF503, 0x03FDFCFD, 0x060AFAFF);
	r2 = D(r2, s[0][0][0], 0xFA040404, 0x0503FF10, 0xFDF6F8EE, 0x05FD0403);
	r3 = D(r3, s[0][0][0], 0x0805FCFA, 0xFFF90D02, 0xF8010A0C, 0xF6FC06FA);
	r0 = D(r0, s[0][0][1], 0xF5FEFD06, 0xFC04090A, 0xFD04030B, 0xFE00F4FC);
	r1 = D(r1, s[0][0][1], 0xF0FCFE03, 0x06FCF408, 0xFD02E8F4, 0x0610020A);
	r2 = D(r2, s[0][0][1], 0x010FFF19, 0xF7010920, 0x050CFF0A, 0xF1FD1201);
	r3 = D(r3, s[0][0][1], 0x0DFCE2D0, 0x0D0601F9, 0xF6040D0D, 0x0D01FD03);
	r0 = D(r0, s[0][0][2], 0xF80404F6, 0xFAF6FD03, 0xFF0401FD, 0x00FFFCED);
	r1 = D(r1, s[0][0][2], 0x09F6FAFC, 0xFA040104, 0xFEF4FDFB, 0x090400FF);
	r2 = D(r2, s[0][0][2], 0x0AF6FDF3, 0xFE050208, 0x0300FF00, 0xE50505FF);
	r3 = D(r3, s[0][0][2], 0x0903FE04, 0x03F800FB, 0xFB0208F6, 0x00FBFF08);
	r0 = D(r0, s[0][1][0], 0x0206F3F1, 0xF2FC0B06, 0x02010406, 0xF8FBEBFD);
	r1 = D(r1, s[0][1][0], 0xFA030A09, 0x0402FC03, 0x04060303, 0xF2ED06F7);
	r2 = D(r2, s[0][1][0], 0x00F300FF, 0xF804F910, 0xF7FFFEEA, 0xFBFA05FC);
	r3 = D(r3, s[0][1][0], 0x0610FC12, 0xFCFCFDFC, 0xFDFFFB03, 0x07FF02FA);
	r0 = D(r0, s[0][1][1], 0xEC00F2EE, 0x0901032F, 0x14F6FD17, 0xF6F60216);
	r1 = D(r1, s[0][1][1], 0x05F30A27, 0x06F0F0F8, 0xFD01FAE3, 0xE9F6F806);
	r2 = D(r2, s[0][1][1], 0x12F60D22, 0xECFEF825, 0xE9FAFD1F, 0x0902FD14);
	r3 = D(r3, s[0][1][1], 0xF3FC0107, 0x120E05F1, 0x0C030918, 0x16FAFFF1);
	r0 = D(r0, s[0][1][2], 0x02F6F304, 0xFEFB040B, 0xF80F01F5, 0x02FBFF08);
	r1 = D(r1, s[0][1][2], 0xFD060CF9, 0xF7FD02FB, 0xECEE0AE3, 0xF5F3F8FD);
	r2 = D(r2, s[0][1][2], 0x0A060804, 0xF8F7FAF5, 0x0202FCF7, 0x1413FE0F);
	r3 = D(r3, s[0][1][2], 0xEEFE021E, 0x0DFD03F8, 0x0801FCF8, 0x0502FFFD);
	r0 = D(r0, s[0][2][0], 0x06070000, 0xFDFCFB03, 0xFD0303FD, 0x01FD01FD);
	r1 = D(r1, s[0][2][0], 0xFDFA03FC, 0x0408FB01, 0x0500FC01, 0x0101030A);
	r2 = D(r2, s[0][2][0], 0xF2FD05FE, 0x080506FD, 0x010300FD, 0x06FDFD01);
	r3 = D(r3, s[0][2][0], 0x0200FD04, 0x00FC0301, 0x04FD0403, 0xFC04FC02);
	r0 = D(r0, s[0][2][1], 0xF9F1010C, 0x0706FE0A, 0x08FAFF01, 0xFAF601F9);
	r1 = D(r1, s[0][2][1], 0x060603F7, 0x03FEFD0E, 0xFAFE0A04, 0x1B0F05FD);
	r2 = D(r2, s[0][2][1], 0xFB0802EF, 0x08FD0000, 0xF5F1FC15, 0x120003F6);
	r3 = D(r3, s[0][2][1], 0xFDFB05FF, 0x0106FF03, 0x03FD01F6, 0x0DFDFB03);
	r0 = D(r0, s[0][2][2], 0xF8FE010F, 0xFD03FD03, 0xFD03FFFA, 0x07FF0100);
	r1 = D(r1, s[0][2][2], 0x020AFF03, 0x01FA0104, 0xF7F80105, 0x1A04081B);
	r2 = D(r2, s[0][2][2], 0x0108FFEC, 0x020601FF, 0x0805FEF2, 0x07F603FE);
	r3 = D(r3, s[0][2][2], 0xFCF8FEFD, 0x0203FEFF, 0x040203FE, 0x0104FD03);
	r0 = D(r0, s[1][0][0], 0xFF030401, 0xFDFD0009, 0x0206FA04, 0x0B0204FD);
	r1 = D(r1, s[1][0][0], 0xFEF6FB0A, 0x05FD05FE, 0xFFF30203, 0x070101F5);
	r2 = D(r2, s[1][0][0], 0x0503F6FF, 0xF7EE0603, 0x0A0703FA, 0xF6FD0103);
	r3 = D(r3, s[1][0][0], 0x0CFDFEF9, 0x0100FE07, 0xFD03FD04, 0x0E130107);
	r0 = D(r0, s[1][0][1], 0xF607F9F6, 0x06090403, 0xFEF90102, 0xFF10FBFE);
	r1 = D(r1, s[1][0][1], 0x030D0700, 0x0B0BF3FF, 0x00170703, 0x0E06FD04);
	r2 = D(r2, s[1][0][1], 0x09030401, 0x040BFC01, 0xFDFF0308, 0xF5FFFD03);
	r3 = D(r3, s[1][0][1], 0xF6F10203, 0xF9F50005, 0xF603F902, 0xFCF60602);
	r0 = D(r0, s[1][0][2], 0xFC01FEFF, 0x01FFF9FC, 0xFE02FCFC, 0xFB050202);
	r1 = D(r1, s[1][0][2], 0xFDF9F604, 0x0603FCFD, 0x010803FF, 0x0AFFFB01);
	r2 = D(r2, s[1][0][2], 0x07FFFBFD, 0xFBFD08FD, 0xFE0408FF, 0xFB080BFE);
	r3 = D(r3, s[1][0][2], 0xFCFFF1FD, 0x03FE05FC, 0xFD050406, 0xFD030101);
	r0 = D(r0, s[1][1][0], 0x08080801, 0xFD01F7FD, 0xFE0B0802, 0xF9000F0B);
	r1 = D(r1, s[1][1][0], 0xF8071102, 0x14FFF9FF, 0xFCFAFCFC, 0xFD08FB09);
	r2 = D(r2, s[1][1][0], 0xECFCFC06, 0xF8FF1208, 0x04F6E3FF, 0x060302FE);
	r3 = D(r3, s[1][1][0], 0x03FC0C03, 0x06040106, 0x06040A08, 0xFF0E0C09);
	r0 = D(r0, s[1][1][1], 0x0F10FA0C, 0xF5242109, 0xFAFA1B0E, 0x0A100304);
	r1 = D(r1, s[1][1][1], 0x0B0D1F01, 0xF9E7F316, 0xF3140404, 0xFEF8F0F8);
	r2 = D(r2, s[1][1][1], 0xE2FD1B03, 0x191116F3, 0x09FEFAFD, 0xF40300F8);
	r3 = D(r3, s[1][1][1], 0x3403F302, 0xCB0A1903, 0x04FE1701, 0xE50C3117);
	r0 = D(r0, s[1][1][2], 0xFFFBF800, 0x0B0302FD, 0xFF07FFF6, 0x04010801);
	r1 = D(r1, s[1][1][2], 0xFDEEE203, 0x01FDF8F8, 0x16F2E5F5, 0xF5FC07FF);
	r2 = D(r2, s[1][1][2], 0xE7090AFB, 0x010A12F6, 0xFF080DFC, 0xF70D1E0E);
	r3 = D(r3, s[1][1][2], 0x0DFD0104, 0xF90F0B03, 0xFFFC0AFD, 0x080F0B06);
	r0 = D(r0, s[1][2][0], 0xF106FDF2, 0xFDF8FF04, 0x03F7FD02, 0xF504FDFB);
	r1 = D(r1, s[1][2][0], 0x06FE0107, 0x05010600, 0xFA0E0B01, 0xF5F3F700);
	r2 = D(r2, s[1][2][0], 0x0BFCF603, 0xF3060407, 0xF8F8F8FF, 0xFDFBFAFE);
	r3 = D(r3, s[1][2][0], 0xFD020803, 0x00FCF6FA, 0x000103FC, 0x04FB0606);
	r0 = D(r0, s[1][2][1], 0x09FCF4FA, 0xF81A0BF9, 0xFC1808FB, 0x040B04FA);
	r1 = D(r1, s[1][2][1], 0xFB180DFA, 0x01FDF4FF, 0x08FAF8FD, 0xE0181200);
	r2 = D(r2, s[1][2][1], 0xF91109FD, 0x030D1703, 0x0FF60602, 0xFBFDF103);
	r3 = D(r3, s[1][2][1], 0xFFFD0802, 0x0BF20400, 0xF5FDFCFF, 0x06081803);
	r0 = D(r0, s[1][2][2], 0x01FBFE00, 0x0307FEFC, 0xFD010100, 0x01070A01);
	r1 = D(r1, s[1][2][2], 0xFBFA000A, 0x0104F801, 0x03FDFAF8, 0xEDFBFF00);
	r2 = D(r2, s[1][2][2], 0x050A0AF8, 0xFE0B0B03, 0x00081507, 0xF60BF3FC);
	r3 = D(r3, s[1][2][2], 0xFDFA0804, 0x010A0600, 0x0209F900, 0x04120806);
	s[0][0][0] = G[4][xy.y+0][xy.x+0]; s[0][0][1] = G[4][xy.y+0][xy.x+1];
	s[0][0][2] = G[4][xy.y+0][xy.x+2]; s[0][1][0] = G[4][xy.y+1][xy.x+0];
	s[0][1][1] = G[4][xy.y+1][xy.x+1]; s[0][1][2] = G[4][xy.y+1][xy.x+2];
	s[0][2][0] = G[4][xy.y+2][xy.x+0]; s[0][2][1] = G[4][xy.y+2][xy.x+1];
	s[0][2][2] = G[4][xy.y+2][xy.x+2]; s[1][0][0] = G[5][xy.y+0][xy.x+0];
	s[1][0][1] = G[5][xy.y+0][xy.x+1]; s[1][0][2] = G[5][xy.y+0][xy.x+2];
	s[1][1][0] = G[5][xy.y+1][xy.x+0]; s[1][1][1] = G[5][xy.y+1][xy.x+1];
	s[1][1][2] = G[5][xy.y+1][xy.x+2]; s[1][2][0] = G[5][xy.y+2][xy.x+0];
	s[1][2][1] = G[5][xy.y+2][xy.x+1]; s[1][2][2] = G[5][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0DF60408, 0xFD0B05FF, 0xF8FDFCFC, 0x0501010D);
	r1 = D(r1, s[0][0][0], 0x0D0308F5, 0xFC1BFEFF, 0x08060205, 0xFFFA03FD);
	r2 = D(r2, s[0][0][0], 0xFBFBFCFC, 0x0CF8FAF8, 0xF7FD0105, 0xFD08FF01);
	r3 = D(r3, s[0][0][0], 0xFCFDFBFC, 0x00FAF601, 0x06FA04FF, 0xF404FF09);
	r0 = D(r0, s[0][0][1], 0xFC000B0F, 0x03EDF0F6, 0x04FBFCFA, 0xF60415FD);
	r1 = D(r1, s[0][0][1], 0x0FE6E9F8, 0xEE0900F1, 0xF9FF0F10, 0x00FDFDEB);
	r2 = D(r2, s[0][0][1], 0x00F5FEF3, 0x0FEEF5F8, 0x000C0B05, 0x0AEF1203);
	r3 = D(r3, s[0][0][1], 0xF20F0706, 0xF8EC03F8, 0x08FD010B, 0xFA0FFF09);
	r0 = D(r0, s[0][0][2], 0xFAFE00FB, 0x03070608, 0x0301FEFA, 0x06010106);
	r1 = D(r1, s[0][0][2], 0xFD0B0A03, 0x06FAFD08, 0x0508FF11, 0xFCFFFAF6);
	r2 = D(r2, s[0][0][2], 0xFC06FA01, 0x08FFF4FB, 0x01FEF500, 0x04010C09);
	r3 = D(r3, s[0][0][2], 0xFF00FAF8, 0x0401FE04, 0x00FBFA03, 0x0AFD0408);
	r0 = D(r0, s[0][1][0], 0xE703F203, 0xF5FC0904, 0x06F312F5, 0x1312F306);
	r1 = D(r1, s[0][1][0], 0xF6FB0318, 0x1B04FEED, 0x0208F117, 0x03FA0CFC);
	r2 = D(r2, s[0][1][0], 0xF90AFF0A, 0x0001140B, 0x0B0F00F8, 0x04FD03F6);
	r3 = D(r3, s[0][1][0], 0x12FE04FD, 0x0801EE14, 0x08FCF5FF, 0x01EFE9F8);
	r0 = D(r0, s[0][1][1], 0xF80A08E5, 0x0FD918EF, 0x120408FC, 0x1401C7EB);
	r1 = D(r1, s[0][1][1], 0x20FA0297, 0xEF0214FD, 0xFDFC16EE, 0xF101F603);
	r2 = D(r2, s[0][1][1], 0x0F0D0F0C, 0xFDEFEEF4, 0xF102D21D, 0xFE0AF51D);
	r3 = D(r3, s[0][1][1], 0xFF160DEF, 0xF8F7F600, 0x0EFFCDF7, 0x12F00DFA);
	r0 = D(r0, s[0][1][2], 0xF8041309, 0x02FC0BF0, 0xFDFCFDF4, 0x08FA0213);
	r1 = D(r1, s[0][1][2], 0xE8031001, 0x09FC0E08, 0x0212EDFF, 0xF1030324);
	r2 = D(r2, s[0][1][2], 0x14F6F8FD, 0x140FF503, 0x06FAF1FA, 0x1D05F4E2);
	r3 = D(r3, s[0][1][2], 0x01FF0CF7, 0x0CFDFDE6, 0x03FFF416, 0x0BFCFCEE);
	r0 = D(r0, s[0][2][0], 0xEAFF0A06, 0xF601F600, 0x00FDFCF1, 0xFC01FA12);
	r1 = D(r1, s[0][2][0], 0xFFF6FEFF, 0x1106F1F5, 0x0DFF0305, 0x10020102);
	r2 = D(r2, s[0][2][0], 0x0AF604F3, 0x0BF4010F, 0x0F01FAFC, 0xF50BFD04);
	r3 = D(r3, s[0][2][0], 0x04FE06F8, 0xFC02030B, 0x0208FD0A, 0xFAF8F309);
	r0 = D(r0, s[0][2][1], 0xF1FAFF1D, 0x05EEFEE3, 0x02FDFCFF, 0x03FB12E9);
	r1 = D(r1, s[0][2][1], 0x19FA15E4, 0x060405F1, 0xFD010BFF, 0x38DE20FF);
	r2 = D(r2, s[0][2][1], 0xFDFDF711, 0x150103F2, 0xFC081ADC, 0x0001FBF5);
	r3 = D(r3, s[0][2][1], 0xFD090601, 0x01FC09FC, 0x01FDFC03, 0x14F8E90A);
	r0 = D(r0, s[0][2][2], 0xFFFB08EF, 0x0C12FA05, 0x030004FC, 0x0502EF0E);
	r1 = D(r1, s[0][2][2], 0xF603030A, 0x04020E08, 0xF6040321, 0x1B0002FA);
	r2 = D(r2, s[0][2][2], 0x0004F807, 0x03FDDFFB, 0x01FDF5EE, 0xFDFCFA24);
	r3 = D(r3, s[0][2][2], 0x0801FFEA, 0x04FA06F4, 0xFA02FA03, 0x0800FFFD);
	r0 = D(r0, s[1][0][0], 0xFD040203, 0xFE060102, 0x06FA03FC, 0xF806FA03);
	r1 = D(r1, s[1][0][0], 0xFC0D0802, 0x01F6FAFF, 0xFB00FF01, 0x00FDFBFC);
	r2 = D(r2, s[1][0][0], 0x0201FD00, 0xFC0009FC, 0x01FB0206, 0x010A0701);
	r3 = D(r3, s[1][0][0], 0x00F6F600, 0x01070103, 0xFF0305FB, 0x09F9FF01);
	r0 = D(r0, s[1][0][1], 0x08FD0601, 0x090BFD06, 0xF8FC0101, 0xFFFA0207);
	r1 = D(r1, s[1][0][1], 0x02FB0308, 0x0AFFFD0D, 0x020AFCFA, 0xFEFCFC04);
	r2 = D(r2, s[1][0][1], 0x0808FDFE, 0xFFFA0404, 0xF6FC01F5, 0xF50D06FC);
	r3 = D(r3, s[1][0][1], 0x01F30AFF, 0x190CFDFD, 0xF9F60800, 0xFEF3FCFD);
	r0 = D(r0, s[1][0][2], 0x010703FF, 0xF902F7FC, 0xFD00FE02, 0xFEFC0203);
	r1 = D(r1, s[1][0][2], 0x010301FC, 0xF603F802, 0xFBFE060D, 0x05FC0104);
	r2 = D(r2, s[1][0][2], 0x00F5040D, 0xF5FD01FF, 0x0102FF02, 0x02F203FC);
	r3 = D(r3, s[1][0][2], 0xFC060407, 0x03F8FF04, 0x03FC04FC, 0xFDFFF5FE);
	r0 = D(r0, s[1][1][0], 0x06010D00, 0x0FFDFF06, 0x08F5F9FE, 0xF8031103);
	r1 = D(r1, s[1][1][0], 0x06FAFFFF, 0xFF0C0008, 0xFC090103, 0xFCFE06FD);
	r2 = D(r2, s[1][1][0], 0x080801FD, 0x03F40FF5, 0xF30F10FF, 0xFFF1FC05);
	r3 = D(r3, s[1][1][0], 0xF50107FA, 0x040C0504, 0xFC010000, 0xF8ED03FF);
	r0 = D(r0, s[1][1][1], 0x0304F5FA, 0x05F8F1F3, 0x0AF6F7FC, 0x03100706);
	r1 = D(r1, s[1][1][1], 0x12020A07, 0x03FDF8FB, 0xF00409F8, 0x13080DFC);
	r2 = D(r2, s[1][1][1], 0x0E010301, 0x0DFC0303, 0x08FC0003, 0x04F7FAF2);
	r3 = D(r3, s[1][1][1], 0xFA111701, 0xECF608EB, 0x05F9FA07, 0xF1DBEFFA);
	r0 = D(r0, s[1][1][2], 0xF307F3FF, 0xFD01FE0F, 0xFDFD080F, 0x0303F9FF);
	r1 = D(r1, s[1][1][2], 0xFA00FCEE, 0xF90CFE0B, 0xFB03FCFB, 0x0AF80308);
	r2 = D(r2, s[1][1][2], 0x0301FCFA, 0x02E8FE03, 0x03F40204, 0x15FFFF0D);
	r3 = D(r3, s[1][1][2], 0xFDF80A08, 0x08F8FC00, 0x0201FDF8, 0xFCFCF608);
	r0 = D(r0, s[1][2][0], 0x0706FF01, 0x0108F801, 0x01FD01F9, 0xF6000600);
	r1 = D(r1, s[1][2][0], 0xF9F5F306, 0x01030802, 0x0106FC09, 0x02FB01FD);
	r2 = D(r2, s[1][2][0], 0xF6F50301, 0xF101F900, 0xF0FC06FF, 0x0300FBFF);
	r3 = D(r3, s[1][2][0], 0xFFFD01FD, 0xFD00FC06, 0x03FAFBFE, 0x04FF09FA);
	r0 = D(r0, s[1][2][1], 0x0207F503, 0x0A080301, 0x0101FF0D, 0x0006F405);
	r1 = D(r1, s[1][2][1], 0xFE000910, 0xF00909F5, 0x010C04EC, 0xF1FCF3FA);
	r2 = D(r2, s[1][2][1], 0xFD000BFB, 0x02FFFE0C, 0x04FF04F8, 0x0304F40F);
	r3 = D(r3, s[1][2][1], 0x01F6FF09, 0x01FE0BFF, 0x0104F0FF, 0xF3010BFD);
	r0 = D(r0, s[1][2][2], 0x02FF0204, 0x01FD01F8, 0x04FD010A, 0x0001F804);
	r1 = D(r1, s[1][2][2], 0xFF03FCF3, 0xFCFF0308, 0x00F6F3FA, 0xF9F401FF);
	r2 = D(r2, s[1][2][2], 0x01FFFE0D, 0x08FBFC0B, 0x0401F907, 0x0C07FBFC);
	r3 = D(r3, s[1][2][2], 0x08010401, 0x01FC06FA, 0xF805F801, 0x03FA0906);
	s[0][0][0] = G[6][xy.y+0][xy.x+0]; s[0][0][1] = G[6][xy.y+0][xy.x+1];
	s[0][0][2] = G[6][xy.y+0][xy.x+2]; s[0][1][0] = G[6][xy.y+1][xy.x+0];
	s[0][1][1] = G[6][xy.y+1][xy.x+1]; s[0][1][2] = G[6][xy.y+1][xy.x+2];
	s[0][2][0] = G[6][xy.y+2][xy.x+0]; s[0][2][1] = G[6][xy.y+2][xy.x+1];
	s[0][2][2] = G[6][xy.y+2][xy.x+2]; s[1][0][0] = G[7][xy.y+0][xy.x+0];
	s[1][0][1] = G[7][xy.y+0][xy.x+1]; s[1][0][2] = G[7][xy.y+0][xy.x+2];
	s[1][1][0] = G[7][xy.y+1][xy.x+0]; s[1][1][1] = G[7][xy.y+1][xy.x+1];
	s[1][1][2] = G[7][xy.y+1][xy.x+2]; s[1][2][0] = G[7][xy.y+2][xy.x+0];
	s[1][2][1] = G[7][xy.y+2][xy.x+1]; s[1][2][2] = G[7][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x02FAFAF3, 0x0403FD01, 0xFC080206, 0x00F7F601);
	r1 = D(r1, s[0][0][0], 0x060CF50C, 0x03F308F7, 0x0BF4F3F3, 0xFC04FA03);
	r2 = D(r2, s[0][0][0], 0x0604FA06, 0xF3FFF2FD, 0xFBFA0FF9, 0xFB040504);
	r3 = D(r3, s[0][0][0], 0x06FBFDFB, 0x0601F800, 0xFA080106, 0x020B0310);
	r0 = D(r0, s[0][0][1], 0x04FE03EC, 0x01030602, 0x0804F6FF, 0x05FC0A08);
	r1 = D(r1, s[0][0][1], 0xF9030804, 0x08F31BFB, 0xF6FA0A0A, 0xFC040604);
	r2 = D(r2, s[0][0][1], 0xFC0FF30E, 0x040BF509, 0x06E9F600, 0x0F070316);
	r3 = D(r3, s[0][0][1], 0xFCF202E0, 0xF616F707, 0x05FCF60B, 0xFD03F8F6);
	r0 = D(r0, s[0][0][2], 0x000206F9, 0xFD06FA03, 0xFD010004, 0xFBFC0200);
	r1 = D(r1, s[0][0][2], 0xFFFBFEFF, 0x03FA05FD, 0xFDEA0401, 0xFCFF04FF);
	r2 = D(r2, s[0][0][2], 0x0106010B, 0x0102F601, 0x01010004, 0x00FD0F0E);
	r3 = D(r3, s[0][0][2], 0xF502FFF8, 0x0302FD05, 0x06FCFF04, 0xFF03F9FD);
	r0 = D(r0, s[0][1][0], 0x06F001FF, 0x0EFF0304, 0xF8070B04, 0xFFF00B04);
	r1 = D(r1, s[0][1][0], 0x0300EF03, 0x05F8170C, 0x04FBEE0A, 0x0DF80BFC);
	r2 = D(r2, s[0][1][0], 0xF90401F9, 0xFA00FD13, 0xFD041708, 0x030603FE);
	r3 = D(r3, s[0][1][0], 0xFB030402, 0x0FF3E303, 0xFEF8F602, 0xF703FAFD);
	r0 = D(r0, s[0][1][1], 0xFC01FF0B, 0xF403F802, 0x0005DCF3, 0x0700F706);
	r1 = D(r1, s[0][1][1], 0x1204E8EC, 0x021922F4, 0x030425FE, 0x07F6F600);
	r2 = D(r2, s[0][1][1], 0x04EF0A01, 0xFCF4E20D, 0xF0FC0613, 0x060FE2F2);
	r3 = D(r3, s[0][1][1], 0x0402F504, 0xFA02F301, 0x10FAF7FF, 0xEA1BF4FD);
	r0 = D(r0, s[0][1][2], 0xF608FC01, 0x01FCF20A, 0x06FE02FF, 0x0308F601);
	r1 = D(r1, s[0][1][2], 0x030F00FC, 0xF1080604, 0xED0DFD06, 0x0CFC11FE);
	r2 = D(r2, s[0][1][2], 0x10F7FCF7, 0x06FFF80B, 0x030300F8, 0x0FFAE3FC);
	r3 = D(r3, s[0][1][2], 0x0DFF0B01, 0xFC03F006, 0x02FEF7FE, 0xF105EC0A);
	r0 = D(r0, s[0][2][0], 0x0402FCFA, 0xFDFFF804, 0x04070400, 0x03FE04FA);
	r1 = D(r1, s[0][2][0], 0x00050002, 0xFDF707FF, 0xFCF5F8FF, 0x020AF80A);
	r2 = D(r2, s[0][2][0], 0xFF0D0906, 0x0301F2F9, 0xF9060504, 0xFFFDFF01);
	r3 = D(r3, s[0][2][0], 0xFAFDF8FE, 0x0102FE03, 0x0007FDFD, 0xFF070C00);
	r0 = D(r0, s[0][2][1], 0xFA0901FA, 0x01EE1DF8, 0xFEF6FAFA, 0xFF050505);
	r1 = D(r1, s[0][2][1], 0x07EB04FD, 0xF902FA03, 0x040BF804, 0x0117050B);
	r2 = D(r2, s[0][2][1], 0x0AFAF5FC, 0x01FCE901, 0xFD03EF04, 0x03FA0F03);
	r3 = D(r3, s[0][2][1], 0x01FF0005, 0x0101FA04, 0x00030A00, 0xF601F901);
	r0 = D(r0, s[0][2][2], 0xF60701FF, 0x0401F9FA, 0x040206FD, 0x0102F3FB);
	r1 = D(r1, s[0][2][2], 0xFF01F9FF, 0x02050301, 0xFE12FA06, 0x0803F307);
	r2 = D(r2, s[0][2][2], 0x0900FFFC, 0x0104F7FC, 0xFF03FCF9, 0x01FD1201);
	r3 = D(r3, s[0][2][2], 0x01F7FDF7, 0x01FCFFFF, 0xFB030608, 0xFDFDFEFE);
	r0 = D(r0, s[1][0][0], 0xFC0303FC, 0x06FF01FA, 0xFD060202, 0x1908FD01);
	r1 = D(r1, s[1][0][0], 0xF90904F9, 0x07FDF804, 0x02F60103, 0xFA020AFF);
	r2 = D(r2, s[1][0][0], 0x0606FDFC, 0xF90D0AFC, 0x01FC0101, 0x0806F904);
	r3 = D(r3, s[1][0][0], 0x06F3080A, 0x0D0BF901, 0xF0070601, 0x0D10F7FA);
	r0 = D(r0, s[1][0][1], 0xFBFB06FD, 0xFC03FB07, 0xFCF80109, 0x2714FDEF);
	r1 = D(r1, s[1][0][1], 0x05060403, 0x10FFEF05, 0x08FF0400, 0x030101F9);
	r2 = D(r2, s[1][0][1], 0xF60AF50E, 0x000303ED, 0x07F810F4, 0x000808F2);
	r3 = D(r3, s[1][0][1], 0x0DFF0A02, 0xF303E411, 0xF6F805FF, 0xF007FE10);
	r0 = D(r0, s[1][0][2], 0x08FD0904, 0x08FDFD05, 0xFF0401FC, 0x080D0102);
	r1 = D(r1, s[1][0][2], 0x09FAF801, 0xFC041201, 0x05100AF7, 0x0603FCFD);
	r2 = D(r2, s[1][0][2], 0x0B08F801, 0x0D030BF5, 0xF503FDFB, 0x060CF1F8);
	r3 = D(r3, s[1][0][2], 0x19FA06FB, 0xFD0AF501, 0xE903FF03, 0xF30A0404);
	r0 = D(r0, s[1][1][0], 0x0D00EFFD, 0xF003FCF2, 0xFB0B03FC, 0x1F14FC05);
	r1 = D(r1, s[1][1][0], 0xF50A1304, 0x0602F4FF, 0xFFFAFF02, 0x100BFA03);
	r2 = D(r2, s[1][1][0], 0x080C0106, 0x09040F00, 0x0304E5F7, 0x02FBFE03);
	r3 = D(r3, s[1][1][0], 0x15060504, 0xF001FF01, 0xE7FC0403, 0xF7180108);
	r0 = D(r0, s[1][1][1], 0x2A0DF8F9, 0x1BFE0627, 0x12FD000E, 0x0906F2F6);
	r1 = D(r1, s[1][1][1], 0x2BFDF81A, 0xE0F2E21D, 0x01E9F310, 0x08FCF403);
	r2 = D(r2, s[1][1][1], 0x0601F7EE, 0xFA1014E0, 0xE2130DD6, 0x29071718);
	r3 = D(r3, s[1][1][1], 0xEC00F6FF, 0x1C0A10FF, 0x04030406, 0x25F3FD23);
	r0 = D(r0, s[1][1][2], 0x09FD03FA, 0x0AF6FC00, 0x06030A02, 0x0800F901);
	r1 = D(r1, s[1][1][2], 0xDEF5FE02, 0xFF020A01, 0xECF3FFF5, 0xF1060203);
	r2 = D(r2, s[1][1][2], 0xF3FC080D, 0xF806FEEB, 0xFCFDFE10, 0x2A110501);
	r3 = D(r3, s[1][1][2], 0xE80A01FD, 0x0A02FA00, 0x0FF9FC01, 0x0CFFF804);
	r0 = D(r0, s[1][2][0], 0x0303FD00, 0xF3FF08FD, 0x010304FC, 0xFF0604FF);
	r1 = D(r1, s[1][2][0], 0xF10316F7, 0x0A02ED03, 0xFE000008, 0x0C08F5FB);
	r2 = D(r2, s[1][2][0], 0x0400FEFE, 0xF10109FA, 0x08F80106, 0xFF0603F6);
	r3 = D(r3, s[1][2][0], 0x08030501, 0xF903FF02, 0xFEFB04FE, 0xFB0CFFFD);
	r0 = D(r0, s[1][2][1], 0xE4FAFA08, 0x0B0CFDFE, 0xFC08FF01, 0xF6FBF1F6);
	r1 = D(r1, s[1][2][1], 0x0A06FE04, 0x05FDF805, 0x06F4F304, 0x0AF50811);
	r2 = D(r2, s[1][2][1], 0x040B10FD, 0x10F906F8, 0x060C09F6, 0x06FEFFFA);
	r3 = D(r3, s[1][2][1], 0xF3F8F9F5, 0x070A0A02, 0xFCF80D00, 0xF9FDFDFA);
	r0 = D(r0, s[1][2][2], 0x0EFEF900, 0xF70001FD, 0xFD03FEFF, 0xFD0A0102);
	r1 = D(r1, s[1][2][2], 0x04FF01F3, 0xFF03FF03, 0xF2F707F8, 0xEC0B060A);
	r2 = D(r2, s[1][2][2], 0xFA0DF503, 0x04FBFD05, 0x03FDFD03, 0xE7FDFDFC);
	r3 = D(r3, s[1][2][2], 0xFE010604, 0x06FDFEFF, 0xFBFEFD04, 0x0E06F8FD);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-3.730e-03, 5.803e-03, 3.460e-03, 3.831e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(7.011e-03, -1.725e-03, -1.251e-03, 7.711e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(4.872e-03, 4.543e-03, -7.901e-03, 5.535e-03);
	imageStore(out_image, opos + ivec2(0, 1), vec4(f2));
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(-4.554e-03, -7.529e-04, 5.290e-03, 1.684e-02);
	imageStore(out_image, opos + ivec2(1, 1), vec4(f3));
}

//!DESC CuNNy-4x16C-TEST-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv4
//!BIND easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[8][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv4_pt;
			r = conv4_gather(p, 0);
			g = conv4_gather(p, 1);
			b = conv4_gather(p, 2);
			a = conv4_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v2 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v4 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v6 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			vec4 v5 = max(-v4, vec4(0));
			v4 = max(v4, vec4(0));
			vec4 v7 = max(-v6, vec4(0));
			v6 = max(v6, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
			G[4][ay][ax] = int(packSnorm4x8(v4));
			G[5][ay][ax] = int(packSnorm4x8(v5));
			G[6][ay][ax] = int(packSnorm4x8(v6));
			G[7][ay][ax] = int(packSnorm4x8(v7));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFAFF022A, 0xFDFEF60B, 0x050BF8E9, 0x000AEEF6);
	r0 = D(r0, s[0][0][1], 0xFCF603DF, 0xFAFF0D1D, 0xFA03062E, 0x05120A05);
	r0 = D(r0, s[0][0][2], 0x02FFFFFE, 0x060505D3, 0xFDF8F806, 0x00FC010F);
	r0 = D(r0, s[0][1][0], 0x0A03FCE9, 0x03FD06ED, 0xFB15F4F3, 0x03FC0303);
	r0 = D(r0, s[0][1][1], 0xF40FF860, 0x1304F52D, 0x020D08AE, 0xFFFAF7AE);
	r0 = D(r0, s[0][1][2], 0x050004FA, 0xFEFEF120, 0xFEF60C19, 0xFCFD0513);
	r0 = D(r0, s[0][2][0], 0x0009FFF4, 0xFDF70400, 0x00EE0225, 0xFEF5050B);
	r0 = D(r0, s[0][2][1], 0x04ED04ED, 0x020A02F0, 0x03FBFFFB, 0x01FD0525);
	r0 = D(r0, s[0][2][2], 0xFD010001, 0xF1EB0401, 0x060CFFEA, 0x00FCFCE4);
	r0 = D(r0, s[1][0][0], 0x0401FAFB, 0x0905FFF8, 0xFCFC0A03, 0x03FB1100);
	r0 = D(r0, s[1][0][1], 0x083ED600, 0xF5DD1E04, 0x09F3EFF8, 0xF6DFFCFE);
	r0 = D(r0, s[1][0][2], 0x03F40AFD, 0x0AF8F400, 0x02060900, 0x01030104);
	r0 = D(r0, s[1][1][0], 0xEEFCFA04, 0xFB19F80E, 0xF5E2FCFE, 0xFB0EF106);
	r0 = D(r0, s[1][1][1], 0x134DE202, 0xEB812CF6, 0x047FD20D, 0xE99A59FF);
	r0 = D(r0, s[1][1][2], 0xFFEAFBFD, 0x03110B04, 0x0FE7FEF5, 0x170FF0F8);
	r0 = D(r0, s[1][2][0], 0x08F30503, 0x060DFAFF, 0x0C1205FC, 0x0618FCFB);
	r0 = D(r0, s[1][2][1], 0xF615FAFA, 0xFEFB04F8, 0xF617E901, 0x06D6FEFC);
	r0 = D(r0, s[1][2][2], 0x01010204, 0x110AFDFC, 0xF8F00309, 0x02F70804);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x01D705FA, 0x000D0504, 0xFB01FFFE, 0x02FF0509);
	r0 = D(r0, s[0][0][1], 0x0A0800FA, 0x101CFCF1, 0x090203FB, 0x0011F3F1);
	r0 = D(r0, s[0][0][2], 0xFB0302FD, 0xF80002F5, 0xF8FE0203, 0xFEFD09FF);
	r0 = D(r0, s[0][1][0], 0x0DEAFB0F, 0x0646FAFA, 0x09D0F806, 0x0046FAFC);
	r0 = D(r0, s[0][1][1], 0xF531E20F, 0xFB94FA1C, 0xF820F303, 0x00E0030E);
	r0 = D(r0, s[0][1][2], 0xFFF40600, 0xFD10E805, 0x02FE1603, 0x0205F702);
	r0 = D(r0, s[0][2][0], 0x0019FBFA, 0x00F40300, 0x04050905, 0x010004FF);
	r0 = D(r0, s[0][2][1], 0xFCFD11FE, 0xFD0500F6, 0xFC15EEFC, 0x02C20004);
	r0 = D(r0, s[0][2][2], 0x02FF02FE, 0x02090C02, 0x02FAFBF7, 0xFF19EFF8);
	r0 = D(r0, s[1][0][0], 0xDAFA0305, 0xF40100FE, 0x2D000300, 0x0600FDF7);
	r0 = D(r0, s[1][0][1], 0xF602FF0B, 0xD8FD0212, 0x0AFD0406, 0x36F81012);
	r0 = D(r0, s[1][0][2], 0xF8FF0505, 0xFEFA060B, 0x0E03FEFE, 0x0C04FC01);
	r0 = D(r0, s[1][1][0], 0xF8FE0503, 0xFEF70BFF, 0xE5E20809, 0x03F70B05);
	r0 = D(r0, s[1][1][1], 0x0508E8C4, 0x0227E50D, 0x0C0CE8DD, 0xE915E6F7);
	r0 = D(r0, s[1][1][2], 0x01010006, 0x02020501, 0xFBFCF602, 0x05FAFD06);
	r0 = D(r0, s[1][2][0], 0x00FB0A05, 0x0006FFFF, 0xFF0A0001, 0xFF0400FD);
	r0 = D(r0, s[1][2][1], 0x0305FAFE, 0x02F6060C, 0x030402EF, 0x0006FA1A);
	r0 = D(r0, s[1][2][2], 0xFEFE0401, 0xFEFFFD03, 0xFDFF0F0A, 0xFE00100D);
	s[0][0][0] = G[4][xy.y+0][xy.x+0]; s[0][0][1] = G[4][xy.y+0][xy.x+1];
	s[0][0][2] = G[4][xy.y+0][xy.x+2]; s[0][1][0] = G[4][xy.y+1][xy.x+0];
	s[0][1][1] = G[4][xy.y+1][xy.x+1]; s[0][1][2] = G[4][xy.y+1][xy.x+2];
	s[0][2][0] = G[4][xy.y+2][xy.x+0]; s[0][2][1] = G[4][xy.y+2][xy.x+1];
	s[0][2][2] = G[4][xy.y+2][xy.x+2]; s[1][0][0] = G[5][xy.y+0][xy.x+0];
	s[1][0][1] = G[5][xy.y+0][xy.x+1]; s[1][0][2] = G[5][xy.y+0][xy.x+2];
	s[1][1][0] = G[5][xy.y+1][xy.x+0]; s[1][1][1] = G[5][xy.y+1][xy.x+1];
	s[1][1][2] = G[5][xy.y+1][xy.x+2]; s[1][2][0] = G[5][xy.y+2][xy.x+0];
	s[1][2][1] = G[5][xy.y+2][xy.x+1]; s[1][2][2] = G[5][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0DFA0112, 0x0BFDFE08, 0xFDFDFE03, 0xFEFCFAFB);
	r0 = D(r0, s[0][0][1], 0xFD3401F4, 0xFFF401FC, 0x0203FFF6, 0xFAEA03F8);
	r0 = D(r0, s[0][0][2], 0x00FCFF06, 0xFBEB00FE, 0x00030209, 0x00FD0001);
	r0 = D(r0, s[0][1][0], 0xEEFDF3ED, 0xF1FEFFF4, 0x0BF8FC08, 0xFFFD0503);
	r0 = D(r0, s[0][1][1], 0x05111506, 0xF80600F2, 0x01580FFB, 0x08160105);
	r0 = D(r0, s[0][1][2], 0x010BF7FF, 0x02EE0305, 0x0504F706, 0x00F0FF02);
	r0 = D(r0, s[0][2][0], 0x0405FEFC, 0x0201FFFD, 0xFC0100FC, 0xFFFEFE00);
	r0 = D(r0, s[0][2][1], 0xFEF8050C, 0x02F6FE10, 0xF6E80101, 0xF8F7FF01);
	r0 = D(r0, s[0][2][2], 0x0105FFFB, 0x050B0604, 0x0006FBF7, 0x02FD00FF);
	r0 = D(r0, s[1][0][0], 0x0C04FADF, 0x0402FEF3, 0xF4060012, 0xF8040911);
	r0 = D(r0, s[1][0][1], 0xF8F4FA23, 0x0408FE06, 0xFDFF040B, 0xFD10FE0F);
	r0 = D(r0, s[1][0][2], 0x000502FB, 0x01FEFF0C, 0xFD04FFF7, 0xFE00FF01);
	r0 = D(r0, s[1][1][0], 0xC600065A, 0xE5040025, 0x37FF03BA, 0x0C01FAF3);
	r0 = D(r0, s[1][1][1], 0xFCFFD909, 0xD8F8DF47, 0x12E1CEE8, 0x37E5E1A3);
	r0 = D(r0, s[1][1][2], 0xFEFB0005, 0x0204FE00, 0xFCF601FB, 0x00F5FF01);
	r0 = D(r0, s[1][2][0], 0x06FBFEFF, 0x05FD00FF, 0x03FEF203, 0x0F00FFF4);
	r0 = D(r0, s[1][2][1], 0x0B0FFCF1, 0x080801E9, 0x001B040B, 0xED0DF211);
	r0 = D(r0, s[1][2][2], 0x01FE0204, 0xFEF8FAFB, 0x00010208, 0x00040302);
	s[0][0][0] = G[6][xy.y+0][xy.x+0]; s[0][0][1] = G[6][xy.y+0][xy.x+1];
	s[0][0][2] = G[6][xy.y+0][xy.x+2]; s[0][1][0] = G[6][xy.y+1][xy.x+0];
	s[0][1][1] = G[6][xy.y+1][xy.x+1]; s[0][1][2] = G[6][xy.y+1][xy.x+2];
	s[0][2][0] = G[6][xy.y+2][xy.x+0]; s[0][2][1] = G[6][xy.y+2][xy.x+1];
	s[0][2][2] = G[6][xy.y+2][xy.x+2]; s[1][0][0] = G[7][xy.y+0][xy.x+0];
	s[1][0][1] = G[7][xy.y+0][xy.x+1]; s[1][0][2] = G[7][xy.y+0][xy.x+2];
	s[1][1][0] = G[7][xy.y+1][xy.x+0]; s[1][1][1] = G[7][xy.y+1][xy.x+1];
	s[1][1][2] = G[7][xy.y+1][xy.x+2]; s[1][2][0] = G[7][xy.y+2][xy.x+0];
	s[1][2][1] = G[7][xy.y+2][xy.x+1]; s[1][2][2] = G[7][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0405FA00, 0x00FA0000, 0xFEFBFCF7, 0xFBF704F8);
	r0 = D(r0, s[0][0][1], 0xFFFC0901, 0x030D0100, 0xFCFB04FF, 0xFFFFFBFC);
	r0 = D(r0, s[0][0][2], 0x0202FE02, 0xFAFE02FE, 0x0902FE04, 0x00010300);
	r0 = D(r0, s[0][1][0], 0xFAFBF61B, 0x030AFFFB, 0x0304F705, 0x0506FAF4);
	r0 = D(r0, s[0][1][1], 0x04FF010A, 0xEDFC0531, 0x01FF08FA, 0x000B030E);
	r0 = D(r0, s[0][1][2], 0xFA020802, 0x0FF8F4F6, 0xF10B0F05, 0xFD010301);
	r0 = D(r0, s[0][2][0], 0x0102FFFF, 0x08FCFA05, 0xFEFEFAF2, 0x0301FBF8);
	r0 = D(r0, s[0][2][1], 0xFCF408FA, 0xF80A13FB, 0xFE010AF7, 0xF30616FC);
	r0 = D(r0, s[0][2][2], 0x0505F804, 0x05FCF303, 0x0AFAF4FA, 0x0DF6EBF3);
	r0 = D(r0, s[1][0][0], 0xF6F100FA, 0x03FCFEFF, 0x04FD0406, 0x0608FD06);
	r0 = D(r0, s[1][0][1], 0x161EE801, 0xFE0AF1F8, 0x04040001, 0xFEF60603);
	r0 = D(r0, s[1][0][2], 0xFDFB06FD, 0x0F040205, 0xF6F802FD, 0x01010301);
	r0 = D(r0, s[1][1][0], 0x0A00120E, 0xFBFDFC09, 0xF81D0505, 0xFEFC030B);
	r0 = D(r0, s[1][1][1], 0x1AB2FEFB, 0x34C21901, 0x2D05DFFD, 0x1F40FAFA);
	r0 = D(r0, s[1][1][2], 0x0905F4FF, 0xF303FE06, 0x11FDF2F6, 0x12EDEDFD);
	r0 = D(r0, s[1][2][0], 0x0106FDFB, 0xFB0A02FD, 0x04F31002, 0xFC0001FD);
	r0 = D(r0, s[1][2][1], 0x0419FA09, 0x0BFFF1FC, 0x060C0AF7, 0x12DD0FF0);
	r0 = D(r0, s[1][2][2], 0xFBFB05FD, 0xFB060B01, 0xF80D0A04, 0xF4201109);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(4.141e-04, -3.461e-04, 8.596e-04, 1.795e-04);
	f0 = tanh(f0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(f0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(f0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(f0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

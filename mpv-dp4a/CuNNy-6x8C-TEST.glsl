// CuNNy 6x8C TEST
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

//!DESC CuNNy-6x8C-TEST-EASU
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


//!DESC CuNNy-6x8C-TEST-in
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND LUMA
//!SAVE in
//!WIDTH LUMA.w 2 *
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
	ivec2 opos = pos * ivec2(2, 1);
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
	s[0][0][0] = g[0][xy.y+0][xy.x+0];
	s[0][1][0] = g[0][xy.y+0][xy.x+1];
	s[0][2][0] = g[0][xy.y+0][xy.x+2];
	s[1][0][0] = g[0][xy.y+1][xy.x+0];
	s[1][1][0] = g[0][xy.y+1][xy.x+1];
	s[1][2][0] = g[0][xy.y+1][xy.x+2];
	s[2][0][0] = g[0][xy.y+2][xy.x+0];
	s[2][1][0] = g[0][xy.y+2][xy.x+1];
	s[2][2][0] = g[0][xy.y+2][xy.x+2];
	r0 += V4(4.314e-02, -3.595e-03, -1.007e-01, 1.043e-01) * s[0][0][0];
	r1 += V4(1.438e-02, 2.876e-02, 1.797e-02, 3.595e-02) * s[0][0][0];
	r0 += V4(2.157e-02, 1.690e-01, -2.516e-01, 1.474e-01) * s[0][1][0];
	r1 += V4(-1.797e-02, -8.628e-02, 3.595e-02, 7.190e-03) * s[0][1][0];
	r0 += V4(-3.954e-02, -1.690e-01, -6.111e-02, 1.186e-01) * s[0][2][0];
	r1 += V4(-1.366e-01, 2.157e-02, 5.392e-02, 7.190e-03) * s[0][2][0];
	r0 += V4(5.752e-02, -2.301e-01, -3.595e-02, -1.294e-01) * s[1][0][0];
	r1 += V4(2.157e-02, -5.033e-02, 7.190e-03, 7.190e-03) * s[1][0][0];
	r0 += V4(5.069e-01, 1.726e-01, 2.337e-01, -4.062e-01) * s[1][1][0];
	r1 += V4(-2.624e-01, -2.984e-01, 7.190e-03, -4.314e-02) * s[1][1][0];
	r0 += V4(-1.941e-01, 9.706e-02, -2.301e-01, 7.909e-02) * s[1][2][0];
	r1 += V4(-2.229e-01, 3.703e-01, -3.667e-01, -2.301e-01) * s[1][2][0];
	r0 += V4(-2.588e-01, 2.265e-01, 1.438e-02, 1.438e-02) * s[2][0][0];
	r1 += V4(-4.314e-02, 1.438e-02, 2.121e-01, 3.595e-02) * s[2][0][0];
	r0 += V4(-1.510e-01, -3.379e-01, -1.438e-02, -2.157e-02) * s[2][1][0];
	r1 += V4(3.451e-01, -7.549e-02, 7.190e-02, -1.654e-01) * s[2][1][0];
	r0 += V4(6.830e-02, 7.549e-02, 2.876e-02, 5.033e-02) * s[2][2][0];
	r1 += V4(3.092e-01, 7.549e-02, -2.157e-02, 2.049e-01) * s[2][2][0];
	r0 += V4(-1.966e-03, 2.607e-05, 3.659e-03, -6.560e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(-1.931e-02, 4.008e-03, -3.338e-02, 1.023e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-6x8C-TEST-conv1
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND in
//!BIND LUMA
//!SAVE conv1
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) in_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * in_pt)
#define l1(x, y) in_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * in_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x18083208, 0x06000209, 0x0821F7FD, 0x09E9EEF5);
	r1 = D(r1, s[0][0][0], 0x0615F40B, 0xE8E9FA17, 0x0F3D0EFD, 0xEEBA0902);
	r0 = D(r0, s[0][0][1], 0xE8E5FE05, 0x09210B08, 0xFB41F51A, 0x03DFF2DA);
	r1 = D(r1, s[0][0][1], 0xFBDD00D7, 0xD221263A, 0x031AEEFD, 0x05F20CF2);
	r0 = D(r0, s[0][0][2], 0x151202E5, 0x0E12030F, 0xD7FE0FFE, 0x06F5F109);
	r1 = D(r1, s[0][0][2], 0x00F714F8, 0x03EF0C1D, 0x111DDA02, 0x090806F8);
	r0 = D(r0, s[0][1][0], 0x0C2E4402, 0xFB37F8FD, 0x0581F8F1, 0xE9A6CFFE);
	r1 = D(r1, s[0][1][0], 0x112EF2FB, 0xF15DF803, 0xFEC203FE, 0xE67F2634);
	r0 = D(r0, s[0][1][1], 0x15DAABD4, 0x09211B11, 0xD17F320C, 0x2F82CC18);
	r1 = D(r1, s[0][1][1], 0x007F14E5, 0x0203F8CF, 0x00E54115, 0x15FBD4EC);
	r0 = D(r0, s[0][1][2], 0x02231714, 0x1500F508, 0xDF0803FB, 0x0CE51111);
	r1 = D(r1, s[0][1][2], 0x09140E08, 0xFED1E60C, 0xFD02BC06, 0x110EE206);
	r0 = D(r0, s[0][2][0], 0x007F1DF5, 0x00151203, 0x1A81F406, 0xE8C3ECF2);
	r1 = D(r1, s[0][2][0], 0xF2C5F500, 0x1509EFF8, 0x0F1A1EFE, 0x087F0C0F);
	r0 = D(r0, s[0][2][1], 0x29FBE518, 0x157AFEEE, 0x28811509, 0x0F81DF28);
	r1 = D(r1, s[0][2][1], 0x1D03E002, 0xF7C5F7FA, 0xDFC621F2, 0xF144EB03);
	r0 = D(r0, s[0][2][2], 0xE9EC0309, 0xFB4314F5, 0x028BFB00, 0x08E2F8FA);
	r1 = D(r1, s[0][2][2], 0x1521DB0B, 0x00FDFE0B, 0xFD831417, 0x1EEC0302);
	r0 = D(r0, s[1][0][0], 0x0009181E, 0x02F709FD, 0xF702FE15, 0xF1FDC8EB);
	r1 = D(r1, s[1][0][0], 0xFDF2EBF1, 0x110B11F8, 0xFAF50F1A, 0x000F030C);
	r0 = D(r0, s[1][0][1], 0x09112300, 0xF2F50600, 0xFBF717EB, 0x0315E905);
	r1 = D(r1, s[1][0][1], 0xF5141A1A, 0x0CFBC3D7, 0xE3061102, 0x0FFDFB05);
	r0 = D(r0, s[1][0][2], 0x03E9FA25, 0xFAF206EB, 0x0F020214, 0x03F414F1);
	r1 = D(r1, s[1][0][2], 0x05030F09, 0x060E09E5, 0x03FDE0FA, 0xEEF10B05);
	r0 = D(r0, s[1][1][0], 0xECFD15FD, 0xFAF502F7, 0x0011DD2E, 0xF200F511);
	r1 = D(r1, s[1][1][0], 0x0308EC09, 0xFEF5F4E6, 0xF40E2803, 0x29FDD5F7);
	r0 = D(r0, s[1][1][1], 0xEBF51B12, 0x09FBF10B, 0x0B03F5E5, 0x28FAF805);
	r1 = D(r1, s[1][1][1], 0x030B230C, 0xDA06FE0F, 0x14EECEEC, 0x090625FB);
	r0 = D(r0, s[1][1][2], 0xF102DDF8, 0xF2FD0609, 0x18141409, 0x06FBDF12);
	r1 = D(r1, s[1][1][2], 0x11E8EFBA, 0xE9FA06DF, 0x00FAE909, 0xE9EF1100);
	r0 = D(r0, s[1][2][0], 0x1211F408, 0x00E208FE, 0xF5050EEC, 0xD81EEB23);
	r1 = D(r1, s[1][2][0], 0xF2FEF5EF, 0xEFFA1209, 0x17061D1B, 0xFA12F8E6);
	r0 = D(r0, s[1][2][1], 0x0EFBFD26, 0xF5F81B12, 0xDF0302F4, 0xF7F4DA29);
	r1 = D(r1, s[1][2][1], 0xF1FD00F7, 0xE90006FA, 0xDD0B1238, 0xE20EF411);
	r0 = D(r0, s[1][2][2], 0x08020915, 0x03E6F50C, 0xFA171506, 0x1AFAFAEE);
	r1 = D(r1, s[1][2][2], 0xC906F7DB, 0xF1FE1105, 0x02F4050C, 0xE8FAFEFE);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xC6EF18F8, 0x0911F505, 0x5EECF711, 0x41FA0002);
	r1 = D(r1, s[0][0][0], 0x1BEE11EB, 0x28E6F8F4, 0xB80FFAFB, 0x23E0F51D);
	r0 = D(r0, s[0][0][1], 0xC305FDDD, 0x110FFD00, 0xD20B0208, 0xB8FEE321);
	r1 = D(r1, s[0][0][1], 0x32EE0B23, 0x0515D5DD, 0xF4E61428, 0x1D17F1D8);
	r0 = D(r0, s[0][0][2], 0xE912E606, 0xF40002FB, 0x311803E9, 0xE9EC03FD);
	r1 = D(r1, s[0][0][2], 0x40E50E0C, 0x06E6FD02, 0xEB050809, 0x0E020002);
	r0 = D(r0, s[0][1][0], 0xDD002EEB, 0x34080EFD, 0xC9D7FEF4, 0x0F12FEDA);
	r1 = D(r1, s[0][1][0], 0x11F402EB, 0xF515141B, 0xD4080005, 0x1505A8C8);
	r0 = D(r0, s[0][1][1], 0xE21B2111, 0x38E5FE00, 0x96E914EB, 0xE809EC15);
	r1 = D(r1, s[0][1][1], 0xFAFA28C5, 0xFD23FB2C, 0x0E0BE3DD, 0x31EB09F5);
	r0 = D(r0, s[0][1][2], 0xF5170C0B, 0x1BFBF4EE, 0xF50BFB0F, 0xDBF8FA18);
	r1 = D(r1, s[0][1][2], 0x25FB1B05, 0x02FD06F5, 0xE018D8E5, 0x08F7FE00);
	r0 = D(r0, s[0][2][0], 0xF2F4ECD5, 0xF4FE09F5, 0x001AEE03, 0x2BCB0E02);
	r1 = D(r1, s[0][2][0], 0x2C06EB12, 0x1DFD02F8, 0x2CE026D7, 0xE608AFFA);
	r0 = D(r0, s[0][2][1], 0x0B21B1E0, 0x18FB0505, 0x060B1100, 0x170FD200);
	r1 = D(r1, s[0][2][1], 0x0CFECC06, 0x140E0CF5, 0x1403E3EC, 0x0CFE030F);
	r0 = D(r0, s[0][2][2], 0xABF40002, 0x05EC03FA, 0x1DFE0FEC, 0x0B00F206);
	r1 = D(r1, s[0][2][2], 0xEBF1F802, 0xF5F7EB05, 0xFB1DDDF5, 0x0906F8FB);
	r0 = D(r0, s[1][0][0], 0xFA14E6E5, 0xFDECFA00, 0xF712E202, 0x0811E308);
	r1 = D(r1, s[1][0][0], 0xFB08E8FA, 0x0EFBF120, 0x02FD28FD, 0x1E03F505);
	r0 = D(r0, s[1][0][1], 0x03F2F720, 0xFDFAFA06, 0x081415F1, 0x1406D5FD);
	r1 = D(r1, s[1][0][1], 0xF8EC0CF8, 0xF417024B, 0x090909DA, 0xFD06090E);
	r0 = D(r0, s[1][0][2], 0x0812F705, 0x0200FDFD, 0xF2F20815, 0x0E0CF2FE);
	r1 = D(r1, s[1][0][2], 0x0EF406F4, 0x0B141DF7, 0xFB00F4FD, 0x00000EFD);
	r0 = D(r0, s[1][1][0], 0xE9EB1AEE, 0x12EC0626, 0x091AD209, 0xEE03F502);
	r1 = D(r1, s[1][1][0], 0xF50918EE, 0x03F50C11, 0xFD08E511, 0x06DF0B09);
	r0 = D(r0, s[1][1][1], 0x08FE0FEB, 0xFB0BEB05, 0x15FB140E, 0xEC000C09);
	r1 = D(r1, s[1][1][1], 0x090905FA, 0x00FDEC02, 0xEF0B121A, 0xDFFAEFFE);
	r0 = D(r0, s[1][1][2], 0xFDF70006, 0xFD060912, 0xFEFAF108, 0xFAFAF2F2);
	r1 = D(r1, s[1][1][2], 0x000F1514, 0xF705F702, 0xF70BF7FD, 0xF205F403);
	r0 = D(r0, s[1][2][0], 0x0F14C6F2, 0xF708FD00, 0xFAFBF7FE, 0xF109DFF5);
	r1 = D(r1, s[1][2][0], 0xFBE61702, 0xEFFE0E06, 0x110003F8, 0x02EE0FFD);
	r0 = D(r0, s[1][2][1], 0xF1EEC905, 0xF505EF05, 0x05EC0F0C, 0xFDF1E302);
	r1 = D(r1, s[1][2][1], 0xF2F2F20C, 0xFBEEFE08, 0x18FAEF17, 0xF70BF8FE);
	r0 = D(r0, s[1][2][2], 0x080FECF4, 0xEF0EFE06, 0xF2F4050B, 0x080B0606);
	r1 = D(r1, s[1][2][2], 0x14E90B00, 0x0B0E09F5, 0x02F5D7EE, 0x00FB09FE);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(2.189e-03, -4.094e-03, -1.199e-01, 1.997e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-6.233e-03, -1.905e-02, 2.494e-02, 5.693e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-6x8C-TEST-conv2
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv1
//!BIND LUMA
//!SAVE conv2
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv1_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv1_pt)
#define l1(x, y) conv1_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv1_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x05F20EF7, 0xF3FC38FF, 0x030391FF, 0x13FF1308);
	r1 = D(r1, s[0][0][0], 0xF5F2171B, 0x120FF1F0, 0xF3FDED0B, 0x2FE5C708);
	r0 = D(r0, s[0][0][1], 0x0A087FFA, 0x0E03360A, 0xF8FA81F6, 0xF7FA10F3);
	r1 = D(r1, s[0][0][1], 0xE708A701, 0xF6FA2AE0, 0xEA180D0E, 0x03F6810E);
	r0 = D(r0, s[0][0][2], 0x0A06DA10, 0x09067F0B, 0x03061CEC, 0x03F74405);
	r1 = D(r1, s[0][0][2], 0xFD06E4F6, 0xFFF0F6D4, 0xFC0F57F7, 0x100339F8);
	r0 = D(r0, s[0][1][0], 0x0F03D103, 0xF5FFF1F6, 0x10FB8709, 0x0BF617FC);
	r1 = D(r1, s[0][1][0], 0x250944F5, 0x120316F3, 0xE913EDFC, 0xD2DE2026);
	r0 = D(r0, s[0][1][1], 0x00E00EFC, 0x0021CDFC, 0xFF09B0F2, 0xE2D8FB0A);
	r1 = D(r1, s[0][1][1], 0x1210FD06, 0x03F330FC, 0xEEF3B90A, 0x2012EEDB);
	r0 = D(r0, s[0][1][2], 0xFF06D6F3, 0x1608E719, 0x0501FDFB, 0xFC04F50A);
	r1 = D(r1, s[0][1][2], 0xFBF81C01, 0x19031603, 0xF8FA270D, 0xF2FC480A);
	r0 = D(r0, s[0][2][0], 0x0100FA00, 0xF505E50E, 0xF0FBCFFD, 0x00FDEC03);
	r1 = D(r1, s[0][2][0], 0xF2102F12, 0xF6011DFD, 0x0112C7EE, 0x04FA210D);
	r0 = D(r0, s[0][2][1], 0xFA03F5F8, 0x08130BFA, 0x0300E5F3, 0x05ECFCF6);
	r1 = D(r1, s[0][2][1], 0x04F5F52A, 0x0EFF310D, 0x08F3EEEC, 0xFD04010F);
	r0 = D(r0, s[0][2][2], 0xF80903FD, 0x05FAE0E9, 0x19F810FD, 0x09F0F0FA);
	r1 = D(r1, s[0][2][2], 0xF6FAFD04, 0xFBF7F003, 0x0B000FF3, 0x0301E21E);
	r0 = D(r0, s[1][0][0], 0x01FA01F1, 0x0605FDF3, 0xFF00FD04, 0xF51005FD);
	r1 = D(r1, s[1][0][0], 0x16F206E9, 0xE8090A13, 0x0506F8EE, 0x0812FD0F);
	r0 = D(r0, s[1][0][1], 0xDEFBF80A, 0xFA0409FD, 0x001306FC, 0x060DF20D);
	r1 = D(r1, s[1][0][1], 0xFCF70019, 0x1E0BFD0A, 0x03030AF0, 0x08F5FF0E);
	r0 = D(r0, s[1][0][2], 0x0504F0F5, 0x14F7F001, 0x06FF0601, 0xF80AF7FD);
	r1 = D(r1, s[1][0][2], 0xEC10E927, 0xF0FF0F06, 0x08F7FA03, 0x0B000AF2);
	r0 = D(r0, s[1][1][0], 0xF713FF08, 0x0E1CFD0E, 0x0EED0E18, 0xEEF6FAFF);
	r1 = D(r1, s[1][1][0], 0xDDFBF014, 0x14E903F6, 0x030D010A, 0x0DEE08F6);
	r0 = D(r0, s[1][1][1], 0xF71DF30A, 0xE0EA09E3, 0x08E4F506, 0x2BF705F2);
	r1 = D(r1, s[1][1][1], 0x22D80314, 0x3408EEE8, 0xE4FB0FFA, 0x05FB0019);
	r0 = D(r0, s[1][1][2], 0xF8FA000A, 0x0AEDFB0A, 0x14FF0810, 0x0B0900F5);
	r1 = D(r1, s[1][1][2], 0x10130BD0, 0xF700F6EA, 0x1E14F709, 0xF60B0BFA);
	r0 = D(r0, s[1][2][0], 0xFF03F5F1, 0x05FC04F5, 0x08F6FFF6, 0x0D05F7FF);
	r1 = D(r1, s[1][2][0], 0x090300FD, 0xFB00F604, 0xFC0010FC, 0x0803EDF6);
	r0 = D(r0, s[1][2][1], 0xF300FA08, 0xD800F006, 0xF70BE3FC, 0xF70AF7FB);
	r1 = D(r1, s[1][2][1], 0xFF0017F3, 0x1D0001F7, 0xED00F100, 0x12FA0D05);
	r0 = D(r0, s[1][2][2], 0x12F800FC, 0xFBF8000F, 0xFB08F603, 0xFA12E306);
	r1 = D(r1, s[1][2][2], 0xF600F605, 0x011017F5, 0xFBFBF101, 0x010D0303);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0108060A, 0xEDEAFFE7, 0x06E8FFF7, 0x000901FC);
	r1 = D(r1, s[0][0][0], 0x030803E9, 0xF80AF60D, 0xEDE006F0, 0xF104FF18);
	r0 = D(r0, s[0][0][1], 0x00250826, 0xE01EF601, 0x0901FFE5, 0x1E12F700);
	r1 = D(r1, s[0][0][1], 0x2516F30B, 0xFC010F21, 0xD8EEF7F2, 0xFA060105);
	r0 = D(r0, s[0][0][2], 0xFAF3FC0F, 0xF7F8FF12, 0xEA01FFF5, 0xF3FB03FC);
	r1 = D(r1, s[0][0][2], 0x19101218, 0x06FCF8EA, 0xEE03F806, 0x01170005);
	r0 = D(r0, s[0][1][0], 0x040900DA, 0xCBFD09F5, 0xFD10E51B, 0x0BF6ED12);
	r1 = D(r1, s[0][1][0], 0xF2E9E83B, 0x19EA1E20, 0xD92605E0, 0xEDEC2C3B);
	r0 = D(r0, s[0][1][1], 0xFBF80627, 0xC20B1B1C, 0xF01D08F0, 0x0FEA2A0D);
	r1 = D(r1, s[0][1][1], 0xF6F7E817, 0x14FB23FF, 0xB40BF60E, 0xB501F617);
	r0 = D(r0, s[0][1][2], 0xEAF0F504, 0xD6FBF2FF, 0xE4F212E5, 0xEA0105F1);
	r1 = D(r1, s[0][1][2], 0x09010A09, 0xFD130E08, 0xEAFAFFE5, 0xF000030A);
	r0 = D(r0, s[0][2][0], 0x0403F7F7, 0x000AEDC6, 0x01F71BED, 0x0AE80BF3);
	r1 = D(r1, s[0][2][0], 0xFDFD1201, 0x00F22649, 0xF308F0C2, 0x0E030A04);
	r0 = D(r0, s[0][2][1], 0xFF08E92B, 0xD9FF19F8, 0xE30146FA, 0xF70904FF);
	r1 = D(r1, s[0][2][1], 0xE0080003, 0x09F32809, 0xF810E4F2, 0xF5FC1E00);
	r0 = D(r0, s[0][2][2], 0x0BFCFB0F, 0xF301FFF7, 0xF50405F8, 0xFD03FA09);
	r1 = D(r1, s[0][2][2], 0xF6FFF716, 0xE90D0B01, 0xFCFBFBEE, 0xFF0AFD16);
	r0 = D(r0, s[1][0][0], 0x09FFFAF8, 0x081C09F6, 0xFC12FF0B, 0x00F7FCFF);
	r1 = D(r1, s[1][0][0], 0xFC0F03E3, 0xF5F3F805, 0xFB1608FD, 0x05E4FDF5);
	r0 = D(r0, s[1][0][1], 0xF2E9E7FB, 0x0A000600, 0xDF0A0A12, 0xFDDAFFED);
	r1 = D(r1, s[1][0][1], 0x09F0E3F2, 0x2100EC13, 0xF80F1708, 0xE7030110);
	r0 = D(r0, s[1][0][2], 0xFAFF04FC, 0x0B05FBFC, 0x0408040D, 0x0604FD05);
	r1 = D(r1, s[1][0][2], 0xCFF2F30B, 0x0509FD06, 0xFA080304, 0xECF6FBFA);
	r0 = D(r0, s[1][1][0], 0xF60BF621, 0xFF31DE00, 0x04002809, 0x00ED0F1C);
	r1 = D(r1, s[1][1][0], 0x01E217F7, 0x09D430F3, 0xFD130313, 0x06FAF6F0);
	r0 = D(r0, s[1][1][1], 0xDEFACAFB, 0xF7FDFBDA, 0xF8F70110, 0xFF17E0EE);
	r1 = D(r1, s[1][1][1], 0xF101DF1C, 0x1EF72212, 0xDEEC12EA, 0x3A0F1405);
	r0 = D(r0, s[1][1][2], 0x2703F603, 0x13051701, 0xFC04F00E, 0x3904FF0D);
	r1 = D(r1, s[1][1][2], 0xFD06FC03, 0x13F2EDFC, 0x0BFDFC0E, 0xF803FDF7);
	r0 = D(r0, s[1][2][0], 0xFB05EE10, 0xFB04DD16, 0x08FD06F7, 0x051318F8);
	r1 = D(r1, s[1][2][0], 0xF10B1008, 0x06ED36E8, 0x04EC0925, 0xF7F6F5FC);
	r0 = D(r0, s[1][2][1], 0xF5F7E503, 0xFCFBD9F7, 0x16EAFF0A, 0x0DEA1DF1);
	r1 = D(r1, s[1][2][1], 0xF601F0F8, 0x170E0BF8, 0xF8F6F1FD, 0x0505ED0E);
	r0 = D(r0, s[1][2][2], 0x00FCF306, 0xF800FC05, 0xFAFCFBF7, 0xFFFF17FB);
	r1 = D(r1, s[1][2][2], 0x080419F3, 0x06F7F1FF, 0x0F03F201, 0x03F8F5FB);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(1.724e-01, 3.875e-02, 6.200e-02, 2.134e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(1.376e-02, -5.622e-02, 4.163e-02, -4.881e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-6x8C-TEST-conv3
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE conv3
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv2_pt)
#define l1(x, y) conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv2_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x14FA0CEF, 0x03101BFC, 0x1F0103FA, 0x05EDE902);
	r1 = D(r1, s[0][0][0], 0xF9051206, 0xF8F10702, 0x05E2E5FA, 0xFEFAF4F9);
	r0 = D(r0, s[0][0][1], 0xF0F1EB04, 0xD92714DC, 0x090A0313, 0x0609FA06);
	r1 = D(r1, s[0][0][1], 0x0BEFE7FC, 0x11E10B00, 0xFB17ECF7, 0x22FBDD11);
	r0 = D(r0, s[0][0][2], 0x0C0FFF05, 0x09FAFFF7, 0x0601FAFF, 0xF5090010);
	r1 = D(r1, s[0][0][2], 0x020310FA, 0xFAEF0602, 0x07000607, 0x03041503);
	r0 = D(r0, s[0][1][0], 0xEF06FAE4, 0xFF060FFB, 0x0AFE0711, 0x11EFFFF3);
	r1 = D(r1, s[0][1][0], 0xFA071D0A, 0xF8E8091D, 0x0FECFA06, 0xFAFEDDF6);
	r0 = D(r0, s[0][1][1], 0xDE14BA26, 0x33FFCD1B, 0x0BF4080C, 0xFFE2F51E);
	r1 = D(r1, s[0][1][1], 0x012BF3CF, 0xEB133203, 0xF61D050F, 0x28F4BBE4);
	r0 = D(r0, s[0][1][2], 0x0312162B, 0x06FAEFF6, 0x0D07F0FA, 0x0B05E1EE);
	r1 = D(r1, s[0][1][2], 0x1D21EFF4, 0x01E50706, 0xF6EFFFDF, 0xF1FD09F7);
	r0 = D(r0, s[0][2][0], 0x000AFC08, 0xFB0CF3F4, 0x14F90A0F, 0x09FB07E3);
	r1 = D(r1, s[0][2][0], 0x05FCFDFB, 0xFCFAF60C, 0x0BE90601, 0x080906F0);
	r0 = D(r0, s[0][2][1], 0xFA00F704, 0x0503F5FC, 0x0602060C, 0xF7FDE7EE);
	r1 = D(r1, s[0][2][1], 0x0503FAEC, 0x0206E713, 0xFC1EF502, 0xF21111F1);
	r0 = D(r0, s[0][2][2], 0x010606FA, 0x03FEF201, 0xFA08FB04, 0xFC00F9F0);
	r1 = D(r1, s[0][2][2], 0xFF06F3FD, 0xF2FAF806, 0x06EF10EE, 0x010406F6);
	r0 = D(r0, s[1][0][0], 0xEAFBFB05, 0xFDFFE4FC, 0xE0F2FC03, 0xF00C07FF);
	r1 = D(r1, s[1][0][0], 0x04FA03F8, 0x0D001701, 0xF52E0109, 0xFF25000A);
	r0 = D(r0, s[1][0][1], 0x08EA0401, 0x35E1EEFE, 0xDFEC0CF8, 0xE5CCE601);
	r1 = D(r1, s[1][0][1], 0xF7D51406, 0xF419110E, 0x16ECD0FA, 0xD84F0FF9);
	r0 = D(r0, s[1][0][2], 0xE7D7FA01, 0xFBFAFBFC, 0xF3060306, 0xF8D6FBF3);
	r1 = D(r1, s[1][0][2], 0xFBF1F007, 0x01DE020A, 0xE900FFEF, 0x013FF606);
	r0 = D(r0, s[1][1][0], 0x1DDAF6FA, 0xFFFB0102, 0xD7EFEAF4, 0x0427EF06);
	r1 = D(r1, s[1][1][0], 0x1BEDEFEB, 0x01FA03ED, 0xDA200706, 0x020D0FFF);
	r0 = D(r0, s[1][1][1], 0x3C8C2214, 0xD61CFFDA, 0xC806FDDF, 0x17EDEB0D);
	r1 = D(r1, s[1][1][1], 0x05810833, 0x0FD3FB0D, 0x29D1E003, 0xBE2822E9);
	r0 = D(r0, s[1][1][2], 0xE2B9F9DD, 0x002EEB11, 0xD8FFFEF2, 0xF4D80C0E);
	r1 = D(r1, s[1][1][2], 0xEE81050F, 0x06E911F4, 0x080D0D3A, 0x152CFD14);
	r0 = D(r0, s[1][2][0], 0xF7FF10EF, 0x080106FE, 0xE6FAF1FE, 0xE3F4FBFF);
	r1 = D(r1, s[1][2][0], 0xFF0802F0, 0xF3CFEF00, 0xE612EAE9, 0x09050904);
	r0 = D(r0, s[1][2][1], 0x140808E1, 0xFA02FD17, 0xD8FA01EA, 0x39C60BF3);
	r1 = D(r1, s[1][2][1], 0x0AFD03F9, 0xEFC906EF, 0x0DDE07DC, 0x2A050106);
	r0 = D(r0, s[1][2][2], 0xFCF1F801, 0x0CEA04F7, 0xFDEC10F4, 0x05EBF907);
	r1 = D(r1, s[1][2][2], 0xFAE200FC, 0x13EA160A, 0x0D0BF1F8, 0x0409F6FC);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x07FAFC01, 0xF5EF030F, 0xFD02FDF0, 0xF7040300);
	r1 = D(r1, s[0][0][0], 0x0AF801F9, 0xE1FC0E03, 0xF705010F, 0x00FAF403);
	r0 = D(r0, s[0][0][1], 0x0D1EF503, 0xFAE30011, 0xFC08FEFD, 0xE8070208);
	r1 = D(r1, s[0][0][1], 0x1A1D050A, 0xCDF5F21D, 0xF4FE08FE, 0x28E5030C);
	r0 = D(r0, s[0][0][2], 0x0616F9FF, 0x00CC0008, 0xFBFF02FE, 0xEFFDF701);
	r1 = D(r1, s[0][0][2], 0xFEF4F5FA, 0xEC060D11, 0xFA00FF0F, 0x20150114);
	r0 = D(r0, s[0][1][0], 0x0CF106EF, 0x13F3FC1E, 0xFB0501FB, 0xFA06FE09);
	r1 = D(r1, s[0][1][0], 0xEFF812F4, 0xEF0313FE, 0x0B19FA0B, 0x09FBF81F);
	r0 = D(r0, s[0][1][1], 0x051DF0E4, 0x12D6FB2B, 0xE90FFEEF, 0xF14AFDDC);
	r1 = D(r1, s[0][1][1], 0x1011EF12, 0x0DFBF6EB, 0x01F51110, 0x15111EF4);
	r0 = D(r0, s[0][1][2], 0xEC0800FC, 0x2BF9FC1C, 0x01F6FBF3, 0xEF10F8F7);
	r1 = D(r1, s[0][1][2], 0x0F05F304, 0xE200FEFB, 0xF8FFEE0F, 0x1FF50311);
	r0 = D(r0, s[0][2][0], 0x05040202, 0x06090006, 0x03FB0100, 0xFA03060E);
	r1 = D(r1, s[0][2][0], 0xF3F2FE0D, 0xEFF91101, 0xFF111604, 0xFCF6F312);
	r0 = D(r0, s[0][2][1], 0xF4FAF1EF, 0x10F9F008, 0xFF0101FD, 0x33F0FC16);
	r1 = D(r1, s[0][2][1], 0x13F7FC13, 0xEAF00408, 0xF411061A, 0x1A0AFC0E);
	r0 = D(r0, s[0][2][2], 0xF0F3FC11, 0x0408000C, 0xFE02FBFE, 0xFEF60A13);
	r1 = D(r1, s[0][2][2], 0x0FF0EF11, 0xDEF0FFF0, 0x11FE0705, 0x0503FCFE);
	r0 = D(r0, s[1][0][0], 0xF806FF07, 0x13110602, 0xFE01FF03, 0x01FE2902);
	r1 = D(r1, s[1][0][0], 0x04FAFFF2, 0xF40D0816, 0x0CF6F806, 0xF9F9F8FC);
	r0 = D(r0, s[1][0][1], 0x0FF616FD, 0xFA03F5F4, 0x06FBF9FE, 0xFF171C05);
	r1 = D(r1, s[1][0][1], 0x04D6DCF2, 0x101EF90C, 0xEF111E00, 0x08E9DC0A);
	r0 = D(r0, s[1][0][2], 0xFD061DFE, 0x11F7E601, 0x010602FF, 0x0C122B02);
	r1 = D(r1, s[1][0][2], 0x0E0AEF08, 0xF4110800, 0xF1FC0F04, 0xF106E401);
	r0 = D(r0, s[1][1][0], 0xF8062AFD, 0x0105F4FA, 0xFAFDFDFB, 0xF30F59FB);
	r1 = D(r1, s[1][1][0], 0x040BF4F5, 0xD40FE406, 0x04EFFA12, 0x0808D0FF);
	r0 = D(r0, s[1][1][1], 0xFB101F06, 0x0DF8EFF3, 0x0CF5060B, 0xEADAE716);
	r1 = D(r1, s[1][1][1], 0xECC7ECD8, 0xF5331412, 0xDD0605FF, 0x1DC50A12);
	r0 = D(r0, s[1][1][2], 0x0211F806, 0x02F8F3FE, 0xFB171005, 0xF7FF180C);
	r1 = D(r1, s[1][1][2], 0xF621EA0B, 0xDA1D1307, 0xF71B180F, 0x03F2F5F8);
	r0 = D(r0, s[1][2][0], 0xF6EF0F00, 0x06FC0F03, 0xFF0401F9, 0xEF0B2812);
	r1 = D(r1, s[1][2][0], 0xFE100FFA, 0x08FAC112, 0x020CFB0A, 0xF906F806);
	r0 = D(r0, s[1][2][1], 0x010B59F3, 0x0006DFFF, 0xF70004FF, 0xE0F94A12);
	r1 = D(r1, s[1][2][1], 0x0E13FDF3, 0xE9040811, 0x0BED1D00, 0x09FBD8FE);
	r0 = D(r0, s[1][2][2], 0xFC063BFB, 0xF908FEFD, 0x00030AFA, 0x050B1903);
	r1 = D(r1, s[1][2][2], 0x0613FFF9, 0xF40AFA11, 0xF10D1B08, 0xFF01E0FA);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-2.875e-02, -2.901e-02, 1.553e-01, 1.580e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-5.088e-03, 6.706e-02, 1.837e-02, -1.712e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-6x8C-TEST-conv4
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv3
//!BIND LUMA
//!SAVE conv4
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv3_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv3_pt)
#define l1(x, y) conv3_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv3_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFB0806FF, 0x07FFFB00, 0x0708FBF8, 0x04FC0BF3);
	r1 = D(r1, s[0][0][0], 0xFFF30711, 0x06EF0BFC, 0x0BFA00E3, 0xF2FA0205);
	r0 = D(r0, s[0][0][1], 0x0002F2FE, 0x17060AEE, 0xFC06F90B, 0x0C12F1FA);
	r1 = D(r1, s[0][0][1], 0xD60E0D11, 0xEC0C1900, 0xF9FF00F9, 0x0501EDF4);
	r0 = D(r0, s[0][0][2], 0xF9FB02FA, 0x0CF8F8F8, 0xF20100FF, 0x14FEFCF6);
	r1 = D(r1, s[0][0][2], 0xF906EF07, 0x0108040B, 0x02FE0BFC, 0x07FE00FF);
	r0 = D(r0, s[0][1][0], 0xFCFC0EF4, 0x17FB07E3, 0xF311F11E, 0x0E021DF5);
	r1 = D(r1, s[0][1][0], 0xF3020FFE, 0x04050A05, 0x071226F6, 0x06020BF4);
	r0 = D(r0, s[0][1][1], 0x0BFF0DFB, 0xE3FFE314, 0xF5E717F4, 0x00FECD06);
	r1 = D(r1, s[0][1][1], 0xD30027D7, 0xE5EF01FA, 0xF5F417F5, 0x0DF8B3E3);
	r0 = D(r0, s[0][1][2], 0x0F000508, 0x010AFF19, 0x060015FE, 0x01FCF8F9);
	r1 = D(r1, s[0][1][2], 0xE70E05FB, 0xF5020E0C, 0x010A1D07, 0x0804E1FB);
	r0 = D(r0, s[0][2][0], 0xF8050112, 0x0D011100, 0xFA01F1FB, 0xFEFB0FF4);
	r1 = D(r1, s[0][2][0], 0x0D01F3F3, 0x060CF8F5, 0x06FE040A, 0x020408F4);
	r0 = D(r0, s[0][2][1], 0xF8FAF8FC, 0x02F519FC, 0xF9FBEFFA, 0xF5FC00FB);
	r1 = D(r1, s[0][2][1], 0xF8F815FB, 0x05F208F3, 0x0EFF2D13, 0x0C02F6FC);
	r0 = D(r0, s[0][2][2], 0xFEFB0FF6, 0x05050A00, 0xF8000407, 0xFE08E905);
	r1 = D(r1, s[0][2][2], 0xFFF8F8E3, 0xF50CFC02, 0xFCFF0E0A, 0xFFFE060B);
	r0 = D(r0, s[1][0][0], 0x17D50400, 0x0FFAF3EF, 0x0C02F9F6, 0xFCC9FAFA);
	r1 = D(r1, s[1][0][0], 0xF333FFFE, 0xEB13020F, 0xF9DF06F6, 0x04D4FAFB);
	r0 = D(r0, s[1][0][1], 0x08BBFFFF, 0x11FB06F6, 0xEE0AFCFB, 0x05E3070A);
	r1 = D(r1, s[1][0][1], 0xF42600F5, 0xE5EEFC1D, 0xFBCF1102, 0xFEEBFEF3);
	r0 = D(r0, s[1][0][2], 0xFCC7F804, 0x000BFEFE, 0xFB1D000B, 0xFAFA020F);
	r1 = D(r1, s[1][0][2], 0xEDF60B02, 0xECFF0604, 0xF50EFEF6, 0x07D2FA05);
	r0 = D(r0, s[1][1][0], 0x02C10801, 0xE5FCFEF8, 0x04240B05, 0xE8A9F2DC);
	r1 = D(r1, s[1][1][0], 0xF6C4FC01, 0xF41AF804, 0xE0CEF20C, 0xE5AEE6F8);
	r0 = D(r0, s[1][1][1], 0x01810B05, 0xF5200ED5, 0x39070839, 0x0D7F1DEC);
	r1 = D(r1, s[1][1][1], 0x158FE92D, 0xF9210A2D, 0x074B17FC, 0xE12307C4);
	r0 = D(r0, s[1][1][2], 0xFEC2FA1B, 0xE740F5E8, 0xFE19FFFB, 0x13E30BFB);
	r1 = D(r1, s[1][1][2], 0x112D0BE2, 0xF80BFAE2, 0x061DEEF2, 0xFAB3F901);
	r0 = D(r0, s[1][2][0], 0x0BDF00FB, 0x04070AFB, 0xF90E0DFB, 0x05C70601);
	r1 = D(r1, s[1][2][0], 0xEE0613EF, 0xEFDAF8F2, 0x06170A11, 0xFFF1FE08);
	r0 = D(r0, s[1][2][1], 0x0BAEFB00, 0xF40AC1ED, 0xF60C191E, 0xEEE2F9F1);
	r1 = D(r1, s[1][2][1], 0xF8FCCDFC, 0xFA04061F, 0x0E4F0FFC, 0x00DA0FF2);
	r0 = D(r0, s[1][2][2], 0x04C9070F, 0xFBF10DFC, 0xFF2DEDFA, 0xF6320AF8);
	r1 = D(r1, s[1][2][2], 0xF61A01FC, 0xFCECECEF, 0x0A1AF407, 0x07F4FFFC);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFB070101, 0xFC0505FA, 0xF4F6FC00, 0xFB060605);
	r1 = D(r1, s[0][0][0], 0x0700FA02, 0x0AFA0105, 0xEEF1FBF1, 0x000701FF);
	r0 = D(r0, s[0][0][1], 0xF80B000F, 0xFFF8F6F2, 0xF4F9FF15, 0xFC05FC13);
	r1 = D(r1, s[0][0][1], 0x0D0D0204, 0x1402F9EF, 0xFC06FBED, 0x050DF617);
	r0 = D(r0, s[0][0][2], 0xFCF80B12, 0xFF01FC05, 0xF4F6FAFC, 0xEE040AF5);
	r1 = D(r1, s[0][0][2], 0xFE0C01F6, 0x0B07F8FB, 0x0AFBF5FA, 0xFCFF0504);
	r0 = D(r0, s[0][1][0], 0x00F80602, 0x04F4FAF1, 0x11FE00F6, 0xFC04FB02);
	r1 = D(r1, s[0][1][0], 0x04FF02FC, 0x07EFF602, 0x26F506F2, 0x14FBFEEB);
	r0 = D(r0, s[0][1][1], 0x0EE9E5F9, 0xEF12FF0A, 0x21E61400, 0xCC3A0DFC);
	r1 = D(r1, s[0][1][1], 0xE92AF8FE, 0x110D1325, 0x2EFE20FF, 0xC708E2F9);
	r0 = D(r0, s[0][1][2], 0xFCFE0D02, 0xFBEE02F4, 0x1A0601FA, 0xFA06001E);
	r1 = D(r1, s[0][1][2], 0x061FF9F9, 0x230002DF, 0x17010EFE, 0xEFF901F6);
	r0 = D(r0, s[0][2][0], 0x080201FC, 0x05FEFC04, 0x01EBF3FB, 0x02070408);
	r1 = D(r1, s[0][2][0], 0xFC01F200, 0x0C04FA00, 0xF8EC01E9, 0x080E06FE);
	r0 = D(r0, s[0][2][1], 0x19F6F1FB, 0x080FEB04, 0x1904FFFB, 0x010708FA);
	r1 = D(r1, s[0][2][1], 0x02170B04, 0xD9060D08, 0xEEFEF6FB, 0xF902F805);
	r0 = D(r0, s[0][2][2], 0x05F9FF05, 0x000CFEFF, 0xF9FC06FA, 0x06FE07FE);
	r1 = D(r1, s[0][2][2], 0x050CEB0C, 0xFE02F2F9, 0xF10604EB, 0x08010005);
	r0 = D(r0, s[1][0][0], 0x01F5FB02, 0xF902F60E, 0xF30812FC, 0xF60BF201);
	r1 = D(r1, s[1][0][0], 0xFB0C1905, 0x06051BF8, 0x0207F10D, 0xFF080B11);
	r0 = D(r0, s[1][0][1], 0x02F206FB, 0xF40FFF0D, 0x0E05F2E8, 0x0AEDEDF8);
	r1 = D(r1, s[1][0][1], 0x12180606, 0x0C120800, 0xFAE8F502, 0x0CFF2708);
	r0 = D(r0, s[1][0][2], 0x0106FEF9, 0xF800F411, 0x0005F401, 0x01F221FB);
	r1 = D(r1, s[1][0][2], 0x0AFA17F9, 0x05F9E802, 0xF302DF02, 0x0B01F808);
	r0 = D(r0, s[1][1][0], 0x0D040602, 0x001DF314, 0xFEFB12F5, 0xF61DEF11);
	r1 = D(r1, s[1][1][0], 0xF9FF07FE, 0xFE0A0C05, 0xE3F2DA01, 0xF9041914);
	r0 = D(r0, s[1][1][1], 0x0214150C, 0x1ADA05EF, 0x0D26FADA, 0x3CE71304);
	r1 = D(r1, s[1][1][1], 0x1DE11EE1, 0x07DAE9C8, 0xE5FCE0C1, 0x0A0B0F25);
	r0 = D(r0, s[1][1][2], 0xF9FBD313, 0xEFFAEB05, 0x07F50605, 0x1508D2E2);
	r1 = D(r1, s[1][1][2], 0x020BECFE, 0xEB052601, 0xEFFEF2F5, 0x0204130D);
	r0 = D(r0, s[1][2][0], 0xFFE8FA04, 0xF6F2ED0E, 0xFCECEE00, 0xF3FAFAFA);
	r1 = D(r1, s[1][2][0], 0x080DF51A, 0x0012F818, 0xFAE7FEFB, 0x00FAFAFB);
	r0 = D(r0, s[1][2][1], 0xEDF6001D, 0x0C00ED0C, 0x13130E00, 0x0F0011FE);
	r1 = D(r1, s[1][2][1], 0x0FEB0100, 0x1F01FFE7, 0x00FACCE8, 0xED01F200);
	r0 = D(r0, s[1][2][2], 0x06012402, 0xF5EE0101, 0xF61413F8, 0x08F80BFC);
	r1 = D(r1, s[1][2][2], 0x0C0633FF, 0xF4FCF4FE, 0x04FFEF0C, 0xF6F6F400);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(2.793e-02, 6.506e-03, -2.487e-02, -1.732e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-1.236e-02, -2.552e-02, -6.637e-03, 5.250e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-6x8C-TEST-conv5
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv4
//!BIND LUMA
//!SAVE conv5
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv4_pt)
#define l1(x, y) conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv4_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x04FBEC02, 0xFB064605, 0xFCF9EDF4, 0xFFFDE2FF);
	r1 = D(r1, s[0][0][0], 0xFFFEEE06, 0x0105F7FB, 0xF7F7EA0A, 0xEC0DE508);
	r0 = D(r0, s[0][0][1], 0xFDFDD4F6, 0xF90D4B04, 0xFA0CED0E, 0x06FECEFC);
	r1 = D(r1, s[0][0][1], 0xFEFEF2F6, 0x0AFBF608, 0x0207F805, 0x07080BFB);
	r0 = D(r0, s[0][0][2], 0x02F8E9F6, 0xFB010A04, 0x00FCE5FB, 0xFE12DBFB);
	r1 = D(r1, s[0][0][2], 0xFEFBEC02, 0x0701F5FD, 0xFA0EF6F3, 0x05203511);
	r0 = D(r0, s[0][1][0], 0x10F50BF7, 0x04F9F805, 0x050DF0F8, 0x11FCD103);
	r1 = D(r1, s[0][1][0], 0xF6F9F200, 0xEBF2EB05, 0x00FCD605, 0xFC080CF3);
	r0 = D(r0, s[0][1][1], 0x040FF0FB, 0x17E94604, 0xFDF5370E, 0x1006D002);
	r1 = D(r1, s[0][1][1], 0x16EF21FF, 0xECF5BE21, 0x0DFF110B, 0x0B0F561B);
	r0 = D(r0, s[0][1][2], 0xF9F0F0E3, 0xF8021BF6, 0xF50911F8, 0xFEFEDBFA);
	r1 = D(r1, s[0][1][2], 0xF50AF9F8, 0x0AF5D107, 0x0518FCFE, 0xFEFC1107);
	r0 = D(r0, s[0][2][0], 0xFCFF0AFC, 0xF9F600FC, 0x0002FCF6, 0xF5FEECFC);
	r1 = D(r1, s[0][2][0], 0xFE07FAFC, 0xFC00E803, 0x1EFF0E05, 0x00FEFE03);
	r0 = D(r0, s[0][2][1], 0x01090205, 0x01F506FB, 0xFEFC1215, 0x03F8D3FC);
	r1 = D(r1, s[0][2][1], 0xFC170D01, 0xFEF5E706, 0xF501FD04, 0x05FBF8FB);
	r0 = D(r0, s[0][2][2], 0x04F6E8FC, 0xF8010E04, 0x00F9060A, 0xFFFEE6FA);
	r1 = D(r1, s[0][2][2], 0x03EC1209, 0x0DFBEBFB, 0x08F90403, 0xF80004F5);
	r0 = D(r0, s[1][0][0], 0xF80509EA, 0x0414FCFE, 0xFB0A02F4, 0x04FE0405);
	r1 = D(r1, s[1][0][0], 0xFFFC0AFE, 0x04F9FB0E, 0x000403F7, 0x15080BEA);
	r0 = D(r0, s[1][0][1], 0x05EB0806, 0xF60BF4F5, 0xF007F6D1, 0xFEF00307);
	r1 = D(r1, s[1][0][1], 0xFCF302FA, 0xFEF7F806, 0x0115F902, 0xF60B0D0A);
	r0 = D(r0, s[1][0][2], 0xFA0202F5, 0x011402EE, 0xFD1D05ED, 0xFFF5FDF9);
	r1 = D(r1, s[1][0][2], 0x010205FE, 0x07EC0020, 0x06020213, 0xF5F2F302);
	r0 = D(r0, s[1][1][0], 0xE9FBF5FE, 0xF00910FD, 0xF10502FD, 0xFAFB0B0E);
	r1 = D(r1, s[1][1][0], 0x10070F09, 0x0CFAFDFF, 0x0116140D, 0x04FF000E);
	r0 = D(r0, s[1][1][1], 0x36D6FEFF, 0xE514050B, 0x0E1FECD6, 0xF1F8E711);
	r1 = D(r1, s[1][1][1], 0xEF020508, 0x35ED16AA, 0xFA16FA0B, 0xD602EFF6);
	r0 = D(r0, s[1][1][2], 0x00060BFC, 0xFC230000, 0xFE1101E9, 0x07F2FB04);
	r1 = D(r1, s[1][1][2], 0xFF0700FE, 0x0BE204F8, 0xFEEB04F5, 0xFEFDFE0D);
	r0 = D(r0, s[1][2][0], 0x14F9FCEC, 0x200109F7, 0xFB0602EF, 0x0BFE000F);
	r1 = D(r1, s[1][2][0], 0xF2030702, 0xFCF9FD08, 0xEE0E07EB, 0x04FF0107);
	r0 = D(r0, s[1][2][1], 0x1AF0F207, 0xF30E0BEE, 0xF81301DC, 0x0AFF02F5);
	r1 = D(r1, s[1][2][1], 0x0502031E, 0x11F8FF14, 0x1111F20E, 0xFE020401);
	r0 = D(r0, s[1][2][2], 0xFE0207FB, 0x0705FFFF, 0xFB1605F3, 0x08FD0208);
	r1 = D(r1, s[1][2][2], 0xFE2102FC, 0x01F3FC11, 0xFEF8FEFE, 0x05F80008);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x03F2060B, 0xFD0D09ED, 0x07090513, 0x02FFF90A);
	r1 = D(r1, s[0][0][0], 0x0C0401F9, 0xFBF902F9, 0x0412FD07, 0x11F3FAED);
	r0 = D(r0, s[0][0][1], 0x12EAFE08, 0xF319F2F4, 0x23E707F3, 0x14F40B01);
	r1 = D(r1, s[0][0][1], 0x0C02F80F, 0xF20A0BFC, 0x0AF50BF0, 0x0EDB04F3);
	r0 = D(r0, s[0][0][2], 0x0AE3060A, 0xF8020100, 0xF2F60AF9, 0x09EAFC0C);
	r1 = D(r1, s[0][0][2], 0xFDF70008, 0x050EFCFB, 0xF3FEFB06, 0x24F800FB);
	r0 = D(r0, s[0][1][0], 0x0DEC1415, 0xFC0BDF0B, 0x070314FE, 0x07FCFC14);
	r1 = D(r1, s[0][1][0], 0xFF0AF01A, 0x0B0504F9, 0x21F5D804, 0x04EEFB16);
	r0 = D(r0, s[0][1][1], 0x44181CED, 0x1BED03DB, 0xEFC30BDE, 0x01EF3527);
	r1 = D(r1, s[0][1][1], 0xFE1C14EF, 0xFCF1E024, 0x041017F0, 0x0BE2100C);
	r0 = D(r0, s[0][1][2], 0xD1FB000F, 0xE404F7FC, 0xF610F501, 0xF8ECFB11);
	r1 = D(r1, s[0][1][2], 0x0CFBF412, 0x1A14020B, 0x10F00211, 0xF9ECFE1C);
	r0 = D(r0, s[0][2][0], 0xFCF60B01, 0x0C09FE03, 0x09060603, 0x00020805);
	r1 = D(r1, s[0][2][0], 0x19F8100A, 0xFBFF0208, 0xFE0008FF, 0x0102010D);
	r0 = D(r0, s[0][2][1], 0x13DA0426, 0xEC16FFEF, 0x0E010EFA, 0xF70804FF);
	r1 = D(r1, s[0][2][1], 0x38C8FCF0, 0xFD020207, 0x20E302F6, 0xF50BF7F9);
	r0 = D(r0, s[0][2][2], 0xF3010710, 0x0D040105, 0x05EF070C, 0x07FEFB0D);
	r1 = D(r1, s[0][2][2], 0xE3F90E11, 0x0805FB02, 0xE0060304, 0x010EF60D);
	r0 = D(r0, s[1][0][0], 0x05F9F503, 0x010808F8, 0x06FB0401, 0xFB0004FF);
	r1 = D(r1, s[1][0][0], 0xF902F408, 0xFC05FF04, 0x07FE0AF8, 0xEA060E08);
	r0 = D(r0, s[1][0][1], 0xF505F20E, 0x110305F9, 0xEE05FA05, 0xF3F4E812);
	r1 = D(r1, s[1][0][1], 0xFF02020A, 0x0B09F804, 0xFDFEF701, 0xF20C0018);
	r0 = D(r0, s[1][0][2], 0xFDF40DFE, 0x0104FDFD, 0x09FB05F8, 0xF3020701);
	r1 = D(r1, s[1][0][2], 0x00010204, 0xFCFE04F9, 0xFEFE0AFF, 0xEA08F50A);
	r0 = D(r0, s[1][1][0], 0x0EFED60A, 0x05F91BF1, 0xEDFD0407, 0x03FEFDF6);
	r1 = D(r1, s[1][1][0], 0x07F613F0, 0xFEFDEF0F, 0xE80934F2, 0xFCFFFD01);
	r0 = D(r0, s[1][1][1], 0xFCE4E8F3, 0xDD0308F9, 0x092FF911, 0x0AF9E309);
	r1 = D(r1, s[1][1][1], 0x0A02FE01, 0x1A0D08F5, 0xE3FDEB0E, 0xFDF6D619);
	r0 = D(r0, s[1][1][2], 0x110C0E08, 0x080704FE, 0xF1090CF9, 0x13070402);
	r1 = D(r1, s[1][1][2], 0xF20906F7, 0xEAECFFFC, 0xEAED0AEF, 0x0B0A01FF);
	r0 = D(r0, s[1][2][0], 0x0801FB02, 0xF3FE11F4, 0xF6F902FB, 0xFAFF09FD);
	r1 = D(r1, s[1][2][0], 0xF1FCF508, 0x04FFFA04, 0x0504F806, 0xFA0206FB);
	r0 = D(r0, s[1][2][1], 0xF4F6FAFC, 0x0C01FE05, 0xF805E50D, 0x0A030AFF);
	r1 = D(r1, s[1][2][1], 0xE5200102, 0x07FC0D00, 0xF604ECFC, 0x08F90DF9);
	r0 = D(r0, s[1][2][2], 0x0E000201, 0xF001FAFC, 0xFB08F6FC, 0x00FE0AFD);
	r1 = D(r1, s[1][2][2], 0x0803F608, 0xFDF70809, 0x0CFEFF0C, 0xFDFF10FE);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(1.464e-02, -5.008e-03, 7.644e-03, 1.656e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-9.976e-04, -1.024e-02, 2.977e-03, -2.637e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-6x8C-TEST-conv6
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv5
//!BIND LUMA
//!SAVE conv6
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv5_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv5_pt)
#define l1(x, y) conv5_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv5_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xF5070306, 0x0701FEF4, 0xFF06F9F6, 0x05010201);
	r1 = D(r1, s[0][0][0], 0xFAFB0309, 0x03FDFDF7, 0xFA08FDFF, 0x04FAFFFB);
	r0 = D(r0, s[0][0][1], 0x0F00F5F4, 0xF9FFFEF7, 0x04F7FDED, 0xFFF20915);
	r1 = D(r1, s[0][0][1], 0x010601FD, 0x080CEFEA, 0xE7FF090A, 0xF6FCFF07);
	r0 = D(r0, s[0][0][2], 0xF5F70411, 0x0006F800, 0xF903FAFD, 0xFD030103);
	r1 = D(r1, s[0][0][2], 0x04F40C08, 0x01F604FD, 0xFB0DECE6, 0xFF05F4F6);
	r0 = D(r0, s[0][1][0], 0xEF06F701, 0x0DFDFCFF, 0x19FFF9EB, 0xFBFB03F4);
	r1 = D(r1, s[0][1][0], 0x01070507, 0x06FE0519, 0xF703F7EF, 0xFBFB00FF);
	r0 = D(r0, s[0][1][1], 0x0E20E7F3, 0xE4F80727, 0x15DD0F39, 0xF307070A);
	r1 = D(r1, s[0][1][1], 0x2DEBFFCB, 0x09EF0907, 0x2703FB17, 0xF10DEE06);
	r0 = D(r0, s[0][1][2], 0xFBEF1613, 0x080AF7E7, 0xFBF00E01, 0x0A01F5FC);
	r1 = D(r1, s[0][1][2], 0xF1F3160F, 0xFAF20203, 0xF907FD04, 0xFCF9F919);
	r0 = D(r0, s[0][2][0], 0x01FEFA01, 0xFF030604, 0xEDFC0101, 0xFCFFFBFF);
	r1 = D(r1, s[0][2][0], 0x0E010503, 0xF5000CFC, 0xFEFAFBFC, 0xF807FA07);
	r0 = D(r0, s[0][2][1], 0x110104F7, 0xFBEF03EF, 0xF100F9F6, 0x0406030F);
	r1 = D(r1, s[0][2][1], 0xFA0FFE05, 0xF2F70115, 0xFB0705FD, 0xFEFBF403);
	r0 = D(r0, s[0][2][2], 0xFFFF0609, 0x06FA04F7, 0xFE05FFFA, 0x0604FBFF);
	r1 = D(r1, s[0][2][2], 0xFB010003, 0xFD0BF801, 0x01F7FDFF, 0xF9FFF8FB);
	r0 = D(r0, s[1][0][0], 0x0DFDF501, 0xF9050404, 0x00030206, 0xFBFFFBFF);
	r1 = D(r1, s[1][0][0], 0x030307FD, 0x01000A03, 0xFF0505FD, 0xF9FCFB01);
	r0 = D(r0, s[1][0][1], 0xFDFD0A01, 0x0CFBFF07, 0xFB120E07, 0xFD04FFF5);
	r1 = D(r1, s[1][0][1], 0xFAFFF5FF, 0x03FC0909, 0x15F71300, 0x00FD0F05);
	r0 = D(r0, s[1][0][2], 0x000500FD, 0xFDFF0605, 0x01FF0101, 0xFEFDFC03);
	r1 = D(r1, s[1][0][2], 0xFD07FDF7, 0x050202F9, 0xFFF7F609, 0x08FE0708);
	r0 = D(r0, s[1][1][0], 0x1402F706, 0xF90305F9, 0xED1609FA, 0xFF09FB02);
	r1 = D(r1, s[1][1][0], 0x03F50505, 0xF8F105F5, 0xF607F502, 0x0C0B0501);
	r0 = D(r0, s[1][1][1], 0xF7F93A07, 0x0AE9DEF9, 0x0D482FF1, 0x03030A05);
	r1 = D(r1, s[1][1][1], 0x0106CB05, 0xF5FBF904, 0x040B05FF, 0x0FEB47FE);
	r0 = D(r0, s[1][1][2], 0x010FE7F6, 0xF3FB1505, 0x030BFDF8, 0x0B06FAFD);
	r1 = D(r1, s[1][1][2], 0xFFF9F8FF, 0xFFFD1103, 0xFE081700, 0xFA0618F9);
	r0 = D(r0, s[1][2][0], 0x000403FB, 0xFBFFFCFB, 0xFD080001, 0x0A0006FF);
	r1 = D(r1, s[1][2][0], 0x00FEFD01, 0x0706F707, 0xFD0801FB, 0x0BFE09FD);
	r0 = D(r0, s[1][2][1], 0xF70BF402, 0x0303F604, 0x0CF80809, 0xF7FBFC01);
	r1 = D(r1, s[1][2][1], 0x03F103FD, 0x160108F9, 0xF7FBF405, 0xFF0FFA05);
	r0 = D(r0, s[1][2][2], 0x0100F2FB, 0x000701FB, 0x03FD0D01, 0xFFFE0503);
	r1 = D(r1, s[1][2][2], 0x010406FF, 0x05031300, 0x03050201, 0x0307FD03);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x01070501, 0x000101FF, 0x04FBFDFE, 0x02FFFD09);
	r1 = D(r1, s[0][0][0], 0xFFFB00FC, 0xFDFD04F3, 0xFFFFFE03, 0x02080101);
	r0 = D(r0, s[0][0][1], 0x01FE0509, 0xFF0802F7, 0xFDFFFF03, 0xFD04FDF4);
	r1 = D(r1, s[0][0][1], 0x03F9F405, 0xFF070613, 0x00FF19F1, 0xFF0AFE06);
	r0 = D(r0, s[0][0][2], 0xFB06FDF6, 0x01FF020D, 0x01050102, 0x00FDFFFF);
	r1 = D(r1, s[0][0][2], 0x0005FDFE, 0x00020204, 0x01010305, 0x00FFFD02);
	r0 = D(r0, s[0][1][0], 0xF10115FB, 0x05FFEDFB, 0x09FAF1FD, 0xFDF9FD03);
	r1 = D(r1, s[0][1][0], 0x0D020102, 0x0505FA05, 0x070611FE, 0xF3FDF705);
	r0 = D(r0, s[0][1][1], 0xFBFD11FF, 0xFF11E90B, 0xF209DE07, 0x08F726FB);
	r1 = D(r1, s[0][1][1], 0xF6FACFFE, 0xFD05E405, 0xF4001DFB, 0x00FAF801);
	r0 = D(r0, s[0][1][2], 0x02FA0A07, 0xFA03FB05, 0x01020DFF, 0xFCFB01FE);
	r1 = D(r1, s[0][1][2], 0x0900FF01, 0xFAFFFD09, 0xFB0B0C07, 0xFAFFFE0F);
	r0 = D(r0, s[0][2][0], 0xFB00FF01, 0x07FF0100, 0x02031102, 0x02FFF8FF);
	r1 = D(r1, s[0][2][0], 0xFD0101FF, 0xFEFB0404, 0xFC010001, 0x0201F8FD);
	r0 = D(r0, s[0][2][1], 0xF309FAF9, 0x01FF070D, 0x11F90905, 0x010703F9);
	r1 = D(r1, s[0][2][1], 0x09FB0603, 0x0DF10EFF, 0x060706FE, 0xF71002F8);
	r0 = D(r0, s[0][2][2], 0xFCFF0101, 0x00F803FF, 0x02FB0003, 0xF304FDFD);
	r1 = D(r1, s[0][2][2], 0x0B02FFFD, 0x0A04FEFF, 0xF9FBFFFF, 0xFE00FA03);
	r0 = D(r0, s[1][0][0], 0xF7F5F5EE, 0x000B0021, 0xF9FF0E01, 0x000602FD);
	r1 = D(r1, s[1][0][0], 0x0303FF0B, 0xFDF50013, 0x05020009, 0x030304F2);
	r0 = D(r0, s[1][0][1], 0xFC0AED1B, 0xFFEE0612, 0xFFF3FF20, 0x03E8FAF3);
	r1 = D(r1, s[1][0][1], 0x05031307, 0xFA0C08ED, 0xF9E4F1F1, 0xFDFB03F0);
	r0 = D(r0, s[1][0][2], 0x03010D00, 0x0105FDFB, 0xFC020502, 0x000D04FC);
	r1 = D(r1, s[1][0][2], 0xFFEB05FE, 0xFCF803EB, 0xFE0F05ED, 0x000E03F9);
	r0 = D(r0, s[1][1][0], 0x05FDD906, 0x0D041213, 0x020715F9, 0xF90903F7);
	r1 = D(r1, s[1][1][0], 0xF1F10207, 0x16010AEA, 0xF1FD0104, 0x010DFAE9);
	r0 = D(r0, s[1][1][1], 0x0915EDFA, 0x06CC0BF7, 0x01F5FB0E, 0xEAFDE409);
	r1 = D(r1, s[1][1][1], 0xF4001CF5, 0x0ED81FF7, 0x0100DFFB, 0x17F90A9F);
	r0 = D(r0, s[1][1][2], 0xF300F9F5, 0x0D020810, 0xFC20FA03, 0x011BFBED);
	r1 = D(r1, s[1][1][2], 0xFD010B19, 0x010A040F, 0xECEDF903, 0x09FF0BF7);
	r0 = D(r0, s[1][2][0], 0x0B010303, 0xF1FE0601, 0xF0FFFFFD, 0xFF0404FD);
	r1 = D(r1, s[1][2][0], 0x15FEF3FB, 0xEC0505F9, 0x04FE0301, 0xF7FC060A);
	r0 = D(r0, s[1][2][1], 0xEEFD0801, 0x01FC1402, 0x110507F3, 0x1BFBF105);
	r1 = D(r1, s[1][2][1], 0xECFDFF00, 0xEB0AF4F9, 0x07010303, 0xE6D5F907);
	r0 = D(r0, s[1][2][2], 0xFF0202FD, 0xFF0B0003, 0xEBF5FA00, 0xFE01FFFB);
	r1 = D(r1, s[1][2][2], 0x0AFAFB06, 0xFBEFF7FE, 0xF90A02F9, 0x09EF07F8);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-1.684e-03, -3.060e-03, -1.105e-03, 2.326e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(1.576e-03, 4.583e-03, -4.848e-03, 8.649e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-6x8C-TEST-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv6
//!BIND easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv6_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv6_pt)
#define l1(x, y) conv6_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv6_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
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
			vec4 v0 = l0(x - 1, y - 1);
			vec4 v1 = max(-v0, vec4(0));
			v0 = max(v0, vec4(0));
			vec4 v2 = l1(x - 1, y - 1);
			vec4 v3 = max(-v2, vec4(0));
			v2 = max(v2, vec4(0));
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
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
	r0 = D(r0, s[0][0][0], 0x19FDF7F7, 0x0301F9F6, 0x0E01F9F7, 0xF502FFFF);
	r0 = D(r0, s[0][0][1], 0x18090704, 0xCF010C10, 0x1DF705F7, 0x0BFAF9F3);
	r0 = D(r0, s[0][0][2], 0x0400FF03, 0xFFFFFBF7, 0x03010205, 0x02F903FB);
	r0 = D(r0, s[0][1][0], 0x20000318, 0xEEFD03F1, 0x23FF0913, 0x07FFFCED);
	r0 = D(r0, s[0][1][1], 0x2C25F6A6, 0x0826F310, 0xF03AF9E1, 0xA9261C32);
	r0 = D(r0, s[0][1][2], 0x02F70712, 0xFAFD0BF7, 0x03F8030C, 0xDF0FF9FD);
	r0 = D(r0, s[0][2][0], 0xFB0000FF, 0xFF0001FD, 0x01FEFA05, 0xFBFC02F7);
	r0 = D(r0, s[0][2][1], 0x030501FF, 0xFE070301, 0x1D0400F4, 0x0911F00E);
	r0 = D(r0, s[0][2][2], 0xF900FD01, 0xE9FEFAF8, 0xFAFF030B, 0xF7F40605);
	r0 = D(r0, s[1][0][0], 0xF7090105, 0xFA020503, 0x04000905, 0x05FF04FF);
	r0 = D(r0, s[1][0][1], 0x04F3CB07, 0xFBFFF102, 0xED05FD03, 0xFE051409);
	r0 = D(r0, s[1][0][2], 0xF801FD03, 0xFBFD1307, 0xFF05F901, 0xF7070102);
	r0 = D(r0, s[1][1][0], 0xFD01FAFD, 0x0607FB06, 0xEA08F5F7, 0xFA060208);
	r0 = D(r0, s[1][1][1], 0x1DEE13FD, 0x09E741FC, 0x34DDB5FB, 0xF1EAF1E7);
	r0 = D(r0, s[1][1][2], 0xFA0DFBF9, 0x050D08F0, 0xF608FBFB, 0x1DF905F9);
	r0 = D(r0, s[1][2][0], 0x0403FE03, 0x02030000, 0x0604FC09, 0x0205FB03);
	r0 = D(r0, s[1][2][1], 0xF2FDF700, 0xF2FEFCFD, 0xF1FB0405, 0x01F5170D);
	r0 = D(r0, s[1][2][2], 0x0802FFFE, 0x0B020405, 0x050400FB, 0xFF0902FF);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xF60309F5, 0xFD0201F9, 0xFBFFFDF7, 0x03FFFE01);
	r0 = D(r0, s[0][0][1], 0x15F703FD, 0x07FE0903, 0x08FD09FF, 0xF7FE02F5);
	r0 = D(r0, s[0][0][2], 0xFB04FD02, 0x03FCFDF9, 0xFB0101FF, 0x04FF0301);
	r0 = D(r0, s[0][1][0], 0xFDF30509, 0xFAFFF7F5, 0xF5F80905, 0xF9FBF9F0);
	r0 = D(r0, s[0][1][1], 0xFE1BFD11, 0x0FF3051D, 0x11F3F103, 0x0CF40927);
	r0 = D(r0, s[0][1][2], 0x09FFFB09, 0xF90DF911, 0x0700F908, 0x04F0F1FB);
	r0 = D(r0, s[0][2][0], 0xFF04FFFB, 0xFF01FEFD, 0x01FC0200, 0xFA02FDFB);
	r0 = D(r0, s[0][2][1], 0xFFEFF9FB, 0xF9ECFCFF, 0xF7EFFE04, 0x09D8FA08);
	r0 = D(r0, s[0][2][2], 0x010107F6, 0x050606EF, 0x01FF05F9, 0xF4090BF5);
	r0 = D(r0, s[1][0][0], 0x00FB0A0F, 0x05FFFD06, 0x0301F507, 0x01FFFFFF);
	r0 = D(r0, s[1][0][1], 0xD9010507, 0xDEF93009, 0x0303F3FC, 0x0903F30B);
	r0 = D(r0, s[1][0][2], 0xFBFE07F9, 0xEC010705, 0x09FEFFFF, 0x030103FF);
	r0 = D(r0, s[1][1][0], 0xFEF9FCF0, 0x03070B0B, 0xFF0200FE, 0x09070013);
	r0 = D(r0, s[1][1][1], 0xFDEC26EE, 0xF3F3F7B1, 0xFCFFC424, 0xE301EDD4);
	r0 = D(r0, s[1][1][2], 0xF8FF06EB, 0xFBF432F9, 0xF8FEFFEF, 0x06FEF51D);
	r0 = D(r0, s[1][2][0], 0x01030201, 0xFF030502, 0x01F302FE, 0x01020503);
	r0 = D(r0, s[1][2][1], 0x01120105, 0x03140302, 0xFDFE15FF, 0x01FA0BF3);
	r0 = D(r0, s[1][2][2], 0x0300FA0A, 0x01FCF715, 0x01FEF305, 0xFFF2F80E);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-1.452e-04, 1.008e-04, 2.994e-04, 7.678e-04);
	f0 = tanh(f0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(f0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(f0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(f0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

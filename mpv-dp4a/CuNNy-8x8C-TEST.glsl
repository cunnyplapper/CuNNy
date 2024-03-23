// CuNNy 8x8C TEST
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

//!DESC CuNNy-8x8C-TEST-EASU
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


//!DESC CuNNy-8x8C-TEST-in
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
	r0 += V4(1.499e-01, -9.406e-02, -2.351e-02, 1.293e-01) * s[0][0][0];
	r1 += V4(-8.230e-02, -1.323e-01, -3.233e-02, -2.645e-02) * s[0][0][0];
	r0 += V4(-1.764e-01, -5.291e-02, -8.524e-02, -3.233e-02) * s[0][1][0];
	r1 += V4(-1.176e-02, 2.528e-01, 6.172e-02, -1.911e-01) * s[0][1][0];
	r0 += V4(3.821e-02, 1.411e-01, -2.851e-01, -4.115e-02) * s[0][2][0];
	r1 += V4(-4.703e-02, -3.527e-02, 9.112e-02, 5.291e-02) * s[0][2][0];
	r0 += V4(1.528e-01, 1.234e-01, 8.230e-02, -1.911e-01) * s[1][0][0];
	r1 += V4(2.939e-02, -2.057e-02, 4.997e-02, -1.764e-02) * s[1][0][0];
	r0 += V4(1.734e-01, 1.234e-01, 2.880e-01, -1.146e-01) * s[1][1][0];
	r1 += V4(-3.027e-01, -2.057e-02, -1.646e-01, 2.969e-01) * s[1][1][0];
	r0 += V4(-2.645e-02, -2.616e-01, -5.291e-02, -1.528e-01) * s[1][2][0];
	r1 += V4(-5.879e-03, -1.969e-01, 3.527e-01, -1.764e-02) * s[1][2][0];
	r0 += V4(1.764e-02, -5.291e-02, -2.939e-02, 1.734e-01) * s[2][0][0];
	r1 += V4(3.233e-02, 1.440e-01, -2.057e-02, 1.470e-02) * s[2][0][0];
	r0 += V4(-4.409e-02, -5.291e-02, 1.793e-01, -3.939e-01) * s[2][1][0];
	r1 += V4(3.233e-02, -2.204e-01, 4.115e-02, -1.969e-01) * s[2][1][0];
	r0 += V4(1.176e-02, 1.440e-01, -5.879e-02, 1.205e-01) * s[2][2][0];
	r1 += V4(3.821e-02, 1.969e-01, 1.470e-02, .0) * s[2][2][0];
	r0 += V4(-2.098e-02, 3.373e-03, -2.948e-02, 1.335e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(2.607e-01, -1.306e-03, -6.971e-03, 5.558e-04);
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-8x8C-TEST-conv1
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
	r0 = D(r0, s[0][0][0], 0xFCFFF102, 0xCA01110A, 0xF5F7F5F6, 0xFB040105);
	r1 = D(r1, s[0][0][0], 0x0BFAF7F5, 0x12FEF2FA, 0x12FBFFFA, 0x021FFA02);
	r0 = D(r0, s[0][0][1], 0x220C02FE, 0xE40A100A, 0xEEFB0404, 0xEF07E114);
	r1 = D(r1, s[0][0][1], 0x0010FAEF, 0xD2FC060F, 0xFBEAF1FA, 0x10DE002A);
	r0 = D(r0, s[0][0][2], 0x04FC11F9, 0xF60E21F2, 0x0B090BFF, 0xECF101F7);
	r1 = D(r1, s[0][0][2], 0xFC02EFF6, 0xF9F61115, 0xEAFC0717, 0xF0FAFE06);
	r0 = D(r0, s[0][1][0], 0xFCE9F104, 0x16270AFA, 0x04F6F0FC, 0xFF1C0BFE);
	r1 = D(r1, s[0][1][0], 0x0EF7F9FE, 0x0209EC06, 0x09C9FC02, 0x0E1A16F1);
	r0 = D(r0, s[0][1][1], 0x3427E5EC, 0x37EBEBFA, 0xEB0E0914, 0xD7EAF0FB);
	r1 = D(r1, s[0][1][1], 0xDA400AFC, 0x0106E607, 0xE7FAEC07, 0x11FCFCFE);
	r0 = D(r0, s[0][1][2], 0x0E0F2600, 0x160EF0FF, 0x0111FE0B, 0xD2FF0AF7);
	r1 = D(r1, s[0][1][2], 0xF20C1B0E, 0xF7200F00, 0xF7FC160E, 0x1FF4F2E7);
	r0 = D(r0, s[0][2][0], 0xE9FBFF07, 0xF007FAFB, 0xF510F400, 0xFA050709);
	r1 = D(r1, s[0][2][0], 0x17F907FC, 0xFBE20E06, 0xFF0BE5FE, 0x02FC010A);
	r0 = D(r0, s[0][2][1], 0xC6250B00, 0x15FB0EFA, 0x00FA0509, 0x07170EFC);
	r1 = D(r1, s[0][2][1], 0xD10F02F5, 0x01F102F4, 0xF90917F0, 0xD12B041B);
	r0 = D(r0, s[0][2][2], 0xE01705EF, 0xE9FA0006, 0xF7E412F7, 0x020100F1);
	r1 = D(r1, s[0][2][2], 0xFEF409FB, 0x0E0BFA05, 0x11091610, 0x161B07F6);
	r0 = D(r0, s[1][0][0], 0x17FF0EFE, 0x1E0F2AB5, 0xFB1E0512, 0xFBFEDC0C);
	r1 = D(r1, s[1][0][0], 0xEEFB06F1, 0x02FEEE29, 0xFA000CF9, 0x14E1E4FF);
	r0 = D(r0, s[1][0][1], 0xFC06C91E, 0x10090787, 0x0AFAE100, 0x0CFC15DB);
	r1 = D(r1, s[1][0][1], 0x04F2E9EC, 0x09FE00FE, 0x0900FBCA, 0xDF1509F7);
	r0 = D(r0, s[1][0][2], 0xFEF1D030, 0x02FC0A0E, 0x02F401FC, 0x0900F1FE);
	r1 = D(r1, s[1][0][2], 0x0EF4EC2E, 0x12F7E40C, 0xEBF120EE, 0x09F70AD1);
	r0 = D(r0, s[1][1][0], 0x07E90B30, 0xFBFFE60B, 0xFEF616DB, 0xFB020C1A);
	r1 = D(r1, s[1][1][0], 0x02F71BE4, 0xFA0EFB06, 0xF9F5E610, 0xF5E5C729);
	r0 = D(r0, s[1][1][1], 0x02260B32, 0x0024001C, 0x1CF2D6A1, 0xEB0732DB);
	r1 = D(r1, s[1][1][1], 0x10F653C4, 0xFFEF2006, 0x22CCF7DB, 0xF01F434B);
	r0 = D(r0, s[1][1][2], 0x060F0E7F, 0x0B121B5B, 0x0AC1D9FE, 0x0B00CBF6);
	r1 = D(r1, s[1][1][2], 0x0E020F20, 0x27E5EE99, 0x12FC19F9, 0xF11A25EC);
	r0 = D(r0, s[1][2][0], 0x090C1EF7, 0x0B070EFC, 0x0BF41AFA, 0xFAFB0CE9);
	r1 = D(r1, s[1][2][0], 0x04F621F1, 0x050CDC17, 0xFEEB20EA, 0xFEFF0A07);
	r0 = D(r0, s[1][2][1], 0xFC3CE504, 0xF90E25C7, 0x0726FAF5, 0xF011EAFB);
	r1 = D(r1, s[1][2][1], 0x1A11FAEE, 0xFE1AC974, 0x040F002C, 0x0B05E0BA);
	r0 = D(r0, s[1][2][2], 0x020012C0, 0x12E62681, 0xF0F1F20B, 0xEF00FFCA);
	r1 = D(r1, s[1][2][2], 0x10160B4E, 0x09012BD6, 0xF2FBE5B9, 0xFEECE741);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xDAF5DAF7, 0x11F617F2, 0xF1F5FFF6, 0x06FBEA0B);
	r1 = D(r1, s[0][0][0], 0xE4040B10, 0x1200E90C, 0x15E9F90A, 0x1FF5CAF2);
	r0 = D(r0, s[0][0][1], 0x02FEFA02, 0x0F1E1C15, 0x010FEA00, 0xC40702F1);
	r1 = D(r1, s[0][0][1], 0xDC0F0115, 0xEE02EEF6, 0x39140412, 0xF0FC22EF);
	r0 = D(r0, s[0][0][2], 0xE5FAFAFF, 0xC0040007, 0x0901E712, 0xD5E90112);
	r1 = D(r1, s[0][0][2], 0xE6FF140B, 0x0FEEF2F2, 0x1EFF1B10, 0x30F5FCFE);
	r0 = D(r0, s[0][1][0], 0xD0FF2202, 0x01DF0BEE, 0xF7FF0AFE, 0xDE02DA04);
	r1 = D(r1, s[0][1][0], 0xD0040011, 0x0415F51C, 0xD90AE705, 0xFFE4E4EF);
	r0 = D(r0, s[0][1][1], 0xAC11C02A, 0xB60F0F25, 0x0110FA12, 0xF110EADE);
	r1 = D(r1, s[0][1][1], 0xE90EC906, 0x290A1FDF, 0x34FB10E4, 0xB60A210F);
	r0 = D(r0, s[0][1][2], 0x1AF517E2, 0x2A020FEC, 0x1CFAEF0A, 0x16EEF7E7);
	r1 = D(r1, s[0][1][2], 0x0006190A, 0x311AFCEE, 0x11F419FC, 0x1C010A06);
	r0 = D(r0, s[0][2][0], 0x0E00070A, 0xF9F414EE, 0xE5F0020A, 0xFCF11005);
	r1 = D(r1, s[0][2][0], 0x2901FC01, 0x120AF1FB, 0x12E6FEF7, 0x1F0002FA);
	r0 = D(r0, s[0][2][1], 0xC9FEF10F, 0xFE06F519, 0x0202E1E9, 0x2406F5EB);
	r1 = D(r1, s[0][2][1], 0x0A0A3EFA, 0xE0F701EB, 0xDBF9EF10, 0x100610EA);
	r0 = D(r0, s[0][2][2], 0xFF1412FE, 0xEAF5262B, 0x05D5E2FE, 0xE712FA04);
	r1 = D(r1, s[0][2][2], 0xDCE9F710, 0xE509FA40, 0xF507DC02, 0xE90FDAFB);
	r0 = D(r0, s[1][0][0], 0x00F706FB, 0x157FF702, 0xFCE2FA09, 0x0CA015F1);
	r1 = D(r1, s[1][0][0], 0x10AFFFE5, 0xF5D9F7FA, 0xF905F411, 0xF919FF27);
	r0 = D(r0, s[1][0][1], 0x0EFBF5EE, 0x06F701EC, 0xEBDEF2F6, 0xE9060011);
	r1 = D(r1, s[1][0][1], 0x101405E1, 0x14210702, 0x21C009F6, 0xF019FC1F);
	r0 = D(r0, s[1][0][2], 0x112F0AF5, 0xE4E6F114, 0x000500DE, 0xF2E100FA);
	r1 = D(r1, s[1][0][2], 0xE9F5FFEB, 0x021BFA1C, 0xE627F109, 0xFA0E0E1C);
	r0 = D(r0, s[1][1][0], 0x016100F9, 0xF974FC1E, 0x15810BEB, 0xEF81FECF);
	r1 = D(r1, s[1][1][0], 0xEFE5FFFA, 0xFA920601, 0x2032F6E5, 0xF7F1EE26);
	r0 = D(r0, s[1][1][1], 0xF61BFE1A, 0x1BE902EB, 0xFFB2FA0B, 0x1BAAF9E7);
	r1 = D(r1, s[1][1][1], 0xF13206F9, 0xF67F0426, 0xD6EF2632, 0x37810FBB);
	r0 = D(r0, s[1][1][2], 0xECE2F20A, 0xEC2AF920, 0xFCD10617, 0x05F701FF);
	r1 = D(r1, s[1][1][2], 0x02F0FE05, 0xFF011A20, 0x09E1EFDE, 0xF5F704E9);
	r0 = D(r0, s[1][2][0], 0xF5F10010, 0xFC3BF50B, 0xFFA9FA06, 0x0192F5F1);
	r1 = D(r1, s[1][2][0], 0xFCBC01F9, 0x06020507, 0x0925F902, 0x10D5F114);
	r0 = D(r0, s[1][2][1], 0xFEB4D51C, 0xF24C1010, 0xF4B212F9, 0xF79C0BDF);
	r1 = D(r1, s[1][2][1], 0xF43FF104, 0x0459F415, 0x0FD5112A, 0xE20715FB);
	r0 = D(r0, s[1][2][2], 0x0FD70E0B, 0xF219FEFB, 0x05C1F501, 0x07EFFAF4);
	r1 = D(r1, s[1][2][2], 0xFE02020B, 0xFE14F415, 0x09CA0AF2, 0x05D4E90A);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-9.798e-02, -8.632e-02, 4.196e-02, 2.280e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-9.590e-02, -1.608e-01, -2.406e-02, 7.740e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv2
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
	r0 = D(r0, s[0][0][0], 0xED01FFF0, 0x03E5F11E, 0xF6CD15F2, 0x081E0803);
	r1 = D(r1, s[0][0][0], 0xF911F8E3, 0xFAFBF607, 0xFA0E08F2, 0xFEFB0507);
	r0 = D(r0, s[0][0][1], 0xF402FC0E, 0x130108EC, 0xEF02F013, 0x03090609);
	r1 = D(r1, s[0][0][1], 0xF801F806, 0x050812FD, 0x0507FF12, 0xEF01F60B);
	r0 = D(r0, s[0][0][2], 0x10FE070A, 0xF3F2011F, 0x0DF10C03, 0xF919F903);
	r1 = D(r1, s[0][0][2], 0xFAFDFFE1, 0xF600F601, 0x0AF90004, 0xF80501F9);
	r0 = D(r0, s[0][1][0], 0x0D050405, 0xF3E408DA, 0xFBE00D1A, 0xF72C07F0);
	r1 = D(r1, s[0][1][0], 0x0104F7D7, 0x05ECEBF9, 0xF4F2E7F2, 0xF920010C);
	r0 = D(r0, s[0][1][1], 0xF819E00F, 0xEE0213EF, 0x0C07E5FC, 0x0509D8F4);
	r1 = D(r1, s[0][1][1], 0x0110F412, 0xF9F40E10, 0xE9010BFD, 0xFAF30337);
	r0 = D(r0, s[0][1][2], 0xE0F90914, 0xFB19E7E8, 0x2312EAEE, 0xF4ED0103);
	r1 = D(r1, s[0][1][2], 0x0AF8FF00, 0xF3FCF011, 0x00FF0509, 0xFEF0FFFF);
	r0 = D(r0, s[0][2][0], 0x120913FB, 0x03FB0CF6, 0xF9FB0208, 0xFEF410F7);
	r1 = D(r1, s[0][2][0], 0x05FE1011, 0xF2050FFA, 0x07F6FD0D, 0x01FD0304);
	r0 = D(r0, s[0][2][1], 0x151B0BF1, 0x1306D4F2, 0xFB08F007, 0x0EE409F7);
	r1 = D(r1, s[0][2][1], 0xF9FD05F6, 0x000D1203, 0xF80E0010, 0xF4020301);
	r0 = D(r0, s[0][2][2], 0x0004EAF8, 0x03EC05F9, 0xF20E0500, 0x07021412);
	r1 = D(r1, s[0][2][2], 0x05070104, 0xEA030316, 0x0EF90EFE, 0xF605F009);
	r0 = D(r0, s[1][0][0], 0xF2F90312, 0xD81720EB, 0xEDF9F4FD, 0xFD17EEFD);
	r1 = D(r1, s[1][0][0], 0x1B03F915, 0xF5030A04, 0xFEDFFB12, 0x0F01070D);
	r0 = D(r0, s[1][0][1], 0x16FDF208, 0xEFF5F5FE, 0x41F621FA, 0x1BFDF70C);
	r1 = D(r1, s[1][0][1], 0x0516F607, 0x1005DF09, 0xF903100C, 0x1FFF1B03);
	r0 = D(r0, s[1][0][2], 0xDFE4DCED, 0x26140CEA, 0xF90CFB19, 0x17EDF9FA);
	r1 = D(r1, s[1][0][2], 0xDD0CF405, 0xFBF80AFD, 0xFF0EEFF8, 0xFFFFF113);
	r0 = D(r0, s[1][1][0], 0xE65D03F8, 0x17FCFF14, 0x11F00CEE, 0x06FBF706);
	r1 = D(r1, s[1][1][0], 0xE416260B, 0x151235FC, 0x190A1612, 0x26FF1205);
	r0 = D(r0, s[1][1][1], 0xF50D1603, 0x24150A26, 0xFC124E11, 0xC7FC2A05);
	r1 = D(r1, s[1][1][1], 0xD60FDDF3, 0x0A17EB08, 0x0DFC01E8, 0x461BE5C8);
	r0 = D(r0, s[1][1][2], 0x5D27EF14, 0xE9F00411, 0xF6FC1CFE, 0x0CFBECF7);
	r1 = D(r1, s[1][1][2], 0x0B14F3F4, 0x30EF05EA, 0xED03F6F9, 0x0E080E12);
	r0 = D(r0, s[1][2][0], 0xE0DBDF06, 0x01E717EF, 0xEC0305F7, 0x061CEA0B);
	r1 = D(r1, s[1][2][0], 0xFB05F3F4, 0x00E4060A, 0xEE0D03FC, 0x14F404F9);
	r0 = D(r0, s[1][2][1], 0xEBF214F8, 0xDAF03010, 0xFEF0F905, 0xFBEEC307);
	r1 = D(r1, s[1][2][1], 0x04D82301, 0x06F70BF5, 0x0AF8E9F5, 0x1210F60B);
	r0 = D(r0, s[1][2][2], 0xFAFC1307, 0xC9F515FB, 0x17FD12FB, 0x1600D2F7);
	r1 = D(r1, s[1][2][2], 0x04EF23FE, 0x2501FFEE, 0xE101D4FB, 0x12030BFE);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x09F0EC10, 0xEB1209F5, 0x2610FD0A, 0x13FB040A);
	r1 = D(r1, s[0][0][0], 0xFEFC08FB, 0x0BFFF8F9, 0x11F1E4FE, 0x01F6FAF6);
	r0 = D(r0, s[0][0][1], 0x1B26E710, 0x322EF00A, 0xF8E108FF, 0x041304FD);
	r1 = D(r1, s[0][0][1], 0xF5F4F008, 0xF8FE190F, 0xDDECFFFF, 0x00F3FCF1);
	r0 = D(r0, s[0][0][2], 0xFDE2E3F9, 0x2621FEF4, 0xD20D0708, 0x0112F5FC);
	r1 = D(r1, s[0][0][2], 0xB8A80701, 0x071DF2F9, 0xEC030003, 0x0714FDFA);
	r0 = D(r0, s[0][1][0], 0xFB0A0EED, 0x1912EEFA, 0x0602030C, 0x09F6160E);
	r1 = D(r1, s[0][1][0], 0x06050F0D, 0xF90BF9EE, 0x0113E9FB, 0x01ECFD0F);
	r0 = D(r0, s[0][1][1], 0xCB1F0E15, 0xFF44FAFE, 0xD6B8F71D, 0xD6481DFE);
	r1 = D(r1, s[0][1][1], 0x03D8EAFF, 0x04DD0808, 0x10C1DDF9, 0x11DFF9FB);
	r0 = D(r0, s[0][1][2], 0x0814FCFB, 0xF90C1F03, 0xD01603F7, 0x10C5F4E7);
	r1 = D(r1, s[0][1][2], 0xE3140C16, 0x1FF00D0E, 0xF707FDEB, 0x05F60606);
	r0 = D(r0, s[0][2][0], 0xFAF91708, 0x01FC031A, 0xF7F0EF07, 0xF701FBF8);
	r1 = D(r1, s[0][2][0], 0xFC0A0111, 0x08FF1409, 0xFBFBF407, 0x031102FB);
	r0 = D(r0, s[0][2][1], 0x16FD1407, 0xEAE910F2, 0xEAF9FCF4, 0x07ECF6DB);
	r1 = D(r1, s[0][2][1], 0x0A18F814, 0x0819111D, 0x02F8FA04, 0xEC05F9FD);
	r0 = D(r0, s[0][2][2], 0x06EE04FB, 0x090EF80E, 0x0ADD0E03, 0x1C20E9DC);
	r1 = D(r1, s[0][2][2], 0x022CFB0D, 0x0E2314EB, 0xF810F415, 0xF4F0F8F8);
	r0 = D(r0, s[1][0][0], 0xFD100EF3, 0x100903FC, 0x10FFFBE9, 0xF4F9F4EA);
	r1 = D(r1, s[1][0][0], 0xFD0AF216, 0x07040511, 0x080B170F, 0x01F7ECF5);
	r0 = D(r0, s[1][0][1], 0xD6FF0F0A, 0xFC0C1DCD, 0x2108FB0E, 0x12F4FB1F);
	r1 = D(r1, s[1][0][1], 0xD9F4052E, 0x0106F6F8, 0x13ED0327, 0x0805FDF1);
	r0 = D(r0, s[1][0][2], 0xDF0A2EFC, 0x0BF80A10, 0xFF05EEE9, 0x050A0DF4);
	r1 = D(r1, s[1][0][2], 0xEF10EFF9, 0x02FAFBF8, 0xF10010E5, 0x05FB03FB);
	r0 = D(r0, s[1][1][0], 0x0CF2EC18, 0xE4170AEE, 0x080EF9FB, 0x05F4EAFD);
	r1 = D(r1, s[1][1][0], 0x02030817, 0x0502ED07, 0x080C1F08, 0x0A16040C);
	r0 = D(r0, s[1][1][1], 0x4CE00512, 0xEAE706DF, 0x180017FD, 0x17EBE4FB);
	r1 = D(r1, s[1][1][1], 0xE30A2AFB, 0xF201E5F6, 0xECFA3712, 0xF00E3203);
	r0 = D(r0, s[1][1][2], 0x0ED2F70A, 0x0FECD61A, 0xEE03FC0F, 0xD31F19E8);
	r1 = D(r1, s[1][1][2], 0xE6E2F8DD, 0x05F814FA, 0xF507FDFC, 0x07F6F602);
	r0 = D(r0, s[1][2][0], 0xF902EA01, 0x071908F4, 0x180A12F1, 0x07070306);
	r1 = D(r1, s[1][2][0], 0x05FFECFB, 0xFC0DF006, 0xFD121202, 0xFFF7FEF0);
	r0 = D(r0, s[1][2][1], 0xE71DF2F9, 0xF2E7D415, 0x16F607FD, 0xF2080B23);
	r1 = D(r1, s[1][2][1], 0x11F2EE09, 0x0911FEFD, 0x01F71AFD, 0xFDDF14DD);
	r0 = D(r0, s[1][2][2], 0xF902F700, 0xF221FD1D, 0xF505EE0C, 0xE30E210E);
	r1 = D(r1, s[1][2][2], 0xFF0814EC, 0x0EF0FAD0, 0x01FD0D08, 0x17F0FF10);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(8.529e-03, -2.278e-02, -1.587e-02, 3.381e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-7.428e-03, -1.934e-01, 1.236e-01, -9.655e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv3
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
	r0 = D(r0, s[0][0][0], 0x0E0419FF, 0xF5FB03FC, 0xEE0D00F5, 0x1BFFF1F3);
	r1 = D(r1, s[0][0][0], 0xF70909FD, 0x05E7EC05, 0x1FF20005, 0x081D16FB);
	r0 = D(r0, s[0][0][1], 0xEEFD0804, 0x0A0400F3, 0xF3F511FB, 0xFC04F118);
	r1 = D(r1, s[0][0][1], 0xDC0EDEF8, 0x20F1E009, 0x240F2AF2, 0xF5241CFD);
	r0 = D(r0, s[0][0][2], 0x0008FD01, 0xFF050406, 0x04111811, 0x090006FD);
	r1 = D(r1, s[0][0][2], 0xF71C1811, 0x12E3E30B, 0xFCE700F1, 0xFF04FC0F);
	r0 = D(r0, s[0][1][0], 0x1CF5FDE4, 0xFFF600F6, 0xE1E0FBD9, 0x08060606);
	r1 = D(r1, s[0][1][0], 0xE5EFF5FB, 0x182724F1, 0x1B190001, 0xFC1C1FE3);
	r0 = D(r0, s[0][1][1], 0xEACC09CB, 0x0BFCCBF7, 0x0011EED0, 0xEDE4DA0A);
	r1 = D(r1, s[0][1][1], 0xD9F8080B, 0xF6E808F5, 0x33FA00F5, 0x29041217);
	r0 = D(r0, s[0][1][2], 0x13F7F10B, 0xDFFC17F8, 0x12FD04FF, 0x0803FCFC);
	r1 = D(r1, s[0][1][2], 0x00190920, 0x051CEAEA, 0xF50141ED, 0x0AFBF5FD);
	r0 = D(r0, s[0][2][0], 0x19160B12, 0xF10BFA04, 0xF8170DE4, 0x1DF60B09);
	r1 = D(r1, s[0][2][0], 0x0401FBF6, 0xFCF5FFF6, 0x09FD06FC, 0xF60501E0);
	r0 = D(r0, s[0][2][1], 0x0009F616, 0x05090100, 0xFCEA0ADF, 0xEF0911D0);
	r1 = D(r1, s[0][2][1], 0xF6FBF81B, 0xFAE90EDE, 0x11F6FDFA, 0xE024FFD6);
	r0 = D(r0, s[0][2][2], 0x0D27F200, 0x0411EE08, 0xFAE408F5, 0x0809E40F);
	r1 = D(r1, s[0][2][2], 0x01EFE006, 0x01140EFD, 0x09F222FC, 0x0B1106E5);
	r0 = D(r0, s[1][0][0], 0x0F08FAF1, 0xF804FD00, 0x04F80417, 0xFBFA0A14);
	r1 = D(r1, s[1][0][0], 0x0109F50A, 0x0A0D09FD, 0x03FA03EF, 0xFBFBED0D);
	r0 = D(r0, s[1][0][1], 0xE4002BFC, 0xF1FF0906, 0x0BE801F5, 0x09F812E3);
	r1 = D(r1, s[1][0][1], 0x2916170A, 0x11F30AF7, 0x1205DB16, 0xFDFAFD00);
	r0 = D(r0, s[1][0][2], 0xF1F7EC00, 0xF8FBFAF2, 0xFDEF0E09, 0x03FDF103);
	r1 = D(r1, s[1][0][2], 0xFCF8F5ED, 0xF7FF0E03, 0xFA0E01F7, 0xFBFFF8FF);
	r0 = D(r0, s[1][1][0], 0x09F62A11, 0xEF0BFD04, 0xEE1713EA, 0x11F8EAFD);
	r1 = D(r1, s[1][1][0], 0x090EFA06, 0x16E5E719, 0xFBEE05D1, 0xF7080108);
	r0 = D(r0, s[1][1][1], 0x1CD0D7FF, 0xD30604F1, 0xE1190F1D, 0x0A0A2AEF);
	r1 = D(r1, s[1][1][1], 0x30080F03, 0x25E5050A, 0x0E010AEF, 0xE10921DA);
	r0 = D(r0, s[1][1][2], 0xF717FDEC, 0x080FE4E8, 0x01F6F5F5, 0xFFF3ED08);
	r1 = D(r1, s[1][1][2], 0xFBF2FCE9, 0xFADAF505, 0x19060E04, 0x06030EEA);
	r0 = D(r0, s[1][2][0], 0xF7FBF713, 0x0BF509FA, 0xF6EDFFE0, 0xEC09EC00);
	r1 = D(r1, s[1][2][0], 0xFF060503, 0xFC13080E, 0xFF0E0603, 0x031B03FA);
	r0 = D(r0, s[1][2][1], 0xF112F2F1, 0x01EFFCF1, 0x08FA000A, 0x0BFAFD11);
	r1 = D(r1, s[1][2][1], 0xFBF1FAFF, 0x19160F2F, 0x0BEF0BFF, 0x17FC2006);
	r0 = D(r0, s[1][2][2], 0x11EC0FFA, 0x08F511EE, 0xFD00FAEF, 0xFFC8EFE3);
	r1 = D(r1, s[1][2][2], 0x08FC0018, 0x0108F601, 0x04FCFAF2, 0xFDFD1D01);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xDA04E501, 0xEC05C9FD, 0xE5050D09, 0x1BFBF509);
	r1 = D(r1, s[0][0][0], 0x0B0EFCF8, 0x0B00FDFC, 0xEDFF00FA, 0xDAFB1720);
	r0 = D(r0, s[0][0][1], 0xABEF16DA, 0xF817E80D, 0x2AFCFF04, 0x1FEF04FD);
	r1 = D(r1, s[0][0][1], 0x37FC17FC, 0xD0F8FFE4, 0xFA0BD925, 0xE0F71BFC);
	r0 = D(r0, s[0][0][2], 0xAB03EAF7, 0xE0FBE9FA, 0x30F111E8, 0xF2FA0A03);
	r1 = D(r1, s[0][0][2], 0x11131DDC, 0xFCF6F20D, 0x0100DA03, 0xE90501EF);
	r0 = D(r0, s[0][1][0], 0xFCFD26F7, 0x1605E1FD, 0xE425E5EA, 0x5911DCF6);
	r1 = D(r1, s[0][1][0], 0x210505FC, 0x0EFAE417, 0xE5F5FCFD, 0xE103E712);
	r0 = D(r0, s[0][1][1], 0xD60A1D14, 0x420BD5D3, 0x4EE9E5E0, 0x7F122755);
	r1 = D(r1, s[0][1][1], 0x7D0133FD, 0x29FD0B2F, 0xB9DBE3EC, 0xACDBF6E5);
	r0 = D(r0, s[0][1][2], 0xDBFDE0F6, 0x1F18E93A, 0x35FB290A, 0x17F8FB14);
	r1 = D(r1, s[0][1][2], 0xD5E9DAE5, 0xB8E1E80F, 0x4113F814, 0xB901FA05);
	r0 = D(r0, s[0][2][0], 0x13FBEA04, 0xF5FDF604, 0xFFFBC900, 0x1203FB17);
	r1 = D(r1, s[0][2][0], 0x1106ECFF, 0xEE05FFF8, 0xFBF60D19, 0x2511F5ED);
	r0 = D(r0, s[0][2][1], 0x04040616, 0xE4FCF104, 0xCC0BEAFC, 0x42FF14F6);
	r1 = D(r1, s[0][2][1], 0x03F80817, 0x32160EFB, 0x0E0008EC, 0x34171FE9);
	r0 = D(r0, s[0][2][2], 0xF30B1800, 0xE3270412, 0x0A050AF8, 0x0B0A1621);
	r1 = D(r1, s[0][2][2], 0xFAF8F6FC, 0xF60B00F7, 0x140D1800, 0x30F804FD);
	r0 = D(r0, s[1][0][0], 0xFD0304F5, 0x01F801F7, 0x0BFBFA06, 0xFA0FFA08);
	r1 = D(r1, s[1][0][0], 0xFBFC0900, 0x01F81403, 0xFD00F10E, 0x12FD04E8);
	r0 = D(r0, s[1][0][1], 0xFA0E08FA, 0x01F7ECFA, 0x00080A09, 0x1311FB0E);
	r1 = D(r1, s[1][0][1], 0x04F6EAEE, 0xF520FC1D, 0xFB0506ED, 0xFBFAF5FC);
	r0 = D(r0, s[1][0][2], 0x0EF701E8, 0x0BEDFA01, 0x011B03FF, 0x060106FF);
	r1 = D(r1, s[1][0][2], 0x04F6EFFF, 0x0D0503FD, 0xECEF0806, 0x0DFFFD08);
	r0 = D(r0, s[1][1][0], 0xF1F61718, 0xF5F3F200, 0x0DEDFBFB, 0xFCE703FF);
	r1 = D(r1, s[1][1][0], 0xE8FBFD0B, 0xF6FD03EE, 0x08110D0A, 0xF503EEE1);
	r0 = D(r0, s[1][1][1], 0xFC01F5F7, 0x06F703FF, 0xFA09FDFA, 0xEEEEFF04);
	r1 = D(r1, s[1][1][1], 0xF80F16DF, 0xFDECEAF7, 0x13F10612, 0x09381B16);
	r0 = D(r0, s[1][1][2], 0x011BFAE3, 0x0AF1EDFD, 0x0B08F301, 0x1104FC04);
	r1 = D(r1, s[1][1][2], 0x201306F7, 0x13170105, 0xF2FAF8FC, 0x0801FDF8);
	r0 = D(r0, s[1][2][0], 0x03FFE4EA, 0xFBFF090B, 0xFCF5FB18, 0xFC0B0605);
	r1 = D(r1, s[1][2][0], 0x03EF06FD, 0xF7040901, 0xFB1103EE, 0x05F10B11);
	r0 = D(r0, s[1][2][1], 0x0B030017, 0xFCEDF801, 0x06E90BFB, 0xFAFDFBF8);
	r1 = D(r1, s[1][2][1], 0xF505F6F8, 0xF1EC05F1, 0x000A0EF6, 0xF2F2FF00);
	r0 = D(r0, s[1][2][2], 0xFAE3FDEE, 0xFCD305F5, 0xF10104FD, 0x06F7F50A);
	r1 = D(r1, s[1][2][2], 0x0E0408F8, 0xEFF50606, 0xFAF6F6FD, 0xF70A0DFC);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(1.797e-02, 1.435e-01, 1.780e-02, 9.529e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(6.012e-03, 1.069e-02, 6.754e-02, -2.272e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv4
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
	r0 = D(r0, s[0][0][0], 0xFEE8F705, 0x0B0CFA04, 0xFA23FFF0, 0x12060F0E);
	r1 = D(r1, s[0][0][0], 0xFAE8E1EC, 0x14FE0307, 0xE1FF0EF2, 0x1DFC1B09);
	r0 = D(r0, s[0][0][1], 0x01F4FA09, 0x0BEE0C04, 0xFD1705E3, 0xF9FFFE18);
	r1 = D(r1, s[0][0][1], 0x1D040BED, 0xEF14F025, 0xF7F8F8E2, 0x08E51010);
	r0 = D(r0, s[0][0][2], 0xFCFF01FF, 0xF3FCF50C, 0x02070EE8, 0x1214F501);
	r1 = D(r1, s[0][0][2], 0xE8FF14EF, 0x06F908FB, 0xFE070FFF, 0x090CF60E);
	r0 = D(r0, s[0][1][0], 0xF0E51918, 0xF9FB2214, 0xF53BFDE8, 0xEC0C03E6);
	r1 = D(r1, s[0][1][0], 0x1ED41F27, 0x03F4FCEF, 0xF926F3E9, 0xFD0EE920);
	r0 = D(r0, s[0][1][1], 0xBFE007FF, 0x18E40E23, 0x1B09DDED, 0xFEE71702);
	r1 = D(r1, s[0][1][1], 0x0C0AD21C, 0xFEE503E9, 0x071DE9F5, 0xF7DA0508);
	r0 = D(r0, s[0][1][2], 0xE311FC0B, 0x04F5F801, 0x03270DEF, 0x041109E7);
	r1 = D(r1, s[0][1][2], 0x0D250AFF, 0xFEF8F207, 0xF80B08DA, 0x1CF9F702);
	r0 = D(r0, s[0][2][0], 0xFFE40211, 0xFFF3030E, 0x1910FCE1, 0x09F3DEF3);
	r1 = D(r1, s[0][2][0], 0x01EE0714, 0x05020200, 0xF50103EE, 0xFBF304FB);
	r0 = D(r0, s[0][2][1], 0xFBDBEF0D, 0xFFF4F10F, 0x1E2004DB, 0xF9EC01D4);
	r1 = D(r1, s[0][2][1], 0x0CEAFC14, 0x01EF06EC, 0xF219F6DE, 0xFB06FE1E);
	r0 = D(r0, s[0][2][2], 0xFAE8FE0F, 0x0009F307, 0x0F0D09E1, 0x0A11FF14);
	r1 = D(r1, s[0][2][2], 0x08E80204, 0x0F050601, 0x0B0C0CE0, 0xFFF3F214);
	r0 = D(r0, s[1][0][0], 0x03EEF009, 0xFBFC16F9, 0x0E04F8ED, 0xECF4E8F1);
	r1 = D(r1, s[1][0][0], 0x25EDFF0E, 0x16FCF505, 0x1201EFFF, 0x10FCF1E1);
	r0 = D(r0, s[1][0][1], 0x18000109, 0x070D1104, 0xF2030E06, 0x0900FAE9);
	r1 = D(r1, s[1][0][1], 0x03F4EF27, 0x03F60EE7, 0x090B09F5, 0xF402F6FD);
	r0 = D(r0, s[1][0][2], 0x18F9F408, 0xEEF418F7, 0xFBFDF9FE, 0x000006F2);
	r1 = D(r1, s[1][0][2], 0x2BFAE21C, 0x0413FB07, 0xF101E9EA, 0x0B0201FC);
	r0 = D(r0, s[1][1][0], 0x19F40904, 0x16F113FC, 0x0606E5FB, 0x0AF50CFD);
	r1 = D(r1, s[1][1][0], 0x0C0C090C, 0x00010116, 0x08021BF4, 0x18E90EEC);
	r0 = D(r0, s[1][1][1], 0x281C1803, 0xFA09170C, 0x0AFC1D12, 0x2302FCF8);
	r1 = D(r1, s[1][1][1], 0xFBEE3CE4, 0xEFF820FD, 0xF70820E3, 0xFA020B05);
	r0 = D(r0, s[1][1][2], 0x0DEA03F0, 0xFAF9120C, 0x0CFAFB08, 0x1CFCF70B);
	r1 = D(r1, s[1][1][2], 0x05E3FB08, 0x02F40FEA, 0xFDFA01F2, 0xFCFA0CFA);
	r0 = D(r0, s[1][2][0], 0x01F90208, 0xFEF710FC, 0xF92401FC, 0x05FD20FC);
	r1 = D(r1, s[1][2][0], 0x05F7E9FF, 0x0200F307, 0x00FE0903, 0x07FFFD0F);
	r0 = D(r0, s[1][2][1], 0xFFEA0DFD, 0x140212FC, 0x0E24FD0C, 0x1101020C);
	r1 = D(r1, s[1][2][1], 0x13060606, 0xFBFCEC06, 0x0606040C, 0x0BFA0509);
	r0 = D(r0, s[1][2][2], 0x0EF9FA03, 0xFE0411FD, 0xF6030406, 0x07F704ED);
	r1 = D(r1, s[1][2][2], 0x02FEF817, 0x0AFAEC07, 0xFCFDEFFE, 0xFF0D07F9);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0BFF03FA, 0xF9F8F5F8, 0xEAF80B06, 0x0E0AFA08);
	r1 = D(r1, s[0][0][0], 0xF8FC0CF9, 0xFE03F20F, 0xF3FF09F4, 0x0902F305);
	r0 = D(r0, s[0][0][1], 0x0CF9FAFC, 0xF3EFE603, 0xF8F804F1, 0xE7F1080E);
	r1 = D(r1, s[0][0][1], 0x2D0B01E1, 0xDCFF030D, 0xF608DD08, 0xF2EE1E0F);
	r0 = D(r0, s[0][0][2], 0xFFF5FC04, 0xFC11F1FD, 0xF3F4FBF7, 0xE9FF0601);
	r1 = D(r1, s[0][0][2], 0xFAE7F3F1, 0x21F40407, 0x0E0FFF06, 0x090EF8FB);
	r0 = D(r0, s[0][1][0], 0xEE011409, 0x02F4F9F6, 0x0E1004F1, 0x1304FC03);
	r1 = D(r1, s[0][1][0], 0xFFFFECE2, 0x0801FAF2, 0xFA0B2D1D, 0x050EEF18);
	r0 = D(r0, s[0][1][1], 0x20EEF7F2, 0x16D9EF0F, 0xF50B1EEA, 0x1BD4131D);
	r1 = D(r1, s[0][1][1], 0xCF001C0D, 0xD81BE4DD, 0x13102A16, 0x2012DBFF);
	r0 = D(r0, s[0][1][2], 0xFC13FEFF, 0x0808FAF7, 0xF2F90FFC, 0x070C03DE);
	r1 = D(r1, s[0][1][2], 0x0F020D06, 0xF501F4F4, 0x0DEF07F8, 0x12FAF70C);
	r0 = D(r0, s[0][2][0], 0x08F714F0, 0xFDF701FC, 0x02EC03D3, 0xFA0BFEF1);
	r1 = D(r1, s[0][2][0], 0x0B040706, 0x03070404, 0xEF14062E, 0xFD0EED11);
	r0 = D(r0, s[0][2][1], 0x06F411D9, 0xFD0C0103, 0x03DF0704, 0xF70906ED);
	r1 = D(r1, s[0][2][1], 0x0CFAFC09, 0x00030A05, 0x03F31212, 0xDFFBF002);
	r0 = D(r0, s[0][2][2], 0xFDF50A04, 0xFE090001, 0xFD0208F7, 0x01F90CF6);
	r1 = D(r1, s[0][2][2], 0x08F10608, 0x0700FA0A, 0x02F1F6FE, 0x0902F002);
	r0 = D(r0, s[1][0][0], 0x09170701, 0xFB0A030D, 0xEEF307F1, 0xE3F30904);
	r1 = D(r1, s[1][0][0], 0xFF0FFDF2, 0xECF60D01, 0x1E21FBF7, 0xEDE40816);
	r0 = D(r0, s[1][0][1], 0x1101F4FB, 0xF9140800, 0xFE030707, 0xFAFE21F3);
	r1 = D(r1, s[1][0][1], 0xE8E4E800, 0x1BEF02FA, 0x33240117, 0x0B0BF5E7);
	r0 = D(r0, s[1][0][2], 0x09020C01, 0x04EA04FD, 0x001C0D02, 0x06160900);
	r1 = D(r1, s[1][0][2], 0xFA0914F6, 0xFD08F70F, 0x09FEF400, 0xF2EE01F8);
	r0 = D(r0, s[1][1][0], 0x0314F3FA, 0x0310FF0D, 0x070520EB, 0xF1060BF8);
	r1 = D(r1, s[1][1][0], 0xE70E0E05, 0xDD040E02, 0x1212020F, 0xE7EFF203);
	r0 = D(r0, s[1][1][1], 0xD8FD0CFA, 0xEA10F3D5, 0xFE14F7FE, 0xDC5138DD);
	r1 = D(r1, s[1][1][1], 0x22F9E4E5, 0x01172607, 0x2502F749, 0xF2E8012B);
	r0 = D(r0, s[1][1][2], 0x18E31BFF, 0xF3E7080B, 0x0105FCF7, 0xF7071302);
	r1 = D(r1, s[1][1][2], 0xF00503F7, 0x2D090912, 0x0D07FB19, 0xF8060301);
	r0 = D(r0, s[1][2][0], 0x04090D06, 0xFD05FC01, 0xF91B1C0E, 0x0814FE01);
	r1 = D(r1, s[1][2][0], 0xFD020FEC, 0x03ED14E9, 0xFFE0F3FC, 0xDFF5E816);
	r0 = D(r0, s[1][2][1], 0x021D0913, 0x08F8E3F8, 0x0C2902FC, 0x0906FF0D);
	r1 = D(r1, s[1][2][1], 0xEAF813F9, 0xFC1A1AE6, 0xFA110C1D, 0x06ECF23B);
	r0 = D(r0, s[1][2][2], 0x0CF302F6, 0xF6F1F9F7, 0x050EFB09, 0x02EFFFEE);
	r1 = D(r1, s[1][2][2], 0x03F109F8, 0xF9E902FA, 0x061704FA, 0x02FA0E05);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(2.541e-02, -1.301e-01, 2.887e-02, 2.208e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-1.076e-02, -1.653e-02, -3.546e-02, -1.153e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv5
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
	r0 = D(r0, s[0][0][0], 0x03F12CF2, 0xEEFEF3FD, 0xF20B2508, 0xF0F8DC02);
	r1 = D(r1, s[0][0][0], 0x0C010F0C, 0xF9F00C04, 0x01FF180D, 0xF805DD06);
	r0 = D(r0, s[0][0][1], 0x05071C0B, 0x0FFC0EEE, 0x0AF50EFD, 0x001CF7F7);
	r1 = D(r1, s[0][0][1], 0xFD0CF411, 0x14E718ED, 0x18FD280C, 0x0011EEFF);
	r0 = D(r0, s[0][0][2], 0xFDFA0201, 0xF407FF13, 0xFF141308, 0xF1FDF504);
	r1 = D(r1, s[0][0][2], 0xFAF700FD, 0xFAFF1DFB, 0xFFE4F101, 0xFAFCE80A);
	r0 = D(r0, s[0][1][0], 0x02FD6BF4, 0xDF0B0B04, 0x0A0344FD, 0x29F43504);
	r1 = D(r1, s[0][1][0], 0x05055917, 0x0BF410F8, 0xF201FA00, 0xEA0BF808);
	r0 = D(r0, s[0][1][1], 0x060C4329, 0xDC0FE4F6, 0xFB0AFE23, 0x18F30310);
	r1 = D(r1, s[0][1][1], 0x03DFC62E, 0xEEF8BBDF, 0x030C17E4, 0x18ED2303);
	r0 = D(r0, s[0][1][2], 0x060A04FF, 0x07070CF7, 0xF8071301, 0x07FC0BE4);
	r1 = D(r1, s[0][1][2], 0xF61C0F01, 0xFFFD01FA, 0x09F9E80F, 0x09E8EDF4);
	r0 = D(r0, s[0][2][0], 0xFF011D01, 0x01F51FFA, 0x19F324FF, 0x170901EB);
	r1 = D(r1, s[0][2][0], 0x0AFDE503, 0x0CFF35E4, 0x04FB1BFB, 0x09010802);
	r0 = D(r0, s[0][2][1], 0x070A26F7, 0x070A031A, 0x090011EE, 0x02F816F1);
	r1 = D(r1, s[0][2][1], 0xEDF7040F, 0x14101803, 0x0405F102, 0x06F025FD);
	r0 = D(r0, s[0][2][2], 0xFD0022F9, 0x0208FEF6, 0x0C04F1F3, 0xF50FF10B);
	r1 = D(r1, s[0][2][2], 0xED04FAF6, 0x0600F1FD, 0xFD03F10C, 0x0204F607);
	r0 = D(r0, s[1][0][0], 0x04FFF8FD, 0xF708F8FD, 0x06FDF1FE, 0xFAF50AF4);
	r1 = D(r1, s[1][0][0], 0x10EF03FA, 0xF608FA04, 0x0601F80F, 0xEE080508);
	r0 = D(r0, s[1][0][1], 0xEFECF7FA, 0x03E4F811, 0xF0F10F01, 0x1108FA18);
	r1 = D(r1, s[1][0][1], 0x0E0EFBFB, 0xF4F2F818, 0xDCF7F7E8, 0xE9F4FA09);
	r0 = D(r0, s[1][0][2], 0xFF00FF02, 0xF9020AF7, 0xF9F0FBFD, 0x06F8FEF8);
	r1 = D(r1, s[1][0][2], 0xFFE10403, 0x060FF906, 0xF6180EF9, 0xFD010602);
	r0 = D(r0, s[1][1][0], 0x06FFFAF8, 0xF8F6F1FA, 0xEDE4F9FC, 0xF6200800);
	r1 = D(r1, s[1][1][0], 0x1300F6F8, 0x1DEF0A05, 0x01EAFFF4, 0x0F0801F6);
	r0 = D(r0, s[1][1][1], 0xFFF7FBAD, 0x19D225D2, 0x0DE605DA, 0xF320FD1C);
	r1 = D(r1, s[1][1][1], 0x081108F9, 0x18F70ADF, 0x13F60FF1, 0xCC1CDC43);
	r0 = D(r0, s[1][1][2], 0xF9F102FA, 0xF8F9F8F5, 0x0DF9F5EB, 0xF4090A08);
	r1 = D(r1, s[1][1][2], 0x0AF3F8F0, 0x130903EB, 0xEED40FFD, 0xEDF80618);
	r0 = D(r0, s[1][2][0], 0x04F80103, 0xFFF8F80C, 0xFD001501, 0x030F0606);
	r1 = D(r1, s[1][2][0], 0x15091B06, 0x1715F105, 0x0706F1FF, 0xF7FA0602);
	r0 = D(r0, s[1][2][1], 0x0CFAEDED, 0x01EF01F7, 0xFF06FA06, 0x06FEEE03);
	r1 = D(r1, s[1][2][1], 0xF4F0FF08, 0x0F01FDF4, 0x0FFC03F8, 0xED03E80A);
	r0 = D(r0, s[1][2][2], 0x0309F601, 0x00F4F6FB, 0xFFF8080A, 0x03F703F5);
	r1 = D(r1, s[1][2][2], 0x0CFDF601, 0xFAF6FD11, 0x0001FA01, 0xF9F30C00);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0005FD08, 0xF3FF1313, 0x06FD1006, 0x01FAEDE2);
	r1 = D(r1, s[0][0][0], 0xFDFCFAEA, 0xFEFF000C, 0x05060E1C, 0xF6060A14);
	r0 = D(r0, s[0][0][1], 0xFA0A0414, 0xF40E2021, 0x0706FAF6, 0xF9040E03);
	r1 = D(r1, s[0][0][1], 0xF6F9EFEF, 0xED030916, 0xF6F6F9EF, 0xFC081510);
	r0 = D(r0, s[0][0][2], 0x01F5FB04, 0xFAFFFC08, 0xF30105FD, 0xF3FF0CFB);
	r1 = D(r1, s[0][0][2], 0xF10304FF, 0xE701150D, 0xFDF3F8FD, 0x0503F5FA);
	r0 = D(r0, s[0][1][0], 0xF1040901, 0xF00318F2, 0xF5F0EB00, 0x0E0103D4);
	r1 = D(r1, s[0][1][0], 0x01F1FCEB, 0xDCF31305, 0xFAFD0C21, 0xF6FD0603);
	r0 = D(r0, s[0][1][1], 0x03F90200, 0x1F041611, 0xFD02E0C4, 0x2CF810E4);
	r1 = D(r1, s[0][1][1], 0xF3EFFCCE, 0xD3021E01, 0x0AF6012B, 0xE4F2F50E);
	r0 = D(r0, s[0][1][2], 0x00050716, 0xF8FB0A0F, 0xEE0002F0, 0xFF060109);
	r1 = D(r1, s[0][1][2], 0xFB0DFA06, 0x04FF0F0F, 0xFBFBFCEF, 0x01F7FFFF);
	r0 = D(r0, s[0][2][0], 0xFDF906F8, 0xF7FC08F9, 0xF4FB06F8, 0x0310EF0D);
	r1 = D(r1, s[0][2][0], 0x09F3FFE0, 0x0AF80905, 0xFF06020E, 0xFA0006EB);
	r0 = D(r0, s[0][2][1], 0xFD02F8F8, 0xFE0813E8, 0xFA01E712, 0x04F60CE1);
	r1 = D(r1, s[0][2][1], 0xE407EEC6, 0x07F8EBFD, 0x02FE0F1E, 0xFCFD03C3);
	r0 = D(r0, s[0][2][2], 0xFF02010A, 0xF6FC090D, 0xFEFCF9F3, 0x0805F4F1);
	r1 = D(r1, s[0][2][2], 0x0F020003, 0xF4FB04E9, 0xFA00FF03, 0xFD0804F1);
	r0 = D(r0, s[1][0][0], 0xF8F9FDFF, 0x0EE8FA06, 0x08F1F7FF, 0x042BF909);
	r1 = D(r1, s[1][0][0], 0x03160808, 0x12E405FA, 0xFDFBFFEE, 0x111605FA);
	r0 = D(r0, s[1][0][1], 0xF5EBFAF6, 0xFCCDF8F4, 0xF7CF03F9, 0x111BE5F6);
	r1 = D(r1, s[1][0][1], 0x1327080B, 0x0DC300EF, 0xF2D91209, 0x011DF0F6);
	r0 = D(r0, s[1][0][2], 0xFA0D0604, 0xDDE106F9, 0xF5D5F9F2, 0xEF1AFFFF);
	r1 = D(r1, s[1][0][2], 0x051106FD, 0xFADD05F2, 0x11FF09FA, 0xF91105FF);
	r0 = D(r0, s[1][1][0], 0x08FBFA03, 0x04E80218, 0x00DB150E, 0xE41FEB18);
	r1 = D(r1, s[1][1][0], 0x080AF615, 0x13D3110E, 0x0AD416F8, 0x0637FD08);
	r0 = D(r0, s[1][1][1], 0xFB0E131A, 0xDCEBED03, 0xE2CB0F15, 0x0209D0FB);
	r1 = D(r1, s[1][1][1], 0x0D08FF2A, 0x10E1050C, 0xFECF03F3, 0x2C08FFEF);
	r0 = D(r0, s[1][1][2], 0x01F7FFFF, 0xEFCEFA03, 0xFDEA1410, 0x0E1FECE6);
	r1 = D(r1, s[1][1][2], 0xFD1EFDEA, 0x0CEA0606, 0xF4080904, 0x1033FDFF);
	r0 = D(r0, s[1][2][0], 0x06F8F108, 0xFF11FD02, 0xFFFA0200, 0x080701F7);
	r1 = D(r1, s[1][2][0], 0xF63AFA08, 0xFB08F811, 0x01F1F801, 0x041AE508);
	r0 = D(r0, s[1][2][1], 0xECE60808, 0x08C8EE1D, 0x18EF0FFB, 0xF621EB19);
	r1 = D(r1, s[1][2][1], 0x1A380A0D, 0x06C7021A, 0xF9DD0201, 0xFA2AFA16);
	r0 = D(r0, s[1][2][2], 0xFDFAFDF4, 0xF2ED0607, 0xF401FCFE, 0xF92308FB);
	r1 = D(r1, s[1][2][2], 0xFD1106FA, 0xECF8F606, 0xFF1F0AFF, 0x0A350705);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-2.097e-02, 1.016e-02, -7.690e-03, 1.256e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-9.695e-03, 8.726e-05, -3.101e-02, 3.732e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv6
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
	r0 = D(r0, s[0][0][0], 0x01FCFA0F, 0x0003FFF5, 0xFAF50201, 0x01FFFCFA);
	r1 = D(r1, s[0][0][0], 0x02090E02, 0x01F30601, 0xFFFB0216, 0xF5FAE804);
	r0 = D(r0, s[0][0][1], 0xF4F709FB, 0xFDFB0C09, 0x0915FB0F, 0x06091302);
	r1 = D(r1, s[0][0][1], 0x12001009, 0x06F8EE02, 0x08E9FC0B, 0xF51C0B27);
	r0 = D(r0, s[0][0][2], 0x091305F5, 0xF5F60608, 0xFDFF01F5, 0x04100402);
	r1 = D(r1, s[0][0][2], 0xF9161CFA, 0x05160008, 0x02FF0509, 0x12E7EEF4);
	r0 = D(r0, s[0][1][0], 0xFE0104F5, 0x06F5E003, 0xFEFD090F, 0x00FCFC04);
	r1 = D(r1, s[0][1][0], 0xFFF0FF0F, 0x0305FBFF, 0x0305011F, 0xEBEDF102);
	r0 = D(r0, s[0][1][1], 0xFA17CF59, 0xF5E2D7EE, 0x06FBE4D3, 0xF204E724);
	r1 = D(r1, s[0][1][1], 0x010F23EC, 0x16F3E7DE, 0x1914182A, 0xF5F5D326);
	r0 = D(r0, s[0][1][2], 0xF9050DF0, 0xEFEDED02, 0xEE04FF15, 0xE6F41713);
	r1 = D(r1, s[0][1][2], 0x04F4F8F2, 0x06E1E301, 0x24F4ED0F, 0xFFF8FAF5);
	r0 = D(r0, s[0][2][0], 0xFD1203FE, 0xFFF7F4FD, 0x0401F300, 0xFCFC08F7);
	r1 = D(r1, s[0][2][0], 0x0711FB04, 0x0AFCF307, 0xFFF80B08, 0xF919F2FC);
	r0 = D(r0, s[0][2][1], 0xF4ECF4EE, 0xF40F0EF6, 0xF2F4FAE7, 0xF5FF09F8);
	r1 = D(r1, s[0][2][1], 0x0F0E09F8, 0x070F0603, 0xFA07FC19, 0xEA01FFE6);
	r0 = D(r0, s[0][2][2], 0xF0E9F1EA, 0x0C12F60D, 0xEEFAF70B, 0x01FAFCFE);
	r1 = D(r1, s[0][2][2], 0xF202FEEB, 0xF7F2FA04, 0x05FDFF12, 0xFFF00207);
	r0 = D(r0, s[1][0][0], 0x01FA0CF7, 0xF400FE01, 0x0408FB07, 0x060902FD);
	r1 = D(r1, s[1][0][0], 0x08FB080F, 0x040BF501, 0x02F80B06, 0xF8F90CFB);
	r0 = D(r0, s[1][0][1], 0x0C05FA07, 0xF1040807, 0xF5F709F7, 0xFD0DFAFF);
	r1 = D(r1, s[1][0][1], 0xF5F40FEC, 0x0108F8F7, 0x1705FE08, 0xEDF516F1);
	r0 = D(r0, s[1][0][2], 0x0606FD0B, 0xF5F406EC, 0x0404FC08, 0x07020608);
	r1 = D(r1, s[1][0][2], 0x13FFEEFE, 0xEDFC0B01, 0x04FFFFF7, 0x0107FE12);
	r0 = D(r0, s[1][1][0], 0xF7F50B06, 0x0206FF03, 0x020CE8EB, 0xEE0FF1F3);
	r1 = D(r1, s[1][1][0], 0x1AFDF803, 0x010DEDF1, 0x05020507, 0xF90911F9);
	r0 = D(r0, s[1][1][1], 0xF8DE11D4, 0x2914F608, 0xFB010C10, 0xEE02F8E9);
	r1 = D(r1, s[1][1][1], 0x0EE2230B, 0xBE0FF812, 0x0BCFE3EB, 0xF4E92706);
	r0 = D(r0, s[1][1][2], 0xE1F3130D, 0x1D20F00C, 0x03000BF1, 0xF60F16F5);
	r1 = D(r1, s[1][1][2], 0x2300F9FF, 0x081805FA, 0x1A09E812, 0xFA08F8FB);
	r0 = D(r0, s[1][2][0], 0xFEFB06FA, 0xF7FF09FA, 0x0309F6FB, 0xFB0FFCFE);
	r1 = D(r1, s[1][2][0], 0x00020400, 0xFD06FFF5, 0xF6020201, 0xFD0209FC);
	r0 = D(r0, s[1][2][1], 0xF50504FF, 0xE6FF05F7, 0xF71CFA0E, 0xE824FD08);
	r1 = D(r1, s[1][2][1], 0x02F6F8F6, 0x0A07E6FF, 0x0F040506, 0xFAFA0F02);
	r0 = D(r0, s[1][2][2], 0xFB100501, 0xE4EB0EFF, 0xFEF80103, 0xEE0303FF);
	r1 = D(r1, s[1][2][2], 0xFBFFF512, 0xF706F402, 0xFC01FFFB, 0xF7010900);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0404F7FA, 0xFC10F2F9, 0xFE020509, 0x050CFD02);
	r1 = D(r1, s[0][0][0], 0xF81C1C05, 0xFD01F105, 0x0B1AFEF0, 0xFFE22102);
	r0 = D(r0, s[0][0][1], 0xF501030F, 0xFA0914F5, 0xFC060DFE, 0xFFFD0FF6);
	r1 = D(r1, s[0][0][1], 0xED0823F1, 0x01F40501, 0xFA09F10C, 0xF70C08FD);
	r0 = D(r0, s[0][0][2], 0xF00909FF, 0x08FEF8FB, 0x05FA0405, 0xF8FF04FA);
	r1 = D(r1, s[0][0][2], 0x0E06090F, 0xF9FF0C01, 0x0904FE01, 0xF40900F9);
	r0 = D(r0, s[0][1][0], 0x05FAEEF5, 0xF9050812, 0xFB000F07, 0x01F305FB);
	r1 = D(r1, s[0][1][0], 0xF2EBFF07, 0xF6F2F50E, 0xF7DA0B0E, 0x0212EBEB);
	r0 = D(r0, s[0][1][1], 0xF0F8FE19, 0xEBF8F112, 0x12F510EB, 0xFC08EDF7);
	r1 = D(r1, s[0][1][1], 0x2D0F01DF, 0x21E1F9FA, 0xDFF5EA01, 0x0D10DE13);
	r0 = D(r0, s[0][1][2], 0x011AE408, 0xF8EE1008, 0x0E0208FC, 0x10FB1604);
	r1 = D(r1, s[0][1][2], 0x0D10F3FE, 0x04FF0D04, 0xEDFF04FB, 0xFFF702F7);
	r0 = D(r0, s[0][2][0], 0x0007FFF5, 0x07FE1506, 0xFC1A0F14, 0x0427FDFF);
	r1 = D(r1, s[0][2][0], 0xFB08F8FF, 0xFA18F5FD, 0x0AFA08F3, 0xFCE90FFF);
	r0 = D(r0, s[0][2][1], 0xFA45F00F, 0x05E51909, 0x15EF1CF5, 0x0101FC04);
	r1 = D(r1, s[0][2][1], 0xFA19E8F4, 0x06F8F1FB, 0xF6ED040E, 0x0B1B10FC);
	r0 = D(r0, s[0][2][2], 0x02F7080A, 0xFE1903FF, 0x13F20005, 0x08F60004);
	r1 = D(r1, s[0][2][2], 0x0105FCFE, 0x0BE9FE08, 0x03FBF700, 0x020E010C);
	r0 = D(r0, s[1][0][0], 0x0A04FC08, 0xEE011207, 0x000202F0, 0x02F8FEF6);
	r1 = D(r1, s[1][0][0], 0xE1040006, 0x04F7FDF8, 0x0306F8F5, 0xFE0F020B);
	r0 = D(r0, s[1][0][1], 0xF7FFFCF9, 0xFDFBFAFF, 0x0CFF03F9, 0x050808FF);
	r1 = D(r1, s[1][0][1], 0x13010202, 0x06020502, 0x0CFCF10D, 0xF0F809E7);
	r0 = D(r0, s[1][0][2], 0x0BFF1206, 0xEEFFF7E6, 0xFAFE01F4, 0xFD0006FC);
	r1 = D(r1, s[1][0][2], 0xE00509FF, 0x02F7FAFF, 0xF8FFEE03, 0x0FFAFB13);
	r0 = D(r0, s[1][1][0], 0xFF1401FE, 0x1CF8EDF7, 0xF8000FE4, 0xED0409FB);
	r1 = D(r1, s[1][1][0], 0xFF0BF20E, 0xFCF30301, 0x0209EE0C, 0xEF1D03FC);
	r0 = D(r0, s[1][1][1], 0xE7051FF5, 0x3C03FDF5, 0xEAFE061A, 0xDA10FCD5);
	r1 = D(r1, s[1][1][1], 0xE2F60A07, 0xCF0AF8F8, 0x1FFB08EA, 0x1AFA16DE);
	r0 = D(r0, s[1][1][2], 0xFDEE1CEA, 0x0515050B, 0xF7F8F8E7, 0xF7F7FAB7);
	r1 = D(r1, s[1][1][2], 0xDEFAF8FB, 0xFAF8E70A, 0xFF10F31C, 0x01FF0511);
	r0 = D(r0, s[1][2][0], 0xFB090508, 0xFAE1F9F7, 0x06EB0EF5, 0xF6F211F7);
	r1 = D(r1, s[1][2][0], 0x02FEFEFC, 0x01F40101, 0xF8060104, 0x020DFBFC);
	r0 = D(r0, s[1][2][1], 0xF20218F8, 0xF8F0F506, 0xF109FAFC, 0xF8F506D9);
	r1 = D(r1, s[1][2][1], 0xF80B020C, 0x0315FDF8, 0x04FCFDFA, 0xFCFC06F2);
	r0 = D(r0, s[1][2][2], 0xF0FAFFFF, 0x10FFFFF5, 0x1006FBEB, 0x1303F6F5);
	r1 = D(r1, s[1][2][2], 0xFB02FEF1, 0x0506F8FA, 0x06FFFB02, 0x08FEFBF1);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(7.692e-03, -2.301e-02, 1.157e-02, 1.746e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-1.459e-03, 2.081e-02, -3.308e-02, 3.705e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv7
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv6
//!BIND LUMA
//!SAVE conv7
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
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
	r0 = D(r0, s[0][0][0], 0x05FCFDEC, 0x09F60BEF, 0x04FE0904, 0x08051BFC);
	r1 = D(r1, s[0][0][0], 0x1603F6EC, 0xF60007F0, 0x14F4F707, 0xFB0EFE08);
	r0 = D(r0, s[0][0][1], 0x03EF1CEC, 0x1E0B10E8, 0xFD0301F9, 0x0AE206F7);
	r1 = D(r1, s[0][0][1], 0x07F430FA, 0xFFEB2CFE, 0x1F10E915, 0xEE0EF213);
	r0 = D(r0, s[0][0][2], 0x01F50DF7, 0x0AF512F9, 0xF8FD00F2, 0xF8FC1801);
	r1 = D(r1, s[0][0][2], 0x0EFD0507, 0xF4F11E04, 0x0104DB05, 0xF4F90802);
	r0 = D(r0, s[0][1][0], 0x0FFFE8FC, 0x19030910, 0xFF00F800, 0xFE0F15F1);
	r1 = D(r1, s[0][1][0], 0x0C0405F8, 0xED1B130C, 0x04F0EA05, 0xFF0D07FE);
	r0 = D(r0, s[0][1][1], 0x1405B822, 0x27E21D27, 0x01181BFD, 0x01F90FF8);
	r1 = D(r1, s[0][1][1], 0x090BD022, 0xEEF8FBFB, 0x3CEC1720, 0xE10C14F2);
	r0 = D(r0, s[0][1][2], 0x09F7F104, 0x0217FBFD, 0xFE08E1E5, 0x030415F3);
	r1 = D(r1, s[0][1][2], 0x1BFFFDF8, 0xFE100B07, 0xFF04EFEC, 0x05F00808);
	r0 = D(r0, s[0][2][0], 0x010205FF, 0xFA070604, 0x0BF9F4FD, 0x0A01FAFE);
	r1 = D(r1, s[0][2][0], 0x0BF9F0F6, 0xFC091708, 0x02F7EAF3, 0xF905EC02);
	r0 = D(r0, s[0][2][1], 0x0DFC1F0F, 0x07FB0009, 0x000A150F, 0xFF08F7FB);
	r1 = D(r1, s[0][2][1], 0x07030E12, 0xFDF6EB08, 0xFD0BF403, 0x05F8F1ED);
	r0 = D(r0, s[0][2][2], 0xFE0C0708, 0x02040104, 0xFE0119FD, 0x0202FDFC);
	r1 = D(r1, s[0][2][2], 0x0AFE08F9, 0xF7020205, 0xFB05FCF0, 0xF704F7FB);
	r0 = D(r0, s[1][0][0], 0xFE0C020A, 0x0A050303, 0x0201FE01, 0xFC09FB0B);
	r1 = D(r1, s[1][0][0], 0x0101FD01, 0xFA04FC08, 0x02000409, 0xECFDF6FB);
	r0 = D(r0, s[1][0][1], 0x01FE05FE, 0xF704FD08, 0x0909FFF2, 0x04F8F3F8);
	r1 = D(r1, s[1][0][1], 0x0106FEED, 0xF1F9F111, 0x02E905E9, 0x0F08F600);
	r0 = D(r0, s[1][0][2], 0xFF0C01FF, 0xFF0A02F9, 0xF818030D, 0xFEF90507);
	r1 = D(r1, s[1][0][2], 0x0905FFF4, 0xFFFF04F9, 0x07EF0B02, 0x03FBFEF2);
	r0 = D(r0, s[1][1][0], 0x0AFBFA02, 0xFEF20BF8, 0x010206FE, 0x0403030E);
	r1 = D(r1, s[1][1][0], 0x09050B0E, 0xFDF10704, 0x17FAFC04, 0xF40DFE07);
	r0 = D(r0, s[1][1][1], 0xFE1006BE, 0xF026EFD6, 0xF0ECF5EA, 0x11EBF42B);
	r1 = D(r1, s[1][1][1], 0x05E5F2D9, 0xF5FFF70D, 0xE5020FE4, 0x03D7DEE8);
	r0 = D(r0, s[1][1][2], 0x0507FEFE, 0x07F30701, 0x0931FC11, 0x03F9070A);
	r1 = D(r1, s[1][1][2], 0xF1100305, 0xFDFF080A, 0x07E40E06, 0xF20CFF09);
	r0 = D(r0, s[1][2][0], 0x04020802, 0x08030409, 0xFA02FEFF, 0xF6050709);
	r1 = D(r1, s[1][2][0], 0x02FE0003, 0x0FF807FF, 0xFCFDFF07, 0x03F901F7);
	r0 = D(r0, s[1][2][1], 0xF9010202, 0xFC03FB06, 0xFE06FCEF, 0x0D010309);
	r1 = D(r1, s[1][2][1], 0x02FDFCE9, 0xFDFAF0FF, 0xFCF603F8, 0xFF0901FF);
	r0 = D(r0, s[1][2][2], 0x05F6FCFF, 0xFEFF01FD, 0x0217F304, 0xFC0C0208);
	r1 = D(r1, s[1][2][2], 0xFD07FF01, 0x02FF01FF, 0xFCFC0909, 0x0402FE04);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x0805FB03, 0x02000305, 0xFE03FFFB, 0xFFFAFE06);
	r1 = D(r1, s[0][0][0], 0x04F7FDFC, 0x07040803, 0xF6FDFBF9, 0xFA020406);
	r0 = D(r0, s[0][0][1], 0x05F60B0A, 0x01F6F902, 0xFFF50202, 0xF2E41503);
	r1 = D(r1, s[0][0][1], 0xF9071405, 0xFFF71B04, 0xE5F7EFFB, 0xF71206FB);
	r0 = D(r0, s[0][0][2], 0x04FCF905, 0xFCFC0307, 0xFFFBF702, 0xF5FD0104);
	r1 = D(r1, s[0][0][2], 0xF7FA0007, 0xFEF71203, 0xF90EF7FF, 0x09F810FD);
	r0 = D(r0, s[0][1][0], 0xFAF50BF8, 0xFEEB0301, 0x00F8F808, 0xFEE7F107);
	r1 = D(r1, s[0][1][0], 0x04F6F110, 0xF2F2EDFF, 0x02FF0CFD, 0xF604F018);
	r0 = D(r0, s[0][1][1], 0xFFF41C16, 0x24160415, 0x02F6FB09, 0xFBBB070F);
	r1 = D(r1, s[0][1][1], 0x0BF004FC, 0x031ECBEE, 0x31032717, 0xCAF4F4F6);
	r0 = D(r0, s[0][1][2], 0x01FEFEFC, 0xF3FAFAF5, 0x0611DFF1, 0xF7E50EFE);
	r1 = D(r1, s[0][1][2], 0xF7050903, 0x1407F7FD, 0xF0F20AF6, 0x1812EF07);
	r0 = D(r0, s[0][2][0], 0x01FC030C, 0x08FD0007, 0x02FB04FC, 0x02EBFBFB);
	r1 = D(r1, s[0][2][0], 0xFDF60AFD, 0x0A0AFC01, 0x05F90604, 0xFEF507F7);
	r0 = D(r0, s[0][2][1], 0x03F7FC16, 0xF9FDFF08, 0x0208F410, 0xFFF20801);
	r1 = D(r1, s[0][2][1], 0x0E0CF901, 0xF80FF101, 0xFDF70C0B, 0x0E08F90B);
	r0 = D(r0, s[0][2][2], 0x0108F70E, 0x0103F605, 0xFB08EFEF, 0x07EFFF02);
	r1 = D(r1, s[0][2][2], 0xFDFCFC02, 0x060504F4, 0x01FBF501, 0x0102FEF8);
	r0 = D(r0, s[1][0][0], 0x00FE0706, 0xFC03F3F8, 0xFFFFFCFE, 0x02080400);
	r1 = D(r1, s[1][0][0], 0xFF02F605, 0xFB05FE01, 0x070505FF, 0x0702F6F7);
	r0 = D(r0, s[1][0][1], 0xEF0AF6F5, 0xF9FEECFB, 0xFC03FCFF, 0xF410FEF4);
	r1 = D(r1, s[1][0][1], 0x050BF5FE, 0xF901FEF8, 0x0A0803FD, 0x0FF2020D);
	r0 = D(r0, s[1][0][2], 0xFB00FCF7, 0xFB01FBF7, 0xFFFC04F9, 0xFC071000);
	r1 = D(r1, s[1][0][2], 0x0102FDFA, 0x040502F8, 0x01F5FE06, 0x0A02FDFA);
	r0 = D(r0, s[1][1][0], 0xFB0CF1F6, 0x04F90308, 0xFEFD0605, 0xFE16FEEC);
	r1 = D(r1, s[1][1][0], 0x01030AF0, 0x0A0501F7, 0xF7F20AFC, 0x0B09F9E7);
	r0 = D(r0, s[1][1][1], 0x15FEE500, 0xD3F2F2FE, 0xFB05F4EB, 0x0507E1FE);
	r1 = D(r1, s[1][1][1], 0xF6F0E919, 0x27EF3819, 0xD2F0F107, 0x17103702);
	r0 = D(r0, s[1][1][2], 0x0F01EC01, 0x0E00FA14, 0x1302FD11, 0xFA120B07);
	r1 = D(r1, s[1][1][2], 0xF9F7F705, 0x0DFE0207, 0xFD040308, 0x12F204EA);
	r0 = D(r0, s[1][2][0], 0xF801FFFC, 0xFBF9F9FF, 0x0506FF11, 0xF7090102);
	r1 = D(r1, s[1][2][0], 0x05040407, 0xF4F3FBF8, 0xFA01090A, 0xFAFFFFE4);
	r0 = D(r0, s[1][2][1], 0xFDF71306, 0x06F604F6, 0x16F9F109, 0x1110FBFC);
	r1 = D(r1, s[1][2][1], 0xFFF10012, 0x05F605F4, 0x02F900F5, 0x141208F9);
	r0 = D(r0, s[1][2][2], 0x07F50104, 0xFAF605FE, 0xFE09FF01, 0x03070103);
	r1 = D(r1, s[1][2][2], 0x0704FE01, 0xE4F6F507, 0x1A070914, 0x1E02FC05);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-5.639e-03, 1.863e-02, -1.253e-03, -9.300e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-1.712e-02, 6.179e-03, 6.364e-04, -9.563e-04);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-conv8
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv7
//!BIND LUMA
//!SAVE conv8
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv7_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv7_pt)
#define l1(x, y) conv7_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv7_pt)
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
	r0 = D(r0, s[0][0][0], 0xFDEC08F2, 0x03F804FD, 0x05E501E1, 0xF9F70101);
	r1 = D(r1, s[0][0][0], 0x04F3FEFC, 0xFC140404, 0xFEE9F5FF, 0xFD080300);
	r0 = D(r0, s[0][0][1], 0xEEFFFC02, 0xF8E7F8FB, 0x03F710E6, 0xF7FEFCFE);
	r1 = D(r1, s[0][0][1], 0x080A0903, 0xFB160209, 0xF9F7F107, 0xEEECE6EB);
	r0 = D(r0, s[0][0][2], 0x02FEF30D, 0xFCF2F5F9, 0x04020BF2, 0x0501010A);
	r1 = D(r1, s[0][0][2], 0x01FFF702, 0x0104FEFC, 0xFCFCF1F6, 0x040308F3);
	r0 = D(r0, s[0][1][0], 0xF7E41105, 0xF9FB03F9, 0x00F71305, 0x07E9FEFD);
	r1 = D(r1, s[0][1][0], 0xF50BF6F0, 0xF01C0217, 0x10EFFEF5, 0xF41208FB);
	r0 = D(r0, s[0][1][1], 0x0212F8F4, 0x1B2208F5, 0xF8F81609, 0x0B08FCF7);
	r1 = D(r1, s[0][1][1], 0xE7F1FCF1, 0x2B120402, 0x1601F30E, 0x0DFDDE0D);
	r0 = D(r0, s[0][1][2], 0xFDFEDF08, 0xFD04EA05, 0xFF0104FF, 0x03FF0903);
	r1 = D(r1, s[0][1][2], 0xFCFCFCFB, 0xF8FFF1FB, 0x0503FFFC, 0x03080501);
	r0 = D(r0, s[0][2][0], 0xFB02030E, 0xFEFF02F9, 0x0008FC0B, 0xFFFE03FD);
	r1 = D(r1, s[0][2][0], 0xFFEF04FB, 0xFD0AFB07, 0xFDF803FB, 0x0405FFFD);
	r0 = D(r0, s[0][2][1], 0x03FEFDEF, 0xFDF7FF01, 0xFEFDFCEB, 0xF9F601FB);
	r1 = D(r1, s[0][2][1], 0x0DFAFBF4, 0xFB05E4FD, 0x00FB11FB, 0x01F9FAFE);
	r0 = D(r0, s[0][2][2], 0x0101EB04, 0x040505F9, 0xFE0204FB, 0xFFFCFF01);
	r1 = D(r1, s[0][2][2], 0x05FBF6FE, 0xF403FDFD, 0xFFFDFEF9, 0x02FE04FC);
	r0 = D(r0, s[1][0][0], 0xFE08F7FC, 0xFF0FF9F8, 0xF9160309, 0x0AFFFDFE);
	r1 = D(r1, s[1][0][0], 0xF804FC02, 0xF70DFBED, 0xFC0301F5, 0xFE10FFF2);
	r0 = D(r0, s[1][0][1], 0x0608FEF3, 0x0901FFF9, 0xFD070D0D, 0x0BFBF804);
	r1 = D(r1, s[1][0][1], 0xFA0BFB16, 0xF70009F0, 0x070B1AFD, 0x0DF811F2);
	r0 = D(r0, s[1][0][2], 0x01FF0DF9, 0x05040406, 0xF604FCFD, 0x02FBFC05);
	r1 = D(r1, s[1][0][2], 0xFEFDF702, 0xFC0406F5, 0x030308FB, 0xFE0AFFFF);
	r0 = D(r0, s[1][1][0], 0x0309FDDB, 0x0501FC00, 0xFE09FF0F, 0xF8FE0AF5);
	r1 = D(r1, s[1][1][0], 0x06030B05, 0x01FE0201, 0xF501FFF1, 0x07FDF902);
	r0 = D(r0, s[1][1][1], 0xF305FF12, 0xEAF3F238, 0x0E06E531, 0xF8003221);
	r1 = D(r1, s[1][1][1], 0x19FDEA01, 0xBAF90E16, 0xFD0115FC, 0xF7F617D8);
	r0 = D(r0, s[1][1][2], 0xFCFA0AEF, 0x0305FEEE, 0x0406FA0A, 0xF9FCE106);
	r1 = D(r1, s[1][1][2], 0x0504FD0F, 0xFDFCF9FF, 0xFFFEFFFB, 0xFFFBEE13);
	r0 = D(r0, s[1][2][0], 0xFFF308F1, 0x0105FC09, 0xFFF7FEF3, 0xFF03FF09);
	r1 = D(r1, s[1][2][0], 0xFA05FBFE, 0xFCFDF509, 0x00030304, 0xFF03FF04);
	r0 = D(r0, s[1][2][1], 0xF9FCF601, 0x0002ED00, 0x0001FE04, 0x0105F005);
	r1 = D(r1, s[1][2][1], 0xF2050EF2, 0xF9FC1AFD, 0x0102F102, 0x0105FB03);
	r0 = D(r0, s[1][2][2], 0xFBFE0BFE, 0xF9FFF508, 0x0202F203, 0xFC0407FD);
	r1 = D(r1, s[1][2][2], 0xF3FF11F7, 0x0902F308, 0xFE010600, 0xFC05FFFE);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x02FFF9FC, 0xFF01F7FF, 0xFD030BE6, 0xFDFFFC05);
	r1 = D(r1, s[0][0][0], 0x0503F5FA, 0x0505F5FE, 0xEF0104F3, 0xF5FBF809);
	r0 = D(r0, s[0][0][1], 0xFC020EF5, 0xEDFC10F0, 0xEEF607EE, 0x05050F0B);
	r1 = D(r1, s[0][0][1], 0xFCFCF7FC, 0x05FAFAFE, 0xE9FFF807, 0x05010EFB);
	r0 = D(r0, s[0][0][2], 0x0902F802, 0xFE030103, 0x07FBFC04, 0x020001F9);
	r1 = D(r1, s[0][0][2], 0x03FFFEFD, 0x0400FE02, 0xFC020B03, 0x01FBF705);
	r0 = D(r0, s[0][1][0], 0x1AFDF609, 0x01F8FAF5, 0x12EDF605, 0x03040703);
	r1 = D(r1, s[0][1][0], 0x0E0E1109, 0x12F8FD04, 0xFE0308E4, 0xEDE9F103);
	r0 = D(r0, s[0][1][1], 0xDAF013D1, 0xF9F2EBD0, 0x3EFB0EE1, 0x1008091D);
	r1 = D(r1, s[0][1][1], 0x140619E7, 0x00F7BBFA, 0xF7EF23DE, 0x2B011CCD);
	r0 = D(r0, s[0][1][2], 0x07FBF507, 0xE5F91309, 0x09FEF5F6, 0xF9FEF8FC);
	r1 = D(r1, s[0][1][2], 0xF800FCFF, 0x00FEFAFC, 0xF5FC0301, 0xFDF6E5FD);
	r0 = D(r0, s[0][2][0], 0x02F5FEF7, 0xFDF5FDFE, 0x020100F6, 0xFB01FF09);
	r1 = D(r1, s[0][2][0], 0xFEF60611, 0x02FD02F5, 0x01040106, 0xF8F9FDFE);
	r0 = D(r0, s[0][2][1], 0xF802F6E0, 0x13090CFB, 0xEF0C0202, 0x0000110B);
	r1 = D(r1, s[0][2][1], 0xF8F408F8, 0xFC0607FB, 0xFA03F403, 0x0E00080B);
	r0 = D(r0, s[0][2][2], 0x02FD0A03, 0xF802F703, 0xF9030005, 0x13010E04);
	r1 = D(r1, s[0][2][2], 0x07FB1307, 0xF70507FF, 0xFE010204, 0xFE02FF02);
	r0 = D(r0, s[1][0][0], 0xFE0F0BF9, 0xFC0D0502, 0x0BF101F7, 0xFF0705FB);
	r1 = D(r1, s[1][0][0], 0x01FF0208, 0xF70DFC0B, 0x09FCF905, 0xFE0C0101);
	r0 = D(r0, s[1][0][1], 0x0403E80D, 0x0706FCFC, 0x1008E7F8, 0x0105F508);
	r1 = D(r1, s[1][0][1], 0x09F90003, 0xF901FC01, 0x10FC01F7, 0xFA0EFEED);
	r0 = D(r0, s[1][0][2], 0xFB090AF9, 0x060A01FE, 0xF60308FD, 0xFB0306FB);
	r1 = D(r1, s[1][0][2], 0xFCFDFF02, 0xFDFF0501, 0xFF00F801, 0x08070301);
	r0 = D(r0, s[1][1][0], 0xF71303EF, 0x080803FC, 0xF20DFBFD, 0x07FDFDFB);
	r1 = D(r1, s[1][1][0], 0x09DFF5FF, 0x02E7F902, 0xFD150309, 0x031707FE);
	r0 = D(r0, s[1][1][1], 0x0D2DE11C, 0xFF1F0507, 0xE2EDEF15, 0x0B33F002);
	r1 = D(r1, s[1][1][1], 0xF400FFF5, 0x02E604EA, 0xFE03FD13, 0xEF1CF5EF);
	r0 = D(r0, s[1][1][2], 0xFFFF13F2, 0xFD000806, 0xFC080606, 0xF7ED0BF2);
	r1 = D(r1, s[1][1][2], 0x02FCFFFB, 0x0BFD02FE, 0xFD0A0403, 0xF8110EF7);
	r0 = D(r0, s[1][2][0], 0xFF140302, 0x030EFF01, 0x04F90903, 0xFE03FEFE);
	r1 = D(r1, s[1][2][0], 0xF91101F7, 0x07F50602, 0xFCF4FCFF, 0x040905FC);
	r0 = D(r0, s[1][2][1], 0x01050A0E, 0x01DF0305, 0x07F30A01, 0xFD06FF05);
	r1 = D(r1, s[1][2][1], 0x051AFB04, 0x08DBFC08, 0x040809FE, 0xFEFEFDFC);
	r0 = D(r0, s[1][2][2], 0x0BFCFCFB, 0x0AFDFFF3, 0x050104FD, 0xFEEBF8FF);
	r1 = D(r1, s[1][2][2], 0x0000FC01, 0x05F8FF04, 0x0201FFFD, 0x03FB02FD);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-6.171e-03, -7.783e-03, -1.728e-02, 8.460e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-5.205e-03, 9.495e-03, -2.168e-02, 1.016e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-8x8C-TEST-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv8
//!BIND easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv8_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv8_pt)
#define l1(x, y) conv8_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv8_pt)
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
	r0 = D(r0, s[0][0][0], 0xFFFD1203, 0xFFFF0B07, 0xFF00F600, 0x00FEFA00);
	r0 = D(r0, s[0][0][1], 0xFEF2E130, 0xF2F006E9, 0x120CFEF2, 0x090603F8);
	r0 = D(r0, s[0][0][2], 0xFD0203F9, 0x0301FB08, 0xFFFDFD03, 0x030401FF);
	r0 = D(r0, s[0][1][0], 0x1A0CCEF8, 0x06F8E417, 0x1EFBFCF8, 0x05FD1012);
	r0 = D(r0, s[0][1][1], 0xD443373A, 0xE950FBA6, 0xD0CBD77A, 0xE1DFDBC1);
	r0 = D(r0, s[0][1][2], 0xFFFA03E4, 0xEF011BFD, 0x03FE0CE4, 0xFCEBFD0E);
	r0 = D(r0, s[0][2][0], 0xFDFD0FFD, 0xFC0708FB, 0xF7F90AFC, 0xFDFDF807);
	r0 = D(r0, s[0][2][1], 0x0EF0F801, 0x09ED070F, 0x030C1901, 0xFA0E1AE5);
	r0 = D(r0, s[0][2][2], 0x0406FC0B, 0x0502F803, 0xFE00FD00, 0xFBFB0BFD);
	r0 = D(r0, s[1][0][0], 0x0B0014FE, 0xF800F0FF, 0x0300F9FE, 0xFCFFFA01);
	r0 = D(r0, s[1][0][1], 0xFC0408F4, 0x070325F3, 0xF1FAFC0D, 0xFAFDFA08);
	r0 = D(r0, s[1][0][2], 0x0400FFFD, 0xFC0204FD, 0x010003FB, 0xFCFD02FE);
	r0 = D(r0, s[1][1][0], 0xFEF90808, 0xF2081AFA, 0xFEFC1F06, 0xE4010100);
	r0 = D(r0, s[1][1][1], 0x23FCE505, 0x26E1E424, 0x1A0FFDD7, 0x1F0616F1);
	r0 = D(r0, s[1][1][2], 0x0303FA0D, 0x0D11F60C, 0x0000F909, 0xFF0905FD);
	r0 = D(r0, s[1][2][0], 0x0902F6FD, 0x01FBF801, 0x0801F700, 0x030605FC);
	r0 = D(r0, s[1][2][1], 0xEF0301F8, 0xF709FEF8, 0x03FCF60D, 0x00EFF712);
	r0 = D(r0, s[1][2][2], 0xFDFB06F8, 0xFBF905F9, 0x02FE03FD, 0x0805F704);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xF8FAFFEE, 0xFA02FEF5, 0xF40302F2, 0xFF000108);
	r0 = D(r0, s[0][0][1], 0xFF0DF3D7, 0x15F3FDF6, 0xF8FA070A, 0xF40106F8);
	r0 = D(r0, s[0][0][2], 0x03FCFD03, 0x020CF2EC, 0x0302FD03, 0xFDFD000D);
	r0 = D(r0, s[0][1][0], 0x15E9FEF8, 0xFAFD0A00, 0x16F0FB21, 0xFB0807F8);
	r0 = D(r0, s[0][1][1], 0xB2D8F6F8, 0x42DCEEF7, 0xE90AE207, 0x4FDCEC56);
	r0 = D(r0, s[0][1][2], 0x0DEE0A08, 0xFBE9150F, 0x05FA0808, 0x0417FCEE);
	r0 = D(r0, s[0][2][0], 0xF8050201, 0xFE00FDFE, 0xF8F604FF, 0xF7F700FF);
	r0 = D(r0, s[0][2][1], 0xFDF7FEFD, 0x00FB0603, 0xC6D8030A, 0x0FE903FF);
	r0 = D(r0, s[0][2][2], 0x0107FAFA, 0x0103FAFB, 0x09F7FCFF, 0xFAEA060C);
	r0 = D(r0, s[1][0][0], 0x00FAF805, 0x08FB0306, 0x06FBF808, 0x0100FFFF);
	r0 = D(r0, s[1][0][1], 0xFFF21208, 0xF80903F3, 0x07FFF503, 0x09FCF509);
	r0 = D(r0, s[1][0][2], 0x02040102, 0xFAF60C0D, 0xFFFD0100, 0x0000FEFF);
	r0 = D(r0, s[1][1][0], 0xF00306F7, 0xF8FEF404, 0xE40309F3, 0x00F8FC07);
	r0 = D(r0, s[1][1][1], 0x07FD17FE, 0xFE0826EF, 0xF4F93814, 0xDD2231E4);
	r0 = D(r0, s[1][1][2], 0x040CF4F3, 0x0500ECEB, 0x0508F8FB, 0xF8EF090F);
	r0 = D(r0, s[1][2][0], 0x06FAFD03, 0x01FE0501, 0x0BFBFB00, 0xFF030002);
	r0 = D(r0, s[1][2][1], 0x08100303, 0x040BFC01, 0x100601F3, 0x14FF00F7);
	r0 = D(r0, s[1][2][2], 0xFFF90607, 0x01000808, 0x00030303, 0x0606FDF8);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(2.449e-03, 1.392e-03, 2.087e-03, 6.662e-04);
	f0 = tanh(f0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(f0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(f0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(f0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

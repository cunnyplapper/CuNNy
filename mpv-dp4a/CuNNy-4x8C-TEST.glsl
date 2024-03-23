// CuNNy 4x8C TEST
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

//!DESC CuNNy-4x8C-TEST-EASU
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


//!DESC CuNNy-4x8C-TEST-in
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
	r0 += V4(-6.261e-02, 1.096e-01, 1.683e-01, -1.565e-02) * s[0][0][0];
	r1 += V4(6.652e-02, 7.826e-03, -1.604e-01, -1.017e-01) * s[0][0][0];
	r0 += V4(4.304e-02, -1.135e-01, 4.696e-02, -3.130e-02) * s[0][1][0];
	r1 += V4(-1.565e-01, 7.826e-03, 1.996e-01, 3.130e-02) * s[0][1][0];
	r0 += V4(4.304e-02, 1.174e-02, 9.782e-02, 4.696e-02) * s[0][2][0];
	r1 += V4(-1.174e-02, -3.913e-03, 2.309e-01, 1.174e-02) * s[0][2][0];
	r0 += V4(-2.426e-01, 2.504e-01, -5.869e-02, 6.261e-02) * s[1][0][0];
	r1 += V4(-1.135e-01, -3.913e-03, -2.348e-02, -5.869e-02) * s[1][0][0];
	r0 += V4(1.213e-01, -6.026e-01, -4.226e-01, -8.608e-02) * s[1][1][0];
	r1 += V4(-1.761e-01, -2.622e-01, -3.365e-01, -1.174e-01) * s[1][1][0];
	r0 += V4(-7.826e-03, 9.000e-02, -1.956e-02, -2.465e-01) * s[1][2][0];
	r1 += V4(1.565e-02, 2.739e-02, 1.487e-01, -2.230e-01) * s[1][2][0];
	r0 += V4(6.261e-02, 2.348e-02, -4.696e-02, -4.696e-02) * s[2][0][0];
	r1 += V4(2.739e-02, 3.913e-03, 7.043e-02, 6.652e-02) * s[2][0][0];
	r0 += V4(6.261e-02, 1.487e-01, -7.826e-02, 3.913e-01) * s[2][1][0];
	r1 += V4(5.478e-02, 1.565e-02, -3.130e-02, -1.135e-01) * s[2][1][0];
	r0 += V4(-3.913e-02, 6.652e-02, 4.304e-02, -7.435e-02) * s[2][2][0];
	r1 += V4(2.896e-01, -3.913e-03, -8.608e-02, 9.782e-02) * s[2][2][0];
	r0 += V4(-3.426e-03, 3.012e-03, 1.111e-01, 2.345e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(7.698e-04, 7.153e-03, 1.826e-02, 5.657e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-4x8C-TEST-conv1
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
	r0 = D(r0, s[0][0][0], 0xF100F10A, 0x2414DFEC, 0xFBF80DFB, 0x45F812FB);
	r1 = D(r1, s[0][0][0], 0xFDFDFDF6, 0xEEFDF60A, 0x080014DF, 0xD2F30312);
	r0 = D(r0, s[0][0][1], 0xF30D1229, 0x24FB36FD, 0x050A08E4, 0xF1D70AF8);
	r1 = D(r1, s[0][0][1], 0xF8F30AF6, 0xF100F805, 0x0DF126EE, 0xF3000D00);
	r0 = D(r0, s[0][0][2], 0xFD052603, 0x0508FB0D, 0xFD21F800, 0xF60024FB);
	r1 = D(r1, s[0][0][2], 0xFD0A0005, 0xF60FF3E6, 0x1208FB33, 0xFBF80021);
	r0 = D(r0, s[0][1][0], 0x14F812FD, 0xF108242C, 0x1F00FB03, 0x17E9E926);
	r1 = D(r1, s[0][1][0], 0x0DF608F6, 0xEE0D000D, 0x08FDFDE9, 0xAC210300);
	r0 = D(r0, s[0][1][1], 0x17EE24DA, 0xCFE4E412, 0x17F80003, 0x1717FD1C);
	r1 = D(r1, s[0][1][1], 0x1AE90D17, 0xFD00D7F8, 0xA4B8B821, 0xC3F6F10D);
	r0 = D(r0, s[0][1][2], 0x00DCC8F1, 0xF6FDF8F3, 0xFBE91231, 0xFD0D29BB);
	r1 = D(r1, s[0][1][2], 0x08FDEC05, 0x08F81700, 0x03051405, 0xEC0AFB3B);
	r0 = D(r0, s[0][2][0], 0xDFFDF805, 0xFD0DFD17, 0x00050A0F, 0xF31CFBDA);
	r1 = D(r1, s[0][2][0], 0xF3F30D0D, 0x0312F3F1, 0x00FDF6EC, 0x0517FD05);
	r0 = D(r0, s[0][2][1], 0xE9000526, 0x0005F3F6, 0xF6FB0DF3, 0xEE0F0D17);
	r1 = D(r1, s[0][2][1], 0x03DAC512, 0x0F1A141F, 0x0A1AFDFD, 0xF30317E4);
	r0 = D(r0, s[0][2][2], 0xF8F8F3F8, 0x05F80812, 0xFBF6EC29, 0xEEFD21F8);
	r1 = D(r1, s[0][2][2], 0x03F61AD2, 0xFD0A1A17, 0x0505F617, 0xFB0D0D2E);
	r0 = D(r0, s[1][0][0], 0x1205120F, 0x0F0A0F05, 0xF308FD0F, 0x6B05FBF8);
	r1 = D(r1, s[1][0][0], 0xFB030508, 0xE1FD00EC, 0x26FD03F6, 0xB80800EC);
	r0 = D(r0, s[1][0][1], 0xDF00FBFD, 0x05FBBB1C, 0xDCFD2105, 0x360F1AFB);
	r1 = D(r1, s[1][0][1], 0x260AF80F, 0x0DF6EEEC, 0x17080F05, 0x9A0AF100);
	r0 = D(r0, s[1][0][2], 0xFBF8F6FB, 0x05F30AEE, 0x240DFDEC, 0xDFFBFD0A);
	r1 = D(r1, s[1][0][2], 0x08FBFBFD, 0x1CFDF3EE, 0x17032103, 0x05FB00F3);
	r0 = D(r0, s[1][1][0], 0xFB0AE6F3, 0x14ECDAFB, 0xFB080308, 0x211C0AEC);
	r1 = D(r1, s[1][1][0], 0x0D0DF608, 0xF105030D, 0x14140503, 0xD2E1F60F);
	r0 = D(r0, s[1][1][1], 0x1FF1E421, 0x170343EC, 0xEC031FFD, 0xF80F030A);
	r1 = D(r1, s[1][1][1], 0x0D0FF8EE, 0xF3144000, 0xE91F1708, 0xE41A4303);
	r0 = D(r0, s[1][1][2], 0x080826DA, 0xFBF80D17, 0xF3F614E1, 0xEEF3ECE9);
	r1 = D(r1, s[1][1][2], 0x0F030FFB, 0xF6DFA424, 0xE1F8F10A, 0xDFFD1214);
	r0 = D(r0, s[1][2][0], 0xF800F6FD, 0x0D08F8FD, 0x0DF8F6FB, 0xE6DFFB0A);
	r1 = D(r1, s[1][2][0], 0x030A05F6, 0xFBEC030A, 0xFB081403, 0xEEE9F108);
	r0 = D(r0, s[1][2][1], 0x0A0A2608, 0xF80505E9, 0x0F0FF805, 0x0FDF0005);
	r1 = D(r1, s[1][2][1], 0xF814240A, 0xF6E908FD, 0xE6DFE6F6, 0xF3ECEC0F);
	r0 = D(r0, s[1][2][2], 0xE61238F8, 0x0303E900, 0x03170A05, 0xF800FDEC);
	r1 = D(r1, s[1][2][2], 0xFB0AECFB, 0x0AF8CF12, 0xFDFBF3EE, 0x03FBFDF3);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFB00DF17, 0x431469E4, 0x5C054DFD, 0x2CEE2C36);
	r1 = D(r1, s[0][0][0], 0x1C08F10A, 0x7F0A6B14, 0x7F0F78FB, 0x0F05330F);
	r0 = D(r0, s[0][0][1], 0x08FD7F0F, 0x0D247FF6, 0x5F087FF1, 0x4A08AE26);
	r1 = D(r1, s[0][0][1], 0xDA08EE05, 0x4A0A8112, 0x5AF85AEE, 0x3DECCDF3);
	r0 = D(r0, s[0][0][2], 0xA4006EF3, 0xF3FB521C, 0x7F057F08, 0x690031E6);
	r1 = D(r1, s[0][0][2], 0x1F0038FD, 0xE9F68105, 0x7FF64AF6, 0x21004D05);
	r0 = D(r0, s[0][1][0], 0x0F0AFD29, 0xEEFB57E4, 0x4F0A52F6, 0xE60F5C3D);
	r1 = D(r1, s[0][1][0], 0x4F00F8FD, 0xA4057F0F, 0x05F67FCA, 0x811FC817);
	r0 = D(r0, s[0][1][1], 0x81F6DAF3, 0xD4BB000D, 0x3BF67FE6, 0xE6EE030F);
	r1 = D(r1, s[0][1][1], 0x81FB8105, 0x08F38103, 0x61E181BD, 0xBBDA81DC);
	r0 = D(r0, s[0][1][2], 0xB1F3810A, 0x9C0AA1E9, 0x7FFB7F03, 0x97FB0DEE);
	r1 = D(r1, s[0][1][2], 0x2CFB0303, 0xC0FB81F8, 0xE10017F3, 0x81F3E1FB);
	r0 = D(r0, s[0][2][0], 0x9CF81CFD, 0xC8037F08, 0x3603CF00, 0xFBFD4808);
	r1 = D(r1, s[0][2][0], 0xD7087FF3, 0x1AFD21F6, 0x2421DFFB, 0xC521B30A);
	r0 = D(r0, s[0][2][1], 0xA9CF0F08, 0xD41C03F3, 0x5FEE7FEE, 0xA9FD81F6);
	r1 = D(r1, s[0][2][1], 0x69FDB3F1, 0xB3147FFD, 0x7F14E1EE, 0x880A81F6);
	r0 = D(r0, s[0][2][2], 0xD21AA105, 0xF6F15A0F, 0x5F0A7F0A, 0xE41AFBE6);
	r1 = D(r1, s[0][2][2], 0xF6F66403, 0xD2F87FF6, 0x81F8CF14, 0x81F1F8FB);
	r0 = D(r0, s[1][0][0], 0x0FF8F81A, 0x000812CF, 0x0FEE0FF8, 0x08081724);
	r1 = D(r1, s[1][0][0], 0x0FF60800, 0x170300E4, 0xF8FD03F8, 0x08EEFBDF);
	r0 = D(r0, s[1][0][1], 0xE6FDF30D, 0xFBF1F6F8, 0xF8F6FB05, 0x0FE60FF3);
	r1 = D(r1, s[1][0][1], 0x05FB0AF6, 0x0A00FDF8, 0xFD00080D, 0x00000503);
	r0 = D(r0, s[1][0][2], 0x05FBEE14, 0x031CFBE6, 0xE60003F8, 0xF3E4FB1A);
	r1 = D(r1, s[1][0][2], 0x0303EC00, 0xF10A0303, 0xF8000DF3, 0x0AFD0D00);
	r0 = D(r0, s[1][1][0], 0xFBE905FD, 0x0824ECDA, 0x00EC0505, 0x0FDAE603);
	r1 = D(r1, s[1][1][0], 0xF6000D12, 0x24050FFB, 0x080500EE, 0x0FEE03F6);
	r0 = D(r0, s[1][1][1], 0x0FF600F6, 0x0017FD08, 0x0514F608, 0xF81F030D);
	r1 = D(r1, s[1][1][1], 0xFDFD00FD, 0x050505F1, 0x08050DEE, 0xF83DF605);
	r0 = D(r0, s[1][1][2], 0x0FF1F6F8, 0xF3F80014, 0xF1FD0AF8, 0x0329F80A);
	r1 = D(r1, s[1][1][2], 0x1703FB05, 0xF605EE24, 0xFBE6F10D, 0x03000305);
	r0 = D(r0, s[1][2][0], 0xFDCF00F3, 0xFB1F0300, 0xF6E608FB, 0xFDDF0FF1);
	r1 = D(r1, s[1][2][0], 0x0AF608F8, 0x03F61CF6, 0xF80A0FFB, 0xFD1CFD05);
	r0 = D(r0, s[1][2][1], 0xF6E60A00, 0x0FE40F0F, 0xF80A0303, 0xFD12F30D);
	r1 = D(r1, s[1][2][1], 0x0805FB0A, 0x03BDFBFB, 0xF8E6FB21, 0x0A05F808);
	r0 = D(r0, s[1][2][2], 0xE4E112F1, 0x08FD05FB, 0xF3FBF305, 0x050803FB);
	r1 = D(r1, s[1][2][2], 0x1408FD00, 0xFB1FEE17, 0x0303E1F8, 0x050DFD0A);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(1.611e-02, -1.372e-02, -2.238e-02, -4.749e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-3.172e-01, -6.954e-02, 1.379e-02, -1.984e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-4x8C-TEST-conv2
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
	r0 = D(r0, s[0][0][0], 0x051CFB20, 0x00E405FE, 0xFDFEFAFE, 0xEBDC03E6);
	r1 = D(r1, s[0][0][0], 0xFB24FA15, 0x0A031212, 0x0FF60200, 0xFE1D06FE);
	r0 = D(r0, s[0][0][1], 0xFBF5F318, 0x03F50006, 0x06FBFDD1, 0xF30305E4);
	r1 = D(r1, s[0][0][1], 0xFDF6ED13, 0xFB050A15, 0x050FEE0D, 0x0305061A);
	r0 = D(r0, s[0][0][2], 0xF1F5EEFB, 0x060208F0, 0xFAF50608, 0xF8F100E9);
	r1 = D(r1, s[0][0][2], 0x03F3F012, 0x000012DE, 0x050AFB08, 0xFA0D06F1);
	r0 = D(r0, s[0][1][0], 0x050B0D1D, 0x058B0500, 0x001AFB25, 0xFA8F05ED);
	r1 = D(r1, s[0][1][0], 0xF8120210, 0x00CF06DB, 0xFD08000D, 0x06A21034);
	r0 = D(r0, s[0][1][1], 0xF803F124, 0x020F0503, 0x0FD3F002, 0x1DE039DC);
	r1 = D(r1, s[0][1][1], 0xEB00FE0D, 0xFD0F15F5, 0x03F0FEE0, 0x08F11D20);
	r0 = D(r0, s[0][1][2], 0x0208101F, 0xFDFAFA06, 0xFD03DE22, 0x0F0D29FB);
	r1 = D(r1, s[0][1][2], 0x1AFE2015, 0xE9FB06F3, 0xF1FBE10B, 0xF3020FFD);
	r0 = D(r0, s[0][2][0], 0xF603F305, 0x06AC05E8, 0x030FF8FD, 0xFEE80AFB);
	r1 = D(r1, s[0][2][0], 0xFD0FFE15, 0x0D0F1DD7, 0xFBE60305, 0xFB9D03F1);
	r0 = D(r0, s[0][2][1], 0xF10F1006, 0x05D7E3F5, 0x08F5E829, 0x051D0DE3);
	r1 = D(r1, s[0][2][1], 0x02020A08, 0xF6F51CF1, 0x08E0EBFA, 0x081D0BC9);
	r0 = D(r0, s[0][2][2], 0xF117FE13, 0x0005F80F, 0x0BF8F103, 0xFA0520E9);
	r1 = D(r1, s[0][2][2], 0x0008130B, 0xF802100D, 0x03FE0515, 0xFA0A18FD);
	r0 = D(r0, s[1][0][0], 0x0FF00F02, 0xFB0200FE, 0x080B0008, 0xFA06F505);
	r1 = D(r1, s[1][0][0], 0xFA03FB17, 0x0A0A03F6, 0x050B0508, 0xFDF305EB);
	r0 = D(r0, s[1][0][1], 0x060308E3, 0x20FA0AF5, 0xFA02F508, 0xFD08FBF6);
	r1 = D(r1, s[1][0][1], 0xF80002F8, 0x03F502E8, 0x17F306FE, 0xE6000FF8);
	r0 = D(r0, s[1][0][2], 0xFA0F0DF6, 0xFBFA0612, 0x06F1FAF5, 0xF00D02FA);
	r1 = D(r1, s[1][0][2], 0xF60312FB, 0xFBFBF013, 0x06030506, 0xFD060812);
	r0 = D(r0, s[1][1][0], 0x03F0100A, 0xF5FA0006, 0x1713F617, 0xFB06FAE4);
	r1 = D(r1, s[1][1][0], 0x0517F6F5, 0xFEEE0D0B, 0x08220808, 0xEBFB0DFE);
	r0 = D(r0, s[1][1][1], 0x0DFE2C00, 0x2710E6E8, 0xDCFBE412, 0xC60BE60F);
	r1 = D(r1, s[1][1][1], 0x0B1308F3, 0x460010D7, 0x1C0A0300, 0xF1120DE8);
	r0 = D(r0, s[1][1][2], 0xF1FE0BFB, 0x030303FB, 0x13DC15F5, 0xDEFAF1FD);
	r1 = D(r1, s[1][1][2], 0xDC00CAEE, 0x2CF5120F, 0x240610FD, 0x1213FD10);
	r0 = D(r0, s[1][2][0], 0xF80F05FB, 0xE4EBFE10, 0x1F00F0F3, 0x00050203);
	r1 = D(r1, s[1][2][0], 0x0FFA00F3, 0xEDF3FD0F, 0xFAF006F1, 0xEEFA0608);
	r0 = D(r0, s[1][2][1], 0x0F0B15F3, 0x0BF50A12, 0xFB08EBF3, 0xD7F11005);
	r1 = D(r1, s[1][2][1], 0x06EE00FD, 0x1C0FFEF3, 0x08FA0200, 0x0DFB1318);
	r0 = D(r0, s[1][2][2], 0xEEF608FB, 0x050503F6, 0x2002E6FD, 0xE1FDFBF8);
	r1 = D(r1, s[1][2][2], 0x0202FE06, 0x2CED0F08, 0x29FAF00A, 0x1202FE03);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x02FB2527, 0xF8F0E60B, 0x0F17EEF1, 0x1A0D05F5);
	r1 = D(r1, s[0][0][0], 0x03F61259, 0xEEF0F3CF, 0x02F1E117, 0xF1030F36);
	r0 = D(r0, s[0][0][1], 0x17360D81, 0x05E1F0C9, 0xFE0BFD75, 0x2DFAD77F);
	r1 = D(r1, s[0][0][1], 0xFA052232, 0xFEE01581, 0xEECFFA7E, 0x00E1125E);
	r0 = D(r0, s[0][0][2], 0xFB0A10E0, 0xDEF5F860, 0xE1290F9A, 0x00F0FA1D);
	r1 = D(r1, s[0][0][2], 0xFA1DF67E, 0xE9E800B5, 0xD7100220, 0x06E9F03F);
	r0 = D(r0, s[0][1][0], 0x08FE2C02, 0x1AF5FBE3, 0x0A13FDE4, 0x0F0202FD);
	r1 = D(r1, s[0][1][0], 0x12082059, 0x0FDBDBC6, 0x12FBCCE0, 0xFAFEDC27);
	r0 = D(r0, s[0][1][1], 0xDE0DF8B4, 0x2DEBCFB4, 0xFD493AD6, 0xF617EE47);
	r1 = D(r1, s[0][1][1], 0xE3F52206, 0xE6E0F6D1, 0x25DB1D4F, 0xE313E87F);
	r0 = D(r0, s[0][1][2], 0x050B0853, 0x17E913DB, 0x051C02BA, 0x06F0F3F3);
	r1 = D(r1, s[0][1][2], 0x0815F0FA, 0x13EB051A, 0x05FB0A1D, 0x13CE064B);
	r0 = D(r0, s[0][2][0], 0xF1F80FD3, 0xFBF502E6, 0x06F8000A, 0xFB00E4E1);
	r1 = D(r1, s[0][2][0], 0xEB0D20FD, 0x05EDF8F8, 0x0A02F506, 0xF5E3FB0A);
	r0 = D(r0, s[0][2][1], 0xF30527E8, 0xF5F612C2, 0x0F1D02E4, 0xFB05FB1C);
	r1 = D(r1, s[0][2][1], 0xFB1D00FB, 0x0BEE25C6, 0x1CEE180F, 0x08D41708);
	r0 = D(r0, s[0][2][2], 0x0BFB0A0A, 0xF8170008, 0xEDFBFAE0, 0xFA0510FD);
	r1 = D(r1, s[0][2][2], 0xF1F5FD2C, 0x18E606B9, 0x0AEE0003, 0x1FE008F3);
	r0 = D(r0, s[1][0][0], 0xFD00F80A, 0xFAF51C00, 0xFB08ED00, 0x0AF5F300);
	r1 = D(r1, s[1][0][0], 0xF1FEF0F1, 0xFA0DFB05, 0xF806FEFA, 0x05000006);
	r0 = D(r0, s[1][0][1], 0xE602F3FA, 0x0A001AFA, 0xFD0DFB0B, 0x05F8FEF5);
	r1 = D(r1, s[1][0][1], 0xE412021F, 0xFEE3EDF6, 0x0613FE0D, 0xF8F606EE);
	r0 = D(r0, s[1][0][2], 0xE9150505, 0xF3050308, 0x0AE902FA, 0xFE050A17);
	r1 = D(r1, s[1][0][2], 0x03F618F0, 0x0AFA03FD, 0x0200FA05, 0xFE0A1206);
	r0 = D(r0, s[1][1][0], 0xEE03FAEE, 0xE3F5E600, 0x1810E8FD, 0x1AF50602);
	r1 = D(r1, s[1][1][0], 0x06031010, 0xE4FE0BF6, 0xEEFAF5FA, 0xF8E41AF3);
	r0 = D(r0, s[1][1][1], 0x0315FD02, 0xD40FE6FE, 0xFA02E902, 0x06E0F500);
	r1 = D(r1, s[1][1][1], 0x12F11A13, 0xE9FBFB0B, 0xCFFECCF6, 0xE8E9F808);
	r0 = D(r0, s[1][1][2], 0xF312ED02, 0xE6FAF502, 0x15EE1700, 0x0DFA0602);
	r1 = D(r1, s[1][1][2], 0xD90008E1, 0xD7FA0FFA, 0xF6EEFD06, 0xF602E40A);
	r0 = D(r0, s[1][2][0], 0xF8001202, 0x08FB1803, 0xFB10F8FB, 0x0DF5170B);
	r1 = D(r1, s[1][2][0], 0x02FDF805, 0x17F30AFD, 0x00031200, 0x080B0B00);
	r0 = D(r0, s[1][2][1], 0xEB050F02, 0x12F806FE, 0xE0F312FA, 0x1FF60DFE);
	r1 = D(r1, s[1][2][1], 0x08FBFD06, 0xEBFDEDFA, 0xE1FAE4F5, 0xF017DEFE);
	r0 = D(r0, s[1][2][2], 0xEE060003, 0x00F808F8, 0x05022008, 0x0DFDF3F3);
	r1 = D(r1, s[1][2][2], 0x1005F8FA, 0xEB030806, 0xFDFB0A05, 0xE106F3FD);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-2.495e-02, 3.013e-02, 1.727e-02, -3.868e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-2.733e-02, 5.621e-02, 1.848e-02, -1.333e-02);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-4x8C-TEST-conv3
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
	r0 = D(r0, s[0][0][0], 0xEC09E4FE, 0xFF0D05F5, 0xFDFBFF01, 0x08FDE5F5);
	r1 = D(r1, s[0][0][0], 0x0D01FEFD, 0xFF071711, 0x12FB14FE, 0x0B091B0D);
	r0 = D(r0, s[0][0][1], 0x04ECE307, 0x05FDEB03, 0x00F5FB12, 0x0301E2F5);
	r1 = D(r1, s[0][0][1], 0xF30EFA02, 0xF00D18F6, 0x0A070EEC, 0x02090F11);
	r0 = D(r0, s[0][0][2], 0x1000FFF9, 0x07FF01F7, 0xF2FCFB09, 0x14F0ED02);
	r1 = D(r1, s[0][0][2], 0x02FCF1FE, 0x02FC0CFD, 0xF5FBF80F, 0x13FD07FF);
	r0 = D(r0, s[0][1][0], 0x0B08EB0D, 0xFBFBFC03, 0x04EAF801, 0x1313F805);
	r1 = D(r1, s[0][1][0], 0xF60D0305, 0xE8F9E0E3, 0x0A01F105, 0xE8010CE7);
	r0 = D(r0, s[0][1][1], 0x0FF0F91A, 0x3CF72615, 0xF7EF021B, 0xEE08F4FD);
	r1 = D(r1, s[0][1][1], 0xFE2BE903, 0xFA010B00, 0xDAFEFF01, 0x0EFDFCD7);
	r0 = D(r0, s[0][1][2], 0xEF0CEFED, 0x040111F3, 0x02FFF704, 0xF0FBEAF2);
	r1 = D(r1, s[0][1][2], 0xEC11F3ED, 0xFB040C05, 0x11F8FAFC, 0xE8EC0426);
	r0 = D(r0, s[0][2][0], 0xF004FCF3, 0xFDFFF2F0, 0xFBF2FA0C, 0xEAFE02F6);
	r1 = D(r1, s[0][2][0], 0xFFFDF209, 0xFF0AEA05, 0xFB01EC05, 0x0F02F70E);
	r0 = D(r0, s[0][2][1], 0x02EEF9ED, 0x0BFDF7F8, 0xF6FDF6FE, 0x2803FA06);
	r1 = D(r1, s[0][2][1], 0x0D12F505, 0x0220060D, 0x2313F3FD, 0xF914F91A);
	r0 = D(r0, s[0][2][2], 0x08EF0417, 0x03F7F709, 0xFAF7FFFC, 0x0F05FDF8);
	r1 = D(r1, s[0][2][2], 0xFD07FD02, 0xED13FCE4, 0x16040FFE, 0xFB0B04EE);
	r0 = D(r0, s[1][0][0], 0x0400FC0D, 0x0D03FB0A, 0xFB08F502, 0xFD0F1303);
	r1 = D(r1, s[1][0][0], 0xF60501F4, 0x06ECF30A, 0x03FF09F5, 0xFFEDF6F5);
	r0 = D(r0, s[1][0][1], 0xF3FE13E3, 0x020E15F9, 0x02EFFAFF, 0x0D1B1AE9);
	r1 = D(r1, s[1][0][1], 0x131508F5, 0xF1E700F9, 0x070EF90A, 0xF9F20100);
	r0 = D(r0, s[1][0][2], 0x1A18F909, 0x0902FC0B, 0x0BFDFEFD, 0x041F050C);
	r1 = D(r1, s[1][0][2], 0x0B1F01FF, 0xFD070B02, 0xF7F90C04, 0xF7090006);
	r0 = D(r0, s[1][1][0], 0xEF0C0610, 0x04101208, 0x12F404F1, 0xEDFE06F5);
	r1 = D(r1, s[1][1][0], 0x0EF6E911, 0x0304020E, 0x09FAF2F9, 0x0B070B12);
	r0 = D(r0, s[1][1][1], 0x19CA0318, 0x0900E719, 0x2806FC02, 0xEA0C08E0);
	r1 = D(r1, s[1][1][1], 0xE52BF8F3, 0xE905FBE3, 0x053402D9, 0xE60DFA0B);
	r0 = D(r0, s[1][1][2], 0x05F01100, 0x08FEFB06, 0x01E8FC09, 0x122212FC);
	r1 = D(r1, s[1][1][2], 0x000DF201, 0x1D15FAF2, 0xFD020507, 0x000909FC);
	r0 = D(r0, s[1][2][0], 0xFFFEF301, 0x16FE0B06, 0x0AF3F901, 0x0103FC05);
	r1 = D(r1, s[1][2][0], 0xFC03F90E, 0xFAFB19F9, 0xF000F404, 0xF3FC18E8);
	r0 = D(r0, s[1][2][1], 0x0C00E91E, 0x11FFEC0C, 0x02EEF505, 0xE40A12FC);
	r1 = D(r1, s[1][2][1], 0xCB0712F8, 0xF4F509E4, 0xE8F9FF04, 0xF0FE0DEA);
	r0 = D(r0, s[1][2][2], 0xF80BF701, 0xFB0407FA, 0x03F3F90D, 0xF40D0B05);
	r1 = D(r1, s[1][2][2], 0xFA0BF4FB, 0xFCF910FA, 0xF3FFF805, 0x03F10B02);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFF0816E9, 0x02FBE60C, 0xFBFD0AFA, 0xFFF5E3FD);
	r1 = D(r1, s[0][0][0], 0x0EF40306, 0x0BFCF810, 0x03EEDD05, 0x03F6F800);
	r0 = D(r0, s[0][0][1], 0x120E35FF, 0xEB01F0F9, 0xF6F025FE, 0xD107E5F9);
	r1 = D(r1, s[0][0][1], 0xE401ECFC, 0xFC08BB0C, 0xEFEADDFC, 0x0E06E7FF);
	r0 = D(r0, s[0][0][2], 0xF7E915EA, 0xEDF0F1FD, 0xF9F505F7, 0xECFAEEED);
	r1 = D(r1, s[0][0][2], 0xF9FBDAF0, 0xFAFCF104, 0x0412EB08, 0xEC080900);
	r0 = D(r0, s[0][1][0], 0x0E0A0CDA, 0xFBEE021F, 0xECF408ED, 0xF9F8DC08);
	r1 = D(r1, s[0][1][0], 0x01FCFD25, 0x051EDCED, 0xF1F3F713, 0x0908DB17);
	r0 = D(r0, s[0][1][1], 0xF80D2B0C, 0xD82ABFF0, 0xD1F311DF, 0xDDFDF509);
	r1 = D(r1, s[0][1][1], 0xF705D9FC, 0xF1F1C8FA, 0xF1DEDCFE, 0x001AE803);
	r0 = D(r0, s[0][1][2], 0xFD050607, 0x0709F5FC, 0xFCF81DFA, 0xF501ECFA);
	r1 = D(r1, s[0][1][2], 0x02EADAFB, 0x0EE3F2F3, 0xE501E8F8, 0x0A0CF1FF);
	r0 = D(r0, s[0][2][0], 0x04F325F7, 0xFAF5E803, 0xFDFD12FB, 0x13FEE107);
	r1 = D(r1, s[0][2][0], 0x0112F710, 0x12F8E907, 0x0C1ADC0F, 0xF4ECC304);
	r0 = D(r0, s[0][2][1], 0x080A1BFB, 0xF303F1F7, 0xE7FB18F3, 0xEF12D7FA);
	r1 = D(r1, s[0][2][1], 0x0C18D50B, 0x08E1EE18, 0xF819D600, 0xF6D8D503);
	r0 = D(r0, s[0][2][2], 0xF10A03F2, 0xEF13E403, 0xFA020EF5, 0xFD05E208);
	r1 = D(r1, s[0][2][2], 0xF203DEFF, 0x11F1FD09, 0xF112E303, 0x0CEEF713);
	r0 = D(r0, s[1][0][0], 0xF2F90B09, 0x021908FA, 0x140C0802, 0xEF09FD0C);
	r1 = D(r1, s[1][0][0], 0x0A06F5F8, 0xFFFEFBF9, 0xFE01FD06, 0x0DFCF8FB);
	r0 = D(r0, s[1][0][1], 0x09E800FF, 0x020E0AFE, 0x09FFFEFD, 0x210BEF04);
	r1 = D(r1, s[1][0][1], 0x0E07F302, 0xFBEA0E04, 0x011600F3, 0x16FAFF05);
	r0 = D(r0, s[1][0][2], 0xF919F9FB, 0x0101FFFC, 0xFD080A09, 0x14F4F606);
	r1 = D(r1, s[1][0][2], 0xFCFF0705, 0x06FB0202, 0x0EE4FF08, 0x0CF1F702);
	r0 = D(r0, s[1][1][0], 0x02F10901, 0xEC1DF9F2, 0x1706F1F7, 0xF907FF0D);
	r1 = D(r1, s[1][1][0], 0x0B0EEEFA, 0xF50504FE, 0x050DF413, 0xDB020C0D);
	r0 = D(r0, s[1][1][1], 0x34E70006, 0x1C05F719, 0x1A2DEDFF, 0xFD10F619);
	r1 = D(r1, s[1][1][1], 0xCBFF0D28, 0xDB120F2A, 0xF52200F2, 0xF9DE1010);
	r0 = D(r0, s[1][1][2], 0x00F7FDF2, 0xF60FFAFA, 0x0C0BFF03, 0xFB09ECFF);
	r1 = D(r1, s[1][1][2], 0xF024FD01, 0xEB1CFC0A, 0x080B010F, 0xF5F30A05);
	r0 = D(r0, s[1][2][0], 0x030E02F0, 0xFBF8F705, 0x070A041C, 0xFDF900EF);
	r1 = D(r1, s[1][2][0], 0x0BE6FCF7, 0xED03FD0D, 0x09F1FDF6, 0xF2FE0514);
	r0 = D(r0, s[1][2][1], 0x0FEF0EED, 0x08F80711, 0x0D12F410, 0x16EC0209);
	r1 = D(r1, s[1][2][1], 0xF8020E03, 0xF502F115, 0x08F10215, 0xEC23F009);
	r0 = D(r0, s[1][2][2], 0x13F90807, 0x02F102F9, 0x0DFFF70D, 0x05F504F5);
	r1 = D(r1, s[1][2][2], 0xFD06FD0A, 0xF601F6FB, 0x07FFFD09, 0xF802F9EA);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-6.102e-03, -6.369e-03, 6.035e-02, 1.318e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(4.582e-05, 1.424e-02, 1.673e-04, 8.722e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-4x8C-TEST-conv4
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
	r0 = D(r0, s[0][0][0], 0xF904FFF9, 0xFBF9FBE1, 0x090402F5, 0x01FE0400);
	r1 = D(r1, s[0][0][0], 0x050602FE, 0x06050502, 0xF8FFFCFF, 0x060DFE03);
	r0 = D(r0, s[0][0][1], 0x05FD02FF, 0x02040105, 0xFBF80101, 0xF8FF010F);
	r1 = D(r1, s[0][0][1], 0x0E0200F3, 0xF6FDFE02, 0x0E0A05FA, 0xEFFA0210);
	r0 = D(r0, s[0][0][2], 0x04F80002, 0xF7FC0208, 0x0502FF02, 0xF7FF060E);
	r1 = D(r1, s[0][0][2], 0xFD06FD01, 0x04F606ED, 0xF5EFFE0C, 0xFB020308);
	r0 = D(r0, s[0][1][0], 0x00F90300, 0x01FDF3EF, 0xF6F2010F, 0xFAF701F6);
	r1 = D(r1, s[0][1][0], 0x0304FB10, 0x0502F910, 0xFC06FA02, 0xE3F6F8FD);
	r0 = D(r0, s[0][1][1], 0x02010E0D, 0x1D0220EE, 0xDFEB1323, 0xE5EAFB03);
	r1 = D(r1, s[0][1][1], 0xDDFE020A, 0x0EFE0512, 0x331502FF, 0xF7F610FF);
	r0 = D(r0, s[0][1][2], 0xFDF2F801, 0xF601E714, 0xFE01020A, 0x1201FAFB);
	r1 = D(r1, s[0][1][2], 0x070209F9, 0xF50A0207, 0x0AFEF6F8, 0xEE02F405);
	r0 = D(r0, s[0][2][0], 0x0802080A, 0x0A01FBFB, 0x1606FE07, 0x17FD0501);
	r1 = D(r1, s[0][2][0], 0xF6FE0102, 0x00FEFC08, 0xF9040206, 0x12040401);
	r0 = D(r0, s[0][2][1], 0xF200060A, 0xFA0608E5, 0x13010617, 0xF9060A25);
	r1 = D(r1, s[0][2][1], 0x07020207, 0xFDF60D06, 0xF2F602EE, 0xCDFE0223);
	r0 = D(r0, s[0][2][2], 0x100806FA, 0x0200F900, 0x0EFDFF02, 0xF506030B);
	r1 = D(r1, s[0][2][2], 0xFF01FE08, 0xFA05F802, 0xF6050602, 0x0102F707);
	r0 = D(r0, s[1][0][0], 0xFEF70300, 0x0616FA17, 0xF2EDFF0F, 0xF4ED150A);
	r1 = D(r1, s[1][0][0], 0x00F3FBF9, 0x03F0F70A, 0x0413FBFA, 0xF3F20206);
	r0 = D(r0, s[1][0][1], 0x021406FA, 0xF6F706FC, 0x1205F6F6, 0xFD030AFD);
	r1 = D(r1, s[1][0][1], 0x060EF5FD, 0x04BF030C, 0xFAFE110E, 0xFF1905F6);
	r0 = D(r0, s[1][0][2], 0xFE09FEFA, 0x0AF502FE, 0xF7E01304, 0x02EF18FE);
	r1 = D(r1, s[1][0][2], 0x0202FE04, 0x07E50F0D, 0x1226F4F8, 0x03FE0BFA);
	r0 = D(r0, s[1][1][0], 0x03FEF305, 0xEA0EEE01, 0x0A0FEDF6, 0x1707F1F6);
	r1 = D(r1, s[1][1][0], 0xF9F400FD, 0xFBF90C00, 0xFBFEFC06, 0x0A02F506);
	r0 = D(r0, s[1][1][1], 0x0A330AD5, 0x13F5C407, 0x173626F1, 0x1E330203);
	r1 = D(r1, s[1][1][1], 0xF1FAFE11, 0xF9A409E0, 0xDDFEDECD, 0x127118D9);
	r0 = D(r0, s[1][1][2], 0xFEED0013, 0xF4F60411, 0xF5E53F07, 0xF7F43A0C);
	r1 = D(r1, s[1][1][2], 0x02000CFE, 0xF7BE32F4, 0x02EEF71F, 0xFE080C05);
	r0 = D(r0, s[1][2][0], 0x03F802F3, 0xF2F805FD, 0xFCEE15FA, 0xFAF8020A);
	r1 = D(r1, s[1][2][0], 0x0A09FF07, 0x00F40A09, 0x01FE03F2, 0x01DB0E02);
	r0 = D(r0, s[1][2][1], 0xF3060BEE, 0x0AFEEF0C, 0x0EDD0BE5, 0x0FD939D5);
	r1 = D(r1, s[1][2][1], 0x04FD0600, 0x0CF5F6FE, 0xF619EF1A, 0x1BF80FCD);
	r0 = D(r0, s[1][2][2], 0xFE011210, 0x00080809, 0xEFEC0A12, 0xEFE12301);
	r1 = D(r1, s[1][2][2], 0x01F606F6, 0xFAD506FF, 0x0A1BEEFB, 0xF1040E06);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x070402F6, 0xEEEBEB09, 0xF6FD15F9, 0xFB0111F6);
	r1 = D(r1, s[0][0][0], 0xFBFA0010, 0xFB00FC02, 0x0601F200, 0x021206EE);
	r0 = D(r0, s[0][0][1], 0x120CFDFF, 0x0A090A0F, 0xE707EF12, 0xFE1115FC);
	r1 = D(r1, s[0][0][1], 0xF902F806, 0xFEC6F807, 0x23020E02, 0xE70F0AFE);
	r0 = D(r0, s[0][0][2], 0x09FE05FD, 0xFE06F505, 0xF204F702, 0xF40A0A01);
	r1 = D(r1, s[0][0][2], 0x0201FC06, 0xEBF0FE0E, 0x160A1110, 0xF71107F9);
	r0 = D(r0, s[0][1][0], 0xFBFAF9E3, 0xFBE8D928, 0xF4FEEB07, 0xEC020008);
	r1 = D(r1, s[0][1][0], 0x02FA07FA, 0x0EF2E8FD, 0x1201ECF8, 0xDAF2D5F1);
	r0 = D(r0, s[0][1][1], 0x2BEFF752, 0xF8FB31FA, 0x15FF1AE4, 0x06F2B812);
	r1 = D(r1, s[0][1][1], 0xD4E60AFC, 0xEAF2D1B1, 0x17FA1817, 0x2BFDF617);
	r0 = D(r0, s[0][1][2], 0xEA120606, 0xED00E908, 0xE90DEEFB, 0xDEF5D703);
	r1 = D(r1, s[0][1][2], 0xF6F6FA06, 0xFF03E901, 0x0F02CF01, 0xD702FA04);
	r0 = D(r0, s[0][2][0], 0x09FAFFFD, 0x08FAE60D, 0x0100FEFD, 0xF5FA0AFB);
	r1 = D(r1, s[0][2][0], 0xFFFEFF0B, 0xF909FB0A, 0x0BF9FF0A, 0xFA0FE7F5);
	r0 = D(r0, s[0][2][1], 0xFFEA1505, 0xF8FAFE08, 0x1102EC06, 0x02081807);
	r1 = D(r1, s[0][2][1], 0x02F6FE11, 0x07F10309, 0xF3FE00F6, 0x060C2DF8);
	r0 = D(r0, s[0][2][2], 0x020DED05, 0xFC07FCFF, 0xFFFDFA03, 0x0302F40A);
	r1 = D(r1, s[0][2][2], 0x0A02FF03, 0x02F30903, 0xFF040EFB, 0x0206EFFE);
	r0 = D(r0, s[1][0][0], 0xFD000A12, 0x02130A03, 0x06FD0C04, 0x05F90510);
	r1 = D(r1, s[1][0][0], 0xFE02FAF6, 0xFF01F3F2, 0xF6060103, 0xF6FF040A);
	r0 = D(r0, s[1][0][1], 0xFEF80606, 0x01F910E4, 0xEE0A0BFD, 0x00E80602);
	r1 = D(r1, s[1][0][1], 0xFF16FA02, 0xFE09FF03, 0x12F6F801, 0xFDFCFBF6);
	r0 = D(r0, s[1][0][2], 0x02F60302, 0xFFF50206, 0xFC12FEFE, 0x01F9FE00);
	r1 = D(r1, s[1][0][2], 0xF907FFF8, 0x0514F9FE, 0x00E1FCFA, 0x03FFF802);
	r0 = D(r0, s[1][1][0], 0x0B0CF801, 0x032805E1, 0x05FD00F7, 0x0DF6FB01);
	r1 = D(r1, s[1][1][0], 0xF6FF050D, 0xF00A0AFC, 0xF80E06FA, 0xF62003E3);
	r0 = D(r0, s[1][1][1], 0xFEF6F20E, 0xFEF4FAE9, 0xE817EC09, 0xEC1402F9);
	r1 = D(r1, s[1][1][1], 0xF616020E, 0x0C04F117, 0x0DFBF207, 0xF60304F4);
	r0 = D(r0, s[1][1][2], 0x0A0502FE, 0xFC03FE0A, 0xFC07000A, 0x0D17F907);
	r1 = D(r1, s[1][1][2], 0xFD0206FE, 0xF6FAFD12, 0x09EC0202, 0x0510FEFF);
	r0 = D(r0, s[1][2][0], 0xFFFCF6FE, 0xFA0D08F9, 0xFDF6040B, 0x03FB0210);
	r1 = D(r1, s[1][2][0], 0xFDF9FEF8, 0xF80D02F5, 0xFC0CFCF2, 0x0303FB0D);
	r0 = D(r0, s[1][2][1], 0x0606F601, 0x0EF6F7FC, 0xF4FCF4FC, 0xEA0BEBF7);
	r1 = D(r1, s[1][2][1], 0x0AFE0502, 0x05F8FEFB, 0x0C030B03, 0xF6F7ECFA);
	r0 = D(r0, s[1][2][2], 0xFDFEFD06, 0xFFFE07FE, 0x060D0500, 0xF70B0306);
	r1 = D(r1, s[1][2][2], 0xFBF60502, 0x06010BFE, 0xFCF7FEFF, 0xFA060604);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(1.381e-02, -2.388e-03, 1.898e-02, 1.800e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0));
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-2.185e-04, -1.242e-03, -8.751e-03, 1.767e-03);
	imageStore(out_image, opos + ivec2(1, 0), vec4(f1));
}

//!DESC CuNNy-4x8C-TEST-out-shuffle
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
#define l0(x, y) conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv4_pt)
#define l1(x, y) conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv4_pt)
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
	r0 = D(r0, s[0][0][0], 0x01030306, 0x0B0106FA, 0xFFFB0503, 0x06FC0102);
	r0 = D(r0, s[0][0][1], 0xFAF51808, 0xFAEFF71E, 0x02FBFF05, 0xFDF6050A);
	r0 = D(r0, s[0][0][2], 0x0108F9FF, 0xFB07FEFE, 0x04020200, 0x03000104);
	r0 = D(r0, s[0][1][0], 0x0A0AF2EB, 0x0D090AE6, 0x020DF605, 0x0B0A0AEA);
	r0 = D(r0, s[0][1][1], 0xF1FD5304, 0xF303BD0B, 0xE7F93E06, 0xEE00CA2B);
	r0 = D(r0, s[0][1][2], 0x03F3DE06, 0x01F60005, 0x03FDE803, 0xF8FEFAFB);
	r0 = D(r0, s[0][2][0], 0xFFFF00FC, 0x00010002, 0x0705FBE6, 0x060405F7);
	r0 = D(r0, s[0][2][1], 0x0503FB03, 0x03FBF7FA, 0x01052D0B, 0xFEFBDEF5);
	r0 = D(r0, s[0][2][2], 0x000303FE, 0x03040302, 0xFEFBF302, 0x04010906);
	r0 = D(r0, s[1][0][0], 0x12F3FDFF, 0xFEFAFE03, 0xFFFFFCFA, 0xFD03FD02);
	r0 = D(r0, s[1][0][1], 0x0721FED2, 0x0F1BF6FB, 0x06FCFBFB, 0xFFFBF4F5);
	r0 = D(r0, s[1][0][2], 0xFDFB00FE, 0x0002FF0A, 0xFFFDFE00, 0x0700FC00);
	r0 = D(r0, s[1][1][0], 0x19050C12, 0x06ED090F, 0xEC180505, 0xF7F30507);
	r0 = D(r0, s[1][1][1], 0x2997FFCE, 0x18D2FF31, 0xDD040AB3, 0xB84E051A);
	r0 = D(r0, s[1][1][2], 0x08120502, 0x23F90603, 0xFC0903FC, 0x08F60612);
	r0 = D(r0, s[1][2][0], 0xFB00FC04, 0x020000FD, 0xFFFF0410, 0xF8FA0508);
	r0 = D(r0, s[1][2][1], 0xFB0BFD01, 0xF405FB0B, 0x09F2F7EF, 0x14ECF820);
	r0 = D(r0, s[1][2][2], 0x01FB0002, 0xFF020001, 0x04050507, 0xFB1C04FB);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xF81104F2, 0xFB0901F9, 0xFFFBFCFE, 0xFE01FDFC);
	r0 = D(r0, s[0][0][1], 0x1FFE0313, 0x0EFC0716, 0x0402050C, 0x03F70412);
	r0 = D(r0, s[0][0][2], 0xFC04FBF0, 0x0802FCEE, 0xFE01FFFE, 0xFFFD02FE);
	r0 = D(r0, s[0][1][0], 0x06E0FC05, 0xFF29FC01, 0xFA1E0BF2, 0xFB2204FB);
	r0 = D(r0, s[0][1][1], 0xFB07EB01, 0x02A5EB0B, 0x1D0BF8FD, 0x0AF0FFFB);
	r0 = D(r0, s[0][1][2], 0x04F60C00, 0x05030AFB, 0x030201F8, 0x1509FEF6);
	r0 = D(r0, s[0][2][0], 0x0019FB04, 0xFE070000, 0x0604F10E, 0x0021FB01);
	r0 = D(r0, s[0][2][1], 0xFC030600, 0x030BFF01, 0xF207F905, 0x03D3F00E);
	r0 = D(r0, s[0][2][2], 0xFF06FC04, 0xFB02FE06, 0x01FE05FF, 0xF90105FF);
	r0 = D(r0, s[1][0][0], 0x06FB0021, 0x00F9FE08, 0x010202F3, 0x010101FB);
	r0 = D(r0, s[1][0][1], 0xDB05F1F7, 0xF10DF50F, 0xFF03FBD6, 0xFF03FBCE);
	r0 = D(r0, s[1][0][2], 0x06FE0603, 0xFFFF04F7, 0x01FD0209, 0x04020300);
	r0 = D(r0, s[1][1][0], 0xFFEB19EE, 0xFBE30505, 0x0DFA090C, 0xFDE6FFFD);
	r0 = D(r0, s[1][1][1], 0xE4132BB6, 0xFF0F49A6, 0xAD060C7D, 0xEF162643);
	r0 = D(r0, s[1][1][2], 0xF303F50D, 0xE901F301, 0xFE02FBFB, 0xDDFAF437);
	r0 = D(r0, s[1][2][0], 0xFD0302F6, 0x0001FEFC, 0xF6ED10FA, 0xFCF604F8);
	r0 = D(r0, s[1][2][1], 0x03F8F717, 0xFEFFFC0E, 0x120B05E7, 0xFF041300);
	r0 = D(r0, s[1][2][2], 0x02FF03F9, 0x05FBFF05, 0xF801FD06, 0x0700FBFA);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(3.023e-04, -4.466e-04, -3.621e-04, -1.232e-03);
	f0 = tanh(f0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(f0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(f0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(f0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

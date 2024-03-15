// CuNNy 8x4C DS
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

//!DESC CuNNy-8x4C-DS-EASU
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


//!DESC CuNNy-8x4C-DS-in
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
	r0 += V4(-3.012e-01, -4.698e-02, -3.840e-02, -5.659e-02) * s[0][0][0];
	r0 += V4(-1.608e-01, -3.623e-01, -4.953e-01, -5.670e-03) * s[0][1][0];
	r0 += V4(-9.165e-02, -1.716e-01, -2.201e-01, 5.303e-02) * s[0][2][0];
	r0 += V4(-2.894e-02, -2.209e-02, -2.482e-02, 1.236e-01) * s[1][0][0];
	r0 += V4(7.987e-01, 6.305e-01, 5.987e-02, -2.308e-02) * s[1][1][0];
	r0 += V4(-1.039e-02, -1.256e-01, -5.661e-02, -4.220e-02) * s[1][2][0];
	r0 += V4(-1.775e-02, 4.311e-02, 1.698e-02, -2.190e-01) * s[2][0][0];
	r0 += V4(-4.382e-02, -2.217e-03, -2.824e-02, 2.466e-01) * s[2][1][0];
	r0 += V4(-3.721e-02, 1.843e-02, 4.113e-02, -1.616e-01) * s[2][2][0];
	r0 += V4(-1.879e-03, 4.289e-02, 4.405e-02, 9.725e-04);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv1
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
	r0 += M4(5.124e-02, 5.995e-02, -5.943e-02, -5.524e-03, -1.316e-01, -1.595e-01, 4.131e-01, 1.790e-01, -1.703e-03, 1.389e-01, -2.306e-01, 2.515e-01, 3.805e-01, -3.968e-01, 1.382e-01, -1.819e-01) * s[0][0][0];
	r0 += M4(4.421e-02, 1.510e-01, -4.694e-02, -6.483e-02, -1.278e-01, -3.522e-01, 3.280e-01, 1.144e-01, -9.109e-02, 6.066e-02, -1.081e-01, -9.294e-02, -1.381e-02, -6.636e-02, 1.703e-02, -5.497e-02) * s[0][0][1];
	r0 += M4(2.001e-01, 5.858e-03, -2.201e-01, 1.516e-02, -1.318e-01, 1.655e-01, 1.051e-01, 7.259e-02, 3.415e-02, -1.882e-01, -8.081e-02, 2.195e-02, 4.396e-02, 4.288e-01, 1.009e-01, -1.123e-01) * s[0][1][0];
	r0 += M4(1.078e-01, 1.096e-02, -1.735e-01, 1.400e-01, -7.214e-02, 7.352e-03, -2.324e-01, -4.396e-02, 1.158e-01, -8.977e-02, -6.614e-02, -2.623e-01, 5.921e-02, 1.440e-01, 1.738e-01, -2.116e-01) * s[0][1][1];
	r0 += M4(1.868e-01, -7.043e-02, -1.847e-01, 4.195e-03, -5.337e-02, 9.300e-02, 1.741e-01, -7.499e-02, -1.065e-02, 4.179e-01, -9.114e-02, -9.529e-02, 1.092e-01, -2.554e-01, 5.023e-01, 4.906e-01) * s[0][2][0];
	r0 += M4(1.057e-01, -3.028e-01, -1.606e-01, 1.219e-01, 4.090e-03, 2.201e-01, 1.510e-01, -9.667e-02, -9.582e-02, -6.961e-02, -1.094e-03, 1.431e-01, -1.595e-01, 1.075e-01, -1.780e-01, 2.611e-01) * s[0][2][1];
	r0 += M4(-2.291e-01, -5.578e-02, 1.746e-01, 1.059e-01, 1.843e-02, -4.363e-01, -2.782e-01, 3.397e-01, 6.780e-02, -2.960e-01, -8.329e-01, -7.635e-01, 5.975e-02, -9.359e-02, 1.094e-01, -7.681e-02) * s[1][0][0];
	r0 += M4(-1.119e-01, -1.711e-01, 1.043e-01, -7.239e-02, 1.969e-02, -4.943e-01, -2.360e-01, 4.786e-01, 1.845e-01, -1.201e-01, -1.962e-01, -1.277e-01, 2.502e-02, 7.146e-02, -1.256e-02, 1.216e-01) * s[1][0][1];
	r0 += M4(3.077e-02, 7.629e-01, 1.001e+00, 1.228e-01, 2.627e-02, 4.947e-01, 6.314e-02, 2.492e-01, 2.202e-01, 7.248e-01, 7.920e-01, 7.267e-01, -4.048e-01, 8.328e-03, -9.083e-02, -6.854e-01) * s[1][1][0];
	r0 += M4(-1.792e-01, 1.152e+00, -4.096e-02, -2.907e-02, 1.945e-01, 8.293e-01, 2.608e-01, 2.816e-01, -4.480e-02, -8.396e-02, -1.435e-01, -4.547e-02, -1.650e-01, 1.029e-01, -1.930e-01, -1.317e-01) * s[1][1][1];
	r0 += M4(1.233e-01, 9.115e-03, -2.542e-01, -3.082e-01, -2.863e-01, -1.323e-01, -3.526e-02, -3.509e-01, 3.678e-01, 1.315e-01, 3.881e-01, 1.760e-01, 5.328e-01, 3.881e-01, 1.856e-02, 8.171e-02) * s[1][2][0];
	r0 += M4(3.764e-02, -3.767e-01, -2.145e-01, -2.264e-01, -1.699e-01, -9.206e-02, -9.286e-02, -2.766e-01, 2.322e-01, -4.916e-02, -8.024e-02, 2.401e-01, -2.431e-01, -1.427e-01, -4.187e-02, 3.678e-03) * s[1][2][1];
	r0 += M4(1.641e-02, -2.621e-01, -1.050e-01, -3.773e-02, 2.653e-02, -3.183e-01, -7.191e-02, 1.701e-01, 6.939e-01, -1.142e+00, 7.093e-01, -2.264e+00, 4.737e-01, 1.220e-01, -2.902e-02, -2.031e-01) * s[2][0][0];
	r0 += M4(-1.199e-01, -7.861e-03, -1.001e-02, 1.156e-01, -2.091e-02, -1.706e-01, 8.709e-02, -2.691e-02, 2.304e-01, -2.286e-01, -9.176e-03, -2.744e-03, -1.070e-02, -6.045e-02, 4.228e-02, -1.443e-01) * s[2][0][1];
	r0 += M4(-1.179e-01, -8.889e-03, 5.755e-02, -6.840e-01, -6.745e-02, -2.434e-01, -3.863e-01, -7.594e-01, 5.277e-01, -1.157e+00, 2.028e+00, 1.828e+00, 2.353e-01, -4.523e-01, 3.500e-01, -6.787e-02) * s[2][1][0];
	r0 += M4(-8.172e-01, -7.029e-01, 2.772e-01, 1.381e-01, 2.542e-01, -9.482e-02, -3.286e-01, -7.989e-01, -8.249e-03, -2.256e-01, -8.436e-04, -3.074e-02, 1.038e-01, 7.148e-02, -7.394e-02, 2.325e-01) * s[2][1][1];
	r0 += M4(-2.700e-03, -1.790e-01, -1.599e-01, -1.722e-01, -1.467e-01, -7.666e-02, 1.523e-01, -1.614e-02, 3.463e-01, -6.153e-01, 2.701e-01, 1.023e+00, 2.798e-01, -5.813e-02, 1.812e-01, 3.271e-01) * s[2][2][0];
	r0 += M4(-2.015e-01, -1.742e-01, -9.644e-02, -2.270e-01, -9.629e-02, 5.789e-02, 7.652e-02, -1.104e-02, 6.430e-02, 1.376e-01, -9.235e-03, 1.318e-02, 4.095e-02, 4.748e-02, 7.950e-02, 1.462e-01) * s[2][2][1];
	r0 += V4(-4.146e-02, -1.002e-01, -4.342e-01, -3.117e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv2
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
	r0 += M4(4.095e-02, 1.396e-01, 9.324e-02, 1.498e+00, 1.671e-01, 8.182e-02, -2.398e-03, -2.534e-02, -9.333e-03, -3.757e-01, 2.183e-01, -2.097e-01, -6.747e-01, 7.042e-02, 2.711e-01, 1.538e-01) * s[0][0][0];
	r0 += M4(9.716e-02, -2.056e-01, 1.512e-01, -5.173e-02, 1.326e-01, 5.943e-02, 9.154e-02, -5.216e-02, 1.559e-01, -3.916e-02, -6.067e-02, -8.262e-02, -2.324e-02, -3.526e-02, 2.035e-02, 1.258e-01) * s[0][0][1];
	r0 += M4(9.212e-01, -7.801e-01, 3.790e-01, 2.299e+00, 9.572e-02, -5.458e-01, -1.010e-01, -2.704e-01, -4.194e-01, -5.466e-01, 1.446e-01, -2.128e-01, 5.610e-02, -9.259e-01, 5.254e-01, 4.350e-02) * s[0][1][0];
	r0 += M4(1.692e-01, -4.199e-02, -2.009e-01, 3.157e-02, -2.195e-02, -6.033e-01, -6.242e-02, -2.862e-01, -1.600e-01, -2.010e-01, -7.239e-03, 3.862e-02, 5.054e-01, -2.601e-01, -1.310e-01, -8.628e-03) * s[0][1][1];
	r0 += M4(-1.064e-01, -5.848e-01, 2.579e-01, 3.844e-01, -1.220e-01, -2.073e-01, -1.883e-02, -1.420e-01, -8.127e-02, 1.106e-01, 6.210e-02, 1.333e-01, -4.748e-01, -2.395e-01, 1.237e-01, 6.593e-02) * s[0][2][0];
	r0 += M4(-4.972e-02, 1.387e-01, -1.350e-01, 1.042e-01, -2.272e-01, -9.888e-02, 3.069e-02, -4.501e-02, 2.376e-01, 3.104e-01, 6.899e-02, 2.222e-01, 1.093e-01, -3.614e-01, -3.342e-02, -1.379e-01) * s[0][2][1];
	r0 += M4(-8.937e-01, 1.745e-02, 7.087e-01, 4.084e-01, -6.983e-02, -5.798e-02, 3.025e-01, -2.233e-02, 1.800e-01, 9.968e-02, -9.100e-02, -1.223e-01, 4.934e-02, 1.163e-01, -4.791e-01, 7.703e-02) * s[1][0][0];
	r0 += M4(-1.489e-01, -7.544e-02, 3.292e-01, 5.030e-02, -7.110e-02, -8.866e-02, 3.523e-01, 2.946e-01, 1.481e-02, -1.093e-01, 8.560e-02, 6.058e-02, 2.069e-01, -1.301e-01, -5.164e-02, 2.417e-02) * s[1][0][1];
	r0 += M4(-1.274e+00, 3.983e-02, 1.215e+00, 1.052e+00, -5.064e-01, 3.970e-02, 3.828e-01, -3.145e-01, -1.144e+00, 1.793e-01, -3.075e-01, -4.603e-01, -1.329e-02, -2.105e-03, 7.477e-02, 6.353e-01) * s[1][1][0];
	r0 += M4(-1.881e-01, -1.331e-01, 1.223e-01, -2.724e-02, 9.268e-02, 3.348e-01, 1.863e-01, -3.981e-01, -5.020e-01, 5.645e-01, -1.705e-01, 2.096e-01, -8.185e-02, -1.692e-01, -3.690e-01, -2.146e-01) * s[1][1][1];
	r0 += M4(-5.042e-01, -2.608e-01, 1.843e-01, 5.450e-01, 5.662e-02, 4.822e-02, 6.057e-02, -8.471e-02, -5.215e-02, -1.063e-02, -2.401e-01, -4.243e-01, -2.586e-02, 2.103e-01, 3.863e-02, 1.156e-01) * s[1][2][0];
	r0 += M4(2.510e-02, -1.377e-01, -2.675e-02, 2.246e-01, 2.828e-01, 2.524e-01, -1.165e-02, -8.520e-02, 1.753e-01, -1.878e-01, 1.269e-03, 1.234e-01, -1.607e-01, -1.018e-01, -1.490e-01, -2.906e-01) * s[1][2][1];
	r0 += M4(-3.363e-01, 2.227e-01, -6.905e-01, -6.434e-02, 2.813e-03, -6.191e-02, -2.822e-01, -2.319e-02, 7.881e-02, -9.349e-02, -3.903e-01, -1.443e-01, -2.017e-02, 1.431e-01, 3.340e-02, -9.952e-02) * s[2][0][0];
	r0 += M4(9.261e-03, 4.054e-03, 1.886e-01, 5.071e-02, -1.183e-01, -3.214e-02, -3.095e-01, -4.491e-03, -2.109e-02, -8.447e-02, -2.881e-01, -8.888e-02, -3.479e-04, 2.160e-02, 1.407e-01, 2.660e-02) * s[2][0][1];
	r0 += M4(9.922e-02, -1.096e-01, 1.311e+00, 5.119e-01, 1.296e-01, 8.517e-02, 2.674e-01, 2.903e-02, -4.155e-02, -7.180e-02, -5.925e-02, -2.477e-01, -1.340e-02, -5.649e-02, 1.194e-01, 5.011e-02) * s[2][1][0];
	r0 += M4(2.108e-01, -7.631e-03, 1.657e-01, 1.325e-01, 1.117e-01, 1.175e-02, 2.787e-01, -4.090e-02, -7.569e-03, -5.407e-03, 1.077e-02, 1.049e-02, 3.429e-02, -4.966e-02, 2.026e-01, 1.259e-01) * s[2][1][1];
	r0 += M4(-4.254e-01, -1.466e-01, -1.546e-02, 6.513e-02, -7.874e-02, -4.549e-02, 9.796e-03, 1.253e-02, 1.296e-01, 2.368e-01, 4.131e-01, -1.719e-01, 8.084e-03, 2.624e-02, -2.302e-02, 8.615e-02) * s[2][2][0];
	r0 += M4(-1.499e-01, 6.971e-02, -1.820e-02, 1.524e-02, -4.777e-02, 1.212e-02, 3.691e-02, -1.156e-02, 1.637e-02, 1.074e-01, 7.411e-02, -1.795e-01, -8.061e-02, 1.246e-02, -3.412e-02, 1.103e-01) * s[2][2][1];
	r0 += V4(1.569e-01, -3.797e-02, 4.632e-02, 5.942e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv3
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
	r0 += M4(-1.134e-02, -1.339e-01, 1.890e-01, -9.392e-02, -4.775e-02, -3.957e-02, -1.609e-01, 3.599e-02, 9.746e-02, -1.569e-01, 1.231e-01, 1.585e-02, -3.309e-02, 5.123e-02, 4.320e-01, -2.424e-02) * s[0][0][0];
	r0 += M4(2.651e-02, -2.419e-01, 1.022e-01, 2.337e-02, -1.112e-01, -7.138e-02, -8.736e-02, -4.337e-02, 5.788e-02, -1.100e-01, 3.851e-02, 2.075e-01, 1.289e-01, 1.100e-01, 4.404e-01, 1.186e-01) * s[0][0][1];
	r0 += M4(1.298e-01, -6.143e-02, -4.974e-02, -2.408e-02, -4.188e-02, -4.365e-01, 1.064e-01, -6.827e-02, -3.165e-01, 4.510e-02, 5.805e-01, -3.208e-02, 1.240e-01, 4.598e-01, -4.108e-01, -1.505e-01) * s[0][1][0];
	r0 += M4(-1.017e-02, -9.009e-03, -3.640e-02, 1.583e-01, -7.245e-02, -2.169e-01, 6.660e-02, 2.298e-02, -4.269e-01, -2.149e-04, -7.777e-01, -4.654e-01, 3.426e-01, 3.297e-01, -4.565e-01, 8.780e-02) * s[0][1][1];
	r0 += M4(-4.373e-02, 5.013e-03, -7.239e-02, -1.313e-01, -4.890e-02, 6.663e-02, -4.954e-02, 7.993e-02, -1.629e-02, 4.623e-01, -1.099e-01, 1.888e-01, -2.010e-01, -2.488e-01, 1.741e-01, 1.302e-01) * s[0][2][0];
	r0 += M4(1.866e-03, 3.647e-02, -9.927e-03, 6.776e-02, -6.662e-02, 1.339e-01, -2.372e-02, -1.083e-01, 6.387e-01, 2.545e-01, 1.193e-01, -4.289e-01, -1.577e-01, -3.104e-01, 9.260e-02, 5.535e-02) * s[0][2][1];
	r0 += M4(-3.152e-01, 1.706e-02, 3.654e-01, -1.037e-01, -1.587e-01, -2.703e-01, -6.685e-01, -6.919e-02, -2.675e-01, -1.048e-01, -1.110e-01, 5.129e-02, 4.968e-01, 5.259e-01, 1.299e+00, 4.426e-02) * s[1][0][0];
	r0 += M4(-2.918e-01, -9.345e-02, 3.168e-01, 1.155e-01, -6.819e-02, -3.076e-01, -1.454e-02, -1.236e-02, -1.817e-01, 1.155e-01, -1.675e-01, -1.567e-01, 1.905e-01, 1.078e-01, 2.710e-01, 2.391e-01) * s[1][0][1];
	r0 += M4(2.077e-01, -3.047e-01, -4.563e-01, -8.788e-02, -3.705e-01, -2.914e-02, 2.777e-01, 8.685e-01, -3.689e-01, -2.630e-01, 2.058e-01, 1.084e-01, 1.108e+00, 4.307e-01, 6.619e-01, -5.706e-01) * s[1][1][0];
	r0 += M4(3.003e-02, 1.346e-01, -6.856e-01, 3.315e-01, -1.923e-01, -1.880e-01, 3.105e-01, 2.102e-01, 3.996e-01, -2.644e-01, 7.507e-02, 1.898e-01, 5.300e-01, 6.707e-02, 1.393e-01, 3.930e-02) * s[1][1][1];
	r0 += M4(-1.773e-01, 2.436e-01, -1.078e-01, 7.370e-03, -6.579e-02, 1.314e-01, 1.278e-01, 8.562e-02, 1.304e-01, 4.007e-02, -1.962e-02, -8.140e-02, -3.733e-01, 1.398e-01, -1.178e-02, 4.670e-01) * s[1][2][0];
	r0 += M4(-2.137e-01, 8.592e-02, 5.387e-02, 1.025e-01, 2.799e-02, 2.364e-01, 1.782e-01, -7.392e-02, 4.131e-01, -2.130e-01, -1.849e-01, -3.291e-01, -1.282e-01, 7.407e-02, -1.763e-01, 2.790e-01) * s[1][2][1];
	r0 += M4(-4.821e-02, 5.525e-02, 5.091e-02, 5.088e-02, 1.781e-01, -1.872e-01, 3.002e-01, 5.042e-03, 1.768e-03, -1.155e-02, 6.942e-02, 4.091e-02, -3.187e-01, 4.208e-01, 3.249e-01, -1.451e-01) * s[2][0][0];
	r0 += M4(5.125e-02, 1.267e-01, 8.140e-02, -2.381e-02, 2.658e-01, -1.258e-01, 1.111e-01, -3.716e-02, 6.729e-03, -1.630e-01, 9.254e-02, 1.059e-01, -3.884e-01, 2.253e-01, -1.301e-01, -5.406e-03) * s[2][0][1];
	r0 += M4(-5.079e-01, 1.704e-01, -1.067e-01, 3.236e-02, -2.337e-02, 7.606e-01, -3.780e-01, -9.291e-02, 1.733e-01, -8.410e-02, 1.437e-01, -8.569e-02, 2.684e-01, 1.603e-01, -7.057e-02, 2.722e-01) * s[2][1][0];
	r0 += M4(-6.325e-01, 2.107e-01, 1.160e-02, 1.185e-01, 6.696e-01, 2.745e-01, 1.913e-01, -7.911e-03, 3.999e-02, -6.282e-02, 8.700e-03, -2.368e-02, -1.346e-01, -6.008e-02, -2.160e-01, 1.116e-01) * s[2][1][1];
	r0 += M4(-1.351e-01, 3.247e-02, -4.167e-02, 2.320e-02, 6.989e-02, -1.050e-01, 2.313e-02, -2.604e-02, -6.025e-02, 3.947e-02, -5.115e-02, -2.125e-02, -4.832e-02, 9.057e-02, 5.329e-02, -1.021e-01) * s[2][2][0];
	r0 += M4(-4.815e-02, -1.803e-01, 1.150e-01, 7.637e-03, 1.362e-01, 1.713e-01, -5.251e-02, 1.778e-02, 5.865e-03, -1.529e-01, -1.797e-02, -1.308e-01, -6.021e-02, -2.046e-01, 1.138e-01, -8.235e-02) * s[2][2][1];
	r0 += V4(2.845e-01, 7.986e-02, 3.558e-02, 4.752e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv4
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
	r0 += M4(-1.431e-01, 2.217e-01, 1.465e-01, 3.085e-02, -1.386e-02, 1.452e-01, 2.311e-03, -1.123e-02, 1.223e-02, -4.405e-02, -8.324e-02, -2.432e-02, 6.519e-02, 1.222e-01, -2.808e-02, -3.459e-02) * s[0][0][0];
	r0 += M4(3.727e-02, 4.151e-02, -1.895e-01, -1.191e-01, 4.107e-02, -1.143e-01, 1.852e-01, 1.392e-02, 8.390e-02, -2.911e-01, 5.633e-03, 4.975e-03, 2.205e-01, -2.146e-02, 1.666e-01, 5.907e-02) * s[0][0][1];
	r0 += M4(-6.885e-01, -9.072e-02, -4.819e-01, 2.818e-01, 9.298e-02, 4.404e-02, 5.108e-02, -2.146e-01, 1.265e-01, 8.807e-02, 2.734e-02, 1.071e-01, 1.343e-01, 9.615e-03, -9.767e-03, 7.935e-02) * s[0][1][0];
	r0 += M4(-2.991e-01, -1.204e-01, -7.642e-01, -2.920e-01, 1.536e-01, -9.887e-02, 4.699e-01, -1.676e-02, 3.615e-01, -1.778e-01, 2.549e-01, -3.005e-01, 2.553e-01, -1.760e-01, -2.947e-01, 3.694e-02) * s[0][1][1];
	r0 += M4(-2.163e-01, 1.548e-01, -1.905e-01, 5.425e-02, -4.762e-02, 5.257e-03, -2.529e-01, 1.324e-01, 3.244e-02, 2.023e-01, 1.501e-01, 4.177e-02, -9.543e-02, -1.454e-01, -1.098e-01, -1.003e-01) * s[0][2][0];
	r0 += M4(1.278e-01, 2.856e-01, -2.383e-01, -2.686e-01, -1.052e-02, 4.537e-02, 5.456e-01, 1.193e-01, 3.206e-01, -1.056e-01, 3.135e-01, -1.414e-01, 3.197e-01, 1.707e-01, 1.098e-01, 3.194e-01) * s[0][2][1];
	r0 += M4(-1.458e-01, 1.849e-01, 3.918e-01, 1.757e-01, 1.850e-01, 2.107e-01, -2.398e-01, -1.767e-02, -4.872e-02, -3.812e-02, -6.492e-02, 1.049e-02, -9.167e-02, -5.503e-02, 1.217e-01, -2.692e-02) * s[1][0][0];
	r0 += M4(-6.535e-02, 2.231e-01, 9.597e-02, -1.050e-01, 1.378e-02, 2.089e-01, -4.183e-02, 1.897e-01, -1.001e-01, -1.485e-01, -1.204e-01, 2.227e-02, 8.356e-02, -7.729e-01, 4.314e-01, 7.066e-01) * s[1][0][1];
	r0 += M4(1.248e-01, -3.488e-01, 1.271e-01, 7.404e-01, 4.536e-01, -5.619e-01, -4.053e-01, 9.304e-02, -2.349e-01, -2.143e-01, 1.580e-01, -1.220e-01, -5.464e-01, 3.760e-01, -1.453e-01, 4.012e-01) * s[1][1][0];
	r0 += M4(4.198e-01, -1.891e-01, 4.300e-03, 2.983e-01, 4.566e-01, -1.496e-01, 2.428e-01, 2.356e-01, 7.897e-03, -5.311e-01, -3.976e-01, -8.836e-01, 2.771e-01, -1.974e-01, -8.554e-01, 1.223e+00) * s[1][1][1];
	r0 += M4(-2.458e-01, 8.031e-02, -4.729e-01, 6.350e-02, 5.844e-02, -3.701e-01, -5.147e-02, 3.746e-02, 2.024e-01, -1.535e-01, 4.091e-01, 6.349e-01, 1.972e-01, 3.055e-01, -4.384e-02, -1.063e-01) * s[1][2][0];
	r0 += M4(-1.757e-01, 2.965e-01, -3.730e-01, -4.234e-03, 4.057e-02, -1.453e-01, 1.910e-01, 4.073e-02, 3.346e-01, -2.625e-01, -8.551e-02, 3.656e-03, 3.146e-01, 2.345e-01, -2.515e-01, 5.251e-01) * s[1][2][1];
	r0 += M4(-9.324e-02, -2.052e-01, -2.846e-02, -3.432e-02, -3.051e-02, 7.707e-03, 6.761e-02, -8.844e-02, 7.796e-02, -2.507e-02, 5.416e-02, -5.790e-03, -1.047e-02, -4.806e-02, -4.060e-03, -1.684e-01) * s[2][0][0];
	r0 += M4(-7.711e-02, 9.311e-02, -3.219e-02, -5.551e-02, -6.246e-02, -8.788e-02, 1.176e-01, 2.216e-02, 6.913e-02, -1.204e-01, 1.519e-01, 4.862e-02, 1.256e-01, -8.798e-01, 4.168e-02, 1.939e-01) * s[2][0][1];
	r0 += M4(2.995e-01, -2.506e-01, 1.524e-01, -1.008e-01, 1.066e-01, 9.087e-02, -1.199e-01, 2.013e-03, 1.322e-02, 1.598e-01, 4.668e-02, 3.270e-02, -3.013e-02, -2.591e-01, 2.447e-01, 6.892e-02) * s[2][1][0];
	r0 += M4(3.554e-02, 1.234e-01, 1.331e-01, -1.074e-02, 1.614e-01, 3.227e-02, 1.764e-01, -1.594e-02, -5.523e-02, 4.639e-01, -5.009e-02, -1.689e-01, 1.001e+00, -5.507e-01, -3.189e-01, 1.366e+00) * s[2][1][1];
	r0 += M4(-1.487e-01, 3.601e-02, -9.175e-02, 3.409e-02, 1.568e-02, -3.370e-03, -9.472e-02, 5.700e-02, -8.774e-02, -2.506e-01, 1.508e-01, 1.834e-01, -8.423e-02, -7.990e-02, -1.637e-01, 5.649e-02) * s[2][2][0];
	r0 += M4(-6.541e-02, 1.625e-01, -7.710e-02, 3.306e-02, -1.435e-02, 7.307e-02, 6.777e-02, 5.987e-02, -5.248e-02, 1.337e-03, 3.796e-02, 7.104e-02, -1.238e-01, -1.165e-02, -9.509e-01, 3.182e-01) * s[2][2][1];
	r0 += V4(1.762e-01, -7.447e-02, -9.008e-02, -1.052e-01);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv5
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(2.623e-01, -1.816e-02, 8.237e-02, -9.739e-02, -8.447e-02, -1.512e-01, 9.568e-02, -1.569e-01, 1.586e-01, -5.885e-02, -2.046e-01, 5.219e-02, 1.529e-01, -2.008e-02, 2.890e-02, 3.812e-02) * s[0][0][0];
	r0 += M4(-4.769e-02, -1.066e-01, 1.058e-02, -1.920e-01, 1.621e-01, -1.642e-01, 1.428e-01, -1.165e-01, 2.830e-01, 1.715e-02, -5.382e-02, 8.177e-02, -1.934e-01, -1.454e-01, 1.641e-02, -5.946e-02) * s[0][0][1];
	r0 += M4(-1.890e-01, -4.908e-01, -6.954e-02, -4.156e-02, 4.935e-02, -2.428e-01, -6.971e-02, -1.973e-01, 4.078e-02, -1.737e-02, 5.722e-02, -1.164e-01, -1.457e-02, -2.764e-02, -2.357e-02, 5.321e-02) * s[0][1][0];
	r0 += M4(-3.897e-01, -3.389e-01, -7.740e-02, -1.478e-01, 3.747e-01, -1.242e-01, -1.465e-01, -4.629e-02, 1.374e-01, 9.041e-02, -3.956e-02, 3.794e-02, -2.819e-01, -3.433e-01, -1.394e-01, -5.744e-02) * s[0][1][1];
	r0 += M4(-3.666e-02, -2.594e-01, -1.153e-01, -1.069e-01, 1.638e-02, -2.687e-01, -1.280e-01, -6.215e-02, -7.659e-03, 1.376e-02, 2.387e-01, -5.934e-02, -9.067e-04, 2.676e-02, 3.094e-03, -1.135e-02) * s[0][2][0];
	r0 += M4(-1.397e-01, -2.252e-01, -3.260e-02, -1.721e-01, 5.820e-02, -3.393e-02, -1.882e-01, 2.603e-02, 2.559e-02, 1.176e-02, -4.715e-02, 7.431e-02, -2.848e-01, -3.099e-01, 6.868e-02, -3.334e-01) * s[0][2][1];
	r0 += M4(2.626e-01, 1.019e-01, -3.921e-01, 3.405e-01, -1.056e-01, -2.960e-02, -5.611e-02, -8.162e-02, -1.960e-01, -1.524e-01, 2.353e-01, -2.284e-01, 6.118e-02, -1.776e-02, -4.101e-02, 1.620e-01) * s[1][0][0];
	r0 += M4(-9.794e-02, 4.854e-02, -6.602e-02, -4.872e-02, 5.688e-02, 5.801e-03, -2.202e-01, 1.805e-01, 9.377e-02, -2.492e-03, -5.300e-02, -2.218e-02, 1.396e-01, -3.409e-02, -1.621e-01, 2.987e-01) * s[1][0][1];
	r0 += M4(3.137e-01, -1.371e-01, -3.063e-01, 4.816e-01, 1.992e-01, 5.270e-02, 2.008e-03, -2.320e-01, 1.822e-01, 5.824e-01, 4.135e-01, 5.074e-01, 1.720e-01, -4.089e-01, -4.229e-01, 3.646e-01) * s[1][1][0];
	r0 += M4(-1.596e-01, -2.510e-01, 1.292e-01, 3.055e-01, 2.659e-01, 1.476e-01, -4.647e-01, 8.956e-02, 3.261e-01, 3.955e-01, -1.056e-01, 3.185e-01, 1.812e-01, -3.797e-01, -7.175e-01, 6.491e-01) * s[1][1][1];
	r0 += M4(9.228e-02, 1.480e-01, 4.435e-01, 1.302e-02, -1.457e-01, -1.345e-01, 2.954e-02, -7.258e-02, 8.526e-03, -2.967e-01, -4.247e-02, -2.855e-01, 9.887e-02, 2.317e-01, -1.153e-01, 1.352e-01) * s[1][2][0];
	r0 += M4(-5.313e-02, -1.803e-01, 3.415e-01, -1.982e-01, -1.220e-01, 1.969e-01, -1.073e-01, 7.919e-02, 7.403e-02, 8.433e-02, -7.788e-02, 3.203e-02, -1.188e-01, -1.757e-03, 3.721e-01, -1.645e-01) * s[1][2][1];
	r0 += M4(-2.228e-02, 8.769e-02, -2.250e-01, 2.764e-01, -6.821e-03, -2.419e-02, 1.513e-01, 7.608e-02, -1.201e-02, -1.938e-01, 3.369e-01, -3.053e-01, 5.843e-03, 3.962e-02, -1.106e-01, 1.823e-01) * s[2][0][0];
	r0 += M4(-6.070e-02, -6.355e-03, 1.234e-01, -9.172e-02, -3.490e-02, 3.463e-02, 2.521e-02, 1.169e-01, 4.481e-02, 6.438e-02, -1.057e-01, 8.062e-02, -4.042e-03, 3.247e-02, -1.430e-01, 3.341e-01) * s[2][0][1];
	r0 += M4(1.660e-02, 2.132e-01, 2.469e-01, 2.551e-01, 7.421e-03, -5.854e-02, 5.026e-03, -1.807e-01, 6.111e-02, -3.149e-01, -1.683e-01, -1.626e-01, 2.970e-02, 2.477e-01, 6.669e-02, 9.546e-02) * s[2][1][0];
	r0 += M4(-1.756e-01, -6.899e-02, 2.488e-01, -3.201e-01, -4.942e-02, 6.043e-02, -4.817e-02, -6.894e-02, 2.653e-02, 6.670e-02, -1.318e-01, 1.230e-01, -2.941e-02, -4.077e-02, 1.380e-01, 3.386e-01) * s[2][1][1];
	r0 += M4(4.012e-02, 1.236e-01, 1.286e-01, 2.253e-02, 8.078e-02, -9.593e-02, -5.655e-02, -8.370e-02, 1.155e-01, -5.858e-02, 1.886e-01, -6.987e-02, -7.656e-02, 2.307e-01, 5.085e-03, 9.559e-02) * s[2][2][0];
	r0 += M4(-2.885e-02, -2.163e-01, 8.372e-02, -1.508e-01, -5.647e-03, 6.801e-02, -3.428e-02, 1.769e-02, 2.345e-03, 5.877e-02, -1.123e-01, 1.195e-01, -1.316e-01, -3.621e-02, 1.511e-01, -6.953e-02) * s[2][2][1];
	r0 += V4(2.232e-02, 1.963e-02, -1.411e-02, 3.390e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv6
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv5_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(2.774e-02, 4.869e-02, -3.655e-02, 2.748e-03, 1.121e-01, -5.448e-02, 7.002e-02, -3.611e-02, -7.680e-02, -3.658e-02, -1.361e-01, 2.144e-02, -5.826e-02, -7.691e-02, -5.182e-03, 7.302e-02) * s[0][0][0];
	r0 += M4(3.073e-02, 3.764e-03, 4.792e-02, 2.082e-02, -1.539e-02, 4.038e-02, 4.171e-02, 1.814e-02, -1.198e-01, -5.598e-02, 1.531e-02, 1.101e-01, -1.209e-01, -1.238e-01, -1.679e-01, 9.375e-02) * s[0][0][1];
	r0 += M4(-2.690e-02, -1.678e-02, 2.273e-02, 1.592e-01, 8.044e-02, -8.771e-02, -6.758e-02, -3.031e-01, -1.354e-01, 6.417e-03, 2.213e-02, 3.124e-01, 9.661e-02, 7.806e-02, 1.587e-01, 3.018e-01) * s[0][1][0];
	r0 += M4(-8.905e-02, -9.735e-04, 3.611e-02, 7.551e-03, -7.861e-03, 7.688e-02, -1.246e-01, -1.822e-01, 6.631e-02, -9.585e-02, 6.221e-01, 2.158e-01, 1.186e-01, -6.155e-03, 4.625e-01, 2.332e-01) * s[0][1][1];
	r0 += M4(2.050e-03, -6.692e-02, -1.131e-02, -1.853e-03, -1.226e-01, -3.695e-02, -1.333e-01, -3.706e-02, 1.025e-01, -4.687e-02, 1.367e-01, 2.549e-02, 1.598e-01, 7.899e-02, 9.125e-02, -7.306e-02) * s[0][2][0];
	r0 += M4(-1.749e-02, -5.795e-02, 6.993e-03, -2.726e-02, -1.164e-01, -1.807e-02, -1.728e-01, 2.436e-02, -6.303e-02, 1.912e-01, 1.244e-01, 1.679e-01, 1.507e-01, 8.356e-02, 1.770e-01, -1.711e-01) * s[0][2][1];
	r0 += M4(-9.062e-02, 1.385e-02, -1.942e-02, 2.378e-01, 1.629e-01, 2.821e-01, 3.514e-01, -4.842e-01, -1.231e-01, -1.888e-01, -1.734e-01, 1.686e-01, 1.218e-02, -6.661e-02, -7.276e-03, -5.312e-02) * s[1][0][0];
	r0 += M4(8.581e-06, -7.673e-03, -3.588e-02, 7.348e-02, 2.571e-02, 1.206e-01, 2.962e-01, -2.528e-01, -4.392e-05, 6.668e-02, -2.057e-01, 8.735e-02, -6.864e-02, -2.007e-01, -3.634e-01, 1.597e-01) * s[1][0][1];
	r0 += M4(-2.183e-01, 2.746e-01, 2.649e-01, -3.566e-01, 3.397e-01, 7.561e-02, -4.700e-01, 2.120e-01, -1.059e-01, 1.305e-01, -1.972e-01, 3.118e-02, 2.361e-01, 6.405e-01, -1.977e-01, -1.146e-01) * s[1][1][0];
	r0 += M4(-4.104e-03, 7.852e-02, 1.070e-01, -2.902e-01, 2.505e-01, -1.486e-01, 1.105e-01, -3.203e-02, -9.608e-02, -9.304e-02, -4.603e-01, 2.833e-01, -2.780e-01, 4.975e-01, -1.038e-01, 1.763e-01) * s[1][1][1];
	r0 += M4(4.731e-01, -7.961e-02, 3.073e-01, 3.570e-02, 2.619e-01, -2.190e-02, -3.913e-02, 1.440e-01, -1.874e-01, -5.498e-02, -1.519e-01, 9.596e-02, -4.373e-01, 1.339e-01, 5.188e-02, -1.758e-01) * s[1][2][0];
	r0 += M4(3.750e-01, 9.091e-03, -1.150e-01, 3.232e-01, 2.352e-01, -2.615e-02, 5.170e-02, 5.930e-02, 1.919e-02, 1.091e-01, -1.216e-01, 1.968e-01, -5.059e-01, 3.158e-01, 3.038e-01, -4.678e-01) * s[1][2][1];
	r0 += M4(-8.899e-02, 2.359e-02, -2.262e-02, 1.562e-01, 2.547e-02, 1.212e-01, 9.839e-02, -7.592e-02, 9.069e-03, -1.582e-01, -5.186e-02, 6.951e-02, 5.503e-03, -3.573e-02, 4.292e-02, 5.400e-06) * s[2][0][0];
	r0 += M4(1.734e-02, 1.864e-02, -3.698e-02, -1.033e-02, 5.467e-02, 5.176e-02, 1.146e-01, -1.225e-01, 6.370e-03, 2.689e-02, 4.930e-02, 3.963e-02, 9.858e-03, -1.720e-01, -6.453e-02, 7.112e-02) * s[2][0][1];
	r0 += M4(5.050e-02, -1.838e-01, 3.511e-01, 7.266e-02, -1.144e-01, 1.379e-01, 7.258e-02, 8.370e-02, 7.791e-02, -8.178e-02, -7.835e-02, -4.655e-03, -3.553e-02, 2.463e-01, -1.488e-02, -6.027e-02) * s[2][1][0];
	r0 += M4(2.388e-01, -1.251e-01, 1.815e-01, -2.862e-01, 3.145e-02, 8.498e-02, 1.070e-01, -6.020e-02, -4.346e-02, 5.019e-02, 8.525e-02, 8.236e-02, 3.156e-02, 8.911e-02, -1.655e-01, -8.151e-02) * s[2][1][1];
	r0 += M4(2.017e-01, 1.612e-01, 1.161e-01, -4.555e-02, -6.936e-02, 3.650e-03, -8.862e-02, 5.051e-02, 9.056e-03, -7.319e-02, -2.577e-02, 4.097e-02, -1.741e-02, -5.410e-02, 6.889e-02, 1.440e-03) * s[2][2][0];
	r0 += M4(1.528e-01, -1.078e-01, -2.041e-01, 2.675e-01, 7.082e-03, 9.253e-02, -2.074e-02, 7.838e-02, -1.057e-01, 1.732e-01, 1.425e-01, -1.172e-01, 3.828e-02, -2.441e-01, -7.109e-02, -4.656e-02) * s[2][2][1];
	r0 += V4(1.157e-02, -3.558e-02, 2.020e-02, 1.717e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv7
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv6_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(6.233e-02, -2.163e-01, -1.501e-02, 1.109e-01, 3.201e-02, 2.630e-01, -4.899e-02, -1.799e-01, -7.224e-02, 2.608e-02, 2.077e-02, 4.388e-03, 3.155e-02, -3.514e-02, -1.071e-02, 4.926e-02) * s[0][0][0];
	r0 += M4(-5.876e-02, -1.343e-01, 1.349e-02, 5.181e-02, -5.150e-03, 9.454e-02, 7.619e-03, -2.750e-02, -2.230e-02, 6.636e-02, 2.375e-02, -6.145e-02, 7.024e-02, 1.587e-02, 1.269e-02, -2.089e-01) * s[0][0][1];
	r0 += M4(6.946e-02, 1.714e-01, -5.424e-02, -3.702e-01, 1.233e-01, 1.043e-01, -1.817e-02, -5.145e-01, -5.334e-02, -7.316e-03, 7.496e-02, -3.918e-02, -4.489e-02, -3.608e-02, -3.349e-02, 1.137e-01) * s[0][1][0];
	r0 += M4(4.387e-02, 9.771e-02, 9.039e-02, -3.367e-01, -1.770e-01, -1.438e-02, -1.173e-01, 8.029e-02, 1.685e-02, -1.635e-01, 3.083e-02, 2.039e-01, 9.825e-02, -9.791e-02, -2.106e-02, 6.808e-02) * s[0][1][1];
	r0 += M4(5.234e-02, 2.035e-03, 8.498e-02, -7.752e-02, 6.850e-02, 3.908e-03, 2.550e-01, -2.037e-01, 2.049e-02, 7.433e-02, 5.090e-02, -1.673e-01, 3.919e-02, 8.130e-02, -6.119e-02, -1.262e-01) * s[0][2][0];
	r0 += M4(1.560e-02, -6.819e-03, 5.411e-02, -1.713e-02, 5.802e-02, 7.056e-02, 4.461e-02, -1.766e-01, 4.952e-02, 3.584e-03, -5.308e-02, 1.056e-02, 3.386e-02, 8.039e-02, -3.982e-02, -6.007e-02) * s[0][2][1];
	r0 += M4(3.480e-01, -4.381e-01, -7.649e-02, 4.247e-01, 3.232e-01, 7.648e-02, -1.142e-01, -8.505e-02, 3.018e-01, -2.959e-01, -2.292e-01, 2.042e-01, -5.150e-02, -1.479e-01, 6.160e-03, 7.857e-02) * s[1][0][0];
	r0 += M4(7.163e-02, -4.293e-01, 6.372e-02, 3.386e-01, 2.542e-01, -1.814e-02, -1.100e-01, 2.833e-02, -1.007e-02, -1.082e-01, -1.925e-02, 9.903e-02, -5.442e-01, -1.558e-01, 2.989e-01, -2.036e-01) * s[1][0][1];
	r0 += M4(1.096e-01, -3.347e-01, 3.515e-01, -5.676e-02, -1.842e-01, -6.446e-01, 3.192e-02, 3.701e-01, 2.864e-01, 1.658e-01, -6.930e-01, -6.799e-01, 8.115e-02, -1.528e-01, 1.135e-01, 3.029e-02) * s[1][1][0];
	r0 += M4(-4.308e-02, -1.808e-01, 8.073e-02, 1.757e-02, -1.229e-01, -4.143e-01, 1.441e-01, 2.648e-01, 1.445e-02, 2.361e-01, 4.371e-03, -3.005e-01, 5.841e-01, -5.723e-01, 9.159e-01, 8.432e-03) * s[1][1][1];
	r0 += M4(-2.773e-02, -8.318e-02, -7.097e-03, 1.245e-01, -5.980e-02, 6.083e-02, -1.053e-01, -6.956e-02, -9.430e-02, 1.677e-02, 2.340e-01, -2.937e-02, 6.924e-02, -5.297e-02, 9.334e-02, -2.634e-02) * s[1][2][0];
	r0 += M4(-2.761e-02, 6.500e-03, -5.282e-02, 5.891e-02, -1.600e-02, 1.450e-01, -1.157e-01, -1.763e-01, 8.791e-02, -5.823e-02, 1.091e-01, 4.381e-02, 7.959e-02, 3.116e-02, 6.471e-03, -8.869e-02) * s[1][2][1];
	r0 += M4(-2.013e-01, -2.192e-01, -9.524e-04, 1.219e-01, -1.144e-01, -4.278e-02, 6.478e-02, 1.071e-02, -7.641e-02, 1.626e-02, 8.139e-02, -2.526e-02, -1.293e-01, -1.309e-01, 6.570e-02, 1.170e-01) * s[2][0][0];
	r0 += M4(-1.339e-01, -1.186e-01, 4.861e-03, 5.165e-02, -1.061e-01, -7.553e-02, 8.810e-02, 5.487e-02, -4.945e-02, -2.058e-02, -5.793e-03, 3.024e-03, 9.651e-02, -1.902e-01, -4.142e-03, 1.243e-01) * s[2][0][1];
	r0 += M4(7.063e-03, 1.839e-01, -1.889e-01, -6.763e-02, 7.593e-02, 6.252e-02, -5.426e-02, -5.245e-02, 8.822e-02, -1.951e-01, -6.158e-02, 8.612e-02, -7.422e-03, 1.184e-01, -1.222e-01, -1.129e-01) * s[2][1][0];
	r0 += M4(1.875e-02, 1.273e-01, -1.295e-01, -7.600e-02, -3.973e-02, -4.471e-02, 3.506e-03, 1.425e-02, 3.848e-02, 2.322e-02, -9.851e-02, -1.815e-02, 2.053e-01, -5.554e-02, 7.761e-03, 4.896e-04) * s[2][1][1];
	r0 += M4(2.915e-02, -2.907e-02, 3.697e-02, 2.101e-02, 4.934e-02, 3.796e-02, -3.898e-02, -2.885e-02, -9.141e-02, -2.958e-02, 8.901e-02, 4.265e-02, 3.301e-02, 3.758e-02, 9.630e-03, 2.639e-02) * s[2][2][0];
	r0 += M4(2.196e-02, 2.158e-02, 2.971e-02, -2.626e-02, 2.918e-02, -3.112e-02, -1.683e-02, 3.284e-02, 5.474e-03, -2.569e-02, 1.020e-01, 4.016e-02, 7.153e-02, -9.512e-02, 2.204e-01, 3.552e-02) * s[2][2][1];
	r0 += V4(-8.378e-03, 1.392e-03, -9.964e-03, 1.630e-02);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-conv8
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
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(texelFetch(conv7_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
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
	r0 += M4(5.950e-02, 1.742e-02, -4.906e-02, -2.957e-02, 3.727e-02, -7.506e-03, 7.688e-02, 1.511e-01, 1.294e-01, 4.864e-02, -8.375e-02, 7.405e-02, 4.628e-02, 4.800e-03, -1.646e-02, 8.901e-02) * s[0][0][0];
	r0 += M4(1.004e-01, 8.844e-03, -1.565e-01, 1.579e-02, 4.064e-02, 2.331e-02, 1.185e-01, 5.340e-02, 1.027e-01, -2.402e-02, -1.802e-01, 2.655e-02, 3.615e-02, 2.830e-02, -2.407e-02, 2.893e-02) * s[0][0][1];
	r0 += M4(2.183e-01, 1.833e-02, -4.484e-01, -5.604e-02, -1.555e-01, -9.254e-02, -3.024e-01, -8.772e-02, 2.128e-02, -5.780e-02, -3.233e-01, -1.021e-01, -5.598e-02, -1.195e-01, -2.456e-01, 7.203e-02) * s[0][1][0];
	r0 += M4(3.088e-02, -9.498e-02, -4.259e-02, -7.477e-02, -3.357e-02, -9.807e-02, -5.084e-01, -7.709e-02, 6.616e-02, 5.104e-03, -5.677e-02, 4.114e-02, -3.367e-03, -3.918e-02, -1.710e-01, 1.674e-02) * s[0][1][1];
	r0 += M4(1.554e-01, 1.392e-01, 8.984e-02, 3.617e-02, 2.080e-01, 1.597e-01, -5.346e-02, 6.306e-02, 9.158e-02, 7.061e-02, -1.062e-01, 1.987e-02, 9.965e-02, 5.605e-02, -9.113e-02, 1.797e-02) * s[0][2][0];
	r0 += M4(1.606e-01, 1.431e-01, 4.866e-02, 1.922e-02, 5.103e-02, 3.667e-03, 2.760e-02, 1.616e-01, 5.185e-02, 1.775e-02, -1.815e-01, 3.713e-03, 8.667e-02, 3.552e-02, -3.724e-02, 4.414e-02) * s[0][2][1];
	r0 += M4(-9.989e-02, 1.344e-01, 3.718e-02, -1.844e-01, -1.494e-01, 7.413e-02, 2.081e-02, -1.421e-01, 4.673e-02, 4.331e-01, -4.933e-01, -7.749e-01, -9.786e-02, 9.918e-02, -9.143e-02, -3.152e-01) * s[1][0][0];
	r0 += M4(-1.063e-01, 1.134e-01, 6.079e-02, -5.727e-02, -2.884e-02, -1.114e-01, 4.893e-02, 1.772e-01, -2.766e-01, 3.154e-01, 3.301e-02, -3.997e-01, -6.901e-02, 7.247e-02, -1.574e-01, -3.154e-01) * s[1][0][1];
	r0 += M4(-5.606e-02, 3.807e-01, -1.329e-01, -2.658e-02, 3.701e-01, 2.888e-01, -3.983e-02, -2.514e-01, 3.075e-01, 1.998e-01, 2.556e-02, -1.381e-01, 3.308e-01, 5.762e-01, -5.328e-02, -3.470e-01) * s[1][1][0];
	r0 += M4(-2.725e-01, -8.866e-02, 5.502e-02, 1.587e-01, 2.279e-01, 9.940e-02, -3.006e-01, -1.929e-01, 2.998e-01, 1.909e-01, -8.476e-02, 2.859e-02, 2.427e-01, 4.259e-01, 3.498e-01, -2.290e-01) * s[1][1][1];
	r0 += M4(-1.077e-01, -2.250e-01, 1.668e-01, 5.868e-02, 2.592e-02, -1.823e-01, -5.531e-02, 5.382e-02, 1.575e-01, 1.159e-01, -1.009e-01, -3.716e-02, -2.705e-01, -3.129e-01, 2.764e-01, 1.126e-01) * s[1][2][0];
	r0 += M4(-2.704e-01, -3.115e-01, 3.333e-01, 6.270e-02, 9.761e-02, -1.173e-01, -2.611e-02, 5.484e-02, 6.150e-02, -1.418e-02, -1.059e-01, -1.537e-02, -1.427e-01, -2.134e-01, 8.656e-02, 3.981e-02) * s[1][2][1];
	r0 += M4(9.755e-03, 3.108e-02, -2.868e-02, -6.496e-02, 3.401e-02, -5.185e-02, -5.515e-02, -1.971e-02, 2.358e-02, -1.298e-01, 4.011e-02, 3.181e-02, 8.116e-02, -4.676e-02, -9.334e-02, -4.742e-02) * s[2][0][0];
	r0 += M4(1.227e-03, 8.728e-03, 2.234e-02, 3.608e-02, -1.281e-01, 6.598e-02, 5.696e-02, -4.595e-02, 9.161e-02, -3.267e-02, -5.211e-02, 5.173e-03, 1.029e-02, -4.891e-02, -4.056e-02, -7.457e-02) * s[2][0][1];
	r0 += M4(1.265e-01, 8.450e-02, -9.366e-02, -6.284e-02, -8.731e-02, 1.046e-01, 7.207e-02, 2.514e-03, 1.619e-01, 2.542e-02, -8.903e-03, 1.199e-01, -2.135e-02, 1.132e-01, -2.211e-02, -2.826e-02) * s[2][1][0];
	r0 += M4(-9.214e-02, -4.887e-02, 4.784e-02, 8.096e-03, -1.023e-01, 1.088e-01, 1.534e-02, -3.090e-03, 7.506e-02, -2.203e-02, -3.340e-03, 8.749e-02, 4.846e-02, 2.724e-01, -6.291e-02, -7.934e-02) * s[2][1][1];
	r0 += M4(4.535e-03, 5.808e-02, 1.033e-02, 6.141e-03, -3.382e-02, 1.294e-02, -6.946e-02, -1.183e-02, -5.360e-02, -7.760e-02, 4.405e-02, 1.969e-02, 5.652e-02, 3.367e-02, -9.353e-02, -3.153e-02) * s[2][2][0];
	r0 += M4(-4.425e-02, 1.292e-02, 3.743e-02, 1.429e-02, -9.773e-02, -5.402e-02, 5.487e-02, 2.653e-02, -9.888e-02, -8.130e-02, 7.254e-02, 1.276e-02, 6.820e-02, 5.617e-02, -7.376e-02, -1.967e-02) * s[2][2][1];
	r0 += V4(2.568e-03, -5.662e-03, 2.785e-03, 6.388e-03);
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
}

//!DESC CuNNy-8x4C-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!BIND conv8
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
#define l0(x, y) V4(texelFetch(conv8_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
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
	r0 += M4(4.191e-02, 3.788e-02, 2.412e-02, 9.993e-04, -2.027e-02, -1.400e-02, -2.079e-02, 2.375e-03, 1.691e-02, 1.303e-02, 1.690e-02, 3.299e-03, -1.800e-02, -4.021e-03, -1.800e-02, -3.482e-03) * s[0][0][0];
	r0 += M4(2.571e-02, 2.325e-02, 1.052e-02, 4.036e-03, -1.104e-02, 6.855e-03, -1.140e-02, -8.199e-03, 1.330e-02, 2.453e-02, 4.303e-03, -4.649e-03, -7.713e-03, -2.783e-02, -4.262e-03, -8.972e-03) * s[0][0][1];
	r0 += M4(-9.597e-02, -4.669e-02, -2.189e-02, 1.861e-02, 1.204e-01, 6.000e-02, 2.772e-02, -3.357e-02, -3.845e-02, -7.047e-03, -8.968e-03, 1.250e-02, 6.418e-02, 3.198e-02, -1.500e-02, -3.092e-02) * s[0][1][0];
	r0 += M4(-7.897e-02, -3.139e-02, -5.506e-02, 1.320e-02, 4.259e-02, 9.783e-03, 4.358e-02, -5.882e-03, -2.570e-02, -2.055e-02, -4.706e-03, 1.031e-02, 4.788e-02, 4.174e-02, 1.583e-02, -2.224e-03) * s[0][1][1];
	r0 += M4(7.959e-03, -1.667e-02, 3.684e-04, -5.897e-03, -1.496e-02, 8.262e-03, -4.466e-03, 5.775e-03, 4.447e-04, -1.325e-02, 5.519e-03, 9.053e-03, -1.337e-02, 2.563e-02, -2.240e-02, -1.382e-02) * s[0][2][0];
	r0 += M4(7.523e-03, -1.178e-02, 1.011e-02, -2.704e-02, -1.873e-02, 1.553e-02, -3.186e-02, 1.753e-02, 3.701e-03, -2.434e-03, -8.445e-04, -3.457e-03, -1.581e-02, 4.841e-03, -5.320e-03, 7.077e-03) * s[0][2][1];
	r0 += M4(-2.234e-02, -5.897e-02, 2.644e-02, 4.091e-02, -5.994e-02, -9.935e-02, 1.852e-02, -4.211e-02, -1.976e-02, -4.460e-02, -2.896e-02, 3.735e-02, -3.078e-03, -2.869e-02, 3.635e-04, -1.983e-02) * s[1][0][0];
	r0 += M4(-1.127e-01, -1.072e-01, 7.552e-02, 8.512e-02, -1.214e-01, -1.066e-01, -6.274e-02, -2.995e-02, -1.362e-02, -3.338e-02, 1.430e-02, 4.798e-02, 7.702e-03, -1.324e-02, 2.692e-02, -3.085e-02) * s[1][0][1];
	r0 += M4(-1.794e-01, -2.773e-02, -2.913e-01, -1.366e-01, 1.530e-01, -1.399e-02, 3.215e-01, 2.051e-01, -6.953e-03, 1.059e-01, -7.937e-02, -8.407e-02, -3.861e-01, -1.140e-01, 1.218e-01, 1.700e-01) * s[1][1][0];
	r0 += M4(-3.748e-01, -3.795e-02, -2.578e-01, -8.114e-02, 2.539e-01, 2.814e-01, 2.213e-01, 2.076e-01, 5.383e-02, 1.969e-02, -1.156e-02, -5.191e-02, -1.343e-01, -2.014e-01, 3.912e-02, 6.021e-02) * s[1][1][1];
	r0 += M4(3.062e-02, -1.236e-01, 6.213e-02, -8.888e-02, -2.166e-02, 1.292e-01, -6.138e-02, 8.770e-02, 2.106e-02, 1.651e-02, -1.955e-02, -3.251e-02, 5.119e-02, -9.881e-02, 3.595e-02, 7.647e-02) * s[1][2][0];
	r0 += M4(3.659e-02, -1.933e-01, 8.517e-02, -1.775e-02, 1.542e-02, 8.916e-02, -4.919e-02, 4.089e-03, 9.810e-03, -5.583e-03, 1.338e-02, -1.959e-04, 3.113e-02, 5.001e-02, -1.843e-02, -8.039e-03) * s[1][2][1];
	r0 += M4(9.149e-02, 2.227e-02, -2.270e-02, -9.495e-02, 1.437e-02, -7.765e-03, -1.224e-01, -1.157e-01, 9.939e-02, 8.002e-04, 8.251e-02, -9.692e-02, -4.314e-02, -2.365e-02, -5.923e-02, -3.274e-02) * s[2][0][0];
	r0 += M4(7.800e-02, 4.918e-02, -7.397e-02, -1.166e-01, -1.315e-02, 8.992e-03, -1.841e-01, -1.182e-01, 1.104e-01, 4.217e-02, 5.483e-02, -4.576e-02, -3.320e-02, -1.498e-02, -7.666e-02, -2.030e-02) * s[2][0][1];
	r0 += M4(4.283e-02, 1.894e-01, 4.884e-02, 1.646e-01, 4.773e-02, 8.423e-02, -1.003e-01, -1.277e-01, -3.328e-02, 2.388e-01, 2.877e-02, 4.093e-01, 5.458e-02, 2.064e-02, -5.332e-01, -3.096e-01) * s[2][1][0];
	r0 += M4(-4.386e-02, 1.499e-01, 3.383e-02, 3.005e-01, 2.737e-03, 5.619e-02, -2.309e-01, -9.107e-02, 8.790e-02, 2.056e-01, 1.382e-01, 2.251e-01, -1.273e-02, -6.166e-02, -3.253e-01, -3.929e-01) * s[2][1][1];
	r0 += M4(1.328e-02, -2.013e-02, 2.807e-02, -1.175e-02, 1.613e-02, 6.670e-02, -5.424e-03, 3.129e-02, 3.332e-02, -1.494e-02, 6.813e-02, 3.127e-02, 1.164e-02, 1.993e-01, -5.147e-03, -6.624e-02) * s[2][2][0];
	r0 += M4(2.073e-02, -2.497e-02, 2.721e-02, -1.304e-02, 1.384e-02, 1.200e-01, 1.649e-02, 4.131e-03, 1.126e-02, 1.010e-02, 2.472e-02, 3.152e-02, 1.025e-02, 1.257e-01, -3.474e-02, 2.161e-02) * s[2][2][1];
	r0 += V4(8.719e-04, 7.645e-04, 7.340e-04, 5.693e-04);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + easu_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + easu_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + easu_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + easu_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

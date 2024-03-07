// CuNNy 4x4C RCAS DS
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


//!DESC CuNNy-4x4C-RCAS-DS-in
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
	r += V4(-2.695e-04, 7.182e-02, -1.661e-02, 3.774e-02) * s0[y+0][x+0];
	r += V4(7.643e-02, -5.627e-01, 2.563e-01, -3.475e-01) * s0[y+0][x+1];
	r += V4(-7.763e-02, -2.997e-02, 2.884e-01, 4.012e-02) * s0[y+0][x+2];
	r += V4(3.467e-03, 5.627e-02, -5.244e-02, -3.818e-01) * s0[y+1][x+0];
	r += V4(-6.114e-01, 1.375e-01, 8.288e-02, -1.906e-02) * s0[y+1][x+1];
	r += V4(6.270e-01, 3.190e-01, 1.940e-02, -5.717e-02) * s0[y+1][x+2];
	r += V4(-8.355e-03, -1.053e-03, 3.590e-02, 5.652e-02) * s0[y+2][x+0];
	r += V4(6.091e-02, 6.653e-02, -3.587e-02, -8.766e-02) * s0[y+2][x+1];
	r += V4(-6.715e-02, -7.423e-02, 1.976e-02, 4.110e-02) * s0[y+2][x+2];
	r += V4(-1.574e-03, 1.307e-02, -3.763e-01, 7.251e-03);
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


//!DESC CuNNy-4x4C-RCAS-DS-conv1
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
	r += M4(2.216e-01, -3.440e-01, -4.187e-01, 1.365e-01, 7.171e-02, -6.777e-02, -7.510e-02, 1.039e-01, 1.410e-01, -1.672e-01, -6.353e-02, 8.865e-02, -4.797e-01, 3.055e+00, 1.777e+00, -3.640e-02) * s0[y+0][x+0];
	r += M4(1.509e-01, 5.177e-01, 2.390e-01, -7.463e-02, -2.617e-02, -1.323e-01, 4.335e-02, -8.288e-03, -8.395e-03, -6.051e-02, -9.121e-02, 1.109e-01, -9.575e-02, 7.766e+00, 2.004e+00, -2.789e+00) * s0[y+0][x+1];
	r += M4(-4.493e-02, 1.192e-01, 1.836e-01, 7.412e-02, -1.988e-02, -1.537e-01, -2.187e-01, 9.227e-02, -1.207e-02, 2.534e-02, -1.211e-02, -4.758e-02, -5.460e-01, 7.422e+00, 5.008e+00, -4.883e+00) * s0[y+0][x+2];
	r += M4(-3.036e-01, -6.501e-01, 6.935e-02, -9.892e-02, -4.717e-01, 2.152e-01, 3.193e-01, -3.302e-03, -9.067e-02, -3.149e-01, -1.578e-01, -9.011e-02, -2.030e+00, 2.287e+00, -1.484e+00, -2.219e+00) * s0[y+1][x+0];
	r += M4(3.001e-01, 1.079e-01, -1.153e+00, 7.246e-01, -4.576e-03, 5.595e-01, 5.847e-01, 1.866e-01, 2.393e-01, 3.684e-03, -2.467e-01, 3.929e-01, -1.599e+00, 1.014e+01, 2.550e+00, -2.233e+00) * s0[y+1][x+1];
	r += M4(1.644e-01, -4.697e-02, -1.854e-01, -3.795e-02, 2.446e-01, -3.140e-02, 1.250e-01, 1.566e-01, -2.846e-02, -1.119e-01, -1.915e-02, 4.272e-02, -2.119e+00, 4.936e+00, -4.725e+00, -1.838e+00) * s0[y+1][x+2];
	r += M4(-1.411e-01, 2.356e-01, 8.478e-02, -2.482e-02, -3.056e-01, 1.708e-02, -2.900e-01, 9.297e-02, -4.743e-01, -2.251e-01, 7.903e-02, -2.892e-01, -1.981e+00, -1.462e+00, -2.208e+00, 1.768e+00) * s0[y+2][x+0];
	r += M4(4.821e-02, 5.504e-02, -5.531e-03, -2.400e-02, 2.203e-01, -2.368e-02, -1.466e-01, 3.538e-03, 3.807e-02, -2.188e-01, 2.725e-01, -3.823e-02, -5.020e-01, 2.710e+00, -5.961e+00, 5.875e-01) * s0[y+2][x+1];
	r += M4(1.686e-01, -1.305e-03, 1.980e-03, 5.100e-02, -5.830e-01, 4.635e-02, 1.145e-02, -5.707e-02, -1.171e-03, 1.777e-02, -1.194e-02, 1.977e-01, -2.114e+00, 6.956e-01, -3.511e+00, 2.152e+00) * s0[y+2][x+2];
	r += M4(3.728e-01, -5.676e-01, -5.127e-01, 4.597e-02, 7.848e-02, -2.998e-01, -1.948e-01, 5.346e-02, 2.427e-01, -1.053e-01, -5.134e-02, 2.569e-01, -3.380e-03, 6.181e-02, 1.372e-01, 7.640e-02) * s1[y+0][x+0];
	r += M4(4.876e-01, 2.742e-01, 1.528e-01, 3.660e-01, 2.850e-02, -2.629e-01, -1.693e-02, 4.258e-01, -2.104e-01, 4.843e-02, 2.982e-02, 5.473e-02, -1.876e-02, 4.544e-02, -1.795e-01, 1.745e-02) * s1[y+0][x+1];
	r += M4(-4.649e-02, 2.329e-01, 1.675e-01, 7.701e-02, 4.750e-02, -2.300e-01, -2.396e-01, 1.916e-01, -3.298e-02, -1.126e-01, -1.116e-01, -7.105e-02, -1.005e-01, 9.474e-02, 1.984e-01, -2.021e-02) * s1[y+0][x+2];
	r += M4(2.826e-01, -4.976e-01, 8.246e-01, -2.467e-02, -1.191e-01, 1.895e-01, 5.878e-01, 2.213e-01, -4.257e-02, 6.998e-03, 4.608e-02, -7.830e-02, 1.136e-02, 1.796e-01, 2.807e-02, -5.303e-03) * s1[y+1][x+0];
	r += M4(5.305e-01, 6.998e-01, -1.959e-01, 1.314e-01, 4.799e-02, 2.512e-01, 4.198e-01, -9.252e-03, 1.898e-01, 9.242e-02, -1.694e-01, 2.315e-02, -3.659e-02, 2.816e-01, 1.439e-01, 9.806e-02) * s1[y+1][x+1];
	r += M4(-1.147e-01, -4.368e-02, -2.146e-01, -4.463e-02, 1.332e-01, -9.821e-02, 3.035e-01, -3.699e-01, 1.861e-02, 3.009e-02, 6.279e-02, 5.823e-02, -8.168e-03, 2.083e-01, -2.349e-01, -1.371e-01) * s1[y+1][x+2];
	r += M4(8.506e-02, 2.965e-02, 2.358e-01, -1.864e-02, 4.141e-01, 1.351e-01, -1.144e-01, 7.788e-02, -6.136e-01, 1.233e-01, -6.915e-02, -2.535e-01, -2.622e-02, 5.205e-02, -8.131e-02, 2.382e-02) * s1[y+2][x+0];
	r += M4(2.992e-01, 9.122e-02, 3.740e-01, -1.548e-01, 3.169e-01, -2.086e-01, -2.766e-01, -1.888e-01, 4.053e-01, -1.091e-01, 1.483e-02, 2.002e-01, -7.419e-02, -1.766e-01, -3.114e-01, -5.958e-02) * s1[y+2][x+1];
	r += M4(2.209e-01, -1.662e-01, 9.827e-03, -8.362e-03, -2.688e-01, 1.793e-01, 5.097e-02, -1.779e-01, -5.845e-02, 4.683e-02, 3.777e-02, 4.760e-02, 1.943e-01, 8.532e-02, 1.029e-01, 1.714e-01) * s1[y+2][x+2];
	r += V4(-3.678e-02, 5.500e-03, -7.968e-02, 8.004e-02);
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


//!DESC CuNNy-4x4C-RCAS-DS-conv2
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
	r += M4(2.162e-01, 2.826e-01, -2.292e-02, -2.565e-02, -4.049e-02, 2.827e-02, -2.803e-01, 1.168e-01, -2.059e-02, 5.909e-02, 3.076e-01, -1.247e-01, -1.003e-01, -9.598e-02, 1.702e-02, -3.508e-02) * s0[y+0][x+0];
	r += M4(5.113e-01, 3.463e-01, 6.326e-01, -2.689e-01, 1.537e-01, -2.818e-01, -3.966e-01, -5.611e-02, -2.138e-02, 2.697e-01, 4.240e-01, 9.186e-02, 2.227e-02, 6.566e-02, -1.552e-01, -3.526e-02) * s0[y+0][x+1];
	r += M4(2.814e-01, -4.321e-01, 2.438e-01, -7.204e-02, 3.147e-02, 2.008e-01, 2.132e-02, 3.857e-02, -2.788e-02, -1.948e-01, -1.154e-01, -1.653e-02, -1.696e-01, 5.486e-02, -2.510e-02, -9.726e-04) * s0[y+0][x+2];
	r += M4(1.224e-01, 5.070e-02, -6.379e-01, 9.122e-02, 2.958e-01, 2.000e-01, 5.270e-02, 7.131e-03, 4.100e-03, 1.171e-01, -5.151e-02, -8.046e-02, -6.730e-02, -1.185e-01, 2.111e-01, -2.389e-02) * s0[y+1][x+0];
	r += M4(-5.292e-01, 7.488e-01, -4.355e-02, 6.197e-01, -3.111e+00, -2.184e+00, 5.842e-01, -1.629e+00, -6.556e-01, 5.176e-01, -2.685e-01, 4.286e-01, -2.144e-01, -9.284e-02, -1.447e-01, 1.856e-03) * s0[y+1][x+1];
	r += M4(-3.564e-01, -3.750e-01, -3.194e-01, 1.057e-01, -1.603e-01, 3.366e-01, 1.919e-01, -3.254e-02, -5.854e-02, -5.481e-01, -4.932e-01, -3.996e-02, 1.548e-01, -1.176e-01, -5.578e-02, 1.277e-02) * s0[y+1][x+2];
	r += M4(1.015e-02, 1.641e-03, -1.867e-01, -8.730e-02, -8.511e-02, 1.371e-01, -3.192e-01, -1.129e-01, 1.400e-01, 1.024e-01, 2.412e-01, 1.657e-02, -3.134e-01, -9.057e-03, 5.644e-01, 1.383e-01) * s0[y+2][x+0];
	r += M4(7.544e-02, 8.995e-02, 2.005e-01, 3.733e-02, -8.323e-01, -2.868e-01, 8.760e-02, -9.679e-01, -2.652e-01, -3.966e-01, 1.473e-01, -3.263e-01, -4.757e-01, -2.544e-02, 3.232e-01, -7.150e-02) * s0[y+2][x+1];
	r += M4(-3.116e-01, -2.413e-02, -1.269e-01, 2.645e-03, 4.053e-02, -3.332e-01, 5.725e-02, -1.622e-01, 3.373e-01, -6.675e-02, 4.997e-02, 8.323e-05, 4.604e-02, -3.918e-02, 6.042e-02, 5.033e-02) * s0[y+2][x+2];
	r += M4(5.682e-02, 3.079e-02, 1.573e-02, -2.243e-02, 8.745e-02, 4.690e-02, -2.339e-01, 1.085e-01, 1.228e-01, 3.384e-02, 3.916e-01, -1.132e-01, 2.046e-01, -1.020e-02, -1.419e-01, 2.644e-02) * s1[y+0][x+0];
	r += M4(1.725e-01, 1.958e-01, 3.105e-01, -2.697e-03, -7.448e-03, -2.979e-01, -3.198e-01, -6.958e-02, 6.226e-01, 3.887e-01, 5.775e-01, -1.279e-02, -1.372e-01, -1.218e-01, -2.294e-01, -3.263e-02) * s1[y+0][x+1];
	r += M4(5.782e-02, -2.034e-01, 8.235e-02, -4.123e-02, -3.934e-03, 1.355e-01, 2.307e-02, -7.444e-03, 1.304e-01, -1.886e-01, -2.433e-03, -6.685e-02, -2.536e-02, 9.631e-02, -6.308e-02, 3.449e-02) * s1[y+0][x+2];
	r += M4(2.310e-01, 1.930e-02, -2.456e-01, 3.255e-02, 1.247e-01, 1.038e-01, 1.016e-01, -1.811e-03, -1.498e-01, -1.101e-01, 2.032e-01, -9.539e-02, -2.373e-01, 7.688e-02, -5.159e-01, 6.764e-02) * s1[y+1][x+0];
	r += M4(2.751e-01, -2.746e-02, -1.840e-01, -9.437e-02, -3.374e-02, -3.526e-01, 4.253e-01, -3.041e-01, -5.951e-01, 6.977e-01, -3.330e-01, 5.006e-01, -4.901e-01, 1.567e-01, -4.482e-01, 3.173e-03) * s1[y+1][x+1];
	r += M4(-9.947e-02, 4.586e-02, -1.084e-01, 6.065e-02, -1.320e-02, 4.047e-01, 5.717e-02, -4.163e-02, -3.393e-02, -6.466e-01, -4.516e-01, -9.890e-02, 1.421e-01, 6.922e-02, -1.913e-02, -1.179e-02) * s1[y+1][x+2];
	r += M4(8.092e-02, 1.756e-01, -1.781e-01, -9.669e-03, -7.487e-02, 1.082e-01, -6.021e-02, -7.374e-02, -2.143e-01, 3.480e-02, 5.626e-02, -2.695e-02, 2.861e-01, -5.072e-01, 7.555e-01, -1.185e-01) * s1[y+2][x+0];
	r += M4(-5.079e-02, -1.041e-01, 2.400e-02, -1.080e-02, -1.451e-01, -6.452e-03, 6.198e-02, -2.100e-01, -6.187e-02, 9.839e-02, 2.612e-01, -4.281e-02, -1.950e-02, 1.198e-01, 3.410e-01, 1.550e-02) * s1[y+2][x+1];
	r += M4(-1.123e-01, -1.610e-02, 8.241e-02, -2.060e-02, 1.417e-02, -1.373e-01, 2.609e-02, -9.936e-02, -5.332e-02, -1.487e-01, -2.726e-02, -2.870e-02, 1.980e-01, 1.907e-01, 1.688e-02, 2.385e-02) * s1[y+2][x+2];
	r += V4(-1.499e-02, -5.619e-03, -6.679e-03, -5.691e-01);
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


//!DESC CuNNy-4x4C-RCAS-DS-conv3
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
	r += M4(9.184e-03, 2.809e-02, -4.775e-01, 9.587e-02, -2.666e-01, -1.017e-01, 2.627e-01, 1.101e-01, -1.008e-01, -4.931e-02, 2.549e-01, 8.822e-02, -1.776e-01, -4.873e-01, 4.672e-01, -7.706e-02) * s0[y+0][x+0];
	r += M4(-3.753e-02, 2.417e-01, 3.615e-02, -2.460e-02, -1.432e-02, 5.044e-02, 2.866e-02, -1.294e-01, -5.264e-02, -1.053e-01, 2.234e-01, -1.126e-01, 1.386e-01, -1.561e+00, -1.673e-01, -2.342e-01) * s0[y+0][x+1];
	r += M4(-6.773e-02, 2.289e-01, -6.969e-02, 5.996e-02, -2.836e-02, 6.240e-03, 3.287e-02, -2.893e-02, -2.010e-02, -4.018e-02, -3.822e-02, 1.294e-01, 1.168e-01, -9.746e-01, 1.440e-01, -2.190e-01) * s0[y+0][x+2];
	r += M4(-3.621e-02, -4.932e-02, -2.161e-01, 4.456e-01, -4.355e-01, 3.211e-01, 2.282e-02, 4.226e-01, 1.088e-01, 1.806e-01, 5.026e-01, 2.682e-02, -6.107e-01, -6.682e-01, 1.302e+00, 8.457e-01) * s0[y+1][x+0];
	r += M4(2.590e+00, -1.119e-01, 4.080e-01, -3.828e-01, 2.013e-01, -1.018e-01, 9.515e-02, -1.489e-01, 9.437e-01, 4.122e-01, 5.845e-01, -3.065e-01, 1.650e-01, -2.852e+00, -8.543e-01, -1.256e+00) * s0[y+1][x+1];
	r += M4(2.114e-01, -2.507e-01, 1.942e-02, 2.120e-01, 1.022e-01, -1.694e-02, -1.418e-03, -2.095e-01, -2.241e-01, -1.140e-02, -9.119e-02, 4.329e-03, -3.517e-01, -1.565e+00, 2.250e-01, -2.059e-01) * s0[y+1][x+2];
	r += M4(-1.678e-01, -1.793e-01, -8.944e-02, 1.205e-01, -4.757e-01, 4.458e-02, -1.244e-01, -1.586e-01, 4.882e-02, -1.125e-02, 7.305e-02, 3.260e-02, -3.459e-01, -7.183e-01, -1.091e+00, 7.121e-01) * s0[y+2][x+0];
	r += M4(7.742e-02, -9.084e-02, 1.967e-03, -1.699e+00, 1.273e-01, -1.332e-01, 4.709e-02, 4.169e-01, 4.339e-02, 6.944e-03, 1.598e-01, -4.896e-01, -8.120e-01, -1.321e+00, -5.791e-01, 1.890e+00) * s0[y+2][x+1];
	r += M4(1.082e-01, -8.275e-02, -1.934e-02, -2.211e-01, 6.164e-03, -3.755e-02, 3.436e-02, 1.284e-01, -3.174e-03, 7.461e-03, -3.082e-02, -9.304e-02, -3.075e-01, -7.370e-01, 1.669e-01, 4.852e-01) * s0[y+2][x+2];
	r += M4(2.316e-02, 3.551e-02, -1.939e-01, 1.547e-02, -3.803e-02, -9.465e-02, 3.721e-01, -3.688e-02, -1.530e-02, -1.068e-01, 2.155e-01, -1.914e-02, 2.018e-02, 1.884e-02, -1.372e-01, -3.178e-02) * s1[y+0][x+0];
	r += M4(-2.883e-02, 5.722e-02, 2.082e-02, 4.877e-02, 5.930e-02, -1.382e-01, -4.426e-02, -1.107e-01, -3.896e-02, -5.613e-02, 1.164e-01, -4.500e-02, -5.956e-03, 2.515e-02, 1.729e-01, 6.521e-02) * s1[y+0][x+1];
	r += M4(-3.070e-02, -1.704e-02, -1.567e-02, 1.489e-02, 8.178e-02, 3.059e-02, 1.707e-02, -9.461e-03, 7.419e-02, 1.238e-02, -4.513e-02, -6.309e-02, -7.627e-03, -5.444e-02, -9.325e-03, -7.059e-02) * s1[y+0][x+2];
	r += M4(-5.023e-02, -8.200e-02, -3.623e-01, -4.969e-02, 5.508e-02, 8.276e-02, 5.098e-01, 9.485e-02, -3.391e-02, -1.127e-02, 1.538e-01, 1.254e-01, 9.420e-04, 7.151e-02, -3.302e-02, 4.052e-03) * s1[y+1][x+0];
	r += M4(2.942e-02, 2.213e-02, 1.926e-01, -8.987e-02, -2.406e-01, -4.878e-02, -3.553e-01, 3.350e-01, 2.534e-01, 3.557e-01, 2.045e-01, 2.740e-01, 1.209e-01, -1.645e-01, 1.172e-01, -2.417e-01) * s1[y+1][x+1];
	r += M4(-8.806e-02, -6.200e-02, -7.286e-02, 2.528e-02, 3.030e-01, 1.474e-02, 1.909e-01, -1.909e-01, -8.676e-02, -5.978e-02, -3.973e-02, -1.119e-01, -8.473e-02, 1.044e-01, -1.850e-02, 1.730e-01) * s1[y+1][x+2];
	r += M4(-7.433e-02, -7.276e-02, -9.101e-02, -8.045e-03, 4.532e-03, -1.242e-02, 1.567e-01, 5.503e-02, 3.808e-02, -1.973e-02, 1.673e-01, -2.338e-02, 4.015e-02, -1.563e-02, -1.171e-01, 2.449e-02) * s1[y+2][x+0];
	r += M4(-7.825e-02, -2.432e-01, 2.781e-02, 3.368e-02, 1.863e-02, -9.819e-02, 5.422e-03, 3.447e-01, 1.389e-01, -5.212e-03, 1.073e-01, -3.863e-01, -1.422e-01, 5.197e-02, 4.934e-02, 1.467e-01) * s1[y+2][x+1];
	r += M4(-3.730e-02, -1.901e-03, -1.985e-02, -2.252e-02, 5.922e-02, -1.951e-02, 3.748e-02, 3.924e-02, -2.210e-03, -3.852e-02, -3.568e-02, -2.101e-01, 9.839e-02, -1.150e-02, 8.283e-02, -1.162e-01) * s1[y+2][x+2];
	r += V4(2.879e-02, 1.371e-02, 7.738e-02, -4.382e-02);
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


//!DESC CuNNy-4x4C-RCAS-DS-conv4
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
	r += M4(2.894e-02, -6.323e-02, 4.043e-02, 6.769e-02, 2.459e-04, -9.167e-02, 5.137e-02, 1.623e-01, 1.256e-02, -2.867e-02, 2.905e-02, 1.205e-01, 3.839e-01, -4.690e-01, 1.386e-01, 4.695e-01) * s0[y+0][x+0];
	r += M4(-4.672e-02, 1.392e-01, 1.421e-01, -2.480e-01, -3.419e-02, 4.779e-03, -1.747e-02, -1.787e-02, 3.571e-02, -4.535e-02, 6.381e-02, 6.149e-02, 3.018e-01, -2.135e-01, -2.138e-02, 4.416e-01) * s0[y+0][x+1];
	r += M4(-8.361e-03, -6.559e-03, -9.399e-03, 2.395e-02, 2.830e-02, 3.432e-02, -2.195e-02, -9.375e-03, 7.005e-03, -9.919e-02, 1.353e-02, -6.373e-02, 4.228e-02, -2.027e-01, 1.387e-01, -5.528e-02) * s0[y+0][x+2];
	r += M4(1.581e-02, -4.892e-02, 1.149e-02, 4.650e-02, 3.697e-02, -1.722e-02, 1.931e-02, 1.307e-01, -5.597e-02, 1.151e-01, -7.933e-02, -1.322e-01, 3.804e-01, -2.058e-02, -1.483e-01, 2.538e-01) * s0[y+1][x+0];
	r += M4(7.911e-02, -8.223e-02, 1.069e-02, 2.231e-01, 2.421e-01, -5.577e-01, 2.081e-01, -5.602e-02, -2.082e-01, 2.653e-01, -2.822e-01, -2.594e-01, 4.470e-01, 8.337e-03, 2.528e-01, -2.211e-01) * s0[y+1][x+1];
	r += M4(1.054e-01, -1.558e-01, 6.140e-02, -3.353e-02, 1.526e-02, 2.335e-02, 6.723e-02, -9.084e-02, -1.684e-01, 2.605e-01, -5.634e-02, 1.635e-01, 1.734e-01, 5.097e-03, 1.898e-02, -1.299e-01) * s0[y+1][x+2];
	r += M4(-8.481e-02, 4.435e-02, -7.084e-02, -8.431e-02, -9.955e-03, 6.950e-03, -2.831e-02, 3.119e-02, 2.644e-02, 2.242e-02, 5.158e-02, -1.303e-03, -3.862e-01, 1.708e-03, -1.616e-01, -3.232e-02) * s0[y+2][x+0];
	r += M4(1.074e-01, -1.388e-01, 1.030e-01, -1.790e-02, -1.323e-01, 8.457e-02, -4.838e-02, 9.993e-02, 8.834e-02, -4.402e-02, 1.043e-01, 8.318e-02, -1.578e-01, 8.968e-02, -1.272e-01, 1.626e-02) * s0[y+2][x+1];
	r += M4(-2.127e-02, -1.146e-02, 9.854e-03, -1.298e-02, 2.425e-02, 4.718e-02, -2.361e-02, -3.636e-02, 1.711e-01, -9.285e-02, 8.224e-02, -7.461e-03, 1.716e-02, 6.908e-02, -3.999e-02, -5.145e-02) * s0[y+2][x+2];
	r += M4(7.139e-02, -6.927e-02, -1.740e-02, -7.848e-03, -2.046e-01, 2.730e-01, 2.275e-02, -2.432e-01, 2.511e-02, -4.285e-02, 3.364e-02, -1.126e-02, 1.024e-01, -1.983e-01, 1.564e-01, 1.608e-01) * s1[y+0][x+0];
	r += M4(1.597e-01, 1.190e-01, 1.884e-02, -1.729e-01, -1.887e-01, 1.916e-01, -1.394e-01, -1.350e-01, 3.861e-02, -1.041e-01, 8.374e-02, -9.767e-02, 5.385e-02, -3.325e-02, 2.354e-01, -1.655e-01) * s1[y+0][x+1];
	r += M4(-9.640e-02, -8.200e-02, -5.183e-02, 1.890e-01, -8.632e-02, 1.374e-01, -9.615e-02, -6.982e-02, -7.275e-02, -1.267e-01, -9.029e-02, 3.820e-01, 3.691e-02, -1.068e-01, 3.277e-02, 5.184e-02) * s1[y+0][x+2];
	r += M4(1.098e-01, -2.510e-01, 2.628e-01, 6.082e-02, 5.454e-02, 8.405e-02, -7.254e-02, -1.674e-01, 6.715e-02, 1.024e-02, -1.462e-02, -3.132e-02, 4.627e-03, 5.704e-02, -4.504e-02, -2.652e-02) * s1[y+1][x+0];
	r += M4(8.420e-01, -2.327e-01, -9.458e-02, 1.964e-01, 5.769e-01, -1.203e+00, -3.674e-02, -1.728e-01, 8.138e-02, 4.971e-01, -1.769e-01, -7.714e-01, 1.272e-01, -5.783e-02, 1.618e-01, 7.855e-02) * s1[y+1][x+1];
	r += M4(6.182e-02, -1.510e-01, 1.281e-02, 6.315e-02, -1.447e-01, -1.373e-02, 6.431e-02, -1.931e-02, -3.117e-01, -4.753e-01, 2.434e-01, 1.051e+00, 1.003e-01, -3.542e-02, 6.745e-02, -8.921e-03) * s1[y+1][x+2];
	r += M4(1.753e-01, 3.211e-02, 7.007e-02, 2.678e-02, 8.472e-02, 4.404e-02, 1.210e-02, -3.118e-02, -5.113e-02, -5.487e-03, -1.197e-02, -3.307e-02, -4.089e-03, -8.504e-04, 6.684e-03, 7.270e-03) * s1[y+2][x+0];
	r += M4(4.580e-01, -1.637e-01, 1.990e-01, 1.329e-01, 3.284e-02, -1.025e-01, 3.751e-02, 9.926e-03, -7.558e-03, 1.022e-01, 1.419e-01, -3.003e-02, 2.777e-02, -3.992e-02, 2.851e-02, 1.486e-02) * s1[y+2][x+1];
	r += M4(-4.942e-02, -7.794e-02, -2.476e-02, 9.485e-02, 1.497e-03, -4.599e-02, -6.778e-02, -9.139e-02, 7.132e-01, -4.189e-01, 5.367e-01, 1.006e-01, 2.814e-02, -2.631e-03, 2.404e-02, -3.785e-03) * s1[y+2][x+2];
	r += V4(4.282e-03, -7.817e-03, 4.272e-03, 2.586e-03);
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


//!DESC CuNNy-4x4C-RCAS-DS-out
//!HOOK LUMA
//!COMPUTE 8 8 8 8
//!BIND conv4
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
#define l0(x, y) V4(texelFetch(conv4_raw, clamp(ipos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0))
shared V4 s0[10][10];
shared V4 s1[10][10];
vec4 f0(int x, int y) {
	V4 r = V4(0.0);
	r += M4(8.989e-02, 2.295e-02, 6.769e-03, 6.956e-03, 1.130e-01, 9.547e-03, 1.526e-02, 2.869e-02, 9.803e-02, 3.287e-02, -7.865e-03, -1.968e-02, 3.030e-02, 4.531e-03, 1.164e-02, -2.943e-03) * s0[y+0][x+0];
	r += M4(1.102e-01, 1.117e-01, -7.490e-02, -8.034e-02, 4.699e-03, 2.163e-01, -7.154e-02, -3.384e-02, -1.552e-01, -8.513e-03, 1.242e-02, -4.047e-03, -6.307e-02, 4.208e-03, 2.341e-02, 1.632e-02) * s0[y+0][x+1];
	r += M4(-1.935e-02, 1.642e-02, -2.033e-03, -1.147e-02, -1.732e-02, -4.211e-02, -1.398e-02, -2.075e-02, 2.302e-02, -5.153e-02, -1.352e-03, 2.842e-02, 1.157e-02, -3.210e-02, 8.336e-03, 2.484e-02) * s0[y+0][x+2];
	r += M4(-3.701e-02, -5.782e-03, 6.248e-02, 4.480e-02, 8.259e-02, -1.411e-01, 1.871e-01, -9.947e-02, -1.720e-01, 2.309e-02, 9.937e-03, -6.151e-02, 5.927e-02, -2.105e-02, 1.623e-02, -4.564e-03) * s0[y+1][x+0];
	r += M4(-4.218e-01, -3.018e-01, 2.725e-01, 1.841e-01, -1.039e-01, 3.680e-01, 9.785e-02, 5.918e-01, 5.639e-01, 3.545e-02, 1.184e-01, 1.379e-01, 3.316e-01, 2.716e-01, -3.381e-02, 3.335e-02) * s0[y+1][x+1];
	r += M4(4.389e-03, -1.296e-01, 4.960e-02, 1.419e-01, 5.356e-02, -1.356e-01, 4.577e-02, -7.306e-02, 8.294e-03, 3.043e-01, -4.032e-02, -5.937e-02, 2.269e-02, 2.095e-01, -1.234e-02, -3.866e-02) * s0[y+1][x+2];
	r += M4(-2.251e-02, -3.795e-02, 2.457e-02, -4.269e-02, -1.993e-02, 2.522e-02, -1.326e-02, -2.358e-02, 1.193e-01, -4.048e-02, -2.879e-02, 7.751e-02, -2.325e-02, -9.396e-03, 2.879e-02, -2.387e-02) * s0[y+2][x+0];
	r += M4(9.057e-02, 1.219e-01, -9.888e-02, 7.446e-02, 4.390e-02, -3.601e-02, -7.102e-02, 2.435e-02, 1.076e-01, 2.007e-01, -6.908e-02, -3.134e-01, -1.023e-01, -3.777e-02, 1.824e-01, 1.637e-01) * s0[y+2][x+1];
	r += M4(1.354e-02, 2.881e-02, 5.579e-02, -2.842e-02, -2.826e-02, 2.030e-02, -2.050e-03, -5.394e-02, 3.772e-02, 1.751e-02, -1.047e-01, -6.761e-02, -1.830e-02, -9.594e-02, -1.177e-03, 1.158e-01) * s0[y+2][x+2];
	r += M4(1.116e-01, -1.500e-02, 1.354e-03, 6.245e-03, 7.984e-02, 2.789e-02, 2.998e-03, -1.395e-02, 6.903e-02, 6.617e-02, 1.019e-03, -1.642e-02, 4.097e-02, 2.467e-02, 1.879e-02, -3.278e-03) * s1[y+0][x+0];
	r += M4(-9.447e-02, 1.382e-01, 3.775e-02, 5.594e-02, 5.205e-02, 4.917e-02, -7.716e-03, -2.675e-02, 1.241e-01, 5.277e-03, -1.163e-01, -5.819e-02, -5.065e-02, -5.231e-02, 2.378e-02, 2.922e-02) * s1[y+0][x+1];
	r += M4(-4.450e-02, -5.322e-03, -1.605e-02, 6.639e-02, -3.371e-02, 1.282e-02, -1.866e-02, 9.319e-03, -2.963e-02, 1.649e-02, 4.758e-02, -7.208e-02, -2.080e-02, 1.016e-02, -1.762e-02, 7.321e-03) * s1[y+0][x+2];
	r += M4(5.460e-02, -9.973e-02, 1.265e-01, -7.152e-02, 6.863e-02, -7.153e-02, 9.418e-02, -2.252e-02, -1.298e-01, 5.395e-02, -2.454e-02, 6.413e-02, 5.988e-02, -2.834e-02, 3.535e-02, 2.783e-02) * s1[y+1][x+0];
	r += M4(-2.515e-01, 1.658e-01, -3.395e-01, 1.652e-01, 2.397e-01, 3.722e-01, 2.134e-01, 2.529e-01, 2.216e-01, -1.938e-01, 5.274e-01, 4.829e-02, 2.533e-01, 3.076e-01, 9.692e-02, 5.062e-03) * s1[y+1][x+1];
	r += M4(8.666e-02, -3.120e-02, 4.024e-02, -7.016e-02, -2.892e-02, -8.665e-03, -1.581e-02, 4.390e-02, -2.585e-02, 1.071e-01, -1.092e-01, 1.787e-01, 6.505e-04, -3.095e-02, -2.802e-02, 5.418e-02) * s1[y+1][x+2];
	r += M4(-2.845e-02, 2.241e-02, 1.379e-03, -3.284e-02, -2.895e-02, 2.968e-02, 9.103e-03, 1.248e-02, 1.784e-02, 1.499e-04, -1.702e-02, 6.374e-02, -2.999e-02, -9.818e-03, 2.871e-02, -4.838e-02) * s1[y+2][x+0];
	r += M4(2.473e-02, 8.083e-04, -2.816e-02, 9.052e-02, -3.033e-02, -8.035e-02, 4.919e-02, 8.358e-02, 3.528e-02, -2.419e-02, -2.383e-02, -1.821e-01, -6.075e-02, -2.042e-02, 2.348e-02, 2.244e-01) * s1[y+2][x+1];
	r += M4(-6.934e-03, 2.222e-02, 2.703e-02, 8.915e-03, 1.643e-02, 2.061e-03, -1.236e-02, -4.943e-02, -2.765e-02, -1.365e-02, -3.577e-02, -1.431e-02, 4.348e-03, -5.879e-02, 4.946e-02, -1.323e-01) * s1[y+2][x+2];
	r += V4(8.176e-04, 6.593e-04, 7.569e-04, 7.094e-04);
	return tanh(vec4(r));
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


//!DESC CuNNy-4x4C-RCAS-DS-shuffle
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

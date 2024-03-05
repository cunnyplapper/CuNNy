// CuNNy 2x4C EASU NVL
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

//!MAGPIE EFFECT
//!VERSION 3
//!OUTPUT_WIDTH INPUT_WIDTH * 2
//!OUTPUT_HEIGHT INPUT_HEIGHT * 2

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
//!FORMAT R8_UNORM
Texture2D easu;

//!SAMPLER
//!FILTER POINT
SamplerState SP;

//!SAMPLER
//!FILTER LINEAR
SamplerState SL;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D t0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D t1;

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

//!PASS 1
//!DESC CuNNy-EASU
//!STYLE PS
//!IN INPUT
//!OUT easu

float GetLuma(float3 rgb) {
	return dot(float3(0.299, 0.587, 0.114), rgb);
}

float APrxLoRcpF1(float a) {
	return asfloat(uint(0x7ef07ebb) - asuint(a));
}

float APrxLoRsqF1(float a) {
	return asfloat(uint(0x5f347d74) - (asuint(a) >> uint(1)));
}

float AMin3F1(float x, float y, float z) {

	return min(x, min(y, z));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z));
}

void tap(inout float aC, inout float aW, float2 off, float2 dir, float2 len,
         float lob, float clp, float c){
	float2 v;
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

void set(inout float2 dir, inout float len, float2 pp, bool biS, bool biT,
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
	dir += float2(dirX, dirY) * w;
	len += dot(float2(w, w), float2(lenX, lenY));
}

float4 Pass1(float2 pos) {
	float2 pt = float2(GetInputPt());
	float2 size = float2(GetInputSize());
	float4 pix = float4(0.0, 0.0, 0.0, 1.0);
	float2 pp = pos * size - float2(0.5, 0.5);
	float2 fp = floor(pp);
	pp -= fp;
	float b = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(0.5, -0.5)) * pt), 0).rgb);
	float c = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(1.5, -0.5)) * pt), 0).rgb);
	float e = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(-0.5, 0.5)) * pt), 0).rgb);
	float f = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 0.5, 0.5)) * pt), 0).rgb);
	float g = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 1.5, 0.5)) * pt), 0).rgb);
	float h = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 2.5, 0.5)) * pt), 0).rgb);
	float i = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(-0.5, 1.5)) * pt), 0).rgb);
	float j = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 0.5, 1.5)) * pt), 0).rgb);
	float k = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 1.5, 1.5)) * pt), 0).rgb);
	float l = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 2.5, 1.5)) * pt), 0).rgb);
	float n = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(0.5, 2.5) ) * pt), 0).rgb);
	float o = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(1.5, 2.5) ) * pt), 0).rgb);
	float4 bczzL = float4(b, c, 0.0, 0.0);
	float4 ijfeL = float4(i, j, f, e);
	float4 klhgL = float4(k, l, h, g);
	float4 zzonL = float4(0.0, 0.0, o, n);
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
	float2 dir = float2(0.0, 0.0);
	float len = 0.0;
	set(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	set(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	set(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	set(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	float2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
	dir *= float2(dirR, dirR);
	len = len * 0.5;
	len *= len;
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	float2 len2 = float2(1.0 + (stretch - 1.0) * len, 1.0 + -0.5 * len);
	float lob = 0.5 + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	float clp = APrxLoRcpF1(lob);
	float aC = 0.0;
	float aW = 0.0;
	tap(aC, aW, float2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL);
	tap(aC, aW, float2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL);
	tap(aC, aW, float2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL);
	tap(aC, aW, float2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL);
	tap(aC, aW, float2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL);
	tap(aC, aW, float2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL);
	tap(aC, aW, float2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL);
	tap(aC, aW, float2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL);
	tap(aC, aW, float2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL);
	tap(aC, aW, float2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL);
	tap(aC, aW, float2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL);
	tap(aC, aW, float2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL);
	pix.r = aC / aW;
	float min1 = min(AMin3F1(fL, gL, jL), kL);
	float max1 = max(AMax3F1(fL, gL, jL), kL);
	pix.r = clamp(pix.r, min1, max1);
	pix.r = clamp(pix.r, 0.0, 1.0);
	return pix;
}

//!PASS 2
//!DESC CuNNy-2x4C-EASU-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(9.367e-01, 1.756e+00, 4.509e-01), O(INPUT, float2(x, y)).rgb) + -2.743e+00)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-1.222e-02, -5.223e-02, 4.819e-02, 2.352e-02) * s0_0;
	r += V4(-1.871e-02, -6.783e-02, 6.214e-02, -1.998e-03) * s0_1;
	r += V4(3.032e-02, 9.058e-02, -5.338e-02, -3.308e-02) * s0_2;
	r += V4(4.699e-02, 1.107e-02, 2.244e-01, -9.905e-04) * s0_3;
	r += V4(-3.708e-01, 2.297e-01, -4.502e-01, -3.403e-01) * s0_4;
	r += V4(-6.113e-03, -2.025e-01, 5.700e-02, 3.545e-01) * s0_5;
	r += V4(-4.187e-02, 4.700e-02, -8.451e-02, 3.223e-02) * s0_6;
	r += V4(3.974e-01, 1.357e-01, 1.213e-01, -1.990e-02) * s0_7;
	r += V4(-2.313e-02, -1.897e-01, 7.300e-02, -1.407e-02) * s0_8;
	r += V4(-8.335e-04, 5.362e-03, -2.085e-03, -1.666e-03);
	return r;
}
void Pass2(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	min16float s0_0 = l0(-1.0, -1.0);
	min16float s0_1 = l0(0.0, -1.0);
	min16float s0_2 = l0(1.0, -1.0);
	min16float s0_3 = l0(-1.0, 0.0);
	min16float s0_4 = l0(0.0, 0.0);
	min16float s0_5 = l0(1.0, 0.0);
	min16float s0_6 = l0(-1.0, 1.0);
	min16float s0_7 = l0(0.0, 1.0);
	min16float s0_8 = l0(1.0, 1.0);
	t0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 3
//!DESC CuNNy-2x4C-EASU-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(1.606e-01, -1.968e-01, 4.640e-02, 1.372e-01, -7.711e-03, -2.741e-01, -6.708e-02, -2.055e-01, -6.769e-02, 1.150e-01, -1.354e-02, -7.638e-02, 7.785e-02, -3.771e-01, 1.401e-01, -6.399e-02));
	r += mul(s0_1, M4(3.138e-01, -7.090e-01, 2.327e-02, -7.007e-02, -4.121e-01, -1.034e-01, -1.022e-02, -7.161e-02, 9.026e-02, -2.977e-02, -2.024e-02, 2.787e-04, -5.055e-02, 2.238e-01, 3.943e-02, 1.275e-02));
	r += mul(s0_2, M4(7.694e-02, 2.924e-02, -7.530e-02, -2.057e-02, -1.335e-01, -3.564e-02, 8.989e-02, -4.190e-02, 1.830e-01, 1.597e-01, 2.292e-02, -3.837e-02, 1.497e-01, 3.441e-03, 9.557e-02, -1.188e-01));
	r += mul(s0_3, M4(-3.754e-01, 1.175e-01, 1.033e-01, 9.584e-02, 1.278e-01, 1.820e-03, 4.357e-02, -7.951e-03, 2.432e-02, 1.665e-03, -7.723e-02, 6.424e-02, 3.272e-01, -1.355e-01, 2.495e-01, 1.175e-01));
	r += mul(s0_4, M4(-5.053e-01, 3.284e-02, 1.255e-01, -1.997e-01, 1.675e-01, -3.330e-01, -3.885e-02, -5.821e-02, -1.444e-02, 8.924e-02, 1.728e-02, 1.972e-01, 1.959e-01, -1.016e-01, 1.238e-01, 4.406e-02));
	r += mul(s0_5, M4(-2.330e-02, -1.288e-01, -2.424e-01, -1.100e-03, -1.656e-01, 4.235e-02, -6.502e-01, 4.973e-01, 1.262e-01, -4.152e-02, -1.299e-01, 2.310e-01, 1.500e-01, 1.514e-01, -1.617e-01, 1.746e-01));
	r += mul(s0_6, M4(-6.519e-02, -1.179e-01, 1.399e-02, -5.948e-02, 1.986e-02, 1.808e-02, -8.342e-03, 2.882e-02, 1.911e-02, 6.566e-02, -4.105e-02, 6.251e-02, -4.132e-01, -3.387e-03, 1.130e-01, -2.636e-02));
	r += mul(s0_7, M4(3.881e-03, -5.672e-02, 9.755e-02, 6.044e-02, 2.014e-01, 3.232e-01, -1.499e-01, -1.111e-01, -4.955e-02, -1.348e-01, -9.257e-02, -1.203e-01, -1.430e-01, 3.467e-01, 1.690e-01, -1.187e-03));
	r += mul(s0_8, M4(6.010e-02, 2.466e-01, -6.664e-02, 1.322e-02, 9.097e-03, -3.502e-02, -5.146e-02, 5.713e-02, -1.961e-01, -7.980e-02, -6.143e-02, 1.529e-02, 2.720e-02, 1.530e-02, -9.481e-02, 1.411e-01));
	r += mul(s1_0, M4(1.573e-01, -2.900e-01, -9.576e-02, -2.172e-01, 1.445e-01, -1.574e-01, 4.832e-02, -1.698e-01, -9.494e-02, 1.596e-02, -1.740e-02, -1.182e-01, -1.092e-01, -6.068e-02, 3.557e-02, -5.275e-02));
	r += mul(s1_1, M4(-3.173e-02, -3.530e-01, -1.453e-01, 6.451e-02, 8.191e-02, 3.525e-01, 2.939e-01, 3.394e-02, 1.546e-03, -5.293e-01, 3.399e-02, -2.959e-01, -2.027e-01, 4.368e-01, 1.233e-01, 1.012e-01));
	r += mul(s1_2, M4(-1.304e-01, 1.067e-01, 1.472e-01, 5.618e-02, 3.173e-01, 1.603e-01, 6.315e-02, -6.354e-02, -1.089e-01, 6.185e-02, 6.091e-02, 2.135e-02, -4.795e-03, -4.336e-02, 1.440e-01, -8.411e-02));
	r += mul(s1_3, M4(-1.629e-01, -6.113e-02, 4.456e-02, -9.648e-02, 6.511e-02, 1.319e-02, -3.566e-02, -2.464e-01, 2.388e-01, 1.419e-02, 7.632e-02, 1.282e-01, 1.177e-01, -2.436e-01, -2.262e-02, 2.142e-01));
	r += mul(s1_4, M4(-2.231e-01, -4.394e-02, -1.558e-02, -1.235e-01, -4.167e-02, -1.426e-01, 3.918e-01, 8.472e-02, 2.342e-02, -2.260e-01, 4.014e-01, -5.745e-01, -3.000e-01, -9.584e-02, 8.130e-01, 2.395e-01));
	r += mul(s1_5, M4(-1.286e-01, 1.297e-02, -1.494e-01, 7.252e-02, 1.073e-01, 1.096e-01, -2.279e-01, 3.205e-01, 8.705e-02, 1.533e-01, -2.083e-01, 3.369e-01, -2.397e-01, -2.988e-02, -3.107e-01, 2.585e-01));
	r += mul(s1_6, M4(8.285e-02, -1.294e-01, 4.487e-02, -5.341e-02, -6.503e-03, 3.470e-03, 2.031e-03, 5.552e-02, -1.262e-01, 2.657e-02, -5.921e-03, 4.096e-02, 1.219e-01, -6.107e-03, 8.979e-03, -8.456e-02));
	r += mul(s1_7, M4(1.059e-01, -5.232e-03, 1.470e-01, 6.681e-02, -5.695e-02, 2.919e-01, -2.021e-01, -2.863e-02, -1.417e-01, -2.376e-01, 1.063e-01, -1.097e-01, 2.778e-01, 3.214e-01, -1.227e-01, -1.609e-01));
	r += mul(s1_8, M4(1.733e-01, 2.568e-01, -6.796e-02, -4.277e-02, -6.612e-02, -5.555e-02, 6.125e-02, 1.261e-02, -8.532e-02, -4.414e-02, -1.901e-02, 8.276e-02, -4.131e-02, -3.019e-02, -3.951e-01, 2.372e-01));
	r += V4(-1.393e-03, -4.853e-03, -1.290e-03, 3.885e-03);
	return r;
}
void Pass3(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t1[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 4
//!DESC CuNNy-2x4C-EASU-NVL-conv2
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t1
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t1, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(8.811e-03, 7.088e-02, -1.421e-01, 3.815e-02, 3.654e-02, -1.941e-02, -1.572e-01, -1.659e-02, -3.466e-01, -3.738e-02, 2.900e-01, -5.137e-01, -7.102e-03, -2.384e-03, 4.408e-02, 1.169e-02));
	r += mul(s0_1, M4(-8.324e-02, 2.026e-02, 5.045e-02, -1.345e-01, 2.553e-02, -6.142e-02, -1.154e-01, -4.639e-02, 9.562e-02, 9.281e-02, -3.620e-02, -2.601e-01, -1.475e-01, 2.639e-02, 6.984e-02, 7.099e-02));
	r += mul(s0_2, M4(6.039e-02, -3.055e-02, -8.613e-02, -4.016e-02, -1.518e-02, -1.156e-02, 3.183e-02, -7.594e-02, -3.363e-02, -7.969e-03, -1.441e-01, 5.021e-02, 9.163e-02, -4.007e-03, -2.385e-02, 9.354e-02));
	r += mul(s0_3, M4(3.050e-02, 1.840e-01, -8.569e-02, 9.415e-02, -1.605e-01, -5.309e-02, 1.058e-01, 4.651e-02, -3.487e-01, 4.410e-02, -2.622e-01, 8.513e-01, 3.410e-02, -2.452e-02, -3.894e-02, -6.896e-02));
	r += mul(s0_4, M4(-4.929e-01, -1.527e-02, -2.131e-01, 1.048e-03, -8.943e-02, -1.145e-01, 7.090e-01, 3.035e-01, 7.954e-01, 4.302e-01, -6.980e-01, 6.962e-01, 2.831e-02, -5.266e-02, 1.237e-02, -5.925e-01));
	r += mul(s0_5, M4(9.759e-02, -5.704e-02, -5.896e-02, 1.197e-01, -6.841e-02, 8.960e-02, -2.985e-02, 7.363e-02, -3.593e-01, -2.114e-01, 2.145e-01, 2.901e-02, 1.394e-01, -9.563e-02, 1.281e-01, -1.597e-01));
	r += mul(s0_6, M4(-4.744e-02, 5.586e-02, 1.542e-02, 1.199e-02, -3.616e-02, -1.806e-01, -5.478e-03, 3.256e-01, -2.443e-01, 4.578e-01, 6.922e-02, -3.665e-01, 2.899e-02, 5.697e-02, -3.210e-02, -4.257e-02));
	r += mul(s0_7, M4(-2.897e-02, 3.192e-02, 6.049e-03, 1.618e-01, -4.789e-01, -1.223e+00, 2.616e-02, -1.063e-01, 6.074e-01, -1.528e+00, -4.977e-02, -1.424e-01, 2.065e-01, 3.252e-02, -5.192e-02, -1.316e-01));
	r += mul(s0_8, M4(-5.460e-02, -3.283e-02, 1.836e-02, 6.253e-02, -2.942e-02, 8.247e-03, -8.193e-03, 3.893e-02, -3.926e-01, 2.847e-01, -7.170e-03, -2.295e-01, -4.937e-02, -1.892e-01, 1.216e-02, -4.190e-02));
	r += mul(s1_0, M4(3.235e-02, 5.077e-02, -9.473e-02, 1.343e-02, -5.027e-02, 2.949e-02, -3.658e-02, 2.423e-02, -7.794e-02, -4.113e-02, -1.540e-02, -6.181e-02, 5.252e-02, 4.430e-02, -8.028e-02, 1.371e-01));
	r += mul(s1_1, M4(1.167e-01, 3.473e-02, -2.710e-01, 3.068e-01, 1.314e-01, 1.505e-02, -4.652e-02, -6.210e-02, -5.927e-02, -1.963e-02, 7.398e-03, 7.607e-02, -1.781e-01, -4.621e-02, -1.938e-01, 1.811e-01));
	r += mul(s1_2, M4(1.445e-01, -1.668e-02, -2.865e-02, -4.944e-02, 5.041e-03, -2.576e-03, -2.777e-03, -4.260e-02, 4.006e-02, 2.283e-04, -3.090e-02, 1.393e-02, 7.820e-02, -1.351e-03, -1.174e-01, -2.772e-02));
	r += mul(s1_3, M4(-4.583e-02, 1.481e-02, 1.665e-02, 3.255e-02, -7.145e-02, 5.876e-02, 1.111e-01, -1.460e-01, -1.576e-01, 4.968e-02, -2.086e-02, 2.133e-01, 7.720e-02, 5.022e-02, -6.736e-02, -9.423e-02));
	r += mul(s1_4, M4(9.104e-02, 6.095e-02, 1.725e-02, -1.294e-01, 1.526e-01, 1.175e-02, 2.941e-01, 1.949e-01, 2.644e-01, 9.359e-02, -1.174e-01, -8.923e-02, 3.316e-01, -2.670e-01, -1.156e+00, -1.668e-01));
	r += mul(s1_5, M4(-3.697e-02, -4.622e-02, 2.626e-02, 3.646e-02, -1.003e-01, 2.733e-02, 2.640e-02, 7.015e-02, 3.127e-02, -5.352e-03, -1.587e-02, 3.715e-02, 1.043e-01, -8.767e-02, -9.534e-02, 1.179e-01));
	r += mul(s1_6, M4(2.485e-02, -6.138e-04, 4.485e-04, 2.769e-02, 6.279e-02, 9.593e-02, -1.123e-02, 1.751e-02, 9.851e-03, -4.155e-02, 3.408e-03, 5.958e-03, -1.131e-01, 1.669e-02, 5.118e-03, 2.721e-02));
	r += mul(s1_7, M4(-1.551e-02, -2.017e-03, -6.440e-03, -4.923e-02, -2.206e-03, -1.551e-01, -3.732e-02, -1.082e-01, 3.503e-02, 3.356e-02, 2.385e-03, -3.225e-03, 1.346e-02, -1.033e-01, 6.141e-03, 1.149e+00));
	r += mul(s1_8, M4(-1.495e-04, -1.053e-02, 8.904e-03, 1.467e-02, -8.010e-02, 1.140e-01, -2.367e-02, -1.199e-01, 2.727e-02, -1.437e-03, 1.463e-02, 2.941e-02, -7.788e-02, -2.046e-02, -2.294e-02, 1.593e-01));
	r += V4(-5.294e-03, -4.264e-04, 3.805e-03, -1.221e-03);
	return r;
}
void Pass4(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 5
//!DESC CuNNy-2x4C-EASU-NVL-out
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(7.859e-03, -3.801e-03, 1.969e-02, 2.051e-02, -8.783e-01, 5.222e-01, -2.902e-01, 2.435e-01, 1.508e-03, -2.728e-02, -6.398e-03, 7.185e-03, 5.189e-02, -2.017e-01, 3.819e-02, 9.044e-03));
	r += mul(s0_1, M4(5.780e-02, 1.495e-01, 5.555e-02, -4.926e-02, 5.824e-01, -5.911e-01, -7.669e-02, 3.527e-01, -1.849e-02, 3.634e-04, 2.458e-02, 1.437e-02, -1.326e-01, 1.987e-01, -4.869e-02, -1.717e-02));
	r += mul(s0_2, M4(1.401e-01, -2.822e-01, 6.747e-03, -4.706e-03, -3.652e-02, 9.109e-02, -2.406e-02, -4.634e-02, 1.886e-02, -1.013e-02, 1.688e-02, 6.422e-03, -4.191e-03, -1.865e-01, 2.298e-02, 3.427e-02));
	r += mul(s0_3, M4(7.853e-02, -8.018e-02, -1.657e-03, -8.081e-02, 3.346e-01, -8.188e-02, -2.380e-01, 2.038e-01, 6.930e-03, 7.264e-02, 6.477e-03, 1.451e-02, 4.160e-01, 7.146e-02, -4.894e-01, 1.048e-01));
	r += mul(s0_4, M4(-1.127e+00, 3.935e-01, -6.606e-01, 7.129e-01, 2.282e-01, -3.459e-01, 1.146e+00, -1.341e+00, -1.988e-02, -3.779e-01, -4.698e-02, -1.978e-01, 4.647e-01, 6.348e-01, -5.567e-01, -1.129e+00));
	r += mul(s0_5, M4(2.816e-02, 2.748e-01, 1.558e-01, -3.018e-01, -2.360e-01, 2.870e-01, -1.338e-01, 5.174e-02, -1.948e-02, 8.781e-02, 1.069e-02, 3.723e-02, -2.575e-02, 9.303e-02, 8.915e-02, 3.493e-02));
	r += mul(s0_6, M4(2.891e-02, -1.559e-02, 1.393e-01, -2.251e-02, -7.930e-02, -6.469e-03, -4.042e-02, -8.159e-02, 8.179e-02, 1.986e-02, 6.929e-02, 4.064e-02, -1.494e-02, 9.841e-03, 4.115e-02, -2.147e-02));
	r += mul(s0_7, M4(2.685e-01, 5.610e-02, -2.312e-01, -6.559e-03, 7.898e-03, 8.967e-02, -1.545e-01, -2.146e-02, -9.644e-02, -2.592e-02, -6.091e-02, -1.264e-01, -4.186e-02, -3.397e-02, -1.522e-02, 8.463e-02));
	r += mul(s0_8, M4(-8.523e-02, -3.924e-02, -7.985e-02, 2.691e-01, -2.474e-02, 3.694e-02, -1.069e-01, 3.880e-01, 5.784e-02, -7.694e-03, 5.728e-02, 5.479e-02, 1.967e-02, -6.718e-03, 6.697e-03, -9.976e-03));
	r += mul(s1_0, M4(3.967e-02, 1.791e-02, 1.308e-02, 1.230e-02, -2.759e-02, 1.016e-02, -6.761e-02, 2.469e-03, 6.447e-03, 2.442e-02, 7.928e-03, -4.247e-03, 8.945e-03, -1.603e-02, 4.832e-03, -1.005e-02));
	r += mul(s1_1, M4(3.748e-02, 1.715e-02, 3.767e-04, 1.585e-02, 5.286e-02, -1.325e-01, 1.924e-01, -2.545e-02, 5.553e-03, 1.670e-02, -5.485e-02, -1.769e-02, -7.036e-02, 4.729e-04, -3.648e-02, 1.243e-02));
	r += mul(s1_2, M4(-1.226e-02, 1.416e-02, -6.129e-03, -9.404e-03, -1.224e-02, 5.709e-02, -4.529e-02, 4.958e-02, -6.897e-05, -3.190e-05, 1.223e-02, -8.902e-03, 1.552e-02, -1.828e-02, 3.351e-02, -8.498e-03));
	r += mul(s1_3, M4(-1.079e-01, 6.335e-03, -2.349e-02, 6.253e-02, 3.441e-02, -1.077e-04, 3.254e-02, 7.570e-04, 5.850e-02, 1.687e-01, -3.891e-02, -2.417e-02, 4.210e-02, 1.133e-02, 3.455e-02, -2.371e-03));
	r += mul(s1_4, M4(-7.757e-02, -1.822e-01, -3.275e-02, -1.578e-01, 2.944e-02, 3.654e-02, -1.179e-01, -8.407e-02, -4.563e-01, -4.117e-01, 1.406e-01, 1.313e-01, -1.753e-01, -5.242e-02, -1.636e-01, -2.085e-02));
	r += mul(s1_5, M4(6.278e-03, 2.941e-03, -1.139e-02, 1.678e-02, 1.368e-02, 1.755e-02, 1.513e-02, -1.605e-02, 5.695e-02, -1.238e-01, 6.567e-02, 6.472e-02, 6.615e-02, -1.373e-02, 6.574e-02, 2.574e-02));
	r += mul(s1_6, M4(5.831e-02, 2.125e-02, 1.712e-02, -2.821e-03, -1.343e-02, -1.517e-03, -1.059e-03, -1.603e-03, 2.817e-02, -1.265e-01, 6.013e-02, 1.460e-01, 9.127e-03, 1.889e-03, 2.069e-02, 8.342e-03));
	r += mul(s1_7, M4(1.654e-02, 1.222e-02, 2.297e-02, -1.104e-02, -2.130e-02, -1.125e-02, -2.190e-03, 5.417e-03, 1.024e+00, 7.259e-01, -1.088e+00, -8.711e-01, 3.344e-03, 1.666e-02, -1.017e-02, 8.574e-03));
	r += mul(s1_8, M4(-3.932e-03, 3.791e-03, 6.662e-03, 1.062e-02, 2.902e-03, -7.376e-03, -3.757e-03, 7.582e-03, -3.424e-02, 2.915e-01, 1.449e-01, -1.592e-01, -2.831e-03, 1.253e-03, 9.560e-03, -1.571e-03));
	r += V4(-3.417e-04, 6.462e-04, -2.036e-04, 6.225e-04);
	return tanh(r);
}
void Pass5(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t1[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 6
//!DESC CuNNy-2x4C-EASU-NVL-shuffle
//!STYLE PS
//!IN t1, INPUT, easu
float4 Pass6(float2 pos) {
	float2 pt = float2(GetInputPt());
	static const float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	static const float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = t1.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += easu.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

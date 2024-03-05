// CuNNy 2x4C EASU NVL DS
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
//!DESC CuNNy-2x4C-EASU-NVL-DS-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(-7.022e-01, -1.249e+00, -3.089e-01), O(INPUT, float2(x, y)).rgb) + 1.468e+00)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-7.348e-02, -2.653e-02, 6.670e-02, 4.073e-02) * s0_0;
	r += V4(3.817e-01, -1.528e-01, -6.508e-01, -3.147e-02) * s0_1;
	r += V4(2.107e-01, 2.221e-02, 5.380e-02, -1.484e-03) * s0_2;
	r += V4(-2.124e-02, -2.107e-01, -3.470e-02, -6.309e-01) * s0_3;
	r += V4(-3.604e-01, 4.912e-01, 6.074e-01, 6.581e-01) * s0_4;
	r += V4(-5.928e-02, -4.152e-02, -3.084e-02, -9.841e-03) * s0_5;
	r += V4(1.126e-01, 3.258e-02, -3.772e-02, 7.070e-02) * s0_6;
	r += V4(-3.426e-02, -5.640e-02, 4.894e-02, -9.842e-02) * s0_7;
	r += V4(-1.567e-01, 4.079e-03, -2.006e-02, 5.038e-03) * s0_8;
	r += V4(2.306e-08, -7.251e-02, -2.424e-04, -1.714e-03);
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
//!DESC CuNNy-2x4C-EASU-NVL-DS-conv1
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
	r += mul(s0_0, M4(-1.682e-02, -1.433e-01, -2.373e-01, 6.039e-02, 2.082e-01, -1.674e-01, -6.455e-02, 4.731e-03, -1.938e-01, 6.103e-02, -1.743e-02, 4.342e-02, -2.167e-02, 3.009e-02, 4.739e-02, -3.951e-02));
	r += mul(s0_1, M4(-8.701e-02, -2.664e-01, -1.617e-01, -2.006e-01, 7.946e-02, -1.824e-01, -1.259e-01, -3.848e-01, -3.193e-01, -2.086e-01, -1.394e-01, 1.327e-01, -1.724e-01, 2.263e-01, 2.378e-02, 3.174e-01));
	r += mul(s0_2, M4(6.884e-03, 1.695e-02, 2.455e-02, -5.324e-02, -2.651e-01, -8.152e-02, 1.122e-01, -4.306e-02, -3.563e-02, -1.379e-01, -1.880e-01, 9.204e-02, -8.162e-02, 1.439e-02, 5.288e-02, 1.705e-01));
	r += mul(s0_3, M4(3.604e-01, 1.056e-02, -3.259e-01, -8.695e-03, 8.251e-02, -1.266e-01, 1.164e-01, 3.100e-01, 7.110e-02, -8.541e-02, 1.587e-01, -3.425e-01, -1.106e-01, 5.799e-02, -8.666e-02, -9.542e-02));
	r += mul(s0_4, M4(1.236e-01, 5.566e-01, 3.832e-01, -1.239e-01, -3.683e-01, 2.467e-01, -2.277e-01, 5.680e-02, 2.180e-01, -3.988e-01, 1.130e-01, 4.283e-02, 2.600e-01, -3.429e-01, 6.934e-01, -8.228e-02));
	r += mul(s0_5, M4(-4.594e-02, -1.175e-02, 4.431e-02, 1.270e-01, -1.239e-01, -1.467e-02, -3.836e-02, -2.626e-01, -6.005e-02, -7.132e-02, -7.970e-02, 3.900e-01, 8.363e-02, 5.653e-02, -4.606e-01, 9.724e-01));
	r += mul(s0_6, M4(-4.657e-02, -1.293e-01, 2.209e-02, 4.553e-01, -1.305e-01, 3.110e-02, -3.219e-02, 1.951e-03, -1.168e-01, 3.202e-01, -3.060e-02, 8.486e-02, 8.774e-02, 3.804e-02, 1.814e-02, 1.026e-03));
	r += mul(s0_7, M4(-1.990e-01, 3.219e-01, 1.789e-03, -1.238e-01, 1.407e-01, -2.612e-01, -2.335e-01, -1.513e-01, -1.056e-01, 1.265e-01, -3.687e-01, -1.064e-01, -3.229e-02, 2.913e-01, 2.300e-01, 1.142e-02));
	r += mul(s0_8, M4(1.577e-01, -8.094e-02, 1.260e-01, 5.777e-02, 2.958e-01, 7.237e-02, 3.340e-01, 3.174e-01, 7.574e-02, -9.308e-02, -3.989e-01, -2.946e-02, -3.633e-02, -2.447e-02, -3.039e-01, -3.564e-01));
	r += mul(s1_0, M4(-2.542e-01, -1.696e-03, -6.547e-02, 7.442e-03, 5.744e-02, -6.809e-02, 1.015e-01, 2.096e-02, -6.600e-03, 1.534e-02, -1.812e-01, 1.865e-02, 2.154e-02, -9.486e-02, -4.474e-02, -2.318e-02));
	r += mul(s1_1, M4(-3.189e-01, -5.077e-01, -2.228e-01, 1.459e-01, -3.290e-01, -4.875e-01, 8.740e-02, 9.356e-02, -2.152e-02, -5.123e-02, -2.459e-01, -1.655e-01, 5.018e-02, 2.678e-01, -1.703e-01, -7.834e-03));
	r += mul(s1_2, M4(1.638e-02, 8.659e-02, -8.959e-02, -2.240e-02, -4.015e-01, 1.755e-05, 5.529e-02, 2.165e-01, 1.121e-01, -9.301e-02, -1.111e-01, -1.631e-01, 1.477e-01, 3.223e-01, 1.086e-01, -6.309e-02));
	r += mul(s1_3, M4(-3.919e-02, 1.086e-01, -2.599e-03, -2.547e-01, -5.413e-02, 4.251e-01, 3.537e-01, 5.622e-02, 4.970e-01, -3.899e-01, -2.375e-01, -1.143e-01, -3.870e-02, -5.520e-02, -2.134e-01, -2.793e-02));
	r += mul(s1_4, M4(3.179e-01, 5.700e-02, -1.376e-01, 3.135e-01, 1.210e-01, -2.087e-01, -6.299e-02, -1.003e-01, 6.295e-01, 3.863e-01, -1.450e-02, -1.384e-01, 2.117e-01, -6.218e-01, 1.598e-01, 9.699e-02));
	r += mul(s1_5, M4(-1.607e-02, -5.704e-03, -2.183e-01, 2.108e-02, -8.865e-02, -1.804e-01, -3.268e-01, -1.855e-01, -6.953e-02, 3.518e-01, 3.013e-01, -2.505e-02, -2.510e-01, 5.293e-01, -1.028e-01, 2.685e-01));
	r += mul(s1_6, M4(-1.876e-01, 1.266e-01, -1.089e-01, -2.362e-01, -8.604e-02, 4.118e-01, -8.081e-02, 3.566e-02, -1.519e-01, -3.564e-01, -2.782e-02, 2.878e-01, 7.992e-02, -1.929e-01, -2.195e-02, -1.471e-02));
	r += mul(s1_7, M4(1.561e-01, -1.242e-01, -3.605e-01, -3.875e-01, 2.843e-01, 1.027e-01, -2.099e-01, -1.095e-01, -5.332e-01, 1.738e-01, 1.132e-01, 4.093e-01, -2.261e-01, -3.247e-01, 1.460e-01, -5.118e-03));
	r += mul(s1_8, M4(4.962e-03, -4.923e-02, 7.365e-02, -3.993e-02, 5.293e-01, -1.386e-02, 9.712e-02, -3.931e-02, -4.308e-01, 7.285e-02, -5.106e-02, 1.441e-01, -5.432e-01, 8.580e-02, -6.467e-03, -2.474e-01));
	r += V4(1.979e-03, 3.162e-03, 5.076e-03, 6.298e-03);
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
//!DESC CuNNy-2x4C-EASU-NVL-DS-conv2
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
	r += mul(s0_0, M4(-4.135e-02, -7.526e-02, 6.290e-03, -8.040e-02, -3.183e-02, 2.235e-02, 2.057e-02, 5.310e-02, -6.675e-02, -4.983e-02, 5.635e-02, -1.314e-02, 9.126e-03, 8.545e-02, -4.204e-02, 3.150e-03));
	r += mul(s0_1, M4(1.831e-01, -4.950e-02, -7.567e-02, -3.462e-02, -5.016e-02, -8.294e-02, -8.301e-03, 8.981e-02, -1.040e-01, -2.627e-01, -2.768e-03, -7.439e-02, 5.607e-03, -1.393e-01, 3.728e-02, -5.797e-02));
	r += mul(s0_2, M4(8.175e-02, 1.291e-01, 1.366e-01, -1.040e-01, -7.966e-02, 9.440e-02, -7.091e-02, 4.782e-02, -7.350e-03, 1.003e-01, 5.303e-03, 7.053e-02, 3.530e-02, 2.074e-02, -1.316e-02, -3.446e-02));
	r += mul(s0_3, M4(-4.177e-02, -1.440e-01, 1.841e-01, -3.651e-03, -1.386e-03, -3.304e-02, -3.371e-03, -7.950e-02, 7.592e-02, -9.597e-02, -4.509e-02, 8.716e-04, -4.089e-02, 6.420e-02, -3.360e-02, -3.961e-02));
	r += mul(s0_4, M4(-1.374e-01, -1.515e-01, -8.920e-01, 1.582e-01, -2.360e-02, -1.101e-01, -6.352e-02, -1.684e-01, 1.269e-01, 2.508e-01, -3.770e-02, 7.601e-02, -3.377e-02, -3.951e-01, -4.450e-02, 1.013e-01));
	r += mul(s0_5, M4(4.378e-02, 8.975e-02, 2.359e-01, -2.510e-01, 5.417e-02, 4.022e-01, 2.682e-01, -7.732e-02, -3.070e-02, 1.705e-02, 1.423e-01, -6.548e-02, -3.333e-02, 4.671e-02, -5.097e-02, -3.708e-02));
	r += mul(s0_6, M4(-3.512e-02, -6.214e-02, 6.030e-02, -5.761e-02, -1.371e-02, 3.230e-02, 5.956e-03, -1.013e-02, -3.371e-02, 9.264e-02, 4.230e-02, -1.125e-05, -1.407e-02, 2.345e-02, -8.590e-03, -9.344e-03));
	r += mul(s0_7, M4(9.507e-03, -3.685e-02, -1.812e-01, 6.666e-02, 6.058e-02, 5.343e-02, -7.084e-02, 2.719e-02, -3.729e-02, 6.171e-04, -3.478e-02, 1.317e-02, 1.883e-02, -1.156e-01, 1.052e-02, -5.410e-02));
	r += mul(s0_8, M4(-3.181e-03, -5.305e-02, -3.317e-02, -5.198e-02, -7.492e-03, 1.374e-01, 1.812e-01, -2.701e-01, -3.454e-02, -3.386e-02, 1.627e-01, 1.311e-01, -2.900e-02, 3.233e-02, -4.011e-02, 2.868e-02));
	r += mul(s1_0, M4(-2.679e-02, -1.780e-02, 1.170e-02, 3.025e-02, -6.979e-02, -1.562e-01, 7.293e-02, -7.234e-03, -2.074e-01, -2.017e-01, -1.011e-01, -7.332e-02, -5.451e-02, 1.012e-01, 5.965e-03, -1.444e-02));
	r += mul(s1_1, M4(-1.173e-03, 1.283e-01, -3.504e-02, 3.218e-03, -2.384e-02, -6.158e-02, -4.630e-02, -6.912e-03, -4.577e-02, 8.500e-02, 1.103e-01, -6.569e-02, -1.927e-02, 3.650e-01, 4.669e-02, -2.097e-01));
	r += mul(s1_2, M4(3.632e-02, -9.008e-02, 5.740e-03, -5.792e-02, -2.037e-02, 2.578e-02, 4.642e-02, 2.868e-02, 5.886e-04, 8.095e-02, -3.890e-02, -3.205e-02, 3.824e-02, 2.427e-01, 1.565e-01, -5.597e-02));
	r += mul(s1_3, M4(-2.201e-02, -1.072e-01, 8.780e-02, 2.844e-02, -3.278e-02, -1.679e-01, -1.606e-01, -6.669e-02, 1.773e+00, -3.170e-01, -1.909e-01, 1.991e-01, 4.372e-02, 1.081e-01, -1.392e-01, -1.188e-01));
	r += mul(s1_4, M4(1.062e-01, 3.493e-01, -8.404e-02, 1.147e-01, 6.508e-02, 3.679e-01, 2.372e-01, 2.635e-01, -1.702e-02, -1.246e-01, 1.345e-01, 2.576e-01, 2.998e-01, -1.150e-01, 4.728e-01, -4.936e-01));
	r += mul(s1_5, M4(6.122e-03, -1.251e-01, 1.144e-01, -8.132e-02, 1.091e-01, 4.574e-02, 7.971e-02, -7.495e-02, -1.875e-02, 4.378e-02, -2.612e-02, 1.639e-02, 5.063e-02, 1.974e-01, 2.291e-01, -2.199e-01));
	r += mul(s1_6, M4(-1.621e-01, 2.628e-03, 2.284e-01, -1.114e-01, 2.266e-02, -7.933e-02, -1.336e-01, -3.542e-02, 4.314e-02, 8.233e-02, -6.415e-02, 2.364e-01, -3.061e-03, -2.017e-02, 3.689e-03, -5.291e-02));
	r += mul(s1_7, M4(-1.100e-01, -1.184e-01, -4.048e-01, 5.388e-01, 1.661e-01, 2.030e-01, 2.191e-01, -2.026e-01, -2.711e-02, 1.949e-01, 1.865e-01, 2.307e-01, -6.494e-02, -3.747e-02, 7.577e-02, -4.523e-02));
	r += mul(s1_8, M4(-5.027e-02, 1.264e-01, 1.690e-01, 1.349e-01, 1.199e-02, 6.216e-02, 1.656e-01, -2.346e-01, -8.714e-03, 4.335e-02, 7.607e-02, 3.425e-02, 1.716e-02, -3.901e-03, -2.522e-02, 1.663e-02));
	r += V4(-1.163e-03, -5.602e-03, -5.012e-03, -1.892e-03);
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
//!DESC CuNNy-2x4C-EASU-NVL-DS-out
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
	r += mul(s0_0, M4(-9.944e-03, -1.618e-02, 1.374e-02, -1.695e-02, 3.358e-02, -5.404e-03, -5.121e-03, 1.378e-02, -6.625e-02, -1.074e-03, 1.697e-03, -9.699e-03, -5.124e-01, -6.268e-02, 1.890e-01, 3.614e-02));
	r += mul(s0_1, M4(9.801e-02, -6.413e-02, -8.304e-02, 3.853e-03, -7.140e-02, 1.200e-01, 1.283e-01, 1.353e-02, 3.139e-01, -2.290e-01, -2.421e-02, -3.056e-02, 8.975e-02, -5.684e-01, 1.567e-01, 3.078e-01));
	r += mul(s0_2, M4(1.192e-01, 2.588e-01, -6.001e-02, -1.333e-01, 4.274e-02, -1.284e-01, -7.077e-03, -2.189e-02, 3.573e-02, -1.953e-01, 2.878e-02, 6.091e-02, 3.544e-03, 2.270e-01, -7.446e-02, -6.709e-02));
	r += mul(s0_3, M4(1.919e-01, -7.248e-02, 6.189e-02, -4.866e-02, 7.446e-02, -6.943e-02, 9.525e-02, -5.116e-02, 7.269e-04, -8.428e-03, -4.633e-02, 3.362e-02, 3.597e-02, -1.048e-01, 2.439e-01, -4.722e-04));
	r += mul(s0_4, M4(-1.232e+00, 1.150e-01, 7.228e-01, 5.932e-01, -6.527e-01, 3.232e-01, -6.625e-01, 3.877e-01, 9.018e-02, 1.491e-02, 5.918e-01, -1.291e-01, 4.775e-01, 6.333e-01, -6.777e-01, -1.788e-01));
	r += mul(s0_5, M4(2.164e-01, -7.881e-01, -1.321e-01, 2.656e-01, 4.630e-02, 6.288e-02, 8.962e-02, -3.140e-02, 3.670e-03, 6.674e-02, 5.918e-02, -2.497e-01, -4.656e-02, 5.147e-02, 1.145e-01, -1.485e-01));
	r += mul(s0_6, M4(7.453e-02, 5.355e-02, -3.569e-01, -7.027e-02, 6.142e-03, 2.761e-02, 3.946e-02, 7.758e-03, -2.168e-02, -1.951e-03, -4.329e-03, -2.117e-02, -1.415e-02, 1.011e-02, -4.371e-02, 1.790e-02));
	r += mul(s0_7, M4(3.950e-01, 3.486e-01, -1.887e-01, -4.637e-01, 1.677e-01, 3.750e-02, -4.935e-02, 4.381e-02, 7.639e-03, -7.728e-02, -1.028e-01, -5.635e-02, -7.396e-02, -3.341e-02, 7.226e-02, -5.508e-02));
	r += mul(s0_8, M4(-1.669e-01, -7.676e-02, 1.691e-01, 2.406e-01, -1.015e-02, -6.617e-02, -4.171e-03, -7.207e-02, 1.771e-02, 4.144e-02, -3.821e-02, 1.265e-01, -1.769e-02, -3.697e-02, 4.715e-02, 2.002e-01));
	r += mul(s1_0, M4(2.479e-02, -1.421e-02, 1.164e-02, -4.470e-03, 2.227e-02, -1.649e-03, 4.297e-03, 7.181e-03, -9.099e-04, -6.488e-02, -3.067e-02, -1.265e-02, -1.395e-02, -1.421e-02, -1.486e-02, -6.431e-03));
	r += mul(s1_1, M4(-7.268e-02, 1.238e-01, 1.414e-02, 6.334e-02, 4.335e-02, 3.332e-02, 1.024e-02, 4.335e-04, -3.686e-02, 5.465e-02, -4.896e-03, -2.465e-02, -8.033e-02, -1.606e-01, 3.766e-02, -5.198e-03));
	r += mul(s1_2, M4(3.650e-02, -8.460e-02, 4.894e-02, 2.660e-02, 2.542e-03, 5.766e-03, -3.420e-03, 1.424e-03, -1.000e-02, -1.627e-02, -1.442e-02, -7.203e-03, -2.317e-02, 5.129e-02, -2.131e-02, 1.344e-02));
	r += mul(s1_3, M4(2.195e-02, -4.216e-03, 2.440e-02, -1.380e-02, 8.634e-03, -4.558e-03, 2.226e-02, 4.387e-03, -8.137e-03, -1.029e-02, 6.814e-02, -4.675e-02, -4.477e-02, -3.457e-02, -2.119e-03, 5.601e-03));
	r += mul(s1_4, M4(-5.359e-02, 6.763e-02, -1.491e-01, 9.155e-02, -1.470e-01, -1.353e-01, -6.825e-02, -6.579e-02, 1.077e-01, 5.982e-02, 6.334e-02, 1.909e-01, 6.763e-02, 1.494e-01, -3.919e-02, -4.257e-02));
	r += mul(s1_5, M4(5.426e-02, -1.911e-02, -1.315e-02, -1.880e-01, 5.579e-03, 1.453e-02, 1.496e-02, 1.493e-02, -1.535e-02, -6.720e-03, 3.816e-03, 3.055e-03, 7.398e-03, -7.007e-02, -2.249e-02, -4.496e-02));
	r += mul(s1_6, M4(6.612e-03, 2.223e-03, 2.845e-03, -8.800e-03, 5.743e-03, 3.405e-02, 1.571e-02, 6.377e-03, -5.075e-03, -1.701e-02, -2.969e-02, -4.109e-03, -9.275e-03, 4.099e-03, 3.277e-04, 1.248e-03));
	r += mul(s1_7, M4(1.389e-02, -4.404e-03, 8.997e-03, 2.682e-02, 3.865e-02, 4.192e-02, 1.477e-02, 4.769e-02, -2.847e-02, -2.027e-02, -1.993e-02, -7.056e-02, 1.981e-03, -3.460e-02, -6.761e-03, -1.151e-02));
	r += mul(s1_8, M4(-2.522e-02, -5.495e-03, 1.099e-02, 2.012e-02, -6.006e-04, -2.040e-02, -5.267e-03, -2.096e-02, 1.344e-02, 2.081e-02, -2.314e-03, 8.092e-03, -1.292e-02, 9.887e-03, 2.013e-02, 3.234e-02));
	r += V4(-1.152e-04, 5.282e-06, 3.957e-04, 6.461e-04);
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
//!DESC CuNNy-2x4C-EASU-NVL-DS-shuffle
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

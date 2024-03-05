// CuNNy 3x4C EASU NVL
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
//!DESC CuNNy-3x4C-EASU-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(-3.916e-01, -7.442e-01, -1.840e-01), O(INPUT, float2(x, y)).rgb) + 1.045e+00)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-4.682e-02, -3.351e-04, -5.334e-02, -7.692e-03) * s0_0;
	r += V4(4.748e-01, 5.181e-02, 1.529e-02, 7.531e-02) * s0_1;
	r += V4(-8.935e-03, 9.643e-02, 6.004e-02, 1.533e-01) * s0_2;
	r += V4(5.290e-02, 1.052e-01, 6.392e-03, -1.055e-01) * s0_3;
	r += V4(1.824e-02, -6.542e-01, -5.098e-01, -5.918e-01) * s0_4;
	r += V4(-4.814e-01, 1.333e-01, -1.225e-02, 5.344e-01) * s0_5;
	r += V4(-1.349e-02, 4.692e-02, 3.459e-01, 1.142e-01) * s0_6;
	r += V4(-2.959e-03, 1.433e-01, 1.890e-01, -1.124e-01) * s0_7;
	r += V4(8.796e-03, 2.692e-02, -3.983e-02, -5.903e-02) * s0_8;
	r += V4(2.967e-04, 4.217e-02, 1.231e-03, -3.290e-03);
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
//!DESC CuNNy-3x4C-EASU-NVL-conv1
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
	r += mul(s0_0, M4(1.003e-02, 1.176e-02, -9.313e-02, 2.986e-02, -3.657e-02, 5.592e-02, 2.805e-01, -5.263e-02, 4.506e-02, -2.572e-02, -6.610e-02, -6.679e-02, -2.672e-02, -9.982e-04, -2.724e-01, -6.477e-02));
	r += mul(s0_1, M4(-4.552e-02, -4.075e-03, -2.675e-02, 4.767e-02, -8.617e-02, -1.626e-01, 3.170e-01, -1.015e-01, -6.173e-02, 1.928e-01, -2.975e-01, 8.046e-02, 3.695e-02, -2.633e-02, -3.152e-01, -8.925e-02));
	r += mul(s0_2, M4(4.267e-02, 3.214e-02, -5.285e-02, 5.759e-02, -3.186e-03, 1.602e-01, 2.910e-01, 4.398e-01, 9.475e-03, -2.610e-01, -2.871e-01, -4.580e-01, 1.606e-02, -3.061e-02, -8.863e-02, -3.037e-01));
	r += mul(s0_3, M4(8.046e-02, 2.019e-01, 1.607e-01, 8.132e-02, -4.368e-02, -4.153e-01, -1.245e-01, -6.776e-02, -1.645e-01, 1.705e-01, -9.304e-02, 1.533e-01, 3.259e-02, -3.622e-01, -7.634e-02, -3.115e-01));
	r += mul(s0_4, M4(-1.870e-01, 1.737e-01, 4.284e-01, 8.220e-01, 3.299e-01, 3.754e-01, -1.426e-01, -1.711e-01, 3.825e-01, -2.011e-01, 1.733e-01, -2.547e-01, -3.536e-02, 1.870e-01, 1.598e-01, 4.892e-02));
	r += mul(s0_5, M4(-1.114e-01, 3.407e-02, 1.212e-01, 4.444e-01, -9.411e-02, -4.091e-02, -8.757e-02, 3.731e-01, 1.606e-01, 7.398e-02, -7.076e-02, -3.687e-01, -4.511e-02, 1.286e-02, -2.106e-02, 1.286e-01));
	r += mul(s0_6, M4(-2.021e-01, 2.336e-01, -2.280e-03, 1.734e-01, 2.895e-01, 8.031e-02, 8.520e-02, -1.145e-01, 1.976e-02, 3.248e-03, -2.187e-02, -2.007e-02, -7.145e-02, -1.275e-03, -1.552e-02, 1.068e-01));
	r += mul(s0_7, M4(-4.873e-01, -8.881e-02, -1.194e-01, 1.721e-01, -3.595e-01, 3.380e-03, -6.893e-01, -3.194e-01, 1.111e-01, -4.054e-02, 1.725e-01, 1.331e-01, -6.621e-01, -7.236e-02, -3.143e-01, -7.571e-02));
	r += mul(s0_8, M4(3.030e-02, -3.311e-02, 1.804e-01, 1.328e-01, -2.741e-02, -9.536e-02, -6.800e-03, -7.975e-03, -1.786e-01, 6.476e-03, 5.369e-02, 5.363e-02, -2.889e-02, 4.284e-02, -3.990e-02, -9.936e-02));
	r += mul(s1_0, M4(-8.504e-03, 3.806e-03, 6.433e-03, -3.807e-02, 4.881e-02, 3.569e-02, 1.098e-01, -1.212e-01, 3.251e-02, 5.261e-02, -1.013e-04, -3.012e-02, 2.259e-02, 1.411e-02, 1.270e-02, 1.071e-01));
	r += mul(s1_1, M4(-3.188e-02, -3.380e-02, -3.502e-02, -1.265e-01, -2.249e-01, -9.479e-02, 1.128e-01, 2.153e-01, 7.620e-03, 2.481e-01, 2.466e-02, 1.912e-01, 1.434e-01, -9.552e-02, 3.205e-03, 1.444e-02));
	r += mul(s1_2, M4(-1.420e-03, 2.831e-02, -2.560e-02, -5.976e-03, 1.175e-01, 1.304e-01, 2.301e-01, 3.135e-01, -7.843e-02, -7.642e-02, 9.013e-02, 9.044e-01, -1.720e-03, -2.244e-02, -3.555e-02, -1.284e-01));
	r += mul(s1_3, M4(2.042e-01, -6.005e-03, 1.254e-02, -3.428e-01, -8.667e-02, -3.698e-01, -3.054e-01, -8.957e-02, -1.233e-01, 1.138e-01, 1.155e-01, 2.182e-01, 1.112e-01, -7.129e-01, 6.422e-01, -1.178e-01));
	r += mul(s1_4, M4(-1.031e-01, 1.840e-01, -3.369e-01, -6.851e-01, -7.939e-02, 2.544e-01, 8.890e-02, -2.655e-01, 2.352e-01, -2.782e-01, 7.001e-02, -1.018e-01, 2.247e-01, 2.764e-01, 3.256e-01, 8.115e-01));
	r += mul(s1_5, M4(-1.512e-01, 6.658e-02, -8.131e-02, 1.975e-01, 4.761e-02, -1.140e-01, 3.556e-01, 5.035e-01, -3.831e-02, 2.257e-01, -1.937e-01, -8.041e-02, -7.953e-02, 2.756e-02, -9.666e-02, 2.221e-01));
	r += mul(s1_6, M4(-1.564e-01, 1.567e-01, -2.270e-01, -1.020e-01, 4.092e-01, 9.783e-02, 6.359e-02, -4.970e-02, -7.954e-02, 5.046e-03, -6.169e-02, -5.963e-02, -1.653e-01, -5.399e-02, 1.209e-02, 9.108e-02));
	r += mul(s1_7, M4(-5.801e-01, 2.768e-02, -7.803e-01, -2.464e-01, -7.700e-02, -5.277e-04, -4.323e-01, -4.241e-01, -8.807e-02, -4.700e-02, 1.811e-01, 1.897e-01, -7.871e-01, -1.630e-01, -1.190e-01, 1.084e-01));
	r += mul(s1_8, M4(1.366e-02, -3.942e-02, 2.139e-02, -6.734e-02, -1.362e-01, -1.834e-02, 7.824e-02, -1.849e-02, -6.052e-02, -6.873e-04, -1.866e-03, 1.155e-01, 3.888e-02, 1.867e-02, 2.515e-02, 3.729e-02));
	r += V4(1.134e-03, 6.802e-04, -2.937e-03, 6.129e-04);
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
//!DESC CuNNy-3x4C-EASU-NVL-conv2
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
	r += mul(s0_0, M4(-2.686e-01, -9.019e-02, 7.737e-02, 9.248e-02, -5.432e-02, 5.502e-02, -4.213e-02, -1.014e-02, 2.276e-01, 1.524e-01, -2.956e-03, -1.062e-01, 4.180e-02, -7.515e-02, 2.601e-02, -3.499e-02));
	r += mul(s0_1, M4(-1.291e-01, -2.286e-02, 1.533e-01, 5.464e-01, -2.398e-02, 6.498e-02, 2.287e-02, 1.353e-01, 2.386e-01, -3.774e-02, -4.805e-02, -3.816e-02, -6.772e-02, -2.972e-02, -9.613e-03, -9.519e-02));
	r += mul(s0_2, M4(-7.709e-02, 1.226e-01, -1.548e-01, 1.384e-01, 1.526e-01, -9.074e-02, 3.139e-03, 3.826e-02, -1.408e-02, -4.991e-02, 1.337e-01, -7.964e-02, -2.839e-02, -4.322e-03, -3.033e-02, 1.936e-02));
	r += mul(s0_3, M4(4.273e-02, 3.577e-02, 1.150e-02, -2.272e-01, 2.880e-02, -2.402e-02, -2.748e-02, -8.371e-02, 3.122e-01, 5.461e-02, -1.125e-01, -2.431e-01, 2.007e-01, -3.838e-01, 1.183e-01, 2.372e-01));
	r += mul(s0_4, M4(-6.885e-03, -3.278e-02, 3.865e-03, -2.673e-01, 3.433e-01, 1.940e-01, -1.469e-02, -5.130e-01, 3.400e-01, -3.584e-01, 9.739e-02, -1.880e-01, -5.148e-01, 2.953e-01, -5.034e-01, -5.517e-02));
	r += mul(s0_5, M4(-1.502e-02, 2.392e-01, 5.191e-02, 2.676e-03, 6.183e-02, -7.246e-01, 9.690e-02, 3.263e-01, -2.282e-01, -1.956e-01, -4.185e-02, 9.103e-02, 9.989e-02, 9.971e-02, -3.241e-02, -2.875e-02));
	r += mul(s0_6, M4(4.629e-02, 2.454e-02, -2.628e-02, -1.094e-01, -4.735e-02, -2.478e-02, -1.523e-03, 9.252e-02, -2.638e-02, -7.395e-02, 2.904e-02, 3.252e-01, -5.809e-02, 1.752e-01, 4.798e-03, 9.267e-02));
	r += mul(s0_7, M4(2.198e-03, 8.306e-03, 1.105e-01, -2.055e-01, 2.257e-02, -6.077e-02, 2.994e-03, 1.221e-01, -4.236e-02, -1.532e-01, -1.282e-01, 3.311e-01, -1.333e-01, 3.877e-01, -2.016e-02, -1.353e-01));
	r += mul(s0_8, M4(2.746e-02, 1.444e-02, -3.578e-02, -1.868e-02, -4.738e-02, -9.366e-02, 1.367e-01, 1.286e-02, -3.406e-02, 2.581e-02, 1.972e-02, -2.602e-02, 2.648e-02, -7.907e-03, 6.538e-02, 8.296e-03));
	r += mul(s1_0, M4(1.577e-01, -3.368e-01, 8.041e-02, 5.495e-02, -1.570e-02, 2.278e-02, 6.676e-03, -3.716e-03, 4.072e-02, 1.739e-02, -2.098e-02, -7.276e-02, -6.614e-02, 7.182e-02, 1.148e-01, -1.262e-02));
	r += mul(s1_1, M4(1.308e-01, -3.135e-01, 1.666e-01, -3.076e-01, 2.890e-01, -1.284e-01, 2.068e-01, 1.510e-02, -1.212e-01, 6.418e-02, 1.353e-01, 2.269e-01, 7.241e-02, 2.071e-03, 2.359e-01, -1.219e-01));
	r += mul(s1_2, M4(-2.370e-01, -2.025e-02, -3.760e-01, -4.275e-04, 3.880e-02, -1.151e-01, -3.117e-01, -1.227e-01, 3.721e-02, 5.460e-02, 5.197e-02, 2.375e-02, -1.921e-02, -4.085e-02, 1.014e-01, -2.825e-02));
	r += mul(s1_3, M4(1.714e-01, -2.044e-02, -3.631e-02, 2.565e-01, 6.209e-02, -4.258e-02, 6.886e-03, -3.377e-02, -6.335e-02, -1.326e-02, -7.832e-02, -1.033e-01, -3.729e-01, 1.586e-01, 3.466e-01, 3.192e-01));
	r += mul(s1_4, M4(-2.399e-01, 7.228e-01, -1.745e-01, 1.958e-01, 9.882e-01, 2.211e-01, -2.674e-01, -3.851e-01, 5.764e-01, -9.744e-02, -8.191e-03, -6.104e-01, -1.345e-01, 1.200e-01, 3.505e-01, 3.753e-01));
	r += mul(s1_5, M4(-2.329e-01, 2.587e-01, 1.134e-01, -6.064e-02, -6.081e-01, -9.270e-02, 1.307e-02, -8.478e-02, 3.509e-02, -1.088e-01, -5.884e-02, 1.283e-01, 3.308e-02, 7.204e-02, 2.549e-01, -5.901e-02));
	r += mul(s1_6, M4(-2.130e-02, 6.567e-02, -2.638e-02, 3.040e-02, 9.647e-03, -5.768e-02, -1.144e-02, 7.492e-02, -7.004e-02, -4.515e-02, 2.953e-03, 1.372e-01, 9.726e-02, 1.575e-01, 1.163e-01, -4.968e-01));
	r += mul(s1_7, M4(-1.082e-01, 7.494e-02, 3.692e-02, 3.959e-02, -1.596e-01, -3.853e-02, -9.998e-02, 4.746e-01, 8.791e-02, -1.651e-01, -3.937e-02, 2.391e-01, 1.244e-01, -7.554e-02, 2.959e-01, -5.480e-02));
	r += mul(s1_8, M4(-2.530e-02, 8.911e-02, -4.188e-02, 4.501e-03, -4.090e-01, 1.544e-01, 4.366e-02, 9.994e-02, 7.829e-02, -9.867e-02, 1.614e-01, -7.646e-03, 5.799e-02, 1.980e-02, 2.284e-02, -4.652e-02));
	r += V4(1.772e-03, -4.189e-03, -2.039e-03, -3.549e-04);
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
//!DESC CuNNy-3x4C-EASU-NVL-conv3
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
	r += mul(s0_0, M4(8.052e-02, 6.569e-02, -1.958e-01, -9.765e-02, -7.699e-03, -6.467e-04, 4.688e-02, 3.317e-02, -3.663e-02, -3.938e-03, 7.010e-02, -1.999e-02, -7.291e-02, -1.931e-02, -4.743e-02, -1.702e-02));
	r += mul(s0_1, M4(5.170e-02, -4.822e-02, -2.550e-02, -1.430e-02, -1.284e-01, -4.561e-02, -4.596e-02, -4.226e-02, 7.735e-02, -1.032e-01, -9.974e-02, -2.124e-01, 4.876e-02, 3.494e-02, 1.132e-01, 9.042e-02));
	r += mul(s0_2, M4(-1.349e-02, 3.376e-02, -6.991e-03, -2.628e-02, 1.342e-01, 2.343e-03, 2.149e-03, 7.151e-02, 8.822e-02, -2.842e-02, -6.222e-02, -5.732e-02, -6.271e-02, -1.973e-02, -3.294e-03, -3.726e-02));
	r += mul(s0_3, M4(-1.366e-01, 9.299e-02, 5.870e-01, -3.999e-01, -1.559e-01, 8.841e-04, 1.931e-01, -3.967e-02, 7.859e-01, -1.713e-01, 6.931e-01, 1.679e+00, -4.999e-02, 4.991e-03, 7.327e-02, 2.646e-01));
	r += mul(s0_4, M4(-3.303e-02, -7.174e-02, 6.727e-02, 1.047e-01, -5.964e-02, -1.932e-03, 1.719e-01, -1.038e-01, -3.810e-01, -7.644e-01, 3.432e-02, -4.403e-01, -1.086e-01, 1.173e-01, 5.855e-02, 5.819e-02));
	r += mul(s0_5, M4(2.925e-02, -1.807e-02, -3.534e-02, -1.434e-02, 1.149e-01, -1.618e-01, 2.207e-02, 2.139e-02, 4.315e-02, -1.287e-01, 5.316e-02, -4.119e-02, -6.029e-02, -1.548e-01, -4.810e-02, -7.015e-02));
	r += mul(s0_6, M4(-3.204e-02, 1.428e-02, 2.240e-02, -1.689e-01, -1.458e-02, -1.663e-02, -4.032e-02, 1.630e-01, 2.045e-01, -1.209e-01, -2.666e-01, -5.735e-01, -1.639e-02, 2.180e-02, -1.234e-02, 3.047e-02));
	r += mul(s0_7, M4(-1.853e-02, 2.538e-02, 1.431e-01, 6.714e-02, -1.733e-01, 3.839e-02, 5.078e-02, 2.082e-01, -1.704e-04, 4.566e-02, 6.054e-02, 7.690e-02, 2.851e-02, -3.728e-02, -1.311e-01, -7.233e-02));
	r += mul(s0_8, M4(-2.032e-03, -5.913e-03, 3.407e-02, 1.999e-02, 8.326e-02, -2.559e+00, 1.162e-01, -4.583e-01, -5.652e-02, -1.067e-01, 8.179e-02, 3.037e-02, 1.519e-02, -1.372e-02, -5.164e-02, -4.064e-02));
	r += mul(s1_0, M4(-4.776e-02, -3.573e-04, -5.940e-02, -2.097e-02, -1.836e-01, 1.081e-02, -2.446e-01, -1.359e-01, 6.812e-02, 1.655e-03, 4.157e-02, 4.704e-03, 2.417e-03, 2.936e-03, 8.605e-02, 1.222e-01));
	r += mul(s1_1, M4(7.954e-02, -3.236e-02, 6.189e-02, 1.992e-02, 5.679e-02, -5.535e-02, -5.282e-02, 9.374e-03, -7.257e-02, -1.732e-04, -9.239e-03, -3.432e-02, 1.372e+00, 1.421e-01, 3.336e-01, 2.709e-01));
	r += mul(s1_2, M4(-9.316e-02, 2.996e-02, 6.135e-02, 2.272e-02, -9.006e-03, 7.025e-03, -2.469e-02, -2.337e-02, 2.445e-02, -8.324e-03, -1.318e-03, 2.964e-03, -1.319e-04, -7.300e-02, 5.016e-02, -9.661e-03));
	r += mul(s1_3, M4(4.592e-02, 8.294e-03, 2.261e-02, 2.141e-02, -1.388e-02, -5.078e-04, 3.118e-01, -4.899e-02, 6.118e-02, -2.831e-02, -1.968e-01, -2.899e-03, 2.611e-03, 3.607e-02, 6.343e-02, -2.499e-02));
	r += mul(s1_4, M4(-4.437e-02, 1.053e-01, -8.162e-01, -6.314e-01, -2.856e-02, 5.525e-02, 8.010e-02, 1.837e-02, -1.238e-01, 6.258e-02, 5.504e-02, -9.307e-03, 7.661e-02, 2.763e-02, 1.764e-02, -1.654e-01));
	r += mul(s1_5, M4(-6.050e-02, -1.072e-01, -4.759e-03, 8.796e-02, 2.508e-02, -4.740e-02, -2.264e-02, -5.233e-03, 5.668e-02, -3.073e-03, 1.343e-02, 2.106e-02, 1.588e-03, -4.874e-02, -4.994e-02, -8.757e-02));
	r += mul(s1_6, M4(-1.725e-03, -1.636e-02, -3.866e-02, -3.233e-02, 7.158e-03, -9.717e-03, -2.828e-02, -5.091e-02, -1.219e-02, 2.012e-02, 2.464e-02, 2.142e-02, -4.308e-03, -4.385e-04, 2.529e-03, -3.965e-02));
	r += mul(s1_7, M4(-9.827e-02, 4.357e-02, 4.912e-02, -1.495e-02, -4.589e-03, 2.192e-02, -1.920e-02, 2.122e-02, 9.060e-02, -4.558e-02, -6.076e-02, -3.383e-02, -6.484e-03, 3.852e-02, 4.619e-02, 1.495e-02));
	r += mul(s1_8, M4(2.414e-02, -3.262e-02, 6.125e-02, 7.422e-02, -1.133e-02, -1.357e-02, 2.361e-02, -1.447e-03, -1.487e-02, 1.873e-02, -2.518e-02, -2.821e-02, 3.971e-03, -1.055e-02, 1.179e-02, -1.026e-02));
	r += V4(-3.818e-03, -1.986e-03, 3.486e-03, 2.348e-03);
	return r;
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
//!DESC CuNNy-3x4C-EASU-NVL-out
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
	r += mul(s0_0, M4(-1.429e-02, -1.666e-02, 1.308e-02, 4.080e-03, -1.289e+00, 4.177e-01, 5.554e-02, 8.773e-02, 8.676e-03, 1.568e-03, 1.608e-02, 6.093e-03, -1.548e-02, -9.910e-04, -3.019e-03, 4.823e-03));
	r += mul(s0_1, M4(-1.580e-01, -2.001e-02, 2.070e-02, 4.161e-02, -1.743e-01, 2.842e-01, -1.545e-01, 1.204e-01, -1.483e-02, 7.716e-03, -3.047e-02, -2.567e-02, 1.412e-03, 5.322e-03, 1.947e-02, 3.012e-02));
	r += mul(s0_2, M4(1.452e-02, -1.296e-01, -3.133e-02, 1.716e-02, 1.031e-01, -6.764e-02, -3.892e-02, -6.908e-02, -1.151e-02, 5.506e-03, 1.090e-02, 3.107e-02, 3.144e-02, 1.995e-03, -1.339e-02, -4.167e-02));
	r += mul(s0_3, M4(-1.641e-01, -1.847e-02, -3.770e-02, 2.387e-02, 6.075e-01, 8.080e-01, -2.025e+00, 8.510e-01, 4.526e-03, 1.056e-03, -8.593e-03, 6.344e-03, 4.262e-02, 5.198e-03, 5.019e-03, -9.486e-03));
	r += mul(s0_4, M4(-7.127e-02, 5.586e-01, -8.168e-02, -4.702e-02, 1.483e+00, -2.370e+00, 1.802e+00, -4.064e-01, -6.091e-02, -7.350e-02, -1.699e-02, -2.964e-02, -4.568e-02, 4.192e-02, 7.003e-02, 3.246e-03));
	r += mul(s0_5, M4(1.473e-02, -1.191e-01, 2.432e-01, 8.786e-02, -4.908e-05, 2.561e-01, -1.023e-01, -1.256e-01, 1.062e-01, 3.096e-01, 5.188e-02, 1.751e-01, -7.377e-02, -4.356e-01, -2.514e-02, -1.348e-01));
	r += mul(s0_6, M4(8.914e-02, -8.800e-02, 1.397e-01, -6.355e-02, 7.461e-02, -3.117e-01, 9.854e-01, -2.222e-01, 1.913e-03, -4.998e-03, 1.046e-02, -5.904e-03, 8.883e-03, 5.463e-03, -2.033e-02, -1.286e-04));
	r += mul(s0_7, M4(-3.745e-01, 2.139e-01, -1.200e+00, 1.018e+00, -4.228e-02, 4.374e-01, 2.245e-01, -9.798e-01, -6.516e-02, 6.580e-04, -9.496e-02, 6.247e-03, 6.236e-02, 5.896e-02, -4.138e-02, -5.688e-02));
	r += mul(s0_8, M4(-1.159e-01, 7.345e-02, -3.075e-02, -2.324e-01, -1.538e-01, -7.595e-02, -1.355e-01, 3.580e-01, -2.245e-02, -1.140e-01, 4.162e-02, -3.339e-02, 3.912e-02, 1.782e-01, -1.680e-02, -2.037e-02));
	r += mul(s1_0, M4(3.328e-02, 1.147e-02, -1.215e-02, -6.637e-03, -2.163e-01, -3.783e-02, 2.637e-02, 6.376e-02, 7.885e-02, -1.994e-03, 1.364e-02, -6.852e-03, -1.287e-01, 3.625e-02, 2.938e-02, 4.209e-02));
	r += mul(s1_1, M4(-2.313e-02, 2.476e-03, 1.364e-02, -9.844e-03, 6.724e-02, -5.288e-02, 1.416e-02, -1.183e-02, 2.627e-01, 1.480e-01, -2.529e-01, -1.284e-01, 1.818e-01, 1.440e-01, -9.605e-02, -5.106e-02));
	r += mul(s1_2, M4(6.194e-03, -1.438e-02, -1.092e-03, 1.442e-02, -2.996e-02, -6.131e-03, 3.735e-03, 2.815e-02, -1.848e-01, 4.610e-02, 6.761e-02, 6.127e-03, 1.199e-01, -1.629e-04, 1.752e-03, -7.643e-02));
	r += mul(s1_3, M4(7.760e-03, -1.768e-02, 1.630e-02, -4.492e-03, 4.202e-02, 3.337e-02, -1.558e-01, -6.640e-02, -1.057e-02, 1.733e-02, 5.248e-03, 9.911e-03, 1.213e-01, 2.964e-03, 8.669e-02, -4.953e-02));
	r += mul(s1_4, M4(4.097e-02, -3.470e-03, 2.063e-02, 2.205e-02, 1.067e-01, -5.367e-03, 8.038e-03, -1.304e-01, -5.864e-01, -1.204e-01, 3.332e-01, -1.053e-01, -9.436e-01, 5.134e-02, -2.165e-01, 9.725e-01));
	r += mul(s1_5, M4(2.395e-02, 6.470e-02, -1.666e-02, -3.626e-02, 2.102e-02, 1.012e-01, -7.460e-03, 4.553e-02, 4.506e-02, -4.687e-01, 5.176e-01, 1.023e+00, -5.608e-02, -3.331e-01, 7.980e-02, -3.037e-01));
	r += mul(s1_6, M4(2.496e-02, -2.324e-02, 4.090e-02, -7.249e-03, 2.242e-03, 1.144e-02, 3.332e-02, 2.580e-02, 1.996e-03, 2.229e-02, -2.573e-02, -7.764e-04, 7.594e-02, 1.395e-02, -1.060e-01, -2.277e-03));
	r += mul(s1_7, M4(-2.482e-02, 1.149e-01, -2.339e-01, -6.042e-02, -9.756e-03, 2.402e-03, 4.312e-04, 2.458e-02, -3.735e-02, 2.462e-02, 3.092e-03, 4.401e-02, 4.724e-02, 1.274e-01, -5.534e-02, -1.140e-01));
	r += mul(s1_8, M4(-1.571e-02, -1.052e-01, 4.461e-02, -8.569e-02, -3.206e-03, -2.801e-02, 1.083e-02, -1.021e-02, 7.455e-02, -7.838e-02, 4.856e-02, -7.350e-02, -9.192e-03, 9.302e-02, -3.343e-02, 9.328e-02));
	r += V4(9.573e-04, 6.973e-04, -1.585e-04, -2.160e-04);
	return tanh(r);
}
void Pass6(uint2 blockStart, uint3 tid) {
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
//!PASS 7
//!DESC CuNNy-3x4C-EASU-NVL-shuffle
//!STYLE PS
//!IN t0, INPUT, easu
float4 Pass7(float2 pos) {
	float2 pt = float2(GetInputPt());
	static const float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	static const float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = t0.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += easu.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

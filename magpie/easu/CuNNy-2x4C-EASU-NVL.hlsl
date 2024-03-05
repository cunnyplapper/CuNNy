// CuNNy 2x4C CHROMA NVL
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
//!DESC CuNNy-2x4C-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(9.023e-01, 1.631e+00, 4.249e-01), O(INPUT, float2(x, y)).rgb) + -2.498e+00)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-5.195e-02, 3.838e-02, -5.282e-02, -1.431e-02) * s0_0;
	r += V4(-7.837e-02, -5.332e-01, 5.203e-02, -6.588e-03) * s0_1;
	r += V4(-7.336e-02, 7.500e-02, -2.302e-03, -2.679e-03) * s0_2;
	r += V4(6.247e-02, -4.793e-03, 6.763e-02, -1.472e-02) * s0_3;
	r += V4(3.465e-01, 4.902e-01, -4.325e-02, 3.820e-01) * s0_4;
	r += V4(2.331e-02, -6.028e-02, -9.290e-02, -1.289e-02) * s0_5;
	r += V4(-8.381e-02, -1.740e-02, 9.782e-03, 8.051e-04) * s0_6;
	r += V4(-1.471e-02, 7.715e-03, -4.170e-01, -1.972e-02) * s0_7;
	r += V4(-8.340e-02, 2.698e-03, 4.790e-01, -1.068e-02) * s0_8;
	r += V4(8.819e-02, -1.786e-03, -1.459e-03, -1.344e-01);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-conv1
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
	r += mul(s0_0, M4(-3.169e-01, -1.636e-01, -1.397e-01, 1.863e-01, 5.863e-03, 6.613e-02, 3.235e-02, -1.076e-01, 4.564e-02, 4.240e-02, 3.682e-01, -4.912e-01, -1.325e-01, -8.563e-01, -1.639e-02, 7.261e-01));
	r += mul(s0_1, M4(1.488e-01, 8.084e-03, -1.343e-01, 1.615e-01, -1.542e-01, 5.750e-02, 5.049e-02, -7.099e-02, -7.373e-02, -1.707e-01, 2.910e-02, 1.096e-01, -1.155e-01, -2.128e-01, -2.647e-01, -2.614e-01));
	r += mul(s0_2, M4(3.233e-02, 3.470e-02, 3.727e-02, -2.119e-02, -6.259e-02, -2.456e-02, 1.260e-02, -1.207e-02, 2.474e-03, 9.150e-03, -1.736e-02, 2.237e-02, -5.246e-01, 2.664e-01, 3.912e-01, 1.979e-01));
	r += mul(s0_3, M4(4.852e-02, 5.177e-02, 2.352e-02, -5.903e-02, -3.205e-02, 2.338e-02, -7.639e-02, 7.886e-02, -8.765e-02, -2.100e-02, -3.271e-01, -1.387e-01, -5.824e-02, -2.035e+00, 3.884e-01, 8.731e-01));
	r += mul(s0_4, M4(-8.853e-03, 3.733e-01, -1.206e-02, 8.278e-02, -2.279e-01, -3.442e-02, 2.238e-02, -1.542e-01, -9.014e-02, 6.371e-02, -7.561e-02, 7.349e-02, 2.100e+00, -6.016e+00, 5.196e-01, -2.131e+00));
	r += mul(s0_5, M4(-2.483e-02, -3.169e-02, 7.165e-02, -8.439e-03, -2.241e-01, -1.432e-01, -3.356e-02, 1.567e-01, -1.160e-02, 1.015e-02, -1.126e-01, 7.495e-02, -4.399e-01, -1.151e+00, -2.197e-01, 1.879e-01));
	r += mul(s0_6, M4(1.313e-01, 1.323e-01, -1.074e-01, -2.478e-02, 4.545e-02, 1.288e-03, 1.568e-01, -4.184e-02, 1.675e-01, 6.233e-03, 1.579e-01, -2.861e-02, 1.499e-01, 1.860e-01, 3.934e-01, 1.877e-01));
	r += mul(s0_7, M4(-3.754e-01, -1.347e-01, 4.994e-02, -1.035e-01, 1.108e-01, -1.186e-01, 4.624e-02, 5.643e-01, -1.324e-02, -1.961e-02, -5.135e-02, 3.947e-02, -4.462e-01, -6.879e-01, -1.211e+00, 3.396e-01));
	r += mul(s0_8, M4(4.391e-02, 3.183e-03, 3.962e-01, 3.231e-02, -2.074e-02, 1.801e-01, -3.389e-01, 1.760e-01, 1.061e-02, 8.089e-03, -1.258e-02, 2.985e-02, 2.839e-01, 4.171e-01, 2.064e-01, 2.404e-01));
	r += mul(s1_0, M4(-1.793e-01, -1.114e-01, -1.022e-01, 4.709e-02, 1.272e-01, -6.708e-02, 1.505e-02, 1.137e-02, 1.528e-01, 4.444e-02, -4.125e-01, -3.640e-02, 8.817e-02, -1.701e-01, -2.292e-02, 1.379e-01));
	r += mul(s1_1, M4(-4.323e-01, -7.567e-02, 1.462e-03, -7.404e-02, 1.254e-01, -8.718e-04, 2.119e-02, 3.954e-02, 3.591e-01, 3.108e-02, 5.901e-02, -1.436e-02, -1.637e-01, 8.049e-03, -1.091e-01, -2.252e-01));
	r += mul(s1_2, M4(-3.667e-02, -1.444e-01, -1.077e-02, 9.363e-03, 9.914e-02, 1.111e-01, 3.015e-02, -2.960e-02, 7.888e-02, -2.295e-02, 1.096e-01, -6.610e-02, -2.434e-01, 3.394e-02, 7.444e-02, 1.402e-01));
	r += mul(s1_3, M4(1.530e-01, 5.571e-02, 2.532e-01, -1.618e-01, -6.545e-02, -2.319e-01, -2.802e-01, 2.529e-01, -2.160e-01, -3.921e-02, -7.090e-01, -2.927e-03, -5.177e-02, 8.245e-02, 1.574e-01, -1.603e-01));
	r += mul(s1_4, M4(2.703e-01, 1.568e-01, 9.561e-02, 2.606e-01, 4.694e-01, 8.765e-02, -4.218e-02, -2.349e-01, -3.721e-01, -1.307e-01, 7.545e-01, -2.393e-01, 1.587e-01, -1.878e-01, -1.364e-01, -2.059e-01));
	r += mul(s1_5, M4(-5.143e-02, 5.926e-02, -2.547e-01, 1.639e-01, -8.228e-02, -1.219e-01, 1.378e-01, -5.036e-02, -1.829e-02, -4.637e-03, -3.889e-02, -2.825e-02, -6.645e-02, 1.016e-01, 6.362e-02, -3.538e-03));
	r += mul(s1_6, M4(3.265e-02, 1.735e-02, 5.799e-03, -1.235e-01, -1.743e-01, 2.360e-02, -1.823e-01, -1.037e-01, 5.316e-02, 4.417e-02, 1.218e-01, 4.482e-02, -3.703e-02, 7.416e-02, -5.356e-02, -1.495e-02));
	r += mul(s1_7, M4(-5.485e-02, -1.313e-01, 4.270e-02, -9.193e-02, -5.319e-01, 2.564e-02, -2.263e-01, -3.678e-02, -8.814e-02, -1.522e-02, 2.078e-01, 2.156e-02, 6.896e-02, 4.909e-02, 1.449e-01, 1.357e-01));
	r += mul(s1_8, M4(4.606e-02, 5.402e-02, -7.252e-02, 1.606e-01, -1.258e-01, -9.974e-02, 1.616e-01, -1.664e-01, 1.919e-02, 2.825e-03, 1.073e-01, -2.678e-02, 2.920e-01, -2.569e-02, -1.429e-01, 1.612e-01));
	r += V4(3.186e-02, -1.393e-02, -2.004e-02, -2.563e-02);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-conv2
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
	r += mul(s0_0, M4(-2.089e-02, 1.180e-01, 1.728e-01, 1.057e-01, -3.284e-02, -1.691e-02, 2.315e-03, 3.354e-03, -4.213e-02, 3.065e-02, -6.047e-02, 5.983e-03, 1.813e-01, -2.359e-01, -1.343e-01, -1.978e-01));
	r += mul(s0_1, M4(-8.537e-02, 1.059e-01, 1.331e-01, -1.968e-01, 7.016e-02, -6.899e-02, -1.222e-04, -1.485e-02, 2.183e-01, 8.784e-02, -1.735e-01, -1.756e-02, 1.091e-01, -4.854e-01, -1.006e-01, 2.703e-01));
	r += mul(s0_2, M4(2.104e-01, -1.003e-01, 3.122e-02, -9.253e-02, 3.275e-03, -6.022e-02, 7.040e-04, 5.295e-02, -2.435e-01, -1.427e-01, -5.176e-02, 2.075e-01, -7.353e-02, -8.689e-02, 1.985e-02, 5.101e-03));
	r += mul(s0_3, M4(-1.332e-01, -7.153e-02, -2.647e-01, -4.799e-04, 4.293e-03, -7.787e-02, -4.494e-02, -1.811e-03, -1.058e-02, -1.243e-02, -3.842e-02, -7.168e-03, 2.741e-01, 2.650e-02, 4.599e-01, -2.655e-02));
	r += mul(s0_4, M4(7.299e-01, 3.037e-01, -3.797e-01, 2.065e-01, -5.959e-02, 3.367e-01, 1.342e-01, 1.854e-01, 1.797e-01, 2.985e-01, -1.525e-02, -1.477e-02, -1.313e-01, 6.464e-01, 5.628e-02, -1.827e-02));
	r += mul(s0_5, M4(1.246e-01, 4.678e-02, 7.292e-02, -1.480e-01, -6.119e-02, 9.804e-02, 1.501e-01, -9.484e-02, 8.768e-02, -4.880e-03, 6.904e-03, 1.178e-01, 1.082e-01, 2.802e-02, -8.062e-02, 1.206e-01));
	r += mul(s0_6, M4(-4.136e-02, -1.147e-02, -7.350e-03, 3.558e-02, 3.752e-03, 3.270e-02, 3.492e-02, 3.424e-02, 4.175e-02, 5.613e-03, 4.072e-02, -1.968e-02, 2.432e-02, -9.308e-03, -6.620e-02, -3.519e-03));
	r += mul(s0_7, M4(7.787e-02, 5.598e-02, -7.820e-02, 3.784e-02, 9.104e-03, 1.065e-01, -1.108e-01, 1.662e-01, 1.025e-01, 1.687e-02, -3.845e-02, 6.864e-03, -9.064e-03, -1.136e-01, -2.671e-02, -6.662e-03));
	r += mul(s0_8, M4(9.874e-02, 3.105e-02, 1.053e-02, -4.163e-02, -5.250e-02, 9.552e-02, -5.461e-02, -7.583e-03, -3.760e-02, 3.996e-02, 1.317e-02, 6.651e-03, -9.342e-03, 3.447e-02, 5.247e-02, -2.702e-02));
	r += mul(s1_0, M4(-4.602e-02, 4.431e-02, 2.247e-02, 2.468e-02, 1.862e-01, -2.949e-02, -4.869e-02, -2.148e-01, 1.999e-01, -1.568e-01, 1.601e-01, -9.507e-02, -1.938e-02, -4.489e-02, -7.548e-02, 1.216e-02));
	r += mul(s1_1, M4(-1.213e-02, 3.943e-02, 2.029e-02, -3.918e-02, -1.389e-01, -2.447e-01, -6.536e-02, 1.960e-01, -2.097e-01, -2.114e-01, 1.145e-01, -1.782e-01, 1.591e-02, -2.378e-01, -8.731e-02, 1.481e-05));
	r += mul(s1_2, M4(-3.794e-03, -3.169e-02, -2.115e-02, 2.603e-02, 4.475e-02, 5.434e-02, -3.846e-03, -8.768e-02, -2.989e-02, -3.608e-02, 2.539e-03, 2.108e-02, 3.374e-02, -1.579e-01, -1.102e-02, 1.106e-01));
	r += mul(s1_3, M4(-3.303e-02, 8.116e-02, -1.668e-03, 5.258e-02, 6.988e-03, 3.989e-02, 8.888e-01, 1.013e-01, 2.686e-01, 8.104e-02, 9.739e-02, 1.368e-01, -3.368e-02, 8.586e-02, 1.111e-01, 5.115e-02));
	r += mul(s1_4, M4(-6.983e-02, -2.522e-02, 8.770e-02, -1.372e-01, 1.786e-02, 3.248e-01, 8.809e-01, -1.101e+00, 1.518e-02, 2.339e-01, -1.953e-02, -5.422e-02, 3.304e-01, 3.310e-01, 1.382e-01, -1.938e-01));
	r += mul(s1_5, M4(4.798e-02, -8.909e-02, 4.036e-03, 3.724e-02, -4.026e-02, -2.721e-02, -1.165e-01, 1.205e-01, 2.546e-02, 1.131e-02, 9.962e-03, -8.015e-03, 3.096e-01, -2.513e-01, -6.119e-02, 1.440e-01));
	r += mul(s1_6, M4(-8.698e-02, -2.131e-02, -2.153e-01, 4.406e-02, 1.533e-02, -8.203e-02, 2.114e-02, -2.300e-02, 2.609e-02, -1.144e-02, -6.216e-03, 3.181e-02, -4.398e-02, -7.956e-02, 2.130e-02, -4.499e-02));
	r += mul(s1_7, M4(-1.005e-01, 2.615e-01, -1.562e-01, -7.447e-02, -1.961e-02, 1.115e-01, -1.055e-02, -1.628e-01, 2.789e-02, -3.761e-03, 2.629e-02, -4.461e-03, -1.870e-01, -4.209e-01, 1.051e+00, -1.165e-02));
	r += mul(s1_8, M4(1.041e-01, 8.461e-02, 2.777e-02, -1.829e-02, -7.886e-02, 9.692e-03, 2.379e-01, -3.482e-02, 1.255e-03, 2.696e-02, 1.021e-02, -2.043e-02, 2.597e-01, -1.462e-01, -1.364e-02, 1.217e-01));
	r += V4(8.158e-03, -1.375e-03, -8.540e-03, 1.525e-03);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-out
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
	r += mul(s0_0, M4(-7.055e-02, -9.103e-05, -1.037e-02, 6.490e-03, 4.211e-02, -1.522e-02, 1.437e-02, -1.905e-02, -7.884e-02, -5.607e-03, 1.083e-01, -7.071e-03, -2.038e-01, -9.695e-03, -8.846e-02, 3.381e-02));
	r += mul(s0_1, M4(1.282e-02, -5.460e-02, -5.139e-02, -4.966e-02, -9.100e-02, 1.605e-02, -4.500e-02, 4.605e-02, -2.920e-01, -2.192e-01, -1.801e-02, 1.920e-01, -8.585e-02, -5.414e-02, -1.158e-01, -7.822e-02));
	r += mul(s0_2, M4(-6.439e-03, -5.672e-02, -2.323e-02, -4.625e-02, 1.138e-02, -4.711e-02, 4.020e-02, -7.648e-03, 1.159e-01, -1.329e-02, 8.123e-03, -8.097e-02, 5.374e-02, -7.767e-02, 4.468e-02, -8.963e-02));
	r += mul(s0_3, M4(8.403e-02, 1.713e-02, 1.959e-02, -1.243e-02, -2.361e-02, 1.528e-02, 4.365e-03, 9.923e-03, 3.329e-02, -9.390e-03, 8.369e-02, -5.333e-02, 6.813e-02, 7.984e-03, 3.478e-02, -1.058e-01));
	r += mul(s0_4, M4(-1.604e-02, 9.780e-02, 1.999e-01, 1.840e-01, -1.817e-01, -1.763e-01, -3.564e-01, -2.105e-01, 5.519e-01, 3.237e-01, -7.090e-01, -7.349e-02, -1.195e-02, -4.197e-02, -1.167e-02, 1.279e-01));
	r += mul(s0_5, M4(-2.524e-03, -6.040e-02, 2.543e-02, 3.047e-02, 1.018e-01, 8.858e-02, 9.582e-02, -3.327e-02, -4.713e-02, 2.641e-01, 8.667e-02, -4.802e-01, -9.547e-03, 9.141e-02, 4.623e-03, 4.382e-02));
	r += mul(s0_6, M4(-9.307e-03, -2.838e-02, 9.478e-03, 3.698e-03, 1.868e-02, 2.535e-02, 9.794e-03, 3.670e-03, -1.524e-02, 7.359e-03, -1.813e-02, 1.085e-02, 2.461e-02, 4.211e-02, -5.921e-02, 5.701e-02));
	r += mul(s0_7, M4(1.252e-02, 9.501e-03, -5.053e-02, -1.418e-02, -2.538e-02, -5.723e-03, -1.716e-02, -1.665e-02, -6.435e-02, -3.337e-02, 5.546e-02, -4.500e-02, 1.646e-02, 3.122e-02, 5.045e-02, -8.521e-02));
	r += mul(s0_8, M4(-3.186e-03, 1.283e-03, 1.851e-02, -2.533e-02, 5.054e-03, -9.037e-03, 5.119e-03, 2.512e-02, -6.165e-03, -7.690e-02, 3.063e-02, 1.264e-01, 8.206e-03, -2.630e-02, -5.346e-03, 1.638e-02));
	r += mul(s1_0, M4(-1.647e-01, 8.420e-02, 1.563e-02, 2.402e-02, 2.472e-02, 2.385e-02, 9.977e-03, 2.089e-02, 1.994e-02, -4.470e-03, 3.415e-02, -2.411e-02, -2.696e-01, 7.937e-02, -1.554e-01, 1.290e-02));
	r += mul(s1_1, M4(7.289e-02, 9.987e-02, -5.794e-02, -1.869e-01, -6.679e-02, -1.791e-02, -8.640e-02, -2.320e-02, -3.057e-01, -3.521e-02, -1.821e-01, 6.981e-02, 2.265e-02, -4.486e-04, -1.543e-01, -5.956e-02));
	r += mul(s1_2, M4(6.999e-02, -1.392e-01, -8.526e-03, -3.254e-02, 2.301e-02, -1.561e-02, 2.435e-02, -3.955e-02, 8.005e-02, -1.475e-01, 6.275e-02, -1.338e-01, 2.026e-01, -2.510e-01, 1.003e-01, -4.923e-02));
	r += mul(s1_3, M4(2.203e-01, -1.435e-01, -1.763e-01, 6.044e-02, -1.164e-01, 1.553e-01, -4.422e-02, 5.715e-02, 8.889e-03, 6.367e-03, -3.199e-03, 1.219e-02, 7.114e-02, 6.245e-02, -1.549e-01, 9.162e-02));
	r += mul(s1_4, M4(-5.762e-01, 5.528e-01, -2.900e-01, 7.580e-01, -3.419e-01, -5.840e-01, 6.511e-02, -4.101e-02, -1.773e-03, 1.991e-02, -7.222e-02, -7.671e-02, 6.656e-01, -8.546e-01, 5.420e-01, -3.578e-01));
	r += mul(s1_5, M4(4.978e-02, 5.134e-02, 1.700e-01, -6.741e-02, 9.440e-02, 7.406e-02, 1.598e-02, 4.667e-02, 2.898e-03, -2.925e-02, 2.564e-03, -2.918e-02, -3.257e-01, 6.544e-01, 4.700e-02, -3.656e-01));
	r += mul(s1_6, M4(1.534e-02, -6.086e-02, 2.280e-01, -2.037e-01, 1.066e-01, 2.716e-02, -1.363e-01, -1.923e-03, 4.239e-03, 4.688e-03, -1.029e-04, -2.801e-04, 3.319e-02, 2.448e-02, 7.732e-02, 4.666e-02));
	r += mul(s1_7, M4(8.041e-02, -4.729e-02, -1.479e-01, -4.218e-02, 1.053e-01, 2.046e-01, -1.571e-01, -2.749e-01, 9.181e-03, -1.083e-02, -1.244e-02, -4.966e-03, -1.164e-01, 1.265e-01, -1.111e-01, -2.879e-01));
	r += mul(s1_8, M4(5.838e-03, 1.801e-02, -9.134e-03, 7.552e-03, 5.040e-03, 1.900e-02, 3.871e-02, 3.598e-02, -9.823e-04, 3.425e-03, 1.867e-02, 3.294e-03, -4.178e-02, -2.467e-02, -3.037e-01, 6.700e-01));
	r += V4(1.275e-03, 9.650e-04, 1.144e-03, 6.652e-04);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-shuffle
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

// CuNNy 3x4C EASU NVL DS
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
//!DESC CuNNy-3x4C-EASU-NVL-DS-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(-6.888e-01, -1.225e+00, -3.037e-01), O(INPUT, float2(x, y)).rgb) + 1.690e+00)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(1.280e-01, -1.449e-01, -2.580e-02, 9.816e-03) * s0_0;
	r += V4(-5.335e-02, -1.181e-01, -5.167e-02, 3.977e-03) * s0_1;
	r += V4(-5.637e-02, 8.395e-02, 8.781e-02, -6.163e-02) * s0_2;
	r += V4(-9.455e-02, -3.837e-01, 6.852e-02, -1.282e-02) * s0_3;
	r += V4(-3.877e-01, 5.762e-01, -5.414e-02, 6.956e-03) * s0_4;
	r += V4(5.300e-02, -1.780e-02, -4.619e-01, -1.673e-01) * s0_5;
	r += V4(-2.998e-02, 7.442e-02, -4.598e-02, -7.244e-03) * s0_6;
	r += V4(9.835e-02, 3.298e-02, 5.047e-01, -7.465e-02) * s0_7;
	r += V4(3.425e-01, -9.351e-02, -2.104e-02, 3.604e-01) * s0_8;
	r += V4(3.710e-03, -2.186e-02, -5.477e-04, -9.154e-02);
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
//!DESC CuNNy-3x4C-EASU-NVL-DS-conv1
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
	r += mul(s0_0, M4(3.006e-02, 1.049e-01, -4.578e-02, 2.191e-01, 1.517e-02, 1.115e-01, -1.231e-01, 3.721e-02, 2.203e-02, 4.932e-01, 1.528e-01, -6.221e-02, -1.105e-01, -1.928e-01, 1.532e-01, 1.191e-01));
	r += mul(s0_1, M4(9.914e-02, 2.698e-01, -7.628e-02, 9.121e-02, 2.476e-02, -1.919e-01, 7.153e-03, -1.492e-02, 3.331e-02, 4.057e-01, 1.230e-02, -1.627e-01, 4.640e-02, -1.392e-01, -1.469e-01, -1.212e-01));
	r += mul(s0_2, M4(-4.328e-02, -2.529e-01, -9.546e-02, 2.210e-01, -2.707e-02, 1.079e-01, 6.617e-02, 4.404e-02, -7.543e-02, -5.691e-02, 6.129e-02, -7.788e-02, -1.694e-02, 2.879e-01, 1.778e-01, -8.291e-03));
	r += mul(s0_3, M4(2.891e-02, 1.563e-01, -5.810e-02, 2.686e-01, 2.008e-02, -9.352e-02, 1.193e-01, -3.525e-03, -1.353e-02, -1.413e-01, 1.817e-01, -2.348e-01, -4.601e-01, -2.221e-01, 8.479e-02, 1.414e-01));
	r += mul(s0_4, M4(2.958e-01, 1.661e-01, -4.942e-02, 3.876e-01, 1.793e-02, 3.248e-01, -3.733e-01, 1.083e-01, 2.424e-01, 7.835e-02, -1.576e-01, -5.645e-01, -1.341e-02, 1.102e-01, 8.035e-02, -2.450e-01));
	r += mul(s0_5, M4(-5.487e-02, -5.586e-02, -1.913e-01, -4.414e-02, 1.727e-02, 8.742e-03, 2.588e-01, -1.463e-01, -2.003e-01, 2.423e-02, 1.723e-01, -2.452e-01, 2.362e-01, -1.918e-01, 9.825e-02, 2.569e-01));
	r += mul(s0_6, M4(-8.783e-03, -1.797e-02, -7.576e-02, 1.469e-01, -1.293e-02, -2.250e-02, 6.950e-04, -2.664e-02, 9.217e-03, 1.233e-02, -1.393e-01, -7.042e-02, 9.677e-02, 8.526e-02, 2.848e-02, -3.733e-02));
	r += mul(s0_7, M4(-4.748e-02, -7.493e-02, -4.362e-02, 1.217e-01, -2.015e-02, -5.585e-02, 1.749e-01, -5.597e-02, 5.847e-02, 1.275e-02, 3.417e-02, -1.332e-01, 2.807e-02, 1.413e-01, -1.343e-01, 1.042e-02));
	r += mul(s0_8, M4(-1.908e-01, 1.557e-01, 2.275e-01, 4.239e-02, -4.525e-01, 4.401e-03, 1.704e-01, 5.488e-01, 3.016e-02, -1.323e-01, -3.481e-02, -9.334e-02, 2.283e-02, -1.753e-01, -1.732e-01, 1.911e-01));
	r += mul(s1_0, M4(-5.177e-03, 1.928e-01, 2.893e-02, -4.200e-02, 1.284e-02, 8.618e-02, -5.447e-02, 3.025e-02, 2.733e-02, 3.857e-01, 3.130e-02, 7.986e-02, -1.047e-01, 2.936e-01, -8.457e-02, 7.232e-02));
	r += mul(s1_1, M4(9.522e-02, 4.229e-01, -9.450e-02, -1.758e-01, 5.933e-02, -2.803e-01, -4.901e-02, -3.719e-02, 6.076e-02, 3.761e-01, -2.100e-01, 2.767e-01, 6.858e-02, -2.147e-01, 2.180e-01, -1.664e-01));
	r += mul(s1_2, M4(-1.604e-01, -2.625e-01, 6.329e-02, 3.033e-02, -6.037e-02, 6.039e-02, 6.215e-02, 6.108e-02, -6.480e-02, -1.174e-01, -6.812e-02, 8.567e-02, 5.240e-02, 2.390e-01, 2.323e-02, -9.947e-02));
	r += mul(s1_3, M4(7.311e-02, 2.202e-01, 1.484e-02, -6.396e-02, 1.549e-02, -7.874e-02, 2.340e-01, -4.677e-02, -1.334e-02, -1.528e-01, 5.078e-01, 2.665e-01, 1.450e-01, -2.089e-01, -2.058e-01, -1.554e-01));
	r += mul(s1_4, M4(4.052e-01, 2.220e-01, -7.538e-02, -4.554e-01, 4.458e-02, 3.760e-01, -2.576e-01, 1.899e-01, 3.810e-01, 2.359e-02, -2.870e-02, 5.873e-01, -5.549e-01, -1.003e-02, -7.843e-03, 2.003e-01));
	r += mul(s1_5, M4(-3.313e-02, -7.156e-02, -9.333e-02, -5.449e-01, -1.793e-02, 3.260e-02, 1.425e-01, -3.751e-01, -1.958e-01, 5.700e-02, 5.253e-02, 5.055e-02, 1.809e-01, -1.727e-01, 6.671e-02, 1.965e-01));
	r += mul(s1_6, M4(-5.300e-02, -6.348e-02, -1.558e-01, -1.313e-02, -5.568e-02, -3.121e-02, -1.708e-02, -2.694e-02, -1.796e-02, 1.992e-02, 6.675e-03, 1.159e-01, 7.181e-02, 1.037e-01, 3.492e-02, -2.753e-02));
	r += mul(s1_7, M4(-1.294e-01, -4.440e-02, -8.981e-03, -2.607e-01, -8.914e-02, -6.934e-02, 4.297e-01, -2.666e-01, 7.243e-02, 3.098e-02, 1.055e-01, 1.702e-01, 1.870e-01, 1.103e-01, -8.754e-02, -2.114e-02));
	r += mul(s1_8, M4(-2.710e-01, 1.558e-01, 2.894e-01, -2.868e-02, -9.392e-01, -3.231e-02, 3.490e-01, 2.330e-01, 1.790e-01, -1.316e-01, -1.013e-01, 3.294e-02, 1.026e-01, -1.547e-01, -1.480e-01, 2.770e-02));
	r += V4(-5.890e-03, -4.012e-03, 5.268e-03, 2.278e-03);
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
//!DESC CuNNy-3x4C-EASU-NVL-DS-conv2
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
	r += mul(s0_0, M4(-8.723e-02, 5.836e-02, 1.431e-01, 4.190e-01, 6.800e-03, 7.345e-02, 2.655e-02, 8.051e-02, 2.427e-02, 1.372e-01, -3.131e-02, -1.095e-01, 2.895e-02, -1.036e-02, 3.470e-02, -1.675e-01));
	r += mul(s0_1, M4(1.284e-01, -2.644e-01, 2.208e-02, -5.137e-01, -3.551e-02, -1.664e-02, 1.209e-02, 1.125e-01, 1.121e-01, -1.309e-01, -2.764e-01, -2.153e-01, 6.814e-04, -1.222e-01, -2.269e-02, -8.157e-02));
	r += mul(s0_2, M4(-5.485e-02, -2.492e-03, 8.186e-02, -9.517e-02, 1.436e-02, 3.265e-02, -7.616e-03, 1.140e-02, -2.935e-02, -1.120e-03, -4.496e-02, -4.381e-02, 2.330e-02, -2.593e-04, -2.573e-03, 3.717e-02));
	r += mul(s0_3, M4(2.234e-01, -8.476e-02, 3.937e-02, 2.029e-01, 3.900e-02, 1.555e-01, 2.636e-02, 1.142e-02, 5.263e-02, 1.354e-01, -4.978e-01, -1.745e-01, 1.374e-02, -6.275e-02, 2.548e-02, 2.995e-02));
	r += mul(s0_4, M4(5.286e-02, -1.842e-01, -6.728e-02, -4.109e-01, 5.793e-02, 5.124e-01, 3.561e-01, 1.333e-01, -3.163e-01, -3.154e-02, -9.507e-01, 2.426e-01, -3.154e-01, 4.682e-01, -2.397e-01, 6.582e-01));
	r += mul(s0_5, M4(-1.018e-01, -8.866e-02, 1.415e-01, -1.665e-01, 9.343e-02, 7.852e-03, -1.199e-01, -1.103e-01, -2.653e-01, 1.665e-01, -5.825e-02, 1.602e-01, 2.756e-02, -3.357e-02, -6.400e-03, -2.390e-02));
	r += mul(s0_6, M4(-4.936e-02, 2.332e-02, -7.609e-02, 6.414e-02, -5.157e-03, -8.513e-02, 7.445e-02, 3.178e-02, -7.106e-02, 7.104e-02, 1.510e-01, 9.348e-02, 2.929e-04, -1.923e-02, -1.159e-01, -8.903e-02));
	r += mul(s0_7, M4(-4.260e-02, 1.040e-01, -2.997e-02, 1.089e-02, 3.858e-01, -5.794e-01, -3.053e-02, -5.560e-02, -3.297e-01, 7.149e-02, 1.775e-01, 3.086e-01, 1.142e-01, -6.466e-02, 1.289e-01, -1.020e-01));
	r += mul(s0_8, M4(2.390e-02, 1.074e-02, 2.136e-02, -8.062e-04, -2.318e-01, -2.644e-01, 9.176e-02, -5.527e-01, -2.854e-02, 2.244e-01, 2.164e-01, 2.139e-01, -9.318e-02, 3.409e-02, 6.764e-02, 8.243e-02));
	r += mul(s1_0, M4(-2.411e-01, 7.252e-02, -1.577e-01, 7.619e-02, 2.093e-02, -2.009e-02, 5.973e-02, -4.360e-02, 2.569e-02, -5.355e-02, 1.134e-01, -4.487e-02, 1.185e-01, 9.670e-02, 2.153e-02, 1.177e-01));
	r += mul(s1_1, M4(-2.391e-01, 2.920e-01, -1.650e-01, 4.307e-01, 5.345e-03, -9.969e-02, 4.532e-03, 9.509e-03, 5.516e-02, -1.932e-01, -5.403e-02, -3.683e-01, 3.618e-01, 1.366e-02, 3.488e-02, 1.348e-02));
	r += mul(s1_2, M4(-2.086e-01, 8.337e-02, 4.733e-02, 1.208e-01, -5.782e-02, -3.825e-02, 6.147e-04, -8.580e-02, -2.453e-02, -5.093e-02, 3.393e-02, -5.690e-02, 9.189e-02, 3.742e-03, -2.284e-02, -7.785e-02));
	r += mul(s1_3, M4(-5.079e-03, -9.903e-02, 5.414e-02, 2.185e-01, 5.626e-02, -6.126e-02, -4.161e-02, -2.281e-01, 2.278e-02, 3.521e-02, -7.595e-02, -1.268e-01, 2.349e-01, -5.872e-02, 9.645e-02, 2.407e-01));
	r += mul(s1_4, M4(-6.872e-02, 4.015e-01, -1.721e-01, 2.677e-01, -9.922e-03, 1.033e-01, 1.013e-01, 8.965e-02, 4.354e-02, -2.510e-01, 3.611e-01, 8.335e-02, 5.323e-02, -3.952e-01, 2.285e-01, -8.890e-01));
	r += mul(s1_5, M4(8.789e-02, 1.017e-01, 1.596e-01, 2.388e-01, -1.160e-01, 1.941e-02, -1.688e-01, -1.326e-01, -2.068e-01, 6.096e-02, 1.812e-01, -2.279e-01, 3.467e-01, -9.266e-02, -6.713e-03, 2.256e-02));
	r += mul(s1_6, M4(-6.115e-02, -1.009e-01, -7.345e-02, -9.899e-02, -7.888e-02, -1.233e-01, -4.596e-02, -1.233e-01, -6.033e-02, -1.041e-02, 2.147e-01, 5.137e-02, 4.103e-02, -3.911e-02, -4.183e-02, -9.468e-02));
	r += mul(s1_7, M4(5.089e-02, 3.847e-02, 1.246e-01, -5.931e-02, 1.221e-01, 5.228e-02, -6.643e-01, 7.734e-01, 2.432e-02, 1.367e-01, 6.083e-01, 7.562e-02, 2.855e-01, 3.663e-02, -2.624e-02, 1.788e-01));
	r += mul(s1_8, M4(6.038e-02, -1.287e-02, 2.025e-02, 8.352e-03, -8.910e-02, 1.843e-01, -1.225e-01, 2.243e-01, 3.134e-03, -1.129e-01, 2.353e-01, -1.108e-01, 1.714e-01, -5.064e-03, -4.525e-02, -1.702e-02));
	r += V4(-2.325e-03, 4.386e-03, -7.300e-03, 9.131e-03);
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
//!DESC CuNNy-3x4C-EASU-NVL-DS-conv3
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
	r += mul(s0_0, M4(-1.353e-03, -9.467e-02, 9.598e-02, -3.028e-02, -1.395e-03, -7.310e-02, 1.777e-02, -3.887e-02, 1.908e-02, -1.933e-01, -6.356e-02, -1.308e-02, 1.548e-02, -5.851e-02, 5.437e-03, -1.158e-02));
	r += mul(s0_1, M4(-6.926e-03, 8.179e-02, 1.263e-01, -8.837e-02, -3.610e-02, 5.490e-02, 1.245e-02, -1.227e-02, 1.167e-03, -1.310e+00, -1.333e-01, 1.045e-01, 4.479e-02, -6.320e-02, -6.320e-02, 6.357e-03));
	r += mul(s0_2, M4(5.607e-02, 7.588e-02, 1.401e-01, -6.984e-02, 1.283e-02, -5.519e-02, 1.383e-02, 2.405e-02, -1.685e-01, 7.163e-02, -8.238e-02, -1.247e-01, -1.488e-02, 1.382e-01, -1.135e-03, 2.100e-02));
	r += mul(s0_3, M4(-2.735e-01, 1.111e-01, -1.619e-02, -5.307e-01, -5.580e-02, -6.520e-02, -3.686e-02, -1.027e-01, 5.498e-02, -1.493e-01, -4.124e-02, -1.149e-01, -6.914e-04, 2.513e-02, 9.260e-02, 3.012e-02));
	r += mul(s0_4, M4(-3.925e-01, -3.624e-01, -1.355e-01, 7.715e-01, 5.519e-02, 1.597e-01, -2.840e-02, 4.570e-02, 2.148e-01, -9.609e-02, 2.848e-02, -4.669e-01, 1.273e-02, -2.686e-01, 1.724e-01, -1.354e-01));
	r += mul(s0_5, M4(-3.173e-01, 1.106e-01, -1.532e-01, -2.491e-01, -8.487e-02, -2.919e-02, 5.736e-02, 5.257e-02, 3.244e-01, -1.111e-01, -9.289e-02, -2.998e-01, 2.256e-01, 7.051e-02, -2.908e-02, 3.436e-02));
	r += mul(s0_6, M4(3.209e-02, 6.307e-02, -9.054e-02, -8.768e-02, 4.559e-02, 1.228e-02, -9.741e-02, -1.333e-02, 4.699e-02, -2.987e-02, -9.209e-02, -4.504e-02, -5.781e-02, -1.210e-02, 4.755e-03, -3.660e-02));
	r += mul(s0_7, M4(3.852e-01, -7.354e-02, 6.934e-01, 2.655e-01, -1.076e-01, -2.764e-02, -2.245e-01, -2.043e-02, 2.494e-02, -2.843e-02, -1.866e-01, -1.078e-01, -9.126e-01, -7.305e-02, 5.294e-01, -4.012e-01));
	r += mul(s0_8, M4(-2.689e-02, -3.109e-02, 6.119e-02, -5.038e-02, -3.484e-02, -2.413e-02, -2.045e-02, -6.949e-02, 1.689e-01, -2.581e-02, -3.432e-01, -1.183e-01, -2.626e-01, 1.252e-01, 1.065e-01, 9.964e-02));
	r += mul(s1_0, M4(5.563e-02, -5.293e-03, -1.144e-01, -1.838e-02, 1.701e-02, -5.409e-02, -3.752e-03, -5.477e-02, -2.012e-02, 2.925e-02, 3.412e-03, -5.534e-02, -1.092e-02, -2.163e-01, -1.631e-02, -3.629e-02));
	r += mul(s1_1, M4(-5.482e-02, 1.035e-01, 2.477e-02, 8.276e-02, -6.786e-03, 4.052e-01, -2.698e-02, 6.194e-02, -1.876e-02, -1.215e-01, 4.887e-02, -1.139e-02, -3.486e-02, 6.106e-02, -8.037e-02, 3.796e-02));
	r += mul(s1_2, M4(-1.306e-02, -6.373e-03, 2.787e-02, -2.192e-02, 2.204e-02, -1.570e-02, 5.419e-02, 4.557e-02, 1.856e-02, 5.854e-02, -4.102e-02, 1.026e-02, -2.166e-02, 2.179e-02, -2.596e-02, -2.485e-02));
	r += mul(s1_3, M4(-2.055e-01, -4.064e-02, 1.909e-01, -1.990e-02, -1.418e-01, -5.217e-02, -1.189e-01, -2.404e-01, -1.007e-02, -3.034e-02, -6.765e-02, -4.256e-02, 5.986e-03, -1.362e-01, 9.809e-02, 7.911e-02));
	r += mul(s1_4, M4(1.165e-01, -1.708e-03, 9.398e-02, -2.319e-02, -2.175e-01, 1.383e-01, 1.886e-01, 8.530e-01, 1.774e-01, 8.190e-02, -1.219e-01, 1.468e-01, 2.250e-01, 1.069e-02, 1.893e-01, -3.827e-01));
	r += mul(s1_5, M4(9.527e-02, 7.578e-03, -8.374e-02, 7.642e-02, -2.803e-01, 2.766e-02, -1.083e-02, 1.334e-01, 1.318e-01, 4.811e-03, -1.092e-01, -1.165e-01, 1.460e-01, -1.919e-02, 3.415e-02, -1.275e-03));
	r += mul(s1_6, M4(1.174e-01, 3.071e-02, -2.049e-01, -3.301e-03, 8.101e-02, 4.616e-02, -2.816e-03, -3.701e-02, -1.546e-02, -4.089e-02, 3.641e-02, -2.577e-02, 6.504e-03, -4.748e-02, -1.203e-01, -2.020e-02));
	r += mul(s1_7, M4(-1.052e-01, -1.710e-02, 1.421e-02, -1.809e-02, -1.499e-01, -7.391e-03, 2.723e-02, 4.627e-02, 4.884e-02, 2.186e-02, -4.261e-03, 1.091e-01, -9.455e-02, -2.441e-03, -1.243e-01, -1.077e-01));
	r += mul(s1_8, M4(-5.349e-02, -1.001e-02, -1.542e-02, -1.971e-02, 2.600e-01, -3.059e-02, -1.564e-02, 9.008e-02, -3.460e-02, 1.414e-02, -1.044e-01, -5.504e-02, -1.130e-01, 7.744e-03, -1.029e-02, 2.556e-02));
	r += V4(-1.858e-03, -5.817e-03, 3.324e-03, -9.668e-03);
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
//!DESC CuNNy-3x4C-EASU-NVL-DS-out
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
	r += mul(s0_0, M4(6.643e-01, 3.401e-01, -7.676e-01, -3.818e-01, 5.581e-02, 1.137e-02, -4.765e-03, 3.137e-02, -5.289e-02, -4.053e-02, -8.227e-02, -5.556e-02, 1.841e-01, 3.065e-02, -1.900e-02, 2.759e-02));
	r += mul(s0_1, M4(-3.107e-02, 2.690e-01, 2.212e-01, -1.202e-01, -1.141e-01, 1.770e-01, 1.382e-01, 2.369e-02, 1.007e-01, 8.667e-02, 2.036e-01, 1.279e-01, 4.326e-01, -5.176e-01, 2.400e-01, 2.360e-02));
	r += mul(s0_2, M4(1.814e-02, 7.462e-03, -5.233e-02, -4.583e-02, -1.461e-02, -6.256e-02, -6.617e-02, -8.767e-02, -2.396e-02, -2.642e-02, -6.841e-02, -4.397e-02, -5.667e-02, 1.176e-01, 3.367e-02, 8.154e-02));
	r += mul(s0_3, M4(-1.392e-01, -9.315e-02, 1.577e-01, 1.666e-02, 1.583e-01, -1.100e-01, 1.137e-01, -7.586e-02, -3.910e-02, -3.840e-02, 2.260e-02, -2.892e-02, -1.002e-01, 5.646e-03, 1.274e-01, -5.799e-02));
	r += mul(s0_4, M4(5.824e-02, -2.228e-04, 1.984e-02, 1.738e-01, -1.044e+00, 5.601e-01, -9.166e-01, 5.142e-01, 5.447e-02, 6.344e-02, 1.358e-02, 1.162e-01, 1.146e-01, -2.105e-01, 2.576e-01, -7.501e-01));
	r += mul(s0_5, M4(-7.355e-03, -1.700e-02, -3.322e-03, -5.285e-02, -2.511e-02, 1.091e-01, 6.475e-03, 1.319e-01, -1.696e-02, -9.743e-03, 1.491e-02, 1.573e-02, 4.273e-03, 2.935e-02, -9.109e-02, 1.850e-02));
	r += mul(s0_6, M4(-2.809e-03, -7.527e-03, 1.550e-02, 7.044e-03, 1.884e-02, 2.753e-02, 1.540e-01, -9.503e-03, -1.630e-02, -5.151e-03, -7.440e-03, 3.902e-03, 3.068e-03, -1.957e-02, -7.496e-02, -6.215e-03));
	r += mul(s0_7, M4(1.511e-02, 7.467e-03, -1.635e-03, -1.551e-02, 2.394e-01, 9.993e-02, -1.314e-01, 2.791e-01, 2.935e-02, 1.284e-02, -1.619e-04, -1.316e-02, -1.189e-02, 4.189e-03, 2.467e-02, 4.740e-02));
	r += mul(s0_8, M4(-3.246e-03, 2.795e-03, -2.328e-03, 2.465e-03, 9.151e-03, -8.467e-02, 2.810e-02, -6.371e-02, -5.609e-03, -3.389e-03, 7.509e-03, -4.672e-03, -1.604e-03, -1.847e-02, 9.294e-03, -1.131e-02));
	r += mul(s1_0, M4(-2.569e-02, -6.140e-02, -5.066e-02, -7.886e-02, 6.134e-03, -5.385e-03, 7.814e-03, 1.382e-02, 3.743e-01, -1.794e-01, -3.115e-01, -1.335e-01, 2.654e-02, 4.972e-02, 5.772e-02, 4.128e-02));
	r += mul(s1_1, M4(5.274e-02, 1.433e-01, 7.226e-02, 1.233e-01, 7.853e-03, 1.030e-02, -5.460e-03, -1.144e-02, 1.724e-01, 7.832e-01, -5.172e-02, -1.903e-01, 1.074e-02, -3.101e-02, 9.649e-02, 9.889e-02));
	r += mul(s1_2, M4(-4.427e-03, -5.205e-02, -2.769e-02, -3.470e-02, -1.378e-02, -7.455e-03, -1.854e-02, -1.733e-02, -5.365e-03, -9.204e-02, -5.196e-02, -5.263e-02, 1.861e-02, 3.079e-02, 3.054e-02, 3.402e-02));
	r += mul(s1_3, M4(-1.857e-03, -3.641e-02, 6.275e-02, -2.309e-02, -4.122e-03, 1.085e-02, -4.384e-02, -2.570e-02, -8.616e-02, -3.725e-02, -4.388e-02, 6.714e-02, -6.789e-02, 2.711e-02, -1.204e-01, 3.963e-02));
	r += mul(s1_4, M4(2.288e-02, 6.920e-02, 3.117e-02, 1.997e-01, -1.698e-01, -1.508e-01, -3.172e-02, -3.567e-02, 1.054e-01, 3.142e-02, 1.160e-01, -4.843e-02, 7.384e-03, -9.956e-02, -1.454e-01, -3.824e-01));
	r += mul(s1_5, M4(-1.362e-02, -1.511e-02, -1.641e-03, -5.846e-02, 8.500e-03, -1.880e-02, -1.061e-03, -1.854e-02, -5.483e-02, -1.032e-02, 2.227e-02, 1.237e-01, 3.769e-05, 5.721e-03, -9.416e-03, 1.414e-02));
	r += mul(s1_6, M4(-2.747e-02, -4.482e-03, -1.678e-02, 9.957e-03, -5.181e-03, 6.395e-03, 5.460e-02, 5.089e-03, -3.309e-02, -1.004e-02, 1.217e-02, -1.461e-02, 2.507e-02, -9.274e-03, 1.388e-02, -2.028e-02));
	r += mul(s1_7, M4(1.659e-02, -5.342e-03, 2.806e-03, -3.822e-02, 1.304e-01, 9.736e-02, 4.189e-02, 1.047e-01, 3.091e-02, 3.879e-04, -2.258e-02, 1.221e-02, -4.236e-02, -1.016e-02, 2.191e-02, 5.118e-02));
	r += mul(s1_8, M4(8.131e-03, 1.151e-02, 1.254e-02, 3.061e-02, -8.184e-03, 6.823e-03, 1.573e-02, 3.306e-02, -5.250e-03, 5.308e-03, 5.017e-03, -8.732e-03, 2.378e-03, -4.097e-03, -2.565e-03, -1.355e-02));
	r += V4(-8.351e-05, -3.388e-04, -2.019e-04, -6.806e-04);
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
//!DESC CuNNy-3x4C-EASU-NVL-DS-shuffle
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

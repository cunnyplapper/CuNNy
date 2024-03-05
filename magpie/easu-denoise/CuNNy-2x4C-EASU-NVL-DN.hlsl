// CuNNy 2x4C CHROMA NVL DN
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
//!DESC CuNNy-2x4C-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(1.028e+00, 1.881e+00, 4.897e-01), O(INPUT, float2(x, y)).rgb) + -2.865e+00)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(6.574e-03, 1.233e-01, 1.474e-02, 3.772e-02) * s0_0;
	r += V4(9.741e-02, 7.812e-02, -5.481e-03, 3.136e-02) * s0_1;
	r += V4(1.597e-01, -1.996e-01, -8.135e-03, -3.886e-01) * s0_2;
	r += V4(8.602e-02, 2.010e-01, -3.823e-01, -3.362e-02) * s0_3;
	r += V4(-3.924e-01, -3.428e-01, 5.288e-01, -3.800e-02) * s0_4;
	r += V4(-3.528e-02, 2.340e-02, 3.046e-02, 3.957e-01) * s0_5;
	r += V4(8.279e-02, -1.012e-01, 6.690e-02, -1.679e-03) * s0_6;
	r += V4(1.911e-02, 1.487e-01, -2.276e-01, 4.077e-03) * s0_7;
	r += V4(-3.634e-02, 6.542e-02, -1.654e-02, -8.546e-03) * s0_8;
	r += V4(-2.958e-02, -9.306e-03, 3.719e-03, 3.064e-03);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-DN-conv1
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
	r += mul(s0_0, M4(-1.479e-01, -1.398e-01, -9.293e-03, -8.369e-02, -3.008e-02, 3.932e-02, -8.985e-03, 9.360e-02, -1.583e-01, 4.843e-02, 5.620e-02, 8.259e-02, -6.324e-02, -1.285e-01, 3.310e-02, -1.658e-01));
	r += mul(s0_1, M4(6.391e-02, 2.100e-01, -9.586e-02, 2.820e-01, 2.203e-01, 1.708e-02, 3.331e-02, -1.606e-01, 9.790e-02, 3.365e-01, 1.993e-01, -1.689e-02, -6.117e-03, -6.371e-02, 3.723e-02, 1.429e-01));
	r += mul(s0_2, M4(2.465e-02, 1.880e-02, -6.402e-02, 9.155e-02, -1.475e-01, -1.248e-02, -2.417e-01, -2.261e-02, -4.281e-02, 2.272e-01, -3.985e-02, -8.294e-02, 9.856e-02, -6.864e-02, 1.577e-01, 3.137e-02));
	r += mul(s0_3, M4(-2.864e-01, 2.155e-01, 2.304e-01, 7.347e-01, 2.316e-02, -3.014e-02, 3.359e-01, 5.245e-01, -1.603e-01, 7.233e-02, 1.997e-01, 2.376e-01, -2.200e-01, 2.172e-01, -8.360e-02, -1.294e-01));
	r += mul(s0_4, M4(-9.182e-02, -1.430e-01, 1.039e-01, -3.758e-01, -7.785e-02, -1.493e-01, 4.888e-01, 3.761e-01, -4.096e-01, 1.737e-02, -2.627e-01, -7.854e-02, -4.284e-02, 1.313e-01, -2.603e-02, -2.312e-01));
	r += mul(s0_5, M4(7.225e-02, 8.765e-02, -3.712e-01, -3.066e-01, -9.406e-02, -2.358e-01, 3.459e-02, -6.629e-02, 9.576e-02, 4.700e-01, -1.155e-01, 9.271e-03, 4.358e-02, -6.018e-02, -6.719e-03, -1.236e-02));
	r += mul(s0_6, M4(-3.409e-02, 6.755e-02, -3.879e-02, -1.087e-01, 1.281e-01, -1.579e-02, 7.925e-03, -1.138e-01, -3.888e-02, 1.273e-02, -1.188e-03, 3.312e-02, 1.086e-01, 1.755e-02, 1.743e-02, 2.809e-02));
	r += mul(s0_7, M4(-1.357e-01, 2.175e-03, 4.762e-02, 1.206e-02, -2.469e-01, -1.870e-01, 1.694e-01, -1.097e-01, -4.325e-01, -3.623e-02, -8.705e-02, 1.450e-02, 2.963e-02, 1.663e-01, -8.461e-02, 1.792e-01));
	r += mul(s0_8, M4(-3.275e-02, -1.255e-01, -8.845e-02, 1.871e-01, 1.662e-01, -8.117e-02, 8.326e-02, 1.333e-01, 2.472e-01, 6.192e-02, -7.630e-02, 1.343e-01, -1.313e-01, 1.391e-02, -7.917e-02, 1.370e-02));
	r += mul(s1_0, M4(-2.437e-01, -2.195e-01, 7.086e-04, -1.792e-01, 9.490e-03, 9.700e-02, -1.243e-02, 2.299e-02, 4.830e-02, 2.318e-02, 1.013e-01, 2.506e-01, -4.920e-02, -8.436e-02, -1.242e-02, 1.899e-04));
	r += mul(s1_1, M4(1.471e-01, 7.732e-03, 1.080e-01, 1.165e-01, 2.319e-01, -2.568e-02, 3.886e-02, -2.207e-01, 1.435e-01, 2.628e-01, 3.641e-01, 1.073e-01, -9.455e-02, 2.129e-01, -2.008e-01, 1.917e-01));
	r += mul(s1_2, M4(1.299e-01, -9.002e-02, 8.808e-02, 6.517e-02, -9.861e-02, -1.717e-02, -1.895e-01, -7.109e-02, -2.803e-01, 2.017e-01, 8.801e-03, 6.769e-02, 8.765e-02, 9.364e-03, 6.064e-02, 6.041e-02));
	r += mul(s1_3, M4(-2.725e-01, 1.950e-01, 2.300e-01, 5.997e-01, -1.061e-01, 1.217e-01, 1.581e-01, 2.671e-01, 3.600e-01, 3.457e-02, 2.900e-01, -1.350e-01, -2.093e-01, 3.410e-02, -1.297e-01, -1.711e-02));
	r += mul(s1_4, M4(3.951e-01, 1.178e-01, 6.811e-02, -4.469e-01, 5.440e-02, 2.725e-01, 9.496e-02, 5.555e-02, 9.826e-02, -3.165e-01, 9.560e-02, 2.477e-02, -1.469e-01, 4.089e-01, -1.616e-01, -2.822e-01));
	r += mul(s1_5, M4(1.733e-01, -1.333e-01, -2.842e-01, -2.807e-01, -3.719e-02, 4.947e-02, -1.772e-01, -1.135e-01, -4.609e-02, 4.665e-01, 1.412e-01, -5.865e-02, 1.634e-01, 6.408e-02, -1.884e-02, -4.070e-02));
	r += mul(s1_6, M4(9.222e-03, -1.340e-02, -1.794e-02, -1.777e-01, 2.714e-02, 2.563e-02, -7.441e-02, -1.142e-01, 1.499e-01, 2.449e-02, -3.231e-02, -2.619e-02, -1.710e-01, 2.141e-02, 2.201e-01, -5.755e-02));
	r += mul(s1_7, M4(9.424e-03, -5.724e-02, 3.865e-02, 1.406e-02, -1.780e-01, 4.490e-02, -9.305e-02, -8.658e-02, -2.744e-01, -1.327e-01, 6.148e-02, -1.464e-01, -5.188e-02, 2.212e-02, 1.451e-01, 1.974e-01));
	r += mul(s1_8, M4(-3.841e-02, -1.084e-01, -1.617e-01, 2.378e-01, 2.095e-01, 9.455e-02, -4.629e-02, 1.698e-01, 1.331e-01, -6.167e-02, 1.084e-01, 8.227e-02, 1.925e-02, -2.688e-02, 1.864e-02, -2.825e-02));
	r += V4(-4.458e-03, -1.349e-02, 8.457e-04, 5.913e-03);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-DN-conv2
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
	r += mul(s0_0, M4(-1.379e-01, -1.247e-01, -4.861e-01, 2.153e-01, -1.509e-01, -5.127e-02, 1.634e-02, 1.969e-02, -7.398e-03, 5.489e-03, 1.290e-02, 1.362e-01, -6.438e-07, -5.875e-03, -4.097e-03, -1.406e-02));
	r += mul(s0_1, M4(-1.087e-01, -5.253e-01, 4.436e-01, -4.604e-03, -6.532e-02, 1.145e-01, 2.081e-02, 6.523e-02, -1.677e-02, 3.410e-02, 1.201e-02, 4.879e-02, 8.313e-04, -1.546e-03, 1.773e-02, -5.401e-02));
	r += mul(s0_2, M4(4.533e-02, 1.561e-01, 1.428e-01, 1.937e-01, 1.800e-02, 4.507e-02, 2.399e-02, 5.876e-02, 1.958e-02, -3.235e-02, -2.899e-02, -5.605e-02, -2.409e-02, 2.389e-02, -3.724e-02, -5.944e-02));
	r += mul(s0_3, M4(-2.578e-01, -9.177e-02, -6.525e-01, -1.009e-01, -1.618e-02, -9.350e-02, -8.301e-01, 2.098e-01, -1.769e-01, -2.772e-02, -4.053e-02, -4.268e-01, 1.256e-02, -1.600e-03, -3.331e-02, 3.094e-02));
	r += mul(s0_4, M4(8.576e-01, 1.608e+00, 9.085e-01, -5.424e-01, 3.149e-01, -2.116e-01, 6.309e-01, 5.266e-01, -4.791e-02, 2.881e-02, 6.608e-02, -1.155e-01, 1.103e-01, 1.001e-01, 2.667e-02, 1.208e-01));
	r += mul(s0_5, M4(9.298e-02, 1.132e+00, 2.646e-01, 5.996e-01, -5.694e-02, 1.089e-01, 9.256e-03, 7.624e-02, -1.997e-02, -8.479e-02, -3.937e-02, -1.031e-01, 8.285e-02, -1.467e-01, 7.886e-02, 5.361e-02));
	r += mul(s0_6, M4(-2.529e-01, -1.453e-02, -8.356e-01, 4.938e-01, 7.914e-03, 3.340e-02, -1.332e-01, 8.918e-02, -4.016e-02, 4.932e-02, -1.176e-01, 4.324e-01, 1.321e-02, 1.409e-02, 8.582e-03, 2.008e-02));
	r += mul(s0_7, M4(4.821e-02, -3.524e-01, 8.890e-02, -1.003e-01, 3.040e-03, -1.912e-01, -1.459e-03, 8.166e-04, 8.857e-02, 2.750e-01, -5.682e-02, -5.894e-02, 1.083e-02, 5.921e-02, 1.309e-02, -3.688e-02));
	r += mul(s0_8, M4(-2.091e-02, 2.260e-01, 7.089e-03, -7.025e-02, 1.896e-02, 1.008e-01, 1.277e-02, 1.254e-02, 7.682e-03, -2.914e-02, 1.198e-02, 2.525e-03, -4.573e-02, 3.569e-03, -9.528e-02, 4.678e-03));
	r += mul(s1_0, M4(9.117e-03, -4.822e-02, 3.455e-02, -7.682e-03, -2.080e-02, 4.736e-02, -1.768e-02, 5.961e-03, -1.757e-02, 2.959e-01, -1.428e-01, -3.760e-02, 6.643e-03, -1.351e-02, -1.693e-02, -4.307e-02));
	r += mul(s1_1, M4(-5.212e-02, 1.855e-02, 1.110e-02, -4.139e-02, 6.579e-03, 2.044e-02, -2.679e-02, 1.316e-03, -7.353e-02, 3.066e-02, -1.795e-01, -1.480e-01, 5.720e-02, -1.904e-01, 1.034e-01, 4.711e-02));
	r += mul(s1_2, M4(1.229e-03, 6.087e-02, -2.362e-02, -1.151e-02, -1.223e-02, -3.667e-02, -1.344e-02, -3.979e-02, -2.336e-02, -1.302e-03, -1.356e-02, -7.940e-03, 1.016e-01, -7.543e-02, 1.733e-01, 1.402e-01));
	r += mul(s1_3, M4(5.893e-03, 1.347e-02, -7.722e-02, 6.422e-02, 9.056e-03, 1.225e-01, -5.706e-02, -3.949e-01, -5.972e-02, 9.535e-02, 2.056e-01, -1.581e-01, 2.217e-03, 4.508e-02, -5.517e-02, 5.053e-02));
	r += mul(s1_4, M4(1.531e-01, 8.960e-02, 1.749e-02, 1.043e-01, 6.153e-02, -2.588e-01, 1.058e-01, -3.598e-02, 5.436e-02, -7.793e-01, 2.331e-01, -1.300e-02, 5.310e-02, 2.509e-01, -2.874e-01, -9.371e-02));
	r += mul(s1_5, M4(3.536e-02, -1.064e-01, 4.435e-02, 4.168e-02, 1.781e-03, 1.010e-02, -7.597e-03, -2.737e-03, -3.646e-03, 4.725e-02, -3.945e-02, 1.460e-02, 2.350e+00, 2.990e-01, -1.319e-01, 2.241e-01));
	r += mul(s1_6, M4(9.708e-03, 3.821e-02, 1.953e-02, -3.481e-02, 2.206e-02, 1.382e-01, -4.086e-02, 8.771e-02, 1.364e-02, -5.183e-02, 5.011e-02, -2.247e-02, 1.813e-02, -4.816e-02, 5.940e-03, 1.244e-01));
	r += mul(s1_7, M4(-1.063e-02, 1.605e-02, 2.314e-02, -3.368e-02, -4.065e-02, -5.162e-02, -6.618e-02, -2.648e-02, -2.736e-02, 6.308e-02, -1.373e-02, 5.102e-02, -3.022e-02, 3.317e-02, 6.938e-02, 1.664e-01));
	r += mul(s1_8, M4(-2.460e-02, -2.926e-02, -3.664e-02, -3.639e-02, 5.562e-03, 1.992e-02, 2.860e-04, -3.795e-03, -5.872e-03, -6.077e-02, -3.795e-03, -5.908e-03, -1.812e-01, -4.021e-02, 9.912e-02, -1.782e-01));
	r += V4(-9.052e-04, 1.778e-03, -9.512e-04, 2.624e-03);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-DN-out
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
	r += mul(s0_0, M4(-1.777e-01, 5.696e-02, 6.715e-02, 3.810e-02, 1.510e-01, -5.986e-02, 2.054e-02, -2.786e-02, 4.678e-02, 4.460e-02, -5.529e-02, 1.145e-02, 7.350e-02, -1.925e-02, 3.720e-02, -9.186e-03));
	r += mul(s0_1, M4(1.788e-01, -5.345e-01, 3.531e-02, 1.938e-01, 2.733e-02, 9.178e-02, -9.115e-02, -4.343e-02, 9.590e-02, 9.880e-02, -8.075e-02, -4.170e-02, -1.587e-01, 9.107e-02, 6.915e-03, 2.155e-02));
	r += mul(s0_2, M4(-4.915e-02, 1.388e-01, -1.407e-02, -3.121e-02, -2.191e-02, 3.207e-02, -1.075e-02, 5.039e-03, -1.725e-02, -8.419e-03, 3.308e-02, 1.111e-02, 3.753e-02, -9.707e-02, -1.407e-02, -1.205e-03));
	r += mul(s0_3, M4(-1.704e-01, 1.652e-01, -1.753e-02, 1.802e-01, -6.369e-02, -1.096e-01, 2.067e-01, -6.269e-02, 7.412e-02, 5.822e-02, -6.450e-02, 2.655e-02, 1.594e-02, 7.757e-03, 4.505e-02, 8.449e-03));
	r += mul(s0_4, M4(1.033e+00, 4.084e-01, -5.608e-01, -1.595e+00, -7.544e-02, 8.716e-02, 1.035e-01, 2.607e-01, -3.195e-01, -5.410e-01, 5.445e-01, -4.597e-02, 9.378e-02, 3.589e-03, -1.988e-01, -3.164e-02));
	r += mul(s0_5, M4(-5.285e-02, 1.776e-01, -2.451e-01, -7.053e-02, 2.334e-02, -5.668e-02, 4.838e-04, -1.963e-02, 3.542e-02, -1.773e-01, 7.348e-02, -2.994e-02, -1.633e-02, 1.668e-01, 1.377e-02, 4.186e-02));
	r += mul(s0_6, M4(-3.122e-03, -9.158e-02, -2.667e-02, 1.103e-02, 2.872e-02, -3.918e-02, 1.452e-02, -3.834e-03, -5.965e-02, 2.224e-02, 3.997e-03, 1.142e-02, -1.169e-02, 2.078e-03, 5.908e-02, 1.299e-03));
	r += mul(s0_7, M4(-2.797e-02, 5.536e-02, 2.708e-02, 7.055e-02, -1.244e-03, -7.012e-03, -2.605e-02, -4.111e-03, 5.102e-02, -3.467e-02, 3.905e-02, 7.766e-03, -2.539e-02, -4.700e-02, -2.907e-02, 6.681e-03));
	r += mul(s0_8, M4(2.373e-02, 3.576e-03, 1.366e-03, -3.842e-02, -3.924e-03, 1.658e-02, 3.443e-04, -8.309e-06, 2.529e-02, 2.611e-02, -6.051e-03, 1.088e-02, -8.302e-03, -2.204e-02, 1.097e-02, 8.029e-03));
	r += mul(s1_0, M4(-1.457e-02, 9.356e-03, 5.403e-03, 3.727e-03, 8.081e-02, -1.208e-02, -4.111e-03, -2.344e-02, 2.774e-02, -1.529e-02, -7.790e-03, 7.870e-04, 5.247e-02, -5.245e-03, -2.240e-02, -2.517e-02));
	r += mul(s1_1, M4(2.589e-02, -1.702e-02, -6.889e-03, -1.268e-03, -1.297e-03, 8.097e-02, -1.160e-01, -7.481e-03, -5.336e-02, 3.429e-02, 1.285e-02, 1.953e-02, -1.035e-02, 1.418e-02, -1.572e-03, 1.620e-02));
	r += mul(s1_2, M4(-5.908e-03, 2.090e-02, -6.188e-03, -4.231e-03, -1.284e-02, -2.262e-02, 2.848e-03, 8.881e-03, 1.945e-02, -1.489e-02, 2.330e-02, 7.969e-03, -1.235e-01, 4.789e-02, 6.617e-02, 4.255e-02));
	r += mul(s1_3, M4(-7.020e-02, 2.776e-02, -3.951e-02, 7.056e-03, -6.041e-02, 3.819e-02, 6.763e-02, 3.187e-02, 2.916e-03, 1.285e-02, 2.918e-02, -1.010e-03, -5.547e-02, -1.953e-02, 1.806e-01, 1.856e-02));
	r += mul(s1_4, M4(-9.155e-02, -2.059e-01, 8.226e-02, 3.528e-02, 5.922e-01, -2.824e-01, 4.746e-01, -1.543e-01, -1.606e-01, 1.519e-01, -2.712e-01, 6.577e-02, 2.128e-01, -1.404e-01, -5.909e-01, 6.377e-02));
	r += mul(s1_5, M4(4.099e-03, -2.193e-02, -3.942e-03, -9.237e-03, -1.210e-01, 5.358e-02, -7.350e-02, 1.556e-02, 1.459e-01, -1.623e-01, 1.411e-01, -2.441e-01, 4.510e-01, 7.833e-01, -1.183e-01, -5.332e-01));
	r += mul(s1_6, M4(-4.165e-03, -2.203e-02, 5.253e-02, -7.954e-04, -2.359e-03, -2.155e-02, 8.181e-03, 1.334e-04, 4.294e-03, 5.146e-03, -7.657e-03, 2.727e-03, -1.174e-02, 5.385e-03, 1.016e-01, 2.889e-02));
	r += mul(s1_7, M4(2.202e-01, 1.592e-01, -1.557e-01, -1.508e-01, -6.722e-02, -2.752e-02, 1.000e-01, -4.485e-02, -2.116e-02, -6.814e-02, 5.677e-02, 2.618e-02, -8.998e-01, -4.717e-01, 9.871e-01, 4.135e-01));
	r += mul(s1_8, M4(4.377e-03, 7.709e-02, -1.287e-02, -1.257e-02, -2.648e-02, 4.871e-02, -7.883e-02, 1.607e-02, 1.715e-02, -1.693e-02, -7.155e-03, -5.897e-03, 2.960e-02, -3.819e-01, -3.033e-01, 3.143e-01));
	r += V4(8.809e-04, 5.560e-04, 5.884e-04, -2.296e-04);
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
//!DESC CuNNy-2x4C-CHROMA-NVL-DN-shuffle
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

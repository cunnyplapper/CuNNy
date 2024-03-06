// CuNNy 3x4C CHROMA NVL DN
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
//!DESC CuNNy-3x4C-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(3.177e-01, 5.957e-01, 1.476e-01), O(INPUT, float2(x, y)).rgb) + -9.009e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(7.293e-02, -5.286e-02, 1.682e-01, 1.553e-02) * s0_0;
	r += V4(-5.113e-02, -8.077e-02, -1.165e-01, -8.149e-02) * s0_1;
	r += V4(-1.360e-02, 1.479e-01, -3.836e-02, 3.585e-02) * s0_2;
	r += V4(-1.047e-01, 1.223e-01, 6.014e-01, -1.674e-02) * s0_3;
	r += V4(-6.348e-01, -7.148e-01, -6.454e-01, -5.959e-01) * s0_4;
	r += V4(5.250e-02, -1.525e-01, 5.977e-03, 6.497e-01) * s0_5;
	r += V4(2.730e-02, 3.100e-01, 3.186e-02, -2.594e-02) * s0_6;
	r += V4(5.270e-01, 4.276e-01, -4.613e-02, 1.153e-02) * s0_7;
	r += V4(1.242e-01, -2.752e-02, 4.333e-02, 2.201e-03) * s0_8;
	r += V4(4.098e-03, -1.008e-02, -1.849e-02, -1.291e-02);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-DN-conv1
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
	r += mul(s0_0, M4(-1.223e-01, 1.265e-01, -8.047e-02, 1.120e-01, -1.209e-01, -1.562e-01, 2.026e-01, -1.112e-01, 7.700e-02, 5.611e-03, -4.475e-03, 8.239e-02, 1.630e-01, 3.886e-01, -8.715e-02, 4.111e-01));
	r += mul(s0_1, M4(-2.568e-01, 1.640e-01, 3.260e-01, 2.542e-02, 5.862e-03, -3.699e-01, 4.399e-01, 5.651e-03, -6.361e-02, 1.243e-01, 1.335e-01, -5.343e-02, -2.310e-01, -1.460e-01, -2.089e-01, 4.698e-02));
	r += mul(s0_2, M4(-2.160e-01, 2.105e-01, -2.260e-01, -3.346e-02, 1.579e-01, -7.204e-02, 1.527e-02, 1.547e-01, -1.331e-01, -1.188e-02, 3.831e-02, -3.566e-03, -6.374e-02, -1.096e-02, -7.992e-02, 1.652e-01));
	r += mul(s0_3, M4(-4.106e-01, 2.639e-01, -3.155e-01, -5.865e-02, 2.920e-01, -3.693e-01, -2.281e-02, -4.255e-02, -4.688e-02, 1.746e-01, -1.455e-01, -3.101e-02, -4.207e-01, 9.191e-03, 9.580e-01, -3.866e-01));
	r += mul(s0_4, M4(1.047e-01, 7.293e-01, -4.428e-01, -2.143e-01, 3.291e-01, -4.167e-01, 3.000e-01, -6.186e-02, -2.041e-01, 2.248e-01, -6.201e-01, -7.228e-02, 5.010e-01, -2.881e-01, 8.027e-01, -3.942e-01));
	r += mul(s0_5, M4(-3.955e-02, 2.822e-01, 3.361e-01, 2.195e-01, 2.991e-01, -4.741e-01, 2.569e-01, -5.590e-01, -7.207e-01, 2.148e-01, -2.946e-01, -1.193e-01, 8.824e-02, -1.430e-01, 1.474e-01, -2.377e-01));
	r += mul(s0_6, M4(-1.790e-01, 7.466e-03, -2.341e-01, 3.750e-02, 2.376e-02, -1.166e-01, 1.659e-03, -1.246e-02, -1.479e-01, 9.414e-02, 6.516e-02, 9.414e-02, 4.271e-01, 4.198e-01, 4.032e-01, -4.553e-01));
	r += mul(s0_7, M4(-2.641e-01, 2.529e-01, -1.753e-01, -3.594e-02, 3.115e-01, -1.308e-01, 4.083e-01, 1.353e-01, -6.947e-02, -3.119e-03, -1.130e-01, 1.272e-01, 7.103e-02, 2.959e-01, -4.629e-01, -4.762e-02));
	r += mul(s0_8, M4(4.052e-02, 3.135e-01, -3.361e-04, 2.660e-01, 7.462e-02, -3.271e-01, -3.776e-02, -2.389e-01, -2.442e-03, 2.790e-01, 3.173e-02, -6.053e-01, 5.454e-02, -1.657e-02, -6.544e-02, -2.203e-02));
	r += mul(s1_0, M4(-1.926e-01, -1.330e-01, -1.766e-01, -2.434e-01, -1.981e-01, 5.441e-02, 1.342e-01, 1.050e-01, 9.315e-02, -6.182e-02, -1.384e-02, -4.304e-02, -1.034e-01, 5.382e-02, 1.479e-01, 6.105e-02));
	r += mul(s1_1, M4(-4.565e-01, -3.723e-01, 9.164e-02, -4.002e-02, -1.443e-01, 1.822e-01, 1.603e-01, 7.649e-02, 1.219e-01, 3.233e-01, -7.093e-02, 3.305e-01, -2.361e-01, -1.578e-01, 8.122e-02, 9.983e-02));
	r += mul(s1_2, M4(-1.044e-01, -2.683e-01, -7.755e-03, 1.398e-01, -8.080e-02, 4.747e-01, -2.670e-01, -8.891e-02, -1.218e-01, 2.048e-02, -1.494e-01, -9.895e-02, -9.102e-02, 4.121e-02, 9.105e-02, 4.016e-02));
	r += mul(s1_3, M4(-4.815e-01, -1.326e-01, -1.265e-01, -3.022e-01, 2.216e-01, -1.820e-02, -1.199e-01, 2.091e-02, -2.925e-02, -9.688e-04, -7.614e-02, -4.674e-02, -2.385e-01, -4.611e-02, -3.886e-01, 8.188e-02));
	r += mul(s1_4, M4(-5.885e-02, -4.715e-01, -4.006e-01, 9.090e-01, 1.997e-01, 7.090e-01, 2.073e-01, -9.947e-02, -5.367e-01, -4.471e-02, 4.989e-01, -3.843e-01, -2.114e-01, 4.582e-01, -1.294e-01, 2.551e-01));
	r += mul(s1_5, M4(4.960e-03, -6.346e-01, 3.640e-01, 3.440e-01, 1.734e-01, 3.707e-01, -1.085e-01, 5.974e-03, -5.270e-01, -5.762e-01, 4.792e-01, 2.588e-01, 9.503e-02, 1.255e-01, -4.137e-02, -1.208e-01));
	r += mul(s1_6, M4(-2.466e-01, -2.705e-01, -9.905e-02, 2.710e-02, 7.369e-02, 1.065e-01, -4.520e-02, -2.555e-02, -1.223e-01, 4.284e-02, -3.914e-02, -5.157e-02, 8.563e-02, 1.067e-01, 2.576e-01, -4.455e-02));
	r += mul(s1_7, M4(-2.359e-01, -3.830e-01, 4.475e-03, -1.739e-01, 3.330e-01, 3.331e-01, 1.462e-01, -2.891e-02, 1.563e-01, 3.345e-01, 2.138e-01, -2.912e-01, 1.871e-01, 2.539e-01, -5.148e-01, -6.254e-02));
	r += mul(s1_8, M4(7.370e-02, -1.948e-01, 8.668e-02, -1.239e-02, -2.196e-02, 1.341e-01, -2.344e-01, -4.889e-02, -1.997e-01, 1.291e-01, 3.428e-02, 5.013e-01, 6.618e-02, 7.199e-02, -1.523e-02, -2.017e-01));
	r += V4(-3.431e-02, 1.195e-02, -1.356e-02, 3.793e-02);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-DN-conv2
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
	r += mul(s0_0, M4(1.021e-02, 1.889e-02, -3.427e-02, 8.294e-03, -4.283e-02, 1.383e-02, 8.457e-02, 2.841e-02, 1.449e-02, 8.710e-02, 5.027e-03, -4.115e-02, 9.573e-02, 2.705e-01, -1.497e-01, -3.465e-01));
	r += mul(s0_1, M4(-2.589e-02, -2.632e-02, 6.958e-02, 9.158e-02, 1.432e-01, 1.714e-01, -2.106e-02, -2.772e-01, -9.090e-02, -8.616e-02, 7.273e-02, -7.268e-03, -3.254e-01, 3.635e-01, -4.178e-01, -3.931e-01));
	r += mul(s0_2, M4(-3.441e-02, -4.350e-02, -1.175e-01, -4.162e-02, -2.705e-01, -5.510e-02, -1.590e-01, 5.793e-02, -1.663e-01, 1.892e-02, -1.953e-01, 9.883e-02, -3.474e-01, 9.194e-02, -2.529e-01, -4.146e-01));
	r += mul(s0_3, M4(-2.021e-02, -1.143e-01, 7.202e-03, -6.763e-02, 4.186e-02, -5.054e-02, -1.898e-01, -3.174e-02, -4.424e-02, -1.881e-02, 4.520e-02, -2.717e-02, 1.227e-01, 1.615e-01, -1.248e-01, -1.895e-01));
	r += mul(s0_4, M4(-1.490e-01, 6.426e-01, 1.416e-01, 4.542e-01, -3.349e-01, -5.899e-02, 1.968e-01, 2.771e-01, -1.112e-01, -4.541e-01, 1.051e-01, 5.176e-01, -3.212e-01, 1.314e-01, -2.466e-01, -1.334e-01));
	r += mul(s0_5, M4(-1.304e-01, -1.346e-01, -8.531e-02, 2.921e-02, 5.431e-02, -5.470e-02, -2.801e-01, 1.606e-01, 2.535e-01, -3.834e-02, 1.449e-01, 3.003e-01, -4.122e-01, -2.532e-02, -3.817e-01, -1.220e-01));
	r += mul(s0_6, M4(4.814e-02, -3.853e-02, -9.582e-02, -2.133e-02, 8.103e-02, 2.783e-02, 4.680e-02, 1.574e-02, 3.494e-02, -2.546e-02, -7.309e-02, -6.558e-02, 1.538e-01, 1.372e-01, 1.792e-01, -2.476e-03));
	r += mul(s0_7, M4(-2.997e-01, -2.959e-01, 2.574e-01, 4.408e-02, -1.079e-01, -5.011e-02, -3.023e-02, -9.689e-03, -1.236e-01, -9.119e-02, 4.006e-02, -7.095e-02, -2.958e-01, -4.012e-02, -8.549e-02, -9.461e-02));
	r += mul(s0_8, M4(1.905e-01, 3.084e-02, 1.782e-01, 1.011e-01, 4.871e-02, 8.326e-02, -1.564e-01, -1.602e-01, 2.095e-01, 1.713e-01, 1.322e-01, -3.965e-02, -8.020e-02, -9.015e-02, -1.410e-01, 6.518e-02));
	r += mul(s1_0, M4(-5.115e-02, 6.494e-02, -1.802e-01, -7.989e-02, -2.963e-02, -7.532e-02, -8.476e-02, 2.005e-02, -3.730e-02, 7.641e-02, 3.070e-02, 3.735e-03, -6.039e-02, 1.378e-01, 8.312e-02, 1.092e-01));
	r += mul(s1_1, M4(-2.222e-01, -5.991e-02, 3.808e-02, 6.983e-03, 1.040e-01, -1.850e-01, 1.290e-01, 2.016e-01, -4.640e-02, 7.833e-02, -1.626e-01, -1.173e-01, -3.102e-02, 1.635e-01, -4.138e-02, -7.276e-02));
	r += mul(s1_2, M4(-2.588e-02, -2.494e-02, -2.802e-01, 2.013e-02, -1.711e-01, 5.605e-02, -2.104e-01, 7.295e-02, -2.199e-01, -1.615e-01, -2.686e-01, 1.304e-01, -1.196e-01, -5.500e-02, -6.953e-02, 3.307e-02));
	r += mul(s1_3, M4(-3.335e-02, -9.849e-02, -2.000e-01, -2.036e-01, 6.737e-03, 6.546e-02, -2.628e-01, -1.357e-01, -7.383e-02, 1.509e-01, -9.253e-02, -5.729e-02, -3.378e-03, 1.445e-02, 1.118e-01, 1.097e-01));
	r += mul(s1_4, M4(-9.828e-02, 4.955e-01, 4.357e-01, 7.794e-01, -1.086e-01, -1.376e-01, 5.956e-01, 1.320e-01, 1.372e-01, 2.568e-01, -4.539e-01, 5.310e-03, -2.211e-01, 1.958e-02, -7.982e-02, 1.214e-01));
	r += mul(s1_5, M4(1.178e+00, -5.927e-02, 2.349e-01, 2.150e-01, 3.135e-01, -1.919e-01, 4.362e-02, 3.667e-01, -1.598e-01, -1.179e-01, -2.287e-01, 1.145e-01, -1.809e-02, -4.934e-02, 8.487e-03, 1.076e-01));
	r += mul(s1_6, M4(1.435e-01, 4.578e-01, -2.637e-01, -3.574e-01, 7.931e-02, -1.267e-01, 1.555e-01, 1.441e-01, -1.030e-02, -3.037e-02, 3.242e-02, 3.834e-02, -2.728e-02, -4.773e-02, 7.760e-03, -4.855e-02));
	r += mul(s1_7, M4(-4.968e-01, 1.915e-01, 3.297e-02, -7.487e-01, -1.903e-01, 1.073e-01, -3.764e-01, -1.000e-01, -1.304e-01, -4.946e-02, -1.220e-01, -7.538e-02, -4.232e-02, -1.417e-01, 1.318e-01, 6.283e-02));
	r += mul(s1_8, M4(4.681e-01, 3.305e-01, 4.073e-01, -4.553e-01, 2.112e-01, 4.567e-02, -6.048e-03, -1.556e-01, -7.370e-02, 4.448e-02, -1.558e-01, -9.576e-02, 6.297e-02, 1.938e-02, 5.336e-02, 2.907e-02));
	r += V4(-1.036e-02, 3.697e-03, -1.944e-02, -8.768e-03);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-DN-conv3
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
	r += mul(s0_0, M4(5.112e-01, -2.155e-01, -2.415e-01, 1.923e-02, -3.547e-03, 8.899e-02, -3.650e-02, -7.005e-02, -7.017e-03, -1.324e-01, -2.959e-01, 1.076e-01, -9.236e-02, 3.087e-02, 9.746e-02, -1.508e-02));
	r += mul(s0_1, M4(-2.081e-01, -6.614e-01, 1.305e-01, 2.144e-01, -1.115e-02, -5.439e-02, -1.490e-01, 5.587e-02, 5.231e-01, -7.538e-02, -3.636e-01, 2.032e-02, -8.068e-01, -6.182e-02, 2.539e-01, 3.365e-02));
	r += mul(s0_2, M4(-9.882e-02, 2.173e-01, 8.735e-02, -6.402e-02, 8.931e-02, -7.551e-02, -9.741e-02, 2.131e-02, 7.109e-02, -9.969e-02, 7.411e-03, -4.144e-02, -1.431e-01, 7.925e-02, 1.443e-02, -2.703e-02));
	r += mul(s0_3, M4(7.247e-01, 2.956e-02, 3.958e-01, 6.047e-01, -3.804e-02, 1.037e-01, -2.011e-02, -7.598e-03, 1.529e-01, 4.015e-02, 2.745e-01, 2.744e-01, -3.447e-01, 8.295e-03, 3.141e-02, 1.349e-01));
	r += mul(s0_4, M4(-6.757e-02, -5.339e-01, -2.835e-01, 1.141e-02, -4.131e-02, -1.585e-01, 8.032e-02, 2.075e-01, -1.224e-01, -4.301e-02, 3.386e-01, -3.005e-01, 6.808e-01, -5.733e-02, 1.943e-01, -1.424e-01));
	r += mul(s0_5, M4(-3.486e-02, 1.581e-02, -2.975e-02, -3.458e-02, -4.700e-03, 2.789e-02, 5.309e-02, -1.263e-01, -7.820e-02, -1.411e-01, -7.105e-02, 1.823e-01, 5.579e-02, 8.310e-02, 1.243e-01, -5.914e-02));
	r += mul(s0_6, M4(3.394e-02, 4.688e-02, -2.458e-01, -1.025e-01, -2.940e-02, 4.988e-02, 6.885e-02, 8.073e-02, 6.057e-03, -7.992e-02, -1.470e-01, 7.587e-02, -4.700e-02, 6.096e-02, 2.017e-01, 8.905e-02));
	r += mul(s0_7, M4(9.957e-02, -3.241e-02, -4.819e-02, -3.526e-02, -3.176e-03, -4.749e-02, 7.434e-02, 7.008e-02, -1.162e-02, -6.780e-04, -1.304e-01, -6.087e-02, -4.020e-02, -1.148e-01, -1.683e-01, -3.886e-02));
	r += mul(s0_8, M4(3.581e-02, 3.038e-02, 2.812e-02, -5.280e-02, 1.950e-02, 2.673e-02, -2.788e-02, -6.861e-02, 7.728e-02, -9.351e-02, -2.227e-02, 1.284e-01, 2.526e-02, 8.153e-02, 2.010e-02, -7.496e-02));
	r += mul(s1_0, M4(-1.370e-01, 1.729e-02, 3.060e-02, 4.006e-02, 6.517e-02, -2.634e-02, 2.988e-02, -3.018e-02, -1.899e-02, -5.272e-04, -6.213e-02, -3.144e-04, -4.534e-02, -2.604e-02, -2.986e-02, 5.578e-02));
	r += mul(s1_1, M4(-3.586e-02, -3.895e-02, 9.839e-02, -6.187e-02, -7.074e-02, -1.744e-02, -4.758e-02, 5.347e-02, 1.459e-02, -7.933e-02, -1.132e-01, 4.767e-02, -4.885e-02, -2.334e-02, -1.255e-01, 4.043e-02));
	r += mul(s1_2, M4(-2.218e-02, -3.330e-02, -1.510e-03, 3.221e-02, 1.212e-01, -6.511e-02, -7.358e-02, -1.714e-02, -8.026e-03, 4.118e-02, 2.005e-02, -5.500e-02, 1.053e-01, -7.837e-02, -9.057e-02, -2.039e-02));
	r += mul(s1_3, M4(9.903e-03, -4.439e-02, 2.184e-01, 3.545e-01, -8.862e-02, -3.626e-02, -1.008e-02, -4.745e-02, 8.495e-02, -1.340e-01, 8.347e-02, -8.579e-02, -1.052e-01, 1.050e-01, 4.502e-02, 1.860e-01));
	r += mul(s1_4, M4(-1.292e-01, -4.288e-02, 9.600e-02, 2.122e-02, -2.420e-01, -1.037e+00, 2.424e-01, 4.232e-01, -1.311e-02, 2.315e-01, 8.629e-02, 8.788e-02, 1.993e-02, -2.298e-01, 2.225e-01, 1.542e-01));
	r += mul(s1_5, M4(-2.013e-02, -4.255e-02, 1.609e-02, 3.626e-02, -3.866e-01, 3.542e-01, 2.174e-01, -1.713e-01, 8.838e-03, -1.360e-02, 1.412e-02, -3.092e-02, -3.972e-02, 1.529e-01, 1.081e-01, -1.275e-01));
	r += mul(s1_6, M4(3.870e-02, 1.176e-02, -1.169e-01, -1.204e-01, -3.374e-02, -2.420e-02, 7.625e-02, 7.069e-02, -3.745e-02, -4.662e-02, -1.215e-03, 1.651e-02, -1.803e-02, 6.015e-02, 1.670e-01, 1.581e-01));
	r += mul(s1_7, M4(7.253e-02, 1.962e-02, -8.664e-02, -7.260e-02, -1.033e-01, -9.227e-02, -1.382e-01, 5.343e-02, 4.191e-03, 3.653e-02, -1.739e-03, 3.642e-03, -4.140e-02, -1.353e-01, 1.417e-01, 7.425e-02));
	r += mul(s1_8, M4(-7.946e-03, 3.537e-02, 1.027e-02, -7.016e-03, 6.455e-02, 2.727e-02, 4.275e-02, -5.705e-02, 2.150e-02, -3.228e-02, -2.129e-02, 2.459e-02, 1.299e-02, 8.146e-02, -4.571e-02, -9.001e-02));
	r += V4(-6.552e-04, 7.968e-03, -3.670e-04, -4.058e-03);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-DN-out
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
	r += mul(s0_0, M4(7.152e-02, 2.069e-02, -2.531e-02, 5.967e-03, 5.033e-03, -4.763e-03, -7.498e-03, -1.768e-03, 9.741e-02, -3.873e-02, 4.235e-02, -4.927e-03, 1.531e-01, -1.166e-02, -8.983e-02, -1.007e-02));
	r += mul(s0_1, M4(-8.028e-03, -3.826e-02, -5.779e-03, -4.663e-02, -6.552e-02, -6.538e-02, -3.741e-02, -7.104e-02, -1.387e-01, 1.367e-02, -5.728e-03, 3.022e-02, -6.693e-01, 2.203e-01, 1.480e-01, -1.558e-01));
	r += mul(s0_2, M4(5.288e-03, 8.863e-02, 2.034e-02, 4.728e-02, -7.674e-03, -2.186e-02, -1.807e-02, -8.427e-03, 6.368e-02, 4.962e-02, 6.030e-02, 5.046e-02, 1.025e-01, 2.882e-01, -5.334e-02, -3.801e-02));
	r += mul(s0_3, M4(-2.387e-01, 3.454e-02, -2.231e-02, 2.122e-02, -6.343e-02, -3.582e-02, -4.152e-02, -3.024e-02, 1.400e-01, 3.872e-02, -2.809e-01, 2.713e-01, 2.047e-01, -9.628e-02, 4.152e-01, -8.471e-02));
	r += mul(s0_4, M4(-2.190e-02, -4.947e-01, 5.739e-02, -2.572e-01, 3.711e-01, 2.417e-01, 3.200e-01, 1.819e-01, 7.366e-01, 5.534e-01, -9.188e-01, -1.527e+00, -3.083e-01, 8.616e-01, -1.226e+00, 1.069e+00));
	r += mul(s0_5, M4(5.302e-02, 2.085e-01, 1.528e-02, 2.134e-01, 3.063e-02, 1.655e-01, -6.596e-03, 1.240e-01, -1.381e-01, 1.237e-01, 1.635e-01, 2.560e-01, 5.317e-02, -1.243e-01, 2.183e-01, 2.814e-01));
	r += mul(s0_6, M4(8.333e-02, 1.959e-02, -1.877e-02, 5.920e-02, 5.767e-03, -2.246e-02, -5.087e-02, -5.700e-02, -9.058e-03, -1.036e-02, 1.665e-01, -3.674e-02, -1.506e-02, -1.985e-02, -6.620e-02, -3.591e-02));
	r += mul(s0_7, M4(7.290e-02, 9.350e-02, -1.696e-03, -1.421e-01, -1.274e-01, -2.704e-02, -1.106e-01, 1.680e-02, -1.753e-01, -1.101e-01, 2.964e-01, 4.463e-01, -6.978e-02, -1.381e-01, 7.382e-02, 2.578e-02));
	r += mul(s0_8, M4(-1.224e-02, 2.077e-02, 6.799e-03, 5.628e-02, -4.247e-02, -1.167e-01, -3.011e-02, -1.054e-01, 2.902e-02, -5.034e-02, -1.059e-02, 3.548e-02, 1.023e-02, -8.402e-02, -1.402e-02, -1.995e-01));
	r += mul(s1_0, M4(-2.625e-02, -5.494e-05, -6.276e-04, 9.102e-03, -3.059e-02, 2.257e-02, 1.632e-02, 4.536e-02, -1.078e-01, -2.134e-02, 1.018e-03, 1.133e-03, 1.303e-02, 2.622e-02, -6.162e-02, 2.354e-02));
	r += mul(s1_1, M4(-1.630e-02, -6.846e-02, 9.419e-03, -3.915e-02, -4.502e-02, -6.136e-02, -1.849e-02, -1.260e-01, 5.829e-03, -1.558e-01, -4.362e-02, -1.078e-01, -2.626e-02, -1.450e-01, -1.272e-01, -2.437e-01));
	r += mul(s1_2, M4(1.670e-02, 5.269e-02, 6.832e-03, 4.211e-02, -1.881e-02, -2.861e-03, -4.554e-03, -3.404e-04, 4.089e-02, 1.361e-01, 6.048e-02, 1.245e-01, 3.730e-02, 8.134e-02, 5.554e-02, 6.158e-02));
	r += mul(s1_3, M4(3.164e-02, 6.275e-02, -1.122e-02, 4.161e-02, -7.676e-01, 2.893e-01, -4.112e-01, 5.343e-02, 9.452e-02, 4.616e-02, -1.548e-01, 6.517e-02, -4.028e-02, -6.089e-02, 1.326e-01, -4.050e-02));
	r += mul(s1_4, M4(-2.007e-01, -3.272e-01, -2.264e-02, -1.267e-01, 2.705e-01, 4.735e-01, 1.719e-01, 5.374e-01, -1.476e-01, -1.708e-01, 1.421e-02, -3.585e-01, 1.870e-01, 2.975e-01, 3.345e-01, 3.955e-01));
	r += mul(s1_5, M4(9.880e-02, 2.189e-01, 4.874e-02, 1.249e-01, 8.258e-02, 9.643e-02, 4.598e-02, 3.467e-02, -9.470e-03, 1.241e-02, -4.017e-02, 1.036e-01, 6.030e-03, -1.414e-02, -2.402e-02, 7.435e-02));
	r += mul(s1_6, M4(2.899e-01, 4.160e-02, -3.955e-01, 6.785e-02, 2.192e-01, -1.171e-01, -1.668e-01, 1.381e-01, -3.081e-03, 2.402e-02, 6.616e-02, 2.631e-02, -1.127e-02, 5.919e-03, -7.155e-02, -2.527e-02));
	r += mul(s1_7, M4(3.096e-01, 5.605e-01, 4.179e-02, -7.468e-01, -7.201e-02, -1.028e-01, -2.085e-02, -9.420e-02, 5.468e-02, 1.613e-02, 1.693e-02, 3.868e-02, -6.306e-02, -9.546e-02, -1.204e-01, -6.616e-02));
	r += mul(s1_8, M4(-2.226e-02, -6.764e-02, -9.734e-02, 1.881e-01, -5.818e-02, -6.798e-02, -1.955e-02, -1.483e-02, 1.677e-02, 4.705e-02, 1.095e-03, -2.380e-03, -1.667e-02, -3.719e-02, -1.644e-02, -8.760e-02));
	r += V4(-8.840e-04, -1.536e-03, 1.189e-04, -8.348e-04);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-DN-shuffle
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

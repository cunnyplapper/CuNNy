// CuNNy 4x4C CHROMA NVL DN
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
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(2.842e-01, 5.346e-01, 1.273e-01), O(INPUT, float2(x, y)).rgb) + -6.716e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-1.401e-01, -8.269e-02, -7.003e-03, -3.829e-02) * s0_0;
	r += V4(1.193e-02, 3.353e-01, -9.566e-02, -3.686e-02) * s0_1;
	r += V4(5.722e-02, -9.253e-02, -5.605e-01, -1.179e-01) * s0_2;
	r += V4(-6.470e-01, -6.104e-02, 1.935e-02, -2.968e-01) * s0_3;
	r += V4(6.640e-01, -3.908e-01, 8.025e-02, 8.727e-01) * s0_4;
	r += V4(5.410e-02, 2.925e-01, 5.620e-01, -9.628e-02) * s0_5;
	r += V4(9.523e-04, -3.037e-01, 6.558e-03, -1.636e-01) * s0_6;
	r += V4(2.105e-02, 1.846e-01, -2.008e-02, -6.524e-02) * s0_7;
	r += V4(-4.781e-02, 1.113e-01, 1.405e-02, -2.020e-02) * s0_8;
	r += V4(-2.251e-02, -6.765e-03, -7.162e-03, 1.984e-02);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-conv1
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
	r += mul(s0_0, M4(-4.243e-03, 1.705e-01, -9.505e-02, 8.135e-03, -6.061e-02, 7.723e-02, 7.690e-02, -8.989e-02, 5.995e-02, 4.649e-02, -3.689e-02, 5.333e-02, -2.037e-01, 4.833e-02, 1.034e-01, 1.308e-01));
	r += mul(s0_1, M4(4.597e-02, -4.543e-02, 8.787e-02, -1.463e-02, -1.366e-01, 8.180e-02, 4.947e-02, -8.926e-02, 2.684e-02, 9.002e-02, 2.560e-03, -1.932e-01, 2.123e-01, -3.100e-02, 5.266e-02, 1.279e-01));
	r += mul(s0_2, M4(-9.932e-02, -4.222e-01, -5.333e-02, 1.772e-01, -6.191e-01, 1.782e-01, -2.351e-02, -9.063e-02, 1.100e-02, -1.715e-02, -2.118e-02, 5.331e-02, -1.222e-01, 6.167e-02, 1.318e-01, -1.203e-01));
	r += mul(s0_3, M4(1.559e-01, 2.099e-04, 1.573e-02, 2.298e-01, 6.625e-02, -2.495e-01, 2.171e-01, -5.532e-01, 1.943e-02, -8.583e-01, 2.307e-02, 5.138e-01, -2.387e-01, -2.306e-01, -7.552e-02, -4.048e-01));
	r += mul(s0_4, M4(-2.358e-01, -5.197e-01, -3.289e-01, -3.301e-01, -2.883e-01, -7.348e-02, 3.819e-01, -7.900e-02, -5.521e-02, -6.249e-01, 4.051e-02, -5.080e-02, 2.900e-01, 1.983e-01, 1.694e-01, -5.088e-01));
	r += mul(s0_5, M4(1.004e+00, 1.168e-01, -1.285e-01, 1.680e-01, -4.069e-02, 1.984e-01, 1.376e-01, -3.872e-01, 5.605e-04, 9.578e-03, -2.955e-02, -3.577e-02, -2.565e-01, -1.177e-01, 3.427e-01, -1.331e-01));
	r += mul(s0_6, M4(-1.545e-03, 1.033e-01, -8.799e-02, 2.456e-01, 2.851e-02, 3.774e-03, -4.805e-02, -4.344e-02, -1.433e-02, -5.279e-01, -1.442e-01, 5.760e-01, -1.561e-02, 1.949e-01, 3.429e-02, 1.197e-01));
	r += mul(s0_7, M4(1.791e-01, 2.735e-01, -1.851e-01, 4.246e-01, -3.253e-02, 1.123e-01, 1.438e-02, 4.909e-02, 1.954e-01, -3.094e-01, -4.265e-01, 5.377e-01, -3.995e-02, -1.420e-01, -1.156e-02, 6.510e-02));
	r += mul(s0_8, M4(1.925e-02, -9.329e-04, 8.344e-02, 4.174e-03, 2.460e-02, 1.574e-01, -2.578e-03, 8.130e-02, 1.199e-01, 1.312e-01, 6.070e-02, -1.143e-01, -9.931e-02, 1.415e-01, -3.648e-02, -1.410e-01));
	r += mul(s1_0, M4(-3.048e-02, 2.106e-02, -1.226e-01, 9.986e-02, 1.574e-02, -2.778e-01, 1.444e-02, -8.610e-02, -4.873e-02, -1.883e-01, -3.008e-02, 2.589e-02, -5.589e-02, 1.443e-01, 1.121e-01, -4.877e-02));
	r += mul(s1_1, M4(7.123e-02, -4.838e-02, 1.965e-01, -1.971e-01, -2.901e-02, 2.996e-01, 2.543e-02, -4.491e-02, -3.488e-01, 1.362e-01, 3.689e-02, -1.820e-01, 2.978e-01, 3.564e-01, -1.802e-01, 2.139e-01));
	r += mul(s1_2, M4(4.674e-02, -8.863e-02, 1.475e-01, -1.543e-02, 4.591e-02, -1.821e-01, -4.213e-02, -1.104e-01, 1.194e-01, -1.570e-01, 2.776e-02, 4.876e-02, 5.900e-02, 3.973e-01, -4.262e-02, -4.342e-02));
	r += mul(s1_3, M4(9.239e-02, 9.645e-02, 3.894e-02, 2.346e-01, 6.503e-02, -1.246e-01, 3.239e-01, -8.421e-01, -4.668e-01, -1.002e-01, 1.521e-01, -1.763e-01, -7.613e-02, -2.392e-01, -3.273e-02, -3.976e-01));
	r += mul(s1_4, M4(-2.838e-01, -1.689e-01, 1.608e-01, -9.133e-01, -3.215e-01, -3.861e-01, 5.035e-01, 1.447e-02, -1.449e+00, 3.209e-02, -7.576e-03, -2.060e-01, 2.047e-01, -3.274e-01, -6.074e-01, 1.263e+00));
	r += mul(s1_5, M4(1.373e-01, 2.930e-01, 9.852e-01, -3.994e-01, -6.489e-02, -5.979e-02, 2.612e-01, -2.417e-01, 5.634e-02, 1.220e-04, 5.032e-02, -3.235e-02, -1.540e-01, 2.627e-01, 6.260e-01, -3.969e-01));
	r += mul(s1_6, M4(-2.167e-02, 1.321e-01, -1.775e-01, 4.893e-01, -1.385e-02, -1.346e-01, -5.602e-02, -9.114e-02, -1.342e-01, -2.198e-02, 1.450e-01, -3.328e-01, 6.108e-02, -1.592e-02, 9.300e-02, -7.846e-03));
	r += mul(s1_7, M4(9.591e-02, 4.103e-01, -1.841e-01, 3.279e-01, 2.249e-02, 9.896e-04, -8.534e-02, -1.524e-01, 2.017e-03, -2.568e-01, -2.330e-02, -4.116e-02, -4.461e-02, -3.307e-01, 1.959e-02, 3.912e-02));
	r += mul(s1_8, M4(1.057e-01, -6.141e-02, 3.643e-02, 1.964e-01, 1.767e-01, 9.423e-02, -5.849e-02, 1.606e-01, 1.046e-01, 5.777e-02, 2.503e-02, -2.714e-03, -7.190e-03, -5.101e-02, -1.958e-01, 1.076e-01));
	r += V4(-2.092e-02, 2.802e-02, 4.120e-03, -2.105e-02);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-conv2
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
	r += mul(s0_0, M4(3.428e-02, -1.119e-01, 4.379e-02, 3.116e-04, -3.958e-02, -8.731e-02, -3.619e-02, 5.749e-02, 4.290e-01, 6.392e-01, -6.051e-01, 4.338e-01, -9.220e-02, -6.322e-02, 4.615e-02, -1.841e-01));
	r += mul(s0_1, M4(-1.153e-02, 1.301e-01, -1.554e-02, -8.035e-02, -1.782e-01, -5.449e-01, 1.814e-01, -2.297e-01, 7.287e-01, 1.145e+00, -7.972e-01, 8.079e-01, 7.203e-02, 1.745e-01, -5.508e-01, 3.100e-01));
	r += mul(s0_2, M4(-5.848e-02, -6.338e-02, -3.430e-02, 4.084e-02, 8.699e-02, -9.414e-02, 2.242e-01, 7.248e-02, 1.514e-01, -5.281e-01, -9.724e-02, -3.189e-01, 4.716e-02, -1.450e-01, -1.056e-01, 7.860e-02));
	r += mul(s0_3, M4(9.424e-02, 3.499e-01, -1.033e-01, -4.073e-02, -9.287e-02, -1.336e-01, 1.983e-02, 1.052e-01, 1.552e-01, 3.090e-01, -5.170e-01, -8.824e-02, -1.564e-01, 5.260e-02, -4.593e-01, 9.943e-02));
	r += mul(s0_4, M4(-9.277e-02, 2.136e-01, 9.736e-02, -5.345e-02, -2.921e-01, -1.819e-01, 7.539e-01, -1.840e-01, 5.888e-01, 1.090e+00, 8.945e-03, 2.241e-01, -4.459e-01, 4.303e-01, -1.856e-02, 4.156e-01));
	r += mul(s0_5, M4(-3.253e-02, 8.268e-02, -3.229e-02, -8.332e-03, 1.470e-01, -2.943e-02, 2.389e-01, -7.473e-02, 8.351e-01, 2.037e-01, 3.924e-01, -9.573e-01, 2.156e-01, 2.375e-02, 3.991e-02, -3.350e-01));
	r += mul(s0_6, M4(5.966e-02, 1.584e-02, -3.970e-02, -2.551e-01, 8.257e-03, -2.978e-01, 5.446e-02, 1.514e-01, 4.911e-02, 2.269e-01, 9.674e-02, 1.160e-01, 5.786e-03, -1.343e-01, 4.225e-02, 5.029e-02));
	r += mul(s0_7, M4(-5.618e-02, -1.596e-01, -2.586e-01, 1.126e-01, 2.998e-02, 1.414e-01, -2.960e-02, -1.133e-01, 1.755e-01, -9.806e-02, 2.597e-01, 2.040e-01, -4.973e-02, -4.420e-03, 1.086e-01, 8.477e-02));
	r += mul(s0_8, M4(-4.375e-02, 9.732e-02, -1.520e-02, 1.297e-01, -1.528e-02, -1.028e-01, 1.810e-01, -5.159e-02, 4.240e-01, 5.395e-02, 9.157e-02, -2.716e-01, -2.685e-02, -9.037e-02, 1.871e-01, 7.838e-02));
	r += mul(s1_0, M4(-5.775e-02, 2.684e-01, -3.637e-02, -9.415e-02, -4.114e-02, 7.741e-02, 3.009e-03, 2.268e-02, -7.165e-02, -7.580e-02, 6.969e-02, -1.533e-01, 5.852e-02, 3.115e-01, -2.298e-01, 1.558e-01));
	r += mul(s1_1, M4(-5.794e-02, 2.213e-01, -4.966e-03, 2.844e-01, 8.077e-02, 1.405e-01, -8.218e-02, -1.323e-02, -4.940e-02, 1.043e-01, -4.111e-01, 3.949e-01, 4.991e-01, 6.073e-01, -5.482e-01, 5.840e-01));
	r += mul(s1_2, M4(9.040e-02, 3.726e-02, -2.406e-02, 1.450e-01, 2.828e-02, -7.842e-02, -1.005e-02, 3.632e-02, 5.833e-02, -1.075e-01, -4.237e-02, -1.202e-02, 1.306e-01, -4.131e-01, -2.390e-03, -3.669e-01));
	r += mul(s1_3, M4(-1.283e-01, 8.585e-01, -2.202e-01, -2.183e-01, -6.944e-02, 1.706e-01, -4.582e-02, -2.719e-02, -8.083e-02, 1.620e-01, -4.505e-01, 1.357e-02, -4.130e-02, 2.649e-01, -1.045e-01, -7.357e-03));
	r += mul(s1_4, M4(-7.213e-02, -2.403e-02, 1.233e-01, 2.780e-01, -6.792e-02, 1.019e-01, 3.002e-01, 6.136e-03, -7.366e-01, 1.592e-01, 8.247e-02, 6.209e-01, 1.474e-01, 3.395e-01, -1.754e-01, 9.627e-02));
	r += mul(s1_5, M4(3.679e-03, 8.457e-02, 1.627e-01, -8.176e-02, 1.466e-01, 1.694e-01, -5.540e-03, -3.447e-02, 1.236e-01, -3.734e-03, 9.118e-02, -4.014e-01, 7.755e-01, 5.934e-02, 3.760e-01, -9.941e-01));
	r += mul(s1_6, M4(1.209e-01, -1.514e-01, 7.524e-02, 3.217e-01, -1.062e-02, 2.482e-02, 4.958e-02, 6.463e-02, 2.020e-02, -1.159e-01, 3.279e-02, 1.012e-02, -2.090e-02, -3.148e-02, 1.556e-01, 1.220e-01));
	r += mul(s1_7, M4(4.075e-01, 2.705e-01, 2.555e-01, -1.083e-01, -3.396e-02, 1.397e-01, -2.358e-01, -4.675e-02, -9.566e-02, -1.344e-01, 1.638e-01, 1.766e-01, 9.571e-02, -1.417e-03, 1.704e-01, -8.449e-02));
	r += mul(s1_8, M4(-9.540e-02, 9.714e-02, -1.396e-01, 4.717e-01, 1.095e-02, -6.393e-02, 5.647e-02, 9.761e-02, 1.490e-03, 6.923e-02, -2.920e-03, 1.072e-01, 1.889e-01, -1.281e-01, 9.391e-02, -2.744e-01));
	r += V4(-1.902e-02, 1.058e-02, -1.928e-02, -2.365e-02);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-conv3
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
	r += mul(s0_0, M4(-1.844e-02, 9.329e-03, 1.448e-01, 8.525e-02, 8.045e-02, 3.048e-02, -5.322e-02, -1.612e-02, -1.202e-03, 3.954e-02, -6.421e-02, 6.652e-02, 4.840e-02, 1.068e-01, -5.040e-02, -9.487e-02));
	r += mul(s0_1, M4(2.216e-01, 1.019e-01, -2.849e-01, -4.578e-02, -8.033e-02, 1.012e-01, 6.415e-02, 7.984e-02, 3.479e-02, 4.041e-02, -9.742e-02, 7.488e-02, 2.084e-01, -7.008e-02, 3.958e-03, -1.850e-01));
	r += mul(s0_2, M4(-1.645e-02, 8.146e-02, 9.126e-02, 7.037e-04, 2.821e-02, -9.400e-02, 5.505e-03, -2.599e-02, 3.126e-02, 1.207e-01, 4.967e-02, -9.956e-02, 5.817e-02, 1.685e-01, 9.783e-02, -1.282e-01));
	r += mul(s0_3, M4(5.527e-01, -1.156e-01, -3.058e-01, -7.337e-02, -6.592e-02, -3.527e-02, -6.845e-02, 9.721e-02, 9.010e-02, 5.471e-02, 1.166e-03, -6.884e-02, -1.841e-01, 2.160e-02, 1.521e-02, 2.062e-02));
	r += mul(s0_4, M4(-2.698e-01, -4.130e-01, 3.613e-03, 2.392e-01, 7.134e-02, -3.873e-02, 4.453e-02, 2.941e-02, 1.750e-02, -4.334e-02, 5.445e-02, 6.072e-02, 6.642e-01, -3.591e-02, -1.165e+00, 6.511e-01));
	r += mul(s0_5, M4(-4.493e-02, 6.140e-02, -4.727e-02, 2.231e-01, -1.897e-02, -6.391e-02, -6.737e-02, 2.066e-02, 2.646e-02, 3.735e-02, 3.082e-02, -7.712e-02, -4.243e-03, -7.049e-02, -1.053e-01, -6.346e-02));
	r += mul(s0_6, M4(-3.063e-02, -7.273e-03, -1.932e-02, 4.141e-02, -1.403e-01, -7.254e-02, 3.178e-02, 1.634e-01, -2.195e-02, -6.141e-02, 4.261e-03, -6.362e-02, -7.195e-02, -8.948e-02, 5.298e-03, -2.895e-02));
	r += mul(s0_7, M4(2.811e-01, 3.369e-01, -2.613e-01, 1.411e-01, -7.130e-02, 2.466e-01, -1.630e-01, -7.562e-02, -3.041e-02, -4.483e-02, 8.774e-02, -1.792e-01, 3.566e-01, 4.934e-01, -2.054e-01, -2.686e-01));
	r += mul(s0_8, M4(9.193e-02, -1.432e-02, -7.912e-02, 1.548e-01, -4.634e-02, 5.827e-02, 6.204e-02, -1.260e-01, -3.253e-02, 2.586e-02, 1.548e-04, 3.717e-02, -3.206e-02, -8.356e-02, -7.676e-02, 1.971e-01));
	r += mul(s1_0, M4(-2.361e-01, 1.634e-01, 7.819e-02, 1.347e-01, -1.559e-02, -1.278e-01, -3.032e-02, 7.105e-02, -1.786e-02, -3.298e-03, 6.959e-03, 1.234e-02, 1.120e-01, 1.575e-02, -7.983e-02, 6.353e-02));
	r += mul(s1_1, M4(8.054e-02, 6.200e-02, -1.577e-01, -1.222e-01, -3.476e-02, -8.444e-02, 1.778e-02, 6.417e-02, -2.400e-02, 6.477e-02, -3.718e-02, 5.994e-02, -2.080e-02, 2.732e-02, 6.275e-02, 2.995e-02));
	r += mul(s1_2, M4(-3.309e-02, 1.645e-01, -6.237e-02, 1.294e-01, 2.304e-02, -8.801e-02, -1.791e-03, -8.912e-02, 7.106e-03, 1.294e-01, 2.395e-02, -4.059e-02, -6.325e-02, 1.045e-01, 1.532e-01, 2.436e-02));
	r += mul(s1_3, M4(8.312e-02, -1.282e-01, -4.693e-02, -2.664e-01, 2.195e-01, 1.371e-01, -1.118e-01, 6.991e-02, 3.268e-02, 1.235e-01, -7.558e-02, 2.222e-01, -3.364e-02, -7.762e-02, -5.898e-02, 2.711e-01));
	r += mul(s1_4, M4(-3.389e-01, -5.090e-01, 3.000e-01, 3.033e-01, 5.293e-01, 3.370e-01, 7.472e-02, -5.507e-01, -5.688e-01, 4.678e-01, 9.700e-01, 1.913e-01, -1.106e-01, -1.372e-01, -2.442e-01, 6.629e-01));
	r += mul(s1_5, M4(-1.551e-01, -1.658e-01, 1.761e-01, 2.085e-01, 1.194e-01, 1.430e-01, 6.103e-02, -1.591e-01, -9.899e-02, -1.655e-01, 2.736e-02, 7.194e-02, -2.747e-03, 1.315e-02, -1.098e-01, 1.906e-01));
	r += mul(s1_6, M4(1.517e-02, 5.540e-02, -4.284e-02, 2.069e-01, -6.327e-02, -2.438e-02, 5.389e-02, -6.713e-02, 1.645e-03, -3.691e-01, -1.803e-01, 4.575e-02, -4.372e-02, -6.254e-02, 3.952e-03, -9.347e-03));
	r += mul(s1_7, M4(1.190e-01, 1.298e-01, -3.748e-01, 4.086e-01, 5.934e-02, 3.520e-01, 3.115e-01, -5.137e-01, -2.017e-01, -7.014e-01, -6.240e-02, -7.249e-02, 5.241e-02, 7.069e-02, -1.243e-02, -2.037e-02));
	r += mul(s1_8, M4(6.930e-02, -4.428e-02, -1.412e-01, 1.097e-01, 2.819e-02, 2.163e-01, 1.774e-01, -2.167e-01, 1.331e-01, -1.935e-01, -3.136e-01, 1.345e-02, 3.525e-02, -2.677e-02, -5.422e-02, 1.095e-01));
	r += V4(-6.311e-03, -8.537e-03, -3.357e-02, 7.690e-02);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-conv4
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
	r += mul(s0_0, M4(8.824e-02, 9.455e-03, 2.961e-02, -7.623e-03, 3.981e-02, 1.772e-02, 1.033e-01, 2.932e-02, 2.907e+00, -2.405e-01, -3.982e-01, -2.442e-02, 4.264e-02, -1.011e-03, -1.967e-02, -4.346e-03));
	r += mul(s0_1, M4(-1.038e-01, 1.139e-01, -3.174e-01, 3.035e-02, -8.541e-02, -9.847e-02, 2.617e-01, 7.251e-02, 4.325e-03, 8.315e-01, -3.150e-02, -7.605e-02, -1.035e-03, 1.841e-03, -1.054e-01, 7.889e-02));
	r += mul(s0_2, M4(1.107e-03, 2.348e-02, -2.465e-01, -2.196e-02, 6.057e-02, -8.763e-02, 1.661e-02, 1.947e-01, -6.801e-02, -1.733e-01, -1.111e-01, -3.963e-01, -6.279e-02, 1.874e-02, -1.170e-01, 2.176e-02));
	r += mul(s0_3, M4(4.403e-02, 1.361e-02, -5.870e-02, -1.299e-02, 1.333e-01, -7.581e-02, 1.941e-02, 1.002e-02, 9.151e-02, -1.734e+00, -3.193e-01, -4.016e-02, 5.549e-02, 4.388e-03, -3.238e-02, -1.622e-02));
	r += mul(s0_4, M4(-2.706e-01, 1.074e+00, 6.074e-01, -1.420e-01, -2.112e-01, -8.039e-01, -4.034e-01, 3.018e-01, 3.343e-02, 3.476e-02, 3.387e-01, 9.005e-01, -4.346e-02, 1.229e-02, 2.863e-01, 1.996e-02));
	r += mul(s0_5, M4(6.752e-02, -3.175e-01, 2.768e-01, -1.009e+00, 1.395e-01, 6.001e-02, 1.981e-02, 4.346e-01, 1.948e-01, -6.865e-02, 1.649e-02, 1.781e-01, -3.278e-02, -3.829e-02, 1.542e-01, -2.947e-01));
	r += mul(s0_6, M4(-9.674e-02, 6.132e-02, 1.144e-01, 3.310e-02, 7.203e-02, 1.239e-02, -1.755e-02, -1.191e-02, -5.410e-02, 3.098e-02, 1.236e-01, 1.136e-01, -7.325e-04, -9.761e-03, 7.675e-02, 2.213e-02));
	r += mul(s0_7, M4(8.346e-02, 3.652e-02, -8.814e-02, 1.201e-01, -5.236e-02, -2.531e-02, -6.809e-02, -8.097e-02, 9.182e-02, -5.452e-02, -3.618e-03, 3.536e-02, -2.165e-02, 3.005e-03, -7.110e-02, 4.195e-02));
	r += mul(s0_8, M4(-1.383e-01, -3.440e-02, -2.286e-02, 1.635e-01, 3.071e-02, 4.608e-02, 4.944e-02, -7.105e-02, -2.610e-02, -7.416e-02, 1.766e-02, -7.103e-02, 2.878e-02, -3.241e-02, -2.838e-02, 1.021e-01));
	r += mul(s1_0, M4(-4.537e-04, 1.018e-02, 4.497e-02, 7.974e-03, 5.284e-02, -6.250e-03, 3.043e-02, 5.247e-03, 7.003e-02, -1.732e-02, -1.333e-02, -2.045e-02, 3.599e-02, 6.646e-02, 6.989e-02, -2.336e-05));
	r += mul(s1_1, M4(-9.631e-02, 2.626e-02, -1.059e-01, 1.227e-01, -1.153e-01, 1.760e-02, -5.075e-02, 1.259e-02, -5.321e-02, 6.036e-02, -5.531e-02, 7.162e-02, -4.501e-02, 2.010e-02, -3.271e-01, -8.529e-03));
	r += mul(s1_2, M4(-5.692e-03, -1.560e-02, -1.044e-01, 9.131e-02, 5.331e-02, -1.465e-02, 4.692e-02, 2.930e-02, -1.875e-02, 1.971e-02, -9.146e-02, -7.067e-03, -7.933e-02, 9.469e-02, -1.194e-01, -2.188e-02));
	r += mul(s1_3, M4(1.026e-01, -3.829e-02, -1.322e-01, -1.890e-02, 1.216e-01, -1.032e-01, -4.525e-02, -4.437e-03, 1.112e-01, 1.090e-02, -8.511e-02, -2.101e-02, -2.549e-01, -2.754e-01, 1.646e-01, 5.590e-02));
	r += mul(s1_4, M4(-3.939e-01, 5.865e-02, 4.137e-01, -8.233e-02, -2.699e-01, 2.202e-01, 1.321e-01, 1.248e-01, -1.620e-01, 5.165e-02, 6.601e-01, 3.274e-02, 3.428e-01, 1.109e+00, 6.285e-01, 6.632e-01));
	r += mul(s1_5, M4(-2.329e-01, -1.353e-01, -3.027e-03, -3.298e-01, 1.323e-01, 6.816e-02, -3.067e-02, 2.706e-01, 3.235e-02, -8.871e-02, 8.060e-02, -2.134e-01, -1.130e-01, -4.813e-02, 2.964e-01, -5.810e-01));
	r += mul(s1_6, M4(-9.210e-02, 3.483e-02, 8.058e-02, 1.659e-03, 5.773e-02, 1.820e-02, 3.570e-03, -6.483e-04, -3.209e-02, -2.054e-02, 1.164e-01, 4.088e-02, -1.032e-01, -6.729e-02, 6.137e-02, -1.796e-02));
	r += mul(s1_7, M4(7.502e-02, -4.666e-02, -8.961e-02, 1.441e-01, -1.190e-01, -5.802e-02, -8.181e-02, -1.083e-01, -1.734e-02, -1.479e-02, -9.460e-02, 1.900e-01, 3.195e-02, -7.426e-02, -9.620e-02, 3.178e-02));
	r += mul(s1_8, M4(-1.882e-01, -1.714e-01, 4.495e-02, -2.891e-01, 5.669e-02, 6.633e-02, -5.308e-04, 1.921e-01, 7.383e-03, -6.865e-02, 4.993e-02, 7.650e-02, -7.251e-02, -2.826e-02, 8.620e-03, 6.079e-02));
	r += V4(5.018e-03, 5.929e-03, 1.631e-03, 3.336e-03);
	return r;
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
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-out
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
	r += mul(s0_0, M4(-1.407e-02, -1.117e-02, 3.877e-03, -5.356e-03, -7.451e-02, -1.575e-03, -8.484e-02, -9.119e-03, 2.280e-01, -2.039e-02, -5.525e-02, 9.847e-03, -2.234e-01, -4.039e-01, 1.365e-01, -5.563e-03));
	r += mul(s0_1, M4(6.648e-02, -1.558e-02, 2.402e-03, -1.497e-02, 1.580e-02, -5.548e-02, -6.958e-02, -1.333e-01, -2.911e-02, 1.660e-01, -2.230e-02, -9.588e-02, -1.246e-02, -4.462e-02, 5.194e-02, 1.305e-01));
	r += mul(s0_2, M4(2.850e-02, 7.852e-02, -5.170e-03, 1.009e-02, 9.217e-03, 2.602e-02, -1.735e-02, -3.484e-02, -4.548e-02, -3.838e-02, -3.477e-02, -3.310e-02, -4.490e-02, -5.350e-02, 2.331e-02, 5.052e-02));
	r += mul(s0_3, M4(-2.661e-02, -3.493e-03, -1.231e-01, -6.990e-03, 1.704e-01, 1.557e-03, 1.037e-01, 4.039e-02, -5.771e-01, 4.596e-01, -5.173e-01, -2.141e-01, -3.357e-01, -1.626e-01, 9.601e-01, 7.324e-01));
	r += mul(s0_4, M4(-1.856e-01, -2.025e-02, 1.121e-01, -9.052e-03, -1.938e-01, 4.014e-01, 2.202e-01, 3.779e-01, -2.309e-01, -1.208e+00, 6.683e-01, 5.044e-02, -6.368e-02, -2.939e-01, -1.802e-01, -5.326e-02));
	r += mul(s0_5, M4(3.356e-02, -1.294e-01, -7.125e-03, -5.404e-03, -8.178e-02, -1.474e-01, -4.566e-02, 2.905e-02, 8.955e-02, 3.096e-01, -9.043e-02, 1.773e-01, 4.463e-02, 8.938e-02, -2.777e-03, 1.468e-02));
	r += mul(s0_6, M4(2.310e-02, 3.919e-02, 8.997e-02, 3.844e-02, -2.470e-02, -1.864e-02, 3.900e-02, -4.125e-02, 5.366e-02, -5.935e-02, 2.607e-01, 2.337e-02, 6.607e-02, 7.017e-02, -9.546e-02, -1.004e-01));
	r += mul(s0_7, M4(1.165e-01, -1.083e-02, -6.589e-02, -3.858e-02, -4.883e-02, -7.399e-02, -2.588e-01, 1.174e-02, 4.658e-01, 3.420e-01, -7.434e-01, 4.124e-02, 8.627e-03, 8.194e-03, 1.791e-02, -2.089e-02));
	r += mul(s0_8, M4(-2.188e-02, 3.443e-02, -3.706e-03, -2.631e-02, 3.551e-02, 3.798e-02, 1.168e-02, -4.106e-02, 1.380e-01, 3.973e-01, 1.456e-02, -3.926e-01, -1.284e-02, 5.710e-04, 1.427e-02, 3.501e-02));
	r += mul(s1_0, M4(3.725e-02, -1.317e-01, 1.802e-01, 1.457e-03, -7.689e-02, -2.122e-02, -1.233e-01, 1.479e-02, -3.249e-02, -7.358e-03, -5.631e-03, 1.228e-02, 4.593e-02, -2.048e-03, -6.552e-02, -1.209e-01));
	r += mul(s1_1, M4(-2.961e-01, 4.336e-01, 2.270e-02, -1.459e-01, 7.873e-03, -5.072e-02, -6.003e-02, -1.881e-01, 3.820e-02, 2.750e-03, 5.505e-02, 3.568e-02, -4.229e-03, 7.222e-02, 7.761e-03, 5.822e-02));
	r += mul(s1_2, M4(8.494e-02, 1.120e-01, -3.975e-02, 8.104e-02, 2.701e-02, 4.479e-02, -1.713e-02, -2.040e-02, -2.294e-02, -6.273e-03, -2.150e-02, -1.104e-02, -1.798e-02, -6.665e-02, 6.187e-03, -2.056e-02));
	r += mul(s1_3, M4(-3.667e-01, -1.703e-02, -3.822e-01, -1.339e-01, 6.665e-02, 7.581e-02, 2.785e-01, 1.467e-02, -2.766e-01, -4.550e-02, -2.564e-01, -2.989e-02, 3.057e-01, 2.112e-01, 3.733e-01, 2.666e-01));
	r += mul(s1_4, M4(-5.962e-01, 8.027e-01, -9.006e-01, 1.401e+00, -1.025e-01, -1.487e-01, 3.740e-01, 5.628e-01, -3.406e-02, -3.785e-01, 1.101e-01, -2.132e-01, -1.152e-01, -2.201e-01, -2.077e-01, -1.625e-01));
	r += mul(s1_5, M4(5.090e-02, -3.055e-01, 1.675e-01, -3.193e-01, -9.253e-02, -1.475e-01, -3.172e-02, -3.576e-03, 3.472e-02, 1.821e-01, -2.012e-02, 1.052e-01, 5.800e-02, 9.648e-02, 5.526e-03, -1.401e-02));
	r += mul(s1_6, M4(6.717e-02, -1.385e-02, -1.239e-02, 4.819e-03, -7.713e-03, -6.996e-03, 5.476e-04, 1.465e-02, 5.520e-02, 7.221e-02, -2.371e-02, 4.829e-02, -6.956e-02, -3.764e-02, 3.151e-02, 2.305e-02));
	r += mul(s1_7, M4(1.216e-01, -2.424e-02, 1.392e-01, -5.529e-02, -2.473e-02, 1.501e-03, -7.946e-02, -9.935e-02, 6.842e-02, 6.296e-02, -3.147e-02, -1.557e-01, 2.866e-02, -2.385e-02, 1.513e-02, -9.599e-02));
	r += mul(s1_8, M4(-8.757e-03, 1.872e-02, -6.116e-02, -6.050e-02, 3.304e-02, 1.152e-02, 2.120e-02, -1.420e-02, -3.119e-02, 5.431e-03, 7.012e-03, 9.296e-02, -2.193e-02, -2.604e-02, -1.343e-03, 2.722e-02));
	r += V4(-2.562e-04, -1.949e-03, -7.342e-04, -2.103e-03);
	return tanh(r);
}
void Pass7(uint2 blockStart, uint3 tid) {
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
//!PASS 8
//!DESC CuNNy-4x4C-CHROMA-NVL-DN-shuffle
//!STYLE PS
//!IN t1, INPUT, easu
float4 Pass8(float2 pos) {
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

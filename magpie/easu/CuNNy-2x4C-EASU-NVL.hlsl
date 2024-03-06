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
#define l0(x, y) (dot(float3(2.882e-01, 5.327e-01, 1.362e-01), O(INPUT, float2(x, y)).rgb) + -8.246e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-3.064e-02, 6.753e-02, 1.129e-02, 7.676e-01) * s0_0;
	r += V4(7.288e-01, -1.766e-01, -9.448e-02, -2.585e-02) * s0_1;
	r += V4(-4.168e-02, -1.503e-01, 9.042e-02, -2.423e-02) * s0_2;
	r += V4(-2.866e-03, 4.284e-02, 1.295e-02, -7.689e-01) * s0_3;
	r += V4(-2.437e-02, -7.808e-02, 6.465e-01, 2.129e-02) * s0_4;
	r += V4(9.960e-03, 4.625e-01, -6.621e-01, 3.657e-02) * s0_5;
	r += V4(-3.613e-03, -1.135e-01, -2.440e-02, 4.904e-03) * s0_6;
	r += V4(-2.633e-03, 1.741e-02, -7.026e-02, 3.213e-03) * s0_7;
	r += V4(-7.119e-03, -1.718e-02, 9.080e-02, -1.505e-02) * s0_8;
	r += V4(-7.885e-02, 3.505e-02, -3.200e-04, 1.962e-05);
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
	r += mul(s0_0, M4(-3.943e-01, -1.774e+00, -5.328e-01, 2.431e-01, 1.729e-01, 6.825e-01, -7.251e-02, 3.667e-01, -1.632e-01, 7.204e-02, -5.777e-01, 1.880e-01, -3.538e-02, -5.817e-02, -2.245e-02, 3.597e-02));
	r += mul(s0_1, M4(-5.382e-01, -1.615e+00, -8.755e-01, -8.281e-02, 5.103e-02, -9.230e-02, 5.820e-02, -6.956e-02, -1.859e-01, -4.589e-01, -8.032e-02, 1.919e-01, 1.385e-01, 4.092e-01, -1.131e-01, 3.634e-03));
	r += mul(s0_2, M4(-4.364e-01, -3.979e-01, -3.870e-01, 5.706e-01, -1.387e-02, 1.554e-02, -3.787e-02, 3.421e-02, -7.318e-02, 1.579e-03, -2.316e-02, 4.974e-02, -8.037e-02, -1.538e-01, 3.808e-02, 1.512e-01));
	r += mul(s0_3, M4(1.883e+00, -9.513e-02, -5.798e-01, 7.959e-01, -5.399e-01, -4.515e-01, 2.378e-01, -6.901e-01, 1.795e-01, 8.505e-01, -7.323e-01, 4.207e-01, 4.612e-02, -9.176e-02, 4.930e-02, 1.168e-01));
	r += mul(s0_4, M4(3.864e+00, 4.078e-01, 1.294e-01, 4.706e-01, 3.639e-01, 8.405e-02, -3.749e-01, 8.096e-02, 6.895e-01, 4.070e-02, 5.801e-01, 5.235e-02, -4.170e-01, 2.010e-01, -3.467e-01, -5.658e-01));
	r += mul(s0_5, M4(1.285e-01, -1.180e+00, -5.762e-01, 2.281e-01, 2.030e-01, -6.792e-02, 4.423e-01, -1.585e-02, 4.429e-02, -4.405e-02, 2.283e-01, 1.698e-01, -4.539e-01, 1.565e-01, -5.052e-01, 4.031e-01));
	r += mul(s0_6, M4(5.717e+00, 1.073e+00, -8.981e-01, 3.450e+00, 1.097e-01, -4.255e-02, 9.547e-02, -2.364e-01, 1.691e-01, 2.614e-01, 8.568e-02, 8.052e-02, -4.836e-03, 3.643e-02, 4.630e-02, -3.625e-02));
	r += mul(s0_7, M4(9.677e+00, -9.353e-01, 6.866e+00, -3.436e+00, 5.994e-02, -2.131e-01, -1.641e-01, -3.999e-02, -1.257e-01, -2.933e-02, 1.530e-01, 2.144e-01, -6.982e-02, -8.752e-02, 5.271e-02, -9.766e-02));
	r += mul(s0_8, M4(2.486e+00, 6.755e-01, 3.494e-01, 1.691e+00, -4.477e-01, 2.090e-01, -1.628e-01, 1.276e-01, -2.822e-01, 8.887e-02, -1.092e-01, 2.301e-01, 4.070e-01, 1.864e-01, 9.650e-01, 1.526e-01));
	r += mul(s1_0, M4(-1.502e-01, -2.799e-01, -1.511e-02, 7.202e-02, -7.995e-02, 1.883e-02, -4.656e-01, 4.161e-01, 1.371e-01, 3.055e-01, 1.597e-01, 3.526e-01, -1.923e-02, -2.337e-02, 2.933e-03, -3.157e-02));
	r += mul(s1_1, M4(5.384e-02, -1.078e-01, -4.441e-02, -6.254e-02, 4.601e-03, -3.428e-01, -2.814e-02, 2.111e-01, 1.116e-01, 2.239e-01, 1.142e-01, -1.968e-01, 2.368e-01, 5.137e-01, 6.709e-02, 4.620e-02));
	r += mul(s1_2, M4(8.351e-04, 3.027e-02, -1.397e-02, 1.681e-02, 1.612e-02, 8.190e-02, -1.392e-02, -7.624e-02, -8.909e-02, -2.122e-03, -9.251e-02, -2.682e-02, 7.445e-02, 6.238e-02, 2.015e-01, 7.641e-02));
	r += mul(s1_3, M4(6.864e-02, 1.014e-01, -2.551e-02, -2.329e-02, 8.955e-03, -6.343e-02, 3.623e-01, -1.284e-01, -3.603e-01, -1.813e-01, 5.599e-02, 8.615e-01, 1.861e-02, -3.139e-02, -4.523e-02, 4.237e-02));
	r += mul(s1_4, M4(-6.682e-02, 1.269e-01, -1.068e-01, -1.054e-03, 2.496e-01, 8.456e-02, -3.689e-03, 2.330e-01, 4.684e-01, 1.874e-01, 2.900e-01, -9.788e-01, -1.221e-01, 2.470e-01, 1.622e-01, -2.816e-01));
	r += mul(s1_5, M4(-5.596e-02, 2.354e-03, 5.379e-02, 2.781e-02, 9.467e-02, -1.430e-01, 4.242e-01, 7.320e-02, 1.181e-01, -8.520e-02, 3.275e-01, -9.737e-03, 2.702e-02, 5.338e-01, 1.308e-01, -2.162e-01));
	r += mul(s1_6, M4(9.692e-02, 2.027e-01, -2.076e-03, -1.144e-01, 3.525e-01, 1.401e-01, 3.451e-01, -2.107e-01, -4.659e-01, -6.230e-01, -9.698e-02, 1.296e-01, 4.006e-02, 6.494e-02, -5.315e-02, 1.915e-02));
	r += mul(s1_7, M4(1.439e-01, -1.860e-01, 1.093e-01, -9.875e-02, -2.595e-02, -1.985e-01, -2.480e-01, -1.393e-01, -4.513e-02, -1.462e-02, -5.392e-01, -7.091e-02, -1.633e-01, -4.616e-01, -2.749e-02, 2.342e-01));
	r += mul(s1_8, M4(-9.195e-02, 9.772e-02, 4.386e-02, 2.076e-01, -3.054e-01, 1.404e-01, -2.487e-01, 2.477e-01, -1.753e-01, 2.036e-01, -1.115e-01, 7.455e-02, -4.680e-01, -8.747e-01, -9.295e-02, -2.036e-01));
	r += V4(2.413e-04, -7.474e-03, 2.058e-03, 1.662e-02);
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
	r += mul(s0_0, M4(-1.177e-01, 2.157e-01, 1.184e-01, 6.862e-02, -3.425e-02, -3.031e-02, 3.550e-03, -5.627e-02, 6.532e-02, -1.907e-01, 1.474e-01, -1.223e-01, 1.596e-01, -3.036e-03, -1.645e-01, 7.608e-02));
	r += mul(s0_1, M4(-1.088e-02, -1.285e-01, 2.032e-03, 1.000e-01, 1.002e-01, -6.289e-02, -2.103e-01, -7.580e-02, 1.224e-01, 7.791e-02, 1.712e-01, -4.800e-02, 1.265e-01, -4.432e-02, -1.440e-01, 6.019e-02));
	r += mul(s0_2, M4(1.034e-02, -1.163e-01, 1.204e-01, 2.092e-03, 2.084e-02, -1.576e-02, -2.606e-02, -1.987e-02, -3.032e-02, 1.062e-01, 8.763e-02, -4.326e-02, -2.020e-02, -1.857e-02, 2.068e-02, 1.126e-02));
	r += mul(s0_3, M4(1.362e-01, -9.068e-02, -9.816e-02, 1.345e-01, 1.441e-02, 1.480e-01, -1.837e-02, 5.781e-02, 2.125e-02, -4.207e-02, 1.360e-01, -1.072e-01, -2.363e-01, 4.208e-01, -1.755e-02, -8.334e-02));
	r += mul(s0_4, M4(-9.256e-02, 1.676e-01, -6.005e-01, 2.258e-02, 8.081e-02, -1.056e-02, 4.240e-01, 1.228e-01, 5.963e-02, 1.331e+00, -1.236e-01, 3.138e-03, 7.117e-02, -1.764e-01, 2.075e-01, -1.070e-02));
	r += mul(s0_5, M4(1.649e-02, 1.440e-01, -2.793e-01, 1.443e-01, -3.787e-02, -5.472e-02, 2.202e-01, 2.779e-02, -1.064e-02, -7.958e-02, 2.882e-02, -5.285e-02, -4.752e-03, 3.095e-02, 3.996e-02, 5.824e-02));
	r += mul(s0_6, M4(-1.210e-02, -4.642e-02, 7.467e-03, -3.576e-02, 4.925e-02, 2.817e-02, -1.585e-02, 1.032e-01, 4.938e-02, -2.622e-02, 1.448e-02, 1.082e-02, 3.036e-02, 1.225e-01, -1.274e-01, 1.434e-01));
	r += mul(s0_7, M4(3.011e-02, 1.242e-02, -5.529e-02, -5.066e-02, -9.845e-03, 7.469e-03, -6.035e-02, 8.793e-03, -4.797e-02, 9.315e-02, -2.454e-02, -9.654e-03, -2.158e-02, -4.011e-02, -1.726e-01, -1.261e-01));
	r += mul(s0_8, M4(7.857e-02, 1.055e-01, -1.466e-01, -2.452e-03, -4.077e-02, -1.649e-02, 9.544e-02, 4.088e-02, -3.076e-02, -2.159e-02, 5.775e-02, 4.365e-02, 4.184e-02, -1.062e-01, -6.914e-02, -1.963e-02));
	r += mul(s1_0, M4(-4.171e-01, 3.138e-01, 2.842e-01, -1.322e-02, -6.743e-02, 8.179e-02, 3.972e-03, -9.366e-03, 1.682e-01, -1.961e-01, -9.495e-02, -2.270e-02, 1.633e-02, -6.104e-02, -2.587e-02, -3.508e-02));
	r += mul(s1_1, M4(2.512e-01, -2.419e-01, -2.239e-01, 3.314e-02, 1.585e-02, -9.176e-02, -1.482e-02, -5.233e-03, -6.192e-02, 5.692e-02, -1.606e-02, -4.602e-02, 5.140e-01, -1.390e-01, -2.430e-01, 5.907e-02));
	r += mul(s1_2, M4(4.907e-02, -1.792e-01, -7.398e-02, -2.435e-02, 2.559e-02, -6.261e-02, -3.015e-02, 4.561e-02, -4.914e-02, 1.787e-01, 1.066e-01, 2.816e-02, -3.782e-01, 1.682e-01, 1.304e-01, -1.539e-02));
	r += mul(s1_3, M4(-1.252e-01, -3.156e-01, 1.260e-02, -7.136e-02, -6.259e-01, 3.077e-01, 2.525e-01, -1.162e-01, 1.116e-01, 3.362e-01, 5.970e-02, 4.431e-02, -2.629e-01, 1.030e-01, 1.489e-01, -8.912e-02));
	r += mul(s1_4, M4(7.407e-02, -9.808e-02, 1.001e-03, -2.664e-01, 4.131e-01, -4.661e-01, -1.369e-01, -5.883e-02, -3.672e-01, -1.843e-01, 1.707e-01, 1.822e-01, 1.732e-01, 4.407e-02, 2.529e-01, -1.807e-01));
	r += mul(s1_5, M4(-7.102e-02, -2.288e-02, 7.593e-02, 9.827e-02, -4.019e-02, -2.066e-01, 1.204e-01, 2.168e-02, -5.571e-02, 9.715e-02, 2.324e-01, -5.666e-02, -3.273e-01, 2.482e-01, 4.050e-01, -8.117e-02));
	r += mul(s1_6, M4(-1.274e-01, -1.195e-01, 8.738e-02, -1.716e-01, -3.224e-02, 1.127e-01, -1.243e-01, 2.723e-01, 1.808e-02, 1.190e-01, -1.082e-01, 2.622e-02, 2.432e-02, -2.148e-02, -4.528e-02, 1.189e-01));
	r += mul(s1_7, M4(6.402e-02, -1.065e-01, 7.816e-02, -2.142e-01, -1.305e-01, -1.311e-01, -1.958e-01, 3.115e-01, 4.640e-02, -1.467e-01, -7.089e-03, -4.110e-01, 9.068e-02, -6.598e-02, -1.618e-01, 2.627e-01));
	r += mul(s1_8, M4(3.764e-02, 2.454e-02, -3.670e-03, -6.028e-02, -1.667e-03, -6.408e-02, -8.157e-02, 1.165e-01, -5.023e-02, 2.224e-02, 8.171e-04, 3.488e-02, -4.667e-02, 1.000e-01, -1.731e-01, -1.158e+00));
	r += V4(2.647e-03, 4.477e-03, -7.585e-03, 5.873e-03);
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
	r += mul(s0_0, M4(-1.194e-02, -4.859e-03, -5.692e-03, 2.529e-02, -2.903e-04, 1.823e-02, 3.792e-02, 2.876e-02, -3.591e-02, -8.850e-02, 5.759e-02, -4.109e-03, 2.863e-02, -5.934e-02, 3.278e-02, -7.091e-02));
	r += mul(s0_1, M4(2.388e-02, 7.045e-02, 2.813e-03, 2.032e-02, 7.297e-02, 8.351e-02, -2.395e-03, 8.480e-03, 7.390e-02, 1.314e-01, 6.763e-03, 8.203e-03, -1.823e-01, -2.454e-02, -1.694e-01, 8.195e-02));
	r += mul(s0_2, M4(-1.881e-02, -5.203e-02, 2.423e-02, -1.779e-02, 3.437e-03, -4.677e-03, 1.284e-02, 1.205e-02, -5.926e-02, -7.963e-02, -1.314e-02, 1.841e-02, 3.938e-02, -8.385e-02, 1.192e-01, -1.682e-02));
	r += mul(s0_3, M4(-2.043e-02, 2.276e-02, -1.476e-02, -3.285e-02, 4.314e-02, 3.723e-02, 1.374e-02, 4.242e-03, 1.746e-01, 5.310e-02, -1.552e-01, 2.238e-01, 1.881e-02, 2.574e-02, -1.749e-02, 2.254e-02));
	r += mul(s0_4, M4(-2.265e-01, -3.311e-01, -6.820e-02, -1.585e-01, -1.155e-01, -8.667e-02, 6.043e-02, 8.791e-02, 2.920e-01, 2.901e-01, -7.285e-01, -9.090e-01, 6.308e-02, 3.175e-02, 7.285e-02, -1.038e-01));
	r += mul(s0_5, M4(-1.467e-04, 9.225e-02, -1.032e-01, -2.631e-02, -5.845e-03, -2.326e-02, -1.654e-02, -2.244e-02, 1.697e-02, 1.216e-01, 1.655e-01, -9.333e-03, 1.862e-02, 6.215e-03, -4.760e-02, -2.081e-02));
	r += mul(s0_6, M4(2.951e-02, 1.458e-02, 1.877e-02, 4.384e-02, 2.213e-03, 3.039e-03, 1.284e-02, 2.764e-02, -3.337e-02, 4.216e-02, 5.122e-02, -2.057e-02, -9.898e-03, 1.134e-03, -9.611e-03, -3.040e-03));
	r += mul(s0_7, M4(5.959e-02, 1.126e-01, -9.399e-02, 8.145e-03, 2.016e-03, -1.047e-02, -3.884e-02, -5.261e-02, -1.257e-01, -1.979e-01, 8.427e-02, 6.812e-02, -2.586e-02, -1.404e-02, 4.950e-03, 2.159e-02));
	r += mul(s0_8, M4(2.517e-02, 4.026e-02, 8.129e-02, 7.857e-02, 3.034e-03, 9.001e-03, 4.633e-04, 3.220e-03, 3.187e-02, 1.563e-02, -1.644e-02, 5.843e-03, -3.159e-03, -1.388e-02, 1.202e-02, -1.002e-02));
	r += mul(s1_0, M4(-5.743e-03, 3.275e-02, -1.267e-02, 3.676e-02, 8.177e-02, -2.736e-02, 6.799e-02, 1.289e-02, -6.908e-03, 8.859e-03, -8.582e-03, -9.254e-03, 6.758e-02, -2.041e-02, -3.263e-02, -1.023e-01));
	r += mul(s1_1, M4(5.285e-02, -1.683e-02, 2.766e-02, 4.442e-02, -9.589e-02, 1.655e-01, 4.116e-02, -1.294e-01, -1.457e-02, -1.813e-02, 2.485e-02, 3.720e-02, -5.174e-01, -1.235e-01, 2.056e-01, 1.856e-01));
	r += mul(s1_2, M4(-9.645e-02, 1.022e-02, 2.427e-02, -7.510e-02, 2.941e-02, -2.895e-02, -6.652e-03, 1.023e-02, -1.049e-02, -4.214e-03, 5.776e-03, -3.638e-03, 5.653e-02, -2.628e-01, 1.086e-01, 1.801e-01));
	r += mul(s1_3, M4(1.383e-02, -7.007e-02, 5.923e-02, -4.918e-02, -1.248e-01, 8.461e-03, -1.177e-01, 3.727e-02, -1.693e-03, 5.189e-02, 3.325e-02, 3.346e-02, -1.510e-01, 1.973e-02, 7.310e-03, 1.031e-01));
	r += mul(s1_4, M4(-3.018e-01, 2.346e-02, -1.219e-01, -1.491e-01, -8.395e-01, 7.989e-01, -6.702e-01, 8.506e-01, -2.329e-01, -2.607e-01, -2.250e-01, -2.447e-01, 1.351e+00, 2.536e-01, -1.154e+00, -5.294e-01));
	r += mul(s1_5, M4(7.096e-01, -8.596e-01, 6.883e-02, -1.303e-01, 1.023e-01, -1.958e-01, 1.881e-01, -1.266e-01, 1.395e-02, 1.808e-02, 3.818e-02, 2.802e-02, -1.469e-01, 8.765e-01, -2.217e-01, -8.782e-01));
	r += mul(s1_6, M4(1.786e-02, 2.192e-02, -1.220e-02, 8.009e-03, 5.334e-02, -9.817e-04, 9.742e-02, -1.366e-02, 7.099e-03, 3.649e-02, -2.105e-02, 6.975e-02, -3.173e-02, 2.023e-02, 1.449e-01, -2.185e-02));
	r += mul(s1_7, M4(1.236e-01, 1.048e-01, -8.486e-02, 2.056e-01, 9.174e-02, -8.500e-02, -2.239e-01, 1.853e-01, -4.594e-03, -3.332e-02, 5.604e-04, -8.544e-02, -1.252e-01, -1.204e-01, -1.529e-01, 1.081e-01));
	r += mul(s1_8, M4(-1.783e-02, 1.614e-01, 5.616e-01, -4.508e-01, 3.156e-02, 8.139e-03, 4.673e-02, -8.034e-02, 1.912e-02, 1.725e-02, -1.175e-02, 2.520e-02, -2.371e-02, -7.804e-02, 1.157e-01, -8.016e-02));
	r += V4(-8.894e-05, 2.216e-04, -5.724e-04, -4.112e-04);
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

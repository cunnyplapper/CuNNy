// CuNNy 1x4C CHROMA NVL
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
//!DESC CuNNy-1x4C-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(1.192e+00, 2.228e+00, 5.615e-01), O(INPUT, float2(x, y)).rgb) + -3.682e-02)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(5.750e-02, 2.341e-03, -9.395e-03, -1.826e-02) * s0_0;
	r += V4(-5.224e-02, -1.608e-02, -1.630e-02, 2.528e-01) * s0_1;
	r += V4(-5.141e-03, 1.034e-02, 9.621e-04, 1.835e-01) * s0_2;
	r += V4(-3.500e-01, 4.362e-02, 2.947e-01, 1.921e-02) * s0_3;
	r += V4(3.311e-01, -4.170e-01, -6.301e-02, -2.803e-01) * s0_4;
	r += V4(1.816e-02, 3.123e-02, 2.780e-02, -1.567e-01) * s0_5;
	r += V4(3.748e-02, -4.446e-02, -4.051e-02, -2.339e-03) * s0_6;
	r += V4(-2.878e-02, 4.326e-01, -9.674e-03, 1.908e-02) * s0_7;
	r += V4(-8.758e-03, -4.234e-02, -1.985e-05, -1.629e-02) * s0_8;
	r += V4(1.958e-03, 9.184e-04, -2.546e-04, -1.468e-03);
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
//!DESC CuNNy-1x4C-CHROMA-NVL-conv1
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
	r += mul(s0_0, M4(-3.827e-03, 2.606e-02, 8.228e-02, -4.219e-02, 5.659e-02, 2.520e-02, -1.069e-01, 6.624e-03, 3.603e-02, 2.310e-02, 1.111e-01, -5.996e-02, -1.295e-01, 1.688e-02, -7.494e-02, -3.964e-02));
	r += mul(s0_1, M4(1.828e-02, -3.633e-03, -1.201e-01, -2.348e-01, 2.632e-01, -3.253e-03, -3.477e-01, -4.958e-03, 1.322e-02, 2.544e-02, -7.202e-02, 3.152e-03, 1.243e-01, -2.444e-02, -6.368e-02, 5.230e-02));
	r += mul(s0_2, M4(2.658e-01, 2.889e-02, -1.773e-01, 8.975e-04, -7.595e-02, -8.380e-03, -1.450e-01, 3.729e-02, 1.383e-01, -2.384e-02, 4.787e-02, 1.123e-01, 2.368e-03, 4.872e-03, -4.323e-02, -5.407e-02));
	r += mul(s0_3, M4(-1.314e-01, -7.505e-02, -9.605e-02, 1.580e-02, 3.605e-02, -4.947e-02, 4.852e-04, 3.742e-02, -2.026e-01, -1.375e-02, -1.304e-01, 3.522e-02, -7.953e-01, 1.733e-01, 6.133e-02, -1.355e-01));
	r += mul(s0_4, M4(6.230e-02, -1.807e-01, -7.671e-02, 1.607e-02, -1.381e-01, -9.936e-02, 3.248e-01, 1.772e-01, 3.462e-02, 1.011e-01, -2.775e-02, -1.711e-01, 8.381e-01, -1.077e-01, 4.379e-02, 3.279e-02));
	r += mul(s0_5, M4(-9.254e-02, 2.510e-01, 9.971e-02, -1.026e-01, -9.769e-02, 3.048e-01, 8.092e-02, 7.886e-02, 4.504e-02, 8.079e-02, -3.679e-02, -1.156e-02, -9.398e-02, 3.389e-02, -7.002e-03, -1.090e-01));
	r += mul(s0_6, M4(-1.022e-01, -1.965e-01, 5.771e-04, 1.724e-01, -1.474e-02, -9.628e-02, 7.740e-02, 6.323e-02, -1.370e-01, -2.847e-01, -7.599e-03, 1.855e-01, -2.554e-02, 7.577e-02, -1.760e-02, 1.612e-01));
	r += mul(s0_7, M4(7.555e-02, -2.151e-01, 1.772e-01, 1.724e-01, -6.885e-03, 6.042e-02, -5.431e-02, 8.568e-02, 2.173e-01, 2.604e-01, 1.233e-01, 1.738e-03, 2.700e-02, -3.188e-01, -3.845e-02, 2.549e-01));
	r += mul(s0_8, M4(-1.386e-01, 3.404e-01, 8.089e-03, 1.431e-01, -1.418e-02, -1.555e-03, 4.378e-02, 7.685e-02, -1.470e-01, -1.671e-01, -8.476e-03, -9.378e-02, -6.067e-02, -4.565e-02, 1.675e-02, 5.231e-02));
	r += mul(s1_0, M4(3.926e-02, 1.008e-02, 7.446e-02, -3.991e-02, -5.966e-01, 9.636e-02, 3.133e-02, 6.515e-02, 1.268e-01, 3.073e-02, 1.203e-01, -4.169e-02, -3.397e-02, 7.150e-03, 3.440e-02, 3.394e-02));
	r += mul(s1_1, M4(-2.560e-01, -3.493e-02, 1.333e-01, -5.736e-02, 1.281e-01, 1.628e-02, 1.123e-01, 3.017e-01, 3.842e-01, -2.005e-01, -5.013e-01, -3.177e-01, 6.909e-02, -1.879e-02, -6.492e-02, -2.463e-03));
	r += mul(s1_2, M4(7.718e-01, 3.373e-02, 1.294e-01, 2.399e-01, 5.684e-01, 7.812e-03, 5.210e-03, 1.169e-01, 6.968e-02, 1.872e-01, -9.695e-01, -1.340e-01, -1.508e-02, 1.362e-02, 3.904e-02, 6.914e-03));
	r += mul(s1_3, M4(-1.736e-01, 3.899e-02, -1.010e-01, 2.967e-02, -1.095e-02, 3.123e-01, -1.212e-01, -6.643e-02, -1.083e-01, -7.230e-02, -1.363e-01, -5.094e-02, 1.088e-01, 2.163e-02, 4.502e-02, -3.048e-02));
	r += mul(s1_4, M4(-3.445e-01, -7.218e-02, -1.126e-01, 6.060e-02, -3.971e-02, -3.037e-01, -5.357e-02, -1.893e-01, 2.262e-01, -2.354e-01, -8.894e-02, -3.182e-01, 1.499e-01, -5.358e-02, -3.242e-02, 9.450e-02));
	r += mul(s1_5, M4(3.547e-01, -5.622e-02, 6.948e-02, -1.355e-01, 7.446e-02, -1.609e-01, -3.284e-02, 1.016e-02, 2.581e-01, 4.729e-01, -2.135e+00, 1.210e+00, -1.704e-01, 3.098e-02, 4.562e-02, -1.098e-02));
	r += mul(s1_6, M4(-1.424e-01, -9.163e-02, 2.007e-02, 1.697e-01, 3.898e-03, 1.041e-02, 1.544e-03, -3.714e-03, -1.030e-01, -1.360e-01, 4.721e-02, 2.112e-01, 1.163e-01, -3.235e-01, -9.595e-02, 1.352e-01));
	r += mul(s1_7, M4(1.062e-01, 1.343e-01, -3.774e-02, -6.994e-02, 6.337e-03, 8.198e-03, -1.024e-02, 8.082e-03, 1.555e-01, -1.558e+00, 5.106e-01, 4.541e-01, -1.899e-01, 2.942e-01, 4.214e-02, 2.369e-01));
	r += mul(s1_8, M4(-1.831e-01, -7.111e-02, -1.450e-01, -1.110e-01, -1.670e-02, -4.847e-02, -1.425e-02, -2.922e-03, -2.546e-01, -1.895e-01, 1.250e-01, 1.499e+00, -8.961e-02, 3.703e-02, -1.064e-01, -3.062e-02));
	r += V4(-9.980e-04, -4.297e-04, 8.294e-04, -1.296e-03);
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
//!DESC CuNNy-1x4C-CHROMA-NVL-out
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
	r += mul(s0_0, M4(-8.958e-03, 1.457e-02, -3.314e-03, 1.423e-02, -7.421e-02, 1.130e-01, -3.287e-02, 1.058e-01, -3.186e-02, -6.481e-03, 5.315e-02, 1.377e-02, -2.980e-02, -7.698e-03, -5.507e-02, 4.331e-02));
	r += mul(s0_1, M4(2.227e-02, -3.285e-02, -1.155e-02, 2.026e-02, 1.440e-01, -3.361e-01, 1.115e-01, -1.628e-01, 1.894e-03, -5.649e-02, 7.380e-02, 8.735e-02, 1.509e-01, 8.870e-02, -1.198e-01, -2.212e-01));
	r += mul(s0_2, M4(2.016e-02, -5.157e-02, -1.429e-03, -1.902e-02, -3.190e-02, 6.860e-02, -2.683e-02, 2.923e-02, -4.611e-02, -1.031e-02, -5.548e-03, 2.133e-02, 7.402e-03, 2.742e-02, 2.686e-02, 3.192e-02));
	r += mul(s0_3, M4(-5.088e-03, -9.040e-03, -3.134e-02, 1.524e-02, 1.009e-03, 1.642e-02, -7.054e-03, 4.741e-02, 5.953e-02, 5.589e-03, 2.519e-02, 5.612e-02, -1.624e-03, 5.307e-03, -1.911e-03, -1.063e-01));
	r += mul(s0_4, M4(-2.686e-01, 1.590e-01, 4.401e-02, -4.811e-02, 3.413e-03, 2.377e-02, -2.476e-02, -1.077e-01, 1.581e-02, 1.052e-01, -2.842e-01, -2.920e-01, -1.174e-01, -9.208e-02, 2.187e-01, 3.369e-01));
	r += mul(s0_5, M4(1.070e-01, -1.861e-02, 5.308e-02, 7.348e-03, 9.793e-03, -1.487e-02, -2.200e-03, 2.814e-02, 3.101e-03, -2.848e-02, 5.204e-02, 3.311e-02, 4.919e-02, -1.696e-04, -3.344e-02, -5.386e-02));
	r += mul(s0_6, M4(-2.339e-02, -1.104e-02, 1.550e-03, -2.788e-02, -1.006e-02, 6.304e-03, -2.577e-02, 2.512e-02, -6.178e-04, 1.217e-02, -8.866e-03, 2.057e-02, -3.051e-03, 5.552e-03, -1.559e-02, 2.139e-02));
	r += mul(s0_7, M4(-1.175e-02, 5.063e-02, -3.763e-01, 2.646e-01, 3.737e-03, -7.539e-03, 4.077e-02, -1.608e-03, 5.543e-03, 6.716e-04, 3.020e-02, -1.201e-02, -9.585e-04, -2.143e-02, 1.764e-02, -4.343e-02));
	r += mul(s0_8, M4(7.691e-02, 9.293e-04, 1.538e-01, -5.123e-02, -6.419e-04, -3.196e-03, 7.618e-03, -5.887e-03, 3.580e-03, -3.858e-04, -2.031e-02, -3.152e-03, -6.128e-04, 7.178e-03, -6.496e-03, 2.485e-02));
	r += mul(s1_0, M4(-2.157e-02, 4.002e-03, 9.145e-04, -7.255e-04, -1.525e-02, -7.020e-03, -7.216e-03, 1.276e-02, -3.750e-03, 1.738e-02, 2.634e-03, 2.894e-03, -1.450e-03, -2.272e-02, -1.297e-02, 1.116e-02));
	r += mul(s1_1, M4(-1.452e-02, -1.553e-02, -2.092e-03, 1.395e-02, -3.043e-01, 1.080e-01, -1.776e-01, 1.519e-01, 4.433e-03, -4.272e-02, 9.601e-03, 1.079e-02, 8.810e-03, 2.517e-03, 1.385e-02, -4.407e-02));
	r += mul(s1_2, M4(1.195e-03, -1.643e-02, 6.041e-03, -5.404e-03, 2.460e-01, -1.819e-01, 1.704e-01, -1.579e-01, 2.808e-03, 2.577e-02, -4.956e-03, -8.459e-03, 2.582e-03, 2.238e-02, -1.211e-02, 2.219e-02));
	r += mul(s1_3, M4(-2.297e-02, 7.544e-02, -3.381e-02, 4.856e-02, 9.784e-03, 9.870e-03, 4.292e-04, -1.618e-02, 3.156e-02, 6.761e-02, 1.349e-02, 8.817e-03, -9.884e-03, -5.135e-02, -2.062e-02, -4.366e-02));
	r += mul(s1_4, M4(5.821e-02, -8.667e-02, 1.961e-02, -7.009e-02, -5.211e-04, 1.800e-02, -1.086e-01, -5.645e-03, -2.782e-01, -2.652e-01, 8.475e-02, 5.659e-02, 2.673e-01, 2.572e-01, -7.966e-02, -2.354e-02));
	r += mul(s1_5, M4(-1.478e-02, 4.528e-02, -6.681e-03, 8.518e-03, 2.299e-02, -2.028e-02, 2.981e-02, 6.633e-02, 5.485e-02, 8.441e-03, -1.879e-02, 1.212e-02, -4.506e-02, -4.567e-03, 2.868e-02, -1.729e-02));
	r += mul(s1_6, M4(-3.490e-02, 5.830e-02, -7.496e-02, 1.136e-01, -6.086e-03, 1.835e-03, -1.257e-02, 1.317e-02, 3.759e-02, 2.720e-03, -6.083e-03, 4.512e-03, -5.477e-02, -1.194e-02, 1.234e-02, 4.833e-02));
	r += mul(s1_7, M4(3.214e-02, -4.602e-02, 6.099e-02, -8.667e-02, -1.008e-03, -2.586e-03, -1.333e-02, 1.697e-02, 1.323e-01, 1.519e-01, -9.126e-02, -1.264e-01, -6.980e-02, -9.648e-02, 3.182e-02, -4.867e-02));
	r += mul(s1_8, M4(1.571e-02, -1.838e-02, 5.249e-03, 8.462e-03, 5.063e-03, -1.358e-02, 2.214e-02, -3.625e-02, -3.109e-02, -1.426e-02, -3.503e-02, -4.508e-03, 5.169e-03, -3.122e-02, 2.467e-02, 6.958e-02));
	r += V4(1.140e-03, 1.294e-03, 9.408e-04, 1.320e-03);
	return tanh(r);
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
//!DESC CuNNy-1x4C-CHROMA-NVL-shuffle
//!STYLE PS
//!IN t0, INPUT, easu
float4 Pass5(float2 pos) {
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

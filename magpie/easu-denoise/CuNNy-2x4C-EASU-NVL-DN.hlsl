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
#define l0(x, y) (dot(float3(-2.842e-01, -5.282e-01, -1.294e-01), O(INPUT, float2(x, y)).rgb) + 7.524e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-3.392e-01, -6.191e-01, -6.403e-03, 3.242e-03) * s0_0;
	r += V4(3.506e-01, -5.967e-02, 8.626e-03, -1.159e-01) * s0_1;
	r += V4(6.435e-03, -2.348e-02, -6.216e-03, 1.112e-01) * s0_2;
	r += V4(-4.267e-01, 5.259e-01, 4.255e-02, 1.327e-01) * s0_3;
	r += V4(3.605e-01, 1.724e-01, -4.122e-02, -6.065e-02) * s0_4;
	r += V4(5.042e-02, 1.343e-03, 1.278e-02, -4.089e-01) * s0_5;
	r += V4(1.559e-02, 5.237e-02, -1.767e-02, -1.137e-01) * s0_6;
	r += V4(-4.587e-02, -7.941e-02, -5.520e-01, 5.680e-01) * s0_7;
	r += V4(3.012e-02, 2.301e-02, 5.609e-01, -9.888e-02) * s0_8;
	r += V4(-9.536e-03, -8.101e-03, -7.332e-03, -1.688e-02);
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
	r += mul(s0_0, M4(1.196e-01, 1.050e-01, 2.300e-02, -1.909e-01, -8.956e-02, -5.257e-02, -3.871e-02, 1.466e-02, 6.826e-01, -6.418e-01, 5.035e-01, -1.017e-01, 8.692e-01, 5.115e-01, 2.480e-01, 4.727e-01));
	r += mul(s0_1, M4(4.811e-02, 2.539e-02, 1.772e-01, 2.366e-01, 2.381e-02, 5.281e-03, -1.137e-01, -1.914e-01, -6.666e-02, -1.703e-01, 2.881e-01, -1.081e-01, 1.006e-01, 4.004e-01, 2.514e-01, 1.072e-01));
	r += mul(s0_2, M4(2.491e-02, -1.915e-02, -7.685e-02, 2.731e-02, 3.562e-02, 8.716e-02, 9.936e-02, 1.137e-01, 1.423e-01, -5.579e-02, 1.439e-01, -1.135e-01, -1.089e-01, -5.676e-02, -1.402e-01, -7.818e-03));
	r += mul(s0_3, M4(3.812e-02, 2.549e-01, -1.896e-01, 2.998e-01, -4.051e-02, 1.287e-01, 5.144e-02, -1.130e-03, -9.576e-02, -4.645e-01, -5.215e-02, -2.758e-02, 4.604e-01, -2.857e-02, -2.923e-01, 4.088e-01));
	r += mul(s0_4, M4(4.502e-01, -5.659e-03, -1.984e-01, 9.733e-02, 4.227e-01, 4.717e-01, -9.769e-02, 3.312e-01, -6.943e-04, -5.109e-02, -4.543e-02, -1.851e-01, -3.468e-02, 4.754e-02, -1.708e-01, 9.035e-02));
	r += mul(s0_5, M4(-2.567e-01, -2.276e-01, 5.127e-01, 8.075e-02, 3.202e-01, -5.287e-03, 1.461e-02, 9.001e-02, 2.457e-02, -8.093e-03, 3.520e-01, -2.140e-02, 1.129e-01, -1.352e-01, 3.623e-01, 9.285e-02));
	r += mul(s0_6, M4(-1.295e-01, 5.204e-02, 7.059e-02, -1.004e-01, -6.013e-02, -1.005e-01, 1.788e-02, -6.608e-02, -7.935e-02, -1.326e-01, 7.229e-03, -1.362e-01, 1.665e-03, -6.639e-03, -1.013e-01, -1.616e-01));
	r += mul(s0_7, M4(2.883e-01, 4.089e-01, -1.095e-02, 3.106e-01, -2.851e-01, -2.478e-01, 1.194e-01, -5.071e-02, -3.340e-02, 3.349e-02, -4.082e-01, 2.414e-02, 7.281e-02, -2.755e-02, -3.129e-01, 8.280e-02));
	r += mul(s0_8, M4(-4.532e-02, 2.322e-01, -1.019e-01, 4.139e-01, -1.558e-01, -5.479e-01, 3.555e-01, 1.193e-01, -2.740e-02, 1.746e-02, 1.204e-01, -5.898e-03, -2.498e-02, -4.963e-02, 4.367e-01, 1.041e-01));
	r += mul(s1_0, M4(1.539e-01, 1.308e-01, 8.712e-02, -1.034e-01, -8.953e-02, -1.527e-01, 2.626e-02, 7.988e-02, 4.714e-02, 1.567e-01, 1.108e-01, -4.857e-01, 2.240e-01, 1.251e-01, 1.991e-01, -3.146e-01));
	r += mul(s1_1, M4(-8.011e-02, 6.245e-02, 2.060e-01, 1.450e-01, 9.243e-02, -6.026e-02, -6.179e-02, -4.521e-02, -3.210e-01, 6.764e-02, -2.334e-01, -8.807e-03, -9.509e-02, -1.939e-01, 2.959e-01, -1.647e-01));
	r += mul(s1_2, M4(-7.699e-03, 2.044e-02, -9.838e-02, 1.225e-02, 4.490e-02, -4.590e-03, 1.852e-01, 1.833e-01, 5.187e-02, -1.428e-02, -3.238e-02, -1.307e-02, 4.553e-02, -4.452e-02, 1.115e-01, 7.475e-02));
	r += mul(s1_3, M4(-5.993e-02, -6.510e-02, -1.511e-01, 1.723e-01, -8.202e-02, -1.753e-01, 1.164e-01, -6.461e-02, -4.544e-02, 5.962e-01, 1.280e-01, 1.563e-01, 8.623e-02, 8.549e-02, -2.416e-01, 1.791e-01));
	r += mul(s1_4, M4(5.561e-02, 8.423e-02, -1.727e-01, -3.277e-01, -1.922e-01, 1.641e-01, -7.629e-02, -2.717e-01, -9.185e-02, 3.037e-01, -2.605e-01, 2.333e-02, -2.173e-01, -1.862e-02, -4.298e-01, -2.531e-01));
	r += mul(s1_5, M4(-3.857e-01, 4.693e-02, 3.412e-01, -4.074e-02, 1.489e-02, 1.249e-01, -2.319e-01, -6.616e-02, 7.159e-02, -7.930e-02, 2.771e-01, 6.614e-02, 6.140e-02, -2.197e-02, 4.429e-01, -9.177e-03));
	r += mul(s1_6, M4(-7.082e-02, -1.646e-01, 1.606e-01, -5.583e-02, -2.357e-02, -1.300e-01, 4.065e-02, 4.315e-02, -3.736e-02, -6.899e-02, -1.582e-02, -1.235e-01, -5.168e-02, -7.413e-02, 8.346e-03, -1.088e-01));
	r += mul(s1_7, M4(1.575e-01, -5.249e-01, -1.749e-01, -3.392e-04, -3.944e-01, 4.897e-02, 6.328e-02, -1.238e-01, 2.387e-02, 1.229e-02, -2.981e-01, 5.902e-03, 7.904e-02, 1.587e-01, -3.976e-01, 5.994e-02));
	r += mul(s1_8, M4(-1.117e-01, -2.576e-01, -5.566e-01, 1.590e-01, -3.018e-01, 8.745e-02, -6.504e-01, 2.731e-01, 4.982e-03, -1.562e-02, 2.281e-01, 4.771e-02, -7.351e-03, -6.117e-04, 3.428e-01, 2.727e-02));
	r += V4(-3.036e-02, 9.474e-03, -1.728e-02, -3.107e-02);
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
	r += mul(s0_0, M4(-6.131e-02, 1.423e-02, -2.481e-03, -3.371e-02, -2.224e-02, -5.974e-03, 6.676e-02, -9.607e-03, 9.102e-02, -1.120e-01, -2.472e-02, -6.036e-02, 4.094e-02, 5.628e-03, 2.659e-02, 3.529e-02));
	r += mul(s0_1, M4(-2.338e-02, -6.614e-02, -2.286e-01, -1.023e-01, 2.133e-02, 2.361e-02, -1.724e-01, -6.697e-04, -2.275e-02, 8.924e-02, -2.113e-01, -3.529e-02, -6.872e-03, 6.369e-02, 2.164e-01, 1.210e-01));
	r += mul(s0_2, M4(7.836e-02, 2.288e-02, -1.284e-01, 1.918e-02, -4.261e-02, -2.335e-02, 3.121e-01, 2.827e-02, -6.876e-02, -1.905e-02, 1.763e-01, -5.264e-02, 9.124e-06, -1.293e-02, -2.056e-02, 1.435e-02));
	r += mul(s0_3, M4(8.654e-02, -6.706e-02, 3.012e-02, 3.292e-04, -9.651e-03, -5.453e-03, -1.605e-02, -3.152e-02, -1.325e-01, 8.528e-03, 2.073e-02, -4.987e-02, -4.816e-03, 8.235e-02, 9.477e-02, 5.152e-02));
	r += mul(s0_4, M4(1.421e-01, 1.211e-01, 5.762e-01, 4.234e-01, -1.091e-01, -5.229e-02, -2.456e-01, 1.413e-02, -8.472e-04, -1.101e-01, 1.936e-01, -2.075e-01, -2.443e-01, -1.921e-03, -3.643e-01, -2.824e-01));
	r += mul(s0_5, M4(1.721e-02, -4.712e-02, -1.880e-01, 2.439e-01, -5.479e-02, -1.923e-02, 3.452e-02, -5.762e-01, 4.955e-02, 1.169e-01, 1.125e-02, -2.448e-01, -5.083e-02, -6.459e-02, -5.379e-02, -4.443e-04));
	r += mul(s0_6, M4(6.265e-02, 3.838e-01, 3.185e-02, -3.928e-02, 4.343e-02, -9.690e-03, 4.091e-03, 2.696e-02, -5.718e-02, 4.236e-02, -9.186e-03, -1.194e-02, -1.615e-01, -2.202e-01, 3.125e-04, 2.421e-02));
	r += mul(s0_7, M4(7.160e-02, -2.968e-01, -9.485e-02, 7.414e-02, 6.711e-02, -4.597e-01, -8.840e-02, 5.127e-02, -8.702e-02, 2.009e-02, -8.506e-02, -1.831e-01, 5.505e-02, 4.739e-01, 5.421e-02, -7.669e-02));
	r += mul(s0_8, M4(-8.666e-02, -1.629e-01, 4.284e-02, 2.966e-01, 5.823e-02, 2.157e-01, -1.375e-01, -7.969e-02, 1.657e-02, 7.885e-02, 7.452e-03, -1.411e-01, -5.112e-02, -2.725e-01, 4.041e-02, 8.635e-02));
	r += mul(s1_0, M4(-1.587e-01, -8.539e-02, 9.362e-02, -9.740e-02, 6.885e-02, -1.481e-02, 5.613e-03, -1.488e-02, 2.085e-01, -4.447e-03, -4.370e-02, -8.910e-02, 1.333e-01, 3.260e-02, -7.430e-02, 1.377e-02));
	r += mul(s1_1, M4(-1.229e-01, -1.292e-01, -1.973e-01, -2.047e-01, 4.836e-03, 5.650e-02, 2.997e-02, -8.427e-03, 1.319e-01, 7.979e-02, -2.882e-01, 3.158e-01, 2.025e-02, 7.084e-02, 1.508e-01, 1.080e-01));
	r += mul(s1_2, M4(-4.089e-02, -6.425e-03, -2.569e-01, -1.598e-01, -1.050e-01, -8.293e-02, 1.968e-01, -1.373e-02, -3.767e-02, 4.497e-02, -3.813e-01, -5.715e-02, -1.290e-02, -1.340e-02, -1.013e-01, 2.240e-02));
	r += mul(s1_3, M4(-1.308e-01, -1.632e-01, 2.153e-01, -2.182e-01, -1.756e-02, -6.472e-02, -4.275e-02, 2.157e-02, -1.206e-01, 1.743e-01, 3.166e-01, 2.202e-01, -4.489e-02, 6.770e-02, -9.598e-02, 7.039e-02));
	r += mul(s1_4, M4(2.698e-01, 1.918e-01, -7.269e-02, 7.755e-01, -1.518e-01, 2.213e-01, -2.587e-01, -1.809e-01, 4.365e-01, -1.802e-01, -2.342e-01, 2.063e-01, -2.415e-01, 1.173e-01, 5.437e-02, -3.037e-01));
	r += mul(s1_5, M4(9.689e-02, -3.851e-02, -1.425e-02, 3.732e-01, 4.111e-02, 2.959e-01, 5.931e-02, -6.523e-02, 2.546e-02, -4.676e-02, 2.485e-02, 4.279e-01, -6.662e-02, -5.533e-02, -2.091e-01, -2.475e-02));
	r += mul(s1_6, M4(3.740e-01, 3.604e-01, 1.161e-02, -2.554e-01, -1.159e-01, -5.424e-02, -5.808e-02, -2.633e-03, 3.864e-01, 3.164e-02, 5.229e-02, -2.841e-02, -8.640e-02, -1.457e-02, -1.033e-02, 1.207e-01));
	r += mul(s1_7, M4(2.146e-01, 2.212e-01, -7.757e-03, 3.823e-01, -3.946e-02, -2.205e-01, 7.006e-03, -3.709e-02, 4.515e-01, 3.173e-01, 1.018e-03, 2.755e-01, 1.421e-01, -2.945e-01, -1.407e-01, -1.601e-02));
	r += mul(s1_8, M4(-9.405e-03, -6.209e-03, 1.422e-01, 3.135e-01, 2.323e-02, -1.421e-02, -2.919e-02, -7.544e-02, -5.099e-02, -9.363e-02, -2.011e-02, 2.399e-01, 4.326e-02, -7.011e-02, 8.093e-02, 1.327e-01));
	r += V4(-9.063e-03, -2.430e-03, 8.114e-03, 4.833e-03);
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
	r += mul(s0_0, M4(4.332e-01, -1.478e-01, -1.679e-01, -1.309e-01, -1.152e-03, 1.964e-03, 4.178e-03, 1.007e-02, 2.049e-02, -8.757e-03, -3.100e-02, -1.224e-02, -2.448e-01, 2.627e-01, 6.848e-02, 1.216e-01));
	r += mul(s0_1, M4(-1.309e+00, 1.048e+00, 6.577e-01, 9.651e-02, 4.647e-01, -2.680e-01, 6.901e-01, -8.888e-02, 3.372e-02, 7.397e-03, 4.429e-02, -2.530e-05, -2.732e-02, -9.749e-01, 2.548e-01, 2.099e-01));
	r += mul(s0_2, M4(1.076e-01, -1.430e+00, 5.605e-01, 4.477e-01, -3.077e-01, 1.676e-01, -2.901e-01, 2.541e-01, -1.536e-04, 2.151e-02, 3.685e-03, 4.773e-03, -9.741e-02, 1.439e-01, -1.491e-02, 7.589e-02));
	r += mul(s0_3, M4(2.640e-01, -1.950e-01, 1.307e-01, -1.282e-01, 1.065e-02, 1.144e-02, -7.985e-03, 9.620e-03, -3.247e-02, 1.773e-02, 6.809e-02, 1.175e-02, -1.136e-01, 2.136e-01, -6.101e-01, 2.998e-01));
	r += mul(s0_4, M4(7.090e-01, 5.059e-01, -1.908e+00, -7.780e-02, 9.553e-02, 4.013e-02, -3.629e-02, -1.558e-01, -3.658e-01, -1.865e-01, -2.300e-01, -2.878e-02, 9.463e-01, 2.185e-01, 2.309e-01, -1.472e+00));
	r += mul(s0_5, M4(8.071e-03, 5.545e-01, 4.444e-01, 9.747e-02, 4.895e-02, 9.891e-02, -7.910e-02, -1.111e-01, -9.762e-03, -5.214e-02, 6.165e-02, 3.163e-02, -4.731e-02, 1.587e-01, -1.655e-01, 1.358e-01));
	r += mul(s0_6, M4(1.318e-02, -2.555e-02, 2.989e-01, -3.638e-02, 3.323e-03, 6.469e-03, 3.516e-02, 2.203e-02, -4.925e-02, -1.056e-02, -5.794e-02, 2.985e-02, -6.991e-03, 4.285e-02, 6.401e-02, 1.018e-01));
	r += mul(s0_7, M4(-4.734e-02, -1.150e-01, 3.772e-02, 5.365e-02, 5.117e-03, 1.176e-02, -1.369e-03, 2.480e-02, 3.884e-02, -2.518e-02, 1.022e-02, -1.248e-01, -1.096e-01, -1.180e-01, 1.557e-01, 1.595e-01));
	r += mul(s0_8, M4(-1.448e-03, -9.189e-03, -5.830e-03, -6.118e-02, -1.466e-02, -2.024e-02, -1.054e-02, -7.078e-03, 2.969e-03, 4.773e-02, -2.260e-02, 7.993e-02, 2.804e-02, -1.927e-02, -9.349e-04, 1.694e-03));
	r += mul(s1_0, M4(-4.094e-02, -1.790e-02, -3.894e-02, 9.420e-03, -4.652e-02, -3.131e-02, 1.255e-01, -1.656e-02, 2.714e-02, -2.937e-03, -1.662e-02, 4.673e-03, 1.455e-02, 4.691e-02, 3.996e-02, 2.953e-02));
	r += mul(s1_1, M4(1.187e-01, -2.512e-02, -7.597e-02, -1.231e-01, 2.764e-01, 1.545e-01, 8.816e-02, 1.680e-01, 5.236e-02, 5.437e-02, 4.188e-02, -5.219e-03, -3.397e-01, -1.801e-01, -1.518e-01, -6.652e-02));
	r += mul(s1_2, M4(3.721e-02, 4.587e-02, 1.174e-01, 3.105e-02, -9.811e-03, 4.499e-02, -4.578e-02, -2.441e-02, -2.400e-02, -1.959e-02, -4.810e-03, 3.392e-03, -8.389e-04, -3.628e-02, 1.322e-02, 4.847e-02));
	r += mul(s1_3, M4(2.065e-02, -1.041e-02, 4.827e-02, 3.913e-03, 3.551e-02, 1.802e-02, -1.959e-01, -2.251e-02, -5.103e-02, 1.013e-01, -2.369e-02, 4.747e-02, -1.516e-01, -1.134e-01, -9.531e-02, -3.127e-02));
	r += mul(s1_4, M4(-3.389e-02, 1.044e-01, 1.061e-01, 1.250e-01, 4.821e-02, -5.039e-02, 4.391e-02, -2.686e-01, -5.029e-01, -9.482e-01, 1.743e-01, 7.744e-03, 3.113e-01, 2.039e-01, 1.343e-01, 7.812e-02));
	r += mul(s1_5, M4(-1.059e-01, -1.976e-01, -1.110e-01, -1.077e-01, -1.207e-02, 3.395e-02, -1.444e-02, 5.199e-02, -8.862e-02, 2.847e-02, -1.451e-02, 4.416e-02, -2.873e-02, 6.563e-02, -4.989e-02, 5.224e-03));
	r += mul(s1_6, M4(1.844e-02, 2.291e-02, -2.529e-03, 3.270e-03, 1.610e-02, 9.317e-04, 1.474e-02, -2.530e-02, -2.359e-02, -7.894e-02, 1.398e-01, 4.910e-03, 6.718e-02, 4.231e-02, 3.309e-02, 1.909e-02));
	r += mul(s1_7, M4(-8.602e-02, -5.594e-02, -3.323e-02, 1.700e-02, 4.465e-04, 1.765e-03, 4.783e-03, -7.923e-03, 3.232e-01, 2.588e-01, -2.215e-01, -4.053e-01, -6.068e-02, -2.406e-02, 3.510e-03, 4.399e-02));
	r += mul(s1_8, M4(5.994e-02, 2.324e-02, -4.597e-04, -5.734e-02, -6.953e-03, -3.265e-03, -8.788e-03, 3.580e-03, 3.471e-03, 1.013e-01, -1.004e-01, 7.929e-02, 1.370e-02, -9.710e-03, 1.923e-02, -1.788e-03));
	r += V4(4.533e-03, 2.447e-03, 1.847e-03, 6.665e-06);
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

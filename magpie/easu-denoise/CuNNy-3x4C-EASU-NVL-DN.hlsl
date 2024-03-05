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
#define l0(x, y) (dot(float3(2.959e-01, 5.450e-01, 1.372e-01), O(INPUT, float2(x, y)).rgb) + -9.377e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-8.714e-02, 1.652e-01, 1.136e-02, 2.822e-03) * s0_0;
	r += V4(-1.003e-01, -1.067e-01, 4.431e-02, -1.566e-01) * s0_1;
	r += V4(-6.198e-02, 2.745e-02, 2.198e-02, 8.239e-03) * s0_2;
	r += V4(1.450e-01, 2.881e-01, 3.743e-02, 6.520e-01) * s0_3;
	r += V4(8.223e-01, 3.443e-01, -8.763e-01, -5.840e-01) * s0_4;
	r += V4(-2.299e-01, -9.250e-02, -5.858e-04, 7.781e-02) * s0_5;
	r += V4(-1.492e-02, -9.237e-02, 1.410e-02, -2.287e-02) * s0_6;
	r += V4(-2.994e-01, -5.652e-02, 1.138e-02, 9.948e-02) * s0_7;
	r += V4(-1.718e-01, -6.417e-04, 1.643e-02, -6.988e-02) * s0_8;
	r += V4(-4.834e-04, -1.710e-02, 2.838e-02, -1.425e-04);
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
	r += mul(s0_0, M4(-1.165e-01, -2.429e-01, -1.034e-01, -1.494e-01, -3.505e-01, -2.891e-01, -1.318e-01, -2.822e-01, 6.631e-03, -2.607e-01, -1.772e-01, 8.756e-02, 5.378e-02, -6.673e-02, 2.744e-01, -5.750e-03));
	r += mul(s0_1, M4(-1.244e-01, 1.477e-01, -6.340e-01, 2.134e-01, 2.004e-01, -5.775e-01, 9.844e-02, 2.691e-01, 3.013e-02, 7.909e-02, -4.520e-02, 1.158e-01, 1.281e-01, 2.319e-01, 3.083e-02, 3.271e-01));
	r += mul(s0_2, M4(-2.969e-02, -5.384e-02, -1.184e-01, -6.589e-02, -6.093e-01, 3.198e-02, 2.405e-01, 3.610e-01, 1.155e-02, -1.225e-02, -1.353e-01, 7.516e-03, 2.225e-01, -1.149e-01, 1.849e-01, -5.817e-02));
	r += mul(s0_3, M4(-4.950e-01, -1.256e+00, 4.404e-01, 4.002e-01, -5.063e-01, -2.922e-01, -6.843e-01, 1.810e-01, -6.566e-02, 1.627e-01, -2.455e-03, 9.319e-02, 1.763e-01, 2.926e-01, -5.951e-04, -2.036e-01));
	r += mul(s0_4, M4(9.520e-01, 4.971e-01, -5.135e-02, -7.206e-01, 1.487e+00, -1.241e+00, 2.153e+00, -1.528e+00, -2.431e-01, -1.110e-01, -1.130e-03, 1.764e-01, 4.050e-01, -1.068e-01, -1.548e-01, -3.076e-01));
	r += mul(s0_5, M4(-2.270e-01, -2.298e-01, 5.641e-02, 1.464e-01, -3.713e-02, 3.327e-01, 5.912e-01, -1.164e+00, -9.131e-02, -4.422e-01, 3.806e-01, 7.904e-02, -5.813e-02, 2.840e-01, 2.324e-01, 1.289e-01));
	r += mul(s0_6, M4(-1.024e-01, -1.266e-01, -3.017e-01, -5.721e-02, 3.535e-01, -9.088e-02, 4.255e-01, -4.724e-01, 1.010e-01, 1.649e-01, -2.786e-04, -2.358e-02, -4.808e-02, -1.239e-01, -7.591e-02, 1.043e-01));
	r += mul(s0_7, M4(-3.408e-01, 6.009e-02, 6.491e-02, -3.631e-02, 4.287e-01, 6.297e-02, 6.466e-01, 8.322e-01, 1.347e-01, 4.102e-01, 1.580e-02, -5.916e-01, -4.557e-01, -2.133e-01, 7.319e-02, 5.658e-02));
	r += mul(s0_8, M4(1.322e-01, 2.957e-02, -1.183e-01, -4.419e-02, 3.440e-01, 1.188e-01, 6.869e-01, -4.369e-02, 1.733e-01, 3.566e-02, -6.354e-02, 3.703e-02, -1.091e-01, -1.764e-01, 4.832e-02, 7.828e-02));
	r += mul(s1_0, M4(3.367e-03, -3.136e-01, 1.997e-01, -6.522e-02, -1.897e-02, -2.482e-01, -1.858e-01, -2.072e-02, 1.889e-01, -3.058e-01, -1.717e+00, -1.714e-01, 6.117e-02, 3.492e-02, -1.654e-02, -1.260e-02));
	r += mul(s1_1, M4(-5.619e-02, 8.236e-02, -5.450e-01, 5.224e-02, 1.114e-01, -1.421e-01, -2.033e-01, 9.138e-02, -2.028e+00, -1.346e-01, -1.569e+00, 6.768e-01, 6.237e-02, 1.057e-01, 6.445e-02, 2.063e-01));
	r += mul(s1_2, M4(3.458e-02, -4.404e-02, 3.116e-02, -1.482e-02, 6.228e-02, 9.875e-02, -5.391e-02, 4.002e-02, 5.673e-01, -4.167e-01, 1.005e-01, 1.221e-01, 6.536e-02, 4.336e-02, 6.821e-02, 1.097e-03));
	r += mul(s1_3, M4(-5.253e-01, -1.254e+00, 1.033e+00, 4.890e-01, -2.824e-01, 4.463e-02, -2.559e-01, 3.162e-01, -1.105e+00, 2.087e+00, -4.510e+00, -2.357e-01, 2.500e-01, 8.213e-02, -2.031e-01, -1.777e-01));
	r += mul(s1_4, M4(2.939e-01, 5.371e-01, 4.333e-02, -8.176e-01, -2.062e-01, 1.685e-01, 3.166e-01, -3.996e-01, -4.322e+00, -3.141e+00, -4.383e+00, 2.141e+00, 5.012e-01, 2.607e-01, -7.719e-01, -5.385e-01));
	r += mul(s1_5, M4(-1.962e-01, -3.211e-02, 1.011e-01, 2.634e-01, -1.311e-01, -1.424e-01, -2.952e-02, -3.212e-01, 2.723e-01, 2.160e-01, -7.613e-01, 1.368e-01, -1.100e-01, 7.582e-01, -8.613e-03, 1.680e-02));
	r += mul(s1_6, M4(-8.357e-02, -1.414e-01, -1.561e-01, -1.764e-01, 4.030e-02, 2.491e-01, 9.513e-02, -1.460e-01, 7.104e-01, -6.656e-01, -4.663e-01, 4.499e-01, -3.939e-02, -1.161e-01, -2.222e-01, 4.733e-02));
	r += mul(s1_7, M4(-2.153e-01, 2.067e-02, 1.362e-01, 2.484e-01, 3.163e-01, 8.398e-02, 2.200e-01, 3.941e-01, -1.520e-01, 7.054e-01, -1.916e+00, -2.824e+00, -3.401e-01, -3.306e-01, 2.550e-01, 2.529e-01));
	r += mul(s1_8, M4(1.372e-01, 7.757e-02, -9.449e-02, -1.939e-01, 2.771e-01, -6.715e-02, 6.354e-02, 2.350e-02, 7.236e-01, -1.935e-01, 2.653e-01, 7.814e-01, -1.929e-01, -7.667e-03, 2.325e-01, 1.563e-01));
	r += V4(3.090e-02, -2.548e-03, 4.789e-04, 6.961e-04);
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
	r += mul(s0_0, M4(-2.500e-02, -1.490e-01, -1.665e-01, 1.832e-02, -8.180e-02, 5.708e-02, 4.268e-01, 1.127e-02, -6.887e-03, 1.700e-02, 1.839e-01, -1.478e-02, 2.334e-04, 2.425e-01, 2.536e-01, 5.177e-03));
	r += mul(s0_1, M4(2.009e-01, -4.134e-01, 3.700e-02, 1.328e-01, 4.702e-02, -5.432e-02, -2.182e-01, -2.430e-02, 3.129e-02, -6.751e-02, -2.428e-02, -1.474e-02, 4.995e-01, 2.463e-01, 9.257e-02, 1.902e-02));
	r += mul(s0_2, M4(8.670e-02, -1.920e-01, 3.730e-02, 5.135e-02, -1.216e-01, 2.980e-01, -2.645e-01, -4.874e-02, -2.096e-02, 4.075e-02, -1.615e-02, -4.315e-03, 9.702e-02, 8.473e-02, -2.396e-01, -1.199e-02));
	r += mul(s0_3, M4(-1.516e-01, 1.189e-01, -5.756e-01, 4.396e-02, -8.645e-02, 5.580e-03, 2.093e-01, -1.616e-02, -1.733e-02, -7.162e-02, -1.190e-01, -3.045e-02, 5.945e-02, -1.587e-01, 2.616e-01, -1.266e-01));
	r += mul(s0_4, M4(-5.774e-01, 4.972e-01, 7.301e-01, -5.259e-02, -1.748e-01, 4.092e-01, -4.598e-01, -1.550e-01, 2.963e-01, 1.010e-02, -6.822e-01, 6.940e-03, 9.531e-02, -1.806e-01, -1.802e-01, 4.766e-01));
	r += mul(s0_5, M4(-3.055e-01, 4.462e-01, 2.761e-03, -1.251e-01, 5.151e-01, -3.838e-01, -8.877e-02, 3.428e-01, 1.444e-01, -3.514e-01, 9.887e-02, -1.146e-02, 2.144e-01, -2.083e-01, -1.547e-01, -8.772e-03));
	r += mul(s0_6, M4(4.915e-02, -1.640e-03, -1.410e-01, 1.782e-01, -4.219e-02, 4.952e-02, 3.450e-01, 2.627e-01, 4.405e-03, 4.089e-02, 1.233e-01, 5.097e-02, -4.813e-02, -7.533e-03, 2.809e-02, -4.976e-02));
	r += mul(s0_7, M4(5.462e-01, -1.365e-01, 2.783e-02, -1.550e-01, 8.284e-02, -1.216e-01, 3.604e-02, -5.273e-01, -8.176e-02, 1.548e-02, 1.356e-02, -4.557e-01, -1.743e-01, 6.899e-02, 1.204e-01, 9.982e-03));
	r += mul(s0_8, M4(1.997e-01, -1.307e-02, 8.579e-03, -7.429e-02, -2.725e-01, -1.692e-01, -1.595e-01, 5.226e-01, 1.766e-02, -3.167e-03, 1.083e-01, -4.170e-02, -1.355e-01, 4.677e-02, -1.151e-02, -5.188e-02));
	r += mul(s1_0, M4(4.882e-02, 1.079e-02, -4.803e-01, -6.089e-02, 3.745e-02, -1.008e-02, 8.755e-02, 3.811e-02, -6.596e-03, -1.029e-01, 1.537e-01, 3.392e-02, 1.560e-02, -3.199e-02, -2.883e-02, 1.815e-02));
	r += mul(s1_1, M4(3.740e-01, 5.318e-02, -1.122e-01, 3.624e-02, -6.862e-02, -4.686e-02, -1.581e-02, 1.229e-02, -8.860e-02, 1.190e-03, -1.532e-02, -4.364e-02, -7.979e-01, 6.523e-01, 4.206e-01, -5.111e-03));
	r += mul(s1_2, M4(3.130e-02, -2.134e-01, 1.785e-01, -6.819e-02, -9.475e-03, 4.241e-02, -6.516e-02, 9.173e-03, -2.120e-02, 1.528e-01, -1.096e-01, 1.808e-02, -2.939e-01, 2.765e-01, -2.077e-01, -8.863e-02));
	r += mul(s1_3, M4(-5.932e-02, 1.473e-01, -8.262e-01, -3.023e-01, 5.263e-02, -1.086e-01, -7.402e-01, 6.282e-02, -8.144e-02, -2.197e-02, 2.134e-01, -6.881e-02, 4.931e-02, -3.275e-03, -6.205e-02, 5.693e-04));
	r += mul(s1_4, M4(1.694e-01, -1.148e-01, 3.746e-01, 3.545e-01, -1.854e-01, 2.284e-01, 5.013e-02, -9.216e-02, -1.924e-01, 1.835e-01, -2.494e-01, -6.825e-02, -9.351e-02, 2.804e-01, 1.558e-01, -5.255e-01));
	r += mul(s1_5, M4(-1.825e-01, -7.399e-02, 2.180e-03, -7.350e-02, -2.134e-01, 1.234e-01, 9.102e-02, -1.194e-01, 1.591e-01, -1.908e-01, 3.032e-02, 1.966e-01, -1.150e-01, 1.722e-01, -1.059e-01, -1.997e-01));
	r += mul(s1_6, M4(-9.071e-02, -7.537e-02, -2.109e-01, 5.056e-02, 8.617e-02, 3.293e-03, 1.285e-01, 1.887e-01, 6.390e-02, 6.958e-02, 2.564e-01, 1.682e-01, 1.207e-01, 3.725e-03, -3.600e-02, 6.667e-02));
	r += mul(s1_7, M4(1.406e-01, -1.232e-01, 1.606e-01, -1.029e-02, 8.130e-02, -7.495e-03, 1.213e-01, -2.672e-01, -1.965e-02, 3.212e-02, -3.391e-02, -5.215e-01, 1.382e-01, 7.396e-03, -1.647e-02, -1.626e-01));
	r += mul(s1_8, M4(2.032e-02, -1.221e-01, 8.088e-02, -3.983e-02, 4.310e-02, 4.702e-03, 7.639e-02, -3.633e-02, -1.364e-01, 1.711e-02, -2.947e-02, 9.302e-03, 5.579e-02, -2.245e-02, -1.016e-02, -7.483e-02));
	r += V4(-2.161e-03, 1.624e-03, 7.962e-04, 1.507e-03);
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
	r += mul(s0_0, M4(-3.308e-02, -5.164e-02, -2.853e-03, -6.238e-03, -6.429e-02, 6.574e-03, -1.747e-02, -4.570e-02, -4.832e-04, 3.107e-03, -3.033e-02, -1.041e-02, 1.010e-02, -4.355e-03, -1.501e-01, -1.056e-01));
	r += mul(s0_1, M4(-2.658e-02, 4.854e-02, -1.626e-01, -6.271e-02, -1.996e-02, 2.472e-02, 8.239e-02, 2.728e-02, -2.750e-02, 2.339e-03, -1.422e-02, -2.520e-02, 8.618e-02, 2.132e-01, 3.519e-01, -4.303e-01));
	r += mul(s0_2, M4(1.593e-02, 6.763e-02, -3.128e-02, 2.711e-02, 2.858e-02, -4.462e-02, 2.956e-02, -1.788e-02, -8.876e-04, -1.737e-02, -5.162e-02, 5.482e-02, 5.805e-02, -2.144e-01, 6.275e-02, -7.489e-02));
	r += mul(s0_3, M4(-1.806e-01, -4.269e-02, -2.102e-01, -2.976e-01, 1.062e-01, -3.104e-02, 8.603e-02, 8.089e-02, 3.872e-04, 1.164e-02, -4.212e-02, -4.975e-03, 5.405e-02, -8.289e-02, -6.325e-04, 1.629e-01));
	r += mul(s0_4, M4(-8.026e-01, 3.467e-01, -5.925e-02, -3.525e-01, 1.410e-01, 3.289e-02, -4.657e-01, 3.096e-01, 3.651e-02, 8.189e-02, -7.965e-02, 5.202e-03, 1.101e-01, 2.993e-01, -4.481e-02, 3.313e-01));
	r += mul(s0_5, M4(-4.593e-02, 3.820e-02, 2.831e-02, -3.966e-02, 1.446e-01, 9.389e-02, 1.190e-01, 8.463e-02, 2.646e-01, 1.022e-01, 1.772e-01, 1.256e-01, -1.195e-02, -7.424e-02, -2.050e-02, 4.580e-02));
	r += mul(s0_6, M4(1.001e-01, -6.869e-02, 5.325e-02, 1.464e-01, -7.475e-02, -9.664e-02, -9.175e-02, -1.189e-01, 1.784e-02, -1.788e-02, 4.971e-03, 4.510e-03, 9.774e-02, 1.027e-02, 1.707e-02, 4.404e-02));
	r += mul(s0_7, M4(8.543e-02, 2.632e-01, -9.146e-02, 1.702e-01, 3.253e-01, 3.545e-01, 3.975e-01, -1.290e-01, -3.581e-02, -2.203e-02, -4.015e-02, -3.279e-02, 1.140e-01, 2.862e-02, -8.218e-03, -2.153e-02));
	r += mul(s0_8, M4(3.165e-02, -1.082e-01, 4.853e-02, -6.371e-02, 1.524e-01, -9.388e-02, 3.738e-02, -4.231e-02, -8.482e-02, -1.080e-01, -4.203e-02, -5.194e-02, 3.068e-02, -8.271e-02, 8.614e-03, -1.972e-02));
	r += mul(s1_0, M4(-1.907e-01, -3.408e-02, -3.587e-01, -1.381e-01, 2.138e-02, -5.628e-02, 5.554e-03, 6.248e-03, -1.886e-03, 8.060e-03, 7.213e-02, 9.474e-03, -4.910e-02, 1.392e-02, 7.296e-02, -2.067e-01));
	r += mul(s1_1, M4(-9.277e-01, 3.351e-01, 4.044e-01, -1.152e+00, 3.228e-02, 5.350e-02, -3.237e-02, -1.236e-01, 8.179e-02, -7.662e-02, -4.189e-02, 4.954e-02, -7.818e-02, -1.850e-01, 1.024e+00, -3.291e-01));
	r += mul(s1_2, M4(1.333e-01, -6.230e-01, 2.094e-01, 2.980e-01, 3.423e-02, 1.838e-02, -2.566e-02, -8.635e-03, 3.290e-02, 7.791e-02, -4.750e-02, -2.223e-02, -1.917e-01, -6.426e-01, 1.538e-01, -4.932e-01));
	r += mul(s1_3, M4(-3.574e-02, 1.790e-02, 8.796e-02, -1.915e-01, -6.463e-02, -2.346e-02, -2.038e-01, -2.192e-01, 9.479e-04, 6.375e-02, -4.008e-03, 2.005e-02, -3.796e-02, -3.198e-02, -4.325e-02, 1.832e-02));
	r += mul(s1_4, M4(-2.724e-01, -3.026e-01, -1.415e-01, 3.870e-01, -7.557e-01, 3.442e-01, 6.615e-02, -2.558e-01, 7.863e-02, 8.576e-02, 9.409e-02, 1.655e-01, -8.232e-02, 1.306e-01, 3.559e-01, 3.858e-01));
	r += mul(s1_5, M4(-3.560e-02, -4.981e-01, 1.851e-01, -1.645e-01, -4.624e-03, -5.310e-02, 7.056e-02, 9.477e-04, -1.546e-01, 2.104e-01, 9.109e-02, -4.394e-01, 3.326e-02, 2.736e-01, -1.880e-01, 1.890e-01));
	r += mul(s1_6, M4(-2.374e-02, -6.276e-02, 2.974e-02, 5.062e-02, 5.041e-02, -2.125e-01, -3.577e-02, 1.013e-01, -6.052e-04, -2.947e-02, 7.068e-03, -2.672e-02, 5.517e-02, 5.883e-03, 4.325e-02, -7.059e-03));
	r += mul(s1_7, M4(1.223e-01, 5.238e-02, 6.978e-02, -4.651e-02, 4.092e-01, 3.049e-01, 5.757e-02, 1.261e-02, -2.895e-01, -1.772e-01, 1.188e-01, -2.092e-01, 2.668e-03, 6.315e-02, -2.529e-02, -3.876e-02));
	r += mul(s1_8, M4(-7.043e-03, -2.499e-01, 1.023e-01, -8.328e-03, -5.961e-02, -3.486e-01, 8.129e-02, -1.282e-01, -3.741e-02, 2.490e-01, -1.265e-01, 1.793e-01, 1.569e-02, -1.558e-01, -2.438e-02, -2.439e-02));
	r += V4(-8.904e-04, 3.195e-03, -2.395e-03, 3.933e-03);
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
	r += mul(s0_0, M4(-3.217e-02, -7.498e-03, 1.390e-02, 4.724e-02, -1.421e-02, 8.859e-02, -1.733e-01, 3.387e-02, 3.915e-02, -4.684e-02, -4.313e-02, -8.669e-02, 1.598e-02, 1.486e-02, -2.253e-02, -3.282e-03));
	r += mul(s0_1, M4(-1.982e-01, -3.003e-01, 1.606e-01, 1.091e-01, 2.979e-01, 6.075e-02, -2.548e-02, -1.783e-01, -4.534e-03, 3.133e-01, -6.955e-02, -1.392e-01, 1.607e-01, 2.168e-01, -6.956e-02, -1.558e-01));
	r += mul(s0_2, M4(-6.068e-02, 6.103e-02, -1.037e-02, 5.445e-02, 7.788e-02, -2.459e-02, 3.431e-02, -4.218e-02, 1.997e-01, 3.757e-03, 2.510e-01, -7.791e-02, 2.723e-03, -3.837e-02, -1.880e-02, -3.935e-02));
	r += mul(s0_3, M4(-2.669e-02, 4.659e-03, 1.679e-03, 2.923e-02, -1.758e-02, -4.005e-02, 8.039e-02, -1.973e-03, -1.086e-01, 1.812e-02, 1.337e-01, 1.753e-02, 8.130e-02, -1.323e-03, 6.958e-02, -7.600e-02));
	r += mul(s0_4, M4(-7.380e-02, -8.233e-02, -4.152e-01, -4.842e-01, -2.862e-01, -9.932e-02, 6.521e-02, -9.166e-03, 1.037e-01, -5.056e-01, -6.428e-01, 5.132e-01, 1.046e-03, 2.074e-01, 1.411e-01, 5.168e-01));
	r += mul(s0_5, M4(-1.152e-01, 9.644e-02, -5.172e-03, 1.354e-01, 2.437e-02, 1.391e-02, 1.062e-02, -1.239e-02, 1.490e-01, 6.630e-02, 2.110e-01, -2.017e-01, 1.432e-01, -2.134e-01, 9.454e-02, -1.323e-01));
	r += mul(s0_6, M4(-1.202e-02, 1.089e-02, -5.341e-02, -3.604e-02, -4.488e-03, 8.232e-03, 1.171e-03, 3.968e-03, 8.779e-02, 1.606e-01, 1.146e-01, 4.263e-02, 8.175e-03, -1.253e-02, 3.958e-02, 4.702e-02));
	r += mul(s0_7, M4(-8.563e-03, -1.566e-03, -3.419e-02, -6.233e-03, 5.769e-02, -2.462e-02, -4.178e-02, -2.484e-02, -5.797e-02, -4.139e-02, 2.278e-01, -1.376e-01, -3.572e-04, 1.741e-02, 4.261e-02, 3.917e-02));
	r += mul(s0_8, M4(4.337e-02, 1.526e-04, -1.815e-02, 2.211e-04, -1.215e-02, -6.112e-03, 3.593e-03, 1.606e-02, -4.213e-02, -1.983e-02, -4.852e-02, 1.489e-02, -4.241e-03, -1.117e-02, 1.678e-02, -6.097e-02));
	r += mul(s1_0, M4(-1.879e-02, 2.679e-02, -1.281e-02, 8.375e-02, -6.451e-02, 1.113e-01, -3.561e-02, -1.649e-01, 2.056e-02, 8.185e-05, 9.495e-03, -6.133e-03, -2.235e-02, -7.051e-04, 1.290e-02, -9.705e-03));
	r += mul(s1_1, M4(4.783e-02, -6.518e-02, 4.111e-02, -3.250e-02, 3.135e-01, 5.794e-03, 5.558e-02, -1.402e-01, 1.294e-02, 7.153e-02, -1.091e-01, -1.044e-02, 1.664e-01, 1.071e-01, -3.659e-02, -1.265e-03));
	r += mul(s1_2, M4(-2.490e-02, 8.147e-02, -3.160e-02, 3.106e-02, 6.065e-02, -1.787e-02, 1.827e-02, -2.239e-02, 1.864e-01, 6.576e-03, 2.044e-02, -1.382e-01, -1.772e-02, -2.230e-02, 1.741e-02, -2.054e-02));
	r += mul(s1_3, M4(9.410e-02, 2.337e-02, -1.006e-01, 2.167e-02, -8.116e-01, 7.485e-01, -6.430e-01, 8.185e-01, -2.670e-02, 2.094e-02, -2.814e-02, 2.486e-02, 1.549e-01, -4.077e-02, 2.373e-02, -8.640e-03));
	r += mul(s1_4, M4(-4.700e-01, -4.171e-01, 6.376e-02, -2.713e-01, -1.225e-01, -1.281e-02, 1.506e-01, -4.670e-03, -3.193e-01, -6.750e-02, -2.039e-02, 1.073e-01, 3.975e-01, 7.492e-01, -1.792e-01, -1.036e-01));
	r += mul(s1_5, M4(-5.690e-02, 1.352e-01, -4.815e-02, 1.929e-01, -3.342e-02, -5.112e-02, 2.053e-02, -5.458e-02, 1.483e-01, -3.369e-01, 2.119e-01, -1.440e-01, 9.226e-02, -1.765e-01, 5.970e-02, -1.008e-01));
	r += mul(s1_6, M4(-6.064e-02, 8.858e-03, 3.339e-02, -1.317e-01, 1.193e-01, -1.134e-01, -1.377e-01, 4.863e-02, 2.731e-03, 1.764e-03, 6.863e-03, 7.513e-04, -1.242e-04, 1.256e-02, -2.735e-02, 1.268e-01));
	r += mul(s1_7, M4(-8.068e-03, 4.655e-03, -6.202e-02, 1.492e-01, 4.015e-02, -6.167e-02, 1.568e-02, -2.280e-02, 4.284e-02, -7.790e-03, -1.431e-01, -1.294e-01, -1.159e-01, -1.175e-01, 1.851e-01, 3.130e-02));
	r += mul(s1_8, M4(5.011e-02, 4.782e-02, -8.364e-04, 1.015e-01, -1.541e-02, 2.439e-02, -2.136e-02, 3.180e-02, -3.662e-02, 4.006e-02, -1.936e-02, -5.969e-02, 3.751e-03, -8.172e-02, 3.333e-02, -1.780e-02));
	r += V4(2.536e-04, 2.312e-04, 1.039e-03, 1.194e-03);
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

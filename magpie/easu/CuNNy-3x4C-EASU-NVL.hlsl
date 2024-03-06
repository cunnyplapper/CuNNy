// CuNNy 3x4C CHROMA NVL
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
//!DESC CuNNy-3x4C-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(4.466e-01, 8.453e-01, 2.031e-01), O(INPUT, float2(x, y)).rgb) + -4.328e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(-1.868e-01, -7.515e-03, 6.075e-02, 5.390e-02) * s0_0;
	r += V4(-4.248e-01, -2.396e-02, -1.640e-01, -1.628e-01) * s0_1;
	r += V4(3.076e-02, 3.362e-02, -1.735e-01, -6.140e-02) * s0_2;
	r += V4(1.481e-01, -5.957e-01, -1.681e-02, 5.654e-01) * s0_3;
	r += V4(3.805e-01, 6.074e-01, -8.179e-02, -3.075e-01) * s0_4;
	r += V4(2.606e-02, -1.631e-02, -2.478e-02, 8.514e-02) * s0_5;
	r += V4(-2.652e-02, 3.062e-02, -9.097e-02, -1.280e-02) * s0_6;
	r += V4(7.674e-02, -2.394e-02, 3.342e-01, -6.235e-02) * s0_7;
	r += V4(-3.650e-02, -6.663e-03, 1.652e-01, -3.508e-02) * s0_8;
	r += V4(-8.022e-03, 2.603e-05, 4.373e-03, 1.922e-02);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-conv1
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
	r += mul(s0_0, M4(-6.385e-03, -1.028e-01, 9.259e-03, 3.050e-02, 8.572e-02, 2.820e-01, -3.584e-01, -1.104e-02, -1.153e-02, -1.859e-01, 2.256e-01, -8.716e-05, 1.250e-01, 1.472e-01, -2.855e-01, -4.274e-02));
	r += mul(s0_1, M4(-6.608e-03, 1.953e-01, -3.988e-02, -4.273e-02, -3.552e-01, -2.061e-01, -7.480e-04, -8.021e-02, 1.999e-02, -4.466e-02, -7.371e-02, 2.241e-02, -1.411e-01, -3.914e-01, 2.710e-01, 3.143e-02));
	r += mul(s0_2, M4(-5.399e-02, 2.407e-02, -9.242e-02, -1.756e-02, 6.045e-02, 7.637e-03, 3.798e-02, -4.588e-02, 7.370e-03, -2.501e-02, 4.173e-02, -9.964e-03, 2.022e-01, 1.987e-01, 4.641e-02, 6.447e-02));
	r += mul(s0_3, M4(1.000e-01, -2.367e-02, -1.347e-01, 2.316e-02, 3.355e-01, -2.706e-02, -7.546e-02, 1.043e-01, -8.681e-02, 3.057e-01, 2.754e-02, -4.140e-01, 3.002e-01, -4.062e-02, -1.419e-02, 1.743e-01));
	r += mul(s0_4, M4(-4.322e-02, -2.912e-02, 1.148e-01, 1.739e-01, 2.270e-01, -5.548e-01, 1.969e-01, -2.855e-01, -2.006e-01, -1.324e-01, -4.792e-01, -3.914e-02, -4.651e-01, 3.200e-01, 6.337e-01, -2.808e-01));
	r += mul(s0_5, M4(1.606e-01, -1.000e-01, 1.018e-01, 5.798e-02, -6.220e-03, 3.621e-01, 6.777e-01, 9.247e-02, -3.305e-02, 7.063e-03, 1.694e-01, -8.187e-02, 7.580e-03, -9.742e-02, -4.826e-01, 8.269e-02));
	r += mul(s0_6, M4(-1.293e-01, -2.271e-01, 3.678e-03, -1.753e-01, -3.264e-02, -2.435e-01, 1.203e-02, 2.348e-01, 7.093e-02, 8.125e-02, 8.260e-02, -2.220e-01, 4.485e-03, -1.776e-01, -1.190e-02, 2.877e-01));
	r += mul(s0_7, M4(-7.637e-01, 8.722e-02, 2.984e-01, -8.460e-01, -4.441e-01, -1.086e-01, 1.020e-01, -5.224e-02, -5.000e-03, -9.099e-02, -1.208e-01, 6.827e-02, -1.425e-01, 1.097e-01, -9.726e-02, -2.495e-01));
	r += mul(s0_8, M4(-1.682e-01, 3.740e-02, -9.602e-02, -5.839e-02, 3.235e-01, -7.528e-03, -7.517e-02, 1.782e-01, -1.775e-02, 3.791e-02, -2.456e-02, 4.943e-02, -7.781e-02, -6.025e-02, -3.098e-02, -3.262e-02));
	r += mul(s1_0, M4(-4.627e-03, -2.235e-01, 1.226e-01, 2.891e-02, 9.251e-02, 2.904e-01, -2.669e-01, -3.522e-02, 4.587e-02, -3.780e-02, -2.793e-03, 1.286e-01, 1.005e-01, 2.291e-01, -3.568e-01, -1.050e-02));
	r += mul(s1_1, M4(3.188e-02, 3.328e-01, -1.127e-01, -5.213e-02, -2.697e-01, -2.476e-01, 1.553e-01, 4.673e-02, 2.855e-02, -4.848e-02, -7.175e-02, 8.620e-02, -1.130e-01, -4.532e-01, 2.121e-01, 3.872e-02));
	r += mul(s1_2, M4(-7.243e-02, 8.862e-02, -2.033e-02, -3.876e-02, 1.626e-01, 1.806e-01, -1.415e-01, 3.808e-02, -1.728e-02, -2.824e-02, -1.168e-02, -5.683e-03, 1.517e-01, 9.956e-02, -1.299e-01, -3.717e-02));
	r += mul(s1_3, M4(1.405e-01, 1.614e-01, 1.808e-02, 1.970e-02, 3.436e-01, 4.087e-02, -2.601e-02, 5.423e-01, -1.342e-01, 2.534e-01, 1.450e-01, 4.626e-02, 2.736e-01, -4.056e-02, 5.796e-02, -3.474e-02));
	r += mul(s1_4, M4(-1.215e-01, -5.365e-01, -1.804e-01, 1.385e-01, 2.722e-01, -9.603e-01, -1.224e-01, -2.493e-02, -1.178e-01, -1.344e-01, -1.308e-01, -2.434e-02, -5.027e-01, 2.211e-01, 6.642e-01, -4.651e-01));
	r += mul(s1_5, M4(1.479e-01, 3.497e-03, -4.714e-02, 5.628e-02, -5.524e-02, -8.281e-02, -3.857e-01, 7.550e-02, -4.386e-03, -1.012e-02, 6.141e-02, -1.163e-01, 4.162e-02, 3.000e-01, -4.862e-03, 1.662e-01));
	r += mul(s1_6, M4(-7.015e-02, -1.731e-02, 1.431e-02, -2.976e-01, 5.016e-03, -2.154e-01, 5.704e-02, 3.053e-01, 7.306e-03, -1.447e-02, -2.172e-02, -1.724e-02, -2.297e-02, -1.613e-01, -5.143e-02, 2.900e-01));
	r += mul(s1_7, M4(-9.863e-01, 3.142e-02, 2.731e-01, -1.323e-01, -6.465e-01, 5.882e-02, 2.121e-01, -5.762e-01, -7.690e-02, -1.707e-02, -7.393e-02, -4.247e-02, -7.965e-02, 5.094e-02, 1.088e-02, -2.595e-02));
	r += mul(s1_8, M4(-6.402e-02, 6.706e-03, -3.537e-02, 1.305e-01, 1.953e-02, -6.666e-02, -4.703e-02, -3.566e-03, -2.499e-02, -6.696e-04, 6.177e-02, 2.215e-02, 1.890e-01, 3.756e-04, -1.380e-01, 1.905e-01));
	r += V4(-4.137e-03, -3.440e-04, -5.301e-04, -2.578e-03);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-conv2
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
	r += mul(s0_0, M4(-1.232e-01, -1.150e-01, -2.355e-02, 3.347e-02, 1.116e-01, -5.629e-02, -4.114e-02, -6.942e-02, 2.006e-01, -2.633e-02, -4.173e-02, 5.615e-02, 2.787e-01, 2.505e-01, -1.785e-01, -5.055e-02));
	r += mul(s0_1, M4(1.470e-01, -9.678e-02, -5.958e-01, -1.055e-01, 1.818e-01, -5.435e-02, 3.501e-03, -2.566e-01, 4.077e-02, 1.045e-01, -1.005e-01, -1.565e-01, -5.953e-01, -1.578e-01, -1.559e-02, 4.197e-01));
	r += mul(s0_2, M4(4.226e-02, -3.704e-02, -1.790e-01, -2.261e-02, -2.342e-01, 3.178e-02, -2.217e-01, -9.691e-02, -1.428e-01, 5.084e-02, 1.950e-02, -1.115e-02, -3.798e-01, 1.998e-01, 3.736e-01, 3.046e-01));
	r += mul(s0_3, M4(-4.404e-01, -2.705e-01, 2.443e-01, 2.114e-01, 1.749e-02, -9.447e-02, -4.820e-02, 3.413e-02, -6.958e-02, 5.848e-02, 1.876e-01, -1.770e-02, 5.673e-02, 1.610e-01, -2.761e-03, -1.090e-01));
	r += mul(s0_4, M4(3.124e-01, 4.272e-01, 5.785e-01, -2.881e-01, 5.785e-01, -3.391e-01, -2.998e-01, -2.478e-01, -4.561e-01, 3.491e-01, 6.443e-01, 5.773e-01, 3.025e-01, 4.296e-01, -1.760e-01, 2.004e-01));
	r += mul(s0_5, M4(1.861e-02, -1.804e-01, -5.268e-02, -5.275e-02, -1.576e-01, 3.323e-01, -1.905e-01, -1.626e-01, 3.426e-02, 2.001e-01, 1.365e-01, 1.003e-01, -1.657e-01, -3.252e-01, -3.074e-01, -1.039e-01));
	r += mul(s0_6, M4(-4.617e-02, -2.462e-02, 3.551e-02, 3.314e-02, 2.936e-02, -8.375e-02, -1.014e-01, 4.215e-02, 1.261e-02, 8.872e-02, 1.357e-01, -3.579e-02, 4.099e-02, 2.597e-02, -2.679e-02, 5.296e-02));
	r += mul(s0_7, M4(4.957e-02, -4.063e-02, -2.459e-02, 1.786e-01, -4.516e-01, -2.967e-01, 7.825e-02, 2.029e-01, -1.379e-01, 1.137e-01, 3.096e-01, 2.738e-01, -1.735e-01, 2.381e-01, 9.636e-02, -6.184e-02));
	r += mul(s0_8, M4(1.298e-02, 1.512e-02, -7.785e-03, 8.478e-02, 7.647e-02, 3.070e-01, 3.771e-01, 1.255e-01, -4.174e-02, -7.648e-03, -6.615e-02, -1.500e-03, -9.463e-02, -8.145e-02, 3.864e-02, -3.398e-01));
	r += mul(s1_0, M4(-4.445e-01, 1.727e-01, 2.586e-01, 3.305e-01, 1.851e-01, 3.876e-02, -8.144e-02, -7.216e-02, 6.541e-02, -8.696e-02, -2.447e-02, -6.134e-04, 7.748e-02, -4.777e-02, -1.461e-02, 3.234e-02));
	r += mul(s1_1, M4(-4.681e-01, -9.424e-02, 8.723e-02, 4.966e-01, 2.988e-01, 1.286e-01, -2.822e-02, -1.802e-01, 4.170e-01, 5.576e-02, -2.588e-01, -2.884e-01, 6.630e-01, -1.862e-01, -1.380e-01, -1.949e-01));
	r += mul(s1_2, M4(1.567e-01, -3.365e-01, 1.177e-01, 1.040e-01, -8.079e-02, 9.957e-02, 1.678e-01, 5.842e-02, -3.779e-01, -5.801e-02, -1.057e-01, -1.597e-01, 2.435e-01, 4.263e-01, -2.413e-01, -1.043e-01));
	r += mul(s1_3, M4(-3.683e-01, 9.377e-02, 1.457e-01, 1.971e-01, -5.603e-02, 7.788e-02, -2.872e-02, 5.191e-02, -2.724e-01, -7.651e-02, 5.371e-02, 6.315e-02, -6.702e-02, 1.245e-02, -1.056e-02, -3.929e-02));
	r += mul(s1_4, M4(1.408e-01, 2.109e-01, 1.990e-01, -7.325e-01, 1.929e-01, 4.828e-02, 5.012e-02, 9.710e-03, -8.220e-02, -4.591e-02, -1.111e-01, 1.013e-01, 2.430e-01, -3.346e-01, -4.561e-02, 2.710e-02));
	r += mul(s1_5, M4(-1.361e-01, -6.691e-01, -2.962e-01, -2.589e-01, -4.506e-01, 2.013e-01, 6.414e-01, -2.879e-03, 3.147e-02, 2.340e-01, -2.405e-01, -2.447e-01, 1.617e-01, 5.778e-01, 2.826e-02, 2.059e-01));
	r += mul(s1_6, M4(7.710e-03, 7.971e-02, -1.033e-01, -8.110e-02, 3.595e-02, 1.740e-01, -6.715e-02, -2.008e-02, 1.417e-02, -7.253e-02, 1.001e-01, -1.901e-02, 3.894e-02, -1.930e-02, 1.744e-03, -1.062e-02));
	r += mul(s1_7, M4(4.990e-02, 3.895e-02, -1.057e-01, -3.103e-02, -5.393e-01, -6.485e-02, 1.636e-01, 1.910e-01, -2.338e-02, -7.194e-02, 8.147e-02, 1.500e-01, -1.102e-01, -1.230e-01, 7.265e-02, 9.477e-02));
	r += mul(s1_8, M4(-2.109e-02, -1.234e-01, -1.880e-01, -8.640e-02, 7.905e-02, 1.894e-02, 4.449e-01, 3.115e-01, -1.736e-01, 1.916e-01, 2.180e-01, -2.284e-02, 7.878e-02, 1.242e-01, 1.161e-01, -2.162e-02));
	r += V4(-9.245e-03, 6.567e-04, 4.481e-03, 3.000e-03);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-conv3
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
	r += mul(s0_0, M4(-2.392e-02, 5.523e-02, -8.130e-02, -1.305e-02, 9.286e-03, -9.643e-02, -1.392e-01, 6.812e-02, -2.101e-02, 6.972e-02, 1.750e-01, -1.982e-02, -8.325e-02, 6.218e-02, -3.269e-02, -1.939e-02));
	r += mul(s0_1, M4(3.730e-02, -1.241e-01, -8.803e-02, -4.850e-02, 1.668e-01, -2.114e-01, 6.036e-02, -1.947e-02, 4.111e-02, 1.168e-01, 2.526e-01, 4.698e-02, -4.272e-02, -2.284e-01, -3.916e-01, 6.322e-04));
	r += mul(s0_2, M4(-4.382e-02, 1.816e-02, 3.882e-03, -6.879e-03, 4.410e-02, -6.240e-02, 3.735e-03, -5.237e-02, 4.533e-02, -6.124e-02, 1.069e-01, -3.375e-02, -2.749e-02, 9.895e-03, -7.199e-02, 4.394e-02));
	r += mul(s0_3, M4(-9.922e-02, 6.075e-02, 2.086e-01, 1.369e-02, -1.010e-01, -1.450e-01, 1.376e-01, 1.218e-01, 4.498e-02, -7.103e-02, -9.253e-02, 1.022e-02, -5.583e-04, 1.996e-01, 7.042e-03, -4.966e-02));
	r += mul(s0_4, M4(-3.688e-01, -1.614e-01, -5.136e-01, 8.580e-02, -4.971e-01, -8.590e-02, -1.597e-01, -1.587e-01, 3.339e-02, 2.077e-01, -3.398e-01, 4.840e-02, -1.421e-01, -3.351e-01, 3.959e-01, 1.353e-01));
	r += mul(s0_5, M4(9.167e-02, -5.196e-03, -1.222e-01, -1.218e-01, -8.836e-02, -3.987e-03, -7.263e-02, 6.595e-03, -3.053e-02, -5.037e-02, 3.552e-02, -1.749e-03, -1.679e-02, 5.438e-02, 6.378e-02, -5.764e-02));
	r += mul(s0_6, M4(-3.377e-02, -2.744e-01, -2.550e-01, 3.753e-02, -6.427e-02, 2.655e-02, -4.312e-02, 9.939e-02, 9.887e-03, -4.866e-02, 2.483e-02, 1.786e-03, -3.479e-02, 4.500e-02, 4.966e-02, -2.920e-03));
	r += mul(s0_7, M4(-2.254e+00, 1.465e+00, -3.395e-01, 2.479e+00, 4.873e-02, -9.883e-02, -6.508e-03, -1.197e-01, 4.762e-02, 1.255e-01, -1.557e-01, 1.447e-02, 2.885e-02, -5.388e-02, 1.620e-03, 3.773e-02));
	r += mul(s0_8, M4(7.295e-02, -1.154e-01, -1.178e-01, 4.075e-02, 9.537e-03, -2.237e-02, -6.852e-02, 2.081e-02, -1.687e-02, -4.699e-02, 4.798e-02, -3.382e-02, -1.878e-03, 7.691e-03, -1.193e-02, -1.776e-02));
	r += mul(s1_0, M4(-4.154e-03, 6.213e-02, 5.514e-02, -1.290e-02, 1.401e-02, -2.299e-02, -9.038e-03, 2.136e-02, -1.135e-02, 3.040e-03, 3.076e-02, -1.563e-02, -4.961e-02, 7.642e-02, -2.755e-03, -7.234e-03));
	r += mul(s1_1, M4(-8.226e-03, -4.399e-02, 3.429e-02, -1.426e-02, 1.704e-01, -1.055e-01, -1.558e-01, 4.631e-02, -1.068e-01, 1.259e-01, 4.975e-02, -4.552e-03, 5.801e-02, -1.333e-01, -4.697e-02, 3.507e-02));
	r += mul(s1_2, M4(2.786e-03, 1.757e-02, -7.445e-03, -2.296e-03, 8.608e-02, -2.441e-01, -7.233e-02, -3.557e-02, -4.432e-02, 2.668e-02, -1.678e-02, 6.036e-03, 8.560e-02, 1.085e-02, 2.283e-02, -2.960e-02));
	r += mul(s1_3, M4(6.402e-03, 3.736e-02, -1.536e-02, -4.013e-03, -2.612e-03, -5.622e-03, 6.422e-02, -2.692e-02, -5.901e-02, -8.863e-02, 1.252e-01, 3.719e-02, -1.063e-01, 2.231e-01, 5.786e-02, 3.070e-02));
	r += mul(s1_4, M4(1.981e-02, 5.549e-02, -2.766e-02, 4.851e-02, 1.525e-01, -1.806e-01, 2.490e-01, -6.220e-01, 1.199e-01, 7.890e-01, 1.785e-01, -7.500e-02, -2.764e-01, -5.449e-01, -5.410e-01, 4.309e-02));
	r += mul(s1_5, M4(6.714e-02, -1.087e-01, -3.141e-02, -2.067e-02, -1.416e-01, -1.971e-01, 2.049e-01, -1.818e-01, 5.744e-02, -5.025e-02, -1.071e-01, -6.701e-02, -9.684e-02, 1.165e-01, 3.388e-01, -1.065e-01));
	r += mul(s1_6, M4(2.507e-02, 1.436e-02, 6.422e-02, -3.559e-04, -8.738e-03, -1.898e-02, -4.223e-02, -6.726e-03, -1.139e-02, -2.509e-02, -1.727e-01, 3.547e-02, 1.267e-02, 4.397e-02, -1.540e-01, -3.246e-02));
	r += mul(s1_7, M4(-1.655e-02, 1.129e-01, 1.146e-01, 2.931e-02, -4.330e-03, 2.761e-02, 2.033e-02, 6.164e-02, 8.385e-02, 4.707e-02, -1.807e-01, -1.080e-02, 4.794e-01, 3.309e-01, -1.860e-01, 1.228e-01));
	r += mul(s1_8, M4(-2.142e-02, -5.815e-02, 2.025e-01, -9.259e-02, 9.714e-03, -6.608e-02, 1.440e-01, -7.233e-02, -6.811e-02, 3.798e-02, -1.886e-01, 4.795e-02, 1.431e-01, 9.597e-02, -8.877e-02, -4.892e-02));
	r += V4(-3.029e-03, -2.896e-04, -6.929e-03, 2.616e-03);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-out
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
	r += mul(s0_0, M4(7.442e-03, 8.813e-02, -1.079e-02, 6.763e-02, -3.444e-02, 5.092e-03, -8.276e-03, 8.844e-03, 6.506e-03, -6.797e-02, 3.139e-02, -9.820e-03, 8.708e-04, 1.838e-02, -2.248e-02, 2.753e-02));
	r += mul(s0_1, M4(6.770e-03, -9.285e-02, 9.564e-02, -8.066e-02, -1.199e-01, -1.087e-02, 3.750e-02, -9.057e-02, 9.226e-02, 1.488e-01, 1.661e-02, 3.543e-02, -1.071e-01, -1.713e-01, 1.024e-01, -6.237e-02));
	r += mul(s0_2, M4(2.180e-02, -7.954e-03, -1.283e-02, 2.248e-03, 1.021e-03, 2.165e-02, -4.645e-02, 6.274e-02, -3.054e-02, -6.045e-02, 1.947e-02, 3.102e-02, 2.473e-02, 4.031e-02, 3.441e-03, 3.621e-02));
	r += mul(s0_3, M4(-1.013e-01, 6.044e-02, -2.110e-01, -2.022e-02, -9.705e-03, 2.394e-02, -1.210e-02, 1.666e-02, -3.021e-02, -8.361e-02, -4.272e-02, 1.812e-01, -6.113e-02, 4.944e-02, -4.554e-02, 2.691e-02));
	r += mul(s0_4, M4(1.946e-01, -3.373e-01, 2.763e-02, -3.669e-01, 7.534e-01, -1.685e-01, 4.174e-01, -3.625e-02, 5.998e-01, 4.978e-01, -7.169e-01, -8.692e-01, -1.265e-01, -2.460e-02, -3.117e-01, -1.477e-01));
	r += mul(s0_5, M4(-2.873e-02, 2.198e-01, 8.913e-02, 1.165e-01, -1.071e-01, 1.798e-02, -6.753e-02, -7.052e-02, -1.056e-02, 1.135e-01, 9.648e-02, -1.053e-02, 6.043e-02, 3.520e-02, 7.943e-02, 7.472e-02));
	r += mul(s0_6, M4(-1.230e+00, -1.319e-01, 1.334e+00, 7.202e-03, -1.678e-02, -1.420e-02, -2.362e-02, -2.089e-03, -2.261e-02, -1.078e-02, 6.111e-02, -5.128e-02, -7.919e-03, 1.089e-02, 7.320e-02, 6.665e-02));
	r += mul(s0_7, M4(-7.510e-02, -1.182e+00, 4.217e-01, 1.710e+00, -9.450e-02, -1.459e-02, -2.460e-02, -8.569e-02, -9.365e-02, -1.189e-01, 9.750e-02, 1.841e-01, 3.518e-02, -2.252e-02, 1.392e-01, 8.911e-02));
	r += mul(s0_8, M4(2.942e-02, 1.760e-01, -2.478e-02, -3.287e-02, 7.777e-03, 7.127e-03, 6.947e-03, -1.333e-01, 2.716e-05, -1.960e-02, 3.939e-03, -1.629e-02, -2.168e-02, -1.618e-03, -5.654e-03, 4.950e-02));
	r += mul(s1_0, M4(-2.583e-02, 4.139e-02, -4.580e-02, 2.880e-02, -9.986e-02, -1.167e-02, 2.746e-03, -8.144e-03, 1.955e-02, 3.499e-03, 2.570e-02, -8.615e-03, -1.536e+00, 1.315e+00, 5.924e-02, 1.347e-01));
	r += mul(s1_1, M4(-1.160e-01, -2.920e-01, 5.320e-02, -4.100e-02, -2.283e-02, -1.265e-01, 4.264e-02, -2.807e-02, -7.484e-04, -1.401e-02, 3.535e-03, 4.836e-02, 2.431e-01, -2.978e-01, 1.422e-01, 1.144e-03));
	r += mul(s1_2, M4(2.964e-02, 4.514e-02, 3.285e-02, 3.076e-02, 1.309e-02, 9.052e-03, -8.436e-03, 1.089e-03, -6.097e-03, -1.174e-03, 1.173e-02, -1.583e-02, -7.175e-02, 2.933e-03, 2.284e-02, -4.855e-02));
	r += mul(s1_3, M4(-1.087e-01, 8.643e-02, -1.044e-01, 7.364e-02, 1.577e-01, -9.841e-02, 4.379e-03, -4.217e-02, -4.546e-02, -2.076e-02, 5.335e-02, 4.201e-02, -2.564e-01, 2.934e-01, -1.798e+00, 1.649e+00));
	r += mul(s1_4, M4(2.774e-01, -1.761e-01, 1.617e-01, -4.118e-01, 9.454e-02, 5.522e-01, -4.599e-02, 1.480e-01, 2.223e-02, -2.309e-02, -1.774e-01, -1.949e-01, -4.603e-02, -1.009e-01, -1.336e-01, -1.963e-01));
	r += mul(s1_5, M4(-3.403e-02, 5.772e-02, -2.959e-02, 1.587e-01, -3.055e-02, -1.824e-02, -2.985e-02, 3.425e-02, -1.106e-02, 1.387e-02, -4.547e-03, 1.050e-02, -5.066e-02, 1.726e-02, -3.761e-02, -1.002e-02));
	r += mul(s1_6, M4(-1.108e-02, 6.749e-04, 6.906e-02, 6.630e-02, -1.994e-02, -2.168e-02, -1.047e-01, -1.053e-01, 1.339e-02, 1.543e-02, -1.373e-02, 5.962e-03, 3.278e-02, 3.600e-03, 2.797e-01, -1.280e-01));
	r += mul(s1_7, M4(-9.348e-03, -2.428e-02, 1.214e-01, 8.537e-02, -9.253e-02, -8.737e-02, -7.945e-02, 1.310e-02, -2.870e-02, 3.641e-03, 6.139e-02, 7.835e-02, 5.311e-02, 2.240e-02, 1.509e-01, 1.669e-03));
	r += mul(s1_8, M4(-2.931e-04, 5.850e-03, 7.187e-03, 2.798e-02, 5.487e-03, -1.588e-02, 4.833e-06, -8.142e-02, 1.099e-02, -1.389e-02, 6.552e-03, -2.365e-02, 4.383e-02, -2.252e-02, -1.895e-02, 5.820e-03));
	r += V4(1.559e-03, -3.139e-04, 1.652e-03, -4.528e-04);
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
//!DESC CuNNy-3x4C-CHROMA-NVL-shuffle
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

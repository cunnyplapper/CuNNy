// CuNNy 1x4C CHROMA NVL DN
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
//!DESC CuNNy-1x4C-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(2.808e-01, 5.176e-01, 1.572e-01), O(INPUT, float2(x, y)).rgb) + -1.498e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(3.536e-02, -4.283e-02, 1.097e-02, 6.262e-03) * s0_0;
	r += V4(3.761e-01, 4.868e-02, -2.691e-02, 1.420e-02) * s0_1;
	r += V4(2.179e-02, -1.918e-02, 1.398e-02, -1.658e-02) * s0_2;
	r += V4(2.100e-02, -1.752e-02, 5.996e-01, -4.482e-01) * s0_3;
	r += V4(-5.840e-01, 5.840e-01, -5.762e-01, -7.438e-02) * s0_4;
	r += V4(8.754e-02, 2.937e-02, -3.050e-02, 5.782e-03) * s0_5;
	r += V4(2.093e-02, -5.695e-02, -4.089e-02, 4.983e-01) * s0_6;
	r += V4(-2.000e-02, -6.007e-03, 4.531e-02, 6.103e-03) * s0_7;
	r += V4(4.065e-02, -2.237e-02, 1.260e-02, 1.113e-02) * s0_8;
	r += V4(-1.358e-02, -3.934e-01, 8.040e-03, -1.206e-02);
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
//!DESC CuNNy-1x4C-CHROMA-NVL-DN-conv1
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
	r += mul(s0_0, M4(4.040e-02, 8.554e-02, -7.113e-02, 6.578e-02, -1.664e-01, -2.456e-01, -1.541e-01, -1.831e-01, -4.285e-02, 3.001e-02, 5.804e-02, 1.487e-02, -2.832e-03, -4.173e-02, 1.420e-02, 7.404e-02));
	r += mul(s0_1, M4(9.157e-02, 8.931e-02, 2.012e-02, -4.175e-02, -6.700e-01, -7.001e-01, 1.055e-01, 4.681e-02, -1.147e-01, 2.220e-01, 2.427e-01, 1.538e-01, 4.785e-02, 3.739e-01, -1.389e-01, -4.867e-02));
	r += mul(s0_2, M4(2.895e-02, 1.621e-02, -5.849e-02, 1.200e-02, 1.164e-01, 2.135e-01, -2.125e+00, -2.575e-02, 2.472e-01, -2.390e-02, -2.881e-01, -1.040e-01, 4.156e-01, 6.375e-01, -4.835e-01, 4.733e-02));
	r += mul(s0_3, M4(2.777e-01, 4.191e-01, -2.978e-01, -2.290e-01, 7.262e-01, -1.164e-01, -7.001e-01, -7.474e-02, -1.082e-01, -3.224e-02, 1.638e-01, 5.064e-02, -7.229e-02, -1.385e-01, 1.929e-01, 8.955e-02));
	r += mul(s0_4, M4(3.117e-01, -5.529e-01, -1.054e+00, -5.917e-01, 1.731e+00, 2.515e-01, -1.280e+00, -4.991e-01, -7.246e-01, 3.154e-01, 3.151e-01, 2.904e-01, -3.440e-01, 5.206e-02, 2.646e-01, -2.241e-01));
	r += mul(s0_5, M4(2.104e-01, 5.809e-02, -5.306e-01, -1.661e-01, -4.330e-01, -4.828e-01, -1.385e-01, 8.246e-01, 1.753e-01, -2.165e-01, -2.564e-01, -3.252e-01, -2.178e-01, -7.530e-01, -1.292e-01, 7.192e-02));
	r += mul(s0_6, M4(-2.652e-01, -1.757e-03, 2.884e-01, -4.752e-02, 5.385e-01, 8.523e-02, -4.144e-01, -1.665e-01, 2.193e-02, 1.491e-02, -1.450e-01, -3.420e-02, -4.009e-03, -2.248e-02, -1.065e-02, 1.293e-02));
	r += mul(s0_7, M4(-4.990e-01, 3.416e-01, 6.620e-01, -2.392e-01, 8.948e-01, -1.306e-01, -6.622e-01, -6.765e-02, -2.861e-01, -1.589e-01, 2.698e-01, 2.559e-02, -6.283e-02, -2.359e-03, 9.643e-02, -2.245e-02));
	r += mul(s0_8, M4(5.673e-02, -2.410e-01, -6.020e-02, -1.509e-01, -3.255e-01, -7.106e-02, 1.208e-01, 2.008e-01, -2.637e-03, 8.879e-02, 6.933e-03, -2.568e-01, -1.728e-02, 2.125e-02, -9.437e-03, 1.096e-02));
	r += mul(s1_0, M4(-5.238e-02, -6.518e-02, 1.240e-01, 3.641e-02, 1.519e-01, -1.090e-01, -1.891e-01, -7.716e-02, 2.391e-02, -4.603e-02, -1.818e-02, 2.238e-02, 2.875e-02, -4.236e-02, 3.029e-02, 2.705e-02));
	r += mul(s1_1, M4(7.739e-02, 8.765e-02, -8.789e-02, -2.593e-02, -2.014e-01, 2.959e-02, 1.371e-01, 2.046e-01, -9.636e-02, -1.515e-01, 2.427e-01, 4.218e-02, 3.820e-01, 1.950e-01, -3.252e-01, -2.398e-01));
	r += mul(s1_2, M4(-2.605e-02, -1.969e-02, 2.159e-03, -1.208e-02, 4.114e-02, 1.225e-01, 6.840e-02, -9.614e-02, 1.025e-01, -6.092e-02, 3.185e-01, -4.592e-02, 2.734e-01, -2.573e-01, -2.176e-01, -4.838e-01));
	r += mul(s1_3, M4(-5.390e-03, 1.323e-01, -1.481e-01, 3.625e-02, 1.793e-01, -2.051e-01, -2.510e-01, 7.581e-02, 1.814e-03, -5.945e-02, 8.094e-02, -3.904e-02, -3.761e-02, -1.101e-01, 1.880e-01, 6.909e-02));
	r += mul(s1_4, M4(-7.096e-02, -1.887e-01, 1.669e-01, 8.619e-02, -1.595e-01, 3.271e-01, 3.500e-01, -1.810e-01, 1.197e-01, 6.649e-02, -3.174e-01, -4.407e-02, -5.996e-02, 1.626e-01, -1.028e-01, -9.268e-02));
	r += mul(s1_5, M4(8.541e-02, 1.657e-02, 1.004e-02, -1.377e-01, -2.578e-02, -1.411e-01, -1.003e-01, 9.425e-02, -1.024e-02, 3.572e-01, 4.151e-01, 5.271e-02, 1.532e-01, 2.838e-02, -9.585e-02, 4.501e-02));
	r += mul(s1_6, M4(1.033e-01, 7.854e-02, 6.725e-02, -1.919e-01, 2.774e-01, 2.758e-02, -2.147e-01, 6.728e-03, 1.163e-01, 6.102e-02, -2.496e-01, -5.040e-02, 3.528e-02, -1.746e-03, -4.425e-02, 9.858e-03));
	r += mul(s1_7, M4(-1.303e-01, 1.890e-01, 1.248e-01, -8.943e-03, -2.329e-01, -4.892e-02, 2.115e-01, -4.920e-02, 1.184e-01, 1.959e-02, -3.504e-02, -6.178e-02, 1.049e-02, -2.649e-03, 1.897e-02, 2.651e-04));
	r += mul(s1_8, M4(-1.770e-03, 3.948e-02, 1.271e-02, 1.121e-01, -8.682e-03, 7.106e-03, -1.591e-02, 1.917e-02, -1.332e-01, 3.100e-01, 1.900e-01, -2.762e-02, -3.670e-02, 3.064e-02, 1.788e-02, -7.781e-03));
	r += V4(3.429e-02, -4.220e-03, -1.996e-02, 1.131e-02);
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
//!DESC CuNNy-1x4C-CHROMA-NVL-DN-out
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
	r += mul(s0_0, M4(-5.570e-02, -1.076e-02, -4.286e-02, -4.457e-02, 3.329e-03, 2.554e-02, 2.765e-02, 1.040e-02, -5.335e-02, 6.069e-02, -5.359e-02, -4.672e-02, -1.461e-02, 1.472e-02, 9.053e-03, 6.169e-02));
	r += mul(s0_1, M4(1.372e-01, 3.030e-02, 2.054e-01, 1.816e-01, -2.904e-02, -3.650e-02, -4.627e-02, -3.817e-02, 2.510e-01, 2.072e-02, -1.132e-01, -1.326e-01, 8.149e-02, 3.568e-02, -2.674e-02, -3.408e-02));
	r += mul(s0_2, M4(1.701e-02, 7.742e-02, -9.478e-02, -7.981e-02, -8.179e-02, -8.473e-02, -2.058e-02, -8.878e-03, 7.874e-03, 1.890e-02, 6.419e-03, -4.537e-02, 2.692e-02, 6.285e-02, 7.217e-03, -2.772e-02));
	r += mul(s0_3, M4(-8.031e-02, -9.546e-02, 2.288e-02, 4.923e-03, -1.597e-01, -1.147e-01, -1.203e-01, 3.430e-02, -3.096e-01, -1.147e-02, -7.485e-02, 8.420e-02, -9.741e-02, -1.351e-01, -1.293e-02, -1.123e-01));
	r += mul(s0_4, M4(2.752e-02, 2.684e-01, -5.248e-02, 5.585e-02, 9.824e-01, 5.488e-01, 5.892e-02, -2.260e-01, 1.011e-01, -8.024e-01, 1.012e+00, 8.713e-02, 2.939e-01, 3.584e-01, 3.810e-01, 3.819e-01));
	r += mul(s0_5, M4(-1.375e-02, -1.782e-01, 3.174e-02, 4.767e-04, -2.030e-01, 8.670e-02, -1.566e-01, -8.353e-02, -2.998e-01, 8.924e-02, -1.919e-01, 2.998e-01, -1.808e-02, -4.497e-02, 5.883e-03, 9.687e-02));
	r += mul(s0_6, M4(-8.936e-02, -3.442e-03, -2.298e-01, -7.571e-02, -1.339e-02, 1.590e-02, -2.955e-02, -2.790e-02, 1.182e-02, 2.446e-03, -2.075e-01, -6.119e-03, -1.150e-02, 9.394e-02, -1.002e-01, 3.416e-02));
	r += mul(s0_7, M4(-9.059e-02, -2.787e-01, -1.554e-01, -2.763e-01, -3.936e-01, -2.397e-01, 4.847e-01, 3.276e-01, 3.118e-02, -5.371e-02, -3.252e-01, -5.645e-01, -2.082e-01, -2.466e-01, -1.683e-01, -1.838e-01));
	r += mul(s0_8, M4(8.360e-02, 1.648e-01, 1.742e-01, 1.399e-01, 5.963e-02, -1.544e-01, -1.000e-01, -9.440e-03, -2.239e-02, 8.428e-02, 1.293e-02, 2.241e-02, 1.603e-02, -2.489e-02, 2.101e-02, -6.050e-02));
	r += mul(s1_0, M4(-1.274e-01, 4.078e-02, -9.414e-02, -2.116e-02, 4.135e-02, 3.116e-02, -1.060e-02, 9.796e-03, -4.977e-02, 2.107e-02, 7.211e-03, -1.542e-02, 1.011e-01, 3.196e-01, 9.932e-02, -5.806e-02));
	r += mul(s1_1, M4(7.840e-01, 1.105e-01, -3.871e-02, -1.242e-01, -1.565e-02, 6.546e-02, -5.930e-02, -8.418e-02, 4.163e-02, -9.888e-02, 2.723e-02, 3.264e-02, -7.909e-02, -2.938e-01, 2.982e-02, 1.781e-01));
	r += mul(s1_2, M4(-1.333e-01, 2.864e-01, -1.431e-01, -1.916e-01, -4.983e-03, -9.199e-02, -3.468e-02, -4.254e-02, -2.243e-02, 5.018e-02, -3.382e-02, -2.191e-02, 5.366e-03, 4.407e-02, -9.248e-03, 1.373e-02));
	r += mul(s1_3, M4(-2.874e-01, -3.845e-02, -9.586e-02, 9.936e-02, -4.699e-02, -9.270e-02, -9.700e-02, -8.847e-02, -9.790e-02, -9.098e-02, -4.236e-02, -7.561e-03, -1.507e-01, 3.330e-01, -2.321e-01, 6.230e-01));
	r += mul(s1_4, M4(9.548e-02, -5.169e-01, 1.371e+00, 1.744e-01, 1.373e-01, 3.310e-01, 3.140e-01, 3.857e-01, 6.958e-02, 1.510e-01, 6.032e-02, 3.532e-02, 4.842e-01, -1.121e-01, 2.716e-01, -7.555e-01));
	r += mul(s1_5, M4(-4.405e-01, -1.890e-01, -2.803e-01, 6.074e-01, 5.246e-03, -1.060e-01, -8.447e-02, -1.467e-01, 2.352e-02, -3.861e-02, 1.828e-02, 3.633e-02, 2.553e-02, -6.105e-03, 1.485e-02, 2.762e-02));
	r += mul(s1_6, M4(6.218e-04, 3.209e-02, -2.000e-01, -3.089e-02, -6.083e-02, -2.433e-02, 4.358e-02, -1.321e-02, -4.612e-02, 2.421e-03, -1.804e-01, -4.656e-02, -8.169e-02, -2.141e-02, -6.830e-02, -4.680e-02));
	r += mul(s1_7, M4(5.725e-02, -1.607e-01, -3.062e-01, -5.215e-01, 5.368e-02, 9.532e-03, 1.343e-01, 1.997e-01, -1.080e-01, -2.157e-01, -2.530e-01, -3.291e-01, -2.114e-01, -1.566e-01, -1.057e-01, 5.421e-03));
	r += mul(s1_8, M4(8.910e-02, 2.575e-01, 3.201e-02, 1.725e-02, -2.773e-02, -1.740e-02, -4.787e-02, -4.641e-02, 1.100e-02, 6.327e-02, 1.140e-01, 6.662e-02, 2.766e-02, 1.354e-02, 2.059e-02, 1.348e-02));
	r += V4(-2.176e-03, -3.051e-03, -2.876e-03, -3.685e-03);
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
//!DESC CuNNy-1x4C-CHROMA-NVL-DN-shuffle
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

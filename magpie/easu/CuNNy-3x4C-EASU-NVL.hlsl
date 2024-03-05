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
#define l0(x, y) (dot(float3(-2.585e-01, -4.670e-01, -1.156e-01), O(INPUT, float2(x, y)).rgb) + 7.609e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(9.184e-02, 2.408e-02, 5.400e-03, 4.866e-02) * s0_0;
	r += V4(4.012e-02, -5.608e-03, -8.367e-02, -9.160e-01) * s0_1;
	r += V4(1.929e-02, 2.269e-02, 1.424e-01, 6.425e-02) * s0_2;
	r += V4(-5.899e-01, 2.057e-02, 3.567e-03, -3.670e-02) * s0_3;
	r += V4(5.093e-01, -9.534e-01, -4.072e-01, 9.295e-01) * s0_4;
	r += V4(-6.813e-02, 4.246e-02, -4.044e-01, -8.700e-02) * s0_5;
	r += V4(-4.365e-01, 1.048e-02, -9.185e-02, -6.184e-03) * s0_6;
	r += V4(3.813e-01, 4.860e-02, 1.586e-01, -1.380e-02) * s0_7;
	r += V4(4.563e-02, 4.093e-03, 6.874e-01, 1.886e-02) * s0_8;
	r += V4(7.578e-03, -5.968e-02, -2.205e-03, -5.781e-04);
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
	r += mul(s0_0, M4(-3.776e-02, -2.733e-02, -9.892e-02, -1.101e-02, -1.190e-01, 9.028e-01, 3.580e-01, 9.470e-02, -3.271e-01, -9.817e-02, 2.429e-01, 1.302e-01, 3.468e-02, -9.159e-03, -1.163e-02, 1.851e-02));
	r += mul(s0_1, M4(-1.743e-01, -3.604e-01, -3.156e-01, 1.075e-01, -1.162e+00, 7.205e-01, -8.771e-01, 5.789e-02, -1.465e-02, 1.861e-01, 4.160e-01, 1.871e-01, -7.896e-02, 4.826e-03, 2.036e-02, -5.081e-02));
	r += mul(s0_2, M4(-1.140e-01, -7.837e-02, -6.342e-01, -5.918e-01, -1.278e-01, 6.547e-01, -2.513e-01, -6.554e-01, -1.130e-01, -3.224e-02, -4.291e-02, -2.781e-02, -1.226e-01, 5.229e-02, -1.105e-01, -3.454e-02));
	r += mul(s0_3, M4(1.801e-01, 1.155e-01, 5.047e-02, -6.430e-02, 5.335e-01, 6.142e-01, 1.001e+00, -1.367e-01, -3.751e-01, -9.698e-02, -9.934e-02, -2.395e-02, 3.680e-01, 2.633e-01, 4.084e-01, -6.889e-02));
	r += mul(s0_4, M4(-3.604e-03, 7.170e-02, 6.932e-01, 1.082e-01, 4.306e+00, 9.075e+00, 6.242e-01, -4.868e+00, 1.013e-01, -1.283e-01, -5.263e-01, 1.605e-01, -2.118e-01, -6.209e-02, 4.668e-02, 4.209e-01));
	r += mul(s0_5, M4(2.115e-01, 6.542e-02, 1.043e-01, -6.686e-01, 3.169e+00, 1.281e+00, 2.761e+00, 3.426e+00, 6.397e-02, 1.405e-02, 7.037e-02, 3.509e-02, 8.228e-02, -8.393e-02, -5.166e-01, -4.206e-01));
	r += mul(s0_6, M4(-3.668e-02, -4.309e-02, 1.346e-02, 7.158e-02, 4.620e-01, 9.716e-01, 1.395e+00, -3.744e-01, -5.082e-03, -8.262e-02, 8.706e-02, -2.017e-02, 1.644e-01, -5.634e-02, 4.759e-01, 1.363e-01));
	r += mul(s0_7, M4(1.420e-02, 9.581e-02, 2.894e-02, -6.795e-02, 2.343e+00, 2.855e+00, 1.136e+00, -7.489e-01, -1.902e-02, 1.801e-02, -2.251e-02, 5.382e-02, 8.522e-01, 3.476e-02, 7.931e-01, -1.381e-01));
	r += mul(s0_8, M4(-2.266e-02, -6.859e-02, 1.085e-01, 4.573e-02, 3.256e-02, 8.146e-01, -1.384e+00, -2.075e-01, 8.508e-04, -5.079e-04, 1.823e-03, -4.886e-02, -1.448e-03, -4.853e-02, 6.570e-02, 6.503e-02));
	r += mul(s1_0, M4(-7.487e-02, 9.965e-02, -1.507e-01, -9.813e-03, -2.520e-02, 1.719e-01, -1.988e-01, -5.544e-02, -1.874e-01, -5.965e-01, 5.257e-01, 4.236e-02, 7.411e-02, -6.189e-02, -2.293e-02, 1.691e-02));
	r += mul(s1_1, M4(-4.561e-01, -1.394e-01, -8.268e-01, 5.971e-02, -2.636e-02, -4.349e-02, 2.508e-01, 1.052e-01, 3.559e-02, -5.420e-02, 3.325e-01, -6.096e-02, 1.829e-01, 5.789e-03, 1.130e-01, -7.006e-02));
	r += mul(s1_2, M4(-9.134e-02, 3.779e-01, 9.519e-02, -3.349e-01, -2.143e-01, -1.600e-01, 3.399e-02, -9.086e-02, 8.529e-03, 1.629e-02, 7.008e-02, -5.776e-02, -9.126e-03, -4.705e-02, 1.909e-02, -8.362e-02));
	r += mul(s1_3, M4(1.665e-01, 5.278e-02, -2.727e-02, -6.195e-02, 7.211e-02, 1.704e-01, -1.912e-01, -1.897e-01, 1.869e-01, 4.994e-02, 7.254e-01, 1.089e-01, 3.161e-01, 1.675e-01, 6.994e-03, -4.289e-02));
	r += mul(s1_4, M4(-1.968e-01, -7.390e-02, 3.769e-01, 6.214e-02, -7.822e-02, 1.602e-01, -3.090e-01, -4.385e-02, 2.829e-01, -4.365e-01, -1.917e-01, 1.149e-02, -5.409e-02, -3.174e-01, -6.001e-01, 3.148e-01));
	r += mul(s1_5, M4(-9.883e-02, 3.910e-01, 2.179e-02, -8.057e-01, 8.923e-02, 2.033e-02, 2.137e-02, 7.642e-02, 1.645e-02, 4.293e-02, -3.342e-02, 1.314e-01, 3.888e-01, 2.469e-02, -1.470e-02, -2.362e-01));
	r += mul(s1_6, M4(-1.685e-02, -3.997e-02, 1.139e-02, 3.386e-02, 8.275e-02, -1.506e-01, 2.510e-01, 1.168e-01, 7.805e-04, -8.893e-02, 4.608e-02, -3.110e-02, 2.450e-01, 3.217e-02, 1.772e-01, -4.483e-02));
	r += mul(s1_7, M4(-3.842e-02, 2.240e-02, -8.250e-02, -7.226e-02, 7.135e-02, -1.242e-01, 2.149e-01, 9.595e-02, -5.624e-03, 1.842e-01, -1.024e-01, 4.572e-02, 3.117e-01, 1.105e+00, -4.252e-01, -4.168e-01));
	r += mul(s1_8, M4(2.280e-02, 1.399e-02, 3.711e-02, 2.606e-03, 2.627e-01, -4.454e-02, -6.613e-02, 4.469e-03, -1.960e-02, -3.425e-02, 1.924e-02, -3.711e-02, 1.918e-01, 3.742e-01, 2.761e-01, 4.423e-01));
	r += V4(1.471e-01, 1.368e-04, 5.026e-03, 9.778e-03);
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
	r += mul(s0_0, M4(-7.349e-03, -2.139e-02, -5.458e-02, 7.933e-02, 4.169e-02, 5.454e-02, 1.020e-02, -2.939e-02, 1.849e-02, -1.617e-03, 4.351e-03, -3.058e-02, 2.310e-01, 3.964e-02, 5.518e-02, -2.412e-02));
	r += mul(s0_1, M4(-6.084e-01, 1.665e-01, -1.027e-01, 5.457e-02, -4.978e-02, -3.792e-02, -3.303e-02, 2.710e-02, 3.023e-01, -1.434e-01, 1.265e-01, -6.665e-02, 5.051e-01, -8.385e-02, -5.726e-02, 1.620e-01));
	r += mul(s0_2, M4(-2.189e-01, -1.646e-01, -9.057e-02, -7.665e-02, 3.334e-02, 1.547e-01, 2.088e-02, -5.627e-03, 7.326e-02, 8.964e-02, 1.642e-02, 4.950e-02, 4.586e-02, -1.342e-01, 6.188e-02, -4.277e-02));
	r += mul(s0_3, M4(9.032e-03, -1.244e-01, 5.633e-02, -4.378e-02, -4.924e-03, 7.460e-02, 3.911e-02, -8.464e-02, -1.982e-02, 6.123e-02, 2.172e-02, 1.062e-02, -2.348e-01, 5.353e-02, 1.719e-01, -1.499e-01));
	r += mul(s0_4, M4(4.890e-01, -1.889e-02, 6.742e-03, -1.116e-01, -4.390e-02, -4.209e-01, 1.104e-01, -1.714e-02, -2.724e-01, -4.462e-02, -2.479e-01, 3.987e-02, -3.955e-01, 8.438e-01, 3.938e-01, 2.145e-02));
	r += mul(s0_5, M4(2.350e-01, 1.721e-01, 6.902e-02, 9.183e-02, -2.014e-02, -1.666e-01, 9.638e-01, 6.953e-02, -1.047e-01, 2.359e-01, 2.878e-01, -2.017e-01, -4.872e-02, -4.223e-01, 6.470e-02, -1.499e-02));
	r += mul(s0_6, M4(1.379e-02, 7.063e-02, -2.848e-02, -5.309e-02, -9.685e-02, 3.961e-02, 1.240e-02, 1.169e-02, 2.281e-02, -1.213e-01, 2.866e-02, 9.023e-03, -7.195e-02, 1.227e-01, -7.046e-02, 1.090e-01));
	r += mul(s0_7, M4(1.030e-01, -6.866e-02, -5.832e-02, -2.430e-03, -6.616e-02, 8.489e-02, 1.576e-02, 1.025e-03, -6.979e-02, 5.131e-02, 1.577e-01, -9.946e-02, 3.440e-02, 8.600e-02, -2.666e-01, -1.116e-01));
	r += mul(s0_8, M4(-2.757e-03, 1.335e-02, 1.875e-01, 5.433e-02, -1.956e-01, 1.373e-01, 5.251e-02, -2.543e-02, -1.425e-02, -1.498e-03, -1.811e-01, -1.243e-01, -1.034e-02, -1.380e-01, -6.322e-02, -2.816e-02));
	r += mul(s1_0, M4(-6.986e-02, -3.046e-02, 2.543e-02, 2.293e-02, 1.552e-01, 8.363e-02, -1.410e-02, 1.842e-02, -6.492e-02, -1.927e-01, 4.193e-02, -5.987e-02, 2.113e-01, -8.156e-02, -1.387e-02, -7.930e-02));
	r += mul(s1_1, M4(-7.138e-01, 2.580e-01, -1.986e-02, 7.851e-02, 3.526e-01, -4.038e-01, -8.760e-02, 7.370e-02, -2.168e-02, 8.042e-02, 7.001e-02, 2.421e-02, 3.213e-01, -5.656e-02, -1.811e-01, 8.716e-02));
	r += mul(s1_2, M4(-9.830e-02, -2.764e-01, 6.891e-02, -1.432e-02, -3.297e-02, -1.157e-02, -1.131e-01, -2.242e-02, 1.724e-01, 4.084e-02, -2.280e-04, 9.546e-02, -7.203e-02, 1.269e-02, -6.561e-02, 9.129e-03));
	r += mul(s1_3, M4(-7.539e-02, -1.246e-01, 2.640e-02, 1.548e-02, -1.510e-03, 1.130e-01, 3.873e-02, 4.487e-02, -2.994e-02, 1.794e-02, -2.363e-02, 2.526e-01, 1.571e-01, -1.223e-01, -4.748e-02, -1.542e-01));
	r += mul(s1_4, M4(1.939e-01, 4.129e-01, 2.783e-01, -2.008e-01, -2.449e-01, -1.435e-01, 5.702e-03, 1.466e-02, -7.637e-01, 8.743e-01, -1.372e-01, 8.378e-02, -3.545e-02, -1.107e-01, 3.760e-01, 7.374e-01));
	r += mul(s1_5, M4(2.648e-01, -1.821e-01, -6.752e-02, 5.069e-02, 5.000e-02, 2.317e-04, 1.571e-01, -1.306e-02, -1.345e-01, -5.959e-02, 1.264e-01, -5.686e-02, -9.550e-03, 6.793e-02, 1.143e-01, 6.909e-02));
	r += mul(s1_6, M4(5.572e-02, 3.331e-02, -2.963e-02, 3.735e-02, -3.165e-02, -2.380e-02, 9.436e-03, -6.854e-03, 8.746e-02, -4.436e-02, -1.438e-01, 1.511e-01, -1.822e-01, 2.615e-02, 1.253e-02, -2.807e-02));
	r += mul(s1_7, M4(5.190e-02, 1.459e-01, -7.400e-02, -1.228e-01, -2.094e-02, 2.354e-02, -6.296e-03, 4.047e-02, 7.240e-02, 1.293e-01, -1.697e-01, 9.498e-02, 2.199e-02, -1.768e-02, -2.480e-01, 3.549e-02));
	r += mul(s1_8, M4(2.881e-02, -1.806e-01, 1.393e-01, 9.161e-02, -9.174e-03, -2.480e-02, -6.347e-02, -3.542e-02, 4.339e-02, -1.593e-03, -4.054e-01, -8.519e-02, -2.919e-02, 1.093e-02, -1.776e-02, 3.272e-03));
	r += V4(2.629e-03, -7.497e-03, 3.582e-03, 2.435e-05);
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
	r += mul(s0_0, M4(-1.130e-02, 8.262e-03, 1.310e-02, 3.198e-03, 4.146e-02, 1.470e-01, 1.204e-01, 1.027e-01, -1.019e-02, -1.039e-01, -8.580e-02, 6.523e-02, -1.222e-01, -1.094e-02, -3.591e-02, -1.968e-01));
	r += mul(s0_1, M4(2.254e-02, 2.391e-03, -2.366e-03, 3.407e-02, -1.070e-02, 1.304e-01, 1.110e-01, 8.341e-02, 1.132e-02, 4.780e-02, -3.656e-04, 4.623e-02, -4.030e-02, -2.075e-01, -2.666e-01, 8.905e-01));
	r += mul(s0_2, M4(-1.212e-03, 2.931e-03, -8.653e-03, -1.416e-02, 9.062e-03, -6.064e-02, 1.886e-02, -2.872e-02, 3.221e-03, -1.500e-02, 8.939e-03, -3.111e-02, -6.831e-01, -3.459e-01, -6.816e-01, -9.746e-01));
	r += mul(s0_3, M4(-7.493e-02, 6.137e-02, 5.861e-02, -2.071e-02, -6.362e-02, 1.204e-01, 1.318e-02, 2.013e-01, -3.784e-02, -2.323e-01, -1.478e-01, 4.446e-01, -4.407e-02, -3.277e-02, -5.065e-02, -1.659e-02));
	r += mul(s0_4, M4(5.056e-02, -6.642e-02, -2.157e-03, -1.419e-01, 2.135e-01, 5.633e-02, 3.410e-01, -4.001e-01, -8.736e-02, 8.292e-02, -9.483e-02, 9.546e-02, -4.059e-01, 3.395e-01, 8.431e-01, 1.604e+00));
	r += mul(s0_5, M4(-1.107e-03, 4.216e-02, -4.774e-02, 9.008e-02, 3.200e-03, -9.887e-02, 4.814e-02, -4.903e-02, 9.705e-03, -5.473e-03, -3.990e-02, -1.124e-02, -1.067e+00, -6.767e-02, -2.286e+00, 2.594e-01));
	r += mul(s0_6, M4(7.720e-02, 6.772e-02, 1.264e-01, -7.709e-02, -4.351e-02, -3.748e-03, -1.194e-01, 1.586e-01, 3.042e-02, -7.569e-03, 9.434e-02, 4.276e-02, -5.997e-02, -9.846e-02, 1.714e-01, 6.485e-02));
	r += mul(s0_7, M4(-4.209e-01, 4.945e-02, 9.008e-02, -1.794e-01, -4.334e-02, 2.792e-01, -2.066e-01, 7.833e-02, -4.714e-02, 4.262e-02, 1.847e-02, -4.387e-02, -2.297e-01, -2.030e-01, -3.019e-01, 8.085e-02));
	r += mul(s0_8, M4(-2.134e-01, 3.623e-02, 2.721e-03, 2.239e-01, 2.727e-02, 4.048e-03, -5.018e-02, -3.075e-02, -4.768e-03, -4.110e-02, 3.546e-02, 2.751e-02, 9.522e-02, -3.331e-01, 3.482e-01, -2.350e-01));
	r += mul(s1_0, M4(2.342e-02, 8.418e-03, -4.783e-04, -8.645e-03, 1.616e-01, 1.085e-01, 1.197e-01, 4.351e-03, 3.696e+00, 7.713e-02, -9.963e-01, -1.246e+00, 4.260e-02, -7.154e-02, -3.933e-02, 1.046e-01));
	r += mul(s1_1, M4(1.187e-01, 7.742e-02, 1.847e-02, 1.101e-02, -1.533e-02, -4.095e-02, 4.703e-02, -9.920e-03, 1.009e-01, 4.978e-01, -3.660e-02, 7.003e-02, -1.311e-02, 6.128e-02, -1.010e-01, 1.676e-01));
	r += mul(s1_2, M4(9.692e-02, -6.729e-03, -2.007e-02, -2.485e-02, 2.111e-04, -1.207e-02, 5.512e-03, 1.019e-02, -9.062e-03, 1.112e-01, -1.358e-01, -6.658e-03, 1.147e-02, 5.502e-03, -1.923e-02, 4.525e-02));
	r += mul(s1_3, M4(-1.273e-01, 9.331e-02, 6.936e-02, 7.172e-02, 4.914e-02, 4.039e-01, 4.268e-01, 3.243e-01, 3.396e-01, 6.045e-01, 1.332e+00, -2.022e-01, 7.651e-03, -2.319e-01, -1.343e-01, 2.370e-01));
	r += mul(s1_4, M4(-3.232e-01, -1.618e-01, -1.758e-01, -4.021e-01, -3.606e-02, -1.890e-01, 4.608e-03, -1.813e-01, -2.088e-01, 7.166e-02, 4.737e-02, 2.453e-01, 2.196e-01, 6.783e-01, 3.124e-01, -2.319e-01));
	r += mul(s1_5, M4(-1.006e-01, 1.523e-01, -6.812e-02, 2.920e-01, -9.422e-03, 1.309e-02, 4.697e-03, 1.283e-02, 9.113e-02, -7.788e-02, 6.108e-02, -8.960e-02, 3.545e-02, -8.352e-02, 1.048e-01, 6.820e-03));
	r += mul(s1_6, M4(1.798e-02, 1.057e-01, 6.861e-02, 1.686e-02, -2.011e-02, 1.268e-01, -1.899e-01, 1.265e-01, -5.288e-02, 1.033e-01, -4.554e-01, 1.382e-01, -1.106e-02, -9.435e-02, -4.860e-03, 2.432e-02));
	r += mul(s1_7, M4(4.641e-02, 1.983e-01, 3.506e-01, -9.722e-02, 3.724e-02, 1.640e-01, -6.863e-02, 9.007e-02, 1.723e-01, -8.829e-02, 1.708e-01, -2.436e-01, -5.753e-02, 5.128e-02, -1.005e-01, 5.173e-02));
	r += mul(s1_8, M4(-1.119e-01, -2.638e-02, -3.110e-02, 1.841e-01, 1.286e-02, 9.431e-03, -2.323e-03, 4.102e-03, 3.959e-02, -5.043e-02, 6.637e-02, -5.807e-02, -1.395e-02, 3.692e-02, -2.062e-02, -1.138e-02));
	r += V4(-1.521e-05, 1.152e-03, -9.917e-04, 2.771e-03);
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
	r += mul(s0_0, M4(-2.300e-01, -1.043e-01, 1.587e-01, 5.310e-02, -2.082e-02, -1.668e-02, 3.396e-02, 2.474e-02, 6.863e-02, 3.215e-02, -2.505e-02, -1.932e-03, -9.031e-03, 2.943e-03, -2.867e-03, 5.868e-03));
	r += mul(s0_1, M4(2.559e-01, -2.447e-01, 3.844e-02, 1.889e-01, -3.037e-02, -3.252e-02, 1.880e-01, 8.666e-02, -1.574e-02, 9.789e-02, -6.616e-02, -5.913e-02, -4.225e-02, -2.655e-02, 1.172e-02, -1.652e-03));
	r += mul(s0_2, M4(-6.043e-02, 1.559e-01, -3.246e-02, -6.527e-02, 4.562e-03, 5.677e-02, -2.223e-02, -6.069e-02, 6.074e-02, -6.371e-02, 1.139e-02, -4.527e-03, 7.794e-03, 7.061e-03, 1.650e-02, 1.199e-02));
	r += mul(s0_3, M4(1.968e-01, -1.577e-01, -1.309e-01, 3.632e-02, -9.570e-02, -2.931e-02, -1.997e-01, -6.542e-02, 1.192e-01, -5.195e-02, 1.750e-01, 6.149e-02, 1.366e-02, -2.220e-03, -3.698e-02, -1.014e-02));
	r += mul(s0_4, M4(5.371e-01, 1.277e+00, -8.232e-01, -1.047e+00, -4.951e-01, 2.367e-01, -7.623e-01, -1.323e-01, -8.640e-01, -2.813e-01, 2.067e-01, 3.643e-01, 3.369e-01, 6.702e-02, 4.017e-02, -1.223e-01));
	r += mul(s0_5, M4(-1.033e-02, -5.136e-02, 1.129e-01, 3.828e-02, 8.422e-02, -1.120e-01, 5.188e-02, 5.314e-02, 1.084e-01, -1.510e-01, -1.159e-02, -9.458e-02, -3.259e-02, 1.763e-01, -6.693e-02, 8.231e-02));
	r += mul(s0_6, M4(-8.472e-02, 1.448e-02, -3.468e-02, -1.125e-01, 4.382e-02, 2.425e-02, 7.687e-02, -6.912e-03, 2.726e-02, -2.142e-02, 1.074e-01, -3.577e-02, 9.334e-03, -1.314e-02, 8.130e-02, -3.797e-03));
	r += mul(s0_7, M4(-2.051e-01, -2.977e-01, 1.776e-01, 3.447e-01, 7.746e-02, 1.240e-02, 5.957e-02, 1.255e-01, 6.097e-02, 7.960e-02, -1.043e-01, 3.752e-02, -4.893e-02, -7.013e-02, 1.547e-01, 9.964e-02));
	r += mul(s0_8, M4(4.731e-02, -5.308e-02, 4.214e-03, 2.940e-02, 3.134e-02, -1.264e-02, 7.350e-02, -7.667e-02, -5.459e-03, -3.960e-02, 7.423e-02, 1.470e-01, -1.315e-02, 2.127e-02, -5.443e-03, 1.268e-01));
	r += mul(s1_0, M4(2.412e-02, 5.819e-04, -2.093e-02, -6.240e-03, -1.179e-01, -1.261e-02, 8.600e-02, 4.650e-02, 1.277e-01, -3.094e-02, -6.811e-02, -1.752e-02, -2.687e-03, -4.439e-03, 2.263e-03, -2.438e-02));
	r += mul(s1_1, M4(-2.000e-02, 4.906e-02, 4.282e-03, -1.781e-02, 5.221e-02, -9.888e-02, 2.985e-02, 6.763e-02, -2.240e-01, 1.709e-01, 4.644e-02, -1.784e-02, -5.773e-02, 3.951e-02, 2.152e-03, -5.451e-02));
	r += mul(s1_2, M4(-5.497e-04, -2.043e-02, 1.279e-02, 8.107e-03, 1.199e-02, -2.624e-02, -4.991e-03, 8.425e-03, 3.892e-02, -4.407e-02, 2.853e-02, 5.951e-03, 1.497e-02, -3.529e-02, 4.622e-04, -4.798e-03));
	r += mul(s1_3, M4(-3.011e-02, -3.107e-03, 7.495e-02, 4.909e-03, -1.597e-01, 1.089e-01, -4.133e-01, 2.968e-02, 6.839e-02, -4.264e-02, 3.328e-01, -3.348e-02, 8.129e-02, -1.279e-01, 8.001e-03, -1.018e-01));
	r += mul(s1_4, M4(2.140e-01, -6.459e-02, -1.294e-01, 1.235e-02, -1.100e-02, -2.283e-01, 1.952e-02, -4.491e-01, -8.565e-02, -6.735e-03, -3.644e-01, 2.452e-01, 2.980e-02, 6.172e-01, -1.470e-01, 5.449e-01));
	r += mul(s1_5, M4(-4.550e-02, 1.460e-01, 3.210e-02, -1.421e-03, -1.558e-02, -1.535e-02, 1.896e-02, -5.184e-02, 5.991e-02, -6.472e-02, 4.943e-03, -1.290e-01, 1.261e-02, 2.824e-02, 1.285e-02, -1.491e-02));
	r += mul(s1_6, M4(2.564e-02, 1.751e-02, 1.194e-01, -4.554e-02, 3.384e-02, 1.056e-02, 8.805e-02, 1.672e-02, 3.544e-03, -2.887e-02, 5.412e-02, 1.498e-02, 4.116e-02, 7.862e-03, 8.147e-02, -3.877e-02));
	r += mul(s1_7, M4(-5.603e-02, -6.297e-02, 2.668e-01, 3.243e-01, 9.954e-03, 3.943e-02, -7.428e-04, 6.567e-02, -1.897e-03, 4.090e-02, -1.082e-01, -6.078e-02, -1.304e-02, -1.372e-01, 1.061e-01, 6.258e-02));
	r += mul(s1_8, M4(7.656e-03, 4.068e-02, -5.296e-02, 2.977e-02, 4.774e-03, 1.534e-02, -8.219e-03, 6.362e-03, -1.471e-02, -2.214e-02, 2.712e-02, 1.135e-02, -2.030e-02, 1.342e-02, -1.140e-02, 4.592e-02));
	r += V4(9.236e-05, 1.652e-04, 7.676e-04, 7.242e-04);
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

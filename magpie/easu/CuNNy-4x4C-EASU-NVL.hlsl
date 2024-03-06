// CuNNy 4x4C CHROMA NVL
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
//!DESC CuNNy-4x4C-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(3.312e-01, 6.152e-01, 1.503e-01), O(INPUT, float2(x, y)).rgb) + -7.542e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(1.777e-02, 1.414e-02, -5.850e-03, 2.555e-02) * s0_0;
	r += V4(-1.947e-02, 2.417e-02, 1.101e-01, -4.901e-01) * s0_1;
	r += V4(1.482e-03, -8.969e-04, -8.767e-02, 5.042e-02) * s0_2;
	r += V4(-5.801e-01, 7.926e-02, -5.310e-02, -4.398e-02) * s0_3;
	r += V4(5.801e-01, 4.419e-02, -4.894e-02, -9.691e-02) * s0_4;
	r += V4(-4.802e-04, 4.594e-02, 5.097e-01, 5.313e-01) * s0_5;
	r += V4(1.185e-02, 4.782e-02, 4.820e-02, 1.382e-02) * s0_6;
	r += V4(-1.592e-02, -5.370e-01, -4.479e-01, 1.214e-01) * s0_7;
	r += V4(5.230e-03, 1.987e-01, -2.218e-02, -1.131e-01) * s0_8;
	r += V4(5.392e-04, -5.221e-02, 5.315e-04, -5.890e-04);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-conv1
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
	r += mul(s0_0, M4(1.875e-02, -8.672e-02, -2.289e-02, 8.663e-02, 2.281e-02, 1.554e-01, -1.693e-03, 7.649e-02, 1.332e-01, 1.840e-01, -4.628e-02, -5.878e-02, -8.874e-03, 9.498e-02, -5.062e-03, 3.370e-02));
	r += mul(s0_1, M4(8.375e-02, 2.807e-02, 4.140e-02, -3.964e-02, 3.848e-03, -5.998e-01, -1.344e-01, 8.849e-02, 1.489e-01, 3.569e-01, -2.619e-02, -5.863e-02, 7.251e-02, 1.007e-01, 1.752e-02, 4.453e-02));
	r += mul(s0_2, M4(1.356e-01, -1.570e-01, -1.044e-01, -2.855e-01, 1.104e-01, -9.994e-02, -2.496e-01, 3.722e-01, -3.937e-02, 2.179e-02, -1.646e-02, -2.134e-01, 4.050e-02, 1.190e-01, -8.044e-02, -3.976e-02));
	r += mul(s0_3, M4(4.323e-02, -6.098e-02, 8.080e-02, 5.678e-02, -4.836e-02, -1.231e-01, -1.636e-01, 1.266e-01, 1.490e-02, 5.804e-01, -2.253e-01, 1.349e-01, -2.381e-01, 9.490e-02, 2.965e-02, 5.762e-01));
	r += mul(s0_4, M4(-1.018e-01, 2.312e-01, -3.290e-01, 1.058e-01, -2.889e-01, -2.057e-01, -4.058e-01, -1.981e-01, 3.427e-02, 3.033e-01, -1.334e-01, -1.094e-01, -1.802e-01, -2.616e-02, 3.078e-01, -1.000e-01));
	r += mul(s0_5, M4(8.287e-01, 3.209e-01, -1.526e-01, -1.009e+00, 2.479e-01, -9.142e-02, -2.012e-01, -3.862e-01, -1.665e-01, -1.268e-01, -1.255e-01, -1.498e-01, 1.304e-01, 3.373e-02, 7.455e-03, -2.122e-02));
	r += mul(s0_6, M4(-8.337e-02, -7.727e-02, -6.771e-02, 9.431e-02, 2.128e-02, -4.528e-02, 1.268e-01, -5.505e-02, 1.295e-01, 2.247e-01, -1.772e-01, 8.908e-02, 1.944e-01, 1.126e-01, 4.757e-02, 1.500e-01));
	r += mul(s0_7, M4(1.647e-02, -6.896e-02, 2.376e-01, 1.470e-02, -8.014e-02, 1.334e-01, 3.427e-02, 2.036e-01, -1.707e-01, -5.046e-02, -1.196e-01, -8.917e-02, -1.861e-02, 7.412e-03, 4.472e-01, -3.838e-02));
	r += mul(s0_8, M4(-1.359e-01, -1.285e-01, 9.489e-02, -5.733e-02, -1.357e-01, -6.924e-02, 1.057e-01, 1.277e-01, 1.122e-02, 1.666e-01, -1.987e-01, 3.876e-02, -3.914e-01, -7.225e-02, 5.660e-01, 2.763e-01));
	r += mul(s1_0, M4(1.093e-02, 1.086e-02, -1.239e-02, 4.363e-03, 8.580e-03, 1.588e-01, -2.466e-02, 2.427e-01, -1.189e-01, -1.145e-01, 7.649e-02, -1.217e-01, 1.528e-04, 3.601e-02, 2.754e-03, -6.428e-02));
	r += mul(s1_1, M4(-1.313e-01, 1.023e-01, 1.525e-01, -3.210e-02, 1.562e-01, 3.186e-01, 5.576e-02, 6.296e-03, -1.363e-01, -6.790e-02, 1.982e-01, 2.747e-01, 2.002e-02, -1.372e-01, 5.749e-02, 1.874e-02));
	r += mul(s1_2, M4(-1.051e-03, -2.836e-01, -9.776e-02, -2.759e-01, 1.094e-01, 3.364e-01, -1.606e-01, -2.120e-01, -9.245e-02, -1.131e-01, 2.075e-01, 1.594e-01, 4.149e-03, 4.154e-02, -9.536e-02, -1.679e-02));
	r += mul(s1_3, M4(2.269e-02, 7.521e-02, 5.225e-02, 2.786e-02, 5.945e-02, -2.664e-01, -1.746e-01, 2.668e-01, -1.018e-01, 6.096e-01, -4.560e-01, 2.492e-01, 1.423e-02, -2.106e-02, -3.046e-01, -1.703e-01));
	r += mul(s1_4, M4(-3.093e-01, 3.370e-01, -6.346e-01, 3.657e-01, -2.115e-01, -2.645e-01, -2.618e-01, -2.801e-02, -8.583e-02, 1.098e-01, -4.465e-02, 6.192e-01, 1.882e-02, -1.133e-01, -5.025e-02, -2.372e-01));
	r += mul(s1_5, M4(5.564e-01, -5.282e-01, -2.623e-02, 5.879e-01, -1.633e-01, -1.165e-01, 2.209e-01, -2.811e-01, -2.195e-01, -2.200e-01, 1.233e-01, 1.714e-01, 2.639e-01, 5.257e-02, -2.211e-01, 2.981e-02));
	r += mul(s1_6, M4(-6.311e-02, 1.584e-02, -3.084e-02, -6.698e-02, 4.272e-02, -1.722e-01, 2.430e-01, -1.156e-01, -3.846e-03, 1.923e-01, -2.895e-02, 8.583e-02, 3.804e-01, 4.951e-01, -1.705e-01, -4.218e-01));
	r += mul(s1_7, M4(2.240e-01, 2.148e-01, 2.869e-01, -6.276e-02, 3.746e-02, 3.760e-02, 9.616e-02, 1.207e-02, -9.712e-02, -9.600e-02, -4.418e-02, -3.893e-02, 8.344e-01, 1.136e-02, -4.948e-01, -2.655e-01));
	r += mul(s1_8, M4(5.787e-01, -3.771e-02, -4.600e-01, -1.995e-01, -9.693e-02, -9.318e-02, 8.369e-02, 6.220e-02, 1.332e-01, 1.431e-01, -3.000e-01, 6.398e-02, -1.216e-01, -4.883e-03, 2.509e-01, 3.354e-02));
	r += V4(-3.993e-03, -1.300e-03, -4.736e-03, 2.729e-03);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-conv2
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
	r += mul(s0_0, M4(-2.173e-01, 1.693e-01, -1.513e-01, 3.439e-02, 1.351e-01, -3.399e-02, 9.782e-02, 7.787e-02, 6.471e-02, -7.294e-03, 6.512e-02, 2.887e-02, -1.151e-01, -3.958e-02, -2.781e-02, 3.793e-02));
	r += mul(s0_1, M4(-1.060e-01, 6.620e-01, -1.016e-01, -1.720e-01, -9.866e-02, -1.208e-01, -8.539e-02, 1.038e-01, 1.371e-02, 3.981e-01, 2.842e-01, 2.585e-01, -1.024e-03, 4.398e-02, -2.610e-03, -2.227e-01));
	r += mul(s0_2, M4(-3.993e-01, 1.863e-01, -1.115e-01, 2.453e-02, 6.361e-02, 9.306e-02, -9.255e-02, -7.844e-03, 9.387e-03, 3.467e-01, -2.271e-01, -1.218e-01, -1.150e-01, -4.395e-01, 2.833e-01, 9.126e-03));
	r += mul(s0_3, M4(2.530e-02, 6.770e-02, -3.083e-02, -1.345e-01, -8.455e-02, 1.939e-01, -1.362e-01, -1.362e-01, -3.064e-02, 1.553e-01, -1.071e-01, -4.675e-02, 7.440e-02, 9.311e-02, 6.761e-02, 2.279e-02));
	r += mul(s0_4, M4(-1.969e-01, -5.104e-01, -3.853e-01, -2.405e-01, 1.976e-01, 2.648e-01, -3.340e-01, 1.418e-01, 6.242e-01, -1.067e-01, -6.069e-02, -1.252e-01, 1.944e-01, -6.952e-01, 6.314e-01, 3.994e-01));
	r += mul(s0_5, M4(-7.168e-01, -1.977e-01, -1.268e-02, 3.410e-01, -7.739e-02, -1.722e-01, 2.397e-01, 1.083e-01, -2.628e-01, -7.899e-02, 1.603e-01, 2.744e-01, 4.753e-02, -3.020e-01, -5.015e-02, -2.073e-01));
	r += mul(s0_6, M4(-1.304e-01, 1.166e-02, -1.253e-01, 6.717e-02, -8.277e-02, -1.238e-01, 8.764e-02, 3.011e-02, 6.790e-03, 9.958e-03, 1.233e-01, 3.198e-02, 9.384e-02, 5.499e-02, -3.642e-03, 3.491e-02));
	r += mul(s0_7, M4(-2.016e-01, 1.004e-01, -2.381e-01, 1.075e-01, 3.480e-02, 3.205e-02, 3.503e-01, -2.746e-02, 1.723e-01, 4.091e-03, 1.361e-01, -2.346e-02, -7.450e-02, 1.475e-01, 3.181e-02, 1.179e-01));
	r += mul(s0_8, M4(-3.250e-01, 2.804e-02, -2.475e-01, 2.159e-02, 1.193e-01, 4.171e-02, 7.198e-02, -1.232e-01, -5.077e-02, -9.315e-04, -1.333e-01, -1.823e-02, 3.321e-02, -1.886e-02, -1.618e-01, -1.086e-01));
	r += mul(s1_0, M4(4.684e-02, 1.198e-01, 1.063e-01, 7.901e-02, 6.621e-02, -6.801e-02, 7.827e-02, 4.006e-02, -1.505e-01, 9.126e-02, -2.301e-01, -1.879e-02, -1.838e-01, -6.698e-03, -2.429e-03, 9.254e-02));
	r += mul(s1_1, M4(-2.344e-02, 4.376e-01, 9.794e-02, 8.073e-03, 4.761e-02, -5.755e-02, 7.626e-02, 3.887e-02, -4.991e-01, 5.879e-01, -4.828e-01, 2.921e-01, -8.014e-03, 6.791e-02, -6.011e-02, -8.661e-02));
	r += mul(s1_2, M4(4.419e-02, 3.122e-01, -1.411e-01, -7.642e-02, -4.102e-02, -3.001e-02, -3.313e-01, 1.950e-01, -1.764e-01, 4.788e-01, -5.063e-01, -3.509e-02, -2.169e-01, 1.050e-01, -1.420e-01, 3.681e-02));
	r += mul(s1_3, M4(1.763e-01, -9.573e-02, 2.568e-01, 9.985e-02, -7.536e-02, 1.977e-01, -1.434e-01, -1.101e-01, -3.514e-01, 2.883e-01, -5.380e-01, -1.830e-01, 6.293e-02, -4.105e-02, -9.855e-02, -7.251e-02));
	r += mul(s1_4, M4(5.845e-01, -3.721e-01, -6.902e-02, -2.851e-01, 2.192e-01, 2.894e-01, -4.424e-01, -1.228e-01, -3.056e-01, -2.285e-01, -4.821e-01, -4.365e-02, -9.657e-02, -4.219e-01, -5.461e-02, 1.919e-01));
	r += mul(s1_5, M4(-1.320e-01, -1.802e-01, 2.344e-01, 2.232e-01, -1.459e-01, 2.898e-01, -3.821e-01, -4.756e-01, -3.557e-01, -1.118e-01, 6.298e-03, 3.738e-01, -3.165e-01, 1.567e-01, -1.688e-01, -8.858e-02));
	r += mul(s1_6, M4(8.916e-02, 6.717e-02, -2.869e-02, 3.926e-03, 2.701e-02, -9.400e-02, 8.075e-02, 5.554e-02, -1.485e-01, -5.089e-02, 1.053e-01, 2.850e-02, -3.637e-02, -6.308e-02, -2.828e-02, 3.614e-02));
	r += mul(s1_7, M4(6.700e-02, 2.745e-02, 1.150e-02, 8.233e-02, -1.919e-01, 8.696e-03, 3.110e-01, -9.791e-03, -2.091e-01, -6.075e-03, 6.035e-02, 5.326e-02, -5.513e-02, 1.052e-01, -5.920e-02, 1.044e-01));
	r += mul(s1_8, M4(4.302e-02, 4.016e-02, -1.067e-01, -1.023e-01, 8.645e-02, 4.803e-02, 1.052e-02, -2.714e-01, -7.146e-02, 2.118e-04, -1.118e-02, -9.503e-02, -1.938e-01, 1.010e-01, -2.859e-01, 5.365e-03));
	r += V4(4.965e-03, 3.278e-03, 1.858e-03, 2.739e-03);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-conv3
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
	r += mul(s0_0, M4(7.289e-03, 4.135e-02, 8.709e-02, -6.283e-02, -1.730e-01, -3.755e-02, -4.881e-02, -1.366e-01, -5.366e-02, 2.552e-02, -6.194e-03, 9.229e-02, 8.753e-02, 5.231e-02, -8.227e-02, -1.171e-02));
	r += mul(s0_1, M4(2.798e-01, 1.503e-02, 1.476e-01, 1.694e-03, 4.411e-02, -5.484e-02, 2.631e-02, -2.458e-01, 3.564e-02, 4.777e-02, -1.643e-01, 1.169e-01, -7.899e-03, 1.112e-01, 5.304e-02, 7.015e-02));
	r += mul(s0_2, M4(-2.751e-01, 6.959e-02, -7.236e-02, 8.301e-02, -6.278e-02, -5.138e-02, -8.602e-02, 5.233e-02, 8.756e-03, -2.370e-02, 3.178e-02, 1.750e-02, -9.763e-03, 5.427e-02, 2.549e-02, 8.010e-02));
	r += mul(s0_3, M4(-2.442e-03, -7.339e-02, -8.342e-02, -3.342e-01, -2.029e-01, -2.725e-01, -2.529e-01, -1.477e-01, -8.896e-02, 1.947e-01, 1.579e-01, 3.944e-01, 5.887e-02, -2.358e-01, -3.135e-01, -3.676e-01));
	r += mul(s0_4, M4(-2.080e-01, -8.441e-02, -6.588e-02, -1.304e-01, 2.298e-01, -3.245e-01, 1.851e-01, 2.552e-01, 2.477e-01, -1.050e-01, -6.910e-02, 3.509e-01, 9.590e-02, -4.287e-01, 3.135e-01, 9.052e-02));
	r += mul(s0_5, M4(1.857e-01, -1.428e-01, -4.842e-03, -3.272e-01, -2.835e-01, -2.049e-01, -3.649e-02, -2.052e-01, -2.064e-01, 8.469e-02, 9.014e-02, 2.065e-01, -5.988e-02, -1.994e-01, -3.530e-02, -2.725e-01));
	r += mul(s0_6, M4(2.456e-02, -3.723e-03, 1.980e-02, -5.358e-02, 4.674e-02, 2.678e-01, -5.163e-02, 3.157e-01, 1.132e-02, -1.049e-02, -1.324e-02, 4.785e-02, 4.950e-02, -7.566e-02, 3.621e-02, -9.300e-02));
	r += mul(s0_7, M4(-4.659e-02, -3.229e-02, 4.238e-02, -6.562e-02, 1.277e-01, 5.957e-01, 1.558e-01, -1.305e-01, 4.073e-02, 2.791e-02, -7.326e-02, -1.317e-02, -2.756e-02, 1.255e-01, 1.714e-01, -4.224e-02));
	r += mul(s0_8, M4(6.188e-02, 2.902e-03, -1.261e-02, 1.304e-01, 7.610e-02, 2.188e-01, -2.919e-02, -4.774e-02, -1.155e-01, 2.475e-02, -2.272e-02, -9.413e-02, 1.085e-01, 1.093e-01, 5.195e-02, 1.119e-01));
	r += mul(s1_0, M4(1.833e-02, 1.440e-01, -1.261e-01, -1.295e-01, -1.169e-02, -1.829e-02, 3.407e-03, 1.431e-02, 1.800e-01, -3.026e-01, 1.823e-01, 7.899e-02, -1.518e-01, 4.111e-01, -9.738e-02, 3.857e-01));
	r += mul(s1_1, M4(-7.497e-01, 3.992e-02, 3.267e-01, -1.622e-01, 2.979e-01, 2.199e-02, 1.410e-01, -8.325e-02, 1.028e+00, 2.349e-01, 4.675e-01, -7.347e-02, -2.722e-01, 4.092e-01, -3.027e-01, 2.142e-01));
	r += mul(s1_2, M4(3.311e-01, -1.294e-01, -8.098e-02, -1.883e-01, -1.223e-01, -3.332e-03, -5.773e-02, 1.025e-01, -4.881e-02, 1.322e-01, -4.124e-02, 2.001e-01, 1.285e-01, 2.265e-01, -7.221e-02, 3.119e-01));
	r += mul(s1_3, M4(4.028e-01, -3.464e-03, 4.130e-01, -3.860e-01, 6.410e-02, 1.347e-01, 5.030e-02, 4.329e-01, 7.769e-02, 1.171e+00, 2.012e-01, 1.155e+00, -8.899e-02, -1.084e-01, -1.414e-01, -4.553e-01));
	r += mul(s1_4, M4(-3.077e-01, -2.697e-01, -4.992e-01, -4.848e-01, 9.457e-01, 3.878e-02, 5.657e-01, 6.078e-01, 7.644e-02, 1.682e-01, 1.471e+00, 9.305e-01, 6.578e-02, -8.644e-01, 1.419e-01, -1.422e-01));
	r += mul(s1_5, M4(1.879e-01, -2.539e-01, 5.333e-02, -1.077e-01, -2.650e-01, -8.619e-02, 5.636e-03, 2.879e-02, 3.152e-01, 1.275e-01, -1.909e-01, 1.529e-01, -5.833e-01, -3.532e-01, -5.215e-01, -1.720e-01));
	r += mul(s1_6, M4(8.085e-02, -1.330e-01, -9.107e-02, 7.062e-02, -3.449e-02, 1.973e-02, -8.158e-02, -1.264e-02, 5.944e-02, -1.790e-01, -4.470e-03, -4.909e-01, 3.919e-02, -1.182e-02, 9.999e-02, 1.062e-01));
	r += mul(s1_7, M4(-4.280e-02, 3.519e-03, 3.230e-02, 1.410e-01, 1.508e-01, 1.116e-01, 2.363e-01, -2.997e-01, -2.302e-01, 4.734e-01, -5.954e-01, -5.339e-01, -1.231e-01, -2.233e-01, -7.016e-03, -7.848e-03));
	r += mul(s1_8, M4(4.198e-02, 1.540e-02, 2.911e-02, 4.849e-02, -2.080e-02, 9.944e-02, 5.742e-03, -4.079e-02, 3.615e-01, -1.445e-02, 2.084e-01, -4.666e-02, -3.464e-01, -7.412e-02, -3.596e-01, 1.646e-01));
	r += V4(-7.491e-03, 3.447e-03, -3.684e-03, 1.138e-03);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-conv4
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
	r += mul(s0_0, M4(1.356e-01, -8.637e-02, 3.098e-02, -9.960e-02, 5.516e-02, -7.499e-02, 1.122e-01, -1.567e-01, -3.467e-01, 1.841e-01, -2.752e-01, 1.803e-01, 2.666e-02, -1.145e-01, 4.428e-03, 3.057e-02));
	r += mul(s0_1, M4(-1.295e-01, 8.741e-02, -8.159e-02, 1.503e-02, -1.275e-01, 6.738e-02, 4.404e-01, 2.136e-01, 7.638e-01, -2.065e-01, -6.225e-02, 4.948e-03, 7.749e-02, -2.151e-01, 4.138e-02, -1.116e-01));
	r += mul(s0_2, M4(-3.244e-02, 5.973e-02, 3.062e-03, 3.308e-02, 6.896e-02, -4.117e-03, 1.369e-01, -4.546e-02, -1.919e-01, 4.577e-03, -1.393e-01, -5.627e-02, -2.995e-02, -3.090e-02, 9.397e-02, 4.538e-02));
	r += mul(s0_3, M4(9.837e-02, 2.920e-01, -9.707e-02, 1.337e-02, -4.279e-02, -9.841e-02, -1.120e-01, 5.767e-02, -1.448e-01, 3.583e-02, -1.681e-02, -5.625e-01, 1.165e-01, 1.335e-01, 7.864e-02, 1.675e-01));
	r += mul(s0_4, M4(-5.176e-01, 6.533e-01, -1.134e-01, 5.788e-01, -5.534e-01, -5.269e-01, -1.675e-01, -4.111e-01, 5.136e-01, 2.111e-01, 1.036e-01, 9.594e-02, -2.820e-01, 3.319e-01, -6.846e-01, -3.835e-01));
	r += mul(s0_5, M4(2.218e-01, 8.087e-02, 9.852e-02, 2.744e-01, 4.412e-02, -5.998e-02, -3.809e-02, -1.330e-01, -1.147e-01, 4.275e-02, -1.844e-01, 6.323e-02, -1.252e-01, 8.635e-02, -1.009e-01, 2.137e-01));
	r += mul(s0_6, M4(-1.847e-03, 1.763e-01, -7.267e-02, -3.673e-01, -5.830e-02, 3.198e-02, -1.246e-02, -8.723e-02, -9.130e-02, -9.744e-02, -1.379e-02, 4.367e-02, 7.778e-03, -1.063e-01, 5.003e-03, 8.860e-02));
	r += mul(s0_7, M4(-1.053e-01, -3.117e-01, -2.650e-01, 3.455e-01, 6.583e-02, 1.278e-01, 7.511e-02, -4.720e-02, 2.301e-01, 2.488e-01, 1.870e-01, -3.239e-02, -4.895e-02, 8.687e-02, -6.633e-03, -2.011e-01));
	r += mul(s0_8, M4(1.106e-01, -5.191e-02, 7.222e-02, 3.418e-03, -3.911e-02, -1.444e-02, -1.221e-02, -2.503e-02, -2.907e-02, 5.498e-02, -1.999e-02, 1.873e-02, -3.904e-02, -6.533e-02, -6.908e-02, 6.869e-02));
	r += mul(s1_0, M4(6.148e-04, -5.834e-02, -1.525e-02, -2.844e-02, -4.407e-02, 2.122e-02, -3.754e-02, -3.112e-02, -2.412e-02, -3.674e-02, 3.304e-02, 4.025e-02, -7.083e-03, 4.185e-02, -5.238e-02, 2.471e-02));
	r += mul(s1_1, M4(2.944e-02, -6.198e-02, 1.565e-02, -3.251e-02, 9.545e-02, -1.558e-02, 8.323e-02, 7.896e-02, 1.888e-01, -9.921e-02, 1.022e-01, 1.497e-01, -1.136e-03, -2.444e-02, -6.209e-02, -8.667e-02));
	r += mul(s1_2, M4(-1.421e-02, 1.166e-02, -5.666e-03, -1.245e-02, -5.454e-02, 1.682e-03, 3.613e-02, -2.908e-02, 2.229e-01, -1.141e-01, 1.664e-01, 9.743e-02, -7.106e-02, 6.309e-02, -8.032e-02, 1.926e-02));
	r += mul(s1_3, M4(1.174e-01, 3.543e-02, 1.223e-01, -7.423e-02, 7.006e-02, -3.058e-02, 5.637e-02, -1.460e-01, -2.495e-02, -7.588e-02, 3.896e-02, 1.707e-01, -2.719e-03, 1.743e-01, -3.922e-02, 2.876e-01));
	r += mul(s1_4, M4(-2.979e-01, 2.023e-01, 9.412e-02, -4.016e-02, -3.291e-02, 4.170e-02, 6.252e-01, 2.963e-01, 3.858e-01, -4.548e-02, -9.403e-02, 1.771e-01, 8.545e-04, -1.503e-01, -5.388e-01, -5.031e-01));
	r += mul(s1_5, M4(3.442e-02, 3.696e-02, 7.352e-02, -1.214e-02, 1.268e-02, -1.587e-01, 1.140e-01, -1.401e-01, -5.594e-02, 4.128e-03, -4.949e-02, 8.538e-02, 1.101e-01, 5.966e-02, -3.282e-02, 2.298e-01));
	r += mul(s1_6, M4(-8.340e-02, -2.129e-01, -5.897e-02, -5.617e-02, -3.314e-02, -4.831e-03, -8.554e-02, 6.592e-02, 3.742e-02, 5.719e-02, 3.556e-03, 4.793e-02, 1.245e-02, 2.921e-01, -7.094e-02, 2.829e-02));
	r += mul(s1_7, M4(1.028e-02, -1.873e-01, -6.864e-02, 2.105e-01, 6.897e-02, 5.055e-02, -1.269e-01, -1.332e-01, 3.736e-02, 1.568e-03, 4.915e-02, -1.494e-01, -1.010e-01, 4.138e-01, 8.749e-02, 3.619e-02));
	r += mul(s1_8, M4(-1.440e-02, -7.349e-02, -1.837e-02, -8.813e-02, 4.258e-03, -4.448e-02, -1.270e-01, 1.248e-01, 9.435e-02, 3.056e-02, 3.505e-02, 1.294e-01, -1.404e-01, 1.659e-01, -2.873e-02, -5.981e-02));
	r += V4(-3.291e-03, 8.133e-03, -7.168e-03, 9.168e-04);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-out
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
	r += mul(s0_0, M4(-1.086e-01, -4.058e-02, -4.103e-02, 1.626e-02, 1.159e-01, -2.460e-02, 6.220e-02, -2.406e-02, 2.017e-01, -3.954e-02, -1.552e-02, -9.234e-03, -1.795e-01, 2.156e-02, 4.201e-02, -2.053e-04));
	r += mul(s0_1, M4(-1.704e-01, -4.928e-02, -7.838e-02, -1.241e-02, -2.631e-01, -4.876e-02, -1.998e-01, 1.624e-02, -2.026e-01, 1.272e-01, -1.754e-01, -6.277e-02, 2.290e-01, 1.173e-02, 1.203e-01, -4.941e-02));
	r += mul(s0_2, M4(-5.969e-02, -5.362e-03, -3.342e-03, -1.910e-02, 1.018e-02, 3.233e-02, 1.383e-02, -9.791e-02, 4.993e-02, -5.600e-02, 5.886e-02, -4.129e-02, 1.246e-02, -6.932e-03, -3.472e-03, 5.262e-02));
	r += mul(s0_3, M4(6.288e-01, -3.339e-01, 7.450e-02, -1.460e-01, -3.945e-02, -2.779e-02, 1.168e-03, -3.724e-02, -3.646e-01, 1.042e-01, 4.152e-01, 7.834e-02, -3.955e-01, 6.816e-01, -6.934e-01, 4.542e-01));
	r += mul(s0_4, M4(2.212e-01, 1.300e-01, 9.111e-02, 2.798e-02, -1.426e-02, -6.178e-03, 6.041e-02, 6.853e-02, -5.821e-01, -1.022e+00, 7.308e-02, 4.189e-01, -7.677e-04, -1.440e-01, 1.184e-01, 2.346e-02));
	r += mul(s0_5, M4(-2.012e-02, 2.317e-02, -6.981e-02, 9.154e-02, -8.624e-03, -3.739e-02, -5.085e-02, 5.162e-02, 2.838e-02, 1.233e-01, 8.172e-02, 6.083e-02, -1.902e-03, 3.081e-02, 1.947e-02, -5.237e-02));
	r += mul(s0_6, M4(1.381e-01, -3.696e-01, 7.090e-01, -6.543e-01, 1.505e-02, 2.456e-02, 7.358e-03, 3.565e-02, -5.934e-02, -6.716e-03, 2.085e-01, -1.018e-01, 5.347e-02, -1.316e-01, 1.501e-01, 1.184e-01));
	r += mul(s0_7, M4(-1.564e-02, 1.453e-01, -7.031e-03, 1.558e-01, -8.033e-03, -4.512e-02, -5.432e-02, -1.265e-01, -6.068e-02, -1.323e-01, 3.485e-02, 4.087e-01, -1.316e-02, -1.277e-02, -3.699e-02, -1.583e-01));
	r += mul(s0_8, M4(3.764e-03, -2.731e-03, 4.817e-03, -3.713e-02, -9.970e-03, 1.266e-02, 2.006e-02, 5.019e-02, -7.491e-03, 4.686e-03, -1.686e-02, -4.818e-02, -9.742e-03, -2.561e-02, -1.049e-02, -3.142e-04));
	r += mul(s1_0, M4(-1.273e-01, 1.788e-03, -3.525e-02, -7.217e-03, 2.005e-01, -1.845e-02, 4.956e-02, -2.758e-02, 1.567e-01, -2.466e-02, 4.943e-02, -1.595e-02, -8.792e-02, 1.474e-02, -4.640e-02, 7.942e-05));
	r += mul(s1_1, M4(-1.861e-01, -9.674e-02, -6.250e-02, -1.786e-02, -4.062e-01, -4.489e-02, -1.588e-01, -7.198e-03, -2.079e-01, 7.010e-02, -9.694e-02, 4.139e-02, 3.582e-01, -1.251e-01, 9.156e-02, -3.674e-02));
	r += mul(s1_2, M4(-6.239e-02, -1.018e-02, -6.402e-03, -4.529e-02, 6.086e-02, -6.527e-02, 5.258e-03, -9.400e-02, 8.422e-02, -1.282e-02, 5.274e-02, -4.875e-02, -2.245e-03, 3.650e-02, -1.495e-03, 9.356e-02));
	r += mul(s1_3, M4(1.149e-01, 1.060e-02, -2.891e-02, -1.722e-03, -7.214e-02, -3.738e-02, -4.786e-03, -7.482e-02, 6.525e-02, -1.114e-02, 1.636e-01, -9.321e-03, -4.376e-02, 7.619e-02, -7.641e-02, 6.573e-02));
	r += mul(s1_4, M4(3.369e-01, 2.901e-01, 1.133e-01, -1.090e-04, -5.004e-01, -4.277e-01, 7.885e-01, 4.111e-01, -3.074e-01, -2.326e-01, -3.252e-01, -4.066e-02, -2.682e-01, 7.158e-02, 1.087e-01, 1.010e-04));
	r += mul(s1_5, M4(-3.774e-02, -1.073e-02, -7.789e-02, 1.052e-01, -2.665e-02, -2.270e-01, -1.181e-01, 3.682e-01, 3.117e-02, 2.649e-02, 7.247e-02, -1.127e-02, 6.208e-02, -2.289e-02, 5.765e-02, -1.538e-01));
	r += mul(s1_6, M4(-1.728e-02, -9.455e-02, -1.121e-02, -6.711e-02, 2.080e-02, 1.194e-02, 2.863e-02, 5.079e-02, 6.874e-03, 2.154e-02, 3.330e-02, 1.255e-02, -2.153e-03, -6.322e-03, -2.282e-03, 1.327e-02));
	r += mul(s1_7, M4(-2.142e-02, 2.290e-02, 7.642e-02, 2.437e-01, 7.130e-02, 4.816e-02, -1.304e-01, -1.722e-01, 2.383e-02, 3.324e-03, -2.380e-02, -1.179e-01, 7.097e-03, -3.188e-02, -7.251e-02, -5.194e-02));
	r += mul(s1_8, M4(1.427e-02, 1.259e-02, 2.218e-03, -7.785e-02, 7.022e-04, 2.594e-02, 2.190e-02, -1.751e-02, -2.179e-02, -2.237e-02, -2.178e-02, 4.427e-02, -1.539e-02, -2.098e-02, -1.414e-02, 3.443e-02));
	r += V4(2.022e-03, 1.537e-03, 1.652e-03, 1.091e-03);
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
//!DESC CuNNy-4x4C-CHROMA-NVL-shuffle
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

// CuNNy 0x4 NVL
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
//!FORMAT R16_FLOAT
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
//!FORMAT R16G16B16A16_FLOAT
Texture2D up_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R16G16B16A16_FLOAT
Texture2D down;

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
//!DESC CuNNy-0x4-NVL-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
float4 f0(float2 pt, float2 pos, float s0_0, float s0_1, float s0_2, float s0_3, float s0_4, float s0_5, float s0_6, float s0_7, float s0_8) {
	float4 r = 0.0;
	r += float4(-0.004851581063121557, 0.020280154421925545, -0.017170369625091553, 0.01635739393532276) * s0_0;
	r += float4(0.004682003986090422, 0.043670009821653366, 0.14730723202228546, 0.009648498147726059) * s0_1;
	r += float4(-0.0008447431027889252, -0.07153350859880447, 0.024954678490757942, 0.042468875646591187) * s0_2;
	r += float4(-0.08372588455677032, 0.003778755199164152, 0.2236550897359848, 0.10234526544809341) * s0_3;
	r += float4(-0.061135392636060715, -0.3073138892650604, -0.584021270275116, 0.06016957014799118) * s0_4;
	r += float4(0.013827483169734478, 0.48589080572128296, 0.021077442914247513, 0.02199917659163475) * s0_5;
	r += float4(0.595703125, -0.003579159267246723, -0.011138898320496082, 0.13256722688674927) * s0_6;
	r += float4(-0.0808781236410141, 0.003176655387505889, 0.17837458848953247, -0.5811895132064819) * s0_7;
	r += float4(-0.015837639570236206, -0.17832669615745544, 0.018508849665522575, -0.06764081120491028) * s0_8;
	r += float4(-0.3680674433708191, -0.004284880124032497, -0.004434608854353428, -0.0015339532401412725);
	return max(r, 0.0);
}
void Pass2(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	float s0_0 = l0(-1.0, -1.0);
	float s0_1 = l0(0.0, -1.0);
	float s0_2 = l0(1.0, -1.0);
	float s0_3 = l0(-1.0, 0.0);
	float s0_4 = l0(0.0, 0.0);
	float s0_5 = l0(1.0, 0.0);
	float s0_6 = l0(-1.0, 1.0);
	float s0_7 = l0(0.0, 1.0);
	float s0_8 = l0(1.0, 1.0);
	up_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 3
//!DESC CuNNy-0x4-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
float4 f0(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(-0.07432886958122253, 0.23917260766029358, -0.042066413909196854, 0.2503919303417206, -0.014960050582885742, 0.01987137459218502, -0.10096735507249832, -0.10185136646032333, 0.04286491125822067, 0.007723710965365171, 0.00160867755766958, 0.03494620323181152, -0.08186924457550049, -0.11126203089952469, 0.11262603104114532, -0.10968545079231262));
	r += mul(s0_1, float4x4(0.6040570735931396, -0.6445651650428772, 0.8715080618858337, -0.35667887330055237, 0.01539945974946022, -0.08773268759250641, 0.05619035288691521, 0.025895489379763603, 0.03764835745096207, 0.13037274777889252, 0.03907835856080055, 0.0471232607960701, -0.5212414860725403, 0.017234859988093376, -0.17659588158130646, 0.6434740424156189));
	r += mul(s0_2, float4x4(0.8486191630363464, 1.5410587787628174, -0.18357762694358826, 0.8530812859535217, -0.005569154862314463, -1.8565766595202149e-06, -0.019236711785197258, -0.016436422243714333, -0.005376997869461775, -0.014406684786081314, 0.006700459867715836, -0.01997162029147148, 0.35829034447669983, -0.21606706082820892, 0.3622962236404419, -0.3185916841030121));
	r += mul(s0_3, float4x4(0.0492740161716938, -0.024151695892214775, 0.02298620156943798, 0.004713376984000206, 0.3540244698524475, 0.16749273240566254, 0.4932180941104889, 0.348153293132782, 0.004494995344430208, 0.043147973716259, -0.06289655715227127, -0.004116372670978308, -0.011055417358875275, -0.028676224872469902, -0.1086282804608345, -0.02385811321437359));
	r += mul(s0_4, float4x4(0.07941664010286331, 0.35920023918151855, -0.0981743261218071, -0.06911690533161163, -0.23772406578063965, -0.114990234375, -0.20800594985485077, -0.07892715185880661, -0.32918596267700195, -0.4739086627960205, -0.4083307385444641, -0.5717554688453674, 0.0060420711524784565, 0.05787676200270653, -0.23832599818706512, -0.2817210257053375));
	r += mul(s0_5, float4x4(-0.47992604970932007, -0.6210984587669373, 0.41837766766548157, 0.39700746536254883, 0.042329370975494385, -0.015513257123529911, 0.047219954431056976, -0.021995246410369873, 0.07500537484884262, 0.22382818162441254, 0.04290112853050232, 0.19284768402576447, -0.10326827317476273, -0.054650578647851944, 0.11908520013093948, 0.1370934695005417));
	r += mul(s0_6, float4x4(-0.0084654800593853, -0.00011711619299603626, -0.03377988561987877, -0.004080520942807198, -0.042339082807302475, -0.028666488826274872, -0.02056884951889515, -2.4338085040653823e-06, -0.006036767736077309, 0.00016177991346921772, 0.049647100269794464, -0.005935635417699814, 0.011494332924485207, 0.02614094316959381, 0.008166692219674587, 0.014019805006682873));
	r += mul(s0_7, float4x4(-0.004522969014942646, -0.08799345046281815, 0.03370602801442146, -0.026857491582632065, 0.0005867392173968256, -0.006392867770045996, -0.0001306164194829762, -0.09174574166536331, 0.045832857489585876, 0.0493471659719944, 0.05410337448120117, 0.11341889202594757, -0.0006215291214175522, -0.012332734651863575, 0.01248207688331604, 0.03136883303523064));
	r += mul(s0_8, float4x4(0.09732473641633987, 0.10165663808584213, -0.13763731718063354, -0.11698565632104874, -0.002946216380223632, -0.01630318909883499, 0.014186597429215908, 0.01995275728404522, 0.01905190385878086, 0.03319168463349342, -0.007597479969263077, 0.021342189982533455, 0.01947663351893425, 0.021288534626364708, -0.016240470111370087, 0.0038068145513534546));
	r += float4(-1.249726633290038e-08, -1.3481491478728458e-08, -1.3743611582128779e-08, -7.579245675515267e-09);
	return tanh(r);
}
void Pass3(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	down[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 4
//!DESC CuNNy-0x4-NVL-shuffle
//!STYLE PS
//!IN down, INPUT, easu
float4 Pass4(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = down.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += easu.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

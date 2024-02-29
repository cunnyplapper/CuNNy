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
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	min16float s0_0 = l0(-1.0, -1.0);
	min16float s0_1 = l0(0.0, -1.0);
	min16float s0_2 = l0(1.0, -1.0);
	min16float s0_3 = l0(-1.0, 0.0);
	min16float s0_4 = l0(0.0, 0.0);
	min16float s0_5 = l0(1.0, 0.0);
	min16float s0_6 = l0(-1.0, 1.0);
	min16float s0_7 = l0(0.0, 1.0);
	min16float s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += min16float4(0.00924715306609869, 0.038207121193408966, -0.020873604342341423, -0.024839483201503754) * s0_0;
	r0 += min16float4(0.039208631962537766, 0.21705928444862366, 0.028840111568570137, -0.6633681654930115) * s0_1;
	r0 += min16float4(-0.027666732668876648, -0.037700340151786804, -0.00576166482642293, 0.46109965443611145) * s0_2;
	r0 += min16float4(-0.2143753170967102, 0.07654338330030441, 0.03170373663306236, 0.07560271769762039) * s0_3;
	r0 += min16float4(-0.017354430630803108, -0.5753283500671387, -0.1477627158164978, 0.009448401629924774) * s0_4;
	r0 += min16float4(0.015890605747699738, 0.21826152503490448, -0.06825762242078781, -0.08013129234313965) * s0_5;
	r0 += min16float4(0.4700002372264862, -0.011097591370344162, -0.015287264250218868, -0.026507526636123657) * s0_6;
	r0 += min16float4(-0.29858970642089844, 0.07722195982933044, -0.1264161467552185, -0.0022942733485251665) * s0_7;
	r0 += min16float4(0.0222779493778944, -0.004481158684939146, 0.611232578754425, 0.015151800587773323) * s0_8;
	r0 += float4(-0.00593371270224452, -0.0042357295751571655, -0.2880869507789612, -0.017349807545542717);
	up_0[gxy] = max(r0, 0.0);
}
void Pass2(uint2 blockStart, uint3 tid) {
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	};
	float2 pos = (gxy + 0.5) * GetInputPt();
	float2 step = 8 * GetInputPt();
	hook(gxy, pos);
}

//!PASS 3
//!DESC CuNNy-0x4-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	min16float4 s0_0 = l0(-1.0, -1.0);
	min16float4 s0_1 = l0(0.0, -1.0);
	min16float4 s0_2 = l0(1.0, -1.0);
	min16float4 s0_3 = l0(-1.0, 0.0);
	min16float4 s0_4 = l0(0.0, 0.0);
	min16float4 s0_5 = l0(1.0, 0.0);
	min16float4 s0_6 = l0(-1.0, 1.0);
	min16float4 s0_7 = l0(0.0, 1.0);
	min16float4 s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += mul(s0_0, min16float4x4(7.136147814890137e-07, 0.0232551246881485, -0.019142042845487595, 0.018575096502900124, 0.02032436802983284, -0.009146382100880146, -0.022402551025152206, 0.006305389106273651, 0.9959182739257812, 0.1103881374001503, 0.5018414855003357, -0.20702697336673737, -5.873792474631045e-07, -0.00045187215437181294, -0.002623731503263116, 0.014474006369709969));
	r0 += mul(s0_1, min16float4x4(-0.11271093040704727, -0.19890151917934418, 0.009407544508576393, -0.18603889644145966, 0.022691044956445694, 0.020214226096868515, 0.022656096145510674, 0.013107986189424992, -0.44050267338752747, 0.41482898592948914, -0.3076260983943939, 0.623837947845459, -0.012565563432872295, 0.026660511270165443, -0.048633456230163574, -0.01549263671040535));
	r0 += mul(s0_2, min16float4x4(0.2246379256248474, 0.46386948227882385, 0.09306088835000992, 0.4150044918060303, -0.010679204016923904, 0.0035062129609286785, -0.0003633795422501862, -0.025364946573972702, 0.1323239803314209, 0.0005052969208918512, 0.13151130080223083, -0.03552946448326111, 0.00012125217472203076, -0.001805314444936812, -0.0011098218383267522, -0.00718398904427886));
	r0 += mul(s0_3, min16float4x4(-0.008021589368581772, -0.007042094133794308, 0.018873926252126694, -0.001588323968462646, 0.09914080798625946, 0.048186954110860825, 0.2466808557510376, 0.07155971229076385, -0.4191240668296814, -0.19484111666679382, 0.13567928969860077, 0.16066285967826843, -0.15569089353084564, 0.14916500449180603, -0.06633464246988297, 0.11645606905221939));
	r0 += mul(s0_4, min16float4x4(0.041039492934942245, 0.08497539907693863, -0.18503530323505402, 0.01547167357057333, -0.4951120615005493, -0.3555728495121002, -0.5839827060699463, -0.3182041049003601, 0.2447267323732376, -0.010953318327665329, -0.15718141198158264, -0.25155967473983765, -0.0017690859967842698, -0.08967605233192444, -0.008083105087280273, 0.080329030752182));
	r0 += mul(s0_5, min16float4x4(-0.10456275194883347, -0.14208096265792847, -0.05262462794780731, -0.15599103271961212, 0.03109276480972767, -0.040178071707487106, 0.08029258251190186, -0.010326274670660496, -0.046494681388139725, 0.010605796240270138, -0.06253906339406967, -0.029032837599515915, 0.004491904284805059, 0.0015918747521936893, 0.01192846056073904, 0.0077809737995266914));
	r0 += mul(s0_6, min16float4x4(-0.0014832824235782027, 1.0672727057681186e-06, -0.031207697466015816, -0.001305579673498869, 0.0033222658094018698, 0.00599463377147913, 3.6584642657544464e-05, -0.006175443064421415, 0.060877420008182526, 0.05501212924718857, -0.0323278084397316, -0.0437740720808506, 0.01561818178743124, 0.1040860190987587, -0.12430497258901596, 0.0925167053937912));
	r0 += mul(s0_7, min16float4x4(-0.0011547424364835024, -0.02244466543197632, 0.03346090018749237, -0.005484660621732473, 0.09711696207523346, 0.09477312862873077, 0.2709640562534332, 0.14502239227294922, -0.08980292826890945, -0.010286670178174973, -0.027474641799926758, 0.039293233305215836, 0.2933723032474518, -0.3525400161743164, 0.3604806661605835, -0.5146887898445129));
	r0 += mul(s0_8, min16float4x4(0.001906093442812562, 0.004124681930989027, -0.00013742722512688488, 0.0002937166718766093, 0.032518986612558365, 0.031112603843212128, 0.04593341797590256, 0.14209727942943573, 0.0010889561381191015, -0.013661902397871017, -0.015405254438519478, -0.054452504962682724, -0.0620708093047142, 0.016669273376464844, -0.1015889123082161, -0.0008634442347101867));
	r0 += float4(-1.507284785873253e-08, -1.3929358999575925e-08, -1.4737486786486897e-08, -1.4379438084688445e-08);
	down[gxy] = tanh(r0);
}
void Pass3(uint2 blockStart, uint3 tid) {
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	};
	float2 pos = (gxy + 0.5) * GetInputPt();
	float2 step = 8 * GetInputPt();
	hook(gxy, pos);
}

//!PASS 4
//!DESC CuNNy-0x4-NVL-shuffle
//!STYLE PS
//!IN down, easu, INPUT
float4 Pass4(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float2x3 rgb2uv = {-0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	int2 i = int2(f * 2.0);
	r.r = down.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += easu.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float2 uv = mul(rgb2uv, INPUT.SampleLevel(SL, pos, 0).rgb);
	float3 px = mul(yuv2rgb, float3(r.r, uv));
	return float4(px, 1.0);
}

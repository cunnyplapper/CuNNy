// CuNNy 1x4 RCAS NVL
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

//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
//!FORMAT R8_UNORM
Texture2D rcas;

//!SAMPLER
//!FILTER POINT
SamplerState SP;

//!SAMPLER
//!FILTER LINEAR
SamplerState SL;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_UNORM
Texture2D up_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_UNORM
Texture2D conv1_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
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
//!DESC CuNNy-RCAS
//!STYLE PS
//!IN easu
//!OUT rcas

// CuNNy: do not change unless changed during training as well
#define SHARPNESS 2.0
#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0))

float APrxMedRcpF1(float a) {
	float b = asfloat(uint(0x7ef19fff) - asuint(a));
	return b * (-b * a + 2.0);
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z)); 
}


float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

float4 Pass2(float2 pos) {
	float2 pt = float2(GetInputPt());
	float2 size = float2(GetInputSize());
	float3 bde = easu.Gather(SP, pos + pt * float2(-0.5, -0.5), 0).xyz;
	float b = bde.z;
	float d = bde.x;
	float e = bde.y;
	float2 fh = easu.Gather(SP, pos + pt * float2(0.5, 0.5), 0).zx;
	float f = fh.x;
	float h = fh.y;
	float mn1L = min(AMin3F1(b, d, f), h);
	float mx1L = max(AMax3F1(b, d, f), h);
	float2 peakC = float2(1.0, -1.0 * 4.0);
	float hitMinL = min(mn1L, e) / (4.0 * mx1L);
	float hitMaxL = (peakC.x - max(mx1L, e)) / (4.0 * mn1L + peakC.y);
	float lobeL = max(-hitMinL, hitMaxL);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(lobeL, 0.0)) * exp2(-clamp(float(SHARPNESS), 0.0, 2.0));
	float nz = 0.25 * b + 0.25 * d + 0.25 * f + 0.25 * h - e;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(b, d, e), f, h) - AMin3F1(AMin3F1(b, d, e), f, h)), 0.0, 1.0);
	nz = -0.5 * nz + 1.0;
	lobe *= nz;
	float rcpL = APrxMedRcpF1(4.0 * lobe + 1.0);
	float4 pix = float4(0.0, 0.0, 0.0, 1.0);
	pix.r = float((lobe * b + lobe * d + lobe * h + lobe * f + e) * rcpL);
	return pix;
}

//!PASS 3
//!DESC CuNNy-1x4-RCAS-NVL-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	min16float4 r = 0.0;
	r += min16float4(0.004724545404314995, 0.021491261199116707, -0.07953549921512604, 0.13206122815608978) * s0_0;
	r += min16float4(0.3447265326976776, -0.019133031368255615, 0.06713927537202835, 0.26961857080459595) * s0_1;
	r += min16float4(-0.018056808039546013, 0.4039727747440338, -0.019536364823579788, -0.13909831643104553) * s0_2;
	r += min16float4(0.2724606394767761, 0.04482167959213257, -0.5321635007858276, 0.2939452826976776) * s0_3;
	r += min16float4(-0.5456479787826538, 0.09887687116861343, 0.24657918512821198, -0.21264593303203583) * s0_4;
	r += min16float4(-0.030031884089112282, -0.40917959809303284, -0.029801949858665466, -0.12516024708747864) * s0_5;
	r += min16float4(-0.05646182969212532, 0.02217874303460121, 0.28027406334877014, -0.2564420998096466) * s0_6;
	r += min16float4(-0.026481879875063896, 0.051179058849811554, 0.08372259140014648, -0.19269230961799622) * s0_7;
	r += min16float4(0.05969257280230522, -0.0020228989887982607, 0.022553104907274246, 0.23634138703346252) * s0_8;
	r += float4(-0.0017120400443673134, -0.0070196776650846004, -0.0008808173588477075, -0.01706847921013832);
	return max(r, 0.0);
}
void Pass3(uint2 blockStart, uint3 tid) {
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
	up_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 4
//!DESC CuNNy-1x4-RCAS-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT conv1_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(-0.08294564485549927, -0.0359703004360199, 0.39169400930404663, 0.07130355387926102, 0.0073567405343055725, 0.018841158598661423, 0.7636719942092896, 0.052295513451099396, -0.064346082508564, -0.3195393681526184, 0.0714590847492218, 0.035269271582365036, 0.08666952699422836, -0.21246467530727386, -0.5611945390701294, 0.003745915135368705));
	r += mul(s0_1, min16float4x4(-0.014253582805395126, 0.23104320466518402, -1.1917248964309692, 1.2460932731628418, -0.012715131044387817, 0.27562275528907776, -0.005932768806815147, -0.03078816644847393, -0.045149821788072586, 0.3411799967288971, 0.31542953848838806, 0.06463712453842163, -0.044294681400060654, -0.8121047019958496, 0.29958996176719666, -0.4573328197002411));
	r += mul(s0_2, min16float4x4(-0.05359422415494919, -0.5917116403579712, -0.346327006816864, 0.32261180877685547, -0.022265600040555, 0.03848269581794739, 0.06991158425807953, 0.04168599098920822, -0.06528810411691666, -0.22741973400115967, 0.2075149416923523, 0.548828125, -0.031861767172813416, -0.12685425579547882, 0.11646086722612381, -0.41958528757095337));
	r += mul(s0_3, min16float4x4(-0.13228310644626617, -0.375247985124588, -0.31155112385749817, 0.14922137558460236, 0.40310874581336975, 0.3575841188430786, -0.09333069622516632, -0.4279249310493469, 0.08023377507925034, -0.2291308045387268, -0.007615513633936644, -0.08376001566648483, 0.021396411582827568, 0.29003748297691345, -0.2467232346534729, -0.08130072802305222));
	r += mul(s0_4, min16float4x4(0.9805644750595093, 0.7792000770568848, 0.230812668800354, 0.5449215769767761, -0.1848783791065216, -0.33016327023506165, -0.12182717770338058, 0.1564367264509201, -0.27245742082595825, -0.10899618268013, -0.09962121397256851, -0.14404477179050446, -0.15760716795921326, -0.8421685695648193, -0.3934021294116974, -0.3791804313659668));
	r += mul(s0_5, min16float4x4(0.583534836769104, -0.42291852831840515, 0.3388614356517792, -0.011924570426344872, 0.025694523006677628, -0.015683481469750404, -0.014849604107439518, -0.04205711558461189, 0.7152243256568909, 0.028341980651021004, -0.003972489852458239, -0.0725090280175209, -0.4847440719604492, -0.2998051643371582, -0.40722519159317017, 0.013261884450912476));
	r += mul(s0_6, min16float4x4(0.0950051099061966, 0.0037782059516757727, 0.2548831105232239, 0.09160754084587097, -0.13134826719760895, 0.2761126756668091, -0.23677556216716766, 0.08655694872140884, 0.04497039318084717, -0.0181284137070179, 0.018151070922613144, -0.033566515892744064, -0.11110968887805939, 0.03736519068479538, -0.14612798392772675, -0.0125533202663064));
	r += mul(s0_7, min16float4x4(0.685587465763092, 0.09424187242984772, 0.1274326890707016, -0.03784702345728874, -0.09387119114398956, -0.44125935435295105, -0.34068191051483154, 0.12420087307691574, -0.10760889202356339, -0.03975064307451248, -0.05248849466443062, -0.0062246788293123245, -0.40332865715026855, -0.1410427838563919, -0.05156387761235237, 0.016487276181578636));
	r += mul(s0_8, min16float4x4(0.3777735233306885, 0.3983982801437378, 0.38800761103630066, -0.22218561172485352, -0.017590617761015892, -0.08520273119211197, -0.06447017192840576, 0.01350427232682705, -0.008783902041614056, 0.10568772256374359, -0.03162536770105362, 0.06080583482980728, -0.12376760691404343, -0.13821262121200562, -0.13330182433128357, 0.06567621231079102));
	r += float4(-0.02643583156168461, -0.019344288855791092, -0.017616890370845795, -0.025451190769672394);
	return max(r, 0.0);
}
void Pass4(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	min16float4 s0_0 = l0(-1.0, -1.0);
	min16float4 s0_1 = l0(0.0, -1.0);
	min16float4 s0_2 = l0(1.0, -1.0);
	min16float4 s0_3 = l0(-1.0, 0.0);
	min16float4 s0_4 = l0(0.0, 0.0);
	min16float4 s0_5 = l0(1.0, 0.0);
	min16float4 s0_6 = l0(-1.0, 1.0);
	min16float4 s0_7 = l0(0.0, 1.0);
	min16float4 s0_8 = l0(1.0, 1.0);
	conv1_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 5
//!DESC CuNNy-1x4-RCAS-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN conv1_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(conv1_0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(0.01725214533507824, -0.06188873574137688, 0.017493244260549545, -0.017497826367616653, 0.12349818646907806, -0.0038133058696985245, 0.05674322322010994, -0.0305812768638134, 0.08671078830957413, -0.0056568835861980915, 0.018570898100733757, 0.0066062393598258495, -0.002133607165887952, -2.0668663637479767e-05, -8.763012715462537e-08, -1.2374081848065543e-07));
	r += mul(s0_1, min16float4x4(-0.3763314187526703, -0.3840506970882416, 0.11495553702116013, 0.05339721217751503, -0.08912231773138046, -0.19383272528648376, 0.14012135565280914, 0.06692157685756683, -0.03897683694958687, 0.056490298360586166, -0.021278107538819313, -0.0084603950381279, -0.012100385501980782, -0.003526516957208514, 3.1270403155758686e-07, -2.1677931272279238e-07));
	r += mul(s0_2, min16float4x4(-0.12368972599506378, -0.008565804921090603, 0.015461884438991547, 0.1478700041770935, -0.061706531792879105, 0.2901228368282318, -0.09106435626745224, 0.03297174721956253, -0.017525125294923782, -0.04377048835158348, -0.0019477662863209844, -0.009891988709568977, 0.0004910569987259805, -1.548979042809151e-07, -4.3874837984958504e-08, 8.205147992157436e-07));
	r += mul(s0_3, min16float4x4(-0.19043634831905365, 0.18230809271335602, -0.2726823091506958, 0.05480972304940224, 0.1242842897772789, -0.1831226795911789, 0.14505387842655182, -0.11116424202919006, -0.15772387385368347, 0.07905257493257523, 0.15379536151885986, 0.022190513089299202, 0.039924487471580505, 0.006634382531046867, -0.047904253005981445, 0.0010038921609520912));
	r += mul(s0_4, min16float4x4(0.8310983180999756, -0.10404778271913528, -0.1831064224243164, -1.0897223949432373, -0.8964841365814209, 1.191419005393982, -0.7339694499969482, 0.27485302090644836, -0.1050029769539833, -0.4387669861316681, 0.5097638368606567, 0.3955126404762268, 0.42285194993019104, 0.6035153865814209, -0.15673291683197021, -0.058413583785295486));
	r += mul(s0_5, min16float4x4(-0.02856150083243847, 0.3593575358390808, -0.09576347470283508, 0.31152045726776123, 0.3623196482658386, -0.6863964200019836, 0.04499776288866997, 0.26301437616348267, 0.15293163061141968, 0.05198543891310692, -0.03481515869498253, 0.03695295751094818, 0.15850085020065308, 0.024768969044089317, 0.010479501448571682, -0.15185490250587463));
	r += mul(s0_6, min16float4x4(0.006519956514239311, 0.025176167488098145, 0.033350858837366104, 0.03533882275223732, -0.06702595949172974, -0.0012947184732183814, -0.12063832581043243, -0.08303916454315186, 0.06090151518583298, -0.06621448695659637, 0.21337777376174927, 0.008943228051066399, 0.3271462917327881, -0.13454611599445343, 0.5866900682449341, -0.05756550654768944));
	r += mul(s0_7, min16float4x4(-0.025211205706000328, -0.004819000605493784, 0.2182609885931015, 0.17428597807884216, 0.16660843789577484, -0.21924081444740295, -0.08559373766183853, 0.25074073672294617, 0.19268882274627686, 0.4544924795627594, -1.3945491313934326, -0.19675499200820923, -1.1367188692092896, -0.2841781675815582, -0.24446037411689758, 1.018427848815918));
	r += mul(s0_8, min16float4x4(3.9907753546231106e-08, -0.03446844965219498, -0.015484295785427094, 0.03870821371674538, 0.20943492650985718, -0.22813519835472107, 0.7408512234687805, -0.7062113881111145, 0.1262902170419693, 0.1304367184638977, 0.32802823185920715, -0.7520469427108765, 0.05866508558392525, -0.19968974590301514, 0.13429349660873413, -0.27832019329071045));
	r += float4(-8.232365011906495e-09, -7.363015086525593e-09, -1.0732277289093872e-08, -1.1064225091672597e-08);
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
	min16float4 s0_0 = l0(-1.0, -1.0);
	min16float4 s0_1 = l0(0.0, -1.0);
	min16float4 s0_2 = l0(1.0, -1.0);
	min16float4 s0_3 = l0(-1.0, 0.0);
	min16float4 s0_4 = l0(0.0, 0.0);
	min16float4 s0_5 = l0(1.0, 0.0);
	min16float4 s0_6 = l0(-1.0, 1.0);
	min16float4 s0_7 = l0(0.0, 1.0);
	min16float4 s0_8 = l0(1.0, 1.0);
	down[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 6
//!DESC CuNNy-1x4-RCAS-NVL-shuffle
//!STYLE PS
//!IN down, INPUT, rcas
float4 Pass6(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = down.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += rcas.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

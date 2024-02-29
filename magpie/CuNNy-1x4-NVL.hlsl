// CuNNy 1x4 NVL
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
Texture2D conv1_0;

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
//!DESC CuNNy-1x4-NVL-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	float s0_0 = l0(-1.0, -1.0);
	float s0_1 = l0(0.0, -1.0);
	float s0_2 = l0(1.0, -1.0);
	float s0_3 = l0(-1.0, 0.0);
	float s0_4 = l0(0.0, 0.0);
	float s0_5 = l0(1.0, 0.0);
	float s0_6 = l0(-1.0, 1.0);
	float s0_7 = l0(0.0, 1.0);
	float s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += float4(-0.04073860123753548, 0.0031418227590620518, 0.0025088239926844835, -0.07493328303098679) * s0_0;
	r0 += float4(-0.00024427167954854667, -0.001506536966189742, 0.4579133689403534, -0.1684122383594513) * s0_1;
	r0 += float4(-0.033533018082380295, 0.004569887649267912, -0.0068548284471035, -0.09545999020338058) * s0_2;
	r0 += float4(0.06900110840797424, 0.016049545258283615, 0.009361494332551956, -0.2822263538837433) * s0_3;
	r0 += float4(0.6620897650718689, 0.46382617950439453, -0.45273515582084656, 0.7056611180305481) * s0_4;
	r0 += float4(-0.4654645621776581, -0.583805501461029, 0.00539256539195776, -0.056711722165346146) * s0_5;
	r0 += float4(0.004335780628025532, -0.007457214407622814, 0.0760497897863388, -0.01427238155156374) * s0_6;
	r0 += float4(0.0803091824054718, 0.007855698466300964, -0.09091761708259583, -0.08325354754924774) * s0_7;
	r0 += float4(-0.06908505409955978, 0.10131645947694778, 0.0072466181591153145, 0.06875059008598328) * s0_8;
	r0 += float4(-0.010758671909570694, -0.0028171020094305277, 0.0029506145510822535, 0.004212047904729843);
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
//!DESC CuNNy-1x4-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT conv1_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += mul(s0_0, float4x4(-0.10291248559951782, -0.12475423514842987, -0.2905051112174988, 0.21731795370578766, -0.02649296261370182, 0.33098548650741577, 0.4284626245498657, -0.09663953632116318, 0.03667076677083969, -0.034224145114421844, -0.123809814453125, -0.22509847581386566, -0.5742507576942444, -0.013319707475602627, 0.03475603461265564, -0.13134169578552246));
	r0 += mul(s0_1, float4x4(-0.10026349127292633, 0.03531487286090851, -0.2250937670469284, 0.13524800539016724, -0.1566200852394104, -0.0643836110830307, 0.23998694121837616, 0.14609180390834808, -0.2299424558877945, -0.01040893979370594, -0.014718040823936462, -0.28613096475601196, -0.16388019919395447, -0.21976901590824127, 0.026791030541062355, -0.04672962799668312));
	r0 += mul(s0_2, float4x4(0.024466080591082573, 0.5644484162330627, 0.028157493099570274, -0.08569754660129547, -0.09731350094079971, -0.907691478729248, -0.13102668523788452, 0.025767825543880463, 0.053584836423397064, -0.024841846898198128, 0.0015322610270231962, -0.23076564073562622, -0.007878176867961884, 0.108140729367733, 0.03886057808995247, 0.026432611048221588));
	r0 += mul(s0_3, float4x4(-0.053335532546043396, -0.01921962946653366, -0.02269698493182659, 0.021419089287519455, 0.26530060172080994, 0.06956620514392853, 0.6548494696617126, 0.21331627666950226, -0.027568424120545387, -0.19704072177410126, 0.20479270815849304, -0.2047959566116333, -0.4599336087703705, 0.022624429315328598, -0.07730555534362793, 0.24468213319778442));
	r0 += mul(s0_4, float4x4(-0.09339038282632828, -0.15280592441558838, -0.452144593000412, -0.5317398309707642, -0.04904531314969063, 0.16329045593738556, 0.18722838163375854, 0.31740427017211914, -0.09018880128860474, 0.1370542198419571, 0.6829801797866821, 0.5214859843254089, -0.26390647888183594, -0.2602298855781555, -0.40917959809303284, -1.7771849632263184));
	r0 += mul(s0_5, float4x4(0.05515620857477188, -0.4872879385948181, 0.4037289321422577, -0.12620367109775543, -0.18161442875862122, 0.09186321496963501, -0.3115255534648895, 0.04923097416758537, -0.07446859031915665, -0.22087416052818298, 0.0807470828294754, 0.3583984076976776, -0.12406127899885178, -0.5679275989532471, 0.2568650245666504, 0.4213470220565796));
	r0 += mul(s0_6, float4x4(-0.09270458668470383, 0.2446281909942627, 0.19363367557525635, 0.013280647806823254, 0.04175181686878204, -0.5306519865989685, -0.18582436442375183, -0.008397592231631279, 0.04461114481091499, -0.08512291312217712, -0.009648537263274193, -0.02486378140747547, -0.6884589195251465, -0.02955680526793003, 0.055315908044576645, -0.0818747729063034));
	r0 += mul(s0_7, float4x4(-0.03529584780335426, -0.035779185593128204, 0.24024799466133118, 0.22174294292926788, -0.13577239215373993, 0.09692256897687912, -0.28033313155174255, -0.06009304150938988, -0.03862312436103821, -4.464022159576416, -0.34275591373443604, 0.132280170917511, -0.22674909234046936, 0.4243437349796295, 0.31152045726776123, -0.07801436632871628));
	r0 += mul(s0_8, float4x4(-0.14632727205753326, -0.013381818309426308, 0.04608479514718056, 0.09252949804067612, -0.08321044594049454, 0.1401156485080719, -0.21749486029148102, -0.029814492911100388, -0.07052794843912125, 0.3803689181804657, -0.29211661219596863, 0.0950375646352768, -0.02743336744606495, 0.19862602651119232, 0.13317245244979858, 0.24064671993255615));
	r0 += float4(-0.05882386118173599, -0.007358903530985117, -0.007672747131437063, -0.009486258961260319);
	conv1_0[gxy] = max(r0, 0.0);
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
//!DESC CuNNy-1x4-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN conv1_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(conv1_0, float2(x, y))
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += mul(s0_0, float4x4(-0.03381248936057091, 0.026028674095869064, -0.11955983936786652, -0.046017300337553024, 0.012334560975432396, -0.06992269307374954, 0.31234225630760193, 0.1401185244321823, 0.03676026687026024, -0.025488805025815964, -0.020079275593161583, 0.0009328287560492754, -0.054027121514081955, 0.017512036487460136, -0.04968009516596794, -0.0017360999481752515));
	r0 += mul(s0_1, float4x4(-0.13057540357112885, 0.10470928996801376, -0.07792159914970398, 0.013323039747774601, 0.15791055560112, 0.3451332151889801, -0.03886963427066803, 0.1621011346578598, 0.14990514516830444, 0.22618752717971802, -0.04726763069629669, -0.02221895009279251, -0.020607467740774155, -0.21827882528305054, 0.07344894856214523, 0.019290665164589882));
	r0 += mul(s0_2, float4x4(0.285689115524292, -0.14773105084896088, 0.060363635420799255, -0.22513610124588013, -0.019564902409911156, -0.06592144072055817, 6.334299769150675e-07, -0.01359024178236723, 0.044757138937711716, 0.029524553567171097, 0.0014839725336059928, -0.04773401841521263, -0.05456343665719032, 0.040025729686021805, -3.701957439261605e-06, 0.016492418944835663));
	r0 += mul(s0_3, float4x4(0.04204890877008438, 0.014488765969872475, -0.044871799647808075, 0.03388179466128349, 0.38379088044166565, 0.6660271883010864, -0.9981223344802856, -0.21155674755573273, 0.18797141313552856, -0.11793976277112961, 0.30417636036872864, -0.05402308702468872, -0.08225052058696747, 0.17816627025604248, -0.11890944838523865, 0.1390596181154251));
	r0 += mul(s0_4, float4x4(-0.044742461293935776, 0.05760403722524643, -0.22418475151062012, 0.06228502467274666, 0.13825157284736633, -0.3464587330818176, 0.5125047564506531, -0.4267224669456482, -0.8371074199676514, -0.16501614451408386, -0.20562875270843506, 0.34082725644111633, 0.4695666432380676, -0.2916196882724762, -0.08787744492292404, -0.8120425343513489));
	r0 += mul(s0_5, float4x4(0.04284217208623886, 0.04364683851599693, 0.29910334944725037, 0.018818486481904984, -0.04311728477478027, 0.046668969094753265, -0.0788961797952652, -0.016890760511159897, 0.04084537923336029, -0.18112608790397644, 0.08321096003055573, 0.004356801975518465, -0.03143000975251198, 0.3095701336860657, -0.05849248170852661, 0.2206086665391922));
	r0 += mul(s0_6, float4x4(-0.04572898894548416, 0.02072281390428543, -0.04246965050697327, 0.043030742555856705, -0.1682433933019638, -0.20580440759658813, 0.17033150792121887, 0.012434943579137325, 0.08861608803272247, 0.015218887478113174, 0.014116873033344746, -0.0878935232758522, -0.09731610864400864, -4.3389252368797315e-07, -0.01888367161154747, 0.09351331740617752));
	r0 += mul(s0_7, float4x4(0.03472069278359413, 0.013776621781289577, -0.11265731602907181, 0.03774480149149895, -0.07360633462667465, -0.10224991291761398, 0.04558949917554855, 0.058991607278585434, 0.16161435842514038, 0.21533244848251343, -0.20410241186618805, 0.017695359885692596, -0.0499751940369606, -0.0922340378165245, 0.40525704622268677, 0.14941366016864777));
	r0 += mul(s0_8, float4x4(0.08479824662208557, -0.07805343717336655, 0.048690780997276306, -0.02352161891758442, -0.030685313045978546, 0.013474876992404461, -0.06008579581975937, 0.011758618988096714, -0.008119842037558556, 0.021448323503136635, -0.019661379978060722, -0.0847221314907074, 5.363719424167357e-07, -0.03348744288086891, 4.254754912835779e-06, 0.13038387894630432));
	r0 += float4(-1.4834814265896057e-08, -1.2576228058946981e-08, -1.0221950397237833e-08, -1.4724273356137019e-08);
	down[gxy] = tanh(r0);
}
void Pass4(uint2 blockStart, uint3 tid) {
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	};
	float2 pos = (gxy + 0.5) * GetInputPt();
	float2 step = 8 * GetInputPt();
	hook(gxy, pos);
}

//!PASS 5
//!DESC CuNNy-1x4-NVL-shuffle
//!STYLE PS
//!IN down, easu, INPUT
float4 Pass5(float2 pos) {
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

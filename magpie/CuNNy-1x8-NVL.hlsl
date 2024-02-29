// CuNNy 1x8 NVL
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
Texture2D up_1;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R16G16B16A16_FLOAT
Texture2D conv1_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R16G16B16A16_FLOAT
Texture2D conv1_1;

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
//!DESC CuNNy-1x8-NVL-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0, up_1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
float4 f0(float2 pt, float2 pos, float s0_0, float s0_1, float s0_2, float s0_3, float s0_4, float s0_5, float s0_6, float s0_7, float s0_8) {
	float4 r = 0.0;
	r += float4(-0.013644934631884098, 0.00490080751478672, -0.008306958712637424, -0.036738522350788116) * s0_0;
	r += float4(0.2763671875, -0.00031897687586024404, -0.1538085788488388, 0.03166325390338898) * s0_1;
	r += float4(0.2880858778953552, -0.0011848803842440248, 0.017634037882089615, -0.001724904403090477) * s0_2;
	r += float4(0.01666208729147911, -0.3748655617237091, 0.05050073191523552, 0.07783371955156326) * s0_3;
	r += float4(-0.1850813627243042, 0.3731716573238373, -0.23495768010616302, 0.3834061920642853) * s0_4;
	r += float4(-0.23627740144729614, -0.00042464438593015075, 0.4873620271682739, -0.027764182537794113) * s0_5;
	r += float4(0.034566279500722885, 0.02569630928337574, -0.014133798889815807, 0.0574963316321373) * s0_6;
	r += float4(-0.11519026756286621, -0.02565866708755493, -0.13665688037872314, -0.507682204246521) * s0_7;
	r += float4(-0.06620240211486816, -0.001452566240914166, -0.001526359119452536, 0.02409147471189499) * s0_8;
	r += float4(-0.0026169167831540108, 0.0006035896367393434, 0.0032045503612607718, -0.0005726934759877622);
	return max(r, 0.0);
}
float4 f1(float2 pt, float2 pos, float s0_0, float s0_1, float s0_2, float s0_3, float s0_4, float s0_5, float s0_6, float s0_7, float s0_8) {
	float4 r = 0.0;
	r += float4(0.034790001809597015, 0.11724281311035156, 0.06774251163005829, -0.09535032510757446) * s0_0;
	r += float4(-0.2025008499622345, -0.07560485601425171, 0.09320803731679916, 0.041266921907663345) * s0_1;
	r += float4(0.057739146053791046, -0.04479416459798813, 0.06853388994932175, 0.06459034234285355) * s0_2;
	r += float4(-0.05968587100505829, 0.014204958453774452, 0.0470612533390522, -0.29071512818336487) * s0_3;
	r += float4(0.42219051718711853, 0.46954113245010376, -0.4292093515396118, 0.5729925632476807) * s0_4;
	r += float4(-0.20871679484844208, -0.19873039424419403, -0.23118169605731964, -0.10023327171802521) * s0_5;
	r += float4(0.02815629541873932, -0.05596989393234253, -0.030184542760252953, 0.035478949546813965) * s0_6;
	r += float4(0.04813220351934433, -0.30823132395744324, 0.2607421875, -0.006180679891258478) * s0_7;
	r += float4(-0.11938463151454926, 0.08973480761051178, 0.1514909714460373, -0.2133791595697403) * s0_8;
	r += float4(0.0006282788817770779, 0.0019429493695497513, 0.0005773864686489105, 0.0002814282779581845);
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
	up_1[gxy] = f1(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 3
//!DESC CuNNy-1x8-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0, up_1
//!OUT conv1_0, conv1_1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
#define l1(x, y) O(up_1, float2(x, y))
float4 f0(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8, float4 s1_0, float4 s1_1, float4 s1_2, float4 s1_3, float4 s1_4, float4 s1_5, float4 s1_6, float4 s1_7, float4 s1_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(-0.04747803881764412, 0.03243304416537285, 0.14791937172412872, -0.3248451054096222, 0.06706924736499786, -0.0017671744571998715, -0.4784604609012604, 0.19322726130485535, -0.03207625821232796, 0.018388643860816956, 0.0462004579603672, -0.06149958446621895, -0.09249042719602585, -0.033799514174461365, -0.4257282316684723, 0.41616639494895935));
	r += mul(s0_1, float4x4(0.006534276530146599, -0.02531525492668152, -0.18312083184719086, -0.06688264012336731, -0.274238646030426, 0.10069340467453003, -0.2977242171764374, 0.29356399178504944, -0.07213596999645233, 0.004786141682416201, -0.23397760093212128, 0.09697817265987396, -0.8600873947143555, 0.16332800686359406, 0.2954930067062378, 0.507860004901886));
	r += mul(s0_2, float4x4(-0.032774560153484344, 0.07087026536464691, -0.000983016681857407, -0.05391189455986023, 0.2836061418056488, 0.17080718278884888, 0.5644605755805969, -0.010410310700535774, 0.05492015182971954, -0.06840625405311584, 0.0822753831744194, 0.08015073835849762, 0.8066405653953552, -0.31201720237731934, 0.491599977016449, 0.251858651638031));
	r += mul(s0_3, float4x4(0.2041958123445511, -0.012438882142305374, 0.2997087240219116, -0.11632716655731201, -0.03015940636396408, -0.14208289980888367, -0.14651711285114288, 0.0264568030834198, 0.40296491980552673, -0.11004520207643509, -0.20433540642261505, -0.5299408435821533, -0.1570073664188385, -0.2415541261434555, -0.17236317694187164, 0.06635916233062744));
	r += mul(s0_4, float4x4(-0.8111625909805298, 0.10127294808626175, -0.6944230794906616, -0.006512433290481567, -0.5674680471420288, -0.28417906165122986, -0.14874334633350372, 0.30766424536705017, -1.2027158737182617, 0.3435490131378174, -0.32540270686149597, -0.5710787773132324, -0.2607068419456482, -0.1312481164932251, 0.3380521833896637, 0.07777133584022522));
	r += mul(s0_5, float4x4(-0.1060618981719017, 0.08443973958492279, -0.08300669491291046, -0.13708139955997467, -1.5281809568405151, -0.9472684264183044, 0.8870436549186707, 0.634765625, 0.1611928939819336, -0.04212981089949608, -0.1910049468278885, -0.18210957944393158, 0.540547788143158, -0.05358799919486046, 0.48176389932632446, -0.07020644843578339));
	r += mul(s0_6, float4x4(0.31251341104507446, -0.25394102931022644, -0.06951192021369934, 0.1376856565475464, -0.07102978974580765, 0.22375960648059845, -0.15115056931972504, 0.006994254421442747, 0.17335447669029236, -0.24169227480888367, -0.006778377573937178, 0.22254763543605804, -0.11353041976690292, 0.13108764588832855, -0.012864199467003345, -0.1690048724412918));
	r += mul(s0_7, float4x4(-0.19440437853336334, -0.08721719682216644, -0.12642356753349304, -0.010093193501234055, -0.11691804230213165, 0.2918252944946289, 0.003734422381967306, -1.0351886749267578, -0.11474626511335373, -0.9598027467727661, 0.07313375174999237, 0.5292969346046448, -0.005923145450651646, -0.0779670774936676, 0.005391339305788279, -0.3979977071285248));
	r += mul(s0_8, float4x4(-0.16023503243923187, -0.023734278976917267, -0.06056394428014755, 0.023662112653255463, 0.36468857526779175, 0.9862274527549744, -0.16452477872371674, -0.8675594329833984, -0.12475328892469406, 0.044922761619091034, 0.04880828782916069, 0.033442173153162, 0.37597644329071045, 0.14461801946163177, 0.13295425474643707, -0.26336368918418884));
	r += mul(s1_0, float4x4(-0.0015539369778707623, -0.031315747648477554, -0.07161436229944229, -0.07929608970880508, 0.028114672750234604, -0.0064895362593233585, 0.04398937523365021, -0.01534536574035883, 0.10886713117361069, -0.058881763368844986, -0.04412815719842911, 0.2705078125, -0.1049082800745964, -0.05537036433815956, 0.3172399699687958, -0.12051289528608322));
	r += mul(s1_1, float4x4(0.019782422110438347, 0.05794691666960716, 0.113856241106987, -0.14475828409194946, -0.07730117440223694, -0.16954898834228516, 0.06559231132268906, 0.3462512791156769, 0.061195798218250275, 0.06344586610794067, -0.27950528264045715, 0.5171207785606384, 0.12448687851428986, -0.09222574532032013, -0.007724133785814047, 0.136824369430542));
	r += mul(s1_2, float4x4(0.0004760206211358309, -0.0036583496257662773, 0.030606616288423538, 0.011025588028132915, 0.06674385070800781, 0.039830613881349564, 0.02984735742211342, -0.041243430227041245, 0.05933070927858353, -0.17594526708126068, 0.19970688223838806, 0.11009278148412704, -0.13399556279182434, -0.04164598882198334, 0.030011137947440147, 0.08076240867376328));
	r += mul(s1_3, float4x4(-0.2260158807039261, -0.21285822987556458, -0.2991200089454651, -0.1914387047290802, -0.1740211844444275, -0.07375238835811615, 0.1329118013381958, -0.1737544685602188, 0.19805648922920227, 0.0007688009063713253, 0.068235844373703, -0.5504416823387146, -0.0110575957223773, 0.2240418940782547, 0.34067219495773315, -0.2436395138502121));
	r += mul(s1_4, float4x4(0.15199363231658936, -0.2714877426624298, 0.5986742377281189, -1.0730794668197632, 0.23612740635871887, 0.28592556715011597, -0.44468748569488525, -1.0606026649475098, -0.5566405057907104, 0.1937519609928131, -0.27838894724845886, 0.04922555759549141, 0.12692514061927795, 0.2626420259475708, -0.6561916470527649, -0.8291532397270203));
	r += mul(s1_5, float4x4(-0.20388606190681458, 0.13361182808876038, 0.4370550215244293, -0.26946938037872314, 0.07289065420627594, -0.025747844949364662, -0.42798376083374023, -0.19376587867736816, 0.30004391074180603, -0.4933742582798004, -0.04102426394820213, 0.02179485373198986, 0.1428910493850708, -0.1171959862112999, -0.06476864218711853, 0.11616136133670807));
	r += mul(s1_6, float4x4(-0.18067283928394318, 0.005277301650494337, -0.059333134442567825, 0.15932372212409973, 0.03324234485626221, 0.0472419336438179, -0.010073780082166195, -0.012902125716209412, 0.06206003576517105, 0.3012353181838989, 0.034817878156900406, 0.020937753841280937, 0.1321377009153366, -0.2621142268180847, 0.10764527320861816, 0.06800227612257004));
	r += mul(s1_7, float4x4(-0.2095382809638977, -1.2382012605667114, 0.008092165924608707, 0.2438454031944275, -0.09402824193239212, 0.1902058720588684, -0.0014116396196186543, 0.3427657186985016, -0.10001671314239502, 0.676754355430603, -0.033844444900751114, 0.10859423130750656, -0.17462824285030365, -0.32602638006210327, -0.04287498816847801, 0.24731308221817017));
	r += mul(s1_8, float4x4(0.37209072709083557, -0.8066546320915222, -0.1635759323835373, 0.11602584272623062, -0.2015913724899292, 0.44424721598625183, -0.16713418066501617, 0.18744997680187225, 0.0017229130025953054, -0.15684184432029724, -0.04847797006368637, -0.13223223388195038, -0.16751334071159363, 0.6036508679389954, 0.03742561861872673, -0.037561263889074326));
	r += float4(-0.006759880110621452, -0.002474188571795821, -0.0007613212801516056, -0.004435715731233358);
	return max(r, 0.0);
}
float4 f1(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8, float4 s1_0, float4 s1_1, float4 s1_2, float4 s1_3, float4 s1_4, float4 s1_5, float4 s1_6, float4 s1_7, float4 s1_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(-0.08032847195863724, 0.15207527577877045, -0.4946824014186859, -0.007718570996075869, -0.17345790565013885, -0.35245099663734436, -0.09564972668886185, -0.14120548963546753, 0.262694776058197, -0.047587282955646515, 0.21142394840717316, 0.010500811971724033, 0.13431181013584137, 0.008552026003599167, 0.09084726870059967, 0.202565997838974));
	r += mul(s0_1, float4x4(0.050193995237350464, -0.1633303165435791, -0.20269156992435455, -0.02347409911453724, 0.2248726487159729, 0.23050175607204437, -0.4094703793525696, -0.14694726467132568, -0.12383096665143967, -0.18212658166885376, -0.028464993461966515, -0.07974132150411606, 0.33824536204338074, 1.445702314376831, 0.06065523251891136, 0.09120316058397293));
	r += mul(s0_2, float4x4(-0.006223730742931366, 0.08930694311857224, -0.16441933810710907, -0.0076380143873393536, 0.06006787717342377, 0.3117103576660156, -0.32632920145988464, -0.005154106300324202, -0.08665164560079575, -0.4489164352416992, 0.12824153900146484, 0.028624558821320534, -0.29039520025253296, 0.7735008001327515, 0.39358454942703247, 0.14348669350147247));
	r += mul(s0_3, float4x4(-0.6192042827606201, -0.6574654579162598, -0.06708237528800964, -0.30448952317237854, -0.07030288130044937, -0.28818178176879883, 0.15535445511341095, -0.12294229865074158, -0.2944236397743225, 0.04818359389901161, -0.22626517713069916, 0.1905621886253357, 0.5014475584030151, 0.1593107134103775, 0.09883125871419907, 0.4402939975261688));
	r += mul(s0_4, float4x4(0.2882328927516937, -1.340897560119629, 0.007616824004799128, -0.13340261578559875, 0.5208186507225037, 0.24215000867843628, 0.108031265437603, -0.0375419482588768, -0.012510962784290314, -0.26496005058288574, -0.307587593793869, -0.17710216343402863, 0.6084185838699341, 0.45270201563835144, 0.4808993637561798, -0.25479739904403687));
	r += mul(s0_5, float4x4(0.0345408171415329, -0.11530324071645737, -0.1417435258626938, -0.04257155582308769, -0.07599032670259476, 0.805185854434967, 0.24949681758880615, 0.2845150828361511, -0.06018025055527687, -0.179547518491745, -0.16153112053871155, -0.041495900601148605, -0.7949234247207642, 0.22184747457504272, 0.1925777941942215, 0.14419974386692047));
	r += mul(s0_6, float4x4(-0.4580639898777008, 0.2103031724691391, -0.03675428777933121, -0.44834768772125244, 0.0013425681972876191, -0.17630432546138763, 0.060020074248313904, 0.11055661737918854, 0.08697503805160522, 0.26149290800094604, 0.014601010829210281, 0.49110645055770874, 0.17438164353370667, -0.06643079966306686, 0.1124722883105278, 0.058956537395715714));
	r += mul(s0_7, float4x4(-0.03817189857363701, 0.01471844594925642, 0.11664412170648575, -0.028780078515410423, 0.2868216037750244, -0.20841452479362488, 0.08917956799268723, 0.7368968725204468, -0.05596098676323891, 0.0074835969135165215, 0.1739535629749298, -0.303984135389328, 0.08474980294704437, 0.09301382303237915, 0.15811952948570251, 0.2810887396335602));
	r += mul(s0_8, float4x4(0.10718497633934021, 0.04388929903507233, 0.0027859508991241455, 0.01596628874540329, -0.49681711196899414, -0.15824663639068604, -0.1243022233247757, -2.3570539951324463, 0.04266640171408653, -0.02541227452456951, 0.05306218937039375, 0.03697981685400009, -0.1009155809879303, -0.06072891503572464, 0.05240216478705406, -0.0479162335395813));
	r += mul(s1_0, float4x4(0.010261098854243755, 0.0666927695274353, -0.4532075524330139, 0.023121140897274017, 0.06940992921590805, 0.1723410189151764, 0.1803540736436844, -0.0550428070127964, -0.04747167229652405, -0.06293303519487381, -0.19570700824260712, -0.03395506367087364, 0.17822504043579102, -0.653640627861023, 0.19384554028511047, 0.07695281505584717));
	r += mul(s1_1, float4x4(-0.16789168119430542, 0.2149680107831955, -0.02220914326608181, 0.006869131699204445, 0.09550180286169052, -0.41937848925590515, 0.4985986351966858, 0.08156899362802505, -0.021132981404662132, -0.45570895075798035, -0.9810264706611633, 0.03540307655930519, -0.30371084809303284, -0.2730533182621002, 0.483662873506546, 0.04346032813191414));
	r += mul(s1_2, float4x4(0.033903855830430984, 0.04505784437060356, -0.09689498692750931, 0.012677177786827087, -0.14272628724575043, 0.03603784367442131, 0.08444719016551971, -0.0032767080701887608, -0.01624874211847782, 0.0074734739027917385, 0.1820053905248642, 0.05216206982731819, 0.1134054958820343, -0.09181822836399078, 0.24021528661251068, 0.01179902721196413));
	r += mul(s1_3, float4x4(0.2765183746814728, -0.14992322027683258, -0.29589518904685974, 0.03113337978720665, 0.15974020957946777, -0.13963785767555237, 0.33214640617370605, -0.11207246035337448, -0.3884461224079132, -0.1557549685239792, -0.2254977971315384, -0.009288636967539787, 0.05123318359255791, 0.15886835753917694, -0.173712819814682, 0.2065507173538208));
	r += mul(s1_4, float4x4(-0.5242648720741272, 0.22156116366386414, -0.49585846066474915, 0.002229338278993964, -1.002869725227356, -0.4917294681072235, -0.6674160361289978, -0.10035916417837143, 0.48310983180999756, -0.9101618528366089, 0.09055584669113159, 0.23050113022327423, -0.34297603368759155, -0.1081935241818428, -0.04870417341589928, -0.0938853919506073));
	r += mul(s1_5, float4x4(-0.08131679147481918, 0.2903807759284973, -0.15101972222328186, -0.06694720685482025, 0.06671562045812607, -0.1783621609210968, -0.37079906463623047, -0.09306451678276062, -0.10080999881029129, 0.1725882887840271, -0.0830121859908104, 0.08819273859262466, 0.20831647515296936, -0.23672892153263092, 0.15298594534397125, 0.005998425185680389));
	r += mul(s1_6, float4x4(0.1019364520907402, 0.009318772703409195, 0.20771938562393188, 0.47425487637519836, -0.07191519439220428, -0.01078519131988287, -0.04345310479402542, -0.052840184420347214, -0.34016185998916626, 0.011073839850723743, -0.011794504709541798, -0.02492661215364933, 0.0066913519985973835, 0.12865811586380005, -0.13791698217391968, -0.1109132245182991));
	r += mul(s1_7, float4x4(0.2613341808319092, 0.2482493817806244, 0.43324029445648193, 0.5214822292327881, -0.2856227159500122, -0.2875882685184479, -0.38533130288124084, -0.2958149015903473, 0.33244210481643677, -0.006166334729641676, -0.00631445599719882, -0.6617194414138794, -0.352376252412796, -0.18228957056999207, -0.35138487815856934, -0.475638747215271));
	r += mul(s1_8, float4x4(-0.6994336247444153, -0.0732031986117363, 0.033933453261852264, -0.20786899328231812, 0.14839790761470795, 0.0352637954056263, -0.05194436013698578, 0.09772350639104843, -0.20856113731861115, 0.027160540223121643, 0.08419548720121384, 0.02009684219956398, 0.42886897921562195, 0.09594854712486267, -0.019801905378699303, 0.17697644233703613));
	r += float4(-0.002771988045424223, -6.727694562869146e-05, -0.013781939633190632, -0.00584200257435441);
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
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	float4 s1_0 = l1(-1.0, -1.0);
	float4 s1_1 = l1(0.0, -1.0);
	float4 s1_2 = l1(1.0, -1.0);
	float4 s1_3 = l1(-1.0, 0.0);
	float4 s1_4 = l1(0.0, 0.0);
	float4 s1_5 = l1(1.0, 0.0);
	float4 s1_6 = l1(-1.0, 1.0);
	float4 s1_7 = l1(0.0, 1.0);
	float4 s1_8 = l1(1.0, 1.0);
	conv1_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
	conv1_1[gxy] = f1(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 4
//!DESC CuNNy-1x8-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN conv1_0, conv1_1
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(conv1_0, float2(x, y))
#define l1(x, y) O(conv1_1, float2(x, y))
float4 f0(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8, float4 s1_0, float4 s1_1, float4 s1_2, float4 s1_3, float4 s1_4, float4 s1_5, float4 s1_6, float4 s1_7, float4 s1_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(0.1362667828798294, -0.016019295901060104, 0.03590257838368416, -0.043800145387649536, 0.027806472033262253, -0.0598042830824852, 0.02314792200922966, 0.20789116621017456, -0.12431413680315018, -0.05643662437796593, -0.09354381263256073, -0.009504596702754498, 0.022148702293634415, 0.012277727015316486, -0.02811696007847786, 0.006806627381592989));
	r += mul(s0_1, float4x4(-0.06901922821998596, 0.12316104024648666, -0.0003896034904755652, -0.0013935205060988665, 0.06543242931365967, 0.4013243317604065, -0.6739280819892883, -0.7831661105155945, -0.02235392853617668, 0.16285064816474915, -0.014197097159922123, 0.025146014988422394, 0.2568362355232239, 0.21721544861793518, -0.15625602006912231, -0.061963148415088654));
	r += mul(s0_2, float4x4(0.0012374587822705507, -0.03775588423013687, 6.999915967753623e-06, 1.1856975106638856e-05, -0.01459154300391674, -0.20901550352573395, 0.13034549355506897, 0.009228363633155823, 0.0022839608136564493, 0.0014292544219642878, 0.002789343474432826, 0.0006620576023124158, 0.01823282241821289, 0.0858638733625412, 0.002555384300649166, -0.04152052477002144));
	r += mul(s0_3, float4x4(0.14284570515155792, -0.34465402364730835, 0.5221945643424988, -0.5457712411880493, 0.004858541302382946, 0.015339753590524197, -0.010466190986335278, -0.03317667916417122, -0.042768701910972595, 0.11443882435560226, 0.011929049156606197, 0.030864018946886063, -0.02500012330710888, 0.073968306183815, 0.09640885144472122, 0.044325556606054306));
	r += mul(s0_4, float4x4(0.002487175865098834, 0.5117212533950806, -0.1484050750732422, 0.6077302694320679, -0.03341738134622574, -0.02864914759993553, 0.06274352222681046, 0.07982879877090454, 0.4252302348613739, -1.4807536602020264, 0.1452462077140808, -0.3011690676212311, -1.328273892402649, -0.9059191942214966, 0.75792396068573, 0.6169406771659851));
	r += mul(s0_5, float4x4(0.00019984724349342287, 0.013526254333555698, -3.159085053994204e-06, -0.014668392017483711, 0.02117970585823059, 0.008379221893846989, -0.018973935395479202, -0.026411699131131172, -0.023542631417512894, 0.0158290583640337, 0.006981606595218182, -0.01805531419813633, 0.08710980415344238, -0.34100398421287537, 0.005419636610895395, 0.17364618182182312));
	r += mul(s0_6, float4x4(0.06035778298974037, 0.00851518101990223, -0.06580716371536255, 0.1337950974702835, 5.315267117111944e-06, 8.051412442000583e-05, -0.0021462973672896624, -0.00017908848531078547, -0.0803316980600357, 0.02206096611917019, 0.020175263285636902, 0.0733339712023735, -0.002670977497473359, -0.014015888795256615, -0.007600565906614065, -0.08549734950065613));
	r += mul(s0_7, float4x4(-0.002827209187671542, -0.08269631862640381, 0.05997316166758537, -0.01801547408103943, -6.082297477405518e-05, -0.0001817315205698833, 0.001254297443665564, 0.0008177108829841018, -0.027675656601786613, 0.1665535420179367, 0.2142181545495987, -0.7246328592300415, 0.1078573539853096, 0.06439381837844849, 0.03865986317396164, 0.08965608477592468));
	r += mul(s0_8, float4x4(-0.0009288579458370805, -6.749334602318413e-07, -4.843063265980163e-07, -1.1141174809381482e-06, -5.435703496914357e-05, 9.225102257914841e-05, 9.81597395366407e-07, -0.0017794450977817178, 0.0006680197548121214, 0.006287381984293461, -0.02703908272087574, 0.04394190013408661, -0.004241015762090683, 0.05780041590332985, -0.08778701722621918, -0.05203811824321747));
	r += mul(s1_0, float4x4(0.0029250860679894686, -0.009525792673230171, -0.02272041328251362, 0.018851816654205322, -0.09265273809432983, -0.02481258288025856, -0.022253910079598427, 0.03716985881328583, -0.03528285399079323, -0.029113341122865677, -0.004908938426524401, 0.00658428343012929, -0.01489238440990448, 0.00027378773665986955, -0.04088353365659714, 0.0006136086885817349));
	r += mul(s1_1, float4x4(-0.29099318385124207, 0.0955934002995491, 0.1286330372095108, 0.0234272088855505, -0.0266671571880579, -0.05325748771429062, 0.054692938923835754, 0.07938607037067413, -0.18603505194187164, -0.12842509150505066, 0.12328048795461655, 0.046022795140743256, 0.6559983491897583, 0.03755751624703407, 0.3212890028953552, -0.10062109678983688));
	r += mul(s1_2, float4x4(0.08424938470125198, 0.0003384932642802596, 0.017103897407650948, -0.06577914953231812, -0.030652238056063652, -0.03257814794778824, -0.01838497444987297, -0.01937549002468586, -0.01631217636168003, -0.09199690073728561, -0.0032556403893977404, 0.020077873021364212, -0.19092918932437897, 0.3917773365974426, -0.14991320669651031, 0.1231323704123497));
	r += mul(s1_3, float4x4(0.008817208930850029, -0.02958822064101696, 0.04007217288017273, -0.03575221449136734, 0.4263811409473419, -0.11996903270483017, -0.01945563033223152, -0.09014278650283813, -0.038090676069259644, 0.04551903158426285, -0.17233233153820038, -0.0354093536734581, -0.0011844452237710357, -0.0017925173742696643, 0.008638516068458557, -0.0028375170659273863));
	r += mul(s1_4, float4x4(-0.6620854139328003, 0.2268376350402832, -1.0680423974990845, 0.5004057288169861, -0.2953261435031891, 0.8695402145385742, -0.10002586245536804, -0.1103346198797226, 0.8027381896972656, 0.3533695638179779, -0.5502409338951111, -0.5136702060699463, -0.11535850912332535, -0.08461609482765198, 0.10234762728214264, 0.07593508809804916));
	r += mul(s1_5, float4x4(0.016449391841888428, 0.13409623503684998, 0.08681230992078781, 0.11883396655321121, 0.01794663444161415, -0.03163470700383186, -0.04793335869908333, -0.060116175562143326, -0.06535332649946213, 0.2471041977405548, -0.0012357519008219242, -0.13896872103214264, 0.0245460644364357, -0.06604385375976562, -0.028064684942364693, 0.0811956450343132));
	r += mul(s1_6, float4x4(0.004649311304092407, 0.02141239307820797, 0.007813719101250172, -0.0036098260898143053, -0.05388517677783966, -0.13617846369743347, 0.55191570520401, -0.2021092027425766, 0.001305571524426341, -0.0002787602134048939, 0.010686269029974937, -0.0494563914835453, -5.0531562010291964e-05, 0.0005049436585977674, -1.2811510714527685e-05, 0.0020351370330899954));
	r += mul(s1_7, float4x4(0.10868211090564728, -0.01004192978143692, 0.019137173891067505, -0.10482053458690643, -0.5583637356758118, 0.3021995425224304, -0.6053210496902466, 1.2930927276611328, -0.07421721518039703, -0.0672772005200386, 0.41371026635169983, 0.4288844168186188, 0.007310554385185242, 0.006995693314820528, -0.008846119977533817, -0.02722051553428173));
	r += mul(s1_8, float4x4(-0.012660566717386246, -0.055944230407476425, 0.01435028575360775, -0.0047420114278793335, 0.036409374326467514, -0.21036367118358612, 0.03725980594754219, -0.1787109524011612, 0.0023689414374530315, -0.02103724144399166, -0.06019386649131775, -0.006865836214274168, -0.008967150002717972, -0.0049091363325715065, -0.013791984878480434, 0.026588303968310356));
	r += float4(-7.836609583478094e-09, -1.474497324238655e-08, -1.0774328096374575e-08, -1.2873086596698613e-08);
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
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	float4 s1_0 = l1(-1.0, -1.0);
	float4 s1_1 = l1(0.0, -1.0);
	float4 s1_2 = l1(1.0, -1.0);
	float4 s1_3 = l1(-1.0, 0.0);
	float4 s1_4 = l1(0.0, 0.0);
	float4 s1_5 = l1(1.0, 0.0);
	float4 s1_6 = l1(-1.0, 1.0);
	float4 s1_7 = l1(0.0, 1.0);
	float4 s1_8 = l1(1.0, 1.0);
	down[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 5
//!DESC CuNNy-1x8-NVL-shuffle
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

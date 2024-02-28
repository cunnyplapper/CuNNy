// CuNNy 0x8 NVL
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
//!VERSION 4

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
Texture2D OUTPUT;

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
//!FORMAT R8G8B8A8_UNORM
Texture2D up_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_UNORM
Texture2D up_1;

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

//!DESC CuNNy-0x8-NVL-up
//!PASS 2
//!BLOCK_SIZE 16
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0, up_1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	min16float s0[9] = {l0(-1.0, -1.0),l0(0.0, -1.0),l0(1.0, -1.0),l0(-1.0, 0.0),l0(0.0, 0.0),l0(1.0, 0.0),l0(-1.0, 1.0),l0(0.0, 1.0),l0(1.0, 1.0)};
	float4 r0 = 0.0;
	float4 r1 = 0.0;
	r0 += min16float4(0.034374166280031204, -0.0073411972261965275, 0.0725145936012268, 0.011899776756763458) * s0[0];
	r0 += min16float4(-0.06736346334218979, 0.04480079934000969, -0.08174515515565872, 0.24740396440029144) * s0[1];
	r0 += min16float4(-0.0840308666229248, -0.03913615271449089, 0.0603942833840847, 0.25314322113990784) * s0[2];
	r0 += min16float4(0.002170455874875188, -0.004982327576726675, 0.02114461176097393, 0.113624706864357) * s0[3];
	r0 += min16float4(-0.18879692256450653, -0.5623544454574585, 0.22769714891910553, -0.7006068229675293) * s0[4];
	r0 += min16float4(0.03810926526784897, 0.2657040059566498, -0.5483116507530212, 0.06372059881687164) * s0[5];
	r0 += min16float4(-0.08960523456335068, 0.009313378483057022, -0.007325168699026108, -0.02843763865530491) * s0[6];
	r0 += min16float4(-0.006072418764233589, 0.21240238845348358, 0.05170835554599762, 0.10416381061077118) * s0[7];
	r0 += min16float4(-0.05408545210957527, 0.07790086418390274, 0.08947882801294327, -0.01196503546088934) * s0[8];
	r0 += float4(-0.07007116824388504, -0.0021387506276369095, -0.009499887004494667, -0.07058168202638626);
	r0 = max(r0, 0.0);
	r1 += min16float4(0.0319099947810173, 0.009374295361340046, 0.517952024936676, -0.044108640402555466) * s0[0];
	r1 += min16float4(-0.021913031116127968, -0.008104740642011166, -0.30957064032554626, 0.3431919515132904) * s0[1];
	r1 += min16float4(0.0191805399954319, 0.03875638544559479, 0.02937844581902027, 0.20606942474842072) * s0[2];
	r1 += min16float4(-0.007948346436023712, 0.011678914539515972, -0.34338629245758057, -0.0024546291679143906) * s0[3];
	r1 += min16float4(-0.6191404461860657, -0.09392640739679337, -0.06854626536369324, -0.5097658038139343) * s0[4];
	r1 += min16float4(0.15282972157001495, -0.10612338781356812, 0.021251041442155838, 0.07159120589494705) * s0[5];
	r1 += min16float4(0.011445634067058563, -0.036290884017944336, -0.001825639745220542, 0.037694793194532394) * s0[6];
	r1 += min16float4(0.13623106479644775, 0.3802033066749573, 0.04116462171077728, -0.04322141036391258) * s0[7];
	r1 += min16float4(0.13426057994365692, -0.2031165361404419, 0.05290938541293144, -0.0013971796724945307) * s0[8];
	r1 += float4(-0.0022328763734549284, -0.00943015981465578, -0.011872073635458946, -0.06571798026561737);
	r1 = max(r1, 0.0);
	up_0[gxy] = r0;
	up_1[gxy] = r1;
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
	gxy.x += 8u;
	pos.x += step.x;
	if (gxy.x < size.x || gxy.y < size.y) {
		hook(gxy, pos);
	}
	gxy.y += 8u;
	pos.y += step.y;
	if (gxy.x < size.x || gxy.y < size.y) {
		hook(gxy, pos);
	}
	gxy.x -= 8u;
	pos.x -= step.x;
	if (gxy.x < size.x || gxy.y < size.y) {
		hook(gxy, pos);
	}
}

//!DESC CuNNy-0x8-NVL-down
//!PASS 3
//!BLOCK_SIZE 16
//!NUM_THREADS 64
//!IN up_0, up_1
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
#define l1(x, y) O(up_1, float2(x, y))
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	min16float4 s0[9] = {l0(-1.0, -1.0),l0(0.0, -1.0),l0(1.0, -1.0),l0(-1.0, 0.0),l0(0.0, 0.0),l0(1.0, 0.0),l0(-1.0, 1.0),l0(0.0, 1.0),l0(1.0, 1.0)};
	min16float4 s1[9] = {l1(-1.0, -1.0),l1(0.0, -1.0),l1(1.0, -1.0),l1(-1.0, 0.0),l1(0.0, 0.0),l1(1.0, 0.0),l1(-1.0, 1.0),l1(0.0, 1.0),l1(1.0, 1.0)};
	float4 r0 = 0.0;
	r0 += mul(s0[0], min16float4x4(-0.03986755385994911, -0.058887843042612076, -0.06768196821212769, -0.037061356008052826, 0.013462209142744541, -0.002335223602131009, -0.033166203647851944, -0.010390033014118671, 0.17633096873760223, -0.1658114641904831, 0.033007267862558365, -0.057894252240657806, -0.01713225618004799, 0.08443022519350052, -0.11891798675060272, 0.03028024546802044));
	r0 += mul(s0[1], min16float4x4(-0.06882613897323608, 0.10470161586999893, -0.04689917713403702, -0.017089415341615677, 0.20161958038806915, 0.19677899777889252, -0.028103861957788467, 0.04986980929970741, -0.106201171875, -0.016841741278767586, -0.0540771447122097, -0.24070525169372559, 0.3055877089500427, 0.2905082702636719, -0.20764736831188202, -0.2685542106628418));
	r0 += mul(s0[2], min16float4x4(0.1226702481508255, -0.10394816100597382, 0.10094581544399261, -0.01602104678750038, 0.08923225849866867, 0.06581196188926697, 0.007702040486037731, -0.07934623956680298, -0.0004008969699498266, -0.017431801185011864, 0.009835812263190746, -0.000123229663586244, -0.003933480475097895, -0.1391589343547821, 0.009115410968661308, 0.010103289969265461));
	r0 += mul(s0[3], min16float4x4(0.06701992452144623, -0.005117618478834629, 0.01411440409719944, -0.058439701795578, 0.21179988980293274, -0.015548307448625565, 0.3525395691394806, 0.022148746997117996, -0.5718039870262146, 0.7122349739074707, -0.3459782898426056, 0.249238520860672, 0.17688775062561035, -0.0034807613119482994, 0.02488602139055729, 0.08954436331987381));
	r0 += mul(s0[4], min16float4x4(-0.14813168346881866, -0.11723878979682922, -0.09665197879076004, 0.20885306596755981, -0.6354544162750244, -0.2657359838485718, -0.38052624464035034, -0.02895638905465603, 0.015956774353981018, -0.46697717905044556, 0.05169669911265373, -0.11289532482624054, -0.17628005146980286, -0.8769551515579224, 0.8056721091270447, -0.15027719736099243));
	r0 += mul(s0[5], min16float4x4(0.0671539306640625, 0.29677334427833557, 0.07134243845939636, -0.0440165251493454, 0.04433227702975273, -0.04199785366654396, 0.08821927011013031, 0.011855100281536579, -0.009313755668699741, 0.0161743201315403, 0.0008106261375360191, 0.02545166201889515, -0.2978600859642029, 0.44512173533439636, -0.2427929937839508, 0.2055578976869583));
	r0 += mul(s0[6], min16float4x4(-0.017855027690529823, -0.07050377130508423, 0.10795200616121292, 0.009428895078599453, 0.04077143222093582, 0.038067229092121124, -0.06571551412343979, -0.0033227719832211733, 0.017205936834216118, -0.19090282917022705, 0.012122559361159801, 0.16102023422718048, 0.01365731656551361, -0.045580826699733734, 0.36425745487213135, -0.03218505159020424));
	r0 += mul(s0[7], min16float4x4(0.22983583807945251, -0.01242070458829403, 0.08412913978099823, -0.12227776646614075, 0.10477504134178162, 0.0948236733675003, 0.050583720207214355, -0.01256541721522808, 0.054564546793699265, -0.06308900564908981, 0.05943106859922409, -0.1795138418674469, -0.012373474426567554, -0.11004316806793213, 0.07043232023715973, 0.1293940544128418));
	r0 += mul(s0[8], min16float4x4(-0.12475213408470154, -0.05018264055252075, -0.07335574179887772, 0.16178645193576813, -0.01868031919002533, -0.022062312811613083, -0.008575220592319965, 0.009671628475189209, 0.01580810360610485, 0.0015879671555012465, -0.008239678107202053, -0.002157817827537656, -0.10415633767843246, 0.07230942696332932, -0.1966322958469391, 0.2811727225780487));
	r0 += mul(s1[0], min16float4x4(0.10449336469173431, -0.008846915327012539, -0.04631601274013519, -0.029263049364089966, 0.03331988304853439, -0.564454197883606, 0.4640072286128998, -0.2921206057071686, -0.03991689160466194, -0.0017241062596440315, -5.010282961848134e-07, 0.008021928369998932, 0.02171180583536625, -0.11977697163820267, 0.17491164803504944, 0.03768184781074524));
	r0 += mul(s1[1], min16float4x4(-0.3232463300228119, -0.07969857007265091, 0.09248407930135727, 0.16627950966358185, 0.10118018835783005, 0.6465033292770386, -0.02428240329027176, 0.5894626975059509, 0.03349538892507553, 0.011857436038553715, -0.04063797742128372, -0.030210284516215324, -0.23485329747200012, -0.2221810519695282, 0.16693884134292603, 0.24754244089126587));
	r0 += mul(s1[2], min16float4x4(-0.041221633553504944, -0.04944288730621338, 0.101988784968853, 0.10918822884559631, 0.00014789181295782328, 0.0008034154307097197, -0.010663184337317944, 1.9700972188729793e-05, 0.009861703962087631, 0.026615269482135773, -0.035718273371458054, -0.06163335219025612, -0.057500604540109634, 0.10799866914749146, -0.01184424851089716, -0.022850602865219116));
	r0 += mul(s1[3], min16float4x4(-0.22998790442943573, 0.14892646670341492, -0.13719375431537628, 0.061265964061021805, 0.0968451052904129, 0.23577886819839478, -0.45717310905456543, -0.10019687563180923, 0.0513349324464798, -0.0632057785987854, 0.03060007095336914, -0.02130974642932415, 0.02609318681061268, -0.018231645226478577, -0.1557653546333313, -0.13959001004695892));
	r0 += mul(s1[4], min16float4x4(0.9704657793045044, -0.19531629979610443, -0.014940408058464527, -0.5175783038139343, -0.04805593192577362, -0.05779363214969635, -0.026586737483739853, -0.03254454582929611, -0.5503306984901428, 0.08252916485071182, 0.1512485295534134, 0.27970483899116516, -0.10357601940631866, 0.9491339921951294, -0.8732176423072815, -0.18213899433612823));
	r0 += mul(s1[5], min16float4x4(-0.06962517648935318, 0.24307382106781006, -0.17177075147628784, -0.12782785296440125, -0.009732943959534168, -0.0025132158771157265, 0.008456479758024216, -0.04239499196410179, 0.1363449990749359, -0.44943222403526306, 0.14844094216823578, 0.031099965795874596, 0.30073752999305725, -0.5741788148880005, 0.2595759630203247, -0.07000183314085007));
	r0 += mul(s1[6], min16float4x4(-0.07141434401273727, 0.11514822393655777, -0.08629690110683441, 0.12151911854743958, -0.04950622841715813, -0.06049017980694771, 0.07560604810714722, -0.010414387099444866, 0.07955395430326462, -0.0014341877540573478, 0.041649624705314636, -0.05750046670436859, -0.045025259256362915, -0.004309458192437887, -0.046745799481868744, 0.0009699168731458485));
	r0 += mul(s1[7], min16float4x4(-0.1464683562517166, -0.1343553364276886, 0.26150941848754883, -0.12548746168613434, -0.014430695213377476, 0.000923671352211386, -0.0108999814838171, 0.019104257225990295, 0.14334015548229218, 0.1616290807723999, -0.754912257194519, -0.04272642731666565, -0.058919940143823624, 0.031956370919942856, -0.02860242687165737, 0.25569528341293335));
	r0 += mul(s1[8], min16float4x4(-0.022237641736865044, -0.08998405933380127, -0.12183010578155518, 0.052365921437740326, 0.0030056347604840994, 0.001374976709485054, -0.0004050602437928319, 0.017290810123085976, 0.13004598021507263, 0.29980531334877014, 0.39773866534233093, -0.06787991523742676, 0.15578384697437286, -0.03012428805232048, 0.2353091686964035, -0.2962384819984436));
	r0 += float4(-2.8709552069017263e-08, -1.3474421578507645e-08, -1.26727286442474e-08, -1.2070191068858094e-08);
	r0 = tanh(r0);
	down[gxy] = r0;
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
	gxy.x += 8u;
	pos.x += step.x;
	if (gxy.x < size.x || gxy.y < size.y) {
		hook(gxy, pos);
	}
	gxy.y += 8u;
	pos.y += step.y;
	if (gxy.x < size.x || gxy.y < size.y) {
		hook(gxy, pos);
	}
	gxy.x -= 8u;
	pos.x -= step.x;
	if (gxy.x < size.x || gxy.y < size.y) {
		hook(gxy, pos);
	}
}

//!DESC CuNNy-0x8-NVL-shuffle
//!PASS 4
//!STYLE PS
//!IN down, easu, INPUT
//!OUT OUTPUT
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

// CuNNy 1x4
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

// FSR EASU mpv | modified
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

//!DESC CuNNy-EASU
//!HOOK LUMA
//!BIND LUMA
//!SAVE easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
//!COMPONENTS 1

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxLoRsqF1(float a) {
	return uintBitsToFloat(uint(0x5f347d74) - (floatBitsToUint(a) >> uint(1)));
}

float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z));
}

void tap(inout float aC, inout float aW, vec2 off, vec2 dir, vec2 len,
         float lob, float clp, float c){
	vec2 v;
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

void set(inout vec2 dir, inout float len, vec2 pp, bool biS, bool biT,
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
	dir += vec2(dirX, dirY) * w;
	len += dot(vec2(w), vec2(lenX, lenY));
}

vec4 hook() {
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	vec2 pp = LUMA_pos * LUMA_size - vec2(0.5);
	vec2 fp = floor(pp);
	pp -= fp;
#if (defined(LUMA_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec4 bczzL = LUMA_gather(vec2((fp + vec2(1.0, -1.0)) * LUMA_pt), 0);
	vec4 ijfeL = LUMA_gather(vec2((fp + vec2(0.0,  1.0)) * LUMA_pt), 0);
	vec4 klhgL = LUMA_gather(vec2((fp + vec2(2.0,  1.0)) * LUMA_pt), 0);
	vec4 zzonL = LUMA_gather(vec2((fp + vec2(1.0,  3.0)) * LUMA_pt), 0);
#else
	float b = LUMA_tex(vec2((fp + vec2(0.5, -0.5)) * LUMA_pt)).r;
	float c = LUMA_tex(vec2((fp + vec2(1.5, -0.5)) * LUMA_pt)).r;
	float e = LUMA_tex(vec2((fp + vec2(-0.5, 0.5)) * LUMA_pt)).r;
	float f = LUMA_tex(vec2((fp + vec2( 0.5, 0.5)) * LUMA_pt)).r;
	float g = LUMA_tex(vec2((fp + vec2( 1.5, 0.5)) * LUMA_pt)).r;
	float h = LUMA_tex(vec2((fp + vec2( 2.5, 0.5)) * LUMA_pt)).r;
	float i = LUMA_tex(vec2((fp + vec2(-0.5, 1.5)) * LUMA_pt)).r;
	float j = LUMA_tex(vec2((fp + vec2( 0.5, 1.5)) * LUMA_pt)).r;
	float k = LUMA_tex(vec2((fp + vec2( 1.5, 1.5)) * LUMA_pt)).r;
	float l = LUMA_tex(vec2((fp + vec2( 2.5, 1.5)) * LUMA_pt)).r;
	float n = LUMA_tex(vec2((fp + vec2(0.5, 2.5) ) * LUMA_pt)).r;
	float o = LUMA_tex(vec2((fp + vec2(1.5, 2.5) ) * LUMA_pt)).r;
	vec4 bczzL = vec4(b, c, 0.0, 0.0);
	vec4 ijfeL = vec4(i, j, f, e);
	vec4 klhgL = vec4(k, l, h, g);
	vec4 zzonL = vec4(0.0, 0.0, o, n);
#endif
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
	vec2 dir = vec2(0.0);
	float len = 0.0;
	set(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	set(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	set(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	set(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	vec2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
	dir *= vec2(dirR);
	len = len * 0.5;
	len *= len;
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	vec2 len2 = vec2(1.0 + (stretch - 1.0) * len, 1.0 + -0.5 * len);
	float lob = 0.5 + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	float clp = APrxLoRcpF1(lob);
	float aC = 0.0;
	float aW = 0.0;
	tap(aC, aW, vec2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL);
	tap(aC, aW, vec2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL);
	tap(aC, aW, vec2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL);
	tap(aC, aW, vec2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL);
	tap(aC, aW, vec2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL);
	tap(aC, aW, vec2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL);
	tap(aC, aW, vec2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL);
	tap(aC, aW, vec2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL);
	tap(aC, aW, vec2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL);
	tap(aC, aW, vec2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL);
	tap(aC, aW, vec2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL);
	tap(aC, aW, vec2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL);
	pix.r = aC / aW;
	float min1 = min(AMin3F1(fL, gL, jL), kL);
	float max1 = max(AMax3F1(fL, gL, jL), kL);
	pix.r = clamp(pix.r, min1, max1);
	pix.r = clamp(pix.r, 0.0, 1.0);
	return pix;
}

//!DESC CuNNy-RCAS
//!HOOK LUMA
//!BIND easu
//!SAVE rcas
//!WIDTH easu.w
//!HEIGHT easu.h
//!COMPONENTS 1

// User variables - RCAS
#define SHARPNESS 2.0 // Controls the amount of sharpening. The scale is {0.0 := maximum, to N>0, where N is the number of stops (halving) of the reduction of sharpness}. 0.0 to 2.0.
#define FSR_RCAS_DENOISE 1 // If set to 1, lessens the sharpening on noisy areas. Can be disabled for better performance. 0 or 1.

// Shader code

#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0)) // This is set at the limit of providing unnatural results for sharpening.

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + 2.0);
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z)); 
}


float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

vec4 hook() {

	// Algorithm uses minimal 3x3 pixel neighborhood.
	//    b 
	//  d e f
	//    h
#if (defined(easu_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec3 bde = easu_gather(easu_pos + easu_pt * vec2(-0.5), 0).xyz;
	float b = bde.z;
	float d = bde.x;
	float e = bde.y;


	vec2 fh = easu_gather(easu_pos + easu_pt * vec2(0.5), 0).zx;
	float f = fh.x;
	float h = fh.y;
#else
	float b = easu_texOff(vec2( 0.0, -1.0)).r;
	float d = easu_texOff(vec2(-1.0,  0.0)).r;
	float e = easu_tex(easu_pos).r;
	float f = easu_texOff(vec2(1.0, 0.0)).r;
	float h = easu_texOff(vec2(0.0, 1.0)).r;
#endif

	// Min and max of ring.
	float mn1L = min(AMin3F1(b, d, f), h);

	float mx1L = max(AMax3F1(b, d, f), h);

	// Immediate constants for peak range.
	vec2 peakC = vec2(1.0, -1.0 * 4.0);

	// Limiters, these need to be high precision RCPs.
	float hitMinL = min(mn1L, e) / (4.0 * mx1L);
	float hitMaxL = (peakC.x - max(mx1L, e)) / (4.0 * mn1L + peakC.y);
	float lobeL = max(-hitMinL, hitMaxL);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(lobeL, 0.0)) * exp2(-clamp(float(SHARPNESS), 0.0, 2.0));

	// Apply noise removal.
#if (FSR_RCAS_DENOISE == 1)
	// Noise detection.
	float nz = 0.25 * b + 0.25 * d + 0.25 * f + 0.25 * h - e;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(b, d, e), f, h) - AMin3F1(AMin3F1(b, d, e), f, h)), 0.0, 1.0);
	nz = -0.5 * nz + 1.0;
	lobe *= nz;
#endif


	// Resolve, which needs the medium precision rcp approximation to avoid visible tonality changes.
	float rcpL = APrxMedRcpF1(4.0 * lobe + 1.0);
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	pix.r = float((lobe * b + lobe * d + lobe * h + lobe * f + e) * rcpL);

	return pix;

}

//!DESC CuNNy-1x4-up:0
//!HOOK LUMA
//!BIND LUMA
//!SAVE up_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) LUMA_texOff(vec2(x, y)).r
vec4 hook() {
	vec4 r = vec4(0.0);
	r += vec4(0.019976234063506126, 0.04992472752928734, -0.022882938385009766, -0.12377936393022537) * l0(-1.0, -1.0);
	r += vec4(0.058627426624298096, -0.06091247871518135, 0.4701773524284363, 0.4578690528869629) * l0(0.0, -1.0);
	r += vec4(-0.06762634962797165, 0.010018590837717056, -0.015205872245132923, -0.012787995859980583) * l0(1.0, -1.0);
	r += vec4(0.060180339962244034, -0.008900064043700695, -0.30487221479415894, -0.1053374782204628) * l0(-1.0, 0.0);
	r += vec4(-0.4912109076976776, -0.4733479619026184, -0.2260739505290985, -0.24294401705265045) * l0(0.0, 0.0);
	r += vec4(0.12423748522996902, 0.14429432153701782, 0.012914890423417091, 0.01630246825516224) * l0(1.0, 0.0);
	r += vec4(-0.043897710740566254, 0.06281417608261108, -0.0019311192445456982, -0.0020655642729252577) * l0(-1.0, 1.0);
	r += vec4(0.15764613449573517, 0.23605066537857056, 0.05033967271447182, 0.016619771718978882) * l0(0.0, 1.0);
	r += vec4(0.1831054389476776, 0.036005035042762756, -0.022612955421209335, -0.005168365780264139) * l0(1.0, 1.0);
	r += vec4(0.057978346943855286, -0.00046618859050795436, 0.10931962728500366, 0.008571858517825603);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-conv1:0
//!HOOK LUMA
//!BIND up_0
//!SAVE conv1_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) up_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.49078911542892456, -0.7125396728515625, -0.022889720275998116, -0.3490768074989319, -0.33301153779029846, 0.6422526836395264, 0.13737492263317108, 0.33496221899986267, -0.14111317694187164, 0.22331742942333221, -0.02046358957886696, 0.19091784954071045, 0.2043166160583496, -0.5253967046737671, 0.07666720449924469, -0.15731684863567352) * l0(-1.0, -1.0);
	r += mat4(-0.06511973589658737, -0.26287224888801575, 0.031352151185274124, -0.03924938663840294, -0.010149925015866756, 0.19092002511024475, -0.15759147703647614, 0.07306335866451263, -0.04231220483779907, 0.03890795260667801, -0.07024117559194565, 0.05441809073090553, 0.1242678314447403, -0.6721346974372864, 0.07200455665588379, -0.07738155126571655) * l0(0.0, -1.0);
	r += mat4(0.0916055366396904, 0.11079905182123184, -0.023066168650984764, 0.052241187542676926, 0.015424041077494621, 0.07055903226137161, 0.07983648777008057, -0.0578143335878849, 0.11120839416980743, -0.20739024877548218, 0.0793527215719223, -0.038747772574424744, -0.20288552343845367, 0.03518572822213173, 0.003980221226811409, 0.034427426755428314) * l0(1.0, -1.0);
	r += mat4(0.28808578848838806, -0.5457909107208252, 0.356435626745224, -0.33938068151474, -0.2718704640865326, 0.5284510254859924, 0.7303794622421265, 0.5048276782035828, -0.23794612288475037, 0.2369358241558075, 0.17631596326828003, 0.17989854514598846, 0.3388686180114746, -0.43652600049972534, 0.12672612071037292, -0.3132438063621521) * l0(-1.0, 0.0);
	r += mat4(-0.3662152588367462, -0.13814249634742737, -0.14901559054851532, 0.15802790224552155, -0.09204025566577911, 0.1819906085729599, -0.11438494920730591, -0.12194979190826416, 0.018094606697559357, 0.054262105375528336, -0.003524698782712221, -0.24002347886562347, 0.21045586466789246, 0.24723124504089355, 0.1760454624891281, 0.229172021150589) * l0(0.0, 0.0);
	r += mat4(0.09233441203832626, -0.10329632461071014, -0.011693019419908524, 0.2207120805978775, -0.03700380027294159, 0.20947332680225372, 0.11686262488365173, -0.09682692587375641, 0.11924111098051071, -0.15500660240650177, -0.08854817599058151, -0.4493739902973175, -0.6935308575630188, 0.34472623467445374, 0.15673953294754028, 0.8808580636978149) * l0(1.0, 0.0);
	r += mat4(0.10748573392629623, 0.05285556986927986, -0.032413944602012634, 0.26136448979377747, -0.14061661064624786, 0.14111347496509552, 0.20491397380828857, -0.7670852541923523, -0.07820174098014832, 0.20448607206344604, -0.04561726748943329, 0.21729236841201782, 0.2519153952598572, -0.0625653937458992, -0.23643451929092407, -0.373466432094574) * l0(-1.0, 1.0);
	r += mat4(-0.029421653598546982, 0.3103174865245819, 0.06713327765464783, -0.33187201619148254, 0.13719463348388672, -0.16553263366222382, 0.04414977505803108, -0.29861414432525635, -0.226549431681633, -0.34054818749427795, -0.015018025413155556, -0.47738930583000183, 0.12055395543575287, 0.2587891221046448, 0.13826832175254822, -18.679931640625) * l0(0.0, 1.0);
	r += mat4(0.03759341686964035, 0.07488211244344711, 0.014790180139243603, 0.17492158710956573, -0.13720782101154327, -0.2567451298236847, -0.005572725553065538, -0.24842140078544617, 0.30529069900512695, -0.25244224071502686, 0.03360601142048836, -0.23780511319637299, -0.4241334795951843, 0.495118111371994, 0.005063083954155445, 0.4150392711162567) * l0(1.0, 1.0);
	r += vec4(-0.03468954563140869, 0.026078715920448303, 0.002678165677934885, 0.02539280243217945);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-down:0
//!HOOK LUMA
//!BIND conv1_0
//!SAVE down_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv1_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.03410511836409569, -0.0637592300772667, 0.042973749339580536, -0.06957986205816269, -0.028598111122846603, 0.009911679662764072, -0.006075596436858177, -0.12209326773881912, -0.009727012366056442, -0.0028969058766961098, -0.007553366478532553, 0.022571958601474762, -0.055040813982486725, 0.055767565965652466, -0.15695033967494965, -0.03991672024130821) * l0(-1.0, -1.0);
	r += mat4(-0.14796866476535797, -0.009384551085531712, 0.07329358160495758, 0.118606336414814, -0.22999858856201172, -0.3447268605232239, 0.23583996295928955, 0.1590946614742279, -0.01566002517938614, -0.0013280522543936968, -0.0364975705742836, -0.053584467619657516, 0.510550856590271, 0.26603344082832336, -0.11544786393642426, -0.13547250628471375) * l0(0.0, -1.0);
	r += mat4(-0.06589937955141068, -0.042394813150167465, -0.1115078404545784, 0.02157813496887684, -0.06481915712356567, -0.02303323894739151, 0.04443376138806343, 0.20159170031547546, 0.14599592983722687, 0.07397321611642838, 0.11239101737737656, 0.08434928953647614, 0.02741992101073265, 0.14037467539310455, 0.01846812479197979, -0.10271880030632019) * l0(1.0, -1.0);
	r += mat4(0.05949503555893898, 0.1342770904302597, -0.023316241800785065, -0.06816809624433517, -0.08223110437393188, 0.2076590359210968, -0.2960529923439026, 0.24198442697525024, 0.004586393013596535, -0.04211428016424179, 0.020082902163267136, -0.04211713373661041, -0.5527626276016235, 0.3026757538318634, -0.11855261027812958, 0.28628021478652954) * l0(-1.0, 0.0);
	r += mat4(1.0410535335540771, -0.07609040290117264, 0.06152718886733055, -0.12977513670921326, 0.7237488031387329, -0.09740716218948364, -0.39746353030204773, -1.0817395448684692, 0.05251043662428856, 0.18901269137859344, 0.02901533618569374, 0.17542381584644318, -0.13037210702896118, -1.2292914390563965, 0.9792126417160034, -0.05777696520090103) * l0(0.0, 0.0);
	r += mat4(-0.8579667806625366, 1.0685508251190186, -0.19818051159381866, 0.2559189200401306, 0.08582228422164917, 0.5104365944862366, -0.05794696509838104, 0.09347619116306305, -0.2705078125, -0.3310551345348358, -0.22190846502780914, -0.2861330211162567, -0.1558612436056137, 0.13818387687206268, 0.012135671451687813, 0.47585368156433105) * l0(1.0, 0.0);
	r += mat4(-0.11701484024524689, 0.009201397188007832, -0.05122536048293114, 0.19091828167438507, -0.07347684353590012, -0.049550022929906845, 0.009373015724122524, -0.005278559867292643, -0.0017376895993947983, 0.010406159795820713, -0.02056589163839817, -0.012720135971903801, 0.08521993458271027, -0.12645921111106873, -0.08031230419874191, 0.09439007192850113) * l0(-1.0, 1.0);
	r += mat4(0.36387571692466736, -0.46191391348838806, 1.1530177593231201, -0.4521447420120239, -0.1274542510509491, -0.0700681284070015, 0.5401696562767029, 0.39941567182540894, -0.03157451003789902, -0.015935152769088745, 0.02020355686545372, 0.04050362855195999, 0.33327409625053406, 0.2920376658439636, -0.15730062127113342, -0.5058596134185791) * l0(0.0, 1.0);
	r += mat4(-0.5411990880966187, 0.20856940746307373, -1.1857342720031738, 1.0684562921524048, -0.043093565851449966, -0.10178928077220917, -0.03865421935915947, 0.18869557976722717, 0.10790792107582092, 0.05387706309556961, 0.07835760712623596, -0.010126735083758831, 0.0026873648166656494, 0.2017909288406372, -0.1071786880493164, 0.026234528049826622) * l0(1.0, 1.0);
	r += vec4(0.00039418210508301854, 0.0014458067016676068, 0.0005738175241276622, 0.0017815802711993456);
	return tanh(r);
}

//!DESC CuNNy-1x4-shuffle
//!HOOK LUMA
//!BIND down_0
//!BIND rcas
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
vec4 hook() {
	vec4 r = vec4(0.0);
	vec2 f = fract(down_0_pos * down_0_size);
	ivec2 i = ivec2(f * vec2(2.0));
	r.r = down_0_tex((vec2(0.5) - f) * down_0_pt + down_0_pos)[2*i.y + i.x];
	r.r += rcas_tex(rcas_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

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
#define SHARPNESS 1.0 // Controls the amount of sharpening. The scale is {0.0 := maximum, to N>0, where N is the number of stops (halving) of the reduction of sharpness}. 0.0 to 2.0.
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
	r += vec4(-0.00641397200524807, -0.030093101784586906, -0.11792159825563431, 0.0030751903541386127) * l0(-1.0, -1.0);
	r += vec4(0.010649945586919785, -0.11034730821847916, 0.010044642724096775, 0.13621582090854645) * l0(0.0, -1.0);
	r += vec4(-0.008188314735889435, 0.11504093557596207, -0.019508935511112213, -0.009936302900314331) * l0(1.0, -1.0);
	r += vec4(-0.0374767929315567, 0.11925307661294937, -0.20941759645938873, -0.04075578227639198) * l0(-1.0, 0.0);
	r += vec4(0.14739146828651428, -0.4499903917312622, 0.44432809948921204, -0.40441110730171204) * l0(0.0, 0.0);
	r += vec4(0.18748007714748383, 0.22314444184303284, 0.04596349969506264, 0.017876693978905678) * l0(1.0, 0.0);
	r += vec4(0.037687428295612335, 0.005955091677606106, -0.08144757151603699, 0.15459148585796356) * l0(-1.0, 1.0);
	r += vec4(-0.4736327826976776, 0.1591661125421524, 0.16391709446907043, 0.2393108457326889) * l0(0.0, 1.0);
	r += vec4(0.14698219299316406, 0.007598062511533499, 0.032404594123363495, -0.06237926706671715) * l0(1.0, 1.0);
	r += vec4(-0.00645209988579154, -0.004618549253791571, -0.03587784990668297, 0.2881050109863281);
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
	r += mat4(0.023147502914071083, 0.09127632528543472, 0.015484376810491085, -0.0813879743218422, -0.008854961954057217, 0.07079517096281052, 0.08303625881671906, 0.13638713955879211, -0.07099824398756027, -0.030721327289938927, -0.044166356325149536, 0.10381139814853668, 0.004809071309864521, -0.055929575115442276, -0.06125568598508835, 0.04533292353153229) * l0(-1.0, -1.0);
	r += mat4(0.41113290190696716, 0.011973285116255283, -0.1395982801914215, -1.700080394744873, 0.1450197398662567, -0.1222371831536293, 0.09972678124904633, -0.12650835514068604, -0.20716175436973572, -0.04436391219496727, 0.0650777816772461, -0.06415795534849167, 0.04648708552122116, -0.0670207068324089, -0.07674677670001984, 0.20780199766159058) * l0(0.0, -1.0);
	r += mat4(0.10778751969337463, 0.04957212507724762, 0.062264978885650635, -0.29785284399986267, 0.059849388897418976, -0.00788695178925991, -0.07343295961618423, -0.017469605430960655, -0.09761033952236176, -0.004804458003491163, 0.05649247393012047, 0.12173094600439072, 0.01574951969087124, -0.005677893757820129, -0.1458539366722107, -0.06610218435525894) * l0(1.0, -1.0);
	r += mat4(0.04506346583366394, -0.04850440472364426, 0.019249923527240753, 0.4959540367126465, 0.01012282446026802, 0.10010012239217758, -0.005927653051912785, 0.27742862701416016, 0.2587890326976776, -0.01773674227297306, -0.022727716714143753, -0.14404894411563873, -0.056815363466739655, -0.18580938875675201, -0.093246690928936, 0.02794521488249302) * l0(-1.0, 0.0);
	r += mat4(0.29004594683647156, -0.07035908102989197, -0.0662902370095253, 0.03920114412903786, -0.20165961980819702, 0.016669273376464844, -0.10508552193641663, -0.7597664594650269, 0.005009613465517759, 0.0342036709189415, -0.0597044937312603, -0.07258175313472748, 0.5794063806533813, -0.07887627184391022, -0.015675736591219902, 0.023764239624142647) * l0(0.0, 0.0);
	r += mat4(0.19271406531333923, -0.05272100120782852, -0.039743393659591675, -0.0478636734187603, -0.1517762392759323, -0.035698991268873215, 0.05240609124302864, 0.32131078839302063, 0.1343434453010559, 0.002964695915579796, 0.03474538028240204, 0.20946280658245087, 0.15581074357032776, -0.07016921043395996, -0.1253635436296463, 0.06673308461904526) * l0(1.0, 0.0);
	r += mat4(-0.1031695157289505, -0.0007228717440739274, -0.02223038114607334, 0.32126885652542114, -0.1198892891407013, 0.149998277425766, 0.016863185912370682, 0.4189058244228363, -0.17885692417621613, 0.08659673482179642, -0.026276802644133568, 0.10476589947938919, 0.013098242692649364, -0.12914976477622986, -0.06790222227573395, -0.021611038595438004) * l0(-1.0, 1.0);
	r += mat4(0.020122051239013672, -0.008064047433435917, -0.010955090634524822, 0.13331174850463867, -0.12595030665397644, 0.05253903195261955, -0.03646090254187584, -0.2568359375, 0.07428836822509766, -0.05716363713145256, -0.030431298539042473, -0.332953542470932, 0.04214148968458176, -0.10204051434993744, -0.011138923466205597, 0.3434779942035675) * l0(0.0, 1.0);
	r += mat4(-0.021765563637018204, 0.019708096981048584, -0.021762790158391, 0.012682114727795124, -0.006666808854788542, -0.07279207557439804, 0.0952467992901802, 0.026793913915753365, 0.029521221294999123, 0.06601189821958542, -0.009742505848407745, -0.041519276797771454, -0.09975612908601761, -0.08290360867977142, -0.0824134424328804, 0.10611695796251297) * l0(1.0, 1.0);
	r += vec4(-0.21435546875, -0.026176001876592636, -0.035087354481220245, -0.22802726924419403);
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
	r += mat4(0.08832617849111557, 0.08210237324237823, -0.08813576400279999, -0.035486601293087006, 0.03350875526666641, 0.03275560960173607, 0.04001489654183388, 0.03861786425113678, -0.008596490137279034, 0.0052396999672055244, 0.04326503351330757, 0.024222442880272865, 0.047557368874549866, 0.004995022434741259, -0.010688734240829945, -0.02886795625090599) * l0(-1.0, -1.0);
	r += mat4(0.3873237669467926, 0.28419023752212524, 0.12367407977581024, 0.11598099768161774, 0.005640982650220394, 0.002697548596188426, -0.03871484473347664, -0.05644149333238602, 0.022024042904376984, 0.06562753766775131, 0.05072256550192833, 0.00743760634213686, 0.6348990797996521, -0.054198719561100006, -0.2509889304637909, -0.4999305307865143) * l0(0.0, -1.0);
	r += mat4(-0.12548817694187164, 0.0017410003347322345, -0.07982911169528961, -0.14949065446853638, 0.07581941038370132, -0.05023622140288353, -0.024960320442914963, 0.08727683871984482, -0.05788474157452583, 0.030678415670990944, -0.12225078791379929, -0.06931611895561218, -0.07826385647058487, 0.5488961338996887, -0.10756021738052368, -0.06017989292740822) * l0(1.0, -1.0);
	r += mat4(-0.4990232586860657, 0.30371084809303284, 0.24770207703113556, 0.6660154461860657, -0.03548585996031761, 0.034747328609228134, -0.055527374148368835, 0.049728989601135254, -0.01407951395958662, 0.12139186263084412, 0.03965369984507561, -0.009050280787050724, -0.07495161890983582, -0.0014903063420206308, -0.03492242097854614, 0.0003130903060082346) * l0(-1.0, 0.0);
	r += mat4(-0.5214840769767761, -1.3809633255004883, -0.004968651570379734, -0.5567561984062195, 0.019489388912916183, -0.07517869025468826, -0.0017428994178771973, 0.018904121592640877, 0.06470751762390137, -0.006416236981749535, 0.06612781435251236, -0.051393721252679825, 0.27855849266052246, -0.2143556773662567, 1.0585938692092896, 0.16386297345161438) * l0(0.0, 0.0);
	r += mat4(0.09578713029623032, 0.24371325969696045, 0.10758347064256668, 0.3895920515060425, -0.0210126806050539, -0.00619994243606925, 0.05671323835849762, -0.03661356121301651, -0.022787999361753464, 0.0921740010380745, -0.08398190885782242, -0.018623191863298416, -0.36621221899986267, 0.03433109074831009, -0.252760112285614, 0.5822204947471619) * l0(1.0, 0.0);
	r += mat4(-0.210444837808609, 0.10426681488752365, -0.7294284701347351, -0.055523816496133804, 0.00018013810040429235, -0.11743496358394623, -0.02549966610968113, -0.019172092899680138, 0.04601152241230011, 0.03519298508763313, -0.015301824547350407, -0.028688717633485794, 0.01180477999150753, -0.0004949974245391786, 0.006820546928793192, 0.028292696923017502) * l0(-1.0, 1.0);
	r += mat4(0.44383925199508667, 0.1556023210287094, 0.13429467380046844, -0.5332381725311279, -0.012336039915680885, -0.00586738483980298, 0.022382542490959167, 0.123957060277462, -0.09806431084871292, 0.008064152672886848, 0.062249183654785156, -0.0986267551779747, -0.005447286181151867, -0.006320034619420767, 0.0017221119487658143, -0.05772096663713455) * l0(0.0, 1.0);
	r += mat4(0.013344088569283485, 0.019584160298109055, -0.03155762329697609, 0.03930626064538956, 0.021964561194181442, -0.07536138594150543, 0.16622348129749298, 0.08328448981046677, 0.002187657868489623, -0.019292261451482773, 0.0869886577129364, 0.04021333158016205, -0.0036780193913728, 0.006489291787147522, -0.008573926985263824, 0.028823189437389374) * l0(1.0, 1.0);
	r += vec4(-1.2286357486956945e-09, -7.832432480370244e-09, 5.3062661903302555e-11, -1.5375032358377894e-09);
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

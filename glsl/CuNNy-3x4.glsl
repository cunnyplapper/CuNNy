// CuNNy 3x4
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

//!DESC CuNNy-3x4-up:0
//!HOOK LUMA
//!BIND LUMA
//!SAVE up_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) LUMA_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += vec4(0.10452909767627716, -0.011452709324657917, -0.012542692013084888, -0.019840067252516747) * l0(-1.0, -1.0);
	r += vec4(-0.14572034776210785, 0.01948024518787861, 0.020988604053854942, -0.036403052508831024) * l0(0.0, -1.0);
	r += vec4(0.019533440470695496, 0.007698191329836845, -0.022634821012616158, -0.13492101430892944) * l0(1.0, -1.0);
	r += vec4(-0.278320848941803, 0.11206145584583282, -0.01236477680504322, -0.07886040955781937) * l0(-1.0, 0.0);
	r += vec4(2.3416101932525635, -0.4350508451461792, 0.10615576803684235, 0.5430448055267334) * l0(0.0, 0.0);
	r += vec4(0.013358213938772678, 0.035277873277664185, 0.1787583827972412, 0.10717754811048508) * l0(1.0, 0.0);
	r += vec4(0.10798673331737518, -0.04489058256149292, 0.03404804319143295, -0.15771500766277313) * l0(-1.0, 1.0);
	r += vec4(-0.2767483592033386, 0.36230483651161194, -0.5449218153953552, -0.10213688760995865) * l0(0.0, 1.0);
	r += vec4(0.14445331692695618, -0.04169023782014847, 0.2524397671222687, -0.08046051114797592) * l0(1.0, 1.0);
	r += vec4(0.03168998658657074, -8.442313992418349e-05, -0.0011005856795236468, -0.010648521594703197);
	return max(r, 0.0);
}

//!DESC CuNNy-3x4-conv1:0
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
	r += mat4(0.11355079710483551, -0.04064401239156723, -0.005674026440829039, -0.04795466363430023, 0.003200747538357973, -0.01624663546681404, -0.2527787387371063, -0.0006994240102358162, -0.2239588052034378, 0.007731656078249216, -0.37205973267555237, -0.09134441614151001, -0.1938631534576416, 0.05258052796125412, 0.11415710300207138, 0.18074370920658112) * l0(-1.0, -1.0);
	r += mat4(-0.18505842983722687, 0.1003287211060524, -0.06716642528772354, 0.07740939408540726, -0.9979625344276428, -0.10311020910739899, -0.8208833336830139, -0.011052863672375679, 0.4298996031284332, 1.2593408823013306, 0.3408763110637665, 1.167968988418579, 0.04014700651168823, 0.0495566688477993, 0.035154860466718674, 0.3349664807319641) * l0(0.0, -1.0);
	r += mat4(0.08692655712366104, -0.0915566086769104, 0.08989831060171127, 0.0007651439518667758, 0.2958444654941559, -0.24263715744018555, 0.26251259446144104, 0.013291196897625923, 0.43538981676101685, 0.14414052665233612, 0.17331916093826294, -0.009282953105866909, -1.0742201805114746, 0.09374159574508667, -0.4032711982727051, 0.3125591576099396) * l0(1.0, -1.0);
	r += mat4(-0.09622809290885925, -0.24584533274173737, -0.04723215475678444, 0.08858735114336014, -0.19560137391090393, -0.34198760986328125, 0.18248438835144043, 0.2824963331222534, 0.4309455156326294, 0.5358767509460449, -1.4043055772781372, 0.6818129420280457, 0.05166984349489212, 0.638132631778717, 0.330653578042984, -0.21421049535274506) * l0(-1.0, 0.0);
	r += mat4(0.16405169665813446, 0.019246941432356834, -0.13426245748996735, -0.2680027484893799, -0.00671541690826416, -0.14919400215148926, -0.4230932593345642, 0.6696280241012573, 0.3441493809223175, 0.3427819609642029, -0.5238410830497742, 0.620581328868866, 0.3269294500350952, 0.7439814805984497, 0.5587524175643921, -0.10736888647079468) * l0(0.0, 0.0);
	r += mat4(-0.1750730723142624, -0.04920824617147446, -0.016462188214063644, 0.10507186502218246, -0.0754079818725586, -0.19639241695404053, 0.2885235846042633, 0.6385676264762878, 0.28014376759529114, 0.11036790162324905, -0.2920045256614685, 0.1821279078722, -0.707385241985321, 0.19970537722110748, 0.007890593260526657, -0.48106294870376587) * l0(1.0, 0.0);
	r += mat4(0.05027999356389046, 0.11352512240409851, -0.10748366266489029, 0.06643618643283844, 0.21036678552627563, 0.09844782203435898, -0.20355340838432312, 0.011301101185381413, -0.10082387179136276, -0.020161176100373268, 0.4639035165309906, -0.27671685814857483, -0.028873952105641365, 0.015869174152612686, 0.09955456852912903, -0.029153654351830482) * l0(-1.0, 1.0);
	r += mat4(-0.027592403814196587, 0.19618657231330872, 0.2407224178314209, -0.037802956998348236, -0.04142411798238754, 0.22171753644943237, 0.26430678367614746, -0.12526580691337585, -0.023554282262921333, 0.12267724424600601, 0.28401774168014526, -0.014135674573481083, 0.003537720302119851, -0.09095872193574905, -0.637416660785675, 0.17550760507583618) * l0(0.0, 1.0);
	r += mat4(-0.0355224534869194, 0.058764077723026276, -0.03669886291027069, -0.022664174437522888, -0.18092171847820282, -0.026867253705859184, 0.11549384146928787, -0.03818473592400551, -0.022153837606310844, -0.01174453366547823, 0.12552209198474884, -0.057808030396699905, -0.09545640647411346, 0.06501861661672592, 0.18736210465431213, -0.07467970997095108) * l0(1.0, 1.0);
	r += vec4(-0.005765500012785196, -0.021388528868556023, -0.005334573332220316, -0.020252784714102745);
	return max(r, 0.0);
}

//!DESC CuNNy-3x4-conv2:0
//!HOOK LUMA
//!BIND conv1_0
//!SAVE conv2_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv1_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(-0.0007999867084436119, 0.03441069647669792, -0.0969579666852951, 0.10234910249710083, -0.13097743690013885, 0.16748468577861786, -0.054060887545347214, 0.027642834931612015, 0.08757325261831284, -0.1697191745042801, 0.08709574490785599, 0.05508185550570488, -0.006496819201856852, -0.0907350555062294, -0.0860380232334137, 0.09248874336481094) * l0(-1.0, -1.0);
	r += mat4(0.21337927877902985, 0.13355518877506256, 0.02146509476006031, 0.041989609599113464, 0.18250076472759247, -0.2334294319152832, 0.2762433588504791, -0.008454367518424988, -0.629551112651825, 0.08271367847919464, -0.10239610075950623, -0.031245194375514984, 0.03750932216644287, 0.23947010934352875, -0.2710600197315216, 0.09396760165691376) * l0(0.0, -1.0);
	r += mat4(0.08700898289680481, 0.09594709426164627, 0.11889326572418213, -0.08553682267665863, -0.24957051873207092, 0.12476065754890442, 0.10408047586679459, 0.26080456376075745, -0.013709322549402714, -0.5154234170913696, -0.19583876430988312, 0.017931027337908745, 0.20539818704128265, 0.08633529394865036, 0.01448129117488861, -0.14990024268627167) * l0(1.0, -1.0);
	r += mat4(-0.09698861837387085, -0.0770283192396164, -0.06989357620477676, 0.16305352747440338, -0.015541097149252892, -0.05749400332570076, -0.08418430387973785, 0.010054514743387699, 0.11008229106664658, -0.31714707612991333, 0.03133716434240341, 0.09882774949073792, -0.030871085822582245, -0.1679922342300415, -0.1515445113182068, -0.14306646585464478) * l0(-1.0, 0.0);
	r += mat4(-0.2900680601596832, -0.029005631804466248, 0.10657446831464767, 0.1293574422597885, 0.2744133174419403, 0.6228931546211243, -0.16447556018829346, -0.02463885210454464, 0.11201704293489456, -0.1397174745798111, 0.07280000299215317, 0.027265222743153572, 0.2818843126296997, -0.09638763964176178, -0.7914980053901672, -0.009969866834580898) * l0(0.0, 0.0);
	r += mat4(-0.1616167575120926, -0.15869760513305664, 0.004199656192213297, 0.3561839163303375, -0.17475314438343048, -0.19690962135791779, -0.34868863224983215, -0.39239588379859924, -0.1911257803440094, -0.1622932255268097, -0.2275218665599823, -0.15795819461345673, 0.23104524612426758, -0.11559449881315231, 0.1858803778886795, 0.04816382750868797) * l0(1.0, 0.0);
	r += mat4(0.2543049454689026, -0.21923762559890747, 0.0027657633181661367, 0.3415519893169403, -0.052828967571258545, -0.01400040928274393, -0.04228867217898369, -0.01979517564177513, 0.14961762726306915, -0.01708991639316082, 0.020556466653943062, 0.02010551281273365, 0.13326075673103333, -0.14580382406711578, 0.044106028974056244, 0.14335118234157562) * l0(-1.0, 1.0);
	r += mat4(0.07295066118240356, 0.3696650564670563, 0.03986193239688873, -0.7073493599891663, -0.10244705528020859, -0.05081620067358017, -0.20748493075370789, 0.1072997897863388, -0.052032921463251114, 0.16454723477363586, 0.05290566757321358, -0.525390625, -0.20458966493606567, -0.17669525742530823, 0.1425871104001999, -0.28890466690063477) * l0(0.0, 1.0);
	r += mat4(0.0035330543760210276, 0.01071961410343647, -0.0941476821899414, -0.25284722447395325, 0.12638099491596222, 0.12969498336315155, 0.1278972029685974, -0.18111886084079742, -0.060705751180648804, -0.0680428296327591, -0.10756722092628479, -0.07778752595186234, -0.11597522348165512, -0.03836305812001228, -0.0983903780579567, 0.22900137305259705) * l0(1.0, 1.0);
	r += vec4(0.011513447389006615, 0.00023576496460009366, -0.02885317988693714, -0.012142222374677658);
	return max(r, 0.0);
}

//!DESC CuNNy-3x4-conv3:0
//!HOOK LUMA
//!BIND conv2_0
//!SAVE conv3_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv2_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.05870848894119263, -0.007594856899231672, 0.14354535937309265, 0.04936739429831505, -0.27470627427101135, -0.04144465550780296, 0.019057773053646088, 0.05361075699329376, -0.2241223305463791, -0.018852388486266136, -0.01957085356116295, 0.017163438722491264, -0.41113269329071045, -0.027671080082654953, 0.3250986635684967, 0.004232371225953102) * l0(-1.0, -1.0);
	r += mat4(0.3955079913139343, -0.002326513407751918, -0.4051676392555237, 0.0029975413344800472, -0.2704773545265198, -0.08169431984424591, -0.4338376522064209, 0.0973619669675827, 0.24549119174480438, -0.021653153002262115, 0.5683588981628418, -0.04028156027197838, 0.5355172157287598, -0.17042537033557892, 0.2787981629371643, 0.04011545702815056) * l0(0.0, -1.0);
	r += mat4(0.17872652411460876, 0.096539705991745, -0.25702589750289917, 0.019203579053282738, -0.10524605214595795, -0.21712857484817505, 0.030764561146497726, 0.018365152180194855, -0.07264132052659988, -0.19513633847236633, -0.23487044870853424, -0.004676563665270805, 0.1836032271385193, 0.21954530477523804, 0.10717462003231049, 0.021277988329529762) * l0(1.0, -1.0);
	r += mat4(0.3353709280490875, 0.052475981414318085, 0.374026358127594, 0.2672838866710663, 0.09161511063575745, 0.061941709369421005, 0.1754579097032547, -0.05041354149580002, 0.32347381114959717, 0.05012759566307068, -0.08665748685598373, -0.7129094004631042, -0.5876753926277161, -0.06160348653793335, 0.12877702713012695, 0.003009603125974536) * l0(-1.0, 0.0);
	r += mat4(-0.037458110600709915, -0.06568196415901184, 0.17837774753570557, 0.060200996696949005, 0.08208024501800537, -0.2732184827327728, -0.06290008127689362, 0.03787948563694954, 0.1333814412355423, -0.07295674830675125, 0.3212890326976776, 0.1722484678030014, -0.40179964900016785, -0.19384504854679108, 0.16377826035022736, 0.02689322456717491) * l0(0.0, 0.0);
	r += mat4(0.02948111481964588, 0.39160147309303284, -0.21406899392604828, 0.038700319826602936, -0.21701981127262115, 0.4440898001194, 0.0331287756562233, 0.0365007109940052, -0.11253723502159119, 0.43866100907325745, -0.18885788321495056, -0.011806887574493885, 0.02996099181473255, 0.10790093243122101, 0.020026229321956635, 0.01845477893948555) * l0(1.0, 0.0);
	r += mat4(-0.025894666090607643, 0.06470081955194473, 0.050824765115976334, -0.08112319558858871, 0.22510762512683868, -0.05523979663848877, 0.025361740961670876, -0.019345790147781372, 0.06665044277906418, -0.018061194568872452, -0.13348893821239471, -0.16065539419651031, 0.06796836107969284, -0.04008442908525467, 0.05056486651301384, 0.06800034642219543) * l0(-1.0, 1.0);
	r += mat4(-0.4861631989479065, -0.10992499440908432, 0.015167426317930222, 0.08469750732183456, 0.29056817293167114, 0.10855518281459808, 0.027682127431035042, -0.04541260749101639, -0.06896140426397324, 0.08719296008348465, -0.012436216697096825, 0.0009803747525438666, 0.2433099001646042, 0.00040324870496988297, 0.0863727480173111, -0.06552350521087646) * l0(0.0, 1.0);
	r += mat4(0.05163734033703804, 0.2904506325721741, -0.04833903908729553, 0.01608229987323284, 0.08153359591960907, 0.043733399361371994, -0.026241563260555267, -0.010770590044558048, -0.012822315096855164, -0.1979701817035675, -0.05666821822524071, 0.018832944333553314, -0.0074042812921106815, -0.04062117636203766, 0.01800690032541752, -0.015182340517640114) * l0(1.0, 1.0);
	r += vec4(-0.010615672916173935, -0.008576003834605217, -0.007379476446658373, 0.012393935583531857);
	return max(r, 0.0);
}

//!DESC CuNNy-3x4-down:0
//!HOOK LUMA
//!BIND conv3_0
//!SAVE down_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv3_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.09793225675821304, 0.009136726148426533, -0.16068902611732483, -0.13818466663360596, -0.09769966453313828, -0.02980082854628563, 0.016809264197945595, -0.004014603327959776, 0.02015652507543564, -0.021850287914276123, 0.027416205033659935, -0.05358884856104851, -0.03270185366272926, -0.005188382230699062, -0.011806304566562176, 0.012179307639598846) * l0(-1.0, -1.0);
	r += mat4(0.06732798367738724, 0.041489798575639725, -0.113655686378479, -0.1720217764377594, 0.06719359755516052, -0.054648786783218384, 0.028682438656687737, 0.016733840107917786, -0.038053084164857864, -0.060690391808748245, 0.12200281769037247, 0.08575791120529175, 0.07788099348545074, 0.008020948618650436, 0.030858449637889862, -0.01321148220449686) * l0(0.0, -1.0);
	r += mat4(-0.010635721497237682, 0.10963695496320724, -0.002164283534511924, 0.03406073898077011, 0.02570820413529873, 0.019807925447821617, 0.018939455971121788, 0.01440515462309122, -0.02520281821489334, 0.012390896677970886, -0.02914249897003174, 0.056934744119644165, 0.03080873377621174, 0.028632979840040207, 0.09214198589324951, 0.06640277802944183) * l0(1.0, -1.0);
	r += mat4(-0.5141178965568542, 0.1423705369234085, 0.16008250415325165, 0.32736849784851074, 0.30035272240638733, 0.6113278865814209, 0.027847446501255035, 0.4071429669857025, -0.051649607717990875, 0.03345251828432083, -0.08147090673446655, 0.023599686101078987, -0.002917860634624958, -0.020293166860938072, -0.013134660199284554, -0.03254299983382225) * l0(-1.0, 0.0);
	r += mat4(0.1833234429359436, -0.8080534934997559, 0.4384874105453491, -0.059809599071741104, 0.09585072100162506, -0.028083987534046173, 0.1062321662902832, -0.07250393182039261, 0.4553767144680023, -0.005800238344818354, -0.2026343047618866, -0.3828740119934082, 0.08158843219280243, 0.07537669688463211, 0.11251167953014374, 0.10836329311132431) * l0(0.0, 0.0);
	r += mat4(-0.18257664144039154, 0.026553627103567123, -0.08449558168649673, 0.12841825187206268, 0.0075413985177874565, -0.011315221898257732, 0.007642843760550022, -0.025911683216691017, -0.12202715128660202, 0.12940771877765656, -0.07587762176990509, -0.1489250361919403, -0.38652458786964417, -0.22033487260341644, -0.3837890028953552, -0.23291020095348358) * l0(1.0, 0.0);
	r += mat4(0.11447610706090927, 0.08183325082063675, -0.29954665899276733, 0.10478725284337997, -0.06262267380952835, -0.06983338296413422, 0.058526791632175446, 0.0830187126994133, -0.06802260130643845, 0.004470682702958584, -0.056965671479701996, 0.0067870342172682285, -0.007321496959775686, -0.0029049781151115894, -0.019177621230483055, -0.004576814826577902) * l0(-1.0, 1.0);
	r += mat4(0.21396404504776, 0.07004114985466003, 0.2028176486492157, -0.4385131895542145, 0.0380280464887619, -0.008491099812090397, 0.014980845153331757, -0.07284293323755264, -0.034354522824287415, -0.1752929985523224, 0.4794885516166687, 0.05062722787261009, 0.06042545661330223, 0.015079712495207787, 0.07641903311014175, 0.005620751064270735) * l0(0.0, 1.0);
	r += mat4(-0.03536941111087799, 0.03594103828072548, -0.08640000969171524, 0.07192213833332062, 0.003171861171722412, 0.005393320694565773, 0.00685559306293726, 0.02129233255982399, -0.14796027541160583, 0.005137248430401087, -0.18395817279815674, 0.25844234228134155, 0.07200653851032257, 0.05809883400797844, 0.01546894758939743, 0.029193973168730736) * l0(1.0, 1.0);
	r += vec4(0.0009648093255236745, 0.0005998662090860307, 0.0008837083587422967, 0.0005507316091097891);
	return tanh(r);
}

//!DESC CuNNy-3x4-shuffle
//!HOOK LUMA
//!BIND down_0
//!BIND easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
vec4 hook() {
	vec4 r = vec4(0.0);
	vec2 f = fract(down_0_pos * down_0_size);
	ivec2 i = ivec2(f * vec2(2.0));
	r.r = down_0_tex((vec2(0.5) - f) * down_0_pt + down_0_pos)[2*i.y + i.x];
	r.r += easu_tex(easu_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

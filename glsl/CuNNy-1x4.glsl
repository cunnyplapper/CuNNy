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

//!DESC CuNNy-1x4-up:0
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
	r += vec4(-0.03869612142443657, 0.015531276352703571, 0.02158425562083721, 0.02973450906574726) * l0(-1.0, -1.0);
	r += vec4(0.08054633438587189, -0.02117002010345459, -0.06427782028913498, 0.11792460083961487) * l0(0.0, -1.0);
	r += vec4(-0.008689428679645061, 0.001271058339625597, 0.03437351435422897, 0.01896076835691929) * l0(1.0, -1.0);
	r += vec4(0.07062733918428421, -0.058155663311481476, -0.03293668478727341, 0.10802362859249115) * l0(-1.0, 0.0);
	r += vec4(-0.5358272790908813, 0.3623046576976776, 0.3740234076976776, -0.5919818878173828) * l0(0.0, 0.0);
	r += vec4(0.25500836968421936, -0.034936029464006424, -0.33473649621009827, -0.012309362180531025) * l0(1.0, 0.0);
	r += vec4(0.0010092080337926745, 0.03431789204478264, 0.007149765267968178, 0.015353242866694927) * l0(-1.0, 1.0);
	r += vec4(0.2518273890018463, -0.3331023156642914, -0.05310022085905075, -0.01469818688929081) * l0(0.0, 1.0);
	r += vec4(-0.0349721759557724, 0.03211919963359833, 0.04573819413781166, -0.016764486208558083) * l0(1.0, 1.0);
	r += vec4(0.4150390625, -3.751852273126133e-05, 0.00012775948562193662, 0.32254523038864136);
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
	r += mat4(-0.10574570298194885, -0.023868344724178314, 0.04775140434503555, 0.033469848334789276, 0.2744143307209015, 0.17097288370132446, -0.24937833845615387, -0.5722202062606812, 0.1561337262392044, 0.11409076303243637, -0.24462859332561493, -0.3778270184993744, 0.10795524716377258, 0.048863764852285385, -0.14564631879329681, -0.1008511409163475) * l0(-1.0, -1.0);
	r += mat4(0.18132033944129944, 0.1284090131521225, -0.12309708446264267, 0.046470582485198975, 0.8379327654838562, 0.3946443200111389, -0.1977095901966095, -1.19279944896698, 0.053792186081409454, -0.03382423520088196, -0.06333253532648087, 0.07446487247943878, 0.07464880496263504, -0.006746785715222359, 0.1778525859117508, 0.08746881783008575) * l0(0.0, -1.0);
	r += mat4(-0.023616718128323555, -0.11606422066688538, 0.07292840629816055, 0.06219347193837166, 0.16731198132038116, 0.021777110174298286, 0.45783716440200806, -0.1457318514585495, 0.007640091236680746, -0.0878211259841919, 0.19181545078754425, 0.08761613816022873, 0.10984127223491669, 0.12646520137786865, 0.057683080434799194, -0.07840293645858765) * l0(1.0, -1.0);
	r += mat4(0.16725388169288635, 0.11234451830387115, 0.04209712892770767, -0.24658209085464478, 0.017251525074243546, -0.08152395486831665, -0.2114955484867096, 0.14528115093708038, 0.8676690459251404, 0.40909555554389954, -1.0514380931854248, -0.1062002182006836, 0.03621312603354454, -0.0265489611774683, 0.06859203428030014, -0.0017140907002612948) * l0(-1.0, 0.0);
	r += mat4(-0.3194592297077179, 0.5672497749328613, -0.3004513084888458, -0.35849860310554504, 0.42480650544166565, 0.10186930745840073, 0.018386121839284897, 0.5597919225692749, 0.3965431749820709, 0.01705428771674633, 0.5646147131919861, -0.17992618680000305, -0.612452507019043, -0.4099463224411011, -0.006221327930688858, 0.12374912202358246) * l0(0.0, 0.0);
	r += mat4(0.22214540839195251, -0.01780366338789463, 0.38764792680740356, -0.030574413016438484, 0.14013487100601196, 0.011337029747664928, 0.33464014530181885, -0.09738100320100784, 0.1440427005290985, 0.011349541135132313, 0.19385041296482086, -0.07582996785640717, 0.0024846948217600584, 0.1362314522266388, -0.09204202145338058, -0.0003375608939677477) * l0(1.0, 0.0);
	r += mat4(-0.015556021593511105, -0.10484058409929276, 0.06797491759061813, 0.22894325852394104, -0.018859967589378357, -0.08968625217676163, 0.14111286401748657, 0.16251765191555023, 0.19660472869873047, 0.03231829032301903, -0.7197765111923218, 0.5136721730232239, 0.13331004977226257, 0.1420796662569046, -0.00636339234188199, 0.12744304537773132) * l0(-1.0, 1.0);
	r += mat4(0.1850275695323944, -0.04376644641160965, -0.21126849949359894, 0.40035107731819153, 0.13427849113941193, -0.012430272996425629, -0.255540132522583, 0.31928470730781555, 0.17443576455116272, 0.05325792357325554, 0.23421365022659302, 0.13874825835227966, 0.004921276122331619, 0.1381438672542572, -0.02281012199819088, -0.22802704572677612) * l0(0.0, 1.0);
	r += mat4(0.11253266036510468, -0.018501490354537964, 0.2192380577325821, -0.007098554167896509, 0.089468814432621, -0.03600464016199112, 0.16357384622097015, 0.04602319002151489, 0.08764935284852982, -0.046166978776454926, 0.20744101703166962, 0.021793706342577934, 0.1909160017967224, -0.08422620594501495, -0.02376629412174225, 0.06716138869524002) * l0(1.0, 1.0);
	r += vec4(-0.1850585639476776, -0.22381149232387543, -0.09764589369297028, -0.062359485775232315);
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
	r += mat4(-0.23974597454071045, -0.07690402865409851, -0.060768552124500275, -0.011076661758124828, 0.45297616720199585, 0.06798174977302551, 0.12247038632631302, 0.12814727425575256, 0.13818614184856415, -0.3252902626991272, -0.012324551120400429, -0.05410858616232872, -0.08439629524946213, 0.08422910422086716, 0.03425408899784088, 0.11938454210758209) * l0(-1.0, -1.0);
	r += mat4(-0.05155843496322632, -0.16650423407554626, -0.08666078001260757, -0.11742208898067474, 0.37805524468421936, 0.861329197883606, -0.21182221174240112, -0.012831754051148891, -0.08221016079187393, 0.38471323251724243, 0.020566532388329506, 0.05625757575035095, 0.39688247442245483, -0.08770700544118881, -0.7045376896858215, -0.4217507243156433) * l0(0.0, -1.0);
	r += mat4(-0.0938706323504448, -0.16849395632743835, 0.03576378524303436, -0.01275547407567501, 0.3603532910346985, 0.30371055006980896, 0.050090886652469635, -0.06913983821868896, 0.09790211915969849, 0.10144256055355072, -0.010978535749018192, 0.0013535164762288332, -0.03669622540473938, 0.3212519586086273, -0.1308857500553131, -0.5292870998382568) * l0(1.0, -1.0);
	r += mat4(-0.03232566639780998, -0.06045437231659889, -0.24853533506393433, -0.16500839591026306, 0.44578638672828674, -0.15038442611694336, 0.7989884614944458, -0.04310169816017151, 0.2111709713935852, -0.5332033634185791, 0.3567194938659668, -0.7121870517730713, 0.12426666915416718, 0.08766139298677444, -0.015256059356033802, -0.035034626722335815) * l0(-1.0, 0.0);
	r += mat4(0.7324217557907104, 0.5371094942092896, 0.6191402673721313, 0.33496078848838806, -2.398447036743164, -0.24081480503082275, -0.39127007126808167, 1.1620447635650635, -0.426759272813797, 0.2608276605606079, -0.5253909826278687, 0.5219030380249023, -0.4091848134994507, -0.21641869843006134, 0.5957028269767761, 0.23772424459457397) * l0(0.0, 0.0);
	r += mat4(-0.14306652545928955, 0.11336173117160797, -0.18798740208148956, 0.02434033900499344, 0.18358759582042694, -1.412610650062561, 0.5712326169013977, -0.10928387939929962, 0.08911159634590149, -0.05017074942588806, 0.1284179985523224, -0.008759629912674427, -0.14195963740348816, -0.35502979159355164, 0.0030482462607324123, 0.35058143734931946) * l0(1.0, 0.0);
	r += mat4(-0.14148330688476562, 0.01605115458369255, -0.10864079743623734, 0.025291137397289276, 0.3741024136543274, -0.011616036295890808, 0.38574454188346863, -0.057806674391031265, -0.040824003517627716, 0.09253045916557312, -0.07493765652179718, -0.010785670951008797, 0.014395746402442455, -0.01208135299384594, 0.037719354033470154, -0.0007262484286911786) * l0(-1.0, 1.0);
	r += mat4(-0.11596117913722992, -0.18918541073799133, 0.05797412618994713, -0.0012162943603470922, 0.1202765628695488, 0.5840207934379578, -1.3296904563903809, -0.04500779137015343, 0.05856649577617645, -0.06024378910660744, 0.020379751920700073, -0.07897345721721649, 0.18505817651748657, 0.062423914670944214, 0.05114617943763733, -0.009500013664364815) * l0(0.0, 1.0);
	r += mat4(0.07495201379060745, 0.0008547216420993209, -0.0063802823424339294, -0.047973766922950745, 0.1508634388446808, 0.13717524707317352, 0.13623610138893127, -0.6591857671737671, -0.05894215777516365, -0.022795455530285835, 0.0045659528113901615, 0.023536305874586105, -0.034693241119384766, 0.08900152146816254, -0.03240833431482315, 0.01867724396288395) * l0(1.0, 1.0);
	r += vec4(2.983390601229985e-08, 2.978997670766148e-08, 2.795643005981674e-08, 2.9416922231462195e-08);
	return tanh(r);
}

//!DESC CuNNy-1x4-shuffle
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

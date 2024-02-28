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
#define l0(x, y) LUMA_texOff(vec2(x, y)).r
vec4 hook() {
	vec4 r = vec4(0.0);
	r += vec4(0.032108813524246216, 0.00633752578869462, 0.02263726107776165, 0.021812861785292625) * l0(-1.0, -1.0);
	r += vec4(0.1999199390411377, 0.12939412891864777, -0.04965286701917648, -0.011700219474732876) * l0(0.0, -1.0);
	r += vec4(0.16445572674274445, 0.03212471678853035, -0.06512956321239471, -0.0066288914531469345) * l0(1.0, -1.0);
	r += vec4(-0.05953766405582428, 0.07104314118623734, -0.3544920086860657, -0.42847633361816406) * l0(-1.0, 0.0);
	r += vec4(-0.3659112751483917, 0.022573737427592278, 0.04623721167445183, 0.032778549939394) * l0(0.0, 0.0);
	r += vec4(0.10286014527082443, 0.13978266716003418, 0.02960309013724327, 0.003460763255134225) * l0(1.0, 0.0);
	r += vec4(0.013371308334171772, -0.019135933369398117, -0.004075331147760153, 0.041439227759838104) * l0(-1.0, 1.0);
	r += vec4(0.2900393307209015, -0.37597671151161194, 0.4383610785007477, 0.3505859375) * l0(0.0, 1.0);
	r += vec4(-0.09059973061084747, -0.09819842875003815, 0.02006220817565918, -0.0026418704073876143) * l0(1.0, 1.0);
	r += vec4(0.00228805560618639, 0.4169924259185791, 0.0014658634318038821, 0.000269583921181038);
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
	r += mat4(0.05163057520985603, -0.016559138894081116, -0.043103400617837906, 0.07216691970825195, -0.10913335531949997, -0.04747216776013374, 0.12394444644451141, 0.18499208986759186, -0.06503032147884369, -0.35644543170928955, 0.03853927552700043, 0.3115237355232239, 0.03844831883907318, 0.4501309096813202, -0.13505525887012482, -0.29241660237312317) * l0(-1.0, -1.0);
	r += mat4(-0.08369044959545135, -0.084321528673172, -0.021890906617045403, -0.17907202243804932, 0.0036814832128584385, 0.021311938762664795, -0.18525481224060059, -0.20733290910720825, -0.11647845804691315, -0.24323317408561707, -0.33105453848838806, -0.6778271198272705, 0.10430597513914108, 0.4268375635147095, 0.2664255201816559, 0.6770471930503845) * l0(0.0, -1.0);
	r += mat4(0.014593416824936867, -0.016545763239264488, -0.09829136729240417, -0.12228909879922867, 0.12469112873077393, 0.013325843028724194, 0.07540254294872284, 0.005239487625658512, 0.14537952840328217, -0.07258454710245132, -0.2639940083026886, -0.3545052111148834, -0.05627318471670151, 0.08886674046516418, 0.3171214759349823, 0.6516593098640442) * l0(1.0, -1.0);
	r += mat4(0.060340672731399536, 0.05321390554308891, -0.059262897819280624, 0.04790252074599266, -0.023842277005314827, 0.24940207600593567, -0.12126462906599045, 0.08311846852302551, -0.13136456906795502, -0.2792987823486328, -0.06694827228784561, 0.5710461735725403, 0.13623350858688354, 0.3176290988922119, 0.036610912531614304, -0.49316462874412537) * l0(-1.0, 0.0);
	r += mat4(0.18310770392417908, 0.1987166702747345, 0.28125083446502686, -0.03491804376244545, -0.26303327083587646, -0.3702584207057953, -0.1459021270275116, 0.16652674973011017, -0.04969283565878868, 0.031659502536058426, -0.20493195950984955, -0.4832448959350586, 0.1460999697446823, 0.22513514757156372, 0.37597739696502686, 0.5761717557907104) * l0(0.0, 0.0);
	r += mat4(-0.36578530073165894, 0.0036848261952400208, -0.024370253086090088, 0.15769760310649872, 0.2688784599304199, 0.06708157807588577, 0.11413490772247314, 0.03887967765331268, -0.22701211273670197, 0.23385857045650482, -0.13270080089569092, 0.02108719013631344, -0.0033832588233053684, -0.1831100732088089, 0.6402682065963745, 0.23683825135231018) * l0(1.0, 0.0);
	r += mat4(0.10984556376934052, 0.2016351819038391, 0.43066439032554626, 0.11935452371835709, 0.14594589173793793, 0.15751031041145325, 0.28000521659851074, 0.07688135653734207, 0.021700317040085793, -0.059713929891586304, -0.19191068410873413, 0.19698387384414673, -0.01613827794790268, -0.03824658319354057, 0.11378607898950577, -0.21765749156475067) * l0(-1.0, 1.0);
	r += mat4(-0.09936130791902542, -0.2396792620420456, -0.17636482417583466, 0.028874725103378296, -0.2548828423023224, -0.2587890625, -0.14501990377902985, -0.07300552725791931, -0.17405514419078827, -0.1380693018436432, -0.12496132403612137, 0.06215640902519226, 0.1372072994709015, 0.007485914509743452, 0.32714325189590454, -0.09302803874015808) * l0(0.0, 1.0);
	r += mat4(0.28563666343688965, 0.004530985374003649, 0.002688886132091284, 0.024548806250095367, 0.17528505623340607, 0.05956481397151947, -0.018559208139777184, 0.02036474086344242, -0.06713936477899551, 0.2326381802558899, -0.07204131782054901, -0.11998964846134186, 0.14860910177230835, -1.3241642713546753, 0.21925972402095795, 0.13416172564029694) * l0(1.0, 1.0);
	r += vec4(-0.016232291236519814, 0.03082306869328022, -0.00478560384362936, -0.13638150691986084);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-down
//!HOOK LUMA
//!BIND conv1_0
//!SAVE down
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv1_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(-0.44689613580703735, -0.32972896099090576, -0.38364455103874207, -0.3994143605232239, 0.10180681943893433, 0.13837027549743652, -0.0655129924416542, 0.029518770053982735, -0.006508576218038797, -0.16064445674419403, 0.042852845042943954, -0.04521017149090767, -0.6039247512817383, 0.09143897145986557, -0.07477061450481415, 0.16774088144302368) * l0(-1.0, -1.0);
	r += mat4(0.290038138628006, 0.028505047783255577, 0.30620676279067993, 0.15966413915157318, 1.065816044807434, 0.16451403498649597, 0.226064532995224, -0.3628798723220825, -0.14794892072677612, 0.4112812578678131, 0.2587895393371582, 0.4993523955345154, 0.0779016837477684, -0.9792725443840027, 0.3014277517795563, -0.12861576676368713) * l0(0.0, -1.0);
	r += mat4(-0.02123493328690529, 0.11206663399934769, -0.06357969343662262, 0.055542245507240295, -0.44804438948631287, 0.5449308156967163, -0.5136650204658508, 0.05268137902021408, 0.04967578127980232, -0.44629186391830444, 0.1352536380290985, -0.08139852434396744, -0.07006826251745224, 0.27765434980392456, -0.18701156973838806, 0.012267331592738628) * l0(1.0, -1.0);
	r += mat4(0.16250215470790863, 0.20111367106437683, 0.02704232931137085, 0.21110670268535614, -0.15318353474140167, -0.026559626683592796, 0.15380869805812836, 0.12485139816999435, 0.09353259950876236, 0.04448981210589409, -0.21029840409755707, -0.14607501029968262, 0.11323674768209457, 0.3255305588245392, -0.6683224439620972, 0.19259589910507202) * l0(-1.0, 0.0);
	r += mat4(0.046723976731300354, 0.01380891166627407, 0.1294751912355423, -0.03911491855978966, -0.30958110094070435, -0.5253915786743164, 0.7050752639770508, 0.13525570929050446, -0.09012709558010101, 0.0794248953461647, -0.5324276685714722, -0.09386354684829712, 0.7966418862342834, 0.1745867282152176, 0.17629197239875793, -1.1538634300231934) * l0(0.0, 0.0);
	r += mat4(-0.04465480148792267, -0.020386161282658577, -0.029994573444128036, 0.013159448280930519, -0.19196675717830658, -0.11262445151805878, -0.22530922293663025, 0.40389201045036316, 0.1062336191534996, 0.02527468092739582, 0.10786287486553192, -0.3331335783004761, -0.19484786689281464, 0.2587897777557373, -0.13051959872245789, 0.3310548663139343) * l0(1.0, 0.0);
	r += mat4(-0.023151259869337082, -0.026183582842350006, 0.012804832309484482, 0.0017392932204529643, 0.033945903182029724, -0.005438264459371567, -0.06473051756620407, -0.02537238784134388, 0.01038170326501131, -0.04162858799099922, 0.1879870891571045, 0.016293788328766823, 0.02142244204878807, -0.055119652301073074, 0.30956995487213135, 0.026870742440223694) * l0(-1.0, 1.0);
	r += mat4(-0.004930163733661175, -0.03537583351135254, -0.03654446825385094, -0.062382373958826065, 0.13916002213954926, 0.07785829156637192, -0.001270152861252427, -0.13807444274425507, -0.07251480221748352, 0.0015704854158684611, -0.05429472774267197, 0.10964491963386536, -0.22314447164535522, -0.15572473406791687, 0.29232269525527954, 0.3628169298171997) * l0(0.0, 1.0);
	r += mat4(-0.005100220907479525, 0.010041010566055775, 0.00023870778386481106, 0.01137620024383068, -0.046803466975688934, 0.0575520284473896, -0.016877232119441032, 0.06167881563305855, 0.012669818475842476, -0.008957216516137123, -0.028135396540164948, -0.007968551479279995, 0.03644445165991783, -0.007318971678614616, -0.0026394661981612444, 0.15927210450172424) * l0(1.0, 1.0);
	r += vec4(-2.1419790385834858e-08, -2.7721560158511238e-08, -2.4729624570341002e-08, -2.8898771375907018e-08);
	return tanh(r);
}

//!DESC CuNNy-1x4-shuffle
//!HOOK LUMA
//!BIND down
//!BIND easu
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
vec4 hook() {
	vec4 r = vec4(0.0);
	vec2 f = fract(down_pos * down_size);
	ivec2 i = ivec2(f * vec2(2.0));
	r.r = down_tex((vec2(0.5) - f) * down_pt + down_pos)[2*i.y + i.x];
	r.r += easu_tex(easu_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

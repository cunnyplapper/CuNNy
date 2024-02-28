// CuNNy 1x4 RCAS DS
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

//!DESC CuNNy-RCAS
//!HOOK LUMA
//!BIND easu
//!SAVE rcas
//!WIDTH easu.w
//!HEIGHT easu.h
//!COMPONENTS 1

// CuNNy: do not change unless changed during training as well
#define SHARPNESS 2.0
#define FSR_RCAS_LIMIT (0.25 - (1.0 / 16.0))

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
	float mn1L = min(AMin3F1(b, d, f), h);
	float mx1L = max(AMax3F1(b, d, f), h);
	vec2 peakC = vec2(1.0, -1.0 * 4.0);
	float hitMinL = min(mn1L, e) / (4.0 * mx1L);
	float hitMaxL = (peakC.x - max(mx1L, e)) / (4.0 * mn1L + peakC.y);
	float lobeL = max(-hitMinL, hitMaxL);
	float lobe = max(float(-FSR_RCAS_LIMIT), min(lobeL, 0.0)) * exp2(-clamp(float(SHARPNESS), 0.0, 2.0));
	float nz = 0.25 * b + 0.25 * d + 0.25 * f + 0.25 * h - e;
	nz = clamp(abs(nz) * APrxMedRcpF1(AMax3F1(AMax3F1(b, d, e), f, h) - AMin3F1(AMin3F1(b, d, e), f, h)), 0.0, 1.0);
	nz = -0.5 * nz + 1.0;
	lobe *= nz;
	float rcpL = APrxMedRcpF1(4.0 * lobe + 1.0);
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	pix.r = float((lobe * b + lobe * d + lobe * h + lobe * f + e) * rcpL);
	return pix;
}

//!DESC CuNNy-1x4-RCAS-DS-up:0
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
	r += vec4(-0.010753484442830086, 0.02678518369793892, 0.04451001062989235, -0.017212804406881332) * l0(-1.0, -1.0);
	r += vec4(-0.05106363445520401, 0.02190801128745079, -0.09871441125869751, 0.46345603466033936) * l0(0.0, -1.0);
	r += vec4(0.019496658816933632, -0.006528007797896862, -0.0396156832575798, -0.03554916009306908) * l0(1.0, -1.0);
	r += vec4(-0.07483737170696259, -0.16064488887786865, 0.013183305971324444, -0.12493552267551422) * l0(-1.0, 0.0);
	r += vec4(0.16576752066612244, -0.1381266713142395, -0.2512173652648926, -0.17481409013271332) * l0(0.0, 0.0);
	r += vec4(-0.00939335860311985, 0.0061818393878638744, 0.46490478515625, -0.12313920259475708) * l0(1.0, 0.0);
	r += vec4(0.19203229248523712, 0.4634961783885956, 0.012087534181773663, 0.04769789054989815) * l0(-1.0, 1.0);
	r += vec4(0.41858357191085815, -0.19549623131752014, -0.0886610671877861, -0.029643334448337555) * l0(0.0, 1.0);
	r += vec4(-0.11846916377544403, 0.062367744743824005, -0.0005735669983550906, 0.04618776589632034) * l0(1.0, 1.0);
	r += vec4(-0.22802734375, -0.04503132775425911, -0.03942877799272537, -0.03698589652776718);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-RCAS-DS-conv1:0
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
	r += mat4(-0.015287309885025024, 0.2116982489824295, 0.2408449798822403, 0.20981980860233307, 0.0063972026109695435, 0.014906646683812141, -0.005486490670591593, -0.12548929452896118, -0.07253782451152802, 0.2958901524543762, 0.4044265151023865, 0.26361531019210815, 0.03857473284006119, -0.06741452217102051, -0.12331151217222214, -0.17529144883155823) * l0(-1.0, -1.0);
	r += mat4(0.40070873498916626, -0.6295936107635498, -0.457186222076416, -0.4052751362323761, -0.07623755186796188, 0.6337567567825317, 0.24178794026374817, 0.38770103454589844, -0.09535736590623856, 0.1891101598739624, 0.2310335785150528, 0.3820987939834595, 0.09336057305335999, 0.21315614879131317, 0.10910768061876297, 0.0970739796757698) * l0(0.0, -1.0);
	r += mat4(0.3065541684627533, -0.10516463965177536, -0.15187443792819977, -0.2615143656730652, 0.25500667095184326, 0.03180428594350815, -0.6894878149032593, -0.03092416562139988, 0.003392399987205863, -0.01735580712556839, -0.09869157522916794, 0.041260965168476105, -0.0013156381901353598, -0.16650919616222382, -0.19498488306999207, -0.15410083532333374) * l0(1.0, -1.0);
	r += mat4(-0.02971775270998478, -0.1306288093328476, -0.09409945458173752, 0.02175627276301384, 0.0009744061972014606, 0.10275876522064209, 0.11402926594018936, -0.046682387590408325, 0.1583164632320404, -0.39474743604660034, -0.3237926959991455, -0.6816427111625671, -0.009322242811322212, 0.42675238847732544, 0.2939457893371582, 0.33580282330513) * l0(-1.0, 0.0);
	r += mat4(0.1038893535733223, -0.1058787927031517, -0.23216886818408966, -0.18672260642051697, 0.025184936821460724, 1.0117524862289429, 1.0195330381393433, 0.6308732032775879, 0.042983803898096085, 0.33207741379737854, 0.47193199396133423, 0.44081276655197144, 0.06706072390079498, 0.39803892374038696, 0.3896772563457489, 0.612388014793396) * l0(0.0, 0.0);
	r += mat4(0.006120116449892521, 0.1781923472881317, 0.006385084707289934, 0.017725689336657524, -0.026753174141049385, 0.5320654511451721, 0.5173865556716919, 0.5136723518371582, 0.09041072428226471, 0.12930679321289062, 0.08761801570653915, 0.11790750175714493, -0.07710961252450943, 0.3330098092556, 0.29393813014030457, 0.4837595522403717) * l0(1.0, 0.0);
	r += mat4(-0.01080163661390543, -0.01702514849603176, -0.06582225114107132, -0.026416992768645287, 0.014803296886384487, -0.2165527045726776, -0.10795202106237411, -0.1688847541809082, 0.020389370620250702, 0.3974606692790985, 0.37982943654060364, 0.0743379071354866, -0.015941783785820007, 0.22963209450244904, 0.2505226731300354, 0.39746731519699097) * l0(-1.0, 1.0);
	r += mat4(-0.008791801519691944, 0.1051899641752243, 0.2029232531785965, 0.10395849496126175, -0.00717563834041357, 0.07627899199724197, -0.0016503415536135435, 0.03387213498353958, -0.022959016263484955, 0.23077118396759033, 0.6000757217407227, 0.5137754678726196, 0.25784698128700256, -0.5140337347984314, -0.08159173280000687, -0.08068808168172836) * l0(0.0, 1.0);
	r += mat4(-0.01273987628519535, -0.05226050317287445, 0.01624525897204876, 0.03558441251516342, 0.0588756799697876, -0.09692484140396118, -0.0295124389231205, 0.10908891260623932, -0.007036022841930389, -0.10264070332050323, -0.14787890017032623, -0.13467183709144592, -0.0759473443031311, -0.04412340745329857, 0.40612196922302246, 0.16446630656719208) * l0(1.0, 1.0);
	r += vec4(-0.23497065901756287, -0.019698863849043846, -0.019492188468575478, -0.01949937269091606);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-RCAS-DS-down
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
	r += mat4(1.3517892360687256, 0.278872549533844, 0.19986592233181, -0.40215784311294556, 0.0033160645980387926, -0.13657887279987335, -0.18407228589057922, -0.06135306879878044, 0.24658827483654022, 0.003152247751131654, 0.1666378676891327, 0.03356105089187622, -0.14502555131912231, 0.11298667639493942, 0.026117069646716118, -0.012846139259636402) * l0(-1.0, -1.0);
	r += mat4(1.2154666185379028, 1.2343294620513916, 0.9621363282203674, 0.8797507286071777, 0.46571922302246094, 0.40961626172065735, -0.10970404744148254, -0.20136809349060059, -0.4185103178024292, 0.1787933111190796, 0.22253555059432983, 0.35449230670928955, -0.016803942620754242, -0.5175777077674866, -0.0020404693204909563, -0.014196698553860188) * l0(0.0, -1.0);
	r += mat4(0.1491464525461197, 1.3978618383407593, -0.4713503420352936, 0.3008054196834564, 0.030255325138568878, 0.22900402545928955, 0.04144115000963211, 0.022245662286877632, 0.20949861407279968, -0.1390208899974823, 0.05418611690402031, 0.09353642910718918, -0.21590392291545868, 0.007227221503853798, -0.1234498918056488, -0.11850016564130783) * l0(1.0, -1.0);
	r += mat4(1.1470720767974854, 0.8117827773094177, 1.1114407777786255, 0.7905301451683044, -0.26380982995033264, -0.031909048557281494, 0.08624516427516937, -0.11573860794305801, 0.5858181715011597, -0.11401069909334183, 0.4033184051513672, -0.07642916589975357, -0.2299817055463791, 0.3158130645751953, -0.37562814354896545, 0.33447155356407166) * l0(-1.0, 0.0);
	r += mat4(-0.09949825704097748, -0.29972103238105774, -0.32461631298065186, -0.32559967041015625, -0.7559856176376343, -0.7445604801177979, 0.3251362442970276, 0.34256646037101746, -0.2299727350473404, 0.7167962193489075, -1.0742188692092896, 0.09035974740982056, 0.5706591606140137, -0.4867790937423706, 0.2153291553258896, -0.992366373538971) * l0(0.0, 0.0);
	r += mat4(0.8356758952140808, 1.479529619216919, 0.8801335692405701, 1.2502505779266357, 0.15285395085811615, -0.03770679980516434, 0.18310712277889252, 0.3681511878967285, 0.10603482276201248, -0.17628775537014008, 0.16320542991161346, -0.5503013134002686, -0.16161109507083893, 0.3443208634853363, -0.2023545354604721, 0.3212893009185791) * l0(1.0, 0.0);
	r += mat4(0.45562824606895447, -0.23477110266685486, 1.4999507665634155, 0.39644742012023926, -0.031574539840221405, -0.11009999364614487, -0.18369799852371216, -0.07072044163942337, -0.13860653340816498, -0.007485120091587305, 0.07778278738260269, -0.13524940609931946, 0.09643949568271637, 0.0395781435072422, 0.11614461243152618, 0.18288199603557587) * l0(-1.0, 1.0);
	r += mat4(0.7992402911186218, 0.8567347526550293, 1.2555570602416992, 1.2382080554962158, 0.3606536388397217, 0.2368135154247284, -0.20942577719688416, -0.3251951336860657, -0.23750357329845428, -0.2580139935016632, -0.013415999710559845, 0.22140836715698242, 0.04810984805226326, 0.17156684398651123, 0.4296342730522156, 0.22798208892345428) * l0(0.0, 1.0);
	r += mat4(-0.40726855397224426, 0.11820071190595627, 0.18482698500156403, 1.3413316011428833, -0.016331735998392105, 0.20011091232299805, -0.004574517719447613, 0.03356192633509636, -0.061281803995370865, -0.1518554538488388, -0.01760394498705864, -0.03806552290916443, 0.019840361550450325, -0.0737205520272255, -0.03478218615055084, 0.06951019167900085) * l0(1.0, 1.0);
	r += vec4(-3.9761856029940645e-09, -1.8277422908496987e-09, -6.782998052123901e-10, -1.3944984056379894e-09);
	return tanh(r);
}

//!DESC CuNNy-1x4-RCAS-DS-shuffle
//!HOOK LUMA
//!BIND down
//!BIND rcas
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
vec4 hook() {
	vec4 r = vec4(0.0);
	vec2 f = fract(down_pos * down_size);
	ivec2 i = ivec2(f * vec2(2.0));
	r.r = down_tex((vec2(0.5) - f) * down_pt + down_pos)[2*i.y + i.x];
	r.r += rcas_tex(rcas_pos).r;
	r.a = 1.0;
	return clamp(r, 0.0, 1.0);
}

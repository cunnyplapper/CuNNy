// CuNNy 0x4 RCAS DS
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

//!DESC CuNNy-0x4-RCAS-DS-up:0
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
	r += vec4(0.02917497605085373, 0.1128552109003067, 0.003726027673110366, 0.009476088918745518) * l0(-1.0, -1.0);
	r += vec4(-0.031298380345106125, 0.04577822983264923, -0.025817980989813805, -0.18854640424251556) * l0(0.0, -1.0);
	r += vec4(-0.10258693248033524, -0.021326333284378052, 0.021495217457413673, 0.5006887316703796) * l0(1.0, -1.0);
	r += vec4(-0.011950965970754623, 0.17500823736190796, -0.04048074036836624, 0.04818372055888176) * l0(-1.0, 0.0);
	r += vec4(-0.0711297020316124, -0.5775967240333557, -0.04893266037106514, -0.18798932433128357) * l0(0.0, 0.0);
	r += vec4(0.10424843430519104, -0.04422325640916824, -0.027755580842494965, -0.13033699989318848) * l0(1.0, 0.0);
	r += vec4(0.011373049579560757, 0.06653258204460144, 0.027449684217572212, -0.06393139809370041) * l0(-1.0, 1.0);
	r += vec4(-0.06770023703575134, 0.18163293600082397, 0.5119776725769043, 0.07406043261289597) * l0(0.0, 1.0);
	r += vec4(-0.036590445786714554, 0.08666989207267761, -0.010312790982425213, -0.024121351540088654) * l0(1.0, 1.0);
	r += vec4(-0.07437034696340561, -0.046766143292188644, -0.4052729904651642, -0.058468904346227646);
	return max(r, 0.0);
}

//!DESC CuNNy-0x4-RCAS-DS-down
//!HOOK LUMA
//!BIND up_0
//!SAVE down
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) up_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.19473497569561005, 0.013821610249578953, 0.16514818370342255, 0.014726796187460423, 0.1309666782617569, 0.050760913640260696, 0.102307990193367, 0.006812394130975008, 2.0405147075653076, 1.1922266483306885, 1.7223070859909058, 1.1282742023468018, -0.16770672798156738, -0.18159697949886322, 0.18635280430316925, 0.11116118729114532) * l0(-1.0, -1.0);
	r += mat4(0.18231871724128723, -0.2192537486553192, 0.1388990432024002, 0.005609991494566202, 0.016917183995246887, 0.08579308539628983, 0.2509762942790985, 0.2590782940387726, 0.17522208392620087, 0.1878257393836975, -1.0446358919143677, -0.6992905139923096, 0.08631477504968643, 0.054324667900800705, 0.03577909991145134, 0.18408627808094025) * l0(0.0, -1.0);
	r += mat4(0.13640281558036804, -0.20099984109401703, 0.17692071199417114, 0.1702030897140503, 0.03776859864592552, 0.0422920398414135, -0.00035335568827576935, 0.05560866743326187, 1.2261502742767334, 1.8056432008743286, 1.0740641355514526, 0.8393064737319946, -0.111758753657341, -0.03999923914670944, -0.067866750061512, -0.08697234839200974) * l0(1.0, -1.0);
	r += mat4(-0.2660028338432312, 0.14113852381706238, 0.07499219477176666, -0.10573665797710419, -0.3085848391056061, 0.12280640751123428, -0.13705530762672424, 0.13348454236984253, -0.17538799345493317, -0.44045567512512207, 1.1555507183074951, 0.2872626781463623, 0.1711599975824356, 0.2316988706588745, -0.4407493472099304, -0.2548772990703583) * l0(-1.0, 0.0);
	r += mat4(0.0050896937027573586, -0.012366781011223793, 0.15633085370063782, -0.024911055341362953, -0.5132695436477661, -0.9276483058929443, -0.5413076281547546, -0.6777993440628052, 0.22969117760658264, 0.24060045182704926, 1.580445408821106, 1.304847002029419, -0.42258578538894653, -0.27833572030067444, -0.12915176153182983, -0.37598276138305664) * l0(0.0, 0.0);
	r += mat4(-0.10389969497919083, -0.0314907506108284, -0.2835604250431061, 0.10437694936990738, 0.30163946747779846, 0.24655775725841522, 0.24983879923820496, 0.09887632727622986, -0.9521360397338867, -0.5490454435348511, -0.1366807222366333, 1.092273473739624, 0.16290666162967682, 0.01029984001070261, -0.01404387317597866, 0.018741309642791748) * l0(1.0, 0.0);
	r += mat4(-0.04687732458114624, -0.034492865204811096, 0.03307078778743744, 0.12689140439033508, 0.02619832381606102, -0.004621888976544142, -0.12148582935333252, 0.03472893685102463, 0.5452688932418823, 0.3532402515411377, -0.16616560518741608, -0.061385221779346466, 0.48339956998825073, 0.3408239781856537, 0.7636725306510925, 0.5644542574882507) * l0(-1.0, 1.0);
	r += mat4(-0.1694413721561432, -0.10461001098155975, -0.030478619039058685, -0.1842365860939026, 0.18619751930236816, 0.10592401027679443, 0.0015763376140967011, -0.30146604776382446, 0.1542893499135971, 0.27315691113471985, -0.309514582157135, -0.17013810575008392, -0.3064773678779602, 0.10005666315555573, -0.5136723518371582, 0.06543087959289551) * l0(0.0, 1.0);
	r += mat4(-0.19191430509090424, 0.12600813806056976, -0.11284223943948746, -0.04203199967741966, 0.014143038541078568, 0.12413287162780762, 0.11645454168319702, 0.2626959979534149, 0.34403711557388306, 0.3703591227531433, -0.17819389700889587, -0.4084591567516327, 0.1780274361371994, -0.09690126776695251, 0.2744167447090149, -0.08105230331420898) * l0(1.0, 1.0);
	r += vec4(-4.9922181943884425e-09, -4.288239097149926e-09, -4.9114432520980245e-09, -6.839478761122564e-09);
	return tanh(r);
}

//!DESC CuNNy-0x4-RCAS-DS-shuffle
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

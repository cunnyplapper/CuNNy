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
#define SHARPNESS 0.5
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
	r += vec4(0.16746634244918823, -0.14813874661922455, -0.03772086650133133, 0.15757857263088226) * l0(-1.0, -1.0);
	r += vec4(0.09399866312742233, -0.017228715121746063, 0.04379730299115181, 0.08600426465272903) * l0(0.0, -1.0);
	r += vec4(0.07490748167037964, 0.01864359714090824, -0.01258799433708191, 0.16504184901714325) * l0(1.0, -1.0);
	r += vec4(0.07449373602867126, -0.12393994629383087, 0.04235595837235451, -0.12027270346879959) * l0(-1.0, 0.0);
	r += vec4(-0.5566406846046448, -0.15604734420776367, -0.20339155197143555, -0.8287973403930664) * l0(0.0, 0.0);
	r += vec4(0.16676822304725647, -0.026070307940244675, -0.06323245912790298, 0.12699230015277863) * l0(1.0, 0.0);
	r += vec4(0.045066751539707184, -0.008635386824607849, -0.012970821000635624, 0.004895241931080818) * l0(-1.0, 1.0);
	r += vec4(-0.003893899964168668, -0.3064473569393158, -0.06042640283703804, -0.15663594007492065) * l0(0.0, 1.0);
	r += vec4(-0.039379484951496124, 0.0031847492791712284, 0.46635425090789795, 0.1303708702325821) * l0(1.0, 1.0);
	r += vec4(-0.046811625361442566, -0.010728907771408558, -0.17138667404651642, 0.02902413159608841);
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
	r += mat4(-0.11901931464672089, -0.05629175901412964, -0.10299260169267654, -0.11577846109867096, 0.18234017491340637, -0.08173415064811707, -0.05034596845507622, 0.14584845304489136, 1.0585981607437134, 0.2338896542787552, 0.4025774896144867, -0.14520275592803955, -0.09543973952531815, 0.1547246277332306, -0.006135106552392244, 0.18798828125) * l0(-1.0, -1.0);
	r += mat4(-0.11314281821250916, -0.0935860276222229, 0.342773973941803, 0.22755518555641174, 0.0361851342022419, -0.2676030993461609, 0.026007814332842827, -0.2068326771259308, -0.5395984649658203, 0.7679309248924255, -0.2825654447078705, 0.5482132434844971, 0.14482036232948303, -0.20117437839508057, -0.2666192054748535, -0.3238063156604767) * l0(0.0, -1.0);
	r += mat4(0.09422244876623154, -0.01265675574541092, 0.11543000489473343, 0.20461000502109528, 0.010359261184930801, 0.1265615075826645, 0.1965949833393097, -0.04358116537332535, 0.32714930176734924, -0.21307216584682465, 0.21204954385757446, -0.23095981776714325, -0.09993758797645569, 0.0678107738494873, -0.03594213351607323, -0.1350088268518448) * l0(1.0, -1.0);
	r += mat4(0.22444692254066467, 0.35066869854927063, -0.0025033357087522745, 0.20858421921730042, -0.047456998378038406, 0.09672225266695023, 0.08145426213741302, -0.08960683643817902, -0.49316585063934326, -0.3813101351261139, 0.6582641005516052, 0.39813491702079773, -0.2457643747329712, -0.04142739996314049, -0.18318353593349457, -0.012501131743192673) * l0(-1.0, 0.0);
	r += mat4(-0.5584397315979004, -0.45411548018455505, -1.0411893129348755, -0.7636740803718567, -0.0011286623775959015, 0.2982757091522217, 0.08955533057451248, -0.0425320602953434, -0.3625221252441406, -0.7296604514122009, -0.7190972566604614, -0.13939855992794037, -0.00886221881955862, -0.1792738288640976, 0.6646268963813782, 0.16153492033481598) * l0(0.0, 0.0);
	r += mat4(0.41281864047050476, 0.1899186223745346, 0.20164893567562103, -0.2860179841518402, 0.0338679701089859, 0.05209140479564667, 0.07334461808204651, 0.07321158796548843, -0.0033335424959659576, 0.12659446895122528, 0.19478245079517365, -0.011349284090101719, -0.2535005509853363, -0.2918912470340729, -0.1830160915851593, 0.20381200313568115) * l0(1.0, 0.0);
	r += mat4(-0.11132276803255081, -0.03187066689133644, 0.10568729788064957, 0.14107535779476166, 0.07898762822151184, 0.09192847460508347, 0.19693118333816528, -0.1049751490354538, 0.3642951548099518, 0.16847601532936096, -0.2560183107852936, -0.34914717078208923, 0.14017409086227417, 0.120643749833107, 0.023718195036053658, 0.09400106221437454) * l0(-1.0, 1.0);
	r += mat4(0.21628950536251068, 0.07234393060207367, 0.2782880961894989, 0.09156200289726257, 0.06744088232517242, -0.16271917521953583, -0.14654836058616638, -0.008899765089154243, 0.08248645067214966, 0.3096509277820587, 0.14275792241096497, 0.017391927540302277, 0.019537875428795815, 0.023297732695937157, -0.31749504804611206, -0.24462884664535522) * l0(0.0, 1.0);
	r += mat4(-0.056381937116384506, 0.0666503831744194, 0.15617376565933228, 0.36803990602493286, -0.289675235748291, -0.14851431548595428, 0.18982702493667603, -0.056396305561065674, -0.10640038549900055, -0.12497007101774216, -0.1304280161857605, 0.044158291071653366, 0.17440438270568848, 0.1429748386144638, 0.026972465217113495, -0.18017560243606567) * l0(1.0, 1.0);
	r += vec4(0.003921508323401213, 0.00392150366678834, 0.003921505529433489, 0.0039215087890625);
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

// CuNNy 1x8 RCAS DS
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

//!DESC CuNNy-1x8-RCAS-DS-up:0
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
	r += vec4(-0.0017286239890381694, 0.040282461792230606, 0.009780226275324821, 0.020968029275536537) * l0(-1.0, -1.0);
	r += vec4(-0.03429677337408066, 0.38183271884918213, 0.1302851289510727, 0.18701167404651642) * l0(0.0, -1.0);
	r += vec4(0.04577245935797691, -0.15682587027549744, -0.013615841045975685, -0.012750002555549145) * l0(1.0, -1.0);
	r += vec4(0.19042739272117615, -0.022758271545171738, 0.15414999425411224, -0.015403644181787968) * l0(-1.0, 0.0);
	r += vec4(-0.4462892711162567, 0.17753151059150696, -0.13971908390522003, 0.11657188832759857) * l0(0.0, 0.0);
	r += vec4(-0.04656613990664482, -0.06056484952569008, 0.15771503746509552, -0.38851940631866455) * l0(1.0, 0.0);
	r += vec4(0.18039439618587494, -0.10229222476482391, 0.07070759683847427, 0.05520780012011528) * l0(-1.0, 1.0);
	r += vec4(0.10609777271747589, -0.132276251912117, -0.5722654461860657, 0.05726945772767067) * l0(0.0, 1.0);
	r += vec4(0.008254538290202618, -0.08078315109014511, 0.07537944614887238, 0.15164558589458466) * l0(1.0, 1.0);
	r += vec4(0.007325530517846346, 0.007564886007457972, 0.06882207840681076, 0.1453387439250946);
	return max(r, 0.0);
}

//!DESC CuNNy-1x8-RCAS-DS-up:1
//!HOOK LUMA
//!BIND LUMA
//!SAVE up_1
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) LUMA_texOff(vec2(x, y)).r
vec4 hook() {
	vec4 r = vec4(0.0);
	r += vec4(0.2545761466026306, 0.004618550185114145, -0.012678911909461021, 0.0017171163344755769) * l0(-1.0, -1.0);
	r += vec4(0.014872374944388866, 0.4597979485988617, 0.07943752408027649, 0.04972756281495094) * l0(0.0, -1.0);
	r += vec4(-0.08655665069818497, -0.12569186091423035, 0.054130177944898605, 0.020060479640960693) * l0(1.0, -1.0);
	r += vec4(0.055039916187524796, -0.006390923634171486, 0.048958636820316315, -0.10414979606866837) * l0(-1.0, 0.0);
	r += vec4(-0.22285351157188416, -0.032155219465494156, -0.08971837162971497, -0.11041077226400375) * l0(0.0, 0.0);
	r += vec4(-0.23845426738262177, -0.3056517243385315, 0.42462584376335144, -0.08576206862926483) * l0(1.0, 0.0);
	r += vec4(0.07669573277235031, -0.0018081213347613811, 0.005828307941555977, -0.12876293063163757) * l0(-1.0, 1.0);
	r += vec4(0.07581694424152374, -0.024556783959269524, -0.1086236760020256, 0.4599612057209015) * l0(0.0, 1.0);
	r += vec4(0.06811481714248657, 0.03318900614976883, -0.013603225350379944, 0.01488170400261879) * l0(1.0, 1.0);
	r += vec4(0.015032456256449223, 0.008893000893294811, -0.052942387759685516, -0.018991826102137566);
	return max(r, 0.0);
}

//!DESC CuNNy-1x8-RCAS-DS-conv1:0
//!HOOK LUMA
//!BIND up_0
//!BIND up_1
//!SAVE conv1_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) up_0_texOff(vec2(x, y))
#define l1(x, y) up_1_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.07556890696287155, -0.05756029859185219, -0.051825132220983505, 0.08625855296850204, 0.07006819546222687, 0.06972809135913849, 0.010409297421574593, 0.09985270351171494, -0.10869442671537399, 0.4001217782497406, -0.05767860636115074, -0.22776438295841217, -0.09299469739198685, -0.342144250869751, 0.14827364683151245, 0.28282058238983154) * l0(-1.0, -1.0);
	r += mat4(0.14567288756370544, 0.3942480981349945, 0.0559740886092186, 0.211537167429924, 0.010893816128373146, 0.18709908425807953, 0.1797466278076172, 0.06374424695968628, -0.66196209192276, 0.8515910506248474, -0.6752632260322571, -0.6951921582221985, 0.11357962340116501, -0.2930505573749542, 0.023652901872992516, 0.05001315847039223) * l0(0.0, -1.0);
	r += mat4(0.39169400930404663, 1.2979925870895386, 0.23744195699691772, 0.5070420503616333, 0.4306660294532776, -0.4693355858325958, 0.05134236440062523, 0.17236675322055817, -0.3105589747428894, 0.2310536801815033, -0.15736062824726105, -0.15256044268608093, 0.055253662168979645, -0.16535533964633942, -0.006995119620114565, -0.014450720511376858) * l0(1.0, -1.0);
	r += mat4(0.08094672113656998, 0.16759085655212402, 0.15107950568199158, -0.07193958759307861, -0.27067455649375916, -0.11542249470949173, -0.08133399486541748, 0.004829373210668564, 0.11713405698537827, 0.1959306299686432, 0.1370813101530075, 0.2128218561410904, -0.061311133205890656, -0.07723086327314377, -0.15375326573848724, -0.1595420241355896) * l0(-1.0, 0.0);
	r += mat4(0.16993527114391327, 0.3720725476741791, 0.5175541639328003, 0.3778516948223114, -0.4092484414577484, 0.08416764438152313, -0.46583178639411926, -0.32676446437835693, -0.07504399865865707, 0.17817071080207825, -0.25579503178596497, -0.028218155726790428, -0.4055238664150238, -0.4848273694515228, -0.44967374205589294, 0.05847322568297386) * l0(0.0, 0.0);
	r += mat4(-0.11494217067956924, 0.45103034377098083, 0.5332044363021851, 0.3974771499633789, 0.16190205514431, 0.20470626652240753, -0.08933251351118088, -0.41515594720840454, 0.10264964401721954, -0.006654019933193922, -0.01797129027545452, 0.12650950253009796, 0.13044288754463196, -0.23379917442798615, -0.0005794923636130989, -0.15672273933887482) * l0(1.0, 0.0);
	r += mat4(-0.08663542568683624, -0.05716600641608238, -0.14320781826972961, -0.320681095123291, -0.16152013838291168, -0.08726054430007935, -0.2000933140516281, -0.09162101149559021, 0.13506262004375458, -0.08523241430521011, 0.11594704538583755, 0.03768423944711685, 0.028002874925732613, 0.12321536988019943, -0.05504773557186127, -0.19094523787498474) * l0(-1.0, 1.0);
	r += mat4(0.3116735517978668, 0.006781419739127159, -0.1342305988073349, 0.09880664944648743, -0.2916557490825653, 0.14445236325263977, -0.47065141797065735, -0.2954334318637848, 0.09912075102329254, 0.07803910970687866, 0.19676798582077026, 0.13858015835285187, 0.1032993346452713, -0.19847215712070465, -0.0016809594817459583, 0.1870105266571045) * l0(0.0, 1.0);
	r += mat4(0.0702969953417778, -0.22314660251140594, -0.08404466509819031, 0.09200394153594971, 0.2869633436203003, 0.10154354572296143, -0.27696743607521057, -0.21048597991466522, 0.12083993852138519, -0.08237569779157639, 0.1635676473379135, 0.14458803832530975, 0.1830296516418457, 0.10714494436979294, -0.14586128294467926, -0.11782768368721008) * l0(1.0, 1.0);
	r += mat4(0.06613712757825851, 0.0323532298207283, -0.02337317354977131, -0.05336910858750343, 0.05945939943194389, -0.10254663974046707, -0.027230985462665558, 0.02230367250740528, 0.18099458515644073, -0.22852373123168945, 0.05214807391166687, 0.011353405192494392, -0.3077431917190552, -0.4315170645713806, -0.3308269679546356, 0.0974116176366806) * l1(-1.0, -1.0);
	r += mat4(-0.32325223088264465, 0.004908570554107428, -0.047959886491298676, -0.2336110770702362, 0.1251591145992279, -0.19481967389583588, 0.13359719514846802, 0.05206437036395073, 0.05758489668369293, -0.08224952965974808, 0.09230510890483856, 0.4160696268081665, -0.2601619064807892, -0.7739402055740356, -0.04597106948494911, -0.002121944446116686) * l1(0.0, -1.0);
	r += mat4(-0.032338786870241165, -0.08944076299667358, -0.09578617662191391, 0.0382428839802742, -0.4399585723876953, 0.48529401421546936, 0.12385285645723343, -0.16186170279979706, -0.12023301422595978, -0.19839391112327576, -0.04753020405769348, -0.025125492364168167, -0.0497150644659996, -0.13266409933567047, 0.07062847167253494, -0.04588950797915459) * l1(1.0, -1.0);
	r += mat4(-0.007388693280518055, -0.2763509750366211, -0.062296781688928604, -0.1178135946393013, 0.6230526566505432, 0.2641114294528961, 0.842050313949585, 0.44435814023017883, -0.1250041127204895, -0.869997501373291, -0.11531639099121094, -0.3201623260974884, 0.1352687031030655, 0.040540874004364014, 0.16048677265644073, -0.07053215056657791) * l1(-1.0, 0.0);
	r += mat4(-0.5085811018943787, -0.3239172101020813, -0.5488813519477844, -0.47971874475479126, 0.5489327907562256, 0.010046728886663914, 0.4267776310443878, 0.21656213700771332, 0.2925644814968109, -0.13482213020324707, 0.2509766221046448, 0.06898538768291473, 0.005266799591481686, 0.02734111063182354, 0.33150193095207214, 0.08865170925855637) * l1(0.0, 0.0);
	r += mat4(0.08485138416290283, -0.01593375764787197, -0.18799972534179688, -0.047120966017246246, -0.18994379043579102, 0.30708029866218567, 0.1386898308992386, 0.11155606061220169, 0.045997679233551025, -0.12613768875598907, 0.001101649715565145, -0.07530069351196289, 0.07019487023353577, 0.1733390986919403, 0.05133599415421486, 0.028051666915416718) * l1(1.0, 0.0);
	r += mat4(-0.06334665417671204, -0.01478583924472332, 0.08988670259714127, 0.02440568245947361, 0.31556418538093567, -0.0839555412530899, 0.1572604477405548, 0.3979032039642334, -0.11281105130910873, 0.5712965130805969, 0.22314639389514923, 0.05074470490217209, -0.08486348390579224, 0.07342889904975891, 0.0028472382109612226, -0.07982224225997925) * l1(-1.0, 1.0);
	r += mat4(-0.3473886251449585, 0.14577747881412506, -0.4316460192203522, -0.18638339638710022, 0.16688120365142822, 0.0023844498209655285, 0.6879067420959473, 0.05285603925585747, 0.017158450558781624, -0.21903911232948303, 0.0946478620171547, 0.08593785017728806, 0.04552236944437027, 0.1839514523744583, -0.05920172482728958, -0.11230681091547012) * l1(0.0, 1.0);
	r += mat4(-0.03993538022041321, 0.09482089430093765, -0.07203123718500137, -0.010579926893115044, -0.5409262776374817, -0.21700875461101532, 0.06056645140051842, 0.05382722243666649, -0.22900207340717316, 0.1081821545958519, -0.26075243949890137, -0.12056420743465424, 0.05019156634807587, 0.005117843393236399, -0.20222342014312744, -0.13511903584003448) * l1(1.0, 1.0);
	r += vec4(-0.022888604551553726, 0.09741272777318954, 0.09493573755025864, 0.006233004853129387);
	return max(r, 0.0);
}

//!DESC CuNNy-1x8-RCAS-DS-conv1:1
//!HOOK LUMA
//!BIND up_0
//!BIND up_1
//!SAVE conv1_1
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) up_0_texOff(vec2(x, y))
#define l1(x, y) up_1_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.03157394006848335, -0.05039096996188164, -0.08811396360397339, -0.026875756680965424, 0.02063046395778656, -0.018088195472955704, -0.07168889790773392, 0.027684643864631653, -0.07545185089111328, -0.0321936309337616, 0.07374782860279083, 0.002378494245931506, -0.0011137702967971563, -0.11820820719003677, -0.046053528785705566, 0.07325156033039093) * l0(-1.0, -1.0);
	r += mat4(0.05264941602945328, -0.3276519179344177, -0.10375267267227173, 0.12375140190124512, 0.02280394919216633, 0.11108379811048508, 0.09190431982278824, 0.10023881494998932, -0.151302769780159, -0.14612267911434174, -0.36296355724334717, -0.44969549775123596, 0.13506434857845306, 0.30943813920021057, -0.01675860770046711, -0.06083597615361214) * l0(0.0, -1.0);
	r += mat4(0.012906097806990147, -0.44045281410217285, -0.08356905728578568, 0.26143690943717957, -0.0394756980240345, 0.06438912451267242, -0.1394929736852646, -0.01740109547972679, 0.0075238896533846855, 0.07099059224128723, -0.027519453316926956, -0.1967281699180603, 0.033685870468616486, -0.0022354386746883392, -0.03970666602253914, 0.11803432554006577) * l0(1.0, -1.0);
	r += mat4(0.13914871215820312, 0.055551107972860336, 0.002378650475293398, -0.1819629669189453, -0.0781019851565361, -0.15477509796619415, 0.030481912195682526, -0.27242136001586914, -0.009538935497403145, -0.03491616249084473, -0.11400607228279114, 0.07105434685945511, -0.1355876624584198, 0.04271942004561424, -0.153804749250412, -0.406626433134079) * l0(-1.0, 0.0);
	r += mat4(0.2902402877807617, 0.5674923062324524, -0.38692131638526917, 0.150789275765419, 0.06967975199222565, -0.08672641962766647, -0.24038490653038025, -0.20177681744098663, -0.4795446991920471, -0.059747956693172455, -0.19619761407375336, -0.14906738698482513, -0.13454385101795197, -0.17637188732624054, 0.0073130629025399685, 0.18679240345954895) * l0(0.0, 0.0);
	r += mat4(0.22277382016181946, -0.7473610639572144, -0.214626282453537, 0.3793396055698395, -0.00790928490459919, 0.1266053467988968, -0.09605512022972107, -0.20146922767162323, -0.10221166163682938, -0.030955540016293526, -0.008184452541172504, -0.010397596284747124, 0.02735018916428089, 0.05549413710832596, 0.11955998092889786, 0.07037454098463058) * l0(1.0, 0.0);
	r += mat4(0.0111476955935359, -0.03258566930890083, 0.011114018969237804, -0.07839573919773102, -0.08104953169822693, 0.23492680490016937, 0.012672252021729946, -0.09711829572916031, 0.1567390263080597, 0.03197851404547691, -0.0656566321849823, 0.06399274617433548, -0.07472610473632812, 0.12841752171516418, -0.018227174878120422, 0.2095637172460556) * l0(-1.0, 1.0);
	r += mat4(0.4384828507900238, 0.0743899717926979, 0.044521912932395935, -0.16375163197517395, -0.37060636281967163, -0.19223958253860474, -0.05330895632505417, -0.054351065307855606, 0.12478586286306381, -0.038659293204545975, -0.15556861460208893, 0.13340193033218384, -0.05459251627326012, 0.10995188355445862, -0.0625695288181305, 0.38439440727233887) * l0(0.0, 1.0);
	r += mat4(0.20264661312103271, -0.05678385868668556, 0.284596711397171, 0.046930499374866486, -0.08152926713228226, 0.12964372336864471, 0.03957907855510712, -0.2552455961704254, 0.15380290150642395, -0.024515127763152122, -0.032857608050107956, 0.1438826024532318, -0.056036900728940964, -0.03788750246167183, -0.0693993791937828, -0.1193908229470253) * l0(1.0, 1.0);
	r += mat4(-0.0271587111055851, 0.03041662834584713, 0.07755114883184433, -0.016257571056485176, 0.01684836857020855, 0.054076630622148514, -0.212687149643898, -0.13970117270946503, -0.0321238674223423, -0.03821118175983429, 0.029751956462860107, 0.05713934823870659, -0.0053612422198057175, -0.019481975585222244, 0.04680449888110161, -0.03179435059428215) * l1(-1.0, -1.0);
	r += mat4(-0.0676836222410202, 0.06052129715681076, -0.04045150801539421, 0.011019722558557987, 0.012453502975404263, -0.12928812205791473, 0.06801886111497879, -0.04259996861219406, 0.002719723852351308, -0.05254732072353363, 0.034519024193286896, -0.09667043387889862, -0.14066413044929504, -0.2705081105232239, 0.03621554374694824, -0.4320441484451294) * l1(0.0, -1.0);
	r += mat4(-0.1025623008608818, 0.06221449747681618, -0.05586681887507439, 0.03308350592851639, 0.031369898468256, -0.15977603197097778, 0.06004878133535385, 0.029551170766353607, -0.02795358933508396, -0.03966432064771652, -0.13113753497600555, 0.08931440114974976, 0.0250160563737154, 0.07955752313137054, 0.032539837062358856, -0.20050421357154846) * l1(1.0, -1.0);
	r += mat4(-0.060275014489889145, 0.036256417632102966, 0.10102371126413345, -0.1047053337097168, 0.31817907094955444, 0.6114099621772766, 0.2028614580631256, 0.7864996790885925, 0.1471938043832779, 0.1318366974592209, -0.05921284854412079, -0.25719261169433594, -0.0577978752553463, 0.044299934059381485, -0.13310547173023224, -0.004737382754683495) * l1(-1.0, 0.0);
	r += mat4(-0.14404326677322388, -0.10408870875835419, -0.030354836955666542, -0.40202999114990234, 0.1132672131061554, -0.011884620413184166, 0.16004578769207, 0.41914716362953186, 0.1911063939332962, 0.07987534254789352, -0.07700618356466293, 0.3140372335910797, -0.43945562839508057, 0.38739630579948425, -0.1206214502453804, -0.16825012862682343) * l1(0.0, 0.0);
	r += mat4(0.027902400121092796, -0.19677354395389557, -0.03713057562708855, -0.2368163764476776, 0.023204801604151726, -0.09681300073862076, 0.03611334413290024, 0.26460811495780945, 0.07742910087108612, -0.05134838819503784, -0.0895429328083992, 0.16540949046611786, 0.12304642796516418, -0.12336337566375732, -0.045536451041698456, 0.2434677630662918) * l1(1.0, 0.0);
	r += mat4(-0.016838187351822853, 0.05191449448466301, -0.03842638432979584, 0.06827274709939957, 0.8265999555587769, -0.5367696285247803, 0.09943555295467377, 0.5798095464706421, -0.39871281385421753, -0.13330931961536407, 0.11448703706264496, -0.2555210590362549, 0.0721132829785347, -0.06922249495983124, -0.052566878497600555, 0.07011154294013977) * l1(-1.0, 1.0);
	r += mat4(-0.44732657074928284, -0.16648024320602417, -0.04689382016658783, -0.37319326400756836, 0.615418553352356, -0.9998977780342102, -0.012202571146190166, 0.09665308147668839, 0.19696137309074402, -0.013854374177753925, 0.1121969223022461, 0.0630168542265892, 0.2153463065624237, -0.04905250295996666, -0.028416821733117104, 0.031186066567897797) * l1(0.0, 1.0);
	r += mat4(-0.22731876373291016, -0.135030135512352, -0.03994230926036835, -0.04946140944957733, 0.12091302126646042, -0.0428360216319561, 0.057389646768569946, 0.23615925014019012, -0.10864458233118057, -0.10237637162208557, 0.17004159092903137, -0.15197312831878662, 0.06140908598899841, -0.07625342160463333, -0.20766997337341309, -0.0821848213672638) * l1(1.0, 1.0);
	r += vec4(0.035929158329963684, 0.030863070860505104, -0.08580378443002701, -0.08253835886716843);
	return max(r, 0.0);
}

//!DESC CuNNy-1x8-RCAS-DS-down
//!HOOK LUMA
//!BIND conv1_0
//!BIND conv1_1
//!SAVE down
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv1_0_texOff(vec2(x, y))
#define l1(x, y) conv1_1_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.11532942205667496, -0.007293303497135639, 0.15482816100120544, -0.004220165777951479, -0.09606218338012695, 0.028808824717998505, 0.04058278352022171, 0.06708367168903351, -0.054499413818120956, -0.105980783700943, -0.1930706799030304, -0.05346842482686043, 0.005645998287945986, 0.04096619039773941, -0.1032891646027565, 0.01590130478143692) * l0(-1.0, -1.0);
	r += mat4(-0.37011903524398804, -0.33754903078079224, 0.23680265247821808, 0.04548493027687073, 0.003217141143977642, -0.16573655605316162, -0.12280721962451935, -0.0637541115283966, 0.7168054580688477, 0.6347808837890625, 0.23961463570594788, 0.03997953608632088, 0.17776143550872803, 0.2116846889257431, -0.06909612566232681, -0.06476013362407684) * l0(0.0, -1.0);
	r += mat4(0.15968157351016998, 0.11511289328336716, -0.050361186265945435, 0.21915020048618317, -0.03378811106085777, 0.021665576845407486, -0.004946645814925432, -0.08052238821983337, -0.001816370291635394, 0.09024599939584732, -0.014239149168133736, 0.023126691579818726, -0.06270918995141983, -0.10032855719327927, 0.03963908553123474, -0.07836885005235672) * l0(1.0, -1.0);
	r += mat4(0.4898485243320465, 0.054177772253751755, 0.4144608676433563, 0.1161084920167923, -0.4063408374786377, 0.025409052148461342, -0.32683804631233215, -0.011125176213681698, 0.0682200938463211, -0.09006310254335403, 0.23584707081317902, -0.09106308966875076, -0.6347889304161072, -0.008638912811875343, -0.12887315452098846, -0.0022114200983196497) * l0(-1.0, 0.0);
	r += mat4(-0.2998116612434387, 0.9180172681808472, -1.0510923862457275, 0.04092559590935707, -0.12204908579587936, -0.5115979313850403, 0.13219493627548218, -0.3451812267303467, -0.9146944284439087, 0.015181630849838257, 0.11680635064840317, 0.8910688161849976, 0.6590940952301025, -0.598538875579834, 1.1680887937545776, 0.47193363308906555) * l0(0.0, 0.0);
	r += mat4(0.033847250044345856, -0.5011910200119019, 0.21241524815559387, -0.4462895393371582, -0.07315867394208908, -0.10606665909290314, -0.03161660581827164, 0.12278453260660172, 0.1254977136850357, -0.5770333409309387, -0.12759187817573547, -0.4931647777557373, -0.0651615783572197, 0.4638310968875885, -0.10928531736135483, 0.3395524024963379) * l0(1.0, 0.0);
	r += mat4(-0.06188349053263664, -0.02288547344505787, -0.005952601786702871, -0.10542172193527222, 0.20972532033920288, 0.2979350984096527, -0.1236465573310852, 0.19839273393154144, 0.05366027355194092, 0.0029206278268247843, -0.006894415710121393, -0.03627029433846474, 0.10719617456197739, 0.10187900811433792, -0.2917419373989105, 0.11589141935110092) * l0(-1.0, 1.0);
	r += mat4(-0.003526979126036167, 0.056413114070892334, 0.11559075862169266, 0.5058956742286682, -0.16204245388507843, -0.09098566323518753, -0.34327977895736694, -0.3638169765472412, 0.09061167389154434, 0.008124484680593014, -0.3959618806838989, -0.19061902165412903, -0.06446906924247742, -0.07782838493585587, -0.20172163844108582, -0.7817399501800537) * l0(0.0, 1.0);
	r += mat4(0.08601029217243195, -0.05579544976353645, 0.0942097157239914, -0.19972027838230133, 0.03460545092821121, -0.07967992126941681, -0.06653495877981186, -0.27209681272506714, -0.030772201716899872, 0.13134625554084778, 0.2014361321926117, 0.04039756953716278, 0.006059793755412102, -0.03219856321811676, -0.10416807979345322, -0.02178668975830078) * l0(1.0, 1.0);
	r += mat4(0.3134762644767761, 0.08129173517227173, -0.004735113121569157, 0.029142536222934723, -0.054741889238357544, -0.043849390000104904, -0.00826877262443304, 0.03883937746286392, -0.028433499857783318, 0.08588503301143646, 0.04986288398504257, 0.09805941581726074, -0.3374195694923401, 0.37898769974708557, 0.47600218653678894, 0.4132690131664276) * l1(-1.0, -1.0);
	r += mat4(-0.5973435640335083, -0.5337355732917786, -0.6685513854026794, -0.6941025853157043, -0.014768638648092747, -0.020574595779180527, -0.1303754448890686, -0.09166819602251053, 0.11231178045272827, -0.042597610503435135, -0.08207608759403229, -0.01322206761687994, -0.14316006004810333, -0.9315101504325867, 0.02602877840399742, 0.06568314135074615) * l1(0.0, -1.0);
	r += mat4(0.10423283278942108, 0.29659080505371094, 0.024920882657170296, 0.07335302233695984, -0.047523681074380875, -0.04824395850300789, -0.03186894580721855, -0.09106829762458801, 0.08329374343156815, 0.12487177550792694, 0.046907369047403336, -0.061118531972169876, -0.0497642420232296, 0.03095088340342045, 0.07976756989955902, 0.08799495548009872) * l1(1.0, -1.0);
	r += mat4(-0.04881591349840164, -0.07739309221506119, 0.2959003746509552, -0.03012683428823948, -0.10137014091014862, -0.1816658079624176, -0.08444666862487793, -0.17256082594394684, 0.06074440851807594, 0.0006274890038184822, 0.05710035189986229, -0.08930832147598267, 0.10650161653757095, 0.22480934858322144, -0.8782711029052734, 0.15017148852348328) * l1(-1.0, 0.0);
	r += mat4(0.07624120265245438, -0.02454272471368313, 0.1697351336479187, 0.20471084117889404, 0.2900451123714447, 0.2280275970697403, 0.29396480321884155, 0.2313164919614792, 0.035165101289749146, 0.10339035838842392, 0.03815099596977234, 0.06810760498046875, 1.098112940788269, 0.5761753916740417, 0.4748436212539673, -1.011722207069397) * l1(0.0, 0.0);
	r += mat4(-0.03188319876790047, 0.13113069534301758, 0.05724969506263733, 0.3569772243499756, -0.024925747886300087, 0.07794079929590225, -0.020437071099877357, 0.08915238082408905, -0.04643208160996437, 0.002920138882473111, -0.011972201056778431, 0.10133520513772964, -0.12793582677841187, 0.04297430068254471, -0.07756441086530685, 0.24733741581439972) * l1(1.0, 0.0);
	r += mat4(-0.016301309689879417, 0.012402028776705265, -0.03741488605737686, 0.03599390387535095, -0.0062231021001935005, 0.04375676438212395, -0.06486452370882034, -0.0436832457780838, -0.025921540334820747, 0.027534525841474533, 0.14581699669361115, 0.17623941600322723, -0.03646368533372879, -0.008550227619707584, 0.08121857047080994, -0.011935125105082989) * l1(-1.0, 1.0);
	r += mat4(0.014731970615684986, -0.03899748995900154, 0.014268068596720695, -0.09510660171508789, -0.11467759311199188, -0.07887934893369675, -0.003679565852507949, -0.005059490446001291, 0.023349490016698837, 0.052767738699913025, -0.0430879220366478, -0.04691622033715248, -0.12374698370695114, -0.029769709333777428, 0.11494861543178558, 0.35455721616744995) * l1(0.0, 1.0);
	r += mat4(-0.03048991970717907, 0.01947065070271492, -0.013821295462548733, 0.04675041884183884, 0.003534396179020405, -0.05981634557247162, -0.02447129786014557, -0.03951968997716904, -0.03108319453895092, -0.05483703315258026, 0.0034944890066981316, 0.013988669030368328, 0.14025525748729706, -0.06641808152198792, 0.0034959090407937765, -0.20463301241397858) * l1(1.0, 1.0);
	r += vec4(0.003014569403603673, 0.003660649759694934, 0.003153326688334346, 0.0036850033793598413);
	return tanh(r);
}

//!DESC CuNNy-1x8-RCAS-DS-shuffle
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

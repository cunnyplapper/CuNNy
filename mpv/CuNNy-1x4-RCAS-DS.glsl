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
	r += vec4(0.09664539992809296, -0.05659914016723633, 0.13466289639472961, 0.07758938521146774) * l0(-1.0, -1.0);
	r += vec4(0.28060877323150635, -0.13649071753025055, -0.0751580148935318, -0.1282355785369873) * l0(0.0, -1.0);
	r += vec4(0.02058769203722477, 0.12364574521780014, 0.033785298466682434, 0.07521463930606842) * l0(1.0, -1.0);
	r += vec4(0.017638953402638435, 0.015317009761929512, 0.06191565841436386, 0.11121530830860138) * l0(-1.0, 0.0);
	r += vec4(-0.038249414414167404, 0.004600675776600838, 0.22658047080039978, -0.22324804961681366) * l0(0.0, 0.0);
	r += vec4(-0.07864542305469513, -0.022687096148729324, -0.023071344941854477, -0.030699795112013817) * l0(1.0, 0.0);
	r += vec4(-0.0027607264928519726, -0.003079186426475644, 0.026857435703277588, -0.2130562961101532) * l0(-1.0, 1.0);
	r += vec4(0.023973610252141953, -0.09794212877750397, -0.1014019027352333, 0.04155272990465164) * l0(0.0, 1.0);
	r += vec4(0.06765661388635635, 0.002981869736686349, 0.010738884098827839, 0.12669992446899414) * l0(1.0, 1.0);
	r += vec4(0.10919784009456635, 0.025568675249814987, -0.004242688417434692, 0.04294673725962639);
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
	r += mat4(-0.07748668640851974, 0.05148541182279587, 0.03454535827040672, -0.10782840102910995, -0.24747313559055328, -0.019714903086423874, -0.2032899707555771, -0.12836821377277374, 0.10728230327367783, -0.1630215048789978, -0.011983564123511314, 0.0027590531390160322, -0.0741124078631401, -0.03896746039390564, 0.035857584327459335, -0.027074960991740227) * l0(-1.0, -1.0);
	r += mat4(-0.04394377022981644, 0.044626157730817795, -0.05858341604471207, 0.0012604964431375265, 0.004840266890823841, -0.07741789519786835, -0.027531739324331284, -0.15601636469364166, 0.06613493710756302, -0.14464029669761658, -0.08028457313776016, 0.07729107141494751, 0.12341293692588806, -0.06225263327360153, -0.12166671454906464, 0.02646731585264206) * l0(0.0, -1.0);
	r += mat4(-0.021886084228754044, -0.13389946520328522, -0.2766234874725342, 0.26354271173477173, 0.0032080658711493015, -0.2295568436384201, -0.2047802209854126, -0.04160169139504433, -0.03376968204975128, 0.0264254380017519, 0.015396312810480595, -0.21391242742538452, -0.009159491397440434, -0.13619336485862732, -0.21390925347805023, 0.02458432875573635) * l0(1.0, -1.0);
	r += mat4(-0.2571517825126648, -0.13223393261432648, -0.16447648406028748, -0.04390307143330574, -0.17396923899650574, -0.20315249264240265, -0.040939975529909134, -0.14156129956245422, 0.04767046496272087, -0.028917595744132996, -0.1891143023967743, -0.14767885208129883, 0.22778835892677307, -0.08684621751308441, -0.12173571437597275, -0.15241371095180511) * l0(-1.0, 0.0);
	r += mat4(-0.09795670956373215, 0.1265956312417984, -0.037296783179044724, -0.14989329874515533, -0.0796426460146904, -0.004608637187629938, -0.051979921758174896, 0.026088809594511986, -0.016306957229971886, -0.2613081932067871, -0.23735681176185608, -0.12403978407382965, 0.040364377200603485, -0.09987082332372665, -0.0061842286959290504, 0.025287501513957977) * l0(0.0, 0.0);
	r += mat4(-0.11363230645656586, -0.20159561932086945, -0.0763775110244751, -0.1944544017314911, -0.07876546680927277, -0.030475730076432228, -0.008194850757718086, -0.17067377269268036, -0.29991230368614197, -0.09143644571304321, -0.04436971992254257, -0.13798095285892487, -0.12193901836872101, 0.017028624191880226, 0.007311510853469372, -0.23744750022888184) * l0(1.0, 0.0);
	r += mat4(-0.12881873548030853, -0.0841185674071312, -0.1054743081331253, -0.017419133335351944, -0.12063583731651306, -0.07987275719642639, 0.05484940484166145, -0.008732818998396397, 0.11781634390354156, -0.1948470175266266, 0.24310028553009033, -0.018753597512841225, -0.06240365654230118, 0.12874621152877808, -0.06674997508525848, 0.022050274536013603) * l0(-1.0, 1.0);
	r += mat4(-0.11666318029165268, -0.22103333473205566, -0.18958811461925507, -0.06099389120936394, -0.06924066692590714, -0.03901837393641472, -0.17226889729499817, -0.10820659250020981, 0.10581130534410477, -0.012315160594880581, -0.0556100495159626, -0.2071683555841446, -0.247958242893219, -0.06827285140752792, 0.049078166484832764, -0.18862558901309967) * l0(0.0, 1.0);
	r += mat4(0.03397775813937187, 0.011788075789809227, -0.2090597301721573, -0.14764255285263062, -0.14181503653526306, 0.02393144927918911, 0.05466949939727783, -0.19431783258914948, -0.0754631832242012, -0.07150928676128387, -0.0890636220574379, 0.14978091418743134, -0.20106390118598938, 0.018207313492894173, -0.16006805002689362, 0.08455852419137955) * l0(1.0, 1.0);
	r += vec4(-0.013418544083833694, -0.04933513328433037, -0.06172824278473854, -0.03778626769781113);
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
	r += mat4(0.23029346764087677, -0.15118592977523804, -0.00469606788828969, 0.18750493228435516, 0.049477215856313705, 0.11224250495433807, 0.23006023466587067, 0.03305468335747719, 0.2233910709619522, 0.05230575054883957, 0.055323611944913864, 0.005922847427427769, -0.06933120638132095, 0.10784953832626343, 0.0014460633974522352, 0.0654851570725441) * l0(-1.0, -1.0);
	r += mat4(0.062495697289705276, -0.124239481985569, 0.10576695948839188, 0.21983161568641663, 0.19427871704101562, -0.00759058678522706, -0.01941782981157303, -0.04441441223025322, -0.13505488634109497, 0.07013557851314545, -0.03803221881389618, 0.054742712527513504, 0.30701684951782227, 0.053268641233444214, 0.03294967859983444, -0.03109113685786724) * l0(0.0, -1.0);
	r += mat4(0.15321524441242218, -0.24898433685302734, 0.10163386166095734, -0.019059309735894203, -0.12440578639507294, 0.05392298474907875, -0.10925188660621643, -0.12071246653795242, 0.13316123187541962, -0.018234234303236008, 0.09024514257907867, 0.020586712285876274, -0.18816900253295898, 0.027413057163357735, -0.12117515504360199, -0.1349644958972931) * l0(1.0, -1.0);
	r += mat4(-0.04340381547808647, 0.22633157670497894, 0.1576235145330429, 0.18444164097309113, -0.03779804706573486, 0.14696720242500305, 0.06802068650722504, -0.0895444005727768, 0.015764283016324043, -0.03348243609070778, -0.1586323380470276, 0.008907541632652283, 0.023753788322210312, -0.12607501447200775, 0.058626580983400345, 0.10442566126585007) * l0(-1.0, 0.0);
	r += mat4(-0.13269369304180145, -0.11366213858127594, -0.10531473904848099, -0.0024356397334486246, -0.051446832716464996, -0.06555759906768799, -0.048219479620456696, 0.13674838840961456, -0.23547866940498352, -0.10501935333013535, 0.022977065294981003, -0.12577444314956665, -0.3036627769470215, -0.09444213658571243, 0.10038696974515915, 0.27017614245414734) * l0(0.0, 0.0);
	r += mat4(-0.03367023542523384, 0.2189953476190567, 0.009513139724731445, 0.024783587083220482, 0.06279393285512924, 0.16799353063106537, 0.2322985678911209, 0.2489219605922699, -0.34143468737602234, -0.1762903928756714, 0.07626556605100632, 0.17282244563102722, -0.17085358500480652, -0.10022643208503723, 0.05548514425754547, 0.15856271982192993) * l0(1.0, 0.0);
	r += mat4(-0.1916780173778534, -0.11711348593235016, 0.1295124739408493, -0.18942341208457947, -0.011282175779342651, -0.027334418147802353, 0.04321642592549324, -0.17029325664043427, 0.11358115077018738, 0.16342240571975708, 0.13590531051158905, 0.19626539945602417, 0.003936024382710457, 0.009564624167978764, 0.18550218641757965, -0.018675142899155617) * l0(-1.0, 1.0);
	r += mat4(0.056284110993146896, 0.12888437509536743, -0.013031849637627602, -0.33032554388046265, 0.014490121975541115, -0.010787611827254295, -0.08739510178565979, -0.12144024670124054, 0.022458700463175774, 0.13372661173343658, 0.018885372206568718, -0.28923505544662476, -0.07517439872026443, 0.02193165197968483, 0.027133580297231674, 0.13041742146015167) * l0(0.0, 1.0);
	r += mat4(-0.13698972761631012, 0.03728041052818298, 0.04874216765165329, 0.16422614455223083, -0.2295828014612198, 0.10908252745866776, 0.16317076981067657, -0.1712757647037506, 0.11486902087926865, -0.0991891548037529, 0.335843950510025, 0.03471503034234047, -0.12306901812553406, 0.16581138968467712, -0.05662356689572334, -0.07357403635978699) * l0(1.0, 1.0);
	r += vec4(0.003921493887901306, 0.003921504598110914, 0.003921494819223881, 0.003921502269804478);
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

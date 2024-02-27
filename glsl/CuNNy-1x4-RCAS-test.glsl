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
#define SHARPNESS 0.2 // Controls the amount of sharpening. The scale is {0.0 := maximum, to N>0, where N is the number of stops (halving) of the reduction of sharpness}. 0.0 to 2.0.
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
	r += vec4(-0.0052056158892810345, -0.22607414424419403, -0.0817870944738388, 0.18212884664535522) * l0(-1.0, -1.0);
	r += vec4(-0.04574930667877197, 0.37254852056503296, 0.4216744005680084, 0.4651637673377991) * l0(0.0, -1.0);
	r += vec4(0.16931135952472687, 0.07650037109851837, -0.01629921793937683, -0.14111383259296417) * l0(1.0, -1.0);
	r += vec4(-0.03872075304389, -0.06247805804014206, -0.27545133233070374, 0.46076977252960205) * l0(-1.0, 0.0);
	r += vec4(0.848920464515686, -0.19267883896827698, -0.0019271605415269732, -0.3896483778953552) * l0(0.0, 0.0);
	r += vec4(-0.3525391221046448, -0.05361173301935196, -0.006597507279366255, 0.14293056726455688) * l0(1.0, 0.0);
	r += vec4(0.17391514778137207, 0.14222967624664307, 0.0026420585345476866, 0.0069335876032710075) * l0(-1.0, 1.0);
	r += vec4(-0.2724602222442627, 0.07124684005975723, -0.05356358364224434, -0.054264381527900696) * l0(0.0, 1.0);
	r += vec4(0.17724642157554626, -0.0007808659574948251, 0.01537694688886404, -0.002995006274431944) * l0(1.0, 1.0);
	r += vec4(0.00403369078412652, -0.013917889446020126, -0.003542665159329772, -0.0005375618929974735);
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
	r += mat4(-0.0800342783331871, 0.08662490546703339, -0.005844355560839176, 0.04768019914627075, -0.07777928560972214, 0.06052382290363312, -0.02566429413855076, 0.07458282262086868, -0.06323229521512985, -0.20751817524433136, 0.04023292660713196, -0.036056242883205414, -0.0057450709864497185, 0.03379565104842186, -0.00276874634437263, 0.054344888776540756) * l0(-1.0, -1.0);
	r += mat4(0.0650005117058754, 0.23689299821853638, -0.16654935479164124, -0.013555150479078293, -0.14008675515651703, -0.08994555473327637, -0.03258054703474045, -0.004008691757917404, -0.042538803070783615, -0.043759193271398544, 0.08663085103034973, -0.30598121881484985, 0.028749264776706696, 0.029232706874608994, 0.049952488392591476, 0.035355761647224426) * l0(0.0, -1.0);
	r += mat4(0.11284440010786057, -0.006538739427924156, 0.0274296086281538, -0.23158808052539825, -0.06116984784603119, -0.10472039878368378, 0.09009844064712524, -0.1699957400560379, 0.15739601850509644, 0.3291640281677246, 0.06833377480506897, -0.20883992314338684, 0.026227902621030807, -0.09543907642364502, 0.0010870923288166523, -0.07712474465370178) * l0(1.0, -1.0);
	r += mat4(0.1206400990486145, 0.08043552935123444, -0.1266113966703415, -0.005012187175452709, 0.042699798941612244, 0.05297122895717621, 0.013177137821912766, -0.15177300572395325, 0.026940885931253433, -0.08006961643695831, -0.06389030814170837, 0.0012710732407867908, -0.007622246630489826, -0.18665514886379242, -0.09025444090366364, -0.17873555421829224) * l0(-1.0, 0.0);
	r += mat4(-0.4632221460342407, -0.4698055684566498, -0.2785433232784271, -0.01895306259393692, 0.09713763743638992, -0.11566809564828873, 0.0075360131449997425, 0.2647849917411804, 0.2966581881046295, 0.4595128893852234, 0.06325966119766235, 0.036857351660728455, 0.2307354360818863, 0.24064761400222778, 0.3212343752384186, 0.004602776374667883) * l0(0.0, 0.0);
	r += mat4(0.13377057015895844, 0.025656169280409813, 0.019053161144256592, 0.009614448063075542, 0.20964816212654114, 0.3759657144546509, -0.08327508717775345, -0.08395767211914062, 0.4103259742259979, 0.6909649968147278, 0.19072221219539642, 0.0016833676490932703, -0.20948918163776398, -0.11156497150659561, -0.019880415871739388, -0.03341429680585861) * l0(1.0, 0.0);
	r += mat4(0.05025387555360794, -0.14957982301712036, 0.4024132192134857, 0.17065617442131042, 0.039673078805208206, 0.30512234568595886, -0.38996732234954834, -0.06291011720895767, -0.04450550675392151, -0.46972617506980896, -0.4898539185523987, -0.0342227965593338, -0.04977861046791077, -0.11988122761249542, -0.329889178276062, -0.1110837459564209) * l0(-1.0, 1.0);
	r += mat4(0.08023905009031296, 0.06731884181499481, 0.08422877639532089, -0.19776907563209534, -0.07516653835773468, -0.7675778269767761, -0.14533375203609467, -0.46823903918266296, 0.2568349242210388, -0.45240136981010437, -1.00313138961792, 0.1060137078166008, 0.038225673139095306, 0.19662801921367645, 0.38641321659088135, -0.2884077727794647) * l0(0.0, 1.0);
	r += mat4(0.049961186945438385, 0.08090677112340927, 0.0510641373693943, 0.13311536610126495, -0.10282914340496063, 0.16578231751918793, -0.1884223371744156, -0.0786159485578537, 0.1450868546962738, 0.0574442520737648, -0.020483165979385376, -0.06355512142181396, -0.11750764399766922, 0.06367859244346619, -0.06412272155284882, -0.14619699120521545) * l0(1.0, 1.0);
	r += vec4(-0.00416355999186635, -0.004351477138698101, -0.09442956745624542, -0.08882448077201843);
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
	r += mat4(0.006477818358689547, -0.22672609984874725, 0.25097665190696716, -0.02984929084777832, 0.1218186691403389, 0.17040987312793732, -0.23292842507362366, -0.10034191608428955, -0.11669064313173294, 0.2644716799259186, -0.1704290807247162, 0.12891831994056702, -0.5088178515434265, -0.17240604758262634, 0.28111401200294495, -0.24796168506145477) * l0(-1.0, -1.0);
	r += mat4(-0.5204691886901855, 0.05578647553920746, 0.5761710405349731, 0.7792894840240479, 0.35836344957351685, 0.10790708661079407, -0.32485872507095337, -0.3916005492210388, 0.3701459467411041, -0.5956331491470337, 0.01697823964059353, -0.6074687242507935, 0.17551289498806, -0.11714937537908554, -0.20409439504146576, 0.06981440633535385) * l0(0.0, -1.0);
	r += mat4(0.24047870934009552, -0.14306561648845673, 0.06696917116641998, 0.19580398499965668, -0.19852828979492188, 0.03075907938182354, -0.09459815174341202, -0.21142587065696716, 0.5874558091163635, 1.2000812292099, 0.09434053301811218, 0.5141406059265137, 0.06912428885698318, 0.014093867503106594, 0.0847746878862381, 0.058724068105220795) * l0(1.0, -1.0);
	r += mat4(0.3583984375, 0.02072731964290142, -0.00812657829374075, -0.1549559086561203, -0.13063880801200867, 0.21044936776161194, 0.1448378562927246, 0.3232419788837433, -0.07637034356594086, -0.10979665070772171, 0.03895677626132965, 0.17569947242736816, -0.2025354653596878, -0.17990006506443024, -0.10907085984945297, -0.10073638707399368) * l0(-1.0, 0.0);
	r += mat4(-0.7279974818229675, 0.42926934361457825, -1.7460933923721313, -0.535171389579773, 0.06818167865276337, -0.826239287853241, 0.7317579984664917, -0.07195618748664856, -0.3861944079399109, -0.11209898442029953, 0.20259533822536469, -0.1878257840871811, 0.3475947380065918, 0.12227384746074677, 0.37726548314094543, 0.025588659569621086) * l0(0.0, 0.0);
	r += mat4(0.9918851256370544, 0.036319833248853683, 0.668424129486084, -0.5800779461860657, -0.6044362187385559, 0.09210868179798126, -0.3881813883781433, 0.3952813148498535, -0.5957034230232239, -0.6959121227264404, 0.14975252747535706, 0.49482396245002747, 0.046135418117046356, 0.15223880112171173, -0.12076448649168015, -0.12584005296230316) * l0(1.0, 0.0);
	r += mat4(-0.04792971909046173, -0.056620676070451736, 0.13168561458587646, -0.08707361668348312, 0.09741596132516861, -0.0112327691167593, 0.08956462889909744, 0.14892619848251343, 0.020728588104248047, 0.01970093511044979, -0.02458983287215233, -0.06405273824930191, -0.010412003844976425, 0.1720781773328781, 0.049047987908124924, -0.021162033081054688) * l0(-1.0, 1.0);
	r += mat4(-0.15380869805812836, 0.06106490641832352, -0.045306719839572906, 0.41496750712394714, 0.3344043493270874, 0.14118941128253937, 0.20850422978401184, -0.21032626926898956, 0.20727476477622986, 0.000566156639251858, -0.07219754904508591, -0.01239738892763853, 0.11873479187488556, 0.31728455424308777, -0.026118049398064613, -0.12839272618293762) * l0(0.0, 1.0);
	r += mat4(-0.11731741577386856, -0.3076172173023224, 0.30242809653282166, -0.028850555419921875, -0.040648799389600754, 0.25349193811416626, -0.2861338257789612, 0.19318534433841705, 0.26927897334098816, 0.3705335259437561, -0.1360003501176834, -0.191170796751976, -0.10100702196359634, -0.27792027592658997, 0.01637767069041729, 0.2685922086238861) * l0(1.0, 1.0);
	r += vec4(1.60694710871212e-08, 1.5667636077409952e-08, 1.2944197713693484e-08, 2.7209472008848934e-08);
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

// CuNNy 0x4 NVL
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

//!DESC CuNNy-0x4-NVL-up:0
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
	r += vec4(0.1637423187494278, 0.5213013887405396, 0.05504212900996208, 0.11335067451000214) * l0(-1.0, -1.0);
	r += vec4(-0.019076718017458916, -0.31657838821411133, -0.027998844161629677, -0.08789962530136108) * l0(0.0, -1.0);
	r += vec4(0.00856601633131504, 0.05940142646431923, 0.08393961936235428, -0.02643093653023243) * l0(1.0, -1.0);
	r += vec4(-0.5842370986938477, -0.19448363780975342, 0.010816436260938644, -0.4306640923023224) * l0(-1.0, 0.0);
	r += vec4(0.2587888240814209, -0.13330088555812836, -0.3927399814128876, 0.004032681230455637) * l0(0.0, 0.0);
	r += vec4(-0.029116515070199966, 0.03841260448098183, -0.010478129610419273, 0.06956366449594498) * l0(1.0, 0.0);
	r += vec4(0.2192506492137909, 0.0015908509958535433, 0.11673224717378616, 0.3041526675224304) * l0(-1.0, 1.0);
	r += vec4(-0.03505421429872513, 0.0830293744802475, 0.31933584809303284, 0.22637996077537537) * l0(0.0, 1.0);
	r += vec4(0.016086190938949585, -0.03644900396466255, -0.08903514593839645, -0.048700060695409775) * l0(1.0, 1.0);
	r += vec4(-0.003148151794448495, -0.031893592327833176, -0.08227546513080597, -0.13621656596660614);
	return max(r, 0.0);
}

//!DESC CuNNy-0x4-NVL-down
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
	r += mat4(0.0001285873440792784, -2.6157439947382954e-07, 0.0025203032419085503, -1.1139277376059908e-05, -0.022587664425373077, -5.479132596519776e-07, -0.0041604554280638695, 8.583784619986545e-06, -0.5853216052055359, 0.043842192739248276, 0.12010272592306137, 0.2436521202325821, -0.011166317388415337, 1.0918913773139138e-07, -0.007131616584956646, 9.809437869989779e-06) * l0(-1.0, -1.0);
	r += mat4(-0.1352539211511612, 1.1766876014007721e-05, -0.09594207257032394, -0.013332261703908443, 0.03357122838497162, 0.005716306623071432, -0.007531582843512297, -0.024840712547302246, 0.5395588278770447, -0.2529304027557373, 0.03160055726766586, -0.030678214505314827, 0.5097745060920715, -0.06561741977930069, 0.07348635792732239, -0.05457375571131706) * l0(0.0, -1.0);
	r += mat4(0.17616094648838043, -0.0013162411050871015, 0.10912729054689407, 0.0881245955824852, 0.012791250832378864, -0.003783145686611533, 0.0014842081582173705, -0.026636634021997452, -0.07060601562261581, 0.14308717846870422, 0.013892008922994137, 0.05560488998889923, -0.05087193474173546, 0.5137479901313782, -0.13611510396003723, -0.089217908680439) * l0(1.0, -1.0);
	r += mat4(0.003399777226150036, -3.835658617390436e-07, 0.010780034586787224, 7.358183938777074e-05, 0.06338150799274445, -0.00567288976162672, 0.0038118064403533936, -0.0010675363009795547, 0.3877045512199402, 0.28417983651161194, -0.5644533634185791, 0.03609905764460564, -0.06552425026893616, -0.019856806844472885, 0.0026437784545123577, -0.014896166510879993) * l0(-1.0, 0.0);
	r += mat4(0.1702640801668167, -1.2488249012676533e-05, 0.10766591876745224, 0.01780085079371929, -0.3526463210582733, 0.0335453636944294, -0.01951424963772297, 0.1710371971130371, 0.1508931666612625, 0.010503668338060379, 0.21070222556591034, -0.6695528626441956, -0.38451504707336426, -0.004055798053741455, 0.3818359076976776, 0.1763509064912796) * l0(0.0, 0.0);
	r += mat4(-0.5058574080467224, -0.35662391781806946, -0.3487597107887268, -0.3428438603878021, 0.0981895700097084, -0.13915862143039703, -0.021482646465301514, -0.13428185880184174, -0.18604177236557007, 0.28236570954322815, -0.13047799468040466, -0.02075911872088909, 0.30054613947868347, -0.3500143587589264, -0.15704087913036346, 0.26270562410354614) * l0(1.0, 0.0);
	r += mat4(-0.00353241222910583, 5.490491048476542e-07, -0.013336041942238808, -6.222305091796443e-05, 0.041559163480997086, 0.008528364822268486, 0.10434587299823761, 0.002713883761316538, -0.060208264738321304, -0.11376359313726425, 0.25683721899986267, 0.009276047348976135, 0.02770351432263851, 0.005778220947831869, -0.13590247929096222, -0.019201459363102913) * l0(-1.0, 1.0);
	r += mat4(-0.0343017540872097, 8.988504305307288e-07, -0.011676150374114513, -0.0045013404451310635, 0.01740078441798687, -0.15946725010871887, -0.21537502110004425, -0.20884037017822266, -0.21297459304332733, -0.17943251132965088, 0.04080895707011223, 0.12963458895683289, 0.17036838829517365, 0.24416518211364746, -0.1327834576368332, -0.06512057036161423) * l0(0.0, 1.0);
	r += mat4(0.1391112506389618, 0.0837363749742508, 0.097932830452919, 0.037344299256801605, -1.0035006425823667e-06, 0.376382976770401, 0.3009093701839447, 0.5058688521385193, 0.060155969113111496, -0.0336201936006546, -0.18505840003490448, 0.1439482867717743, -0.08177796006202698, -0.04581863805651665, 0.13149958848953247, -0.15929056704044342) * l0(1.0, 1.0);
	r += vec4(-1.4248526802873585e-08, -7.740071694684048e-09, -1.3643642660099431e-08, -7.648057298581534e-09);
	return tanh(r);
}

//!DESC CuNNy-0x4-NVL-shuffle
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

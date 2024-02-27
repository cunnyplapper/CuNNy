// CuNNy 0x4
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

//!DESC CuNNy-0x4-up:0
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
	r += vec4(0.037901490926742554, -0.015649378299713135, 0.058197982609272, -0.0030759559012949467) * l0(-1.0, -1.0);
	r += vec4(-0.007221525069326162, 0.0954449400305748, -0.144651859998703, -0.0978124588727951) * l0(0.0, -1.0);
	r += vec4(0.03167401999235153, -0.06213381141424179, 0.08553649485111237, 0.48053744435310364) * l0(1.0, -1.0);
	r += vec4(0.07287652790546417, 0.12805911898612976, -0.10861916095018387, 0.01629609987139702) * l0(-1.0, 0.0);
	r += vec4(0.002820064779371023, -0.5214843153953552, 0.38445860147476196, -0.24375315010547638) * l0(0.0, 0.0);
	r += vec4(0.11988431960344315, 0.09692370891571045, -0.11005086451768875, -0.0033843456767499447) * l0(1.0, 0.0);
	r += vec4(-0.18658731877803802, 0.07835986465215683, 0.0430901013314724, -0.019897721707820892) * l0(-1.0, 1.0);
	r += vec4(-0.6906094551086426, 0.16845065355300903, -0.2133788913488388, 0.0399177111685276) * l0(0.0, 1.0);
	r += vec4(0.24851664900779724, 0.0011710223043337464, 0.023375991731882095, -0.023959286510944366) * l0(1.0, 1.0);
	r += vec4(0.0006659877835772932, 0.02986159548163414, -0.01947776786983013, -0.14420251548290253);
	return max(r, 0.0);
}

//!DESC CuNNy-0x4-down:0
//!HOOK LUMA
//!BIND up_0
//!SAVE down_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) up_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(-0.09843523800373077, 0.24558496475219727, 0.028317002579569817, 0.2687937617301941, 0.1303711235523224, 0.13819439709186554, 0.06470225006341934, 0.04808904603123665, -0.2623102068901062, -0.08628443628549576, -0.16650860011577606, 0.06515811383724213, -0.10288900882005692, -0.03963380679488182, 0.22429604828357697, 0.19977006316184998) * l0(-1.0, -1.0);
	r += mat4(0.13434281945228577, -0.358342707157135, 0.2833324074745178, -0.18164870142936707, 0.07008308917284012, 0.008126413449645042, 0.2299802154302597, 0.14194780588150024, 0.019786598160862923, -0.03930271044373512, -0.2549630403518677, -0.36434292793273926, 0.04606568440794945, -0.06773708760738373, -0.009307406842708588, 0.09588044136762619) * l0(0.0, -1.0);
	r += mat4(-0.27832430601119995, -0.015097911469638348, -0.136952206492424, 0.09801944345235825, 0.15356747806072235, 0.22021283209323883, 0.06801488995552063, 0.17039325833320618, -0.0807919055223465, -0.19092559814453125, -0.15771473944187164, -0.1373765617609024, -0.025186972692608833, 0.04548684507608414, 0.030161727219820023, -0.0005441006505861878) * l0(1.0, -1.0);
	r += mat4(-0.18310654163360596, -0.05859142914414406, -0.21728532016277313, 0.0729609876871109, -0.1139756441116333, 0.21592998504638672, 0.013640408404171467, 0.2705077528953552, 0.02846226841211319, -0.23974855244159698, -0.0578288771212101, -0.31633660197257996, 0.3353502154350281, 0.06276066601276398, -0.2998047471046448, -0.282227486371994) * l0(-1.0, 0.0);
	r += mat4(-0.005710492376238108, -0.12237804383039474, -0.00829168502241373, -0.2645893692970276, -0.7172617316246033, -0.8411582708358765, -0.619688868522644, -0.6687672138214111, 0.5246492624282837, 0.650391161441803, 0.7754343152046204, 0.7708004117012024, -0.3451802134513855, 0.1254919171333313, -0.11472345888614655, -0.22880898416042328) * l0(0.0, 0.0);
	r += mat4(-0.033773839473724365, -0.010812008753418922, -0.09330403059720993, -0.05498538538813591, 0.2231469452381134, 0.025417685508728027, 0.2736574709415436, 0.07252303510904312, -0.15876545011997223, -0.07270205765962601, -0.1479567438364029, -0.009959324263036251, 0.15866874158382416, -0.045995473861694336, -0.01607203111052513, -0.04173964262008667) * l0(1.0, 0.0);
	r += mat4(0.03288564085960388, 0.08545267581939697, -0.00783299095928669, 0.03443654626607895, -0.002040500519797206, -0.036158833652734756, -0.053525544703006744, 0.032406456768512726, -0.02639610879123211, -0.02078818902373314, -0.006315721198916435, -0.061295922845602036, 0.3497406244277954, 0.08514595031738281, 0.6617407202720642, 0.1328275352716446) * l0(-1.0, 1.0);
	r += mat4(-0.0020524514839053154, 0.007118231151252985, -0.02362098917365074, -0.009182009845972061, 0.23876623809337616, 0.14238987863063812, -0.04029037058353424, -0.18606603145599365, -0.20250293612480164, -0.12129012495279312, -0.00729594100266695, 0.1309274286031723, -0.37207067012786865, 0.15869159996509552, -0.556724488735199, 0.31904688477516174) * l0(0.0, 1.0);
	r += mat4(0.054838333278894424, -0.0005656008725054562, 0.045529354363679886, -0.005961819086223841, 0.021766047924757004, 0.12647119164466858, 0.06763402372598648, 0.11987365037202835, 0.07994073629379272, -0.01653319038450718, -0.016695527359843254, -0.1084861308336258, 0.2255363166332245, -0.04586514085531235, 0.264198899269104, -0.06324464827775955) * l0(1.0, 1.0);
	r += vec4(-3.0965946962169255e-07, 9.171261581286672e-07, -6.12553719747666e-07, 4.543774778653642e-08);
	return tanh(r);
}

//!DESC CuNNy-0x4-shuffle
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

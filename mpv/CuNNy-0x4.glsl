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
	r += vec4(-0.036987293511629105, 0.046761199831962585, 0.15039969980716705, -0.08708689361810684) * l0(-1.0, -1.0);
	r += vec4(0.013073982670903206, 0.17340043187141418, 0.090139240026474, -0.07490794360637665) * l0(0.0, -1.0);
	r += vec4(0.030821261927485466, 0.017365267500281334, 0.027565667405724525, -0.02573048509657383) * l0(1.0, -1.0);
	r += vec4(0.01579893007874489, 0.15775717794895172, -0.266385555267334, 0.012561065144836903) * l0(-1.0, 0.0);
	r += vec4(-0.1303708255290985, -0.4679107964038849, -0.4189318120479584, -0.025575969368219376) * l0(0.0, 0.0);
	r += vec4(-0.16064979135990143, 0.008891002275049686, 0.04884008318185806, -0.033257149159908295) * l0(1.0, 0.0);
	r += vec4(0.03054759092628956, 0.005330586805939674, -0.021564530208706856, -0.04223741590976715) * l0(-1.0, 1.0);
	r += vec4(-0.18408218026161194, 0.02325952611863613, -0.33496034145355225, 0.034883905202150345) * l0(0.0, 1.0);
	r += vec4(0.3824865520000458, -0.020692644640803337, 0.21135833859443665, -0.06837451457977295) * l0(1.0, 1.0);
	r += vec4(0.03645560145378113, 0.052122920751571655, 0.0681818425655365, -0.019850367680191994);
	return max(r, 0.0);
}

//!DESC CuNNy-0x4-down
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
	r += mat4(0.41699132323265076, 0.17431651055812836, 0.2124941349029541, 0.03562431409955025, -0.06235712021589279, -0.025001926347613335, -0.0004841733898501843, -0.050644319504499435, -0.1213449239730835, 0.13037002086639404, -0.0718935877084732, 0.13525459170341492, 0.0049821180291473866, -0.03704076632857323, -0.010540114715695381, 0.009771681390702724) * l0(-1.0, -1.0);
	r += mat4(-0.35449710488319397, 0.09245437383651733, -0.3017578423023224, 0.05288465693593025, -0.024912944063544273, -0.09497149288654327, 0.21818694472312927, 0.17487674951553345, 0.2565033435821533, -0.15771478414535522, 0.011312488466501236, -0.2045917510986328, -0.020171837881207466, -0.05228321999311447, -0.08519592136144638, -0.010705159977078438) * l0(0.0, -1.0);
	r += mat4(0.19069620966911316, -0.05135872960090637, 0.1694338619709015, -0.061157193034887314, 0.02616761438548565, 0.04134931042790413, -0.0033916460815817118, 0.058304909616708755, -0.07257260382175446, 0.13623332977294922, -0.14013661444187164, -0.08426831662654877, 0.0825265571475029, -0.11643284559249878, 0.03533097729086876, -0.05113920941948891) * l0(1.0, -1.0);
	r += mat4(-0.2900419235229492, -0.29394614696502686, 0.07824836671352386, 3.992590427515097e-05, 0.007608110550791025, 0.23486389219760895, -0.1342800259590149, 0.14428973197937012, -0.006328047718852758, 0.06013517454266548, -0.019479380920529366, 0.07683897763490677, -0.1310875564813614, 0.020073173567652702, 0.058188546448946, -0.0742945447564125) * l0(-1.0, 0.0);
	r += mat4(0.001902078976854682, -0.08892565220594406, -0.15673798322677612, -0.04749492183327675, -0.11059331893920898, -0.3466813266277313, -0.3845131993293762, -0.6113343834877014, -0.08422885835170746, -0.2192385196685791, 0.3467820882797241, -0.03135393187403679, 0.0224844291806221, 0.059040773659944534, 0.0466211698949337, 0.08818907290697098) * l0(0.0, 0.0);
	r += mat4(-0.007246890105307102, 0.028747329488396645, 0.041301991790533066, 0.004221722017973661, 0.08774080872535706, 0.1797066628932953, 0.0974121168255806, 0.10571405291557312, -0.18494585156440735, -0.15283380448818207, -0.02536758966743946, 0.24171698093414307, 0.030583815649151802, -0.06346350163221359, -0.020036730915308, -0.016491901129484177) * l0(1.0, 0.0);
	r += mat4(0.16412799060344696, 0.14696940779685974, -0.05213690921664238, -0.06932687759399414, 0.004605923313647509, -0.020686905831098557, 0.07691343128681183, 0.0646977648139, -0.0035195648670196533, 0.010579981841146946, -0.006735659204423428, 0.032618653029203415, -0.017578398808836937, 0.018341705203056335, 0.06745707988739014, 0.17392109334468842) * l0(-1.0, 1.0);
	r += mat4(-0.0340532548725605, 0.042844098061323166, 0.023859024047851562, 0.038452014327049255, 0.059166062623262405, 0.06213448569178581, 0.17812339961528778, 0.13134735822677612, 0.1196357011795044, 0.09220115840435028, -0.07241612672805786, -0.08223770558834076, -0.0028602241072803736, 0.0028869202360510826, 0.0883357971906662, 0.050331342965364456) * l0(0.0, 1.0);
	r += mat4(-0.006507643032819033, -0.04333462566137314, -0.02165677584707737, -0.02581958658993244, -0.051773689687252045, -0.04260310158133507, -0.049442749470472336, 0.028672445565462112, 0.09995932132005692, 0.1057143434882164, -0.021713171154260635, -0.08164943754673004, -0.054461296647787094, 0.15602275729179382, 0.052756741642951965, -0.03673836588859558) * l0(1.0, 1.0);
	r += vec4(-3.2782779157969344e-08, -3.026762840363517e-08, -2.8928418771556608e-08, -3.3381862607484436e-08);
	return tanh(r);
}

//!DESC CuNNy-0x4-shuffle
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

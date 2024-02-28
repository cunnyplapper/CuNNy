// CuNNy 1x4 NVL
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

//!DESC CuNNy-1x4-NVL-up:0
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
	r += vec4(0.11840516328811646, 0.030436266213655472, 0.1261518895626068, 0.2221674621105194) * l0(-1.0, -1.0);
	r += vec4(0.3748999536037445, -0.006470967084169388, -0.09405626356601715, 0.3681647777557373) * l0(0.0, -1.0);
	r += vec4(-0.19651323556900024, -0.03419569507241249, -0.04870240017771721, -0.022344334051012993) * l0(1.0, -1.0);
	r += vec4(-0.3157714605331421, 0.4513649046421051, 0.009089428000152111, -0.6131653189659119) * l0(-1.0, 0.0);
	r += vec4(-0.38900434970855713, -0.02690829709172249, 0.33127206563949585, 0.21148934960365295) * l0(0.0, 0.0);
	r += vec4(0.43652722239494324, 0.027981366962194443, -0.14607854187488556, -0.01168066542595625) * l0(1.0, 0.0);
	r += vec4(0.17754487693309784, 0.12177440524101257, 0.21967017650604248, 0.2377929985523224) * l0(-1.0, 1.0);
	r += vec4(-0.2054421454668045, -0.5710557103157043, 0.23133616149425507, 0.011354624293744564) * l0(0.0, 1.0);
	r += vec4(-0.0036751325242221355, 0.005319539457559586, 0.002714306116104126, -0.019681818783283234) * l0(1.0, 1.0);
	r += vec4(0.005442669615149498, 0.003976074513047934, -0.010554488748311996, -0.02656233124434948);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-NVL-conv1:0
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
	r += mat4(-0.16926559805870056, 0.01578947901725769, -0.4817967116832733, 0.1841818392276764, -1.4566495418548584, 0.021265719085931778, -5.361320972442627, 0.10456662625074387, 0.2078370600938797, 0.044955063611269, -0.42778998613357544, -0.040362294763326645, -0.022797148674726486, 0.0004349962982814759, 0.340740442276001, -0.11649486422538757) * l0(-1.0, -1.0);
	r += mat4(0.19766001403331757, -0.04113432765007019, -0.7634221315383911, -0.13560397922992706, 0.2361573576927185, 0.24665211141109467, 0.63796067237854, 0.4438229501247406, 0.20716825127601624, -0.15291501581668854, 0.060397908091545105, 0.07141021639108658, -0.013451953418552876, 0.04913821816444397, 0.2255638986825943, 0.04261396825313568) * l0(0.0, -1.0);
	r += mat4(-0.020418470725417137, -0.06893698126077652, -1.9570164680480957, -0.004674174822866917, 0.3349604904651642, 0.09045334905385971, -0.005136868916451931, 0.21142111718654633, -0.08786500990390778, -0.24944134056568146, 0.6288635730743408, 0.009146739728748798, 0.05733403563499451, -0.0455235093832016, -0.7639201283454895, 0.07512494921684265) * l0(1.0, -1.0);
	r += mat4(-0.27131733298301697, 0.19196319580078125, 0.016157574951648712, 0.8486203551292419, -0.44192859530448914, -0.0121488431468606, 0.2845715582370758, 0.06697379052639008, 0.12052876502275467, 0.06665661185979843, -0.4716739058494568, -0.08808402717113495, 0.02062365412712097, -0.02076350525021553, 0.11520003527402878, -0.33534324169158936) * l0(-1.0, 0.0);
	r += mat4(0.5796229839324951, 0.28985002636909485, -2.625234603881836, -0.05479827895760536, -0.06458237022161484, 0.23696516454219818, -0.7632815837860107, -0.6466743350028992, -0.12786169350147247, -0.3583809733390808, 0.35256120562553406, 0.4306641221046448, -0.7769667506217957, 0.008530194871127605, -0.5317971110343933, 0.16479092836380005) * l0(0.0, 0.0);
	r += mat4(0.06516555696725845, -0.1745782345533371, -3.9352028369903564, 0.01117057166993618, 0.05616268515586853, 0.10618148744106293, -0.013835837133228779, -0.16266755759716034, 0.08258581161499023, 0.17428240180015564, -0.3434845805168152, 0.1793370097875595, 0.14674711227416992, 0.6211594343185425, -3.0432534217834473, 0.05755813792347908) * l0(1.0, 0.0);
	r += mat4(-0.10536325722932816, 0.20652587711811066, -0.7016779184341431, -0.36831238865852356, -0.15378832817077637, 0.06909406930208206, -0.1379082053899765, -0.20079971849918365, -0.07716284692287445, -0.06748680770397186, 0.019218120723962784, 0.13621900975704193, 0.011343743652105331, 0.012895626947283745, 0.20907606184482574, -0.028686054050922394) * l0(-1.0, 1.0);
	r += mat4(0.11891400068998337, 0.2805528938770294, 0.0501687154173851, -0.3681521713733673, 0.007280147168785334, 0.07693371921777725, -0.2612208127975464, -0.1567453145980835, 0.033099714666604996, 0.34864234924316406, -0.17029857635498047, -0.2009667158126831, -0.032331936061382294, -0.25087183713912964, -0.10151748359203339, -0.42090895771980286) * l0(0.0, 1.0);
	r += mat4(-0.07726213335990906, -0.1158032938838005, -0.1994561105966568, -0.028789281845092773, 0.02246754989027977, -0.047090355306863785, 0.44328200817108154, -0.06985541433095932, -0.14179746806621552, -0.076910600066185, -0.2067323625087738, -0.1679745465517044, 0.2478877454996109, 0.053988825529813766, 0.21223609149456024, -0.014321461319923401) * l0(1.0, 1.0);
	r += vec4(-0.015531822107732296, -0.006218827795237303, 0.0034326082095503807, -0.013477697968482971);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-NVL-down
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
	r += mat4(-0.030686967074871063, 0.01980683021247387, -0.020191790536046028, -0.008704441599547863, 0.019174840301275253, -0.056911367923021317, 0.05956678465008736, -0.01861579902470112, -0.19186557829380035, 0.13175515830516815, -0.3154512345790863, -0.0007346824277192354, -0.032315295189619064, 7.672468171904256e-08, -0.003966517746448517, -0.0009427494369447231) * l0(-1.0, -1.0);
	r += mat4(0.027384186163544655, -0.07446381449699402, 0.03136514127254486, 0.06323252618312836, -0.24465253949165344, -0.0524229072034359, 0.11694048345088959, 0.2988799214363098, 1.3402280807495117, -0.7903183102607727, 0.4440763294696808, -1.4039722681045532, 0.05960766226053238, 0.03037245385348797, -0.07488296180963516, 0.025121400132775307) * l0(0.0, -1.0);
	r += mat4(-0.03139873966574669, -5.767907964582264e-07, -0.0049398536793887615, -0.05343570560216904, -0.003357500769197941, -0.07836753875017166, 0.025592532008886337, -0.046277858316898346, -0.8807511329650879, 0.9275814890861511, -0.6722907423973083, 0.5115706324577332, 0.27534762024879456, 0.22608239948749542, -0.16356220841407776, -0.2861326038837433) * l0(1.0, -1.0);
	r += mat4(0.04682613164186478, 0.050888773053884506, -0.021909674629569054, 0.05309469997882843, 0.20652374625205994, -0.0031234107445925474, 0.09805815666913986, -0.012902863323688507, -0.20173484086990356, 0.020543653517961502, 0.04458528384566307, 0.24761401116847992, -0.028611265122890472, -9.993392450269312e-05, -0.019003042951226234, 0.0025743478909134865) * l0(-1.0, 0.0);
	r += mat4(0.36166268587112427, -0.1974460482597351, 0.24336852133274078, -0.4165486693382263, -0.12030823528766632, 0.27872955799102783, -0.8143260478973389, -0.4218064546585083, 1.2566081285476685, -0.5692784190177917, 1.6598401069641113, -0.22306539118289948, 0.007225862704217434, 0.08405958861112595, 0.17803573608398438, 0.0274418406188488) * l0(0.0, 0.0);
	r += mat4(-0.018256597220897675, 0.4697266221046448, -0.09643290936946869, 0.38964828848838806, 0.09547442197799683, -0.07837925851345062, 0.0661538615822792, -0.1432262659072876, -0.9921631813049316, 1.409974217414856, -1.113282561302185, 1.2762130498886108, -0.4234776496887207, -0.5648380517959595, 0.46791619062423706, 0.4414074718952179) * l0(1.0, 0.0);
	r += mat4(-0.060760073363780975, -0.03380697965621948, 0.002053483622148633, 0.00040824557072483003, -0.04284553602337837, 0.004598553292453289, 0.03046589158475399, -0.013315701857209206, -0.3175061345100403, -0.060965895652770996, -0.22795777022838593, -0.058724746108055115, -0.007329375017434359, 0.0005352869629859924, -0.0626140609383583, -0.016808824613690376) * l0(-1.0, 1.0);
	r += mat4(-0.06090174615383148, 0.020984167233109474, -0.0008061577100306749, 0.04103704169392586, -0.05161457881331444, -0.05297296494245529, 0.19119681417942047, 0.2339359074831009, 0.3875165283679962, -1.1126470565795898, 0.9150748252868652, -0.8393645286560059, 0.08137905597686768, 0.007880114950239658, 0.035381849855184555, -0.011620570905506611) * l0(0.0, 1.0);
	r += mat4(-0.021149728447198868, -0.1187344565987587, -0.003437283681705594, -0.022232946008443832, -0.006211941130459309, -0.03894603252410889, 0.01294616237282753, 0.009515608660876751, -0.6549332737922668, 0.4598112404346466, -0.7325733304023743, 1.0349491834640503, 0.13818097114562988, 0.15769948065280914, -0.00438374187797308, -0.017269102856516838) * l0(1.0, 1.0);
	r += vec4(-7.70328068000481e-09, -1.3569256829271126e-08, -1.2759727496813866e-08, -9.606943685014357e-09);
	return tanh(r);
}

//!DESC CuNNy-1x4-NVL-shuffle
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

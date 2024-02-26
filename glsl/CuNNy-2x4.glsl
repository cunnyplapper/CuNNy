// CuNNy 2x4
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

//!DESC CuNNy-2x4-up:0
//!HOOK LUMA
//!BIND LUMA
//!SAVE up_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) LUMA_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += vec4(0.038517240434885025, 0.1231926754117012, 0.17909391224384308, -0.034152671694755554) * l0(-1.0, -1.0);
	r += vec4(-0.15277929604053497, 0.02154947631061077, 0.10450361669063568, -0.23527774214744568) * l0(0.0, -1.0);
	r += vec4(-0.15523669123649597, 0.06219127029180527, 0.008847476914525032, -0.016643710434436798) * l0(1.0, -1.0);
	r += vec4(0.07320109754800797, -0.09034839272499084, -0.5214844942092896, 0.49080395698547363) * l0(-1.0, 0.0);
	r += vec4(0.1567843109369278, 1.089460015296936, 0.258512020111084, 0.2948695719242096) * l0(0.0, 0.0);
	r += vec4(-0.33301636576652527, 0.005160646513104439, -0.033119894564151764, 0.07032396644353867) * l0(1.0, 0.0);
	r += vec4(-0.06474697589874268, -0.09730102866888046, 0.021539807319641113, -0.03710366040468216) * l0(-1.0, 1.0);
	r += vec4(0.14427633583545685, -0.1179766058921814, -0.031057657673954964, -0.03834585100412369) * l0(0.0, 1.0);
	r += vec4(0.1733398139476776, 0.1362304538488388, 0.015813108533620834, 0.037483613938093185) * l0(1.0, 1.0);
	r += vec4(0.005311719141900539, 0.008883590810000896, -0.00039549588109366596, -0.0024332276079803705);
	return max(r, 0.0);
}

//!DESC CuNNy-2x4-conv1:0
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
	r += mat4(-0.26138487458229065, 0.10280965268611908, 0.19662147760391235, 0.20702773332595825, -0.014727773144841194, -0.01134293619543314, 0.02262173965573311, -0.006200597155839205, -0.060666777193546295, -0.04769119247794151, -0.17732436954975128, 0.08394857496023178, 0.0008831355953589082, 0.004528369754552841, -0.029677074402570724, -0.05172230675816536) * l0(-1.0, -1.0);
	r += mat4(-0.1352836936712265, -0.15122531354427338, -0.19382691383361816, 0.15777835249900818, 0.21185441315174103, -0.008201227523386478, 0.02888941951096058, -0.08130044490098953, -0.23583737015724182, 0.04442079737782478, -0.05161524936556816, 0.10954190790653229, 0.10016240179538727, -0.1687910109758377, -0.09784552454948425, -0.1576799750328064) * l0(0.0, -1.0);
	r += mat4(-0.08360212296247482, 0.040138695389032364, -0.12452656775712967, 0.12526316940784454, -0.16223818063735962, -0.0916055366396904, -0.0794224739074707, 0.0977713093161583, -0.19579266011714935, 0.09790919721126556, -0.05064140632748604, 0.046463072299957275, 0.09006992727518082, 0.12458473443984985, 0.06288406252861023, -0.024972958490252495) * l0(1.0, -1.0);
	r += mat4(0.195997416973114, -0.10035859048366547, -0.297871857881546, 0.05778117477893829, -0.18888570368289948, 0.09282707422971725, 0.15886613726615906, 0.20846597850322723, 0.13134680688381195, -0.02543998323380947, 0.509391188621521, 0.10204567015171051, -0.02069055661559105, -0.1469726413488388, 0.16828247904777527, 0.20191246271133423) * l0(-1.0, 0.0);
	r += mat4(0.11170253902673721, -0.13711240887641907, -0.031769901514053345, 0.20678195357322693, 0.30502861738204956, 0.24637371301651, -0.22201389074325562, 0.3497113287448883, -1.1404117345809937, 0.11971703171730042, 0.6383054256439209, 0.5331544876098633, -0.21338056027889252, -0.19951817393302917, -0.29908913373947144, -0.1488712728023529) * l0(0.0, 0.0);
	r += mat4(-0.01688491739332676, -0.099480539560318, 0.06936431676149368, -0.04786242917180061, -0.0909229964017868, -0.21902643144130707, 0.02945557050406933, -0.05716188624501228, 0.04012598842382431, -0.016316860914230347, 0.8805736303329468, -0.454818457365036, 0.0929570347070694, 0.23872989416122437, 0.022202342748641968, 0.04421525076031685) * l0(1.0, 0.0);
	r += mat4(0.01609349250793457, -0.6025023460388184, -0.6383928060531616, 0.2932502329349518, -0.1342773288488388, 0.4466235339641571, -0.006554206367582083, -0.2326163500547409, -0.04761074483394623, -0.34668177366256714, -0.013417307287454605, 0.38427966833114624, -0.018037641420960426, -0.11157549172639847, 0.14472699165344238, 0.28028029203414917) * l0(-1.0, 1.0);
	r += mat4(-0.07583434134721756, 0.10522782802581787, -0.011799415573477745, -0.2761405110359192, 0.07686633616685867, -0.17360399663448334, -0.07314914464950562, -0.15185542404651642, -0.3319609463214874, 0.43914464116096497, 0.4775390326976776, -0.5371114611625671, -0.06752922385931015, -0.24251456558704376, 0.28025317192077637, -0.20439288020133972) * l0(0.0, 1.0);
	r += mat4(0.017880704253911972, 0.04273663088679314, 0.04429112374782562, -0.07143763452768326, -0.0538351871073246, 0.028647134080529213, -0.09252875298261642, -0.1295076459646225, 0.06001080572605133, 0.4757828116416931, 0.8808587789535522, -0.5371061563491821, 0.06533564627170563, 0.1071646511554718, 0.22117939591407776, 0.13875247538089752) * l0(1.0, 1.0);
	r += vec4(0.1979828178882599, -0.07591991871595383, -0.02998972125351429, -0.16357417404651642);
	return max(r, 0.0);
}

//!DESC CuNNy-2x4-conv2:0
//!HOOK LUMA
//!BIND conv1_0
//!SAVE conv2_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv1_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(-0.015145670622587204, -0.2026294320821762, 0.17724891006946564, 0.07903583347797394, 0.05353440344333649, -0.1224767416715622, -0.11561749875545502, -0.05530042573809624, 0.08606144040822983, 0.09112697094678879, -0.07715316116809845, -0.05846613645553589, -0.09876277297735214, -0.26461341977119446, 0.08999374508857727, 0.14196409285068512) * l0(-1.0, -1.0);
	r += mat4(-0.016901681199669838, -0.14887937903404236, 0.14665135741233826, -0.05975416302680969, -0.2537013292312622, -0.012589464895427227, -0.370140016078949, -0.052520811557769775, 0.034956302493810654, 0.04051588475704193, 0.3118865191936493, 0.11626346409320831, 0.108901247382164, -0.19793060421943665, -0.3416418731212616, -0.20397917926311493) * l0(0.0, -1.0);
	r += mat4(0.016795309260487556, -0.028165774419903755, -0.15059790015220642, -0.19775564968585968, -0.21532727777957916, 0.01788323186337948, 0.18136505782604218, 0.37397250533103943, -0.09355288743972778, 0.01688208058476448, 0.08056078106164932, -0.030016006901860237, -0.2822284698486328, -0.03535854071378708, -0.2978515326976776, -0.373234361410141) * l0(1.0, -1.0);
	r += mat4(0.10894474387168884, 0.3003626763820648, 0.1127258911728859, -0.13177388906478882, 0.1422254592180252, 0.6417438387870789, 0.09058890491724014, -0.1469726711511612, 0.2197907418012619, 0.23153801262378693, -0.132748082280159, -0.031397026032209396, -0.10060065239667892, 0.14240284264087677, 0.14238983392715454, -0.050623901188373566) * l0(-1.0, 0.0);
	r += mat4(0.113419309258461, -0.1411135494709015, -0.2919921576976776, 0.044728439301252365, 0.7013384103775024, -0.12314025312662125, 0.2051280438899994, -0.06478899717330933, -0.4039745330810547, 0.4931643009185791, 0.7246095538139343, 0.4927555322647095, 0.2383870631456375, 0.1652781367301941, 0.2861330211162567, 0.6580456495285034) * l0(0.0, 0.0);
	r += mat4(0.4551982581615448, -0.006378822028636932, -0.02871817536652088, -0.2508327066898346, -0.07879076153039932, 0.025149524211883545, 0.02863183058798313, 0.16697579622268677, -0.29655399918556213, 0.016850152984261513, 0.13236266374588013, -0.21150538325309753, -0.20503674447536469, -0.04482156038284302, -0.015586785972118378, -0.10034303367137909) * l0(1.0, 0.0);
	r += mat4(-0.19285015761852264, 0.07134973257780075, 0.03649425506591797, 0.3544921576976776, -0.08295752108097076, -0.10240644961595535, 0.03159601241350174, -0.07557934522628784, 0.3642582595348358, 0.5019540786743164, -0.08919425308704376, -0.16441640257835388, -0.07346319407224655, 0.003667230252176523, 0.0017783690709620714, -0.25962573289871216) * l0(-1.0, 1.0);
	r += mat4(0.23319992423057556, -0.021735472604632378, 0.10449087619781494, 0.5995511412620544, 0.08141042292118073, -0.19637639820575714, 0.08171682804822922, 0.024807125329971313, -0.052736684679985046, 0.2624267041683197, 0.14628608524799347, 0.08216675370931625, 0.08351141959428787, 0.022947607561945915, 0.013113822788000107, -0.03158136084675789) * l0(0.0, 1.0);
	r += mat4(0.00603869091719389, 0.03234288841485977, 0.00949595682322979, 0.18307554721832275, -0.10468563437461853, -0.012412485666573048, -0.01057406235486269, 0.05493198707699776, 0.1370306760072708, 0.03869834542274475, 0.021636702120304108, 0.012429317459464073, 0.07432913035154343, 0.05108049511909485, 0.007799656596034765, -0.02738472819328308) * l0(1.0, 1.0);
	r += vec4(-0.17138671875, 0.06520456820726395, 0.0032482300885021687, -0.14599618315696716);
	return max(r, 0.0);
}

//!DESC CuNNy-2x4-down:0
//!HOOK LUMA
//!BIND conv2_0
//!SAVE down_0
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#define l0(x, y) conv2_0_texOff(vec2(x, y))
vec4 hook() {
	vec4 r = vec4(0.0);
	r += mat4(0.0002193024120060727, 0.010859929025173187, -0.03388097509741783, -0.0032038388308137655, 0.03408239409327507, -0.011005784384906292, 0.01357678510248661, -0.03210553899407387, -0.013654908165335655, 0.03993745520710945, 0.031862445175647736, 0.07412517070770264, 0.1919056475162506, -0.16188141703605652, 0.046124301850795746, -0.15485058724880219) * l0(-1.0, -1.0);
	r += mat4(0.4248080253601074, -0.0666220411658287, -0.19145216047763824, -0.2808910012245178, -0.1860298067331314, 0.045750971883535385, -0.04676373675465584, 0.09546616673469543, 0.15093477070331573, -0.0018634120933711529, -0.028461962938308716, -0.07183726876974106, -0.2786766588687897, 0.2646483778953552, 0.057716745883226395, 0.24046407639980316) * l0(0.0, -1.0);
	r += mat4(-0.2313040941953659, 0.3505859971046448, -0.1895134598016739, -0.09994490444660187, -0.060445912182331085, -0.261295348405838, -0.07641661167144775, -0.19287104904651642, -0.04739925637841225, 0.04725107178092003, -0.006908583454787731, -8.25814058771357e-05, 0.1351466178894043, -0.0581216961145401, 0.029610350728034973, 0.07690579444169998) * l0(1.0, -1.0);
	r += mat4(-0.10326851159334183, 0.07126089185476303, 0.035570185631513596, 0.12212440371513367, 0.04089353606104851, 0.01912645809352398, 0.014295922592282295, 0.00846848450601101, -0.0385725311934948, 0.18133635818958282, 0.07564826309680939, 0.18017616868019104, 0.3344078063964844, -0.26113444566726685, 0.19092708826065063, -0.3101215362548828) * l0(-1.0, 0.0);
	r += mat4(0.035537317395210266, -0.4091826379299164, 0.7013694643974304, -0.07713670283555984, -0.10322542488574982, -0.11966957896947861, -0.2723236382007599, -0.1674814224243164, -0.058956045657396317, -0.4023037254810333, 0.3170923888683319, -0.007730191107839346, 0.1668270230293274, 0.7441422939300537, -0.705078125, 0.1586914211511612) * l0(0.0, 0.0);
	r += mat4(-0.426758736371994, -0.03593205660581589, -0.3368009626865387, 0.4801937937736511, 0.4756104052066803, 0.469597727060318, 0.36226680874824524, 0.2069552093744278, -0.18919052183628082, 0.006436176132410765, -0.11858708411455154, 0.16748030483722687, 0.20361328125, 0.1281871646642685, 0.17625969648361206, -0.24959950149059296) * l0(1.0, 0.0);
	r += mat4(0.04919244721531868, -0.011385137215256691, -0.06471697241067886, -0.021462738513946533, 0.00314796413294971, 0.0015082332538440824, 0.0457763746380806, 0.017161766067147255, 0.12377456575632095, 0.14501647651195526, -0.022219644859433174, 0.16259759664535522, -0.09411454945802689, -0.027417514473199844, 0.18137280642986298, -0.061683289706707) * l0(-1.0, 1.0);
	r += mat4(0.16453053057193756, 0.19622334837913513, 0.029471270740032196, -0.01444067619740963, -0.1323249191045761, -0.09411347657442093, -0.09690182656049728, -0.09057606756687164, -0.0625610202550888, -0.06242833659052849, -0.3193356990814209, -0.4326179623603821, -0.39942455291748047, -0.37462106347084045, 0.1949329376220703, 0.31627556681632996) * l0(0.0, 1.0);
	r += mat4(0.07987332344055176, 0.08116666972637177, -0.026735393330454826, -0.05746989697217941, -0.03174610435962677, -0.050899915397167206, 0.13915608823299408, 0.1762867122888565, 0.04078877717256546, -0.00802151020616293, -0.08689416199922562, -0.1469726711511612, -0.10601441562175751, -0.17688913643360138, 0.04424036666750908, 0.12640143930912018) * l0(1.0, 1.0);
	r += vec4(2.7054300133499964e-08, 2.8737066060102734e-08, 5.4676658756136476e-09, 3.727361974625865e-09);
	return tanh(r);
}

//!DESC CuNNy-2x4-shuffle
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

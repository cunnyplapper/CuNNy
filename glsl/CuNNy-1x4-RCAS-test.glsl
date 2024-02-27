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
	r += vec4(0.15058276057243347, 0.011300230398774147, 0.023331621661782265, -0.029061775654554367) * l0(-1.0, -1.0);
	r += vec4(-0.4505574703216553, -0.01264933217316866, 0.0032432747539132833, 0.09526003152132034) * l0(0.0, -1.0);
	r += vec4(0.15714068710803986, 0.011307272128760815, -0.005908325780183077, -0.11353996396064758) * l0(1.0, -1.0);
	r += vec4(0.038795098662376404, 0.009595009498298168, 0.13424040377140045, -0.06492648273706436) * l0(-1.0, 0.0);
	r += vec4(-0.183330237865448, -0.505859375, -0.19157567620277405, 0.5010976195335388) * l0(0.0, 0.0);
	r += vec4(0.11390016973018646, 2.829022196237929e-05, 0.14285211265087128, -0.4814460277557373) * l0(1.0, 0.0);
	r += vec4(0.03647458553314209, -0.01543030422180891, 0.37597644329071045, 0.06269766390323639) * l0(-1.0, 1.0);
	r += vec4(0.12477833032608032, -0.0028152032755315304, -0.43149271607398987, -0.0011789336567744613) * l0(0.0, 1.0);
	r += vec4(-0.046020422130823135, 0.027118248865008354, -0.026421252638101578, -0.07817462086677551) * l0(1.0, 1.0);
	r += vec4(0.034842878580093384, 0.5077887773513794, 0.016064312309026718, 0.017770400270819664);
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
	r += mat4(0.004042015876621008, 0.09391742199659348, 0.018653513863682747, 0.05160916596651077, -0.09478864818811417, -0.03390282765030861, -0.18766601383686066, -0.016299834474921227, -0.06797608733177185, -0.09117169678211212, -0.5368843078613281, 0.08797993510961533, 0.030074652284383774, 0.02910897321999073, -0.1146819218993187, -0.24508769810199738) * l0(-1.0, -1.0);
	r += mat4(-0.04685494676232338, 0.04457380250096321, 0.01968388631939888, -0.008682380430400372, -0.11032925546169281, 0.02314559929072857, 0.556268036365509, 0.4116556942462921, -0.09339725226163864, 0.4877578318119049, 0.552083432674408, -0.09690123796463013, 0.026333697140216827, 0.16203340888023376, 0.31933796405792236, -0.1415078192949295) * l0(0.0, -1.0);
	r += mat4(0.048834994435310364, -0.054568469524383545, 0.051796842366456985, 0.04418380185961723, -0.08125039935112, -0.011177493259310722, -0.1694343388080597, 0.04411868378520012, -0.1897878795862198, -0.4837784171104431, 0.07766249030828476, -0.07110172510147095, -0.14146678149700165, -0.027160583063960075, 0.03883138671517372, -0.015430385246872902) * l0(1.0, -1.0);
	r += mat4(-0.10134565085172653, 0.18055935204029083, -0.436803936958313, -0.2636115252971649, -0.16205722093582153, -0.0822751373052597, 0.253743439912796, 0.20549212396144867, 0.043110933154821396, 0.09117633104324341, -0.0507393516600132, 0.04103867709636688, 0.0005341083742678165, 0.031551629304885864, -0.2429305464029312, 1.3976894617080688) * l0(-1.0, 0.0);
	r += mat4(-0.004149945918470621, -0.22633199393749237, -0.3310389518737793, 0.1981341689825058, -0.21966534852981567, 0.5122136473655701, -0.45790454745292664, -3.8892366886138916, -0.025017397478222847, -0.47811415791511536, 0.31738296151161194, -0.019783496856689453, -0.009060586802661419, -11.494914054870605, -0.18781378865242004, 0.20134080946445465) * l0(0.0, 0.0);
	r += mat4(0.016474680975079536, 0.02308124117553234, -0.11834441870450974, -0.1628374606370926, -0.04154251515865326, -0.35449209809303284, 0.15037336945533752, 0.22244077920913696, -0.060021642595529556, -1.1470390558242798, 0.05053641274571419, -0.07760772854089737, 0.035927314311265945, 0.007599981501698494, -0.16115081310272217, 0.01862427219748497) * l0(1.0, 0.0);
	r += mat4(0.03537975996732712, -0.13134890794754028, 0.006769677624106407, 0.24663302302360535, -0.042024966329336166, 0.1215684786438942, 0.12496879696846008, 0.09222015738487244, 0.02246122807264328, 0.03163566067814827, -0.027320779860019684, -0.02635364606976509, -0.02803766168653965, 0.42052972316741943, -0.14881333708763123, -0.24155525863170624) * l0(-1.0, 1.0);
	r += mat4(0.02176540158689022, -0.5153868794441223, -0.15586136281490326, 0.5007902383804321, -0.0924428328871727, -0.14892731606960297, -0.07121724635362625, 0.415596067905426, -0.07144829630851746, -0.16162091493606567, 0.10717837512493134, 0.013347056694328785, -0.0716654509305954, 1.1999456882476807, -0.051277630031108856, -0.2104492038488388) * l0(0.0, 1.0);
	r += mat4(0.02948232740163803, -0.08588024973869324, 0.10399636626243591, 0.3648591935634613, -0.1449045091867447, -0.0072701312601566315, -0.04276956245303154, -0.07629526406526566, -0.14284542202949524, -0.04095501825213432, 0.10669807344675064, 0.11612429469823837, -0.06066077575087547, -0.033467162400484085, -0.014591513201594353, 0.015632783994078636) * l0(1.0, 1.0);
	r += vec4(-0.06379354000091553, -0.014459898695349693, -0.0890825167298317, 0.07890128344297409);
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
	r += mat4(-0.03692947328090668, 0.0037743987049907446, 0.02420778013765812, 0.013385099358856678, 0.09898267686367035, -0.2276209145784378, -0.07569623738527298, -0.09895677119493484, -0.2865472435951233, 0.12369195371866226, -0.12113715708255768, 0.018296917900443077, 0.05127013847231865, 0.032623376697301865, -0.047219112515449524, 0.021154815331101418) * l0(-1.0, -1.0);
	r += mat4(0.07574141770601273, 0.07352611422538757, 0.01391531340777874, 0.030271925032138824, -0.19926714897155762, 0.7362784743309021, 0.19523653388023376, 0.2920667827129364, 0.13688719272613525, -0.00010765292245196179, -0.07732284069061279, -0.25110912322998047, 0.426828533411026, 0.3721758723258972, -0.14285723865032196, -0.1209593117237091) * l0(0.0, -1.0);
	r += mat4(-0.03957615792751312, -0.012762646190822124, -0.022440021857619286, -0.07654556632041931, 0.4700021743774414, -1.0601519346237183, 0.072020024061203, -0.5605475306510925, -0.10198579728603363, -0.21145837008953094, 0.027992436662316322, -0.04115013778209686, 0.041237395256757736, 0.10856667160987854, 0.012798677198588848, -0.07753362506628036) * l0(1.0, -1.0);
	r += mat4(-0.021109461784362793, -0.06492021679878235, 0.0003162392240483314, -0.04254878684878349, 0.26845642924308777, -0.23208507895469666, 0.25878429412841797, -0.21949230134487152, -0.9055476188659668, 0.4295947253704071, -0.658847451210022, 0.15033428370952606, 0.25940030813217163, -0.056463561952114105, 0.17086729407310486, -0.09327979385852814) * l0(-1.0, 0.0);
	r += mat4(-0.030931446701288223, 0.017139391973614693, -0.11105624586343765, -0.032416023313999176, -0.8613360524177551, 0.10061465203762054, -1.1601611375808716, 0.6810555458068848, 1.2383818626403809, -0.4956621527671814, 0.7484009861946106, 0.1972435712814331, 0.8141433596611023, 0.8270647525787354, 0.8589827418327332, 0.8257443308830261) * l0(0.0, 0.0);
	r += mat4(0.03502314165234566, -0.04474373906850815, 0.006098638754338026, 0.07967869937419891, 0.29809001088142395, 0.21445699036121368, 0.592147946357727, -0.3686007261276245, -0.31502142548561096, 0.416986346244812, -0.2513984739780426, 0.02759547345340252, -0.10957534611225128, 0.2296551764011383, -0.12790311872959137, 0.20164814591407776) * l0(1.0, 0.0);
	r += mat4(-0.08464711159467697, 0.037569791078567505, 0.09225768595933914, 0.06614009290933609, 0.11305174976587296, -0.06306489557027817, 0.17566904425621033, -0.19876079261302948, 0.2353622317314148, 0.1313461810350418, -0.17332737147808075, 0.4681505858898163, -0.05945178121328354, 0.006740344688296318, 0.15145133435726166, 0.06957104802131653) * l0(-1.0, 1.0);
	r += mat4(0.05148640275001526, 0.008824693970382214, 0.005529799964278936, -0.012510662898421288, -0.04001018404960632, 0.18430456519126892, -0.20539358258247375, 0.1114317998290062, -0.08420925587415695, -0.874853253364563, 0.690822422504425, -1.4844566583633423, -0.1484750658273697, -0.12775534391403198, 0.3569878041744232, 0.4478137493133545) * l0(0.0, 1.0);
	r += mat4(0.09086640179157257, 0.03300862014293671, 0.01623467728495598, -0.10526497662067413, -0.20460845530033112, -3.8668346746817406e-07, -0.09225586801767349, 0.24367308616638184, -0.3018720746040344, 0.3603789210319519, -0.342084139585495, 0.5878901481628418, 0.012829585000872612, -0.06964478641748428, 0.048761699348688126, 0.07380609959363937) * l0(1.0, 1.0);
	r += vec4(2.9322611005966337e-10, 1.3332585035996658e-10, 3.098996892436645e-10, 5.418779869259538e-10);
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

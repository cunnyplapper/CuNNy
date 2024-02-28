// CuNNy 1x4 RCAS
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
	r += vec4(0.09204250574111938, -0.009817102923989296, -0.007296757772564888, 0.007884657941758633) * l0(-1.0, -1.0);
	r += vec4(-0.6725878119468689, 0.013276804238557816, 0.05749056860804558, 0.2471916228532791) * l0(0.0, -1.0);
	r += vec4(0.15648265182971954, 0.013028782792389393, -0.03584910184144974, 0.020532691851258278) * l0(1.0, -1.0);
	r += vec4(0.1486607789993286, -0.009240229614078999, 0.059179630130529404, 0.05077002942562103) * l0(-1.0, 0.0);
	r += vec4(0.05945893004536629, -0.018928010016679764, -0.4091796576976776, -0.5527343153953552) * l0(0.0, 0.0);
	r += vec4(-0.009670785628259182, -0.4541015923023224, 0.3494526743888855, -0.006736010313034058) * l0(1.0, 0.0);
	r += vec4(-0.007659091614186764, 0.011540417559444904, -0.028868699446320534, 0.02483266219496727) * l0(-1.0, 1.0);
	r += vec4(0.03284585848450661, 0.32115963101387024, 0.01801704429090023, 0.09887675940990448) * l0(0.0, 1.0);
	r += vec4(0.02927582524716854, 0.1283579021692276, -0.001252256683073938, 0.04504353553056717) * l0(1.0, 1.0);
	r += vec4(0.08614703267812729, 0.006062270142138004, 0.004496831446886063, 0.22210246324539185);
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
	r += mat4(-0.042160969227552414, -0.07480288296937943, 0.02864036336541176, -0.031346291303634644, 0.10875310003757477, 0.5253906846046448, 0.19817231595516205, -0.22700847685337067, 0.06269046664237976, 0.2034926861524582, 0.1588992327451706, -0.3408183455467224, -0.04009539633989334, -0.1372067630290985, -0.10083197057247162, 0.08992022275924683) * l0(-1.0, -1.0);
	r += mat4(-0.0204655472189188, -0.03869153559207916, 0.06564388424158096, -0.006156537216156721, -0.01038466114550829, -0.16455066204071045, -0.31346234679222107, -0.11656106263399124, 0.024308988824486732, -0.012428492307662964, -0.00858252216130495, 0.10220755636692047, -0.023371310904622078, -0.11765923351049423, 0.2270505130290985, -0.10985838621854782) * l0(0.0, -1.0);
	r += mat4(0.006530997809022665, -0.010035287588834763, 0.04650937393307686, 0.021073374897241592, 0.1323240101337433, -0.005661169532686472, -0.11171872913837433, -0.0192660391330719, 0.00935162603855133, -0.025726936757564545, -0.47132158279418945, -0.01582268252968788, 0.00958541315048933, -0.014490446075797081, 0.12315693497657776, 0.002241888316348195) * l0(1.0, -1.0);
	r += mat4(0.08594829589128494, -0.008568483404815197, 0.04183027893304825, -0.05075784772634506, 0.35256481170654297, 0.3894609212875366, 0.4541187882423401, 0.3312227129936218, 0.03397463262081146, -0.061152614653110504, -0.02595040760934353, -0.363424152135849, 0.1420888453722, 0.03787927329540253, 0.03137238323688507, -0.17504362761974335) * l0(-1.0, 0.0);
	r += mat4(0.06970507651567459, -0.10868458449840546, -0.08268691599369049, 0.06616120040416718, 0.39862582087516785, 0.3545234501361847, 0.3664660155773163, 0.11674409359693527, 0.43328624963760376, 0.22571803629398346, 0.833984375, 0.40516719222068787, 0.07829062640666962, 0.2528955638408661, -0.05517468973994255, 0.43671172857284546) * l0(0.0, 0.0);
	r += mat4(0.138409823179245, 0.2607233226299286, 0.16676248610019684, 0.0026784089859575033, 0.02840503118932247, 0.0969705656170845, 0.12842319905757904, 0.03307288512587547, 0.19384825229644775, 0.13433422148227692, -1.580160140991211, 0.01813066191971302, 0.2548828423023224, 0.11052000522613525, -0.08269081264734268, -0.17210696637630463) * l0(1.0, 0.0);
	r += mat4(-0.07012856751680374, -0.16454443335533142, -0.06264670193195343, 0.06905606389045715, -1.1213457584381104, 0.06374724209308624, 0.03990967199206352, 0.07441860437393188, -0.26074227690696716, 0.18865592777729034, 0.21821829676628113, -0.1303098350763321, 0.2878675162792206, 0.03943776711821556, -0.038207292556762695, 0.12841583788394928) * l0(-1.0, 1.0);
	r += mat4(-0.5175788402557373, -0.8120779395103455, -0.6074247360229492, -0.1546935737133026, -0.0324072539806366, -0.09206075221300125, -0.02202521450817585, 0.05245865136384964, 0.28585803508758545, 0.4560181498527527, 0.23824624717235565, 0.24161814153194427, -0.49122899770736694, 0.040366705507040024, 0.11258532851934433, -0.3447161912918091) * l0(0.0, 1.0);
	r += mat4(-0.23284296691417694, -0.14874131977558136, -0.3291010856628418, 0.009092967957258224, -0.07202301919460297, -0.06433606892824173, -0.04829039052128792, 0.015621108934283257, -0.08616079390048981, -0.20166146755218506, -0.17336231470108032, 0.05945597216486931, 0.3544921278953552, 0.41860076785087585, 0.25878697633743286, 0.2190580815076828) * l0(1.0, 1.0);
	r += vec4(-0.1232745349407196, -0.14501991868019104, -0.1011466532945633, -0.01873627118766308);
	return max(r, 0.0);
}

//!DESC CuNNy-1x4-down
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
	r += mat4(0.2536447048187256, -0.2531537711620331, -0.0309582706540823, -0.17431625723838806, -0.24679148197174072, 0.03738579899072647, 0.052896637469530106, -0.036530766636133194, 0.012498609721660614, 0.009524689055979252, -0.15185578167438507, 9.627739927964285e-05, -0.03765812888741493, 0.02806462161242962, -0.03040819615125656, -0.038217462599277496) * l0(-1.0, -1.0);
	r += mat4(0.36933407187461853, 0.9942823052406311, -0.20264163613319397, 0.17616793513298035, -0.26269686222076416, -0.7022884488105774, 0.18851549923419952, 0.06693615764379501, -0.1130378320813179, 0.06339152902364731, 0.06909429281949997, -0.04966636002063751, 0.0824614018201828, -0.1168549656867981, 0.23715707659721375, 0.10180649906396866) * l0(0.0, -1.0);
	r += mat4(0.06476615369319916, -0.004529735539108515, 0.004603628534823656, -0.14363524317741394, -0.13235615193843842, -0.06352991610765457, 0.01625329628586769, 0.13058730959892273, 0.025930147618055344, -0.057751793414354324, -0.019564900547266006, -0.012317772954702377, -0.0672011598944664, -0.015258894301950932, -0.008580613881349564, 0.01694156974554062) * l0(1.0, -1.0);
	r += mat4(-0.17547383904457092, -0.021597780287265778, 0.23386944830417633, -0.143965944647789, -0.22306537628173828, 0.2587894797325134, -0.7170323133468628, 0.11108981817960739, 0.5488273501396179, -0.19040566682815552, 0.7955780029296875, 0.10302838683128357, 0.07837754487991333, 0.20654338598251343, -0.10178422927856445, 0.15624260902404785) * l0(-1.0, 0.0);
	r += mat4(-0.5963196754455566, -0.3342667520046234, 0.1850673109292984, 0.7793199419975281, 1.0247769355773926, 0.1733398139476776, 0.012023361399769783, -1.0117287635803223, -0.6347658038139343, 0.3142257332801819, -0.36816346645355225, 0.6047765612602234, -0.07850857824087143, -0.40139240026474, -0.37597665190696716, -0.6855471730232239) * l0(0.0, 0.0);
	r += mat4(2.125737773894798e-05, -0.20752140879631042, 0.054571669548749924, -0.017207153141498566, 0.007051882334053516, 0.36621198058128357, -0.16003353893756866, 0.007407949771732092, 0.11557837575674057, -0.19150276482105255, 0.17627599835395813, -0.09106393903493881, 0.023137975484132767, 0.15771467983722687, -0.023014092817902565, 0.00831005722284317) * l0(1.0, 0.0);
	r += mat4(0.11712343990802765, -0.05276796594262123, 0.04621649160981178, -0.011977078393101692, -0.18017786741256714, -0.006942435167729855, 0.015413997694849968, 0.1987425684928894, 0.01667061261832714, 0.006488582119345665, -0.0357884019613266, -0.22509774565696716, -0.07248259335756302, -0.018643459305167198, 0.04902195185422897, 0.03527870401740074) * l0(-1.0, 1.0);
	r += mat4(0.0842280462384224, 0.22607482969760895, -0.16852730512619019, -0.057420309633016586, -0.058908890932798386, -0.17529171705245972, 0.5618910193443298, 0.3079991042613983, 0.058874793350696564, 0.11823079735040665, -0.29785239696502686, -0.01228364184498787, 0.04600759595632553, -0.02483982779085636, 0.14794805645942688, 0.022779658436775208) * l0(0.0, 1.0);
	r += mat4(-0.05129068344831467, 0.05406548082828522, 0.006661069579422474, 0.024125974625349045, 0.0453585684299469, -0.03193625435233116, 0.01384561788290739, 0.08707639575004578, 0.014678866602480412, 0.029496828094124794, 0.028445731848478317, -0.08178512752056122, -0.011352404952049255, -0.0030387933366000652, -0.03244192153215408, 0.09447868913412094) * l0(1.0, 1.0);
	r += vec4(-1.508937153005263e-08, -7.442471083862756e-09, -5.358076649031318e-09, -2.857385084098496e-08);
	return tanh(r);
}

//!DESC CuNNy-1x4-shuffle
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

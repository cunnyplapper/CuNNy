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

//!MAGPIE EFFECT
//!VERSION 3
//!OUTPUT_WIDTH INPUT_WIDTH * 2
//!OUTPUT_HEIGHT INPUT_HEIGHT * 2

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
//!FORMAT R16_FLOAT
Texture2D easu;

//!SAMPLER
//!FILTER POINT
SamplerState SP;

//!SAMPLER
//!FILTER LINEAR
SamplerState SL;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R16G16B16A16_FLOAT
Texture2D up_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R16G16B16A16_FLOAT
Texture2D conv1_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R16G16B16A16_FLOAT
Texture2D down;

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

//!PASS 1
//!STYLE PS
//!IN INPUT
//!OUT easu

float GetLuma(float3 rgb) {
	return dot(float3(0.299, 0.587, 0.114), rgb);
}

float APrxLoRcpF1(float a) {
	return asfloat(uint(0x7ef07ebb) - asuint(a));
}

float APrxLoRsqF1(float a) {
	return asfloat(uint(0x5f347d74) - (asuint(a) >> uint(1)));
}

float AMin3F1(float x, float y, float z) {

	return min(x, min(y, z));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z));
}

void tap(inout float aC, inout float aW, float2 off, float2 dir, float2 len,
         float lob, float clp, float c){
	float2 v;
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

void set(inout float2 dir, inout float len, float2 pp, bool biS, bool biT,
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
	dir += float2(dirX, dirY) * w;
	len += dot(float2(w, w), float2(lenX, lenY));
}

float4 Pass1(float2 pos) {
	float2 pt = float2(GetInputPt());
	float2 size = float2(GetInputSize());
	float4 pix = float4(0.0, 0.0, 0.0, 1.0);
	float2 pp = pos * size - float2(0.5, 0.5);
	float2 fp = floor(pp);
	pp -= fp;
	float b = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(0.5, -0.5)) * pt), 0).rgb);
	float c = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(1.5, -0.5)) * pt), 0).rgb);
	float e = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(-0.5, 0.5)) * pt), 0).rgb);
	float f = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 0.5, 0.5)) * pt), 0).rgb);
	float g = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 1.5, 0.5)) * pt), 0).rgb);
	float h = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 2.5, 0.5)) * pt), 0).rgb);
	float i = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(-0.5, 1.5)) * pt), 0).rgb);
	float j = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 0.5, 1.5)) * pt), 0).rgb);
	float k = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 1.5, 1.5)) * pt), 0).rgb);
	float l = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2( 2.5, 1.5)) * pt), 0).rgb);
	float n = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(0.5, 2.5) ) * pt), 0).rgb);
	float o = GetLuma(INPUT.SampleLevel(SP, float2((fp + float2(1.5, 2.5) ) * pt), 0).rgb);
	float4 bczzL = float4(b, c, 0.0, 0.0);
	float4 ijfeL = float4(i, j, f, e);
	float4 klhgL = float4(k, l, h, g);
	float4 zzonL = float4(0.0, 0.0, o, n);
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
	float2 dir = float2(0.0, 0.0);
	float len = 0.0;
	set(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	set(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	set(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	set(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	float2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
	dir *= float2(dirR, dirR);
	len = len * 0.5;
	len *= len;
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	float2 len2 = float2(1.0 + (stretch - 1.0) * len, 1.0 + -0.5 * len);
	float lob = 0.5 + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	float clp = APrxLoRcpF1(lob);
	float aC = 0.0;
	float aW = 0.0;
	tap(aC, aW, float2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL);
	tap(aC, aW, float2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL);
	tap(aC, aW, float2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL);
	tap(aC, aW, float2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL);
	tap(aC, aW, float2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL);
	tap(aC, aW, float2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL);
	tap(aC, aW, float2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL);
	tap(aC, aW, float2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL);
	tap(aC, aW, float2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL);
	tap(aC, aW, float2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL);
	tap(aC, aW, float2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL);
	tap(aC, aW, float2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL);
	pix.r = aC / aW;
	float min1 = min(AMin3F1(fL, gL, jL), kL);
	float max1 = max(AMax3F1(fL, gL, jL), kL);
	pix.r = clamp(pix.r, min1, max1);
	pix.r = clamp(pix.r, 0.0, 1.0);
	return pix;
}

//!PASS 2
//!DESC CuNNy-1x4-NVL-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
float4 f0(float2 pt, float2 pos, float s0_0, float s0_1, float s0_2, float s0_3, float s0_4, float s0_5, float s0_6, float s0_7, float s0_8) {
	float4 r = 0.0;
	r += float4(-0.13916026055812836, -0.23849739134311676, 0.03825230523943901, 0.027492884546518326) * s0_0;
	r += float4(0.5337809324264526, 0.43387851119041443, -0.24657616019248962, -0.03643292933702469) * s0_1;
	r += float4(-0.10536675900220871, -0.1343400925397873, 0.2627984285354614, -0.0009888767963275313) * s0_2;
	r += float4(-0.1094827651977539, -0.006667146924883127, 0.22415252029895782, -0.545428991317749) * s0_3;
	r += float4(-0.16323800384998322, 0.34892961382865906, 0.01654587686061859, 0.3557887077331543) * s0_4;
	r += float4(-0.009408144280314445, 0.0487227588891983, -0.2395077496767044, 0.004287833347916603) * s0_5;
	r += float4(0.0005717469612136483, 0.08324411511421204, -0.08179163187742233, 0.18652604520320892) * s0_6;
	r += float4(0.0029084086418151855, -0.006353327538818121, 0.038240909576416016, 0.018651854246854782) * s0_7;
	r += float4(-0.0059611438773572445, -0.03804326802492142, 0.1580265909433365, -0.007937219925224781) * s0_8;
	r += float4(0.000280301203019917, 0.10431312024593353, 0.1890152245759964, 0.00019242402049712837);
	return max(r, 0.0);
}
void Pass2(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	float s0_0 = l0(-1.0, -1.0);
	float s0_1 = l0(0.0, -1.0);
	float s0_2 = l0(1.0, -1.0);
	float s0_3 = l0(-1.0, 0.0);
	float s0_4 = l0(0.0, 0.0);
	float s0_5 = l0(1.0, 0.0);
	float s0_6 = l0(-1.0, 1.0);
	float s0_7 = l0(0.0, 1.0);
	float s0_8 = l0(1.0, 1.0);
	up_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 3
//!DESC CuNNy-1x4-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT conv1_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
float4 f0(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(-0.25738418102264404, 0.09436063468456268, -0.057794034481048584, -0.10066262632608414, 0.19579005241394043, 0.010863184928894043, 0.18111518025398254, 0.027949417009949684, 0.2572130560874939, 0.22216813266277313, 0.48109009861946106, -0.2812809646129608, 0.20657436549663544, 0.14298930764198303, 0.09465578198432922, -0.11596803367137909));
	r += mul(s0_1, float4x4(-0.2052517682313919, -0.0404677614569664, 0.3134606182575226, -0.06350328773260117, -0.13583235442638397, -0.149631068110466, -0.35057976841926575, 0.189096137881279, -0.06096319854259491, -0.025039000436663628, -0.013027596287429333, 0.06629238277673721, 0.3874184489250183, 0.485996276140213, 0.5609124898910522, -0.31150320172309875));
	r += mul(s0_2, float4x4(-0.3427751362323761, -0.11266136914491653, -0.0021423818543553352, -0.009466796182096004, 0.16077253222465515, 0.008605057373642921, -0.08402936160564423, -0.008704417385160923, 0.02200821042060852, -0.04092080518603325, -0.06523517519235611, 0.05113743990659714, -1.1727346181869507, -0.2752583622932434, 0.27881303429603577, -0.12032198905944824));
	r += mul(s0_3, float4x4(0.13016794621944427, 0.45157620310783386, 0.09698035567998886, -0.18598969280719757, -0.0755334123969078, 0.0054977815598249435, 0.20516733825206757, 0.011686031706631184, 0.455527663230896, 0.33666756749153137, -0.15596221387386322, 0.3977850079536438, 0.28542444109916687, -0.5605449080467224, -0.09286074340343475, 0.034443579614162445));
	r += mul(s0_4, float4x4(0.5008928179740906, 0.8735015988349915, -0.6503919959068298, 0.0426228865981102, -0.14794804155826569, -0.27679938077926636, -0.3076169490814209, -0.33399441838264465, -0.3282153010368347, -0.04175320267677307, -0.08132462203502655, 0.2133934199810028, 0.18159836530685425, 0.029398057609796524, -0.22965966165065765, 0.2456059455871582));
	r += mul(s0_5, float4x4(-0.1009853333234787, -0.07846658676862717, -0.07940342277288437, 0.08156666904687881, -0.08278801292181015, -0.012731197290122509, 0.24368062615394592, -0.1266232579946518, -0.016287213191390038, 0.002227899618446827, -0.005111928563565016, 0.04705141484737396, -0.15833918750286102, -0.11793188005685806, -0.5214812755584717, 0.7400662302970886));
	r += mul(s0_6, float4x4(-0.08033265918493271, -2.7265665531158447, -0.11429519951343536, 0.38061973452568054, -0.07210294902324677, 0.41500231623649597, -0.04076236113905907, 0.3759765625, 0.12745092809200287, -0.1135631799697876, 0.03745880350470543, 0.03807844594120979, 0.09838739037513733, -0.49975383281707764, 0.09390684962272644, -0.12377913296222687));
	r += mul(s0_7, float4x4(0.1357920616865158, 0.27977728843688965, 0.33265259861946106, -0.3695560097694397, -0.07575847953557968, -0.27576884627342224, 0.01443108357489109, -0.20231308043003082, -0.08138000220060349, -0.07707171142101288, 0.13859671354293823, -0.10968076437711716, 0.005448699928820133, 0.025524882599711418, -0.031659651547670364, 0.14197345077991486));
	r += mul(s0_8, float4x4(-0.0773792415857315, 0.002071856055408716, -0.30379679799079895, 0.38365674018859863, 0.08522053807973862, 0.15290473401546478, 0.02617422118782997, -0.10857071727514267, 0.04890517145395279, 0.014149515889585018, -0.04827004671096802, 0.03382018208503723, -0.11147042363882065, 0.01469084620475769, -0.05685330927371979, 0.13036398589611053));
	r += float4(-0.0715332105755806, -0.040236830711364746, -0.0464448556303978, -0.07489264011383057);
	return max(r, 0.0);
}
void Pass3(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	conv1_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 4
//!DESC CuNNy-1x4-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN conv1_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(conv1_0, float2(x, y))
float4 f0(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(-0.008946303278207779, -0.0016398897860199213, 0.0005517356912605464, 0.0008328144904226065, 0.0749475285410881, 0.004492135252803564, 0.007257672026753426, 0.0002592617238406092, -0.003667384386062622, 0.011934041976928711, -0.0013311086222529411, 0.0021205716766417027, 0.006696048192679882, 0.008136478252708912, 0.055416978895664215, 0.03209945186972618));
	r += mul(s0_1, float4x4(-0.05651206150650978, -0.04722021147608757, 0.007909372448921204, 0.00825893972069025, -0.014147651381790638, 0.02486499398946762, -0.006839539390057325, -0.0048794737085700035, -0.022621382027864456, -0.02413332462310791, 0.003947497345507145, -7.313008245546371e-05, -0.15622176229953766, -0.26179781556129456, 0.31547465920448303, 0.2036105841398239));
	r += mul(s0_2, float4x4(-0.055979058146476746, 0.02104281075298786, -0.0370870940387249, 0.0105625931173563, 0.008393153548240662, -0.018938355147838593, -0.019749602302908897, -0.0321149043738842, -1.517483667612396e-07, -0.020033789798617363, -0.0015721203526481986, -0.0007859637262299657, -0.05720827355980873, -0.09698353707790375, 0.007403170224279165, 0.027886612340807915));
	r += mul(s0_3, float4x4(0.021065603941679, 0.000153253335156478, -0.0022228744346648455, -0.010788503102958202, -0.012851601466536522, -0.03503947705030441, 0.005498820915818214, -0.033869531005620956, 0.03771623596549034, -0.015793276950716972, -0.01649433560669422, 0.006605785805732012, -0.03950721025466919, 0.13623064756393433, -0.17646823823451996, 0.11413615942001343));
	r += mul(s0_4, float4x4(0.30031806230545044, -0.002916442696005106, -0.2159593552350998, -0.13180531561374664, -0.4655514359474182, 0.13133946061134338, -0.023134745657444, 0.02739148773252964, 0.46019020676612854, 0.5527342557907104, -0.28227102756500244, -0.1635756641626358, 0.5058593153953552, -0.32129210233688354, -0.20456908643245697, -1.0398106575012207));
	r += mul(s0_5, float4x4(-0.2007652074098587, 0.44827449321746826, -0.22152355313301086, -0.058983638882637024, 0.12548832595348358, -0.8116552829742432, 0.3369174003601074, 0.025107132270932198, 0.09400052577257156, 0.25098299980163574, -0.001311345724388957, -0.03215324133634567, -0.06628506630659103, 0.2607802748680115, -0.051668718457221985, 0.19482439756393433));
	r += mul(s0_6, float4x4(-0.02972668595612049, 0.001400332315824926, -0.000651830283459276, 0.007856861688196659, -0.048705942928791046, 0.003205497981980443, -0.03405924513936043, -0.015406781807541847, 0.022963818162679672, -0.11035169661045074, 0.13629581034183502, -0.1538083404302597, -0.14248593151569366, 0.011857536621391773, -0.1557733714580536, -0.00032890410511754453));
	r += mul(s0_7, float4x4(0.3427729904651642, -0.11186134815216064, 0.8808603882789612, 0.006703567691147327, 0.17557139694690704, 0.05335165932774544, -0.10618583112955093, 0.16455064713954926, -0.896562933921814, -0.207518070936203, -0.12584514915943146, 0.6837041974067688, 0.026230663061141968, -0.007850628346204758, 0.16357389092445374, 0.038797684013843536));
	r += mul(s0_8, float4x4(-0.3096364438533783, 0.018501967191696167, -0.24755875766277313, 0.6238948106765747, 0.18505746126174927, 0.2091689556837082, 0.08081477135419846, -0.3280755877494812, 0.1264657974243164, 0.12459861487150192, 0.061712898313999176, 0.08867894113063812, 0.013117827475070953, -0.035707537084817886, -0.005387060344219208, 0.01566695049405098));
	r += float4(-1.124361492799153e-08, -1.5153847954252342e-08, -1.2269453009139397e-08, -1.4662954406219342e-08);
	return tanh(r);
}
void Pass4(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	float4 s0_0 = l0(-1.0, -1.0);
	float4 s0_1 = l0(0.0, -1.0);
	float4 s0_2 = l0(1.0, -1.0);
	float4 s0_3 = l0(-1.0, 0.0);
	float4 s0_4 = l0(0.0, 0.0);
	float4 s0_5 = l0(1.0, 0.0);
	float4 s0_6 = l0(-1.0, 1.0);
	float4 s0_7 = l0(0.0, 1.0);
	float4 s0_8 = l0(1.0, 1.0);
	down[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 5
//!DESC CuNNy-1x4-NVL-shuffle
//!STYLE PS
//!IN down, INPUT, easu
float4 Pass5(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = down.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += easu.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

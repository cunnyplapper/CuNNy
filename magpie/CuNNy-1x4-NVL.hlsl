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
	r += float4(-0.029752228409051895, 0.042643651366233826, 0.22081871330738068, 0.07127300649881363) * s0_0;
	r += float4(0.2568361163139343, -0.5516409277915955, 0.00021533023391384631, 0.2534238398075104) * s0_1;
	r += float4(0.19420281052589417, 0.3447265625, -4.6921916007995605, 0.05677366256713867) * s0_2;
	r += float4(-0.0057132430374622345, 0.029544595628976822, 0.12655732035636902, -0.19093510508537292) * s0_3;
	r += float4(-0.5106335878372192, 0.1257784217596054, 0.3027925193309784, 0.8186547756195068) * s0_4;
	r += float4(0.10026982426643372, 0.027004163712263107, -1.9319705963134766, 0.16897718608379364) * s0_5;
	r += float4(0.024721719324588776, -0.012781666591763496, -0.08269480615854263, 0.01219751127064228) * s0_6;
	r += float4(-0.028274495154619217, 0.00039652647683396935, -0.10474157333374023, -0.2666013836860657) * s0_7;
	r += float4(-0.005069285165518522, -0.0017262448091059923, -4.629909038543701, 0.0015202866634353995) * s0_8;
	r += float4(-3.0081904696999118e-05, 0.00013951111759524792, -0.006163984537124634, -0.007868793793022633);
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
	r += mul(s0_0, float4x4(-0.3496471345424652, 0.13963395357131958, 0.10270028561353683, -0.025580311194062233, 0.06016622111201286, 0.03010649047791958, -0.11914939433336258, 0.18442420661449432, -0.17383147776126862, -0.11135534197092056, -0.1289360076189041, -1.3796045780181885, 0.039444733411073685, -0.3476390838623047, -0.04508998617529869, 0.008282004855573177));
	r += mul(s0_1, float4x4(-0.4264755845069885, 0.07018591463565826, -0.03759440779685974, 0.05843682959675789, 0.08387292921543121, -0.11653508245944977, -0.05050061270594597, 0.2802727222442627, 0.02257497049868107, -0.07741949707269669, -0.07480766624212265, -0.2839448153972626, 0.2587890625, -0.1283404678106308, -0.271323025226593, 0.5099185705184937));
	r += mul(s0_2, float4x4(-1.8508986234664917, -0.018312545493245125, 0.19543161988258362, 0.046281564980745316, 0.07830869406461716, -0.12505561113357544, -0.18209941685199738, 0.056949637830257416, -0.06946887075901031, -0.2711855471134186, -0.0009939769515767694, -0.09632112085819244, 0.0429968424141407, -0.45238885283470154, -0.48273521661758423, -0.30477097630500793));
	r += mul(s0_3, float4x4(-0.12085410207509995, 0.2270839661359787, 0.027256451547145844, 0.1509111076593399, 0.2244657278060913, -0.14460434019565582, -0.26950791478157043, 0.1697361171245575, -0.110078364610672, -0.17104020714759827, -0.16197755932807922, -0.2061755657196045, -0.0021100828889757395, -0.04020011052489281, -0.1689728945493698, 0.014370789751410484));
	r += mul(s0_4, float4x4(0.2774021625518799, -0.19822420179843903, -0.07145882397890091, 0.181326761841774, 0.7324296236038208, -0.5047662258148193, -0.2914142906665802, 0.4020986557006836, -0.4288606345653534, -0.15412607789039612, -0.16827577352523804, -0.4883088767528534, 0.016318075358867645, -0.22716191411018372, -0.4410775899887085, -0.04724130034446716));
	r += mul(s0_5, float4x4(-0.024415694177150726, -0.07395514845848083, 0.06170186027884483, 0.09582578390836716, -4.940704822540283, -0.3552732467651367, -0.4516715705394745, 0.1928711086511612, -0.04528927057981491, 0.10247843712568283, 0.07309047877788544, -0.1422143131494522, -0.2878013849258423, -0.40141403675079346, -0.22274115681648254, -0.18767797946929932));
	r += mul(s0_6, float4x4(0.14604106545448303, -0.08533386886119843, -0.0713379830121994, -0.11097513884305954, 0.3643944561481476, -0.4025353193283081, -0.3025085926055908, 0.19638346135616302, -0.8376937508583069, 0.058886054903268814, 0.022606847807765007, 0.018514012917876244, -0.014719830825924873, -0.03783026337623596, -0.19951428472995758, 0.025515465065836906));
	r += mul(s0_7, float4x4(0.04130850359797478, -0.07323383539915085, -0.009248302318155766, -0.048409949988126755, 0.8101176023483276, -0.2640593349933624, -0.17027242481708527, 0.4448300898075104, -0.06514165550470352, -0.05545995011925697, -0.007858874276280403, -0.06147565320134163, 0.005994895007461309, -0.17228826880455017, -0.13606031239032745, 0.0136623065918684));
	r += mul(s0_8, float4x4(-0.00620932737365365, 0.0016188090667128563, 0.09126638621091843, -0.065150186419487, 0.21129964292049408, -0.10397759079933167, -0.38383516669273376, 0.10130969434976578, -0.08601127564907074, -0.012260965071618557, 0.03890478238463402, -0.02703595720231533, -0.06993211805820465, -0.3829036056995392, -0.39521753787994385, -0.053070828318595886));
	r += float4(-0.009480203501880169, -0.019382217898964882, -0.02310756780207157, -0.0024065347388386726);
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
	r += mul(s0_0, float4x4(-0.03201840817928314, 0.018893936648964882, 0.046187616884708405, 0.03500870242714882, -0.03006638027727604, 0.06050813943147659, 0.3114748001098633, 0.15846064686775208, -0.218388631939888, -0.07269993424415588, 0.07349716126918793, 0.07529252022504807, 0.0689353346824646, 0.004992843605577946, -0.013512789271771908, -0.01344046276062727));
	r += mul(s0_1, float4x4(0.06275317072868347, -0.02201559580862522, 0.03464854881167412, 0.03945394232869148, 0.12509280443191528, -0.0937541127204895, 0.1981693059206009, -0.0038405475206673145, -0.08442884683609009, -0.15962360799312592, -0.0016730048228055239, 0.18097203969955444, 0.11256986111402512, 0.08855542540550232, 0.011597334407269955, 0.00897578988224268));
	r += mul(s0_2, float4x4(0.02595955692231655, 0.014911127276718616, -0.01014696154743433, -0.012478731572628021, 0.04584695026278496, 0.09247779101133347, -0.10542170703411102, -0.008706827647984028, -0.07143854349851608, 0.24855323135852814, 0.04077376052737236, 0.1890178918838501, 0.0008431358728557825, 0.10229381918907166, -0.016661513596773148, -0.009421483613550663));
	r += mul(s0_3, float4x4(0.43846872448921204, -0.04896247014403343, -0.12602895498275757, -0.12548868358135223, -0.11926575005054474, 0.12423213571310043, 0.020940586924552917, 0.0462317019701004, 0.11901786923408508, -0.08296933025121689, -0.115086130797863, 0.23147517442703247, -0.13134467601776123, -0.01691347360610962, 0.0886230543255806, 0.05920301005244255));
	r += mul(s0_4, float4x4(-0.14001332223415375, 0.3018355965614319, -0.17500653862953186, -0.2559378445148468, -0.17562589049339294, -0.15183982253074646, -0.015409709885716438, -0.0953480526804924, -0.0500149205327034, -0.10541202127933502, 0.19853997230529785, -0.06046471372246742, -0.3834202289581299, -0.29394519329071045, -0.09008873999118805, -0.10323874652385712));
	r += mul(s0_5, float4x4(0.006168338004499674, -0.07153034955263138, 0.01224421989172697, -0.013438316062092781, -0.11149942874908447, 0.05038473755121231, -0.23732243478298187, 0.04456392303109169, 0.012844320386648178, 0.037393808364868164, -0.23184524476528168, -0.09129119664430618, -0.021725470200181007, -0.19462433457374573, 0.046798888593912125, 0.0993654727935791));
	r += mul(s0_6, float4x4(0.08739723265171051, -0.10873760282993317, 0.5712970495223999, -0.02194860205054283, 0.0040840511210262775, -0.18848693370819092, 0.10749392956495285, -0.1068158894777298, -0.14066354930400848, 0.17978596687316895, 0.047290973365306854, 0.1528244912624359, -0.1194843202829361, -0.10133568197488785, -0.25079551339149475, -0.16162192821502686));
	r += mul(s0_7, float4x4(-0.30566367506980896, -0.19665804505348206, -0.15967656672000885, 0.32519465684890747, -0.08641726523637772, 0.1156340166926384, 0.12444078177213669, -0.11663669347763062, -0.0922391414642334, -0.029721712693572044, 0.06704995036125183, -0.05316204950213432, 0.3839074671268463, 0.4794924557209015, 0.15087877213954926, 0.32910168170928955));
	r += mul(s0_8, float4x4(0.01016285177320242, -0.03136216849088669, 0.025685017928481102, -0.05231276527047157, 0.04055535048246384, 0.16511009633541107, -0.03469465672969818, 0.17006903886795044, 0.12824566662311554, 0.008442997932434082, 0.08589779585599899, -0.000325034954585135, 0.017528941854834557, 0.033207133412361145, -0.03623935952782631, -0.15249641239643097));
	r += float4(-1.4486123411927565e-08, -1.4896702538180762e-08, -1.3695706790883833e-08, -1.4379740065351143e-08);
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
//!IN down, easu, INPUT
float4 Pass5(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float2x3 rgb2uv = {-0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	int2 i = int2(f * 2.0);
	r.r = down.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += easu.SampleLevel(SP, pos, 0).r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float2 uv = mul(rgb2uv, INPUT.SampleLevel(SL, pos, 0).rgb);
	float3 px = mul(yuv2rgb, float3(r.r, uv));
	return float4(px, 1.0);
}

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
//!DESC CuNNy-0x4-NVL-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
float4 f0(float2 pt, float2 pos, float s0_0, float s0_1, float s0_2, float s0_3, float s0_4, float s0_5, float s0_6, float s0_7, float s0_8) {
	float4 r = 0.0;
	r += float4(-0.006198681890964508, -0.05231315270066261, -0.025221413001418114, 0.5404523015022278) * s0_0;
	r += float4(-0.07716923952102661, 0.21020303666591644, 0.03323926404118538, -0.33689653873443604) * s0_1;
	r += float4(0.525390625, -0.01079510897397995, 0.030590998008847237, 0.01617068238556385) * s0_2;
	r += float4(0.01528616901487112, 0.24027569591999054, 0.05138692259788513, -0.3603471517562866) * s0_3;
	r += float4(-0.10230162739753723, -0.5535659790039062, -0.040179893374443054, -0.04588337987661362) * s0_4;
	r += float4(-0.08648762106895447, 0.0955221876502037, -0.3135211765766144, 0.0345270112156868) * s0_5;
	r += float4(-0.010947072878479958, 0.03388180583715439, 0.007299046963453293, 0.011357237584888935) * s0_6;
	r += float4(0.014406616799533367, 0.06554145365953445, -0.21588078141212463, 0.03210633248090744) * s0_7;
	r += float4(-0.004528616089373827, -0.02740689180791378, 0.4619140923023224, 0.0042297146283090115) * s0_8;
	r += float4(-0.26725050806999207, -0.0048223501071333885, -0.007218413054943085, -0.007989190518856049);
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
//!DESC CuNNy-0x4-NVL-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
float4 f0(float2 pt, float2 pos, float4 s0_0, float4 s0_1, float4 s0_2, float4 s0_3, float4 s0_4, float4 s0_5, float4 s0_6, float4 s0_7, float4 s0_8) {
	float4 r = 0.0;
	r += mul(s0_0, float4x4(-0.03651314601302147, -0.09008797258138657, 0.10478276014328003, 0.09388914704322815, 0.003909591119736433, 0.00512347649782896, -0.011159833520650864, 0.057005953043699265, 0.4128411114215851, 0.47949299216270447, 0.28064003586769104, 0.19144093990325928, -0.007016010582447052, -8.631743497744537e-08, 3.223498197257868e-07, 0.0064472327940166));
	r += mul(s0_1, float4x4(-0.03102370910346508, 0.006508303806185722, -0.07646448165178299, -0.036956872791051865, 0.08370202779769897, -0.07903745025396347, 0.02690637670457363, -0.032232560217380524, -0.07303495705127716, -0.2758699655532837, -0.04968535900115967, -0.057026997208595276, 0.011345628648996353, -0.03453972935676575, -0.017991144210100174, -0.04722951725125313));
	r += mul(s0_2, float4x4(-9.497873543296009e-05, -0.10977692157030106, 0.009429615922272205, -0.009613240137696266, -4.0683440261091164e-07, 0.2533860206604004, -0.010805288329720497, 0.017466355115175247, 7.541160016444337e-07, 0.032318588346242905, 1.522286794397587e-07, -3.801353329890844e-07, -0.012450573034584522, 0.04035258665680885, -0.017093375325202942, -0.020335063338279724));
	r += mul(s0_3, float4x4(0.36730650067329407, 0.511563777923584, -0.5028628706932068, -0.35397371649742126, 0.05474788323044777, 0.004125842358916998, -0.0009186062379740179, -0.0017708304803818464, -0.1764625757932663, -0.1204511746764183, -0.27460744976997375, -0.03408453240990639, 0.0048112948425114155, -0.052116669714450836, -0.013159972615540028, -0.05514978617429733));
	r += mul(s0_4, float4x4(-0.055579133331775665, -0.2599703371524811, 0.23288226127624512, -0.06155417487025261, -0.5275958776473999, -0.3467997610569, -0.32614123821258545, -0.5888392925262451, 0.08324722200632095, 0.04186828434467316, 0.0508933961391449, -0.27245837450027466, -0.3678518831729889, 0.09931151568889618, 0.05724451318383217, 0.14576959609985352));
	r += mul(s0_5, float4x4(0.00013707487960346043, 0.03617449477314949, -0.028421083465218544, -0.05347476527094841, 0.04442855343222618, 0.0652160495519638, 0.05358745902776718, 0.35839924216270447, -0.015584498643875122, -0.01275507640093565, -0.01066204346716404, 0.040132053196430206, 0.1368238627910614, -0.4623268246650696, 0.15850375592708588, 0.12108513712882996));
	r += mul(s0_6, float4x4(0.34867340326309204, -0.3270348906517029, 1.2632712125778198, 0.48950135707855225, -0.03650841489434242, -0.00016143232642207295, 0.0520440898835659, -0.0123445400968194, -2.5232695406884886e-05, 0.008997606113553047, 0.00801099557429552, -0.010375458747148514, 0.0005506941815838218, 0.005576358176767826, 0.0221962071955204, -0.03164855018258095));
	r += mul(s0_7, float4x4(-0.4534633755683899, 0.39991486072540283, -0.5575308799743652, 0.31941157579421997, 0.1246396154165268, 0.056408535689115524, 0.02786223776638508, 0.24381466209888458, -0.015939986333251, -0.008265125565230846, -0.014917469583451748, 0.03610799461603165, 0.1891893744468689, 0.1646750420331955, -0.31241080164909363, 0.14381523430347443));
	r += mul(s0_8, float4x4(0.11795194447040558, -0.0930541530251503, 0.1148894801735878, -0.06787025183439255, 0.02142314985394478, 4.3255417381260486e-07, 0.010453768074512482, 0.001251149456948042, 5.261408659862354e-07, -0.0018913489766418934, -0.000953360868152231, -0.036873895674943924, 0.08778369426727295, 0.2743948996067047, 0.25544044375419617, -0.19203492999076843));
	r += float4(-1.482609857106354e-08, -1.4803463344037482e-08, -1.4248187518717259e-08, -1.4822846061690598e-08);
	return tanh(r);
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
	down[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 4
//!DESC CuNNy-0x4-NVL-shuffle
//!STYLE PS
//!IN down, easu, INPUT
float4 Pass4(float2 pos) {
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

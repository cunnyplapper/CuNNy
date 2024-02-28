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
//!VERSION 4

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
//!WIDTH INPUT_WIDTH * 2
//!HEIGHT INPUT_HEIGHT * 2
Texture2D OUTPUT;

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
//!FORMAT R8G8B8A8_UNORM
Texture2D up_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
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

//!DESC CuNNy-0x4-NVL-up
//!PASS 2
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	min16float s0_0 = l0(-1.0, -1.0);
	min16float s0_1 = l0(0.0, -1.0);
	min16float s0_2 = l0(1.0, -1.0);
	min16float s0_3 = l0(-1.0, 0.0);
	min16float s0_4 = l0(0.0, 0.0);
	min16float s0_5 = l0(1.0, 0.0);
	min16float s0_6 = l0(-1.0, 1.0);
	min16float s0_7 = l0(0.0, 1.0);
	min16float s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += min16float4(0.1637423187494278, 0.5213013887405396, 0.05504212900996208, 0.11335067451000214) * s0_0;
	r0 += min16float4(-0.019076718017458916, -0.31657838821411133, -0.027998844161629677, -0.08789962530136108) * s0_1;
	r0 += min16float4(0.00856601633131504, 0.05940142646431923, 0.08393961936235428, -0.02643093653023243) * s0_2;
	r0 += min16float4(-0.5842370986938477, -0.19448363780975342, 0.010816436260938644, -0.4306640923023224) * s0_3;
	r0 += min16float4(0.2587888240814209, -0.13330088555812836, -0.3927399814128876, 0.004032681230455637) * s0_4;
	r0 += min16float4(-0.029116515070199966, 0.03841260448098183, -0.010478129610419273, 0.06956366449594498) * s0_5;
	r0 += min16float4(0.2192506492137909, 0.0015908509958535433, 0.11673224717378616, 0.3041526675224304) * s0_6;
	r0 += min16float4(-0.03505421429872513, 0.0830293744802475, 0.31933584809303284, 0.22637996077537537) * s0_7;
	r0 += min16float4(0.016086190938949585, -0.03644900396466255, -0.08903514593839645, -0.048700060695409775) * s0_8;
	r0 += float4(-0.003148151794448495, -0.031893592327833176, -0.08227546513080597, -0.13621656596660614);
	up_0[gxy] = max(r0, 0.0);
}
void Pass2(uint2 blockStart, uint3 tid) {
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	};
	float2 pos = (gxy + 0.5) * GetInputPt();
	float2 step = 8 * GetInputPt();
	hook(gxy, pos);
}

//!DESC CuNNy-0x4-NVL-down
//!PASS 3
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
void hook(uint2 gxy, float2 pos) {
	float2 pt = float2(GetInputPt());
	min16float4 s0_0 = l0(-1.0, -1.0);
	min16float4 s0_1 = l0(0.0, -1.0);
	min16float4 s0_2 = l0(1.0, -1.0);
	min16float4 s0_3 = l0(-1.0, 0.0);
	min16float4 s0_4 = l0(0.0, 0.0);
	min16float4 s0_5 = l0(1.0, 0.0);
	min16float4 s0_6 = l0(-1.0, 1.0);
	min16float4 s0_7 = l0(0.0, 1.0);
	min16float4 s0_8 = l0(1.0, 1.0);
	float4 r0 = 0.0;
	r0 += mul(s0_0, min16float4x4(0.0001285873440792784, -2.6157439947382954e-07, 0.0025203032419085503, -1.1139277376059908e-05, -0.022587664425373077, -5.479132596519776e-07, -0.0041604554280638695, 8.583784619986545e-06, -0.5853216052055359, 0.043842192739248276, 0.12010272592306137, 0.2436521202325821, -0.011166317388415337, 1.0918913773139138e-07, -0.007131616584956646, 9.809437869989779e-06));
	r0 += mul(s0_1, min16float4x4(-0.1352539211511612, 1.1766876014007721e-05, -0.09594207257032394, -0.013332261703908443, 0.03357122838497162, 0.005716306623071432, -0.007531582843512297, -0.024840712547302246, 0.5395588278770447, -0.2529304027557373, 0.03160055726766586, -0.030678214505314827, 0.5097745060920715, -0.06561741977930069, 0.07348635792732239, -0.05457375571131706));
	r0 += mul(s0_2, min16float4x4(0.17616094648838043, -0.0013162411050871015, 0.10912729054689407, 0.0881245955824852, 0.012791250832378864, -0.003783145686611533, 0.0014842081582173705, -0.026636634021997452, -0.07060601562261581, 0.14308717846870422, 0.013892008922994137, 0.05560488998889923, -0.05087193474173546, 0.5137479901313782, -0.13611510396003723, -0.089217908680439));
	r0 += mul(s0_3, min16float4x4(0.003399777226150036, -3.835658617390436e-07, 0.010780034586787224, 7.358183938777074e-05, 0.06338150799274445, -0.00567288976162672, 0.0038118064403533936, -0.0010675363009795547, 0.3877045512199402, 0.28417983651161194, -0.5644533634185791, 0.03609905764460564, -0.06552425026893616, -0.019856806844472885, 0.0026437784545123577, -0.014896166510879993));
	r0 += mul(s0_4, min16float4x4(0.1702640801668167, -1.2488249012676533e-05, 0.10766591876745224, 0.01780085079371929, -0.3526463210582733, 0.0335453636944294, -0.01951424963772297, 0.1710371971130371, 0.1508931666612625, 0.010503668338060379, 0.21070222556591034, -0.6695528626441956, -0.38451504707336426, -0.004055798053741455, 0.3818359076976776, 0.1763509064912796));
	r0 += mul(s0_5, min16float4x4(-0.5058574080467224, -0.35662391781806946, -0.3487597107887268, -0.3428438603878021, 0.0981895700097084, -0.13915862143039703, -0.021482646465301514, -0.13428185880184174, -0.18604177236557007, 0.28236570954322815, -0.13047799468040466, -0.02075911872088909, 0.30054613947868347, -0.3500143587589264, -0.15704087913036346, 0.26270562410354614));
	r0 += mul(s0_6, min16float4x4(-0.00353241222910583, 5.490491048476542e-07, -0.013336041942238808, -6.222305091796443e-05, 0.041559163480997086, 0.008528364822268486, 0.10434587299823761, 0.002713883761316538, -0.060208264738321304, -0.11376359313726425, 0.25683721899986267, 0.009276047348976135, 0.02770351432263851, 0.005778220947831869, -0.13590247929096222, -0.019201459363102913));
	r0 += mul(s0_7, min16float4x4(-0.0343017540872097, 8.988504305307288e-07, -0.011676150374114513, -0.0045013404451310635, 0.01740078441798687, -0.15946725010871887, -0.21537502110004425, -0.20884037017822266, -0.21297459304332733, -0.17943251132965088, 0.04080895707011223, 0.12963458895683289, 0.17036838829517365, 0.24416518211364746, -0.1327834576368332, -0.06512057036161423));
	r0 += mul(s0_8, min16float4x4(0.1391112506389618, 0.0837363749742508, 0.097932830452919, 0.037344299256801605, -1.0035006425823667e-06, 0.376382976770401, 0.3009093701839447, 0.5058688521385193, 0.060155969113111496, -0.0336201936006546, -0.18505840003490448, 0.1439482867717743, -0.08177796006202698, -0.04581863805651665, 0.13149958848953247, -0.15929056704044342));
	r0 += float4(-1.4248526802873585e-08, -7.740071694684048e-09, -1.3643642660099431e-08, -7.648057298581534e-09);
	down[gxy] = tanh(r0);
}
void Pass3(uint2 blockStart, uint3 tid) {
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	};
	float2 pos = (gxy + 0.5) * GetInputPt();
	float2 step = 8 * GetInputPt();
	hook(gxy, pos);
}

//!DESC CuNNy-0x4-NVL-shuffle
//!PASS 4
//!STYLE PS
//!IN down, easu, INPUT
//!OUT OUTPUT
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

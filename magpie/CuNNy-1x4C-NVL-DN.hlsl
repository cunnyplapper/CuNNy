// CuNNy 1x4C BILINEAR CHROMA DS NVL
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


//!SAMPLER
//!FILTER POINT
SamplerState SP;

//!SAMPLER
//!FILTER LINEAR
SamplerState SL;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D in_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D conv1_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D out_0;

//!PASS 1
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-DS-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT in_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) (dot(float3(0.5058538317680359, 0.963489294052124, 0.22261954843997955), O(INPUT, float2(x, y)).rgb) + -1.541204810142517)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	min16float4 r = 0.0;
	r += min16float4(-0.0105991326, -0.0730266720, -0.0258489717, -0.0592013337) * s0_0;
	r += min16float4(0.0251948275, -0.0915527344, -0.2313482612, 0.0973198786) * s0_1;
	r += min16float4(-0.0191957559, 0.1736155599, 0.0744626224, -0.0327240489) * s0_2;
	r += min16float4(0.0150632067, 0.4130854309, -0.1731500775, 0.5722677708) * s0_3;
	r += min16float4(-0.0092177233, -0.5816155672, 0.7205718160, -0.5410156846) * s0_4;
	r += min16float4(-0.4360009730, -0.0901246518, -0.2336566746, -0.0360137932) * s0_5;
	r += min16float4(-0.0070935944, 0.0627481788, 0.0598268025, -0.0080838064) * s0_6;
	r += min16float4(-0.0097165881, 0.2628348470, -0.1518554538, -0.0494077206) * s0_7;
	r += min16float4(0.4521484375, -0.0764168426, -0.0376800522, 0.0574618913) * s0_8;
	r += min16float4(-0.0008617450366728008, -0.0004983404069207609, -0.002143917605280876, -0.0006519986200146377);
	return r;
}
void Pass1(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	min16float s0_0 = l0(-1.0, -1.0);
	min16float s0_1 = l0(0.0, -1.0);
	min16float s0_2 = l0(1.0, -1.0);
	min16float s0_3 = l0(-1.0, 0.0);
	min16float s0_4 = l0(0.0, 0.0);
	min16float s0_5 = l0(1.0, 0.0);
	min16float s0_6 = l0(-1.0, 1.0);
	min16float s0_7 = l0(0.0, 1.0);
	min16float s0_8 = l0(1.0, 1.0);
	in_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 2
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-DS-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN in_0
//!OUT conv1_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(in_0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(0.1450259089, 0.4322708845, 0.1673682928, -0.1972510517, 0.1557616740, 0.1222178787, 0.0292370226, 0.0168411229, 0.0925931558, 0.1036500335, 0.0475765727, -0.0093743866, -0.1185680106, -0.1148693711, -0.0002729314, -0.0440395810));
	r += mul(s0_1, min16float4x4(0.0473550744, 0.3037122488, -0.0801509321, 0.2348706275, 0.2476767302, 0.2031315863, -0.0165289640, 0.0084396377, -0.2841950357, -0.3525401354, -0.0232823398, -0.0041597118, -0.2100006491, -0.2340872735, -0.0554484837, -0.1112141833));
	r += mul(s0_2, min16float4x4(-0.0557840094, -0.0383012109, -0.0103033455, -0.0705588683, 0.0652014092, -0.0504127555, 0.0121492036, 0.0071875299, 0.1587605029, 0.2143674940, -0.0100777345, 0.0252166372, -0.0287796352, 0.2130044699, -0.0669348910, 0.0238739308));
	r += mul(s0_3, min16float4x4(0.0977683887, -0.6506862640, 0.1715642214, -0.9160163999, -0.0401275568, -0.1732942164, 0.0385675095, -0.0079077976, -0.1450157166, -0.3329910934, -0.1352460235, -0.3374107778, 0.0060030399, 0.0108732879, -0.0540714860, -0.1070963964));
	r += mul(s0_4, min16float4x4(-0.1965039819, 0.1064951867, -0.0345300846, 0.3336674869, 0.6131454706, -0.0691969544, -0.1052709818, 0.1433318257, 0.5332096815, 0.4813530743, -0.5112469792, 0.3502680659, -0.3904922009, -0.1959070861, 0.2270272225, -0.5054302216));
	r += mul(s0_5, min16float4x4(0.0114214262, -0.1063790917, -0.0651923195, -0.1391678154, 0.1188317463, 0.0544238314, -2.6888587475, -0.0847714469, -0.3037182689, 0.0604530126, 0.0899196640, -0.0024977145, 0.2970764339, -0.1144978926, 0.1977559775, 0.7022974491));
	r += mul(s0_6, min16float4x4(0.0337847583, 0.0406166799, -0.0018097431, 0.0026019244, 0.0475151166, -0.0221662577, 0.0216635689, 0.0263424180, -0.1567554772, -0.0545958132, 0.0364355966, -0.1374388635, -0.0501443036, 0.0716376901, -0.0203283653, -0.0122260917));
	r += mul(s0_7, min16float4x4(-0.1313562691, -0.1430600137, -0.0614008754, -0.1880384088, -0.0733919144, -0.0294872038, 0.0000349389, -0.1401431113, -0.3564438522, 0.0384861603, -0.0903003141, -0.2379058897, 0.1125644073, 0.0115462216, -0.0280830804, -0.0393132418));
	r += mul(s0_8, min16float4x4(-0.0054933112, 0.0005858384, -0.0024857887, 0.0140924305, 0.1252430230, 0.0411597043, 0.0530009009, 0.1728029102, 0.0909314379, -0.2260324657, -0.0676655918, -0.0474780574, -0.0327291004, -0.1859761626, -0.0641981512, -0.1332962811));
	r += mul(s1_0, min16float4x4(-0.0774600729, -0.1056246087, 0.0379474126, -0.3818407655, 0.0793137997, 0.0035268622, 0.0476818234, -0.0807499439, 0.0355217457, -0.0012156523, -0.0357670039, 0.0022105365, -0.0483671091, 0.0117179910, -0.0486941785, 0.0853756294));
	r += mul(s1_1, min16float4x4(-0.3874969184, -0.2104463428, -0.0101709748, -0.0938483775, -0.0186404977, -0.1644256860, -0.0073342826, 0.0814381912, 0.0615592077, 0.1782245636, -0.1143968552, -0.0362541601, 0.3901741207, 0.6202397346, 0.1003877372, 0.0577981099));
	r += mul(s1_2, min16float4x4(0.0440155007, 0.0430929735, 0.0185670909, 0.0196206775, 0.1883029044, 0.1189997569, 0.0352398865, 0.0873472095, -0.1102787852, -0.1674810052, -0.0337972641, 0.0418400057, -0.2182697952, -0.0880155861, 0.0048925113, 0.0722188130));
	r += mul(s1_3, min16float4x4(-0.2641727924, -0.3325996995, -0.0254382771, -0.1396422684, 0.2016601712, 0.1452141851, -0.0316716544, -0.0081235114, 0.1111685336, 0.4078688025, 0.0864514783, 0.4166055322, -0.1151114330, -0.0357975364, 0.0503505617, 0.0841875300));
	r += mul(s1_4, min16float4x4(0.7034037113, -0.1655484438, -0.0007442586, 0.2745842338, 0.5202981830, 0.2686371207, 0.1502669454, 0.0437458456, -0.2271579206, -0.2654366493, -0.1221194044, -0.2646448314, -0.0232449714, -0.3544692695, -0.0529489033, -0.5019533038));
	r += mul(s1_5, min16float4x4(0.0057419087, 0.1313999444, 0.0667003989, 0.1202976257, -0.0731648579, -0.1355898231, 0.0501084551, 0.0906080306, 0.0507468544, -0.1001766101, -0.2009340823, -0.1967774779, -0.2172847539, -0.3759495318, -0.0835028961, -0.6682830453));
	r += mul(s1_6, min16float4x4(-0.1548690945, -0.0136573790, -0.0554379225, -0.0479801446, -0.0292207580, -0.0026400818, -0.0063267089, -0.0364204682, 0.0905345902, -0.0367785655, -0.0504189357, 0.0440768488, 0.0499257967, -0.0328357369, -0.0209162850, 0.0176164191));
	r += mul(s1_7, min16float4x4(0.0591818169, 0.1345661879, 0.0150157865, 0.1180882454, 0.3897037804, -0.0501704812, 0.0416651294, 0.1439806372, 0.1879330724, 0.0605950654, 0.0348522067, 0.2744169533, -0.2373656482, 0.0262950063, -0.0247878786, 0.0002384119));
	r += mul(s1_8, min16float4x4(-0.0214962214, -0.0101829292, -0.0061246515, -0.0224584918, 0.1071802154, -0.0989874899, 0.0287418123, -0.0349213369, 0.0637990758, 0.2820732594, 0.0911542848, 0.1772463024, 0.0546274744, 0.0783257559, 0.0699923113, 0.1149700209));
	r += min16float4(-0.0004361420578788966, -0.00025631047901697457, -0.002184867626056075, -0.0008077476522885263);
	return r;
}
void Pass2(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	min16float4 s0_0 = l0(-1.0, -1.0);
	min16float4 s0_1 = l0(0.0, -1.0);
	min16float4 s0_2 = l0(1.0, -1.0);
	min16float4 s0_3 = l0(-1.0, 0.0);
	min16float4 s0_4 = l0(0.0, 0.0);
	min16float4 s0_5 = l0(1.0, 0.0);
	min16float4 s0_6 = l0(-1.0, 1.0);
	min16float4 s0_7 = l0(0.0, 1.0);
	min16float4 s0_8 = l0(1.0, 1.0);
	min16float4 s1_0 = max(-s0_0, 0.0);
	min16float4 s1_1 = max(-s0_1, 0.0);
	min16float4 s1_2 = max(-s0_2, 0.0);
	min16float4 s1_3 = max(-s0_3, 0.0);
	min16float4 s1_4 = max(-s0_4, 0.0);
	min16float4 s1_5 = max(-s0_5, 0.0);
	min16float4 s1_6 = max(-s0_6, 0.0);
	min16float4 s1_7 = max(-s0_7, 0.0);
	min16float4 s1_8 = max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	conv1_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 3
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-DS-NVL-out
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN conv1_0
//!OUT out_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(conv1_0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(-0.0391845442, 0.0103252847, -0.0720923319, -0.0462250933, 0.0426033065, -0.0085286004, 0.0681146458, 0.0346285887, -0.1836654544, -0.2724511623, 0.2401746809, 0.0717999116, 0.0191503465, -0.1391578764, -0.0082512535, -0.0273465123));
	r += mul(s0_1, min16float4x4(0.0496635512, 0.0327444412, -0.0361112654, -0.1071832329, -0.0651936531, -0.0172295831, 0.0006025624, 0.0715203136, -0.8339843154, -0.5443655252, 0.2444767952, 0.2965001762, -0.0100098317, 0.0556495674, 0.0443435572, 0.0152069554));
	r += mul(s0_2, min16float4x4(-0.0095366277, -0.0280876569, -0.0151401013, -0.0094271861, 0.0071688727, 0.0058704671, -0.0054595177, -0.0239837859, 0.0515489988, 0.0650272444, -0.0758519843, -0.0281592496, -0.0265341531, 0.0321081765, -0.0066117751, 0.0152893001));
	r += mul(s0_3, min16float4x4(-0.1034096703, 0.0663891956, -0.0134346681, 0.0935197249, 0.1184095666, -0.0983886123, 0.0516559593, -0.0590315014, 0.5181901455, 0.1164946184, 0.3310548961, -0.2475222498, 0.2761375904, -0.0510140806, 0.3419660032, -0.1769888103));
	r += mul(s0_4, min16float4x4(0.2120281458, -0.2183586508, 0.4291336834, 0.2243743539, 0.1948907524, 0.4774766564, -0.1989689320, -0.0695420429, 0.4107091725, 2.0296306610, -2.1796915531, 0.3442386985, -0.2068963945, 0.3994178772, -0.4105707109, 0.1390436441));
	r += mul(s0_5, min16float4x4(-0.1284177899, 0.0055896491, -0.0188326389, 0.0658924282, 0.0093284519, 0.0678571388, 0.0789579526, 0.0600489676, 0.2846751213, -0.4070526659, 0.3051038384, -0.6707786322, 0.0580374822, -0.0470537022, -0.0744221583, -0.1282673776));
	r += mul(s0_6, min16float4x4(-0.0007182869, -0.0058729490, 0.0149091724, 0.0056658578, 0.0582280979, -0.0017946629, -0.0379171371, -0.0588378720, 0.0295448713, -0.0252398234, -0.0512750670, 0.0263376795, -0.0123533569, 0.0260514040, 0.0104539795, 0.0871612430));
	r += mul(s0_7, min16float4x4(0.0715469643, 0.0100352755, -0.0581330396, -0.1528244764, -0.1567393243, -0.1198710352, 0.1352478117, 0.1009812132, -0.3037828803, 0.1186933145, 0.2037452012, 0.4170586467, -0.0730088577, -0.0067603607, 0.0871015340, 0.2065422386));
	r += mul(s0_8, min16float4x4(-0.0618610717, -0.0097180149, -0.1164478958, -0.0710752457, -0.0458406508, -0.0789949819, -0.0566452518, -0.0334778205, 0.0501685329, -0.1898069233, 0.2379287332, -0.0934963450, 0.0730546489, 0.0010386226, 0.1362305433, 0.0705567375));
	r += mul(s1_0, min16float4x4(0.1203611866, -0.0263987370, 0.0186169185, 0.0054342747, -0.1174322218, -0.0406299010, -0.0222875252, -0.0156481136, -0.0244746469, -0.0011745881, -0.0184566788, 0.0054488867, 0.0234689284, 0.0421144664, -0.0097545860, 0.0044351351));
	r += mul(s1_1, min16float4x4(-0.0949838534, 0.0964335278, -0.0014503188, 0.0619035736, 0.0303107407, -0.1439916044, 0.0606122985, 0.0077109658, 0.0117515484, 0.0022375698, 0.0004344881, -0.0003605473, 0.0521178022, 0.0748801082, -0.0732588097, -0.0504439361));
	r += mul(s1_2, min16float4x4(-0.0265410580, 0.0364985503, 0.0241154097, -0.0105037205, -0.0753319114, -0.0173141975, 0.0002442452, 0.0560490638, 0.0020268571, -0.0032355075, 0.0026003914, -0.0001388936, 0.0742558464, -0.0125136087, 0.0179949068, -0.0573016182));
	r += mul(s1_3, min16float4x4(-0.3581319451, 0.0420138128, 0.2890752554, -0.0042630201, -0.0411377065, 0.1698447913, -0.1860257387, 0.0708391070, -0.0223332364, -0.0475134440, -0.0560313836, -0.0335692316, 0.0748835355, -0.1193848178, 0.1079198718, -0.0238429774));
	r += mul(s1_4, min16float4x4(0.2044252157, -0.6928368807, -0.2657463253, 0.0983730927, 0.3994136155, -0.0183295477, -0.1127810329, -0.6601642370, 0.0328415446, 0.0323493406, 0.0216015670, 0.0022727910, -0.4319209754, 0.0642444566, 0.0977345780, 0.4332977235));
	r += mul(s1_5, min16float4x4(0.0803211108, 0.1198763922, -0.0362306051, -0.1219239458, -0.0469953045, 0.0492372029, -0.1173388734, -0.0011351081, 0.0040651867, 0.0099421516, 0.0114335110, 0.0114854435, 0.0117291082, -0.0801739618, 0.1283971369, 0.1064762026));
	r += mul(s1_6, min16float4x4(0.0878977031, 0.2598537207, -0.3792337775, 0.0744308084, -0.0869879499, -0.0017796928, 0.0489757322, 0.1293945909, -0.0335667916, 0.0108538186, -0.0133825494, -0.0072763902, 0.0574890599, -0.0051779463, -0.0077546998, -0.0954428464));
	r += mul(s1_7, min16float4x4(-0.0545818806, 0.1276764870, 0.3154291213, -0.1860405654, -0.0052377013, -0.0427643470, 0.2318652868, 0.2217027098, 0.0161246788, 0.0098808203, 0.0219651330, 0.0151670445, 0.0814895779, 0.0129597932, -0.1948240101, -0.1430664808));
	r += mul(s1_8, min16float4x4(0.0372894928, -0.0054049133, 0.0742261931, 0.1198701337, 0.0353830010, 0.0286245383, 0.0391845852, 0.0545971468, 0.0025816062, -0.0006345272, -0.0010127968, -0.0001622128, -0.0607981831, -0.0301985927, -0.1060507745, -0.1313475966));
	r += min16float4(5.1837512728525326e-05, 3.993907375843264e-05, 4.411826012074016e-05, 8.358651939488482e-06);
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
	min16float4 s0_0 = l0(-1.0, -1.0);
	min16float4 s0_1 = l0(0.0, -1.0);
	min16float4 s0_2 = l0(1.0, -1.0);
	min16float4 s0_3 = l0(-1.0, 0.0);
	min16float4 s0_4 = l0(0.0, 0.0);
	min16float4 s0_5 = l0(1.0, 0.0);
	min16float4 s0_6 = l0(-1.0, 1.0);
	min16float4 s0_7 = l0(0.0, 1.0);
	min16float4 s0_8 = l0(1.0, 1.0);
	min16float4 s1_0 = max(-s0_0, 0.0);
	min16float4 s1_1 = max(-s0_1, 0.0);
	min16float4 s1_2 = max(-s0_2, 0.0);
	min16float4 s1_3 = max(-s0_3, 0.0);
	min16float4 s1_4 = max(-s0_4, 0.0);
	min16float4 s1_5 = max(-s0_5, 0.0);
	min16float4 s1_6 = max(-s0_6, 0.0);
	min16float4 s1_7 = max(-s0_7, 0.0);
	min16float4 s1_8 = max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	out_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 4
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-DS-NVL-shuffle
//!STYLE PS
//!IN out_0, INPUT
float4 Pass4(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = out_0.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += yuv.r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

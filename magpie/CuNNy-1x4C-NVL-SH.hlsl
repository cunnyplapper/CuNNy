// CuNNy 1x4C BILINEAR NVL SH
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
Texture2D up_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D conv1_0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D down;

//!PASS 1
//!DESC CuNNy-1x4C-BILINEAR-NVL-SH-up
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT up_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) dot(float3(0.299, 0.587, 0.114), O(INPUT, float2(x, y)).rgb)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	min16float4 r = 0.0;
	r += min16float4(0.08997927606105804, 0.027914363890886307, -0.025509633123874664, 0.007517277263104916) * s0_0;
	r += min16float4(0.07525984942913055, -0.24254070222377777, 0.0503670871257782, -0.06762690842151642) * s0_1;
	r += min16float4(0.01823834516108036, -0.18432775139808655, -0.02749897912144661, 0.06045375019311905) * s0_2;
	r += min16float4(0.10282750427722931, -0.02957170456647873, -0.012287241406738758, -0.024723293259739876) * s0_3;
	r += min16float4(-0.45596906542778015, 0.250791072845459, 0.3134765923023224, 0.4013671576976776) * s0_4;
	r += min16float4(-0.03991697356104851, 0.18249599635601044, -0.00483658304437995, -0.37529808282852173) * s0_5;
	r += min16float4(0.03847062960267067, 0.003618963761255145, 0.03649762272834778, 0.0110893864184618) * s0_6;
	r += min16float4(0.14404301345348358, -0.006149762775748968, -0.3634743392467499, -0.05627444386482239) * s0_7;
	r += min16float4(0.02196277305483818, -0.0016943076625466347, 0.032999224960803986, 0.04392935335636139) * s0_8;
	r += float4(0.0015523910988122225, 0.001569064217619598, 0.0003615606401581317, 0.001712498371489346);
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
	up_0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 2
//!DESC CuNNy-1x4C-BILINEAR-NVL-SH-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN up_0
//!OUT conv1_0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(up_0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(-0.11058933287858963, -0.002450755797326565, 0.026485605165362358, -0.028117792680859566, 0.020782332867383957, -0.02189934439957142, -0.035500358790159225, -0.02668379433453083, -0.2026364952325821, -0.45215269923210144, 0.36036360263824463, -0.07493062317371368, -0.08864268660545349, -0.03421758860349655, 0.0350610688328743, 0.009301171638071537));
	r += mul(s0_1, min16float4x4(-0.033870406448841095, 0.5920073986053467, -0.361065536737442, 0.027395855635404587, 0.08911221474409103, -0.013182563707232475, -0.09545908868312836, -0.005449324380606413, 0.0084612425416708, 0.06930607557296753, -0.31854113936424255, -0.32475659251213074, -0.02228168398141861, -0.28908899426460266, -0.03942680358886719, -0.06323252618312836));
	r += mul(s0_2, min16float4x4(0.19602589309215546, 0.06514354795217514, -0.07670244574546814, 0.01520978007465601, -0.030917208641767502, -0.05356963351368904, 0.04780520498752594, 0.03322543948888779, 0.4780005216598511, 0.20461249351501465, -0.20551925897598267, -0.048837583512067795, 0.08819280564785004, -0.003376029897481203, 0.002752734115347266, 0.04806625470519066));
	r += mul(s0_3, min16float4x4(0.32252469658851624, 0.022610632702708244, 0.14374539256095886, 0.12533289194107056, 0.06193997338414192, 0.13256016373634338, -0.13771815598011017, -0.08921390026807785, -0.0032442372757941484, -0.01436188817024231, 0.2480662316083908, 0.10802222043275833, -0.9473434686660767, 0.08348704129457474, -1.1863987445831299, -0.6623256802558899));
	r += mul(s0_4, min16float4x4(-0.2919871211051941, -0.4806119203567505, -0.07686247676610947, 0.5332136154174805, -0.04478093981742859, 0.19482429325580597, 0.10652466118335724, 0.01443659421056509, -0.10493821650743484, 0.16552749276161194, -0.2744140625, -0.1811523139476776, 1.0389991998672485, 0.4502592384815216, 0.006205855868756771, 0.11987500637769699));
	r += mul(s0_5, min16float4x4(-0.087642140686512, -0.0949784591794014, 0.14788608253002167, -0.020898884162306786, 0.0045928070321679115, -0.02206284925341606, -0.002300985623151064, -0.07279736548662186, 0.1252187341451645, 0.31471872329711914, -0.012154361233115196, -0.11956074088811874, -0.08560509979724884, -0.08464741706848145, -0.026801418513059616, -0.04833312705159187));
	r += mul(s0_6, min16float4x4(-0.05501187965273857, -0.02020592987537384, -0.04384685680270195, -0.24859827756881714, 0.9238295555114746, 0.14507706463336945, 0.28809261322021484, -0.24786414206027985, -0.027230432257056236, -0.030535120517015457, 0.060979731380939484, 0.050168726593256, -0.13525710999965668, -0.07270354777574539, -0.017583057284355164, 0.686047375202179));
	r += mul(s0_7, min16float4x4(-0.2557075023651123, -0.03564736247062683, -0.06122247129678726, -0.5456959009170532, -0.8167362213134766, -0.2939054071903229, 0.1733756959438324, 0.142362579703331, -0.030576808378100395, -0.024863101541996002, 0.08812571316957474, 0.061645716428756714, 0.5019537210464478, -0.07614139467477798, 0.04049614071846008, -0.06255500763654709));
	r += mul(s0_8, min16float4x4(0.10995015501976013, 0.005263048689812422, -0.14030036330223083, -0.01024281233549118, -0.1949150115251541, 0.2014622539281845, 0.0685969665646553, -0.0056189727038145065, 0.08230863511562347, -0.07055914402008057, -0.005837260279804468, 0.10987541824579239, 0.00242592953145504, 0.08962637931108475, 0.022073088213801384, 0.00040689436718821526));
	r += mul(s1_0, min16float4x4(0.005184822250157595, 0.12230194360017776, 0.020434308797121048, 0.044933728873729706, 0.11840939521789551, -0.2283606380224228, 0.0827159509062767, -0.014104907400906086, 0.11458616703748703, -0.0297547560185194, 0.1199469119310379, 0.09692439436912537, -0.0062741804867982864, -0.6582043170928955, 0.3005450963973999, -0.16585031151771545));
	r += mul(s1_1, min16float4x4(-0.16447843611240387, -0.01946253515779972, 0.14951905608177185, 0.027486667037010193, -0.10081734508275986, -0.06716614216566086, 0.22804506123065948, 0.0824039950966835, -0.18854902684688568, 0.3340068459510803, 0.015200656838715076, 0.010878515429794788, 0.0696292296051979, -0.8417965769767761, -0.24778451025485992, -0.17629538476467133));
	r += mul(s1_2, min16float4x4(-0.016145097091794014, 0.07124020159244537, 0.012837711721658707, -0.07566986232995987, -0.00024921883596107364, -0.16731221973896027, -0.04758067429065704, -0.05334121361374855, -0.007359062787145376, -0.0910453274846077, 0.013279960490763187, -0.09087134152650833, 0.16428472101688385, -0.02056889235973358, 0.01912521757185459, 0.010031908750534058));
	r += mul(s1_3, min16float4x4(0.026127448305487633, -0.11862264573574066, -0.021700380370020866, -0.041081078350543976, 0.24378879368305206, 0.35323676466941833, -0.3720693290233612, -0.26491743326187134, -0.5734990835189819, -0.04965275526046753, 0.22135299444198608, -0.17302413284778595, 0.033304452896118164, 0.0005815449985675514, 1.2148181200027466, 0.044114015996456146));
	r += mul(s1_4, min16float4x4(0.05028383806347847, -0.14644384384155273, 0.14111341536045074, 0.21788592636585236, -0.10003139078617096, -1.1885539293289185, 0.3132607340812683, -0.1737031787633896, -0.2731051445007324, 0.4365231692790985, -0.24189452826976776, -0.9171741604804993, -0.2911781072616577, 1.3239754438400269, -1.4816701412200928, -2.558196544647217));
	r += mul(s1_5, min16float4x4(-0.0959775373339653, -0.40045255422592163, -0.06042037531733513, 0.11458131670951843, -0.2337012141942978, 0.2509555220603943, -0.04107906296849251, -0.057824838906526566, 1.2752796411514282, 0.18867948651313782, -0.25245779752731323, -0.30718255043029785, -0.036474622786045074, -0.027117183431982994, 0.11524000018835068, 0.10803846269845963));
	r += mul(s1_6, min16float4x4(0.004592812154442072, -0.0009219549247063696, 0.03276627138257027, -0.010152123868465424, 0.11845516413450241, 0.12548959255218506, -0.33858710527420044, 0.38787907361984253, -0.012954545207321644, 0.043716318905353546, -0.0920499935746193, 0.2998395562171936, -0.09020537883043289, -0.03922739997506142, 0.24501170217990875, -0.005838269367814064));
	r += mul(s1_7, min16float4x4(0.06909173727035522, 0.1635744720697403, -0.2806726098060608, -0.2417251467704773, -0.1557932198047638, 0.027483535930514336, 0.40529805421829224, 0.6269153356552124, 0.14498528838157654, -0.03496171534061432, 0.11007826030254364, 0.7446362972259521, 0.0787448063492775, -0.002312472090125084, 0.029228955507278442, 0.3741411566734314));
	r += mul(s1_8, min16float4x4(-0.10848849266767502, 0.02031528390944004, 0.03153397887945175, -0.06205489858984947, 0.0520084984600544, 0.07864691317081451, -0.011700160801410675, -0.06270036101341248, -0.001628741854801774, 0.11719173938035965, 0.16844385862350464, 0.1883394718170166, 0.28604286909103394, -0.09004580229520798, -0.05597767233848572, -0.020778842270374298));
	r += float4(0.0037708093877881765, -0.0030638501048088074, 0.004613643977791071, -0.0001925381802720949);
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
//!DESC CuNNy-1x4C-BILINEAR-NVL-SH-down
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN conv1_0
//!OUT down
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(conv1_0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(-0.006156535819172859, 0.017035948112607002, 0.03245621174573898, -0.11186666786670685, 0.023293988779187202, -0.08717262744903564, -0.04428388178348541, -0.08130108565092087, 0.05553701892495155, 0.005339980125427246, 0.016654103994369507, 0.028230011463165283, -0.06133786961436272, 0.006653312128037214, -0.1675439178943634, 0.1210474818944931));
	r += mul(s0_1, min16float4x4(0.06951649487018585, -0.06237923726439476, 0.06484147161245346, 0.13368117809295654, 0.04761248454451561, 0.15966132283210754, -0.020164430141448975, -0.004886142909526825, 0.177056685090065, 0.23506397008895874, 0.0715196281671524, 0.11846759915351868, 0.42230337858200073, 0.3769781291484833, -0.8917778134346008, -1.1233028173446655));
	r += mul(s0_2, min16float4x4(0.00913134217262268, 0.03527872636914253, 0.00017696709255687892, 0.03409188985824585, 0.0029731590766459703, 0.008669777773320675, 0.006619797088205814, -0.00883516389876604, 0.01103260274976492, -0.045705899596214294, -0.00035508189466781914, 0.0338536836206913, -0.03350942209362984, -0.06835196912288666, 0.12323331087827682, 0.061598390340805054));
	r += mul(s0_3, min16float4x4(0.23652289807796478, -0.09881419688463211, 0.2900582551956177, 0.1315365731716156, -0.6230320930480957, -0.03450995683670044, 0.5332959890365601, -0.11558259278535843, -0.11684972047805786, -0.04944545403122902, -0.09904492646455765, -0.176346093416214, -0.033082544803619385, 0.15410801768302917, 0.09831338375806808, 0.21727444231510162));
	r += mul(s0_4, min16float4x4(-0.13766559958457947, 0.15711544454097748, -0.05565209314227104, -0.09057608991861343, 0.5644534826278687, -0.2122008204460144, 0.21142660081386566, 0.8742489814758301, 0.32384470105171204, 0.06667273491621017, 0.5726861953735352, 0.4394323527812958, -0.10885654389858246, -0.5922693014144897, 0.627959668636322, 0.1934932917356491));
	r += mul(s0_5, min16float4x4(-0.015924939885735512, -0.0057758004404604435, -0.009928111918270588, -0.015593988820910454, 0.012354378588497639, 0.25738200545310974, -0.01849057897925377, -0.0686035230755806, -0.24511267244815826, -0.2493337094783783, -0.20758430659770966, -0.2117045521736145, 0.0461752787232399, 0.3249550759792328, -0.06185540929436684, 0.23134906589984894));
	r += mul(s0_6, min16float4x4(-0.018020080402493477, 0.04858807101845741, -0.042634058743715286, 0.0005002804100513458, 0.006573021877557039, 0.07505586743354797, -0.7336685061454773, -0.18151992559432983, -0.005664524622261524, -0.017840959131717682, 0.002252613427117467, -0.018813056871294975, 0.004080299753695726, 0.03814588487148285, -0.021153440698981285, 0.009613893926143646));
	r += mul(s0_7, min16float4x4(0.03747591748833656, -0.08855144679546356, -0.03501737862825394, -0.07550780475139618, -0.16695591807365417, -0.2510950267314911, 0.14202971756458282, -0.4183499217033386, 0.030733905732631683, -0.0007904741214588284, 0.000694835907779634, -0.06900940090417862, 0.009556430391967297, -0.08692802488803864, 0.06616467237472534, -0.03355954959988594));
	r += mul(s0_8, min16float4x4(0.005502686835825443, -0.0426095649600029, 0.01335776224732399, -0.01682256907224655, 0.025532647967338562, 0.04475812613964081, -0.011348187923431396, 0.10231088101863861, -0.07134748995304108, 0.0335356630384922, -0.20922675728797913, -0.18551766872406006, 0.027355121448636055, 0.09937465190887451, 0.04356953874230385, 0.11784868687391281));
	r += mul(s1_0, min16float4x4(0.03867502138018608, -0.15966761112213135, 0.028398247435688972, 0.10881257057189941, -0.02092590183019638, -0.02607240341603756, -0.010871602222323418, -0.0016452495474368334, -0.05570878088474274, 0.10939217358827591, -0.0766419917345047, -0.0867467075586319, 0.04719802737236023, -0.01739884540438652, -0.01413781475275755, -0.06314112991094589));
	r += mul(s1_1, min16float4x4(-0.30761614441871643, 0.272078275680542, 0.2618108093738556, -0.25637033581733704, -0.1440170854330063, -0.11054463684558868, -0.06018242612481117, -0.08915919810533524, -0.21681331098079681, -0.34138986468315125, -0.019335808232426643, 0.04757331684231758, 0.3466752767562866, 0.39910727739334106, 0.044769514352083206, 0.19676093757152557));
	r += mul(s1_2, min16float4x4(0.09965559840202332, -0.10817699134349823, 0.007943031378090382, -0.06285712867975235, 0.02883332036435604, 0.013085361570119858, 0.014408908784389496, 0.027419475838541985, -0.07837028801441193, -0.07805903255939484, -0.013079729862511158, 0.05871681496500969, 0.05211905762553215, 0.09008469432592392, 0.0071110897697508335, -0.04905235022306442));
	r += mul(s1_3, min16float4x4(-0.0013927592663094401, -0.3933415710926056, 0.0765557587146759, -0.6152408123016357, -0.1393141746520996, 0.05964545160531998, 0.04525182768702507, 0.15863651037216187, 0.040207844227552414, 0.35640984773635864, -0.023302489891648293, 0.5098894834518433, 0.05503561720252037, -0.14895005524158478, -0.11865749955177307, -0.1860356628894806));
	r += mul(s1_4, min16float4x4(-0.9863283038139343, 0.71162348985672, -1.4917898178100586, 1.3323317766189575, -0.23071041703224182, -0.4853852391242981, -0.05979008972644806, -0.23436136543750763, 0.6554027795791626, -0.9589835405349731, 0.05878620594739914, -1.4804681539535522, -0.6819351315498352, 0.021048735827207565, 0.012348925694823265, 0.3744966387748718));
	r += mul(s1_5, min16float4x4(0.3896484375, 0.11593414843082428, 0.4606729745864868, -0.026665741577744484, -0.0776490569114685, -0.07552477717399597, 0.013994836248457432, 0.054344113916158676, 0.045240648090839386, 0.7854146361351013, -0.05949903279542923, 0.37969666719436646, -0.05163244530558586, -0.49244424700737, 0.014292748644948006, -0.20577973127365112));
	r += mul(s1_6, min16float4x4(0.05017122998833656, -0.0069996691308915615, -0.01897354982793331, -0.110089011490345, 0.3167564272880554, 0.14574353396892548, 0.16836999356746674, 0.3179154098033905, -0.06180891394615173, 0.020269980654120445, 0.0013120126677677035, 0.12917760014533997, 0.03953973203897476, -0.01906261220574379, 0.12728101015090942, -0.026899175718426704));
	r += mul(s1_7, min16float4x4(0.13915912806987762, -0.028350355103611946, 0.15468773245811462, 0.004111844580620527, 0.21751442551612854, 0.40589842200279236, 0.08346275985240936, -0.08175250142812729, -0.09026426821947098, 0.046066224575042725, 0.18692412972450256, -0.015924956649541855, 0.11484000831842422, 0.2260752022266388, -0.1440429538488388, 0.12779003381729126));
	r += mul(s1_8, min16float4x4(-0.02813168801367283, -0.07725486159324646, 0.022019850090146065, 0.05314880609512329, -0.061930861324071884, 0.007657184731215239, -0.06411170214414597, -0.011294144205749035, 0.010992593131959438, -0.06473689526319504, 0.07299766689538956, 0.2394399642944336, -0.030109193176031113, -0.025942008942365646, -0.08129619061946869, -0.15380875766277313));
	r += float4(-0.0008897421066649258, 0.00040035168058238924, -0.001830562949180603, -0.0002266023657284677);
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
	down[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 4
//!DESC CuNNy-1x4C-BILINEAR-NVL-SH-shuffle
//!STYLE PS
//!IN down, INPUT
float4 Pass4(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = down.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += yuv.r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

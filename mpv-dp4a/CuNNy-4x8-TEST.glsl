// CuNNy 4x8 BILINEAR TEST
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


//!DESC CuNNy-4x8-BILINEAR-TEST-in
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND LUMA
//!SAVE in
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) F(LUMA_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0)) + vec2(0.5)) * LUMA_pt).r)
shared F g[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			g[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	F s[3][3][1];
	V4 r0 = V4(0.0);
	V4 r1 = V4(0.0);
	s[0][0][0] = g[0][xy.y+0][xy.x+0];
	s[0][1][0] = g[0][xy.y+0][xy.x+1];
	s[0][2][0] = g[0][xy.y+0][xy.x+2];
	s[1][0][0] = g[0][xy.y+1][xy.x+0];
	s[1][1][0] = g[0][xy.y+1][xy.x+1];
	s[1][2][0] = g[0][xy.y+1][xy.x+2];
	s[2][0][0] = g[0][xy.y+2][xy.x+0];
	s[2][1][0] = g[0][xy.y+2][xy.x+1];
	s[2][2][0] = g[0][xy.y+2][xy.x+2];
	r0 += V4(4.722e-02, 1.444e-02, 2.168e-02, 3.062e-02) * s[0][0][0];
	r1 += V4(1.652e-01, -5.857e-03, 2.179e-02, -5.579e-02) * s[0][0][0];
	r0 += V4(1.281e-01, 7.578e-02, -1.136e-01, 1.469e-01) * s[0][1][0];
	r1 += V4(3.678e-01, -2.242e-02, -1.015e-01, 3.333e-02) * s[0][1][0];
	r0 += V4(-5.140e-02, -4.868e-02, 6.746e-03, -8.507e-03) * s[0][2][0];
	r1 += V4(-3.084e-02, 3.406e-02, -2.873e-02, -1.018e-02) * s[0][2][0];
	r0 += V4(-6.335e-02, 5.943e-02, 3.798e-01, 1.013e-01) * s[1][0][0];
	r1 += V4(2.760e-01, -6.435e-02, -1.273e-02, -1.158e-01) * s[1][0][0];
	r0 += V4(1.695e-01, 1.638e-01, 4.335e-01, -2.500e-01) * s[1][1][0];
	r1 += V4(-9.668e-01, -2.782e-01, 1.763e-01, 2.042e-01) * s[1][1][0];
	r0 += V4(-4.504e-02, 2.926e-01, -1.372e-01, 1.399e-01) * s[1][2][0];
	r1 += V4(1.244e-01, -1.326e-01, 7.401e-02, -1.091e-01) * s[1][2][0];
	r0 += V4(-4.681e-02, -5.205e-03, -3.828e-02, -1.387e-02) * s[2][0][0];
	r1 += V4(-2.462e-03, 3.707e-02, -8.471e-02, 3.503e-02) * s[2][0][0];
	r0 += V4(-1.365e-01, 2.561e-01, -1.256e-01, 8.202e-03) * s[2][1][0];
	r1 += V4(5.155e-02, 6.348e-01, 1.187e-01, 4.005e-02) * s[2][1][0];
	r0 += V4(7.548e-02, -5.758e-02, 1.312e-02, 1.658e-02) * s[2][2][0];
	r1 += V4(7.393e-03, -1.971e-01, -2.660e-02, -1.125e-02) * s[2][2][0];
	r0 += V4(2.590e-02, 3.845e-03, 9.253e-02, 8.459e-02);
	r0 = max(r0, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(2.786e-03, 1.248e-02, -1.195e-02, 1.128e-01);
	r1 = max(r1, V4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-4x8-BILINEAR-TEST-conv1
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND in
//!BIND LUMA
//!SAVE conv1
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) in_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * in_pt)
#define l1(x, y) in_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * in_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1) * 1.00000000e+00;
			vec4 v1 = l1(x - 1, y - 1) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFC0ECD0A, 0xE5EA01F9, 0x190BFC08, 0x0FF4E21B);
	r1 = D(r1, s[0][0][0], 0x1BE103C8, 0x030BEF0B, 0x08F308F0, 0x00F7F10A);
	r0 = D(r0, s[0][0][1], 0xF0EEF8E6, 0x07240AF9, 0x0611DC1E, 0x261D03F2);
	r1 = D(r1, s[0][0][1], 0xFBFC17E2, 0xFE0314FC, 0xF3F41EF7, 0xF0FBF90A);
	r0 = D(r0, s[0][0][2], 0xE6E60BEE, 0x06F5F505, 0xDF100D16, 0xEAED06E9);
	r1 = D(r1, s[0][0][2], 0xF8F1FEEE, 0xEEEE1109, 0xEFF8F721, 0x1121FB0D);
	r0 = D(r0, s[0][1][0], 0xF3F3E1DA, 0x1E11BE14, 0xDCF015CB, 0x0614D13C);
	r1 = D(r1, s[0][1][0], 0x7DBA190F, 0xE7FCEAD9, 0xF7F41D21, 0x19F13102);
	r0 = D(r0, s[0][1][1], 0x5F02861C, 0x0AED2621, 0x08CD21E2, 0xFFAFFDC7);
	r1 = D(r1, s[0][1][1], 0x8EDF0C3E, 0x1E2C0112, 0xC80329E7, 0x8B40071D);
	r0 = D(r0, s[0][1][2], 0xF3EFF845, 0x06F30529, 0xFC380A39, 0xDDD00702);
	r1 = D(r1, s[0][1][2], 0x0C1E0E14, 0xF3FE14D9, 0x11FDF4E0, 0x1E3BEDE4);
	r0 = D(r0, s[0][2][0], 0xEF0381DC, 0xE24FE8DF, 0x16FAE1EB, 0x00F6302D);
	r1 = D(r1, s[0][2][0], 0xFC08F3E6, 0xFC05FB06, 0x1DF016F6, 0x2BFCF104);
	r0 = D(r0, s[0][2][1], 0x13C89FCB, 0xC3C7DDBC, 0x0D00FED7, 0xE0400BDC);
	r1 = D(r1, s[0][2][1], 0x0AF5081A, 0x4DF6F119, 0x0B321231, 0x16B4EF17);
	r0 = D(r0, s[0][2][2], 0xFBCFFF2C, 0x020C160C, 0x0CE9F732, 0x173211EF);
	r1 = D(r1, s[0][2][2], 0xE604FDED, 0xE3D8F02B, 0x1D2E0CEF, 0x231FF3C9);
	r0 = D(r0, s[1][0][0], 0x27111C15, 0x0E1C0BFE, 0xDE262BEB, 0xDA1E0CFF);
	r1 = D(r1, s[1][0][0], 0xF4EDFA06, 0x0AF3FF05, 0x01FEF2FC, 0x1A1B15F6);
	r0 = D(r0, s[1][0][1], 0xFD2A0303, 0xD10013F6, 0xF80E81DE, 0xFE200EF7);
	r1 = D(r1, s[1][0][1], 0x0FD3E701, 0x0BFFE708, 0x0D141706, 0x1CD31905);
	r0 = D(r0, s[1][0][2], 0x01E41F0C, 0xE5FAFFFD, 0x10D5C49A, 0x06E40101);
	r1 = D(r1, s[1][0][2], 0x1B0C0104, 0x1BF10002, 0xDAF3FEFF, 0x020F0EF9);
	r0 = D(r0, s[1][1][0], 0xF67F3C04, 0xD27FC01C, 0xDC003C0A, 0x12DEF900);
	r1 = D(r1, s[1][1][0], 0xD406ED05, 0xE5200FFF, 0xE30DED1E, 0xBE191711);
	r0 = D(r0, s[1][1][1], 0xD4ACD15F, 0x0C051CDA, 0xE1CDFC23, 0xDD03340C);
	r1 = D(r1, s[1][1][1], 0x4725FE09, 0xFDF1FE0A, 0xFE123B02, 0x57E92A28);
	r0 = D(r0, s[1][1][2], 0xF4544F10, 0x0AE811FE, 0x281BE4D7, 0x1EE7FD00);
	r1 = D(r1, s[1][1][2], 0xE60DFB06, 0x0D0EE40E, 0xFDF6FFF3, 0xC11A0AF7);
	r0 = D(r0, s[1][2][0], 0x177F2B37, 0x31BB13DC, 0x26110C0F, 0xEADCF90E);
	r1 = D(r1, s[1][2][0], 0xF02AF70D, 0x08FF15E4, 0xED00EA04, 0x0BF500FB);
	r0 = D(r0, s[1][2][1], 0x0E7F3D7F, 0x27FF03D0, 0xEC0EF1EA, 0xEA2506DC);
	r1 = D(r1, s[1][2][1], 0x1CE7060A, 0xD11A157B, 0x34F200E0, 0xF3E11115);
	r0 = D(r0, s[1][2][2], 0x33F5FD53, 0x0D0005EF, 0x1CF80807, 0x2607E902);
	r1 = D(r1, s[1][2][2], 0x00FBFA01, 0x0A15092F, 0x14F5FE2B, 0xDCF200EB);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(8.372e-02, 1.498e-01, 7.176e-03, 1.724e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(3.680e-02, 3.503e-02, -4.394e-01, -8.992e-02);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
}

//!DESC CuNNy-4x8-BILINEAR-TEST-conv2
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv1
//!BIND LUMA
//!SAVE conv2
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv1_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv1_pt)
#define l1(x, y) conv1_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv1_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1) * 1.00000000e+00;
			vec4 v1 = l1(x - 1, y - 1) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xF1FEF803, 0x03E8F2D6, 0xE2031415, 0x1E07FBF4);
	r1 = D(r1, s[0][0][0], 0x0203FC03, 0x06F8F910, 0x07542381, 0x1607F312);
	r0 = D(r0, s[0][0][1], 0x060A021C, 0x9BFF401F, 0x0712E0F1, 0x2808F9C3);
	r1 = D(r1, s[0][0][1], 0xFBFE1CF0, 0xF0F70262, 0x341FE0DA, 0x13F9EB39);
	r0 = D(r0, s[0][0][2], 0xF5F8F919, 0x00FED817, 0xF2FB08F0, 0x020121F7);
	r1 = D(r1, s[0][0][2], 0x04FFED07, 0xFC000D06, 0xE5FB1919, 0xE6FE280A);
	r0 = D(r0, s[0][1][0], 0xEE1704F9, 0xF9E1E9F0, 0xFFE2FCD4, 0xFE0BF124);
	r1 = D(r1, s[0][1][0], 0x050806FE, 0x1000FC04, 0xE7F820E5, 0xF9FEFB33);
	r0 = D(r0, s[0][1][1], 0x2D3E061A, 0x96B234EB, 0x13E8C41D, 0x15DEF92A);
	r1 = D(r1, s[0][1][1], 0xFD025805, 0x2FEEFF2C, 0xFB1127A3, 0x0D16FD47);
	r0 = D(r0, s[0][1][2], 0x0AF8DD34, 0x16F4DA0C, 0x05EE01FE, 0xF4F0DE0E);
	r1 = D(r1, s[0][1][2], 0x0307E805, 0x05FD0A0E, 0x27F9EB28, 0xEC0061F0);
	r0 = D(r0, s[0][2][0], 0xF9220CEF, 0x0CF40C24, 0x00FE050E, 0x02FF0006);
	r1 = D(r1, s[0][2][0], 0x0107F900, 0xFDF9FD10, 0xECE4EA23, 0xF42300FB);
	r0 = D(r0, s[0][2][1], 0x08132319, 0x081D281B, 0x19E4FB20, 0x07F5060C);
	r1 = D(r1, s[0][2][1], 0xF806FE20, 0x07FAFB1E, 0xE013333A, 0xFB22D4F6);
	r0 = D(r0, s[0][2][2], 0xF802FA12, 0xFC01DBF5, 0xF6EF2EE5, 0xFEFB2AFD);
	r1 = D(r1, s[0][2][2], 0x030A0A01, 0x02FC0709, 0x0A18B512, 0xECFDE2F6);
	r0 = D(r0, s[1][0][0], 0x08FEFC07, 0xFAEACC07, 0xE709B8F2, 0x0307FB11);
	r1 = D(r1, s[1][0][0], 0x02050002, 0x03030307, 0x29089BED, 0x0804FF01);
	r0 = D(r0, s[1][0][1], 0xFF14DF1C, 0xCD4120D5, 0x150AF403, 0x21EDE022);
	r1 = D(r1, s[1][0][1], 0xFC001A01, 0x05002810, 0xEFDCEEE8, 0x14EA0D14);
	r0 = D(r0, s[1][0][2], 0x07F5F3FF, 0x0FF8ECEA, 0x04020DF0, 0x02020E08);
	r1 = D(r1, s[1][0][2], 0x0207FC03, 0x02FEF602, 0x1F0422F6, 0x0EFB00EA);
	r0 = D(r0, s[1][1][0], 0x0B000BF4, 0xCAE7010A, 0x5509FB12, 0x2C100C13);
	r1 = D(r1, s[1][1][0], 0xFC000CFD, 0x1D02F90B, 0x5FFCC8FE, 0x1E071805);
	r0 = D(r0, s[1][1][1], 0x05F4311A, 0x66F90098, 0x11E51850, 0xFB041A2C);
	r1 = D(r1, s[1][1][1], 0xF555D7FC, 0xE2F800F9, 0xC206EAF3, 0xD1FE1D3E);
	r0 = D(r0, s[1][1][2], 0x0C051825, 0x13FA2981, 0xFE001527, 0x10FF0B35);
	r1 = D(r1, s[1][1][2], 0xFA16FA10, 0x03000431, 0xCB0A0C2E, 0x04F6FE08);
	r0 = D(r0, s[1][2][0], 0xF6F7FAF9, 0x1AF80BEC, 0x190109E6, 0xFBFE0B08);
	r1 = D(r1, s[1][2][0], 0x0D050305, 0x08040300, 0xE2F1F3F4, 0x280E0001);
	r0 = D(r0, s[1][2][1], 0xE50907B0, 0xDA062416, 0xBDFE21FA, 0xD5FA0017);
	r1 = D(r1, s[1][2][1], 0x0E110C10, 0xFD020518, 0x4912FAFE, 0x14070623);
	r0 = D(r0, s[1][2][2], 0x0100F828, 0xF1120E01, 0xF0FC0914, 0xFE00FE04);
	r1 = D(r1, s[1][2][2], 0xF70100E8, 0x02010012, 0xFFF8F6B1, 0x1102F5FA);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-3.610e-02, -1.611e-02, -3.058e-02, 5.965e-03);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-5.705e-01, 6.814e-02, -1.708e-02, -5.598e-02);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
}

//!DESC CuNNy-4x8-BILINEAR-TEST-conv3
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE conv3
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv2_pt)
#define l1(x, y) conv2_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv2_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1) * 1.00000000e+00;
			vec4 v1 = l1(x - 1, y - 1) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x00030605, 0x11FC0AFA, 0x11090BE6, 0xFB000508);
	r1 = D(r1, s[0][0][0], 0x150EF0FC, 0xF70307F9, 0x08FC0A04, 0x03090314);
	r0 = D(r0, s[0][0][1], 0x10010A0F, 0xD5ADFBB8, 0x02071305, 0x09E50B03);
	r1 = D(r1, s[0][0][1], 0xE50AF218, 0xFF25F13F, 0xE4FDF9FC, 0xEF05F92A);
	r0 = D(r0, s[0][0][2], 0xEF160102, 0x2DD31801, 0x040F0FF6, 0x03F907FB);
	r1 = D(r1, s[0][0][2], 0xF704F7FD, 0xF31AFD02, 0xF9FFF9FC, 0x04F70302);
	r0 = D(r0, s[0][1][0], 0xF207ED03, 0x15E1190E, 0x16130B04, 0x0BF40E01);
	r1 = D(r1, s[0][1][0], 0x2D2CDA03, 0xF0FEFAF8, 0xF5FF06FF, 0x030F03FC);
	r0 = D(r0, s[0][1][1], 0x36FCE442, 0xF8BA2881, 0x3008DCFA, 0x07F82AFC);
	r1 = D(r1, s[0][1][1], 0xFB0FDB06, 0x1D2BCA11, 0xFF11F2F1, 0xFEE0070E);
	r0 = D(r0, s[0][1][2], 0xCE04E91E, 0x04E10D01, 0xF21BEF04, 0x15F40BFF);
	r1 = D(r1, s[0][1][2], 0xEE0DF7FD, 0xE318DD13, 0xEE0DF601, 0x030BFDFB);
	r0 = D(r0, s[0][2][0], 0x02F9FB03, 0x06020AE9, 0xFA10FAF7, 0x0BF706FD);
	r1 = D(r1, s[0][2][0], 0x0B15ECFB, 0xF9FB0300, 0xF8000702, 0xFAFF0606);
	r0 = D(r0, s[0][2][1], 0xF7070308, 0xE0DA3FFB, 0xF41805FA, 0x0DFF0BFC);
	r1 = D(r1, s[0][2][1], 0x0205FAFD, 0x1308EC07, 0xF108F900, 0xE40E020A);
	r0 = D(r0, s[0][2][2], 0xFD12EE00, 0xFF10FCFF, 0xFD25EEF9, 0x07F804FD);
	r1 = D(r1, s[0][2][2], 0xFB06FBFE, 0x10FDF9FA, 0x0003F202, 0xF506FB06);
	r0 = D(r0, s[1][0][0], 0xF216FECD, 0x1DFCFCDA, 0xF5EB0417, 0x0000052A);
	r1 = D(r1, s[1][0][0], 0xE60CFF7F, 0xFFFFFD2C, 0x04FDF92D, 0x08FAF8FC);
	r0 = D(r0, s[1][0][1], 0xEE22E051, 0x2816DE2C, 0xF1F10581, 0x0A00F67F);
	r1 = D(r1, s[1][0][1], 0x00EF2728, 0xD9022A16, 0x070C07B2, 0xFB0D0181);
	r0 = D(r0, s[1][0][2], 0xF703197F, 0x031100DC, 0xF2F3FE40, 0x09F5047F);
	r1 = D(r1, s[1][0][2], 0xF3090824, 0xFCFE0364, 0xFB070A1F, 0x00FEF3EA);
	r0 = D(r0, s[1][1][0], 0xF018270B, 0x23E7D58D, 0xDAE3F7BF, 0xFAFDFD0A);
	r1 = D(r1, s[1][1][0], 0xDE08B17F, 0x010A2B57, 0x04030844, 0x00F9F545);
	r0 = D(r0, s[1][1][1], 0x06FEC2E2, 0x3FCAD0AE, 0xF2D25A50, 0xF208A77F);
	r1 = D(r1, s[1][1][1], 0x2B081738, 0x040A287F, 0x1017701F, 0x08E353CE);
	r0 = D(r0, s[1][1][2], 0xEB27E153, 0xE315F785, 0xF4E70A45, 0x0C02F94B);
	r1 = D(r1, s[1][1][2], 0xF40E03FD, 0x0C07CE5D, 0x0A050A36, 0xFC00000A);
	r0 = D(r0, s[1][2][0], 0xF50000D2, 0x0E04F0F4, 0x01FE09DF, 0xFFFF07E8);
	r1 = D(r1, s[1][2][0], 0x0711F91A, 0xFDFA00F8, 0x02FCFF1A, 0x06FEFE2B);
	r0 = D(r0, s[1][2][1], 0x09170A15, 0xFDFA2237, 0xF7F0E92B, 0x0D03EE07);
	r1 = D(r1, s[1][2][1], 0x070CFD0E, 0xF006F2F7, 0xF80A031F, 0xFE0825F1);
	r0 = D(r0, s[1][2][2], 0x101CF30D, 0xF70A14DA, 0xF6F6FDD6, 0xFEFAFAF7);
	r1 = D(r1, s[1][2][2], 0xFB09090E, 0x00F50200, 0xFF08010B, 0xFB03F42E);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(2.509e-02, 1.047e-01, -7.945e-02, 6.108e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-1.825e-02, -4.544e-02, -7.252e-02, 1.289e-03);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
}

//!DESC CuNNy-4x8-BILINEAR-TEST-conv4
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv3
//!BIND LUMA
//!SAVE conv4
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
#define l0(x, y) conv3_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv3_pt)
#define l1(x, y) conv3_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv3_pt)
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec4 v0 = l0(x - 1, y - 1) * 1.00000000e+00;
			vec4 v1 = l1(x - 1, y - 1) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xE1FBF2DC, 0x13FAF907, 0x1F22F713, 0x0100FD01);
	r1 = D(r1, s[0][0][0], 0x13FEECFD, 0x08FFF206, 0x0306F8FC, 0x10F2F504);
	r0 = D(r0, s[0][0][1], 0xBD03D01F, 0xE103E90C, 0x8CEF81D1, 0x2DFCF5FE);
	r1 = D(r1, s[0][0][1], 0x03EBF3F5, 0xF9E1ED16, 0x15DDEC03, 0x0503F5FC);
	r0 = D(r0, s[0][0][2], 0x0CFB01D4, 0x0115FC0B, 0xC9CEA4F6, 0x0DF8F901);
	r1 = D(r1, s[0][0][2], 0x0702FC00, 0x1631DFFA, 0x0A05F3F0, 0x0F02FDF6);
	r0 = D(r0, s[0][1][0], 0x0405E2DF, 0x0302F405, 0x0C20172F, 0x2901FC04);
	r1 = D(r1, s[0][1][0], 0xF4D6E1F9, 0x0300F105, 0x08FAEF05, 0xE6F6F5EF);
	r0 = D(r0, s[0][1][1], 0x0DEFEDFF, 0xF906EDE1, 0x81098181, 0xD207E30F);
	r1 = D(r1, s[0][1][1], 0xD13FEB3C, 0xB0FAF6CE, 0xADFBEC0E, 0xE411ED13);
	r0 = D(r0, s[0][1][2], 0x0210F3ED, 0xE0FEFC0B, 0xDEDD9603, 0x12FCF9F5);
	r1 = D(r1, s[0][1][2], 0x0F0AF5EA, 0xF7E8DE10, 0xF52CE51A, 0x05FAF203);
	r0 = D(r0, s[0][2][0], 0x090800F5, 0x03FEFDF6, 0x140D2008, 0x0DFFF9F1);
	r1 = D(r1, s[0][2][0], 0xF30BDCF1, 0x00FEFFFE, 0x0203F905, 0xF502F706);
	r0 = D(r0, s[0][2][1], 0x00F2FDFE, 0xFC00FE00, 0x351C361B, 0x2101FC04);
	r1 = D(r1, s[0][2][1], 0xD4E0DE01, 0x0800F404, 0xEDFDE4E4, 0xEEF0F1EB);
	r0 = D(r0, s[0][2][2], 0x01F102F6, 0x0AF8F906, 0x090D0C0E, 0x01010100);
	r1 = D(r1, s[0][2][2], 0x0BF0EAFA, 0x02FFF206, 0x07E4D9FD, 0x08F9F8FD);
	r0 = D(r0, s[1][0][0], 0x1A04F7F5, 0xFFFC0B03, 0x10813E19, 0xF9020CFF);
	r1 = D(r1, s[1][0][0], 0x01F60203, 0x02F8FA09, 0x06FDFF02, 0x05FC0502);
	r0 = D(r0, s[1][0][1], 0xC6F54914, 0xD42516F6, 0xA2C14BDB, 0xF6050EF8);
	r1 = D(r1, s[1][0][1], 0x01ED0D06, 0x0D14F9F8, 0x03EE0208, 0xEE030AFA);
	r0 = D(r0, s[1][0][2], 0xCAFC1FFD, 0x1600EA0D, 0xA3812113, 0xF4020CED);
	r1 = D(r1, s[1][0][2], 0xF30204F8, 0x00F9FC03, 0xF2F811F9, 0xF90A0602);
	r0 = D(r0, s[1][1][0], 0x15090DF8, 0x06FD1401, 0xF5E6400C, 0xF3EF2602);
	r1 = D(r1, s[1][1][0], 0x200AF30F, 0xFAEF0A06, 0x00F00108, 0x1D06FBF9);
	r0 = D(r0, s[1][1][1], 0xF5B61412, 0xEC4EF20B, 0xE87F0CF1, 0xDFE808EF);
	r1 = D(r1, s[1][1][1], 0xDF180601, 0x0BF83404, 0xF53314FD, 0x3E0B1623);
	r0 = D(r0, s[1][1][2], 0xF90FFE01, 0x001EFEE8, 0x81E95AFD, 0xD11A0E31);
	r1 = D(r1, s[1][1][2], 0xFFF30607, 0xFE0B0739, 0x0003FA1B, 0x0A1300E0);
	r0 = D(r0, s[1][2][0], 0x0BF605FA, 0x04FFFCFF, 0xE3E0FB06, 0x05FD0E00);
	r1 = D(r1, s[1][2][0], 0x13DD13FE, 0x01060004, 0x02FC0307, 0x09F00201);
	r0 = D(r0, s[1][2][1], 0xF605100A, 0x0BFB0900, 0x3039EECA, 0xFDFB0DF5);
	r1 = D(r1, s[1][2][1], 0xF310193F, 0x00FBFFFA, 0x0CE617FF, 0x08ED0F14);
	r0 = D(r0, s[1][2][2], 0xFC051106, 0x0100F714, 0x03C21CE9, 0x120E08F2);
	r1 = D(r1, s[1][2][2], 0xF80307FC, 0xFE00F5FF, 0xFE04F720, 0xFDFC0408);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(3.284e-02, 2.094e-02, 7.449e-02, 4.700e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(3.308e-02, 1.886e-02, 2.533e-02, -7.171e-03);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
}

//!DESC CuNNy-4x8-BILINEAR-TEST-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv4
//!BIND LUMA
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#ifdef GL_EXT_shader_explicit_arithmetic_types_float16
#	define V4 f16vec4
#	define M4 f16mat4
#	define F float16_t
#else
#	define V4 vec4
#	define M4 mat4
#	define F float
#endif
#define l0(x, y) V4(conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0)) + vec2(0.5)) * conv4_pt))
#define l1(x, y) V4(conv4_tex((vec2(clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0)) + vec2(0.5)) * conv4_pt))
shared V4 g[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	#pragma optionNV(unroll all)
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		#pragma optionNV(unroll all)
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			g[0][ay][ax] = l0(x - 1, y - 1);
			g[1][ay][ax] = l1(x - 1, y - 1);
		}
	}
	barrier();
	V4 s[3][3][1];
	V4 r0 = V4(0.0);
	s[0][0][0] = g[0][xy.y+0][xy.x+0];
	s[0][1][0] = g[0][xy.y+0][xy.x+1];
	s[0][2][0] = g[0][xy.y+0][xy.x+2];
	s[1][0][0] = g[0][xy.y+1][xy.x+0];
	s[1][1][0] = g[0][xy.y+1][xy.x+1];
	s[1][2][0] = g[0][xy.y+1][xy.x+2];
	s[2][0][0] = g[0][xy.y+2][xy.x+0];
	s[2][1][0] = g[0][xy.y+2][xy.x+1];
	s[2][2][0] = g[0][xy.y+2][xy.x+2];
	r0 += M4(-2.771e-02, -1.089e-02, 1.017e-02, 1.309e-02, 6.580e-02, 1.501e-02, -1.065e-02, -1.996e-02, 3.131e-02, 2.757e-02, -3.357e-02, -1.403e-02, 2.739e-03, 1.897e-03, -1.266e-02, -3.621e-04) * s[0][0][0];
	r0 += M4(-3.967e-02, -3.723e-02, -1.226e-02, -4.339e-03, 6.860e-02, 1.155e-01, -5.998e-03, 1.211e-02, 6.962e-02, 1.776e-02, -1.567e-02, -4.458e-02, -1.040e-02, 2.673e-03, -1.975e-02, -4.321e-02) * s[0][1][0];
	r0 += M4(1.756e-03, -2.749e-02, 1.745e-04, -1.299e-02, -1.214e-02, 1.825e-02, -4.472e-03, 5.499e-03, -1.056e-02, 2.877e-02, -9.878e-03, -5.473e-03, -3.638e-03, -3.162e-02, -3.899e-03, -1.095e-02) * s[0][2][0];
	r0 += M4(9.425e-02, -5.579e-02, -5.166e-02, -6.384e-02, -2.803e-01, -1.593e-02, -3.127e-02, 3.919e-02, -1.685e-01, -1.469e-02, 7.448e-02, 9.253e-02, 3.919e-02, 9.773e-03, 3.134e-02, 8.515e-03) * s[1][0][0];
	r0 += M4(8.032e-02, 3.120e-01, -2.966e-02, 2.277e-02, -3.750e-02, -4.107e-01, 8.604e-02, -6.286e-02, -2.607e-02, -2.549e-01, 1.048e-01, 2.947e-02, 2.217e-01, 2.640e-01, 2.142e-01, 2.510e-01) * s[1][1][0];
	r0 += M4(-1.136e-02, -9.546e-02, 3.374e-02, -4.626e-02, -1.764e-02, 5.725e-02, -2.116e-02, 4.126e-02, -3.510e-02, 7.767e-03, -1.583e-02, 4.431e-02, -2.589e-02, -6.454e-03, -1.155e-02, -6.556e-03) * s[1][2][0];
	r0 += M4(8.499e-03, -4.654e-02, 1.452e-01, -4.074e-02, 6.140e-02, 2.644e-02, -8.374e-02, 2.847e-02, 6.558e-02, 1.265e-01, -7.823e-02, 4.577e-02, -5.688e-03, 8.702e-04, 6.653e-03, -3.570e-03) * s[2][0][0];
	r0 += M4(-2.485e-01, -2.104e-02, -1.605e-01, 2.533e-01, 1.641e-02, -4.620e-04, -4.431e-02, -2.304e-01, 1.462e-01, -1.223e-02, 1.176e-01, -1.752e-01, -1.420e-02, -2.088e-02, 4.145e-03, 3.381e-02) * s[2][1][0];
	r0 += M4(7.153e-02, -6.735e-02, 3.095e-02, -1.400e-01, -3.142e-03, 4.215e-02, -6.549e-03, 5.380e-02, -4.001e-02, 3.528e-02, -5.555e-02, 4.653e-02, 7.907e-03, 3.785e-03, -7.129e-03, -1.728e-02) * s[2][2][0];
	s[0][0][0] = g[1][xy.y+0][xy.x+0];
	s[0][1][0] = g[1][xy.y+0][xy.x+1];
	s[0][2][0] = g[1][xy.y+0][xy.x+2];
	s[1][0][0] = g[1][xy.y+1][xy.x+0];
	s[1][1][0] = g[1][xy.y+1][xy.x+1];
	s[1][2][0] = g[1][xy.y+1][xy.x+2];
	s[2][0][0] = g[1][xy.y+2][xy.x+0];
	s[2][1][0] = g[1][xy.y+2][xy.x+1];
	s[2][2][0] = g[1][xy.y+2][xy.x+2];
	r0 += M4(4.505e-02, -2.316e-02, 5.191e-03, -2.753e-02, 3.699e-02, 1.368e-02, -6.763e-02, -1.792e-02, 1.734e-01, 3.896e-02, 3.204e-02, -5.486e-02, -2.737e-02, -2.023e-02, 2.386e-02, 1.443e-02) * s[0][0][0];
	r0 += M4(-3.964e-01, 6.989e-02, 8.469e-02, 1.944e-01, 6.700e-02, 8.145e-02, -4.309e-02, -7.105e-02, 1.685e-01, -2.557e-02, 6.272e-02, 5.380e-02, -1.548e-01, -1.014e-01, 7.690e-02, 3.919e-02) * s[0][1][0];
	r0 += M4(6.274e-02, 9.913e-03, -2.229e-03, 1.204e-01, 1.535e-02, -5.627e-03, 9.675e-03, -6.031e-03, -3.977e-02, 2.729e-02, -1.121e-02, -4.782e-02, -1.476e-03, -2.838e-02, -1.263e-02, 3.650e-02) * s[0][2][0];
	r0 += M4(-3.914e-02, -1.547e-02, 3.058e-02, -1.776e-02, -1.153e-01, 5.900e-02, 9.692e-02, 8.368e-02, 1.589e-01, 4.825e-02, -9.497e-02, 3.623e-02, 1.539e-01, 1.552e-02, 4.350e-02, -1.454e-02) * s[1][0][0];
	r0 += M4(1.783e-01, 1.431e-01, -2.155e-01, 1.257e-01, -5.212e-02, -5.231e-01, 2.212e-01, -3.423e-03, 1.856e-01, 8.947e-02, -9.575e-02, -5.920e-01, -2.522e-01, 6.585e-02, -6.540e-01, -2.714e-01) * s[1][1][0];
	r0 += M4(-7.627e-03, 1.023e-01, 7.103e-02, 5.949e-02, -6.324e-02, 9.982e-03, -3.114e-02, 5.573e-02, -1.326e-02, 8.965e-02, -5.362e-02, 6.523e-02, 1.023e-01, 1.905e-02, 8.348e-02, -1.558e-01) * s[1][2][0];
	r0 += M4(4.726e-03, -9.132e-04, -6.360e-03, -2.412e-03, 1.168e-03, -6.023e-02, 1.546e-01, 2.691e-02, -3.406e-02, -1.065e-02, 2.061e-02, -2.699e-02, -3.218e-03, -4.020e-04, 3.402e-02, -5.754e-03) * s[2][0][0];
	r0 += M4(-1.683e-02, 1.353e-03, 3.597e-02, -3.248e-03, 2.548e-02, 4.256e-02, 1.558e-01, 5.452e-02, -4.259e-02, -3.461e-02, 4.517e-02, 1.320e-01, -1.418e-03, -8.084e-03, 7.397e-02, 1.111e-01) * s[2][1][0];
	r0 += M4(1.905e-03, -3.807e-03, -1.339e-02, -1.982e-03, -2.020e-02, -5.945e-02, -2.388e-02, 3.386e-02, -4.585e-03, -2.673e-02, -1.780e-02, -4.406e-02, -1.467e-02, -1.786e-02, 1.226e-02, 4.043e-02) * s[2][2][0];
	r0 += V4(-4.965e-09, -1.013e-08, 1.007e-09, -3.938e-09);
	r0 = tanh(r0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + LUMA_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + LUMA_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + LUMA_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + LUMA_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

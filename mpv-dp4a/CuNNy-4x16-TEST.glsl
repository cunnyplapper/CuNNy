// CuNNy 4x16 BILINEAR TEST
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


//!DESC CuNNy-4x16-BILINEAR-TEST-in
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND LUMA
//!SAVE in
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
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
		}
	}
	barrier();
	F s[3][3][1];
	V4 r0 = V4(0.0);
	V4 r1 = V4(0.0);
	V4 r2 = V4(0.0);
	V4 r3 = V4(0.0);
	s[0][0][0] = g[0][xy.y+0][xy.x+0];
	s[0][1][0] = g[0][xy.y+0][xy.x+1];
	s[0][2][0] = g[0][xy.y+0][xy.x+2];
	s[1][0][0] = g[0][xy.y+1][xy.x+0];
	s[1][1][0] = g[0][xy.y+1][xy.x+1];
	s[1][2][0] = g[0][xy.y+1][xy.x+2];
	s[2][0][0] = g[0][xy.y+2][xy.x+0];
	s[2][1][0] = g[0][xy.y+2][xy.x+1];
	s[2][2][0] = g[0][xy.y+2][xy.x+2];
	r0 += V4(1.770e-02, 1.967e-02, 1.633e-02, 3.886e-02) * s[0][0][0];
	r1 += V4(1.518e-01, -1.285e-01, -1.485e-01, 5.217e-03) * s[0][0][0];
	r2 += V4(2.262e-01, -2.897e-02, 2.383e-02, 4.387e-02) * s[0][0][0];
	r3 += V4(-3.720e-02, -3.290e-02, -3.881e-02, -1.851e-01) * s[0][0][0];
	r0 += V4(-1.636e-01, -2.212e-02, 9.923e-02, 1.431e-01) * s[0][1][0];
	r1 += V4(2.867e-02, -2.524e-02, -7.073e-01, -8.172e-03) * s[0][1][0];
	r2 += V4(3.145e-01, -1.459e-02, 1.606e-02, 8.603e-03) * s[0][1][0];
	r3 += V4(-2.502e-02, -8.618e-02, -1.339e-01, -2.423e-01) * s[0][1][0];
	r0 += V4(1.221e-01, -5.541e-03, -7.377e-02, 1.948e-02) * s[0][2][0];
	r1 += V4(-1.919e-01, 1.275e-02, 1.528e-01, 1.069e-02) * s[0][2][0];
	r2 += V4(1.840e-04, 9.365e-03, 1.323e-02, 8.227e-03) * s[0][2][0];
	r3 += V4(-3.528e-02, -2.127e-01, 1.480e-01, -3.601e-02) * s[0][2][0];
	r0 += V4(-3.865e-01, -3.826e-02, -1.194e-01, 4.014e-01) * s[1][0][0];
	r1 += V4(-3.601e-01, 2.018e-01, 1.182e-01, 3.568e-01) * s[1][0][0];
	r2 += V4(-1.127e-01, 7.746e-02, -2.588e-01, 9.599e-02) * s[1][0][0];
	r3 += V4(5.871e-02, -2.670e-02, 8.610e-02, 6.089e-02) * s[1][0][0];
	r0 += V4(3.929e-01, -4.072e-01, 8.216e-02, -3.697e-01) * s[1][1][0];
	r1 += V4(3.389e-01, 3.020e-01, 2.400e-01, -4.538e-01) * s[1][1][0];
	r2 += V4(-7.655e-03, 1.360e-01, 1.565e-01, -1.598e+00) * s[1][1][0];
	r3 += V4(3.786e-01, 4.189e-01, -7.739e-02, 4.221e-01) * s[1][1][0];
	r0 += V4(3.425e-03, 1.314e-01, 3.566e-01, -4.187e-02) * s[1][2][0];
	r1 += V4(3.494e-02, -4.745e-02, 2.088e-02, -5.762e-03) * s[1][2][0];
	r2 += V4(-6.342e-02, -2.611e-01, -2.312e-02, 4.968e-02) * s[1][2][0];
	r3 += V4(-1.565e-01, -3.564e-01, 2.063e-01, -2.171e-02) * s[1][2][0];
	r0 += V4(7.600e-03, 1.014e-02, 1.032e-01, -2.372e-02) * s[2][0][0];
	r1 += V4(6.090e-02, -9.082e-01, 1.844e-03, 1.022e-01) * s[2][0][0];
	r2 += V4(-2.940e-03, 1.541e-02, -5.193e+00, 1.007e-02) * s[2][0][0];
	r3 += V4(-1.907e-02, 2.953e-03, -4.086e-02, 5.539e-04) * s[2][0][0];
	r0 += V4(1.660e-02, 3.278e-03, -3.373e-01, -2.104e-01) * s[2][1][0];
	r1 += V4(-6.159e-02, -3.088e-01, -1.062e-01, 1.171e-03) * s[2][1][0];
	r2 += V4(4.451e-02, 8.384e-02, 1.197e-01, 1.463e-01) * s[2][1][0];
	r3 += V4(-3.125e-01, -5.571e-02, -3.357e-02, -7.784e-03) * s[2][1][0];
	r0 += V4(-1.542e-02, 3.095e-01, -1.364e-01, 3.353e-02) * s[2][2][0];
	r1 += V4(1.062e-03, -1.001e-02, 2.018e-02, -1.241e-02) * s[2][2][0];
	r2 += V4(1.045e-02, -9.900e-03, -8.616e-02, 3.933e-02) * s[2][2][0];
	r3 += V4(1.615e-01, -2.927e-03, -1.124e-01, 8.995e-03) * s[2][2][0];
	r0 += V4(-1.485e-02, -2.254e-03, -9.773e-03, -6.193e-03);
	r0 = max(r0, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(-3.473e-03, -8.180e-04, 5.621e-03, -2.159e-03);
	r1 = max(r1, V4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
	r2 += V4(-1.007e-02, 2.771e-02, 3.417e-02, 4.846e-02);
	r2 = max(r2, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r2));
	r3 += V4(5.516e-04, 3.206e-04, 1.776e-02, 1.581e-02);
	r3 = max(r3, V4(0.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r3));
}

//!DESC CuNNy-4x16-BILINEAR-TEST-conv1
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND in
//!BIND LUMA
//!SAVE conv1
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * in_pt;
			r = in_gather(p, 0);
			g = in_gather(p, 1);
			b = in_gather(p, 2);
			a = in_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v1 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v2 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v3 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x15D3071A, 0xFB214BF2, 0x01FC0804, 0x02E6BA02);
	r1 = D(r1, s[0][0][0], 0xF01212E9, 0x16F7DE09, 0x200B19DB, 0x04010304);
	r2 = D(r2, s[0][0][0], 0x140A2300, 0x0AE5E20F, 0x01020001, 0xF632090C);
	r3 = D(r3, s[0][0][0], 0xF8DA3E05, 0xF709CFF8, 0x2107EAF8, 0x1DFBD5E8);
	r0 = D(r0, s[0][0][1], 0x32FCE540, 0xE73511E7, 0xDD00F000, 0x0B39FC03);
	r1 = D(r1, s[0][0][1], 0xF9FAE714, 0x2F070F07, 0xEE31C427, 0x0D340DF1);
	r2 = D(r2, s[0][0][1], 0x24E420E7, 0x1ACAE6FA, 0x1BFBF509, 0x2122F3F6);
	r3 = D(r3, s[0][0][1], 0xE6F21717, 0xF3FAFE1C, 0xFBE1BB14, 0x04DA1027);
	r0 = D(r0, s[0][0][2], 0x4DF0EC23, 0x05F90B0B, 0xF8030BED, 0x0E090201);
	r1 = D(r1, s[0][0][2], 0xDBE5DCD7, 0x13120BF8, 0x161EFF25, 0x0CDEF6F9);
	r2 = D(r2, s[0][0][2], 0x021608F2, 0xCB070910, 0x02F8FBF5, 0xF4F2FD05);
	r3 = D(r3, s[0][0][2], 0xF9080D0D, 0x080CF6F0, 0x0F09F014, 0xDFEE061D);
	r0 = D(r0, s[0][1][0], 0x10DAF8F9, 0x0229DAF9, 0x061E0E03, 0xFADFEAF7);
	r1 = D(r1, s[0][1][0], 0x08F8FD0B, 0x0414E724, 0x08192E07, 0xFA201BED);
	r2 = D(r2, s[0][1][0], 0x08163115, 0x05ED13C7, 0x00DEEF1D, 0x001B030E);
	r3 = D(r3, s[0][1][0], 0x2F1C29BA, 0x0FF19142, 0xE92EEF0C, 0x1BCAEA1D);
	r0 = D(r0, s[0][1][1], 0x21E017FD, 0xDAE3B036, 0x13040111, 0x1F05FCD9);
	r1 = D(r1, s[0][1][1], 0x04254F12, 0x23DA1214, 0x34E70914, 0x16FBF602);
	r2 = D(r2, s[0][1][1], 0x1D07FC03, 0xDCE2F5D8, 0x0EDF1B0B, 0xE511F844);
	r3 = D(r3, s[0][1][1], 0xCB07F405, 0x2A16152C, 0xCE18A1F5, 0x15D61FCE);
	r0 = D(r0, s[0][1][2], 0x04E90531, 0x240804F5, 0xF6F4FFDF, 0xE70FEE2B);
	r1 = D(r1, s[0][1][2], 0xBF05F111, 0x1009F615, 0xFE000240, 0x08F408F7);
	r2 = D(r2, s[0][1][2], 0x2A0206FA, 0x0814FC21, 0xD80EF747, 0xF9FB0711);
	r3 = D(r3, s[0][1][2], 0x030200ED, 0x02FDFC16, 0x0B05EFD8, 0x21140545);
	r0 = D(r0, s[0][2][0], 0x07F5F002, 0xF608FB14, 0xFBFA020E, 0xF70710F5);
	r1 = D(r1, s[0][2][0], 0x0909F90A, 0xFEFC0A08, 0xECE3F81A, 0x030A1106);
	r2 = D(r2, s[0][2][0], 0xF2FCFF04, 0xEEFD0D1C, 0xFBF1EAFE, 0xFEF91000);
	r3 = D(r3, s[0][2][0], 0xF305FB20, 0x0305D0DF, 0xF113FA1F, 0x08DB07DE);
	r0 = D(r0, s[0][2][1], 0x1AFDF709, 0x01F7FFEC, 0x090BF106, 0xF0EDF40A);
	r1 = D(r1, s[0][2][1], 0x0AF1FFE2, 0x06FFF40C, 0xFCEFFCEA, 0xEA0FF8E6);
	r2 = D(r2, s[0][2][1], 0x200E08F1, 0xE5070412, 0x0CF5040A, 0x0606FAEF);
	r3 = D(r3, s[0][2][1], 0x01EF0BBD, 0x2B012B32, 0x14F6F701, 0xBF1AF5DD);
	r0 = D(r0, s[0][2][2], 0x0C010B18, 0xFD06F911, 0x02FA03FE, 0xE6FE0C1E);
	r1 = D(r1, s[0][2][2], 0x16FE0D0B, 0x07FA0B16, 0xED0DFF1C, 0xF0F50303);
	r2 = D(r2, s[0][2][2], 0x08FB0715, 0x07121024, 0x03F9F1D3, 0xFB04000C);
	r3 = D(r3, s[0][2][2], 0x100101F5, 0xFF0806FC, 0x06130523, 0x13FC09C0);
	r0 = D(r0, s[1][0][0], 0xDB0AF7FF, 0x0BFBEB08, 0xF8FB0301, 0xF704F704);
	r1 = D(r1, s[1][0][0], 0x2301250F, 0xD911FDF3, 0xF2F02122, 0x0FFB0E0E);
	r2 = D(r2, s[1][0][0], 0x1714F4E9, 0x1429D8F9, 0x1209F108, 0x0506D4F1);
	r3 = D(r3, s[1][0][0], 0x102EEDE5, 0xFDF90A0D, 0xFDEB3D09, 0xFACD30B8);
	r0 = D(r0, s[1][0][1], 0xB6E72A08, 0x3E088107, 0x0BE5D122, 0x03EF4203);
	r1 = D(r1, s[1][0][1], 0xED061D0F, 0xCDF20C07, 0xFE5A2516, 0xE7FC34FC);
	r2 = D(r2, s[1][0][1], 0xFC0A25E5, 0xCAEA5C19, 0xF9FC290F, 0x39057EE4);
	r3 = D(r3, s[1][0][1], 0xF7F70C0B, 0xFEFD08FD, 0xEAFD0212, 0x8128CEF6);
	r0 = D(r0, s[1][0][2], 0xC5DF1806, 0x06F102E9, 0x050AFEFC, 0xF5102705);
	r1 = D(r1, s[1][0][2], 0xE91FC8ED, 0xEF0036FC, 0xF3032D0A, 0xE808F8F4);
	r2 = D(r2, s[1][0][2], 0x010939F3, 0x81FFFE0F, 0xF7FFDAFF, 0xFCF6F900);
	r3 = D(r3, s[1][0][2], 0xEFFD42FE, 0x140820FB, 0xDEF981FB, 0xFE01A6FE);
	r0 = D(r0, s[1][1][0], 0x01D1D0EA, 0xE3DC2704, 0xF01B18F4, 0x15070606);
	r1 = D(r1, s[1][1][0], 0xB604E11D, 0xDCF504FC, 0xFE1D191B, 0x1BFAF703);
	r2 = D(r2, s[1][1][0], 0xF820D2E1, 0x14F8C4F1, 0xE50A0E12, 0xF1F32608);
	r3 = D(r3, s[1][1][0], 0xF5FCA602, 0xADED172B, 0x17F7E506, 0xAC430CFD);
	r0 = D(r0, s[1][1][1], 0x292911C4, 0xDCE4270C, 0x4B1E261F, 0xF9E4EF07);
	r1 = D(r1, s[1][1][1], 0x13F8160D, 0xD9FC33F4, 0x1E16E9F3, 0xEDC128DC);
	r2 = D(r2, s[1][1][1], 0x27DF32FA, 0xC318FD23, 0x1AEDF706, 0x2CEB2DF6);
	r3 = D(r3, s[1][1][1], 0xC4012721, 0xD903D2DD, 0xD3121B10, 0xEDDF2F00);
	r0 = D(r0, s[1][1][2], 0xEAFD40D4, 0x07DBF8FD, 0x0A233FF8, 0xD005B42E);
	r1 = D(r1, s[1][1][2], 0x8119183F, 0xE5EE1BF2, 0xEFE8201C, 0xF80DE5F9);
	r2 = D(r2, s[1][1][2], 0x1309EDF9, 0x86FD4C04, 0xEEF8081A, 0x10D7EE05);
	r3 = D(r3, s[1][1][2], 0x21132B09, 0xE4F3CAFD, 0x17F013E8, 0xFB19263B);
	r0 = D(r0, s[1][2][0], 0xF9F0EEFC, 0xFFEBFCDA, 0x07F203F1, 0x03F4080C);
	r1 = D(r1, s[1][2][0], 0xF00800F5, 0xFED7F4E9, 0x00F2FEEA, 0xFE0E0218);
	r2 = D(r2, s[1][2][0], 0x0B07FDFA, 0x010110F9, 0x1BF000F2, 0x090EF8F8);
	r3 = D(r3, s[1][2][0], 0xF021E905, 0x0B810E0A, 0x13F703EC, 0x0AF80E06);
	r0 = D(r0, s[1][2][1], 0xE01823F4, 0xF01101FC, 0xF810FE06, 0x07381807);
	r1 = D(r1, s[1][2][1], 0xFFE614F4, 0xD71901EC, 0x074CF219, 0x193AFE01);
	r2 = D(r2, s[1][2][1], 0x24EAFB02, 0xFB38E314, 0xFFE1EF21, 0x0919061C);
	r3 = D(r3, s[1][2][1], 0xFB07F800, 0x06FFEFE6, 0x0936E8E9, 0xC6F9EE4D);
	r0 = D(r0, s[1][2][2], 0xFF18F8DF, 0xF81004F7, 0xFB03FAE5, 0x0C0DF711);
	r1 = D(r1, s[1][2][2], 0x2C13F620, 0x010010FC, 0x152118E4, 0xF90FF4E5);
	r2 = D(r2, s[1][2][2], 0x0AF9F40B, 0xF7E9F5EA, 0x06140DFE, 0xF1EE01EB);
	r3 = D(r3, s[1][2][2], 0xF3D70BFF, 0x032F0AF8, 0xF12EF6F0, 0x0E042504);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x030A0419, 0x1D112905, 0xFFF4E100, 0xE9F306FB);
	r1 = D(r1, s[0][0][0], 0x06EE09F7, 0x05022F0A, 0x0DEED1F2, 0x0801FA0E);
	r2 = D(r2, s[0][0][0], 0x01F2FEF1, 0x0004F100, 0xF008F200, 0xDB141105);
	r3 = D(r3, s[0][0][0], 0x12181C0C, 0x2DEA1808, 0xFFE30800, 0xBF52F209);
	r0 = D(r0, s[0][0][1], 0xFCED080F, 0x2F03E1F7, 0x1B2807E7, 0xE00815FF);
	r1 = D(r1, s[0][0][1], 0x1031EC00, 0x095605F1, 0x282CDC06, 0xFAC8F8F4);
	r2 = D(r2, s[0][0][1], 0x00FC1702, 0x0C051027, 0x03C509F5, 0x28CF21F1);
	r3 = D(r3, s[0][0][1], 0x1D38ED05, 0x01160A12, 0xCE031900, 0xFDF404F8);
	r0 = D(r0, s[0][0][2], 0x060C19FD, 0x2881ED17, 0x017FFF17, 0xD664F7FD);
	r1 = D(r1, s[0][0][2], 0xE0EFF6FD, 0x0EF3130C, 0x2A7FC1EA, 0xE2AE11F4);
	r2 = D(r2, s[0][0][2], 0x0E0C14F4, 0xD826FA14, 0xF8D7F70A, 0x221105FB);
	r3 = D(r3, s[0][0][2], 0x1181FB0E, 0x0DCD08F1, 0x1F121FFD, 0x080AE4E6);
	r0 = D(r0, s[0][1][0], 0x22F7F7F0, 0xD5FB0FFE, 0x1807FD0A, 0x0D0C2006);
	r1 = D(r1, s[0][1][0], 0x0D1D190D, 0xF7F03410, 0x19FCED02, 0xE9ECCBF5);
	r2 = D(r2, s[0][1][0], 0x1C15E0D1, 0x09F416FE, 0x0FE921FD, 0xEADB0D26);
	r3 = D(r3, s[0][1][0], 0xDC23F015, 0xE6F11B08, 0x1CF2F8DA, 0xFAF925FA);
	r0 = D(r0, s[0][1][1], 0x0FD2F016, 0xC1F626E3, 0xE800140B, 0x4DF90816);
	r1 = D(r1, s[0][1][1], 0xD0F1E0F1, 0x08C9F8D7, 0x2E1529F6, 0xE22E1D02);
	r2 = D(r2, s[0][1][1], 0xF30F040E, 0x2217E8F7, 0x20EB0DF4, 0xE134FAE9);
	r3 = D(r3, s[0][1][1], 0xECDEDAF0, 0xE31AFDE9, 0xB5ED010C, 0x1F151129);
	r0 = D(r0, s[0][1][2], 0x0C000EE3, 0x0FC300E1, 0xD8F6FC31, 0x095CF915);
	r1 = D(r1, s[0][1][2], 0xD554D118, 0x0E050CD5, 0x253911E6, 0xF62A110B);
	r2 = D(r2, s[0][1][2], 0x03F705F1, 0xE62AF10C, 0xE013F82F, 0xFF1406E5);
	r3 = D(r3, s[0][1][2], 0x0C2105F9, 0xF5F606F3, 0x2D3A08F6, 0x27120A0B);
	r0 = D(r0, s[0][2][0], 0x00061002, 0xF2020918, 0x00F8070E, 0xF207E806);
	r1 = D(r1, s[0][2][0], 0x1CEF1D0F, 0xF60A1C1F, 0x13FE050E, 0x01F417FF);
	r2 = D(r2, s[0][2][0], 0xEA00DEF4, 0xE30AFCF7, 0x09F9E103, 0x0C04F429);
	r3 = D(r3, s[0][2][0], 0x13F2F8E3, 0x13091F2B, 0x10FBFCF4, 0xEE04F711);
	r0 = D(r0, s[0][2][1], 0xFAF903F1, 0xE8FBF61E, 0xEDF9FD1A, 0x262610B2);
	r1 = D(r1, s[0][2][1], 0x21D101F7, 0x07F4F719, 0x0518E0F5, 0x0043FC0B);
	r2 = D(r2, s[0][2][1], 0x1915E338, 0xFFE315CA, 0x070108E2, 0x052B06F8);
	r3 = D(r3, s[0][2][1], 0xB3FF0AF6, 0x0616F005, 0xFB0E0532, 0x0AEAD0EF);
	r0 = D(r0, s[0][2][2], 0x0717F303, 0x1B27F6F9, 0x0D030520, 0x01FC11DE);
	r1 = D(r1, s[0][2][2], 0x1159D8FE, 0xFAFD0100, 0x1113EFE7, 0x0A2DF102);
	r2 = D(r2, s[0][2][2], 0xFE0C0A26, 0xF8FA10FC, 0xF0FFF9E5, 0x08D2FCFD);
	r3 = D(r3, s[0][2][2], 0x00ED0009, 0x0C2507E5, 0x0505F70D, 0xE7F013EE);
	r0 = D(r0, s[1][0][0], 0x25071D3B, 0x030A04F0, 0xFFFBE5E3, 0x04E9EBF7);
	r1 = D(r1, s[1][0][0], 0xF9FC1D08, 0xFCFB28D8, 0x0F06E5E7, 0x16060228);
	r2 = D(r2, s[1][0][0], 0xDF00050B, 0xF81E0CEF, 0xFEF6F90B, 0x030510FC);
	r3 = D(r3, s[1][0][0], 0xE709D507, 0x16FAFD08, 0x14FADEF4, 0x0B1D33B5);
	r0 = D(r0, s[1][0][1], 0x1CDE0F17, 0x14EBB8E9, 0x0CF13F10, 0x090A1BE0);
	r1 = D(r1, s[1][0][1], 0xE00A4F37, 0x1AF3E9E5, 0xD8C1342E, 0xF31ADEF1);
	r2 = D(r2, s[1][0][1], 0xF30B07DD, 0x05F5D1ED, 0xF0F61402, 0xFC1FCBC2);
	r3 = D(r3, s[1][0][1], 0x15E9EE0B, 0xFC0503DB, 0x0BE1F4E8, 0x01180426);
	r0 = D(r0, s[1][0][2], 0xFDEF0BDC, 0x0C000A05, 0x05070210, 0xFDF4FFEB);
	r1 = D(r1, s[1][0][2], 0xFF1E0DC5, 0xFFFB0300, 0xCDEF18FF, 0xEFF405F2);
	r2 = D(r2, s[1][0][2], 0x01F7F1FD, 0x2710F810, 0x1602E6EE, 0x06F5FFFF);
	r3 = D(r3, s[1][0][2], 0x05F8FFFD, 0x02FAFDF5, 0xFB00F603, 0xE221D62E);
	r0 = D(r0, s[1][1][0], 0xD80BF316, 0x1BF6E4FC, 0xF20642FA, 0xF61C54EB);
	r1 = D(r1, s[1][1][0], 0x1609D71D, 0x170DE00B, 0xE5FA2810, 0x0704EE0D);
	r2 = D(r2, s[1][1][0], 0xCD1D0209, 0x450AB3F4, 0xFCE5ED2F, 0x29CE2223);
	r3 = D(r3, s[1][1][0], 0x0103DEE3, 0x3D181B3E, 0xF4138103, 0x0EDE812C);
	r0 = D(r0, s[1][1][1], 0x2704E8E4, 0x1CEB31E1, 0x00FB0C05, 0x0AE68F24);
	r1 = D(r1, s[1][1][1], 0x041EF3E8, 0x1EDEF3F8, 0x05D9BE1D, 0x24FC16E8);
	r2 = D(r2, s[1][1][1], 0x11F01910, 0xF6EAF9C0, 0x01FBAA07, 0x110303EA);
	r3 = D(r3, s[1][1][1], 0x290016D0, 0xCE12FD0A, 0x05ED1E0B, 0xC5C69315);
	r0 = D(r0, s[1][1][2], 0x1C2F12ED, 0x19FD0118, 0x0707FBF7, 0xE8FFFD12);
	r1 = D(r1, s[1][1][2], 0xCFFC2C00, 0xD3FAF914, 0x0AEEF30C, 0x071802FD);
	r2 = D(r2, s[1][1][2], 0xE8F90600, 0x070216EF, 0x21EF0E0A, 0x00120003);
	r3 = D(r3, s[1][1][2], 0x07ED03E0, 0xF6010EF1, 0x0B0E0408, 0x15CCF2D8);
	r0 = D(r0, s[1][2][0], 0xEBFA24FB, 0x10F126FE, 0x0CF40004, 0x0B0D5BE8);
	r1 = D(r1, s[1][2][0], 0xFDBDAB15, 0xFEFD05FC, 0xF8FF2A0E, 0x1304301E);
	r2 = D(r2, s[1][2][0], 0xE91213FA, 0x0C03091D, 0xE9FF16ED, 0x18FFF11F);
	r3 = D(r3, s[1][2][0], 0x1D29B004, 0xC2D6F4F9, 0xE508F50B, 0xFCF73D15);
	r0 = D(r0, s[1][2][1], 0x19F402F2, 0x3216F0F8, 0xFB172A04, 0xE20E07F5);
	r1 = D(r1, s[1][2][1], 0x4E140311, 0x2EFE120B, 0xE4DD061A, 0x420E1FEF);
	r2 = D(r2, s[1][2][1], 0x0A050BF7, 0x08FF0B19, 0x2B14390E, 0x3BECFCF6);
	r3 = D(r3, s[1][2][1], 0x31EE1E00, 0xA5E8F4FB, 0xD3F1DAFB, 0xF71625E2);
	r0 = D(r0, s[1][2][2], 0xE9FE0EFC, 0x29F7150B, 0x0AFA0603, 0xF905EFFF);
	r1 = D(r1, s[1][2][2], 0xC7F116F0, 0x1304FD04, 0xDAF53A25, 0x260903FC);
	r2 = D(r2, s[1][2][2], 0xFF07EB06, 0x07EFFB07, 0x3105FA01, 0x05FD0207);
	r3 = D(r3, s[1][2][2], 0xF70FF601, 0xDB00FF00, 0xECFFFC06, 0x281414E9);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(5.775e-03, -3.511e-02, -1.509e-01, 7.100e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-2.369e-02, 1.692e-02, 3.847e-02, -2.716e-02);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(2.765e-02, 1.853e-02, 7.593e-02, -1.457e-02);
	f2 = max(f2, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 1), f2);
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(-1.652e-02, 2.261e-03, 2.661e-02, 1.254e-03);
	f3 = max(f3, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 1), f3);
}

//!DESC CuNNy-4x16-BILINEAR-TEST-conv2
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv1
//!BIND LUMA
//!SAVE conv2
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv1_pt;
			r = conv1_gather(p, 0);
			g = conv1_gather(p, 1);
			b = conv1_gather(p, 2);
			a = conv1_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v1 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v2 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v3 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x00FAD7E6, 0xF9FD1A0E, 0x190806FA, 0x13FCF3EB);
	r1 = D(r1, s[0][0][0], 0xF3F9E630, 0x04FF1205, 0x0B0715F4, 0x01F8F2FE);
	r2 = D(r2, s[0][0][0], 0xE6060412, 0x0013ECFD, 0xFC1DFD00, 0x0FEFF407);
	r3 = D(r3, s[0][0][0], 0xF9FE07FE, 0xFAF90CF6, 0xE5FC0DFE, 0x0B000C02);
	r0 = D(r0, s[0][0][1], 0x1B14CDCA, 0xDC07FF12, 0xEC0906F9, 0xE80EE2FB);
	r1 = D(r1, s[0][0][1], 0x15F111F9, 0x0A0AFE0F, 0x280D0F17, 0x0D000104);
	r2 = D(r2, s[0][0][1], 0x0AFEF016, 0xF50933FD, 0xF7FDFD04, 0x0A17F0EF);
	r3 = D(r3, s[0][0][1], 0x04FFFF03, 0xEFFEFB1D, 0xEE08EB16, 0x09FE020C);
	r0 = D(r0, s[0][0][2], 0x0705D0F2, 0x070608F9, 0x0704141C, 0x0B0605FE);
	r1 = D(r1, s[0][0][2], 0xF9F807FB, 0x0AFF07F5, 0xFAF80B13, 0xFBFBFE03);
	r2 = D(r2, s[0][0][2], 0x190D0CEF, 0x030BF723, 0xF10A0601, 0xF7E5F40E);
	r3 = D(r3, s[0][0][2], 0xF806FB02, 0x06E0F8EF, 0x060917FB, 0xF6FF03F6);
	r0 = D(r0, s[0][1][0], 0x01FAF6E2, 0x010AFDEF, 0x0004F70E, 0xFFFD02ED);
	r1 = D(r1, s[0][1][0], 0x052811EA, 0xDC02240E, 0xD9F5022D, 0xFBFDF4F8);
	r2 = D(r2, s[0][1][0], 0x150DDE04, 0x09F90F05, 0xFC20FA0B, 0x0606FEE6);
	r3 = D(r3, s[0][1][0], 0xEC07F803, 0xFF1315D8, 0xF1090909, 0x15FAF408);
	r0 = D(r0, s[0][1][1], 0xF5EC000B, 0x5CFC2415, 0x0EF0E0EB, 0xE3011105);
	r1 = D(r1, s[0][1][1], 0x05F6301E, 0x0D07DCF4, 0xDF15FBF7, 0x300BCE09);
	r2 = D(r2, s[0][1][1], 0x4AF08131, 0x0810D70D, 0x1F221510, 0x9CF1EE07);
	r3 = D(r3, s[0][1][1], 0xEDF302F1, 0xD11E01FB, 0x2D140517, 0x0C062A13);
	r0 = D(r0, s[0][1][2], 0x0105C0FD, 0xE60F07F5, 0xF9EF1204, 0x03FDE0F3);
	r1 = D(r1, s[0][1][2], 0x141716F2, 0x0BF002F9, 0x05FB0908, 0xFFFEE1FB);
	r2 = D(r2, s[0][1][2], 0x17E6FE1D, 0x1BE7F7F0, 0xF80201F9, 0xE61FF24D);
	r3 = D(r3, s[0][1][2], 0xF910FF04, 0x11ED150B, 0x1AEB17FF, 0xF4F61509);
	r0 = D(r0, s[0][2][0], 0x18FFFCC7, 0x06F9F809, 0x08FEF5CF, 0xFEFBE21E);
	r1 = D(r1, s[0][2][0], 0xEBF8E2CD, 0x06EA14E8, 0xF610E0E9, 0xFF06E712);
	r2 = D(r2, s[0][2][0], 0xE718E60E, 0x03F4F303, 0x080705E8, 0x0805E2F7);
	r3 = D(r3, s[0][2][0], 0x1802FDFE, 0xF40409E5, 0x02FDFAEB, 0x04FB06ED);
	r0 = D(r0, s[0][2][1], 0xF00510F7, 0xEBF414FA, 0xF1FAE906, 0x08FCF6F2);
	r1 = D(r1, s[0][2][1], 0xDB03FD19, 0xF1141F03, 0xFCEFC11A, 0xF7F6180A);
	r2 = D(r2, s[0][2][1], 0xCD0E81F4, 0x13E904F2, 0xFA33F30D, 0xEDF7F2DB);
	r3 = D(r3, s[0][2][1], 0x07F3FA2E, 0x06FB4306, 0x06EE0AE4, 0x020ED9FF);
	r0 = D(r0, s[0][2][2], 0xF5FFFBC4, 0xED021A0C, 0xF215E5FB, 0x0B05F502);
	r1 = D(r1, s[0][2][2], 0x01F50606, 0xFF0E1003, 0x110CF408, 0xF402FA10);
	r2 = D(r2, s[0][2][2], 0xDFECB8E5, 0xFFF70314, 0x090801F4, 0xF6F90A17);
	r3 = D(r3, s[0][2][2], 0x0502F3F4, 0xFE0846FC, 0x00F21517, 0xFEF902E8);
	r0 = D(r0, s[1][0][0], 0xF700120A, 0xF8FAF0ED, 0x1615F02A, 0x0EF20DF8);
	r1 = D(r1, s[1][0][0], 0xFF2B1004, 0xEEFAECFF, 0xEC05F400, 0x0A000ADD);
	r2 = D(r2, s[1][0][0], 0x0F10F2D2, 0x03E41C0E, 0x0CED000C, 0xEE1F0F04);
	r3 = D(r3, s[1][0][0], 0xFF0A0619, 0xEF080E0C, 0xF7F0ECF0, 0xF7080712);
	r0 = D(r0, s[1][0][1], 0x1D124D25, 0x000508F5, 0xF213E1FE, 0x32F40321);
	r1 = D(r1, s[1][0][1], 0xFB1AFE0E, 0xFEFD0CFE, 0xF528F117, 0xF904F202);
	r2 = D(r2, s[1][0][1], 0xEAFA07EE, 0xBE05C514, 0x0605FB12, 0x19283413);
	r3 = D(r3, s[1][0][1], 0x0701FB01, 0x0402FD15, 0xFD08010F, 0xFBEBEE0A);
	r0 = D(r0, s[1][0][2], 0xD8021CFC, 0x0411FAF2, 0x0DFFC60C, 0x030309FC);
	r1 = D(r1, s[1][0][2], 0xF51CF516, 0xFBFCFDFF, 0xED0DD70D, 0x080609F3);
	r2 = D(r2, s[1][0][2], 0xD6130806, 0x1D03F2FD, 0x07F1F405, 0xD7ECF018);
	r3 = D(r3, s[1][0][2], 0x030102FF, 0x0AF0131A, 0xFB13FB07, 0x0B07FA15);
	r0 = D(r0, s[1][1][0], 0xE8F6FE18, 0xF111F200, 0x0202F8FB, 0xF5F5F9EE);
	r1 = D(r1, s[1][1][0], 0x0328FB2E, 0xFE122BFE, 0x1F08EDDE, 0x170CFFDB);
	r2 = D(r2, s[1][1][0], 0x1708F4F5, 0x0EEE1104, 0xFF020108, 0xF8FAF5E3);
	r3 = D(r3, s[1][1][0], 0xF617E021, 0x01100C16, 0xFC0208E6, 0xE5E5FD2C);
	r0 = D(r0, s[1][1][1], 0x251B100E, 0xF41618EF, 0x04FE1C04, 0xE81F200C);
	r1 = D(r1, s[1][1][1], 0xD179FC1B, 0x09FB030C, 0x24110F06, 0x042B190A);
	r2 = D(r2, s[1][1][1], 0xC5FAF104, 0xFB06BC15, 0xF90415F5, 0x2933C50F);
	r3 = D(r3, s[1][1][1], 0x0E14EA01, 0x173CE70C, 0xE73AE60F, 0xF7EDEF00);
	r0 = D(r0, s[1][1][2], 0xFE13041E, 0x2528F9F6, 0xF8F70CFE, 0xE5F7F5FF);
	r1 = D(r1, s[1][1][2], 0xEC2AE8FA, 0x06F1F900, 0xF20006FC, 0x1015E1EF);
	r2 = D(r2, s[1][1][2], 0xF4DBF710, 0xF7E2DCFC, 0xFDF41208, 0xFFE8EA06);
	r3 = D(r3, s[1][1][2], 0xFB0E0E02, 0x96F4F026, 0x11DE0A13, 0x0FEE070F);
	r0 = D(r0, s[1][2][0], 0x06F9F0F1, 0x04051A07, 0x01F604F5, 0xEF06F0FB);
	r1 = D(r1, s[1][2][0], 0x242DEC1B, 0x16ECFA15, 0xE9E321F2, 0xF5F807F0);
	r2 = D(r2, s[1][2][0], 0x3407D8EB, 0xF4F9030D, 0x0BEFF4FF, 0x02D81AF8);
	r3 = D(r3, s[1][2][0], 0xF5F4E8FD, 0xFEE5F913, 0x06F50811, 0x36042220);
	r0 = D(r0, s[1][2][1], 0x0F0CEFF0, 0x00E126FC, 0x120100F2, 0xF70416F8);
	r1 = D(r1, s[1][2][1], 0x1A300E22, 0xF10C3F16, 0xF60D1EF7, 0x06011EF4);
	r2 = D(r2, s[1][2][1], 0x121F09E0, 0xFDE913F9, 0x01F8FB16, 0x392EF714);
	r3 = D(r3, s[1][2][1], 0xF610D409, 0x25FBE6F8, 0xF0F9261C, 0x05E10824);
	r0 = D(r0, s[1][2][2], 0xDE0BEE03, 0xF90AF9E9, 0xE20815EF, 0xF9FFEE00);
	r1 = D(r1, s[1][2][2], 0x0401E408, 0xFCFC0311, 0xF7F01203, 0x1000EFFD);
	r2 = D(r2, s[1][2][2], 0x08DE31F1, 0x0D031807, 0xF600FAFD, 0xEAF50BEB);
	r3 = D(r3, s[1][2][2], 0x0EFB07FF, 0xE90BE70C, 0x1F05D70E, 0xED0F0B0C);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x1DF71506, 0xFB09FEE7, 0xF703F0EB, 0x10FAFCFD);
	r1 = D(r1, s[0][0][0], 0x0FA8E700, 0x01040EF6, 0x0717FDF0, 0x0204FE05);
	r2 = D(r2, s[0][0][0], 0x24F6270C, 0xF2E808FC, 0xFEFA01FD, 0xF101DCFC);
	r3 = D(r3, s[0][0][0], 0xF305080F, 0xF81808F3, 0x0B18F9FC, 0x000D00FD);
	r0 = D(r0, s[0][0][1], 0x1A2512C9, 0x0612190C, 0x170F040B, 0x151CFFD8);
	r1 = D(r1, s[0][0][1], 0xD1EDD81E, 0xF502FD11, 0x191B00DD, 0xFDF4FE04);
	r2 = D(r2, s[0][0][1], 0x0BF500B5, 0x0EDA0033, 0x05080C11, 0xF915FBF3);
	r3 = D(r3, s[0][0][1], 0x010FF802, 0x01FFFA20, 0x09E01409, 0x0DF7FEF9);
	r0 = D(r0, s[0][0][2], 0x30E10A25, 0x05110813, 0x18F511EE, 0x0FE918F5);
	r1 = D(r1, s[0][0][2], 0xF0F8FD27, 0x01F6F9FF, 0x1218FA23, 0xF3F60515);
	r2 = D(r2, s[0][0][2], 0x15FA0206, 0xF000EB19, 0xFCF7FFFA, 0x18FCF9F5);
	r3 = D(r3, s[0][0][2], 0x0504FFFD, 0xE403F10D, 0xFF03FF17, 0x0AF307FF);
	r0 = D(r0, s[0][1][0], 0x12EF0B0D, 0x0DFA1AF3, 0x0F081D00, 0x0FEAF316);
	r1 = D(r1, s[0][1][0], 0xF83C12F3, 0x0826FB02, 0xF31ED3F5, 0x0CF5FDFE);
	r2 = D(r2, s[0][1][0], 0x250707F1, 0xF3F40E0E, 0x06060005, 0xEB2B0701);
	r3 = D(r3, s[0][1][0], 0xF0241606, 0xEB131209, 0xFBECFD07, 0xE8F2FDFB);
	r0 = D(r0, s[0][1][1], 0xEBF31E10, 0xF9162823, 0x3335F8EA, 0x3A11DB08);
	r1 = D(r1, s[0][1][1], 0xED2501B3, 0x121CCAEB, 0xD60100F9, 0x1D4005CA);
	r2 = D(r2, s[0][1][1], 0xFFFD0CA7, 0xC8000EC1, 0x0AD9F811, 0x32FEE80F);
	r3 = D(r3, s[0][1][1], 0xFBFAFF45, 0x15232FEA, 0xF9F9FFF5, 0xF6DE0E3E);
	r0 = D(r0, s[0][1][2], 0x1BFFEA15, 0xEBF61A1A, 0xF1FF1E1E, 0x2304F609);
	r1 = D(r1, s[0][1][2], 0x2D03ECF0, 0x07FDF5FB, 0x121FDF11, 0x1FE60201);
	r2 = D(r2, s[0][1][2], 0xE9FD09E6, 0xF20804E6, 0x0D09EE01, 0x01E4ED1C);
	r3 = D(r3, s[0][1][2], 0xF814F3FD, 0x00A011F3, 0xF4F4F003, 0xFEF80515);
	r0 = D(r0, s[0][2][0], 0x08FD0901, 0x06F1050E, 0x0CE8F7FC, 0x0910D5F9);
	r1 = D(r1, s[0][2][0], 0x09E6F4FC, 0xF9EC092E, 0x0BFDFE03, 0x00FDF9F8);
	r2 = D(r2, s[0][2][0], 0x0DF6D7E5, 0x0AF41103, 0xF8FD00F5, 0xFBFB04E9);
	r3 = D(r3, s[0][2][0], 0x040A0FEE, 0xE5041DEC, 0x01F3FB15, 0xE31706EF);
	r0 = D(r0, s[0][2][1], 0x16D90CF3, 0xF1F816FF, 0x19F0FC16, 0x19F4EDFB);
	r1 = D(r1, s[0][2][1], 0x0C01EC07, 0xF6F20515, 0xF2EDE7EE, 0x18EC0008);
	r2 = D(r2, s[0][2][1], 0x2801200C, 0x100110FF, 0xE5030600, 0x07CEEEF8);
	r3 = D(r3, s[0][2][1], 0x25E8F126, 0xFBFA10F0, 0x20050F04, 0xB1061D06);
	r0 = D(r0, s[0][2][2], 0x1D01FA07, 0x00FD22F6, 0x12021BF9, 0x1200F6FC);
	r1 = D(r1, s[0][2][2], 0x0600D400, 0xF5F8FBFA, 0x0FFDEDEA, 0xF4FF0414);
	r2 = D(r2, s[0][2][2], 0xDAE8311C, 0xF502F007, 0xFC070EFE, 0xE00707D2);
	r3 = D(r3, s[0][2][2], 0x040AF7F8, 0xE523EEDF, 0x07F70710, 0xF00526F6);
	r0 = D(r0, s[1][0][0], 0xF801DDE8, 0xE317030D, 0xF11BFE0E, 0x0605F308);
	r1 = D(r1, s[1][0][0], 0x1D1D0F0C, 0xFA0DF4F2, 0x03E2F40C, 0x0602F905);
	r2 = D(r2, s[1][0][0], 0x0309F011, 0x24070701, 0x04FB00FB, 0x0BE4FF1C);
	r3 = D(r3, s[1][0][0], 0xEFFAF9EF, 0x09EB0EFA, 0xC8FAFBFA, 0xFD26F607);
	r0 = D(r0, s[1][0][1], 0xF9F9EFAE, 0xF3FAE8E0, 0xF50EF22B, 0xF6F110F9);
	r1 = D(r1, s[1][0][1], 0xDF0A0F23, 0x03F6FAE9, 0x10ED222A, 0xF9FC17FD);
	r2 = D(r2, s[1][0][1], 0x21000039, 0xFE531722, 0x03FF0202, 0x0AD406FB);
	r3 = D(r3, s[1][0][1], 0x07050103, 0xFE0F25F1, 0xD500F9EA, 0x1201A604);
	r0 = D(r0, s[1][0][2], 0x12FFB8D2, 0xE8FCE7FA, 0xF015F805, 0x01F3E500);
	r1 = D(r1, s[1][0][2], 0xEEF5F7F2, 0x21070308, 0x27FD0125, 0xFC040F12);
	r2 = D(r2, s[1][0][2], 0x0F04F0FB, 0x0B1602ED, 0x0001FDFF, 0x3CFBFE10);
	r3 = D(r3, s[1][0][2], 0x05FE01FE, 0xEAED1F01, 0xF30DFAF0, 0x0A0EFB0D);
	r0 = D(r0, s[1][1][0], 0xFDF2FB07, 0xE8FEF004, 0xF60102F6, 0x160BF106);
	r1 = D(r1, s[1][1][0], 0x02F1010F, 0xE3E3DFEF, 0x190B0614, 0x1802F602);
	r2 = D(r2, s[1][1][0], 0x0A02E40D, 0xF30205F4, 0x10FC06FE, 0x29F11523);
	r3 = D(r3, s[1][1][0], 0xE8F9F9EC, 0xEEE90FE7, 0xE5060701, 0x1B180902);
	r0 = D(r0, s[1][1][1], 0x06F615F4, 0x17DFE6F6, 0xF0FEFECD, 0xFFC40C25);
	r1 = D(r1, s[1][1][1], 0xEBC0E904, 0x0D02CDFE, 0xFC051D0A, 0x0F000D07);
	r2 = D(r2, s[1][1][1], 0x39E1E881, 0x1B0710E9, 0xFF27E119, 0x08F1EE21);
	r3 = D(r3, s[1][1][1], 0xF126A923, 0x15FEFA02, 0xF91831DE, 0x1227B90B);
	r0 = D(r0, s[1][1][2], 0xF2F1DB06, 0xD51EB21D, 0xF103DCE1, 0xFBE90803);
	r1 = D(r1, s[1][1][2], 0x30E9FA12, 0x21F50804, 0x09F1E924, 0x00FFE919);
	r2 = D(r2, s[1][1][2], 0x1300B0B2, 0x04F813F7, 0x07110B0B, 0x300AF037);
	r3 = D(r3, s[1][1][2], 0xF300F7E5, 0xFC22EB0A, 0x17F8F5D7, 0xFC22F009);
	r0 = D(r0, s[1][2][0], 0x110009FC, 0xD6FAFBFD, 0xF4020B00, 0x04FEFE0E);
	r1 = D(r1, s[1][2][0], 0xF80417FA, 0xE4F0F5F3, 0xFAF8F412, 0xFEF9F70D);
	r2 = D(r2, s[1][2][0], 0x0211FFF4, 0x01FFFEF3, 0x0CF907F4, 0x25ED1306);
	r3 = D(r3, s[1][2][0], 0xF403FC09, 0xFD090AF5, 0xEEE306F0, 0x0F0AFB08);
	r0 = D(r0, s[1][2][1], 0x260809EE, 0xF00F0DEE, 0xFFF304F9, 0xFD011AFC);
	r1 = D(r1, s[1][2][1], 0x1C00FDF2, 0x311006E6, 0x110DF82F, 0x06041106);
	r2 = D(r2, s[1][2][1], 0x3F16E9BE, 0xEFFBFBFB, 0x0A02FC04, 0x45F31AE9);
	r3 = D(r3, s[1][2][1], 0x1207DF13, 0xFCF908D5, 0x020220FF, 0x0A2BE8D6);
	r0 = D(r0, s[1][2][2], 0x05010301, 0xEE19F0F0, 0x0A0513F9, 0xF004F718);
	r1 = D(r1, s[1][2][2], 0x31FD1601, 0x080309E4, 0xEFF3E711, 0x050BF11A);
	r2 = D(r2, s[1][2][2], 0x2C24FFD3, 0xFAFAF601, 0xFCF80108, 0x1607360D);
	r3 = D(r3, s[1][2][2], 0xFAFDF104, 0xF9DCFE0A, 0xF801F6DF, 0x1002F3CC);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(1.107e-02, -4.624e-02, -1.255e-02, 2.100e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(-5.258e-02, -2.243e-02, -3.108e-02, 2.958e-04);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(1.487e-02, 2.663e-02, -3.649e-01, 2.327e-02);
	f2 = max(f2, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 1), f2);
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(-3.731e-02, 3.996e-02, 3.611e-02, -1.003e-02);
	f3 = max(f3, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 1), f3);
}

//!DESC CuNNy-4x16-BILINEAR-TEST-conv3
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv2
//!BIND LUMA
//!SAVE conv3
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv2_pt;
			r = conv2_gather(p, 0);
			g = conv2_gather(p, 1);
			b = conv2_gather(p, 2);
			a = conv2_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v1 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v2 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v3 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x00FBFEF6, 0x0CFDED15, 0x0407E905, 0xFBFC09E4);
	r1 = D(r1, s[0][0][0], 0xFA04F5EA, 0x05000BFC, 0x04FCFAFD, 0x00F7FF03);
	r2 = D(r2, s[0][0][0], 0xF923DAFD, 0xFF0801FB, 0x0202FC0A, 0x03F70EF6);
	r3 = D(r3, s[0][0][0], 0xFF1305FC, 0x03FB0505, 0x0CF6F1C1, 0x03F31101);
	r0 = D(r0, s[0][0][1], 0x07FEF9F8, 0xF01A03F0, 0xF903000E, 0x05E2F90D);
	r1 = D(r1, s[0][0][1], 0xE40DF2F6, 0x0500FAFF, 0x02FA0503, 0xF9FE000A);
	r2 = D(r2, s[0][0][1], 0xF92B0222, 0x04EC00FF, 0x0E03F915, 0xF722FC03);
	r3 = D(r3, s[0][0][1], 0xFA0B1402, 0x01040906, 0x1AC7D6C6, 0x04000E04);
	r0 = D(r0, s[0][0][2], 0xFD0803FF, 0xF8FA2006, 0xFA0E01FD, 0xFC27F8DA);
	r1 = D(r1, s[0][0][2], 0xF3110AFB, 0xFF020203, 0x03FE0302, 0x030E04FA);
	r2 = D(r2, s[0][0][2], 0x0512E0E8, 0x06FDF906, 0x00FFF9FD, 0x09EAF5FC);
	r3 = D(r3, s[0][0][2], 0x06040706, 0x02FCFFFB, 0x00F7E3EC, 0x0BFB01FD);
	r0 = D(r0, s[0][1][0], 0x0201F9F8, 0xDF12F0F5, 0xE10BDFFB, 0xF623D2AF);
	r1 = D(r1, s[0][1][0], 0xFD0EE000, 0x10FB0B0B, 0xFAFA1105, 0x0BFF0B16);
	r2 = D(r2, s[0][1][0], 0x071AF1F0, 0x03F9EFF3, 0x070022FC, 0x0DFB02F1);
	r3 = D(r3, s[0][1][0], 0xFCFFDDEA, 0xF900FBF5, 0x07FF03C3, 0x00EB2815);
	r0 = D(r0, s[0][1][1], 0xFFF2F90D, 0xF9EA8E32, 0xC6D2D301, 0x40C0DAD3);
	r1 = D(r1, s[0][1][1], 0xE9FDEBEA, 0x1CFC1AFD, 0x0602FF08, 0xFFF2E009);
	r2 = D(r2, s[0][1][1], 0xF61005B9, 0xFFFEF4ED, 0x07E8EEDB, 0x3B1112CE);
	r3 = D(r3, s[0][1][1], 0x312AD6F0, 0x25F2F507, 0x21F9EEEC, 0x0E0F05E1);
	r0 = D(r0, s[0][1][2], 0xFB020A04, 0xF910DFEC, 0x000CF9DF, 0xEF160BCC);
	r1 = D(r1, s[0][1][2], 0xDF08E80D, 0x070802EF, 0x05F9F900, 0x0D00F4F7);
	r2 = D(r2, s[0][1][2], 0x00E4F929, 0xFEFB0503, 0x1EEDFC05, 0x1AF1F00A);
	r3 = D(r3, s[0][1][2], 0x010006FD, 0x2001F5FF, 0xFBF114FE, 0x14E90603);
	r0 = D(r0, s[0][2][0], 0x0E05FDFE, 0x0D0CFFDB, 0xFB021401, 0xEF1EDFE5);
	r1 = D(r1, s[0][2][0], 0x07081402, 0x08FD070B, 0x02FB0503, 0x09F9000E);
	r2 = D(r2, s[0][2][0], 0xF1FFA0FA, 0xFAFFFF06, 0x0CFA02F8, 0x0CF200EE);
	r3 = D(r3, s[0][2][0], 0xF80FEBFE, 0xFDFBFE04, 0x06FFF7FA, 0xFDF908FF);
	r0 = D(r0, s[0][2][1], 0xFDF8F8FC, 0xAB1FF4E8, 0x01FEFA04, 0x1CE411EA);
	r1 = D(r1, s[0][2][1], 0xB5F7F31F, 0xF00CF610, 0x02F50BFD, 0x04CDD9D3);
	r2 = D(r2, s[0][2][1], 0x1CF519F1, 0xFD0AF8F2, 0x0B020DFB, 0xFAFF20EB);
	r3 = D(r3, s[0][2][1], 0x03F40A28, 0x0CF70BFF, 0xF21802FE, 0x0E0003FB);
	r0 = D(r0, s[0][2][2], 0x02FD00FC, 0xD524091D, 0x020102EF, 0xECF712EE);
	r1 = D(r1, s[0][2][2], 0xE2E8DC1A, 0xFBF800FB, 0x07F70402, 0x17F5F1C9);
	r2 = D(r2, s[0][2][2], 0x0BC6FC00, 0xFAF9FE0C, 0xF7F807FA, 0xFCF5F5E5);
	r3 = D(r3, s[0][2][2], 0xF8FDFCF1, 0x110C02EE, 0xF8FFF713, 0x06F803FD);
	r0 = D(r0, s[1][0][0], 0xF5FEFB03, 0x10031E00, 0xF7EE0C03, 0x0DF7ECFC);
	r1 = D(r1, s[1][0][0], 0xF10C0306, 0x11070905, 0xFAFF000A, 0x071204F3);
	r2 = D(r2, s[1][0][0], 0x181D02F7, 0xFA020902, 0x08000A09, 0x0600E808);
	r3 = D(r3, s[1][0][0], 0x19F8F30D, 0xFEFE010A, 0xE4E10729, 0x0601F904);
	r0 = D(r0, s[1][0][1], 0xF1090B05, 0x0E0C0B11, 0xE3EB18EC, 0xEB1221FB);
	r1 = D(r1, s[1][0][1], 0x05021504, 0x0BFF08FF, 0xF307FE0C, 0x1DFF0103);
	r2 = D(r2, s[1][0][1], 0xF7FFED1A, 0xEE0202FE, 0xF5FBE406, 0x1E04FD14);
	r3 = D(r3, s[1][0][1], 0x0E140B03, 0x06080018, 0xAF2EF8F9, 0x17FAE303);
	r0 = D(r0, s[1][0][2], 0xFC010504, 0xE6F013EA, 0x04FCFE0B, 0x1A08BF10);
	r1 = D(r1, s[1][0][2], 0xF80B0F0E, 0x05FE0FFE, 0xFDFBFF02, 0x1504FBFE);
	r2 = D(r2, s[1][0][2], 0x1A0CC3F6, 0xFE0200FC, 0xFFFDDDFD, 0x07161818);
	r3 = D(r3, s[1][0][2], 0xF9F8EC09, 0x0C01E3F5, 0xFCFE2608, 0x0405F7FB);
	r0 = D(r0, s[1][1][0], 0xF800F70A, 0x09F52219, 0xDA211516, 0xEB0E19F1);
	r1 = D(r1, s[1][1][0], 0x0B0E0A20, 0x0E03F504, 0x0608FF05, 0x07FD0304);
	r2 = D(r2, s[1][1][0], 0x08D9DB06, 0xF40D0AF7, 0x0F07FD03, 0x1DE4F012);
	r3 = D(r3, s[1][1][0], 0xF2E2F406, 0xFEFE0709, 0x0DEA0309, 0x11FD0004);
	r0 = D(r0, s[1][1][1], 0x92FD06F9, 0x9EFC372B, 0xF52A1219, 0xE5E2F2F8);
	r1 = D(r1, s[1][1][1], 0xEA3406CE, 0xE7000A0B, 0x22F70539, 0xD9F40C1C);
	r2 = D(r2, s[1][1][1], 0xFEF61B0E, 0x31FC00EE, 0xCCEC0219, 0xB9F70AF8);
	r3 = D(r3, s[1][1][1], 0xE8FF21FB, 0xDCF1F520, 0x21E21522, 0xE9DA0B0D);
	r0 = D(r0, s[1][1][2], 0x040DD906, 0x181DF2E5, 0x07FEEE1E, 0x08EF1822);
	r1 = D(r1, s[1][1][2], 0x0013CC11, 0xFEF9FDF8, 0x080AF411, 0x2E0CE0F1);
	r2 = D(r2, s[1][1][2], 0xF529EC06, 0xF8060A00, 0xF6070E06, 0x10FAE9FC);
	r3 = D(r3, s[1][1][2], 0x14F72E16, 0x13030F0C, 0xEF152C18, 0xF8F90CFF);
	r0 = D(r0, s[1][2][0], 0xF801FC0A, 0x0409F2FF, 0xFC0C0402, 0x020B09F3);
	r1 = D(r1, s[1][2][0], 0xF826FF04, 0xFDFCF6FF, 0x01FFFD06, 0x01F8FD02);
	r2 = D(r2, s[1][2][0], 0x0EE0100A, 0xFAFF01FA, 0x19FCF9FB, 0x0D0B0206);
	r3 = D(r3, s[1][2][0], 0xF90904F3, 0xFAFE0300, 0x1117FCF9, 0x08FEFDFC);
	r0 = D(r0, s[1][2][1], 0xF8070D06, 0x018117E9, 0x06FE05F1, 0x03CAE70D);
	r1 = D(r1, s[1][2][1], 0x0E0A13F2, 0x0407FCFD, 0xFDED060E, 0xF5DD052D);
	r2 = D(r2, s[1][2][1], 0xF7BBFC05, 0x0A08FE01, 0xFFE0F3FB, 0x02090501);
	r3 = D(r3, s[1][2][1], 0xF3050303, 0xFCFF0106, 0xFF0601F7, 0xF8F5FF00);
	r0 = D(r0, s[1][2][2], 0xFDFA1202, 0xF4FFF909, 0x000300F9, 0xF60D11FF);
	r1 = D(r1, s[1][2][2], 0x130DF1D5, 0x00F80003, 0xF902050D, 0x07E81409);
	r2 = D(r2, s[1][2][2], 0xF0F61D1E, 0x06FEF905, 0xFFFA0B04, 0x07F7FB08);
	r3 = D(r3, s[1][2][2], 0x09FCF600, 0x02F9F709, 0x11F9F0FD, 0x04F8FDFD);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFF27F905, 0x0B11FB19, 0x0906E60A, 0xEEF6F6F7);
	r1 = D(r1, s[0][0][0], 0xF2FAF504, 0xFC0300E1, 0xFBFD0002, 0xEDF501FF);
	r2 = D(r2, s[0][0][0], 0xFE12FFCE, 0xF2F90403, 0xFD0508EF, 0x06FA07ED);
	r3 = D(r3, s[0][0][0], 0xF00302DB, 0x020601F1, 0x1500EEEA, 0xF81006EF);
	r0 = D(r0, s[0][0][1], 0x023A0B07, 0xDDFE0126, 0x1F2ECB20, 0x1C0D02EF);
	r1 = D(r1, s[0][0][1], 0xF9FDF60D, 0x0DF407F5, 0x0C020410, 0xF5F707E3);
	r2 = D(r2, s[0][0][1], 0x2D1602E4, 0xFA04040C, 0x010CFEE9, 0xFF2719DE);
	r3 = D(r3, s[0][0][1], 0xE5ED1CF0, 0x061809EF, 0xFDE4222D, 0xFC060FFE);
	r0 = D(r0, s[0][0][2], 0x0730FF01, 0xD0E2FD20, 0x0D06FCE5, 0x19F603FB);
	r1 = D(r1, s[0][0][2], 0xF003FBFC, 0x0BF80200, 0x040B03FE, 0xEB11FAF4);
	r2 = D(r2, s[0][0][2], 0xF7FAFED3, 0xFE09FEFE, 0xF8F6FEE9, 0x0D1512DD);
	r3 = D(r3, s[0][0][2], 0xF50C0107, 0xFF0301FB, 0x030B16F2, 0x011208F4);
	r0 = D(r0, s[0][1][0], 0x0346F9F9, 0xC4E30E2E, 0xD807F009, 0x171DE3D9);
	r1 = D(r1, s[0][1][0], 0xFCEFEE12, 0x0F05FEF0, 0xF5FE06FF, 0xFD0407DF);
	r2 = D(r2, s[0][1][0], 0x0FFAF1E8, 0x07F90B0A, 0xF2050FF0, 0x000810D9);
	r3 = D(r3, s[0][1][0], 0x050FECC4, 0xFE03F8FA, 0x23031306, 0xF8CB19FA);
	r0 = D(r0, s[0][1][1], 0xFC7FF201, 0xCD2DCB81, 0xB43FE9EF, 0xFADE20E7);
	r1 = D(r1, s[0][1][1], 0xD5318920, 0x09FD1009, 0xEFE41FF6, 0x18E7E9ED);
	r2 = D(r2, s[0][1][1], 0x299F17E2, 0x02DE141A, 0xF4F317D6, 0x02E8E083);
	r3 = D(r3, s[0][1][1], 0xFACA1CCF, 0x130C0BF5, 0x21C616F4, 0x20BD3B03);
	r0 = D(r0, s[0][1][2], 0x0F40F508, 0xC20AEF38, 0x24F2FCEB, 0x1FF4FB0B);
	r1 = D(r1, s[0][1][2], 0xE7F3DF0A, 0xF9070604, 0x0B160909, 0x272006D7);
	r2 = D(r2, s[0][1][2], 0xE90CFEDB, 0x01080A0A, 0xE10A00EC, 0xF40CFCCB);
	r3 = D(r3, s[0][1][2], 0x130811FE, 0xFEE8FFF3, 0x0011090C, 0xFB120FFA);
	r0 = D(r0, s[0][2][0], 0xFA1AF60D, 0x0FCFFF15, 0x08D9FDF0, 0x28EF0809);
	r1 = D(r1, s[0][2][0], 0xFF00F115, 0x01FBFCEF, 0xFC04F80B, 0xFD08F2FC);
	r2 = D(r2, s[0][2][0], 0xF212E9C3, 0xFF040B00, 0x07FA0210, 0x02F8010C);
	r3 = D(r3, s[0][2][0], 0xDA04FCE6, 0xFB070100, 0xF7FE03FA, 0x0B0DFC09);
	r0 = D(r0, s[0][2][1], 0xF141F3FB, 0x02F3ED15, 0x02E6E404, 0x2024E5EE);
	r1 = D(r1, s[0][2][1], 0xE7F0CEFF, 0xF81403EA, 0x11F6010E, 0xFFF727DE);
	r2 = D(r2, s[0][2][1], 0x26CE0BFF, 0xF4FFF309, 0x09FF12F6, 0x0B151B00);
	r3 = D(r3, s[0][2][1], 0xD210F3C6, 0x040B15FF, 0xEC100300, 0xFC1B0707);
	r0 = D(r0, s[0][2][2], 0x0828F803, 0xE2FCF80D, 0xFBEFF3EE, 0xEEFEF1FA);
	r1 = D(r1, s[0][2][2], 0x00FBDB13, 0x080605FB, 0xF815040F, 0x23E805FF);
	r2 = D(r2, s[0][2][2], 0xE61B00FC, 0xFD0A04FF, 0x020C00F0, 0x08F6F702);
	r3 = D(r3, s[0][2][2], 0xED0909F7, 0xFE01FB08, 0xFDF8F407, 0x07FA05F7);
	r0 = D(r0, s[1][0][0], 0xF5F900FD, 0xF4053EF2, 0x241AC4EB, 0x1806F4ED);
	r1 = D(r1, s[1][0][0], 0x1704F6FC, 0xF8F7FC05, 0xFF09F608, 0xFAFD12FE);
	r2 = D(r2, s[1][0][0], 0xDDDC0312, 0xFC070506, 0xF5F1F7F6, 0xD6E4200B);
	r3 = D(r3, s[1][0][0], 0xE7DD2D04, 0x010802FB, 0xFBFE19F5, 0xEDFF1502);
	r0 = D(r0, s[1][0][1], 0xFBF71AFB, 0x18DE0EDC, 0x2012080C, 0xD505033C);
	r1 = D(r1, s[1][0][1], 0x01060911, 0xFAFE000C, 0xF701F70C, 0x0E001EF8);
	r2 = D(r2, s[1][0][1], 0xDB08F628, 0x0312FB10, 0x0D180811, 0xE0CA17D9);
	r3 = D(r3, s[1][0][1], 0xF0E7F7E4, 0xF3FD03FF, 0xDEFE0818, 0xFFED02EA);
	r0 = D(r0, s[1][0][2], 0xFB01FFFB, 0x06F00EEF, 0x010E0697, 0xECF70C0E);
	r1 = D(r1, s[1][0][2], 0xFD020EEE, 0xFC000106, 0x0400F903, 0xF40AF612);
	r2 = D(r2, s[1][0][2], 0x0B09F7FB, 0xFE0606FC, 0x14FDFEEA, 0x18E10103);
	r3 = D(r3, s[1][0][2], 0x05FBF009, 0x020BF2FC, 0x0B0403EB, 0xFFF2FA02);
	r0 = D(r0, s[1][1][0], 0xF6FB0002, 0xF4D5320E, 0x0C1F10FE, 0x0F0123F8);
	r1 = D(r1, s[1][1][0], 0x080700FA, 0xF6F10C07, 0xFD0703FB, 0x0AFEF0FF);
	r2 = D(r2, s[1][1][0], 0xEFC9DA25, 0xFF0DF501, 0xF8E91C0D, 0xF7ED2BFB);
	r3 = D(r3, s[1][1][0], 0xEEFAE911, 0x04070100, 0xFEF3FD01, 0xFDFD00F9);
	r0 = D(r0, s[1][1][1], 0x040C1309, 0x2AF5F5FD, 0x0DF707ED, 0x98001C33);
	r1 = D(r1, s[1][1][1], 0x43FCF9F4, 0x0AF3F334, 0x0EF417E3, 0x0500151A);
	r2 = D(r2, s[1][1][1], 0xB9251B1F, 0xE00EFFFF, 0x01EE0828, 0x03F00608);
	r3 = D(r3, s[1][1][1], 0xD9002B39, 0xE003121D, 0xE90304E9, 0xE8FA09FC);
	r0 = D(r0, s[1][1][2], 0xEEFD02ED, 0xDC0E000C, 0x061001FF, 0x09040E1A);
	r1 = D(r1, s[1][1][2], 0xFB0906F4, 0xFFF9FEE8, 0xFD01001A, 0xFC27EF0B);
	r2 = D(r2, s[1][1][2], 0x26E50D19, 0x04FE0204, 0x26F2082D, 0x18FBF8EB);
	r3 = D(r3, s[1][1][2], 0xFE0E0D07, 0xF6130B1B, 0x09F6FC21, 0x09F50F0F);
	r0 = D(r0, s[1][2][0], 0x01FC01FC, 0xFF08FEFF, 0x0708EFFA, 0x080D1202);
	r1 = D(r1, s[1][2][0], 0xFB07050B, 0xFA02000B, 0x020003FE, 0x01FEFBFC);
	r2 = D(r2, s[1][2][0], 0xFDFE0CEB, 0xFF020900, 0x00FCEE05, 0x02010306);
	r3 = D(r3, s[1][2][0], 0x030131F8, 0x030204FB, 0xFE000C02, 0xFAFC0406);
	r0 = D(r0, s[1][2][1], 0xEE0307F6, 0xF9100CED, 0x0C09F4EB, 0xE7150D13);
	r1 = D(r1, s[1][2][1], 0x1C12F0FE, 0x02F60103, 0xFA0A00FE, 0xEE080CF7);
	r2 = D(r2, s[1][2][1], 0xE7131323, 0x05F7FC05, 0xFE1805F6, 0x0D0EF902);
	r3 = D(r3, s[1][2][1], 0x12DE1102, 0x02FE00F7, 0x02F7FC14, 0x03030400);
	r0 = D(r0, s[1][2][2], 0xFD0403F8, 0x12E43A0D, 0x09090CEF, 0xF9F70A06);
	r1 = D(r1, s[1][2][2], 0x0213E5E3, 0x0600FA07, 0xFFFAFA0A, 0xD304010E);
	r2 = D(r2, s[1][2][2], 0x16F5F814, 0x0402FDFC, 0xF7030410, 0x0105FCF8);
	r3 = D(r3, s[1][2][2], 0x08F405FF, 0xF506FFFE, 0x03FDFC00, 0x00010309);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-1.561e-01, -1.344e-02, -1.450e-02, -1.494e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(1.132e-02, -7.326e-04, -2.081e-02, -2.326e-02);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(-1.691e-02, 7.593e-02, -1.577e-02, 2.343e-03);
	f2 = max(f2, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 1), f2);
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(-5.096e-03, -1.036e-02, -5.819e-03, -1.182e-02);
	f3 = max(f3, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 1), f3);
}

//!DESC CuNNy-4x16-BILINEAR-TEST-conv4
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv3
//!BIND LUMA
//!SAVE conv4
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 4
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv3_pt;
			r = conv3_gather(p, 0);
			g = conv3_gather(p, 1);
			b = conv3_gather(p, 2);
			a = conv3_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v1 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v2 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v3 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	ivec4 r1 = ivec4(0);
	ivec4 r2 = ivec4(0);
	ivec4 r3 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x05F0134F, 0xF800F4EF, 0xF9FFFB12, 0x0407151E);
	r1 = D(r1, s[0][0][0], 0xFDFEFDFA, 0x0DF602E6, 0x010109F5, 0x0BFE100F);
	r2 = D(r2, s[0][0][0], 0xFD01FE07, 0xFB010D02, 0xF216E50D, 0xF1FB05D0);
	r3 = D(r3, s[0][0][0], 0x0FFCF5FC, 0x0A11F712, 0xFE08040C, 0x0207EA2C);
	r0 = D(r0, s[0][0][1], 0xE9F3F52B, 0xFBFA080F, 0x0501F22F, 0xF2FB1340);
	r1 = D(r1, s[0][0][1], 0x0BFFF5DE, 0x180AE622, 0xFE020E1E, 0xEEFDF63C);
	r2 = D(r2, s[0][0][1], 0xFC00F723, 0xFEFBEB26, 0x09EE8117, 0xF3061781);
	r3 = D(r3, s[0][0][1], 0x12F51EFC, 0x0512F91B, 0x00FE1D2F, 0xDA03E43F);
	r0 = D(r0, s[0][0][2], 0x13F904AA, 0x0BFDEA29, 0x05FBF03B, 0x02FDF80D);
	r1 = D(r1, s[0][0][2], 0x01FFFC16, 0x0D08011F, 0x05FF0A14, 0x09FAF00D);
	r2 = D(r2, s[0][0][2], 0xFE00F42D, 0xF4FD034C, 0xC1F8040F, 0x03F92BE4);
	r3 = D(r3, s[0][0][2], 0xFAF7040E, 0xFF05FF0A, 0x03FCFE3B, 0x0D10FB0D);
	r0 = D(r0, s[0][1][0], 0xF9CFDF45, 0x1BE506CE, 0x0302F62F, 0xFF050C1B);
	r1 = D(r1, s[0][1][0], 0x04FF00DB, 0x1A04052D, 0x04060E10, 0xED17ED23);
	r2 = D(r2, s[0][1][0], 0xF202FC08, 0xFD07E414, 0xCE00F41C, 0xFD040394);
	r3 = D(r3, s[0][1][0], 0xDE12062B, 0x0211F31C, 0xF106032E, 0xF90E0612);
	r0 = D(r0, s[0][1][1], 0xE615023E, 0xF2E8D410, 0x0704ED32, 0xEDE4ED8E);
	r1 = D(r1, s[0][1][1], 0xF301F6CF, 0x18FAE8A9, 0xF7001711, 0x0EFDDDA2);
	r2 = D(r2, s[0][1][1], 0x0403F5E3, 0xFAE9EE5B, 0x15E9F199, 0x0FF528AE);
	r3 = D(r3, s[0][1][1], 0xD2171333, 0x1600FCD2, 0x05E0FE81, 0x12DA1B81);
	r0 = D(r0, s[0][1][2], 0x0AFC01D4, 0x05FD052B, 0x0405E938, 0x0FFC0D30);
	r1 = D(r1, s[0][1][2], 0x07F8F413, 0x02C8D581, 0x02FF083D, 0xF60606F1);
	r2 = D(r2, s[0][1][2], 0xFC00F40D, 0xEBE40917, 0xDFFCE481, 0x2A0E5024);
	r3 = D(r3, s[0][1][2], 0xF203F718, 0xF703F7C2, 0x05F30419, 0xE399EBE7);
	r0 = D(r0, s[0][2][0], 0x00E5010C, 0x1A01FA05, 0x0201FA2C, 0xF6F8F93E);
	r1 = D(r1, s[0][2][0], 0x05FDFD1A, 0xFEFFEC4D, 0xFBFE0708, 0x0702FA1A);
	r2 = D(r2, s[0][2][0], 0xE509FB26, 0x0801F609, 0xDA0AFD03, 0xEDFF01FB);
	r3 = D(r3, s[0][2][0], 0x08FAEE1F, 0x0603F70C, 0xF904F913, 0x02FDFC0B);
	r0 = D(r0, s[0][2][1], 0x03FC01E4, 0x00E6F727, 0x0AF2ED49, 0xF1D20D12);
	r1 = D(r1, s[0][2][1], 0xFBFDFBE6, 0x2CCBF898, 0x01F80E2C, 0xEAC90AE8);
	r2 = D(r2, s[0][2][1], 0x0CE5F9EE, 0xF3FB0A04, 0x0CCFFA22, 0xF2EC13BD);
	r3 = D(r3, s[0][2][1], 0xEDAAE542, 0xFB05FFD9, 0x12E0033A, 0xFFE1F32E);
	r0 = D(r0, s[0][2][2], 0x000407E1, 0xF3FD05F8, 0xFBFFEA38, 0xFEF30210);
	r1 = D(r1, s[0][2][2], 0x01FEF714, 0x2BE5C93A, 0xFAFD072B, 0x04E4EC34);
	r2 = D(r2, s[0][2][2], 0xE9F9F30F, 0xFC01EC15, 0xEDEFD923, 0x28162937);
	r3 = D(r3, s[0][2][2], 0xF3FB001D, 0x0400F8CF, 0xF7E11011, 0x11E5F034);
	r0 = D(r0, s[1][0][0], 0x17BC03EE, 0x0A15FD0E, 0x03F4FFFD, 0x08FFFBDE);
	r1 = D(r1, s[1][0][0], 0x02F9FF02, 0xF80201FE, 0xED02FF00, 0x0EF505FA);
	r2 = D(r2, s[1][0][0], 0x01FAFF01, 0x0E180800, 0x2BEF00F9, 0x01F8FEF9);
	r3 = D(r3, s[1][0][0], 0xFD0CFDFA, 0x040802F6, 0x0600FAF9, 0x100000F3);
	r0 = D(r0, s[1][0][1], 0xFD28F7FE, 0x2BDFF2E1, 0xFB07F9FD, 0x19FBFFE2);
	r1 = D(r1, s[1][0][1], 0xF80FF8FB, 0x0CFB06F2, 0xF8E700FB, 0x12F40FFE);
	r2 = D(r2, s[1][0][1], 0x03F805F8, 0x26F802D7, 0x01090AC6, 0xEB09FC02);
	r3 = D(r3, s[1][0][1], 0xFF10FAFC, 0x05F303F2, 0x1105FFC3, 0x130314E3);
	r0 = D(r0, s[1][0][2], 0xFCFB00FF, 0x030A0907, 0x0101F9FE, 0xFEFFFAFE);
	r1 = D(r1, s[1][0][2], 0x04FC0103, 0x00FFF803, 0x0203020A, 0x0EEEF2FF);
	r2 = D(r2, s[1][0][2], 0x09FCFCFB, 0x2404FEE9, 0x0E07F6F7, 0xF202FA00);
	r3 = D(r3, s[1][0][2], 0x0A07F602, 0xFBF8FDF8, 0x06FBFBF7, 0x0801EBD4);
	r0 = D(r0, s[1][1][0], 0x08F30414, 0xFA05070B, 0xFEFD04F9, 0x13F906E4);
	r1 = D(r1, s[1][1][0], 0x040505F9, 0xF7EE0601, 0xFFF90300, 0x041406EF);
	r2 = D(r2, s[1][1][0], 0xFFF6FFFE, 0xF1E9F5FB, 0x0BEFD9FD, 0x030FFCFE);
	r3 = D(r3, s[1][1][0], 0x1DEF07DB, 0x080C06F2, 0x01F503F5, 0x040301F0);
	r0 = D(r0, s[1][1][1], 0xFC01FFEF, 0x25CEF3F0, 0xFBE60BF1, 0x0607E8DE);
	r1 = D(r1, s[1][1][1], 0x0C16EBF7, 0x040821BB, 0x26E41EEA, 0xFD27DDC4);
	r2 = D(r2, s[1][1][1], 0xF424F2EF, 0xF1F808E7, 0xF8EB2CDB, 0xEE13F708);
	r3 = D(r3, s[1][1][1], 0x24C11ADB, 0xE9150804, 0xFF17F6CE, 0x0614EFD5);
	r0 = D(r0, s[1][1][2], 0xFF060004, 0xF8F51304, 0xFDFE20FB, 0xFF090AFF);
	r1 = D(r1, s[1][1][2], 0xFD051000, 0x15EEDEEA, 0xFEFF110A, 0x1008F5DD);
	r2 = D(r2, s[1][1][2], 0x000B00EF, 0xEA07DFF6, 0x1AF4DDC2, 0xFEF2F908);
	r3 = D(r3, s[1][1][2], 0x0C0702F1, 0xFA06F9F5, 0x050002F1, 0x1AF001E3);
	r0 = D(r0, s[1][2][0], 0xF7FFFFFC, 0xFAFF0005, 0x05FD00FC, 0xFF0600FB);
	r1 = D(r1, s[1][2][0], 0x03FF0500, 0x0717F504, 0x0000FA08, 0xFFF6F9EA);
	r2 = D(r2, s[1][2][0], 0xFDFF05F8, 0x08F6FDFB, 0x06FEFA0A, 0xF8F9FE0C);
	r3 = D(r3, s[1][2][0], 0xFE05F2FF, 0x0205FFF9, 0xFC00FE03, 0xFCF9FB0B);
	r0 = D(r0, s[1][2][1], 0x02FBFA02, 0x0809F606, 0xFC060400, 0x040000EC);
	r1 = D(r1, s[1][2][1], 0xFF0813FB, 0xF8030B9A, 0x0401060D, 0x080407C7);
	r2 = D(r2, s[1][2][1], 0xFA1003F2, 0x0101F0F1, 0x051321F7, 0xFE0506FA);
	r3 = D(r3, s[1][2][1], 0xF4F9D309, 0xFA00F4EF, 0x070E07F3, 0xF9F50F04);
	r0 = D(r0, s[1][2][2], 0x0100FE00, 0xFEFB16FC, 0xF8F60003, 0x00FE0102);
	r1 = D(r1, s[1][2][2], 0xFC060B01, 0x08F90C05, 0xFD06FBFF, 0x00FAEEFD);
	r2 = D(r2, s[1][2][2], 0x01FC0AF3, 0x05FBE706, 0x02FDE704, 0xFB1306F8);
	r3 = D(r3, s[1][2][2], 0xFB08E1FF, 0x03F8FAFE, 0x02F9FEFA, 0xFD02F707);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0x151DFB03, 0x02F60AEE, 0x040208F8, 0x000A0303);
	r1 = D(r1, s[0][0][0], 0x010007FC, 0xFFFF030D, 0xFD02FF01, 0xF2F90004);
	r2 = D(r2, s[0][0][0], 0xFEFE0100, 0x01F609FD, 0x080F0322, 0x020403FC);
	r3 = D(r3, s[0][0][0], 0x04FC0CFE, 0x00FEFC03, 0xFE0602F8, 0xFD07FA03);
	r0 = D(r0, s[0][0][1], 0xF2060F16, 0xFB0CEB2F, 0x03040403, 0x0601F60F);
	r1 = D(r1, s[0][0][1], 0x030FFE10, 0xF6EAF5F2, 0xFC0000FA, 0xF8E5F0EF);
	r2 = D(r2, s[0][0][1], 0xFDFD02F1, 0xF0F101DB, 0xEEFF112A, 0x08100802);
	r3 = D(r3, s[0][0][1], 0x04070903, 0x0B05F8FC, 0x0608FE0B, 0x110000FE);
	r0 = D(r0, s[0][0][2], 0xFEF80402, 0xFF15FB2E, 0x04040308, 0xFCFBFE06);
	r1 = D(r1, s[0][0][2], 0x0306000A, 0x13F80115, 0xFE02F610, 0xFFF5FDFD);
	r2 = D(r2, s[0][0][2], 0xFEFDFD05, 0xFD02E4F6, 0x0B0DDD09, 0x091302CB);
	r3 = D(r3, s[0][0][2], 0x050502F8, 0x03FF0DF8, 0xFCFAF305, 0x0D0C03F2);
	r0 = D(r0, s[0][1][0], 0x123FF232, 0xF1FD00F7, 0xF8FC00FC, 0xF00404F6);
	r1 = D(r1, s[0][1][0], 0xFBFBFB00, 0xEEF9001F, 0x00040608, 0x0E07FE06);
	r2 = D(r2, s[0][1][0], 0x00020503, 0x120BF702, 0x090BFC18, 0x0BFC0DFF);
	r3 = D(r3, s[0][1][0], 0xF607E910, 0x03FE0101, 0x01080306, 0x00FFFD00);
	r0 = D(r0, s[0][1][1], 0xF7F00CDD, 0x181EE03D, 0x0E1EE3FE, 0x0735FB1A);
	r1 = D(r1, s[0][1][1], 0xFB03EC06, 0xF9F00716, 0x151534F2, 0x11221109);
	r2 = D(r2, s[0][1][1], 0xFA0AFEF0, 0x562B0E0B, 0xEDD90228, 0xE5DAF8F6);
	r3 = D(r3, s[0][1][1], 0x02F5D5DB, 0x250128FE, 0xECFF01F7, 0xFDDB0E07);
	r0 = D(r0, s[0][1][2], 0x00F2FDE9, 0xD7FB040D, 0x1103FC12, 0xFCFE04EC);
	r1 = D(r1, s[0][1][2], 0x0715FB03, 0x19160801, 0xFCFDE90E, 0x13191700);
	r2 = D(r2, s[0][1][2], 0x06280402, 0x250E0DF2, 0x1D27F808, 0x0AD4AFF5);
	r3 = D(r3, s[0][1][2], 0x0509F1FD, 0x040D18FB, 0x002304FB, 0x28F8F7F3);
	r0 = D(r0, s[0][2][0], 0x06FEF515, 0xFB0604F8, 0xFA01FF04, 0xFC0CF207);
	r1 = D(r1, s[0][2][0], 0x0302FFFF, 0x00F7FB06, 0x04FD0200, 0x0D06F9FC);
	r2 = D(r2, s[0][2][0], 0xFF04010C, 0xEF04F109, 0xF8FEFBF2, 0x0605FD05);
	r3 = D(r3, s[0][2][0], 0x0704F1FA, 0x0000FF06, 0x0002FF07, 0x11020406);
	r0 = D(r0, s[0][2][1], 0x00FB08F8, 0x0B08F11C, 0x1116F2FF, 0x07000504);
	r1 = D(r1, s[0][2][1], 0x1BFCF808, 0xF7D80C18, 0xF506F305, 0x2CF301F2);
	r2 = D(r2, s[0][2][1], 0x03FC0301, 0x10F7FDFC, 0xE0F4E91B, 0x06FF05F3);
	r3 = D(r3, s[0][2][1], 0x2D13FDFC, 0x09FA10FF, 0xFC0004FE, 0x0F07F1FC);
	r0 = D(r0, s[0][2][2], 0x00FE00EC, 0xEAE70104, 0x00040205, 0xFF040701);
	r1 = D(r1, s[0][2][2], 0x050801F5, 0xF911E7FC, 0x070108F6, 0x1202F0F5);
	r2 = D(r2, s[0][2][2], 0x0DFE0EFE, 0x12F5040E, 0x23210125, 0xF60424DF);
	r3 = D(r3, s[0][2][2], 0x180903F1, 0x08FA0506, 0x04070410, 0xFB05EBFD);
	r0 = D(r0, s[1][0][0], 0xFF0A1AED, 0xF0FB0D05, 0xFDF9FE02, 0xFFFEF806);
	r1 = D(r1, s[1][0][0], 0x02FF05FF, 0xFB00F1FA, 0x04FEF901, 0x0104F504);
	r2 = D(r2, s[1][0][0], 0x0502FF03, 0xFDF2F306, 0x1111EBF3, 0x03FEFC02);
	r3 = D(r3, s[1][0][0], 0xFCEFEFF9, 0xFDFCF300, 0x0100FD05, 0xFC04EA00);
	r0 = D(r0, s[1][0][1], 0xFF05F4EC, 0x100F0AFB, 0xFBF9F7ED, 0x0507F90A);
	r1 = D(r1, s[1][0][1], 0xFDFB03FC, 0x04F6FD08, 0x0B03170F, 0x1416ED18);
	r2 = D(r2, s[1][0][1], 0x0304FE03, 0x0305F00A, 0xF2EDF413, 0xFBF1F4FD);
	r3 = D(r3, s[1][0][1], 0xF9ECF7F4, 0x0502020A, 0xFEFDEB09, 0xFE0AF207);
	r0 = D(r0, s[1][0][2], 0x04F2F70C, 0xF5050001, 0xFCFDFCF9, 0x02FEFC0A);
	r1 = D(r1, s[1][0][2], 0xFF040001, 0x0204FDF7, 0x080801F5, 0x0A03F909);
	r2 = D(r2, s[1][0][2], 0x0203FC0A, 0x0604E908, 0xFD0EFF07, 0x01F60E09);
	r3 = D(r3, s[1][0][2], 0xFBEBF701, 0xFF0003FA, 0x0205FC1E, 0xEAFDF2FA);
	r0 = D(r0, s[1][1][0], 0xF4F50C04, 0xE4FAF903, 0xFBFAF807, 0xF5031807);
	r1 = D(r1, s[1][1][0], 0xFDFA2707, 0x081901E6, 0x090400FC, 0xFCFC04FE);
	r2 = D(r2, s[1][1][0], 0x08FA0F03, 0xFA26F3FE, 0x17F1F9F7, 0x02FD10F9);
	r3 = D(r3, s[1][1][0], 0x0A260A12, 0x060AFEFC, 0xFB04FFFE, 0x040905FE);
	r0 = D(r0, s[1][1][1], 0x0303FB06, 0x400EF9F1, 0x27102008, 0x0D01E41E);
	r1 = D(r1, s[1][1][1], 0xFD19FFEE, 0xDED90F21, 0xDDF33CE1, 0xF5F713F2);
	r2 = D(r2, s[1][1][1], 0xF7F40E00, 0xE00C25E4, 0xD3174903, 0xEBFFD816);
	r3 = D(r3, s[1][1][1], 0x05441E3A, 0xFE000600, 0x0703012F, 0x080A1305);
	r0 = D(r0, s[1][1][2], 0x0BFF0002, 0xD8000207, 0xEC070A08, 0xF8F00904);
	r1 = D(r1, s[1][1][2], 0x03050706, 0x0E0BFBE3, 0xFD100810, 0xFE05F0F7);
	r2 = D(r2, s[1][1][2], 0xF60803F3, 0xDC1E17FD, 0xD60EF9EB, 0x39FB0512);
	r3 = D(r3, s[1][1][2], 0xE91903FC, 0xFA0800F6, 0xF4EE0204, 0xF22DF00D);
	r0 = D(r0, s[1][2][0], 0xFCFEFE0C, 0xF00806FA, 0x040BFD06, 0xFAFC06FC);
	r1 = D(r1, s[1][2][0], 0xFE0006FB, 0x13DCFDF2, 0x07F40100, 0xFA12F1FF);
	r2 = D(r2, s[1][2][0], 0x04F70601, 0x031AFBFF, 0x0101F00D, 0xF8FB08F0);
	r3 = D(r3, s[1][2][0], 0xFB14EB10, 0x010900FC, 0x06FD0501, 0xFD05FEFB);
	r0 = D(r0, s[1][2][1], 0xFAFE0300, 0x0FE5ED08, 0xFC11FBF7, 0xF0E8FA12);
	r1 = D(r1, s[1][2][1], 0xF8FC0A0B, 0xFC0DE9F4, 0x140E0DFE, 0xF41EEE0D);
	r2 = D(r2, s[1][2][1], 0xF60F1D12, 0x1114E31F, 0xFAF6FA02, 0xF9D80AFF);
	r3 = D(r3, s[1][2][1], 0x0840DB01, 0x01FBF70A, 0xF2F1FE00, 0xF6FF07EC);
	r0 = D(r0, s[1][2][2], 0x01010004, 0x04030201, 0xE90E04FA, 0xFCFCFE09);
	r1 = D(r1, s[1][2][2], 0xF9FF08F6, 0xE5F106D9, 0x09F505F7, 0xEA17F606);
	r2 = D(r2, s[1][2][2], 0xFFF2F403, 0xF3F5E619, 0xE5DDF102, 0x1C0813E7);
	r3 = D(r3, s[1][2][2], 0xF308FCF6, 0xF7F3FD06, 0xF3F1F913, 0x110C02E3);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-2.271e-02, 7.671e-04, 2.386e-02, -1.570e-02);
	f0 = max(f0, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), f0);
	vec4 f1 = vec4(r1) * 6.20001240e-05;
	f1 += vec4(2.129e-02, -1.888e-02, -2.724e-02, -1.332e-02);
	f1 = max(f1, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), f1);
	vec4 f2 = vec4(r2) * 6.20001240e-05;
	f2 += vec4(-2.251e-03, -2.180e-02, 6.661e-03, -9.654e-03);
	f2 = max(f2, vec4(0.0));
	imageStore(out_image, opos + ivec2(0, 1), f2);
	vec4 f3 = vec4(r3) * 6.20001240e-05;
	f3 += vec4(1.715e-02, -5.757e-02, -2.143e-02, -1.497e-03);
	f3 = max(f3, vec4(0.0));
	imageStore(out_image, opos + ivec2(1, 1), f3);
}

//!DESC CuNNy-4x16-BILINEAR-TEST-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv4
//!BIND LUMA
//!WIDTH LUMA.w 2 *
//!HEIGHT LUMA.h 2 *
//!COMPONENTS 1
//!WHEN OUTPUT.w LUMA.w / 1.3 > OUTPUT.h LUMA.h / 1.3 > *
#extension GL_EXT_spirv_intrinsics : require
#extension GL_EXT_control_flow_attributes : require
spirv_instruction (extensions = ["SPV_KHR_integer_dot_product"], capabilities = [6019, 6018], id = 4450)
int dp4(int a, int b, spirv_literal int fmt);
#define D(r, s, a, b, c, d) ivec4(r.x + dp4(s, a, 0), r.y + dp4(s, b, 0), r.z + dp4(s, c, 0), r.w + dp4(s, d, 0))
shared int G[4][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	[[unroll]] for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		[[unroll]] for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			vec2 p;
			vec4 r, g, b, a;
			p = vec2(clamp(pos + ivec2(x - 1, y - 1), ivec2(0), sz) * ivec2(2, 2) + ivec2(1, 1)) * conv4_pt;
			r = conv4_gather(p, 0);
			g = conv4_gather(p, 1);
			b = conv4_gather(p, 2);
			a = conv4_gather(p, 3);
			vec4 v0 = vec4(r.w, g.w, b.w, a.w) * 1.00000000e+00;
			vec4 v1 = vec4(r.z, g.z, b.z, a.z) * 1.00000000e+00;
			vec4 v2 = vec4(r.x, g.x, b.x, a.x) * 1.00000000e+00;
			vec4 v3 = vec4(r.y, g.y, b.y, a.y) * 1.00000000e+00;
			G[0][ay][ax] = int(packSnorm4x8(v0));
			G[1][ay][ax] = int(packSnorm4x8(v1));
			G[2][ay][ax] = int(packSnorm4x8(v2));
			G[3][ay][ax] = int(packSnorm4x8(v3));
		}
	}
	barrier();
	int s[2][3][3];
	ivec4 r0 = ivec4(0);
	s[0][0][0] = G[0][xy.y+0][xy.x+0]; s[0][0][1] = G[0][xy.y+0][xy.x+1];
	s[0][0][2] = G[0][xy.y+0][xy.x+2]; s[0][1][0] = G[0][xy.y+1][xy.x+0];
	s[0][1][1] = G[0][xy.y+1][xy.x+1]; s[0][1][2] = G[0][xy.y+1][xy.x+2];
	s[0][2][0] = G[0][xy.y+2][xy.x+0]; s[0][2][1] = G[0][xy.y+2][xy.x+1];
	s[0][2][2] = G[0][xy.y+2][xy.x+2]; s[1][0][0] = G[1][xy.y+0][xy.x+0];
	s[1][0][1] = G[1][xy.y+0][xy.x+1]; s[1][0][2] = G[1][xy.y+0][xy.x+2];
	s[1][1][0] = G[1][xy.y+1][xy.x+0]; s[1][1][1] = G[1][xy.y+1][xy.x+1];
	s[1][1][2] = G[1][xy.y+1][xy.x+2]; s[1][2][0] = G[1][xy.y+2][xy.x+0];
	s[1][2][1] = G[1][xy.y+2][xy.x+1]; s[1][2][2] = G[1][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFC06FE00, 0x01000000, 0xFF000000, 0x00010000);
	r0 = D(r0, s[0][0][1], 0xFC09FC00, 0xF90E0200, 0x06FFFFFF, 0x07FF0000);
	r0 = D(r0, s[0][0][2], 0x01FF0101, 0x16FEFF01, 0xFD000002, 0x0300FF00);
	r0 = D(r0, s[0][1][0], 0x060804FF, 0xFB00F900, 0x060DFE00, 0x0000FC00);
	r0 = D(r0, s[0][1][1], 0xE3FAECFA, 0x22071802, 0xD407F600, 0xFF1A0F00);
	r0 = D(r0, s[0][1][2], 0x08040611, 0xF8FFF9F6, 0x0E010405, 0x11FAFD00);
	r0 = D(r0, s[0][2][0], 0xFC0001FF, 0x0102FF00, 0xFB0005FF, 0xFC02FD00);
	r0 = D(r0, s[0][2][1], 0x0004FCFD, 0xFE000102, 0x03FFF1F8, 0x12FB0E04);
	r0 = D(r0, s[0][2][2], 0x00010105, 0x040101F6, 0xFE020411, 0xFD03FEEE);
	r0 = D(r0, s[1][0][0], 0x05FF0802, 0x01FE0401, 0x06FE0AFF, 0x0100FD00);
	r0 = D(r0, s[1][0][1], 0xF9010A00, 0xFE04EB00, 0x06FEFB04, 0x0CFEFD01);
	r0 = D(r0, s[1][0][2], 0x02FFFB03, 0x01FF0B02, 0x0101FEFE, 0x01000300);
	r0 = D(r0, s[1][1][0], 0x0703F003, 0x03FA0A01, 0xF504F305, 0x01FB0E01);
	r0 = D(r0, s[1][1][1], 0x1B190FD8, 0x131901E6, 0xEE131BE0, 0xE216E8EF);
	r0 = D(r0, s[1][1][2], 0x00FEFF00, 0x0907FAF4, 0xFEFDFB04, 0xFC0305F9);
	r0 = D(r0, s[1][2][0], 0xFFFF0101, 0x0000FFFE, 0x03FFFD01, 0x00FE00FF);
	r0 = D(r0, s[1][2][1], 0xFBFDFE03, 0xFCFE0102, 0x0606FEF4, 0x090609F8);
	r0 = D(r0, s[1][2][2], 0x00000100, 0xFDFE0002, 0x00FF0101, 0x0001FCFE);
	s[0][0][0] = G[2][xy.y+0][xy.x+0]; s[0][0][1] = G[2][xy.y+0][xy.x+1];
	s[0][0][2] = G[2][xy.y+0][xy.x+2]; s[0][1][0] = G[2][xy.y+1][xy.x+0];
	s[0][1][1] = G[2][xy.y+1][xy.x+1]; s[0][1][2] = G[2][xy.y+1][xy.x+2];
	s[0][2][0] = G[2][xy.y+2][xy.x+0]; s[0][2][1] = G[2][xy.y+2][xy.x+1];
	s[0][2][2] = G[2][xy.y+2][xy.x+2]; s[1][0][0] = G[3][xy.y+0][xy.x+0];
	s[1][0][1] = G[3][xy.y+0][xy.x+1]; s[1][0][2] = G[3][xy.y+0][xy.x+2];
	s[1][1][0] = G[3][xy.y+1][xy.x+0]; s[1][1][1] = G[3][xy.y+1][xy.x+1];
	s[1][1][2] = G[3][xy.y+1][xy.x+2]; s[1][2][0] = G[3][xy.y+2][xy.x+0];
	s[1][2][1] = G[3][xy.y+2][xy.x+1]; s[1][2][2] = G[3][xy.y+2][xy.x+2];
	r0 = D(r0, s[0][0][0], 0xFEFD00ED, 0xFF050103, 0x03FF00FE, 0x0300FF02);
	r0 = D(r0, s[0][0][1], 0xFF08FB03, 0xFEF9FBE3, 0xFF020406, 0x00FE03FB);
	r0 = D(r0, s[0][0][2], 0x00FD00FE, 0xFFFEFF08, 0x0000FFFF, 0xFF000105);
	r0 = D(r0, s[0][1][0], 0xF6FB0705, 0xF9050007, 0xF4FBFAF1, 0xF80A0204);
	r0 = D(r0, s[0][1][1], 0x021A1608, 0xFEE61806, 0x0118F602, 0xFCEFF1EA);
	r0 = D(r0, s[0][1][2], 0x01FAFF01, 0x01050503, 0x01FAFF00, 0x01FEFE05);
	r0 = D(r0, s[0][2][0], 0x0104FEFF, 0x02020000, 0xFE010105, 0xFF03FF04);
	r0 = D(r0, s[0][2][1], 0xFF00F900, 0x00FCF9FF, 0x0009FA04, 0x00EE0004);
	r0 = D(r0, s[0][2][2], 0xFFFF0000, 0xFF01FF00, 0x00FCFF00, 0xFF06FC02);
	r0 = D(r0, s[1][0][0], 0x05010100, 0xFFFD0100, 0xFC0502FF, 0xFDFF00FF);
	r0 = D(r0, s[1][0][1], 0x0112FAFD, 0x0902FBFE, 0xFFFB01FB, 0xFE0002FE);
	r0 = D(r0, s[1][0][2], 0x01FC01FE, 0x00F900FD, 0x0001FF00, 0x00FBFFFD);
	r0 = D(r0, s[1][1][0], 0xE718F6FC, 0xFF05FF00, 0x18FFF3FF, 0x0C03FF00);
	r0 = D(r0, s[1][1][1], 0xF7ED01F2, 0xDBE3F1F6, 0xFF12F41C, 0x09DBE60D);
	r0 = D(r0, s[1][1][2], 0xFE0000FC, 0x020007F4, 0x02FC0201, 0x03090410);
	r0 = D(r0, s[1][2][0], 0x06FF0100, 0x03FD0000, 0xF6110201, 0xFDFB0101);
	r0 = D(r0, s[1][2][1], 0x02070904, 0x08000602, 0x0AFB11FB, 0x03080AFE);
	r0 = D(r0, s[1][2][2], 0x00010001, 0xFF020303, 0xFE0001FF, 0x00FA08FC);
	vec4 f0 = vec4(r0) * 6.20001240e-05;
	f0 += vec4(-9.989e-10, 2.133e-09, -4.612e-09, -9.353e-10);
	f0 = tanh(f0);
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(f0.x + LUMA_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(f0.y + LUMA_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(f0.z + LUMA_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(f0.w + LUMA_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}

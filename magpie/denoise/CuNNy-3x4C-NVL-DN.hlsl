// CuNNy 3x4C BILINEAR CHROMA NVL DN
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
Texture2D t0;

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT INPUT_HEIGHT
//!FORMAT R8G8B8A8_SNORM
Texture2D t1;

//!PASS 1
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(7.856e-01, 1.507e+00, 3.409e-01), O(INPUT, float2(x, y)).rgb) + -3.494e-01)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(2.130e-02, 1.440e-02, 8.228e-02, 9.617e-02) * s0_0;
	r += V4(-1.193e-02, -4.697e-01, 7.752e-02, -2.822e-01) * s0_1;
	r += V4(-7.756e-03, 1.541e-02, -1.547e-01, -1.090e-01) * s0_2;
	r += V4(-4.561e-01, -1.386e-02, -2.379e-04, -9.000e-02) * s0_3;
	r += V4(4.426e-01, 4.654e-01, 2.459e-01, 4.458e-01) * s0_4;
	r += V4(7.002e-03, -8.209e-03, 9.644e-02, -3.070e-02) * s0_5;
	r += V4(1.783e-02, -6.583e-03, -1.943e-01, -8.024e-02) * s0_6;
	r += V4(-1.440e-02, 1.368e-02, -2.147e-01, -7.946e-02) * s0_7;
	r += V4(-8.140e-05, -9.763e-03, 6.360e-02, 1.431e-01) * s0_8;
	r += V4(6.306e-04, -1.205e-04, 2.244e-03, -5.490e-03);
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
	t0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8);
}
//!PASS 2
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-DN-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(4.176e-03, -4.310e-02, 3.675e-02, 1.825e-02, 6.442e-02, -1.223e-01, -2.650e-02, 1.673e-03, 1.397e-01, -1.450e-01, 6.948e-02, -2.228e-03, 1.156e-01, 8.725e-02, 1.319e-01, -1.343e-02));
	r += mul(s0_1, M4(-1.493e-02, 7.995e-02, -1.372e-01, 1.184e-01, -1.526e-02, -2.391e-01, 1.070e-01, 1.010e-01, 6.126e-01, -6.004e-01, 2.705e-01, 1.411e-01, 1.316e-01, 2.487e-01, -8.573e-02, -1.311e-01));
	r += mul(s0_2, M4(1.298e-01, -2.311e-03, -8.183e-02, -1.217e-01, -2.610e-01, -5.854e-02, -8.651e-02, -7.642e-02, 1.416e-01, -2.149e-01, 1.276e-01, -6.575e-02, 7.807e-02, 2.670e-01, -3.376e-02, 1.012e-01));
	r += mul(s0_3, M4(-2.094e-02, 9.345e-02, -7.475e-02, -2.249e-02, -3.001e-01, 7.223e-02, -1.379e-01, -5.159e-02, -4.646e-02, 2.212e-01, 4.432e-02, 7.241e-02, 2.530e-01, -3.238e-01, 2.337e-01, -3.214e-02));
	r += mul(s0_4, M4(-2.705e-01, 3.331e-01, 6.403e-02, -1.145e-01, 8.481e-02, 2.945e-01, 2.404e-01, -8.915e-02, -2.784e-02, -5.857e-02, 9.865e-02, -1.193e-01, 1.579e-01, -2.650e-01, -4.271e-01, 3.106e-01));
	r += mul(s0_5, M4(1.180e-01, 1.145e-01, 8.134e-01, -6.570e-01, -1.077e-01, 3.918e-02, -6.183e-02, -5.367e-02, 5.076e-02, -1.382e-01, -1.292e-01, 2.371e-02, 5.724e-02, 2.874e-02, 1.265e-01, -1.953e-02));
	r += mul(s0_6, M4(-9.215e-03, -5.432e-02, -4.185e-02, -1.953e-02, -8.997e-02, 5.131e-03, -7.423e-02, -9.496e-02, 1.362e-01, -5.439e-02, 9.304e-02, -2.404e-02, -1.457e-01, 1.241e-01, -2.084e-01, 5.314e-02));
	r += mul(s0_7, M4(8.587e-02, -4.835e-02, -7.544e-02, -4.528e-02, -2.900e-01, -5.112e-02, 6.766e-01, -2.565e-01, 1.223e-02, 8.666e-02, -9.758e-02, 7.642e-02, -1.405e-01, -1.010e-01, 9.391e-02, -1.622e-01));
	r += mul(s0_8, M4(3.035e-02, -4.644e-02, -2.684e-02, -1.023e-02, -1.408e-01, -3.381e-02, 8.175e-02, -5.005e-02, -1.230e-01, -3.846e-02, 5.114e-03, -4.369e-02, 4.939e-02, 3.748e-02, 7.671e-02, -4.406e-02));
	r += mul(s1_0, M4(-4.087e-02, -3.539e-02, 8.958e-02, 7.247e-03, 1.169e-01, -1.511e-01, 1.380e-01, -5.718e-03, -4.683e-02, -1.916e-01, 5.970e-02, 3.159e-02, -3.061e-01, 2.178e-01, -2.114e-01, 1.720e-02));
	r += mul(s1_1, M4(-4.543e-02, -3.542e-02, 4.748e-03, 1.629e-01, 6.167e-03, -3.614e-01, 2.372e-01, 1.401e-01, 2.281e-01, -5.526e-01, 3.213e-01, 6.505e-02, -9.277e-02, 4.619e-01, -2.611e-01, -2.101e-01));
	r += mul(s1_2, M4(1.271e-01, -9.749e-02, 8.469e-02, -5.730e-02, -1.008e-01, -1.505e-01, 1.771e-02, -1.145e-01, -2.293e-01, -1.515e-01, -1.003e-01, -5.285e-02, 2.353e-02, 2.745e-01, -5.860e-02, 1.622e-01));
	r += mul(s1_3, M4(-9.659e-02, 7.391e-02, 1.781e-02, -3.029e-02, -2.017e-01, -8.379e-03, -3.965e-02, 6.324e-02, -2.665e-01, 2.552e-01, -1.359e-01, 1.279e-01, -1.548e-01, -2.212e-01, 3.482e-01, -1.388e-01));
	r += mul(s1_4, M4(9.643e-02, 4.874e-01, -5.291e-01, 2.840e-01, 9.785e-01, -7.609e-02, -5.007e-01, 4.736e-01, -5.972e-01, -4.955e-02, 1.598e-01, -1.875e-01, -1.656e-01, -1.324e-01, -1.541e-01, 1.829e-01));
	r += mul(s1_5, M4(7.465e-02, -2.295e-01, -1.231e-01, -1.179e-01, 6.186e-02, 1.062e-01, 6.610e-02, -1.323e-01, -2.666e-01, -1.033e-01, -4.947e-02, -9.106e-02, 1.353e-01, -4.155e-02, 5.722e-03, 8.849e-02));
	r += mul(s1_6, M4(1.460e-01, -7.059e-02, 9.813e-03, -1.784e-02, 2.452e-01, -5.655e-02, 5.930e-03, -9.214e-02, 1.439e-01, -4.254e-02, 4.456e-02, -3.790e-02, -3.499e-01, 1.382e-01, -1.111e-01, 6.466e-02));
	r += mul(s1_7, M4(1.558e-01, 3.784e-02, -2.059e-01, -4.433e-02, 5.887e-02, 2.736e-02, -3.496e-01, 3.727e-02, -6.328e-02, 8.657e-02, -1.030e-01, 4.820e-02, -1.426e-01, -1.461e-01, 9.806e-02, -9.960e-02));
	r += mul(s1_8, M4(-3.077e-02, -2.652e-02, -4.641e-02, -7.566e-02, 6.751e-02, -1.512e-02, 1.606e-01, -9.020e-02, -8.475e-02, -3.281e-02, 7.231e-02, -7.291e-02, 4.731e-02, 4.968e-02, -1.608e-01, 9.432e-03));
	r += V4(5.650e-04, -3.241e-03, -1.361e-03, -2.548e-05);
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
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t1[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 3
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-DN-conv2
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t1
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t1, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(-8.507e-03, 2.611e-02, 2.978e-03, 9.932e-03, -2.316e-02, 8.758e-02, -3.142e-03, 1.888e-04, 1.261e-02, 7.206e-02, 1.528e-02, -3.772e-02, 4.457e-01, -1.696e-01, 1.505e-01, 5.408e-02));
	r += mul(s0_1, M4(3.347e-02, -8.362e-02, -1.017e-02, -3.532e-02, -7.819e-02, 5.174e-02, -4.964e-02, 3.078e-01, -1.587e-01, 1.486e-01, -9.322e-02, 1.708e-01, 9.810e-02, -4.950e-01, 1.504e-01, 9.033e-02));
	r += mul(s0_2, M4(-4.184e-02, 2.172e-02, -1.008e-02, 5.326e-02, -1.014e-02, -5.258e-03, -6.921e-03, -1.174e-01, -1.251e-02, 2.049e-04, -4.600e-02, 6.373e-02, 1.115e-01, 1.060e-01, 8.314e-02, 3.878e-01));
	r += mul(s0_3, M4(2.683e-02, 9.348e-02, -2.404e-03, 4.376e-04, 5.181e-02, 2.466e-01, 1.543e-01, -6.875e-02, 1.296e-01, 7.428e-02, 1.383e-01, -3.348e-02, 5.681e-01, -8.915e-01, 2.042e-01, 2.519e-01));
	r += mul(s0_4, M4(-5.304e-02, -3.553e-01, -1.506e-01, -1.351e-02, -5.514e-01, 6.742e-01, -2.117e-01, -1.892e-01, -7.448e-02, 3.253e-01, 3.502e-02, -1.951e-01, -1.132e+00, -2.685e-01, -1.295e+00, -9.890e-01));
	r += mul(s0_5, M4(2.586e-01, 1.061e-01, 1.023e-01, -2.757e-01, 3.230e-02, -2.178e-01, 9.698e-02, -3.229e-02, -3.966e-02, -7.007e-02, -5.433e-02, 3.417e-01, -8.374e-02, 3.535e-01, -2.122e-01, -1.975e-01));
	r += mul(s0_6, M4(3.751e-02, 4.041e-02, 2.507e-02, -2.310e-02, 3.418e-01, -1.092e-01, 1.469e-01, -1.458e-03, 4.822e-02, -1.816e-02, -3.902e-02, -1.714e-02, -2.181e-01, 8.908e-03, -7.200e-01, -3.388e-02));
	r += mul(s0_7, M4(-2.861e-01, -3.064e-02, -3.651e-01, -5.263e-03, 4.352e-01, -2.529e-01, 3.764e-02, -3.280e-02, 2.628e-01, 6.471e-02, -2.529e-01, -3.315e-02, -5.102e-01, 1.860e-01, 4.964e-02, 2.422e-02));
	r += mul(s0_8, M4(-1.668e-02, 1.054e-01, 1.674e-01, 1.278e-01, 9.155e-03, -1.675e-01, -1.449e-01, -2.786e-01, 2.850e-02, -3.895e-02, -2.209e-01, -3.263e-02, -9.770e-02, 9.327e-02, 2.114e-01, 2.278e-01));
	r += mul(s1_0, M4(-3.791e-02, 3.915e-02, -8.820e-02, 1.719e-02, -5.076e-02, 1.539e-01, -4.557e-02, 1.274e-02, -2.981e-02, 4.466e-02, -3.359e-02, 1.626e-03, 1.401e-01, -1.170e-01, 2.060e-02, -8.504e-02));
	r += mul(s1_1, M4(5.764e-02, -2.486e-02, -5.220e-02, 2.362e-01, -3.318e-02, 9.646e-02, -5.732e-02, 3.684e-01, -1.617e-01, 2.544e-01, -8.958e-02, 5.890e-01, -1.606e-01, 4.452e-02, -1.786e-01, -1.043e-01));
	r += mul(s1_2, M4(9.105e-02, -2.841e-02, -4.396e-03, 2.969e-01, -3.971e-02, -1.815e-01, -9.376e-03, 6.560e-02, -6.047e-02, -2.159e-01, -7.551e-02, 3.150e-01, 3.845e-02, 1.763e-01, -3.046e-02, 4.056e-01));
	r += mul(s1_3, M4(5.371e-02, -1.578e-02, 7.562e-03, 3.189e-02, 2.010e-02, 1.811e-01, -3.784e-03, -1.470e-01, 1.457e-01, 1.086e-01, 1.118e-01, -1.625e-02, 2.124e-01, -3.193e-01, 2.479e-01, 8.877e-02));
	r += mul(s1_4, M4(-3.721e-01, 6.029e-02, -5.923e-01, 1.416e-01, -2.185e-01, 1.095e-01, -1.969e-01, -4.624e-02, -3.330e-01, 5.808e-01, -2.243e-02, 4.189e-01, -3.135e-01, 7.406e-01, 7.238e-02, -6.856e-01));
	r += mul(s1_5, M4(3.555e-02, 1.443e-01, -2.728e-01, 1.529e-01, -4.635e-03, -1.146e-01, -8.285e-02, -1.860e-01, -3.257e-01, -9.443e-01, -3.189e-01, 5.444e-01, 1.150e-01, -5.784e-02, 5.767e-02, 2.524e-01));
	r += mul(s1_6, M4(4.058e-03, -2.437e-02, -1.260e-01, 6.761e-02, 1.665e-01, -7.088e-02, 5.210e-03, -8.259e-03, 3.642e-01, -1.417e-01, 3.055e-01, -1.424e-03, -1.457e-01, -1.812e-02, -2.265e-01, -2.268e-02));
	r += mul(s1_7, M4(-3.984e-02, 4.998e-02, 2.792e-01, 5.754e-02, 2.552e-01, -7.162e-02, -3.077e-01, -5.052e-02, 2.165e-01, -1.527e-01, 1.053e-01, -2.410e-01, 3.620e-01, 1.520e-01, -3.672e-01, -8.015e-03));
	r += mul(s1_8, M4(-7.870e-03, 1.434e-01, -1.409e-01, 1.304e-01, -1.377e-01, -1.126e-01, 3.628e-02, -1.687e-01, 1.529e-01, 3.173e-01, -7.598e-01, -1.136e-01, 4.316e-02, -2.768e-02, -1.796e-01, 1.263e-02));
	r += V4(-1.866e-03, 2.639e-03, -5.494e-03, -8.631e-03);
	return r;
}
void Pass3(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 4
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-DN-conv3
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(-1.253e-01, 1.489e-01, -2.701e-01, -1.384e-01, -2.510e-02, 5.676e-02, -9.106e-02, -2.079e-02, 5.941e-02, -8.716e-02, 1.248e-01, 7.460e-02, -1.529e-02, 3.461e-02, -1.092e-02, -1.753e-03));
	r += mul(s0_1, M4(-2.942e-01, 1.397e-01, -9.070e-01, -4.228e-01, 3.250e-03, 7.887e-02, -1.440e-01, 2.099e-02, 2.822e-01, -1.985e-01, 5.276e-01, 2.830e-01, -1.948e-02, 3.257e-02, -5.715e-03, 5.104e-03));
	r += mul(s0_2, M4(-2.289e-01, -1.214e-01, -1.728e-02, -2.613e-01, -8.097e-02, -7.230e-02, -3.047e-02, -1.193e-01, -1.743e-01, 2.703e-02, -4.885e-01, -2.979e-01, -3.163e-02, -8.116e-03, -1.655e-01, -4.603e-02));
	r += mul(s0_3, M4(-2.527e-02, 1.477e-02, -3.348e-02, 1.936e-02, 1.050e-01, -1.544e-01, 1.489e-01, 1.052e-01, 1.265e-01, -1.646e-01, 6.283e-02, 6.712e-02, 2.514e-01, -3.545e-01, 3.856e-01, 2.427e-01));
	r += mul(s0_4, M4(1.996e-01, -3.879e-01, 3.369e-01, 3.582e-01, 1.016e-02, 3.212e-01, 2.439e-01, 2.319e-01, 4.501e-01, -4.916e-01, 8.848e-01, 2.510e-01, -3.057e-01, -1.661e-02, -1.216e+00, -7.552e-01));
	r += mul(s0_5, M4(3.254e-01, 6.502e-01, 8.356e-02, 9.536e-02, 1.936e-01, -4.229e-02, 3.072e-01, 4.482e-01, 2.339e-01, 5.572e-01, 9.897e-02, 9.165e-01, -1.175e-01, 1.175e-02, -9.454e-03, -9.436e-02));
	r += mul(s0_6, M4(4.190e-02, 2.003e-02, 3.548e-03, 4.552e-02, -3.720e-02, 7.793e-03, -6.128e-04, -5.600e-02, -5.566e-04, -7.588e-03, -5.951e-03, -2.994e-02, -4.972e-02, 2.240e-01, 5.554e-02, 4.853e-02));
	r += mul(s0_7, M4(-3.919e-03, 2.452e-02, 4.240e-02, -4.867e-02, -6.566e-02, -2.375e-02, -1.684e-01, -1.616e-01, 1.451e-01, -7.662e-02, 5.610e-02, -4.596e-02, 1.086e-01, 9.448e-01, -6.218e-02, -2.006e-02));
	r += mul(s0_8, M4(1.586e-01, 8.948e-02, -4.148e-02, -3.026e-02, 9.750e-03, -2.881e-01, 8.640e-02, -3.141e-01, 1.607e-01, -1.897e-02, 4.597e-02, -8.278e-02, 9.002e-02, 2.724e-01, -4.425e-02, 6.648e-03));
	r += mul(s1_0, M4(-4.357e-04, 7.254e-02, 4.390e-03, 3.949e-02, -1.576e-01, 1.323e-01, -3.788e-01, -1.956e-01, 8.966e-03, 3.096e-02, 5.782e-02, 2.601e-02, 2.557e-02, -9.782e-03, -2.451e-02, 4.912e-03));
	r += mul(s1_1, M4(-1.450e-01, 8.546e-02, -3.736e-01, -1.367e-01, 1.619e-02, 1.978e-02, -1.073e-01, 5.018e-02, 1.289e-01, -2.978e-01, 1.941e-01, 1.737e-03, -7.688e-02, -1.053e-02, -1.086e-01, -1.309e-01));
	r += mul(s1_2, M4(1.858e-02, -5.481e-02, 1.821e-01, 7.150e-02, 1.526e-02, 5.674e-02, -8.112e-02, 5.885e-03, -6.312e-02, 1.999e-02, -2.241e-01, -2.134e-01, -4.847e-02, -2.671e-02, -2.891e-02, -5.157e-02));
	r += mul(s1_3, M4(-1.148e-02, -1.570e-02, 1.538e-01, 8.426e-02, 1.491e-01, -1.079e-01, -3.026e-01, 1.708e-02, -6.649e-02, -1.323e-01, -1.446e-02, -9.546e-02, 2.815e-02, -8.461e-03, -2.655e-02, -1.158e-02));
	r += mul(s1_4, M4(3.821e-01, 1.158e-01, -2.329e-01, 6.504e-01, -6.615e-01, -1.860e-01, 4.638e-01, -5.296e-01, 3.223e-02, -1.442e-01, 1.782e-01, -7.178e-02, -6.211e-02, -1.117e-01, -1.174e-01, -9.992e-02));
	r += mul(s1_5, M4(2.920e-03, 1.547e-02, 7.383e-02, -2.430e-01, -9.598e-02, -2.454e-02, -5.963e-03, 4.534e-02, -1.499e-01, 1.311e-02, -1.985e-02, 5.155e-02, 3.203e-02, 6.892e-02, -6.709e-02, 3.104e-02));
	r += mul(s1_6, M4(3.315e-03, -2.626e-03, -2.302e-03, 3.215e-02, 7.348e-02, 1.194e-01, 8.566e-02, 4.772e-02, -1.298e-02, -2.372e-02, -7.450e-02, -4.137e-02, -1.084e-01, 8.424e-02, 9.448e-02, -5.359e-02));
	r += mul(s1_7, M4(-1.461e-01, 6.581e-02, 1.206e-02, -1.724e-02, 2.394e-01, 1.552e-01, -9.299e-02, -1.831e-01, -6.232e-02, -1.375e-01, 3.423e-02, -1.548e-01, 1.096e-01, 1.937e-01, -2.776e-04, 3.040e-01));
	r += mul(s1_8, M4(1.708e-02, -5.521e-02, 1.691e-02, 2.901e-02, -1.309e-02, -1.260e-02, 2.526e-04, -8.229e-02, -1.136e-02, 1.519e-02, -1.171e-02, -1.670e-02, -6.528e-03, 1.836e-02, -1.363e-02, 6.608e-02));
	r += V4(3.385e-03, 2.365e-03, 1.737e-03, 5.436e-03);
	return r;
}
void Pass4(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t1[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 5
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-DN-out
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t1
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) O(t1, float2(x, y))
float4 f0(float2 pt, float2 pos, V4 s0_0, V4 s0_1, V4 s0_2, V4 s0_3, V4 s0_4, V4 s0_5, V4 s0_6, V4 s0_7, V4 s0_8, V4 s1_0, V4 s1_1, V4 s1_2, V4 s1_3, V4 s1_4, V4 s1_5, V4 s1_6, V4 s1_7, V4 s1_8) {
	V4 r = 0.0;
	r += mul(s0_0, M4(5.973e-01, 5.383e-02, 5.090e-02, -1.665e-01, 2.056e-01, 4.090e-02, 2.697e-02, -6.373e-02, 2.122e-01, -1.385e-03, 4.773e-02, -3.030e-02, -6.543e-01, -3.211e-02, -6.882e-02, 1.472e-01));
	r += mul(s0_1, M4(-5.302e-01, 2.822e-01, -1.715e-01, 2.359e-01, 1.112e-01, 2.115e-01, -1.204e-01, -1.033e-01, -2.007e-02, 1.470e-01, -7.053e-02, 2.133e-02, 3.115e-01, -3.959e-01, 2.214e-01, -1.275e-01));
	r += mul(s0_2, M4(9.613e-02, -1.890e-01, 1.179e-01, -1.705e-02, -2.711e-02, 9.303e-02, -6.140e-02, 4.768e-04, -6.335e-03, 2.007e-02, -2.036e-02, -9.392e-04, -4.508e-02, 7.839e-02, -5.620e-02, 2.418e-03));
	r += mul(s0_3, M4(-1.480e-01, -1.106e-01, 1.255e-01, 2.250e-02, -7.539e-02, -6.475e-02, 1.110e-01, -3.601e-02, 7.690e-02, -3.362e-02, 8.233e-02, -2.154e-02, 3.613e-02, 2.019e-01, -2.245e-01, -4.182e-02));
	r += mul(s0_4, M4(-8.926e-02, -1.807e-01, -4.774e-01, -2.764e-01, 1.294e-01, 6.396e-02, 2.940e-01, 4.229e-01, 2.195e-01, 1.392e-01, 1.397e-01, 2.095e-01, 1.196e-01, -9.250e-02, 2.416e-01, -1.023e-01));
	r += mul(s0_5, M4(-9.248e-03, 2.333e-02, -3.280e-02, -1.376e-01, -5.303e-03, 3.130e-02, 1.849e-02, 8.374e-02, -7.642e-02, 1.567e-01, -7.834e-02, 2.905e-03, -4.320e-03, -7.751e-03, -8.593e-04, 8.044e-02));
	r += mul(s0_6, M4(-2.605e-02, 4.950e-03, -4.700e-02, 2.015e-02, 1.231e-03, -3.144e-03, -4.015e-02, -2.050e-02, 1.504e-02, -3.670e-03, 9.155e-02, 3.491e-03, -4.628e-02, 2.030e-03, -1.173e-01, 5.381e-02));
	r += mul(s0_7, M4(-4.752e-03, -1.115e-02, -2.214e-02, -6.862e-02, 1.698e-02, 3.308e-02, 5.703e-02, 2.449e-02, 1.248e-01, 6.958e-02, 3.057e-01, 1.054e-01, 1.829e-03, -4.553e-03, 3.092e-02, -7.495e-02));
	r += mul(s0_8, M4(-5.924e-03, 5.018e-03, 6.179e-03, 1.496e-02, 4.560e-03, -6.308e-03, 2.338e-03, 1.310e-02, 1.457e-02, -1.011e-02, 1.402e-02, 1.470e-01, -4.328e-05, -1.152e-03, 3.996e-03, 6.605e-03));
	r += mul(s1_0, M4(6.387e-01, 3.540e-02, 4.256e-02, -1.395e-01, 2.891e-01, 3.719e-02, 7.155e-02, -6.327e-02, 3.140e-01, -5.773e-02, 8.842e-02, -6.788e-02, -7.793e-01, 1.351e-02, -5.654e-02, 2.020e-01));
	r += mul(s1_1, M4(-4.973e-01, 3.485e-01, -2.701e-01, 1.179e-01, 3.998e-02, 2.443e-02, -4.699e-02, 5.738e-02, -3.784e-02, 1.266e-01, -5.489e-02, 1.360e-02, 3.428e-01, -4.010e-01, 2.776e-01, -6.909e-02));
	r += mul(s1_2, M4(1.057e-01, -1.714e-01, 1.168e-01, -3.871e-02, -1.052e-01, 1.948e-01, -1.278e-01, 8.473e-02, 7.991e-03, 9.353e-03, -7.211e-03, -2.371e-02, -4.318e-02, 7.837e-02, -5.487e-02, 2.539e-02));
	r += mul(s1_3, M4(-3.052e-01, 5.386e-02, 1.008e-01, -1.666e-01, 4.147e-02, -1.254e-02, -5.389e-02, -3.667e-02, 9.591e-02, -1.587e-01, 3.545e-01, -1.421e-01, 5.682e-01, 2.379e-01, -6.983e-01, 3.494e-02));
	r += mul(s1_4, M4(-3.418e-01, -7.598e-01, -1.566e-01, 1.460e-01, 3.755e-01, 3.412e-01, 4.443e-01, -1.821e-01, 3.912e-02, 6.114e-01, -2.440e-01, 2.822e-01, 2.163e-01, 1.245e-01, 2.388e-01, -5.444e-01));
	r += mul(s1_5, M4(-5.978e-02, 3.232e-03, -4.115e-02, -4.965e-02, -2.589e-02, -3.579e-02, -4.448e-02, 1.961e-01, -2.254e-02, 1.371e-01, -7.690e-02, 2.946e-02, 5.893e-03, 3.219e-02, -9.583e-03, 3.396e-02));
	r += mul(s1_6, M4(-2.134e-01, -4.766e-02, 3.863e-01, 1.234e-02, -6.433e-02, -7.300e-02, 1.299e-02, 2.716e-02, 9.670e-03, 5.188e-02, -3.532e-03, 2.166e-02, -2.936e-02, 3.568e-02, -1.097e-01, -1.564e-01));
	r += mul(s1_7, M4(-4.475e-02, -1.463e-01, -5.516e-02, 2.202e-01, 1.004e-02, 1.976e-02, -2.822e-02, 8.525e-02, 6.243e-02, -9.622e-02, 3.333e-01, 3.107e-01, -7.349e-02, -6.714e-02, 5.736e-02, 2.954e-02));
	r += mul(s1_8, M4(3.576e-02, 5.097e-02, -9.557e-03, 1.067e-02, 6.704e-03, 9.610e-03, 1.855e-02, -1.093e-02, 1.471e-02, -2.076e-02, 6.175e-02, 1.155e-01, -1.227e-02, -1.676e-02, 6.232e-03, 3.946e-02));
	r += V4(-1.404e-03, -1.335e-03, -1.255e-03, -8.249e-04);
	return tanh(r);
}
void Pass5(uint2 blockStart, uint3 tid) {
	float2 pt = float2(GetInputPt());
	uint2 gxy = Rmp8x8(tid.x) + blockStart;
	uint2 size = GetInputSize();
	if (gxy.x >= size.x || gxy.y >= size.y) {
		return;
	}
	float2 pos = (gxy + 0.5) * pt;
	V4 s0_0 = l0(-1.0, -1.0);
	V4 s0_1 = l0(0.0, -1.0);
	V4 s0_2 = l0(1.0, -1.0);
	V4 s0_3 = l0(-1.0, 0.0);
	V4 s0_4 = l0(0.0, 0.0);
	V4 s0_5 = l0(1.0, 0.0);
	V4 s0_6 = l0(-1.0, 1.0);
	V4 s0_7 = l0(0.0, 1.0);
	V4 s0_8 = l0(1.0, 1.0);
	V4 s1_0 = -max(-s0_0, 0.0);
	V4 s1_1 = -max(-s0_1, 0.0);
	V4 s1_2 = -max(-s0_2, 0.0);
	V4 s1_3 = -max(-s0_3, 0.0);
	V4 s1_4 = -max(-s0_4, 0.0);
	V4 s1_5 = -max(-s0_5, 0.0);
	V4 s1_6 = -max(-s0_6, 0.0);
	V4 s1_7 = -max(-s0_7, 0.0);
	V4 s1_8 = -max(-s0_8, 0.0);
	s0_0 = max(s0_0, 0.0);
	s0_1 = max(s0_1, 0.0);
	s0_2 = max(s0_2, 0.0);
	s0_3 = max(s0_3, 0.0);
	s0_4 = max(s0_4, 0.0);
	s0_5 = max(s0_5, 0.0);
	s0_6 = max(s0_6, 0.0);
	s0_7 = max(s0_7, 0.0);
	s0_8 = max(s0_8, 0.0);
	t0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 6
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-DN-shuffle
//!STYLE PS
//!IN t0, INPUT
float4 Pass6(float2 pos) {
	float2 pt = float2(GetInputPt());
	static const float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	static const float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = t0.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += yuv.r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

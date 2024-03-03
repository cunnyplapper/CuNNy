// CuNNy 3x4C BILINEAR CHROMA NVL
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
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(0.703206479549408, 1.3242888450622559, 0.28984880447387695), O(INPUT, float2(x, y)).rgb) + -0.6522183418273926)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(1.024e-02, -2.736e-02, 8.506e-03, -5.709e-03) * s0_0;
	r += V4(-1.364e-01, -1.479e-01, -3.114e-04, 4.619e-01) * s0_1;
	r += V4(-7.874e-02, -1.160e-02, -1.480e-02, -6.239e-03) * s0_2;
	r += V4(3.796e-02, -3.917e-02, 4.720e-01, -1.409e-03) * s0_3;
	r += V4(5.379e-01, 4.130e-01, -4.717e-01, -4.561e-01) * s0_4;
	r += V4(-3.700e-01, -4.192e-02, 7.979e-03, 3.468e-03) * s0_5;
	r += V4(-2.528e-02, -2.297e-02, -2.653e-02, 1.448e-02) * s0_6;
	r += V4(1.585e-03, -6.569e-02, 1.429e-02, -1.249e-02) * s0_7;
	r += V4(2.081e-02, -4.871e-02, 9.979e-03, 2.283e-03) * s0_8;
	r += V4(-3.122e-06, -1.425e-03, -2.810e-03, 7.366e-04);
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
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-conv1
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
	r += mul(s0_0, M4(-5.386e-02, 7.282e-02, 1.646e-01, 1.937e-02, -9.171e-02, -1.038e-02, -1.600e-01, -4.639e-02, 4.156e-02, 1.072e-01, -3.506e-02, -6.321e-02, 1.026e-01, 7.970e-02, 3.207e-02, -3.776e-02));
	r += mul(s0_1, M4(1.567e-02, -3.994e-01, -2.586e-01, -8.765e-02, 1.117e-01, -8.170e-02, 2.465e-01, 1.300e-01, -3.884e-03, -1.031e-01, -2.989e-01, 1.087e-02, 1.958e-01, -1.840e-02, -6.856e-02, -3.724e-02));
	r += mul(s0_2, M4(2.336e-02, -3.797e-02, 2.974e-02, 4.090e-02, -1.090e-01, 2.608e-01, -2.454e-01, -3.193e-01, 1.148e-01, 2.535e-02, 1.213e-01, 2.215e-02, 1.168e-01, 7.095e-03, -8.131e-02, -4.788e-02));
	r += mul(s0_3, M4(1.188e+00, 1.138e-01, -1.020e-01, -5.064e-02, -4.132e-02, 1.059e-01, 1.036e-01, 5.623e-02, -1.125e-01, -7.898e-02, 4.094e-02, -2.080e-02, -8.168e-02, -2.444e-01, 8.484e-02, 1.387e-01));
	r += mul(s0_4, M4(-1.285e-01, 3.994e-01, 2.535e-01, 8.323e-02, 1.841e-01, -2.018e-01, -1.326e-01, -4.221e-03, -8.848e-01, -3.408e-01, -4.073e-01, -3.955e-01, -1.248e-01, 4.586e-02, -3.377e-01, -1.031e-01));
	r += mul(s0_5, M4(4.577e-02, -5.908e-03, 8.060e-03, 1.289e-02, -1.531e-01, 7.613e-02, 6.164e-02, -6.358e-02, -1.288e-01, 2.944e-02, 8.209e-01, 4.157e-02, 1.592e-01, -3.550e-01, 3.955e-01, -3.375e-02));
	r += mul(s0_6, M4(2.766e-01, 1.498e-01, 2.509e-01, 7.082e-02, 2.265e-02, -2.752e-02, 2.134e-01, 1.461e-02, -4.682e-02, -6.533e-02, -3.541e-02, 4.651e-02, 4.917e-02, -4.356e-02, 8.855e-02, -4.032e-02));
	r += mul(s0_7, M4(7.551e-02, 4.782e-02, 1.578e-01, 7.846e-03, 2.020e-02, -5.111e-03, -3.277e-01, -7.153e-02, -2.241e-01, -7.451e-02, -4.209e-01, -1.707e-01, -3.468e-02, 1.009e-01, -5.723e-02, 1.020e-01));
	r += mul(s0_8, M4(1.846e-02, -4.846e-02, -1.598e-02, 2.582e-02, -5.355e-02, 3.256e-02, 1.343e-01, 6.932e-02, -4.075e-02, -5.283e-04, 9.260e-02, -1.355e-02, -2.626e-03, 3.356e-02, 1.215e-01, -5.015e-03));
	r += mul(s1_0, M4(1.763e-01, 7.395e-02, -2.274e-02, -6.713e-02, -2.369e-01, 1.915e-02, 1.176e-02, 3.528e-02, 3.673e-02, -4.854e-02, 3.000e-02, 8.562e-04, 7.880e-02, -6.519e-02, 3.732e-04, 2.309e-02));
	r += mul(s1_1, M4(1.603e-01, 5.325e-01, 2.358e-01, 1.243e-01, -2.049e-01, 1.258e-01, -6.302e-02, -2.026e-01, -1.573e-01, -3.196e-02, 8.577e-02, -1.706e-02, -1.372e-02, 1.654e-01, 7.703e-03, -1.692e-02));
	r += mul(s1_2, M4(4.459e-02, -1.355e-02, -1.561e-02, 5.683e-03, -1.537e-01, -1.235e-01, 1.556e-01, 1.248e-01, 9.991e-02, -8.071e-02, -1.417e-05, 4.593e-02, 6.698e-03, -1.091e-02, 1.048e-01, 1.100e-01));
	r += mul(s1_3, M4(-7.198e-01, 2.375e-01, 1.082e-01, 1.421e-01, 5.229e-01, 5.338e-02, 9.904e-02, -1.394e-01, 2.402e-02, -1.026e-03, -5.905e-02, 1.417e-02, -2.647e-01, 1.631e-01, -1.636e-01, -1.493e-01));
	r += mul(s1_4, M4(1.546e-01, -5.059e-01, -2.285e-01, 1.267e-01, -8.071e-02, 1.526e-02, 4.802e-01, 1.898e-02, -4.300e-02, 1.577e-01, -1.313e-01, -1.461e-02, 3.869e-02, 1.293e-01, 8.785e-02, -6.124e-02));
	r += mul(s1_5, M4(-7.656e-02, 9.421e-03, 1.216e-01, 3.504e-03, 8.778e-02, -4.436e-02, -7.865e-01, -1.040e-01, 2.349e-01, 5.615e-02, -1.552e-01, -2.791e-01, 1.489e-01, 2.568e-01, 1.489e-01, 1.997e-01));
	r += mul(s1_6, M4(-1.855e-01, -1.053e-02, -1.731e-02, 4.952e-02, -7.675e-02, 6.320e-02, -1.977e-01, 3.300e-02, 3.609e-03, 2.179e-02, 5.514e-03, -1.927e-02, -1.979e-01, -1.211e-02, -1.987e-01, -5.667e-02));
	r += mul(s1_7, M4(4.741e-02, -1.237e-01, 2.318e-01, -4.748e-02, 3.462e-02, -1.656e-03, 4.541e-01, 2.286e-02, 5.999e-02, -9.099e-02, 3.841e-02, -1.233e-02, -2.616e-01, 4.786e-02, -5.928e-01, -6.422e-01));
	r += mul(s1_8, M4(7.986e-02, 3.157e-02, 1.274e-01, 2.779e-02, -8.469e-03, -2.894e-02, -2.616e-01, -7.887e-02, 1.120e-02, 9.399e-02, -4.680e-01, 4.683e-02, 1.061e-01, -9.950e-02, 3.003e-01, -2.645e-02));
	r += V4(1.555e-03, 8.151e-05, 2.633e-03, -1.420e-04);
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
	V4 s1_0 = max(-s0_0, 0.0);
	V4 s1_1 = max(-s0_1, 0.0);
	V4 s1_2 = max(-s0_2, 0.0);
	V4 s1_3 = max(-s0_3, 0.0);
	V4 s1_4 = max(-s0_4, 0.0);
	V4 s1_5 = max(-s0_5, 0.0);
	V4 s1_6 = max(-s0_6, 0.0);
	V4 s1_7 = max(-s0_7, 0.0);
	V4 s1_8 = max(-s0_8, 0.0);
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
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-conv2
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
	r += mul(s0_0, M4(1.862e-02, 7.160e-03, -6.307e-02, -1.678e-02, -4.801e-02, -2.752e-02, 3.043e-02, -1.066e-03, -5.401e-02, -3.886e-02, -9.428e-02, 4.163e-02, 2.994e-01, -2.797e-01, 1.389e-02, 5.611e-02));
	r += mul(s0_1, M4(-2.845e-02, 1.142e-02, 3.859e-02, -2.599e-02, 8.604e-02, -2.504e-03, -7.739e-02, -3.968e-03, -1.772e-01, 2.879e-02, -1.179e-02, 1.121e-01, 3.239e-01, -2.036e-01, -1.848e-01, -3.600e-02));
	r += mul(s0_2, M4(4.846e-02, -4.651e-02, -8.960e-02, -1.522e-02, -2.922e-02, 4.224e-02, 1.207e-01, 2.634e-02, -6.803e-02, 8.081e-02, -1.880e-03, -8.227e-02, 5.242e-02, -8.454e-02, 9.461e-02, 1.839e-01));
	r += mul(s0_3, M4(1.697e-01, -7.563e-02, -1.803e-01, -1.818e-02, -3.827e-02, 1.197e-01, 3.936e-02, -3.319e-02, 2.358e-01, -5.209e-02, 1.378e-01, -1.915e-01, 5.643e-01, -4.188e-01, 5.018e-02, 1.375e-01));
	r += mul(s0_4, M4(4.229e-01, 5.865e-02, 1.812e-01, -4.557e-02, -3.330e-01, -1.694e-01, -3.291e-01, -1.048e-01, 1.402e-01, -2.770e-01, -6.762e-02, 1.228e-01, 5.879e-01, -2.725e-01, -4.452e-01, -2.644e-01));
	r += mul(s0_5, M4(7.153e-02, -1.056e-01, 8.538e-02, 4.043e-02, -9.865e-03, 1.566e-01, 3.296e-01, 1.760e-01, 7.328e-02, 9.483e-03, 1.208e-02, -6.336e-02, 4.434e-01, -4.562e-01, -1.724e-01, 6.130e-01));
	r += mul(s0_6, M4(-2.898e-02, -1.557e-01, -7.438e-02, 3.013e-01, -1.101e-01, 1.416e-01, 1.323e-01, 4.718e-03, 1.478e-01, 1.690e-02, -1.218e-01, -2.802e-01, -1.627e-01, -2.167e-01, 7.320e-03, 3.150e-01));
	r += mul(s0_7, M4(-1.213e-01, 1.783e-02, 9.479e-02, 9.545e-02, -4.761e-02, 1.293e-01, 3.806e-01, 1.547e-01, -1.530e-02, -7.318e-03, -1.830e-02, 3.878e-02, -4.850e-01, -1.620e-01, 2.922e-01, 7.429e-01));
	r += mul(s0_8, M4(3.678e-02, -3.523e-02, -5.436e-02, 7.929e-02, -1.986e-02, 7.902e-02, 1.386e-01, 1.919e-01, -2.019e-02, -1.180e-02, 2.460e-03, 5.458e-02, -3.653e-02, -3.799e-01, -2.828e-02, 4.510e-01));
	r += mul(s1_0, M4(3.047e-02, -4.491e-02, -3.757e-02, 2.238e-02, 4.271e-02, 8.341e-02, -8.693e-03, 1.454e-03, -9.210e-02, 3.604e-02, 5.196e-02, -1.265e-01, 1.639e-01, -5.841e-03, -1.647e-02, 4.911e-02));
	r += mul(s1_1, M4(6.425e-02, -3.151e-02, 1.392e-02, 6.163e-02, -1.401e-01, 1.489e-01, 1.948e-01, -4.626e-02, 4.853e-02, -7.173e-02, -6.191e-02, -2.022e-01, -7.912e-02, -3.054e-02, 6.323e-02, 1.724e-01));
	r += mul(s1_2, M4(-8.835e-03, -5.175e-04, -3.793e-03, -1.072e-02, -4.648e-02, 2.056e-02, -9.066e-02, -9.194e-02, 6.540e-03, 4.459e-02, -6.876e-02, -7.475e-02, -8.248e-02, 2.120e-02, -7.450e-03, -7.211e-02));
	r += mul(s1_3, M4(-2.492e-04, -8.808e-02, -3.554e-02, 9.317e-02, -1.874e-02, 4.344e-04, 1.257e-02, -4.383e-03, -1.233e-01, 1.047e-01, -5.705e-02, 2.760e-02, 3.865e-02, -9.759e-02, 9.595e-02, -2.964e-02));
	r += mul(s1_4, M4(-3.623e-01, -3.368e-01, 3.479e-01, 1.345e-01, 1.131e-01, 5.415e-01, 9.213e-01, -3.913e-02, 4.216e-02, 4.990e-01, -1.187e+00, -3.179e-01, 1.070e-01, -4.483e-01, 6.895e-01, 1.074e+00));
	r += mul(s1_5, M4(4.270e-01, -9.785e-02, -5.062e-01, 6.953e-02, -1.131e-01, 1.157e-01, 1.561e-01, -2.367e-01, -6.208e-02, 3.415e-02, -1.008e-01, -1.195e-01, 1.109e-01, -2.239e-01, -2.865e-01, -2.338e-01));
	r += mul(s1_6, M4(8.863e-02, 4.185e-03, 5.912e-03, -1.487e-01, -1.036e-02, -2.124e-02, 5.091e-03, -7.908e-02, -1.294e-01, 7.253e-02, 5.966e-03, 1.474e-01, 1.836e-01, -6.240e-02, 3.057e-02, -7.944e-02));
	r += mul(s1_7, M4(3.564e-01, -4.976e-02, -1.128e-01, -3.799e-01, -2.556e-01, 1.985e-02, 1.091e-01, -6.468e-02, -1.343e-01, 1.045e-01, 3.054e-02, 1.087e-01, 1.064e-01, -8.962e-02, -1.867e-02, -9.833e-03));
	r += mul(s1_8, M4(1.820e-01, -9.225e-03, 4.038e-02, -1.929e-01, -1.152e-01, 7.993e-02, 3.905e-02, -1.560e-01, -2.514e-02, -6.768e-02, -3.580e-02, 1.499e-02, 8.640e-02, 7.211e-02, 1.714e-02, -6.238e-02));
	r += V4(2.120e-03, 1.423e-03, 3.088e-03, 1.634e-03);
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
	V4 s1_0 = max(-s0_0, 0.0);
	V4 s1_1 = max(-s0_1, 0.0);
	V4 s1_2 = max(-s0_2, 0.0);
	V4 s1_3 = max(-s0_3, 0.0);
	V4 s1_4 = max(-s0_4, 0.0);
	V4 s1_5 = max(-s0_5, 0.0);
	V4 s1_6 = max(-s0_6, 0.0);
	V4 s1_7 = max(-s0_7, 0.0);
	V4 s1_8 = max(-s0_8, 0.0);
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
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-conv3
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
	r += mul(s0_0, M4(2.627e-02, -2.429e-04, -5.115e-02, 5.291e-02, -2.237e-02, 8.618e-03, 3.209e-02, -6.319e-02, -1.290e-03, -5.664e-03, -5.185e-02, 5.599e-02, 8.638e-03, -4.402e-02, 3.071e-02, 9.796e-02));
	r += mul(s0_1, M4(-6.934e-02, 1.759e-02, 1.401e-01, -2.310e-01, 4.425e-03, 9.266e-03, 1.564e-02, -2.301e-02, -1.899e-03, 1.346e-02, 6.278e-03, 3.484e-05, 7.330e-02, -2.446e-02, -1.440e-01, 2.093e-01));
	r += mul(s0_2, M4(5.234e-03, 4.722e-03, -5.076e-04, -3.894e-02, -2.658e-03, -8.665e-03, 9.077e-03, 7.294e-03, 2.729e-02, -7.409e-03, -1.751e-02, 4.687e-02, -2.654e-02, 1.700e-02, 4.479e-02, 1.910e-02));
	r += mul(s0_3, M4(2.942e-02, 2.871e-02, -6.243e-02, -4.936e-02, -1.822e-01, -3.003e-02, -9.256e-02, 1.665e-01, 1.556e-03, 2.901e-02, 1.400e-03, -1.368e-02, 5.207e-02, 8.667e-02, -1.575e-02, -6.287e-02));
	r += mul(s0_4, M4(-8.667e-02, -3.043e-02, 5.112e-01, -2.888e-01, 2.014e-02, -9.352e-02, 2.471e-01, -5.775e-01, -1.793e-02, -6.519e-02, 2.642e-02, 6.321e-02, 1.097e-01, 2.060e-02, -1.351e-02, -4.075e-01));
	r += mul(s0_5, M4(7.391e-03, -3.162e-02, -7.654e-02, -5.084e-03, 4.996e-03, -1.457e-02, -1.233e-01, -3.114e-02, 8.602e-02, -1.254e-02, -1.133e-01, 7.300e-02, -4.886e-02, -4.395e-02, 5.295e-02, -3.902e-02));
	r += mul(s0_6, M4(-2.607e-03, -1.859e-02, -2.190e-02, -9.021e-03, 7.051e-01, 4.494e-03, -7.496e-01, -2.668e-02, 1.166e-01, -4.166e-03, -1.353e-01, -2.654e-02, -1.230e-02, -2.999e-02, -2.065e-02, -1.302e-02));
	r += mul(s0_7, M4(-9.268e-02, -1.829e-02, 3.162e-02, -3.624e-02, -2.546e-01, 4.971e-02, 1.375e-01, 1.466e-01, -2.024e-02, 6.599e-02, -4.989e-02, -5.272e-02, -9.819e-03, -2.242e-02, -8.020e-03, 4.186e-02));
	r += mul(s0_8, M4(4.653e-02, 1.364e-02, -5.430e-02, 3.723e-02, 5.440e-02, -2.305e-02, -3.021e-02, -7.179e-02, 1.021e-01, 2.788e-02, -1.480e-01, 1.753e-02, 2.974e-02, 2.414e-02, -6.566e-02, 7.335e-03));
	r += mul(s1_0, M4(-1.780e-02, -2.393e-02, 2.423e-02, -5.048e-02, 5.672e-02, 1.114e-02, 9.384e-03, 3.829e-02, 5.105e-03, -1.763e-02, 1.890e-01, -1.620e-01, -2.459e-02, 4.188e-02, -1.357e-01, 2.545e-01));
	r += mul(s1_1, M4(-2.478e-02, 3.569e-02, -2.101e-02, -3.486e-02, 1.674e-02, -2.851e-03, -4.334e-02, 8.765e-02, 1.268e-03, -3.665e-02, -5.248e-02, -3.573e-02, 5.196e-01, 1.165e-01, 4.138e-01, -5.569e-02));
	r += mul(s1_2, M4(3.815e-02, -8.044e-04, -3.135e-01, 4.290e-01, -9.726e-03, 6.181e-03, -3.651e-02, 1.276e-02, 1.772e-02, 2.158e-03, 2.508e-02, 5.848e-02, -3.706e-02, -1.636e-02, -1.614e-01, -1.948e-01));
	r += mul(s1_3, M4(-2.263e-02, -1.170e-01, 1.770e-02, 7.480e-02, -2.033e-02, -9.134e-03, -1.364e-01, 3.589e-02, -1.578e-01, -2.393e+00, 1.341e-01, 1.222e-01, 6.187e-01, -9.615e-02, -9.279e-01, 2.225e-02));
	r += mul(s1_4, M4(1.155e-01, -2.510e-01, -5.457e-01, 7.899e-01, -2.021e-01, 1.048e-02, -3.050e-01, 2.141e-01, 1.783e-01, 5.651e-02, 6.616e-02, -2.764e-01, -1.556e+00, -1.277e-01, 7.198e-01, 6.008e-02));
	r += mul(s1_5, M4(-4.252e-01, -2.143e-01, -1.020e+00, -1.314e+00, 8.081e-03, -7.624e-03, 1.282e-02, -3.929e-02, 2.227e-02, -5.519e-03, -5.409e-02, -2.225e-02, -7.975e-02, -3.483e-02, -9.366e-02, -9.953e-02));
	r += mul(s1_6, M4(2.080e-01, -7.050e-02, -7.185e-03, 7.984e-02, 1.274e-01, -2.373e-02, -6.286e-02, 3.747e-02, -1.291e-02, -9.527e-03, -3.520e-01, -1.896e-03, 5.780e-02, -3.259e-02, -1.425e-01, -8.032e-02));
	r += mul(s1_7, M4(1.042e+00, -2.510e-02, -8.196e-01, 4.631e-02, -2.750e-01, 2.241e-02, 3.604e-01, 2.345e-02, 6.372e-02, -9.139e-02, 9.759e-02, -2.017e-01, 3.223e-02, 1.157e-02, -9.055e-02, 7.999e-03));
	r += mul(s1_8, M4(-4.951e-01, 1.350e-02, -5.366e-02, -8.428e-02, -3.503e-02, 1.755e-02, -1.983e-02, -2.469e-02, 7.118e-03, -1.172e-02, 4.724e-02, 4.967e-02, -2.118e-02, -7.585e-03, -3.562e-02, 1.138e-02));
	r += V4(-9.330e-04, -1.885e-03, -4.050e-03, -7.898e-04);
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
	V4 s1_0 = max(-s0_0, 0.0);
	V4 s1_1 = max(-s0_1, 0.0);
	V4 s1_2 = max(-s0_2, 0.0);
	V4 s1_3 = max(-s0_3, 0.0);
	V4 s1_4 = max(-s0_4, 0.0);
	V4 s1_5 = max(-s0_5, 0.0);
	V4 s1_6 = max(-s0_6, 0.0);
	V4 s1_7 = max(-s0_7, 0.0);
	V4 s1_8 = max(-s0_8, 0.0);
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
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-out
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
	r += mul(s0_0, M4(5.448e-03, 4.310e-03, -1.096e-02, -2.142e-02, -1.121e+00, 3.154e-01, 7.144e-01, 1.716e-01, -8.289e-02, 6.575e-03, -1.422e-01, -4.207e-04, -4.993e-02, -9.736e-03, -2.057e-02, -2.201e-02));
	r += mul(s0_1, M4(-1.970e-01, -5.900e-02, -4.914e-02, -4.899e-02, -7.552e-01, -2.920e+00, 1.481e+00, 1.923e+00, 6.994e-01, -6.896e-01, 3.415e-01, 5.610e-03, 1.733e-01, -1.829e-03, 9.011e-02, 4.101e-02));
	r += mul(s0_2, M4(-6.811e-02, -3.187e-01, 1.489e-01, 1.104e-01, 2.574e-01, 9.671e-01, -7.303e-01, -3.543e-01, -1.520e-02, 1.792e-01, -1.517e-02, 9.203e-02, -4.138e-02, 1.016e-01, -4.236e-02, 7.527e-03));
	r += mul(s0_3, M4(1.460e-01, 2.704e-02, -3.321e-02, 5.105e-02, -1.217e-01, -3.436e-01, 7.132e-01, 6.173e-02, 1.076e-01, -1.117e-02, 7.713e-02, 5.422e-02, -1.108e-02, 3.257e-03, -6.071e-02, -2.531e-02));
	r += mul(s0_4, M4(-3.157e-02, 1.311e-01, -7.090e-01, -3.877e-01, 2.506e+00, 1.972e+00, -3.718e+00, -2.709e-01, -2.467e-01, -2.494e-02, 3.534e-01, -1.012e+00, 1.044e+00, 2.562e-01, 1.548e-01, -1.179e-01));
	r += mul(s0_5, M4(2.754e-02, 1.144e-01, 1.571e-02, -3.468e-01, -1.481e-01, 9.893e-01, 6.314e-01, -2.152e+00, -2.398e-02, 9.879e-03, -7.312e-02, 1.082e-01, -1.264e-01, 4.698e-01, -5.564e-02, 1.516e-01));
	r += mul(s0_6, M4(-4.990e-02, -3.870e-02, 6.979e-02, -3.295e-03, 8.126e-02, 2.819e-02, -1.714e-01, -4.896e-04, -2.562e-02, 2.242e-02, 1.726e-02, 4.199e-03, -1.204e-01, -8.680e-02, 8.744e-02, 4.855e-02));
	r += mul(s0_7, M4(1.132e-02, -2.107e-03, 3.378e-02, 5.974e-02, -1.134e-01, 8.786e-02, 2.443e-01, -1.145e-01, 8.193e-02, 2.042e-02, -1.226e-01, 1.724e-01, -1.441e-01, -9.273e-02, 2.627e-01, 2.486e-01));
	r += mul(s0_8, M4(-7.670e-03, -2.814e-03, -3.699e-02, 6.882e-03, -2.081e-01, -2.805e-01, 3.720e-01, 3.801e-01, -1.764e-03, -1.531e-02, 2.496e-02, -4.010e-02, 1.024e-01, 3.286e-03, 3.480e-02, -2.995e-02));
	r += mul(s1_0, M4(-1.150e-01, 2.889e-02, 3.596e-02, 4.246e-02, -1.921e-03, 1.458e-03, -1.271e-03, 2.364e-03, 4.868e-02, 1.163e-02, 3.144e-02, 3.679e-02, 5.143e-03, -3.562e-03, 7.927e-03, 3.506e-02));
	r += mul(s1_1, M4(5.052e-01, 4.740e-02, 4.630e-02, -2.115e-01, 1.955e-02, 9.675e-03, 1.704e-03, 1.826e-02, -2.011e-01, 4.825e-03, -1.362e-01, -8.228e-02, -2.468e-01, 3.187e-02, -6.425e-02, -1.855e-02));
	r += mul(s1_2, M4(-3.049e-02, 1.491e-01, -7.192e-02, 7.058e-02, -1.229e-02, 4.655e-03, 2.863e-02, -2.386e-02, 1.510e-02, -1.346e-01, -5.730e-03, -4.019e-02, 5.384e-02, -8.914e-02, 5.264e-02, -1.071e-02));
	r += mul(s1_3, M4(-1.056e-01, -1.947e-02, -8.807e-02, -4.456e-02, 8.702e-03, -1.544e-03, -3.700e-03, -4.225e-03, -8.032e-02, -2.887e-02, 3.877e-02, -5.187e-02, 4.764e-02, 6.200e-02, 1.186e-01, -2.018e-02));
	r += mul(s1_4, M4(1.190e-01, -4.846e-02, 4.310e-01, 3.916e-01, -2.758e-02, -5.774e-02, 4.215e-02, -1.706e-02, 2.066e-01, 3.299e-02, 3.526e-01, 4.131e-01, -3.539e-01, -3.076e-01, -4.502e-01, -8.601e-02));
	r += mul(s1_5, M4(2.250e-02, 6.278e-02, 7.791e-03, 4.086e-02, -3.748e-02, 2.920e-01, -1.062e-01, 2.241e-01, -2.649e-02, 7.990e-02, 2.142e-03, -5.332e-03, 9.038e-03, -1.183e-01, 1.148e-02, -1.627e-01));
	r += mul(s1_6, M4(1.897e-02, 1.232e-02, -1.447e-02, -2.476e-03, 1.120e-02, 2.411e-03, -3.304e-03, 4.780e-03, 2.890e-02, 1.582e-02, -2.913e-02, -1.262e-02, 6.072e-02, 3.652e-02, 4.188e-02, -9.409e-03));
	r += mul(s1_7, M4(-3.041e-02, -2.537e-02, 5.899e-03, -5.554e-02, -2.618e-02, -1.255e-02, -8.401e-02, -7.106e-02, -2.946e-02, -2.086e-02, 1.625e-03, -5.017e-02, -2.873e-02, -9.260e-03, -1.218e-01, 6.613e-03));
	r += mul(s1_8, M4(3.292e-03, 3.421e-03, -5.630e-03, 2.084e-03, 5.122e-02, -2.542e-03, 8.082e-02, 7.119e-02, 8.270e-03, 1.187e-02, -6.928e-03, 3.002e-02, -9.159e-03, -1.273e-02, 9.266e-03, -5.088e-02));
	r += V4(1.469e-03, 8.639e-04, 3.200e-06, -6.203e-04);
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
	V4 s1_0 = max(-s0_0, 0.0);
	V4 s1_1 = max(-s0_1, 0.0);
	V4 s1_2 = max(-s0_2, 0.0);
	V4 s1_3 = max(-s0_3, 0.0);
	V4 s1_4 = max(-s0_4, 0.0);
	V4 s1_5 = max(-s0_5, 0.0);
	V4 s1_6 = max(-s0_6, 0.0);
	V4 s1_7 = max(-s0_7, 0.0);
	V4 s1_8 = max(-s0_8, 0.0);
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
//!DESC CuNNy-3x4C-BILINEAR-CHROMA-NVL-shuffle
//!STYLE PS
//!IN t0, INPUT
float4 Pass6(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
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

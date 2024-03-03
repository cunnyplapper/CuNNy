// CuNNy 1x4C BILINEAR CHROMA NVL DN
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
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) (dot(float3(0.6501947641372681, 1.2415742874145508, 0.28278347849845886), O(INPUT, float2(x, y)).rgb) + -2.070312976837158)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	min16float4 r = 0.0;
	r += min16float4(3.570e-02, 3.220e-02, -7.276e-02, -2.355e-02) * s0_0;
	r += min16float4(-2.627e-01, -8.376e-02, 2.760e-01, 3.588e-02) * s0_1;
	r += min16float4(-5.091e-02, 4.905e-02, 3.780e-03, -2.045e-02) * s0_2;
	r += min16float4(-8.577e-02, -4.341e-03, 5.041e-01, 1.244e-03) * s0_3;
	r += min16float4(6.789e-01, 4.996e-01, -6.660e-01, 5.215e-01) * s0_4;
	r += min16float4(-1.536e-02, -6.074e-01, -5.316e-02, -3.869e-02) * s0_5;
	r += min16float4(7.274e-03, -2.827e-02, 1.491e-02, 1.796e-02) * s0_6;
	r += min16float4(-3.404e-01, -1.186e-02, -8.050e-02, -5.546e-01) * s0_7;
	r += min16float4(3.121e-02, 1.554e-01, 7.399e-02, 5.941e-02) * s0_8;
	r += min16float4(-0.002799153793603182, 0.0007409106474369764, 0.0032434153836220503, -0.0013218020321801305);
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
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-DN-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(7.328e-02, -4.975e-02, -1.556e-02, 1.938e-02, -7.935e-02, -5.421e-02, -1.043e-03, -9.595e-02, 7.007e-02, -3.259e-02, 3.916e-02, -4.299e-03, -9.885e-02, -5.633e-02, 4.629e-02, -5.379e-02));
	r += mul(s0_1, min16float4x4(-7.351e-02, -1.046e-01, 2.069e-01, -9.053e-02, 9.852e-02, 1.631e-01, -1.953e-01, 8.668e-02, -9.741e-02, 1.182e-01, -1.042e-01, 3.124e-02, -2.158e-01, 7.786e-03, -5.161e-02, -2.861e-01));
	r += mul(s0_2, min16float4x4(4.385e-03, 2.035e-01, -3.621e-02, 8.736e-02, -9.982e-03, 1.403e-03, -1.019e-02, -2.553e-02, -1.401e-01, 1.601e-01, -1.703e-01, 9.740e-02, 4.313e-02, -2.094e-01, -3.236e-02, -1.198e-01));
	r += mul(s0_3, min16float4x4(1.901e-01, -2.203e-01, -1.027e-01, 1.271e-01, -1.675e-01, -1.847e-01, 1.168e-01, -5.673e-01, 1.563e-02, 2.860e-02, -3.111e-02, 1.983e-02, -1.202e-01, 3.201e-01, 9.411e-02, -4.670e-02));
	r += mul(s0_4, min16float4x4(5.546e-01, -3.606e-01, -7.675e-01, 1.794e-01, 3.368e-01, -3.387e-01, 9.432e-04, 1.757e-01, -1.472e-01, -1.467e-01, 2.153e-01, -1.145e-01, 1.078e-01, -1.577e-01, 7.811e-01, -2.736e-01));
	r += mul(s0_5, min16float4x4(9.739e-02, -1.508e-01, 4.699e-02, 8.716e-02, -2.673e-02, -6.121e-02, 3.070e-02, 3.210e-02, 1.089e-01, 3.133e-01, -1.665e-01, -5.411e-02, 1.105e-01, -5.739e-02, -1.123e-01, 5.562e-01));
	r += mul(s0_6, min16float4x4(-1.347e-01, -1.687e-01, 2.258e-01, 2.509e-01, -4.238e-02, 2.842e-01, -1.579e-02, -4.411e-01, -9.010e-02, -1.138e-03, -1.239e-03, 5.652e-03, 8.763e-02, 1.411e-01, -1.637e-01, -1.448e-01));
	r += mul(s0_7, min16float4x4(-1.343e-01, -3.187e-01, 4.636e-01, -1.668e-01, 3.740e-01, -5.888e-01, 3.210e-01, 6.888e-01, 1.850e-01, 1.071e-01, -7.115e-02, 2.302e-03, -1.735e-03, 2.242e-01, -2.951e-01, 2.553e-02));
	r += mul(s0_8, min16float4x4(1.831e-01, 1.402e-01, 3.237e-01, -4.584e-01, 5.399e-02, -2.898e-02, -3.563e-02, 4.884e-02, -1.841e-01, 1.907e-01, 6.452e-02, -8.406e-02, -7.016e-03, -1.982e-01, -1.072e-01, 3.234e-01));
	r += mul(s1_0, min16float4x4(-6.300e-02, -3.013e-03, -3.186e-02, -6.687e-03, 1.149e-01, 1.212e-02, 2.997e-02, -1.786e-02, -4.450e-02, 2.495e-02, -2.190e-02, -6.450e-03, -6.958e-02, 1.392e-01, -4.677e-02, -1.121e-02));
	r += mul(s1_1, min16float4x4(1.313e-01, -2.606e-02, 4.494e-02, 2.972e-02, -4.438e-02, -2.297e-01, 7.757e-02, -1.117e-01, -3.609e-02, 3.356e-02, -9.204e-02, 1.007e-02, -2.022e-02, -6.740e-02, -6.099e-01, -1.392e-01));
	r += mul(s1_2, min16float4x4(3.424e-02, -1.729e-01, 1.157e-01, -1.346e-01, 9.734e-03, -3.434e-02, 2.121e-05, -9.527e-03, 1.108e-02, -1.704e-01, -1.245e-01, -9.688e-02, -1.835e-02, 1.635e-01, -2.664e-01, 1.647e-02));
	r += mul(s1_3, min16float4x4(-1.265e-01, -3.755e-02, 5.913e-02, -1.132e-01, 8.455e-01, -1.516e-01, 5.577e-01, -2.916e-01, -3.818e-02, -9.853e-03, 2.618e-02, -2.854e-02, 1.105e-02, 1.293e-02, 1.003e-01, -3.620e-02));
	r += mul(s1_4, min16float4x4(2.745e-01, -4.044e-01, -1.041e-01, -9.783e-02, 1.626e-01, -3.528e-02, 2.241e-01, 8.096e-02, -7.995e-01, 1.131e+00, -5.293e-01, 2.775e-01, 6.116e-02, 2.280e-01, -1.821e-01, 2.201e-01));
	r += mul(s1_5, min16float4x4(-1.788e-01, 2.822e-01, -9.254e-02, 3.037e-01, 5.677e-02, 2.254e-02, -1.261e-02, 1.771e-02, -1.616e-01, -4.193e-01, 1.928e-01, -3.506e-01, 3.957e-02, -8.514e-02, 1.874e-01, -1.639e-01));
	r += mul(s1_6, min16float4x4(2.079e-01, 1.853e-01, -1.184e-01, -2.104e-01, 1.549e-01, -5.414e-02, 1.256e-01, 2.436e-01, 4.088e-02, 4.716e-02, -2.492e-02, -6.440e-02, -1.460e-01, -1.282e-01, 8.032e-02, 1.786e-01));
	r += mul(s1_7, min16float4x4(1.374e-01, 1.219e-01, -3.422e-01, 3.747e-01, -1.565e-01, 2.771e-01, -2.938e-01, 3.277e-03, -1.831e-01, 2.215e-01, -5.294e-02, -2.543e-01, 1.655e-02, -1.704e-01, 2.115e-01, -1.817e-01));
	r += mul(s1_8, min16float4x4(-1.715e-01, 8.415e-03, -2.026e-01, -1.041e-01, -2.235e-02, -4.357e-02, 4.392e-02, -4.928e-03, 2.065e-01, -2.881e-01, -7.254e-02, 2.824e-01, -4.065e-02, 1.683e-01, 6.991e-02, -1.008e-01));
	r += min16float4(0.002402347279712558, -0.0005639626178890467, 0.0003535184368956834, -0.0012924133334308863);
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
	t1[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 3
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-DN-out
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t1
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t1, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(3.943e-02, -2.307e-03, -2.139e-02, -2.529e-02, 6.093e-03, -9.782e-03, -1.413e-02, -6.213e-03, -8.517e-02, -4.985e-02, 1.067e-01, 2.296e-02, 4.053e-01, -1.046e-01, 2.705e-02, -1.141e-01));
	r += mul(s0_1, min16float4x4(-2.118e-02, 5.635e-02, 4.142e-03, -4.686e-02, 1.304e-01, -8.130e-02, -4.822e-02, -6.471e-02, -1.931e-02, -1.825e-01, 5.430e-02, 7.250e-02, -4.758e-02, 2.630e-01, -1.219e-01, 2.764e-02));
	r += mul(s0_2, min16float4x4(-1.480e-02, -1.666e-02, 2.018e-02, -1.910e-02, -8.603e-02, 7.227e-02, -5.578e-02, -6.270e-04, -3.031e-02, 1.184e-02, -1.507e-02, -7.351e-04, 1.133e-02, 1.948e-02, 4.779e-03, 7.446e-03));
	r += mul(s0_3, min16float4x4(-1.063e-02, -3.459e-02, 1.244e-01, -3.477e-02, 2.036e-03, 1.395e-02, 7.091e-03, 7.381e-03, 1.352e-01, -9.979e-02, -3.230e-02, -6.665e-02, -6.512e-02, -8.453e-02, 1.333e-01, -8.814e-02));
	r += mul(s0_4, min16float4x4(4.617e-02, 6.166e-02, 1.499e-01, 3.623e-01, 1.585e-01, 1.059e-01, 3.844e-01, 3.380e-03, 6.663e-02, 6.760e-01, -6.131e-01, -2.279e-01, 3.136e-02, 7.796e-02, 1.033e-02, 1.062e-01));
	r += mul(s0_5, min16float4x4(-2.800e-02, -1.640e-02, -4.087e-02, 6.723e-04, -2.522e-02, 3.859e-02, -5.628e-02, 1.460e-01, 3.251e-02, -1.265e-01, 9.345e-02, -8.171e-02, 8.176e-03, 8.541e-03, 1.267e-02, 2.938e-02));
	r += mul(s0_6, min16float4x4(4.250e-03, 7.571e-03, 1.286e-02, -1.058e-02, 2.828e-03, -2.899e-03, 1.285e-02, -1.785e-03, 2.087e-02, 4.371e-03, -2.526e-03, -3.034e-03, 2.544e-02, 1.499e-02, 4.970e-02, -9.007e-03));
	r += mul(s0_7, min16float4x4(-2.177e-02, -2.426e-02, -2.436e-02, 2.540e-02, -2.043e-02, -2.034e-02, -8.511e-02, 3.479e-02, -4.452e-02, -1.207e-02, 5.941e-02, 4.663e-02, 4.554e-03, -2.688e-03, 1.981e-02, 3.971e-02));
	r += mul(s0_8, min16float4x4(-5.179e-03, -4.806e-03, -2.283e-02, -3.406e-02, -1.995e-02, 1.359e-02, -4.245e-02, -2.146e-02, 9.500e-03, -1.277e-02, -9.964e-03, 6.792e-03, -2.257e-03, 6.456e-03, -7.427e-03, 3.546e-03));
	r += mul(s1_0, min16float4x4(-1.275e-01, 2.948e-02, 5.525e-02, 3.571e-02, -9.791e-02, 5.377e-02, 2.296e-02, 6.714e-02, 8.645e-03, -4.005e-03, 2.595e-03, 1.899e-03, 8.946e-02, -2.383e-02, -7.693e-02, -3.381e-02));
	r += mul(s1_1, min16float4x4(1.088e-01, -7.701e-02, -1.394e-02, 2.947e-02, 1.274e-01, -3.732e-02, -2.867e-02, 6.958e-02, -6.343e-03, 1.607e-02, 4.440e-03, 8.867e-04, -1.165e-01, 1.323e-01, 2.161e-02, -7.933e-02));
	r += mul(s1_2, min16float4x4(1.045e-01, -9.075e-02, 4.985e-02, -3.110e-02, 1.419e-02, -2.952e-03, 3.082e-02, -7.965e-03, 4.588e-03, -5.515e-03, -6.937e-04, 2.390e-03, -1.518e-02, -1.559e-02, -1.348e-02, 8.824e-04));
	r += mul(s1_3, min16float4x4(6.465e-03, -1.573e-02, 4.144e-02, 2.596e-02, -2.025e-02, 2.396e-02, -1.172e-01, 4.844e-02, 6.960e-02, 3.094e-02, 2.742e-02, 8.055e-03, -6.909e-02, 3.390e-02, 1.296e-01, 2.298e-02));
	r += mul(s1_4, min16float4x4(-6.962e-01, -8.876e-02, -1.884e-01, 3.256e-01, -7.591e-02, -3.098e-01, 1.403e-01, -3.447e-01, 8.827e-02, 1.528e-01, -2.001e-02, -1.693e-02, -1.263e-01, -1.597e-01, -1.753e-01, 1.831e-01));
	r += mul(s1_5, min16float4x4(2.095e-01, -1.372e-01, 1.642e-01, -2.725e-01, -2.410e-02, 2.559e-02, -5.532e-02, 1.565e-02, 1.189e-02, -2.366e-03, -1.054e-02, 1.914e-02, -3.806e-03, -2.551e-02, -1.211e-03, -1.504e-02));
	r += mul(s1_6, min16float4x4(1.210e-01, 9.536e-03, -1.304e-01, -6.822e-02, -1.059e-02, -8.326e-03, -3.273e-02, -1.052e-03, -4.769e-02, -3.405e-02, 1.655e-02, 9.667e-03, -1.488e-02, -7.073e-03, -4.187e-02, 5.163e-03));
	r += mul(s1_7, min16float4x4(1.414e-01, 1.743e-01, -1.313e-01, -2.915e-01, 3.357e-02, 3.249e-02, -5.790e-03, -7.071e-02, -2.810e-02, -1.176e-01, 8.061e-02, 6.665e-02, -2.547e-03, 9.727e-03, -4.041e-02, -4.966e-02));
	r += mul(s1_8, min16float4x4(-1.292e-02, -7.740e-03, 3.793e-02, 3.883e-02, 1.087e-02, -1.784e-03, 2.276e-02, 1.783e-02, -1.534e-02, 1.138e-02, 1.164e-02, -9.667e-03, 5.103e-03, -1.604e-02, 5.385e-03, -4.455e-02));
	r += min16float4(8.611233351984993e-05, -0.0002386098785791546, -0.0005687934462912381, -0.0008577850530855358);
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
	t0[gxy] = f0(pt, pos, s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7, s0_8, s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7, s1_8);
}
//!PASS 4
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-DN-shuffle
//!STYLE PS
//!IN t0, INPUT
float4 Pass4(float2 pos) {
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

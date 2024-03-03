// CuNNy 1x4C BILINEAR CHROMA NVL
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
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) (dot(float3(-0.715873122215271, -1.34689462184906, -0.2895980775356293), O(INPUT, float2(x, y)).rgb) + 2.3331551551818848)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	min16float4 r = 0.0;
	r += min16float4(-1.263e-02, 1.076e-02, -9.798e-03, 4.626e-02) * s0_0;
	r += min16float4(1.573e-01, -2.500e-02, 1.661e-03, -1.243e-01) * s0_1;
	r += min16float4(4.555e-02, 9.862e-03, 2.861e-03, -3.911e-02) * s0_2;
	r += min16float4(8.965e-02, 1.058e-02, -3.204e-03, -3.798e-01) * s0_3;
	r += min16float4(-5.699e-01, -4.951e-01, -4.893e-01, 5.562e-01) * s0_4;
	r += min16float4(3.168e-02, 4.918e-02, 4.990e-01, -4.939e-02) * s0_5;
	r += min16float4(1.154e-02, -1.958e-02, 1.429e-02, -8.190e-02) * s0_6;
	r += min16float4(2.465e-01, 5.176e-01, 3.603e-02, 1.176e-01) * s0_7;
	r += min16float4(-2.036e-03, -5.970e-02, -5.058e-02, -4.285e-02) * s0_8;
	r += min16float4(-0.0009517722064629197, -0.0014529350446537137, 0.00018788989109452814, 0.0024675994645804167);
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
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(1.734e-03, -5.260e-02, 1.293e-01, -2.449e-02, 1.392e-01, -1.748e-01, -2.165e-01, 6.316e-04, -6.103e-02, 1.350e-01, -1.847e-01, -3.658e-02, -2.573e-02, 3.944e-02, 3.287e-02, 2.991e-02));
	r += mul(s0_1, min16float4x4(-1.071e-02, -1.613e-01, -3.072e-01, 1.421e-01, -1.620e-01, -1.712e-01, 7.784e-01, 1.436e-02, -1.101e-01, -1.476e-02, 3.122e-01, -2.063e-01, 1.097e-01, 9.057e-02, -1.333e-01, -1.097e-02));
	r += mul(s0_2, min16float4x4(1.914e-01, -4.454e-02, 2.465e-01, 1.254e-01, -5.221e-02, -2.077e-02, 2.139e-01, -1.166e-02, 3.230e-02, 7.395e-03, 5.377e-03, -2.395e-02, 1.008e-01, 4.920e-02, 1.036e-01, -7.582e-03));
	r += mul(s0_3, min16float4x4(-2.569e-01, 1.106e-01, 1.140e-01, 2.905e-02, 2.128e-01, -5.456e-02, -1.695e-01, -4.556e-02, -4.360e-02, -2.700e-01, -3.950e-01, 7.104e-02, 3.770e-02, 6.371e-03, -2.838e-02, -1.285e-02));
	r += mul(s0_4, min16float4x4(2.453e-01, 7.951e-01, 2.452e-01, -3.288e-01, -5.998e-02, 6.503e-01, 6.208e-02, 4.013e-01, -2.447e-01, -3.451e-02, 5.410e-01, 3.504e-01, -7.351e-02, 6.061e-02, 1.963e-01, 4.370e-02));
	r += mul(s0_5, min16float4x4(1.522e-01, 3.236e-02, -3.544e-01, -2.426e-01, -1.685e-01, 1.006e-01, 9.156e-02, 1.573e-01, 4.913e-02, 9.636e-03, -4.333e-03, -3.185e-02, 1.286e-01, 2.766e-02, -2.539e-01, -3.642e-01));
	r += mul(s0_6, min16float4x4(-3.381e-02, -3.780e-01, -7.974e-02, 1.162e-01, 1.318e-03, 2.331e-01, 4.016e-02, -6.909e-02, 6.158e-02, 2.218e-01, -1.393e-02, -5.189e-02, 7.599e-03, -6.762e-02, -1.535e-02, 1.035e-03));
	r += mul(s0_7, min16float4x4(1.746e-02, -3.861e-01, -2.151e-01, 5.215e-01, -6.780e-03, 1.567e-01, 1.284e-01, -2.495e-01, 2.630e-02, 2.133e-01, 1.361e-01, -1.064e-01, -2.034e-02, -1.064e-01, -9.118e-02, 2.713e-02));
	r += mul(s0_8, min16float4x4(-8.805e-02, -2.241e-01, 7.053e-02, 3.341e-01, 6.763e-02, 1.636e-01, -4.041e-02, -2.300e-01, 5.777e-03, -8.387e-03, -6.118e-03, -9.674e-03, -9.723e-02, -1.281e-01, 1.159e-01, 1.998e-01));
	r += mul(s1_0, min16float4x4(4.976e-02, -4.251e-02, 3.455e-02, -6.393e-02, 2.115e-01, 1.515e-02, 1.353e-01, 1.688e-02, 1.452e-01, -1.721e-01, -1.652e-01, -6.672e-02, -4.753e-03, 4.798e-02, -3.894e-02, 1.205e-03));
	r += mul(s1_1, min16float4x4(-5.820e-02, -1.405e-02, 3.509e-02, 9.293e-02, -1.971e-01, -1.243e-01, -4.387e-01, -5.657e-01, -2.545e-02, 9.876e-03, 1.344e-01, -6.313e-02, 6.702e-02, 1.712e-01, 3.090e-01, -7.449e-02));
	r += mul(s1_2, min16float4x4(-9.676e-02, -7.276e-02, -8.350e-02, -5.945e-02, 4.480e-02, -1.755e-02, 2.803e-01, -1.930e-01, -2.596e-02, 1.128e-02, 4.803e-03, 6.623e-04, -2.247e-01, 6.983e-02, -2.861e-01, -2.251e-01));
	r += mul(s1_3, min16float4x4(-1.175e-01, -3.430e-02, 7.999e-03, -2.096e-02, 1.032e-01, 2.053e-01, 4.578e-02, 3.093e-02, 4.463e-01, 2.262e-01, -1.352e-01, 6.512e-02, 1.596e-02, -4.309e-02, -4.063e-02, 9.642e-03));
	r += mul(s1_4, min16float4x4(9.816e-02, 6.317e-02, -5.246e-02, -1.202e-01, -1.665e-01, -1.733e-01, -7.778e-02, -3.240e-02, 7.589e-02, -8.955e-02, -4.341e-02, 1.421e-01, 4.772e-01, -7.012e-01, -1.028e-01, -1.528e-01));
	r += mul(s1_5, min16float4x4(-3.032e-02, -2.472e-02, 1.323e-01, 1.960e-01, 1.145e-01, 1.096e-02, -1.701e-02, -2.046e-02, -7.056e-03, 9.486e-04, 1.187e-02, 3.944e-02, -3.604e-01, -9.289e-02, 3.775e-01, 2.242e-01));
	r += mul(s1_6, min16float4x4(-2.389e-03, 2.534e-01, 3.111e-02, -5.735e-03, 8.536e-04, -1.112e-01, -5.453e-03, 4.252e-02, -7.739e-02, 4.361e-01, 6.725e-02, -7.593e-02, 3.985e-02, 9.505e-02, 1.012e-02, -4.284e-02));
	r += mul(s1_7, min16float4x4(-1.939e-02, -2.517e-01, 1.417e-01, -3.858e-01, 1.183e-02, 1.304e-01, -8.765e-02, 1.333e-01, -5.990e-02, 1.130e-01, -8.908e-02, -3.301e-02, 3.445e-02, 2.806e-02, 8.472e-02, 2.940e-03));
	r += mul(s1_8, min16float4x4(1.173e-01, 1.140e-01, -1.233e-01, -1.003e-01, -6.616e-02, -6.924e-02, 6.372e-02, 1.077e-01, -5.133e-03, -1.219e-03, 1.162e-02, -2.837e-02, 5.875e-02, 1.313e-01, -9.790e-02, -1.773e-01));
	r += min16float4(0.000573850586079061, 0.001640833099372685, 0.001807940541766584, -0.001292877015657723);
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
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-out
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t1
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t1, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(-1.126e-02, 7.489e-03, -4.992e-03, 7.949e-03, -6.333e-02, -1.581e-03, -1.802e-02, -1.325e-02, -1.243e-02, -3.401e-02, -9.090e-04, -3.296e-03, 4.031e-03, -4.703e-02, 2.236e-02, -2.166e-02));
	r += mul(s0_1, min16float4x4(-1.370e-02, 6.707e-03, -6.707e-02, 1.427e-02, 1.947e-01, 4.304e-02, -1.228e-01, -9.204e-02, -2.017e-02, -1.977e-02, 1.505e-02, 9.184e-03, 5.502e-03, -1.895e-02, 2.389e-02, 4.563e-02));
	r += mul(s0_2, min16float4x4(6.108e-03, -6.138e-02, 6.741e-03, -4.230e-03, -5.432e-02, -4.205e-02, 1.285e-02, -3.206e-02, -1.460e-02, 3.272e-03, 1.495e-03, 6.589e-03, -1.542e-02, -1.545e-02, 6.490e-03, 2.410e-03));
	r += mul(s0_3, min16float4x4(1.046e-02, 1.345e-03, -1.058e-03, -6.333e-03, 8.329e-03, -2.216e-03, -1.225e-02, -7.431e-03, -9.425e-03, -6.019e-02, -4.062e-02, -3.061e-02, 5.183e-01, 8.380e-02, -7.133e-01, 2.056e-01));
	r += mul(s0_4, min16float4x4(2.613e-01, -3.360e-02, 2.613e-01, -5.050e-03, -2.199e-02, 1.929e-02, 9.496e-02, 1.528e-01, -1.421e-01, 4.284e-02, -8.894e-02, -9.125e-02, 2.309e-01, 8.516e-01, -2.456e-01, -1.281e+00));
	r += mul(s0_5, min16float4x4(-2.467e-01, 3.331e-01, -1.319e-01, 1.983e-01, -1.193e-01, -1.987e-01, -7.954e-02, -2.046e-01, -4.532e-03, -3.817e-02, -2.168e-02, -4.163e-02, 2.719e-02, -1.346e-01, -3.082e-02, 8.971e-02));
	r += mul(s0_6, min16float4x4(2.774e-02, 2.008e-02, 2.560e-02, 3.153e-02, 1.427e-02, 1.082e-02, 3.306e-03, 3.019e-03, 6.374e-02, -1.014e-02, 1.460e-01, -4.604e-02, 2.136e-02, 9.540e-02, 1.576e-01, 2.566e-03));
	r += mul(s0_7, min16float4x4(-6.914e-03, 2.716e-02, 6.422e-02, 1.318e-03, -1.243e-02, -2.354e-03, -6.546e-03, -4.878e-03, 1.518e-01, 2.545e-01, 8.666e-02, 3.721e-01, -6.086e-02, -1.043e-01, 3.920e-03, 1.904e-01));
	r += mul(s0_8, min16float4x4(-6.471e-02, -7.642e-02, -1.087e-01, 2.742e-03, 4.745e-04, -8.052e-03, -3.884e-03, -1.305e-02, 2.214e-02, 5.076e-02, 2.350e-02, 4.890e-02, 3.554e-02, 1.622e-02, 2.491e-03, -2.898e-02));
	r += mul(s1_0, min16float4x4(-3.674e-02, 1.316e-02, -1.023e-02, -2.126e-03, 2.521e-03, 1.229e-03, 6.234e-02, 1.605e-02, -1.446e-02, 8.062e-03, -2.932e-03, 2.686e-03, 1.429e-02, -6.611e-03, 2.521e-02, -4.319e-03));
	r += mul(s1_1, min16float4x4(-6.811e-02, 9.446e-02, 6.179e-03, 8.130e-02, 8.472e-02, 9.287e-02, -1.302e-01, -8.707e-02, 3.185e-02, 1.452e-02, -3.190e-02, -7.385e-03, -2.630e-02, 2.949e-02, -2.900e-02, 6.209e-03));
	r += mul(s1_2, min16float4x4(1.646e-02, 2.149e-02, 2.720e-02, 1.603e-02, 2.227e-02, 1.790e-02, 8.796e-03, 1.020e-02, 4.160e-02, -1.888e-02, 1.407e-03, 1.814e-03, 2.310e-02, -1.776e-02, 5.917e-03, -1.370e-02));
	r += mul(s1_3, min16float4x4(-9.294e-02, 1.323e-01, -6.858e-02, 8.464e-02, 1.687e-02, 8.074e-02, -6.836e-02, 1.390e-02, 4.268e-02, 1.151e-03, 3.776e-03, 3.137e-02, 5.067e-03, -3.898e-02, -1.714e-02, -2.249e-02));
	r += mul(s1_4, min16float4x4(6.895e-01, -1.038e+00, 3.419e-01, -6.387e-01, -7.559e-01, -5.996e-01, 6.442e-01, 3.476e-01, -1.155e-01, 1.556e-01, 1.870e-01, 6.958e-02, 1.564e-01, 1.815e-01, 1.740e-02, 3.351e-03));
	r += mul(s1_5, min16float4x4(-3.894e-02, -1.712e-02, -7.007e-02, -3.407e-02, 2.458e-01, 1.659e-02, 9.761e-02, 3.154e-01, 6.811e-02, 2.188e-02, 5.087e-02, 2.985e-02, 1.178e-02, 1.502e-02, 2.840e-02, 4.745e-02));
	r += mul(s1_6, min16float4x4(-4.850e-02, 1.134e-02, -8.565e-02, 4.976e-02, 7.356e-03, -2.477e-02, -3.281e-02, -9.907e-03, -1.350e-02, -3.812e-02, 1.493e-02, -5.768e-02, -1.143e-01, -7.641e-02, -3.722e-02, -1.133e-01));
	r += mul(s1_7, min16float4x4(-4.003e-02, 8.028e-02, 1.315e-01, -3.097e-01, 5.338e-02, 3.635e-02, 1.156e-02, -7.690e-02, -3.408e-01, -5.090e-02, -6.621e-01, 5.481e-02, -4.801e-02, -1.382e-01, -1.950e-02, 6.391e-02));
	r += mul(s1_8, min16float4x4(3.162e-02, 4.384e-02, 2.522e-02, 7.320e-02, 1.281e-02, 3.733e-02, -4.505e-02, -3.628e-02, 3.593e-02, -7.529e-02, 5.301e-02, -1.464e-01, -2.581e-02, 1.077e-02, -2.529e-02, -4.163e-02));
	r += min16float4(6.585673691006377e-05, -0.00016439985483884811, 8.783092926023528e-05, -9.658004273660481e-05);
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
//!DESC CuNNy-1x4C-BILINEAR-CHROMA-NVL-shuffle
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

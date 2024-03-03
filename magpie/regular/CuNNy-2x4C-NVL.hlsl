// CuNNy 2x4C BILINEAR CHROMA NVL
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define V4 min16float4
#define M4 min16float4x4
#define l0(x, y) (dot(float3(0.7080476880073547, 1.3314249515533447, 0.2949870824813843), O(INPUT, float2(x, y)).rgb) + -0.19804057478904724)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	V4 r = 0.0;
	r += V4(1.305e-02, 7.009e-02, -4.861e-01, -2.358e-01) * s0_0;
	r += V4(-1.251e-02, -3.822e-02, 8.673e-05, -9.790e-02) * s0_1;
	r += V4(-1.484e-03, -5.971e-02, 1.103e-02, 1.319e-01) * s0_2;
	r += V4(-5.020e-01, 9.835e-03, 4.873e-01, -1.013e-01) * s0_3;
	r += V4(4.788e-01, 4.346e-01, -1.205e-03, 3.556e-01) * s0_4;
	r += V4(2.570e-02, -3.027e-02, -1.064e-02, -2.631e-02) * s0_5;
	r += V4(2.460e-02, -4.595e-01, -2.975e-03, 7.222e-02) * s0_6;
	r += V4(-4.424e-03, -1.852e-02, 4.779e-03, 1.319e-02) * s0_7;
	r += V4(-2.107e-02, 9.007e-02, -2.010e-03, -1.072e-01) * s0_8;
	r += V4(-3.093e-04, 1.246e-03, -7.922e-05, -2.926e-03);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-conv1
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
	r += mul(s0_0, M4(3.835e-02, 8.813e-02, -1.013e-01, -1.977e-01, -9.643e-03, 3.036e-02, 4.381e-02, -2.673e-01, -4.356e-02, -1.441e-02, 6.576e-03, -6.228e-02, 4.919e-02, 4.579e-02, -1.030e-02, 9.690e-02));
	r += mul(s0_1, M4(-1.461e-03, 2.535e-02, -1.903e-02, 2.391e-01, 1.934e-01, 4.015e-02, 5.985e-02, -2.939e-01, -1.277e-02, 1.534e-02, 2.655e-02, 4.163e-02, 8.857e-02, -4.181e-02, -6.664e-02, 1.071e-01));
	r += mul(s0_2, M4(9.482e-02, 4.992e-02, 8.085e-02, -3.039e-01, 8.574e-03, -1.999e-02, 2.236e-02, -9.432e-02, 5.636e-03, 2.533e-02, 3.162e-02, -8.073e-02, -4.724e-02, -6.762e-02, -8.814e-02, 1.207e-01));
	r += mul(s0_3, M4(-6.664e-02, -4.625e-02, 1.024e-01, 1.424e-01, -1.608e-02, -3.641e-03, -2.290e-01, 5.358e-02, 1.290e-02, -1.066e-01, 1.284e-01, 6.408e-02, -2.844e-02, -7.803e-02, -1.008e-01, 2.617e-01));
	r += mul(s0_4, M4(2.316e-01, 1.177e-01, -2.041e-01, -1.823e-01, -1.763e-01, -9.483e-02, 3.043e-01, -5.695e-02, 2.004e-01, 1.987e-01, -1.295e-01, -4.544e-01, -3.044e-01, -9.409e-02, 1.357e-01, 3.451e-01));
	r += mul(s0_5, M4(-1.834e-01, -4.541e-01, -1.231e-01, 1.966e-01, 1.374e-01, 1.459e-01, -9.500e-02, -3.880e-02, -5.663e-02, -6.189e-02, 3.068e-02, -1.365e-02, -1.415e-02, 9.284e-02, -9.839e-02, 3.385e-01));
	r += mul(s0_6, M4(-8.636e-02, 2.109e-02, 1.468e-01, 4.930e-02, 3.426e-02, -2.059e-02, 2.464e-02, -4.202e-03, -3.919e-04, -1.875e-02, -4.477e-02, 1.313e-01, 1.248e-01, -7.785e-02, 8.115e-02, -3.041e-02));
	r += mul(s0_7, M4(-5.579e-02, 3.838e-01, -1.770e-01, -6.090e-03, -3.813e-02, 4.329e-02, -1.047e-02, -3.019e-02, 1.966e-01, -3.259e-02, -1.504e-01, 1.939e-01, -4.571e-02, 1.222e-02, 3.081e-02, 4.077e-02));
	r += mul(s0_8, M4(-8.578e-02, -4.775e-01, -1.605e-02, -1.714e-01, -3.329e-03, -1.519e-02, -1.581e-02, 2.125e-02, -2.451e-01, 5.530e-02, -4.461e-01, 1.091e-01, 9.480e-02, -4.886e-02, -1.100e-03, 2.240e-01));
	r += mul(s1_0, M4(1.333e-01, -8.453e-02, 8.338e-02, 5.347e-02, 6.323e-02, -7.320e-03, 9.355e-03, 2.273e-02, 4.773e-02, 9.278e-03, 4.622e-03, 7.736e-03, -5.430e-02, -4.213e-02, -1.295e-02, 1.042e-01));
	r += mul(s1_1, M4(2.859e-01, 6.382e-03, 5.140e-02, -6.815e-01, -9.964e-02, -2.468e-02, 3.404e-02, -1.734e-01, 8.451e-02, -1.157e-02, 1.016e-02, -1.881e-01, -2.685e-01, 3.236e-02, -7.398e-02, 4.470e-01));
	r += mul(s1_2, M4(-1.247e-01, -6.043e-02, -6.907e-04, 3.056e-01, 5.814e-02, 2.010e-02, 6.519e-02, -1.539e-01, 4.647e-02, -1.053e-02, 8.911e-03, -9.769e-02, -4.661e-02, 3.922e-02, 3.043e-02, 1.248e-01));
	r += mul(s1_3, M4(5.215e-01, 1.694e-01, -1.189e-01, -1.175e-01, 1.106e-01, -1.498e-02, 2.666e-01, -1.733e-01, 1.685e-01, 9.594e-02, -1.252e-01, -3.278e-02, -9.208e-02, 1.430e-02, 1.067e-01, 1.526e-01));
	r += mul(s1_4, M4(-5.145e-01, -1.193e-01, -2.588e-01, 2.329e-01, -3.134e-02, 1.106e-01, -3.696e-01, -2.613e-01, 3.132e-01, -2.261e-01, -7.430e-03, 4.798e-01, 1.762e-01, 8.025e-02, -3.089e-01, 4.871e-01));
	r += mul(s1_5, M4(3.320e-02, 1.575e-01, 6.757e-02, -2.356e-01, -5.214e-02, -1.470e-01, 1.587e-01, -2.227e-01, 1.395e-01, -4.214e-03, -1.870e-01, -1.630e-01, 8.250e-02, -8.270e-02, 9.340e-02, 3.503e-02));
	r += mul(s1_6, M4(-6.604e-02, 1.679e-01, -1.897e-01, -7.290e-02, -3.183e-02, -1.547e-02, -1.822e-02, -1.615e-02, -4.985e-02, -3.017e-03, 3.771e-02, -1.160e-01, 1.194e-01, -2.400e-01, -5.171e-02, 2.536e-01));
	r += mul(s1_7, M4(-2.817e-01, -1.336e-01, 5.843e-02, 4.185e-02, 1.153e-02, -1.080e-01, 3.702e-03, 2.467e-02, -3.458e-01, 2.796e-01, 4.072e-02, -6.716e-02, 1.116e-01, -1.159e-01, -3.220e-02, 3.447e-01));
	r += mul(s1_8, M4(-1.231e-02, 8.588e-02, 2.362e-02, 9.979e-02, -8.178e-02, 2.625e-02, 1.349e-02, -6.063e-02, -5.159e-01, -2.527e-01, -2.914e-02, -1.736e-02, 9.518e-03, -1.144e-01, -4.144e-02, 5.640e-02));
	r += V4(-2.208e-03, -3.636e-03, -4.931e-04, 2.039e-03);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-conv2
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
	r += mul(s0_0, M4(-8.227e-03, 2.139e-04, -4.042e-04, -1.372e-02, 3.061e-02, -5.579e-02, -3.455e-02, 9.595e-02, -2.037e-01, 1.666e-01, 1.135e-01, 3.955e-01, -1.682e-02, 4.307e-02, -9.269e-03, 3.480e-02));
	r += mul(s0_1, M4(-5.145e-02, 4.016e-03, -4.175e-03, 1.587e-01, 4.346e-01, -7.849e-02, -6.629e-02, 4.237e-02, 9.071e-02, -7.855e-02, -1.646e-01, 4.330e-01, 1.071e-02, 6.319e-02, -3.035e-02, 9.496e-02));
	r += mul(s0_2, M4(2.152e-02, 2.395e-02, -3.845e-02, 1.017e-02, -8.028e-01, 5.820e-01, 2.491e+00, 8.118e-01, 2.697e-03, 4.120e-02, -3.504e-02, 1.057e-01, 6.166e-03, -3.358e-02, -2.784e-02, 3.718e-02));
	r += mul(s0_3, M4(4.478e-02, -3.021e-03, 1.862e-02, 1.207e-02, -1.514e-01, 7.764e-02, 5.098e-02, -6.472e-02, -9.317e-01, 5.302e-01, 8.987e-03, -3.428e-01, -4.494e-02, -5.302e-02, 1.671e-02, -3.772e-02));
	r += mul(s0_4, M4(-4.956e-01, 1.824e-01, 3.282e-02, 9.154e-02, -3.839e-01, -9.858e-03, 7.640e-02, -8.118e-02, -9.307e-03, -7.202e-01, 1.719e+00, -3.915e-01, 5.441e-02, -4.920e-02, 4.345e-02, -8.927e-02));
	r += mul(s0_5, M4(3.545e-02, -3.642e-01, 9.790e-02, 2.005e-01, 2.309e-02, 4.447e-01, -8.926e-03, 3.171e-03, 1.214e-01, -2.459e-02, 2.613e-02, -1.499e-01, 1.939e-02, -2.072e-01, 3.316e-02, -5.795e-02));
	r += mul(s0_6, M4(-1.352e-03, -9.220e-03, -2.252e-02, 3.861e-03, 1.322e-02, -3.977e-02, -1.996e-02, -3.269e-03, 4.102e-01, 2.409e-01, 1.714e-01, 4.912e-01, 1.397e-02, -1.413e-01, -8.668e-03, 2.562e-02));
	r += mul(s0_7, M4(-3.072e-02, 3.856e-02, -4.676e-02, -9.609e-02, 9.481e-03, 4.236e-02, -5.160e-03, -1.850e-03, -4.348e-01, -2.316e-01, 1.297e-01, 7.342e-02, 3.915e-02, 4.912e-01, 1.649e-03, 2.715e-03));
	r += mul(s0_8, M4(8.479e-02, 1.709e-02, -4.924e-02, -5.017e-02, -1.957e-03, -1.293e-01, 4.565e-02, 5.534e-02, -6.402e-02, 2.339e-02, 5.840e-02, 5.725e-02, -3.798e-02, -3.005e-01, 1.499e-02, 2.758e-02));
	r += mul(s1_0, M4(2.407e-02, -1.873e-02, -1.548e-02, -1.220e-02, 1.169e-01, -1.732e-01, 9.509e-03, -1.099e-01, 9.968e-02, -6.215e-02, 5.810e-03, -2.360e-01, 1.722e-02, 8.415e-03, -6.625e-03, -3.367e-02));
	r += mul(s1_1, M4(1.114e-01, 6.953e-02, 9.186e-03, -1.483e-01, -2.460e-01, 4.247e-02, -6.967e-02, 1.255e-01, 4.949e-02, -9.480e-02, 6.920e-02, -3.701e-01, -1.069e-02, 4.126e-03, 4.565e-03, -1.103e-01));
	r += mul(s1_2, M4(-6.448e-02, 4.193e-02, -4.758e-02, -1.213e-01, -1.491e-02, -2.497e-02, -4.236e-02, 3.227e-02, 3.315e-02, 8.276e-02, 9.496e-02, -8.716e-02, -5.690e-03, -2.007e-02, 2.609e-02, -5.434e-02));
	r += mul(s1_3, M4(-4.393e-03, -6.439e-03, -1.012e-02, -2.195e-03, 1.421e-01, -2.530e-01, -3.602e-02, 1.212e-01, 4.699e-01, -7.762e-02, 6.109e-03, 5.267e-02, 6.986e-02, -1.007e-01, 9.198e-02, 3.189e-02));
	r += mul(s1_4, M4(6.074e-01, -9.733e-02, -1.628e-02, 3.503e-02, 1.155e-01, 3.679e-01, 8.682e-02, 5.624e-02, -2.355e-01, 1.077e-01, -1.265e-01, 8.727e-01, 5.507e-02, -1.675e-01, 2.884e-02, 3.271e-01));
	r += mul(s1_5, M4(-3.759e-02, 4.652e-02, 1.010e-01, 8.149e-02, -7.479e-02, -2.672e-01, 6.469e-02, -1.613e-02, -4.065e-03, 2.838e-01, -1.144e-01, 1.401e-01, -7.239e-02, -4.138e-02, 4.309e-02, 1.478e-01));
	r += mul(s1_6, M4(2.362e-02, -7.634e-03, 8.164e-03, 1.114e-02, -5.534e-03, -1.132e-01, 1.800e-02, 2.508e-02, -4.277e-02, 6.194e-02, 2.669e-02, 3.478e-02, 1.357e-02, -1.774e-01, -1.339e-02, 9.789e-02));
	r += mul(s1_7, M4(2.137e-02, 6.486e-02, -3.135e-03, 1.460e-02, -6.274e-02, 4.185e-02, 8.085e-03, -2.765e-02, -8.276e-02, -2.123e-01, 2.106e-03, -8.039e-02, -3.148e-01, 7.793e-01, 4.553e-02, -2.911e-01));
	r += mul(s1_8, M4(-7.010e-03, -1.303e-01, -1.250e-02, 2.189e-02, 8.387e-03, 1.130e-01, -4.416e-03, -1.809e-02, 1.531e-01, 2.227e-01, -2.276e-02, 5.660e-03, -5.074e-02, -3.896e-01, 6.896e-02, -9.232e-02));
	r += V4(-2.232e-03, -2.968e-03, 1.951e-03, 1.123e-03);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-out
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
	r += mul(s0_0, M4(-1.713e-02, -1.153e-02, -5.043e-03, -1.380e-02, -1.743e-01, 5.148e-02, 3.668e-02, 2.317e-02, 3.508e-02, 3.928e-03, 2.493e-02, -2.630e-02, -1.671e-02, -1.387e-02, -1.951e-03, 7.557e-03));
	r += mul(s0_1, M4(1.421e-01, -7.414e-03, -9.937e-02, -8.957e-02, 3.452e-01, -5.382e-01, 1.616e-01, -2.141e-02, -3.091e-02, 4.483e-02, 2.162e-02, 2.759e-02, -1.926e-01, -8.546e-03, -6.003e-03, 3.888e-02));
	r += mul(s0_2, M4(-8.697e-02, 1.248e-01, -7.593e-02, 5.651e-02, -9.324e-03, 3.527e-02, -1.217e-02, 1.337e-02, 2.862e-04, 1.743e-03, -1.069e-02, -4.815e-03, 3.105e-02, -2.827e-02, 3.235e-02, -3.769e-02));
	r += mul(s0_3, M4(1.234e-03, -1.666e-02, -3.625e-02, -4.561e-03, 3.601e-02, 4.168e-02, -1.178e-01, 3.976e-02, 9.579e-02, -6.453e-02, 1.116e-01, -1.176e-02, -1.025e-02, -1.571e-02, -2.862e-02, -4.651e-02));
	r += mul(s0_4, M4(8.219e-02, 1.313e-01, 4.964e-01, 2.281e-01, 1.352e-01, 1.665e-01, 2.777e-02, -4.678e-01, 4.681e-02, 4.498e-01, -1.714e-01, 3.037e-01, -2.659e-01, -1.715e-01, -4.229e-01, -1.636e-01));
	r += mul(s0_5, M4(1.848e-02, -6.707e-02, 1.930e-02, 1.207e-01, 6.785e-03, 2.399e-02, -1.064e-02, -3.431e-02, -1.457e-03, 3.073e-03, -1.777e-02, -3.202e-02, 2.608e-02, -2.315e-02, 1.140e-01, 8.176e-02));
	r += mul(s0_6, M4(2.493e-04, -2.622e-03, -8.483e-03, -7.794e-03, -4.566e-03, -9.249e-03, 5.902e-03, 1.087e-02, 9.072e-03, -6.982e-03, 4.041e-02, -2.389e-02, 8.643e-04, 1.842e-02, -2.203e-02, 1.054e-02));
	r += mul(s0_7, M4(1.504e-02, 1.956e-03, 3.005e-02, 1.872e-02, -2.364e-02, -4.010e-02, 3.576e-02, 2.458e-02, -2.208e-02, -2.020e-02, 7.349e-02, 7.233e-02, 7.705e-03, -1.081e-02, -3.211e-02, -6.420e-02));
	r += mul(s0_8, M4(4.105e-03, 1.859e-02, -3.235e-02, -2.450e-02, -1.582e-02, -2.498e-02, 8.586e-03, 1.317e-02, -3.369e-04, -2.584e-02, 3.635e-02, 1.486e-02, -3.820e-03, 6.304e-03, -2.825e-02, -1.703e-02));
	r += mul(s1_0, M4(-8.008e-03, 2.254e-02, -7.896e-02, 9.839e-02, 5.977e-02, 3.937e-02, 4.174e-03, -1.747e-02, 3.740e-01, -8.515e-02, -1.257e-01, -7.369e-02, -2.330e-02, -8.397e-03, 4.065e-03, 2.021e-02));
	r += mul(s1_1, M4(1.421e-01, -2.489e-02, -3.209e-02, -1.139e-01, 3.429e-02, 3.084e-03, -6.761e-02, -9.762e-03, -1.215e+00, 5.500e-02, 6.270e-01, 4.414e-01, 1.144e-02, -1.923e-03, 6.323e-02, 3.694e-02));
	r += mul(s1_2, M4(-6.320e-03, -8.653e-03, 3.123e-02, 2.363e-02, 3.547e-03, -1.605e-02, 1.586e-02, 1.189e-03, -1.578e-01, -7.091e-01, 3.174e-01, 6.651e-01, -7.376e-03, -1.008e-02, -1.253e-02, -8.090e-03));
	r += mul(s1_3, M4(1.304e-01, 2.971e-02, -1.078e-01, -2.041e-02, -6.951e-02, -2.654e-02, 4.293e-02, 5.906e-02, -4.233e-02, -1.102e-01, -2.645e-01, 2.517e-01, -2.006e-02, 3.698e-02, 4.991e-02, 7.699e-02));
	r += mul(s1_4, M4(-3.777e-01, -5.371e-01, 5.449e-01, -4.747e-01, 1.453e-02, -3.038e-02, 9.157e-02, 2.766e-02, 2.086e+00, 1.021e+00, -1.099e+00, -2.878e+00, 1.146e+00, 4.496e-01, -7.375e-03, -3.968e-01));
	r += mul(s1_5, M4(-6.472e-02, 6.977e-03, -8.676e-02, 7.446e-02, 5.405e-03, -5.753e-03, 2.230e-02, -5.850e-03, -1.247e-01, 2.786e-01, -1.583e-01, 2.683e-01, -2.724e-01, 1.261e-01, -1.332e-01, 8.675e-02));
	r += mul(s1_6, M4(-1.622e-02, 1.789e-03, 6.198e-02, -1.006e-02, 2.668e-02, 1.263e-02, -1.443e-02, -1.625e-02, -1.578e-01, -5.940e-02, 2.550e-01, 2.365e-02, -2.782e-02, -5.770e-02, 1.800e-01, -2.050e-02));
	r += mul(s1_7, M4(1.793e-02, 4.780e-03, -2.440e-01, 1.589e-01, 8.482e-03, 4.189e-02, -1.728e-02, -9.516e-03, -6.320e-02, -2.181e-01, -2.056e-02, 3.211e-01, -3.213e-01, -1.318e-01, 5.805e-02, 5.342e-01));
	r += mul(s1_8, M4(6.042e-02, 7.757e-02, -8.765e-02, -5.184e-02, 1.258e-03, 7.845e-03, -7.768e-03, 4.730e-03, -2.164e-03, 8.951e-02, -3.799e-02, -1.489e-01, -4.568e-02, -8.910e-02, 2.139e-01, -1.024e-02));
	r += V4(2.830e-04, -4.871e-04, 2.051e-04, -6.625e-04);
	return tanh(r);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-shuffle
//!STYLE PS
//!IN t1, INPUT
float4 Pass5(float2 pos) {
	float2 pt = float2(GetInputPt());
	const static float3x3 rgb2yuv = {0.299, 0.587, 0.114, -0.169, -0.331, 0.5, 0.5, -0.419, -0.081};
	const static float3x3 yuv2rgb = {1, -0.00093, 1.401687, 1, -0.3437, -0.71417, 1, 1.77216, 0.00099};
	float4 r = 0.0;
	float2 size = float2(GetInputSize());
	float2 f = frac(pos * size);
	float3 yuv = mul(rgb2yuv, INPUT.SampleLevel(SL, pos, 0).rgb);
	int2 i = int2(f * 2.0);
	r.r = t1.SampleLevel(SP, (float2(0.5, 0.5) - f) * pt + pos, 0)[2*i.y + i.x];
	r.r += yuv.r;
	r.a = 1.0;
	r.r = clamp(r, 0.0, 1.0);
	float3 px = mul(yuv2rgb, float3(r.r, yuv.yz));
	return float4(px, 1.0);
}

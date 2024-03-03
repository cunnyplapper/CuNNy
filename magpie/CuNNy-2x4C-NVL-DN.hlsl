// CuNNy 2x4C BILINEAR CHROMA NVL DN
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-DN-in
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN INPUT
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) (dot(float3(-0.37258198857307434, -0.7120437026023865, -0.16092996299266815), O(INPUT, float2(x, y)).rgb) + 1.0525599718093872)
float4 f0(float2 pt, float2 pos, min16float s0_0, min16float s0_1, min16float s0_2, min16float s0_3, min16float s0_4, min16float s0_5, min16float s0_6, min16float s0_7, min16float s0_8) {
	min16float4 r = 0.0;
	r += min16float4(-5.268e-01, 2.826e-02, 8.807e-03, -1.733e-01) * s0_0;
	r += min16float4(-1.743e-01, -3.171e-02, 7.023e-03, 1.372e-01) * s0_1;
	r += min16float4(1.353e-01, 2.505e-04, -1.169e-02, 2.376e-01) * s0_2;
	r += min16float4(1.289e-01, -6.812e-02, -6.621e-01, 8.386e-02) * s0_3;
	r += min16float4(6.120e-01, 7.278e-01, 6.528e-01, -4.543e-01) * s0_4;
	r += min16float4(-1.043e-02, -2.148e-02, 7.135e-03, 1.289e-02) * s0_5;
	r += min16float4(1.435e-01, 3.879e-02, 1.766e-02, 2.842e-01) * s0_6;
	r += min16float4(-2.145e-02, -6.934e-01, -3.745e-02, 4.244e-02) * s0_7;
	r += min16float4(-2.917e-01, 1.978e-02, 1.648e-02, -1.724e-01) * s0_8;
	r += min16float4(0.002217669039964676, 0.001644763513468206, -0.001935565029270947, 0.0011268239468336105);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-DN-conv1
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(2.228e-02, -2.329e-02, 1.280e-02, 4.036e-03, 1.701e-01, 9.966e-02, 3.045e-01, 9.155e-02, -1.753e-01, 3.676e-01, -1.290e-01, 1.504e-01, 2.747e-02, 1.253e-01, 7.507e-02, -6.811e-02));
	r += mul(s0_1, min16float4x4(-7.365e-03, 7.641e-02, -5.377e-02, 3.454e-02, 3.416e-01, 2.597e-02, 7.405e-03, -2.971e-02, 1.034e-01, 2.705e-01, -1.440e-02, 3.154e-01, -1.610e-01, -9.888e-02, 4.396e-02, -4.572e-03));
	r += mul(s0_2, min16float4x4(-1.009e-01, -5.675e-02, -8.784e-02, -3.155e-02, -1.785e-01, 3.509e-02, 1.013e-01, 5.932e-02, 1.890e-01, 5.522e-02, -1.442e-01, -3.448e-03, 1.567e-01, 4.566e-02, 5.466e-02, 4.088e-03));
	r += mul(s0_3, min16float4x4(2.251e-01, -5.215e-01, 1.804e-01, -1.479e-01, 1.419e-01, -5.447e-01, 3.875e-02, -1.802e-01, 8.018e-02, -4.013e-04, -2.340e-02, -4.258e-02, -7.100e-02, 3.003e-01, 3.450e-03, -1.426e-01));
	r += mul(s0_4, min16float4x4(-3.575e-01, 4.505e-01, -1.565e-01, 5.186e-02, -3.369e-01, 5.449e-01, -1.812e-02, 2.444e-01, 3.423e-01, -5.919e-01, 2.789e-01, 1.392e-01, 3.644e-01, -3.944e-01, 3.184e-01, -1.420e-01));
	r += mul(s0_5, min16float4x4(2.881e-02, -2.657e-02, -2.114e-01, 1.109e-02, 1.634e-01, -3.107e-02, -1.126e-01, -1.037e-01, 8.493e-01, -1.023e-02, -1.660e-01, -2.666e-01, 2.901e-02, 3.420e-02, 8.543e-01, -6.616e-02));
	r += mul(s0_6, min16float4x4(-1.051e-01, -3.385e-02, -1.382e-01, 1.436e-02, -1.435e-01, 2.126e-01, -1.225e-01, 5.641e-02, -8.852e-06, -7.874e-02, 4.399e-02, -7.838e-02, 7.215e-02, -4.126e-02, 2.062e-01, -1.358e-02));
	r += mul(s0_7, min16float4x4(-5.213e-03, -5.293e-01, -2.725e-02, -3.762e-02, 1.214e-02, -3.839e-02, -1.053e-01, -2.082e-02, -4.089e-01, 2.948e-01, -4.580e-02, 1.003e-01, -8.716e-02, 7.691e-01, 4.444e-01, 1.174e-01));
	r += mul(s0_8, min16float4x4(-1.897e-02, 6.285e-03, 2.042e-02, -2.127e-02, 6.232e-02, 8.295e-02, 1.323e-01, -2.469e-03, 5.282e-02, -1.087e-01, 2.456e-01, -1.707e-01, 3.608e-02, 1.138e-01, -1.328e-01, 4.134e-02));
	r += mul(s1_0, min16float4x4(-2.745e-02, 1.342e-02, -3.005e-02, -8.313e-03, 6.041e-02, -7.307e-02, 3.898e-02, 9.782e-02, 2.104e-01, -3.851e-01, 1.586e-01, -1.390e-01, 9.642e-02, -3.104e-02, 2.179e-01, 1.049e-02));
	r += mul(s1_1, min16float4x4(-4.678e-02, -5.450e-02, 3.056e-02, -1.346e-02, 2.351e-02, 9.203e-01, 3.286e-01, 1.137e+00, 6.503e-02, -2.627e-01, 1.392e-01, -2.498e-01, 1.445e-01, 5.594e-02, 9.503e-02, -2.882e-02));
	r += mul(s1_2, min16float4x4(5.480e-02, 3.955e-02, -7.299e-02, 3.024e-02, -2.040e-02, -3.545e-02, -3.048e-01, -3.921e-02, -1.925e-01, -8.869e-02, 2.193e-01, -9.007e-02, 1.118e-02, 1.225e-02, 1.418e-01, 6.644e-03));
	r += mul(s1_3, min16float4x4(-2.767e-01, 5.879e-01, -2.049e-01, 1.714e-01, -6.804e-02, 4.204e-01, 1.173e-01, 1.773e-01, -9.693e-02, -6.252e-02, 5.725e-03, 8.598e-02, 1.002e-01, -2.294e-01, 1.826e-01, 8.165e-02));
	r += mul(s1_4, min16float4x4(1.459e-01, -5.464e-01, -3.716e-01, 1.678e-02, 1.939e-01, -5.493e-01, -4.123e-01, -2.398e-01, -2.349e-01, 8.962e-01, 1.508e-01, 3.682e-01, 3.721e-02, 4.487e-01, 3.462e-01, 1.192e-01));
	r += mul(s1_5, min16float4x4(-1.303e-01, -6.432e-02, 1.306e-01, -4.452e-02, -7.210e-02, 9.850e-02, 5.713e-02, 5.176e-02, -2.294e-01, 4.554e-01, 5.999e-01, 3.077e-01, 1.942e-01, 5.814e-02, 1.037e-01, 3.760e-02));
	r += mul(s1_6, min16float4x4(6.667e-02, 9.423e-02, -5.021e-02, -4.310e-02, 6.471e-02, -3.154e-01, -5.891e-03, -4.867e-02, -2.778e-02, 3.702e-02, -1.047e-01, 1.039e-01, 2.822e-03, 3.923e-02, 2.201e-02, -3.742e-03));
	r += mul(s1_7, min16float4x4(-1.382e-01, 4.948e-01, -2.124e-01, 1.875e-02, -3.261e-02, -3.623e-02, 8.513e-02, 2.907e-02, 2.480e-01, -7.975e-01, -1.291e-01, -1.198e-01, 3.290e-01, -5.605e-01, 2.338e-01, -6.518e-02));
	r += mul(s1_8, min16float4x4(-2.790e-02, 2.539e-02, -2.147e-01, 1.422e-02, 1.131e-02, -3.690e-02, 8.057e-02, -1.537e-02, -1.392e-01, -9.786e-02, -5.498e-02, 3.282e-02, 9.309e-02, 8.285e-03, 3.253e-01, -4.518e-02));
	r += min16float4(0.002357111545279622, -0.003569206455722451, 0.0011409827275201678, 0.0005275766015984118);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-DN-conv2
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t1
//!OUT t0
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t1, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(-4.188e-02, 1.557e-02, -4.359e-02, -2.757e-03, 3.333e-02, -8.713e-02, 2.524e-02, 3.610e-03, 2.656e-02, 1.012e-02, 2.983e-02, 2.472e-02, -3.061e-02, -1.870e-02, -1.692e-02, -1.346e-02));
	r += mul(s0_1, min16float4x4(-5.169e-02, -4.128e-02, 5.421e-02, -3.869e-03, 2.035e-03, -4.788e-01, -5.795e-02, -5.378e-02, 2.055e-02, 2.511e-02, -1.655e-02, -1.750e-03, 3.221e-02, 2.842e-01, 2.123e-02, 1.192e-02));
	r += mul(s0_2, min16float4x4(-2.256e-02, -3.949e-02, 2.133e-02, -5.469e-03, 1.437e-01, -3.275e-01, -8.148e-02, -6.568e-02, -1.169e-02, 3.823e-02, 5.754e-03, 1.490e-02, -1.174e-01, 2.582e-01, 5.283e-02, 6.003e-02));
	r += mul(s0_3, min16float4x4(-1.831e-02, 6.568e-02, -7.364e-03, 9.670e-02, 1.422e-01, 8.466e-02, -6.915e-02, 3.723e-02, 6.266e-02, -7.202e-02, 2.148e-02, -1.459e-02, -1.140e-01, 6.888e-03, 8.934e-02, -5.383e-02));
	r += mul(s0_4, min16float4x4(-1.928e-02, -6.797e-01, 5.260e-01, -1.325e-01, -8.238e-02, 5.176e-01, 2.144e-01, -1.090e-01, -5.616e-02, 2.609e-01, -3.531e-02, 8.771e-02, 9.393e-02, -5.669e-01, -2.892e-01, -9.694e-02));
	r += mul(s0_5, min16float4x4(-1.050e-02, 6.828e-03, -3.500e-02, 7.028e-02, -8.472e-02, 1.687e-01, 9.671e-02, -1.860e-01, 7.225e-03, 1.222e-02, 5.112e-02, 2.133e-02, 8.178e-02, -4.164e-01, -3.593e-02, 1.317e-01));
	r += mul(s0_6, min16float4x4(-1.681e-02, 2.289e-02, -1.364e-01, -1.300e-02, -2.942e-02, 5.597e-03, 6.565e-02, -4.925e-02, -1.445e-02, 6.516e-03, 1.194e-02, -1.292e-02, 8.567e-02, 3.074e-02, -7.497e-02, 4.192e-02));
	r += mul(s0_7, min16float4x4(-1.005e-01, 1.460e-01, -6.495e-02, -4.241e-02, -2.237e-02, 1.673e-02, 2.032e-01, 4.553e-02, 4.382e-02, -6.762e-02, -4.577e-02, 3.533e-02, -1.635e-01, 1.850e-01, 2.509e-01, 2.692e-03));
	r += mul(s0_8, min16float4x4(-5.839e-02, 1.353e-01, 3.357e-02, 2.422e-02, -1.173e-02, 3.079e-02, -6.427e-02, 2.246e-02, 1.473e-02, -1.389e-02, 1.359e-02, 8.866e-03, -2.752e-01, 3.096e-01, 3.558e-01, -1.470e-01));
	r += mul(s1_0, min16float4x4(6.448e-02, 9.155e-02, -7.990e-02, 5.965e-03, 2.112e-02, 1.091e-01, -5.788e-02, 2.555e-02, -1.179e-03, -4.365e-01, 1.242e-01, -6.041e-02, -1.284e-01, 2.093e-01, -3.543e-01, -7.474e-02));
	r += mul(s1_1, min16float4x4(-4.974e-02, -2.959e-01, -1.407e-01, -1.538e-01, 4.235e-03, 4.657e-01, 2.510e-01, 1.013e-01, 1.341e-02, -5.332e-01, -1.188e-01, -5.326e-02, -7.508e-02, 7.771e-01, 5.322e-01, -1.473e-01));
	r += mul(s1_2, min16float4x4(-1.759e-02, -1.320e-01, -2.666e-02, -9.253e-02, -1.409e-01, 2.879e-01, -1.964e-02, 4.225e-02, 1.184e-02, -1.175e-01, 4.250e-02, -1.470e-01, 4.293e-02, -1.770e-02, -6.844e-02, -3.603e-02));
	r += mul(s1_3, min16float4x4(8.097e-01, -3.124e-01, -3.857e-01, 1.503e-01, -7.302e-02, -1.480e-01, -1.346e-02, -8.790e-02, -1.652e+00, -4.585e-01, -2.588e-01, -1.838e+00, -3.331e-01, -1.456e-01, -5.604e-03, 5.419e-02));
	r += mul(s1_4, min16float4x4(-5.358e-01, 1.409e-01, 1.320e-01, -3.552e-01, 3.152e-01, -4.469e-01, 6.891e-01, -1.460e-01, -1.573e-01, 1.459e-01, 4.249e-01, -1.087e-01, 8.195e-01, -8.960e-01, -5.705e-01, -1.714e+00));
	r += mul(s1_5, min16float4x4(-1.112e-02, 2.566e-02, -1.768e-01, -6.039e-02, 2.192e-01, -3.740e-01, -1.938e-01, 2.513e-01, 1.204e-02, 7.681e-03, -1.209e-01, -1.961e-02, -3.889e-02, -1.489e-01, 3.053e-01, -2.693e-01));
	r += mul(s1_6, min16float4x4(2.700e-02, -1.617e-01, -3.076e-01, -2.829e-02, -1.677e-02, 6.640e-03, 5.654e-02, -9.785e-03, 5.782e-02, -1.420e-01, -1.612e-01, -2.175e-01, -1.392e-01, 4.380e-02, 1.306e-01, 2.103e-01));
	r += mul(s1_7, min16float4x4(-4.190e-02, -8.379e-02, 3.588e-02, 1.597e-01, -8.372e-03, 3.892e-02, 1.261e-02, -6.323e-02, -8.692e-03, -1.509e-01, 1.635e-03, -2.296e-01, -1.123e-02, -5.032e-01, -2.548e-01, -4.734e-01));
	r += mul(s1_8, min16float4x4(1.002e-01, -8.276e-02, -4.601e-02, -4.901e-03, -4.993e-02, 7.159e-02, 6.470e-02, 3.030e-02, -1.111e-02, -1.559e-02, 4.328e-02, -4.016e-02, 1.055e-01, -2.629e-01, -2.250e-01, 3.090e-03));
	r += min16float4(0.0003215582109987736, -0.004332222510129213, 0.0013459711335599422, -0.004003440961241722);
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
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-DN-out
//!BLOCK_SIZE 8
//!NUM_THREADS 64
//!IN t0
//!OUT t1
#define O(t, p) t.SampleLevel(SP, pos + p * pt, 0)
#define l0(x, y) O(t0, float2(x, y))
float4 f0(float2 pt, float2 pos, min16float4 s0_0, min16float4 s0_1, min16float4 s0_2, min16float4 s0_3, min16float4 s0_4, min16float4 s0_5, min16float4 s0_6, min16float4 s0_7, min16float4 s0_8, min16float4 s1_0, min16float4 s1_1, min16float4 s1_2, min16float4 s1_3, min16float4 s1_4, min16float4 s1_5, min16float4 s1_6, min16float4 s1_7, min16float4 s1_8) {
	min16float4 r = 0.0;
	r += mul(s0_0, min16float4x4(4.757e-02, 2.332e-03, -9.931e-03, -3.362e-04, -1.714e-01, -5.873e-02, 9.875e-02, 5.872e-02, 2.152e-02, 1.344e-04, -3.296e-02, -2.159e-02, 2.095e-01, -1.135e-01, 3.436e-02, -1.018e-01));
	r += mul(s0_1, min16float4x4(2.647e-01, 2.251e-01, -5.752e-02, -1.395e-02, 7.973e-02, -1.314e-01, 9.664e-03, 5.301e-02, -4.957e-02, -1.488e-02, -3.772e-02, -3.065e-02, -7.648e-01, -2.708e-01, 4.077e-01, -9.183e-03));
	r += mul(s0_2, min16float4x4(-1.046e-02, 1.049e-01, 2.388e-02, -9.781e-03, -2.889e-03, 4.550e-02, -6.447e-03, -1.020e-02, -1.081e-02, -3.602e-03, -2.997e-02, -4.189e-02, -8.074e-02, 4.287e-01, -2.021e-01, -1.174e-01));
	r += mul(s0_3, min16float4x4(4.873e-03, 3.439e-02, 4.572e-02, 2.130e-02, 2.822e-01, 1.003e-01, -1.150e-01, 4.880e-02, -1.183e-02, -2.578e-03, 4.382e-02, 5.683e-04, -8.751e-02, -7.325e-02, 3.079e-01, -1.483e-01));
	r += mul(s0_4, min16float4x4(-4.707e-02, -3.121e-01, 5.817e-01, 3.532e-02, -3.037e-01, 1.398e-01, -3.232e-01, -4.594e-01, 5.823e-02, -1.765e-02, 2.397e-01, 1.890e-01, 5.603e-02, 1.223e+00, -1.498e+00, 9.573e-01));
	r += mul(s0_5, min16float4x4(-1.024e-01, -2.427e-01, -1.813e-01, 8.599e-02, 9.759e-03, -1.630e-01, -3.481e-03, -2.022e-03, 2.081e-02, 7.495e-02, -1.837e-02, 6.584e-02, 3.538e-01, -7.687e-01, 2.764e-01, 1.114e-01));
	r += mul(s0_6, min16float4x4(3.750e-02, 5.408e-02, -1.917e-02, 6.217e-03, 4.383e-02, 2.753e-02, 8.178e-03, -5.234e-03, -1.016e-02, -9.381e-05, -2.610e-02, -7.929e-03, -3.048e-02, -1.900e-03, -5.387e-02, 5.290e-03));
	r += mul(s0_7, min16float4x4(1.157e-01, 1.593e-02, -8.849e-02, -8.032e-02, -1.026e-01, -5.650e-02, -5.089e-02, -2.693e-02, 8.804e-03, 6.261e-03, 3.920e-03, -2.689e-02, -7.477e-02, -8.673e-02, 9.892e-02, 7.566e-02));
	r += mul(s0_8, min16float4x4(-8.586e-02, 3.303e-03, 2.139e-02, -5.552e-02, -5.625e-03, -1.497e-02, 2.422e-02, 2.536e-02, -2.244e-03, 8.524e-04, 9.748e-03, 3.357e-02, 1.439e-01, -3.711e-02, 3.506e-01, -4.013e-01));
	r += mul(s1_0, min16float4x4(-1.567e-01, 8.742e-03, -1.596e-03, 2.493e-02, -4.114e-02, 2.315e-03, 1.419e-02, 5.998e-03, -4.533e-02, 5.855e-03, 1.407e-04, 1.402e-02, 1.696e-01, -2.814e-04, -5.952e-03, -2.463e-02));
	r += mul(s1_1, min16float4x4(-3.668e-01, -4.310e-01, 1.171e-01, 5.421e-02, -2.898e-02, -9.790e-02, 1.531e-02, 1.772e-02, 3.199e-02, 8.522e-02, -2.455e-02, 2.534e-02, 1.131e-01, 3.736e-01, -5.571e-02, -4.695e-02));
	r += mul(s1_2, min16float4x4(-5.457e-02, -2.419e-01, 1.152e-02, 1.305e-02, -7.965e-03, 6.917e-03, -1.994e-02, -1.425e-02, 1.929e-01, -2.449e-01, 9.863e-02, -3.360e-02, 7.486e-03, -4.743e-02, 5.408e-02, 3.772e-02));
	r += mul(s1_3, min16float4x4(-1.389e-02, 8.334e-02, -2.744e-01, -3.545e-03, -8.377e-02, -1.255e-01, -4.819e-02, -1.544e-02, 2.174e-01, -9.580e-02, 6.050e-02, -5.652e-02, 2.446e-02, -2.924e-02, 2.469e-01, 1.455e-02));
	r += mul(s1_4, min16float4x4(5.762e-01, 2.070e-01, -1.871e-01, -5.449e-01, 4.555e-01, 4.323e-01, -7.092e-03, -4.660e-02, -1.011e+00, 4.905e-01, -4.072e-01, 7.051e-01, -4.137e-01, -2.549e-01, -1.528e-01, 3.362e-01));
	r += mul(s1_5, min16float4x4(3.376e-02, 2.095e-01, 1.749e-02, -5.735e-02, -4.155e-03, 9.471e-02, 1.545e-02, 3.528e-02, -4.334e-02, -2.869e-02, 1.038e-01, -3.779e-01, -2.410e-02, -7.308e-02, -2.635e-02, -9.839e-02));
	r += mul(s1_6, min16float4x4(-5.456e-02, -1.837e-02, 4.626e-02, 4.027e-02, -8.619e-02, -8.419e-02, -1.473e-02, -2.358e-02, 5.261e-02, -1.140e-02, 9.590e-02, -3.503e-02, 3.882e-02, 2.917e-02, -2.421e-02, -2.212e-02));
	r += mul(s1_7, min16float4x4(-1.412e-02, -6.173e-02, 8.050e-02, 6.719e-02, -2.090e-02, -4.449e-02, 1.899e-01, 1.196e-01, 1.343e-01, 8.492e-02, -2.822e-01, -1.189e-01, 2.758e-02, 2.775e-02, -7.349e-02, -9.302e-02));
	r += mul(s1_8, min16float4x4(1.480e-02, -1.724e-02, 2.375e-02, 3.126e-04, -8.507e-03, -3.228e-02, 3.748e-03, 4.051e-02, -4.286e-02, -5.649e-02, -4.176e-02, 8.313e-02, 5.221e-04, 1.443e-02, -1.076e-02, -1.281e-02));
	r += min16float4(-0.0008834633626975119, -0.0008376770419999957, -0.0015907275956124067, -0.0015832835342735052);
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
//!PASS 5
//!DESC CuNNy-2x4C-BILINEAR-CHROMA-NVL-DN-shuffle
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

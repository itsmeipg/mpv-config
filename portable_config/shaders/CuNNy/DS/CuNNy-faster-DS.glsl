// CuNNy faster DS
// Copyright (c) 2024 funnyplanter

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


//!DESC CuNNy-faster-DS-in
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
#define l0(x, y) F((LUMA_mul * texelFetch(LUMA_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(1, 1) + ivec2(0, 0), 0)).r)
shared F G[1][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			G[0][ay][ax] = l0(x - 1, y - 1);
		}
	}
	barrier();
	F s0_0_0, s0_0_1, s0_0_2, s0_1_0, s0_1_1, s0_1_2, s0_2_0, s0_2_1, s0_2_2;
	V4 r0, r1;
	r0 = V4(0.0); r1 = V4(0.0);
	s0_0_0 = G[0][xy.y+0][xy.x+0]; s0_0_1 = G[0][xy.y+0][xy.x+1];
	s0_0_2 = G[0][xy.y+0][xy.x+2]; s0_1_0 = G[0][xy.y+1][xy.x+0];
	s0_1_1 = G[0][xy.y+1][xy.x+1]; s0_1_2 = G[0][xy.y+1][xy.x+2];
	s0_2_0 = G[0][xy.y+2][xy.x+0]; s0_2_1 = G[0][xy.y+2][xy.x+1];
	s0_2_2 = G[0][xy.y+2][xy.x+2];
	r0 += V4(1.841e-01, 6.352e-01, -4.782e-02, -1.076e-02) * s0_0_0;
	r1 += V4(2.133e-02, -1.901e-02, 7.787e-02, -1.398e-02) * s0_0_0;
	r0 += V4(2.985e-02, 5.205e-01, 2.056e-02, -4.277e-02) * s0_0_1;
	r1 += V4(-6.660e-01, -5.970e-02, -3.772e-02, 3.924e-02) * s0_0_1;
	r0 += V4(2.027e-01, 4.142e-02, 2.695e-02, 4.800e-02) * s0_0_2;
	r1 += V4(1.636e-01, 4.947e-02, 2.570e-02, -1.516e-02) * s0_0_2;
	r0 += V4(3.898e-01, -1.082e+00, 1.200e+00, 1.102e+00) * s0_1_0;
	r1 += V4(-3.557e-02, -4.984e-02, -1.157e-01, 3.814e-03) * s0_1_0;
	r0 += V4(-1.053e+00, -4.080e-02, -1.137e+00, -1.012e+00) * s0_1_1;
	r1 += V4(-4.557e-01, 9.336e-01, -1.058e+00, 1.168e+00) * s0_1_1;
	r0 += V4(-3.388e-01, -4.637e-02, -7.155e-02, -7.784e-02) * s0_1_2;
	r1 += V4(1.004e+00, -5.106e-02, -3.184e-02, -1.943e-02) * s0_1_2;
	r0 += V4(2.685e-01, -6.809e-02, -4.436e-03, -6.277e-03) * s0_2_0;
	r1 += V4(-3.449e-02, -4.385e-03, 5.308e-02, 1.022e-02) * s0_2_0;
	r0 += V4(1.084e-01, 2.796e-02, -3.309e-02, 2.000e-02) * s0_2_1;
	r1 += V4(-7.496e-02, -1.793e-01, 9.452e-01, -1.191e+00) * s0_2_1;
	r0 += V4(9.098e-02, 1.648e-02, 4.042e-02, 2.891e-03) * s0_2_2;
	r1 += V4(8.861e-02, -4.284e-02, 1.191e-01, 1.793e-02) * s0_2_2;
	r0 += V4(-1.387e-02, -5.310e-05, -1.237e-02, 1.251e-02);
	r0 = max(r0, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(-1.363e-02, 3.391e-03, -8.025e-03, -1.858e-03);
	r1 = max(r1, V4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-faster-DS-conv1
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND in
//!BIND LUMA
//!SAVE conv1
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
#define l0(x, y) V4((in_mul * texelFetch(in_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0), 0)))
#define l1(x, y) V4((in_mul * texelFetch(in_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0), 0)))
shared V4 G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			G[0][ay][ax] = l0(x - 1, y - 1);
			G[1][ay][ax] = l1(x - 1, y - 1);
		}
	}
	barrier();
	V4 s0_0_0, s0_0_1, s0_0_2, s0_1_0, s0_1_1, s0_1_2, s0_2_0, s0_2_1, s0_2_2, s1_0_0, s1_0_1, s1_0_2, s1_1_0, s1_1_1, s1_1_2, s1_2_0, s1_2_1, s1_2_2;
	V4 r0, r1;
	r0 = V4(0.0); r1 = V4(0.0);
	s0_0_0 = G[0][xy.y+0][xy.x+0]; s0_0_1 = G[0][xy.y+0][xy.x+1];
	s0_0_2 = G[0][xy.y+0][xy.x+2]; s0_1_0 = G[0][xy.y+1][xy.x+0];
	s0_1_1 = G[0][xy.y+1][xy.x+1]; s0_1_2 = G[0][xy.y+1][xy.x+2];
	s0_2_0 = G[0][xy.y+2][xy.x+0]; s0_2_1 = G[0][xy.y+2][xy.x+1];
	s0_2_2 = G[0][xy.y+2][xy.x+2]; s1_0_0 = G[1][xy.y+0][xy.x+0];
	s1_0_1 = G[1][xy.y+0][xy.x+1]; s1_0_2 = G[1][xy.y+0][xy.x+2];
	s1_1_0 = G[1][xy.y+1][xy.x+0]; s1_1_1 = G[1][xy.y+1][xy.x+1];
	s1_1_2 = G[1][xy.y+1][xy.x+2]; s1_2_0 = G[1][xy.y+2][xy.x+0];
	s1_2_1 = G[1][xy.y+2][xy.x+1]; s1_2_2 = G[1][xy.y+2][xy.x+2];
	r0 += M4(-7.663e-02, 1.421e-01, 1.549e-01, 2.085e-01, -6.340e-02, -1.030e-02, -3.478e-02, -5.408e-02, 3.643e-01, 2.923e-01, -2.119e-01, -3.445e-01, -9.193e-02, -2.127e-01, 1.204e-01, 1.174e-01) * s0_0_0;
	r1 += M4(9.725e-02, 1.121e-01, 2.040e-01, -2.822e-01, -6.824e-02, 4.894e-02, -2.418e-02, 8.716e-02, 3.528e-02, -3.561e-01, -3.812e-01, 2.222e-01, -9.342e-02, 3.243e-01, 2.124e-01, 6.468e-02) * s0_0_0;
	r0 += M4(1.460e-01, 9.908e-01, 2.230e-01, 2.065e-01, 1.094e-01, -1.101e-01, -5.107e-02, -1.674e-02, 7.039e-01, -3.045e-01, -4.092e-01, -2.473e-01, -1.078e-01, -2.222e-01, 3.897e-01, 2.243e-01) * s0_0_1;
	r1 += M4(1.175e-01, 6.697e-03, 1.754e-02, -1.665e-01, -2.415e-02, 7.703e-02, -5.508e-02, 2.079e-02, 5.567e-02, -5.952e-01, -1.602e-01, 4.147e-01, 6.294e-02, -1.925e-01, 5.467e-01, -9.454e-02) * s0_0_1;
	r0 += M4(-1.044e-01, 7.009e-02, -9.133e-03, 3.941e-02, 5.505e-02, -5.195e-02, -3.877e-02, 2.339e-02, 3.200e-01, -5.495e-01, 4.739e-01, 7.559e-01, -3.470e-01, 1.507e-01, -4.385e-01, -5.506e-01) * s0_0_2;
	r1 += M4(-4.952e-02, 8.532e-02, 1.499e-01, 2.331e-01, -2.572e-02, 1.782e-01, -3.535e-02, 3.732e-03, 5.902e-02, 6.899e-01, 3.742e-01, -1.899e-01, -9.289e-03, -2.277e-01, -4.079e-01, 1.491e-01) * s0_0_2;
	r0 += M4(7.441e-01, -4.893e-01, -4.940e-02, 3.516e-01, 1.274e-01, 1.009e-01, 9.204e-02, 2.698e-02, -3.041e-02, 4.694e-01, 1.827e-01, -1.471e-01, 3.174e-02, -2.228e-01, -1.606e-01, -8.266e-02) * s0_1_0;
	r1 += M4(-4.457e-01, 3.350e-01, -1.957e-02, -4.816e-01, -3.425e-02, -2.861e-02, 6.677e-02, -5.523e-02, -6.772e-01, -5.938e-01, -1.179e-01, 4.580e-01, 5.801e-01, 5.470e-01, 6.194e-02, -2.463e-01) * s0_1_0;
	r0 += M4(4.152e-01, -3.880e-02, -7.839e-01, -8.066e-01, 3.430e-01, 1.147e-01, 1.984e-01, 1.905e-01, -7.322e-01, 1.388e+00, 1.022e+00, 8.316e-01, -2.921e-01, -9.829e-01, -5.895e-01, -6.932e-01) * s0_1_1;
	r1 += M4(7.414e-02, 1.074e+00, -2.447e-01, 5.288e-01, 8.869e-03, -1.027e+00, 1.410e-01, -1.417e-02, 2.879e-01, -1.973e-01, 1.109e+00, -6.162e-01, -7.068e-02, -2.169e+00, -8.054e-01, 1.803e-01) * s0_1_1;
	r0 += M4(-2.910e-01, -6.089e-02, 1.935e-01, 1.607e-01, 9.053e-02, 2.105e-01, 2.230e-02, -6.189e-02, 2.203e-01, -4.363e-01, -4.962e-01, -2.868e-01, 1.076e-01, -8.561e-01, 6.309e-01, 5.567e-01) * s0_1_2;
	r1 += M4(-2.024e-02, -9.464e-02, 8.342e-02, 2.088e-01, -1.743e-01, -1.331e+00, -2.166e-01, 1.202e-01, -4.932e-01, -9.776e-01, -6.365e-01, -6.352e-01, 4.617e-01, 6.627e-01, -2.748e-01, 2.036e-01) * s0_1_2;
	r0 += M4(7.913e-02, 1.515e-01, 9.149e-02, 1.192e-01, -8.378e-02, 4.502e-02, -7.415e-02, -2.729e-02, -7.739e-02, -9.160e-01, 6.477e-02, -4.651e-02, -1.719e-01, 7.661e-01, -1.574e-01, -8.131e-02) * s0_2_0;
	r1 += M4(-1.320e-01, -5.000e-01, 3.096e-02, 6.288e-02, -1.223e-01, 1.574e-01, 4.199e-02, -6.187e-03, 3.858e-01, 2.723e-01, -1.672e-01, 1.031e-01, -2.936e-01, 9.854e-02, 1.441e-01, -4.540e-02) * s0_2_0;
	r0 += M4(-1.243e-01, 7.520e-02, -7.802e-02, -5.564e-02, -1.344e+00, -1.840e-01, -7.486e-02, 1.425e-01, -3.025e-02, -3.147e-01, -8.535e-01, -1.483e-01, 5.370e-02, 6.685e-01, 9.786e-01, 1.914e-01) * s0_2_1;
	r1 += M4(9.786e-02, -2.074e-02, -1.098e-01, 1.487e-01, 5.801e-01, -2.539e-02, -1.548e-01, -1.156e-01, -1.546e-02, 1.832e-01, 1.519e-01, -3.756e-02, 5.521e-02, 9.590e-01, 9.309e-02, -6.811e-02) * s0_2_1;
	r0 += M4(-1.768e-01, 7.982e-03, 1.749e-01, -2.201e-02, -1.996e-01, 5.789e-02, -4.643e-01, -8.455e-02, -4.122e-01, -8.059e-02, 2.548e-01, 2.823e-01, 1.749e-01, 2.152e-01, -7.246e-01, -4.945e-01) * s0_2_2;
	r1 += M4(-6.555e-02, -5.394e-02, -1.063e-03, 2.475e-01, -7.437e-02, 7.837e-02, -3.108e-01, -6.353e-02, 3.479e-01, 5.086e-01, -1.732e-02, -2.190e-01, -3.032e-01, -3.517e-01, -2.417e-01, 1.706e-01) * s0_2_2;
	r0 += M4(7.559e-02, 2.563e-02, -3.082e-02, -1.233e-01, -1.028e-01, -2.552e-01, -3.301e-02, 1.675e-01, 4.092e-01, -6.900e-02, 1.495e-02, 2.450e-01, -8.339e-01, 1.591e-01, -2.040e-01, -2.920e-01) * s1_0_0;
	r1 += M4(-9.624e-02, 7.511e-02, -8.263e-02, 1.372e-01, 4.945e-01, -1.857e-02, -1.477e-01, 1.598e-01, 9.247e-02, -6.435e-01, -7.355e-02, 3.146e-01, -2.822e-01, 4.209e-01, -1.382e-01, 1.626e-01) * s1_0_0;
	r0 += M4(5.148e-02, -6.430e-02, 1.077e-01, 1.546e-01, 9.261e-02, 6.780e-01, -1.326e-03, 1.487e-02, 2.940e-01, -1.161e+00, -6.738e-01, -6.122e-01, -5.795e-01, -4.148e-01, 7.789e-01, 9.231e-01) * s1_0_1;
	r1 += M4(1.135e-01, -2.686e-01, 9.982e-02, -3.662e-02, -6.073e-01, -1.015e-01, 2.663e-01, -5.995e-02, -4.639e-01, -2.090e-01, 1.921e-01, 2.947e-01, 6.033e-01, -1.064e+00, 1.532e-01, -5.044e-01) * s1_0_1;
	r0 += M4(-1.882e-02, 1.165e-02, -6.917e-02, 1.074e-02, 5.328e-02, -7.954e-02, 1.627e-01, -2.674e-02, -1.038e-01, -1.045e-01, 6.624e-02, 1.700e-01, 1.569e-01, -2.650e-01, 1.132e-01, 3.932e-01) * s1_0_2;
	r1 += M4(2.396e-03, 1.984e-01, 2.960e-02, -3.485e-02, 1.499e-01, -4.023e-01, 6.120e-02, 4.472e-03, 4.650e-02, -2.913e-01, 1.174e-01, -7.750e-02, -5.531e-02, 9.205e-01, 1.533e-01, 1.691e-02) * s1_0_2;
	r0 += M4(2.012e-01, 8.457e-02, 3.164e-02, 5.096e-03, 4.717e-01, -6.177e-01, 1.389e-01, 1.692e-01, -9.594e-02, -3.213e-01, 8.812e-02, -8.570e-02, 9.884e-02, 3.568e-01, 9.757e-02, -1.210e-01) * s1_1_0;
	r1 += M4(-2.764e-02, -1.877e-01, -2.067e-01, 3.519e-01, 9.096e-01, 1.441e-01, -4.108e-02, -1.762e-01, -9.100e-02, -1.490e+00, 5.016e-02, 9.793e-02, -2.920e-01, 6.426e-01, 7.039e-02, 2.913e-02) * s1_1_0;
	r0 += M4(5.001e-02, 2.643e-01, 2.460e-01, 3.622e-01, 3.344e-01, 2.042e-01, -9.870e-01, -8.076e-01, 1.119e+00, 7.377e-01, 9.323e-01, 2.485e-01, -1.340e+00, -1.724e-01, -7.140e-01, 9.552e-02) * s1_1_1;
	r1 += M4(6.136e-02, -6.577e-01, 5.293e-01, -2.934e-01, -6.628e-01, 1.107e+00, -1.155e+00, 1.534e+00, -1.161e-01, -1.960e-01, 2.739e-01, 2.137e-01, 2.238e-01, -1.387e+00, 1.763e-01, -8.632e-01) * s1_1_1;
	r0 += M4(-5.452e-02, -4.595e-03, 7.983e-02, 3.814e-02, 9.946e-02, 5.720e-01, -2.350e-02, 8.361e-02, -3.569e-01, 5.005e-01, -7.861e-02, -2.192e-01, 2.640e-01, -4.289e-01, 5.555e-02, 3.096e-01) * s1_1_2;
	r1 += M4(7.950e-03, -1.320e-01, 1.743e-02, 6.681e-02, 7.498e-02, -5.283e-02, 8.109e-01, 3.370e-01, 1.304e-01, -1.716e-01, -4.330e-01, 2.658e-01, -1.724e-01, 3.320e-01, -8.021e-02, -4.116e-01) * s1_1_2;
	r0 += M4(-3.481e-02, -2.516e-01, 1.353e-01, -1.547e-01, -1.779e-01, 5.957e-01, -1.141e-01, 4.732e-02, -5.828e-02, -2.705e-01, -7.203e-02, -8.375e-02, -4.311e-02, -1.354e-01, 3.522e-02, 9.431e-03) * s1_2_0;
	r1 += M4(9.076e-02, -8.925e-01, -9.558e-02, 1.097e-01, -1.012e-02, -4.777e-01, 3.113e-03, -2.357e-01, 1.792e-01, 2.779e-01, 3.307e-02, -1.450e-01, -4.145e-02, 1.528e-01, -4.725e-02, 4.254e-02) * s1_2_0;
	r0 += M4(3.135e-01, -2.764e-01, -6.386e-03, 3.561e-01, -5.326e-01, -6.603e-01, 9.730e-01, 5.254e-01, -1.579e-02, 9.443e-03, 1.962e-02, 7.858e-02, 1.776e-02, 2.627e-01, -7.056e-02, -1.353e-01) * s1_2_1;
	r1 += M4(3.831e-02, 2.510e-01, 2.175e-01, -3.168e-01, -5.216e-02, -4.424e-01, 6.526e-02, -1.267e+00, -4.455e-02, 3.123e-02, 2.041e-02, -1.576e-01, 1.544e-02, 3.633e-02, 3.332e-02, 2.111e-01) * s1_2_1;
	r0 += M4(7.658e-02, -5.559e-02, -1.130e-03, 1.198e-01, -1.966e-01, -4.301e-01, -9.747e-02, -1.590e-01, -5.828e-04, 1.346e-01, 6.507e-02, -6.519e-02, 1.473e-01, -1.341e-02, -9.568e-02, 3.601e-02) * s1_2_2;
	r1 += M4(3.183e-02, 1.689e-01, -2.757e-02, -1.654e-03, -3.069e-01, 2.881e-01, 1.625e-01, -2.787e-01, -8.500e-02, 1.489e-01, 5.631e-02, -1.842e-01, 9.155e-02, -4.163e-03, -4.236e-02, 8.374e-02) * s1_2_2;
	r0 += V4(2.011e-02, -1.789e-02, -2.190e-03, 9.126e-03);
	r0 = max(r0, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(-1.837e-02, -1.633e-03, -4.395e-03, -7.387e-03);
	r1 = max(r1, V4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-faster-DS-conv2
//!HOOK LUMA
//!COMPUTE 16 8 8 8
//!BIND conv1
//!BIND LUMA
//!SAVE conv2
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
#define l0(x, y) V4((conv1_mul * texelFetch(conv1_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0), 0)))
#define l1(x, y) V4((conv1_mul * texelFetch(conv1_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0), 0)))
shared V4 G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 1);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			G[0][ay][ax] = l0(x - 1, y - 1);
			G[1][ay][ax] = l1(x - 1, y - 1);
		}
	}
	barrier();
	V4 s0_0_0, s0_0_1, s0_0_2, s0_1_0, s0_1_1, s0_1_2, s0_2_0, s0_2_1, s0_2_2, s1_0_0, s1_0_1, s1_0_2, s1_1_0, s1_1_1, s1_1_2, s1_2_0, s1_2_1, s1_2_2;
	V4 r0, r1;
	r0 = V4(0.0); r1 = V4(0.0);
	s0_0_0 = G[0][xy.y+0][xy.x+0]; s0_0_1 = G[0][xy.y+0][xy.x+1];
	s0_0_2 = G[0][xy.y+0][xy.x+2]; s0_1_0 = G[0][xy.y+1][xy.x+0];
	s0_1_1 = G[0][xy.y+1][xy.x+1]; s0_1_2 = G[0][xy.y+1][xy.x+2];
	s0_2_0 = G[0][xy.y+2][xy.x+0]; s0_2_1 = G[0][xy.y+2][xy.x+1];
	s0_2_2 = G[0][xy.y+2][xy.x+2]; s1_0_0 = G[1][xy.y+0][xy.x+0];
	s1_0_1 = G[1][xy.y+0][xy.x+1]; s1_0_2 = G[1][xy.y+0][xy.x+2];
	s1_1_0 = G[1][xy.y+1][xy.x+0]; s1_1_1 = G[1][xy.y+1][xy.x+1];
	s1_1_2 = G[1][xy.y+1][xy.x+2]; s1_2_0 = G[1][xy.y+2][xy.x+0];
	s1_2_1 = G[1][xy.y+2][xy.x+1]; s1_2_2 = G[1][xy.y+2][xy.x+2];
	r0 += M4(2.040e-02, 2.957e-02, -4.139e-02, -1.474e-02, -8.813e-02, -4.213e-02, 1.383e-01, 2.684e-02, 2.119e-02, -9.056e-02, 1.067e-01, 1.165e-01, -1.822e-02, 1.323e-01, -6.481e-02, -1.316e-01) * s0_0_0;
	r1 += M4(-7.275e-02, -1.340e-03, -2.362e-02, 7.297e-03, 7.839e-02, 8.713e-02, 1.939e-02, -1.154e-01, 5.174e-02, 7.905e-02, 9.249e-02, 1.479e-02, -6.634e-02, 1.838e-02, -3.260e-02, 2.395e-03) * s0_0_0;
	r0 += M4(-2.729e-02, -7.279e-02, 9.508e-03, 1.841e-02, -9.644e-02, 9.051e-02, 2.194e-01, 6.204e-02, 1.017e-01, 2.656e-01, 7.327e-01, 7.207e-01, -1.528e-01, -2.300e-01, -5.527e-01, -3.623e-01) * s0_0_1;
	r1 += M4(-4.729e-02, 1.763e-02, 5.056e-02, -5.293e-03, -5.632e-02, 3.979e-01, 1.370e-01, -6.760e-02, -1.188e+01, -5.643e-02, 2.881e-01, 1.052e-01, -4.765e-01, -9.803e-02, -1.968e-01, -1.480e-01) * s0_0_1;
	r0 += M4(-1.613e-02, -1.112e-01, 1.509e-01, 1.209e-01, -9.932e-02, -1.287e-01, 2.991e-02, 1.293e-01, 5.240e-02, -3.353e-02, 7.690e-02, 7.208e-02, -4.430e-03, -1.867e-02, 1.032e-02, -7.548e-02) * s0_0_2;
	r1 += M4(1.292e-02, -1.801e-01, -9.793e-02, -6.997e-02, -8.394e-03, 3.018e-01, -2.093e-01, -2.939e-01, 7.056e-03, -1.480e-02, -2.830e-02, 5.188e-03, -8.225e-02, 1.008e-01, 1.536e-02, 7.665e-03) * s0_0_2;
	r0 += M4(-1.564e-02, 7.343e-02, 3.834e-03, -2.757e-02, -8.833e-02, -2.111e-01, -6.807e-02, 2.400e-02, -1.091e-01, -1.323e-01, -1.966e-03, -3.976e-03, -2.001e-02, 1.812e-01, 1.540e-01, -6.223e-03) * s0_1_0;
	r1 += M4(1.663e-02, 8.467e-02, 1.166e-01, 3.958e-02, 1.389e-03, -1.765e-01, -8.389e-02, 8.923e-03, 7.593e-02, -9.106e-02, -1.558e-01, -1.418e-01, 8.568e-02, 3.155e-01, 2.210e-01, 7.936e-02) * s0_1_0;
	r0 += M4(-3.580e-02, -3.213e-01, -1.890e-01, 3.715e-02, -1.946e-01, 7.495e-02, -4.804e-01, 6.959e-02, 4.888e-03, 7.884e-02, -7.305e-02, -2.018e-01, 1.135e-01, -7.341e-02, 5.109e-01, 1.362e-01) * s0_1_1;
	r1 += M4(-1.748e-01, -1.832e-01, -4.572e-01, -2.290e-01, 2.606e-01, 1.860e-01, -9.592e-02, 5.936e-02, -2.574e-01, 4.423e-02, 5.850e-02, 1.265e-01, 7.376e-01, -7.793e-01, -5.701e-02, -8.581e-02) * s0_1_1;
	r0 += M4(-1.948e-01, 1.401e-01, -3.096e-01, -1.516e-01, 1.298e-01, -6.584e-02, 1.317e-01, 9.351e-02, 4.650e-02, 1.596e-02, 1.048e-01, 3.636e-02, 2.198e-02, -1.151e-02, 1.948e-01, 5.721e-02) * s0_1_2;
	r1 += M4(-2.420e-01, -4.607e-01, 6.850e-02, -3.942e-02, 2.726e-01, 4.367e-02, -4.976e-02, -3.895e-01, 9.621e-02, -1.982e-01, 5.237e-02, -1.605e-02, 1.494e-01, 2.257e-01, 5.214e-02, 8.357e-02) * s0_1_2;
	r0 += M4(5.345e-03, -1.266e-02, -1.340e-02, 1.373e-02, -1.665e-01, -2.789e-02, 4.373e-02, -4.251e-03, -9.925e-03, -1.726e-02, -1.833e-02, 1.325e-02, -1.761e-01, -7.324e-02, 2.767e-02, 2.635e-02) * s0_2_0;
	r1 += M4(-2.614e-03, 8.082e-02, 8.166e-03, 5.273e-02, -4.674e-03, 8.181e-02, -4.603e-02, -1.782e-01, 9.096e-02, -2.568e-02, -2.295e-02, -3.116e-02, -2.226e-02, -8.219e-02, -1.611e-01, -1.336e-01) * s0_2_0;
	r0 += M4(-2.327e-02, 6.647e-02, 6.583e-02, 1.068e-02, -1.013e-01, 5.594e-02, 1.318e-01, -4.243e-02, 3.944e-02, -2.320e-03, -3.484e-03, 1.715e-02, -1.107e-01, -4.920e-02, -1.304e-01, -1.910e-02) * s0_2_1;
	r1 += M4(-3.410e-02, -3.021e-02, 3.805e-02, -2.732e-01, -5.040e-02, -4.061e-02, 3.308e-02, -7.598e-02, 2.597e-02, -2.060e-02, 4.019e-03, 8.301e-02, -4.823e-02, 2.435e-01, -1.662e-03, -1.096e-01) * s0_2_1;
	r0 += M4(-1.698e-03, -1.163e-02, 7.495e-02, -2.328e-02, 5.635e-02, 7.737e-03, -7.139e-02, -6.520e-03, 2.684e-02, 3.258e-03, 8.611e-04, 1.124e-02, -4.175e-02, -5.182e-03, -8.861e-02, 2.097e-02) * s0_2_2;
	r1 += M4(-5.396e-02, -4.404e-01, 1.506e-02, 1.593e-01, -3.405e-02, 2.764e-01, -4.644e-03, -4.847e-02, 1.053e-02, 4.830e-03, 3.484e-03, -1.794e-02, 5.356e-02, 8.422e-03, 1.303e-02, 2.536e-02) * s0_2_2;
	r0 += M4(-8.023e-03, -5.924e-03, 2.636e-02, -2.509e-02, 2.470e-02, -1.380e-01, -5.782e-03, -5.052e-02, 1.688e-01, 1.832e-01, 3.478e-02, -8.143e-02, -3.821e-02, 1.970e-02, -3.557e-02, -8.863e-02) * s1_0_0;
	r1 += M4(3.889e-02, -5.780e-02, 5.769e-03, -3.631e-03, 3.155e-03, -1.143e-01, -2.583e-02, 3.050e-02, 2.073e-02, 3.078e-02, 8.859e-02, 1.772e-01, 9.422e-03, -1.047e-01, -5.798e-02, -2.176e-02) * s1_0_0;
	r0 += M4(9.191e-02, -4.794e-03, -1.199e-02, 2.794e-02, -1.075e-01, -2.725e-01, -3.939e-01, 8.939e-02, 7.651e-02, 3.626e-02, -1.898e-01, -1.577e-01, -1.326e-01, -1.549e-01, -3.019e-01, 7.500e-02) * s1_0_1;
	r1 += M4(8.443e-02, -5.202e-02, 8.450e-02, 1.691e-02, -1.737e-01, -1.578e-01, -5.102e-01, -1.183e-01, -8.180e-02, -1.518e-01, -1.402e-03, 8.463e-02, 5.013e-02, 7.583e-02, -6.568e-02, -1.433e-01) * s1_0_1;
	r0 += M4(8.182e-02, 6.523e-02, 9.499e-02, -5.155e-02, -5.839e-02, 3.512e-02, -4.269e-01, -7.345e-02, 5.060e-02, 7.813e-03, -8.326e-02, 5.609e-03, -5.643e-02, 8.480e-02, 1.809e-01, -9.497e-02) * s1_0_2;
	r1 += M4(1.699e-02, 4.580e-01, 1.250e-01, 1.131e-01, -5.320e-03, -6.907e-02, 4.526e-02, 2.113e-02, 3.848e-02, -2.802e-02, -1.385e-02, -2.770e-02, -2.118e-02, 1.716e-01, 5.921e-02, 6.277e-02) * s1_0_2;
	r0 += M4(5.991e-02, 3.355e-02, -3.860e-02, -4.014e-02, -1.973e-01, -2.029e-01, -9.498e-02, -9.654e-02, 3.990e-02, 4.861e-01, 1.698e-03, 1.028e-01, -4.528e-02, 2.312e-02, -1.460e-01, -1.271e-01) * s1_1_0;
	r1 += M4(1.006e-02, 9.996e-03, 1.619e-02, 6.096e-02, -5.723e-02, -3.503e-01, -4.243e-01, -3.489e-01, -3.582e-02, 2.588e-01, 3.470e-01, 1.343e-01, -1.864e-01, -3.055e-01, -8.930e-02, -7.177e-02) * s1_1_0;
	r0 += M4(8.875e-01, -1.447e-01, -3.050e-02, 8.667e-02, -2.120e-01, -2.846e-01, -2.920e-01, -3.130e-01, -5.285e-02, 1.174e-01, 1.538e-01, 5.451e-02, -5.173e-01, -5.433e-01, -1.176e+00, -5.879e-01) * s1_1_1;
	r1 += M4(6.542e-02, -2.783e-01, 3.859e-01, 7.560e-01, -3.055e-01, -4.049e-01, -2.650e-01, -3.358e-01, -6.037e-02, 1.954e-01, 2.568e-01, 1.902e-01, -3.378e-01, -8.019e-01, -1.096e+00, -7.598e-01) * s1_1_1;
	r0 += M4(-6.775e-03, -2.169e-02, -1.821e-01, 7.405e-02, -2.202e-01, -1.357e-03, -2.958e-01, -2.941e-01, 1.888e-02, -1.216e-02, -3.228e-02, 1.202e-02, -8.473e-02, 1.122e-02, -4.641e-01, -1.101e-01) * s1_1_2;
	r1 += M4(-3.979e-02, -4.877e-01, -3.252e-01, -2.115e-01, -1.645e-01, -2.383e-01, -1.980e-01, -1.416e-01, -1.179e-01, -2.168e-01, -7.499e-02, -4.889e-02, -2.986e-01, 2.140e-01, 7.529e-02, 5.029e-02) * s1_1_2;
	r0 += M4(-3.866e-02, 5.336e-02, 1.969e-02, -1.309e-02, -4.117e-02, -1.277e-01, 1.098e-02, -2.979e-04, 1.645e-01, -6.688e-02, -1.120e-01, -3.887e-02, 8.893e-02, 8.693e-03, 8.916e-02, 5.859e-02) * s1_2_0;
	r1 += M4(-2.167e-02, 4.283e-02, -1.483e-04, 1.438e-02, -8.832e-02, -3.901e-02, -2.865e-02, -3.585e-01, 9.253e-02, 8.678e-02, 3.639e-02, 3.312e-01, -2.544e-02, -5.309e-02, 9.057e-02, 7.540e-02) * s1_2_0;
	r0 += M4(1.294e-01, 2.818e-02, -5.550e-02, -7.251e-02, -2.291e-01, -1.072e-01, -1.421e-01, -1.375e-02, 3.095e-02, -7.837e-02, -2.134e-01, -1.042e-01, -1.556e-01, 1.218e-01, 1.792e-01, 7.735e-02) * s1_2_1;
	r1 += M4(-1.323e-01, 1.050e-02, -9.605e-03, 9.924e-03, -2.725e-01, -5.317e-01, -1.556e-01, -1.940e-01, -1.184e-01, 1.777e-01, -1.294e-01, -7.498e-03, -7.643e-02, -2.979e-01, 8.255e-02, -2.900e-01) * s1_2_1;
	r0 += M4(2.121e-02, 5.037e-02, 1.128e-01, -3.922e-02, -1.877e-01, -3.367e-03, -1.401e-01, -5.277e-02, -4.964e-03, 2.084e-02, -1.897e-02, -4.794e-02, 1.350e-01, 7.989e-02, 7.025e-02, 6.640e-03) * s1_2_2;
	r1 += M4(-1.575e-01, -2.500e-01, 1.242e-01, 5.875e-02, -1.509e-01, -1.773e-01, -7.007e-02, -1.519e-01, -7.593e-02, 4.236e-02, 1.510e-02, -4.527e-02, -3.464e-02, 7.868e-02, 9.581e-02, 1.613e-01) * s1_2_2;
	r0 += V4(1.122e-03, 3.541e-04, -4.234e-03, -5.136e-03);
	r0 = max(r0, V4(0.0));
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0));
	r1 += V4(-6.046e-03, -2.563e-03, -1.055e-03, 1.032e-03);
	r1 = max(r1, V4(0.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r1));
}

//!DESC CuNNy-faster-DS-out-shuffle
//!HOOK LUMA
//!COMPUTE 16 16 8 8
//!BIND conv2
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
#define l0(x, y) V4((conv2_mul * texelFetch(conv2_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(0, 0), 0)))
#define l1(x, y) V4((conv2_mul * texelFetch(conv2_raw, clamp(pos + ivec2(x, y), ivec2(0), sz) * ivec2(2, 1) + ivec2(1, 0), 0)))
shared V4 G[2][10][10];
void hook() {
	ivec2 xy = ivec2(gl_LocalInvocationID.xy);
	ivec2 pos = ivec2(gl_WorkGroupID.xy) * ivec2(8, 8) + xy;
	ivec2 opos = pos * ivec2(2, 2);
	ivec2 sz = ivec2(LUMA_size) - ivec2(1);
	for (int y = 0; y < 10; y += 8) {
		int ay = xy.y + y;
		if (ay >= 10) break;
		for (int x = 0; x < 10; x += 8) {
			int ax = xy.x + x;
			if (ax >= 10) break;
			G[0][ay][ax] = l0(x - 1, y - 1);
			G[1][ay][ax] = l1(x - 1, y - 1);
		}
	}
	barrier();
	V4 s0_0_0, s0_0_1, s0_0_2, s0_1_0, s0_1_1, s0_1_2, s0_2_0, s0_2_1, s0_2_2, s1_0_0, s1_0_1, s1_0_2, s1_1_0, s1_1_1, s1_1_2, s1_2_0, s1_2_1, s1_2_2;
	V4 r0;
	r0 = V4(0.0);
	s0_0_0 = G[0][xy.y+0][xy.x+0]; s0_0_1 = G[0][xy.y+0][xy.x+1];
	s0_0_2 = G[0][xy.y+0][xy.x+2]; s0_1_0 = G[0][xy.y+1][xy.x+0];
	s0_1_1 = G[0][xy.y+1][xy.x+1]; s0_1_2 = G[0][xy.y+1][xy.x+2];
	s0_2_0 = G[0][xy.y+2][xy.x+0]; s0_2_1 = G[0][xy.y+2][xy.x+1];
	s0_2_2 = G[0][xy.y+2][xy.x+2]; s1_0_0 = G[1][xy.y+0][xy.x+0];
	s1_0_1 = G[1][xy.y+0][xy.x+1]; s1_0_2 = G[1][xy.y+0][xy.x+2];
	s1_1_0 = G[1][xy.y+1][xy.x+0]; s1_1_1 = G[1][xy.y+1][xy.x+1];
	s1_1_2 = G[1][xy.y+1][xy.x+2]; s1_2_0 = G[1][xy.y+2][xy.x+0];
	s1_2_1 = G[1][xy.y+2][xy.x+1]; s1_2_2 = G[1][xy.y+2][xy.x+2];
	r0 += M4(-3.405e-02, 1.866e-03, -4.929e-03, 2.498e-03, 1.344e-03, 1.597e-03, 1.249e-06, 1.194e-03, 4.480e-02, 1.199e-02, 2.597e-03, 3.033e-03, 1.905e-03, 2.746e-04, 5.966e-04, 1.858e-04) * s0_0_0;
	r0 += M4(9.978e-03, -1.261e-01, 1.023e-02, 3.649e-02, 1.247e-02, 5.682e-04, 1.964e-03, -5.054e-03, 3.254e-02, 8.324e-02, -5.706e-04, -3.023e-03, -1.341e-03, 1.164e-03, -2.312e-03, -3.004e-04) * s0_0_1;
	r0 += M4(-8.513e-03, 7.948e-03, -6.436e-03, 8.153e-03, 3.006e-02, 8.032e-02, 1.221e-02, -1.041e-02, 6.844e-04, 1.297e-02, -1.457e-04, -3.221e-03, 1.181e-03, 6.044e-06, 1.719e-03, 6.203e-04) * s0_0_2;
	r0 += M4(-8.863e-02, -1.372e-02, -1.005e-01, -4.049e-03, -4.020e-03, -6.467e-04, 3.124e-03, 1.076e-03, -2.192e-01, -4.211e-02, 1.544e-02, -2.595e-02, 7.494e-02, 1.773e-02, 1.083e-02, 4.929e-05) * s0_1_0;
	r0 += M4(3.623e-01, -2.477e-01, 3.233e-01, -4.131e-01, 2.759e-01, 2.544e-02, 1.938e-01, 8.423e-03, -6.395e-02, -5.025e-01, 2.066e-01, 2.500e-01, 2.303e-01, 2.158e-01, -5.981e-03, 2.667e-02) * s0_1_1;
	r0 += M4(-3.041e-03, 1.372e-01, 8.653e-03, 9.107e-02, -5.238e-02, -3.584e-01, -4.477e-02, -2.582e-02, -1.886e-02, 2.521e-02, -2.874e-03, 1.971e-02, 5.468e-03, 8.579e-02, 1.047e-02, -5.278e-03) * s0_1_2;
	r0 += M4(-7.336e-03, 1.523e-02, -5.704e-03, -3.667e-03, 7.526e-03, -9.237e-04, -1.955e-03, -2.011e-03, -5.918e-03, 1.658e-02, 2.581e-02, -1.182e-02, 1.295e-02, -1.108e-02, -1.313e-01, 2.127e-02) * s0_2_0;
	r0 += M4(-2.815e-03, -1.436e-03, 6.285e-02, 1.012e-02, 3.665e-02, 2.656e-03, 1.262e-01, 2.306e-02, 1.212e-02, 1.305e-02, -2.299e-02, 6.118e-02, -4.455e-02, -5.602e-04, -1.577e-01, -3.545e-01) * s0_2_1;
	r0 += M4(1.194e-03, -2.070e-03, -9.820e-03, 4.030e-02, -6.212e-03, -1.560e-02, -9.035e-03, -2.529e-01, 2.606e-03, 1.139e-02, 8.109e-03, -2.455e-02, 3.804e-03, -1.115e-02, 2.094e-03, 5.976e-02) * s0_2_2;
	r0 += M4(-6.238e-02, -1.602e-02, -2.519e-04, -3.830e-03, 7.061e-02, -7.334e-03, 3.650e-02, -6.759e-03, 2.757e-03, -5.707e-03, -4.980e-03, -1.400e-03, 3.601e-02, 4.695e-03, 7.937e-03, -1.810e-03) * s1_0_0;
	r0 += M4(-3.711e-02, -6.958e-02, 7.818e-03, 3.231e-03, -2.212e-01, 2.911e-02, -1.318e-02, -4.430e-02, 5.311e-02, -5.339e-04, -2.148e-02, 1.243e-03, -8.964e-02, 1.333e-01, -8.387e-03, -2.069e-02) * s1_0_1;
	r0 += M4(-1.642e-02, -3.889e-02, -6.545e-04, 4.715e-03, -6.440e-03, -9.727e-03, -1.740e-03, 2.130e-02, 1.148e-02, -2.855e-02, -6.759e-03, 4.567e-03, 2.785e-03, -1.011e-02, 1.180e-02, 1.256e-03) * s1_0_2;
	r0 += M4(1.704e-01, 1.137e-02, -2.527e-02, 3.733e-03, 1.131e-02, -1.142e-03, 6.042e-02, -1.138e-02, 7.124e-02, 5.341e-04, 1.970e-02, 9.909e-03, 7.183e-03, 3.415e-03, 7.070e-02, -3.441e-03) * s1_1_0;
	r0 += M4(6.165e-02, 2.959e-01, -3.409e-01, -3.154e-01, 5.732e-02, 1.684e-01, -3.896e-01, 2.153e-01, -6.450e-01, 1.144e-01, 1.763e-01, 1.618e-01, -7.177e-02, 9.545e-02, -6.819e-01, 2.529e-01) * s1_1_1;
	r0 += M4(1.359e-02, -6.142e-03, 2.887e-02, -4.918e-02, 2.955e-02, -8.662e-02, 5.206e-02, -7.300e-02, 1.543e-02, 1.431e-01, -4.787e-02, 1.971e-02, 7.697e-03, 4.190e-02, 6.247e-02, 4.181e-03) * s1_1_2;
	r0 += M4(-3.428e-03, 8.373e-03, 5.969e-02, -5.721e-03, -3.539e-03, 1.404e-03, 1.474e-02, 7.659e-05, 1.503e-02, -1.505e-02, -3.628e-02, 7.339e-03, 5.869e-03, 2.350e-03, 2.973e-02, -2.493e-04) * s1_2_0;
	r0 += M4(9.620e-03, -1.911e-02, 1.519e-01, 2.104e-01, -5.001e-03, -8.455e-03, 7.251e-02, 4.956e-02, -9.994e-03, -1.741e-02, 6.895e-03, -7.811e-02, -1.069e-02, 2.318e-02, 7.023e-03, 2.020e-02) * s1_2_1;
	r0 += M4(-1.125e-03, 5.486e-03, -1.731e-03, 2.550e-04, 4.005e-04, 8.647e-03, 1.310e-03, -4.700e-02, 5.754e-03, -2.401e-02, -3.991e-02, 1.232e-01, -3.657e-03, -7.543e-03, 1.154e-02, -6.398e-03) * s1_2_2;
	r0 += V4(-1.400e-10, 3.503e-10, 7.918e-10, 1.349e-09);
	r0 = r0;
	vec2 opt = 0.5 * LUMA_pt;
	vec2 fpos = (vec2(opos) + vec2(0.5)) * opt;
	imageStore(out_image, opos + ivec2(0, 0), vec4(r0.x + LUMA_tex(fpos + vec2(0.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 0), vec4(r0.y + LUMA_tex(fpos + vec2(1.0, 0.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(0, 1), vec4(r0.z + LUMA_tex(fpos + vec2(0.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
	imageStore(out_image, opos + ivec2(1, 1), vec4(r0.w + LUMA_tex(fpos + vec2(1.0, 1.0) * opt).r, 0.0, 0.0, 1.0));
}
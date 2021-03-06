#version 410

layout(quads, fractional_odd_spacing, ccw) in;

uniform	mat4 m_projView;
uniform mat4 m_view;

uniform vec4 light_dir;

uniform float height_noise_frequency;
uniform float height_noise_amplitude;
uniform float height_noise_power;
uniform int height_noise_octaves;
uniform float height_noise_persistance;
uniform float height_noise_lacunarity;

in Data {

	vec4 posTC;
	int side;
  int patch_length;
	vec4 origin;
	float ringTess;

} DataIn[];

/*out Data {

	vec3 normal;
	float height;
	vec3 eye;
	vec3 light_dir;

} DataOut;*/

out vec3 normal;
out vec4 x0;
out vec4 x1;
out vec4 z0;
out vec4 z1;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

////////////////////////////////////////////////////////////////////////////
//                                                                        //
// Description : Array and textureless GLSL 2D simplex noise function.    //
//      Author : Ian McEwan, Ashima Arts.                                 //
//  Maintainer : stegu                                                    //
//     Lastmod : 20110822 (ijm)                                           //
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.     //
//               Distributed under the MIT License. See LICENSE file.     //
//               https://github.com/ashima/webgl-noise                    //
//               https://github.com/stegu/webgl-noise                     //
//                                                                        //
//                                                                        //

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
  
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
  // First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

  // Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

  // Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

  // Gradients: 41 points uniformly over a line, mapped onto a diamond.
  // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

  // Normalise gradients implicitly by scaling m
  // Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

  // Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);

}
//                                                                        //
////////////////////////////////////////////////////////////////////////////

float max_height () {

  float amp = height_noise_amplitude, height = 0;
	
	for(int i = 0; i < height_noise_octaves; i++, amp *= height_noise_persistance) {
		
    height += 1.0 * amp;
	
  }

  return height;

}

float height (vec2 position) {

  float freq = height_noise_frequency, amp = height_noise_amplitude, height = 0, max_height = max_height();
	
  // Calculating height using snoise ( height -> [-max_height, max_heigth] )
	for(int i = 0; i < height_noise_octaves; i++, amp *= height_noise_persistance, freq *= height_noise_lacunarity) {
		
    height += snoise(freq * position) * amp;
	
  }

  // Height -> [0,1]
  height = height / max_height * 0.5 + 0.5;

  // Applying the power (height -> [0, 1])
  height = pow(height, height_noise_power);

  // Height -> [-1, max_height - 1]
  return height * 2 * max_height - 1;
  
}

void main() {

	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;
	float w = 1 - u - v;
	
	vec4 p1 = mix(DataIn[0].posTC,DataIn[1].posTC,u);
	vec4 p2 = mix(DataIn[3].posTC,DataIn[2].posTC,u);
	
	vec4 position = mix(p1, p2, v); // Global space

	position.y = height(position.xz);
	
	// Getting the adjacent points to update the normal after height changes
  
	vec4 adj_pos_left = 	  position - vec4(DataIn[0].patch_length / DataIn[0].ringTess, 0, 0, 0); adj_pos_left.y = height(adj_pos_left.xz);
	vec4 adj_pos_right = 	  position + vec4(DataIn[0].patch_length / DataIn[0].ringTess, 0, 0, 0); adj_pos_right.y = height(adj_pos_right.xz);
	vec4 adj_pos_top = 		  position + vec4(0, 0, DataIn[0].patch_length / DataIn[0].ringTess, 0); adj_pos_top.y = height(adj_pos_top.xz);
	vec4 adj_pos_bottom = 	position - vec4(0, 0, DataIn[0].patch_length / DataIn[0].ringTess, 0); adj_pos_bottom.y = height(adj_pos_bottom.xz);

  x0 = adj_pos_left;
  x1 = adj_pos_right;
  z1 = adj_pos_top;
  z0 = adj_pos_bottom;

	// Calculating the vectors whose cross product will return the normal
	vec4 vecX = adj_pos_right - adj_pos_left;
	vec4 vecZ = adj_pos_top - adj_pos_bottom;

	// Recalculating the normal at the current position
	//DataOut.normal = normalize(cross(vecX.xyz, vecZ.xyz));
  //normal = vec3(0,1,0);
  //normal = normalize(vecZ.xyz);
	normal = normalize( inverse(transpose(mat3(m_view))) * cross(vecZ.xyz, vecX.xyz));
	
	/*DataOut.height = position.y;
	//DataOut.texCoord = texCoord0;
	DataOut.eye = normalize(vec3(-(m_view * position)));
	DataOut.light_dir = normalize(vec3(m_view * - light_dir));*/

	//gl_Position = m_projView * position;
	gl_Position = position;

}


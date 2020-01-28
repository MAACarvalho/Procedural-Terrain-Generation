#version 410

layout(vertices = 4) out;

out vec4 posTC[];


void main() {

	posTC[gl_InvocationID] = gl_in[gl_InvocationID].gl_Position;
	
	if (gl_InvocationID == 0) {

		gl_TessLevelOuter[0] = 1.0;
		gl_TessLevelOuter[1] = 1.0;
		gl_TessLevelOuter[2] = 1.0;
		gl_TessLevelOuter[3] = 1.0;

		gl_TessLevelInner[0] = 1.0;
		gl_TessLevelInner[1] = 1.0;

	}
}
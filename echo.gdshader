shader_type spatial;

render_mode unshaded;

uniform sampler2D depth_texture : hint_depth_texture;

uniform float min_distance;
uniform float max_distance;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float depth = FRAGCOORD.z;
	
	// alternative way of getting depth, but for some reason didn't work for me
	//float depth = texture(depth_texture, SCREEN_UV).x;
	
	// linearize depth: https://godotshaders.com/shader/linear-depth-depth-fog/
	vec3 ndc = vec3((SCREEN_UV * 2.0) - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	float a = step(min_distance, linear_depth) * (1.0 - step(max_distance, linear_depth));
	
	ALBEDO = vec3(a);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

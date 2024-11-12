shader_type spatial;

render_mode unshaded;

//uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D pulse_sources;
uniform vec3 pulse_color : source_color;
const float pulse_speed = 5.0;
const float pulse_duration = 2.0; /*sec*/
uniform float pulse_elapsed;

uniform float ambient = 0.0;

// inverse lerp
float ilerp(float from, float to, float value) {
  return (value - from) / (to - from);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 ndc = vec4((SCREEN_UV * 2.0) - 1.0, FRAGCOORD.z, 1.0);
	vec4 frag_view = INV_PROJECTION_MATRIX * ndc;
	frag_view /= frag_view.w;
	//float linear_depth = -frag_view.z;

	// linearize depth: https://godotshaders.com/shader/linear-depth-depth-fog/
	vec4 frag_world = INV_VIEW_MATRIX * frag_view;

	float pulse = ambient * FRAGCOORD.z;
	int pulse_count = textureSize(pulse_sources, 0).x;
	// skip the first pixel, there always needs to be at least one
	for (int i = 1; i < pulse_count; i += 1) {
		vec4 pulse_source = texelFetch(pulse_sources, ivec2(i, 0), 0);
		float dist = length(frag_world.xyz - pulse_source.xyz);
		//float time_period = 4.0;
		//float max_dist = 4.0;
		//float target_dist = (TIME - pulse_source.w) * max_dist / time_period;
		float target_dist = (pulse_elapsed - pulse_source.w) * pulse_speed;
		float d = abs(target_dist - dist);
		if (d < 0.1) { pulse += 1.0 / dist; }
	}

	if (FRAGCOORD.z > 0.3) {
		pulse = clamp(pulse + (FRAGCOORD.z - 0.3) / 3.0, 0.0, 1.0);
	}
	ALBEDO = pulse * pulse_color;
	//ALBEDO = pulse_color;
}

// tried using lights as pulse sources, but it was slow on my machine
//void light() {
	//vec4 ndc = vec4(FRAGCOORD.xy / VIEWPORT_SIZE * 2.0 - 1.0, FRAGCOORD.z, 1.0);
	//vec4 frag_view = INV_PROJECTION_MATRIX * ndc;
	//frag_view /= frag_view.w;
	//float dist = length(LIGHT - frag_view.xyz);
	////float target_dist = 5.0;
	//float target_dist = mod(TIME, 5.0) * 2.0;
	//float d = abs(target_dist - dist);
	//if (d < 0.1) { d = 1.0; } else { d = 0.0; }
	////float d = 0.0;
	////if (dist > 0.8 && dist < 1.0) { d = 1.0; }
	////DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT) * d, 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
	//DIFFUSE_LIGHT += d * ATTENUATION * LIGHT_COLOR;
//}

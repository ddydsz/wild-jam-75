shader_type spatial;

render_mode unshaded;

uniform float pulse_distance = 1.0;
uniform vec3 pulse_color : source_color;
uniform float pulse_length = 0.025;
uniform float pulse_fade_length = 0.5;
uniform float fresnel_amount = 1.0;

// multipulse stuff
global uniform sampler2D pulse_sources;
global uniform float game_time;
uniform float pulse_speed = 15.0;

global uniform bool debug_enabled = false;
uniform float ambient = 0.0;

uniform bool noise_enabled;
uniform sampler3D noise_texture;

// inverse lerp
float ilerp(float from, float to, float value) {
  return (value - from) / (to - from);
}

// https://godotshaders.com/snippet/fresnel/
float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 ndc = vec4((SCREEN_UV * 2.0) - 1.0, FRAGCOORD.z, 1.0);
	vec4 frag_view = INV_PROJECTION_MATRIX * ndc;
	frag_view /= frag_view.w;
	vec4 frag_world = INV_VIEW_MATRIX * frag_view;

	float pulse = 0.0;
	int pulse_count = textureSize(pulse_sources, 0).x;
	// skip the first pixel, there always needs to be at least one
	for (int i = 1; i < pulse_count; i += 1) {
		vec4 pulse_source = texelFetch(pulse_sources, ivec2(i, 0), 0);
		float dist = length(frag_world.xyz - pulse_source.xyz);
		float target_dist = (game_time - pulse_source.w) * pulse_speed;
		float d = ilerp(pulse_length, pulse_fade_length, abs(target_dist - dist));
		float i = clamp(smoothstep(1.0, 0.0, d), 0.0, 1.0);
		pulse += i;
	}

	float f = fresnel(fresnel_amount, NORMAL, VIEW);
	float a = ambient * FRAGCOORD.z;
	if (debug_enabled) {
		a = 0.7;
	}
	
	float n = 0.0;
	if (noise_enabled) {
		n = texture(noise_texture , frag_world.xyz).x;
	}

	ALBEDO = clamp(pulse + a - f - n, 0.0, 1.0) * pulse_color;
	
	//ALBEDO = pulse_color;
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

shader_type spatial;

render_mode unshaded;

const float pulse_length = 3.0;
const float pulse_fade_length = 15.0;
const float pulse_speed = 33.0;
const float ambient = 0.2;

// runtime varying shader parameters
global uniform sampler2D pulse_sources;
global uniform float game_time;
global uniform bool debug_enabled;

// per-material parameters
uniform vec3 color: source_color;
uniform float fresnel_amount = 1.5;
uniform float noise;
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

float pulse_intensity(vec3 src, float start_time, vec3 frag) {
	float dist = length(frag - src);
	float radius = (game_time - start_time) * pulse_speed;
	float d = ilerp(pulse_length, pulse_fade_length, abs(radius - dist));
	float i = clamp(smoothstep(1.0, 0.0, d), 0.0, 1.0);
	// intensity decreases as the pulse radius grows
	float falloff = clamp(10.0 / radius, 0.0, 1.0);
	return i * falloff;
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
		pulse += pulse_intensity(pulse_source.xyz, pulse_source.w, frag_world.xyz);
	}
	pulse = clamp(pulse, 0.0, 1.3);

	float f = fresnel(fresnel_amount, NORMAL, VIEW);
	float n = noise * texture(noise_texture, frag_world.xyz).r;
	float a = ambient * FRAGCOORD.z * FRAGCOORD.z;

	// want to be able to see something in the material view
	if (debug_enabled || game_time <= 0.0) { a = 1.0; }

	ALBEDO = clamp(pulse + a - f - n, 0.0, 1.0) * color;
	//ALBEDO = pulse_color;
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

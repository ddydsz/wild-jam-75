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

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
	 /* 1. find current tetrahedron T and it's four vertices */
	 /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
	 /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
	 
	 /* calculate s and x */
	 vec3 s = floor(p + dot(p, vec3(F3)));
	 vec3 x = p - s + dot(s, vec3(G3));
	 
	 /* calculate i1 and i2 */
	 vec3 e = step(vec3(0.0), x - x.yzx);
	 vec3 i1 = e*(1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	 /* x1, x2, x3 */
	 vec3 x1 = x - i1 + G3;
	 vec3 x2 = x - i2 + 2.0*G3;
	 vec3 x3 = x - 1.0 + 3.0*G3;
	 
	 /* 2. find four surflets and store them in d */
	 vec4 w, d;
	 
	 /* calculate surflet weights */
	 w.x = dot(x, x);
	 w.y = dot(x1, x1);
	 w.z = dot(x2, x2);
	 w.w = dot(x3, x3);
	 
	 /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
	 w = max(0.6 - w, 0.0);
	 
	 /* calculate surflet components */
	 d.x = dot(random3(s), x);
	 d.y = dot(random3(s + i1), x1);
	 d.z = dot(random3(s + i2), x2);
	 d.w = dot(random3(s + 1.0), x3);
	 
	 /* multiply d by w^4 */
	 w *= w;
	 w *= w;
	 d *= w;
	 
	 /* 3. return the sum of the four surflets */
	 return dot(d, vec4(52.0));
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
	float falloff_rad = 20.0;
	float falloff = clamp(falloff_rad / clamp(radius-falloff_rad, 0.0, radius), 0.0, 1.0);
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
	//float n = simplex3d(frag_world.xyz * 12.0) * 0.3;
	float a = ambient * FRAGCOORD.z * FRAGCOORD.z;

	// want to be able to see something in the material view
	if (debug_enabled) {
		a = 1.0;
	} else if (game_time <= 0.0) {
		// editor/material view
		a = 0.5;
		pulse = 0.5 * pulse_intensity(CAMERA_POSITION_WORLD, game_time - mod(TIME, 3.0), frag_world.xyz);
	}

	ALBEDO = clamp(pulse + a - f - n, 0.0, 1.0) * color;
	//ALBEDO = pulse_color;
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

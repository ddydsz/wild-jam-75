shader_type canvas_item;

// this one is tweened by scripts
uniform float opacity = 1.0;

uniform vec3 color : source_color;
uniform float max_opacity = 0.0;
uniform float vignette_factor = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float d = distance(UV, vec2(0.5, 0.5)) * vignette_factor;
	COLOR = vec4(d * color, max_opacity * opacity);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

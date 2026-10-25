shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float flight_time = 0.0;
varying float glow;

void vertex() {
	// Every quad stores a different phase, speed and radius in its vertex color.
	vec3 seed = COLOR.rgb;
	float phase = seed.r * 6.283185;
	float t = flight_time * mix(0.65, 1.35, seed.g);
	float radius = mix(16.0, 34.0, seed.b);
	VERTEX.x += sin(t + phase) * radius + sin(t * 1.73 + phase * 2.0) * 7.0;
	VERTEX.y += cos(t * mix(0.8, 1.6, seed.b) + phase) * 7.0 + sin(t * 1.9 + phase * 3.0) * 4.0;
	glow = COLOR.a * (0.28 + 0.72 * pow(0.5 + 0.5 * sin(t * 2.2 + phase), 2.0));
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	COLOR = vec4(0.86, 1.0, 0.45, texel.a * glow);
}

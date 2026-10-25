shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.15, 0.27, 0.19, 1.0);
uniform vec4 leaf_color : source_color = vec4(0.36, 0.49, 0.33, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.67, 0.74, 0.52, 1.0);
uniform float palette_strength : hint_range(0.0, 1.0) = 0.94;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float value = clamp(dot(texel.rgb, vec3(0.25, 0.65, 0.10)), 0.0, 1.0);
	vec3 palette = mix(shadow_color.rgb, leaf_color.rgb, smoothstep(0.04, 0.46, value));
	palette = mix(palette, highlight_color.rgb, smoothstep(0.40, 0.88, value));
	COLOR = vec4(mix(texel.rgb, palette, palette_strength), texel.a) * vertex_tint;
}

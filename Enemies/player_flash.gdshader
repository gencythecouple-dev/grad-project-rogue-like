shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 red = vec3(1.0, 0.0, 0.0);
	color.rgb = mix(color.rgb, red, flash_intensity);
	COLOR = color;
}
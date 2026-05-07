shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec3 buff_tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 white = vec3(1.0, 1.0, 1.0);
	color.rgb = mix(color.rgb, white, flash_intensity);
	color.rgb *= buff_tint;
	COLOR = color;
}
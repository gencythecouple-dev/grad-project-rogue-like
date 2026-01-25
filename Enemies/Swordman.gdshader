shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 flash_color = vec3(1.0, 1.0, 1.0); // White
	COLOR.rgb = mix(tex_color.rgb, flash_color, flash_intensity);
	COLOR.a = tex_color.a;
}
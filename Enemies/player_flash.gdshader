shader_type canvas_item;
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float rgb_cycle : hint_range(0.0, 1.0) = 0.0;
uniform bool rainbow_active = false;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 red = vec3(1.0, 0.0, 0.0);
	color.rgb = mix(color.rgb, red, flash_intensity);
	if (rainbow_active) {
		float h = rgb_cycle;
		float r = abs(h * 6.0 - 3.0) - 1.0;
		float g = 2.0 - abs(h * 6.0 - 2.0);
		float b = 2.0 - abs(h * 6.0 - 4.0);
		vec3 rainbow = clamp(vec3(r, g, b), 0.0, 1.0);
		color.rgb = mix(color.rgb, rainbow, 0.5);
	}
	COLOR = color;
}
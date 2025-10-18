shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0);

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	bool within = texture(TEXTURE, UV + pixel_size * vec2(1.0, 0.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, -1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, 1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 0.0)).a > 0.0;
	bool outline = within && texture(TEXTURE, UV).a == 0.0;
	COLOR = float(!outline) * COLOR + float(outline) * outline_color;
}
shader_type canvas_item;

uniform sampler2D gradient_texture;

varying vec2 vertex_pos;
uniform float start_fade = 0.0;
uniform float end_fade = 200.0;

uniform float repeat = 16.0;

void vertex() {
	vertex_pos = VERTEX;
}

void fragment() {
	float real_uv_y = mod((vertex_pos.y - start_fade) / (end_fade - start_fade), repeat);
	if (
			abs(UV.x - 0.5) < 0.5 - TEXTURE_PIXEL_SIZE.x ||
			abs(UV.y - 0.5) < 0.5 - TEXTURE_PIXEL_SIZE.y
	) 
    COLOR = COLOR * texture(gradient_texture, vec2(real_uv_y, 0.0));
}

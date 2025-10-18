shader_type canvas_item;

void fragment() {
	float gray = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
	COLOR = vec4(gray, gray, gray, COLOR.a);
}
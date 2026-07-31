shader_type canvas_item;

uniform float float_height = 3.0;
uniform float float_frequency = 3.0;


void vertex() {
	VERTEX.y += sin(TIME * float_frequency) * float_height;
}

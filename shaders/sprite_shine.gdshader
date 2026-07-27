shader_type canvas_item;

// Liga o pulso branco do sprite.
uniform bool is_shining = false;

// Número de pulsos completos por segundo.
uniform float shine_frequency : hint_range(0.0, 30.0, 0.1) = 8.0;


void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	vec4 modulated_color = sprite_color * COLOR;
	COLOR = modulated_color;

	if (is_shining && shine_frequency > 0.0) {
		float pulse = step(0.5, fract(TIME * shine_frequency));
		if (pulse > 0.0) {
			// Mantém a transparência do sprite, mas remove toda a sua cor.
			COLOR = vec4(vec3(1.0), sprite_color.a * COLOR.a);
		}
	}
}

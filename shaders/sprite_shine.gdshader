shader_type canvas_item;

// Liga o pulso branco do sprite.
uniform bool is_shining = false;

// Número de pulsos completos por segundo.
uniform float shine_frequency : hint_range(0.0, 30.0, 0.1) = 8.0;

// Dissolução dirigida por uma NoiseTexture2D configurada pelo DeathComponent.
uniform bool is_dissolving = false;
uniform sampler2D dissolve_noise_texture : filter_nearest, repeat_enable;
uniform float dissolve_progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float dissolve_edge_width : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform vec4 dissolve_edge_color : source_color = vec4(1.0, 0.82, 0.4, 1.0);


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

	if (is_dissolving) {
		float noise_value = texture(dissolve_noise_texture, UV).r;
		if (noise_value < dissolve_progress) {
			discard;
		}
		float dissolve_edge = 1.0 - smoothstep(
			dissolve_progress,
			dissolve_progress + dissolve_edge_width,
			noise_value
		);
		COLOR.rgb = mix(COLOR.rgb, dissolve_edge_color.rgb, dissolve_edge);
	}
}

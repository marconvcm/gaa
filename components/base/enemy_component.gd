## Reações específicas do inimigo ao receber dano.
class_name EnemyComponent
extends Node

@export_range(0.0, 5.0, 0.01, "suffix:s") var hit_flash_duration := 0.3

var _actor: Node2D
var _hp_component: HPComponent
var _knockback_component: KnockbackComponent
var _sprite: Sprite2D
var _flash_id := 0


func _ready() -> void:
	_actor = get_parent() as Node2D
	_hp_component = _actor.get_node_or_null("HPComponent") as HPComponent
	_knockback_component = _actor.get_node_or_null("KnockbackComponent") as KnockbackComponent
	_sprite = _actor.get_node_or_null("Sprite") as Sprite2D

	if _hp_component != null:
		_hp_component.hit_received.connect(_on_hit_received)
		_hp_component.died.connect(_on_died)


func _on_hit_received(hitbox: HitboxComponent) -> void:
	if _knockback_component != null:
		_knockback_component.apply_from(_get_attacker_center(hitbox), hitbox.knockback_force)
	_start_hit_flash()


func _get_attacker_center(hitbox: HitboxComponent) -> Vector2:
	var attacker := hitbox.get_actor()
	if is_instance_valid(attacker):
		return attacker.global_position
	return hitbox.global_position


func _on_died() -> void:
	_actor.queue_free()


func _start_hit_flash() -> void:
	if _sprite == null:
		return

	var shader_material := _sprite.material as ShaderMaterial
	if shader_material == null:
		return

	_flash_id += 1
	shader_material.set_shader_parameter(&"is_shining", true)
	get_tree().create_timer(hit_flash_duration).timeout.connect(_stop_hit_flash.bind(_flash_id))


func _stop_hit_flash(flash_id: int) -> void:
	if flash_id != _flash_id or _sprite == null:
		return

	var shader_material := _sprite.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(&"is_shining", false)

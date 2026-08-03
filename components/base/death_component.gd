## Executa uma morte visual comum para todos os atores que possuem HPComponent.
class_name DeathComponent
extends Node

signal death_started

const DISSOLVE_NOISE_TEXTURE: Texture2D = preload("res://resources/dissolve_noise_texture.tres")

@export_range(0.01, 5.0, 0.01, "suffix:s") var dissolve_duration := 0.45
@export var dissolve_edge_color := Color("ffd166")
@export var remove_actor_on_death := true

var _actor: CharacterBody2D
var _hp_component: HPComponent
var _move_component: MoveComponent
var _knockback_component: KnockbackComponent
var _hurtbox_component: HurtboxComponent
var _sprite: Sprite2D
var _is_dying := false


func _ready() -> void:
	_actor = get_parent() as CharacterBody2D
	if _actor == null:
		push_error("DeathComponent deve ser filho de um CharacterBody2D.")
		set_process(false)
		return

	_hp_component = _actor.get_node_or_null(HPComponent.__NAME__) as HPComponent
	_move_component = _actor.get_node_or_null(MoveComponent.__NAME__) as MoveComponent
	_knockback_component = _actor.get_node_or_null(KnockbackComponent.__NAME__) as KnockbackComponent
	_hurtbox_component = _actor.get_node_or_null(HurtboxComponent.__NAME__) as HurtboxComponent
	_sprite = _actor.get_node_or_null("Sprite") as Sprite2D
	if _hp_component != null:
		_hp_component.died.connect(prepare_to_die)


func prepare_to_die() -> void:
	if _is_dying:
		return
	_is_dying = true
	death_started.emit()
	_disable_actor()
	_start_dissolve()


func _disable_actor() -> void:
	_actor.velocity = Vector2.ZERO
	if _move_component != null:
		_move_component.set_physics_process(false)
	if _knockback_component != null:
		_knockback_component.set_physics_process(false)
	if _hurtbox_component != null:
		_hurtbox_component.can_receive_damage = false

	for child in _actor.get_children():
		if child is EnemyBrainComponent or child is InputComponent:
			child.set_physics_process(false)


func _start_dissolve() -> void:
	if _sprite == null:
		_finish_death()
		return

	var shader_material := _sprite.material as ShaderMaterial
	if shader_material == null:
		_finish_death()
		return

	# O material precisa ser local: o progresso de um ator não pode dissolver os
	# demais sprites que usam o mesmo shader.
	_sprite.material = shader_material.duplicate()
	shader_material = _sprite.material as ShaderMaterial
	shader_material.set_shader_parameter(&"dissolve_noise_texture", DISSOLVE_NOISE_TEXTURE)
	shader_material.set_shader_parameter(&"dissolve_edge_color", dissolve_edge_color)
	shader_material.set_shader_parameter(&"dissolve_progress", 0.0)
	shader_material.set_shader_parameter(&"is_dissolving", true)
	var tween := create_tween()
	tween.tween_method(_set_dissolve_progress, 0.0, 1.0, dissolve_duration)
	tween.tween_callback(_finish_death)


func _finish_death() -> void:
	if remove_actor_on_death:
		_actor.queue_free()
	elif _sprite != null:
		_sprite.hide()


func _set_dissolve_progress(progress: float) -> void:
	if not is_instance_valid(_sprite):
		return
	var shader_material := _sprite.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(&"dissolve_progress", progress)

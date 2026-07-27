## Cria projéteis na direção em que o ator está olhando.
class_name ShotComponent
extends Node

signal projectile_fired(projectile: ProjectileObject)

@export_range(0.0, 10.0, 0.01, "suffix:s") var cooldown := 0.25
@export_range(0.0, 256.0, 1.0, "suffix:px") var spawn_distance := 12.0
@export_range(0, 9999, 1) var damage := 1
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var knockback_force := 120.0

var _actor: Node2D
var _input_component: InputComponent
var _move_component: MoveComponent
var _cooldown_remaining := 0.0


func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor == null:
		push_error("ShotComponent deve ser filho de um Node2D.")
		set_physics_process(false)
		return

	_input_component = _find_input_component()
	_move_component = _actor.get_node_or_null("MoveComponent") as MoveComponent


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _input_component != null and _input_component.is_shoot_requested():
		shoot()


func shoot(direction := Vector2.ZERO) -> ProjectileObject:
	if _cooldown_remaining > 0.0:
		return null

	var shot_direction := direction
	if shot_direction.is_zero_approx() and _move_component != null:
		shot_direction = _move_component.facing_direction
	if shot_direction.is_zero_approx():
		shot_direction = Vector2.DOWN

	var normalized_direction := shot_direction.normalized()
	var projectile := ProjectileObject.create(
		_actor,
		_actor.global_position + normalized_direction * spawn_distance,
		normalized_direction,
		damage,
		knockback_force,
	)
	get_tree().current_scene.add_child(projectile)

	_cooldown_remaining = cooldown
	projectile_fired.emit(projectile)
	return projectile


func _find_input_component() -> InputComponent:
	for child in _actor.get_children():
		if child is InputComponent:
			return child
	return null

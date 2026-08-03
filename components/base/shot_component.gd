## Cria projéteis na direção em que o ator está olhando.
class_name ShotComponent
extends Node

static var __NAME__: NodePath = ^"ShotComponent"

signal projectile_fired(projectile: ProjectileObject)
signal weapon_changed(weapon: WeaponResource)

@export var weapons: Array[WeaponResource] = []
@export var current_weapon_index := 0

var weapon: WeaponResource

var _actor: Node2D
var _input_component: InputComponent
var _move_component: MoveComponent
var _cooldown_remaining := 0.0
var can_shoot_callback: Callable
var shot_fired_callback: Callable


func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor == null:
		push_error("ShotComponent deve ser filho de um Node2D.")
		set_physics_process(false)
		return

	_input_component = _find_input_component()
	_move_component = _actor.get_node_or_null(MoveComponent.__NAME__) as MoveComponent
	if weapons.is_empty():
		weapons.append(WeaponResource.new())
	current_weapon_index = posmod(current_weapon_index, weapons.size())
	weapon = weapons[current_weapon_index]


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _input_component == null:
		return

	if _input_component.is_previous_weapon_requested():
		_select_weapon(-1)
	elif _input_component.is_next_weapon_requested():
		_select_weapon(1)

	if weapon.automatic_fire and _input_component.is_shoot_held():
		shoot()
	elif not weapon.automatic_fire and _input_component.is_shoot_requested():
		shoot()


func shoot(direction := Vector2.ZERO) -> ProjectileObject:
	if _cooldown_remaining > 0.0:
		return null
	if can_shoot_callback.is_valid() and not can_shoot_callback.call(weapon):
		return null

	var shot_direction := direction
	if shot_direction.is_zero_approx() and _move_component != null:
		shot_direction = _move_component.facing_direction
	if shot_direction.is_zero_approx():
		shot_direction = Vector2.DOWN

	var normalized_direction := shot_direction.normalized()
	var first_projectile: ProjectileObject
	for projectile_index in weapon.projectile_count:
		var projectile_direction := normalized_direction.rotated(_get_spread_angle(projectile_index))
		var projectile := ProjectileObject.create(
			_actor,
			_actor.global_position + projectile_direction * weapon.spawn_distance,
			projectile_direction,
			weapon.projectile_speed,
			weapon.damage,
			weapon.knockback_force,
		)
		get_tree().current_scene.add_child(projectile)
		if first_projectile == null:
			first_projectile = projectile
		projectile_fired.emit(projectile)

	_cooldown_remaining = 1.0 / maxf(weapon.fire_rate, 0.1)
	if shot_fired_callback.is_valid():
		shot_fired_callback.call(weapon)
	return first_projectile


func _get_spread_angle(projectile_index: int) -> float:
	if weapon.projectile_count <= 1:
		return 0.0

	var spread_radians := deg_to_rad(weapon.spread_degrees)
	var spread_progress := float(projectile_index) / float(weapon.projectile_count - 1)
	return lerpf(-spread_radians * 0.5, spread_radians * 0.5, spread_progress)


func _select_weapon(index_change: int) -> void:
	current_weapon_index = posmod(current_weapon_index + index_change, weapons.size())
	weapon = weapons[current_weapon_index]
	weapon_changed.emit(weapon)


func select_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size() or index == current_weapon_index:
		return

	current_weapon_index = index
	weapon = weapons[current_weapon_index]
	weapon_changed.emit(weapon)


func _find_input_component() -> InputComponent:
	for child in _actor.get_children():
		if child is InputComponent:
			return child
	return null

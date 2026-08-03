## Centraliza o estado persistente do Player, começando pela munição das armas.
class_name PlayerControllerComponent
extends Node

static var __NAME__: NodePath = ^"PlayerControllerComponent"

signal ammunition_changed(weapon: WeaponResource, clip_ammo: int, reserve_ammo: int)
signal reload_started(weapon: WeaponResource)
signal reload_finished(weapon: WeaponResource)

var _reserve_ammo_by_weapon: Dictionary = {}
var _clip_ammo_by_weapon: Dictionary = {}
var _shot_component: ShotComponent
var _input_component: InputComponent
var _move_component: MoveComponent
var _is_reloading := false
var _movement_speed_before_reload := 0.0


func _ready() -> void:
	var actor := get_parent() as Node2D
	if actor == null:
		push_error("PlayerControllerComponent deve ser filho de um Node2D.")
		return

	_shot_component = actor.get_node_or_null(ShotComponent.__NAME__) as ShotComponent
	if _shot_component == null:
		push_error("PlayerControllerComponent requer um ShotComponent.")
		return

	_input_component = actor.get_node_or_null(PlayerInputComponent.__NAME__) as InputComponent
	_move_component = actor.get_node_or_null(MoveComponent.__NAME__) as MoveComponent
	for weapon in _shot_component.weapons:
		_reserve_ammo_by_weapon[weapon.weapon_id] = weapon.ammo_capacity
		_clip_ammo_by_weapon[weapon.weapon_id] = weapon.clip_size
	_shot_component.can_shoot_callback = can_consume_ammo
	_shot_component.shot_fired_callback = consume_ammo


func _physics_process(_delta: float) -> void:
	if _input_component != null and _input_component.is_reload_requested():
		reload_weapon(_shot_component.weapon)


func can_consume_ammo(weapon: WeaponResource) -> bool:
	if _is_reloading:
		return false
	if get_clip_ammo(weapon) <= 0:
		reload_weapon(weapon)
		return false
	return true


func consume_ammo(weapon: WeaponResource) -> void:
	var clip_ammo := maxi(get_clip_ammo(weapon) - 1, 0)
	_clip_ammo_by_weapon[weapon.weapon_id] = clip_ammo
	ammunition_changed.emit(weapon, clip_ammo, get_reserve_ammo(weapon))


func add_ammo(weapon: WeaponResource, amount: int) -> void:
	var reserve_ammo := clampi(get_reserve_ammo(weapon) + amount, 0, weapon.ammo_capacity)
	_reserve_ammo_by_weapon[weapon.weapon_id] = reserve_ammo
	ammunition_changed.emit(weapon, get_clip_ammo(weapon), reserve_ammo)


func get_clip_ammo(weapon: WeaponResource) -> int:
	if weapon == null:
		return 0
	return int(_clip_ammo_by_weapon.get(weapon.weapon_id, weapon.clip_size))


func get_reserve_ammo(weapon: WeaponResource) -> int:
	if weapon == null:
		return 0
	return int(_reserve_ammo_by_weapon.get(weapon.weapon_id, weapon.ammo_capacity))


func reload_weapon(weapon: WeaponResource) -> void:
	if _is_reloading or weapon == null or get_clip_ammo(weapon) >= weapon.clip_size or get_reserve_ammo(weapon) <= 0:
		return

	_is_reloading = true
	_set_reload_movement_speed()
	reload_started.emit(weapon)
	await get_tree().create_timer(weapon.reload_duration).timeout
	if not is_instance_valid(weapon):
		return

	var ammo_needed := weapon.clip_size - get_clip_ammo(weapon)
	var ammo_loaded := mini(ammo_needed, get_reserve_ammo(weapon))
	_clip_ammo_by_weapon[weapon.weapon_id] = get_clip_ammo(weapon) + ammo_loaded
	_reserve_ammo_by_weapon[weapon.weapon_id] = get_reserve_ammo(weapon) - ammo_loaded
	_is_reloading = false
	_restore_movement_speed()
	ammunition_changed.emit(weapon, get_clip_ammo(weapon), get_reserve_ammo(weapon))
	reload_finished.emit(weapon)


func _set_reload_movement_speed() -> void:
	if _move_component == null:
		return

	_movement_speed_before_reload = _move_component.speed
	_move_component.speed *= 0.5


func _restore_movement_speed() -> void:
	if _move_component == null:
		return

	_move_component.speed = _movement_speed_before_reload

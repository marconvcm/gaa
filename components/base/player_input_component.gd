## Lê as ações de movimento configuradas no Input Map.
class_name PlayerInputComponent
extends InputComponent

static var __NAME__: NodePath = ^"PlayerInputComponent"

@export_category("Ações de movimento")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_up_action: StringName = &"move_up"
@export var move_down_action: StringName = &"move_down"
@export var shoot_action: StringName = &"shoot"
@export var melee_action: StringName = &"melee"
@export var previous_weapon_action: StringName = &"previous_weapon"
@export var next_weapon_action: StringName = &"next_weapon"
@export var reload_action: StringName = &"reload"

var _virtual_movement_direction := Vector2.ZERO
var _virtual_shoot_pressed := false
var _virtual_shoot_just_pressed := false
var _virtual_melee_pressed := false
var _virtual_melee_just_pressed := false


func get_movement_direction() -> Vector2:
	var physical_direction := Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action,
	)
	return (physical_direction + _virtual_movement_direction).limit_length(1.0)


func is_shoot_requested() -> bool:
	var requested := Input.is_action_just_pressed(shoot_action) or _virtual_shoot_just_pressed
	_virtual_shoot_just_pressed = false
	return requested


func is_shoot_held() -> bool:
	return Input.is_action_pressed(shoot_action) or _virtual_shoot_pressed


func is_melee_requested() -> bool:
	var requested := Input.is_action_just_pressed(melee_action) or _virtual_melee_just_pressed
	_virtual_melee_just_pressed = false
	return requested


func is_previous_weapon_requested() -> bool:
	return Input.is_action_just_pressed(previous_weapon_action)


func is_next_weapon_requested() -> bool:
	return Input.is_action_just_pressed(next_weapon_action)


func is_reload_requested() -> bool:
	return Input.is_action_just_pressed(reload_action)


func set_virtual_movement_direction(direction: Vector2) -> void:
	_virtual_movement_direction = direction.limit_length(1.0)


func set_virtual_shoot_pressed(pressed: bool) -> void:
	if pressed and not _virtual_shoot_pressed:
		_virtual_shoot_just_pressed = true
	_virtual_shoot_pressed = pressed


func set_virtual_melee_pressed(pressed: bool) -> void:
	if pressed and not _virtual_melee_pressed:
		_virtual_melee_just_pressed = true
	_virtual_melee_pressed = pressed

## Lê as ações de movimento configuradas no Input Map.
class_name PlayerInputComponent
extends InputComponent

@export_category("Ações de movimento")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_up_action: StringName = &"move_up"
@export var move_down_action: StringName = &"move_down"
@export var shoot_action: StringName = &"shoot"
@export var melee_action: StringName = &"melee"


func get_movement_direction() -> Vector2:
	return Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action,
	)


func is_shoot_requested() -> bool:
	return Input.is_action_just_pressed(shoot_action)


func is_melee_requested() -> bool:
	return Input.is_action_just_pressed(melee_action)

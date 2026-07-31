## Contrato para componentes que fornecem uma direção de movimento.
##
## Esta classe é abstrata por convenção: use PlayerInputComponent ou
## AIInputComponent em uma entidade, nunca InputComponent diretamente.
class_name InputComponent
extends Node


func get_movement_direction() -> Vector2:
	push_error("InputComponent é abstrato. Use uma implementação concreta.")
	return Vector2.ZERO


func is_shoot_requested() -> bool:
	return false


func is_shoot_held() -> bool:
	return false


func is_melee_requested() -> bool:
	return false


func is_previous_weapon_requested() -> bool:
	return false


func is_next_weapon_requested() -> bool:
	return false


func is_reload_requested() -> bool:
	return false

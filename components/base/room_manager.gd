## Acesso global à sala atualmente ocupada pelo Player.
extends Node

signal current_room_changed(room: Area2D)

var current_room: Area2D
var current_room_margin_percent := 0.0


func set_current_room(room: Area2D, margin_percent := 0.0) -> void:
	if room == current_room and is_equal_approx(margin_percent, current_room_margin_percent):
		return

	current_room = room
	current_room_margin_percent = margin_percent
	current_room_changed.emit(current_room)


func is_position_inside_current_room(global_position: Vector2) -> bool:
	if not is_instance_valid(current_room):
		return true

	var collision_shape := current_room.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return true

	var room_shape := collision_shape.shape as RectangleShape2D
	if room_shape == null:
		return true

	var local_position := current_room.to_local(global_position)
	var margin := room_shape.size * (current_room_margin_percent / 100.0)
	var room_rect := Rect2(-room_shape.size / 2.0 - margin, room_shape.size + margin * 2.0)
	return room_rect.has_point(local_position)

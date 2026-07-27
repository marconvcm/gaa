## Câmera principal do jogo, vinculada ao Player e limitada à sala atual.
class_name GameCamera
extends Camera2D

const GENERATED_AREA_META := &"room_discovery_generated"

@export_range(0.0, 50.0, 1.0, "suffix:%") var room_limit_margin_percent := 8.0
@export_range(0.1, 30.0, 0.1, "suffix:/s") var room_transition_lerp_speed := 8.0

var _player: Node2D
var _room_tile_map: TileMapLayer
var _room_areas: Array[Area2D] = []
var _current_room: Area2D
var _current_limit_rect := Rect2()
var _target_limit_rect := Rect2()
var _is_transitioning := false


func _ready() -> void:
	_player = get_parent() as Node2D
	call_deferred("_discover_room_areas")


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	if _room_areas.is_empty():
		return

	for room_area in _room_areas:
		if _room_contains_player(room_area):
			if room_area != _current_room:
				var is_first_room := _current_room == null
				_current_room = room_area
				RoomManager.set_current_room(room_area, room_limit_margin_percent)
				_set_room_limits(room_area, is_first_room)
			_update_limit_transition(delta)
			return


func _discover_room_areas() -> void:
	if _room_tile_map == null:
		var scene_root := get_tree().current_scene
		if scene_root == null:
			return
		_room_tile_map = scene_root.get_node_or_null(^"RoomTileMap") as TileMapLayer

	if _room_tile_map == null:
		return

	_room_areas.clear()
	for child in _room_tile_map.get_children():
		if child is Area2D and child.get_meta(GENERATED_AREA_META, false):
			_room_areas.append(child)


func _room_contains_player(room_area: Area2D) -> bool:
	var room_shape := _get_room_shape(room_area)
	if room_shape == null:
		return false

	var local_player_position := room_area.to_local(_player.global_position)
	var room_rect := Rect2(-room_shape.size / 2.0, room_shape.size)
	return room_rect.has_point(local_player_position)


func _set_room_limits(room_area: Area2D, apply_immediately := false) -> void:
	var room_shape := _get_room_shape(room_area)
	if room_shape == null:
		return

	var top_left := room_area.to_global(-room_shape.size / 2.0)
	var bottom_right := room_area.to_global(room_shape.size / 2.0)
	var margin := room_shape.size * (room_limit_margin_percent / 100.0)
	var limit_top_left := Vector2(
		minf(top_left.x, bottom_right.x) - margin.x,
		minf(top_left.y, bottom_right.y) - margin.y,
	)
	var limit_bottom_right := Vector2(
		maxf(top_left.x, bottom_right.x) + margin.x,
		maxf(top_left.y, bottom_right.y) + margin.y,
	)
	_target_limit_rect = Rect2(limit_top_left, limit_bottom_right - limit_top_left)

	if apply_immediately:
		_current_limit_rect = _target_limit_rect
		_apply_limit_rect(_current_limit_rect)
		_is_transitioning = false
	else:
		_is_transitioning = true


func _update_limit_transition(delta: float) -> void:
	if not _is_transitioning:
		return

	var weight := 1.0 - exp(-room_transition_lerp_speed * delta)
	_current_limit_rect.position = _current_limit_rect.position.lerp(_target_limit_rect.position, weight)
	_current_limit_rect.size = _current_limit_rect.size.lerp(_target_limit_rect.size, weight)
	_apply_limit_rect(_current_limit_rect)

	if _current_limit_rect.position.distance_to(_target_limit_rect.position) < 0.1 and _current_limit_rect.size.distance_to(_target_limit_rect.size) < 0.1:
		_current_limit_rect = _target_limit_rect
		_apply_limit_rect(_current_limit_rect)
		_is_transitioning = false


func _apply_limit_rect(limit_rect: Rect2) -> void:
	limit_left = floori(limit_rect.position.x)
	limit_top = floori(limit_rect.position.y)
	limit_right = ceili(limit_rect.end.x)
	limit_bottom = ceili(limit_rect.end.y)


func _get_room_shape(room_area: Area2D) -> RectangleShape2D:
	var collision_shape := room_area.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return null
	return collision_shape.shape as RectangleShape2D

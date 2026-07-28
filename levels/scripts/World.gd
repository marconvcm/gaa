extends Node2D

const HORIZONTAL_PATH_KIND := &"HPath"
const VERTICAL_PATH_KIND := &"VPath"
const MISSING_LEVEL_KIND := &"Missing"
const CURRENT_LEVEL_KIND := &"Current"
const SPECIAL_LEVEL_KIND := &"Special"
const CLEAR_LEVEL_KIND := &"Clear"
const INVALID_CELL := Vector2i(999999, 999999)

@export_range(24.0, 480.0, 1.0, "suffix:px/s") var movement_speed := 120.0

@onready var map: TileMapLayer = $Map
@onready var player: Sprite2D = $Player
@onready var globalPlayer: AudioStreamPlayer = $GlobalSoundPlayer

var _current_cell: Vector2i
var _target_cell: Vector2i
var _cell_position_offset := Vector2.ZERO
var _movement_start := Vector2.ZERO
var _movement_target := Vector2.ZERO
var _movement_elapsed := 0.0
var _movement_duration := 0.0
var _waiting_for_input_release := false


func _ready() -> void:
	_current_cell = map.local_to_map(player.position)
	_cell_position_offset = player.position - map.map_to_local(_current_cell)


func _process(delta: float) -> void:
	if _movement_elapsed < _movement_duration:
		_update_movement(delta)
		return

	var direction := _get_input_direction()
	if direction == Vector2i.ZERO:
		_waiting_for_input_release = false
		return
	if _waiting_for_input_release:
		return

	_try_start_movement(direction)


func _update_movement(delta: float) -> void:
	_movement_elapsed = minf(_movement_elapsed + delta, _movement_duration)
	var progress := _movement_elapsed / _movement_duration
	var weight := _get_accelerated_lerp_weight(progress)
	player.position = _movement_start.lerp(_movement_target, weight)

	if is_equal_approx(_movement_elapsed, _movement_duration):
		_current_cell = _target_cell
		player.position = _movement_target
		_waiting_for_input_release = true


func _get_input_direction() -> Vector2i:
	var input_direction := Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down",
	)
	if is_zero_approx(input_direction.length()):
		return Vector2i.ZERO

	if absf(input_direction.x) >= absf(input_direction.y):
		return Vector2i(signi(input_direction.x), 0)
	return Vector2i(0, signi(input_direction.y))


func _try_start_movement(direction: Vector2i) -> void:
	if not _is_level_cell(_current_cell):
		return

	var destination_cell := _find_connected_level(_current_cell, direction)
	if destination_cell == INVALID_CELL:
		return

	_target_cell = destination_cell
	_movement_start = player.position
	_movement_target = map.map_to_local(_target_cell) + _cell_position_offset
	_movement_elapsed = 0.0
	_movement_duration = _get_movement_duration(_target_cell - _current_cell)
	if globalPlayer.playing:
		globalPlayer.stop()
	globalPlayer.play()


func _find_connected_level(origin_cell: Vector2i, direction: Vector2i) -> Vector2i:
	var previous_cell := origin_cell
	var next_cell := origin_cell + direction
	var max_steps := map.get_used_cells().size()

	for _step in max_steps:
		if not _can_travel_between(previous_cell, next_cell, direction):
			return INVALID_CELL
		if _is_level_cell(next_cell):
			return next_cell

		previous_cell = next_cell
		next_cell += direction

	return INVALID_CELL


func _can_travel_between(from_cell: Vector2i, to_cell: Vector2i, direction: Vector2i) -> bool:
	return _can_leave_cell(from_cell, direction) and _can_leave_cell(to_cell, -direction)


func _can_leave_cell(cell: Vector2i, direction: Vector2i) -> bool:
	var tile_data := map.get_cell_tile_data(cell)
	if tile_data == null:
		return false

	match StringName(tile_data.get_custom_data(&"Kind")):
		HORIZONTAL_PATH_KIND:
			return direction.x != 0
		VERTICAL_PATH_KIND:
			return direction.y != 0
		MISSING_LEVEL_KIND, CURRENT_LEVEL_KIND, SPECIAL_LEVEL_KIND, CLEAR_LEVEL_KIND:
			return true
		_:
			return false


func _is_level_cell(cell: Vector2i) -> bool:
	var tile_data := map.get_cell_tile_data(cell)
	if tile_data == null:
		return false

	match StringName(tile_data.get_custom_data(&"Kind")):
		MISSING_LEVEL_KIND, CURRENT_LEVEL_KIND, SPECIAL_LEVEL_KIND, CLEAR_LEVEL_KIND:
			return true
		_:
			return false


func _get_movement_duration(cell_delta: Vector2i) -> float:
	var cell_size := map.tile_set.tile_size
	var distance := Vector2(cell_delta * cell_size).length()
	return distance / movement_speed


func _get_accelerated_lerp_weight(progress: float) -> float:
	return progress * progress * (3.0 - 2.0 * progress)

@tool
extends EditorPlugin

const COMMAND_KEY := "gauho_and_aliens/room_discovery/generate"
const GENERATED_AREA_META := &"room_discovery_generated"
const ROOM_SIZE := Vector2i(480, 270)


func _enter_tree() -> void:
	EditorInterface.get_command_palette().add_command(
		"Generate Room Areas for Selected TileMap",
		COMMAND_KEY,
		_generate_room_areas,
	)


func _exit_tree() -> void:
	EditorInterface.get_command_palette().remove_command(COMMAND_KEY)

func _generate_room_areas() -> void:
	var tile_map := _get_selected_tile_map()
	if tile_map == null:
		push_warning("Selecione um TileMapLayer antes de gerar as áreas de sala.")
		return
	if tile_map.tile_set == null:
		push_warning("O TileMapLayer selecionado precisa de um TileSet.")
		return

	var used_rect := tile_map.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_warning("O TileMapLayer selecionado não possui tiles usados.")
		return

	var bounds := _get_tile_map_bounds(tile_map, used_rect)
	var columns := ceili(bounds.size.x / ROOM_SIZE.x)
	var rows := ceili(bounds.size.y / ROOM_SIZE.y)
	var scene_owner := tile_map.owner if tile_map.owner != null else tile_map
	var existing_areas := _get_generated_areas(tile_map)
	var new_areas: Array[Area2D] = []
	var used_cells := tile_map.get_used_cells()

	for row in rows:
		for column in columns:
			var room_bounds := _get_room_bounds(column, row, bounds.position)
			if _room_contains_tile(tile_map, room_bounds, used_cells):
				new_areas.append(_create_room_area(column, row, bounds.position))

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Generate Room Areas")
	for area in existing_areas:
		var previous_owner := area.owner
		undo_redo.add_do_method(tile_map, &"remove_child", area)
		undo_redo.add_undo_method(tile_map, &"add_child", area)
		undo_redo.add_undo_method(area, &"set_owner", previous_owner)

	for area in new_areas:
		var collision_shape := area.get_node(^"CollisionShape2D") as CollisionShape2D
		undo_redo.add_do_method(tile_map, &"add_child", area)
		undo_redo.add_do_method(area, &"set_owner", scene_owner)
		undo_redo.add_do_method(collision_shape, &"set_owner", scene_owner)
		undo_redo.add_undo_method(tile_map, &"remove_child", area)

	undo_redo.commit_action()


func _get_selected_tile_map() -> TileMapLayer:
	for selected_node in get_editor_interface().get_selection().get_selected_nodes():
		if selected_node is TileMapLayer:
			return selected_node
	return null


func _get_generated_areas(tile_map: TileMapLayer) -> Array[Area2D]:
	var areas: Array[Area2D] = []
	for child in tile_map.get_children():
		if child is Area2D and child.get_meta(GENERATED_AREA_META, false):
			areas.append(child)
	return areas


func _get_tile_map_bounds(tile_map: TileMapLayer, used_rect: Rect2i) -> Rect2:
	var tile_size := Vector2(tile_map.tile_set.tile_size)
	var top_left := tile_map.map_to_local(used_rect.position) - tile_size / 2.0
	return Rect2(top_left, Vector2(used_rect.size) * tile_size)


func _create_room_area(column: int, row: int, bounds_position: Vector2) -> Area2D:
	var room_area := Area2D.new()
	room_area.name = "RoomArea_%d_%d" % [column, row]
	room_area.position = _get_room_bounds(column, row, bounds_position).get_center()
	room_area.set_meta(GENERATED_AREA_META, true)
	room_area.set_meta(&"room_index", Vector2i(column, row))
	room_area.collision_layer = 0
	room_area.collision_mask = 0

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(ROOM_SIZE)
	collision_shape.shape = shape
	room_area.add_child(collision_shape)
	return room_area


func _get_room_bounds(column: int, row: int, bounds_position: Vector2) -> Rect2:
	return Rect2(
		bounds_position + Vector2(column * ROOM_SIZE.x, row * ROOM_SIZE.y),
		Vector2(ROOM_SIZE),
	)


func _room_contains_tile(tile_map: TileMapLayer, room_bounds: Rect2, used_cells: Array[Vector2i]) -> bool:
	for cell in used_cells:
		if room_bounds.has_point(tile_map.map_to_local(cell)):
			return true
	return false

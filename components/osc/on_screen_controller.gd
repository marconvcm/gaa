## Controles touch exibidos somente na exportação Web em dispositivos móveis.
class_name OnScreenController
extends Control

const JOYSTICK_RADIUS := 34.0
const JOYSTICK_KNOB_RADIUS := 13.0
const BUTTON_RADIUS := 20.0
const WEAPON_BUTTON_RADIUS := 13.0
const WEAPON_BUTTON_COUNT := 4
const BUTTON_BORDER_WIDTH := 2.0
const CONTROL_COLOR := Color(1.0, 1.0, 1.0, 0.8)
const PRESSED_CONTROL_COLOR := Color(1.0, 1.0, 1.0, 1.0)

const MOVE_LEFT_ACTION: StringName = &"move_left"
const MOVE_RIGHT_ACTION: StringName = &"move_right"
const MOVE_UP_ACTION: StringName = &"move_up"
const MOVE_DOWN_ACTION: StringName = &"move_down"
const SHOOT_ACTION: StringName = &"shoot"
const MELEE_ACTION: StringName = &"melee"

signal shoot_requested

var _joystick_touch_index := -1
var _joystick_offset := Vector2.ZERO
var _button_touches: Dictionary = {}
var _weapon_button_touches: Dictionary = {}
var _player_input_component: PlayerInputComponent


func _ready() -> void:
	visible = _should_show_on_screen_controls()
	if visible:
		queue_redraw()


func _exit_tree() -> void:
	_release_all_actions()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _draw() -> void:
	var joystick_center := _get_joystick_center()
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 32, CONTROL_COLOR, BUTTON_BORDER_WIDTH, true)
	draw_circle(joystick_center + _joystick_offset, JOYSTICK_KNOB_RADIUS, CONTROL_COLOR)

	for action in [SHOOT_ACTION, MELEE_ACTION]:
		var color := PRESSED_CONTROL_COLOR if _button_touches.has(action) else CONTROL_COLOR
		draw_arc(_get_button_center(action), BUTTON_RADIUS, 0.0, TAU, 24, color, BUTTON_BORDER_WIDTH, true)

	var font := get_theme_default_font()
	for weapon_index in WEAPON_BUTTON_COUNT:
		var color := PRESSED_CONTROL_COLOR if _weapon_button_touches.has(weapon_index) else CONTROL_COLOR
		var center := _get_weapon_button_center(weapon_index)
		draw_arc(center, WEAPON_BUTTON_RADIUS, 0.0, TAU, 16, color, BUTTON_BORDER_WIDTH, true)
		draw_string(font, center + Vector2(-3.0, 4.0), str(weapon_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, color)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _is_inside_joystick(event.position) and _joystick_touch_index == -1:
			_joystick_touch_index = event.index
			_update_joystick(event.position)
			accept_event()
			return

		for action in [SHOOT_ACTION, MELEE_ACTION]:
			if _is_inside_button(event.position, action) and not _button_touches.has(action):
				_button_touches[action] = event.index
				_set_virtual_action_pressed(action, true)
				if action == SHOOT_ACTION:
					shoot_requested.emit()
				queue_redraw()
				accept_event()
				return

		for weapon_index in WEAPON_BUTTON_COUNT:
			if _is_inside_weapon_button(event.position, weapon_index) and not _weapon_button_touches.has(weapon_index):
				_weapon_button_touches[weapon_index] = event.index
				_select_weapon(weapon_index)
				queue_redraw()
				accept_event()
				return
		return

	if event.index == _joystick_touch_index:
		_joystick_touch_index = -1
		_joystick_offset = Vector2.ZERO
		_set_movement_actions(Vector2.ZERO)
		queue_redraw()
		accept_event()
		return

	for action in _button_touches.keys():
		if _button_touches[action] == event.index:
			_button_touches.erase(action)
			_set_virtual_action_pressed(action, false)
			queue_redraw()
			accept_event()
			return

	for weapon_index in _weapon_button_touches.keys():
		if _weapon_button_touches[weapon_index] == event.index:
			_weapon_button_touches.erase(weapon_index)
			queue_redraw()
			accept_event()
			return


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _joystick_touch_index:
		return

	_update_joystick(event.position)
	accept_event()


func _update_joystick(touch_position: Vector2) -> void:
	var offset := touch_position - _get_joystick_center()
	_joystick_offset = offset.limit_length(JOYSTICK_RADIUS - JOYSTICK_KNOB_RADIUS)
	_set_movement_actions(_joystick_offset / (JOYSTICK_RADIUS - JOYSTICK_KNOB_RADIUS))
	queue_redraw()


func _set_movement_actions(direction: Vector2) -> void:
	var player_input_component := _get_player_input_component()
	if player_input_component != null:
		player_input_component.set_virtual_movement_direction(direction)


func _set_virtual_action_pressed(action: StringName, pressed: bool) -> void:
	var player_input_component := _get_player_input_component()
	if player_input_component == null:
		return

	if action == SHOOT_ACTION:
		player_input_component.set_virtual_shoot_pressed(pressed)
	elif action == MELEE_ACTION:
		player_input_component.set_virtual_melee_pressed(pressed)


func _release_all_actions() -> void:
	_set_movement_actions(Vector2.ZERO)
	_set_virtual_action_pressed(SHOOT_ACTION, false)
	_set_virtual_action_pressed(MELEE_ACTION, false)


func _is_inside_joystick(position: Vector2) -> bool:
	return position.distance_to(_get_joystick_center()) <= JOYSTICK_RADIUS


func _is_inside_button(position: Vector2, action: StringName) -> bool:
	return position.distance_to(_get_button_center(action)) <= BUTTON_RADIUS


func _is_inside_weapon_button(position: Vector2, weapon_index: int) -> bool:
	return position.distance_to(_get_weapon_button_center(weapon_index)) <= WEAPON_BUTTON_RADIUS


func _get_joystick_center() -> Vector2:
	return Vector2(JOYSTICK_RADIUS + 10.0, size.y - JOYSTICK_RADIUS - 10.0)


func _get_button_center(action: StringName) -> Vector2:
	if action == SHOOT_ACTION:
		return Vector2(size.x - 54.0, size.y - 52.0)
	return Vector2(size.x - 106.0, size.y - 112.0)


func _get_weapon_button_center(weapon_index: int) -> Vector2:
	return Vector2(size.x - 26.0 - float(WEAPON_BUTTON_COUNT - weapon_index - 1) * 34.0, 26.0)


func _select_weapon(weapon_index: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var shot_component := player.get_node_or_null(ShotComponent.__NAME__) as ShotComponent
	if shot_component != null:
		shot_component.select_weapon(weapon_index)


func _get_player_input_component() -> PlayerInputComponent:
	if is_instance_valid(_player_input_component):
		return _player_input_component

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null

	_player_input_component = player.get_node_or_null(PlayerInputComponent.__NAME__) as PlayerInputComponent
	return _player_input_component


func _should_show_on_screen_controls() -> bool:
	if not OS.has_feature("web"):
		return false

	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or _is_mobile_preview_requested()


func _is_mobile_preview_requested() -> bool:
	return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('mobile') === '1'") as bool

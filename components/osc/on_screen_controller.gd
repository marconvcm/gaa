## Controles touch exibidos somente na exportação Web em dispositivos móveis.
class_name OnScreenController
extends Control

const JOYSTICK_RADIUS := 34.0
const JOYSTICK_KNOB_RADIUS := 13.0
const BUTTON_RADIUS := 20.0
const BUTTON_BORDER_WIDTH := 2.0
const CONTROL_COLOR := Color(1.0, 1.0, 1.0, 0.8)
const PRESSED_CONTROL_COLOR := Color(1.0, 1.0, 1.0, 1.0)

const MOVE_LEFT_ACTION: StringName = &"move_left"
const MOVE_RIGHT_ACTION: StringName = &"move_right"
const MOVE_UP_ACTION: StringName = &"move_up"
const MOVE_DOWN_ACTION: StringName = &"move_down"
const SHOOT_ACTION: StringName = &"shoot"
const MELEE_ACTION: StringName = &"melee"

var _joystick_touch_index := -1
var _joystick_offset := Vector2.ZERO
var _button_touches: Dictionary = {}


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
				Input.action_press(action)
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
			Input.action_release(action)
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
	_set_action_strength(MOVE_LEFT_ACTION, maxf(-direction.x, 0.0))
	_set_action_strength(MOVE_RIGHT_ACTION, maxf(direction.x, 0.0))
	_set_action_strength(MOVE_UP_ACTION, maxf(-direction.y, 0.0))
	_set_action_strength(MOVE_DOWN_ACTION, maxf(direction.y, 0.0))


func _set_action_strength(action: StringName, strength: float) -> void:
	if is_zero_approx(strength):
		Input.action_release(action)
		return

	Input.action_press(action, strength)


func _release_all_actions() -> void:
	for action in [MOVE_LEFT_ACTION, MOVE_RIGHT_ACTION, MOVE_UP_ACTION, MOVE_DOWN_ACTION, SHOOT_ACTION, MELEE_ACTION]:
		Input.action_release(action)


func _is_inside_joystick(position: Vector2) -> bool:
	return position.distance_to(_get_joystick_center()) <= JOYSTICK_RADIUS


func _is_inside_button(position: Vector2, action: StringName) -> bool:
	return position.distance_to(_get_button_center(action)) <= BUTTON_RADIUS


func _get_joystick_center() -> Vector2:
	return Vector2(size.x - JOYSTICK_RADIUS - 10.0, size.y - JOYSTICK_RADIUS - 10.0)


func _get_button_center(action: StringName) -> Vector2:
	if action == SHOOT_ACTION:
		return Vector2(size.x - 106.0, size.y - 52.0)
	return Vector2(size.x - 54.0, size.y - 112.0)


func _should_show_on_screen_controls() -> bool:
	if not OS.has_feature("web"):
		return false

	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or _is_mobile_preview_requested()


func _is_mobile_preview_requested() -> bool:
	return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('mobile') === '1'") as bool

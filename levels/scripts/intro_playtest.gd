extends Control

const GAME_SCENE_PATH := "res://levels/_BASE_.tscn"
const FADE_DURATION := 0.4

@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_transitioning := false


func _ready() -> void:
	fade_overlay.color.a = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or not event.is_action_pressed("shoot"):
		return

	get_viewport().set_input_as_handled()
	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE_PATH))

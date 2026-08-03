class_name GameOverComponent
extends Node

const INTRO_SCENE_PATH := "res://levels/intro_playtest.tscn"

@export_range(0.0, 5.0, 0.05, "suffix:s") var death_visual_delay := 1.0
@export_range(0.05, 5.0, 0.05, "suffix:s") var fade_duration := 0.35
@export_range(0.0, 10.0, 0.05, "suffix:s") var message_duration := 1.5

@onready var overlay: ColorRect = $"../GameOverOverlay"
@onready var title: Label = $"../GameOverTitle"
@onready var hint: Label = $"../GameOverHint"

var _is_transitioning := false


func _ready() -> void:
	overlay.color.a = 0.0
	title.modulate.a = 0.0
	hint.modulate.a = 0.0
	call_deferred("_connect_player_death")


func _connect_player_death() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var hp_component := player.get_node_or_null(HPComponent.__NAME__) as HPComponent
	if hp_component != null:
		hp_component.died.connect(_on_player_died)


func _on_player_died() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_freeze_combat()
	await get_tree().create_timer(death_visual_delay).timeout
	_show_game_over()


func _freeze_combat() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player != null:
		_freeze_actor(player)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		_freeze_actor(enemy as CharacterBody2D)


func _freeze_actor(actor: CharacterBody2D) -> void:
	if actor == null:
		return

	actor.velocity = Vector2.ZERO
	for child in actor.get_children():
		if child is InputComponent or child is MoveComponent or child is KnockbackComponent or child is ShotComponent or child is MeleeComponent or child is EnemyBrainComponent or child is PlayerControllerComponent:
			child.set_physics_process(false)
		if child is MeleeComponent and is_instance_valid(child.active_hitbox):
			child.active_hitbox.queue_free()


func _show_game_over() -> void:
	overlay.visible = true
	title.visible = true
	hint.visible = true

	var reveal_tween := create_tween().set_parallel()
	reveal_tween.tween_property(overlay, "color:a", 1.0, fade_duration)
	reveal_tween.tween_property(title, "modulate:a", 1.0, fade_duration).set_delay(fade_duration * 0.4)
	reveal_tween.tween_property(hint, "modulate:a", 1.0, fade_duration).set_delay(fade_duration * 0.8)
	await reveal_tween.finished

	await get_tree().create_timer(message_duration).timeout
	var exit_tween := create_tween().set_parallel()
	exit_tween.tween_property(overlay, "color:a", 1.0, fade_duration)
	exit_tween.tween_property(title, "modulate:a", 0.0, fade_duration)
	exit_tween.tween_property(hint, "modulate:a", 0.0, fade_duration)
	await exit_tween.finished

	get_tree().change_scene_to_file(INTRO_SCENE_PATH)

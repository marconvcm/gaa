## Visualização de depuração para qualquer Actor.
##
## Deve ser filho de um CharacterBody2D. Não altera o estado do ator: apenas
## desenha sua origem, seu raio de referência e o vetor de velocidade atual.
class_name DebugActorComponent
extends Node2D

@export var show_only_in_debug_builds := false
@export_range(1.0, 256.0, 1.0, "suffix:px") var radius := 10.0
@export_range(1.0, 256.0, 1.0, "suffix:px") var max_velocity_line_length := 24.0
@export_range(0.0, 256.0, 1.0, "suffix:px") var facing_point_distance := 14.0
@export var health_bar_size := Vector2(24, 4)
@export var health_bar_offset := Vector2(0, -18)
@export var debug_color := Color("f7d74d")

var _body: CharacterBody2D
var _move_component: MoveComponent
var _melee_component: MeleeComponent
var _hp_component: HPComponent


func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body == null:
		push_error("DebugActorComponent deve ser filho de um CharacterBody2D.")
		set_process(false)
		return
	_move_component = _body.get_node_or_null("MoveComponent") as MoveComponent
	_melee_component = _body.get_node_or_null("MeleeComponent") as MeleeComponent
	_hp_component = _body.get_node_or_null("HPComponent") as HPComponent

	if show_only_in_debug_builds and not OS.has_feature("debug"):
		visible = false
		set_process(false)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _body == null:
		return

	var transparent_color := Color(debug_color, 0.2)
	draw_circle(Vector2.ZERO, radius, transparent_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, debug_color, 1.0)
	draw_line(Vector2(-radius, 0), Vector2(radius, 0), debug_color, 1.0)
	draw_line(Vector2(0, -radius), Vector2(0, radius), debug_color, 1.0)
	_draw_facing_point()
	_draw_active_melee_hitbox()
	_draw_health_bar()

	if not _body.velocity.is_zero_approx():
		var velocity_line := _body.velocity.limit_length(max_velocity_line_length)
		draw_line(Vector2.ZERO, velocity_line, Color("58d7ff"), 2.0)
		draw_circle(velocity_line, 2.0, Color("58d7ff"))


func _draw_facing_point() -> void:
	if _move_component == null:
		return

	var point_position := _move_component.facing_direction * facing_point_distance
	var point_rect := Rect2(point_position - Vector2(2, 2), Vector2(4, 4))
	draw_rect(point_rect, Color("ff6b6b"))


func _draw_active_melee_hitbox() -> void:
	if _melee_component == null or not is_instance_valid(_melee_component.active_hitbox):
		return

	var hitbox := _melee_component.active_hitbox
	var local_position := to_local(hitbox.global_position)
	var hitbox_rect := Rect2(local_position - _melee_component.hitbox_size / 2.0, _melee_component.hitbox_size)
	draw_rect(hitbox_rect, Color("ff914d", 0.35))
	draw_rect(hitbox_rect, Color("ff914d"), false, 1.0)


func _draw_health_bar() -> void:
	if _hp_component == null or _hp_component.value == null:
		return

	var health_value := _hp_component.value
	var health_ratio := 0.0
	if health_value.maximum_value > 0.0:
		health_ratio = health_value.current_value / health_value.maximum_value

	var bar_position := health_bar_offset - health_bar_size / 2.0
	var bar_rect := Rect2(bar_position, health_bar_size)
	draw_rect(bar_rect, Color("2b1720"))

	var fill_size := Vector2(maxf(health_bar_size.x - 2.0, 0.0) * health_ratio, maxf(health_bar_size.y - 2.0, 0.0))
	var fill_rect := Rect2(bar_position + Vector2.ONE, fill_size)
	draw_rect(fill_rect, Color("63d471"))
	draw_rect(bar_rect, Color.WHITE, false, 1.0)

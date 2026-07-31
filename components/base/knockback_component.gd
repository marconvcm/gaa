## Aplica movimento de recuo e desacelera até o ator parar.
class_name KnockbackComponent
extends Node

@export_range(0.0, 5000.0, 1.0, "suffix:px/s²") var deceleration := 900.0
@export var limit_to_current_room := false

var _body: CharacterBody2D
var _velocity := Vector2.ZERO


func _ready() -> void:
	process_physics_priority = -1
	_body = get_parent() as CharacterBody2D
	if _body == null:
		push_error("KnockbackComponent deve ser filho de um CharacterBody2D.")


func apply(direction: Vector2, force: float) -> void:
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	_velocity = direction.normalized() * force


func apply_from(source_position: Vector2, force: float) -> void:
	if _body == null:
		return
	# O vetor parte do centro do ator atingido, mantendo o recuo alinhado ao
	# centro de quem atacou, independentemente do ponto de colisão.
	apply(_body.global_position - source_position, force)


func is_active() -> bool:
	return not _velocity.is_zero_approx()


func _physics_process(delta: float) -> void:
	if is_active():
		move(delta)


func move(delta: float) -> void:
	if _body == null:
		return

	var next_velocity := _velocity
	if limit_to_current_room and not RoomManager.is_position_inside_current_room(_body.global_position + next_velocity * delta):
		next_velocity = Vector2.ZERO
		_velocity = Vector2.ZERO
	_body.velocity = next_velocity
	_body.move_and_slide()
	_velocity = _velocity.move_toward(Vector2.ZERO, deceleration * delta)

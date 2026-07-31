## Move um CharacterBody2D usando a direção fornecida por um InputComponent.
class_name MoveComponent 
extends Node

@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var speed := 160.0
@export var use_eight_direction_movement := true
@export var movement_enabled := true
@export var limit_to_current_room := false
@export var input_component: InputComponent

var _body: CharacterBody2D
var _melee_component: MeleeComponent
var _knockback_component: KnockbackComponent

## Última direção de movimento não nula. Outros componentes podem usá-la para
## orientação visual, ataques e interações.
var facing_direction := Vector2.DOWN

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body == null:
		push_error("MoveComponent deve ser filho de um CharacterBody2D.")
		set_physics_process(false)
		return
	if not movement_enabled:
		set_physics_process(false)
		return
	_melee_component = _body.get_node_or_null("MeleeComponent") as MeleeComponent
	_knockback_component = _body.get_node_or_null("KnockbackComponent") as KnockbackComponent

	if input_component == null:
		input_component = _find_input_component()

	if input_component == null:
		push_error("MoveComponent requer um InputComponent na mesma entidade.")
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _knockback_component != null and _knockback_component.is_active():
		return

	if _melee_component != null and _melee_component.is_attacking():
		_body.velocity = Vector2.ZERO
		return

	var movement_direction := input_component.get_movement_direction()
	if not movement_direction.is_zero_approx():
		facing_direction = _snap_to_eight_directions(movement_direction)
		if use_eight_direction_movement:
			movement_direction = facing_direction
	var next_velocity := movement_direction * speed
	if limit_to_current_room and not RoomManager.is_position_inside_current_room(_body.global_position + next_velocity * _delta):
		next_velocity = Vector2.ZERO
	_body.velocity = next_velocity
	_body.move_and_slide()


func _find_input_component() -> InputComponent:
	for child in _body.get_children():
		if child is InputComponent:
			return child
	return null


func _snap_to_eight_directions(direction: Vector2) -> Vector2:
	var angle_step := TAU / 8.0
	var snapped_angle := snappedf(direction.angle(), angle_step)
	return Vector2.RIGHT.rotated(snapped_angle)

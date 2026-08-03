## Cria uma hitbox curta na direção em que o ator está olhando.
class_name MeleeComponent
extends Node

static var __NAME__: NodePath = ^"MeleeComponent"

signal attack_started(hitbox: HitboxComponent)

@export_range(0, 9999, 1) var damage := 1
@export_range(0.0, 10.0, 0.01, "suffix:s") var cooldown := 0.4
@export_range(0.01, 2.0, 0.01, "suffix:s") var active_time := 0.12
@export_range(0.0, 256.0, 1.0, "suffix:px") var attack_distance := 14.0
@export var hitbox_size := Vector2(16, 16)
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var knockback_force := 220.0

var _actor: Node2D
var _input_component: InputComponent
var _move_component: MoveComponent
var _animation_player: AnimationPlayer
var _cooldown_remaining := 0.0
var active_hitbox: HitboxComponent


func _ready() -> void:
	process_physics_priority = -1
	_actor = get_parent() as Node2D
	if _actor == null:
		push_error("MeleeComponent deve ser filho de um Node2D.")
		set_physics_process(false)
		return

	_input_component = _find_input_component()
	_move_component = _actor.get_node_or_null(MoveComponent.__NAME__) as MoveComponent
	_animation_player = _actor.get_node_or_null("AnimationPlayer") as AnimationPlayer


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _input_component != null and _input_component.is_melee_requested():
		attack()


func attack(direction := Vector2.ZERO) -> HitboxComponent:
	if _cooldown_remaining > 0.0:
		return null

	var attack_direction := direction
	if attack_direction.is_zero_approx() and _move_component != null:
		attack_direction = _move_component.facing_direction
	if attack_direction.is_zero_approx():
		attack_direction = Vector2.DOWN
	attack_direction = attack_direction.normalized()

	var hitbox := HitboxComponent.new()
	hitbox.damage = damage
	hitbox.knockback_force = knockback_force
	hitbox.source_actor = _actor
	hitbox.global_position = _actor.global_position + attack_direction * attack_distance
	hitbox.add_child(_create_collision_shape())
	get_tree().current_scene.add_child(hitbox)
	active_hitbox = hitbox
	_play_attack_animation()

	_cooldown_remaining = cooldown
	attack_started.emit(hitbox)
	get_tree().create_timer(active_time).timeout.connect(_finish_attack)
	return hitbox


func _finish_attack() -> void:
	if not is_instance_valid(active_hitbox):
		active_hitbox = null
		return

	active_hitbox.queue_free()
	active_hitbox = null


func is_attacking() -> bool:
	return is_instance_valid(active_hitbox)


func _create_collision_shape() -> CollisionShape2D:
	var collision_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = hitbox_size
	collision_shape.shape = shape
	return collision_shape


func _play_attack_animation() -> void:
	if _animation_player != null and _animation_player.has_animation(&"melee_attack"):
		_animation_player.play(&"melee_attack")


func _find_input_component() -> InputComponent:
	for child in _actor.get_children():
		if child is InputComponent:
			return child
	return null

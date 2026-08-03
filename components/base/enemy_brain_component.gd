## Máquina de estados reutilizável para inimigos top-down.
##
## A percepção usa distância, campo de visão e uma consulta de raio opcional.
## O componente apenas decide intenções; movimento e ataques continuam nos
## componentes genéricos do ator.
class_name EnemyBrainComponent
extends Node

static var __NAME__: NodePath = ^"EnemyBrainComponent"

signal state_changed(previous_state: State, current_state: State)

enum State {
	PATROL,
	CHASE,
	ATTACK,
	INVESTIGATE,
	STUNNED,
}

@export var behavior: Resource
@export var target: Node2D
@export_range(1.0, 1000.0, 1.0, "suffix:px") var perception_radius := 144.0
@export_range(0.0, 360.0, 1.0, "suffix:°") var field_of_view := 140.0
@export var require_line_of_sight := true
@export_flags_2d_physics var vision_collision_mask := 1
@export_range(0.01, 10.0, 0.01, "suffix:s") var lost_target_memory_time := 1.5
@export_range(0.01, 10.0, 0.01, "suffix:s") var alert_memory_time := 4.0
@export_range(1.0, 256.0, 1.0, "suffix:px") var attack_range := 22.0
@export var use_navigation_for_investigation := false
@export_range(0.0, 5.0, 0.01, "suffix:s") var hit_stun_duration := 0.18

var state := State.PATROL

var _actor: Node2D
var _ai_input: AIInputComponent
var _melee_component: MeleeComponent
var _move_component: MoveComponent
var _knockback_component: KnockbackComponent
var _hp_component: HPComponent
var _enemy_component: EnemyComponent
var _last_known_target_position := Vector2.ZERO
var _memory_remaining := 0.0
var _stun_remaining := 0.0


func _ready() -> void:
	process_physics_priority = -2
	_actor = get_parent() as Node2D
	if _actor == null:
		push_error("EnemyBrainComponent precisa ser filho de um Node2D.")
		set_physics_process(false)
		return

	_ai_input = _actor.get_node_or_null(AIInputComponent.__NAME__) as AIInputComponent
	_melee_component = _actor.get_node_or_null(MeleeComponent.__NAME__) as MeleeComponent
	_move_component = _actor.get_node_or_null(MoveComponent.__NAME__) as MoveComponent
	_knockback_component = _actor.get_node_or_null(KnockbackComponent.__NAME__) as KnockbackComponent
	_hp_component = _actor.get_node_or_null(HPComponent.__NAME__) as HPComponent
	_enemy_component = _actor.get_node_or_null(EnemyComponent.__NAME__) as EnemyComponent
	if _ai_input == null:
		push_error("EnemyBrainComponent requer um AIInputComponent no mesmo ator.")
		set_physics_process(false)
		return

	_apply_behavior()
	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node2D


func _apply_behavior() -> void:
	if behavior == null:
		return
	var profile: Variant = behavior

	perception_radius = profile.perception_radius
	field_of_view = profile.field_of_view
	require_line_of_sight = profile.require_line_of_sight
	vision_collision_mask = profile.vision_collision_mask
	lost_target_memory_time = profile.lost_target_memory_time
	alert_memory_time = profile.alert_memory_time
	attack_range = profile.attack_range
	use_navigation_for_investigation = profile.use_navigation_for_investigation
	hit_stun_duration = profile.hit_stun_duration

	if _move_component != null:
		_move_component.speed = profile.movement_speed
		_move_component.use_eight_direction_movement = profile.use_eight_direction_movement
	if _knockback_component != null:
		_knockback_component.deceleration = profile.knockback_deceleration
	if _melee_component != null:
		_melee_component.damage = profile.melee_damage
		_melee_component.cooldown = profile.melee_cooldown
		_melee_component.active_time = profile.melee_active_time
		_melee_component.attack_distance = profile.melee_distance
		_melee_component.hitbox_size = profile.melee_hitbox_size
		_melee_component.knockback_force = profile.melee_knockback_force
	if _hp_component != null and _hp_component.value != null:
		_hp_component.value.maximum_value = profile.maximum_health
		_hp_component.value.current_value = profile.maximum_health
	if _enemy_component != null:
		_enemy_component.hit_flash_duration = profile.hit_flash_duration


func _physics_process(delta: float) -> void:
	if _stun_remaining > 0.0:
		_stun_remaining = maxf(_stun_remaining - delta, 0.0)
		_enter_state(State.STUNNED)
		_ai_input.set_external_movement_direction(Vector2.ZERO)
		return

	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Node2D
		_enter_state(State.PATROL)
		_ai_input.resume_autonomous_movement()
		return

	var can_see_target := _can_see_target()
	if can_see_target:
		_last_known_target_position = target.global_position
		_memory_remaining = lost_target_memory_time
	elif _memory_remaining > 0.0:
		_memory_remaining = maxf(_memory_remaining - delta, 0.0)

	if can_see_target and _actor.global_position.distance_to(target.global_position) <= attack_range:
		_enter_state(State.ATTACK)
	elif can_see_target:
		_enter_state(State.CHASE)
	elif _memory_remaining > 0.0:
		_enter_state(State.INVESTIGATE)
	else:
		_enter_state(State.PATROL)

	_update_state()


func _update_state() -> void:
	match state:
		State.PATROL:
			_ai_input.resume_autonomous_movement()
		State.CHASE:
			# A perseguição só entra neste estado com linha de visão. Ir direto ao
			# alvo evita oscilações do caminho enquanto ele está à vista; o agente
			# de navegação continua sendo usado para investigar atrás de obstáculos.
			_ai_input.set_external_movement_direction(_actor.global_position.direction_to(target.global_position))
		State.ATTACK:
			_ai_input.set_external_movement_direction(Vector2.ZERO)
			var attack_direction := _actor.global_position.direction_to(target.global_position)
			if _move_component != null and not attack_direction.is_zero_approx():
				_move_component.facing_direction = _snap_to_eight_directions(attack_direction)
			if _melee_component != null:
				_melee_component.attack(attack_direction)
		State.INVESTIGATE:
			if _actor.global_position.distance_to(_last_known_target_position) <= _ai_input.stopping_distance:
				_memory_remaining = 0.0
				_ai_input.set_external_movement_direction(Vector2.ZERO)
			else:
				_ai_input.set_external_movement_direction(_get_investigation_direction())


func _can_see_target() -> bool:
	if not is_instance_valid(target):
		return false

	var direction_to_target := _actor.global_position.direction_to(target.global_position)
	if _actor.global_position.distance_to(target.global_position) > perception_radius:
		return false

	if field_of_view < 360.0 and _move_component != null:
		var facing := _move_component.facing_direction
		if not facing.is_zero_approx() and absf(facing.angle_to(direction_to_target)) > deg_to_rad(field_of_view * 0.5):
			return false

	return not require_line_of_sight or _has_line_of_sight()


func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(_actor.global_position, target.global_position, vision_collision_mask)
	query.exclude = [_actor.get_rid()]
	query.collide_with_areas = false
	var hit := _actor.get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target


## Dados de leitura usados pelo DebugActorComponent sem expor o estado interno.
func is_target_visible() -> bool:
	return _can_see_target()


func get_last_known_target_position() -> Vector2:
	return _last_known_target_position


func _get_investigation_direction() -> Vector2:
	if use_navigation_for_investigation:
		return _ai_input.get_direction_to(_last_known_target_position)
	return _actor.global_position.direction_to(_last_known_target_position)


## Coloca o inimigo em alerta ao receber dano, mesmo que o atacante esteja
## fora do campo de visão. Se o atacante voltar a ficar visível, o próximo
## ciclo naturalmente muda o estado para perseguição ou ataque.
func alert(attacker: Node2D, attacker_position: Vector2) -> void:
	if is_instance_valid(attacker):
		target = attacker
		_last_known_target_position = attacker.global_position
	else:
		_last_known_target_position = attacker_position
	_memory_remaining = maxf(_memory_remaining, alert_memory_time)
	_enter_state(State.INVESTIGATE)


## Interrompe temporariamente a perseguição sem apagar o estado de alerta.
func stun(duration := hit_stun_duration) -> void:
	_stun_remaining = maxf(_stun_remaining, duration)


func _snap_to_eight_directions(direction: Vector2) -> Vector2:
	return Vector2.RIGHT.rotated(snappedf(direction.angle(), TAU / 8.0))


func _enter_state(next_state: State) -> void:
	if state == next_state:
		return

	var previous_state := state
	state = next_state
	state_changed.emit(previous_state, state)

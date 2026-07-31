## Produz uma direção para perseguir um alvo ou seguir uma direção definida.
class_name AIInputComponent
extends InputComponent

@export var target: Node2D
@export_range(0.0, 1000.0, 1.0, "suffix:px") var stopping_distance := 4.0
@export var patrol_offsets: Array[Vector2] = [Vector2(-40, 0), Vector2(40, 0)]
@export_range(0.0, 10.0, 0.1, "suffix:s") var patrol_wait_time := 0.5

## Útil para patrulhas e outros comportamentos que controlam a IA por código.
var desired_direction := Vector2.ZERO

var _actor: Node2D
var _navigation_agent: NavigationAgent2D
var _patrol_origin := Vector2.ZERO
var _patrol_index := 0
var _wait_remaining := 0.0
var _external_movement_enabled := false


func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor == null:
		push_error("AIInputComponent precisa ser filho de um Node2D.")
		set_physics_process(false)
		return

	_navigation_agent = _actor.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	_patrol_origin = _actor.global_position


func get_movement_direction() -> Vector2:
	if _external_movement_enabled:
		return desired_direction.limit_length(1.0)

	if is_instance_valid(target):
		return _get_direction_to(target.global_position)

	if not patrol_offsets.is_empty():
		return _get_patrol_direction()

	return desired_direction.limit_length(1.0)


## Permite que uma máquina de estados controle temporariamente o deslocamento.
## Enquanto ativo, a patrulha e o alvo exportado não interferem na direção.
func set_external_movement_direction(direction: Vector2) -> void:
	_external_movement_enabled = true
	desired_direction = direction.limit_length(1.0)


func resume_autonomous_movement() -> void:
	_external_movement_enabled = false


## Retorna uma direção que respeita o NavigationAgent2D quando disponível.
func get_direction_to(destination: Vector2) -> Vector2:
	return _get_direction_to(destination)


func _get_patrol_direction() -> Vector2:
	if _wait_remaining > 0.0:
		_wait_remaining -= get_physics_process_delta_time()
		return Vector2.ZERO

	var patrol_destination := _patrol_origin + patrol_offsets[_patrol_index]
	if _actor.global_position.distance_to(patrol_destination) <= stopping_distance:
		_patrol_index = wrapi(_patrol_index + 1, 0, patrol_offsets.size())
		_wait_remaining = patrol_wait_time
		return Vector2.ZERO

	return _get_direction_to(patrol_destination)


func _get_direction_to(destination: Vector2) -> Vector2:
	if _actor.global_position.distance_to(destination) <= stopping_distance:
		return Vector2.ZERO

	if _navigation_agent != null:
		_navigation_agent.target_position = destination
		var navigation_map := _navigation_agent.get_navigation_map()
		var navigation_is_ready := navigation_map.is_valid() and NavigationServer2D.map_get_iteration_id(navigation_map) > 0
		if navigation_is_ready and not _navigation_agent.is_navigation_finished():
			var next_path_position := _navigation_agent.get_next_path_position()
			if not next_path_position.is_equal_approx(_actor.global_position):
				return _actor.global_position.direction_to(next_path_position)

	# Antes de o NavigationRegion2D sincronizar, o agente pode expor um ponto de
	# caminho obsoleto. Seguir diretamente evita que a entidade saia em uma
	# direção arbitrária no primeiro contato com o alvo.
	return _actor.global_position.direction_to(destination)

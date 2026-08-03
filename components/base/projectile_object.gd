## Projétil visual temporário. Mais tarde poderá receber colisão e uma hitbox.
class_name ProjectileObject
extends Sprite2D

@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var speed := 300.0
@export_range(0.0, 30.0, 0.1, "suffix:s") var lifetime := 1.5
@export_range(1.0, 64.0, 1.0, "suffix:px") var radius := 3.0
@export_range(0, 9999, 1) var damage := 1
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var knockback_force := 120.0

var direction := Vector2.RIGHT
var source_actor: Node2D
var _elapsed_time := 0.0
var _hitbox: HitboxComponent
var _has_finished := false


static func create(
	source: Node2D,
	spawn_position: Vector2,
	projectile_direction: Vector2,
	projectile_speed: float,
	projectile_damage: int,
	projectile_knockback_force: float,
) -> ProjectileObject:
	var projectile := ProjectileObject.new()
	projectile.source_actor = source
	projectile.global_position = spawn_position
	projectile.direction = projectile_direction.normalized()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.knockback_force = projectile_knockback_force
	return projectile


func _ready() -> void:
	_create_hitbox()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var motion := direction * speed * delta
	var collision := _get_swept_collision(motion)
	if not collision.is_empty() and _is_blocking_collision(collision):
		var safe_fraction := _get_safe_motion_fraction(motion)
		global_position += motion * safe_fraction
		_handle_swept_collision(collision)
		return

	global_position += motion
	if not RoomManager.is_position_inside_current_room(global_position):
		_finish()
		return

	_elapsed_time += delta
	if _elapsed_time >= lifetime:
		_finish()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.RED)


func _create_hitbox() -> void:
	_hitbox = HitboxComponent.new()
	_hitbox.damage = damage
	_hitbox.knockback_force = knockback_force
	_hitbox.source_actor = source_actor
	_hitbox.collision_mask = 1
	_hitbox.hit_landed.connect(_on_hit_landed)
	_hitbox.body_entered.connect(_on_body_entered)

	var collision_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	_hitbox.add_child(collision_shape)
	add_child(_hitbox)


func _on_hit_landed(_hurtbox: HurtboxComponent) -> void:
	_finish()


func _on_body_entered(body: Node2D) -> void:
	# TileMapLayer emite a colisão dos polígonos físicos do TileSet como o
	# próprio TileMapLayer, e não como um StaticBody2D separado. Como a hitbox
	# usa collision_mask = 1, ambos os casos já estão restritos à layer 1.
	if body is StaticBody2D or body is TileMapLayer:
		_finish()


func _get_swept_collision(motion: Vector2) -> Dictionary:
	if motion.is_zero_approx() or _hitbox == null:
		return {}

	var query := _create_shape_query(motion)
	return get_world_2d().direct_space_state.get_rest_info(query)


func _get_safe_motion_fraction(motion: Vector2) -> float:
	var query := _create_shape_query(motion)
	var motion_fractions := get_world_2d().direct_space_state.cast_motion(query)
	if motion_fractions.is_empty():
		return 0.0
	return motion_fractions[0]


func _create_shape_query(motion: Vector2) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.motion = motion
	query.collision_mask = _hitbox.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var excluded_rids: Array[RID] = [_hitbox.get_rid()]
	if source_actor is CollisionObject2D:
		excluded_rids.append(source_actor.get_rid())
	if source_actor != null:
		var source_hurtbox := source_actor.get_node_or_null(HurtboxComponent.__NAME__) as HurtboxComponent
		if source_hurtbox != null:
			excluded_rids.append(source_hurtbox.get_rid())
	query.exclude = excluded_rids
	return query


func _is_blocking_collision(collision: Dictionary) -> bool:
	var collider: Object = collision.get("collider") as Object
	var hurtbox := collider as HurtboxComponent
	if hurtbox != null:
		return hurtbox.can_receive_hit_from(_hitbox)

	return collider is StaticBody2D or collider is TileMapLayer


func _handle_swept_collision(collision: Dictionary) -> void:
	var collider: Object = collision.get("collider") as Object
	var hurtbox := collider as HurtboxComponent
	if hurtbox != null:
		hurtbox.receive_hit(_hitbox)
		_hitbox.hit_landed.emit(hurtbox)
		return

	if collider is StaticBody2D or collider is TileMapLayer:
		_finish()


func _finish() -> void:
	if _has_finished:
		return

	_has_finished = true
	if _hitbox != null:
		_hitbox.set_deferred("monitoring", false)
	queue_free()

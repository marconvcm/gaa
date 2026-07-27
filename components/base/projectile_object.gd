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


static func create(
	source: Node2D,
	spawn_position: Vector2,
	projectile_direction: Vector2,
	projectile_damage: int,
	projectile_knockback_force: float,
) -> ProjectileObject:
	var projectile := ProjectileObject.new()
	projectile.source_actor = source
	projectile.global_position = spawn_position
	projectile.direction = projectile_direction.normalized()
	projectile.damage = projectile_damage
	projectile.knockback_force = projectile_knockback_force
	return projectile


func _ready() -> void:
	_create_hitbox()
	queue_redraw()


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	if not RoomManager.is_position_inside_current_room(global_position):
		queue_free()
		return

	_elapsed_time += delta
	if _elapsed_time >= lifetime:
		queue_free()


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
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	# TileMapLayer emite a colisão dos polígonos físicos do TileSet como o
	# próprio TileMapLayer, e não como um StaticBody2D separado. Como a hitbox
	# usa collision_mask = 1, ambos os casos já estão restritos à layer 1.
	if body is StaticBody2D or body is TileMapLayer:
		queue_free()

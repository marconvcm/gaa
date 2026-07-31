## Item coletável no chão. Outros sistemas podem reagir ao sinal collected.
class_name CollectableObject
extends Area2D

signal collected(item: Resource, collector: Node2D)

const SCENE: PackedScene = preload("res://components/collectable.tscn")

@export var item: Resource
@export_range(1.0, 1000.0, 1.0, "suffix:px/s") var attraction_speed := 160.0
@export_range(0.0, 64.0, 1.0, "suffix:px") var collect_distance := 4.0

var _was_collected := false
var _attraction_target: Node2D


static func create(spawn_position: Vector2, collectable_item: Resource = null) -> CollectableObject:
	var collectable := SCENE.instantiate() as CollectableObject
	collectable.global_position = spawn_position
	collectable.item = collectable_item
	return collectable


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _was_collected or not is_instance_valid(_attraction_target):
		return

	global_position = global_position.move_toward(
		_attraction_target.global_position,
		attraction_speed * delta,
	)
	if global_position.distance_to(_attraction_target.global_position) <= collect_distance:
		_collect(_attraction_target)


func attract_to(target: Node2D) -> void:
	if not _was_collected:
		_attraction_target = target


func _on_body_entered(body: Node2D) -> void:
	if _was_collected or not body.is_in_group("player"):
		return

	_collect(body)


func _collect(collector: Node2D) -> void:
	if _was_collected:
		return

	_was_collected = true
	set_deferred("monitoring", false)
	collected.emit(item, collector)
	queue_free()

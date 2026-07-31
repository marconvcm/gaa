## Atrai CollectableObjects próximos para o ator que contém este componente.
class_name CollectableAttractionComponent
extends Area2D

@export_range(1.0, 256.0, 1.0, "suffix:px") var attraction_radius := 32.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _actor: Node2D


func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor == null:
		push_error("CollectableAttractionComponent deve ser filho de um Node2D.")
		set_physics_process(false)
		return

	var circle_shape := collision_shape.shape as CircleShape2D
	if circle_shape != null:
		circle_shape.radius = attraction_radius
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var collectable := area as CollectableObject
	if collectable != null:
		collectable.attract_to(_actor)

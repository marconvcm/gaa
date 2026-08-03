## Controla os pontos de vida do ator usando um ActiveValue.
class_name HPComponent
extends Node

static var __NAME__: NodePath = ^"HPComponent"

signal damage_taken(amount: float)
signal hit_received(hitbox: HitboxComponent)
signal died

@onready var value: ActiveValue = $ActiveValue


func _ready() -> void:
	value.depleted.connect(_on_value_depleted)
	var hurtbox := get_parent().get_node_or_null(HurtboxComponent.__NAME__) as HurtboxComponent
	if hurtbox != null:
		hurtbox.hit_received.connect(_on_hit_received)


func take_damage(amount: float) -> void:
	value.discharge(amount)
	damage_taken.emit(amount)


func heal(amount: float) -> void:
	value.charge(amount)


func _on_hit_received(hitbox: HitboxComponent) -> void:
	take_damage(hitbox.damage)
	hit_received.emit(hitbox)


func _on_value_depleted() -> void:
	died.emit()

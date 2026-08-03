## Área que recebe ataques de HitboxComponent.
##
## Adicione um CollisionShape2D como filho. Sistemas de vida podem conectar ao
## sinal `hit_received` para aplicar dano, invencibilidade ou knockback.
class_name HurtboxComponent
extends Area2D

static var __NAME__: NodePath = ^"HurtboxComponent"

signal hit_received(hitbox: HitboxComponent)

@export var can_receive_damage := true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		receive_hit(area)


func receive_hit(hitbox: HitboxComponent) -> void:
	if can_receive_hit_from(hitbox):
		hit_received.emit(hitbox)


func can_receive_hit_from(hitbox: HitboxComponent) -> bool:
	return can_receive_damage and hitbox.get_actor() != get_parent()

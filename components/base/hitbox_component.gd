## Área que causa dano quando toca em um HurtboxComponent.
##
## Adicione um CollisionShape2D como filho e configure as camadas de colisão
## no Inspector para definir quais hurtboxes este ataque pode acertar.
class_name HitboxComponent
extends Area2D

signal hit_landed(hurtbox: HurtboxComponent)

@export_range(0, 9999, 1) var damage := 1
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var knockback_force := 220.0

var source_actor: Node2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func get_actor() -> Node2D:
	if is_instance_valid(source_actor):
		return source_actor
	return get_parent() as Node2D


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox != null and hurtbox.can_receive_hit_from(self):
		hit_landed.emit(hurtbox)

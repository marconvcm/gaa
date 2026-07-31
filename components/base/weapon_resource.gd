## Configuração reutilizável de uma arma disparada pelo ShotComponent.
class_name WeaponResource
extends Resource

@export var weapon_id: StringName
@export_range(0, 9999, 1) var ammo_capacity := 30
@export_range(1, 9999, 1) var clip_size := 12
@export_range(0.05, 10.0, 0.05, "suffix:s") var reload_duration := 1.0
@export var automatic_fire := false
@export_range(0.1, 100.0, 0.1, "suffix: tiros/s") var fire_rate := 4.0
@export_range(0.0, 256.0, 1.0, "suffix:px") var spawn_distance := 12.0
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var projectile_speed := 300.0
@export_range(1, 32, 1) var projectile_count := 1
@export_range(0.0, 180.0, 0.1, "suffix:°") var spread_degrees := 0.0
@export_range(0, 9999, 1) var damage := 1
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var knockback_force := 120.0

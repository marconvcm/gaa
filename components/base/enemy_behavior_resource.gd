## Perfil reutilizável para calibrar um Enemy sem alterar seus componentes.
class_name EnemyBehaviorResource
extends Resource

@export_category("Movimento")
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var movement_speed := 72.0
@export var use_eight_direction_movement := true
@export_range(0.0, 5000.0, 1.0, "suffix:px/s²") var knockback_deceleration := 1500.0

@export_category("Percepção")
@export_range(1.0, 1000.0, 1.0, "suffix:px") var perception_radius := 144.0
@export_range(0.0, 360.0, 1.0, "suffix:°") var field_of_view := 140.0
@export var require_line_of_sight := true
@export_flags_2d_physics var vision_collision_mask := 1
@export_range(0.01, 10.0, 0.01, "suffix:s") var lost_target_memory_time := 1.5
@export_range(0.01, 10.0, 0.01, "suffix:s") var alert_memory_time := 4.0
@export var use_navigation_for_investigation := false

@export_category("Ataque Melee")
@export_range(1.0, 256.0, 1.0, "suffix:px") var attack_range := 22.0
@export_range(0, 9999, 1) var melee_damage := 1
@export_range(0.0, 10.0, 0.01, "suffix:s") var melee_cooldown := 0.4
@export_range(0.01, 2.0, 0.01, "suffix:s") var melee_active_time := 0.12
@export_range(0.0, 256.0, 1.0, "suffix:px") var melee_distance := 16.0
@export var melee_hitbox_size := Vector2(24, 24)
@export_range(0.0, 5000.0, 1.0, "suffix:px/s") var melee_knockback_force := 220.0

@export_category("Vida e Reação")
@export_range(1.0, 999999.0, 1.0) var maximum_health := 10.0
@export_range(0.0, 5.0, 0.01, "suffix:s") var hit_flash_duration := 0.3
@export_range(0.0, 5.0, 0.01, "suffix:s") var hit_stun_duration := 0.18

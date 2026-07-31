extends Control

const BAR_POSITION := Vector2(8.0, 8.0)
const BAR_SIZE := Vector2(96.0, 10.0)
const BAR_BORDER_COLOR := Color(0.05, 0.05, 0.05, 1.0)
const BAR_BACKGROUND_COLOR := Color(0.22, 0.05, 0.05, 1.0)
const BAR_FILL_COLOR := Color(0.25, 0.9, 0.3, 1.0)

@onready var weapon_label: Label = $WeaponLabel
@onready var clip_label: Label = $ClipLabel
@onready var reserve_label: Label = $ReserveLabel

var _health_value: ActiveValue
var _player_controller: PlayerControllerComponent
var _shot_component: ShotComponent


func _ready() -> void:
	call_deferred("_connect_player_health")


func _draw() -> void:
	draw_rect(Rect2(BAR_POSITION, BAR_SIZE), BAR_BORDER_COLOR)
	var inner_bar_rect := Rect2(BAR_POSITION + Vector2.ONE, BAR_SIZE - Vector2(2.0, 2.0))
	draw_rect(inner_bar_rect, BAR_BACKGROUND_COLOR)

	if _health_value == null:
		return

	var health_ratio := _health_value.current_value / _health_value.maximum_value
	var health_bar_rect := Rect2(inner_bar_rect.position, Vector2(inner_bar_rect.size.x * health_ratio, inner_bar_rect.size.y))
	draw_rect(health_bar_rect, BAR_FILL_COLOR)


func _connect_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var hp_component := player.get_node_or_null("HPComponent") as HPComponent
	if hp_component == null:
		return

	_health_value = hp_component.value
	_health_value.value_changed.connect(_on_health_changed)
	_shot_component = player.get_node_or_null("ShotComponent") as ShotComponent
	if _shot_component != null:
		_shot_component.weapon_changed.connect(_on_weapon_changed)
		_player_controller = player.get_node_or_null("PlayerControllerComponent") as PlayerControllerComponent
		if _player_controller != null:
			_player_controller.ammunition_changed.connect(_on_ammunition_changed)
		_on_weapon_changed(_shot_component.weapon)
	queue_redraw()


func _on_health_changed(_current_value: float, _maximum_value: float) -> void:
	queue_redraw()


func _on_weapon_changed(weapon: WeaponResource) -> void:
	if weapon == null:
		weapon_label.text = "ARMA: ---"
		return

	weapon_label.text = "ARMA: %s" % weapon.resource_name.to_upper()
	if _player_controller != null:
		_set_ammo_labels(
			_player_controller.get_clip_ammo(weapon),
			weapon.clip_size,
			_player_controller.get_reserve_ammo(weapon),
			weapon.ammo_capacity,
		)


func _on_ammunition_changed(weapon: WeaponResource, clip_ammo: int, reserve_ammo: int) -> void:
	if _shot_component != null and weapon != _shot_component.weapon:
		return

	_set_ammo_labels(clip_ammo, weapon.clip_size, reserve_ammo, weapon.ammo_capacity)


func _set_ammo_labels(clip_ammo: int, clip_size: int, reserve_ammo: int, reserve_capacity: int) -> void:
	clip_label.text = "PENTE: %d / %d" % [clip_ammo, clip_size]
	reserve_label.text = "RESERVA: %d / %d" % [reserve_ammo, reserve_capacity]

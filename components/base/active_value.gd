## Valor reutilizável que pode carregar ou descarregar automaticamente.
class_name ActiveValue
extends Node

signal value_changed(current_value: float, maximum_value: float)
signal depleted
signal filled

var _maximum_value := 10.0
var _current_value := 10.0

@export_range(0.0, 999999.0, 0.1) var maximum_value := 10.0:
	get:
		return _maximum_value
	set(new_maximum_value):
		_maximum_value = maxf(new_maximum_value, 0.0)
		_set_current_value(_current_value)

@export_range(0.0, 999999.0, 0.1) var current_value := 10.0:
	get:
		return _current_value
	set(new_current_value):
		_set_current_value(new_current_value)

@export_range(0.0, 999999.0, 0.1, "suffix:/s") var auto_charge_rate := 0.0
@export_range(0.0, 999999.0, 0.1, "suffix:/s") var auto_discharge_rate := 0.0

var is_auto_charging := false
var is_auto_discharging := false


func _ready() -> void:
	current_value = clampf(current_value, 0.0, maximum_value)


func _process(delta: float) -> void:
	if is_auto_charging:
		charge(auto_charge_rate * delta)
	if is_auto_discharging:
		discharge(auto_discharge_rate * delta)


func charge(amount: float) -> void:
	if amount > 0.0:
		_set_current_value(current_value + amount)


func discharge(amount: float) -> void:
	if amount > 0.0:
		_set_current_value(current_value - amount)


func start_auto_charge(rate := -1.0) -> void:
	if rate >= 0.0:
		auto_charge_rate = rate
	is_auto_charging = true


func stop_auto_charge() -> void:
	is_auto_charging = false


func start_auto_discharge(rate := -1.0) -> void:
	if rate >= 0.0:
		auto_discharge_rate = rate
	is_auto_discharging = true


func stop_auto_discharge() -> void:
	is_auto_discharging = false


func is_empty() -> bool:
	return is_zero_approx(current_value)


func is_full() -> bool:
	return is_equal_approx(current_value, maximum_value)


func _set_current_value(new_value: float) -> void:
	var previous_value := _current_value
	_current_value = clampf(new_value, 0.0, maximum_value)
	if is_equal_approx(previous_value, _current_value):
		return

	value_changed.emit(_current_value, maximum_value)
	if _current_value <= 0.0 and previous_value > 0.0:
		depleted.emit()
	elif _current_value >= maximum_value and previous_value < maximum_value:
		filled.emit()

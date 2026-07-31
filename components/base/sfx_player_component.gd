## Reproduz um som e pode ser conectado a sinais emitidos por outros componentes.
class_name SFXPlayerComponent
extends AudioStreamPlayer

@export_node_path("Node") var event_source_path: NodePath
@export var event_signal: StringName


func _ready() -> void:
	if event_source_path.is_empty() or event_signal.is_empty():
		return
	bind_to_signal(get_node_or_null(event_source_path), event_signal)


## Conecta este player a qualquer sinal. Crie um SFXPlayerComponent por som
## quando um mesmo ator precisar responder a vários eventos.
func bind_to_signal(source: Object, signal_name: StringName) -> void:
	if source == null:
		push_error("SFXPlayerComponent não encontrou a origem do evento.")
		return
	if not source.has_signal(signal_name):
		push_error("SFXPlayerComponent não encontrou o sinal '%s'." % signal_name)
		return

	var callback := play_sfx
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


## Aceita um argumento opcional para poder receber sinais como attack_started,
## que transportam dados do evento além de solicitar o som.
func play_sfx(_event_data: Variant = null) -> void:
	if stream == null:
		return
	stop()
	play()

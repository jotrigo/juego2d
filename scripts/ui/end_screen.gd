extends Control
class_name EndScreen
## Pantalla final de victoria o derrota. Muestra el resumen de la partida y un
## botón para volver a jugar. Funciona en pausa (PROCESS_MODE_ALWAYS).

signal replay_requested

@onready var title_label: Label = $Panel/VBox/Title
@onready var stats_label: Label = $Panel/VBox/Stats
@onready var replay_button: Button = $Panel/VBox/ReplayButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	replay_button.pressed.connect(func() -> void: replay_requested.emit())

## Muestra el resultado. `victory` decide el título y el color.
func show_result(victory: bool, survived_seconds: float, level: int, kills: int) -> void:
	if victory:
		title_label.text = "NIVEL COMPLETADO"
		title_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	else:
		title_label.text = "HAS SIDO DERROTADO"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	var m := int(survived_seconds) / 60
	var s := int(survived_seconds) % 60
	stats_label.text = "Tiempo: %02d:%02d\nNivel alcanzado: %d\nEnemigos eliminados: %d" % [m, s, level, kills]
	visible = true
	# Pausar para congelar la escena de fondo.
	get_tree().paused = true

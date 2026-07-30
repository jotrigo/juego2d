extends Control
class_name RuneSelectionUI
## Menú de selección de runas. Se muestra al subir de nivel (con el árbol
## pausado) y presenta tres tarjetas distintas. Al elegir una, emite
## `rune_selected` y se oculta. Su process_mode es ALWAYS para funcionar en pausa.

signal rune_selected(rune: RuneData)

@onready var cards_container: HBoxContainer = $Panel/VBox/Cards

var _current_runes: Array[RuneData] = []

func _ready() -> void:
	# Debe procesar entradas aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

## Muestra las runas recibidas creando una tarjeta-botón por cada una.
func show_runes(runes: Array[RuneData]) -> void:
	_current_runes = runes
	# Limpiar tarjetas anteriores.
	for child in cards_container.get_children():
		child.queue_free()
	for rune in runes:
		cards_container.add_child(_build_card(rune))
	visible = true

func _build_card(rune: RuneData) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(240, 300)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text = "%s\n\n%s" % [rune.title, rune.description]
	button.add_theme_font_size_override("font_size", 20)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.pressed.connect(_on_card_pressed.bind(rune))
	return button

func _on_card_pressed(rune: RuneData) -> void:
	visible = false
	rune_selected.emit(rune)

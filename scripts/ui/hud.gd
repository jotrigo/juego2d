extends Control
class_name HUD
## Interfaz de juego. Muestra vida, experiencia, nivel, temporizador, bajas y el
## resumen del hechizo. También gestiona la barra de vida del jefe. Solo recibe
## datos por métodos públicos; no consulta a otros nodos directamente.

@onready var health_bar: ProgressBar = $TopLeft/HealthBar
@onready var health_label: Label = $TopLeft/HealthBar/HealthLabel
@onready var exp_bar: ProgressBar = $TopLeft/ExpBar
@onready var level_label: Label = $TopLeft/LevelLabel
@onready var spell_label: Label = $TopLeft/SpellLabel

@onready var timer_label: Label = $TopCenter/TimerLabel
@onready var kills_label: Label = $TopRight/KillsLabel

@onready var boss_container: VBoxContainer = $BossBar
@onready var boss_name_label: Label = $BossBar/BossName
@onready var boss_bar: ProgressBar = $BossBar/BossHealth

var _boss: Node = null

func _ready() -> void:
	boss_container.visible = false

func update_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [int(round(current)), int(round(maximum))]

func update_experience(current: int, needed: int, level: int) -> void:
	exp_bar.max_value = needed
	exp_bar.value = current
	level_label.text = "Nivel %d   (%d / %d XP)" % [level, current, needed]

func update_timer(seconds: float) -> void:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	timer_label.text = "%02d:%02d" % [m, s]

func update_kills(kills: int) -> void:
	kills_label.text = "Bajas: %d" % kills

func update_spell_info(spell: SpellData) -> void:
	spell_label.text = "Hechizo: %s\n%s" % [spell.get_element_name(), spell.get_modifier_summary()]

# --- Barra del jefe ----------------------------------------------------------

func show_boss_bar(boss: Node) -> void:
	_boss = boss
	boss_container.visible = true
	boss_name_label.text = "◈ GOLEM ARCANO ◈"
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_boss_health_changed)
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)
	# Inicializar valores.
	if "max_health" in boss:
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.max_health

func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_died() -> void:
	boss_container.visible = false

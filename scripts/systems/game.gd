extends Node2D
class_name Game
## Escena principal. Coordina al jugador, el spawner, el sistema de niveles, la
## interfaz y el flujo de victoria/derrota. Administra el temporizador y la
## aparición del jefe a los 5 minutos. Mantiene la lógica repartida: delega el
## comportamiento concreto en los nodos especializados y solo los conecta.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const GOLEM_SCENE := preload("res://scenes/enemies/ArcaneGolem.tscn")

@export var arena_size: Vector2 = Vector2(2200, 1400)
@export var boss_time: float = 300.0   ## 5 minutos

@onready var spawner: EnemySpawner = $EnemySpawner
@onready var level_system: LevelSystem = $LevelSystem
@onready var hud: Control = $UILayer/HUD
@onready var rune_ui: Control = $UILayer/RuneSelectionUI
@onready var end_screen: Control = $UILayer/EndScreen
@onready var player_spawn: Marker2D = $PlayerSpawn

var player: Player
var arena_rect: Rect2

var elapsed: float = 0.0
var kills: int = 0
var boss_spawned: bool = false
var game_over: bool = false
var _pending_levelups: int = 0

func _ready() -> void:
	randomize()
	arena_rect = Rect2(Vector2.ZERO, arena_size)
	_spawn_player()
	_setup_spawner()
	_connect_ui()

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = player_spawn.global_position
	# Configurar límites de la cámara según la arena.
	var cam := player.get_node("Camera2D") as Camera2D
	if cam:
		cam.limit_left = int(arena_rect.position.x)
		cam.limit_top = int(arena_rect.position.y)
		cam.limit_right = int(arena_rect.end.x)
		cam.limit_bottom = int(arena_rect.end.y)
	# Conexiones del jugador.
	player.health_changed.connect(hud.update_health)
	player.experience_gained.connect(level_system.add_experience)
	player.died.connect(_on_player_died)

func _setup_spawner() -> void:
	spawner.setup(player, arena_rect)
	spawner.enemy_spawned.connect(_on_enemy_spawned)

func _connect_ui() -> void:
	level_system.experience_changed.connect(hud.update_experience)
	level_system.level_up.connect(_on_level_up)
	rune_ui.rune_selected.connect(_on_rune_selected)
	end_screen.replay_requested.connect(_on_replay)
	# Inicializar HUD del hechizo.
	hud.update_spell_info(player.spell)

func _process(delta: float) -> void:
	if game_over:
		return
	# El tiempo solo avanza mientras se juega (no en pausa por runas).
	if not get_tree().paused:
		elapsed += delta
		hud.update_timer(elapsed)
	if not boss_spawned and elapsed >= boss_time:
		_spawn_boss()

func _on_enemy_spawned(enemy: Node) -> void:
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died(pos: Vector2, exp_value: int) -> void:
	kills += 1
	hud.update_kills(kills)
	_drop_exp_orb(pos, exp_value)

func _drop_exp_orb(pos: Vector2, value: int) -> void:
	var orb := preload("res://scenes/pickups/ExperienceOrb.tscn").instantiate()
	add_child(orb)
	orb.global_position = pos
	orb.setup(value)

# --- Subida de nivel y runas -------------------------------------------------

func _on_level_up(_new_level: int) -> void:
	_pending_levelups += 1
	_try_show_rune_selection()

func _try_show_rune_selection() -> void:
	# Evita solapar dos menús si se suben varios niveles de golpe.
	if _pending_levelups <= 0 or rune_ui.visible or game_over:
		return
	var runes: Array[RuneData] = RuneDB.get_random_runes(3)
	rune_ui.show_runes(runes)
	get_tree().paused = true

func _on_rune_selected(rune: RuneData) -> void:
	rune.apply(player.spell)
	hud.update_spell_info(player.spell)
	get_tree().paused = false
	_pending_levelups -= 1
	# Si quedaban más niveles pendientes, mostrar el siguiente menú.
	if _pending_levelups > 0:
		call_deferred("_try_show_rune_selection")

# --- Jefe --------------------------------------------------------------------

func _spawn_boss() -> void:
	boss_spawned = true
	spawner.stop()
	var golem := GOLEM_SCENE.instantiate()
	add_child(golem)
	golem.global_position = _boss_spawn_position()
	golem.died.connect(_on_boss_died)
	hud.show_boss_bar(golem)

func _boss_spawn_position() -> Vector2:
	# Aparece a cierta distancia del jugador, dentro de la arena.
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	var pos: Vector2 = player.global_position + dir * 500.0
	pos.x = clamp(pos.x, arena_rect.position.x + 100.0, arena_rect.end.x - 100.0)
	pos.y = clamp(pos.y, arena_rect.position.y + 100.0, arena_rect.end.y - 100.0)
	return pos

func _on_boss_died() -> void:
	if game_over:
		return
	_end_game(true)

# --- Fin de partida ----------------------------------------------------------

func _on_player_died() -> void:
	if game_over:
		return
	_end_game(false)

func _end_game(victory: bool) -> void:
	game_over = true
	spawner.stop()
	end_screen.show_result(victory, elapsed, level_system.level, kills)

func _on_replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

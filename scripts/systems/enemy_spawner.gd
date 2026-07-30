extends Node2D
class_name EnemySpawner
## Genera slimes alrededor del jugador, fuera de la pantalla visible y sin pasarse
## del máximo activo. La dificultad escala con el tiempo: el intervalo baja y la
## cantidad por oleada sube. Deja de generar cuando aparece el jefe.

signal enemy_spawned(enemy: Node)

const SLIME_SCENE := preload("res://scenes/enemies/Slime.tscn")

@export var start_interval: float = 2.0
@export var min_interval: float = 0.5
@export var max_active: int = 60
@export var spawn_margin: float = 120.0   ## distancia extra más allá del borde de pantalla
@export var min_player_distance: float = 420.0

var _player: Node2D
var _arena_rect: Rect2
var _time: float = 0.0
var _spawn_accum: float = 0.0
var _active: bool = true

func setup(player: Node2D, arena_rect: Rect2) -> void:
	_player = player
	_arena_rect = arena_rect

func _process(delta: float) -> void:
	if not _active or _player == null or not is_instance_valid(_player):
		return
	_time += delta
	_spawn_accum += delta
	var interval := _current_interval()
	if _spawn_accum >= interval:
		_spawn_accum = 0.0
		_spawn_wave()

## El intervalo baja linealmente durante los primeros 4 minutos.
func _current_interval() -> float:
	var t: float = clamp(_time / 240.0, 0.0, 1.0)
	return lerp(start_interval, min_interval, t)

## La oleada crece de 1 a 4 enemigos con el tiempo.
func _wave_size() -> int:
	return 1 + int(_time / 75.0)

func _spawn_wave() -> void:
	var current := get_tree().get_nodes_in_group("enemies").size()
	var size := _wave_size()
	for _i in range(size):
		if current >= max_active:
			return
		_spawn_one()
		current += 1

func _spawn_one() -> void:
	var pos := _pick_spawn_position()
	var slime := SLIME_SCENE.instantiate()
	get_tree().current_scene.add_child(slime)
	slime.global_position = pos
	enemy_spawned.emit(slime)

## Elige un punto en anillo alrededor del jugador: fuera de pantalla pero dentro
## de la arena. Intenta varias veces y recorta al rectángulo de la arena.
func _pick_spawn_position() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var off_screen: float = max(viewport_size.x, viewport_size.y) * 0.5 + spawn_margin
	var radius: float = max(off_screen, min_player_distance)
	for _attempt in range(12):
		var angle := randf() * TAU
		var pos: Vector2 = _player.global_position + Vector2(cos(angle), sin(angle)) * radius
		pos.x = clamp(pos.x, _arena_rect.position.x + 40.0, _arena_rect.end.x - 40.0)
		pos.y = clamp(pos.y, _arena_rect.position.y + 40.0, _arena_rect.end.y - 40.0)
		if pos.distance_to(_player.global_position) >= min_player_distance * 0.7:
			return pos
	# Reserva: esquina opuesta si todo falla.
	return _arena_rect.position + _arena_rect.size * 0.5

## Detiene la generación (llamado al aparecer el jefe).
func stop() -> void:
	_active = false

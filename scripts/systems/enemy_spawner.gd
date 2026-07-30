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
@export var spawn_margin: float = 140.0   ## distancia horizontal extra más allá del borde de pantalla
@export var min_player_distance: float = 380.0

var _player: Node2D
var _arena_rect: Rect2
var _ground_y: float = 1250.0   ## altura de la superficie del suelo
var _time: float = 0.0
var _spawn_accum: float = 0.0
var _active: bool = true

func setup(player: Node2D, arena_rect: Rect2, ground_y: float) -> void:
	_player = player
	_arena_rect = arena_rect
	_ground_y = ground_y

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

## Genera a un costado del jugador (izquierda o derecha), fuera de la pantalla y
## justo por encima del suelo, para que caigan y caminen hacia el jugador.
func _pick_spawn_position() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var off_screen: float = viewport_size.x * 0.5 + spawn_margin
	# Lado preferente: el que quede dentro de la arena; si ambos sirven, al azar.
	var left_x := _player.global_position.x - off_screen
	var right_x := _player.global_position.x + off_screen
	var candidates: Array[float] = []
	if left_x > _arena_rect.position.x + 40.0:
		candidates.append(left_x)
	if right_x < _arena_rect.end.x - 40.0:
		candidates.append(right_x)
	var x: float
	if candidates.is_empty():
		# Muy cerca de un borde: aparecer en el lado con más espacio.
		x = right_x if _player.global_position.x < _arena_rect.get_center().x else left_x
	else:
		x = candidates[randi() % candidates.size()]
	x = clamp(x, _arena_rect.position.x + 40.0, _arena_rect.end.x - 40.0)
	# Aparece un poco por encima del suelo; la gravedad los asienta.
	return Vector2(x, _ground_y - 60.0)

## Detiene la generación (llamado al aparecer el jefe).
func stop() -> void:
	_active = false

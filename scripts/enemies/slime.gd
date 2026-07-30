extends CharacterBody2D
class_name Slime
## Enemigo básico. Persigue al jugador en línea recta, aplica una separación
## sencilla respecto a otros enemigos para no amontonarse, recibe daño de los
## proyectiles y suelta una esfera de experiencia al morir.

signal died(position: Vector2, exp_value: int)

@export var max_health: float = 20.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 10.0
@export var exp_value: int = 5
@export var separation_radius: float = 34.0
@export var separation_strength: float = 40.0
@export var gravity: float = 1400.0
@export var anim_fps: float = 8.0   ## velocidad de la animación de caminado

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite

var health: float
var _player: Node2D
var _dead: bool = false
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	# Gravedad.
	if not is_on_floor():
		velocity.y += gravity * delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		velocity.x = 0.0
		move_and_slide()
		return
	# Persecución SOLO horizontal (caminan a la altura del suelo).
	var dir_x := signf(_player.global_position.x - global_position.x)
	# Separación horizontal para no amontonarse.
	var sep_x := _separation_x()
	velocity.x = dir_x * move_speed + sep_x
	move_and_slide()
	_animate(velocity)

## Cicla los 4 frames del spritesheet y voltea el sprite según la dirección.
func _animate(vel: Vector2) -> void:
	_anim_time += get_physics_process_delta_time() * anim_fps
	sprite.frame = int(_anim_time) % sprite.hframes
	if absf(vel.x) > 1.0:
		sprite.flip_h = vel.x < 0.0

## Repulsión horizontal respecto a enemigos cercanos, para no apilarse.
func _separation_x() -> float:
	var result := 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		var dx: float = global_position.x - e.global_position.x
		var dist := absf(dx)
		if dist < separation_radius:
			var push := (1.0 - dist / separation_radius)
			result += (signf(dx) if dx != 0.0 else 1.0) * push
	return result * separation_strength

func get_contact_damage() -> float:
	return contact_damage

## Recibe daño de proyectiles/explosiones.
func take_damage(amount: float) -> void:
	if _dead:
		return
	health -= amount
	_flash()
	if health <= 0.0:
		_die()

func _flash() -> void:
	var tween := create_tween()
	visual.modulate = Color(2.0, 2.0, 2.0)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.15)

func _die() -> void:
	if _dead:
		return
	_dead = true
	died.emit(global_position, exp_value)
	queue_free()

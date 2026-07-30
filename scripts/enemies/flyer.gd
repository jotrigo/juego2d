extends CharacterBody2D
class_name Flyer
## Enemigo volador. A diferencia del slime, ignora la gravedad y persigue al
## jugador libremente por el aire (movimiento 2D), con un leve balanceo. Al morir
## reproduce una animación de muerte de 8 frames antes de desaparecer.

signal died(position: Vector2, exp_value: int)

@export var max_health: float = 14.0
@export var move_speed: float = 130.0
@export var contact_damage: float = 8.0
@export var exp_value: int = 6
@export var separation_radius: float = 40.0
@export var separation_strength: float = 60.0
@export var bob_amplitude: float = 40.0    ## oscilación vertical del vuelo
@export var bob_frequency: float = 3.0
@export var anim_fps: float = 10.0
@export var death_fps: float = 12.0

const TEX_FLY := preload("res://assets/sprites/flyer.png")
const TEX_DEATH := preload("res://assets/sprites/flyer_death.png")
const FLY_FRAMES := 4
const DEATH_FRAMES := 8

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

var health: float
var _player: Node2D
var _dead: bool = false
var _dying: bool = false     # true mientras corre la animación de muerte
var _anim_time: float = 0.0
var _bob_time: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_player = get_tree().get_first_node_in_group("player")
	_bob_time = randf() * TAU   # desfasar el balanceo entre voladores

func _physics_process(delta: float) -> void:
	if _dying:
		_animate_death(delta)
		return
	if _dead:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	# Persecución 2D directa hacia el jugador + separación entre voladores.
	var to_player := (_player.global_position - global_position).normalized()
	var sep := _separation_vector()
	velocity = to_player * move_speed + sep
	# Balanceo vertical suave para dar sensación de vuelo.
	_bob_time += delta * bob_frequency
	velocity.y += sin(_bob_time) * bob_amplitude
	move_and_slide()
	_animate_fly(delta, velocity)

func _animate_fly(delta: float, vel: Vector2) -> void:
	_anim_time += delta * anim_fps
	sprite.frame = int(_anim_time) % FLY_FRAMES
	if absf(vel.x) > 1.0:
		sprite.flip_h = vel.x < 0.0

## Repulsión respecto a otros enemigos cercanos para no apilarse.
func _separation_vector() -> Vector2:
	var result := Vector2.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		var diff: Vector2 = global_position - e.global_position
		var d := diff.length()
		if d > 0.0 and d < separation_radius:
			result += diff.normalized() * (1.0 - d / separation_radius)
	return result * separation_strength

func get_contact_damage() -> float:
	return contact_damage

func take_damage(amount: float) -> void:
	if _dead or _dying:
		return
	health -= amount
	_flash()
	if health <= 0.0:
		_start_death()

func _flash() -> void:
	var tween := create_tween()
	visual.modulate = Color(2.0, 2.0, 2.0)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.15)

## Comienza la animación de muerte: notifica al juego (exp/bajas) de inmediato,
## deja de moverse y de dañar, y cambia al spritesheet de muerte.
func _start_death() -> void:
	if _dying or _dead:
		return
	_dying = true
	velocity = Vector2.ZERO
	# Deja de contar como enemigo activo (no daña ni recibe más impactos).
	remove_from_group("enemies")
	collision.set_deferred("disabled", true)
	visual.modulate = Color.WHITE
	sprite.texture = TEX_DEATH
	sprite.hframes = DEATH_FRAMES
	sprite.frame = 0
	_anim_time = 0.0
	died.emit(global_position, exp_value)

## Avanza la animación de muerte una sola vez y libera al terminar.
func _animate_death(delta: float) -> void:
	_anim_time += delta * death_fps
	var f := int(_anim_time)
	if f >= DEATH_FRAMES:
		_dead = true
		queue_free()
		return
	sprite.frame = f

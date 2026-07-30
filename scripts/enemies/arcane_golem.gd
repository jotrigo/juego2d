extends CharacterBody2D
class_name ArcaneGolem
## Jefe del nivel. Persigue al jugador y, periódicamente, realiza un ataque de
## onda expansiva: primero telegrafía el área en el suelo y, tras una espera,
## genera la onda que daña al jugador si sigue dentro. Al morir termina el nivel.

signal died
signal health_changed(current: float, maximum: float)

@export var max_health: float = 500.0
@export var move_speed: float = 60.0
@export var contact_damage: float = 20.0
@export var wave_radius: float = 180.0
@export var wave_damage: float = 25.0
@export var attack_cooldown: float = 4.0
@export var telegraph_time: float = 1.1

@onready var visual: Node2D = $Visual
@onready var attack_timer: Timer = $AttackTimer

const WAVE_SCENE := preload("res://scenes/enemies/GolemWave.tscn")

var health: float
var _player: Node2D
var _dead: bool = false
var _attacking: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	health = max_health
	_player = get_tree().get_first_node_in_group("player")
	health_changed.emit(health, max_health)
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_start_attack)
	attack_timer.start()
	_spawn_effect()

func _physics_process(_delta: float) -> void:
	if _dead:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	if _attacking:
		velocity = Vector2.ZERO
	else:
		var dir := (_player.global_position - global_position).normalized()
		velocity = dir * move_speed
	move_and_slide()

func get_contact_damage() -> float:
	return contact_damage

func take_damage(amount: float) -> void:
	if _dead:
		return
	health -= amount
	health_changed.emit(max(health, 0.0), max_health)
	_flash()
	if health <= 0.0:
		_die()

func _flash() -> void:
	var tween := create_tween()
	visual.modulate = Color(2.0, 1.4, 1.4)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.15)

## Inicia la secuencia de ataque: telegrafía y luego lanza la onda.
func _start_attack() -> void:
	if _dead:
		return
	_attacking = true
	var wave := WAVE_SCENE.instantiate()
	get_tree().current_scene.add_child(wave)
	wave.global_position = global_position
	wave.setup(wave_radius, wave_damage, telegraph_time)
	# Reanudar movimiento cuando termina el telegrafiado.
	await get_tree().create_timer(telegraph_time).timeout
	_attacking = false

func _spawn_effect() -> void:
	scale = Vector2.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _die() -> void:
	if _dead:
		return
	_dead = true
	died.emit()
	queue_free()

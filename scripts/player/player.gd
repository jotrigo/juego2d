extends CharacterBody2D
class_name Player
## Mago jugable. Responsable del movimiento, la vida, la invulnerabilidad y la
## recepción de daño por contacto. El disparo lo gestiona el nodo hijo "Shooter".
## El estado del hechizo (SpellData) vive aquí y es compartido con el Shooter.

signal health_changed(current: float, maximum: float)
signal died
signal experience_gained(amount: int)   # reenvía la exp recogida al sistema de nivel

@export var move_speed: float = 260.0
@export var max_health: float = 100.0
@export var invuln_time: float = 0.5
@export var anim_fps: float = 10.0
# Física de plataformas.
@export var gravity: float = 1400.0
@export var jump_velocity: float = 560.0   ## impulso de salto (magnitud)
@export var air_control: float = 0.85      ## factor de control horizontal en el aire

# Texturas por estado (spritesheets horizontales de 16x24).
const TEX_IDLE := preload("res://assets/sprites/player_idle.png")
const TEX_RUN := preload("res://assets/sprites/player_run.png")
const TEX_SHOOT := preload("res://assets/sprites/player_shoot.png")
const IDLE_FRAMES := 4
const RUN_FRAMES := 4
const SHOOT_FRAMES := 5

## Estados de animación, en orden de prioridad ascendente.
enum AnimState { IDLE, MOVING, SHOOTING }

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var muzzle: Marker2D = $Muzzle
@onready var shooter: Node = $Shooter

var health: float
var _invulnerable: bool = false
var _dead: bool = false
var _anim_state: AnimState = AnimState.IDLE
var _anim_time: float = 0.0
var _shoot_timer: float = 0.0   # cuánto tiempo más mostrar la animación de disparo

# Datos actuales del hechizo. Se crean a partir de un SpellData por defecto y las
# runas los modifican in situ. El Shooter lee esta misma instancia.
var spell: SpellData

func _ready() -> void:
	add_to_group("player")
	spell = SpellData.new()  # valores por defecto = hechizo inicial de fuego
	health = max_health
	health_changed.emit(health, max_health)
	if shooter and shooter.has_method("set_spell"):
		shooter.set_spell(spell)
	# Mostrar la animación de disparo cuando el shooter lanza proyectiles.
	if shooter and shooter.has_signal("fired"):
		shooter.fired.connect(_on_shooter_fired)
	_apply_anim_textures()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_handle_movement(delta)
	_check_contact_damage()
	_update_animation(delta)

func _handle_movement(delta: float) -> void:
	# Gravedad: se acumula mientras no estemos en el suelo.
	if not is_on_floor():
		velocity.y += gravity * delta
	# Movimiento horizontal (con algo menos de control en el aire).
	var dir := Input.get_axis("move_left", "move_right")
	var control := 1.0 if is_on_floor() else air_control
	velocity.x = dir * move_speed * control
	# Salto: solo desde el suelo.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_velocity
	move_and_slide()
	# El mago mira hacia el mouse volteando el sprite.
	var to_mouse := get_global_mouse_position() - global_position
	if absf(to_mouse.x) > 4.0:
		sprite.flip_h = to_mouse.x < 0.0

# --- Animación por estado -----------------------------------------------------

func _on_shooter_fired() -> void:
	# Reinicia el temporizador para que se vea toda la animación de disparo.
	_shoot_timer = float(SHOOT_FRAMES) / anim_fps

func _update_animation(delta: float) -> void:
	if _shoot_timer > 0.0:
		_shoot_timer -= delta
	# Prioridad: disparo > movimiento > quieto.
	var new_state: AnimState
	if _shoot_timer > 0.0:
		new_state = AnimState.SHOOTING
	elif absf(velocity.x) > 5.0:
		new_state = AnimState.MOVING
	else:
		new_state = AnimState.IDLE
	if new_state != _anim_state:
		_anim_state = new_state
		_anim_time = 0.0
		_apply_anim_textures()
	# Avanzar el frame actual dentro del spritesheet del estado.
	_anim_time += delta * anim_fps
	sprite.frame = int(_anim_time) % maxi(sprite.hframes, 1)

## Ajusta la textura y la cantidad de frames según el estado actual.
func _apply_anim_textures() -> void:
	match _anim_state:
		AnimState.SHOOTING:
			sprite.texture = TEX_SHOOT
			sprite.hframes = SHOOT_FRAMES
		AnimState.MOVING:
			sprite.texture = TEX_RUN
			sprite.hframes = RUN_FRAMES
		_:
			sprite.texture = TEX_IDLE
			sprite.hframes = IDLE_FRAMES

## Daño por contacto: si algún enemigo solapa el hurtbox y no somos invulnerables.
func _check_contact_damage() -> void:
	if _invulnerable or _dead:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("get_contact_damage"):
			take_damage(body.get_contact_damage())
			break

## Aplica daño al jugador y arranca la invulnerabilidad temporal.
func take_damage(amount: float) -> void:
	if _invulnerable or _dead:
		return
	health = max(health - amount, 0.0)
	health_changed.emit(health, max_health)
	_flash_damage()
	if health <= 0.0:
		_die()
	else:
		_start_invuln()

func _start_invuln() -> void:
	_invulnerable = true
	var t := get_tree().create_timer(invuln_time)
	# Parpadeo mientras dura la invulnerabilidad.
	var blink := create_tween().set_loops(int(invuln_time / 0.1))
	blink.tween_property(visual, "modulate:a", 0.3, 0.05)
	blink.tween_property(visual, "modulate:a", 1.0, 0.05)
	await t.timeout
	_invulnerable = false
	visual.modulate.a = 1.0

func _flash_damage() -> void:
	var tween := create_tween()
	visual.modulate = Color(1.6, 0.4, 0.4)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.25)

func _die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	died.emit()

## Llamado por las esferas de experiencia al ser recogidas.
func collect_experience(amount: int) -> void:
	experience_gained.emit(amount)

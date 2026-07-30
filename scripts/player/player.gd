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

@onready var visual: Node2D = $Visual
@onready var hurtbox: Area2D = $Hurtbox
@onready var muzzle: Marker2D = $Muzzle
@onready var shooter: Node = $Shooter

var health: float
var _invulnerable: bool = false
var _dead: bool = false

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

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_handle_movement(delta)
	_check_contact_damage()

func _handle_movement(_delta: float) -> void:
	# Vector de entrada normalizado => diagonal no es más rápida.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	move_and_slide()
	# Orientar visualmente el mago hacia el mouse.
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 4.0:
		visual.rotation = to_mouse.angle()

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

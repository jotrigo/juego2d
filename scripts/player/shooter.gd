extends Node
class_name Shooter
## Sistema de disparo del jugador. Lee el SpellData compartido, respeta la
## cadencia (cooldown) y genera los proyectiles distribuidos en abanico hacia
## el mouse. Se mantiene separado del movimiento para respetar la modularidad.

signal fired   ## se emite cada vez que se lanza una tanda de proyectiles

const PROJECTILE_SCENE := preload("res://scenes/spells/MagicProjectile.tscn")

var spell: SpellData
var _cooldown_left: float = 0.0

@onready var player: CharacterBody2D = get_parent()
@onready var muzzle: Marker2D = get_parent().get_node("Muzzle")

func set_spell(s: SpellData) -> void:
	spell = s

func _process(delta: float) -> void:
	if spell == null:
		return
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
	# Disparo continuo mientras se mantiene pulsado, respetando la cadencia.
	if Input.is_action_pressed("cast_spell") and _cooldown_left <= 0.0:
		_fire()
		_cooldown_left = spell.cooldown

func _fire() -> void:
	var origin := muzzle.global_position
	var base_dir := (player.get_global_mouse_position() - origin).normalized()
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.RIGHT
	var count: int = max(spell.projectile_count, 1)
	# Distribuir los proyectiles en un abanico centrado en base_dir.
	var total_spread := deg_to_rad(spell.spread_angle)
	for i in range(count):
		var offset := 0.0
		if count > 1:
			offset = -total_spread * 0.5 + total_spread * float(i) / float(count - 1)
		var dir := base_dir.rotated(offset)
		_spawn_projectile(origin, dir)
	fired.emit()

func _spawn_projectile(origin: Vector2, dir: Vector2) -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	proj.setup(spell, dir)
	# Los proyectiles cuelgan de la escena actual, no del jugador, para que su
	# posición sea independiente del movimiento del mago.
	get_tree().current_scene.add_child(proj)
	proj.global_position = origin

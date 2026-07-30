extends Area2D
class_name ExperienceOrb
## Esfera de experiencia. Permanece en el suelo hasta que el jugador entra en su
## radio de atracción; entonces vuela hacia él y, al alcanzarlo, otorga la
## experiencia y desaparece. Detecta al jugador por su capa de colisión.

@export var exp_value: int = 5
@export var attract_radius: float = 130.0
@export var pickup_radius: float = 22.0
@export var attract_speed: float = 520.0

@onready var visual: Polygon2D = $Visual

var _player: Node2D
var _collected: bool = false

func setup(value: int) -> void:
	exp_value = value

func _ready() -> void:
	add_to_group("exp_orbs")
	_player = get_tree().get_first_node_in_group("player")
	# Pequeña animación de aparición.
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	if _collected:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= pickup_radius:
		_collect()
	elif dist <= attract_radius:
		var dir := (_player.global_position - global_position).normalized()
		# La atracción se acelera al acercarse.
		var speed := attract_speed * (1.0 - dist / attract_radius) + 90.0
		global_position += dir * speed * delta

func _collect() -> void:
	if _collected:
		return
	_collected = true
	if _player.has_method("collect_experience"):
		_player.collect_experience(exp_value)
	queue_free()

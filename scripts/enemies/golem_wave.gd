extends Node2D
class_name GolemWave
## Onda expansiva del jefe. Primero muestra un aviso rojo en el suelo (telegraph)
## y, al cabo de `telegraph_time`, expande la onda y daña al jugador una sola vez
## si se encuentra dentro del radio. No daña a los enemigos.

@onready var telegraph: Polygon2D = $Telegraph
@onready var wave: Polygon2D = $Wave

var radius: float = 180.0
var damage: float = 25.0
var telegraph_time: float = 1.1

## Configura y lanza la onda. Debe llamarse DESPUÉS de fijar la posición global
## (y tras add_child, para que los @onready estén listos).
func setup(p_radius: float, p_damage: float, p_telegraph: float) -> void:
	radius = p_radius
	damage = p_damage
	telegraph_time = p_telegraph
	_build_circle(telegraph, radius)
	_build_circle(wave, radius)
	telegraph.color = Color(1.0, 0.2, 0.2, 0.25)
	wave.color = Color(0.8, 0.4, 1.0, 0.0)
	wave.scale = Vector2.ZERO
	_run()

func _build_circle(poly: Polygon2D, r: float) -> void:
	var pts := PackedVector2Array()
	var segments := 28
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = pts

func _run() -> void:
	# Fase de aviso: el círculo rojo late.
	var tel := create_tween().set_loops(2)
	tel.tween_property(telegraph, "color:a", 0.5, telegraph_time * 0.25)
	tel.tween_property(telegraph, "color:a", 0.2, telegraph_time * 0.25)
	await get_tree().create_timer(telegraph_time).timeout
	telegraph.visible = false
	_apply_damage()
	# Fase de onda: expansión y desvanecimiento.
	wave.color.a = 0.6
	var tween := create_tween()
	tween.tween_property(wave, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(wave, "color:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

func _apply_damage() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if player.global_position.distance_to(global_position) <= radius and player.has_method("take_damage"):
			player.take_damage(damage)

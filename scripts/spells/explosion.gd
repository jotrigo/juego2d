extends Node2D
class_name Explosion
## Explosión de área: al aparecer daña una sola vez a todos los enemigos dentro
## del radio y reproduce una animación simple de expansión y desvanecimiento.
## No daña al jugador (solo consulta el grupo "enemies").

@onready var visual: Polygon2D = $Visual

var radius: float = 70.0
var damage: float = 6.0
var color: Color = Color(1.0, 0.6, 0.2)

## Configura y dispara la explosión. Debe llamarse DESPUÉS de fijar la posición
## global del nodo (y tras add_child, para que los @onready estén listos).
func setup(p_radius: float, p_damage: float, p_color: Color) -> void:
	radius = p_radius
	damage = p_damage
	color = p_color
	_apply_damage()
	_build_visual()
	_animate()

func _apply_damage() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_to(global_position) <= radius and e.has_method("take_damage"):
			e.take_damage(damage)

func _build_visual() -> void:
	var pts := PackedVector2Array()
	var segments := 20
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	visual.polygon = pts
	visual.color = Color(color.r, color.g, color.b, 0.55)

func _animate() -> void:
	scale = Vector2.ONE * 0.2
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.28)
	tween.tween_callback(queue_free)

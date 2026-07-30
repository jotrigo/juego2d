extends Area2D
class_name MagicProjectile
## Proyectil mágico principal. Es un Area2D que avanza en una dirección y detecta
## enemigos (para dañarlos) y paredes (para rebotar o desaparecer).
## Todos sus parámetros provienen de una copia de SpellData tomada al disparar,
## de modo que las runas obtenidas después no alteran proyectiles ya en vuelo.

@onready var visual: Polygon2D = $Visual
@onready var trail: Line2D = $Trail
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

const EXPLOSION_SCENE := preload("res://scenes/spells/Explosion.tscn")

var direction: Vector2 = Vector2.RIGHT
var speed: float = 650.0
var damage: float = 10.0
var penetration: int = 0
var bounce_count: int = 0
var explosion_radius: float = 0.0
var explosion_damage_factor: float = 0.6
var homing_strength: float = 0.0
var color: Color = Color(1.0, 0.55, 0.15)
var lifetime: float = 2.0

var _pierced: int = 0
var _bounced: int = 0
var _dead: bool = false
var _trail_points: Array[Vector2] = []  # posiciones globales recientes
# Enemigos ya golpeados por ESTE proyectil, para no dañarlos dos veces.
var _hit_enemies: Array[int] = []

## Configura el proyectil a partir de un SpellData y una dirección ya calculada.
func setup(spell: SpellData, dir: Vector2) -> void:
	direction = dir.normalized()
	speed = spell.projectile_speed
	damage = spell.damage
	penetration = spell.penetration
	bounce_count = spell.bounce_count
	explosion_radius = spell.explosion_radius
	explosion_damage_factor = spell.explosion_damage_factor
	homing_strength = spell.homing_strength
	color = spell.get_element_color()
	lifetime = spell.lifetime
	scale = Vector2.ONE * spell.projectile_scale

func _ready() -> void:
	visual.color = color
	trail.default_color = Color(color.r, color.g, color.b, 0.5)
	lifetime_timer.wait_time = lifetime
	lifetime_timer.start()
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	# Detección de impactos.
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	# Seguimiento gradual hacia el enemigo más cercano.
	if homing_strength > 0.0:
		var target := _find_nearest_enemy()
		if target != null:
			var desired := (target.global_position - global_position).normalized()
			direction = direction.lerp(desired, clamp(homing_strength * delta, 0.0, 1.0)).normalized()
	global_position += direction * speed * delta
	rotation = direction.angle()
	_update_trail()

## Estela sencilla: mantiene las últimas posiciones globales y las dibuja en
## espacio local. Se compensa la rotación del nodo para que la línea sea recta.
func _update_trail() -> void:
	_trail_points.append(global_position)
	if _trail_points.size() > 8:
		_trail_points.remove_at(0)
	trail.clear_points()
	for p in _trail_points:
		trail.add_point(to_local(p))

func _on_body_entered(body: Node) -> void:
	if _dead:
		return
	# ¿Es una pared? (StaticBody2D en la capa "walls").
	if body.is_in_group("walls"):
		_handle_wall_bounce()
		return
	# ¿Es un enemigo dañable?
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var id := body.get_instance_id()
		if _hit_enemies.has(id):
			return
		_hit_enemies.append(id)
		body.take_damage(damage)
		_explode_if_needed()
		if _pierced >= penetration:
			_die()
		else:
			_pierced += 1

## Rebote simple: invierte la componente adecuada según la posición del muro.
func _handle_wall_bounce() -> void:
	if _bounced < bounce_count:
		_bounced += 1
		# Aproximación: reflejar según la dirección predominante del movimiento.
		# Detectamos con un pequeño raycast implícito comparando posiciones.
		var space := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(
			global_position - direction * 20.0,
			global_position + direction * 20.0)
		query.collision_mask = 8 # walls
		var hit := space.intersect_ray(query)
		if hit.has("normal"):
			direction = direction.bounce(hit.normal).normalized()
		else:
			direction = -direction
		global_position += direction * 8.0
	else:
		_explode_if_needed()
		_die()

func _explode_if_needed() -> void:
	if explosion_radius <= 0.0:
		return
	var boom := EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.add_child(boom)
	boom.global_position = global_position
	boom.setup(explosion_radius, damage * explosion_damage_factor, color)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest

func _on_lifetime_timeout() -> void:
	_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	queue_free()

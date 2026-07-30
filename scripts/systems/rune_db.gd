extends Node
## Autoload "RuneDB": catálogo central de runas disponibles.
## Registrar una runa nueva es tan simple como añadir una entrada en _build_runes().
## Cada runa modifica el SpellData del jugador mediante una función lambda.

var _runes: Array[RuneData] = []

func _ready() -> void:
	_build_runes()

func _make(id: StringName, title: String, desc: String, fn: Callable, weight: float = 1.0) -> RuneData:
	var r := RuneData.new()
	r.id = id
	r.title = title
	r.description = desc
	r.apply_func = fn
	r.weight = weight
	return r

func _build_runes() -> void:
	_runes.clear()

	# Poder: +25% de daño.
	_runes.append(_make(&"power", "Poder", "+25% de daño del hechizo.",
		func(s: SpellData) -> void:
			s.damage *= 1.25))

	# Rapidez arcana: -15% de cooldown (con mínimo).
	_runes.append(_make(&"haste", "Rapidez arcana", "-15% de tiempo de recarga.",
		func(s: SpellData) -> void:
			s.cooldown = max(s.cooldown * 0.85, SpellData.MIN_COOLDOWN)))

	# Proyectil doble: +1 proyectil y algo más de dispersión.
	_runes.append(_make(&"multishot", "Proyectil doble", "+1 proyectil por disparo.",
		func(s: SpellData) -> void:
			s.projectile_count += 1
			s.spread_angle = min(s.spread_angle + 8.0, 70.0)))

	# Penetración: atraviesa un enemigo más.
	_runes.append(_make(&"pierce", "Penetración", "Los proyectiles atraviesan 1 enemigo más.",
		func(s: SpellData) -> void:
			s.penetration += 1))

	# Explosión: impacto en área.
	_runes.append(_make(&"explosion", "Explosión", "Los impactos generan una explosión en área.",
		func(s: SpellData) -> void:
			if s.explosion_radius <= 0.0:
				s.explosion_radius = 70.0
			else:
				s.explosion_radius += 25.0))

	# Persecución: seguimiento gradual al enemigo más cercano.
	_runes.append(_make(&"homing", "Persecución", "Los proyectiles se curvan hacia el enemigo más cercano.",
		func(s: SpellData) -> void:
			s.homing_strength += 3.0))

	# Rebote: rebota una vez más contra paredes.
	_runes.append(_make(&"bounce", "Rebote", "Los proyectiles rebotan 1 vez más en las paredes.",
		func(s: SpellData) -> void:
			s.bounce_count += 1))

	# Crecimiento arcano: proyectil más grande y algo más de daño.
	_runes.append(_make(&"growth", "Crecimiento arcano", "+tamaño del proyectil y +10% de daño.",
		func(s: SpellData) -> void:
			s.projectile_scale += 0.35
			s.damage *= 1.10))

## Devuelve `count` runas distintas elegidas al azar según su peso.
func get_random_runes(count: int) -> Array[RuneData]:
	var pool: Array[RuneData] = _runes.duplicate()
	var result: Array[RuneData] = []
	count = min(count, pool.size())
	for _i in range(count):
		var total: float = 0.0
		for r in pool:
			total += r.weight
		var roll: float = randf() * total
		var acc: float = 0.0
		var chosen_index: int = 0
		for j in range(pool.size()):
			acc += pool[j].weight
			if roll <= acc:
				chosen_index = j
				break
		result.append(pool[chosen_index])
		pool.remove_at(chosen_index)
	return result

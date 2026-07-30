extends Node
## Banco de pruebas headless. NO forma parte del juego: se usa temporalmente como
## escena principal para validar la lógica sin depender del mouse ni del teclado.
## Ejecuta comprobaciones deterministas e imprime PASS/FAIL, luego cierra.

var _passed := 0
var _failed := 0

func _ready() -> void:
	await get_tree().physics_frame
	print("=== ArcaneMage self-test ===")
	_test_spell_defaults()
	_test_runes()
	_test_level_system()
	await _test_projectile_damage_and_pierce()
	await _test_explosion()
	await _test_golem_wave()
	print("=== Resultado: %d PASS, %d FAIL ===" % [_passed, _failed])
	if _failed > 0:
		print("SELFTEST_FAILED")
	else:
		print("SELFTEST_OK")
	get_tree().quit()

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", label)
	else:
		_failed += 1
		print("  [FAIL] ", label)

func _test_spell_defaults() -> void:
	var s := SpellData.new()
	_check(s.damage == 10.0, "daño inicial 10")
	_check(s.projectile_speed == 650.0, "velocidad inicial 650")
	_check(is_equal_approx(s.cooldown, 0.4), "cooldown inicial 0.4")
	_check(s.projectile_count == 1, "1 proyectil inicial")
	_check(s.penetration == 0 and s.bounce_count == 0 and s.explosion_radius == 0.0, "sin modificadores iniciales")

func _test_runes() -> void:
	# Poder: +25% daño.
	var s := SpellData.new()
	_apply_rune(&"power", s)
	_check(is_equal_approx(s.damage, 12.5), "runa Poder +25% daño")
	# Rapidez arcana: -15% cooldown.
	s = SpellData.new()
	_apply_rune(&"haste", s)
	_check(is_equal_approx(s.cooldown, 0.34), "runa Rapidez -15% cooldown")
	# Multishot.
	s = SpellData.new()
	_apply_rune(&"multishot", s)
	_check(s.projectile_count == 2, "runa Proyectil doble +1")
	# Penetración.
	s = SpellData.new()
	_apply_rune(&"pierce", s)
	_check(s.penetration == 1, "runa Penetración +1")
	# Explosión.
	s = SpellData.new()
	_apply_rune(&"explosion", s)
	_check(s.explosion_radius > 0.0, "runa Explosión activa radio")
	# Homing.
	s = SpellData.new()
	_apply_rune(&"homing", s)
	_check(s.homing_strength > 0.0, "runa Persecución activa homing")
	# Rebote.
	s = SpellData.new()
	_apply_rune(&"bounce", s)
	_check(s.bounce_count == 1, "runa Rebote +1")
	# Crecimiento.
	s = SpellData.new()
	_apply_rune(&"growth", s)
	_check(s.projectile_scale > 1.0 and s.damage > 10.0, "runa Crecimiento +tamaño +daño")
	# Selección aleatoria devuelve 3 distintas.
	var chosen: Array[RuneData] = RuneDB.get_random_runes(3)
	var ids := {}
	for r in chosen:
		ids[r.id] = true
	_check(chosen.size() == 3 and ids.size() == 3, "selección de 3 runas distintas")

func _apply_rune(id: StringName, s: SpellData) -> void:
	for r in RuneDB.get_random_runes(99):
		if r.id == id:
			r.apply(s)
			return
	push_error("runa no encontrada: %s" % id)

func _test_level_system() -> void:
	var ls := LevelSystem.new()
	add_child(ls)
	var leveled := [0]
	ls.level_up.connect(func(_l: int) -> void: leveled[0] += 1)
	_check(ls.experience_needed() == 35, "exp necesaria nivel 1 = 35")
	ls.add_experience(35)
	_check(ls.level == 2 and leveled[0] == 1, "sube a nivel 2 con 35 exp")
	ls.add_experience(1000)
	_check(ls.level > 2, "sube varios niveles con mucha exp")
	ls.queue_free()

func _make_slime_at(pos: Vector2) -> Node:
	var slime: Node = load("res://scenes/enemies/Slime.tscn").instantiate()
	add_child(slime)
	slime.global_position = pos
	# Congelamos su física (gravedad/persecución) para pruebas deterministas.
	slime.set_physics_process(false)
	return slime

func _test_projectile_damage_and_pierce() -> void:
	# Proyectil sin penetración: mata a un slime (daño 10 x2 impactos? no, muere en 2).
	var slime := _make_slime_at(Vector2(400, 0))
	var initial_hp: float = slime.health
	slime.take_damage(10.0)
	_check(slime.health == initial_hp - 10.0, "slime recibe 10 de daño")
	slime.take_damage(10.0)
	await get_tree().physics_frame
	_check(not is_instance_valid(slime), "slime muere a 0 de vida")

	# Penetración: un proyectil con penetration=1 debe golpear 2 slimes distintos.
	var s := SpellData.new()
	s.penetration = 1
	s.damage = 5.0
	var a := _make_slime_at(Vector2(200, 0))
	var b := _make_slime_at(Vector2(260, 0))
	var proj: Node = load("res://scenes/spells/MagicProjectile.tscn").instantiate()
	proj.setup(s, Vector2.RIGHT)
	add_child(proj)
	proj.global_position = Vector2(120, 0)
	# Avanzar varios frames de física para que atraviese ambos.
	for i in range(40):
		await get_tree().physics_frame
	_check(a.health < a.max_health and b.health < b.max_health, "penetración golpea 2 enemigos")
	if is_instance_valid(a): a.queue_free()
	if is_instance_valid(b): b.queue_free()
	if is_instance_valid(proj): proj.queue_free()

func _test_explosion() -> void:
	var a := _make_slime_at(Vector2(1000, 1000))
	var b := _make_slime_at(Vector2(1040, 1000))
	var boom: Node = load("res://scenes/spells/Explosion.tscn").instantiate()
	add_child(boom)
	boom.global_position = Vector2(1000, 1000)
	boom.setup(90.0, 8.0, Color.ORANGE)
	await get_tree().physics_frame
	_check(a.health < a.max_health and b.health < b.max_health, "explosión daña enemigos en radio")
	if is_instance_valid(a): a.queue_free()
	if is_instance_valid(b): b.queue_free()

func _test_golem_wave() -> void:
	# La onda debe dañar al jugador si está dentro del radio.
	var player: Node = load("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	player.global_position = Vector2(1500, 500)
	player.set_physics_process(false)  # congelar gravedad para el test
	await get_tree().physics_frame
	var hp_before: float = player.health
	var wave: Node = load("res://scenes/enemies/GolemWave.tscn").instantiate()
	add_child(wave)
	wave.global_position = Vector2(1500, 500)
	wave.setup(180.0, 25.0, 0.05)  # telegraph corto para el test
	# Esperar a que pase el telegraph y aplique daño.
	for i in range(20):
		await get_tree().physics_frame
	_check(player.health < hp_before, "onda del jefe daña al jugador en el área")
	if is_instance_valid(player): player.queue_free()
	if is_instance_valid(wave): wave.queue_free()

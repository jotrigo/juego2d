extends Node
## Prueba de integración headless sobre la escena real Game.tscn. Conduce el flujo
## llamando a los métodos públicos del Game (sin depender de mouse/teclado) y
## verifica el cableado completo: spawn, niveles+runas, jefe, victoria y derrota.

const GAME := preload("res://scenes/main/Game.tscn")

var _passed := 0
var _failed := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().physics_frame
	print("=== ArcaneMage integration-test ===")
	await _test_flow_victory()
	await _test_flow_defeat()
	print("=== Integración: %d PASS, %d FAIL ===" % [_passed, _failed])
	print("SELFTEST_OK" if _failed == 0 else "SELFTEST_FAILED")
	get_tree().quit()

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", label)
	else:
		_failed += 1
		print("  [FAIL] ", label)

func _wait(frames: int) -> void:
	for i in range(frames):
		await get_tree().physics_frame

func _make_game() -> Node:
	var game: Node = GAME.instantiate()
	add_child(game)
	get_tree().current_scene = game
	return game

func _test_flow_victory() -> void:
	var game: Node = _make_game()
	await _wait(3)
	_check(is_instance_valid(game.player), "jugador instanciado")
	var cam := game.player.get_node("Camera2D") as Camera2D
	_check(cam.limit_right == 2200 and cam.limit_bottom == 1400, "límites de cámara según arena")

	# Esperar a que el spawner genere enemigos (intervalo inicial 2s).
	await _wait(150)
	_check(get_tree().get_nodes_in_group("enemies").size() > 0, "el spawner genera enemigos")

	# Subida de nivel: debe pausar y mostrar la selección de runas.
	var dmg_before: float = game.player.spell.damage
	game.level_system.add_experience(game.level_system.experience_needed())
	await get_tree().physics_frame
	_check(game.rune_ui.visible and get_tree().paused, "level up pausa y muestra runas")

	# Elegir la primera runa disponible => aplica y reanuda.
	var runes: Array[RuneData] = RuneDB.get_random_runes(1)
	game._on_rune_selected(runes[0])
	await get_tree().physics_frame
	_check(not get_tree().paused, "elegir runa reanuda el juego")

	# Aparición del jefe (forzada) => detiene spawner y muestra barra.
	game._spawn_boss()
	await _wait(3)
	var boss := get_tree().get_first_node_in_group("boss")
	_check(boss != null, "el jefe aparece")
	_check(game.hud.boss_container.visible, "se muestra la barra del jefe")

	# Matar al jefe => victoria.
	boss.take_damage(9999.0)
	await _wait(3)
	_check(game.game_over and game.end_screen.visible, "derrotar al jefe => pantalla de victoria")
	_check(game.end_screen.title_label.text.contains("COMPLETADO"), "título de victoria correcto")

	# Limpieza.
	get_tree().paused = false
	game.queue_free()
	await _wait(2)

func _test_flow_defeat() -> void:
	var game: Node = _make_game()
	await _wait(3)
	# Matar al jugador => derrota.
	game.player.take_damage(9999.0)
	await _wait(3)
	_check(game.game_over and game.end_screen.visible, "morir => pantalla de derrota")
	_check(game.end_screen.title_label.text.contains("DERROTADO"), "título de derrota correcto")
	get_tree().paused = false
	game.queue_free()
	await _wait(2)

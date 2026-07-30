extends Node
class_name LevelSystem
## Lleva la experiencia y el nivel del jugador. Cuando se alcanza el umbral,
## emite `level_up` para que el juego pause y muestre la selección de runas.
## No conoce la UI ni el árbol de escenas: solo administra los números.

signal experience_changed(current: int, needed: int, level: int)
signal level_up(new_level: int)

var level: int = 1
var experience: int = 0

## Fórmula de experiencia necesaria por nivel.
func experience_needed() -> int:
	return 20 + level * 15

func _ready() -> void:
	experience_changed.emit(experience, experience_needed(), level)

## Añade experiencia y procesa las posibles subidas de nivel (puede subir varias).
func add_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_needed():
		experience -= experience_needed()
		level += 1
		level_up.emit(level)
	experience_changed.emit(experience, experience_needed(), level)

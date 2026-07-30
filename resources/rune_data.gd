extends Resource
class_name RuneData
## Describe una runa (mejora). El "efecto" se implementa como un Callable que
## recibe el SpellData del jugador y lo modifica. Así el sistema es fácil de
## ampliar: basta con registrar una nueva RuneData en RuneDB.

@export var id: StringName = &""
@export var title: String = ""
@export var description: String = ""
@export var weight: float = 1.0   ## peso para la selección aleatoria

## Función que aplica la mejora sobre un SpellData. Se asigna al construir la runa.
var apply_func: Callable = Callable()

## Aplica la mejora al hechizo indicado.
func apply(spell: SpellData) -> void:
	if apply_func.is_valid():
		apply_func.call(spell)

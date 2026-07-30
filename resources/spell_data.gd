extends Resource
class_name SpellData
## Contenedor de todos los parámetros del hechizo principal del jugador.
## Las runas modifican estos valores en tiempo real. Es un Resource para poder
## duplicarlo con duplicate() y así garantizar un estado limpio en cada partida.

## Elementos disponibles (preparado para ampliar en el futuro).
enum Element { FIRE, ICE, LIGHTNING, ARCANE }

@export var damage: float = 10.0
@export var projectile_speed: float = 650.0
@export var cooldown: float = 0.4          ## segundos entre disparos
@export var projectile_count: int = 1
@export var spread_angle: float = 12.0     ## grados totales de dispersión
@export var penetration: int = 0           ## enemigos extra que atraviesa
@export var bounce_count: int = 0           ## rebotes contra paredes
@export var explosion_radius: float = 0.0   ## 0 = sin explosión
@export var explosion_damage_factor: float = 0.6 ## % del daño aplicado en explosión
@export var homing_strength: float = 0.0    ## 0 = sin seguimiento
@export var element: Element = Element.FIRE
@export var projectile_scale: float = 1.0
@export var lifetime: float = 2.0

const MIN_COOLDOWN: float = 0.08

## Devuelve el color asociado al elemento actual (para placeholders visuales).
func get_element_color() -> Color:
	match element:
		Element.FIRE: return Color(1.0, 0.55, 0.15)
		Element.ICE: return Color(0.4, 0.8, 1.0)
		Element.LIGHTNING: return Color(1.0, 0.95, 0.3)
		Element.ARCANE: return Color(0.75, 0.4, 1.0)
	return Color.WHITE

## Nombre legible del elemento para la interfaz.
func get_element_name() -> String:
	match element:
		Element.FIRE: return "Fuego"
		Element.ICE: return "Hielo"
		Element.LIGHTNING: return "Rayo"
		Element.ARCANE: return "Arcano"
	return "Desconocido"

## Resumen corto de los modificadores activos, para mostrar en el HUD.
func get_modifier_summary() -> String:
	var parts: Array[String] = []
	parts.append("Daño %d" % int(round(damage)))
	parts.append("x%d" % projectile_count)
	if penetration > 0:
		parts.append("Perf. %d" % penetration)
	if bounce_count > 0:
		parts.append("Reb. %d" % bounce_count)
	if explosion_radius > 0.0:
		parts.append("Explosión")
	if homing_strength > 0.0:
		parts.append("Persecución")
	if projectile_scale > 1.0:
		parts.append("Tamaño x%.1f" % projectile_scale)
	return "  ·  ".join(parts)

# ArcaneMage

Prototipo de **roguelite de acción top-down** hecho en **Godot 4 / GDScript**. Controlás a un mago cuyo hechizo evoluciona durante la partida mediante runas. Sobreviví oleadas de enemigos, subí de nivel, elegí mejoras y derrotá al jefe que aparece a los 5 minutos.

Todo el arte son placeholders generados dentro de Godot (`Polygon2D`, `Line2D`, etc.), sin assets externos.

## Cómo ejecutar

1. Abrí el proyecto con Godot 4.x (`Godot.app` → importar `project.godot`).
2. Pulsá **F5** (o el botón *Play*). La escena principal es `scenes/main/Game.tscn`.

## Controles

| Acción | Tecla |
|--------|-------|
| Mover | `WASD` / flechas |
| Apuntar | Mouse |
| Lanzar hechizo | Clic izquierdo (mantener) |
| (reservado) Pausa | `Esc` |

## Sistema de runas

El jugador tiene una única instancia de `SpellData`. Cada runa (`RuneData`) es una función que modifica ese hechizo. Al subir de nivel el juego se pausa y ofrece 3 runas distintas. Para agregar una runa nueva basta con añadir una entrada en `scripts/systems/rune_db.gd`.

Runas incluidas: Poder, Rapidez arcana, Proyectil doble, Penetración, Explosión, Persecución, Rebote y Crecimiento arcano.

## Estructura

```
scenes/    escenas (.tscn): main, player, enemies, spells, pickups, ui
scripts/   lógica (.gd): player, enemies, spells, systems, ui
resources/ datos: spell_data.gd, rune_data.gd
```

## Tests

Bancos de prueba headless incluidos (no forman parte del juego):

```bash
# Lógica central (runas, proyectiles, explosión, niveles, onda del jefe)
godot --headless --path . res://scenes/main/TestBench.tscn

# Flujo completo sobre la escena real (spawn, nivel, jefe, victoria/derrota)
godot --headless --path . res://scenes/main/IntegrationTest.tscn
```

> Nota: para ejecutarlos como escena principal, apuntá `run/main_scene` a la escena de test en `project.godot`.

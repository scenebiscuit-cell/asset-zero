class_name LevelData
extends Resource
## Settings for one level/sector (DESIGN.md §9). Stored as .tres files in data/levels/.

## Shown on screen, e.g. "SECTOR 1".
@export var sector_number: int = 1
## Seconds of waves before the director stops spawning.
@export var duration: float = 150.0
@export var wave_pool: Array[WaveData] = []

@export_group("Budget")
## Budget points gained per second at the start of the level.
@export var budget_rate: float = 1.0
## How much the rate grows every second, so the level ramps up.
@export var budget_growth: float = 0.008
## Never send waves closer together than this, in seconds.
@export var min_wave_gap: float = 1.2
## Hold off new waves while this many enemies are already on screen.
@export var max_enemies_alive: int = 22

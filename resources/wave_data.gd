class_name WaveData
extends Resource
## One enemy wave (DESIGN.md §9). Stored as .tres files in data/waves/. Movement comes from the
## enemy type itself; the wave sets which enemy, how many, the formation and where it enters.

enum Formation { SINGLE, COLUMN, ROW, V, SCATTER }
enum Entry { TOP, LEFT, RIGHT, SIDE_RANDOM }

@export var enemy_scene: PackedScene
@export_range(1, 12) var count: int = 1
@export var formation: Formation = Formation.SINGLE
@export var entry: Entry = Entry.TOP
## Where across the screen (TOP) or down the screen (sides) it enters, 0-1. Below 0 = random.
@export_range(-1.0, 1.0) var lane: float = -1.0
## Gap between members of the formation, in px.
@export var spacing: float = 48.0

@export_group("Director")
## Budget points the director spends to send this wave.
@export var cost: float = 3.0
## Earliest time in the level (seconds) this wave may appear.
@export var min_time: float = 0.0
## How often it's picked compared to other waves. 0 = never.
@export var weight: float = 1.0

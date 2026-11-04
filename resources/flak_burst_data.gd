class_name FlakBurstData
extends ModuleData
## Flak Burst (from the AA Emplacement): rounds that burst in a small blast after a short distance.
## damage is per blast, to everything inside it.

@export var rounds: int = 2
## Gunship form fans the rounds out by this much in total, in degrees. Lance form fires them straight.
@export var fan_degrees: float = 20.0
@export var round_speed: float = 620.0
## How far a round flies before bursting on its own.
@export var burst_distance: float = 190.0
## Lance form: longer range before bursting (DESIGN.md §5.8).
@export var lance_burst_distance: float = 380.0
@export var blast_radius: float = 36.0

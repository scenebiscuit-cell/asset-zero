class_name BeamData
extends WeaponData
## Beam Laser line: a continuous beam. fire_interval is the damage tick, damage is per tick.

## How far the beam reaches from the emitter, in pixels.
@export var reach: float = 600.0
## Hit width in Gunship form. Thresher form uses the thinner, brighter thresher_width (DESIGN.md §5.6).
@export var width: float = 6.0
@export var thresher_width: float = 3.0
@export var core_color: Color = Color(0.91, 1.0, 1.0)
@export var glow_color: Color = Color(0.25, 0.85, 0.82)
## Seconds the beam's afterglow takes to fade once Fire is released.
@export var afterglow_time: float = 0.1
## Split Array: number of beams and the angle between neighbours in Gunship form.
## Thresher form swings them together into one (§5.6). Uses split_array.tscn as the scene.
@export var beam_count: int = 1
@export var split_degrees: float = 0.0
## Thermal Lance: targets keep burning after the beam leaves them (damage per second, seconds).
@export var burn_dps: float = 0.0
@export var burn_time: float = 0.0

class_name DrillLanceData
extends ModuleData
## Drill Lance (from the Mining Platform): a short spinning drill beam that pierces everything.
## fire_interval is the damage tick; damage is per tick, to every enemy the drill touches.

## How far the drill reaches past the Salvage Mount, in pixels.
@export var length: float = 130.0
## Thresher form: the drill extends twice as far (DESIGN.md §5.8).
@export var thresher_length: float = 260.0
@export var width: float = 14.0
## Seconds to extend to full length (and to pull back in when Fire is released).
@export var extend_time: float = 0.08

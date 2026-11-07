class_name SystemRefitData
extends RefitData
## Propulsion and Armor line levels (DESIGN.md §6): stat refits for the Engine and Hull. Each level
## lists its full stats (not a bonus on top of the last level); the last level adds a perk.

enum Perk { NONE, RAZOR_WING, VECTOR_DASH, REACTIVE_ARMOR, NANITE_REPAIR }

## Propulsion: extra move speed (0.15 = +15%).
@export var speed_bonus: float = 0.0
## Propulsion: Thresher form speed as a fraction of Gunship speed. 0 = keep the default (55%).
@export var thresher_speed_multiplier: float = 0.0
## Armor: regenerating shield that soaks hits before Armor (§5.4).
@export var max_plating: int = 0
## Seconds without being hit before Plating recharges, then Plating per second.
@export var plating_recharge_delay: float = 3.0
@export var plating_recharge_rate: float = 10.0
@export var perk: Perk = Perk.NONE
## How this refit changes the airframe (engine glow, swept wings, blades, nozzles), at Light size.
@export var airframe_gunship: AirframeShape
@export var airframe_thresher: AirframeShape


func apply() -> void:
	super.apply()
	GameState.installed_systems[line] = self
	if line == Line.ARMOR:
		GameState.max_plating = max_plating
		GameState.plating = max_plating

extends Node
## Global signal bus. Anything can emit these and anything can listen, without the two knowing
## about each other. Keep it to game-wide moments; parent/child talk stays on normal signals.

## One salvage pickup was collected (any value).
signal salvage_collected
## An enemy round passed through XF-0's graze radius without hitting.
signal grazed(at: Vector2)
## XF-0 moved up a weight class (GameState.WeightClass).
signal weight_class_changed(weight_class: int)
## HSD Threat Level rose (1-4, DESIGN.md §9.1). Fires right after weight_class_changed.
signal threat_level_changed(threat_level: int)
## Overclock started / ended.
signal overclock_started
signal overclock_ended

extends Node
## Global signal bus. Anything can emit these and anything can listen, without the two knowing
## about each other. Keep it to game-wide moments; parent/child talk stays on normal signals.

## One salvage pickup was collected (any value).
signal salvage_collected
## An enemy round passed through XF-0's graze radius without hitting.
signal grazed(at: Vector2)
## Overclock started / ended.
signal overclock_started
signal overclock_ended

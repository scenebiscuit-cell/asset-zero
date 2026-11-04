class_name EnemyRound
extends Round
## Enemy fire. The player does the hit check; the graze ring marks each round so it counts once.

var grazed: bool = false


func activate(start: Vector2, velocity: Vector2, round_damage: int) -> void:
	grazed = false
	super(start, velocity, round_damage)

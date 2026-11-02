class_name RoundPool
extends ObjectPool
## Pool of rounds (player or enemy) with a one-call fire().


func fire(start: Vector2, velocity: Vector2, damage: int) -> void:
	var fired_round: Round = acquire() as Round
	if fired_round == null:
		return
	fired_round.activate(start, velocity, damage)

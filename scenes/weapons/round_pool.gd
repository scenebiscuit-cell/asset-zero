class_name RoundPool
extends ObjectPool
## Pool of rounds (player or enemy) with a one-call fire().


## tint colours the round (module rounds are tinted so you can tell them apart).
func fire(start: Vector2, velocity: Vector2, damage: int, tint: Color = Color.WHITE) -> void:
	var fired_round: Round = acquire() as Round
	if fired_round == null:
		return
	fired_round.activate(start, velocity, damage)
	fired_round.modulate = tint

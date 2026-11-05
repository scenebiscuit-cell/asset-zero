class_name RoundPool
extends ObjectPool
## Pool of rounds (player or enemy) with a one-call fire().


## tint colours the round (module rounds are tinted so you can tell them apart).
## Returns the round (or null if the pool is empty) so callers can set extras like pierce.
func fire(start: Vector2, velocity: Vector2, damage: int, tint: Color = Color.WHITE) -> Round:
	var fired_round: Round = acquire() as Round
	if fired_round == null:
		return null
	fired_round.activate(start, velocity, damage)
	fired_round.modulate = tint
	return fired_round

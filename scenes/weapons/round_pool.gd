class_name RoundPool
extends Node2D
## Makes all rounds up front and reuses them, so firing never creates or frees nodes.

@export var round_scene: PackedScene
@export var pool_size: int = 64

var _free_rounds: Array[PlayerRound] = []


func _ready() -> void:
	for i: int in pool_size:
		var player_round: PlayerRound = round_scene.instantiate() as PlayerRound
		add_child(player_round)
		player_round.expired.connect(_on_round_expired)
		player_round.deactivate()


func fire(start: Vector2, velocity: Vector2, damage: int) -> void:
	if _free_rounds.is_empty():
		return # Pool exhausted: drop the shot rather than allocate mid-game.
	var player_round: PlayerRound = _free_rounds.pop_back()
	player_round.activate(start, velocity, damage)


func _on_round_expired(player_round: PlayerRound) -> void:
	_free_rounds.append(player_round)

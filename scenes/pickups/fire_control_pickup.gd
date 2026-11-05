class_name FireControlPickup
extends DriftPickup
## Rare timed power-up (DESIGN.md §7.3): turns on auto-fire for a few seconds.

@export var duration: float = 10.0


func _on_collected(collector: Node2D) -> void:
	var player: Player = collector as Player
	if player != null:
		player.grant_autofire(duration)

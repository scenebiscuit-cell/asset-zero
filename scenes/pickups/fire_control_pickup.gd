class_name FireControlPickup
extends DriftPickup
## Rare power-up (DESIGN.md §7.3): stored on pickup; the Fire Control key then turns on auto-fire
## for a few seconds. The duration and storage limit live on the Player.


func _on_collected(collector: Node2D) -> void:
	var player: Player = collector as Player
	if player != null:
		player.store_fire_control()

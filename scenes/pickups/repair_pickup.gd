class_name RepairPickup
extends DriftPickup
## Pooled repair kit: restores Armor.

@export var repair_amount: int = 25


func _on_collected(_collector: Node2D) -> void:
	GameState.repair_armor(repair_amount)

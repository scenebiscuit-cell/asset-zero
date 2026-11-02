class_name SalvagePool
extends ObjectPool
## Pool of salvage pickups that burst out where an enemy died.

## What the pickups get pulled into.
@export var player: Node2D
@export var burst_speed: float = 120.0


func spawn_burst(at: Vector2, count: int, value: int = 1) -> void:
	for i: int in count:
		var pickup: SalvagePickup = acquire() as SalvagePickup
		if pickup == null:
			return
		var velocity: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.0) * burst_speed
		pickup.activate(at, velocity, value, player)

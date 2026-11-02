class_name SalvagePool
extends Node2D
## Makes all salvage pickups up front and reuses them.

@export var pickup_scene: PackedScene
@export var pool_size: int = 48
## What the pickups get pulled into.
@export var player: Node2D
@export var burst_speed: float = 120.0

var _free_pickups: Array[SalvagePickup] = []


func _ready() -> void:
	for i: int in pool_size:
		var pickup: SalvagePickup = pickup_scene.instantiate() as SalvagePickup
		add_child(pickup)
		pickup.expired.connect(_on_pickup_expired)
		pickup.deactivate()


func spawn_burst(at: Vector2, count: int, value: int = 1) -> void:
	for i: int in count:
		if _free_pickups.is_empty():
			return # Pool exhausted: skip rather than allocate mid-game.
		var pickup: SalvagePickup = _free_pickups.pop_back()
		var velocity: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.0) * burst_speed
		pickup.activate(at, velocity, value, player)


func _on_pickup_expired(pickup: SalvagePickup) -> void:
	_free_pickups.append(pickup)

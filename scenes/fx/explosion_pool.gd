class_name ExplosionPool
extends Node2D
## Makes all explosions up front and reuses them, so kills never create or free nodes.

@export var explosion_scene: PackedScene
@export var pool_size: int = 16

var _free_explosions: Array[Explosion] = []
# Oldest first, so a full pool can recycle the one that's mostly faded already.
var _active_explosions: Array[Explosion] = []


func _ready() -> void:
	for i: int in pool_size:
		var explosion: Explosion = explosion_scene.instantiate() as Explosion
		add_child(explosion)
		explosion.expired.connect(_on_explosion_expired)
		explosion.deactivate()


func spawn(at: Vector2) -> void:
	if _free_explosions.is_empty():
		_active_explosions.front().deactivate()
	var explosion: Explosion = _free_explosions.pop_back()
	_active_explosions.append(explosion)
	explosion.activate(at)


func _on_explosion_expired(explosion: Explosion) -> void:
	_active_explosions.erase(explosion)
	_free_explosions.append(explosion)

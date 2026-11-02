class_name ObjectPool
extends Node2D
## Makes objects up front and reuses them, so gameplay never creates or frees nodes.

@export var scene: PackedScene
@export var pool_size: int = 64

var _free_objects: Array[PooledObject] = []


func _ready() -> void:
	for i: int in pool_size:
		var object: PooledObject = scene.instantiate() as PooledObject
		add_child(object)
		object.expired.connect(_on_object_expired)
		object.deactivate()


## Returns null when everything is in use; callers skip rather than allocate mid-game.
func acquire() -> PooledObject:
	if _free_objects.is_empty():
		return null
	return _free_objects.pop_back()


func _on_object_expired(object: PooledObject) -> void:
	_free_objects.append(object)

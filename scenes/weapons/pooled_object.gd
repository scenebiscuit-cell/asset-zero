class_name PooledObject
extends Area2D
## Base for anything an ObjectPool reuses. Never freed: the pool switches it on and off.

signal expired(object: PooledObject)

# Starts true so the pool's first deactivate() files it as free.
var _active: bool = true


func is_active() -> bool:
	return _active


func deactivate() -> void:
	if not _active:
		return
	_active = false
	visible = false
	set_physics_process(false)
	# A disabled Area2D is taken out of collision checks. Deferred because this
	# often runs inside a collision callback, where that change isn't allowed.
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	expired.emit(self)


## Subclasses call this at the end of their own activate().
func _start() -> void:
	_active = true
	visible = true
	set_physics_process(true)
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)

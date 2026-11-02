class_name Autocannon
extends Node2D
## Nose weapon. Placed at the muzzle; the player tells it when to fire.

@export var data: WeaponData
## How long the muzzle flash stays lit after each shot (seconds).
@export var flash_duration: float = 0.04
## Random size range per flash, so a steady stream flickers instead of looking frozen.
@export var flash_scale_min: float = 0.75
@export var flash_scale_max: float = 1.15
## Random tilt per flash, in degrees.
@export var flash_max_tilt: float = 8.0

var round_pool: RoundPool
var firing: bool = false
var _cooldown: float = 0.0
var _flash_time: float = 0.0

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_visual.visible = false


func _physics_process(delta: float) -> void:
	_update_flash(delta)
	_cooldown -= delta
	if not firing or round_pool == null:
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown <= 0.0:
		round_pool.fire(global_position, Vector2.UP * data.round_speed, data.damage)
		_cooldown += data.fire_interval
		_show_flash()


func _show_flash() -> void:
	_flash_time = flash_duration
	var s: float = randf_range(flash_scale_min, flash_scale_max)
	# Stretch length more than width so the cone keeps its shape.
	_visual.scale = Vector2(lerpf(1.0, s, 0.5), s)
	_visual.rotation = deg_to_rad(randf_range(-flash_max_tilt, flash_max_tilt))
	_visual.visible = true


func _update_flash(delta: float) -> void:
	if _flash_time <= 0.0:
		return
	_flash_time -= delta
	if _flash_time <= 0.0:
		_visual.visible = false

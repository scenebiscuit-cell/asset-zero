class_name Autocannon
extends Weapon
## Autocannon line (DESIGN.md §6): one or more barrels side by side at the nose, firing tracer rounds.
## The data adds the level-3 behaviours: a fanned spread with fragmenting rounds (M40 Flak Battery)
## or a single piercing slug that fires faster in Lance form (RG-9 Railgun).

## How long the muzzle flash stays lit after each shot (seconds).
@export var flash_duration: float = 0.04
## Random size range per flash, so a steady stream flickers instead of looking frozen.
@export var flash_scale_min: float = 0.75
@export var flash_scale_max: float = 1.15
## Random tilt per flash, in degrees.
@export var flash_max_tilt: float = 8.0

var _gun: GunData
var _cooldown: float = 0.0
var _flash_time: float = 0.0
## One muzzle flash per barrel.
var _flashes: Array[Node2D] = []

@onready var _visual: Node2D = $Visual
@onready var _flash: Node2D = $Visual/Flash


func _ready() -> void:
	_gun = data as GunData
	_flashes.append(_flash)
	for i: int in range(1, _gun.barrel_count):
		var copy: Node2D = _flash.duplicate() as Node2D
		_visual.add_child(copy)
		_flashes.append(copy)
	_visual.visible = false


func _physics_process(delta: float) -> void:
	_update_flash(delta)
	_cooldown -= delta
	if not firing or not enabled or round_pool == null:
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown <= 0.0:
		for i: int in _gun.barrel_count:
			_fire_barrel(i)
		_cooldown += interval(_gun.fire_interval) * (_gun.lance_interval_scale if converged else 1.0)
		_show_flash()


## Gunship form: barrels sit apart. Lance form: they pull together into one stream.
func _barrel_x(index: int) -> float:
	var spacing: float = _gun.lance_barrel_spacing if converged else _gun.barrel_spacing
	return (index - (_gun.barrel_count - 1) * 0.5) * spacing


func _fire_barrel(index: int) -> void:
	var x: float = _barrel_x(index)
	var direction: Vector2 = Vector2.UP
	# Spread guns fan their barrels out; Lance form closes the fan to a narrow cone.
	var fan: float = _gun.lance_fan_degrees if converged else _gun.fan_degrees
	var degrees: float = (index - (_gun.barrel_count - 1) * 0.5) * fan
	if not converged:
		# Outer barrels angle outward; every round gets a little random scatter.
		degrees += signf(x) * _gun.splay_degrees + randf_range(-_gun.spread_degrees, _gun.spread_degrees)
	direction = direction.rotated(deg_to_rad(degrees))
	var fired: PlayerRound = round_pool.fire(global_position + Vector2(x, 0.0), direction * _gun.round_speed,
			scaled_damage(_gun.damage), _gun.round_tint) as PlayerRound
	if fired == null:
		return
	fired.pierce = _gun.pierce
	fired.set_length(_gun.round_length)
	if _gun.fragments > 0:
		fired.fragments = _gun.fragments
		fired.fragment_damage = scaled_damage(_gun.fragment_damage)
		fired.fragment_speed = _gun.fragment_speed
		fired.fragment_range = _gun.fragment_range


func _show_flash() -> void:
	_flash_time = flash_duration
	for i: int in _flashes.size():
		var flash: Node2D = _flashes[i]
		var s: float = randf_range(flash_scale_min, flash_scale_max)
		# Stretch length more than width so the cone keeps its shape.
		flash.scale = Vector2(lerpf(1.0, s, 0.5), s)
		flash.rotation = deg_to_rad(randf_range(-flash_max_tilt, flash_max_tilt))
		flash.position.x = _barrel_x(i)
	_visual.visible = true


func _update_flash(delta: float) -> void:
	if _flash_time <= 0.0:
		return
	_flash_time -= delta
	if _flash_time <= 0.0:
		_visual.visible = false

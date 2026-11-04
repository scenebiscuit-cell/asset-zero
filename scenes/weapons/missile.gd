class_name Missile
extends PooledObject
## Player missile or rocket. Seekers turn toward their target; rockets fly straight.
## Both leave a thin smoke trail and burst on hit.

const OFFSCREEN_MARGIN: float = 48.0

## Seconds between trail points; the trail is a fixed number of points that shuffle along.
@export var trail_interval: float = 0.025
## How long the burst and trail linger after a hit, before the missile goes back to the pool.
@export var burst_time: float = 0.45
## How often a missile without a target looks for one.
@export var retarget_interval: float = 0.15

var damage: int = 0
var _data: MissileData
var _pool: MissilePool
var _ahead_only: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _target: Enemy
var _life: float = 0.0
var _retarget_left: float = 0.0
var _trail_left: float = 0.0
## Above zero once it has burst: no longer flying, just letting the effects finish.
var _burst_left: float = 0.0

@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _body: Node2D = $Visual/Body
@onready var _trail: Line2D = $Visual/Trail
@onready var _burst: CPUParticles2D = $Visual/Burst


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func activate(start: Vector2, direction: Vector2, missile_data: MissileData, missile_damage: int,
		ahead_only: bool, pool: MissilePool) -> void:
	global_position = start
	_data = missile_data
	_pool = pool
	_ahead_only = ahead_only
	damage = missile_damage
	_velocity = direction.normalized() * _data.speed
	rotation = _velocity.angle() + PI / 2.0
	_target = null
	_life = _data.lifetime
	_retarget_left = 0.0
	_trail_left = trail_interval
	_burst_left = 0.0
	_body.visible = true
	_trail.modulate.a = 1.0
	for i: int in _trail.get_point_count():
		_trail.set_point_position(i, start)
	_hitbox.set_deferred("disabled", false)
	_start()


func _physics_process(delta: float) -> void:
	if _burst_left > 0.0:
		_burst_left -= delta
		_trail.modulate.a = clampf(_burst_left / burst_time, 0.0, 1.0)
		_update_trail(delta)
		if _burst_left <= 0.0:
			deactivate()
		return
	_steer(delta)
	position += _velocity * delta
	rotation = _velocity.angle() + PI / 2.0
	_update_trail(delta)
	_life -= delta
	if _life <= 0.0:
		_burst_now()
	elif not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		deactivate()


func _steer(delta: float) -> void:
	if not _data.homing:
		return
	if not is_instance_valid(_target) or _target.hp <= 0:
		_target = null
		_retarget_left -= delta
		if _retarget_left <= 0.0:
			_retarget_left = retarget_interval
			_target = _pool.find_target(global_position, _ahead_only, _data.lance_seek_cone_degrees)
	if _target == null:
		return
	var wanted: float = global_position.direction_to(_target.global_position).angle()
	var turned: float = rotate_toward(_velocity.angle(), wanted, deg_to_rad(_data.turn_rate_degrees) * delta)
	_velocity = Vector2.from_angle(turned) * _data.speed


## The trail is drawn in world space (top_level), so it stays where the smoke was left.
func _update_trail(delta: float) -> void:
	_trail_left -= delta
	if _trail_left <= 0.0:
		_trail_left += trail_interval
		for i: int in range(_trail.get_point_count() - 1, 0, -1):
			_trail.set_point_position(i, _trail.get_point_position(i - 1))
	_trail.set_point_position(0, global_position)


func _on_area_entered(area: Area2D) -> void:
	if not is_active() or _burst_left > 0.0:
		return
	if area is Enemy:
		(area as Enemy).take_damage(damage)
		_burst_now()


func _burst_now() -> void:
	_burst_left = burst_time
	_body.visible = false
	_hitbox.set_deferred("disabled", true)
	_burst.restart()

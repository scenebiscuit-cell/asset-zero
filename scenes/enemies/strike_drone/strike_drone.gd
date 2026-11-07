class_name StrikeDrone
extends Enemy
## SD-6 Strike Drone: drops in, locks on with a red flash and a shiver, then dives at where XF-0 was at full
## speed. No gun: it's the contact damage you have to dodge. data.speed is the dive speed.

enum Phase { APPROACH, LOCK, DIVE }

## Descent speed before the lock, in px/s.
@export var approach_speed: float = 200.0
## It locks on this far below the top of the play area.
@export var lock_depth: float = 120.0
@export var lock_time: float = 0.55
@export var lock_color: Color = Color(1.0, 0.2, 0.15)
## How far it shivers while locking, in px.
@export var shiver: float = 1.5
## Trail points kept behind it during the dive.
@export var trail_length: int = 10
## Off the screen by this much in any direction and it's gone (dives can leave through a side).
@export var exit_margin: float = 60.0

var _phase: Phase = Phase.APPROACH
var _lock_left: float = 0.0
var _dive_direction: Vector2 = Vector2.DOWN

@onready var _trail: Line2D = $Trail
@onready var _eye: Polygon2D = $Visual/Eye


func _ready() -> void:
	super()
	_trail.top_level = true
	_trail.clear_points()


func _tick(delta: float) -> void:
	match _phase:
		Phase.APPROACH:
			position.y += approach_speed * delta
			if position.y >= play_area_top + lock_depth:
				_phase = Phase.LOCK
				_lock_left = lock_time
		Phase.LOCK:
			_lock_left -= delta
			var t: float = 1.0 - _lock_left / lock_time
			_visual.position = Vector2(randf_range(-shiver, shiver), randf_range(-shiver, shiver)) * t
			_eye.scale = Vector2.ONE * (1.0 + 1.5 * t)
			_visual.modulate = Color.WHITE.lerp(lock_color, 0.5 * t)
			if _lock_left <= 0.0:
				_dive()
		Phase.DIVE:
			position += _dive_direction * data.speed * delta
			_trail.add_point(global_position, 0)
			if _trail.get_point_count() > trail_length:
				_trail.remove_point(_trail.get_point_count() - 1)
			if not get_viewport_rect().grow(exit_margin).has_point(global_position):
				escape()


## Locks the dive on XF-0's position right now: a straight line, so a sidestep clears it.
func _dive() -> void:
	_phase = Phase.DIVE
	_visual.position = Vector2.ZERO
	_visual.modulate = Color.WHITE
	_eye.scale = Vector2.ONE * 1.6
	_dive_direction = direction_to_target()
	# Art points down the screen (+y).
	_visual.rotation = _dive_direction.angle() - PI / 2.0
	($Shadow as DropShadow).refresh()

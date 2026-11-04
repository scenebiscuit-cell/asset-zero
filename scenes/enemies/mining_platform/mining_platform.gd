class_name MiningPlatform
extends Enemy
## Mining Platform: a drill tank on treads. Tanky; its turret turns a large drill toward XF-0, winds up, then thrusts
## out and hurts XF-0 on touch. Every few seconds it burrows and resurfaces somewhere else on screen.
## data.fire_interval is the pause between thrusts; data.round_damage is the drill's damage.

enum State { SURFACED, BURROWING, HIDDEN, RISING }

@export_group("Drill")
## How fast the drill turns to follow XF-0, in radians per second.
@export var turn_speed: float = 1.6
## Drill length at rest, and at full thrust, in pixels from the hub.
@export var rest_length: float = 74.0
@export var thrust_length: float = 240.0
@export var drill_width: float = 34.0
## Warning before a thrust: the drill stops turning, glows and pulls back.
@export var windup_time: float = 0.7
@export var thrust_time: float = 0.14
@export var hold_time: float = 0.35
@export var retract_time: float = 0.45
## Spinning-thread look: how fast the threads scroll toward the tip (in drill-art units per second).
@export var spin_speed: float = 140.0
@export var windup_color: Color = Color(1.0, 0.45, 0.3)

@export_group("Burrow")
## Seconds above ground before burrowing again.
@export var surfaced_time: float = 4.0
@export var burrow_time: float = 0.6
## Time underground. A dirt mound churns up at the new spot during this, as a warning.
@export var hidden_time: float = 0.9
@export var rise_time: float = 0.45
## The rig darkens to this as it sinks into the earth, and comes up out of it.
@export var dirt_color: Color = Color(0.36, 0.2, 0.16, 0.0)
## How far the rig shakes while it digs, in pixels.
@export var rumble: float = 2.5
## After this many relocations it stays put and scrolls away with the terrain.
@export var max_relocations: int = 3
## Resurfaces at least this far from XF-0, inside this band of the screen.
@export var min_player_distance: float = 200.0
@export var surface_margin: Vector2 = Vector2(70.0, 140.0)
@export_range(0.0, 1.0) var surface_max_height: float = 0.6

var _state: State = State.SURFACED
var _state_left: float = 0.0
var _relocations: int = 0
var _active: bool = false
var _cooldown: float = 0.0
## Drill thrust phases: 0 aiming, 1 wind-up, 2 thrust, 3 hold, 4 retract.
var _phase: int = 0
var _phase_left: float = 0.0
var _length: float = 0.0
var _spin: float = 0.0

@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _drill: Node2D = $Visual/Drill
@onready var _bit: Node2D = $Visual/Drill/Bit
@onready var _threads: Node2D = $Visual/Drill/Bit/Threads
@onready var _hazard: EnemyHazard = $DrillHazard
@onready var _hazard_shape: CollisionShape2D = $DrillHazard/Shape
@onready var _mound: Node2D = $BurrowMound
@onready var _dirt: CPUParticles2D = $BurrowDirt


func _ready() -> void:
	super()
	_hazard.damage = data.round_damage
	_hazard_shape.shape = RectangleShape2D.new()
	_cooldown = data.fire_interval
	_drill.rotation = PI # Bit art points up; start facing down the screen, toward XF-0.
	_set_length(rest_length)
	_set_armed(false)
	_mound.scale = Vector2.ZERO


func is_targetable() -> bool:
	return _state == State.SURFACED


func _tick(delta: float) -> void:
	_spin = fmod(_spin + spin_speed * delta, 100.0)
	_update_threads()
	if not _active:
		# Waits until it has scrolled fully into view before doing anything.
		if global_position.y < surface_margin.y * 0.5:
			return
		_active = true
		_state_left = surfaced_time
	match _state:
		State.SURFACED:
			_update_drill(delta)
			_state_left -= delta
			# Never burrows mid-thrust.
			if _state_left <= 0.0 and _phase == 0 and _relocations < max_relocations:
				_burrow()
		State.BURROWING, State.RISING:
			_shake(_visual)
		State.HIDDEN:
			_shake(_mound)
			_state_left -= delta
			if _state_left <= 0.0:
				_resurface()


func _update_drill(delta: float) -> void:
	var wanted: float = direction_to_target().angle() + PI / 2.0
	match _phase:
		0: # Aiming: follow XF-0, thrust when lined up and rested.
			_drill.rotation = rotate_toward(_drill.rotation, wanted, turn_speed * delta)
			_cooldown -= delta
			if _cooldown <= 0.0 and absf(angle_difference(_drill.rotation, wanted)) < deg_to_rad(10.0):
				_start_phase(1, windup_time)
		1: # Wind-up: locked aim, glows and pulls back so XF-0 can dodge.
			var t: float = 1.0 - _phase_left / windup_time
			_set_length(rest_length * (1.0 - 0.25 * t))
			_drill.modulate = Color.WHITE.lerp(windup_color, t)
			_bit.position.x = sin(t * 60.0) * 1.5 * t # Shudders harder as it charges.
			_advance_phase(delta, 2, thrust_time)
			if _phase == 2:
				_bit.position.x = 0.0
				_set_armed(true)
		2: # Thrust out.
			var t: float = 1.0 - _phase_left / thrust_time
			_set_length(lerpf(rest_length * 0.75, thrust_length, t))
			_advance_phase(delta, 3, hold_time)
		3: # Hold at full reach.
			_set_length(thrust_length)
			_advance_phase(delta, 4, retract_time)
		4: # Pull back in.
			var t: float = 1.0 - _phase_left / retract_time
			_set_length(lerpf(thrust_length, rest_length, t))
			_drill.modulate = windup_color.lerp(Color.WHITE, t)
			if _length < rest_length * 2.0:
				_set_armed(false)
			_advance_phase(delta, 0, 0.0)
			if _phase == 0:
				_cooldown = data.fire_interval


func _start_phase(phase: int, duration: float) -> void:
	_phase = phase
	_phase_left = duration


func _advance_phase(delta: float, next: int, next_duration: float) -> void:
	_phase_left -= delta
	if _phase_left <= 0.0:
		_start_phase(next, next_duration)


func _set_length(length: float) -> void:
	_length = length
	_bit.scale.y = length / 100.0 # Bit art is drawn 100 px long.
	_hazard.rotation = _drill.rotation
	var rect: RectangleShape2D = _hazard_shape.shape as RectangleShape2D
	# Narrower than the art and stops short of the tip, so near misses stay near misses.
	rect.size = Vector2(drill_width * 0.6, length * 0.85)
	_hazard_shape.position = Vector2(0.0, -length * 0.5)


func _set_armed(armed: bool) -> void:
	_hazard_shape.set_deferred("disabled", not armed)


## Threads scroll toward the tip and narrow with the cone, so the drill looks like it's spinning.
func _update_threads() -> void:
	var count: int = _threads.get_child_count()
	for i: int in count:
		var thread: Node2D = _threads.get_child(i) as Node2D
		var y: float = fmod(_spin + i * (100.0 / count), 100.0)
		thread.position.y = -y
		thread.scale.x = 1.0 - y / 100.0


## Digs down: rumbles, darkens into the earth and sinks while dirt sprays and a mound churns up.
func _burrow() -> void:
	_state = State.BURROWING
	_relocations += 1
	_reset_drill()
	_hitbox.set_deferred("disabled", true)
	_dirt.emitting = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_mound, "scale", Vector2.ONE, burrow_time * 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "scale", Vector2(0.8, 0.8), burrow_time).set_ease(Tween.EASE_IN)
	tween.tween_property(_visual, "modulate", dirt_color, burrow_time).set_ease(Tween.EASE_IN)
	_fade_outline(tween, 0.0, burrow_time)
	tween.chain().tween_property(_mound, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_on_burrowed)


## Underground: moves to the new spot, where a mound churns up to warn XF-0.
func _on_burrowed() -> void:
	_state = State.HIDDEN
	_state_left = hidden_time
	_visual.position = Vector2.ZERO
	position = _pick_surface_point()
	_dirt.restart()
	create_tween().tween_property(_mound, "scale", Vector2.ONE, hidden_time).set_ease(Tween.EASE_OUT)


## Bursts up out of the mound in a spray of dirt.
func _resurface() -> void:
	_drill.rotation = direction_to_target().angle() + PI / 2.0
	_state = State.RISING
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_visual, "scale", Vector2.ONE, rise_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_visual, "modulate", Color.WHITE, rise_time).set_ease(Tween.EASE_OUT)
	_fade_outline(tween, 1.0, rise_time)
	tween.chain().tween_property(_mound, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.parallel().tween_callback(_on_risen)


func _on_risen() -> void:
	_state = State.SURFACED
	_state_left = surfaced_time
	_cooldown = data.fire_interval * 0.5
	_visual.position = Vector2.ZERO
	_dirt.emitting = false
	_hitbox.set_deferred("disabled", false)


## The elite halo sinks and rises with the rig.
func _fade_outline(tween: Tween, alpha: float, duration: float) -> void:
	if elite_outline != null:
		tween.tween_property(elite_outline, "modulate:a", alpha, duration)


func _shake(node: Node2D) -> void:
	node.position = Vector2(randf_range(-rumble, rumble), randf_range(-rumble, rumble))


func _reset_drill() -> void:
	_phase = 0
	_set_armed(false)
	_set_length(rest_length)
	_drill.modulate = Color.WHITE
	_bit.position.x = 0.0


## A random spot in the upper part of the screen, kept away from XF-0 so it never pops up on top of it.
func _pick_surface_point() -> Vector2:
	var size: Vector2 = get_viewport_rect().size
	var best: Vector2 = position
	var best_distance: float = -1.0
	for i: int in 8:
		var point: Vector2 = Vector2(
			randf_range(surface_margin.x, size.x - surface_margin.x),
			randf_range(surface_margin.y, size.y * surface_max_height))
		var distance: float = INF
		if is_instance_valid(target):
			distance = point.distance_to(target.global_position)
		if distance >= min_player_distance:
			return point
		if distance > best_distance:
			best_distance = distance
			best = point
	return best

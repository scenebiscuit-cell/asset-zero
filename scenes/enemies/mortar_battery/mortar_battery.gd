class_name MortarBattery
extends Enemy
## MB-5 Mortar Battery: ground pit that lobs a shell at where XF-0 is. A reticle marks the landing spot
## while the shell is in the air; when it lands it bursts into a ring of rounds. data.fire_interval is the
## pause between shells, data.round_speed/round_damage are the ring's.

## Seconds the shell is in the air (the warning XF-0 gets).
@export var flight_time: float = 1.1
## The landing spot is XF-0's position plus up to this much random scatter, in px.
@export var scatter: float = 36.0
@export var ring_count: int = 10
## Elites burst into this many extra rounds.
@export var elite_extra_rounds: int = 4
## How much bigger the shell draws at the top of its arc (it's "closer to the camera").
@export var arc_scale: float = 1.0
## Seconds on screen before the first shell.
@export var warmup: float = 0.9
@export var reticle_color: Color = Color(1.0, 0.3, 0.2, 0.9)

var _on_screen_time: float = 0.0
var _cooldown: float = 0.0
var _flight_left: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO

@onready var _tube: Node2D = $Visual/Tube
@onready var _shell: Node2D = $Shell
@onready var _reticle: Node2D = $Reticle
@onready var _ring: Line2D = $Reticle/Ring


func _ready() -> void:
	super()
	_shell.top_level = true
	_reticle.top_level = true
	_shell.visible = false
	_reticle.visible = false
	# Placeholder reticle: a ring drawn in code.
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 17:
		points.append(Vector2.from_angle(TAU * i / 16.0) * 14.0)
	_ring.points = points
	_ring.default_color = reticle_color
	for cross: Node in _reticle.get_children():
		if cross is Line2D and cross != _ring:
			(cross as Line2D).default_color = reticle_color


func _tick(delta: float) -> void:
	if _flight_left > 0.0:
		_update_shell(delta)
		return
	if not is_on_screen():
		return
	_on_screen_time += delta
	_cooldown -= delta
	if _on_screen_time >= warmup and _cooldown <= 0.0 and is_instance_valid(target):
		_cooldown = data.fire_interval
		_launch()


func _launch() -> void:
	_from = _tube.global_position
	_to = target.global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, scatter)
	var size: Vector2 = get_viewport_rect().size
	var bottom: float = play_area_bottom if play_area_bottom > 0.0 else size.y
	_to = Vector2(clampf(_to.x, 20.0, size.x - 20.0), clampf(_to.y, play_area_top + 20.0, bottom - 20.0))
	_flight_left = flight_time
	_shell.visible = true
	_shell.global_position = _from
	_reticle.visible = true
	_reticle.global_position = _to
	_reticle.modulate.a = 1.0
	# Recoil.
	_tube.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(_tube, "scale", Vector2.ONE, 0.25)


func _update_shell(delta: float) -> void:
	_flight_left -= delta
	var t: float = clampf(1.0 - _flight_left / flight_time, 0.0, 1.0)
	_shell.global_position = _from.lerp(_to, t)
	_shell.scale = Vector2.ONE * (1.0 + arc_scale * sin(t * PI))
	_shell.rotation += delta * 9.0
	# The reticle tightens as the shell comes down.
	_reticle.scale = Vector2.ONE * (1.7 - 0.7 * t)
	if _flight_left <= 0.0:
		_land()


func _land() -> void:
	_shell.visible = false
	var count: int = ring_count + (elite_extra_rounds if elite else 0)
	fire_ring(_to, count, randf_range(0.0, 360.0))
	# The reticle flashes out.
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_reticle, "scale", Vector2.ONE * 2.4, 0.2)
	tween.tween_property(_reticle, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(_reticle.hide)

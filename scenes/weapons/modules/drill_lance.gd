class_name DrillLance
extends ModuleWeapon
## Drill Lance module (DESIGN.md §5.8): a short spinning drill that pierces everything it touches.
## Lance form extends it twice as far. Pulls back in when Fire is released.

## How fast the drill's threads scroll, in pixels per second (the spinning look).
@export var spin_speed: float = 160.0
@export var thread_spacing: float = 9.0
@export var drill_color: Color = Color(0.5, 0.55, 0.6)
@export var thread_color: Color = Color(0.9, 0.95, 1.0)

var _drill: DrillLanceData
var _length: float = 0.0
var _tick: float = 0.0
var _spin: float = 0.0
## Reused every redraw, so the drill never allocates while spinning.
var _wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

@onready var _bore: Area2D = $Bore
@onready var _bore_shape: CollisionShape2D = $Bore/Shape
@onready var _drill_visual: Node2D = $Visual/Drill


func _ready() -> void:
	super()
	_drill = data as DrillLanceData
	_bore_shape.shape = RectangleShape2D.new()
	_drill_visual.draw.connect(_draw_drill)
	_set_length(0.0)


func _physics_process(delta: float) -> void:
	var active: bool = firing and enabled
	var wanted: float = 0.0
	if active:
		wanted = _drill.lance_length if converged else _drill.length
	if not is_equal_approx(_length, wanted):
		var rate: float = maxf(_drill.length, _drill.lance_length) / _drill.extend_time
		_set_length(move_toward(_length, wanted, rate * delta))
	if _length <= 0.0:
		_tick = maxf(_tick - delta, 0.0)
		return
	_spin = fmod(_spin + spin_speed * delta, thread_spacing)
	_drill_visual.queue_redraw()
	_tick -= delta
	if _tick <= 0.0:
		_tick += interval(_drill.fire_interval)
		for area: Area2D in _bore.get_overlapping_areas():
			var enemy: Enemy = area as Enemy
			if enemy != null:
				enemy.take_damage(scaled_damage(_drill.damage))


func _set_length(length: float) -> void:
	_length = length
	(_bore_shape.shape as RectangleShape2D).size = Vector2(_drill.width, maxf(length, 1.0))
	_bore_shape.position = Vector2(0.0, -length * 0.5)
	_bore.monitoring = length > 0.0
	_drill_visual.visible = length > 0.0
	_drill_visual.queue_redraw()


## A tapering wedge with threads that scroll toward the tip.
func _draw_drill() -> void:
	var half: float = _drill.width * 0.5
	_wedge[0] = Vector2(-half, 0.0)
	_wedge[1] = Vector2(half, 0.0)
	_wedge[2] = Vector2(0.0, -_length)
	_drill_visual.draw_colored_polygon(_wedge, drill_color)
	var y: float = _spin
	while y < _length - 4.0:
		var w: float = half * (1.0 - y / _length)
		_drill_visual.draw_line(Vector2(-w, -y), Vector2(w, -y - 4.0), thread_color, 1.0)
		y += thread_spacing

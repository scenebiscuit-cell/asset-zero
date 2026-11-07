class_name NaniteDrones
extends Node2D
## Nanite Repair made visible: small metal repair blobs fly out beside XF-0 while it heals, spark
## a thin repair beam at the hull, and fly back in once healing stops.

@export var drone_count: int = 3
@export var orbit_radius: float = 30.0
@export var orbit_speed: float = 1.8
@export var blob_radius: float = 3.8
@export var body_color: Color = Color(0.72, 0.75, 0.78)
@export var beam_color: Color = Color(0.45, 1.0, 0.55)
## Seconds to fly out or back in.
@export var deploy_time: float = 0.35

## Set by ShipSystems each frame while Nanite Repair is healing.
var active: bool = false

var _time: float = 0.0
var _deployed: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	_deployed = move_toward(_deployed, 1.0 if active else 0.0, delta / deploy_time)
	visible = _deployed > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var out: float = _deployed * _deployed * (3.0 - 2.0 * _deployed) # Smoothstep.
	for i: int in drone_count:
		var angle: float = _time * orbit_speed + TAU * i / drone_count
		# Bobs in and out a little so they look busy, not fixed.
		var reach: float = orbit_radius * out * (1.0 + 0.12 * sin(_time * 5.0 + i))
		var at: Vector2 = Vector2.from_angle(angle) * reach
		var r: float = blob_radius * (0.5 + 0.5 * out)
		# Repair beam flickers at the hull.
		if active and fmod(_time * 6.0 + i * 0.7, 1.0) < 0.6:
			draw_line(at, at * 0.35, Color(beam_color, 0.8 * out), 1.0)
			draw_circle(at * 0.35, 1.3, Color(beam_color, out))
		# A liquid-metal blob: body, highlight, and a small green eye.
		draw_circle(at, r, Color(body_color, out))
		draw_circle(at + Vector2(-r * 0.35, -r * 0.35), r * 0.4, Color(1.0, 1.0, 1.0, 0.6 * out))
		draw_circle(at + Vector2.from_angle(angle + PI) * r * 0.4, r * 0.3, Color(beam_color, out))

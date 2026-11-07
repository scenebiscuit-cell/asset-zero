class_name SplitArray
extends Weapon
## HEL-3S Split Array (DESIGN.md §6): several Beam Lasers from one emitter, fanned out in Gunship
## form. Thresher form swings them together until they merge into one hot beam (§5.6).

@export var beam_scene: PackedScene
## Degrees per second the outer beams swing while the ship morphs.
@export var swing_speed: float = 300.0

var _beam_data: BeamData
var _beams: Array[BeamLaser] = []
var _angle: float = 0.0


func _ready() -> void:
	_beam_data = data as BeamData
	_angle = _target_angle()
	for i: int in maxi(_beam_data.beam_count, 1):
		var beam: BeamLaser = beam_scene.instantiate() as BeamLaser
		beam.data = _beam_data
		add_child(beam)
		_beams.append(beam)
	_sync()


func _physics_process(delta: float) -> void:
	_angle = move_toward(_angle, _target_angle(), swing_speed * delta)
	_sync()


func _target_angle() -> float:
	return 0.0 if converged else _beam_data.split_degrees


## Child beams copy the hardpoint's state; Hardpoints only talks to this node.
func _sync() -> void:
	var count: int = _beams.size()
	for i: int in count:
		var beam: BeamLaser = _beams[i]
		beam.firing = firing
		beam.converged = converged
		beam.enabled = enabled
		beam.damage_multiplier = damage_multiplier
		beam.rotation_degrees = (i - (count - 1) * 0.5) * _angle

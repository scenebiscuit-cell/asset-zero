class_name SeekerLauncher
extends Weapon
## Missile line (DESIGN.md §6), rockets and seekers: fires a volley from the wing pylons on its own timer, no Fire
## button needed. Gunship form launches outward and seeks anything; Lance form launches straight
## and seeks only targets ahead (§5.6).

var _missile: MissileData
var _cooldown: float = 0.0

@onready var _pods: Array[Node2D] = [$Visual/PodLeft, $Visual/PodRight]


func _ready() -> void:
	_missile = data as MissileData


func _physics_process(delta: float) -> void:
	_follow_pylons()
	if not enabled or missile_pool == null or launch_points.is_empty():
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	# Holds fire until something is there to seek, so it doesn't spray missiles at an empty sky.
	if missile_pool.find_target(global_position, converged, _missile.lance_seek_cone_degrees) == null:
		_cooldown = 0.0
		return
	_cooldown = interval(_missile.fire_interval)
	for i: int in _missile.missiles_per_volley:
		var point: Node2D = launch_points[i % launch_points.size()]
		# Extra missiles from the same pylon fan out a little further.
		var row: int = floori(float(i) / launch_points.size())
		var side: float = -1.0 if point.position.x < 0.0 else 1.0
		var degrees: float = 0.0 if converged else side * (_missile.launch_angle_degrees + row * 12.0)
		missile_pool.launch(point.global_position, Vector2.UP.rotated(deg_to_rad(degrees)), _missile,
				scaled_damage(_missile.damage), converged)


## The pods ride on the pylons, which slide in and out as the airframe morphs.
func _follow_pylons() -> void:
	for i: int in mini(_pods.size(), launch_points.size()):
		_pods[i].position = launch_points[i].position

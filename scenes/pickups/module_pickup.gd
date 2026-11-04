class_name ModulePickup
extends DriftPickup
## Weapon module dropped by an elite (DESIGN.md §5.8): a glowing hexagon in the module's colour
## that drifts slowly for a few seconds, then breaks apart. Fly into it to assimilate it.

@export var lifetime: float = 6.0
## Starts blinking this long before it breaks apart, as a warning.
@export var warn_time: float = 1.5
@export var break_time: float = 0.4

var module: ModuleData
var _breaking_left: float = 0.0

@onready var _hex: Node2D = $Visual/Hex
@onready var _glow: Polygon2D = $Visual/Hex/Glow
@onready var _ring: Polygon2D = $Visual/Hex/Ring
@onready var _shards: CPUParticles2D = $Visual/Shards


## Set module before calling activate().
func activate(at: Vector2, target: Node2D) -> void:
	_breaking_left = 0.0
	_glow.color = Color(module.color, _glow.color.a)
	_ring.color = module.color.lerp(Color.WHITE, 0.3)
	_shards.color = module.color
	_hex.visible = true
	_hex.modulate.a = 1.0
	super(at, target)


func _physics_process(delta: float) -> void:
	if _breaking_left > 0.0:
		_breaking_left -= delta
		position.y += drift_speed * delta
		if _breaking_left <= 0.0:
			deactivate()
		return
	if _age >= lifetime:
		_break_apart()
		return
	super(delta)
	if _age > lifetime - warn_time:
		_hex.modulate.a = 1.0 if fmod(_age * 8.0, 2.0) < 1.0 else 0.35


func _break_apart() -> void:
	_breaking_left = break_time
	_hex.visible = false
	_shards.restart()


func _on_collected(collector: Node2D) -> void:
	var player: Player = collector as Player
	if player != null:
		player.assimilate(module)

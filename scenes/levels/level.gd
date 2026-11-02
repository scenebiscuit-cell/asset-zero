class_name Level
extends Node2D
## Runs one level. For now it just sends lines of RD-2 drones; the wave director replaces that in Step 7.

@export var drone_scene: PackedScene
@export var explosion_scene: PackedScene
@export var line_interval: float = 2.5
@export var drones_per_line: int = 5
@export var line_spacing: float = 48.0
## Keeps spawned lines away from the screen edges.
@export var spawn_margin: float = 60.0

var _spawn_timer: float = 1.0

@onready var _enemies: Node2D = $Enemies
@onready var _fx: Node2D = $FX
@onready var _salvage_pool: SalvagePool = $SalvagePool


func _ready() -> void:
	GameState.reset_run()


func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer += line_interval
		_spawn_drone_line()


func _spawn_drone_line() -> void:
	var x: float = randf_range(spawn_margin, get_viewport_rect().size.x - spawn_margin)
	for i: int in drones_per_line:
		var drone: Enemy = drone_scene.instantiate() as Enemy
		drone.position = Vector2(x, -30.0 - i * line_spacing)
		drone.destroyed.connect(_on_enemy_destroyed)
		_enemies.add_child(drone)


func _on_enemy_destroyed(enemy: Enemy) -> void:
	var explosion: Node2D = explosion_scene.instantiate() as Node2D
	explosion.position = enemy.global_position
	_fx.add_child(explosion)
	_salvage_pool.spawn_burst(enemy.global_position, enemy.data.salvage)

class_name Level
extends Node2D
## Runs one level. For now it just sends lines of RD-2 drones; the wave director replaces that in Step 7.

@export var drone_scene: PackedScene
## Off in test scenes that spawn enemies by hand.
@export var auto_spawn_drones: bool = true
@export var line_interval: float = 2.5
@export var drones_per_line: int = 5
@export var line_spacing: float = 48.0
## Keeps spawned lines away from the screen edges.
@export var spawn_margin: float = 60.0
## Chance (0-1) that any destroyed enemy drops a timed Fire Control pickup (DESIGN.md §7.3).
@export_range(0.0, 1.0) var fire_control_drop_chance: float = 0.03
## Lets the death splash play out before the failure screen appears.
@export var mission_failed_delay: float = 1.0

var _spawn_timer: float = 1.0

@onready var _enemies: Node2D = $Enemies
@onready var _ground_layer: BackgroundLayer = $GroundLayer
@onready var _enemy_round_pool: RoundPool = $EnemyRoundPool
@onready var _explosion_pool: ExplosionPool = $FX/ExplosionPool
@onready var _salvage_pool: SalvagePool = $SalvagePool
@onready var _repair_pool: ObjectPool = $RepairPool
@onready var _fire_control_pool: ObjectPool = $FireControlPool
@onready var _player: Player = $Player
@onready var _mission_failed: MissionFailedScreen = $MissionFailed


func _ready() -> void:
	GameState.reset_run()
	_player.destroyed.connect(_on_player_destroyed)


func _process(delta: float) -> void:
	if not auto_spawn_drones:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer += line_interval
		_spawn_drone_line()


func _spawn_drone_line() -> void:
	var x: float = randf_range(spawn_margin, get_viewport_rect().size.x - spawn_margin)
	for i: int in drones_per_line:
		spawn_enemy(drone_scene, Vector2(x, -30.0 - i * line_spacing))


## The one way enemies enter the level: wires up what they need before they're added.
func spawn_enemy(scene: PackedScene, at: Vector2, elite: bool = false) -> Enemy:
	var enemy: Enemy = scene.instantiate() as Enemy
	enemy.position = at
	enemy.elite = elite
	enemy.round_pool = _enemy_round_pool
	enemy.target = _player
	enemy.ground_speed = _ground_layer.scroll_speed
	enemy.destroyed.connect(_on_enemy_destroyed)
	_enemies.add_child(enemy)
	return enemy


func _on_enemy_destroyed(enemy: Enemy) -> void:
	_explosion_pool.spawn(enemy.global_position)
	_salvage_pool.spawn_burst(enemy.global_position, enemy.salvage_value())
	if randf() < enemy.data.repair_drop_chance:
		drop_pickup(_repair_pool, enemy.global_position)
	if randf() < fire_control_drop_chance:
		drop_pickup(_fire_control_pool, enemy.global_position + Vector2(0.0, -12.0))


func drop_repair(at: Vector2) -> void:
	drop_pickup(_repair_pool, at)


func drop_fire_control(at: Vector2) -> void:
	drop_pickup(_fire_control_pool, at)


func drop_pickup(pool: ObjectPool, at: Vector2) -> void:
	var pickup: DriftPickup = pool.acquire() as DriftPickup
	if pickup != null:
		pickup.activate(at, _player)


func _on_player_destroyed() -> void:
	await get_tree().create_timer(mission_failed_delay).timeout
	_mission_failed.show_screen()

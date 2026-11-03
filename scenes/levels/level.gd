class_name Level
extends Node2D
## Runs one sector: the wave director sends enemies, this spawns them, handles drops, death and
## SECTOR CLEAR. Which sector comes from GameState, so the same scene plays every sector.

## Sectors of the run, in order (data/levels/). After the last one it loops until the boss exists (Step 16).
@export var sectors: Array[LevelData] = []
## Off in test scenes that spawn enemies by hand.
@export var run_waves: bool = true
## Chance (0-1) that any destroyed enemy drops a timed Fire Control pickup (DESIGN.md §7.3).
@export_range(0.0, 1.0) var fire_control_drop_chance: float = 0.03
## Lets the death splash play out before the failure screen appears.
@export var mission_failed_delay: float = 1.0

var _level_data: LevelData
var _player_dead: bool = false

@onready var _enemies: Node2D = $Enemies
@onready var _wave_director: WaveDirector = $WaveDirector
@onready var _sector_clear: SectorClearScreen = $SectorClear
@onready var _sector_banner: SectorBanner = $SectorBanner
@onready var _ground_layer: BackgroundLayer = $GroundLayer
@onready var _enemy_round_pool: RoundPool = $EnemyRoundPool
@onready var _explosion_pool: ExplosionPool = $FX/ExplosionPool
@onready var _salvage_pool: SalvagePool = $SalvagePool
@onready var _repair_pool: ObjectPool = $RepairPool
@onready var _fire_control_pool: ObjectPool = $FireControlPool
@onready var _player: Player = $Player
@onready var _mission_failed: MissionFailedScreen = $MissionFailed


func _ready() -> void:
	if not GameState.run_active:
		GameState.reset_run()
	_player.destroyed.connect(_on_player_destroyed)
	_sector_clear.continue_pressed.connect(_on_continue_pressed)
	if not run_waves or sectors.is_empty():
		return
	_level_data = sectors[GameState.sector_index % sectors.size()]
	_sector_banner.show_banner(_level_data.sector_number)
	_wave_director.level_data = _level_data
	_wave_director.enemies = _enemies
	_wave_director.spawn_requested.connect(_on_spawn_requested)
	_wave_director.sector_cleared.connect(_on_sector_cleared)


func _on_spawn_requested(scene: PackedScene, at: Vector2, elite: bool) -> void:
	spawn_enemy(scene, at, elite)


func _on_sector_cleared() -> void:
	if _player_dead:
		return
	_sector_clear.show_screen(_level_data.sector_number)


func _on_continue_pressed() -> void:
	GameState.advance_sector()
	# Same scene, next sector's data. Nothing on screen carries over; the run does.
	get_tree().reload_current_scene()


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
	_player_dead = true
	await get_tree().create_timer(mission_failed_delay).timeout
	_mission_failed.show_screen()

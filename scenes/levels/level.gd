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
## Salvage lost for each enemy aircraft that gets away.
@export var escape_penalty: int = 2
## Salvage awarded at SECTOR CLEAR if no aircraft got away all sector.
@export var perimeter_bonus: int = 25

var _level_data: LevelData
var _player_dead: bool = false
var _breaches: int = 0

@onready var _enemies: Node2D = $Enemies
@onready var _wave_director: WaveDirector = $WaveDirector
@onready var _sector_clear: SectorClearScreen = $SectorClear
@onready var _sector_banner: SectorBanner = $SectorBanner
@onready var _hud: Hud = $Hud
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _ground_layer: BackgroundLayer = $GroundLayer
@onready var _enemy_round_pool: RoundPool = $EnemyRoundPool
@onready var _explosion_pool: ExplosionPool = $FX/ExplosionPool
@onready var _salvage_pool: SalvagePool = $SalvagePool
@onready var _repair_pool: ObjectPool = $RepairPool
@onready var _fire_control_pool: ObjectPool = $FireControlPool
@onready var _module_pool: ObjectPool = $ModulePool
@onready var _player: Player = $Player
@onready var _mission_failed: MissionFailedScreen = $MissionFailed


## Before any child's _ready, so the Player and HUD start from the fresh run, not the old one.
func _enter_tree() -> void:
	if not GameState.run_active:
		GameState.reset_run()


func _ready() -> void:
	_player.destroyed.connect(_on_player_destroyed)
	_player.meltdown_pulse.connect(_on_meltdown_pulse)
	_sector_clear.continue_pressed.connect(_on_continue_pressed)
	_hud.player = _player
	if not run_waves or sectors.is_empty():
		return
	_level_data = sectors[GameState.sector_index % sectors.size()]
	_hud.sector_number = _level_data.sector_number
	_sector_banner.show_banner(_level_data.sector_number)
	_wave_director.level_data = _level_data
	_hud.wave_director = _wave_director
	_wave_director.enemies = _enemies
	_wave_director.spawn_requested.connect(_on_spawn_requested)
	_wave_director.sector_cleared.connect(_on_sector_cleared)


func _on_spawn_requested(scene: PackedScene, at: Vector2, elite: bool) -> void:
	spawn_enemy(scene, at, elite)


func _on_sector_cleared() -> void:
	if _player_dead:
		return
	_pause_menu.allowed = false
	_player.dissolve_module()
	var bonus: int = perimeter_bonus if _breaches == 0 else 0
	GameState.award_salvage(bonus)
	_sector_clear.show_screen(_level_data.sector_number, _breaches, bonus)


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
	enemy.escaped.connect(_on_enemy_escaped)
	_enemies.add_child(enemy)
	return enemy


func _on_enemy_destroyed(enemy: Enemy) -> void:
	_explosion_pool.spawn(enemy.global_position)
	_salvage_pool.spawn_burst(enemy.global_position, enemy.salvage_value())
	if enemy.elite:
		GameState.add_overclock(GameState.OVERCLOCK_PER_ELITE)
		if enemy.data.module != null:
			drop_module(enemy.data.module, enemy.global_position)
	if randf() < enemy.data.repair_drop_chance:
		drop_pickup(_repair_pool, enemy.global_position)
	if randf() < fire_control_drop_chance:
		drop_pickup(_fire_control_pool, enemy.global_position + Vector2(0.0, -12.0))


func _on_enemy_escaped(_enemy: Enemy) -> void:
	if _player_dead:
		return
	_breaches += 1
	GameState.lose_salvage(escape_penalty)


## Overclock's Meltdown pulse: every enemy round in the circle becomes a salvage pickup.
func _on_meltdown_pulse(center: Vector2, radius: float) -> void:
	for child: Node in _enemy_round_pool.get_children():
		var enemy_round: EnemyRound = child as EnemyRound
		if enemy_round.is_active() and enemy_round.global_position.distance_to(center) <= radius:
			var at: Vector2 = enemy_round.global_position
			enemy_round.deactivate()
			_salvage_pool.spawn_burst(at, 1)


func drop_repair(at: Vector2) -> void:
	drop_pickup(_repair_pool, at)


func drop_fire_control(at: Vector2) -> void:
	drop_pickup(_fire_control_pool, at)


## Elites always drop their weapon module (DESIGN.md §5.8).
func drop_module(module: ModuleData, at: Vector2) -> void:
	var pickup: ModulePickup = _module_pool.acquire() as ModulePickup
	if pickup == null:
		return
	pickup.module = module
	pickup.activate(at, _player)


func drop_pickup(pool: ObjectPool, at: Vector2) -> void:
	var pickup: DriftPickup = pool.acquire() as DriftPickup
	if pickup != null:
		pickup.activate(at, _player)


func _on_player_destroyed() -> void:
	_player_dead = true
	_pause_menu.allowed = false
	await get_tree().create_timer(mission_failed_delay).timeout
	_mission_failed.show_screen()

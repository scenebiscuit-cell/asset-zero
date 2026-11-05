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
## Every this many enemies destroyed drops a repair kit (counts carry over between sectors).
@export var kills_per_repair: int = 20
## Armor restored by that kill-count repair kit.
@export var kill_repair_amount: int = 20
## Armor restored by repair kits that enemies drop by chance (Armored Transport).
@export var enemy_repair_amount: int = 25
## Saturation Strike (DESIGN.md §7.4): damage to every enemy in the play area. High enough to
## destroy anything but a boss.
@export var strike_damage: int = 600
## Extra explosions scattered over the screen for show, and the gap between them.
@export var strike_blasts: int = 14
@export var strike_blast_gap: float = 0.035
## Destructible radar dome placed on the background's barracks and SAM sites.
@export var dome_scene: PackedScene

var _level_data: LevelData
var _player_dead: bool = false
var _breaches: int = 0
## True while a strike is dealing its damage, so its own kills don't refill the strike meter.
var _striking: bool = false

@onready var _enemies: Node2D = $Enemies
## Background targets live apart from Enemies, so they never hold up SECTOR CLEAR or wave spawning.
@onready var _ground_targets: Node2D = $GroundTargets
@onready var _wave_director: WaveDirector = $WaveDirector
@onready var _sector_clear: SectorClearScreen = $SectorClear
@onready var _field_refit: FieldRefitScreen = $FieldRefit
@onready var _armory: ArmoryScreen = $Armory
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
@onready var _strike_flash: StrikeFlash = $StrikeFlash


## Before any child's _ready, so the Player and HUD start from the fresh run, not the old one.
func _enter_tree() -> void:
	if not GameState.run_active:
		GameState.reset_run()


func _ready() -> void:
	_player.destroyed.connect(_on_player_destroyed)
	_player.meltdown_pulse.connect(_on_meltdown_pulse)
	_player.strike_called.connect(_on_strike_called)
	_sector_clear.continue_pressed.connect(_on_continue_pressed)
	_field_refit.finished.connect(_on_field_refit_finished)
	_armory.finished.connect(_on_armory_finished)
	_hud.player = _player
	_player.play_area_bottom = _hud.console_top()
	Enemy.play_area_bottom = _hud.console_top()
	_ground_layer.dome_entering.connect(_on_dome_entering)
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


## Between sectors (DESIGN.md §7.1): Field Refit, then the Armory, then the next sector.
func _on_continue_pressed() -> void:
	# Advance first, so the dissolved module is already gone from the loadout the refit screen shows.
	GameState.advance_sector()
	_sector_clear.visible = false
	_field_refit.open(_level_data.sector_number)


func _on_field_refit_finished() -> void:
	_armory.open(_level_data.sector_number)


func _on_armory_finished() -> void:
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


func _on_dome_entering(at: Vector2) -> void:
	if dome_scene == null:
		return
	var dome: Enemy = dome_scene.instantiate() as Enemy
	dome.position = at
	dome.ground_speed = _ground_layer.scroll_speed
	dome.destroyed.connect(_on_ground_target_destroyed)
	_ground_targets.add_child(dome)


## Background targets only pay salvage: no Fire Control or repair rolls.
func _on_ground_target_destroyed(target: Enemy) -> void:
	_explosion_pool.spawn(target.global_position)
	_salvage_pool.spawn_burst(target.global_position, target.salvage_value())


func _on_enemy_destroyed(enemy: Enemy) -> void:
	_explosion_pool.spawn(enemy.global_position)
	_salvage_pool.spawn_burst(enemy.global_position, enemy.salvage_value())
	if enemy.elite:
		GameState.add_overclock(GameState.OVERCLOCK_PER_ELITE)
		if enemy.data.module != null:
			drop_module(enemy.data.module, enemy.global_position)
	if randf() < enemy.data.repair_drop_chance:
		drop_repair(enemy.global_position, enemy_repair_amount)
	if not _striking:
		_player.register_kill()
	GameState.kills_toward_repair += 1
	if GameState.kills_toward_repair >= kills_per_repair:
		GameState.kills_toward_repair = 0
		drop_repair(enemy.global_position + Vector2(12.0, 0.0), kill_repair_amount)
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


## Clears the screen: every enemy round is gone and every enemy in the play area takes heavy damage.
func _on_strike_called() -> void:
	_strike_flash.play()
	AudioManager.play("strike", -2.0)
	for child: Node in _enemy_round_pool.get_children():
		var enemy_round: EnemyRound = child as EnemyRound
		if enemy_round.is_active():
			enemy_round.deactivate()
	_striking = true
	for container: Node in [_enemies, _ground_targets]:
		for child: Node in container.get_children():
			var enemy: Enemy = child as Enemy
			if enemy != null and enemy.hp > 0 and enemy.is_on_screen() and enemy.is_targetable():
				enemy.take_damage(strike_damage)
	_striking = false
	_strike_barrage()


## Purely visual: blasts ripple up the screen after the flash.
func _strike_barrage() -> void:
	var area: Vector2 = Vector2(get_viewport_rect().size.x, _hud.console_top())
	for i: int in strike_blasts:
		var row: float = 1.0 - (float(i) + randf()) / strike_blasts
		_explosion_pool.spawn(Vector2(randf_range(40.0, area.x - 40.0), lerpf(60.0, area.y - 30.0, row)))
		await get_tree().create_timer(strike_blast_gap).timeout


func drop_repair(at: Vector2, amount: int = 25) -> void:
	var pickup: RepairPickup = _repair_pool.acquire() as RepairPickup
	if pickup == null:
		return
	# Pooled kits are shared by both drop kinds, so the amount is set on every drop.
	pickup.repair_amount = amount
	pickup.activate(at, _player)


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

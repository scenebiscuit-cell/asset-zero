class_name ShipSystems
extends Node2D
## Runs XF-0's Engine and Hull refits (DESIGN.md §6): Propulsion speed, Plating recharge, and the
## last-level perks (Razor Wing, Vector Dash, Reactive Armor, Nanite Repair). Reads what's
## installed from GameState; the Player asks it for speed and tells it about hits.

## Enemies hit by Razor Wing: air only, since the ship flies over ground units.
const ENEMIES_AIR: int = 1 << 2
const DIRECTIONS: Dictionary[String, Vector2] = {
	"move_left": Vector2.LEFT, "move_right": Vector2.RIGHT, "move_up": Vector2.UP, "move_down": Vector2.DOWN,
}

@export_group("Razor Wing")
@export var razor_damage: int = 12
## Seconds between razor hits on everything the wings touch.
@export var razor_tick: float = 0.1
@export_group("Vector Dash")
## Second tap of the same direction within this many seconds dashes.
@export var dash_window: float = 0.25
@export var dash_distance: float = 120.0
@export var dash_time: float = 0.14
@export var dash_cooldown: float = 0.7
## Invulnerable for the dash plus this long after it.
@export var dash_grace: float = 0.1
@export_group("Reactive Armor")
@export var shrapnel_count: int = 16
@export var shrapnel_damage: int = 12
@export var shrapnel_speed: float = 560.0
@export var shrapnel_range: float = 300.0
@export var shrapnel_tint: Color = Color(1.0, 0.75, 0.45)
@export_group("Nanite Repair")
## Armor per second, only while Armor is below nanite_cap of max.
@export var nanite_rate: float = 0.7
@export var nanite_cap: float = 0.5

var _player: Player
var _propulsion: SystemRefitData
var _armor: SystemRefitData
var _plating_wait: float = 0.0
var _plating_carry: float = 0.0
var _nanite_carry: float = 0.0
var _razor_left: float = 0.0
var _dash_left: float = 0.0
var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_cooldown_left: float = 0.0
var _invulnerable_left: float = 0.0
var _last_tap: Dictionary[String, int] = {}

@onready var _razor_area: Area2D = $RazorArea
@onready var _plating_shield: PlatingShield = $Visual/PlatingShield
@onready var _nanites: NaniteDrones = $Visual/NaniteDrones


func _ready() -> void:
	_player = get_parent() as Player
	_razor_area.collision_mask = ENEMIES_AIR
	refresh()
	# Each sector starts with full Plating.
	GameState.plating = GameState.max_plating


## Re-reads the installed refits. Called at the start of each sector (and by tests).
func refresh() -> void:
	_propulsion = GameState.system_refit(RefitData.Line.PROPULSION)
	_armor = GameState.system_refit(RefitData.Line.ARMOR)
	_razor_area.monitoring = GameState.has_perk(SystemRefitData.Perk.RAZOR_WING)


## Gunship-form speed multiplier from Propulsion.
func speed_multiplier() -> float:
	return 1.0 + (_propulsion.speed_bonus if _propulsion != null else 0.0)


## Lance form speed (fraction of Gunship speed), or 0 to keep the default.
func lance_speed_multiplier() -> float:
	return _propulsion.lance_speed_multiplier if _propulsion != null else 0.0


func is_dashing() -> bool:
	return _dash_left > 0.0


## Razor Wing: ramming aircraft doesn't hurt XF-0 (rounds and hazards still do).
func ignores_contact() -> bool:
	return GameState.has_perk(SystemRefitData.Perk.RAZOR_WING)


## True during a Vector Dash and its short grace time: hits pass through.
func is_phased() -> bool:
	return _invulnerable_left > 0.0


func _physics_process(delta: float) -> void:
	_update_plating(delta)
	_update_nanites(delta)
	_update_razor(delta)
	_update_dash(delta)


## Called by the Player whenever a hit lands. `on_plating`: Plating took some of it.
func on_hit(on_plating: bool = false) -> void:
	if on_plating:
		_plating_shield.flash()
	_plating_wait = _armor.plating_recharge_delay if _armor != null else 0.0
	if GameState.has_perk(SystemRefitData.Perk.REACTIVE_ARMOR):
		_burst_shrapnel()


func _update_plating(delta: float) -> void:
	if _armor == null or GameState.plating >= GameState.max_plating:
		return
	if _plating_wait > 0.0:
		_plating_wait -= delta
		return
	_plating_carry += _armor.plating_recharge_rate * delta
	var whole: int = floori(_plating_carry)
	if whole > 0:
		_plating_carry -= whole
		GameState.plating = mini(GameState.plating + whole, GameState.max_plating)


func _update_nanites(delta: float) -> void:
	if not GameState.has_perk(SystemRefitData.Perk.NANITE_REPAIR):
		_nanites.active = false
		return
	var cap: int = floori(GameState.max_armor * nanite_cap)
	_nanites.active = GameState.armor > 0 and GameState.armor < cap
	if not _nanites.active:
		_nanite_carry = 0.0
		return
	_nanite_carry += nanite_rate * delta
	if _nanite_carry >= 1.0:
		_nanite_carry -= 1.0
		GameState.armor = mini(GameState.armor + 1, cap)


func _update_razor(delta: float) -> void:
	if not _razor_area.monitoring:
		return
	_razor_left -= delta
	if _razor_left > 0.0:
		return
	_razor_left = razor_tick
	for area: Area2D in _razor_area.get_overlapping_areas():
		var enemy: Enemy = area as Enemy
		if enemy != null and enemy.hp > 0:
			enemy.take_damage(razor_damage)


## Vector Dash: double-tap a direction key, or press the dash button. The Player moves by dash_offset() while it runs.
func _update_dash(delta: float) -> void:
	_dash_cooldown_left -= delta
	_invulnerable_left -= delta
	if _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			_player.set_liquid(false)
	if not GameState.has_perk(SystemRefitData.Perk.VECTOR_DASH):
		return
	# Gamepad: the dash button dashes the way the ship is moving, or forward when still.
	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0:
		var moving: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_start_dash(moving.normalized() if moving.length() > 0.3 else Vector2.UP)


## Keyboard double-tap. Only real key presses count: a gamepad stick crosses its deadzone over and
## over while steering, and would dash by accident (gamepad players have the dash button).
func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or not GameState.has_perk(SystemRefitData.Perk.VECTOR_DASH):
		return
	for action: String in DIRECTIONS:
		if not key.is_action_pressed(action):
			continue
		var now: int = Time.get_ticks_msec()
		var last: int = _last_tap.get(action, -100000)
		_last_tap[action] = now
		if now - last <= dash_window * 1000.0 and _dash_cooldown_left <= 0.0 and not get_tree().paused:
			_start_dash(DIRECTIONS[action])
			_last_tap[action] = -100000


func _start_dash(direction: Vector2) -> void:
	_dash_velocity = direction * dash_distance / dash_time
	_dash_left = dash_time
	_dash_cooldown_left = dash_cooldown
	_invulnerable_left = dash_time + dash_grace
	_player.set_liquid(true, direction)
	AudioManager.play("morph_to_lance", -6.0)


## Extra movement this frame from a running dash.
func dash_offset(delta: float) -> Vector2:
	return _dash_velocity * delta if _dash_left > 0.0 else Vector2.ZERO


## Reactive Armor: a ring of shrapnel rounds blasts outward from the hull.
func _burst_shrapnel() -> void:
	if _player.round_pool == null:
		return
	var offset: float = randf() * TAU
	for i: int in shrapnel_count:
		var direction: Vector2 = Vector2.from_angle(offset + TAU * i / shrapnel_count)
		var shard: PlayerRound = _player.round_pool.fire(global_position, direction * shrapnel_speed,
				shrapnel_damage, shrapnel_tint) as PlayerRound
		if shard == null:
			return
		shard.range_left = shrapnel_range
		shard.set_length(0.9)

class_name Hud
extends CanvasLayer
## Gameplay HUD (DESIGN.md §11.6/§13): side rails, Armor/Plating top-left, salvage top-centre,
## sector/class/threat top-right, strike meter in the left rail, sector track in the right rail. The bottom
## console holds the module slot, weapons, Saturation Strike charges, Fire Control and Overclock.
## Reads GameState and the Player each frame; nothing in the game needs to know the HUD exists.

## Below this fraction of max Armor, the bar turns red and the warning shows.
@export var armor_warning_fraction: float = 0.25
@export var blink_speed: float = 6.0

const WEIGHT_KEYS: Array[String] = ["CLASS_LIGHT", "CLASS_MEDIUM", "CLASS_HEAVY", "CLASS_ASSAULT"]
const THREAT_KEYS: Array[String] = ["THREAT_LOW", "THREAT_ELEVATED", "THREAT_HIGH", "THREAT_SEVERE"]
const THREAT_COLORS: Array[Color] = [Color(0.55, 1.0, 0.6), Color(1.0, 0.85, 0.3), Color(1.0, 0.55, 0.2), Color(1.0, 0.25, 0.2)]
const AMBER: Color = Color(1.0, 0.7, 0.2)
const WARNING_RED: Color = Color(1.0, 0.25, 0.2)
const OVERCLOCK_HOT: Color = Color(1.0, 0.45, 0.1)
const STRIKE_RED: Color = Color(1.0, 0.4, 0.3)
const PIP_EMPTY: Color = Color(1.0, 1.0, 1.0, 0.12)
const DIM_TEXT: Color = Color(1.0, 1.0, 1.0, 0.35)

## Set by the Level.
var player: Player
var sector_number: int = 1
## Set by the Level when waves are running; the progress track stays hidden without it.
var wave_director: WaveDirector

var _time: float = 0.0
# Last values written, so labels only rebuild their text when something changed.
var _shown_salvage: int = -1
var _shown_armor: int = -1
var _shown_sector: int = -1
var _shown_class: int = -1
var _shown_threat: int = -1
var _shown_fire_control: Vector2i = Vector2i(-9, -9)
var _shown_overclock_secs: int = -1
var _shown_strike: Vector2i = Vector2i(-1, -1)

@onready var _console: Control = $Root/Console
@onready var _top_console: Control = $Root/TopConsole
@onready var _armor_bar: HudBar = $Root/TopLeft/ArmorBar
@onready var _armor_value: Label = $Root/TopLeft/ArmorValue
@onready var _plating_bar: HudBar = $Root/TopLeft/PlatingBar
@onready var _salvage_value: Label = $Root/TopCenter/SalvageValue
@onready var _sector_label: Label = $Root/TopRight/Sector
@onready var _class_label: Label = $Root/TopRight/WeightClass
@onready var _threat_label: Label = $Root/TopRight/Threat
@onready var _module_label: Label = $Root/BottomLeft/ModuleLabel
@onready var _module_icon: WeaponIcon = $Root/BottomLeft/ModuleSlot/ModuleIcon
@onready var _overclock_bar: HudBar = $Root/BottomRight/OverclockBar
@onready var _overclock_state: Label = $Root/BottomRight/OverclockState
@onready var _warning: Label = $Root/BottomCenter/Warning
@onready var _fire_control_state: Label = $Root/FireControl/State
@onready var _fire_control_bar: HudBar = $Root/FireControl/Bar
@onready var _sector_progress: SectorProgress = $Root/SectorProgress
@onready var _strike_meter: StrikeMeter = $Root/StrikeMeter
@onready var _strike_state: Label = $Root/Strike/State
@onready var _strike_pips: Array[ColorRect] = [$Root/Strike/Pip1, $Root/Strike/Pip2, $Root/Strike/Pip3]
@onready var _nose_icon: WeaponIcon = $Root/Weapons/NoseIcon
@onready var _nose_name: Label = $Root/Weapons/NoseName
@onready var _pylon_icon: WeaponIcon = $Root/Weapons/PylonIcon
@onready var _pylon_name: Label = $Root/Weapons/PylonName


func _ready() -> void:
	_warning.text = tr("WARN_ARMOR_CRITICAL")


func _process(delta: float) -> void:
	_time += delta
	var blink_on: bool = fmod(_time * blink_speed, 2.0) < 1.0
	_update_armor(blink_on)
	_plating_bar.value = 0.0 if GameState.max_plating <= 0 else float(GameState.plating) / GameState.max_plating
	_update_salvage()
	_sector_progress.visible = wave_director != null
	if wave_director != null:
		_sector_progress.value = wave_director.progress()
	_update_status()
	_update_module()
	_update_overclock(blink_on)
	_update_fire_control(blink_on)
	_update_strike(blink_on)
	_update_weapon(_nose_icon, _nose_name, WeaponData.Hardpoint.NOSE)
	_update_weapon(_pylon_icon, _pylon_name, WeaponData.Hardpoint.WING_PYLONS)


func _update_armor(blink_on: bool) -> void:
	var fraction: float = float(GameState.armor) / maxi(GameState.max_armor, 1)
	_armor_bar.value = fraction
	var critical: bool = GameState.armor > 0 and fraction <= armor_warning_fraction
	_armor_bar.tint = WARNING_RED if critical else Color(0.0, 0.0, 0.0, 0.0)
	_warning.visible = critical and blink_on
	if GameState.armor != _shown_armor:
		_shown_armor = GameState.armor
		_armor_value.text = "%03d" % GameState.armor


func _update_salvage() -> void:
	if GameState.salvage == _shown_salvage:
		return
	_shown_salvage = GameState.salvage
	_salvage_value.text = "%08d" % GameState.salvage


func _update_status() -> void:
	if sector_number != _shown_sector:
		_shown_sector = sector_number
		_sector_label.text = tr("SECTOR_START") % sector_number
	if GameState.weight_class != _shown_class:
		_shown_class = GameState.weight_class
		_class_label.text = tr(WEIGHT_KEYS[GameState.weight_class])
	if GameState.threat_level != _shown_threat:
		_shown_threat = GameState.threat_level
		var index: int = clampi(GameState.threat_level - 1, 0, THREAT_KEYS.size() - 1)
		_threat_label.text = tr(THREAT_KEYS[index])
		_threat_label.add_theme_color_override("font_color", THREAT_COLORS[index])


func _update_overclock(blink_on: bool) -> void:
	if player != null and player.is_overclocked():
		var left: float = player.overclock_time_left()
		_overclock_bar.value = left / player.overclock_max_time()
		_overclock_bar.tint = OVERCLOCK_HOT
		var secs: int = ceili(left)
		if secs != _shown_overclock_secs:
			_shown_overclock_secs = secs
			_overclock_state.text = tr("HUD_OVERCLOCK_ACTIVE") % secs
		_overclock_state.visible = true
		return
	_shown_overclock_secs = -1
	_overclock_bar.value = GameState.overclock / GameState.OVERCLOCK_MAX
	var full: bool = GameState.is_overclock_full()
	_overclock_bar.tint = Color.WHITE if full and blink_on else Color(0.0, 0.0, 0.0, 0.0)
	_overclock_state.text = tr("HUD_OVERCLOCK_READY")
	_overclock_state.visible = full and blink_on


## Always in the console; dimmed to "EMPTY" with nothing stored.
func _update_fire_control(blink_on: bool) -> void:
	# x: -1 always on (FC-1 or accessibility), 0 off, >0 seconds left. y: stored charges.
	var seconds: int = 0
	var left: float = 0.0
	if player != null:
		left = player.autofire_time_left()
		if player.autofire:
			seconds = -1
		elif left > 0.0:
			seconds = ceili(left)
	var charges: int = GameState.fire_control_charges
	var empty: bool = seconds == 0 and charges == 0
	_fire_control_bar.value = 0.0 if empty else (left / player.fire_control_duration if seconds > 0 else 1.0)
	# While waiting to be used, the prompt blinks so it gets noticed.
	_fire_control_state.visible = empty or seconds != 0 or blink_on
	var state: Vector2i = Vector2i(seconds, charges)
	if state == _shown_fire_control:
		return
	_shown_fire_control = state
	_fire_control_state.add_theme_color_override("font_color", DIM_TEXT if empty else Color.WHITE)
	if empty:
		_fire_control_state.text = tr("HUD_EMPTY")
	elif seconds == -1:
		_fire_control_state.text = tr("HUD_AUTOFIRE_ON")
	elif seconds > 0:
		_fire_control_state.text = tr("HUD_AUTOFIRE_TIMED") % seconds
	elif charges > 1:
		_fire_control_state.text = tr("HUD_FIRE_CONTROL_READY_MULTI") % charges
	else:
		_fire_control_state.text = tr("HUD_FIRE_CONTROL_READY")


## Left-rail meter fills with kills; pips show stored charges; the prompt blinks while one is ready.
func _update_strike(blink_on: bool) -> void:
	if player == null:
		return
	var charges: int = GameState.strike_charges
	var full: bool = charges >= player.max_strike_charges
	_strike_meter.value = player.strike_fill()
	_strike_meter.flash = full and blink_on
	for i: int in _strike_pips.size():
		_strike_pips[i].visible = i < player.max_strike_charges
		_strike_pips[i].color = STRIKE_RED if i < charges else PIP_EMPTY
	_strike_state.visible = charges == 0 or blink_on
	var state: Vector2i = Vector2i(charges, GameState.strike_progress)
	if state == _shown_strike:
		return
	_shown_strike = state
	if charges > 0:
		_strike_state.text = tr("HUD_STRIKE_READY")
		_strike_state.add_theme_color_override("font_color", Color.WHITE)
	else:
		_strike_state.text = tr("HUD_STRIKE_PROGRESS") % [GameState.strike_progress, player.kills_per_strike]
		_strike_state.add_theme_color_override("font_color", DIM_TEXT)


## The icon remembers what it shows, so the name is only rebuilt when the weapon changes.
## (The scene starts every name as "—", which matches an empty hardpoint.)
func _update_weapon(icon: WeaponIcon, label: Label, hardpoint: WeaponData.Hardpoint) -> void:
	var weapon: WeaponData = GameState.weapons.get(hardpoint, null) as WeaponData
	if weapon == icon.weapon:
		return
	icon.weapon = weapon
	label.text = "—" if weapon == null else tr(weapon.name_key)


## The slot shows the module's icon, and its name replaces the MODULE header while one is mounted.
func _update_module() -> void:
	var module: ModuleData = GameState.assimilated_module()
	if module == _module_icon.weapon:
		return
	_module_icon.weapon = module
	_module_label.text = tr("HUD_MODULE") if module == null else tr(module.name_key)


## Top edge of the bottom console: the play area ends here, so the HUD never covers the ship.
func console_top() -> float:
	return _console.position.y


## Bottom edge of the top console: the play area starts here.
func top_console_bottom() -> float:
	return _top_console.position.y + _top_console.size.y

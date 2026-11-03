class_name Hud
extends CanvasLayer
## Gameplay HUD (DESIGN.md §11.6/§13): side rails, Armor/Plating top-left, salvage top-centre,
## sector/class/threat top-right, module slot bottom-left, Overclock bottom-right, warnings bottom-centre.
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

## Set by the Level.
var player: Player
var sector_number: int = 1

var _time: float = 0.0
# Last values written, so labels only rebuild their text when something changed.
var _shown_salvage: int = -1
var _shown_armor: int = -1
var _shown_sector: int = -1
var _shown_class: int = -1
var _shown_threat: int = -1
var _shown_autofire: int = -2
var _shown_overclock_secs: int = -1

@onready var _armor_bar: HudBar = $Root/TopLeft/ArmorBar
@onready var _armor_value: Label = $Root/TopLeft/ArmorValue
@onready var _plating_bar: HudBar = $Root/TopLeft/PlatingBar
@onready var _salvage_value: Label = $Root/TopCenter/SalvageValue
@onready var _sector_label: Label = $Root/TopRight/Sector
@onready var _class_label: Label = $Root/TopRight/WeightClass
@onready var _threat_label: Label = $Root/TopRight/Threat
@onready var _module_value: Label = $Root/BottomLeft/ModuleSlot/ModuleValue
@onready var _overclock_bar: HudBar = $Root/BottomRight/OverclockBar
@onready var _overclock_state: Label = $Root/BottomRight/OverclockState
@onready var _warning: Label = $Root/BottomCenter/Warning
@onready var _autofire: Label = $Root/BottomCenter/AutoFire


func _ready() -> void:
	_warning.text = tr("WARN_ARMOR_CRITICAL")


func _process(delta: float) -> void:
	_time += delta
	var blink_on: bool = fmod(_time * blink_speed, 2.0) < 1.0
	_update_armor(blink_on)
	_plating_bar.value = 0.0 if GameState.max_plating <= 0 else float(GameState.plating) / GameState.max_plating
	_update_salvage()
	_update_status()
	_module_value.text = "—" if GameState.assimilated_module == null else GameState.assimilated_module.resource_name
	_update_overclock(blink_on)
	_update_autofire()


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


func _update_autofire() -> void:
	# -1 = always on (FC-1 or accessibility), 0 = off, >0 = seconds left on a pickup.
	var state: int = 0
	if player != null:
		if player.autofire:
			state = -1
		elif player.autofire_time_left() > 0.0:
			state = ceili(player.autofire_time_left())
	if state == _shown_autofire:
		return
	_shown_autofire = state
	_autofire.visible = state != 0
	_autofire.text = tr("HUD_AUTOFIRE_ON") if state == -1 else tr("HUD_AUTOFIRE_TIMED") % state

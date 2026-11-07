class_name CombatMorph
extends Node
## Combat Morph (DESIGN.md §5.6): hold `morph` for Thresher form, release to flow back to Gunship form.
## Owns the two shapes and the timing; the Player applies the speed, damage and fire-pattern changes.

signal form_changed(is_thresher: bool)

## Base shapes per weight class plus refit overlays; rebuilt when the loadout changes.
@export var airframes: AirframeSet
@export var morph_time: float = 0.22
@export var thresher_speed_multiplier: float = 0.55
@export var thresher_damage_multiplier: float = 1.4
## The price of Thresher form's firepower: hits on XF-0 do this much more, Plating included.
## 3.0 = three standard 12-damage rounds kill a full-Armor Light airframe.
@export var thresher_damage_taken_multiplier: float = 3.0
@export var morph_system_path: NodePath = ^"../MorphSystem"

var is_thresher: bool = false

var _gunship_shape: AirframeShape
var _thresher_shape: AirframeShape

@onready var _morph_system: MorphSystem = get_node(morph_system_path)


func _ready() -> void:
	rebuild()
	_morph_system.snap_to(_gunship_shape)


## Re-reads the loadout (weight class, refits, weapons) into both forms' shapes. Doesn't morph.
func rebuild() -> void:
	_gunship_shape = airframes.build(false)
	_thresher_shape = airframes.build(true)


func gunship_shape() -> AirframeShape:
	return _gunship_shape


func _physics_process(_delta: float) -> void:
	# Polled, not event-driven, so a held button survives focus changes and the Mission Failed restart.
	var want_thresher: bool = Input.is_action_pressed("morph")
	if want_thresher != is_thresher:
		set_form(want_thresher)


func set_form(thresher: bool) -> void:
	is_thresher = thresher
	_morph_system.morph_to(current_shape(), morph_time)
	AudioManager.play("morph_to_thresher" if thresher else "morph_to_gunship")
	form_changed.emit(thresher)


func current_shape() -> AirframeShape:
	return _thresher_shape if is_thresher else _gunship_shape


func speed_multiplier() -> float:
	return thresher_speed_multiplier if is_thresher else 1.0


func damage_multiplier() -> float:
	return thresher_damage_multiplier if is_thresher else 1.0


func damage_taken_multiplier() -> float:
	return thresher_damage_taken_multiplier if is_thresher else 1.0

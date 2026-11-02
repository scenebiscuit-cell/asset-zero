class_name CombatMorph
extends Node
## Combat Morph (DESIGN.md §5.6): hold `morph` for Lance form, release to flow back to Gunship form.
## Owns the two shapes and the timing; the Player applies the speed, damage and fire-pattern changes.

signal form_changed(is_lance: bool)

@export var gunship_shape: AirframeShape
@export var lance_shape: AirframeShape
@export var morph_time: float = 0.15
@export var lance_speed_multiplier: float = 0.55
@export var lance_damage_multiplier: float = 1.4
@export var morph_system_path: NodePath = ^"../MorphSystem"

var is_lance: bool = false

@onready var _morph_system: MorphSystem = get_node(morph_system_path)


func _ready() -> void:
	_morph_system.snap_to(gunship_shape)


func _physics_process(_delta: float) -> void:
	# Polled, not event-driven, so a held button survives focus changes and the Mission Failed restart.
	var want_lance: bool = Input.is_action_pressed("morph")
	if want_lance != is_lance:
		set_form(want_lance)


func set_form(lance: bool) -> void:
	is_lance = lance
	_morph_system.morph_to(current_shape(), morph_time)
	AudioManager.play("morph_to_lance" if lance else "morph_to_gunship")
	form_changed.emit(lance)


func current_shape() -> AirframeShape:
	return lance_shape if is_lance else gunship_shape


func speed_multiplier() -> float:
	return lance_speed_multiplier if is_lance else 1.0


func damage_multiplier() -> float:
	return lance_damage_multiplier if is_lance else 1.0

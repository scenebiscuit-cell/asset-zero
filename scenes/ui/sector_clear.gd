class_name SectorClearScreen
extends CanvasLayer
## Shown when a sector is cleared. Any key or click moves on to the next sector.
## (The Field Refit and Armory screens slot in here in Steps 12–13.)

signal continue_pressed

## Gives the moment a beat before input is accepted, so a held fire key can't skip it.
@export var input_delay: float = 1.2

var _accepting_input: bool = false

@onready var _title: Label = $Lines/Title
@onready var _hint: Label = $Lines/Hint
@onready var _result: Label = $Lines/Result


func _ready() -> void:
	visible = false


## `breaches` = enemy aircraft that got away; `bonus` = salvage paid for holding the perimeter.
func show_screen(sector_number: int, breaches: int = 0, bonus: int = 0) -> void:
	_title.text = tr("SECTOR_CLEAR") % sector_number
	if breaches == 0:
		_result.text = tr("CLEAR_PERIMETER_HELD") % bonus
		_result.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	else:
		_result.text = tr("CLEAR_BREACHES") % breaches
		_result.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	_hint.visible = false
	visible = true
	await get_tree().create_timer(input_delay).timeout
	_hint.visible = true
	_accepting_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_input:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo():
		_accepting_input = false
		continue_pressed.emit()

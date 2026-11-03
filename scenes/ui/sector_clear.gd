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


func _ready() -> void:
	visible = false


func show_screen(sector_number: int) -> void:
	_title.text = tr("SECTOR_CLEAR") % sector_number
	_hint.visible = false
	visible = true
	await get_tree().create_timer(input_delay).timeout
	_hint.visible = true
	_accepting_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_input:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		_accepting_input = false
		continue_pressed.emit()

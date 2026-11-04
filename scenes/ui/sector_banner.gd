class_name SectorBanner
extends CanvasLayer
## Short "SECTOR 1" callout when a sector starts. Fades in, holds, fades out. Doesn't block input.

@export var fade_time: float = 0.4
@export var hold_time: float = 1.6

@onready var _lines: Control = $Lines
@onready var _title: Label = $Lines/Title


func _ready() -> void:
	_lines.modulate.a = 0.0


func show_banner(sector_number: int) -> void:
	_title.text = tr("SECTOR_START") % sector_number
	var tween: Tween = create_tween()
	tween.tween_property(_lines, "modulate:a", 1.0, fade_time)
	tween.tween_interval(hold_time)
	tween.tween_property(_lines, "modulate:a", 0.0, fade_time)

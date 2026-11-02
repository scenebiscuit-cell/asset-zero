class_name PlayerRound
extends Round
## Player tracer round. Damages the first enemy it touches.


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not is_active():
		return
	if area is Enemy:
		(area as Enemy).take_damage(damage)
		deactivate()

class_name ReconDrone
extends Enemy
## RD-2 Recon Drone: flies straight down.


func _tick(delta: float) -> void:
	position.y += data.speed * delta

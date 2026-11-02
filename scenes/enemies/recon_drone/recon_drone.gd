class_name ReconDrone
extends Enemy
## RD-2 Recon Drone: flies straight down.


func _physics_process(delta: float) -> void:
	position.y += data.speed * delta
	if is_below_screen():
		queue_free() # Escaped: no salvage.

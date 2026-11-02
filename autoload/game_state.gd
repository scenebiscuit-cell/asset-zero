extends Node
## Data for the current run. Cleared when a new run starts.

var salvage: int = 0


func reset_run() -> void:
	salvage = 0


func add_salvage(amount: int) -> void:
	salvage += amount
	print("Salvage: ", salvage) # Temporary until the HUD exists (Step 8).

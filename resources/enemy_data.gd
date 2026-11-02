class_name EnemyData
extends Resource
## Stats for one enemy type. Stored as .tres files in data/enemies/.

@export var max_hp: int = 20
@export var speed: float = 180.0
## Number of salvage pickups dropped on death.
@export var salvage: int = 1
## Armor lost when XF-0 flies into this enemy.
@export var contact_damage: int = 20

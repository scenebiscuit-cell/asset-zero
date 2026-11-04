class_name WeaponData
extends Resource
## One weapon system level (DESIGN.md §6). Stored as .tres files in data/weapons/.
## GunData, BeamData and MissileData add the numbers each kind of weapon needs.

## The hardpoints on XF-0 (DESIGN.md §5.1). Each holds one system at a time.
enum Hardpoint { NOSE, WING_PYLONS, ENGINE, HULL, SALVAGE_MOUNT }

## Translation key for the designation, e.g. "M20 Autocannon".
@export var name_key: String = ""
@export var hardpoint: Hardpoint = Hardpoint.NOSE
## The weapon scene mounted on the hardpoint (autocannon.tscn, beam_laser.tscn, ...).
@export var scene: PackedScene
## Seconds between shots (for beams: between damage ticks; for missiles: between volleys).
@export var fire_interval: float = 0.08
## Per round, per tick or per missile, before Lance form and Overclock bonuses.
@export var damage: int = 10

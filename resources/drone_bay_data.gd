class_name DroneBayData
extends ModuleData
## Drone Bay (from the Armored Transport): two small allied drones. Gunship form: they orbit XF-0
## and shoot at the nearest enemy. Thresher form: they line up beside the nose and fire forward.
## fire_interval and damage are per drone.

@export var drone_count: int = 2
@export var orbit_radius: float = 48.0
## Radians per second.
@export var orbit_speed: float = 2.6
## Thresher form: where each drone sits, from the Salvage Mount (mirrored for the other side).
@export var thresher_offset: Vector2 = Vector2(26.0, -24.0)
## How quickly drones catch up to where they should be. Higher is snappier.
@export var follow_sharpness: float = 10.0
@export var round_speed: float = 820.0
## Gunship form: only enemies closer than this get aimed at; otherwise drones fire straight up.
@export var aim_range: float = 420.0

class_name AirframeShape
extends Resource
## One airframe silhouette as point lists (DESIGN.md §5.3). Keys are the Polygon2D node names under
## Visual/Airframe. Every form, weight class and refit is just another one of these in data/shapes/.

@export var parts: Dictionary[String, PackedVector2Array] = {}
## Where the nose weapon's muzzle sits for this shape, relative to the ship.
@export var muzzle_offset: Vector2 = Vector2(0.0, -35.0)
## Right wing pylon (secondary weapons), relative to the ship. The left one is its mirror.
@export var pylon_offset: Vector2 = Vector2(14.0, 6.0)

@export_group("Hitbox")
## Capsule over the body and wing roots (DESIGN.md §5.4). Wing tips don't count.
@export var hitbox_radius: float = 12.0
## Total capsule length, nose to tail, including the rounded ends.
@export var hitbox_height: float = 36.0
@export var hitbox_offset: Vector2 = Vector2.ZERO
## Near-miss ring for Overclock (DESIGN.md §5.4/§5.6). Must stay outside the hitbox.
@export var graze_radius: float = 28.0

class_name AirframeShape
extends Resource
## One airframe silhouette as point lists (DESIGN.md §5.3). Keys are the Polygon2D node names under
## Visual/Airframe. Every form, weight class and refit is just another one of these in data/shapes/.

## Parts that only some loadouts show (weapons, refits, weight class). Shapes without one of these
## leave it empty, so it shrinks into the hull. Each needs a Polygon2D of the same name.
const OPTIONAL_PARTS: PackedStringArray = ["NozzleL", "NozzleR", "PlateL", "PlateR", "Spine", "HeatSinkL",
		"HeatSinkR", "Rail", "Lens", "BladeL", "BladeR", "PodL", "PodR", "Outline", "HullShade", "WingPanelL",
		"WingPanelR", "IntakeL", "IntakeR", "EdgeL", "EdgeR", "StripeL", "StripeR"]

@export var parts: Dictionary[String, PackedVector2Array] = {}
## Parts that change colour in this shape (Thresher form's polished metal); the morph blends to them.
## Any part not listed goes back to its colour in the scene.
@export var part_colors: Dictionary[String, Color] = {}
## Weight-class base shapes: how much bigger than Light they are. Refit overlays are drawn at Light
## size and get scaled by this, so one overlay fits every class.
@export var overlay_scale: float = 1.0
## Swept-wing refit overlays: leans whatever wings the class has backwards, instead of replacing
## the hull and losing the class's silhouette. Rearward shift per pixel outward of sweep_pivot.
@export var wing_sweep: float = 0.0
## Half-width of the body (Light size); points inside it don't move.
@export var sweep_pivot: float = 0.0
## Where the nose weapon's muzzle sits for this shape, relative to the ship.
@export var muzzle_offset: Vector2 = Vector2(0.0, -35.0)
## Right wing pylon (secondary weapons), relative to the ship. The left one is its mirror.
@export var pylon_offset: Vector2 = Vector2(14.0, 6.0)
## Salvage Mount (assimilated module), on the belly, relative to the ship.
@export var mount_offset: Vector2 = Vector2(0.0, 10.0)

@export_group("Hitbox")
## Capsule over the body and wing roots (DESIGN.md §5.4). Wing tips don't count.
@export var hitbox_radius: float = 12.0
## Total capsule length, nose to tail, including the rounded ends.
@export var hitbox_height: float = 36.0
@export var hitbox_offset: Vector2 = Vector2.ZERO
## Near-miss ring for Overclock (DESIGN.md §5.4/§5.6). Must stay outside the hitbox.
@export var graze_radius: float = 28.0


## This base shape with refit overlays laid on top: an overlay part replaces the part of the same
## name (an empty one hides it). Every optional part is listed, so the morph can shrink it away.
func with_overlays(overlays: Array[AirframeShape]) -> AirframeShape:
	var out: AirframeShape = duplicate() as AirframeShape
	out.parts = parts.duplicate()
	for part: String in OPTIONAL_PARTS:
		if not out.parts.has(part):
			out.parts[part] = PackedVector2Array()
	var grow: Transform2D = Transform2D.IDENTITY.scaled(Vector2(overlay_scale, overlay_scale))
	for overlay: AirframeShape in overlays:
		if overlay == null:
			continue
		if overlay.wing_sweep != 0.0:
			out._sweep_wings(overlay.wing_sweep, overlay.sweep_pivot * overlay_scale)
		for part: String in overlay.parts:
			out.parts[part] = grow * overlay.parts[part]
	return out


func _sweep_wings(sweep: float, pivot: float) -> void:
	for part: String in parts:
		# A copy: packed arrays are shared with the base shape, which must stay untouched.
		var points: PackedVector2Array = parts[part].duplicate()
		for i: int in points.size():
			points[i].y += sweep * maxf(absf(points[i].x) - pivot, 0.0)
		parts[part] = points

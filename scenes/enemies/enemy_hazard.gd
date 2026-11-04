class_name EnemyHazard
extends Area2D
## A part of an enemy that hurts XF-0 on touch (the Mining Platform's drill). Sits on the
## enemy_bullets layer so XF-0 detects it, but it isn't a round, so it never counts as a graze.

## Armor lost when XF-0 touches this while it's armed. Set by the owning enemy.
var damage: int = 20

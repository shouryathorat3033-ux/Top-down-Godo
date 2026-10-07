## Skeleton.gd — Skeleton enemy, extends BaseEnemy
extends "res://script/enemies/BaseEnemy.gd"

func _ready() -> void:
	max_hp = 3
	chase_speed = 65.0
	knockback_distance = 80.0
	damage_to_player = 1
	coin_drop = 1
	anim_idle = "idle"
	anim_run = "run"
	anim_death = "death"
	super._ready()

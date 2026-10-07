## Orc.gd — Orc enemy, extends BaseEnemy
extends "res://script/enemies/BaseEnemy.gd"

func _ready() -> void:
	# Orc stats — tougher than slime
	max_hp = 5
	chase_speed = 55.0
	knockback_distance = 60.0
	damage_to_player = 1
	coin_drop = 2
	anim_idle = "idle"
	anim_run = "run"
	anim_death = "death"
	super._ready()

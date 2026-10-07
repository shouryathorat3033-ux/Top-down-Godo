## DoorTrigger.gd
## Attach to an Area2D in the exterior map to teleport the player into the house interior.
extends Area2D

@export var destination_scene: String = "res://scene/world/house_interior.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(destination_scene)

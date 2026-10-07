## HouseInterior.gd
## Handles the house interior scene — shows when player enters house, hides when they exit
extends Node2D

signal player_exited_house

@onready var door_area: Area2D = $DoorArea

func _ready() -> void:
	if door_area:
		door_area.body_entered.connect(_on_door_entered)

func _on_door_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited_house.emit()
		# Transition back to main exterior — handled by main.gd or SceneTransition
		get_tree().change_scene_to_file("res://scene/main.tscn")

## Chest.gd — Chest object that opens on player interaction and grants coins
extends StaticBody2D

@export var coins_inside: int = 3
@export var heal_amount: int = 0

var _opened: bool = false
var _player_nearby: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_label: Label = $InteractionLabel
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("closed")
		animated_sprite.animation_finished.connect(_on_anim_finished)
	if interaction_label:
		interaction_label.hide()
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and not _opened and event.is_action_just_pressed("interact"):
		_open()


func _open() -> void:
	_opened = true
	if interaction_label:
		interaction_label.hide()
	if animated_sprite and animated_sprite.sprite_frames.has_animation("open"):
		animated_sprite.play("open")
	else:
		_give_rewards()


func _on_anim_finished() -> void:
	if animated_sprite and animated_sprite.animation == "open":
		_give_rewards()


func _give_rewards() -> void:
	GameManager.add_coin(coins_inside)
	if heal_amount > 0:
		GameManager.heal(heal_amount)
	GameManager.item_collected.emit("Chest")


func _on_player_entered(body: Node) -> void:
	if body.is_in_group("player") and not _opened:
		_player_nearby = true
		if interaction_label:
			interaction_label.show()


func _on_player_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if interaction_label:
			interaction_label.hide()

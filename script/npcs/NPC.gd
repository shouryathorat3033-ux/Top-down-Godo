## NPC.gd — Simple NPC with dialogue box interaction
extends CharacterBody2D

@export var dialogue_lines: Array[String] = ["Hello, traveller!", "Be careful out there."]
@export var npc_name: String = "Villager"

var _current_line: int = 0
var _player_nearby: bool = false
var _dialogue_open: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_label: Label = $InteractionLabel
@onready var dialogue_box: Control = $DialogueBox
@onready var dialogue_name_label: Label = $DialogueBox/Panel/VBox/NameLabel
@onready var dialogue_text_label: Label = $DialogueBox/Panel/VBox/TextLabel
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	if interaction_label:
		interaction_label.hide()
	if dialogue_box:
		dialogue_box.hide()
	if dialogue_name_label:
		dialogue_name_label.text = npc_name
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	if event.is_action_just_pressed("interact"):
		if not _dialogue_open:
			_open_dialogue()
		else:
			_advance_dialogue()


func _open_dialogue() -> void:
	_dialogue_open = true
	_current_line = 0
	if interaction_label:
		interaction_label.hide()
	if dialogue_box:
		dialogue_box.show()
	_show_line()


func _advance_dialogue() -> void:
	_current_line += 1
	if _current_line >= dialogue_lines.size():
		_close_dialogue()
	else:
		_show_line()


func _show_line() -> void:
	if dialogue_text_label and _current_line < dialogue_lines.size():
		dialogue_text_label.text = dialogue_lines[_current_line]


func _close_dialogue() -> void:
	_dialogue_open = false
	if dialogue_box:
		dialogue_box.hide()
	if _player_nearby and interaction_label:
		interaction_label.show()


func _on_player_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if interaction_label and not _dialogue_open:
			interaction_label.show()


func _on_player_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		_close_dialogue()
		if interaction_label:
			interaction_label.hide()

## HUD.gd — Heads-up display: heart row + coin counter
extends CanvasLayer

@onready var hearts_container: HBoxContainer = $HeartsContainer
@onready var coin_label: Label = $CoinLabel

const HEART_FULL  = preload("res://assets/ui/heart_full.png")  if ResourceLoader.exists("res://assets/ui/heart_full.png")  else null
const HEART_EMPTY = preload("res://assets/ui/heart_empty.png") if ResourceLoader.exists("res://assets/ui/heart_empty.png") else null

var _heart_labels: Array[Label] = []


func _ready() -> void:
	GameManager.player_hp_changed.connect(_on_hp_changed)
	GameManager.item_collected.connect(_on_item_collected)
	_build_hearts(GameManager.player_max_hp)
	_update_hearts(GameManager.player_hp)
	_update_coins(GameManager.player_coins)


func _build_hearts(max_hp: int) -> void:
	if hearts_container == null:
		return
	for child in hearts_container.get_children():
		child.queue_free()
	_heart_labels.clear()
	var half_hearts = max_hp  # 1 heart = 1 HP for simplicity
	for i in half_hearts:
		var lbl = Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color.RED)
		hearts_container.add_child(lbl)
		_heart_labels.append(lbl)


func _update_hearts(current_hp: int) -> void:
	for i in _heart_labels.size():
		_heart_labels[i].add_theme_color_override(
			"font_color",
			Color.RED if i < current_hp else Color(0.3, 0.3, 0.3)
		)


func _update_coins(coins: int) -> void:
	if coin_label:
		coin_label.text = "🪙 %d" % coins


func _on_hp_changed(current: int, max_hp: int) -> void:
	if _heart_labels.size() != max_hp:
		_build_hearts(max_hp)
	_update_hearts(current)


func _on_item_collected(_item: String) -> void:
	_update_coins(GameManager.player_coins)

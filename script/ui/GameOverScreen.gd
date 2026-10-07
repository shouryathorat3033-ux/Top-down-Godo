## GameOverScreen.gd
extends CanvasLayer

@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var quit_button: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	hide()
	GameManager.player_died.connect(_show)
	if restart_button:
		restart_button.pressed.connect(_on_restart)
	if quit_button:
		quit_button.pressed.connect(_on_quit)


func _show() -> void:
	show()
	get_tree().paused = true


func _on_restart() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().quit()

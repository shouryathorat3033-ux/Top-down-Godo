## GameManager.gd — Autoload Singleton
## Tracks player stats, handles game state, and broadcasts signals game-wide.
extends Node

signal player_hp_changed(current: int, max_hp: int)
signal player_died
signal enemy_killed(enemy_name: String)
signal item_collected(item_name: String)

# --- Player stats (persisted across rooms) ---
var player_max_hp: int = 6
var player_hp: int = 6
var player_coins: int = 0
var enemies_killed: int = 0

# --- Game state ---
enum State { PLAYING, PAUSED, GAME_OVER }
var current_state: State = State.PLAYING

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func heal(amount: int) -> void:
	player_hp = min(player_hp + amount, player_max_hp)
	player_hp_changed.emit(player_hp, player_max_hp)

func take_damage(amount: int) -> void:
	player_hp -= amount
	player_hp = max(player_hp, 0)
	player_hp_changed.emit(player_hp, player_max_hp)
	if player_hp <= 0:
		player_died.emit()
		current_state = State.GAME_OVER

func add_coin(amount: int = 1) -> void:
	player_coins += amount

func register_kill(enemy_name: String) -> void:
	enemies_killed += 1
	enemy_killed.emit(enemy_name)

func reset() -> void:
	player_hp = player_max_hp
	player_coins = 0
	enemies_killed = 0
	current_state = State.PLAYING
	player_hp_changed.emit(player_hp, player_max_hp)

## player.gd — Full player controller: movement, animation, combat, damage, death
extends CharacterBody2D

const SPEED = 300.0
const INVINCIBILITY_DURATION = 0.8   # seconds after taking damage

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var _invincible: float = 0.0          # countdown timer

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1   # Player layer
	collision_mask  = 2   # Collide with walls (layer 2)

	hitbox_offset = hitbox.position
	hitbox.monitoring = false
	hitbox.collision_layer = 4   # PlayerAttack
	hitbox.collision_mask  = 8   # EnemyHurtbox

	animated_sprite_2d.frame_changed.connect(_on_animated_sprite_2d_frame_changed)
	hitbox.area_entered.connect(_on_hitbox_area_entered)

	# Connect to GameManager death signal to play death animation
	GameManager.player_died.connect(_on_player_died)


func _physics_process(delta: float) -> void:
	# Invincibility flicker
	if _invincible > 0:
		_invincible -= delta
		animated_sprite_2d.modulate = Color(1, 1, 1, 0.4) if fmod(_invincible * 10, 2) > 1 else Color.WHITE
	else:
		animated_sprite_2d.modulate = Color.WHITE

	if GameManager.current_state == GameManager.State.GAME_OVER:
		return

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if is_attacking:
		velocity = Vector2.ZERO
		return

	process_movement()
	process_animation()
	move_and_slide()


# ─── Movement & Animation ───────────────────────────────────────────────────

func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		update_hitbox_offset()
	else:
		velocity = Vector2.ZERO


func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)


func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")


# ─── Combat ─────────────────────────────────────────────────────────────────

func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	update_hitbox_offset()
	play_animation("attack", last_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false


func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return
	# Active hitbox on frames 2–4 of 6-frame attack sheet
	hitbox.monitoring = animated_sprite_2d.frame >= 2 and animated_sprite_2d.frame <= 4


func _on_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(1, global_position)


func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	match last_direction:
		Vector2.LEFT:  hitbox.position = Vector2(-x,  y)
		Vector2.RIGHT: hitbox.position = Vector2( x,  y)
		Vector2.UP:    hitbox.position = Vector2( y, -x)
		Vector2.DOWN:  hitbox.position = Vector2(-y,  x)


# ─── Damage Received ─────────────────────────────────────────────────────────

## Called by enemies/hazards to deal damage to the player
func receive_damage(amount: int) -> void:
	if _invincible > 0:
		return
	_invincible = INVINCIBILITY_DURATION
	GameManager.take_damage(amount)


func _on_player_died() -> void:
	is_attacking = false
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	set_physics_process(false)
	# Play death animation if it exists, else just fade
	if animated_sprite_2d.sprite_frames.has_animation("death"):
		animated_sprite_2d.play("death")
	else:
		var tw = create_tween()
		tw.tween_property(animated_sprite_2d, "modulate:a", 0.0, 0.8)

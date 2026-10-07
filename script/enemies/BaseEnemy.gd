## BaseEnemy.gd — Shared logic for all enemies (Orc, Skeleton, Slime, Bat)
## Each enemy scene extends this with its own animation names and stats.
extends CharacterBody2D
class_name BaseEnemy

# --- Override these in each enemy scene via @export ---
@export var max_hp: int = 3
@export var chase_speed: float = 60.0
@export var knockback_distance: float = 70.0
@export var knockback_duration: float = 0.2
@export var damage_to_player: int = 1
@export var coin_drop: int = 1
@export var xp_value: int = 10

# --- Animations (override if different) ---
@export var anim_idle: String = "idle"
@export var anim_run: String = "run"
@export var anim_hurt: String = "idle"   # fallback: flash instead
@export var anim_death: String = "death"

# --- Runtime state ---
var hp: int
var is_dead: bool = false
var is_knocked_back: bool = false
var player: Node2D = null

# --- Nodes (resolved in _ready) ---
var animated_sprite: AnimatedSprite2D
var health_bar: ProgressBar
var sight: Area2D
var hurtbox: Area2D
var body_col: CollisionShape2D

# --- Invincibility flash ---
var _hurt_timer: float = 0.0
const HURT_FLASH_DURATION: float = 0.3


func _ready() -> void:
	hp = max_hp
	collision_layer = 2   # Enemy bodies on layer 2
	collision_mask = 1    # Collide with Player (layer 1) and Walls

	animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
	health_bar      = $HealthBar        if has_node("HealthBar")        else null
	hurtbox         = $Hurtbox          if has_node("Hurtbox")          else null
	body_col        = $CollisionShape2D if has_node("CollisionShape2D") else null

	# Sight Area2D
	if has_node("sight"):
		sight = $sight
	elif has_node("DetectionArea"):
		sight = $DetectionArea
	else:
		sight = null

	# Health bar init
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

	# Hurtbox — layer 4 (EnemyHurtbox), detected by player hitbox mask 8
	if hurtbox:
		hurtbox.collision_layer = 8
		hurtbox.collision_mask  = 0

	# Sight setup
	if sight:
		sight.collision_layer = 0
		sight.collision_mask  = 1
		sight.body_entered.connect(_on_sight_entered)
		sight.body_exited.connect(_on_sight_exited)

	if animated_sprite:
		animated_sprite.play(anim_idle)
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead or is_knocked_back:
		return

	# Hurt flash timer
	if _hurt_timer > 0:
		_hurt_timer -= delta
		if animated_sprite:
			animated_sprite.modulate = Color(1, 0.3, 0.3) if fmod(_hurt_timer * 10, 2) > 1 else Color.WHITE
	else:
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE

	if player != null:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * chase_speed
		if animated_sprite:
			animated_sprite.play(anim_run)
			if dir.x != 0:
				animated_sprite.flip_h = dir.x < 0
	else:
		velocity = Vector2.ZERO
		if animated_sprite:
			animated_sprite.play(anim_idle)

	move_and_slide()


# ─── Damage ────────────────────────────────────────────────────────────────

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	hp -= amount
	if health_bar:
		health_bar.value = hp
	_hurt_timer = HURT_FLASH_DURATION
	if hp <= 0:
		_die()
	else:
		if attacker_pos != Vector2.ZERO:
			_apply_knockback(attacker_pos)


func _apply_knockback(attacker_pos: Vector2) -> void:
	is_knocked_back = true
	var dir = (global_position - attacker_pos).normalized()
	var target = global_position + dir * knockback_distance
	var tw = create_tween()
	tw.tween_property(self, "global_position", target, knockback_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): is_knocked_back = false)


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	if body_col:
		body_col.set_deferred("disabled", true)
	if hurtbox:
		var hb_col = hurtbox.get_node_or_null("CollisionShape2D")
		if hb_col:
			hb_col.set_deferred("disabled", true)
	if health_bar:
		health_bar.hide()
	if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_death):
		animated_sprite.play(anim_death)
	else:
		queue_free()
	GameManager.register_kill(name)


func _on_animation_finished() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.animation == anim_death:
		queue_free()


# ─── Sight ─────────────────────────────────────────────────────────────────

func _on_sight_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.is_in_group("player") or body.name.to_lower() == "player":
		player = body

func _on_sight_exited(body: Node2D) -> void:
	if body == player:
		player = null
		velocity = Vector2.ZERO

extends CharacterBody2D

const MAX_HP: int = 3
const CHASE_SPEED: float = 80.0
const KNOCKBACK_DISTANCE: float = 80.0
const KNOCKBACK_DURATION: float = 0.2

var hp: int = MAX_HP
var is_dead: bool = false
var player: Node2D = null       # Set when player enters enemy's sight
var is_knocked_back: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
var sight: Area2D = null  # Resolved in _ready()


func _ready() -> void:
	# Hurtbox on layer 4 (value 8) — detected by player hitbox (mask 8)
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0

	# Initialize health bar
	health_bar.max_value = MAX_HP
	health_bar.value = hp

	# Resolve the sight node safely inside _ready()
	if has_node("sight"):
		sight = $sight
		print("[Slime] sight node found: ", sight)
	elif has_node("DetectionArea"):
		sight = $DetectionArea
		print("[Slime] DetectionArea used as sight: ", sight)
	else:
		push_error("[Slime] ERROR: No sight or DetectionArea node found! Slime will not detect player.")

	# Connect sight signals
	if sight != null:
		sight.collision_layer = 0
		sight.collision_mask = 1
		sight.body_entered.connect(_on_sight_body_entered)
		sight.body_exited.connect(_on_sight_body_exited)
		print("[Slime] sight connected successfully")

	animated_sprite.play("idle")


func _physics_process(_delta: float) -> void:
	if is_dead or is_knocked_back:
		return

	if player != null:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * CHASE_SPEED
		animated_sprite.play("idle")  # Use idle as walk (no separate walk animation)
		# Flip sprite to face the player
		if direction.x != 0:
			animated_sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO

	move_and_slide()


# -----------------------------------------------
#             Take Damage + Knockback
# -----------------------------------------------

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	hp -= amount
	health_bar.value = hp

	if hp <= 0:
		die()
	else:
		# Play hurt flash animation (using "attack" frames as hit reaction)
		animated_sprite.play("attack")
		# Apply knockback away from the attacker
		if attacker_position != Vector2.ZERO:
			apply_knockback(attacker_position)


func apply_knockback(attacker_position: Vector2) -> void:
	is_knocked_back = true
	var knockback_direction = (global_position - attacker_position).normalized()
	var target_position = global_position + knockback_direction * KNOCKBACK_DISTANCE

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, KNOCKBACK_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): is_knocked_back = false)


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	body_collision.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	animated_sprite.play("die")


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "die":
		queue_free()
	elif animated_sprite.animation == "attack":
		# Return to idle after the hit reaction
		animated_sprite.play("idle")


# -----------------------------------------------
#             Sight (Detection Area) Signals
# -----------------------------------------------

func _on_sight_body_entered(body: Node2D) -> void:
	if body == self:
		return  # Ignore self — slime's own body should not trigger sight
	if body.is_in_group("player") or body.name == "player":
		player = body
		print("Slime sight spotted: ", body.name)


func _on_sight_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		velocity = Vector2.ZERO
		print("Slime lost sight of player")


# Compatibility wrappers in case signals were connected to the old function names
func _on_detection_area_body_entered(body: Node2D) -> void:
	_on_sight_body_entered(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	_on_sight_body_exited(body)



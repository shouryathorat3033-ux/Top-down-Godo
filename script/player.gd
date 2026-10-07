extends CharacterBody2D


const SPEED = 300.0

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox



func _ready() -> void:
	add_to_group("player")
	
	# Player body: Layer 1 (Player), Mask 2 (Walls) — so wall tiles block movement
	collision_layer = 1
	collision_mask = 2
	
	# Initialize the hitbox offset
	hitbox_offset = hitbox.position
	
	# Hitbox disabled by default — only active during swing frames
	hitbox.monitoring = false
	
	# Layer 3 (value 4) = PlayerAttack, detects layer 4 (value 8) = EnemyHurtbox
	hitbox.collision_layer = 4
	hitbox.collision_mask = 8
	
	# Connect signals
	animated_sprite_2d.frame_changed.connect(_on_animated_sprite_2d_frame_changed)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	

func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
		
	
	#Skip movement if attacking
	if is_attacking:
		velocity = Vector2.ZERO
		return
	
	
	process_movement()
	process_animation()
	move_and_slide()

#-----------------------------------------------------
#MOVEMENT AND ANIMEATION
#-----------------------------------------------------


func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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

func play_animation(prefix: String ,dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix +  "_down")

#-----------------------------------------------------
#                      Attacking
#------------------------------------------------------
func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true 
	# Update hitbox position even when standing still before swinging
	update_hitbox_offset()
	play_animation("attack", last_direction)
	print("Attack")




func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false


#-----------------------------------------------
#              Hitbox
#-----------------------------------------------

func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	match last_direction:
		Vector2.LEFT:
			hitbox.position = Vector2(-x,y)
		Vector2.RIGHT:
			hitbox.position = Vector2(x,y)
		Vector2.UP:
			hitbox.position = Vector2(y,-x)
		Vector2.DOWN:
			hitbox.position = Vector2(-y,x)


# Enable hitbox only during the active swing frames (frames 2–4 of the 6-frame attack)
func _on_animated_sprite_2d_frame_changed() -> void:
	if not is_attacking:
		return
	hitbox.monitoring = animated_sprite_2d.frame >= 2 and animated_sprite_2d.frame <= 4


# Deal 1 damage to any enemy whose hurtbox the player hitbox overlaps
# Pass global_position so the enemy can calculate knockback direction
func _on_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(1, global_position)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.name.begins_with("Slime"):
		print(body.name)
		print("Hit")    
	

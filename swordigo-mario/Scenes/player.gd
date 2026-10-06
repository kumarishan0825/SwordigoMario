extends CharacterBody2D

const SPEED = 300
const JUMP_VELOCITY = -450
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var facing_direc = "right"

func _physics_process(delta):
	floor_constant_speed = true
	floor_snap_length = 32.0
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var direction = Input.get_axis("ui_left","ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		if direction > 0:
			facing_direc = "right"
			animated_sprite_2d.play("run_right")
		else:
			facing_direc = "left"
			animated_sprite_2d.play("run_left")
			
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if facing_direc == "right":
			animated_sprite_2d.play("idle_right")
		else:
			animated_sprite_2d.play("idle_left")
		
	if not is_on_floor():
		if velocity.y < 0:
			if facing_direc == "right":
				animated_sprite_2d.play("jump_right")
			else:
				animated_sprite_2d.play("jump_left")
				
		else:
			if facing_direc == "right":
				animated_sprite_2d.play("fall_right")
			else:
				animated_sprite_2d.play("fall_left")
	move_and_slide()

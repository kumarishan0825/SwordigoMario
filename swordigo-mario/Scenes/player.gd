extends CharacterBody2D

const SPEED = 300
const JUMP_VELOCITY = -650
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var facing_direc = "right"
var is_fighting = false
var figh_id = 0

var respawn_position: Vector2 = Vector2.ZERO
func _ready():
	floor_constant_speed = true
	floor_snap_length = 32.0
	respawn_position = global_position
	animated_sprite_2d.sprite_frames.set_animation_loop("fight", false)
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	update_heart_ui()
	
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		play_fight()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5
		
	var direction = Input.get_axis("ui_left","ui_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		facing_direc = "right" if direction > 0 else "left"

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	update_animation()
	
func update_animation():
	if is_fighting:
		return
	animated_sprite_2d.flip_h = false
	if not is_on_floor():
		if velocity.y < 0:
			var t = 1.0 - (velocity.y / JUMP_VELOCITY)
			scrub_animation("jump_" + facing_direc, t)
		else:
			var t = velocity.y / abs(JUMP_VELOCITY)
			scrub_animation("fall_" + facing_direc, t)
				
	elif  abs(velocity.x) > 1.0:
		animated_sprite_2d.play("run_" + facing_direc)
	else:
		animated_sprite_2d.play("idle_" + facing_direc)
			
func scrub_animation(anim_name: String, progress: float):
	var frameCount = animated_sprite_2d.sprite_frames.get_frame_count(anim_name)
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.animation = anim_name
	animated_sprite_2d.pause()
	animated_sprite_2d.frame = min(int(clamp(progress, 0.0, 1.0)* frameCount), frameCount - 1)
	
	
func play_fight():
	if is_fighting:
		return
	is_fighting = true
	figh_id += 1
	var this_fight = figh_id
	
	animated_sprite_2d.flip_h = (facing_direc == "left")
	animated_sprite_2d.play("fight")
	var frames = animated_sprite_2d.sprite_frames.get_frame_count("fight")
	var fps = animated_sprite_2d.sprite_frames.get_animation_speed("fight")
	await get_tree().create_timer(frames / fps + 0.1).timeout
	
	if is_inside_tree() and is_fighting and this_fight == figh_id:
		is_fighting = false
		animated_sprite_2d.flip_h = false
		
func _on_animation_finished():
	if animated_sprite_2d.animation == "fight":
		is_fighting = false
		animated_sprite_2d.flip_h = false

func _on_void_area_body_entered(body):
	if body.name == "Player":
		body.call_deferred("take_damage", 0.5)
		
@onready var fullHeart = preload("res://Obstacle_img/148001.png")
@onready var halfHeart = preload("res://Obstacle_img/half_heart.png")
@onready var emptyHeart = preload("res://Obstacle_img/empty_heart.png")
@onready var heartContainer = get_tree().current_scene.find_child("Heart_Container", true, false)

var maxHeart: float = 5.0
var currentHeart: float = 5.0


	
func take_damage(amount: float):
	currentHeart -= amount
	
	if currentHeart < 0:
		currentHeart = 0
		
	update_heart_ui()

	if currentHeart <= 0:
		print("Game Over!")
		currentHeart = maxHeart
		get_tree().call_deferred("reload_current_scene")
		
	else:
		global_position = respawn_position
		velocity = Vector2.ZERO
		
func update_heart_ui():
	if not heartContainer: return
	
	var hearts = heartContainer.get_children()
	
	for i in range(hearts.size()):
		var heartNode = hearts[i] as TextureRect
		if currentHeart >= i + 1:
			heartNode.texture = fullHeart
		elif currentHeart > i and currentHeart < i + 1:
			heartNode.texture = halfHeart
		else:
			heartNode.texture = emptyHeart

extends CharacterBody2D

const SPEED = 300
const JUMP_VELOCITY = -650
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
		
	move_and_slide()                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
	if not is_on_floor():
		print("Hawa mein vel y", velocity.y , "vel x", velocity.x)
		if velocity.y < 0:
			if velocity.x > 0:
				print("Plaring jump right")
				animated_sprite_2d.play("jump_right")
			elif velocity.x < 0:
				print("Plaring jump left")
				animated_sprite_2d.play("jump_left")
				
		else:
			if velocity.x > 0:
				print("Plaring fall right")
				animated_sprite_2d.play("fall_right")
			elif velocity.x < 0:
				print("Plaring fall left")
				animated_sprite_2d.play("fall_left")


func _on_void_area_body_entered(body):
	if body.name == "Player":
		body.call_deferred("take_damage", 0.5)
		
@onready var fullHeart = preload("res://Obstacle_img/148001.png")
@onready var halfHeart = preload("res://Obstacle_img/half_heart.png")
@onready var emptyHeart = preload("res://Obstacle_img/empty_heart.png")
@onready var heartContainer = get_tree().current_scene.find_child("Heart_Container", true, false)

var maxHeart: float = 5.0
var currentHeart: float = 5.0
var respawn_position: Vector2 = Vector2.ZERO

func _ready():
	respawn_position = global_position
	update_heart_ui()
	
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

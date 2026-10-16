extends CharacterBody2D

const SPEED = 300
const JUMP_VELOCITY = -650
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const FightDamage = 0.5
const SpellDamage = 1.5
@onready var attack_area: Area2D = $AttackArea
@onready var spell_area: Area2D = $SpellArea
var invincible = false

var facing_direc = "right"
var is_fighting = false
var figh_id = 0
var attackType = ""
var hitBodies : Array = []

var respawn_position: Vector2 = Vector2.ZERO
func _ready():
	add_to_group("player")
	floor_constant_speed = true
	floor_snap_length = 32.0
	respawn_position = global_position
	animated_sprite_2d.sprite_frames.set_animation_loop("fight", false)
	animated_sprite_2d.sprite_frames.set_animation_loop("spell", false)
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	attack_area.monitoring = false
	spell_area.monitoring = false
	update_heart_ui()
	
func _input(event):
	if event is InputEventMouseButton and event.pressed and not Global.isTalking:
		if event.button_index == MOUSE_BUTTON_LEFT:
			start_attack("fight")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			start_attack("spell")

func _physics_process(_delta):
	if not is_on_floor():
		velocity.y += gravity * _delta
	
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
	deal_attack_damage()
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
	
	
func start_attack(type: String):
	if is_fighting:
		return
	is_fighting = true
	figh_id += 1
	var this_fight = figh_id
	hitBodies.clear()
	var side = -1 if facing_direc == "left" else 1
	attack_area.scale.x = side
	spell_area.scale.x = side
	if type == "fight":
		attack_area.monitoring = true
		spell_area.monitoring = false
	elif type == "spell":
		attack_area.monitoring = false
		spell_area.monitoring = true
	
	animated_sprite_2d.flip_h = (facing_direc == "left")
	animated_sprite_2d.play(type)
	var frames = animated_sprite_2d.sprite_frames.get_frame_count(type)
	var fps = animated_sprite_2d.sprite_frames.get_animation_speed(type)
	await get_tree().create_timer(frames / fps + 0.1).timeout
	
	if is_inside_tree() and is_fighting and this_fight == figh_id:
		endAttack()
		
func endAttack():
	is_fighting = false
	attackType = ""
	attack_area.set_deferred("monitoring", false)
	spell_area.set_deferred("monitoring", false)
	animated_sprite_2d.flip_h = false
	
func deal_attack_damage():
	if not is_fighting:
		return
	var area = attack_area if attackType == "fight" else spell_area
	var damage = FightDamage if attackType == "fight" else SpellDamage
	if not area.monitoring:
		area.monitoring = true
	var overlapping = area.get_overlapping_bodies()
	for body in overlapping:
		if body in hitBodies:
			continue
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
			hitBodies.append(body)
func _on_animation_finished():
	if animated_sprite_2d.animation == "fight" or animated_sprite_2d.animation == "spell":
		endAttack() 

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
		call_deferred("die")
		
	else:
		global_position = respawn_position
		velocity = Vector2.ZERO
func hurt(amount: float, from_x: float):
	if invincible:
		return
	invincible = true

	currentHeart -= amount
	if currentHeart < 0:
		currentHeart = 0
	update_heart_ui()

	if currentHeart <= 0:
		currentHeart = maxHeart
		call_deferred("die")
		return

	# Small knockback away from the mob
	velocity.x = sign(global_position.x - from_x) * 250
	velocity.y = -250

	# Blink while invincible for 1 second
	animated_sprite_2d.modulate.a = 0.5
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.modulate.a = 1.0
	invincible = false		
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



@export var nxt_scene:String = "res://Scenes/win_stage.tscn"
@export var nxt_scene2:String = "res://Scenes/win_stage_2.tscn"
@export var nxt_scene3:String = "res://Scenes/win_stage_3.tscn"
@export var nxt_scene4:String = "res://Scenes/win_stage_4.tscn"

func _on_nxt_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file.call_deferred(nxt_scene)


func _on_nxt_2_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file.call_deferred(nxt_scene2)


func _on_nxt_3_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file.call_deferred(nxt_scene3) # Replace with function body.


func _on_nxt_4_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file.call_deferred(nxt_scene4) # Replace with function body.


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
	
@export var death_scene: PackedScene

func die():
	var tree = get_tree()
	var old = tree.current_scene
	var scene = load("res://Scenes/death_screen.tscn")
	var d = scene.instantiate()
	d.came_from = old.scene_file_path
	tree.root.add_child(d)
	tree.current_scene = d
	old.queue_free()

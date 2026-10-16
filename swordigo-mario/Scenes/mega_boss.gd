extends CharacterBody2D

@export var speed = 60.0
@export var chase_speed = 110.0
@export var zone_left_size = 150.0
@export var zone_right_size = 150.0
@export var detect_height = 100.0
@export var health = 3.0
@export var contact_damage = 0.5
@export var fight_cooldown = 1.0
@export var hit_frame = 2
@export var sprite_faces_right = true
@export var show_zone = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dir = 1.0
var zl = 0.0
var zr = 0.0
var turn_cd = 0.0
var cd = 0.0
var stun = 0.0
var fighting = false
var hit_done = false
var dead = false
var player = null

@onready var sprite = $AnimatedSprite2D
@onready var damage_area = $DamageArea

func _ready():
	add_to_group("enemy")
	sprite.sprite_frames.set_animation_loop("fight", false)
	sprite.animation_finished.connect(_on_fin)
	sprite.play("walk")
	zl = global_position.x - zone_left_size
	zr = global_position.x + zone_right_size
	player = get_tree().get_first_node_in_group("player")

func player_in_zone():
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return false
	var p = player.global_position
	return p.x >= zl and p.x <= zr and abs(p.y - global_position.y) <= detect_height

func player_touching():
	for b in damage_area.get_overlapping_bodies():
		if b.is_in_group("player"):
			return b
	return null

func _physics_process(delta):
	if dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	turn_cd -= delta
	cd -= delta
	stun -= delta

	if stun > 0:
		velocity.x = move_toward(velocity.x, 0, 600 * delta)
		keep_in_zone()
		move_and_slide()
		return

	if fighting:
		velocity.x = 0.0
		if not hit_done and sprite.frame >= min(hit_frame, sprite.sprite_frames.get_frame_count("fight") - 1):
			hit_done = true
			var t = player_touching()
			if t and t.has_method("hurt"):
				t.hurt(contact_damage, global_position.x)
		move_and_slide()
		return

	if player_in_zone():
		var dx = player.global_position.x - global_position.x
		if abs(dx) > 10.0:
			dir = sign(dx)
			velocity.x = dir * chase_speed
		else:
			velocity.x = 0.0
	else:
		velocity.x = dir * speed
		if global_position.x >= zr:
			dir = -1.0
		elif global_position.x <= zl:
			dir = 1.0
		elif is_on_wall() and turn_cd <= 0.0:
			dir *= -1.0
			turn_cd = 0.5

	keep_in_zone()
	move_and_slide()

	if sprite_faces_right:
		sprite.flip_h = dir < 0
	else:
		sprite.flip_h = dir > 0

	if cd <= 0.0 and player_touching():
		start_fight()

	if show_zone:
		queue_redraw()

func keep_in_zone():
	if global_position.x <= zl and velocity.x < 0:
		velocity.x = 0.0
	elif global_position.x >= zr and velocity.x > 0:
		velocity.x = 0.0

func start_fight():
	fighting = true
	hit_done = false
	velocity.x = 0.0
	var t = player_touching()
	if t:
		var d = sign(t.global_position.x - global_position.x)
		if d != 0:
			dir = d
	if sprite_faces_right:
		sprite.flip_h = dir < 0
	else:
		sprite.flip_h = dir > 0
	sprite.play("fight")

func _on_fin():
	if sprite.animation == "fight":
		fighting = false
		cd = fight_cooldown
		sprite.play("walk")

func take_damage(amount):
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		get_tree().change_scene_to_file("res://Scenes/winner_screen.tscn")
		return
	fighting = false
	sprite.play("walk")
	stun = 0.25
	if is_instance_valid(player):
		velocity.x = sign(global_position.x - player.global_position.x) * 200
	sprite.modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(sprite, "modulate", Color(1, 1, 1), 0.25)

func _draw():
	if not show_zone:
		return
	draw_rect(Rect2(zl - global_position.x, -detect_height, zr - zl, detect_height * 2), Color(1, 0, 0, 0.8), false, 2.0)

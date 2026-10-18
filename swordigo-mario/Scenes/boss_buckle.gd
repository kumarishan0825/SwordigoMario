extends CharacterBody2D

@export var spell_scene: PackedScene
@export var speed = 60.0
@export var zone_left_size = 200.0
@export var zone_right_size = 200.0
@export var detect_height = 100.0
@export var health = 3.0
@export var spell_damage = 0.5
@export var cast_cooldown = 2.0
@export var cast_frame = 2
@export var spell_offset = Vector2(30, -10)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var show_zone = true 
var dir = 1.0
@export var sprite_faces_right = true
@export var spell_speed = 250.0
var zl = 0.0
var zr = 0.0
var cd = 1.0
var stun = 0.0
var casting = false
var cast_done = false
var dead = false
var player = null

var turn_cd = 0.0
@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	sprite.sprite_frames.set_animation_loop("cast", false)
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

	if casting:
		velocity.x = 0.0
		if not cast_done and sprite.frame >= min(cast_frame, sprite.sprite_frames.get_frame_count("cast") - 1):
			cast_done = true
			shoot()
		move_and_slide()
		return

	if player_in_zone():
		var dx = player.global_position.x - global_position.x
		if dx != 0:
			dir = sign(dx)
		velocity.x = 0.0
		sprite.play("walk")
		if cd <= 0.0:
			start_cast()
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
	flip()

	if show_zone:
		queue_redraw()

func flip():
	if sprite_faces_right:
		sprite.flip_h = dir < 0
	else:
		sprite.flip_h = dir > 0

func keep_in_zone():
	if global_position.x <= zl and velocity.x < 0:
		velocity.x = 0.0
	elif global_position.x >= zr and velocity.x > 0:
		velocity.x = 0.0

func start_cast():
	casting = true
	cast_done = false
	velocity.x = 0.0
	flip()
	sprite.play("cast")

func shoot():
	if spell_scene == null:
		return
	var s = spell_scene.instantiate()
	s.dir = dir
	s.speed = spell_speed
	s.damage = spell_damage
	s.global_position = global_position + Vector2(spell_offset.x * dir, spell_offset.y)
	get_tree().current_scene.add_child(s)

func _on_fin():
	if sprite.animation == "cast":
		casting = false
		cd = cast_cooldown
		sprite.play("walk")

func take_damage(amount):
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		get_tree().change_scene_to_file("res://Scenes/winner_screen_2_0.tscn")
		return
	casting = false
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

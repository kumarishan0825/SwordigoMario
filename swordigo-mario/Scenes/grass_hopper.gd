extends CharacterBody2D

@export var speed = 60.0
@export var chase_speed = 110.0
@export var zone_left_size = 150.0
@export var zone_right_size = 150.0
@export var detect_height = 100.0
@export var health = 3.0
@export var contact_damage = 0.5
@export var sprite_faces_right = true
@export var show_zone = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dir = 1.0
var zl = 0.0
var zr = 0.0
var turn_cd = 0.0
var player = null

@onready var sprite = $AnimatedSprite2D
@onready var damage_area = $DamageArea

func _ready():
	add_to_group("enemy")
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
	if not is_on_floor():
		velocity.y += gravity * delta
	turn_cd -= delta

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

	if global_position.x <= zl and velocity.x < 0:
		velocity.x = 0.0
	elif global_position.x >= zr and velocity.x > 0:
		velocity.x = 0.0

	move_and_slide()

	if sprite_faces_right:
		sprite.flip_h = dir < 0
	else:
		sprite.flip_h = dir > 0

	for b in damage_area.get_overlapping_bodies():
		if b.is_in_group("player") and b.has_method("hurt"):
			b.hurt(contact_damage, global_position.x)

	if show_zone:
		queue_redraw()

func _draw():
	if not show_zone:
		return
	draw_rect(Rect2(zl - global_position.x, -detect_height, zr - zl, detect_height * 2), Color(1, 0, 0, 0.8), false, 2.0)

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

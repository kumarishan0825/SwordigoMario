extends Area2D

var dir = 1.0
var speed = 250.0
var damage = 0.5
var life = 3.0

@onready var img = $Sprite2D

func _ready():
	img.flip_h = dir < 0
	body_entered.connect(_hit)

func _physics_process(delta):
	position.x += dir * speed * delta
	life -= delta
	if life <= 0:
		queue_free()

func _hit(body):
	if body.is_in_group("player"):
		if body.has_method("hurt"):
			body.hurt(damage, global_position.x)
		queue_free()
	elif not body.is_in_group("enemy"):
		queue_free()

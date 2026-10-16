extends Node2D

var came_from = ""

@onready var btn = $Button2

func _ready():
	btn.pressed.connect(_respawn)

func _respawn():
	if came_from == "":
		came_from = "res://level1_stage1.tscn"
	get_tree().change_scene_to_file(came_from)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_scene.tscn")

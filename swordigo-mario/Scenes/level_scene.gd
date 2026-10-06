extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/castle_wars.tscn")  # Replace with function body.


func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/plain_biome.tscn")  # Replace with function body.


func _on_button_4_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/volcanic_end.tscn")  # Replace with function body.

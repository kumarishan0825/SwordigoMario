extends Area2D

var dialogue: Array = [
	"Master: You have arrived at last, young travller...",\
	"Master: The darkness is spreading across the lands.",
	"Player: Master! HOW??",
	"Master: You are my precious warrior, and I know you're are capable!",
	"Master: Take my intrusive knowledge and fulfill your destiny!",
	"Player: I won't let you down, Master!"
]
var currentLine : int = 0
var player_in_range: bool = false
var isTalking: bool = false
@onready var textBox = $Textbox
@onready var dialogueLabel = $Textbox/DialogueLabel
# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if isTalking and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_next_line()
				

func _on_body_entered(body):
	if body.name == "Player":
		print("entered")
		player_in_range = true
		if not isTalking:
			start_dialogue()
			
func _on_body_exited(body):
	if body.name == "Player":
		print("exited")
		player_in_range = false
		end_dialogue()
		
func start_dialogue():
	print("start dialogue")
	isTalking = true
	Global.isTalking = true
	currentLine = 0
	textBox.visible = true
	show_line()
func show_next_line():
	currentLine += 1
	if currentLine < dialogue.size():
		show_line()
	else:
		end_dialogue()
func show_line():
	dialogueLabel.text = dialogue[currentLine]
func end_dialogue():
	isTalking = false
	Global.isTalking = false
	textBox.visible = false
	

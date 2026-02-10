extends Button

func _ready():
	pressed.connect(_on_pressed)
	print("ContinueButton script ready!")

func _on_pressed():
	print("ContinueButton pressed!")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().process_frame
	get_tree().reload_current_scene()

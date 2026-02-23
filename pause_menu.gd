extends CanvasLayer

# Pause Menu - Press ESC to toggle
# Add this as a CanvasLayer child in main.tscn and main_2.tscn

var is_paused: bool = false

func _ready():
	# Hide entire root (dimmer + panel) at start
	$PauseRoot.visible = false
	# Make sure this layer processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if is_paused:
			_resume()
		else:
			_pause()

func _pause():
	is_paused = true
	get_tree().paused = true
	$PauseRoot.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _resume():
	is_paused = false
	get_tree().paused = false
	$PauseRoot.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_continue_button_pressed():
	_resume()

func _on_menu_button_pressed():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

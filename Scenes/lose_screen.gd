extends Control

@onready var retry_button = $Panel/VBoxContainer/RetryButton
@onready var menu_button = $Panel/VBoxContainer/MenuButton

func _ready():
	hide()
	if GameManager:
		GameManager.game_lost.connect(_on_game_lost)

func _on_game_lost():
	"""Show lose screen"""
	show()
	get_tree().paused = true
	
	# Make cursor visible and free to move
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_retry_button_pressed():
	"""Retry current level"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hide cursor for gameplay
	if GameManager:
		GameManager.reset_level()
		GameManager.start_timer()  # Explicitly restart the timer
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	"""Return to main menu"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Show cursor for menu
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

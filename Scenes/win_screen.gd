extends Control

@onready var star1 = $Panel/Stars/Star1
@onready var star2 = $Panel/Stars/Star2
@onready var star3 = $Panel/Stars/Star3
@onready var level_2_button = $Panel/VBoxContainer/Level2Button
@onready var retry_button = $Panel/VBoxContainer/RetryButton
@onready var menu_button = $Panel/VBoxContainer/MenuButton

var stars_earned: int = 0

func _ready():
	hide()
	if GameManager:
		GameManager.game_won.connect(_on_game_won)

func _on_game_won(stars: int):
	"""Show win screen with star rating"""
	stars_earned = stars
	show()
	display_stars(stars)
	get_tree().paused = true
	
	# Make cursor visible and free to move
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func display_stars(count: int):
	"""Display the earned stars with animation"""
	# Reset all stars first
	star1.modulate = Color(0.3, 0.3, 0.3, 1.0)  # Dim/gray
	star2.modulate = Color(0.3, 0.3, 0.3, 1.0)
	star3.modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	# Light up earned stars
	if count >= 1:
		star1.modulate = Color(1.0, 0.84, 0.0, 1.0)  # Gold
	if count >= 2:
		star2.modulate = Color(1.0, 0.84, 0.0, 1.0)
	if count >= 3:
		star3.modulate = Color(1.0, 0.84, 0.0, 1.0)

func _on_level_2_button_pressed():
	"""Load Level 2"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hide cursor for gameplay
	# Add your Level 2 scene path here
	# get_tree().change_scene_to_file("res://Scenes/Levels/level_2.tscn")
	print("Loading Level 2...")

func _on_retry_button_pressed():
	"""Retry current level"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hide cursor for gameplay
	if GameManager:
		GameManager.reset_level()
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	"""Return to main menu"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Show cursor for menu
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

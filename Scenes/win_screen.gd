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
	"""Show win screen with star rating after 4 second delay"""
	stars_earned = stars
	
	print("🏆 Game won! Waiting 4 seconds before showing win screen...")
	
	# Wait 4 seconds before showing win screen
	await get_tree().create_timer(4.0).timeout
	
	print("✅ Showing win screen now!")
	show()
	display_stars(stars)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func display_stars(count: int):
	"""Light up earned stars, gray out the rest.
	   Supports 0, 1, 2, or 3 stars."""
	var dim  = Color(0.3, 0.3, 0.3, 1.0)  # gray
	var gold = Color(1.0, 0.84, 0.0, 1.0) # gold

	star1.modulate = gold if count >= 1 else dim
	star2.modulate = gold if count >= 2 else dim
	star3.modulate = gold if count >= 3 else dim

func _on_level_2_button_pressed():
	"""Load Level 2"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://Scenes/Levels/level_2.tscn")

func _on_retry_button_pressed():
	"""Retry current level"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager:
		GameManager.reset_level()
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	"""Return to main menu"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

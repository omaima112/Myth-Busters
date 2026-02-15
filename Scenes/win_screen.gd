extends Control

@onready var star1 = $Panel/Stars/Star1
@onready var star2 = $Panel/Stars/Star2
@onready var star3 = $Panel/Stars/Star3
@onready var retry_button = $Panel/VBoxContainer/RetryButton
@onready var menu_button = $Panel/VBoxContainer/MenuButton

# ✅ SAFE: Use get_node_or_null instead of @onready for Level2Button
var level2_button: Button

var stars_earned: int = 0

func _ready():
	hide()
	
	# ✅ SAFE: Get Level2Button only if it exists
	level2_button = get_node_or_null("Panel/VBoxContainer/Level2Button")
	
	print("🎯 Win screen initialized")
	print("   Retry button exists: ", retry_button != null)
	print("   Menu button exists: ", menu_button != null)
	print("   Level 2 button exists: ", level2_button != null)
	
	if GameManager:
		GameManager.game_won.connect(_on_game_won)

func _on_game_won(stars: int):
	"""Show win screen with star rating after 4 second delay"""
	stars_earned = stars
	print("🏆 Game won! Waiting 4 seconds before showing win screen...")
	await get_tree().create_timer(4.0).timeout
	print("✅ Showing win screen now!")
	show()
	display_stars(stars)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# ✅ CONNECT ALL BUTTON SIGNALS (if they exist)
	if level2_button and not level2_button.pressed.is_connected(_on_level_2_button_pressed):
		print("✅ Connecting Level 2 button...")
		level2_button.pressed.connect(_on_level_2_button_pressed)
	
	if retry_button and not retry_button.pressed.is_connected(_on_retry_button_pressed):
		print("✅ Connecting Retry button...")
		retry_button.pressed.connect(_on_retry_button_pressed)
	
	if menu_button and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		print("✅ Connecting Menu button...")
		menu_button.pressed.connect(_on_menu_button_pressed)

func display_stars(count: int):
	"""Light up earned stars, gray out the rest."""
	var dim  = Color(0.3, 0.3, 0.3, 1.0)
	var gold = Color(1.0, 0.84, 0.0, 1.0)
	star1.modulate = gold if count >= 1 else dim
	star2.modulate = gold if count >= 2 else dim
	star3.modulate = gold if count >= 3 else dim

func _on_level_2_button_pressed():
	"""Load Level 2 with loading screen"""
	print("🎮 Level 2 button pressed!")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("📺 Loading Level 2 with loading screen...")
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen_Level2_Final.tscn")

func _on_retry_button_pressed():
	"""Retry current level"""
	print("🔄 Retry button pressed!")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager:
		GameManager.reset_level()
		GameManager.start_timer()
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	"""Return to main menu"""
	print("🏠 Menu button pressed!")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("🏠 Loading main menu...")
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	
func _input(event: InputEvent):
	# Only allow Q input if win screen is visible
	if not visible:
		return
	
	# Press Q to open the quiz
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			print("🎓 Q pressed — loading quiz...")
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://Scenes/Levels/quiz.tscn")

extends Control

@onready var star1 = $Panel/Stars/Star1
@onready var star2 = $Panel/Stars/Star2
@onready var star3 = $Panel/Stars/Star3
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
	await get_tree().create_timer(4.0).timeout
	print("✅ Showing win screen now!")
	show()
	display_stars(stars)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# ✅ CONNECT BUTTON SIGNALS
	if not retry_button.pressed.is_connected(_on_retry_button_pressed):
		retry_button.pressed.connect(_on_retry_button_pressed)
	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

func display_stars(count: int):
	"""Light up earned stars, gray out the rest."""
	var dim  = Color(0.3, 0.3, 0.3, 1.0)
	var gold = Color(1.0, 0.84, 0.0, 1.0)
	star1.modulate = gold if count >= 1 else dim
	star2.modulate = gold if count >= 2 else dim
	star3.modulate = gold if count >= 3 else dim

func _on_retry_button_pressed():
	"""Retry current level — identical behaviour to lose screen retry"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager:
		GameManager.reset_level()  # resets orbs + timer value back to full
		GameManager.start_timer()  # kicks the countdown off again
	get_tree().reload_current_scene()

func _on_quizbutton_pressed():
	"""Load the Quiz scene"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("🎓 Loading quiz scene...")
	get_tree().change_scene_to_file("res://Scenes/Levels/quiz.tscn")

func _on_menu_button_pressed():
	"""Return to main menu"""
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	
func _input(event: InputEvent):
	# ✅ CRITICAL FIX: Only allow Q input if win screen is actually visible
	if not visible:
		return
	
	# Press Q to open the quiz
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			print("🎓 Q pressed — loading quiz...")
			# ✅ CRITICAL FIX: Unpause BEFORE changing scene
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://Scenes/Levels/quiz.tscn")

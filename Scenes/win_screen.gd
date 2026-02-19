extends Control

@onready var star1         = $Panel/Margins/VBoxContainer/Stars/Star1
@onready var star2         = $Panel/Margins/VBoxContainer/Stars/Star2
@onready var star3         = $Panel/Margins/VBoxContainer/Stars/Star3
@onready var retry_button  = $Panel/Margins/VBoxContainer/RetryButton
@onready var menu_button   = $Panel/Margins/VBoxContainer/MenuButton

var level2_button: Button
var stars_earned: int = 0

# For pulsing earned stars
var pulse_time: float = 0.0
var is_showing: bool = false

func _ready():
	hide()
	level2_button = get_node_or_null("Panel/Margins/VBoxContainer/Level2Button")

	print("🎯 Win screen initialized")
	if GameManager:
		GameManager.game_won.connect(_on_game_won)


func _process(delta: float) -> void:
	if not is_showing:
		return
	# Pulse earned stars gently
	pulse_time += delta * 2.5
	var pulse = 0.85 + 0.15 * sin(pulse_time)
	var gold_pulse = Color(1.0 * pulse, 0.84 * pulse, 0.0, 1.0)
	if stars_earned >= 1:
		star1.modulate = gold_pulse
	if stars_earned >= 2:
		star2.modulate = gold_pulse
	if stars_earned >= 3:
		star3.modulate = gold_pulse


func _on_game_won(stars: int):
	stars_earned = stars
	print("🏆 Game won! Stars: ", stars, " — waiting 4s...")
	await get_tree().create_timer(4.0).timeout
	print("✅ Showing win screen!")
	show()
	is_showing = true
	display_stars(stars)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if level2_button and not level2_button.pressed.is_connected(_on_level_2_button_pressed):
		level2_button.pressed.connect(_on_level_2_button_pressed)
	if retry_button and not retry_button.pressed.is_connected(_on_retry_button_pressed):
		retry_button.pressed.connect(_on_retry_button_pressed)
	if menu_button and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)


func display_stars(count: int):
	var dim  = Color(0.22, 0.22, 0.22, 1.0)
	var gold = Color(1.0, 0.84, 0.0, 1.0)
	star1.modulate = gold if count >= 1 else dim
	star2.modulate = gold if count >= 2 else dim
	star3.modulate = gold if count >= 3 else dim


func _on_level_2_button_pressed():
	print("🎮 Level 2 button pressed!")
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen_Level2_Final.tscn")


func _on_retry_button_pressed():
	print("🔄 Retry button pressed!")
	get_tree().paused = false
	is_showing = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager:
		GameManager.reset_level()
		GameManager.start_timer()
	get_tree().reload_current_scene()


func _on_menu_button_pressed():
	print("🏠 Menu button pressed!")
	get_tree().paused = false
	is_showing = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")


func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			print("🎓 Q pressed — loading quiz...")
			get_tree().paused = false
			is_showing = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://Scenes/Levels/quiz.tscn")

extends Control

@onready var retry_button  = $Panel/Margins/VBoxContainer/RetryButton
@onready var menu_button   = $Panel/Margins/VBoxContainer/MenuButton
@onready var title_label   = $Panel/Margins/VBoxContainer/Title
@onready var message_label = $Panel/Margins/VBoxContainer/Message
@onready var icon_label    = $Panel/Margins/VBoxContainer/IconLabel

func _ready():
	hide()
	if GameManager:
		GameManager.game_lost.connect(_on_game_lost)
		if GameManager.has_signal("game_busted"):
			GameManager.game_busted.connect(_on_game_busted)


func _on_game_lost():
	if GameManager.has_meta("busted") and GameManager.get_meta("busted") == true:
		GameManager.set_meta("busted", false)
		_show_busted()
	else:
		_show_times_up()


func _on_game_busted():
	_show_busted()


func _show_times_up():
	icon_label.text    = "⏱"
	title_label.text   = "TIME'S UP!"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1, 1.0))
	message_label.text = "You ran out of time!"
	_present()


func _show_busted():
	icon_label.text    = "🚔"
	title_label.text   = "YOU ARE BUSTED!"
	title_label.add_theme_color_override("font_color", Color(0.95, 0.05, 0.05, 1.0))
	message_label.text = "The police caught you. Better luck next time."
	_present()


func _present():
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_retry_button_pressed():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager:
		GameManager.reset_level()
		GameManager.start_timer()
	get_tree().reload_current_scene()


func _on_menu_button_pressed():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

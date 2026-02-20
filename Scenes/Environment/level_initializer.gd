extends Node3D

# This script should be attached to the Environment scene root
# to initialize the timer when the level starts

func _ready():
	await get_tree().process_frame

	if GameManager:
		# No hardcoded number — uses GameManager.time_limit set by difficulty in menu
		GameManager.start_timer()

# 🔑 SECRET SKIP TO LEVEL 2 - Press K key
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_K:
			get_tree().root.set_input_as_handled()
			skip_to_level_2()

func skip_to_level_2():
	get_tree().change_scene_to_file("res://Scenes/Levels/LoadingScreen_Level2_Final.tscn")

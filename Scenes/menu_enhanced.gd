extends Control

# Add your level scene paths here
var levels = [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
]

var level_names = [
	"Level 1",
	"Level 2",
	"Level 3",
]

@onready var level_option: OptionButton = $MainContainer/LeftPanel/LevelOptionButton

func _ready():
	_populate_level_options()

func _populate_level_options():
	level_option.clear()
	for name in level_names:
		level_option.add_item(name)

func _on_start_button_pressed():
	var selected = level_option.selected
	if selected >= 0 and selected < levels.size():
		get_tree().change_scene_to_file(levels[selected])
	else:
		# Default to first level if nothing selected
		get_tree().change_scene_to_file(levels[0])

func _on_quit_button_pressed():
	get_tree().quit()

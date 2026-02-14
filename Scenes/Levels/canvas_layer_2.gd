extends CanvasLayer

@onready var orb_counter: Label = $VBoxContainer/OrbCounter

func _ready():
	# Connect to the correct signals from GameManager
	if GameManager.has_signal("orbs_updated"):
		GameManager.orbs_updated.connect(_update_counter)
	
	if GameManager.has_signal("all_orbs_collected"):
		GameManager.all_orbs_collected.connect(_on_win)

func _update_counter(collected: int, total: int):
	orb_counter.text = "Barrel: " + str(collected) + " / " + str(total)

func _on_win():
	# Show win message or change scene
	print("ALL CANS COLLECTED! YOU WIN!")
	# get_tree().change_scene_to_file("res://win.tscn")

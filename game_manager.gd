extends Node

signal show_orb_popup_signal(title: String, text: String, image: Texture2D)
signal hide_orb_popup_signal
signal level_complete_signal(level_name: String)
signal orbs_updated(collected: int, total: int)
signal all_orbs_collected

var total_orbs: int = 0
var collected_orbs: int = 0
var current_level: String = "Level 1"

func initialize_orbs(count: int):
	total_orbs = count
	collected_orbs = 0
	print("Level initialized with ", total_orbs, " orbs to collect")

func collect_orb():
	collected_orbs += 1
	print("Orbs collected: ", collected_orbs, " of ", total_orbs)
	orbs_updated.emit(collected_orbs, total_orbs)
	
	if collected_orbs >= total_orbs:
		print("ALL ORBS COLLECTED!")
		all_orbs_collected.emit()
		level_complete_signal.emit(current_level)

func show_orb_popup(title: String, text: String, image: Texture2D = null):
	show_orb_popup_signal.emit(title, text, image)

func hide_orb_popup():
	hide_orb_popup_signal.emit()

func set_level_name(level: String):
	current_level = level

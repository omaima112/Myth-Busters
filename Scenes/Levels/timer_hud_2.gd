extends Control

@onready var timer_label = $TimerLabel

func _ready():
	if not GameManager:
		return
	
	# Disconnect first to avoid duplicate connections on reload
	if GameManager.timer_updated.is_connected(_on_timer_updated):
		GameManager.timer_updated.disconnect(_on_timer_updated)
	
	GameManager.timer_updated.connect(_on_timer_updated)
	
	# Set timer to 5 minutes (300 seconds)
	if GameManager.has_method("set_time_remaining"):
		GameManager.set_time_remaining(300)
	elif GameManager.has_method("set_time"):
		GameManager.set_time(300)
	elif GameManager.has_method("reset_timer"):
		GameManager.reset_timer()
	
	timer_label.text = GameManager.get_time_display()
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	
	if GameManager.has_method("start_timer"):
		GameManager.start_timer()

func _on_timer_updated(time_remaining: int):
	if timer_label == null:
		return
	
	var minutes = time_remaining / 60
	var seconds = time_remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Color feedback based on time remaining
	if time_remaining <= 30 and time_remaining > 0:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining <= 60:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

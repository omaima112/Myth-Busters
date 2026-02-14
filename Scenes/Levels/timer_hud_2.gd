extends Control

@onready var timer_label = $TimerLabel

func _ready():
	# Connect to GameManager signals
	if GameManager:
		# Disconnect first to avoid duplicate connections on reload
		if GameManager.timer_updated.is_connected(_on_timer_updated):
			GameManager.timer_updated.disconnect(_on_timer_updated)
		GameManager.timer_updated.connect(_on_timer_updated)
		# Force display to show reset time immediately
		timer_label.text = GameManager.get_time_display()
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func _on_timer_updated(time_remaining: int):
	"""Update the timer display — left numbers = minutes, right numbers = seconds"""
	var minutes = time_remaining / 60
	var seconds = time_remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	# Color feedback scaled for a 5-minute (300s) timer
	if time_remaining <= 30 and time_remaining > 0:
		# Under 30 seconds — red warning
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining <= 60:
		# Under 1 minute — orange caution
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		# Plenty of time — white (normal)
		timer_label.add_theme_color_override("font_color", Color.WHITE)

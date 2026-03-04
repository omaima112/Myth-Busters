extends CanvasLayer

# UI elements
var radiation_label: Label
var radiation_bar: ProgressBar

# Current radiation level (0-100)
var current_radiation := 0.0

func _ready():
	radiation_label = $Control/VBoxContainer/Label
	radiation_bar = $Control/VBoxContainer/ProgressBar
	
	if radiation_bar:
		radiation_bar.min_value = 0
		radiation_bar.max_value = 1
		radiation_bar.value = 0
		radiation_bar.show_percentage = false
	
	visible = true
	set_radiation(0.0)
	
	# Hide when game ends
	if GameManager:
		GameManager.game_won.connect(func(_s): _hide_ui())
		GameManager.game_lost.connect(func(): _hide_ui())
		if GameManager.has_signal("game_busted"):
			GameManager.game_busted.connect(func(): _hide_ui())

func _process(_delta):
	if radiation_label:
		radiation_label.text = "☢ RADIATION LEVEL: %.1f μSv/h" % current_radiation
		
		if current_radiation < 0.5:
			radiation_label.modulate = Color(0.2, 1.0, 0.2)
		elif current_radiation < 5:
			radiation_label.modulate = Color(1.0, 1.0, 0.0)
		elif current_radiation < 10:
			radiation_label.modulate = Color(1.0, 0.5, 0.0)
		else:
			radiation_label.modulate = Color(1.0, 0.0, 0.0)
	
	if radiation_bar:
		radiation_bar.value = current_radiation
		
		if current_radiation < 0.5:
			radiation_bar.modulate = Color(0.2, 1.0, 0.2)
		elif current_radiation < 5:
			radiation_bar.modulate = Color(1.0, 1.0, 0.0)
		elif current_radiation < 10:
			radiation_bar.modulate = Color(1.0, 0.5, 0.0)
		else:
			radiation_bar.modulate = Color(1.0, 0.0, 0.0)

func set_radiation(value: float):
	current_radiation = clamp(value, 0.0, 30)
	
	if radiation_bar:
		radiation_bar.value = current_radiation

func _hide_ui():
	visible = false

func _show_ui():
	visible = true

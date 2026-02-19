extends Control

@onready var timer_label: Label = $TimerContainer/InnerRow/TimerLabel
@onready var icon_label: Label = $TimerContainer/InnerRow/IconLabel

const TOTAL_TIME: float = 420.0

const COLOR_NORMAL = Color(0.9,  1.0,  0.95, 1.0)
const COLOR_YELLOW = Color(1.0,  0.92, 0.2,  1.0)
const COLOR_ORANGE = Color(1.0,  0.5,  0.08, 1.0)
const COLOR_RED    = Color(1.0,  0.15, 0.15, 1.0)

const GLOW_NORMAL = Color(0.4, 1.0, 0.8, 0.0)
const GLOW_YELLOW = Color(1.0, 0.85, 0.0, 0.55)
const GLOW_ORANGE = Color(1.0, 0.4,  0.0, 0.65)
const GLOW_RED    = Color(1.0, 0.0,  0.0, 0.75)

var bounce_time: float = 0.0
var base_y: float = 0.0
var is_bouncing: bool = false

func _ready():
	base_y = timer_label.position.y
	if GameManager:
		GameManager.timer_updated.connect(_on_timer_updated)
		timer_label.text = GameManager.get_time_display()
	_apply_style(TOTAL_TIME)


func _process(delta: float) -> void:
	if not is_bouncing:
		return
	bounce_time += delta * 8.0
	var offset = sin(bounce_time) * 4.0
	timer_label.position.y = base_y + offset
	icon_label.position.y  = base_y + offset


func _on_timer_updated(time_remaining: int):
	var minutes = time_remaining / 60
	var seconds = time_remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	_apply_style(float(time_remaining))


func _apply_style(t: float):
	var half = TOTAL_TIME / 2.0  # 210s

	var font_color: Color
	var glow_color: Color

	if t > half:
		font_color = COLOR_NORMAL
		glow_color = GLOW_NORMAL
		is_bouncing = false

	elif t > 120.0:
		var ratio = (t - 120.0) / (half - 120.0)
		font_color = COLOR_YELLOW.lerp(COLOR_NORMAL, ratio)
		glow_color = GLOW_YELLOW.lerp(GLOW_NORMAL, ratio)
		is_bouncing = false

	elif t > 30.0:
		var ratio = (t - 30.0) / (120.0 - 30.0)
		font_color = COLOR_ORANGE.lerp(COLOR_YELLOW, ratio)
		glow_color = GLOW_ORANGE.lerp(GLOW_YELLOW, ratio)
		is_bouncing = false

	elif t > 0.0:
		font_color = COLOR_RED
		glow_color = GLOW_RED
		if not is_bouncing:
			is_bouncing = true
			bounce_time = 0.0

	else:
		font_color = COLOR_RED
		glow_color = GLOW_RED
		is_bouncing = false
		timer_label.position.y = base_y
		icon_label.position.y  = base_y

	timer_label.add_theme_color_override("font_color", font_color)
	icon_label.add_theme_color_override("font_color", font_color)

	if timer_label.label_settings:
		timer_label.label_settings.shadow_color = glow_color
		timer_label.label_settings.shadow_size  = 12 if t <= 30.0 else 6
		timer_label.label_settings.font_color   = font_color

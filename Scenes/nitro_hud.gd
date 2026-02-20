extends Control

# Node refs (set by tscn)
@onready var nitro_bar: ProgressBar     = $NitroContainer/Margins/VLayout/BarArea/NitroBar
@onready var fill_glow: ColorRect       = $NitroContainer/Margins/VLayout/BarArea/FillGlow
@onready var boost_label: Label         = $NitroContainer/Margins/VLayout/BoostLabel
@onready var icon_label: Label          = $NitroContainer/Margins/VLayout/IconRow/IconLabel
@onready var key_hint: Label            = $NitroContainer/Margins/VLayout/IconRow/KeyHint

# Colors
const COLOR_FULL    = Color(0.0,  1.0,  1.0,  1.0)   # cyan
const COLOR_MID     = Color(0.2,  0.85, 0.2,  1.0)   # green
const COLOR_LOW     = Color(1.0,  0.55, 0.0,  1.0)   # orange
const COLOR_EMPTY   = Color(0.8,  0.1,  0.1,  1.0)   # red

const GLOW_BOOST    = Color(0.0,  1.0,  1.0,  0.35)
const GLOW_NONE     = Color(0.0,  1.0,  1.0,  0.0)

var jeep: Node = null
var pulse_time: float = 0.0

func _ready():
	await get_tree().process_frame
	jeep = get_tree().root.find_child("Jeep", true, false)
	if jeep:
		nitro_bar.max_value = jeep.max_nitro
	
	# Hide when game ends
	if GameManager:
		GameManager.game_won.connect(func(_s): visible = false)
		GameManager.game_lost.connect(func(): visible = false)
		if GameManager.has_signal("game_busted"):
			GameManager.game_busted.connect(func(): visible = false)


func _process(delta: float) -> void:
	if not jeep:
		return

	var nitro: float   = jeep.current_nitro
	var max_n: float   = jeep.max_nitro
	var boosting: bool = jeep.is_boosting
	var ratio: float   = nitro / max_n if max_n > 0 else 0.0

	# Update bar
	nitro_bar.value = nitro

	# Bar fill color based on ratio
	var bar_color: Color
	if ratio > 0.5:
		bar_color = COLOR_MID.lerp(COLOR_FULL, (ratio - 0.5) / 0.5)
	elif ratio > 0.25:
		bar_color = COLOR_LOW.lerp(COLOR_MID, (ratio - 0.25) / 0.25)
	else:
		bar_color = COLOR_EMPTY.lerp(COLOR_LOW, ratio / 0.25)

	nitro_bar.modulate = bar_color

	# Glow behind bar — pulses when boosting
	if boosting:
		pulse_time += delta * 6.0
		var alpha = 0.2 + 0.15 * sin(pulse_time)
		fill_glow.color = Color(bar_color.r, bar_color.g, bar_color.b, alpha)
		boost_label.visible = true
		boost_label.modulate.a = 0.7 + 0.3 * sin(pulse_time * 2.0)
		icon_label.modulate = Color(1.0, 1.0, 0.3, 1.0)   # yellow flash on icon
	else:
		pulse_time = 0.0
		fill_glow.color = GLOW_NONE
		boost_label.visible = false
		icon_label.modulate = bar_color

	# Dim key hint when empty
	key_hint.modulate.a = 0.4 if ratio <= 0.0 else 1.0

extends Control

@onready var overlay: ColorRect     = $Overlay
@onready var alert_label: Label     = $CenterContainer/VLayout/AlertLabel
@onready var countdown_label: Label = $CenterContainer/VLayout/CountdownLabel
@onready var sub_label: Label       = $CenterContainer/VLayout/SubLabel
@onready var bar_fill: ColorRect    = $BottomBar/BarFill

const BUST_TIME: float = 5.0
var elapsed: float = 0.0
var active: bool = false
var flash_time: float = 0.0
var bar_width: float = 0.0


func _ready():
	hide()
	if GameManager:
		if GameManager.has_signal("player_in_bust_zone"):
			GameManager.player_in_bust_zone.connect(_on_entered_zone)
		if GameManager.has_signal("player_left_bust_zone"):
			GameManager.player_left_bust_zone.connect(_on_left_zone)


func _on_entered_zone():
	# Show bust screen and start countdown — car keeps driving
	show()
	active = true
	elapsed = 0.0
	flash_time = 0.0
	bar_width = get_viewport_rect().size.x
	bar_fill.size.x = bar_width
	countdown_label.text = "5"
	print("🚨 Bust screen ON")


func _on_left_zone():
	# Player escaped — hide and fully reset
	active = false
	hide()
	elapsed = 0.0
	bar_fill.size.x = get_viewport_rect().size.x
	print("✅ Bust screen OFF — player escaped")


func _process(delta: float) -> void:
	if not active:
		return

	elapsed += delta
	flash_time += delta

	# Countdown
	var remaining = max(0.0, BUST_TIME - elapsed)
	countdown_label.text = str(int(ceil(remaining)))

	# Bar depletes
	var ratio = 1.0 - (elapsed / BUST_TIME)
	bar_fill.size.x = bar_width * clamp(ratio, 0.0, 1.0)

	# Flashing overlay
	var flash_alpha = 0.15 + 0.12 * sin(flash_time * 12.0)
	overlay.color = Color(0.85, 0.0, 0.05, flash_alpha)

	# Flashing BUSTING label
	alert_label.modulate.a = 0.7 + 0.3 * sin(flash_time * 8.0)

	# Timer ran out while still in zone — BUSTED
	if elapsed >= BUST_TIME:
		active = false
		_trigger_busted()


func _trigger_busted():
	hide()
	print("🚔 BUSTED!")
	if GameManager and GameManager.has_signal("game_busted"):
		GameManager.game_busted.emit()
	elif GameManager:
		GameManager.set_meta("busted", true)
		GameManager.game_lost.emit()

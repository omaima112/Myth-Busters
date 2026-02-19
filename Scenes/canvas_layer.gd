extends CanvasLayer

@onready var orb_counter: Label       = $VBoxContainer/OrbCounter
@onready var siren_container: Control = $SirenContainer
@onready var red_box: PanelContainer  = $SirenContainer/RedBox
@onready var blue_box: PanelContainer = $SirenContainer/BlueBox

var is_chasing: bool = false
var flash_time: float = 0.0
const FLASH_SPEED: float = 4.0  # flashes per second

var style_red: StyleBoxFlat
var style_blue: StyleBoxFlat
var style_dim: StyleBoxFlat


func _ready():
	# Build styleboxes in code
	style_red = StyleBoxFlat.new()
	style_red.bg_color = Color(1.0, 0.05, 0.05, 1.0)
	style_red.set_corner_radius_all(5)
	style_red.shadow_color = Color(1.0, 0.0, 0.0, 0.85)
	style_red.shadow_size = 10

	style_blue = StyleBoxFlat.new()
	style_blue.bg_color = Color(0.1, 0.4, 1.0, 1.0)
	style_blue.set_corner_radius_all(5)
	style_blue.shadow_color = Color(0.0, 0.3, 1.0, 0.85)
	style_blue.shadow_size = 10

	style_dim = StyleBoxFlat.new()
	style_dim.bg_color = Color(0.12, 0.12, 0.15, 0.5)
	style_dim.set_corner_radius_all(5)

	if GameManager:
		GameManager.orbs_updated.connect(_on_orbs_updated)
		if GameManager.has_signal("police_chase_started"):
			GameManager.police_chase_started.connect(_on_chase_start)
		if GameManager.has_signal("police_chase_ended"):
			GameManager.police_chase_ended.connect(_on_chase_end)


func _on_orbs_updated(collected: int, total: int):
	orb_counter.text = "Barrels: %d / %d" % [collected, total]


func _on_chase_start():
	is_chasing = true
	flash_time = 0.0
	siren_container.visible = true


func _on_chase_end():
	is_chasing = false
	siren_container.visible = false


func _process(delta: float) -> void:
	if not is_chasing:
		return

	flash_time += delta * FLASH_SPEED

	# Hard alternating flash — red ON = blue OFF, then swap
	var red_active: bool = fmod(flash_time, 2.0) < 1.0

	red_box.add_theme_stylebox_override("panel", style_red if red_active else style_dim)
	blue_box.add_theme_stylebox_override("panel", style_blue if not red_active else style_dim)

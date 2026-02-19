extends Control

@onready var siren_box: HBoxContainer = $SirenBox
@onready var red_box: PanelContainer  = $SirenBox/RedBox
@onready var blue_box: PanelContainer = $SirenBox/BlueBox

const FLASH_SPEED: float = 5.0

var flash_time: float = 0.0
var is_chasing: bool = false
var check_timer: float = 0.0

var style_red: StyleBoxFlat
var style_blue: StyleBoxFlat
var style_dim: StyleBoxFlat


func _ready():
	_build_styles()
	siren_box.visible = false
	red_box.add_theme_stylebox_override("panel", style_dim)
	blue_box.add_theme_stylebox_override("panel", style_dim)
	print("🚨 PoliceSirenHUD _ready — node: ", name, " | parent: ", get_parent().name)


func _build_styles():
	style_red = StyleBoxFlat.new()
	style_red.bg_color = Color(1.0, 0.05, 0.05, 1.0)
	style_red.set_corner_radius_all(6)
	style_red.shadow_color = Color(1.0, 0.0, 0.0, 0.9)
	style_red.shadow_size = 10

	style_blue = StyleBoxFlat.new()
	style_blue.bg_color = Color(0.08, 0.35, 1.0, 1.0)
	style_blue.set_corner_radius_all(6)
	style_blue.shadow_color = Color(0.0, 0.3, 1.0, 0.9)
	style_blue.shadow_size = 10

	style_dim = StyleBoxFlat.new()
	style_dim.bg_color = Color(0.1, 0.1, 0.12, 0.55)
	style_dim.set_corner_radius_all(6)


func _process(delta: float) -> void:
	# Debug: every 2 seconds print enemy count
	check_timer += delta
	if check_timer >= 2.0:
		check_timer = 0.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		print("🔍 SirenHUD check — enemies found: ", enemies.size(), " | any chasing: ", _any_chasing(enemies))

	var any_chasing = _any_chasing(get_tree().get_nodes_in_group("enemies"))

	if any_chasing != is_chasing:
		is_chasing = any_chasing
		siren_box.visible = is_chasing
		flash_time = 0.0
		print("🚨 Siren HUD visible: ", is_chasing)
		if not is_chasing:
			red_box.add_theme_stylebox_override("panel", style_dim)
			blue_box.add_theme_stylebox_override("panel", style_dim)

	if not is_chasing:
		return

	flash_time += delta * FLASH_SPEED
	var red_active: bool = fmod(flash_time, 2.0) < 1.0
	red_box.add_theme_stylebox_override("panel",  style_red  if red_active     else style_dim)
	blue_box.add_theme_stylebox_override("panel", style_blue if not red_active else style_dim)


func _any_chasing(enemies: Array) -> bool:
	for enemy in enemies:
		if "is_chasing" in enemy and enemy.is_chasing:
			return true
	return false

extends CanvasLayer

@export var next_scene: String = "res://Scenes/main.tscn"
@export var min_display_time: float = 4.0

var start_time: float = 0.0
var is_loading: bool = false
var scene_ready: bool = false

# Educational tips array - Level 1 focused
var loading_tips = [
	"A banana contains more radiation than properly stored nuclear waste!",
	"Modern nuclear reactors have 5 independent layers of safety containment.",
	"Nuclear power is 350 times safer than coal per unit of energy produced.",
	"Flying in an airplane exposes you to more radiation than working at a nuclear plant.",
	"Nuclear energy has the lowest death rate per terawatt-hour: just 0.07 deaths.",
	"Nuclear plants can operate continuously for 18-24 months without refueling.",
	"A single nuclear fuel pellet the size of a fingertip contains massive energy.",
	"Natural radiation varies worldwide - some beaches have higher levels than reactors.",
	"Nuclear power plants use only 5% enriched uranium, far too low for weapons.",
	"The entire U.S. nuclear waste from 60 years would fit in one football field.",
	"Nuclear energy requires 2000x less land than solar for the same power output.",
	"Civilian nuclear programs operate under strict international inspections.",
	"Nuclear reactors cannot explode like atomic bombs - the physics is different.",
	"Background radiation exists everywhere - from soil, rocks, and even food.",
]

var current_tip: String = ""

func _ready():
	if GameManager and GameManager.next_scene != "":
		next_scene = GameManager.next_scene
		GameManager.next_scene = ""

	print("Loading screen initialized")
	print("Target scene: ", next_scene)
	
	start_time = float(Time.get_ticks_msec()) / 1000.0
	is_loading = true
	
	if not has_node("TipContainer"):
		create_tip_label()

	randomize()
	current_tip = loading_tips[randi() % loading_tips.size()]
	call_deferred("display_tip")
	
	ResourceLoader.load_threaded_request(next_scene)


func create_tip_label():
	# --- Outer container anchored to bottom-center of screen ---
	# --- Outer panel for background/border ---
	var container = PanelContainer.new()
	container.name = "TipContainer"

	container.set_anchors_preset(Control.PRESET_CENTER)
	container.anchor_top    = 0.35
	container.anchor_bottom = 0.65
	container.anchor_left   = 0.05
	container.anchor_right  = 0.95
	container.offset_left   = 0.0
	container.offset_right  = 0.0
	container.offset_top    = 0.0
	container.offset_bottom = 0.0
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var style = StyleBoxFlat.new()
	style.bg_color            = Color(0.05, 0.03, 0.02, 0.82)
	style.border_width_left   = 2
	style.border_width_top    = 2
	style.border_width_right  = 2
	style.border_width_bottom = 2
	style.border_color        = Color(0.6, 0.4, 0.2, 0.7)
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size  = 10
	style.content_margin_left   = 30.0
	style.content_margin_right  = 30.0
	style.content_margin_top    = 20.0
	style.content_margin_bottom = 20.0
	container.add_theme_stylebox_override("panel", style)
	add_child(container)

	# --- VBox so heading + divider + tip stack vertically ---
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	container.add_child(vbox)

	# --- "FACT" label ---
	var fact_heading = Label.new()
	fact_heading.name = "FactHeading"
	fact_heading.text = "FACT"
	fact_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact_heading.add_theme_font_size_override("font_size", 32)
	fact_heading.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1, 1.0))
	fact_heading.add_theme_constant_override("outline_size", 3)
	fact_heading.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 1.0))
	vbox.add_child(fact_heading)

	# --- Divider ---
	var divider = Label.new()
	divider.name = "Divider"
	divider.text = "────────────────────────────────"
	divider.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	divider.add_theme_font_size_override("font_size", 14)
	divider.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2, 0.6))
	vbox.add_child(divider)

	# --- Tip label ---
	var tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode        = TextServer.AUTOWRAP_WORD
	tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_label.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	tip_label.add_theme_font_size_override("font_size", 20)
	tip_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.5, 1.0))
	tip_label.add_theme_constant_override("outline_size", 3)
	tip_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 1.0))
	vbox.add_child(tip_label)


func display_tip():
	var tip_label = get_node_or_null("TipContainer/VBox/TipLabel")
	if not tip_label:
		tip_label = get_node_or_null("TipLabel")
	if tip_label:
		tip_label.text = current_tip

func _process(_delta):
	if not is_loading:
		return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	var elapsed = float(Time.get_ticks_msec()) / 1000.0 - start_time
	
	update_loading_text(elapsed)
	update_progress_bar(progress, elapsed)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		scene_ready = true
	
	if scene_ready and elapsed >= min_display_time:
		print("Loading complete! Switching to: ", next_scene)
		is_loading = false
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("ERROR: Failed to load scene!")
		is_loading = false

func update_loading_text(elapsed: float):
	var label = get_node_or_null("SplashImage/Label")
	if label:
		var dots = ""
		var dot_count = int((elapsed * 2.0)) % 4
		for i in range(dot_count):
			dots += "."
		label.text = "LOADING" + dots

func update_progress_bar(progress: Array, elapsed: float):
	var progress_bar = get_node_or_null("ProgressBar")
	if progress_bar:
		var real_progress = progress[0] if progress.size() > 0 else 0.0
		var time_progress = clamp(elapsed / min_display_time, 0.0, 1.0)
		var display_progress = max(real_progress, time_progress)
		progress_bar.value = display_progress * 100.0

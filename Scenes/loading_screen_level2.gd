extends CanvasLayer

@export var next_scene: String = "res://Scenes/Levels/main_2.tscn"
@export var min_display_time: float = 2.0

var start_time: float = 0.0
var is_loading: bool = false

# Educational tips array - Level 2 focused (Hospital/Coal)
var loading_tips = [
	"Coal plants release 100x more radiation into the environment than nuclear plants.",
	"CT scans expose you to more radiation than living near a nuclear reactor.",
	"Kerala, India has higher natural background radiation than nuclear plant vicinities.",
	"Medical X-rays use electromagnetic radiation - similar to visible light but higher energy.",
	"A single CT scan delivers 7-10 millisieverts - far more than annual nuclear plant exposure.",
	"Coal ash contains uranium, thorium, and other radioactive elements naturally.",
	"Hospital radiation rooms have the highest radiation in our game - not the reactor.",
	"Coal combustion releases mercury, arsenic, and radioactive particles into the air.",
	"Nuclear plants are surrounded by exclusion zones monitored constantly for safety.",
	"Coal mining causes 24.6 deaths per terawatt-hour compared to nuclear's 0.07.",
	"Potassium-40 in bananas makes them slightly radioactive - completely harmless.",
	"Coal plants produce over 100 million tons of toxic ash waste annually.",
	"Nuclear waste is 95% recyclable and stored safely in solid concrete containers.",
	"Radiation exposure from coal plants affects nearby communities more than nuclear.",
	"Medical isotopes used in hospitals come from nuclear reactors worldwide.",
	"Coal emissions cause respiratory diseases affecting millions annually.",
	"The ALARA principle: As Low As Reasonably Achievable - used in radiation safety.",
	"Natural background radiation varies by location due to soil composition.",
	"Thorium in monazite sand causes Kerala's higher natural radiation levels.",
	"Coal generates 820 grams of CO2 per kilowatt-hour versus nuclear's 12 grams."
]

var current_tip: String = ""

func _ready():
	print("Loading screen initialized")
	print("Target scene: ", next_scene)
	
	start_time = Time.get_ticks_msec() / 1000.0
	is_loading = true
	
	if not has_node("TipContainer"):
		create_tip_label()

	randomize()
	current_tip = loading_tips[randi() % loading_tips.size()]
	call_deferred("display_tip")
	
	ResourceLoader.load_threaded_request(next_scene)


func create_tip_label():
	# --- PanelContainer for background/border ---
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
	style.bg_color                   = Color(0.05, 0.03, 0.02, 0.82)
	style.border_width_left          = 2
	style.border_width_top           = 2
	style.border_width_right         = 2
	style.border_width_bottom        = 2
	style.border_color               = Color(0.6, 0.4, 0.2, 0.7)
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color               = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size                = 10
	style.content_margin_left        = 24.0
	style.content_margin_right       = 24.0
	style.content_margin_top         = 16.0
	style.content_margin_bottom      = 16.0
	container.add_theme_stylebox_override("panel", style)
	add_child(container)

	# --- VBoxContainer so items stack vertically ---
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	container.add_child(vbox)

	# --- "FACT" heading ---
	var fact_heading = Label.new()
	fact_heading.name = "FactHeading"
	fact_heading.text = "FACT"
	fact_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact_heading.add_theme_font_size_override("font_size", 32)
	fact_heading.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1, 1.0))
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

	# --- Fact text ---
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
	if tip_label:
		tip_label.text = current_tip

func _process(_delta):
	if not is_loading:
		return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
	
	update_loading_text(elapsed)
	update_progress_bar(progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= min_display_time:
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

func update_progress_bar(progress: Array):
	var progress_bar = get_node_or_null("ProgressBar")
	if progress_bar and progress.size() > 0:
		progress_bar.value = int(progress[0] * 200)

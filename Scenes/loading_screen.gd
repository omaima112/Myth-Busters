extends CanvasLayer

@export var next_scene: String = "res://Scenes/main.tscn"
@export var min_display_time: float = 2.0

var start_time: float = 0.0
var is_loading: bool = false

# Educational tips array - Level 1 focused
var loading_tips = [
	"Nuclear energy prevents 2 million deaths annually by replacing coal.",
	"A banana contains more radiation than properly stored nuclear waste.",
	"Modern nuclear reactors have 5 independent layers of safety containment.",
	"Nuclear energy produces zero carbon emissions during operation.",
	"One uranium pellet produces as much energy as 1 ton of coal.",
	"Nuclear power is 350 times safer than coal per unit of energy produced.",
	"Flying in an airplane exposes you to more radiation than working at a nuclear plant.",
	"Nuclear fuel is 95% recyclable - we can reuse it to generate more power.",
	"Nuclear energy has the lowest death rate per terawatt-hour: just 0.07 deaths.",
	"Ocean water naturally contains uranium - about 3 parts per billion.",
	"Nuclear plants can operate continuously for 18-24 months without refueling.",
	"A single nuclear fuel pellet the size of a fingertip contains massive energy.",
	"Natural radiation varies worldwide - some beaches have higher levels than reactors.",
	"Nuclear power plants use only 5% enriched uranium, far too low for weapons.",
	"The entire U.S. nuclear waste from 60 years would fit in one football field.",
	"Nuclear energy requires 2000x less land than solar for the same power output.",
	"Civilian nuclear programs operate under strict international inspections.",
	"Nuclear reactors cannot explode like atomic bombs - the physics is different.",
	"Background radiation exists everywhere - from soil, rocks, and even food.",
	"Nuclear waste is stored in solid form in secure, monitored facilities."
]

var current_tip: String = ""

func _ready():
	print("Loading screen initialized")
	print("Target scene: ", next_scene)
	
	start_time = Time.get_ticks_msec() / 1000.0
	is_loading = true
	
	# Create tip label if it doesn't exist
	if not has_node("TipLabel"):
		create_tip_label()
	
	# Pick random tip
	randomize()
	current_tip = loading_tips[randi() % loading_tips.size()]
	display_tip()
	
	# Start loading the scene in background
	ResourceLoader.load_threaded_request(next_scene)

func create_tip_label():
	"""Create the tip label programmatically"""
	var tip_label = Label.new()
	tip_label.name = "TipLabel"
	
	# Position RIGHT side
	tip_label.position = Vector2(28, 560)  # Far right
	tip_label.size = Vector2(900, 100)       # Wide label
	
	# Alignment - RIGHT
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT  # Right-aligned text
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# Theme styling - brownish color
	tip_label.add_theme_font_size_override("font_size", 18)
	tip_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4))
	tip_label.add_theme_constant_override("outline_size", 2)
	tip_label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.1))
	
	# Add to scene
	add_child(tip_label)
func display_tip():
	"""Display the educational tip"""
	var tip_label = get_node_or_null("TipLabel")
	if tip_label:
		tip_label.text = current_tip

func _process(_delta):
	if not is_loading:
		return
	
	# Get loading status
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	# Calculate elapsed time
	var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
	
	# Update loading text
	update_loading_text(elapsed)
	
	# Update progress bar if it exists
	update_progress_bar(progress)
	
	# When loaded and minimum time passed, switch scene
	if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= min_display_time:
		print("Loading complete! Switching to: ", next_scene)
		is_loading = false
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("ERROR: Failed to load scene!")
		is_loading = false

func update_loading_text(elapsed: float):
	"""Update the loading text with animated dots"""
	var label = get_node_or_null("SplashImage/Label")
	if label:
		var dots = ""
		var dot_count = int((elapsed * 2.0)) % 4
		for i in range(dot_count):
			dots += "."
		label.text = "LOADING" + dots

func update_progress_bar(progress: Array):
	"""Update the progress bar if it exists"""
	var progress_bar = get_node_or_null("ProgressBar")
	if progress_bar and progress.size() > 0:
		progress_bar.value = int(progress[0] * 200)

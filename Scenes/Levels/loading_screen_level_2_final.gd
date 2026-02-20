extends CanvasLayer

@export var next_scene: String = "res://Scenes/Levels/main_2.tscn"
@export var min_display_time: float = 2.0

var start_time: float = 0.0
var is_loading: bool = false

# Educational tips array - Level 2 focused (Hospital/Coal)
var loading_tips = [
	"Coal plants release 100x more radiation into the environment than nuclear plants.",
	"Kerala, India has higher natural background radiation than nuclear plant vicinities.",
	"Medical X-rays use electromagnetic radiation - similar to visible light but higher energy.",
	"A single CT scan delivers 7-10 millisieverts - far more than annual nuclear plant exposure.",
	"Coal ash contains uranium, thorium, and other radioactive elements naturally.",
	"Hospital radiation rooms have the highest radiation in our game - not the reactor.",
	"Coal combustion releases mercury, arsenic, and radioactive particles into the air.",
	"Nuclear plants are surrounded by exclusion zones monitored constantly for safety.",
	"Coal mining causes 24.6 deaths per terawatt-hour compared to nuclear's 0.07.",
	"Potassium-40 in bananas makes them slightly radioactive - completely harmless.",
	"Nuclear waste is 95% recyclable and stored safely in solid concrete containers.",
	"Radiation exposure from coal plants affects nearby communities more than nuclear.",
	"Medical isotopes used in hospitals come from nuclear reactors worldwide.",
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
	
	# Position - SAME AS SCREEN 1
	tip_label.position = Vector2(28, 560)
	tip_label.size = Vector2(900, 100)  # ← CHANGED FROM 600 to 900!
	
	# Alignment - RIGHT
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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

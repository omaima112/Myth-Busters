extends CanvasLayer

@export var next_scene: String = "res://Scenes/Levels/main_2.tscn"
@export var min_display_time: float = 2.0

var start_time: float = 0.0
var is_loading: bool = false

func _ready():
	print("✅ Loading screen initialized")
	print("   Target scene: ", next_scene)
	
	start_time = Time.get_ticks_msec() / 1000.0
	is_loading = true
	
	# Start loading the scene in background
	ResourceLoader.load_threaded_request(next_scene)

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
		print("✅ Loading complete! Switching to: ", next_scene)
		is_loading = false
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("❌ ERROR: Failed to load scene!")
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

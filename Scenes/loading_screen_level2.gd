extends CanvasLayer

@export var next_scene: String = "res://Scenes/main_2.tscn"
@export var min_display_time: float = 2.0  # Minimum time to show splash (seconds)

var start_time: float = 0.0

func _ready():
	print("🔄 Loading screen started for Level 2")
	start_time = Time.get_ticks_msec() / 1000.0
	
	# Start loading the next scene
	ResourceLoader.load_threaded_request(next_scene)
	print("⏳ Loading Level 2 in background...")

func _process(_delta):
	# Check if scene is loaded
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	# Calculate elapsed time
	var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
	
	# Show loading progress
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		print("📊 Loading progress: ", int(progress[0] * 100), "%")
	
	# Change scene when loaded AND minimum time has passed
	if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= min_display_time:
		print("✅ Level 2 loaded! Showing scene...")
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)

extends Node

signal show_orb_popup_signal(title: String, text: String, image: Texture2D)
signal hide_orb_popup_signal
signal orbs_updated(collected: int, total: int)
signal all_orbs_collected
signal timer_updated(time_remaining: int)
signal game_won(stars: int)
signal game_lost

var total_orbs: int = 0
var collected_orbs: int = 0
var current_level: String = "Level 1"

# Timer variables
var time_limit: int = 420      # 7 minutes in seconds
var time_remaining_f: float = 420.0  # float for accurate delta subtraction
var time_remaining: int = 420        # int used for display / signals
var timer_running: bool = false

func _ready():
	pass

func _process(delta):
	if timer_running:
		time_remaining_f -= delta
		if time_remaining_f <= 0.0:
			time_remaining_f = 0.0
			time_remaining = 0
			timer_running = false
			timer_updated.emit(0)
			game_over_lose()
		else:
			time_remaining = int(time_remaining_f)
			timer_updated.emit(time_remaining)

func start_timer(duration: int = 420):
	"""Start the countdown timer with specified duration in seconds"""
	time_limit = duration
	time_remaining_f = float(duration)
	time_remaining = duration
	timer_running = true
	print("Timer started: ", format_time(time_remaining))

func stop_timer():
	"""Stop the timer"""
	timer_running = false

func format_time(seconds: int) -> String:
	"""Format seconds into MM:SS format"""
	@warning_ignore("integer_division")
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func get_time_display() -> String:
	"""Get the current time in display format"""
	return format_time(time_remaining)

func initialize_orbs(count: int):
	total_orbs = count
	collected_orbs = 0
	print("Level initialized with ", total_orbs, " orbs to collect")

func collect_orb():
	collected_orbs += 1
	print("Orbs collected: ", collected_orbs, " of ", total_orbs)
	orbs_updated.emit(collected_orbs, total_orbs)
	
	if collected_orbs >= total_orbs:
		print("ALL ORBS COLLECTED!")
		all_orbs_collected.emit()
		level_complete()

func level_complete():
	"""Handle level completion - calculate stars and show win screen"""
	stop_timer()
	var stars = calculate_stars()
	print("Level Complete! Stars: ", stars)
	game_won.emit(stars)

func game_over_lose():
	"""Handle game over when timer runs out"""
	print("Game Over - Time's up!")
	game_lost.emit()

func calculate_stars() -> int:
	"""Calculate star rating based on time remaining:
	   3 stars = completed with 2:00 or more remaining  (>= 120s)
	   2 stars = completed with 1:30 - 1:59 remaining   (>= 90s)
	   1 star  = completed with 0:30 - 1:29 remaining   (>= 30s)
	   0 stars = completed in last 30 seconds            (< 30s)
	"""
	if time_remaining >= 120:
		return 3
	elif time_remaining >= 90:
		return 2
	elif time_remaining >= 30:
		return 1
	else:
		return 0

func show_orb_popup(title: String, text: String, image: Texture2D = null):
	show_orb_popup_signal.emit(title, text, image)

func hide_orb_popup():
	hide_orb_popup_signal.emit()

func set_level_name(level: String):
	current_level = level

func reset_level():
	"""Reset the level for retry"""
	collected_orbs = 0
	time_remaining_f = float(time_limit)
	time_remaining = time_limit
	timer_running = false
	orbs_updated.emit(0, total_orbs)

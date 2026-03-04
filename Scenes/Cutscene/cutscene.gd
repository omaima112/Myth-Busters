extends CanvasLayer

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_btn: Button = $SkipButton

# After cutscene → loading screen → main.tscn
const LOADING_SCENE := "res://Scenes/LoadingScreen.tscn"
const MAIN_SCENE    := "res://Scenes/main.tscn"

var _skipped := false

func _ready() -> void:
	# Make sure the mouse is visible so the skip button can be clicked
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Tell the loading screen what to load next
	if GameManager:
		GameManager.next_scene = MAIN_SCENE

	if not video_player:
		push_error("Cutscene: VideoStreamPlayer node not found!")
		_go_to_loading()
		return

	video_player.finished.connect(_go_to_loading)
	video_player.play()

	print("🎬 Cutscene started — loading screen will follow.")


func _go_to_loading() -> void:
	if _skipped:
		return
	_skipped = true
	print("✅ Cutscene done — going to loading screen.")
	get_tree().change_scene_to_file(LOADING_SCENE)


# ── Skip button ───────────────────────────────────────────────────────────────
func _on_skip_pressed() -> void:
	_go_to_loading()


# ── Keyboard / touch skip ─────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	var skip := false

	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			skip = true

	if event is InputEventScreenTouch and not event.pressed:
		# Only skip on touch if NOT tapping the skip button area
		# (the button handles its own press)
		skip = false

	if skip:
		get_viewport().set_input_as_handled()
		_go_to_loading()

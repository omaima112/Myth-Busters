extends CanvasLayer

@onready var info_popup: PopupPanel = $ItemPopup
@onready var title_label: Label = $ItemPopup/MainLayout/TitleBar/TitleLabel
@onready var info_label: Label = $ItemPopup/MainLayout/ContentRow/LeftColumn/InfoLabel
@onready var info_image: TextureRect = $ItemPopup/MainLayout/ContentRow/ImageSection/ImageContainer/OrbImage

# Defined in popups.tscn
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var continue_label: Label = $ContinueLabel

var popup_visible: bool = false
var waiting_for_input: bool = false
var elapsed: float = 0.0
const READ_TIME: float = 3.0

var pulse_time: float = 0.0
var jeep: Node3D = null

func _ready():
	GameManager.show_orb_popup_signal.connect(_show_popup)
	GameManager.hide_orb_popup_signal.connect(_hide_popup)
	info_popup.hide()
	progress_bar.visible = false
	continue_label.visible = false

	# Block PopupPanel's built-in escape close
	info_popup.close_requested.connect(_on_close_requested)

	await get_tree().process_frame
	jeep = get_tree().root.find_child("Jeep", true, false)
	print("✅ Popup manager ready | jeep found: ", jeep != null)


func _on_close_requested():
	if popup_visible and not info_popup.visible:
		info_popup.popup_centered()


func _show_popup(title: String, text: String, image: Texture2D):
	info_popup.popup_centered()
	title_label.text = title
	info_label.text = text

	if image:
		info_image.texture = image
		info_image.visible = true
	else:
		info_image.visible = false

	elapsed = 0.0
	pulse_time = 0.0
	waiting_for_input = false
	popup_visible = true

	progress_bar.value = 0.0
	progress_bar.visible = true
	continue_label.visible = false

	if jeep:
		jeep.can_drive = false

	print("🔋 Popup shown")


func _process(delta: float) -> void:
	if not popup_visible:
		return

	# Keep escape from closing popup
	if not info_popup.visible:
		info_popup.popup_centered()

	# Position progress bar just above the popup (thin, full width)
	var px = info_popup.position.x
	var py = info_popup.position.y
	var pw = info_popup.size.x
	progress_bar.position = Vector2(px, py - 18)
	progress_bar.size = Vector2(pw, 10)

	# Position continue label just below the popup
	continue_label.position = Vector2(px, py + info_popup.size.y + 12)
	continue_label.size = Vector2(pw, 38)

	# Pulse the continue label alpha for a breathing glow effect
	if continue_label.visible:
		pulse_time += delta
		var alpha = 0.5 + 0.5 * sin(pulse_time * 4.0)
		continue_label.modulate = Color(1, 1, 1, alpha)

	# Tick bar
	if not waiting_for_input:
		elapsed += delta
		progress_bar.value = min(elapsed, READ_TIME)

		if elapsed >= READ_TIME:
			waiting_for_input = true
			continue_label.visible = true
			print("✅ 3s done — press W to continue")

	# Close on Gas (W) — same action as jeep
	if waiting_for_input and Input.is_action_just_pressed("Gas"):
		print("▶️  Gas pressed — closing popup")
		_close_everything()


func _close_everything():
	info_popup.hide()
	progress_bar.visible = false
	continue_label.visible = false
	popup_visible = false
	waiting_for_input = false

	# 🎙️ Stop voice if still playing when popup closes
	if GameManager.active_voice_player != null:
		GameManager.active_voice_player.stop()
		GameManager.active_voice_player.queue_free()
		GameManager.active_voice_player = null

	if jeep:
		jeep.can_drive = true

	print("✅ Popup closed, driving enabled")


func _hide_popup():
	_close_everything()


func hide_popup_immediately():
	_close_everything()
	print("⚡ Force closed")

extends CanvasLayer

@onready var info_popup: PopupPanel = $ItemPopup
@onready var title_label: Label = $ItemPopup/MainLayout/TitleBar/TitleLabel
@onready var info_label: Label = $ItemPopup/MainLayout/ContentRow/LeftColumn/InfoLabel
@onready var info_image: TextureRect = $ItemPopup/MainLayout/ContentRow/ImageSection/ImageContainer/OrbImage
@onready var image_section: PanelContainer = $ItemPopup/MainLayout/ContentRow/ImageSection
@onready var background_shade: ColorRect = $BackgroundShade
# Defined in popups.tscn
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var continue_label: Label = $ContinueLabel

var popup_visible: bool = false
var waiting_for_input: bool = false
var elapsed: float = 0.0
const READ_TIME: float = 3.0
var pulse_time: float = 0.0
var jeep: Node3D = null
var radiation_ui: Node = null
var nitro_hud: Node = null

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
	radiation_ui = get_tree().root.find_child("RadiationUI", true, false)
	nitro_hud = get_tree().root.find_child("NitroHUD", true, false)
	background_shade.visible = false

func _on_close_requested():
	if popup_visible and not info_popup.visible:
		info_popup.popup_centered()

func _apply_popup_size() -> void:
	# Wait TWO frames so Godot layout is fully ready — fixes first popup being small
	await get_tree().process_frame
	await get_tree().process_frame

	var screen_size = get_viewport().get_visible_rect().size

	# Popup: 70% screen width, 16:9 ratio
	var popup_w = int(screen_size.x * 0.70)
	var popup_h = int(popup_w * 9.0 / 16.0)

	# Clamp height for short/portrait screens
	if popup_h > int(screen_size.y * 0.85):
		popup_h = int(screen_size.y * 0.85)
		popup_w = int(popup_h * 16.0 / 9.0)

	# Set min_size FIRST — without it, first popup ignores size and stays small
	info_popup.min_size = Vector2i(popup_w, popup_h)
	info_popup.size     = Vector2i(popup_w, popup_h)
	info_popup.max_size = Vector2i(popup_w, popup_h)

	var content_h = popup_h - 54 - 36
	var img_section_w = int(content_h * 3.0 / 4.0)
	image_section.custom_minimum_size   = Vector2(img_section_w, 0)
	image_section.size_flags_horizontal = Control.SIZE_SHRINK_END

	info_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	info_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	info_image.get_parent().clip_contents = true

	# Font sizes INCREASED: title 12%, info 7% of popup height (was 10% / 5.5%)
	title_label.add_theme_font_size_override("font_size", int(popup_h * 0.12))
	info_label.add_theme_font_size_override("font_size",  int(popup_h * 0.09))

	# Re-apply size after layout settles, then center
	info_popup.size = Vector2i(popup_w, popup_h)
	info_popup.popup_centered()

func _show_popup(title: String, text: String, image: Texture2D):
	title_label.text = title
	info_label.text  = text
	background_shade.visible = true

	# Hide RadiationUI while popup is open
	if radiation_ui:
		radiation_ui.visible = false

	# Hide NitroHUD while popup is open
	if nitro_hud:
		nitro_hud.visible = false

	if image:
		info_image.texture = image
		info_image.visible = true
	else:
		info_image.visible = false

	elapsed           = 0.0
	pulse_time        = 0.0
	waiting_for_input = false
	popup_visible     = true

	progress_bar.value     = 0.0
	progress_bar.visible   = true
	continue_label.visible = false

	# Async size function waits 2 frames internally — fixes first-popup-small bug
	_apply_popup_size()

	if jeep:
		jeep.can_drive = false

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
	progress_bar.size     = Vector2(pw, 10)

	# Position continue label just below the popup
	continue_label.position = Vector2(px, py + info_popup.size.y + 12)
	continue_label.size     = Vector2(pw, 38)

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

	# Close on Gas (W) — same action as jeep
	if waiting_for_input and Input.is_action_just_pressed("Gas"):
		_close_everything()

func _close_everything():
	info_popup.hide()
	progress_bar.visible   = false
	continue_label.visible = false
	popup_visible          = false
	waiting_for_input      = false
	background_shade.visible = false

	# Restore RadiationUI when popup closes
	if radiation_ui:
		radiation_ui.visible = true

	# Restore NitroHUD when popup closes
	if nitro_hud:
		nitro_hud.visible = true

	# Stop voice if still playing when popup closes
	if GameManager.active_voice_player != null:
		GameManager.active_voice_player.stop()
		GameManager.active_voice_player.queue_free()
		GameManager.active_voice_player = null

	if jeep:
		jeep.can_drive = true

func _hide_popup():
	_close_everything()

func hide_popup_immediately():
	_close_everything()

extends CanvasLayer

@onready var info_popup: PopupPanel = $ItemPopup
@onready var title_label: Label = $ItemPopup/MainLayout/LeftColumn/TitleLabel
@onready var info_label: Label = $ItemPopup/MainLayout/LeftColumn/InfoLabel
@onready var info_image: TextureRect = $ItemPopup/MainLayout/OrbImage

var popup_timer: Timer
var popup_visible: bool = false
var jeep: Node3D = null

func _ready():
	GameManager.show_orb_popup_signal.connect(_show_popup)
	GameManager.hide_orb_popup_signal.connect(_hide_popup)
	info_popup.hide()
	
	# Create timer
	popup_timer = Timer.new()
	add_child(popup_timer)
	popup_timer.timeout.connect(_on_popup_timer_timeout)
	
	# Find the jeep - try multiple ways
	await get_tree().process_frame
	jeep = get_tree().root.find_child("Jeep", true, false)
	
	if jeep:
		print("✅ Found Jeep: ", jeep.name)
		print("   Jeep type: ", jeep.get_class())
		# Try to get can_drive property
		if "can_drive" in jeep:
			print("   ✓ can_drive property exists")
		else:
			print("   ❌ can_drive property NOT found!")
	else:
		print("⚠️ Jeep not found in scene tree")
	
	print("✅ Popup manager ready")

func _show_popup(title: String, text: String, image: Texture2D):
	"""Show popup for 3.5 seconds. Car controls disabled, game keeps running."""
	
	print("🔋 Showing popup: ", title)
	
	# Show the popup
	info_popup.popup_centered()
	title_label.text = title
	info_label.text = text
	
	if image:
		info_image.texture = image
		info_image.visible = true
	else:
		info_image.visible = false
	
	popup_visible = true
	print("📺 Popup visible")
	
	# DISABLE CAR CONTROLS
	if jeep:
		print("🛑 Setting can_drive = false")
		jeep.can_drive = false
		print("   Engine force: ", jeep.engine_force)
		print("   Can drive: ", jeep.can_drive)
	else:
		print("⚠️ Jeep is null - cannot disable controls")
	
	# Start timer - 1 second
	popup_timer.wait_time = 1.0
	popup_timer.one_shot = true
	popup_timer.start()
	print("⏱️ Popup will auto-hide in 1 second")

func _on_popup_timer_timeout():
	"""Called after 1 second"""
	print("⏰ 1 second elapsed!")
	popup_timer.stop()
	_hide_popup()

func _hide_popup():
	"""Hide popup and re-enable car controls"""
	if popup_visible:
		# Hide popup
		info_popup.hide()
		popup_visible = false
		print("✅ Popup hidden")
		
		# RE-ENABLE CAR CONTROLS
		if jeep:
			print("▶️  Setting can_drive = true")
			jeep.can_drive = true
			print("   Can drive: ", jeep.can_drive)
		else:
			print("⚠️ Jeep is null - cannot enable controls")
	else:
		info_popup.hide()

func hide_popup_immediately():
	"""Force hide popup immediately"""
	popup_timer.stop()
	info_popup.hide()
	popup_visible = false
	
	if jeep:
		jeep.can_drive = true
	
	print("⚡ Popup force hidden")

# Block Escape key while popup visible
func _input(event: InputEvent) -> void:
	if popup_visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().root.set_input_as_handled()
			print("🛑 Escape blocked - wait 1 second")

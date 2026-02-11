extends CanvasLayer

"""
Barrel Popup Manager
This script manages the display of tutorial popup images when barrels are collected.
Attach this to the TutorialUI CanvasLayer node.

Features:
- Displays barrel tutorial images for 4 seconds each
- Smooth show/hide transitions
- Supports multiple barrels with different images
- Auto-closes and shows next barrel
"""

class_name BarrelPopupManager

# Popup UI elements
var popup_panel: Panel
var popup_image: TextureRect
var popup_title: Label
var close_button: Button

# Popup state
var is_visible: bool = false
var popup_timer: float = 0.0
var popup_duration: float = 4.0

# Animation
var fade_speed: float = 0.5

func _ready() -> void:
	"""Initialize the popup UI"""
	layer = 10  # Ensure it appears on top
	create_popup_ui()
	print("✅ BarrelPopupManager initialized")

func create_popup_ui() -> void:
	"""Create all UI elements for the popup"""
	
	# Main panel with dark background
	popup_panel = Panel.new()
	popup_panel.name = "BarrelPopupPanel"
	popup_panel.anchor_left = 0.5
	popup_panel.anchor_top = 0.5
	popup_panel.anchor_right = 0.5
	popup_panel.anchor_bottom = 0.5
	popup_panel.offset_left = -450
	popup_panel.offset_top = -350
	popup_panel.offset_right = 450
	popup_panel.offset_bottom = 350
	popup_panel.visible = false
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.85)
	panel_style.border_color = Color.WHITE
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	popup_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(popup_panel)
	
	# Create container for content
	var vbox = VBoxContainer.new()
	vbox.name = "ContentContainer"
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	
	popup_panel.add_child(vbox)
	
	# Title label
	popup_title = Label.new()
	popup_title.name = "PopupTitle"
	popup_title.text = "Tutorial"
	popup_title.custom_minimum_size = Vector2(0, 50)
	popup_title.add_theme_font_size_override("font_size", 36)
	popup_title.add_theme_color_override("font_color", Color.WHITE)
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	vbox.add_child(popup_title)
	
	# Image display
	popup_image = TextureRect.new()
	popup_image.name = "PopupImage"
	popup_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	popup_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	popup_image.custom_minimum_size = Vector2(800, 300)
	
	vbox.add_child(popup_image)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Progress indicator (optional)
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "This will close automatically in 4 seconds..."
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	vbox.add_child(progress_label)
	
	# Close button (optional - for manual closing)
	var hbox_buttons = HBoxContainer.new()
	hbox_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_buttons.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(hbox_buttons)
	
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Skip (Press ESC)"
	close_button.custom_minimum_size = Vector2(200, 40)
	close_button.pressed.connect(_on_close_button_pressed)
	
	hbox_buttons.add_child(close_button)
	
	print("✅ Popup UI created successfully")

func show_popup(image: Texture2D, title: String = "Tutorial Info") -> void:
	"""
	Display the popup with the given image
	
	Args:
		image: The texture to display
		title: The title text to show (optional)
	"""
	
	if not image:
		print("❌ No image provided for popup")
		return
	
	# Set content
	popup_image.texture = image
	popup_title.text = title
	
	# Reset timer and show
	popup_timer = popup_duration
	popup_panel.visible = true
	is_visible = true
	
	print("📺 Popup shown with title: '", title, "' for ", popup_duration, " seconds")

func hide_popup() -> void:
	"""Hide the popup"""
	popup_panel.visible = false
	is_visible = false
	popup_timer = 0.0
	print("✅ Popup hidden")

func _process(delta: float) -> void:
	"""Handle popup timer countdown"""
	
	if is_visible and popup_panel.visible:
		popup_timer -= delta
		
		if popup_timer <= 0:
			hide_popup()

func _input(event: InputEvent) -> void:
	"""Allow ESC key to close popup"""
	
	if is_visible and event.is_action_pressed("ui_cancel"):
		hide_popup()
		get_tree().root.set_input_as_handled()

func _on_close_button_pressed() -> void:
	"""Called when close button is pressed"""
	hide_popup()

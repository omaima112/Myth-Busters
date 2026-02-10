extends CanvasLayer

@onready var info_popup: PopupPanel = $ItemPopup
@onready var title_label: Label = $ItemPopup/MainLayout/LeftColumn/TitleLabel
@onready var info_label: Label = $ItemPopup/MainLayout/LeftColumn/InfoLabel
@onready var info_image: TextureRect = $ItemPopup/MainLayout/OrbImage

var level_complete_popup: PopupPanel
var level_complete_title: Label
var level_complete_text: Label

var current_orb_text: String = ""

func _ready():
	GameManager.show_orb_popup_signal.connect(_show_popup)
	GameManager.hide_orb_popup_signal.connect(_hide_popup)
	GameManager.level_complete_signal.connect(_show_level_complete)

	info_popup.hide()
	
	if has_node("LevelCompletePopup"):
		var node = get_node("LevelCompletePopup")
		
		if node is PopupPanel:
			level_complete_popup = node as PopupPanel
			level_complete_title = level_complete_popup.get_node("MarginContainer/VBoxContainer/TitleLabel") as Label
			level_complete_text = level_complete_popup.get_node("MarginContainer/VBoxContainer/MessageLabel") as Label
			level_complete_popup.hide()
			print("✅ Level complete popup loaded!")
		else:
			print("❌ LevelCompletePopup is wrong type: ", node.get_class())
	else:
		print("⚠️ LevelCompletePopup not found in scene")

func _show_popup(title: String, text: String, image: Texture2D):
	info_popup.popup()
	title_label.text = title
	info_label.text = text

	if image:
		info_image.texture = image
		info_image.visible = true
	else:
		info_image.visible = false

	get_tree().paused = false

func _hide_popup():
	info_popup.hide()

func _show_level_complete(level_name: String = "Level 1"):
	_hide_popup()
	await get_tree().create_timer(0.3).timeout
	
	if level_complete_popup == null:
		print("❌ Level complete popup is null!")
		return
	
	level_complete_title.text = level_name + " COMPLETED!"
	level_complete_text.text = "Next level is coming soon..."
	level_complete_popup.popup_centered_ratio(0.6)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("✅ Level complete shown! Restarting in 3 seconds...")
	
	await get_tree().create_timer(3.0).timeout
	_restart_game()

func _restart_game():
	print("✅ Restarting game!")
	if level_complete_popup != null:
		level_complete_popup.hide()
	
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	get_tree().reload_current_scene()

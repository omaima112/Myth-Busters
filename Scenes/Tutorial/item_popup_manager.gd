extends PopupPanel
"""
ItemPopup Visibility Manager
Attach this script to your ItemPopup (PopupPanel) node.
Controls when the popup shows/hides to prevent overlap with win screen.
"""

var is_final_barrel = false
var can_show_popup = true

func _ready() -> void:
	visible = false
	
	# Connect to win signal if GameManager has one
	if GameManager and GameManager.has_signal("win_triggered"):
		GameManager.connect("win_triggered", Callable(self, "_on_game_won"))

# Call this function when a barrel is collected
# Return true if popup was shown, false if skipped
func show_barrel_popup(barrel_info: Dictionary) -> bool:
	if not can_show_popup:
		return false
	
	# Check if this is the final barrel
	is_final_barrel = check_if_final_barrel()
	
	if is_final_barrel:
		return false
	
	# Show popup for non-final barrels
	display_popup(barrel_info)
	return true

# Check if the barrel being collected completes the level
func check_if_final_barrel() -> bool:
	var collected = GameManager.get_collected_orbs()
	var total = GameManager.total_orbs
	var remaining = total - collected
	
	if remaining <= 1:
		return true
	return false

# Display the popup with barrel information
func display_popup(barrel_info: Dictionary) -> void:
	if has_node("VBoxContainer/Title"):
		$VBoxContainer/Title.text = barrel_info.get("title", "Barrel Collected")
	
	if has_node("VBoxContainer/Description"):
		$VBoxContainer/Description.text = barrel_info.get("description", "Nuclear Information")
	
	if has_node("VBoxContainer/Image"):
		var image_path = barrel_info.get("image", "")
		if image_path and ResourceLoader.exists(image_path):
			$VBoxContainer/Image.texture = load(image_path)
	
	# Show the popup
	popup_centered()
	visible = true

# Hide the popup
func hide_popup() -> void:
	if visible:
		hide()
		visible = false

# Called when win screen is triggered
func _on_game_won() -> void:
	can_show_popup = false
	hide_popup()

# Reset popup for new level/retry
func reset() -> void:
	is_final_barrel = false
	can_show_popup = true
	visible = false

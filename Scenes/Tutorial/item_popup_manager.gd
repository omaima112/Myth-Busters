extends PopupPanel
"""
ItemPopup Visibility Manager
Attach this script to your ItemPopup (PopupPanel) node.
Controls when the popup shows/hides to prevent overlap with win screen.
"""

var is_final_barrel = false
var can_show_popup = true

func _ready() -> void:
	# Hide the popup when the scene starts
	visible = false
	print("✅ ItemPopup hidden at startup")
	
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
		print("⚠️ Final barrel collected - SKIPPING popup, win screen will show instead")
		return false
	
	# Show popup for non-final barrels
	display_popup(barrel_info)
	return true

# Check if the barrel being collected completes the level
func check_if_final_barrel() -> bool:
	# Get collected and total from GameManager
	var collected = GameManager.get_collected_orbs()  # This should be current count
	var total = GameManager.total_orbs  # Total orbs in level
	
	# If remaining is 1, the current barrel being collected is the final one
	var remaining = total - collected
	
	print("Barrels - Collected: ", collected, " / Total: ", total, " / Remaining: ", remaining)
	
	if remaining <= 1:
		return true
	return false

# Display the popup with barrel information
func display_popup(barrel_info: Dictionary) -> void:
	# Populate popup content if you have labels
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
	print("📋 Popup showing: ", barrel_info.get("title", "Barrel"))

# Hide the popup
func hide_popup() -> void:
	if visible:
		hide()
		visible = false
		print("✅ Popup hidden")

# Called when win screen is triggered
func _on_game_won() -> void:
	print("🎉 Win triggered - disabling popup")
	can_show_popup = false
	hide_popup()

# Reset popup for new level/retry
func reset() -> void:
	is_final_barrel = false
	can_show_popup = true
	visible = false
	print("🔄 Popup reset for new level")

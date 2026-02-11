extends PopupPanel

"""
ItemPopup Visibility Manager
Attach this script to your ItemPopup (Panel) node to hide it by default.
It will be controlled by the tutorial_manager when barrels are collected.
"""

func _ready() -> void:
	# Hide the popup when the scene starts
	visible = false
	print("✅ ItemPopup hidden at startup")

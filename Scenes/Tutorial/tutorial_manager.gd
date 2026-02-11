extends Node3D

# Barrel collection tracking
var orbs_collected: int = 0
var total_orbs: int = 3
var barrel_counter_label: Label
var instruction_label: Label
var collection_complete: bool = false

# Popup references
var item_popup: PopupPanel
var popup_image: TextureRect
var is_popup_active: bool = false

# Barrel data
var barrels_data: Array = []

# Jeep reference for fixing rotation
var jeep: Node3D

func _ready() -> void:
	set_process_input(true)
	
	# Get Jeep and fix its rotation/position
	jeep = $Jeep
	if jeep:
		print("✅ Found Jeep, fixing rotation...")
		# Set completely level rotation (identity quaternion)
		jeep.rotation = Vector3.ZERO
		# Position slightly above ground
		jeep.position.y = 0.5
		print("✅ Jeep rotation fixed to: ", jeep.rotation)
		print("✅ Jeep Y position set to: ", jeep.position.y)
	else:
		print("❌ Jeep not found!")
	
	# Get UI labels
	barrel_counter_label = $TutorialUI/BarrelCounter
	instruction_label = $TutorialUI/InstructionLabel
	
	# Get ItemPopup
	item_popup = $TutorialUI/ItemPopup
	if not item_popup:
		print("ERROR: ItemPopup not found")
		return
	
	item_popup.visible = false
	
	# Find TextureRect in ItemPopup
	popup_image = find_texture_rect(item_popup)
	if popup_image:
		popup_image.texture = null
	
	update_ui()
	setup_orb_collection()

func find_texture_rect(node: Node) -> TextureRect:
	if node is TextureRect:
		return node
	for child in node.get_children():
		var result = find_texture_rect(child)
		if result:
			return result
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("ESC PRESSED - is_popup_active: ", is_popup_active)
		
		if is_popup_active:
			print("Popup is active, closing it...")
			close_current_popup()
			get_tree().root.set_input_as_handled()
			
			print("Barrels collected: ", orbs_collected, "/", total_orbs)
			
			if orbs_collected >= total_orbs:
				print("All barrels collected! Calling complete_tutorial()...")
				complete_tutorial()
			else:
				print("Need more barrels...")
		else:
			print("Popup not active")

func setup_orb_collection() -> void:
	await get_tree().process_frame
	
	var barrels_node = $Barrels
	if not barrels_node:
		print("ERROR: Barrels node not found")
		return
	
	print("Setting up ", barrels_node.get_child_count(), " barrels")
	
	for i in range(barrels_node.get_child_count()):
		var orb = barrels_node.get_child(i)
		print("Setting up barrel: ", orb.name)
		
		barrels_data.append({
			"node": orb,
			"name": orb.name,
			"image": null,
			"title": "Tutorial"
		})
		
		if "info_image" in orb:
			barrels_data[i]["image"] = orb.info_image
			print("  - Has info_image")
		
		if "info_title" in orb:
			barrels_data[i]["title"] = orb.info_title
			print("  - Has info_title: ", orb.info_title)
		
		if orb.has_signal("collected"):
			orb.collected.connect(_on_orb_collected.bind(orb, i))
			print("  - Connected to 'collected' signal")
		else:
			orb.tree_exited.connect(_on_orb_disappeared.bind(orb, i))
			print("  - Connected to 'tree_exited' signal")

func _on_orb_collected(_orb: Node, barrel_index: int) -> void:
	if collection_complete:
		return
	
	orbs_collected += 1
	print("Barrel collected! Total: ", orbs_collected)
	show_barrel_popup(barrel_index)
	update_ui()

func _on_orb_disappeared(_orb: Variant, barrel_index: int) -> void:
	if collection_complete:
		return
	
	orbs_collected += 1
	print("Barrel disappeared! Total: ", orbs_collected)
	show_barrel_popup(barrel_index)
	update_ui()

func show_barrel_popup(barrel_index: int) -> void:
	if not item_popup or barrel_index < 0 or barrel_index >= barrels_data.size():
		return
	
	var barrel_info = barrels_data[barrel_index]
	print("Showing popup for: ", barrel_info["name"])
	
	if popup_image:
		popup_image.texture = null
		if barrel_info.get("image"):
			popup_image.texture = barrel_info["image"]
	
	item_popup.visible = true
	is_popup_active = true
	print("Popup visible: ", item_popup.visible, " | is_popup_active: ", is_popup_active)

func close_current_popup() -> void:
	if not is_popup_active:
		print("ERROR: Trying to close but is_popup_active is false!")
		return
	
	item_popup.visible = false
	is_popup_active = false
	print("Popup closed")

func update_ui() -> void:
	if barrel_counter_label:
		barrel_counter_label.text = "Barrels: " + str(orbs_collected) + "/" + str(total_orbs)
	
	if instruction_label:
		if orbs_collected >= total_orbs:
			instruction_label.text = "Press ESC to continue!"
		else:
			var remaining = total_orbs - orbs_collected
			instruction_label.text = "Collect all " + str(total_orbs) + " barrels! (" + str(remaining) + " remaining)"

func complete_tutorial() -> void:
	print("complete_tutorial() called")
	
	if collection_complete:
		print("Already marked complete, returning")
		return
	
	collection_complete = true
	print("Setting collection_complete = true")
	
	if item_popup:
		item_popup.visible = false
		print("Popup hidden")
	
	# Try different possible paths
	var paths = [
		"res://Scenes/LoadingScreen.tscn",
		"res://LoadingScreen.tscn",
		"res://Scenes/Environment/environment.tscn",
		"res://Scenes/Environment.tscn",
		"res://main.tscn"
	]
	
	print("Checking for scene files...")
	for path in paths:
		var exists = ResourceLoader.exists(path)
		print("  ", path, " - EXISTS: ", exists)
		if exists:
			print("Loading: ", path)
			get_tree().change_scene_to_file(path)
			return
	
	print("ERROR: No scene file found!")

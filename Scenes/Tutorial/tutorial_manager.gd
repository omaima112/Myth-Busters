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
		jeep.rotation = Vector3.ZERO
		jeep.position.y = 0.5
	
	# Get UI labels
	barrel_counter_label = $TutorialUI/BarrelCounter
	instruction_label = $TutorialUI/InstructionLabel
	
	# Get ItemPopup
	item_popup = $TutorialUI/ItemPopup
	if not item_popup:
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
		if is_popup_active:
			close_current_popup()
			get_tree().root.set_input_as_handled()
			
			if orbs_collected >= total_orbs:
				complete_tutorial()
	
	# E key to skip tutorial anytime
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			skip_tutorial()

func setup_orb_collection() -> void:
	await get_tree().process_frame
	
	var barrels_node = $Barrels
	if not barrels_node:
		return
	
	for i in range(barrels_node.get_child_count()):
		var orb = barrels_node.get_child(i)
		
		barrels_data.append({
			"node": orb,
			"name": orb.name,
			"image": null,
			"title": "Tutorial"
		})
		
		if "info_image" in orb:
			barrels_data[i]["image"] = orb.info_image
		
		if "info_title" in orb:
			barrels_data[i]["title"] = orb.info_title
		
		if orb.has_signal("collected"):
			orb.collected.connect(_on_orb_collected.bind(orb, i))
		else:
			orb.tree_exited.connect(_on_orb_disappeared.bind(orb, i))

func _on_orb_collected(_orb: Node, barrel_index: int) -> void:
	if collection_complete:
		return
	
	orbs_collected += 1
	show_barrel_popup(barrel_index)
	update_ui()

func _on_orb_disappeared(_orb: Variant, barrel_index: int) -> void:
	if collection_complete:
		return
	
	orbs_collected += 1
	show_barrel_popup(barrel_index)
	update_ui()

func show_barrel_popup(barrel_index: int) -> void:
	if not item_popup or barrel_index < 0 or barrel_index >= barrels_data.size():
		return
	
	var barrel_info = barrels_data[barrel_index]
	
	if popup_image:
		popup_image.texture = null
		if barrel_info.get("image"):
			popup_image.texture = barrel_info["image"]
	
	item_popup.visible = true
	is_popup_active = true

func close_current_popup() -> void:
	if not is_popup_active:
		return
	
	item_popup.visible = false
	is_popup_active = false

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
	if collection_complete:
		return
	
	collection_complete = true
	
	if item_popup:
		item_popup.visible = false
	
	var paths = [
		"res://Scenes/LoadingScreen.tscn",
		"res://Scenes/Environment/environment.tscn",
		"res://Scenes/main.tscn"
	]
	
	for path in paths:
		if ResourceLoader.exists(path):
			get_tree().change_scene_to_file(path)
			return

func skip_tutorial() -> void:
	var paths = [
		"res://Scenes/LoadingScreen.tscn",
		"res://Scenes/Environment/environment.tscn",
		"res://Scenes/main.tscn"
	]
	
	for path in paths:
		if ResourceLoader.exists(path):
			get_tree().change_scene_to_file(path)
			return

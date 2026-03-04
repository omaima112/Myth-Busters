extends Node3D

# ── Barrel tracking ────────────────────────────────────────────────────────────
var orbs_collected: int = 0
var total_orbs: int = 3
var collection_complete: bool = false
var barrels_data: Array = []

# ── UI nodes ───────────────────────────────────────────────────────────────────
var instruction_label: Label

# ── Popup system (mirrors popups.gd exactly) ───────────────────────────────────
var item_popup: PopupPanel
var popup_image: TextureRect
var progress_bar: ProgressBar
var continue_label: Label

var popup_visible: bool = false
var waiting_for_input: bool = false
var elapsed: float = 0.0
var pulse_time: float = 0.0
const READ_TIME: float = 3.0

# ── Jeep ───────────────────────────────────────────────────────────────────────
var jeep: Node3D = null


# ==============================================================================
func _ready() -> void:
	jeep = $Jeep
	if jeep:
		jeep.rotation = Vector3.ZERO
		jeep.position.y = 0.5

	instruction_label = $TutorialUI/InstructionLabel

	# Popup nodes
	item_popup     = $TutorialUI/ItemPopup
	progress_bar   = $TutorialUI/ProgressBar
	continue_label = $TutorialUI/ContinueLabel

	if item_popup:
		item_popup.hide()
		item_popup.close_requested.connect(_on_close_requested)

	if progress_bar:
		progress_bar.visible = false

	if continue_label:
		continue_label.visible = false

	# Find the TextureRect inside the popup
	popup_image = _find_texture_rect(item_popup)
	if popup_image:
		popup_image.texture = null

	update_ui()
	setup_orb_collection()


# ==============================================================================
# INPUT
# ==============================================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			skip_tutorial()


# ==============================================================================
# PROCESS — progress bar tick, Gas-to-dismiss, hide-on-drive
# ==============================================================================
func _process(delta: float) -> void:
	if not popup_visible:
		return

	# Keep popup centered (prevent escape from closing it)
	if not item_popup.visible:
		item_popup.popup_centered()

	# Anchor progress bar just above popup
	var px = item_popup.position.x
	var py = item_popup.position.y
	var pw = item_popup.size.x
	progress_bar.position = Vector2(px, py - 18)
	progress_bar.size     = Vector2(pw, 10)

	# Anchor continue label just below popup
	continue_label.position = Vector2(px, py + item_popup.size.y + 12)
	continue_label.size     = Vector2(pw, 38)

	# Pulse continue label
	if continue_label.visible:
		pulse_time += delta
		continue_label.modulate = Color(1, 1, 1, 0.5 + 0.5 * sin(pulse_time * 4.0))

	# Tick progress bar
	if not waiting_for_input:
		elapsed += delta
		progress_bar.value = min(elapsed, READ_TIME)
		if elapsed >= READ_TIME:
			waiting_for_input = true
			continue_label.visible = true

	# Dismiss on Gas (W) — same action as driving forward
	if waiting_for_input and Input.is_action_just_pressed("Gas"):
		_close_popup()


# ==============================================================================
# POPUP SHOW / CLOSE
# ==============================================================================
func show_barrel_popup(barrel_index: int) -> void:
	if not item_popup or barrel_index < 0 or barrel_index >= barrels_data.size():
		return

	var info = barrels_data[barrel_index]
	if popup_image:
		popup_image.texture = info.get("image", null)

	elapsed           = 0.0
	pulse_time        = 0.0
	waiting_for_input = false
	popup_visible     = true

	progress_bar.value     = 0.0
	progress_bar.visible   = true
	continue_label.visible = false

	if jeep:
		jeep.can_drive = false

	item_popup.popup_centered()


func _close_popup() -> void:
	if not popup_visible:
		return

	item_popup.hide()
	progress_bar.visible   = false
	continue_label.visible = false
	popup_visible          = false
	waiting_for_input      = false

	if jeep:
		jeep.can_drive = true

	# After closing the LAST barrel popup → go to next scene
	if orbs_collected >= total_orbs and not collection_complete:
		complete_tutorial()


func _on_close_requested() -> void:
	# Prevent built-in ESC close from working while popup is active
	if popup_visible and not item_popup.visible:
		item_popup.popup_centered()


# ==============================================================================
# ORB COLLECTION
# ==============================================================================
func setup_orb_collection() -> void:
	await get_tree().process_frame

	var barrels_node = $Barrels
	if not barrels_node:
		return

	for i in range(barrels_node.get_child_count()):
		var orb = barrels_node.get_child(i)
		barrels_data.append({
			"node":  orb,
			"name":  orb.name,
			"image": orb.get("info_image") if "info_image" in orb else null,
			"title": orb.get("info_title") if "info_title" in orb else "Tutorial",
		})

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


func update_ui() -> void:
	if instruction_label:
		if orbs_collected >= total_orbs:
			instruction_label.text = "All barrels collected! Press Gas to continue."
		else:
			var remaining = total_orbs - orbs_collected
			instruction_label.text = "Collect all %d barrels! (%d remaining)" % [total_orbs, remaining]


# ==============================================================================
# COMPLETE / SKIP
# ==============================================================================
func complete_tutorial() -> void:
	if collection_complete:
		return
	collection_complete = true

	if item_popup:    item_popup.hide()
	if progress_bar:  progress_bar.visible = false
	if continue_label: continue_label.visible = false

	get_tree().change_scene_to_file("res://Scenes/Cutscene/Cutscene.tscn")


func skip_tutorial() -> void:
	if collection_complete:
		return
	collection_complete = true
	get_tree().change_scene_to_file("res://Scenes/Cutscene/Cutscene.tscn")


# ==============================================================================
# HELPERS
# ==============================================================================
func _find_texture_rect(node: Node) -> TextureRect:
	if node == null:
		return null
	if node is TextureRect:
		return node
	for child in node.get_children():
		var result = _find_texture_rect(child)
		if result:
			return result
	return null

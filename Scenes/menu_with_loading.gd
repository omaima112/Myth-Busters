extends Node3D

@export var model: MeshInstance3D
@export var area: Area3D

var highlight_mat: StandardMaterial3D = preload("res://Materials/highlight.tres")
var original_materials: Array[Material] = []

func _ready():
	# Auto-find model and area if not set
	if model == null:
		for child in get_children():
			if child is MeshInstance3D:
				model = child
				break
	
	if area == null:
		for child in get_children():
			if child is Area3D:
				area = child
				break
	
	# Store original materials
	if model != null:
		var surface_count = model.mesh.get_surface_count() if model.mesh else 0
		
		for i in range(surface_count):
			var mat = model.get_surface_override_material(i)
			if mat == null:
				mat = model.mesh.surface_get_material(i)
			original_materials.append(mat)
	
	# Connect area signals ONLY if not already connected
	if area != null:
		if not area.mouse_entered.is_connected(_on_mouse_entered):
			area.mouse_entered.connect(_on_mouse_entered)
		if not area.mouse_exited.is_connected(_on_mouse_exited):
			area.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	apply_highlight(true)

func _on_mouse_exited():
	apply_highlight(false)

func apply_highlight(enabled: bool):
	if model == null or model.mesh == null:
		return
	
	var surface_count = model.mesh.get_surface_count()
	for i in range(surface_count):
		if enabled:
			model.set_surface_override_material(i, highlight_mat)
		else:
			if i < original_materials.size():
				model.set_surface_override_material(i, original_materials[i])

# This function is connected in the editor
func _on_area_3d_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_start_pressed()

func _on_start_pressed():
	var loading_screen_path = "res://Scenes/LoadingScreen.tscn"
	
	if FileAccess.file_exists(loading_screen_path):
		get_tree().change_scene_to_file(loading_screen_path)
	else:
		# Fallback to loading main scene directly
		var scene_path = "res://Scenes/main.tscn"
		if FileAccess.file_exists(scene_path):
			get_tree().change_scene_to_file(scene_path)

extends Node3D

# The Player is inside the Jeep scene
@onready var player = $Jeep

var chase_active: bool = false

func _ready():
	_apply_graphics_quality()
	GameManager.police_chase_started.connect(_on_chase_started)
	GameManager.police_chase_ended.connect(_on_chase_ended)

func _physics_process(delta):
	if player:
		get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)

func _on_chase_started():
	chase_active = true
	_set_orbs_locked(true)

func _on_chase_ended():
	chase_active = false
	_set_orbs_locked(false)

func _set_orbs_locked(locked: bool) -> void:
	var all_nodes = get_tree().get_nodes_in_group("orbs")
	
	if all_nodes.is_empty():
		all_nodes = _find_orbs_recursive(get_tree().root)
	
	for orb in all_nodes:
		orb.visible = not locked
		var trigger = orb.get_node_or_null("TriggerArea")
		if trigger:
			trigger.monitoring = not locked
			trigger.monitorable = not locked

func _find_orbs_recursive(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("orb.gd"):
			result.append(child)
		result.append_array(_find_orbs_recursive(child))
	return result

func _apply_graphics_quality() -> void:
	var quality: String = "MEDIUM"
	if GameManager and "graphics_quality" in GameManager:
		quality = GameManager.graphics_quality

	var high := quality == "HIGH"

	# Shadows
	RenderingServer.directional_shadow_atlas_set_size(4096 if high else 0, high)
	for node in _find_all_recursive(get_tree().root):
		if node is DirectionalLight3D:
			node.shadow_enabled = high
		if node is GeometryInstance3D:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if high \
							 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Reflections (SSR) on the WorldEnvironment
	var we := _find_world_environment(get_tree().root)
	if we and we.environment:
		we.environment.ssr_enabled = high

func _find_world_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node
	for child in node.get_children():
		var r = _find_world_environment(child)
		if r: return r
	return null

func _find_all_recursive(node: Node) -> Array:
	var result := [node]
	for child in node.get_children():
		result.append_array(_find_all_recursive(child))
	return result

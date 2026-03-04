# graphics_quality_applier.gd
# Attach to any map root node, or call apply() from its _ready().
# Reads GameManager.graphics_quality and disables/enables shadows + reflections
# on every mesh and the world environment.

extends Node

func _ready() -> void:
	apply()

func apply() -> void:
	var quality: String = "MEDIUM"
	if GameManager:
		quality = GameManager.get("graphics_quality") if GameManager.get("graphics_quality") else "MEDIUM"

	var shadows_on:     bool = (quality == "HIGH")
	var reflections_on: bool = (quality == "HIGH")

	# ── World Environment ─────────────────────────────────────────────────────
	var env_node = get_tree().get_first_node_in_group("world_environment")
	if not env_node:
		env_node = _find_node_of_type(get_tree().root, "WorldEnvironment")
	if env_node and env_node.environment:
		env_node.environment.ssr_enabled    = reflections_on
		env_node.environment.ssao_enabled   = false   # always off for perf
		env_node.environment.ssil_enabled   = false
		env_node.environment.sdfgi_enabled  = false

	# ── All GeometryInstance3D (meshes, CSG, etc.) ────────────────────────────
	var shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows_on \
	                  else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_set_shadows_recursive(get_tree().root, shadow_mode)

	# ── DirectionalLight3D shadow ─────────────────────────────────────────────
	var lights = _find_all_of_type(get_tree().root, "DirectionalLight3D")
	for light in lights:
		light.shadow_enabled = shadows_on

	# ── RenderingServer shadow atlas ──────────────────────────────────────────
	if shadows_on:
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
	else:
		RenderingServer.directional_shadow_atlas_set_size(0, false)


# ── Helpers ───────────────────────────────────────────────────────────────────
func _set_shadows_recursive(node: Node, mode: int) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = mode
	for child in node.get_children():
		_set_shadows_recursive(child, mode)

func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var result = _find_node_of_type(child, type_name)
		if result:
			return result
	return null

func _find_all_of_type(node: Node, type_name: String) -> Array:
	var results = []
	if node.get_class() == type_name:
		results.append(node)
	for child in node.get_children():
		results.append_array(_find_all_of_type(child, type_name))
	return results

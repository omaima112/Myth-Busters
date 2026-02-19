extends Node3D

# The Player is inside the Jeep scene
@onready var player = $Jeep

var chase_active: bool = false

func _ready():
	# Listen to police chase signals from GameManager
	GameManager.police_chase_started.connect(_on_chase_started)
	GameManager.police_chase_ended.connect(_on_chase_ended)

func _physics_process(delta):
	if player:
		get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)

func _on_chase_started():
	chase_active = true
	print("🚨 Chase started — locking all orbs")
	_set_orbs_locked(true)

func _on_chase_ended():
	chase_active = false
	print("✅ Chase ended — unlocking all orbs")
	_set_orbs_locked(false)

func _set_orbs_locked(locked: bool) -> void:
	# Find every orb in the scene by script class or node name pattern
	var all_nodes = get_tree().get_nodes_in_group("orbs")
	
	# Fallback: if orbs aren't in a group, find them by searching the tree
	if all_nodes.is_empty():
		all_nodes = _find_orbs_recursive(get_tree().root)
	
	for orb in all_nodes:
		# Hide/show the orb visually
		orb.visible = not locked
		
		# Disable/enable the trigger area so driving through does NOTHING
		var trigger = orb.get_node_or_null("TriggerArea")
		if trigger:
			trigger.monitoring = not locked
			trigger.monitorable = not locked
	
	print("🔒 Orbs locked: ", locked, " (", all_nodes.size(), " orbs)")

func _find_orbs_recursive(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		# Detect orbs by their script filename
		if child.get_script() and child.get_script().resource_path.ends_with("orb.gd"):
			result.append(child)
		result.append_array(_find_orbs_recursive(child))
	return result

extends MeshInstance3D

@export var custom_mesh: Mesh: set = _set_custom_mesh

func _set_custom_mesh(new_mesh: Mesh):
	mesh = new_mesh
	if mesh:
		print("Loaded custom mesh: ", mesh.resource_name)

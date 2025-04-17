extends MeshInstance3D

var _letter: String = "A"

var letter: String:
	get:
		return _letter
	set(value):
		_letter = value
		# Update text only if the mesh is ready and valid
		if is_inside_tree() and mesh is TextMesh:
			update_text()

func _ready() -> void:
	# Ensure the mesh resource is unique for this instance
	# so that changing mesh.text doesn't affect other instances.
	if mesh:
		mesh = mesh.duplicate(true)
	# Update text immediately after ensuring the mesh is unique
	update_text()

func update_text() -> void:
	if mesh is TextMesh:
		mesh.text = _letter
	else:
		printerr("Mesh is not a TextMesh or is null in letter_3d.gd for letter: ", _letter)


func set_material(new_material: Material) -> void:
	# Use material_override on the MeshInstance3D itself
	self.material_override = new_material
	# print("Set material override on '", _letter, "' to: ", new_material)

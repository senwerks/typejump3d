extends Node3D

@export var number_of_chunks: int = 20
@export var level_chunks_path: String = "res://scenes/level_chunks.tscn"
@export var start_position: Vector3 = Vector3(0, 0, 0)

func _ready():
	generate_level()

func generate_level():
	# Load the level chunks scene
	var chunks_scene = load(level_chunks_path)
	if not chunks_scene:
		printerr("Failed to load level chunks from: ", level_chunks_path)
		return
	
	# Instance the scene to access its children
	var chunks_instance = chunks_scene.instantiate()
	
	# Get all the direct children (the chunk pieces)
	var available_chunks = []
	for child in chunks_instance.get_children():
		available_chunks.append(child)
	
	if available_chunks.size() == 0:
		printerr("No chunks found in the level chunks scene")
		chunks_instance.queue_free()
		return
	
	# We don't need the original instance anymore, just the references to its children
	chunks_instance.queue_free()
	
	# Keep track of where to place the next chunk
	var current_position = start_position
	
	# Generate the level
	for i in range(number_of_chunks):
		# Pick a random chunk
		var random_index = randi() % available_chunks.size()
		var chunk_template = available_chunks[random_index]
		
		# Create an instance of the selected chunk
		var chunk_instance = chunk_template.duplicate()
		
		# Place it at the current position
		chunk_instance.position = current_position
		
		# Add it to the scene
		add_child(chunk_instance)
		
		# Calculate where the next chunk should go
		# This assumes each chunk has the same width; you might need to adjust this
		# based on your specific chunk designs
		var chunk_width = 10.0  # Adjust this based on your chunk size
		current_position.x += chunk_width

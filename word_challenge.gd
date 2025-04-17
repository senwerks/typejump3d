extends Node3D

signal challenge_completed

@export var letter_scene: PackedScene
@export var letter_spacing: float = 0.5
@export var word_list: Array[String] = [
	"apple", "bunny", "candy", "cloud", "daisy",
	"eagle", "fairy", "grape", "happy", "jelly",
	"kitty", "lemon", "magic", "night", "ocean",
	"panda", "queen", "rainy", "smile", "tiger",
	"under", "vivid", "whale", "xylol", "yummy",
	"zebra", "brave", "charm", "dream", "event",
	"fizzy", "gleam", "honey", "igloo", "jolly",
	"koala", "laugh", "merry", "noble", "orbit",
	"poppy", "quiet", "raven", "sunny", "tulip",
	"uncle", "vroom", "winds", "xenon", "young"
]

var target_word: String = ""
var typed_word: String = ""
var letter_nodes: Array = []
var error_indices: Array = []  # Track which letters have errors

# Materials for the challenge words
@export var mat_correct: Material
@export var mat_incorrect: Material
@export var mat_default: Material

# Completed challenge particle explosion settings
@export var explosion_force: float = 5.0
@export var explosion_torque: float = 3.0
@export var fireworks_duration: float = 1.5

# Incorrect letter animation settings
@export var pulse_speed: float = 5.0
@export var pulse_min_scale: float = 0.8
@export var pulse_max_scale: float = 1.2

func _ready() -> void:
	# Hide by default
	visible = false

func _process(delta: float) -> void:
	# Animate pulsing for incorrect letters
	if visible and error_indices.size() > 0:
		var pulse_value = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed) + 1) / 2.0
		var current_scale = lerp(pulse_min_scale, pulse_max_scale, pulse_value)

		for error_index in error_indices:
			if error_index < letter_nodes.size() and is_instance_valid(letter_nodes[error_index]):
				letter_nodes[error_index].scale = Vector3(current_scale, current_scale, current_scale)

func start_challenge() -> void:
	# Select random word and reset everything
	target_word = word_list[randi() % word_list.size()]
	print("Target Word: " + target_word)
	typed_word = ""
	visible = true
	error_indices.clear()

	# Do the challenge words
	update_display()
	
	# Enable input processing
	set_process_input(true)
	
func update_display() -> void:
	# Clear existing letters
	for child in get_children():
		if child.is_in_group("letter"):
			child.queue_free()
	
	letter_nodes.clear()
	error_indices.clear()

	# Create new letters
	for i in target_word.length():
		var letter_instance = letter_scene.instantiate()
		letter_instance.letter = target_word[i]
		letter_instance.add_to_group("letter")
		
		# Set color based on typing progress
		if i < typed_word.length():
			if typed_word[i] == target_word[i]:
				# Typed letter is correct, add appropriate material
				letter_instance.set_material(mat_correct)
			else:
				# Typed letter is incorrect
				letter_instance.set_material(mat_incorrect)
				error_indices.append(i)  # Track this as a wrong-letter input for visual effects
		else:
			letter_instance.set_material(mat_default)
			letter_instance.scale = Vector3(1, 1, 1)  # Reset scale

		# Position the letter
		letter_instance.position.x = (i - target_word.length() / 2.0) * letter_spacing
		add_child(letter_instance)
		letter_nodes.append(letter_instance)

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode = event.keycode
		
		# Handle backspace
		if keycode == KEY_BACKSPACE and typed_word.length() > 0:
			typed_word = typed_word.substr(0, typed_word.length() - 1)
			update_display()
			
		# Handle letter keys
		elif keycode >= KEY_A and keycode <= KEY_Z:
			var can_type = true
			var current_pos = typed_word.length()
			
			# Check if we have any errors that need fixing first
			for i in typed_word.length():
				if typed_word[i] != target_word[i]:
					can_type = (i == current_pos - 1)
					break
			
			# Add the letter if valid
			if can_type and current_pos < target_word.length():
				typed_word += char(keycode).to_lower()
				update_display()
				
				# Check for completion
				if typed_word == target_word:
					complete_challenge()
					
func complete_challenge() -> void:
	# Word is correct, make it explode and the letters go flying randomly
	create_celebration_effects()
	
	# Wait while the effects play
	await get_tree().create_timer(fireworks_duration).timeout
	
	# Hide the challenge and signal success
	visible = false
	set_process_input(false)
	emit_signal("challenge_completed")

func create_celebration_effects() -> void:
	# Make each letter into a rigid body that tumbles away
	for i in range(letter_nodes.size()):
		var letter = letter_nodes[i]

		# Skip if the letter is no longer valid
		if !is_instance_valid(letter):
			continue
	
		# Create a rigid body to replace the letter
		var rigid_letter = RigidBody3D.new()
		rigid_letter.collision_layer = 0  # Don't collide with player
		rigid_letter.mass = 1.0

		# Add collision shape
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.4, 0.4, 0.4)  # Adjust based on your letter size
		collision.shape = shape
		rigid_letter.add_child(collision)

		# Transfer visual properties
		letter.get_parent().remove_child(letter)
		rigid_letter.add_child(letter)
		letter.position = Vector3.ZERO

		# Add to scene at the letter's position
		add_child(rigid_letter)
		rigid_letter.global_transform = letter.global_transform

		# Apply explosion force
		var direction = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.5, 1.5),  # Mostly upward
			randf_range(-1.0, 1.0)
		).normalized()

		rigid_letter.apply_central_impulse(direction * explosion_force)

		# Apply random rotation
		var torque = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * explosion_torque
		rigid_letter.apply_torque_impulse(torque)

		# Create fade-out effect with tween (TODO: Not working, not sure why)
		var start_fade_time = fireworks_duration * 0.5
		var fade_duration = fireworks_duration * 1

		var tween = create_tween()
		var original_material = letter.material_override

		# Duplicate the material to avoid affecting other letters with same material
		var fade_material = original_material.duplicate()

		# Enable transparency on the material
		fade_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fade_material.albedo_color.a = 1.0 # Force full alpha first? Troubleshooting.

		# Set the duplicated material
		letter.material_override = fade_material

		tween.tween_property(fade_material, "albedo_color:a", 0.0, fade_duration).set_delay(start_fade_time)

		# Finally remove after effect is complete
		tween.tween_callback(func(): rigid_letter.queue_free())

	# Now create fireworks particle effect
	create_fireworks_particles()

func create_fireworks_particles() -> void:
	# Create particle system
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = fireworks_duration
	particles.amount = 100
	
	# Start at the center of the word
	particles.position = Vector3(0, 0, 0)
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.1
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3(0, -1.0, 0)
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.angle_max = 360.0
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	
	# Color over lifetime - multiple colors for fireworks effect (TODO: Not working properly)
	particle_material.color_ramp = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.5, 0.1, 1))  # Orange
	gradient.add_point(0.25, Color(1, 1, 0.1, 1))   # Yellow
	gradient.add_point(0.5, Color(0.5, 1, 0.1, 1))  # Green
	gradient.add_point(0.75, Color(0.1, 0.5, 1, 1)) # Blue
	gradient.add_point(1.0, Color(1, 0.1, 1, 0))    # Purple, fade out
	particle_material.color_ramp.gradient = gradient
	
	particles.process_material = particle_material
	
	# Create mesh for particles
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.1
	particle_mesh.height = 0.2
	particles.draw_pass_1 = particle_mesh
	
	# Add to scene
	add_child(particles)
	
	# Set up auto-removal
	var timer = Timer.new()
	timer.wait_time = fireworks_duration + 0.5  # Extra time to ensure particles finish
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	add_child(timer)
	timer.start()

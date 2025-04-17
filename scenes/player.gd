extends CharacterBody3D

@export var move_speed: float = 3.0
@export var fall_acceleration: float = 20.0
@export var max_fall_speed: float = 50.0
@export var jump_strength: float = 12.0
@export var word_challenge_scene: PackedScene  # Assign word_challenge.tscn here
@export var challenge_group: String = "obstacle"  # Group name for obstacles that trigger challenges

var is_moving: bool = true
var active_challenge: RigidBody3D = null
var word_challenge: Node3D = null
var should_jump_next_frame: bool = false

@onready var camera = $Camera3D

func _ready() -> void:
	# Create the word challenge and attach it to camera
	word_challenge = word_challenge_scene.instantiate()
	camera.add_child(word_challenge)
	
	# Position it in front of the camera
	word_challenge.position = Vector3(0, -1, -2)
	
	# Connect the completion signal
	word_challenge.challenge_completed.connect(_on_challenge_completed)

func _physics_process(delta: float) -> void:
	if is_moving:
		velocity.x = move_speed
	else:
		velocity.x = 0.0

	# Jumping and gravity
	if should_jump_next_frame:
		velocity.y = jump_strength
		should_jump_next_frame = false
	elif not is_on_floor():
		velocity.y = clamp(velocity.y - fall_acceleration * delta, -max_fall_speed, max_fall_speed)
	else:
		velocity.y = 0.0

	move_and_slide()

	# Check for collisions with challenge objects
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if it's a RigidBody3D that has the obstacle group
		if collider is RigidBody3D and is_moving:
			# Option 1: Check if it's in our challenge group
			if collider.is_in_group(challenge_group):
				handle_collision_with_challenge(collider)
			
			# Option 2: Check if it's named "Obstacle" (based on your structure)
			elif collider.name == "Obstacle":
				handle_collision_with_challenge(collider)
			
			# Option 3: Check if it has a specific metadata tag
			elif collider.get_meta("is_challenge", false):
				handle_collision_with_challenge(collider)

func handle_collision_with_challenge(collider: RigidBody3D) -> void:
	print("Collided with ", collider)
	active_challenge = collider
	is_moving = false
	word_challenge.start_challenge()

func _on_challenge_completed() -> void:
	if active_challenge:
		# Disable the challenge collision
		active_challenge.collision_layer = 0
		active_challenge.collision_mask = 0
		
		# Visual feedback - make it disappear
		var tween = create_tween()
		tween.tween_property(active_challenge, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(active_challenge.queue_free)
		
		active_challenge = null
		
	# Jump and resume movement
	should_jump_next_frame = true
	is_moving = true

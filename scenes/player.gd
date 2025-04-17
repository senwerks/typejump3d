extends CharacterBody3D

@export var move_speed: float = 3.0
@export var fall_acceleration: float = 20.0
@export var max_fall_speed: float = 50.0
@export var jump_strength: float = 12.0
@export var word_challenge_scene: PackedScene

var is_moving: bool = true
var active_challenge: RigidBody3D = null
var word_challenge: Node3D = null
var challenge_completed: bool = false
var challenge_completion_timer: float = 0.0

@onready var camera = $Camera3D

func _ready() -> void:
	word_challenge = word_challenge_scene.instantiate()
	camera.add_child(word_challenge)
	word_challenge.position = Vector3(0, -1, -2)
	word_challenge.challenge_completed.connect(_on_challenge_completed)

func _physics_process(delta: float) -> void:
	# Handle challenge completion sequence
	if challenge_completed:
		challenge_completion_timer += delta
		
		# First pause briefly to show completion
		if challenge_completion_timer < 0.2:
			velocity = Vector3.ZERO
		# Then apply jump
		elif challenge_completion_timer < 0.3:
			velocity.y = jump_strength
			is_moving = true
		# Then reset the challenge state
		else:
			challenge_completed = false
			challenge_completion_timer = 0.0
	
	# Normal movement
	if is_moving:
		velocity.x = move_speed
	else:
		velocity.x = 0.0

	# Regular gravity when not in challenge completion sequence
	if not challenge_completed and not is_on_floor():
		velocity.y = clamp(velocity.y - fall_acceleration * delta, -max_fall_speed, max_fall_speed)
	elif not challenge_completed and is_on_floor():
		velocity.y = 0.0

	# Move the character
	move_and_slide()

	# Check for collisions with challenge objects
	if !challenge_completed and is_moving:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider is RigidBody3D:
				# Check if it's an obstacle using any method that works for your setup
				if collider.name == "Obstacle" or collider.is_in_group("obstacle"):
					active_challenge = collider
					is_moving = false
					word_challenge.start_challenge()
					break

func _on_challenge_completed() -> void:
	if active_challenge:
		# Disable the challenge collision immediately
		active_challenge.collision_layer = 0
		active_challenge.collision_mask = 0
		
		# Visual feedback
		var tween = create_tween()
		tween.tween_property(active_challenge, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(active_challenge.queue_free)
		
		active_challenge = null
	
	# Start the jump sequence
	challenge_completed = true
	challenge_completion_timer = 0.0

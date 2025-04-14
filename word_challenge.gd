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

@export var mat_correct: Material
@export var mat_incorrect: Material
@export var mat_default: Material

func _ready() -> void:
	# Hide by default
	visible = false
	
func start_challenge() -> void:
	# Select random word and reset
	target_word = word_list[randi() % word_list.size()]
	print("Target Word: " + target_word)
	typed_word = ""
	visible = true
	
	# Create the 3D text
	update_display()
	
	# Enable input processing
	set_process_input(true)
	
func update_display() -> void:
	# Clear existing letters
	for child in get_children():
		child.queue_free()
	
	# Create new letters
	for i in target_word.length():
		var letter_instance = letter_scene.instantiate()
		letter_instance.letter = target_word[i]
		
		# Set color based on typing progress
		if i < typed_word.length():
			if typed_word[i] == target_word[i]:
				letter_instance.set_material(mat_correct)
			else:
				letter_instance.set_material(mat_incorrect)
		else:
			letter_instance.set_material(mat_default)

		
		# Position the letter
		letter_instance.position.x = (i - target_word.length() / 2.0) * letter_spacing
		add_child(letter_instance)

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
	# Wait a moment to show the completed word
	await get_tree().create_timer(0.5).timeout
	
	# Hide the challenge and notify success
	visible = false
	set_process_input(false)
	emit_signal("challenge_completed")

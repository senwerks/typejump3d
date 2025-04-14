extends Area3D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("Player hit the lower boundary!")
		get_tree().reload_current_scene()

extends Area2D

@export var location: String 
@onready var transition: Node2D = $"../CanvasLayer2/Transition"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		transition.get_node("AnimationPlayer").play("Transition")
		await transition.get_node("AnimationPlayer").animation_finished
		get_tree().change_scene_to_file(location)

extends Node2D

@onready var transition: Node2D = $Transition_layer/Transition

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition.get_node("AnimationPlayer").play("Transition")
	

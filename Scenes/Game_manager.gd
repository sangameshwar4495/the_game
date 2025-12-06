extends Node2D

@onready var transition := $CanvasLayer2/Transition
@onready var anim: AnimationPlayer = transition.get_node("AnimationPlayer")

func _ready() -> void:
	var a := "Transition"
	var length := anim.get_animation(a).length

	anim.play(a)                   
	anim.seek(length, true)         
	anim.play_backwards(a)        

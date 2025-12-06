extends Node2D

@onready var animation_player: AnimationPlayer = $CanvasLayer/AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("Thank_you")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

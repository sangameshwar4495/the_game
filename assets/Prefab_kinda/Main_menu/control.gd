extends Control

@onready var start: TextureButton = $VBoxContainer/Start
@onready var transition: Node2D = $"../../../CanvasLayer2/Transition"

func _ready() -> void:
	await get_tree().process_frame
	start.grab_focus()

func _on_start_button_down() -> void:
	transition.get_node("AnimationPlayer").play("Transition")
	await transition.get_node("AnimationPlayer").animation_finished
	get_tree().change_scene_to_file("res://Scenes/level1.tscn")

func _on_quit_button_down() -> void:
	get_tree().quit()

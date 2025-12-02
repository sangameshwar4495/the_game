extends Control

@onready var start: TextureButton = $VBoxContainer/Start

func _ready() -> void:
	await get_tree().process_frame 
	start.grab_focus()

func _on_start_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/testing_scene.tscn")

func _on_quit_button_down() -> void:
	get_tree().quit()

extends Control

@onready var start: TextureButton = $VBoxContainer/Start
@export var animation:AnimationPlayer
@export var Transition:Node2D
@onready var anim_player: AnimationPlayer = Transition.get_node("AnimationPlayer") as AnimationPlayer
@export var canvas:CanvasLayer
@onready var transition_layer: CanvasLayer = $"../../../Transition_layer"
func _ready() -> void:
	await get_tree().process_frame 
	start.grab_focus()

func _on_start_button_down() -> void:
	canvas.visible = false 
	animation.play("Start_anim")
	await animation.animation_finished
	anim_player.play("Transition")
	await anim_player.animation_finished
	get_tree().change_scene_to_file("res://Scenes/level1.tscn")

func _on_quit_button_down() -> void:
	get_tree().quit()

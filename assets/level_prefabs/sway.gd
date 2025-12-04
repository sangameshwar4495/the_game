extends Node2D

@export var sway_amount: float = 8.0      # how far left/right
@export var sway_speed: float = 1.5       # how fast the wind moves
@export var sway_offset: float = 0.0      # set different per vine for variation

var t := 0.0

func _process(delta: float) -> void:
	t += delta * sway_speed
	rotation = sin(t + sway_offset) * deg_to_rad(sway_amount)

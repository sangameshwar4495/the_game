extends Node2D

@export var rot_amplitude := 6.0
@export var rot_speed := 3.0

@export var bob_amplitude := 4.0
@export var bob_speed := 3.0

var t := 0.0
var base_pos: Vector2

func _ready() -> void:
	base_pos = position

func _process(delta: float) -> void:
	t += delta

	rotation_degrees = sin(t * rot_speed) * rot_amplitude
	position.y = base_pos.y + sin(t * bob_speed) * bob_amplitude

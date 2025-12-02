extends Camera2D

@export var deadzone_size := Vector2(200, 140)
@export var camera_lerp_speed := 4.0

@export var look_ahead_distance := Vector2(120, 80)
@export var look_ahead_lerp := 6.0

var player: Node2D
var _look_offset := Vector2.ZERO

func _ready() -> void:
	player = get_node("../Player")

func _process(delta: float) -> void:
	var p := player.global_position
	var cam := global_position

	var half := deadzone_size * 0.5

	var left   := cam.x - half.x
	var right  := cam.x + half.x
	var top    := cam.y - half.y
	var bottom := cam.y + half.y

	var target := cam

	if p.x > right:
		var excess := p.x - right
		target.x += excess
	elif p.x < left:
		var excess := p.x - left
		target.x += excess

	if p.y > bottom:
		var excess := p.y - bottom
		target.y += excess
	elif p.y < top:
		var excess := p.y - top
		target.y += excess

	var vel := Vector2.ZERO
	if player.has_method("get_velocity"):
		vel = player.get_velocity()
	elif "velocity" in player:
		vel = player.velocity
	else:
		vel = p - cam

	var desired_offset := Vector2(
		sign(vel.x) * look_ahead_distance.x,
		sign(vel.y) * look_ahead_distance.y
	)

	_look_offset = _look_offset.lerp(desired_offset, look_ahead_lerp * delta)

	target += _look_offset

	global_position = global_position.lerp(target, camera_lerp_speed * delta)

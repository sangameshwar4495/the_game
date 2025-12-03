extends Camera2D

@export var deadzone_size := Vector2(200, 80)
@export var camera_lerp_speed := 4.0

@export var look_ahead_distance := Vector2(120, 80)
@export var look_ahead_lerp := 6.0

var player: Node2D
var _look_offset := Vector2.ZERO

# --- SHAKE ---
var shake_strength := 0.0
var shake_duration := 0.0
var shake_timer := 0.0
var shake_offset := Vector2.ZERO
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	player = get_node("../Player")
	GameEvents.player_died.connect(on_player_died)

func start_shake(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_timer = duration

func _physics_process(delta: float) -> void:
	var p := player.global_position
	var cam := global_position

	var half := deadzone_size * 0.5

	var left   := cam.x - half.x
	var right  := cam.x + half.x
	var top    := cam.y - half.y
	var bottom := cam.y + half.y

	var target := cam

	if p.x > right:
		target.x += p.x - right
	elif p.x < left:
		target.x += p.x - left

	if p.y > bottom:
		target.y += p.y - bottom
	elif p.y < top:
		target.y += p.y - top

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

	var base := global_position.lerp(target, camera_lerp_speed * delta)

	update_shake(delta)
	global_position = base + shake_offset


func update_shake(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		var falloff := shake_timer / shake_duration
		shake_offset = Vector2(
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1)
		) * shake_strength * falloff
	else:
		shake_offset = Vector2.ZERO

func on_player_died() -> void:
	start_shake(10.0, 0.4)

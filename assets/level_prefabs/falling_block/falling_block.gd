extends CharacterBody2D

@export var gravity := 1800.0
@export var shake_time := 0.3
@export var shake_strength := 4.0

var shaking := false
var falling := false
var shake_timer := 0.0
var original_pos := Vector2.ZERO
var fall_speed := 0.0

func _ready() -> void:
	original_pos = position
	$Player_Check.body_entered.connect(_on_player_check_body_entered)

func _physics_process(delta: float) -> void:
	if shaking:
		shake_timer += delta
		position = original_pos + Vector2(
			(randf() - 0.5) * shake_strength,
			(randf() - 0.5) * shake_strength
		)
		if shake_timer >= shake_time:
			position = original_pos
			shaking = false
			falling = true

	elif falling:
		fall_speed += gravity * delta
		velocity.y = fall_speed
		move_and_slide()
		if is_on_floor():
			despawn()

func despawn() -> void:
	queue_free()

func _on_player_check_body_entered(body) -> void:
	if body.name == "Player" and not shaking and not falling:
		shaking = true
		shake_timer = 0.0

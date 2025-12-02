extends CharacterBody2D

enum {
	STATE_PATROL,
	STATE_SPOT,
	STATE_CHASE
}

@onready var exclaim := $GFX/ExclaimSign
@onready var exclaim_tween := create_tween()

@export var patrol_speed: float = 70.0
@export var chase_speed: float = 230.0
@export var sight_distance: float = 340.0
@export var gravity: float = 2000.0
@export var flip_with_direction: bool = true
@export var chase_accel := 20.0
@export var forget_distance := 500.0
@export var los_mask := 1
@export var vertical_vision_tolerance := 40.0

var spot_time: float = 1.0
var player: Node2D = null
var direction: float = -1.0
var t: float = 0.0
var state: int = STATE_PATROL
var spot_timer: float = 0.0

@onready var gfx: Node2D = $GFX
@onready var head: Node2D = $GFX/Head
@onready var mid: Node2D = $GFX/Mid
@onready var butt: Node2D = $GFX/Butt
@onready var leg1: Node2D = $GFX/Leg1
@onready var leg2: Node2D = $GFX/Leg2
@onready var mouth: Node2D = $GFX/Mouth

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	hide_exclaim()

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	match state:
		STATE_PATROL:
			state_patrol(delta)
		STATE_SPOT:
			state_spot(delta)
		STATE_CHASE:
			state_chase(delta)

	if flip_with_direction and direction != 0.0:
		gfx.scale.x = direction

	apply_body_animation(delta)
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			player.die()

	if is_on_wall():
		direction *= -1.0

func state_patrol(delta: float) -> void:
	if player != null:
		var to_player = player.global_position - global_position
		var facing_player = sign(to_player.x) == direction
		var aligned_y = abs(to_player.y) < vertical_vision_tolerance

		if facing_player and aligned_y and to_player.length() < sight_distance:
			state = STATE_SPOT
			spot_timer = spot_time
			velocity.x = 0.0
			show_exclaim()
			return


	velocity.x = lerp(velocity.x, direction * patrol_speed, 6.0 * delta)

func state_spot(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 12.0 * delta)
	spot_timer -= delta
	if spot_timer <= 0.0:
		state = STATE_CHASE
		hide_exclaim()



func state_chase(delta: float) -> void:
	if player == null:
		state = STATE_PATROL
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var aligned_y = abs(to_player.y) < vertical_vision_tolerance

	var params = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	params.collide_with_areas = false
	params.collision_mask = los_mask
	var hit = get_world_2d().direct_space_state.intersect_ray(params)
	var has_los = (hit.is_empty() or hit["collider"] == player)

	if (not has_los or not aligned_y) and dist > forget_distance:
		hide_exclaim()
		state = STATE_PATROL
		return

	direction = float(sign(to_player.x))
	var target_speed = direction * chase_speed
	velocity.x = lerp(velocity.x, target_speed, chase_accel * delta)

func apply_body_animation(delta: float) -> void:
	var horizontal_speed = abs(velocity.x)

	var chase_boost = 1.8 if state == STATE_CHASE else 1.0
	var spotting_slow = 0.3 if state == STATE_SPOT else 1.0

	var walk_amp = 0.20
	var run_amp = 0.57
	var walk_body_amp = 0.04
	var run_body_amp = 0.10
	var walk_phase_speed = 6.0
	var run_phase_speed = 11.0

	var pause_scale = 0.1 if state == STATE_SPOT else 1.0

	var run_blend = clamp(horizontal_speed / chase_speed, 0.0, 1.0)

	var leg_amp = lerp(walk_amp, run_amp, run_blend)
	var body_amp = lerp(walk_body_amp, run_body_amp, run_blend)
	var phase_speed = lerp(walk_phase_speed, run_phase_speed, run_blend)

	leg_amp *= chase_boost
	body_amp *= chase_boost * 0.9
	phase_speed *= chase_boost

	leg_amp *= spotting_slow
	body_amp *= spotting_slow * 0.9
	phase_speed *= spotting_slow

	var idle_blend = clamp(horizontal_speed / 40.0, 0.0, 1.0)
	leg_amp *= idle_blend
	body_amp *= idle_blend
	phase_speed *= idle_blend

	leg_amp *= pause_scale
	body_amp *= pause_scale
	phase_speed = max(phase_speed * pause_scale, 0.2)

	t += delta * phase_speed

	var ph1 = sin(t * 2.0)
	var ph2 = sin(t * 2.0 + PI)
	leg1.rotation = ph1 * leg_amp
	leg2.rotation = ph2 * leg_amp

	var sway = sin(t * 1.1)
	head.rotation = sway * body_amp
	mid.rotation = sway * -body_amp * 0.8
	butt.rotation = sway * body_amp * 0.6

	mouth.position.y = sin(t * 0.9) * (body_amp * 6.0)


func show_exclaim() -> void:
	exclaim.visible = true
	exclaim.scale = Vector2(0.0, 0.0)
	exclaim.position.y = -70
	var tw = create_tween()
	tw.tween_property(exclaim, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(exclaim, "position:y", -68.0, 0.08)

func hide_exclaim() -> void:
	var tw = create_tween()
	tw.tween_property(exclaim, "scale", Vector2(0.0, 0.0), 0.10).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(exclaim.hide)

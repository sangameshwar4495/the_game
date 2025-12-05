@tool
extends CharacterBody2D

@export var antenna1: Node2D
@export var antenna2: Node2D
@export var cape: Node2D
@export var body: Node2D
@export var Eye_left: Node2D
@export var Eye_right: Node2D

@export var run_threshold := 20.0
@export var run_animation_enabled := true
@export var fall_animation_enabled := false

# -----------------------------
# HOP SETTINGS
# -----------------------------
@export var hop_enabled := true
@export var hop_height := 10.0
@export var hop_min_interval := 1.0
@export var hop_max_interval := 3.0

var hop_timer := 0.0
var next_hop_time := 0.0
var hop_progress := 0.0

# -----------------------------
# Antenna parameters
# -----------------------------
const ANT_RUN_FREQ = 8.0
const ANT_RUN_AMP = 0.35
const ANT_FALL_FREQ = 14.0
const ANT_FALL_AMP = 0.5

# Cape parameters
const CAPE_SWING_FREQ = 10.0
const CAPE_SWING_AMP = 0.22
const CAPE_FLAP_FREQ = 26.0
const CAPE_FLAP_AMP = 0.05

# Body tilt
const TILT_ANGLE_DEG = 5.0

# Eye blink parameters (from original script)
var blink_timer := 0.0
var next_blink := 0.0
var blink_anim_t := -1.0
const BLINK_MIN_INTERVAL = 1.0
const BLINK_MAX_INTERVAL = 4.0
const BLINK_DURATION = 0.14

var anim_time := 0.0
var fake_vel_x := 0.0
const ACCEL = 6.0
const DECEL = 5.0
const MAX_SPEED = 40.0

func _process(delta):
	if run_animation_enabled:
		simulate_velocity(delta)

	update_run_animation(fake_vel_x, delta)
	update_fall_animation(delta)
	update_blink(delta)
	update_hop(delta)


# -------------------------------
# SIMULATED VELOCITY
# -------------------------------
func simulate_velocity(delta):
	if fake_vel_x < MAX_SPEED:
		fake_vel_x += ACCEL
	else:
		fake_vel_x -= DECEL

	fake_vel_x = clamp(fake_vel_x, 0, MAX_SPEED)


# -------------------------------
# EYE BLINKS (original style)
# -------------------------------
func update_blink(delta):
	if blink_anim_t < 0.0:
		blink_timer += delta
		if blink_timer >= next_blink:
			blink_anim_t = 0.0
			blink_timer = 0.0
	else:
		blink_anim_t += delta
		var p = blink_anim_t / BLINK_DURATION
		if p >= 1.0:
			set_eye_scale_y(1.0)
			blink_anim_t = -1.0
			schedule_next_blink()
		else:
			if p < 0.5:
				var t = p * 2.0
				var s = lerp(1.0, 0.06, t * (2.0 - t))
				set_eye_scale_y(s)
			else:
				var t2 = (p - 0.5) * 2.0
				var s2 = lerp(0.06, 1.0, t2 * t2)
				set_eye_scale_y(s2)


func schedule_next_blink():
	next_blink = randf_range(BLINK_MIN_INTERVAL, BLINK_MAX_INTERVAL)
	blink_timer = 0.0


func set_eye_scale_y(v):
	if Eye_left:
		var s = Eye_left.scale
		s.y = v
		Eye_left.scale = s
	if Eye_right:
		var s = Eye_right.scale
		s.y = v
		Eye_right.scale = s


# -------------------------------
# RUN ANIMATION
# -------------------------------
func update_run_animation(vel_x: float, delta: float):
	anim_time += delta

	var is_running = abs(vel_x) > run_threshold

	if not is_running or not run_animation_enabled:
		_reset_animation(delta)
		return

	if vel_x != 0:
		body.scale.x = sign(vel_x)

	var target_rot = -deg_to_rad(TILT_ANGLE_DEG) * sign(vel_x)
	body.rotation = lerp(body.rotation, target_rot, 0.7)

	var t1 = sin(anim_time * ANT_RUN_FREQ) * ANT_RUN_AMP
	var t2 = sin(anim_time * ANT_RUN_FREQ + 0.4) * ANT_RUN_AMP * 0.9

	antenna1.rotation = lerp(antenna1.rotation, t1, delta * 12.0)
	antenna2.rotation = lerp(antenna2.rotation, t2, delta * 12.0)

	var swing = sin(anim_time * CAPE_SWING_FREQ) * CAPE_SWING_AMP
	var flap  = sin(anim_time * CAPE_FLAP_FREQ) * CAPE_FLAP_AMP
	var target_cape_rot = swing + flap

	cape.rotation = lerp(cape.rotation, target_cape_rot, delta * 10.0)


# -------------------------------
# FALLING ANIMATION
# -------------------------------
func update_fall_animation(delta):
	if not fall_animation_enabled:
		return

	var t1 = sin(anim_time * ANT_FALL_FREQ) * ANT_FALL_AMP
	var t2 = sin(anim_time * ANT_FALL_FREQ + 0.25) * ANT_FALL_AMP * 0.85

	antenna1.rotation = lerp(antenna1.rotation, t1, delta * 12.0)
	antenna2.rotation = lerp(antenna2.rotation, t2, delta * 12.0)

	var swing = sin(anim_time * 14.0) * 0.18
	var flap  = sin(anim_time * 24.0) * 0.10
	var target_cape_rot = 0.35 + swing + flap

	cape.rotation = lerp(cape.rotation, target_cape_rot, delta * 10.0)

	body.rotation = lerp(body.rotation, deg_to_rad(5), 0.7)


# -------------------------------
# HOP ANIMATION
# -------------------------------
func update_hop(delta):
	if not hop_enabled:
		body.position.y = 0
		return

	hop_timer += delta
	if hop_timer >= next_hop_time:
		hop_timer = 0
		next_hop_time = randf_range(hop_min_interval, hop_max_interval)
		hop_progress = 1.0

	if hop_progress > 0:
		# Smooth hop with sine curve
		var hop = sin((1.0 - hop_progress) * PI) * hop_height
		body.position.y = -hop
		hop_progress -= delta * 2.0   # Adjust hop speed
	else:
		body.position.y = 0


func _reset_animation(delta):
	antenna1.rotation = lerp(antenna1.rotation, 0.0, delta * 5.0)
	antenna2.rotation = lerp(antenna2.rotation, 0.0, delta * 5.0)
	cape.rotation = lerp(cape.rotation, 0.0, delta * 5.0)
	body.rotation = lerp(body.rotation, 0.0, 0.5)
	body.position.y = 0

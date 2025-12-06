extends CharacterBody2D

const GRAVITY = 2400.0
const EXTRA_FALL_GRAVITY = 2.2
const HANG_GRAVITY = 0.15
const CUT_GRAVITY = 2.8

const MAX_SPEED = 390.0
const MAX_FALL_SPEED = 986.0
const GLIDE_VELOCITY = 110.0
const GLIDE_CLIP_VEL = 100.0

const ACCELERATION = 7200.0
const JUMP_VELOCITY = -690.0
const MIN_JUMP_VELOCITY = -500.0

const WALL_JUMP_VELOCITY = -720.0
const WALL_JUMP_PUSH = 370.0
const WALL_JUMP_CONTROL_LOCK = 0.10

const COYOTE_TIME = 0.11
const JUMP_BUFFER_TIME = 0.10
const WALL_COYOTE_TIME = 0.3

@onready var rotatable = $Rotatable
@onready var antenna1 = $Rotatable/Antena1
@onready var antenna2 = $Rotatable/Antena2
@onready var eye1 = $Rotatable/Eye1
@onready var eye2 = $Rotatable/Eye2
@onready var cape = $Rotatable/Cape
@onready var audio = $AudioPlayer
@onready var spawn: Node2D = $"../Spawn"

var jump_audio_stream = preload("res://assets/audio/jump.wav")
var wall_jump_audio_stream = preload("res://assets/audio/wall_jump.wav")
var land_audio_stream = preload("res://assets/audio/land.wav")
var die_audio_stream = preload("res://assets/audio/hurt.wav")

var has_amethyst: bool = false
var amethyst_node: Node = null

var vel := Vector2.ZERO
var axis := Vector2.ZERO

var coyote_timer = 0.0
var wall_coyote_timer = 0.0
var jump_buffer_timer = 0.0

var can_jump = false
var airborne_friction = false
var is_shielding = false

var on_wall = false
var wall_dir = 0
var last_wall_dir = 0
var wall_jump_lock = 0.0
var is_gliding = false
var was_gliding = false

var glide_delay := 0.0
var glide_delay_time := 0.22

var anim_time = 0.0

var blink_timer = 0.0
var next_blink = 0.0
const BLINK_MIN_INTERVAL = 1.0
const BLINK_MAX_INTERVAL = 4.0
const BLINK_DURATION = 0.14
var blink_anim_t = -1.0

var anten1_rot = 0.0
var anten2_rot = 0.0

const ANT_IDLE_FREQ = 2.0
const ANT_IDLE_AMP = 0.18
const ANT_RUN_FREQ = 8.0
const ANT_RUN_AMP = 0.35
const ANT_FALL_FREQ = 20.0
const ANT_FALL_AMP = 0.5
const ANT_JUMP_TILT = -0.28
const ANT_WALL_TILT = 0.45

const RUN_THRESHOLD = 20.0

var cape_rot = 0.0
var cape_swing = 0.0
var cape_flap = 0.0

var max_stamina = 100.0
var stamina = 100.0
var stamina_recharge_delay = 0.0
var stamina_recharge_cooldown = 0.56

var glide_stamina_drain := 10.0
var wall_jump_stamina_cost := 12.0
var stamina_recovery_rate := 4.0

var current_spawn: Vector2
var was_on_floor = false
var was_on_wall = false
var prev_vel_y = 0

func sign_nonzero(x: float) -> int:
	if x > 0: return 1
	if x < 0: return -1
	if rotatable and rotatable.scale.x != 0:
		return int(sign(rotatable.scale.x))
	return 1

func _ready():
	current_spawn = spawn.global_position
	add_to_group("player")
	randomize()
	schedule_next_blink()

func _physics_process(delta):
	get_input_axis()
	glide_delay = max(glide_delay - delta, 0.0)

	apply_gravity(delta)
	check_wall()
	handle_floor_and_coyote(delta)
	handle_jump_input(delta)
	handle_wall_slide()
	apply_variable_jump(delta)
	wall_jump_lock = max(wall_jump_lock - delta, 0.0)
	horizontal_movement(delta)

	prev_vel_y = vel.y
	velocity = vel
	move_and_slide()
	vel = velocity

	update_stamina(delta)

	anim_time += delta
	update_state_and_flip()
	update_ambient(delta)
	update_cape(delta)
	apply_debug_rotation()

	SFX_post_motion()

func SFX_post_motion():
	if is_on_floor() and not was_on_floor and prev_vel_y > 200:
		play_sfx(land_audio_stream)

	was_gliding = is_gliding
	was_on_floor = is_on_floor()
	was_on_wall = on_wall

func play_sfx(stream):
	if audio and stream:
		audio.stream = stream
		audio.play()

func update_stamina(delta):
	if is_gliding:
		stamina -= glide_stamina_drain * delta
		stamina_recharge_delay = stamina_recharge_cooldown
	elif is_on_floor() or (on_wall and vel.y > 0):
		if stamina_recharge_delay > 0.0:
			stamina_recharge_delay -= delta
		else:
			var before = stamina
			stamina += stamina_recovery_rate * delta
			if stamina >= max_stamina and before < max_stamina:
				pass

	stamina = clamp(stamina, 0.0, max_stamina)

func get_input_axis():
	axis.x = float(Input.is_action_pressed("right")) - float(Input.is_action_pressed("left"))
	if axis.length() > 1:
		axis = axis.normalized()

func check_wall():
	on_wall = false
	wall_dir = 0

	if not is_on_floor() and is_on_wall_only():
		var col = get_last_slide_collision()
		if col:
			wall_dir = int(sign(col.get_normal().x))

			# Only stick if input is towards wall!
			if axis.x != 0 and axis.x == -wall_dir:
				on_wall = true
				last_wall_dir = wall_dir


func apply_gravity(delta):
	if vel.y < 0:
		if Input.is_action_pressed("jump"):
			vel.y += GRAVITY * (1.0 - HANG_GRAVITY) * delta
		else:
			vel.y += GRAVITY * delta
	else:
		var clip = MAX_FALL_SPEED
		var can_glide = glide_delay <= 0.0

		if can_glide and Input.is_action_pressed("jump") and vel.y > GLIDE_CLIP_VEL and stamina > 0.0:
			clip = GLIDE_VELOCITY
			is_gliding = true
		else:
			is_gliding = false

		vel.y += GRAVITY * EXTRA_FALL_GRAVITY * delta
		vel.y = min(vel.y, clip)

func handle_floor_and_coyote(delta):
	if is_on_floor():
		can_jump = true
		coyote_timer = 0.0
		wall_coyote_timer = 0.0
		on_wall = false
		airborne_friction = false
	else:
		coyote_timer += delta
		if on_wall:
			wall_coyote_timer = 0.0
		else:
			wall_coyote_timer += delta
		if coyote_timer > COYOTE_TIME:
			can_jump = false
		airborne_friction = true

func handle_jump_input(delta):
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	jump_buffer_timer -= delta

	if jump_buffer_timer > 0.0:
		if can_jump:
			do_jump()
			jump_buffer_timer = 0.0
		elif on_wall or wall_coyote_timer < WALL_COYOTE_TIME:
			do_wall_jump()
			jump_buffer_timer = 0.0

func handle_wall_slide():
	if on_wall and vel.y > 0 and axis.x == -wall_dir:
		vel.y = min(vel.y, MAX_FALL_SPEED * 0.25)


func apply_variable_jump(delta):
	if not Input.is_action_pressed("jump") and vel.y < 0:
		vel.y += GRAVITY * CUT_GRAVITY * delta
	if Input.is_action_just_released("jump") and vel.y < MIN_JUMP_VELOCITY:
		vel.y = MIN_JUMP_VELOCITY

func horizontal_movement(delta):
	if wall_jump_lock > 0:
		vel.x = move_toward(vel.x, 0, ACCELERATION * delta * 0.4)
		return

	if on_wall:
		vel.x = 0
		return

	if axis.x != 0:
		var t = axis.x * MAX_SPEED
		if sign(vel.x) != axis.x:
			vel.x = move_toward(vel.x, t, ACCELERATION * delta * 2.0)
		else:
			vel.x = move_toward(vel.x, t, ACCELERATION * delta)

		rotatable.scale.x = sign_nonzero(axis.x)
	else:
		vel.x = move_toward(vel.x, 0, ACCELERATION * delta * 0.7)

	if airborne_friction:
		vel.x = lerp(vel.x, 0.0, 0.08)

@export var feet:Node2D
@export var side:Node2D
@export var Particle_fx:Node2D

func instantiate_jump_particles():
	var Position = feet.global_position
	Particle_fx.global_position = Position
	Particle_fx.play_particle()

func instantiate_Walljump_particles():
	var Position = side.global_position
	Particle_fx.global_position = Position
	Particle_fx.play_particle()

func do_jump():
	play_sfx(jump_audio_stream)
	instantiate_jump_particles()
	vel.y = JUMP_VELOCITY
	can_jump = false
	glide_delay = glide_delay_time
	

func do_wall_jump():
	if stamina <= 0.0:
		return

	glide_delay = glide_delay_time
	stamina -= wall_jump_stamina_cost
	stamina_recharge_delay = stamina_recharge_cooldown
	stamina = max(stamina, 0.0)

	instantiate_Walljump_particles()
	play_sfx(wall_jump_audio_stream)

	var d = int(sign(axis.x))
	var p = WALL_JUMP_PUSH

	if d != 0 and d == -wall_dir:
		p *= 1.65
	else:
		p *= 2.3

	vel.y = WALL_JUMP_VELOCITY
	vel.x = wall_dir * p
	wall_jump_lock = WALL_JUMP_CONTROL_LOCK

	if d == 0:
		rotatable.scale.x = -sign_nonzero(rotatable.scale.x)
	else:
		rotatable.scale.x = -sign_nonzero(wall_dir)

func update_state_and_flip():
	if on_wall:
		rotatable.scale.x = -sign_nonzero(wall_dir)

func update_ambient(delta):
	update_blink(delta)
	update_antennas(delta)

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
	if eye1:
		var s = eye1.scale
		s.y = v
		eye1.scale = s
	if eye2:
		var s = eye2.scale
		s.y = v
		eye2.scale = s

func update_antennas(delta):
	var st = "idle"
	if on_wall:
		st = "wall"
	elif not is_on_floor():
		if vel.y < 0:
			st = "jump"
		else:
			st = "glide" if is_gliding else "fall"
	elif abs(vel.x) > RUN_THRESHOLD:
		st = "run"

	var t1 = 0.0
	var t2 = 0.0

	match st:
		"idle":
			t1 = sin(anim_time * ANT_IDLE_FREQ) * ANT_IDLE_AMP * 0.8
			t2 = sin(anim_time * ANT_IDLE_FREQ + 0.7) * ANT_IDLE_AMP * 0.9
		"run":
			t1 = sin(anim_time * ANT_RUN_FREQ) * ANT_RUN_AMP
			t2 = sin(anim_time * ANT_RUN_FREQ + 0.4) * ANT_RUN_AMP * 0.9
		"jump":
			t1 = ANT_JUMP_TILT + sin(anim_time * 10.0) * 0.06
			t2 = ANT_JUMP_TILT + sin(anim_time * 10.0 + 0.5) * 0.05
		"fall":
			t1 = sin(anim_time * ANT_FALL_FREQ) * ANT_FALL_AMP
			t2 = sin(anim_time * ANT_FALL_FREQ + 0.25) * ANT_FALL_AMP * 0.85
		"glide":
			t1 = sin(anim_time * 3.0) * ANT_IDLE_AMP * 0.6
			t2 = sin(anim_time * 3.0 + 0.6) * ANT_IDLE_AMP * 0.6
		"wall":
			var tt = -ANT_WALL_TILT
			t1 = tt + sin(anim_time * 4.0) * 0.08
			t2 = tt + sin(anim_time * 4.0 + 0.3) * 0.06

	var sp = clamp(12.0 * delta, 0.0, 1.0)
	anten1_rot = lerp_angle(anten1_rot, t1, sp)
	anten2_rot = lerp_angle(anten2_rot, t2, sp)

	if antenna1:
		antenna1.rotation = anten1_rot
	if antenna2:
		antenna2.rotation = anten2_rot

func update_cape(delta):
	var st = "idle"
	if on_wall:
		st = "wall"
	elif not is_on_floor():
		if vel.y < 0:
			st = "jump"
		else:
			st = "glide" if is_gliding else "fall"
	elif abs(vel.x) > RUN_THRESHOLD:
		st = "run"

	var base = 0.0
	var swing = 0.0
	var flap = 0.0

	match st:
		"idle":
			swing = sin(anim_time * 1.4) * 0.08
		"run":
			swing = sin(anim_time * 10.0) * 0.22
			flap = sin(anim_time * 26.0) * 0.05
		"jump":
			base = -0.10
			swing = sin(anim_time * 4.0) * 0.10
		"fall":
			base = 0.35
			swing = sin(anim_time * 14.0) * 0.18
			flap = sin(anim_time * 24.0) * 0.10
		"glide":
			base = 0.75
			swing = sin(anim_time * 3.0) * 0.10
		"wall":
			base = -0.45
			swing = sin(anim_time * 5.0) * 0.05

	var target = base + swing + flap
	var sp = clamp(10.0 * delta, 0.0, 1.0)
	cape_rot = lerp_angle(cape_rot, target, sp)

	if cape:
		cape.rotation = cape_rot

func apply_debug_rotation():
	var t = 0.0
	if axis.x != 0 and abs(vel.x) > 0.01:
		t = -deg_to_rad(5) * axis.x
	rotatable.rotation = lerp(rotatable.rotation, t, 0.7)

func add_stamina(amount: float) -> void:
	stamina = clamp(stamina + amount, 0.0, max_stamina)

func set_stamina_max(value: float) -> void:
	max_stamina = max(value, 0.0)
	stamina = clamp(stamina, 0.0, max_stamina)

func set_respawn(checkpoint_:Vector2):
	current_spawn = checkpoint_

func distance_to_spawn():
	var displacement_vector = current_spawn - $".".global_position 
	return displacement_vector.length()

func respawn():
	global_position = current_spawn
	stamina = max_stamina

	var time := 0.2
	if distance_to_spawn() > 15:
		get_tree().paused = true
		await get_tree().create_timer(time).timeout
		get_tree().paused = false

	set_physics_process(true)
	set_process(true)
	
func die() -> void:
	set_physics_process(false)
	set_process(false)
	
	has_amethyst = false
	amethyst_node = null

	GameEvents.player_died.emit()

	play_sfx(die_audio_stream)

	await get_tree().create_timer(0.35).timeout 
	respawn()
	

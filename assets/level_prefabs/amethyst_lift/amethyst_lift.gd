extends Node2D

@export var lift_height: float = -200.0
@export var lift_speed: float = 120.0
@export var debug_draw: bool = true

var platform: Node2D
var start_pos: Vector2
var target_pos: Vector2
var lifting: bool = false
var player_trigger: Node = null
var last_platform_pos: Vector2

func _ready() -> void:
	platform = $Moving_Platform
	start_pos = platform.position
	target_pos = start_pos + Vector2(0, lift_height)
	last_platform_pos = platform.position

	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	var prev := platform.position

	if lifting:
		platform.position = platform.position.move_toward(target_pos, lift_speed * delta)
		if platform.position.distance_to(target_pos) < 1.0:
			platform.position = target_pos
			lifting = false

	var motion := platform.position - prev

	if player_trigger and motion != Vector2.ZERO:
		player_trigger.position += motion

	last_platform_pos = platform.position

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_trigger = body

	if body.has_amethyst:
		body.has_amethyst = false

		if body.amethyst_node:
			body.amethyst_node.queue_free()
			body.amethyst_node = null

		lifting = true

func _on_body_exited(body: Node) -> void:
	if body == player_trigger:
		player_trigger = null

func _draw() -> void:
	if not debug_draw:
		return

	var line_col      = Color(0.25, 0.28, 0.22, 0.45)
	var shadow_col    = Color(0.1, 0.1, 0.1, 0.35)
	var highlight_col = Color(0.55, 0.6, 0.5, 0.35)
	var plate_col     = Color(0.2, 0.22, 0.2, 0.55)

	var p = platform.position
	var base_thick := 2.0
	var t := Time.get_ticks_msec() * 0.001
	var wobble := 0.3 + sin(t * 1.3) * 0.15

	var mid := (start_pos + target_pos) * 0.5 + Vector2(-6, 3)
	draw_polyline([start_pos, mid, target_pos], line_col, base_thick + wobble, true)
	draw_polyline([start_pos, mid, target_pos], shadow_col, 1.0, true)

	draw_circle(start_pos, 8, plate_col)
	draw_circle(start_pos, 4, highlight_col)
	draw_circle(target_pos, 8, plate_col)
	draw_circle(target_pos, 4, highlight_col)

	var rect = Rect2(p - Vector2(24, 8), Vector2(48, 16))
	draw_rect(rect.grow(3), shadow_col, true)
	draw_rect(rect, plate_col, true)
	draw_rect(rect, line_col, false, base_thick + wobble)

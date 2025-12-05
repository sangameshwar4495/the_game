extends Node2D

@export var lift_height: float = -200.0
@export var lift_speed: float = 120.0
@export var debug_draw: bool = true

var platform: Node2D
var start_pos: Vector2
var target_pos: Vector2
var lifting: bool = false
var player_trigger: Node = null

func _ready() -> void:
	platform = $Moving_Platform
	start_pos = platform.position
	target_pos = start_pos + Vector2(0, lift_height)

	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if lifting:
		platform.position = platform.position.move_toward(target_pos, lift_speed * delta)

		if platform.position.distance_to(target_pos) < 1.0:
			platform.position = target_pos
			lifting = false

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

	var p = platform.position
	var col := Color(0.6, 0.8, 1.0, 0.7)

	draw_circle(start_pos, 6, col)
	draw_circle(target_pos, 6, Color(1.0, 0.5, 0.6, 0.7))
	draw_line(start_pos, target_pos, Color(0.8, 0.4, 1.0, 0.8), 2)

	var rect = Rect2(p - Vector2(24, 8), Vector2(48, 16))
	draw_rect(rect, Color(0, 0.6, 0.2, 0.25))
	draw_rect(rect, Color(0.1, 1.0, 0.3, 0.8), false, 2)

extends Node2D

@export var follow_speed: float = 30.0
@export var follow_distance: float = 40.0
@export var bob_height: float = 6.0
@export var bob_speed: float = 3.0

var base_y: float
var t: float = 0.0
var original_pos: Vector2
var collected: bool = false
var player: Node = null

func _ready() -> void:
	original_pos = position
	base_y = position.y
	$Area2D.body_entered.connect(_on_body_entered)
	GameEvents.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
	if not collected:
		t += delta * bob_speed
		position.y = base_y + sin(t) * bob_height
		return

	if player:
		var target = player.global_position - Vector2(0, follow_distance)
		position = position.lerp(target, delta * follow_speed)

func _on_body_entered(body: Node) -> void:
	if collected:
		return

	if body.is_in_group("player"):
		player = body
		player.has_amethyst = true
		player.amethyst_node = self

		$CollectSound.play()
		collected = true
		$Area2D.monitoring = false


func _on_player_died() -> void:
	collected = false

	if player:
		player.has_amethyst = false
		player.amethyst_node = null

	player = null

	position = original_pos
	base_y = original_pos.y
	t = 0.0

	$Area2D.monitoring = true
	$Sprite2D.visible = true

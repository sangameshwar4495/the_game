extends Area2D

var player: CharacterBody2D

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()

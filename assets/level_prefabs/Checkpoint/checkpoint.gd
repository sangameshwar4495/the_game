extends Node2D

@onready var checkpoint: Node2D = $"."
@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $ColorRect/AnimationPlayer

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.set_respawn(checkpoint.global_position)
		animation_player.play("Fade_In")
		await get_tree().create_timer(2).timeout
		queue_free()

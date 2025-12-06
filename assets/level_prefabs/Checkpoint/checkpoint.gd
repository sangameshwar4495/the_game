extends Node2D

@onready var checkpoint: Node2D = $"."
@onready var sprite := $Sprite

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.set_respawn(checkpoint.global_position)
		fade_out()

func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await tw.finished
	queue_free()

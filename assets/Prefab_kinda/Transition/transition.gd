extends Node2D

func play_anim():
	$AnimationPlayer.play("Transition")
	await $AnimationPlayer.animation_finished

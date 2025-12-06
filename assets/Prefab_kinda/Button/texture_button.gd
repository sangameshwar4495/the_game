@tool
extends TextureButton

@export var text = "Text button"
@export var arrow_margin_from_center = 100
@export var sway_amplitude := 6.0
@export var sway_speed := 4.0

var time : float = 0.0
var base_left_x : float
var base_right_x : float

func _ready():
	setup_text()
	hide_arrows()

func _process(delta: float):
	if Engine.is_editor_hint():
		setup_text()
		show_arrows()

	time += delta
	apply_sine_sway()

func apply_sine_sway():
	if not $Left.visible:
		return

	var sway = sin(time * sway_speed) * sway_amplitude
	$Left.position.x = base_left_x + sway
	$Right.position.x = base_right_x - sway

func setup_text():
	$Text.bbcode_text = "[center] %s [/center]" % text

func show_arrows():
	for arrow in [$Right, $Left]:
		arrow.visible = true

	var center_x = get_global_rect().position.x + (get_global_rect().size.x / 2)
	$Left.global_position.x = center_x - arrow_margin_from_center
	$Right.global_position.x = center_x + arrow_margin_from_center

	base_left_x = $Left.position.x
	base_right_x = $Right.position.x

func hide_arrows():
	for arrow in [$Right, $Left]:
		arrow.visible = false

func _on_focus_entered() -> void:
	show_arrows()

func _on_focus_exited() -> void:
	hide_arrows()

func _on_mouse_entered() -> void:
	grab_focus()

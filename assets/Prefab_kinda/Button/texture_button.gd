@tool
extends TextureButton

@export var text = "Text button"
@export var arrow_margin_from_center = 100

func _ready():
	setup_text()
	hide_arrows()

func _process(delta):
	if Engine.is_editor_hint():
		setup_text()
		show_arrows()
		
	#setup_text()
	#show_arrows()
func setup_text():
	$Text.bbcode_text = "[center] %s [/center]" % text
	
func show_arrows():
	for arrow in [$Right, $Left]:
		arrow.visible = true
		#arrow.global_position.y = get_global_rect().position.y + (get_global_rect().size.y / 3.0)

	var center_x = get_global_rect().position.x + (get_global_rect().size.x / 2)
	$Left.global_position.x = center_x - arrow_margin_from_center
	$Right.global_position.x = center_x + arrow_margin_from_center

func hide_arrows():
	for arrow in [$Right, $Left]:
		arrow.visible = false#left.position.x  = center_x - set_distance - left_half

func _on_focus_entered() -> void:
	show_arrows()

func _on_focus_exited() -> void:
	hide_arrows()

func _on_mouse_entered() -> void:
	grab_focus()

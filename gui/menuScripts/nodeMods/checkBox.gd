tool
extends CheckBox

export (NodePath) var enabled_block
export (NodePath) var visibility_block

func _pressed():
	if enabled_block and get_node(enabled_block):
		get_node(enabled_block).disabled = not(pressed)
	if visibility_block and get_node(visibility_block):
			get_node(visibility_block).visible = pressed

func _ready():
	_pressed()

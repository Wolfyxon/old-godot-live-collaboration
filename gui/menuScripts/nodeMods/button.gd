tool
extends Button

signal clicked #pressed but better

export (NodePath) var visibility_switch

export (bool) var use_child_as_visibility_switch = true

onready var vs_node
onready var signal_node

func _ready():
	
	if visibility_switch:
		vs_node = get_node(visibility_switch)
	
	if (not vs_node) and use_child_as_visibility_switch:
		var children = get_children()
		if children != []:
			vs_node = children[0]

func _pressed():
	emit_signal("clicked",self)
	if vs_node:
		if (vs_node is Control) or (vs_node is Node2D):
			if vs_node is Popup:
				vs_node.popup_centered()
			else:
				vs_node.visible = not(vs_node.visible)
	pass

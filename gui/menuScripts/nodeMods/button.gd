tool
extends Button

export (NodePath) var visibility_switch
export (bool) var use_child_as_visibility_switch = true

onready var node

func _ready():
	if visibility_switch:
		node = get_node(visibility_switch)
	
	if (not node) and use_child_as_visibility_switch:
		var children = get_children()
		if children != []:
			node = children[0]

func _pressed():
	if node:
		if (node is Control) or (node is Node2D):
			if node is Popup:
				node.popup_centered()
			else:
				node.visible = not(node.visible)
	pass

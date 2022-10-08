extends ColorRect

var utils = preload("../../utils.gd").new()

func _ready():
	add_child(utils)
	connect("visibility_changed",self,"_visibility_changed")
	_visibility_changed()
	
func _visibility_changed():
	if visible:
		for i in utils.get_descendants(get_parent(),[self]):
			if i is Control: i.focus_mode = FOCUS_NONE
	else:
		for i in utils.get_descendants(get_parent(),[self]):
			if i is Control: i.focus_mode = FOCUS_ALL
	pass

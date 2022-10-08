tool
extends EditorPlugin

var menu = preload("gui/menu.tscn").instance()
var menuName = "Live Collaboration"


######### main
func _enter_tree():
	add_child(menu)
	add_tool_menu_item(menuName,self,"openMenu")


func _exit_tree():
	remove_tool_menu_item(menuName)
	menu.free()
	
	
	
############

func openMenu(data):
	menu.popup_centered()

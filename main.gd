tool
extends EditorPlugin

var server = preload("networking/server.gd").new()
var client = preload("networking/client.gd").new()

var menu = preload("gui/menu.tscn").instance()
var menuName = "Live Collaboration"

func _enter_tree():
	self.name = "LiveCollaborationPlugin"
	add_child(server)
	add_child(client)
	
	add_child(menu)
	add_tool_menu_item(menuName,self,"openMenu")

	menu.connect("start_server",server,"start_server")
	menu.connect("connect_to_server",client,"connect_to_server")
	menu.connect("disconnect_from_server",client,"connect_to_server")
	
	server.connect("gui_alert",menu,"alert")
	client.connect("gui_alert",menu,"alert")


func _exit_tree():
	server.stop_server()
	remove_tool_menu_item(menuName)
	menu.free()
	
func openMenu(data):
	menu.popup_centered()






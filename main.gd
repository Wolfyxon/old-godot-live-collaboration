tool
extends EditorPlugin


var server = preload("networking/server.gd").new()
var client = preload("networking/client.gd").new()

var menu = preload("gui/menu.tscn").instance()
var menuName = "Live Collaboration"

func _enter_tree():
	add_child(menu)
	add_tool_menu_item(menuName,self,"openMenu")
	
	menu.connect("start_server",self,"start_server")


func _exit_tree():
	remove_tool_menu_item(menuName)
	menu.free()
	

func start_server(port:int,max_users:int,password:String="",manual_join_aproval=false):
	server.start_server(port,max_users,password,manual_join_aproval)
	
func stop_server():
	pass

func openMenu(data):
	menu.popup_centered()






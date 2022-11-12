tool
extends EditorPlugin

var server = preload("networking/server.gd").new()
var client = preload("networking/client.gd").new()
var utils = preload("utils.gd").new()
var editor_events = preload("editor_events.gd").new(get_editor_interface())

var menu = preload("gui/menu.tscn").instance()
var menuName = "Live Collaboration"

const version:float = 1.0

var nickname:String = "error"
var plugin_dir = self.get_script().get_path().get_base_dir()

var remove_with_self = []

func _enter_tree():
	self.name = "LiveCollaborationPlugin"
	add_child(server)
	add_child(client)
	add_child(editor_events)
	add_child(utils)
	add_child(menu)
	
	add_tool_menu_item(menuName,self,"openMenu")

	menu.connect("start_server",server,"start_server")
	menu.connect("connect_to_server",client,"connect_to_server")
	menu.connect("disconnect_from_server",client,"disconnect_from_server")
	
	server.connect("gui_alert",menu,"alert")
	client.connect("gui_alert",menu,"alert")
	#editor_events.connect("gui_alert",menu,"alert")

	#for i in utils.get_descendants(get_editor_interface().get_parent()):
		#print(i.get_script())


func _exit_tree():
	server.stop_server()
	remove_tool_menu_item(menuName)
	menu.free()
	
	for i in remove_with_self:
		if i and is_instance_valid(i): i.queue_free()
	
func openMenu(data):
	menu.popup_centered()






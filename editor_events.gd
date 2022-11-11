tool
extends Node
#https://docs.godotengine.org/en/stable/classes/class_editorinterface.html

signal property_changed
signal node_added
signal node_removed
signal gui_alert
signal script_edited

var utils = preload("utils.gd").new()
onready var tmr_check_properties = Timer.new()
onready var tmr_check_script = Timer.new()

onready var main:EditorPlugin = get_parent()
var editor_interface:EditorInterface
var script_text_editor: TextEdit

func _init(_editor_interface:EditorInterface):
	editor_interface = _editor_interface

func _ready():
	add_child(utils)
	add_child(tmr_check_properties)
	tmr_check_properties.wait_time = 0.05
	tmr_check_properties.one_shot = false
	tmr_check_properties.connect("timeout",self,"_property_check")
	tmr_check_properties.start()
	
	add_child(tmr_check_script)
	tmr_check_script.wait_time = 0.05
	tmr_check_script.one_shot = false
	tmr_check_script.connect("timeout",self,"_script_check")
	tmr_check_script.start()
	
	editor_interface.get_inspector().connect("property_edited",self,"_property_edited")
	editor_interface.get_inspector().connect("object_id_selected",self,"_node_selected")
	
	get_tree().connect("node_added",self,"_node_added")
	get_tree().connect("node_removed",self,"_node_removed")
	
	connect("property_changed",self,"_on_property_changed")
######################################################
	


func get_script_text_editor():
	var list = utils.get_descendants(editor_interface.get_script_editor())
	var containers = []
	for c in list:
		if c.get_class() == "CodeTextEditor":
			for ch in c.get_children():
				if (ch is TextEdit) and ch.is_visible_in_tree():
					return ch

func get_root():
	return get_editor_interface().get_node("/")

func get_3d_camera():
	var cam_index = 0
	var e = editor_interface.get_editor_viewport()
	var cam = e.get_child(1).get_child(1).get_child(0).get_child(0).get_child(cam_index).get_child(0).get_child(0).get_camera()
	return cam

func get_2d_mouse_position() -> Vector2:
	return editor_interface.get_viewport().get_mouse_position()

func get_edited_scene():
	return editor_interface.get_edited_scene_root()

func get_editor_interface():
	return editor_interface

func is_in_current_scene(node:Node):
	var scene =  editor_interface.get_edited_scene_root()
	if not scene: return
	var path = scene.get_path_to(node)
	if not String(node.get_path()).begins_with(String(scene.get_path())): return false
	if ".." in String(path): return false
	if not(scene.has_node(path)): return false
	
	return true

func _on_property_changed(node:Node,key:String,value,scene_path:String):
	rpc("set_property",node.get_path(),key,value,scene_path)

var cached_properties = {}
func _property_check():
	var t = Thread.new()
	t.start(self,"_property_check_")

func _property_check_(): #run this always with thread!
	var scene = editor_interface.get_edited_scene_root()
	var scene_path = scene.filename
	var nodes = utils.get_descendants(scene)
	for node in nodes:
		var properties = utils.get_properties(node)
		if node in cached_properties:
			var cached = cached_properties[node]
			for key in properties:
				var value = properties[key]
				var cached_value = cached_properties[node][key]
				if key in cached:
					if value != cached_value:
						emit_signal("property_changed",node,key,value,scene_path)
						cached_properties[node] = properties
					else:
						pass
				else:
					cached_properties[node][key] = value
					emit_signal("property_changed",node,key,value,scene_path)
					cached_properties[node] = properties
		else:
			cached_properties[node] = properties

var cached_scripts = {
	#path: code
}
var ignored_scripts = []

func _script_changed():
	print("change")
	emit_signal("script_edited",editor_interface.get_script_editor().get_current_script().resource_path)

func _script_check():
	script_text_editor = get_script_text_editor()
	if not script_text_editor: return
	
	var script = editor_interface.get_script_editor().get_current_script()
	#prints("path",script.resource_path)
	
	if utils.is_script_builtin(script): #TODO: support for local scripts
		var _name = "gdlc_script_warn"
		if script_text_editor.has_node(_name): return
		var lbl = Label.new()
		lbl.owner = self
		lbl.name = _name
		lbl.text = "WARNING: This script is built-in to scene and it will NOT be replicated to other collaborators. Feature comming soon"
		lbl.modulate = Color.yellow
		script_text_editor.add_child(lbl)
		return
		
	if not script_text_editor.is_connected("text_changed",self,"_script_changed"):
		script_text_editor.connect("text_changed",self,"_script_changed")
	
#	var editor = editor_interface.get_script_editor()
#	if not editor: return
#	var script = editor.get_current_script()
#	if not script: return
#	if script in ignored_scripts: return
#	if script.resource_local_to_scene:
#		ignored_scripts.append(script)
#		emit_signal("gui_alert","This script is local to scene and will NOT be replicated to other collaborators.")
#		return
#
#	var src = script.source_code
#	var path = script.resource_path
#	if path == "": return
#
#	if not(path in cached_scripts): 
#		cached_scripts[path] = src
#		return
#	if cached_scripts[path] != src:
#		emit_signal("script_edited",path,src)
#		cached_scripts[path] = src


func _node_added(node:Node):
	if not is_in_current_scene(node): return
	emit_signal("node_added",node,utils.get_properties(node))
	
	if get_tree().network_peer:
		if not main.server.server_running: rpc_id(1,"create_node",node)
		rpc("create_node",node)
	
func _node_removed(node:Node):
	if not is_in_current_scene(node): return
	emit_signal("node_removed",node)

################################################################################
# NETWORK ZONE

remotesync func set_property(path:NodePath,property:String,value,scene_path:String="",requireReload:bool=false):
	var id = get_tree().get_rpc_sender_id()
	if scene_path != "":
		if get_editor_interface().get_edited_scene_root().filename != scene_path: 
			#TODO: Download updated scene from peer who edited it
			return
	
	var node = get_node(path)
	if node:
		node.set(property,value)

remotesync func create_node(node_class:String,parent_path:NodePath,scene:String,properties:Dictionary={},name:String=""):
	if not ClassDB.is_class(node_class): 
		printerr("Invalid class: ",node_class)
		return
	if editor_interface.get_edited_scene_root().filename != scene: return
	if not get_node(parent_path): return
	
	var node = ClassDB.instance(node_class)
	


remotesync func delete_node(path:NodePath,scene:String):
	var node = get_node(path)

########### markers
var marker_group_name = "LiveCollaboration_client_marker"
var cursor_marker:Node2D #self
var camera_marker:Spatial #self

var prev_cursor_pos = Vector2()
var prev_camera_pos = Vector3()
var prev_camera_rot = Vector3()
func _input(event):
	if not main: return
	if not get_tree(): return
	if not editor_interface.get_edited_scene_root(): return
	if not(main.server.server_running or main.client.connected): return
	
	if not(is_instance_valid(cursor_marker)): return
	if not(is_instance_valid(camera_marker)): return
	
	camera_marker.translation = get_3d_camera().translation
	camera_marker.rotation = get_3d_camera().rotation
	
	if event is InputEventMouse:
		#Mouse position looks different on other screens
		#TODO: fix
		cursor_marker.global_position = get_editor_interface().get_base_control().get_global_mouse_position()
	
	if (prev_camera_pos != camera_marker.translation) or (prev_camera_rot != camera_marker.rotation):
		rpc("move_camera_marker",camera_marker.translation,camera_marker.rotation)
		if not main.server.server_running: rpc_id(1,"move_camera_marker",camera_marker.translation,camera_marker.rotation)
	if prev_cursor_pos != cursor_marker.position:
		rpc("move_cursor_marker",cursor_marker.global_position)
		if not main.server.server_running: rpc_id(1,"move_cursor_marker",cursor_marker.global_position)
	
remote func remove_all_markers():
	if not get_tree(): return
	for i in get_tree().get_nodes_in_group(marker_group_name):
		i.queue_free()

remote func create_markers(nickname:String,color:Color,id:int):
	var camera = preload("client_scenes/client3D.tscn").instance()
	var cursor = preload("client_scenes/client2D.tscn").instance()
	
	add_child(camera)
	add_child(cursor)
	cursor.name = "cursor_"+String(id)
	camera.name = "camera_"+String(id)
	
	camera.add_to_group(marker_group_name); cursor.add_to_group(marker_group_name)
	if id == get_tree().network_peer.get_unique_id():
		cursor_marker = cursor
		camera_marker = camera
		
		cursor.visible = false
		camera.visible = false

	camera.id = id; cursor.id = id
	camera.set_nickname(nickname); cursor.set_nickname(nickname)
	camera.set_color(color); cursor.set_color(color)
	
func get_camera_marker(id:int):
	for i in get_tree().get_nodes_in_group(marker_group_name):
		if i is Spatial:
			if i.id == id: return i
			
func get_cursor_marker(id:int):
	for i in get_tree().get_nodes_in_group(marker_group_name):
		if i is Node2D:
			if i.id == id: return i

remote func remove_markers(id:int):
	var cursor = get_cursor_marker(id)
	var camera = get_camera_marker(id)
	
	if cursor: cursor.queue_free()
	if camera: camera.queue_free()

remote func move_camera_marker(pos:Vector3,rot:Vector3):
	var id = get_tree().get_rpc_sender_id()
	var m = get_camera_marker(id)
	if not m: return
	
	rpc_id(1,"set_property",m.get_path(),"translation",pos)
	rpc("set_property",m.get_path(),"translation",pos)
	
	if not main.server.server_running: rpc_id(1,"set_property",m.get_path(),"rotation",rot)
	rpc("set_property",m.get_path(),"rotation",rot)

remote func move_cursor_marker(pos:Vector2):
	var id = get_tree().get_rpc_sender_id()
	var m = get_cursor_marker(id)
	if not m: return
		
	if not main.server.server_running: rpc_id(1,"set_property",m.get_path(),"global_position",pos)
	rpc("set_property",m.get_path(),"global_position",pos)

####################### nodes

func _property_edited(property:String):
	var nodes = editor_interface.get_selection().get_selected_nodes()



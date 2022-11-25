tool
extends Node
#DO NOT MODIFY THIS SCRIPT WHILE THE PLUGIN IS RUNNING

signal node_added
signal node_removed
signal gui_alert
signal script_edited
signal property_changed
signal property_list_changed
signal properties_scanned

var utils = preload("utils.gd").new()
onready var tmr_check_properties = Timer.new()
onready var tmr_check_script = Timer.new()

onready var main:EditorPlugin = get_parent()
var editor_interface:EditorInterface
var script_text_editor: TextEdit

var ignore_group = "gdlc_ignore" #don't touch

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
	connect("property_list_changed",self,"_on_property_list_changed")
######################################################
	#gui_highlight()
	#clear_tooltips()
	var tmp = editor_interface.get_script_editor().get_node("../../..").get_children()[0]
	var btn = ToolButton.new()
	main.remove_with_self.append(btn)
	btn.disabled = true
	btn.text = "Commit script changes"
	btn.icon = load("res://addons/GdLiveCollaboration/textures/icons/green_check.png")
	btn.hint_tooltip = "This is NOT availble yet, I need to create a system that will merge scripts to avoid overwriting someone's work.\nMark code as finished and send it to server"
	tmp.add_child(btn)
	tmp.move_child(btn,tmp.get_children().find(btn)-1)
	
	#tmp.add_child(btn)


onready var tooltip_target = editor_interface.get_script_editor()
func gui_highlight(): #used for finding certrain editor gui parts 
	var nodes = utils.get_descendants(tooltip_target)
	for i in nodes:
		if i is Control:
			i.hint_tooltip = i.name+" "+i.get_class()+"\n"+tooltip_target.get_path_to(i)

func clear_tooltips():
	var nodes = utils.get_descendants(tooltip_target)
	for i in nodes:
		if i is Control:
			i.hint_tooltip = ""
			

func rpc_all(method:String,args:Array):
	callv("rpc",[method]+args)
	if not main.server.server_running: callv("rpc_id",[1,method]+args)

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
	var tmp = e.get_child(1).get_child(1).get_child(0).get_child(0).get_child(cam_index).get_child(0).get_child(0)
	if tmp.has_method("get_camera"): return tmp.get_camera()


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

func _on_property_list_changed(node:Node,properties:Dictionary,previous:={}):
	if not(main.server.server_running or main.client.connected): return
	var path = node.get_path()
	for i in properties:
		var value = node.get(i)
		if value and not(value is Object): #TODO: encoding and decoding objects from dicts
			rpc_all("set_property",[ path,i,properties[i],editor_interface.get_edited_scene_root().filename ])

func _on_property_changed(node:Node,key:String,value,scene_path:String):
	if not(main.server.server_running or main.client.connected): return
	var path = node.get_path()
	if not(scene_path in blocked_properties): blocked_properties[scene_path] = {}
	if not(path in blocked_properties[scene_path]): blocked_properties[scene_path][path] = []
	
	if key in blocked_properties[scene_path][path]: 
		return
	rpc("set_property",path,key,value,scene_path)

var cached_properties = {}
var scanning_properties = false
func _property_check():
	if not(main.server.server_running or main.client.connected): return
	_property_check_()
	#if scanning_properties: return
	#var t = Thread.new()
	#t.start(self,"_property_check_")

func _property_check_(): #run this always with thread!
	scanning_properties = true
	var scene = editor_interface.get_edited_scene_root()
	if not scene: return
	if not OS.is_window_focused(): return
	var scene_path = scene.filename
	var nodes = editor_interface.get_selection().get_selected_nodes() #utils.get_descendants(scene)
	
	for node in nodes:
		if is_instance_valid(node) and not(node.is_queued_for_deletion()) and not(node.is_in_group(ignore_group)):
			if not(scene_path in blocked_properties): blocked_properties[scene_path] = {}
			if not(node.get_path() in blocked_properties[scene_path]): blocked_properties[scene_path][node.get_path()] = []
			var properties = utils.get_properties(node)
			if node in cached_properties:
				var cached = cached_properties[node]
				if not(utils.compare_dicts(cached,properties)):
					cached_properties[node] = properties
					var ok = true
					for key in properties:
						if key in blocked_properties[scene_path][node.get_path()]:
							ok = false
							blocked_properties[scene_path].erase(node.get_path())
							#break
					if ok:
						emit_signal("property_list_changed",node,properties,cached)
				
				#WARNING: for some reason when 2 properties are changed at the same time, only one will be detected
	#			for key in properties:
	#				var value = properties[key]
	#				var cached_value = cached_properties[node][key]
	#				if key in cached:
	#					if value != cached_value:
	#						emit_signal("property_changed",node,key,value,scene_path)
	#						cached_properties[node] = properties
	#				else:
	#					cached_properties[node][key] = value
	#					emit_signal("property_changed",node,key,value,scene_path)
	#					cached_properties[node] = properties
			else:
				cached_properties[node] = properties
	scanning_properties = false
	emit_signal("properties_scanned")

var cached_scripts = {
	#path: code
}
var ignored_scripts = []

func _script_changed():
	emit_signal("script_edited",editor_interface.get_script_editor().get_current_script().resource_path,editor_interface.get_script_editor().get_current_script().source_code)

func _script_check():
	script_text_editor = get_script_text_editor()
	if not script_text_editor: return
	
	var script = editor_interface.get_script_editor().get_current_script()
	#prints("path",script.resource_path)
	
	if utils.is_script_builtin(script): #TODO: support for local scripts
		var tmp = script_text_editor.get_parent().get_parent().get_parent()
		var _name = "gdlc_script_warn"
		if tmp.has_node(_name): 
			return
		script_text_editor.rect_clip_content = false
		var lbl = Label.new()
		lbl.name = _name
		lbl.text = "WARNING: This script is built-in to scene and it will NOT be replicated to other collaborators. Feature comming soon"
		lbl.add_color_override("font_color",Color.yellow)
		main.remove_with_self.append(lbl)
		tmp.add_child(lbl)
		
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
		#if not main.server.server_running: rpc_id(1,"create_node",node)
		rpc_all("create_node",[node])
	
func _node_removed(node:Node):
	if not is_in_current_scene(node): return
	emit_signal("node_removed",node)

################################################################################
# NETWORK ZONE

var blocked_properties = {
	#scene_path: {node_path: [properties]}
}
remotesync func set_property(path:NodePath,property:String,value,scene_path:="",requireReload:=false,force:=false): 
	if not(scene_path in blocked_properties): blocked_properties[scene_path] = {}
	if not(path in blocked_properties[scene_path]): blocked_properties[scene_path][path] = []
	#if property in blocked_properties[scene_path][path]: return 
	var id = get_tree().get_rpc_sender_id()
	if (not force) and (id == get_tree().get_network_unique_id()): return #DO NOT USE FORCE, it's reserved for the plugin
	if scene_path != "":
		if get_editor_interface().get_edited_scene_root().filename != scene_path: 
			#TODO: Download updated scene from peer who edited it
			return
	
	var node = get_node_or_null(path)
	if node:
		#blocked_properties[scene_path][path].append(property)
		if not(node in cached_properties): 
			cached_properties[node] = utils.get_properties(node)
		node.set(property,value)
		node.set_meta("gdlc_last_modified",[id,OS.get_unix_time()])
		cached_properties[node][property] = value

remotesync func create_node(node_class:String,parent_path:NodePath,scene:String,properties:Dictionary={},name:String=""):
	if not ClassDB.is_class(node_class): 
		printerr("Invalid class: ",node_class)
		return
	if editor_interface.get_edited_scene_root().filename != scene: return
	if not get_node_or_null(parent_path): return
	
	var node = ClassDB.instance(node_class)

remotesync func delete_node(path:NodePath,scene:String):
	var node = get_node_or_null(path)

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
	
	#########
	if not(is_instance_valid(cursor_marker)): return
	if not(is_instance_valid(camera_marker)): return
	
	var cam = get_3d_camera() 
	if cam:
		camera_marker.translation = cam.translation
		camera_marker.rotation = cam.rotation
	
	if event is InputEventMouse:
		#Mouse position looks different on other screens
		#TODO: fix
		cursor_marker.global_position = get_editor_interface().get_base_control().get_global_mouse_position()
	
	if (prev_camera_pos != camera_marker.translation) or (prev_camera_rot != camera_marker.rotation):
		rpc_all("move_camera_marker",[camera_marker.translation,camera_marker.rotation])
		#if not main.server.server_running: rpc_id(1,"move_camera_marker",camera_marker.translation,camera_marker.rotation)
	if prev_cursor_pos != cursor_marker.position:
		rpc_all("move_cursor_marker",[cursor_marker.global_position])
		#if not main.server.server_running: rpc_id(1,"move_cursor_marker",cursor_marker.global_position)
	
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
	
	#rpc_id(1,"set_property",m.get_path(),"translation",pos)
	rpc_all("set_property",[m.get_path(),"translation",pos,"",false,true])
	
	#if not main.server.server_running: rpc_id(1,"set_property",m.get_path(),"rotation",rot)
	rpc_all("set_property",[m.get_path(),"rotation",rot,"",false,true])

remote func move_cursor_marker(pos:Vector2):
	var id = get_tree().get_rpc_sender_id()
	var m = get_cursor_marker(id)
	if not m: return
		
	#if not main.server.server_running: rpc_id(1,"set_property",m.get_path(),"global_position",pos)
	rpc_all("set_property",[m.get_path(),"global_position",pos,"",false,true])

####################### nodes

func _property_edited(property:String):
	var nodes = editor_interface.get_selection().get_selected_nodes()



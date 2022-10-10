tool
extends Node

signal property_changed
signal node_added
signal node_removed

var utils = preload("utils.gd").new()
onready var tmr_check_properties = Timer.new()

#https://docs.godotengine.org/en/stable/classes/class_editorinterface.html

onready var main:EditorPlugin = get_parent()
var editor_interface:EditorInterface

func _init(_editor_interface:EditorInterface):
	editor_interface = _editor_interface

func _ready():
	add_child(utils)
	add_child(tmr_check_properties)
	tmr_check_properties.wait_time = 0.1
	tmr_check_properties.one_shot = false
	tmr_check_properties.connect("timeout",self,"_property_check")
	tmr_check_properties.start()
	
	editor_interface.get_inspector().connect("property_edited",self,"_property_edited")
	editor_interface.get_inspector().connect("object_id_selected",self,"_node_selected")
	
	get_tree().connect("node_added",self,"_node_added")
	get_tree().connect("node_removed",self,"_node_removed")
	


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

func _node_added(node:Node):
	emit_signal("node_added",node)
	
func _node_removed(node:Node):
	emit_signal("node_removed",node)
	
var cached_properties = {}
func _property_check():
	#if not Engine.editor_hint: return
	var nodes = utils.get_descendants(editor_interface.get_edited_scene_root())
	for node in nodes:
		var properties = utils.get_properties(node)
		if node in cached_properties:
			var cached = cached_properties[node]
			for key in properties:
				var value = properties[key]
				var cached_value = cached_properties[node][key]
				if key in cached:
					if value != cached_value:
						emit_signal("property_changed",node,key,value)
						cached_properties[node] = properties
					else:
						pass
				else:
					cached_properties[node][key] = value
					emit_signal("property_changed",node,key,value)
					cached_properties[node] = properties
		else:
			cached_properties[node] = properties


################################################################################
# NETWORK ZONE

remotesync func set_property(path:NodePath,property:String,value):
	var node = get_node(path)
	if node:
		node.set(property,value)



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
		
		cursor.visible = true
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




tool
extends Node

var utils = preload("utils.gd").new()

#https://docs.godotengine.org/en/stable/classes/class_editorinterface.html

var main = get_parent()
var editor_interface:EditorInterface

func _init(_editor_interface:EditorInterface):
	editor_interface = _editor_interface

func _ready():
	add_child(utils)

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

###################################

func get_camera_marker():
	pass
	
func get_mouse_marker():
	pass

remote func create_markers(nickname:String,color:Color,id:int):
	pass









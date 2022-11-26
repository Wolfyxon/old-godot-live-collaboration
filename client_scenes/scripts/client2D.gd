tool
extends Node2D

var id = -1

var editor_interface:EditorInterface
var scene_path = "" #in which scenes the cursor should be visible
var is_self = false

func _process(delta):
	#TODO: make cursors show only in the same scene
	#(it doesnt work)
	#prints($nick.text,scene_path,editor_interface.get_edited_scene_root().filename)
	var tmp = true
	if editor_interface:
		tmp = (editor_interface.get_edited_scene_root().filename == scene_path)
	visible = not(is_self) and tmp


func set_nickname(nick:String):
	$nick.text = nick

func set_color(color:Color):
	modulate = color

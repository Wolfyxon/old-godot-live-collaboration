tool
extends Node

var PERMISSION_SERVER_MANAGEMENT = 0
var PERMISSION_EDIT_SCENES = 1
var PERMISSION_EDIT_SCRIPTS = 2
var PEMISSION_EDIT_ALL_FILES = 3
var PERMISSION_PROJECT_SETTINGS = 4

var LEVEL_HOST = 2
var LEVEL_ADMIN = 1
var LEVEL_EDITOR = 0

var permission_names = {
	LEVEL_HOST: "host",
	LEVEL_ADMIN: "admin",
	LEVEL_EDITOR: "editor"
}
var permissions = {
	LEVEL_HOST:[0,1,2,3],
	LEVEL_ADMIN:[1,2,3,4],
	LEVEL_EDITOR:[1,2,3],
}

var project_path = ProjectSettings.globalize_path("res://")
var rng = RandomNumberGenerator.new()

var supported


func random(from:float,to:float,to_int:bool=true):
	rng.randomize()
	var r = rng.randf_range(from,to)
	if to_int: r = int(r)
	return r

func has_permission(level,permission) -> bool:
	if not level in permissions:
		printerr(level," is not a valid permission level")
		return false
	
	if permission in permissions[level]: return true
	return false

func create_dirs(dirs:PoolStringArray,debug:=false): #used to automatically create dirs from scan_dirs
	var d = Directory.new()
	for path in dirs:
		if not(d.dir_exists(path)) and not(d.file_exists(path)):
			if debug:
				print("Created directory: ",path)
			d.make_dir_recursive(path)

func scan_dirs(path:String) -> Array:
	var dirs = []
	var dir = Directory.new()
	if dir.open(path) != OK: return []

	if dir.list_dir_begin(true, true) != OK: return []
	
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var d = dir.get_current_dir()
			if not(d in dirs): 
				dirs.append(d)
			for i in scan_dirs(d + "/" + file_name):
				if not(i in dirs): 
					dirs.append(i)
				
		file_name = dir.get_next()
	return dirs

func scan_files(path : String) -> Array:
	var files : Array = []
	var dir := Directory.new()
	if dir.open(path) != OK: return []

	if dir.list_dir_begin(true, true) != OK: return []

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			files += scan_files(dir.get_current_dir() + "/" + file_name)
		else:
			files.append(dir.get_current_dir() + "/" + file_name)

		file_name = dir.get_next()

	return files

func file_exists(path:String):
	return Directory.new().file_exists(path)

func dir_exists(path:String):
	return Directory.new().dir_exists(path)

func compare_dicts(a:Dictionary,b:Dictionary): # {"e":"e"} != {"e":"e"} for some reason
	for key in a:
		if not(key in b): return false
	for key in b:
		if not(key in a): return false
	
	for key in a:
		if a[key] is Dictionary:
			if not( compare_dicts(a[key],b[key]) ): 
				return false
		else:
			if a[key] != b[key]: 
				return false
	return true

func get_node_from_array(array:Array,name:String) -> Object:
	for i in array:
		if i.name == name: return i
		
	return null

func get_properties(object:Object) -> Dictionary:
	var r = {}
	var list = object.get_property_list()
	for data in list:
		var name = data["name"]
		r[name] = object.get(name)
		
	return r

func get_descendants(node:Node,ignoredNodes:Array=[],allowed_classes=[]) -> Array:
	if not is_inside_tree():
		printerr("Utils not in scene tree! Use add_child")
		return []
	
	var _name = "descendants_"+node.name+String(rand_range(0,100))
	node.propagate_call("add_to_group",[_name])
	var r = get_tree().get_nodes_in_group(_name)
	
	if allowed_classes != []:
		for i in r:
			var check = allowed_classes.size()
			for c in allowed_classes:
				if not(i is c):
					check -= 1
			if check == 0: r.erase(i)

	for i in ignoredNodes:
		if i in r: r.remove(r.find(i))
	
	node.propagate_call("remove_from_group",[_name])
	return r

func is_script_builtin(script:GDScript):
	return ("::" in script.resource_path)

func is_file_in_project(path:String) -> bool: #prevents accessing files outside project
	if ".." in path:
		path = ProjectSettings.localize_path(path)

	var globalized = ProjectSettings.globalize_path(path)
	if not(globalized.begins_with(project_path)):
		return false
	
	return true

func is_valid_url(url:String):
	pass
	if (" " in url): return false
	if not("." in url): return false
	
	return true

func get_resources_of_scene(scene_path:String) -> PoolStringArray:
	return ResourceLoader.get_dependencies(scene_path)

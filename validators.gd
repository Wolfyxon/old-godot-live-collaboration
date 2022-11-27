extends Node
tool
#Script for validating files and resources
var utils = preload("utils.gd").new()

var project_path = ProjectSettings.globalize_path("res://")
var data_path = ProjectSettings.globalize_path("user://")

var invalid_in_project_paths = [".import",".git"] #feel free to modify but be careful and better don't remove .import and .git because these are very heavy caches

func validate_path(path:String):
	if ".." in path: return false #.. can be used to access and modify files outside project
	if "~" in path: return false
	var globalized_path = ProjectSettings.globalize_path(path)
	var localized_path = ProjectSettings.localize_path(path)
	if not globalized_path.begins_with(project_path): return false
	for i in invalid_in_project_paths:
		if localized_path.begins_with("res://"+i): 
			return false 
	return true

func validate_resource(path:String):
	if not validate_path(path): return false
	var loader = ResourceLoader
	if not loader.exists(path): return false #this also check if the resource is recognized by the loader
	
	return true
	

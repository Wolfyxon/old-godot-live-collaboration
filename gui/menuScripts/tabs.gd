tool
extends TabContainer

var utils = preload("../../utils.gd").new()

onready var tab_joinOrHost = get_node("Join or host")
onready var tab_server = $server
onready var tab_client = $client
onready var tab_info = $info

var ready = false

func _ready():
	add_child(utils)
	tab_server.get_node("cover").visible = true
	tab_client.get_node("cover").visible = true


func _physics_process(delta):
	pass



func get_tab_idx(tab: Tabs):
	return get_children().find(tab)




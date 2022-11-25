tool
extends TabContainer

var utils = preload("../../utils.gd").new()

onready var tab_joinOrHost = get_node("Join or host")
onready var tab_server = $server
onready var tab_client = $client
onready var tab_info = $info

onready var join_request_list = $server/popup_join_requests/scroll/join_requests

func _ready():
	pass

func get_tab_idx(tab: Tabs):
	return get_children().find(tab)

func _on_join_requests_requests_changed():
	if not get_tree(): return
	yield(get_tree(),"idle_frame")
	var count = join_request_list.get_list_items().size()
	tab_server.get_node("vbox/btn_requests").text = "Show join requests ("+String(count)+")"



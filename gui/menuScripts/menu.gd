tool
extends AcceptDialog

signal connect_to_server
signal disconnect_from_server
signal client_action

signal start_server
signal stop_server
signal update_server #(settings)
signal server_action

onready var start_menu = $tabs.tab_joinOrHost.get_node("scroll").get_node("vbox").get_node("start")
onready var join_menu = start_menu.get_node("join")
onready var host_menu = start_menu.get_node("host")

func _ready():
	pass

func _on_btn_join_pressed():
	pass # Replace with function body.

func _on_btn_start_pressed():
	yield(get_tree(),"idle_frame")
	emit_signal("start_server",
		host_menu.get_node("input_port").value,
		host_menu.get_node("input_max_users").value,
		host_menu.get_node("input_password").text,
		host_menu.get_node("ch_aproval").pressed
	)






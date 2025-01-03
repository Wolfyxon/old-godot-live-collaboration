tool
extends AcceptDialog

signal connect_to_server
signal disconnect_from_server

signal start_server
signal stop_server
signal update_server #(settings)
signal server_action

onready var start_menu = $tabs.tab_joinOrHost.get_node("scroll").get_node("vbox").get_node("start")
onready var join_menu = start_menu.get_node("join")
onready var host_menu = start_menu.get_node("host")

onready var main = get_parent()
onready var nickname_input = $tabs.tab_joinOrHost.get_node("scroll/vbox/nick/nick_input")

onready var progress_bar_dialog:PopupDialog = $Node/progress_bar_dialog

func _ready():
	if not Engine.editor_hint:
		$Node/editor_warning.visible = true
	
	if not main: return
	if main.name != "LiveCollaborationPlugin": 
		main = null
		return
	
	_on_nick_input_text_changed(nickname_input.text)
	main.client.connect("disconnected",self,"_disconnected")
	$tabs.tab_server.get_node("vbox/serverOptions/btn_stop_server").connect("pressed",main.server,"stop_server")
	
func _process(delta):
	if Input.is_key_pressed(KEY_F9): popup()
	if not is_inside_tree(): return
	if not main: return
	$Node/cover.visible = $Node/alert.visible or $Node/progress_dialog.visible
	$tabs.tab_joinOrHost.get_node("cover").visible = (main.server.server_running or main.client.connected)
	$tabs/client/cover.visible = not(main.client.connected)
	$tabs/server/cover.visible = not(main.server.server_running)
	

	
func alert(text:String,title:String=""):
	#if not main: return
	while $Node/alert.visible: yield(get_tree(),"idle_frame")
	$Node/alert.dialog_text = text
	$Node/alert.window_title = title
	$Node/alert.popup_centered()

func _disconnected():
	$Node/progress_dialog.hide()

func nick_check(nick:String,show_alert:bool=true):
	var title = "Invalid username"
	if nick == "":
		if show_alert: alert("Don't make your username empty.",title)
		return false
	
	return true

func _on_btn_join_pressed():
	if not nick_check(nickname_input.text): return
	yield(get_tree(),"idle_frame")
	var inputs = $tabs.tab_joinOrHost.get_node("scroll/vbox/start/join/connection")
	var ip_input = inputs.get_node("input_ip")
	var port_input = inputs.get_node("input_port")
	
	#it doesn't let connect to URLs
#	if not(ip_input.text.is_valid_ip_address()):
#		alert("Please enter a valid IP adress","Invalid IP")
#		return
	
	$tabs.current_tab = $tabs.get_tab_idx($tabs.tab_client)
	emit_signal("connect_to_server",
		ip_input.text,
		port_input.value,
		start_menu.get_node("join/input_password").text
	)
	if not main: return
	$Node/progress_dialog.wait_popup(main.client,"server_responded","Waiting for server's response...")


func _on_btn_start_pressed():
	if not nick_check(nickname_input.text): return
	$tabs.current_tab = $tabs.get_tab_idx($tabs.tab_server)
	yield(get_tree(),"idle_frame")
	emit_signal("start_server",
		host_menu.get_node("input_port").value,
		host_menu.get_node("input_max_users").value,
		host_menu.get_node("input_password").text,
		host_menu.get_node("ch_aproval").pressed
	)

func _on_nick_input_text_changed(new_text):
	var error = $tabs.tab_joinOrHost.get_node("scroll/vbox/nick/error")
	if new_text == "":
		error.text = "Username cannot be empty"
		return
	error.text = ""
	if not main: return
	
	main.nickname = new_text
	main.server.host_nickname = new_text
	main.client.nickname = new_text

func _on_btn_disconnect_pressed():
	emit_signal("disconnect_from_server")

func _server_user_auth(data:Dictionary):
	$tabs/server/vbox/people/columns.add_row(data["id"],data["nickname"],data["ip"],0)

func _on_columns_kick(id:int):
	if not main: return
	if not main.server: return
	main.server.kick(id,"Kicked by host.")



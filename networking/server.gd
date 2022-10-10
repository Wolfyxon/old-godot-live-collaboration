tool
extends Node

signal gui_alert

signal server_started
signal server_stopped
signal server_start_failed

signal user_connected
signal user_disconnected

onready var network = NetworkedMultiplayerENet.new()

var host_nickname = "host" setget _nickname_changed
var server_password = ""
var connected_ids = []
var connected = []

onready var main = get_parent()
onready var client = main.client
onready var menu = main.menu

var host_color:Color = Color.darkred

var colors = [
	Color.red, 
	Color.green, 
	Color.blue,
	Color.white, 
	Color.aqua,
	Color.yellow,
	Color.orangered,
	Color.purple,
	Color.magenta
]
var color_alpha = 0.5

func _ready():
	network.connect("peer_connected",self,"_user_connected")
	network.connect("peer_disconnected",self,"_user_disconnected")
	name = "server"
	
	
	for i in colors:
		colors[i].a = color_alpha

func add_host_to_list():
	var data = {"id":0,"nickname":host_nickname,"ip":"127.0.0.1"}
	connected.append(data)

var server_running = false
func start_server(port:int,max_users:int,password:String="",manual_join_aproval=false):
	connected = []
	if server_running:
		printerr("Server already running.")
		return
	var err = network.create_server(port,max_users)
	if err == OK:
		add_host_to_list()
		server_password = password
		get_tree().network_peer = network
		print("Server started at port: ",port)
		print("Max users: ",max_users)
		print("Password: ",password)
		print("Manual join aproval: ",manual_join_aproval)
		server_running = true
		main.editor_events.create_markers(host_nickname,host_color,1)
	else:
		emit_signal("server_start_failed",err)
		emit_signal("gui_alert","Something might be already using this port, try changing it.\nError code: "+String(err),"Server start failed")

func stop_server():
	if not network: return
	if not server_running: return
	print("Server stopped")
	for i in connected_ids:
		kick(i,"Server stopped by host.")
	if get_tree():
		yield(get_tree(),"idle_frame")
	network.close_connection()
	server_running = false
	connected = []
	main.editor_events.remove_all_markers()
	emit_signal("server_stopped")

func get_connected_ids(include_host:bool=false):
	var r = connected
	if include_host: r.append(1)
	print(connected)
	return r

func get_user_by_id(id:int):
	for i in connected:
		if i["id"] == id:
			return i
	return

func get_user_by_nickname(nickname:String):
	for i in connected:
		if i["nickname"] == nickname:
			return i
	return

func random_color():
	return colors[main.utils.random(0,colors.size()-1)]

func kick(id:int,reason:String=""):
	if reason != "": 
		rpc_id(id,"server_message",reason,"You have been kicked")
		if get_tree(): yield(get_tree(),"idle_frame")
	network.disconnect_peer(id,true)
	print("Kicked: ",id," Reason: ",reason)

func _nickname_changed(new_value): #WARNING: this fires if HOST nickname changes, not one of the clients'!
	#connected[0]["nickname"] = new_value #this is broken lmao, ill fix it later
	pass

remote func auth_client(nickname:String,password:String=""):
	var id = get_tree().get_rpc_sender_id()
	print("Authenticating user: ",id," with nickname: ",nickname)
	var message_title = "Server rejected connection"
	var error = null
	if get_user_by_id(id):
		error = "Someone is already logged on that ID."
	if get_user_by_nickname(nickname):
		error = "Someone is already using this nickname."
	if server_password != "":
		if password != server_password:
			error = "Invalid password"
	if not(error):
		var data = {
			"id":id,
			"ip":network.get_peer_address(id),
			"nickname":nickname
		}
		connected.append(data)
		print(connected)
		print("User authenticated: ",data)
		var color = random_color()
		client.rpc_id(id, "server_response",main.version,host_nickname,color,id)
		for i in connected_ids:
			main.editor_events.rpc_id(i,"remove_all_markers")
			main.editor_events.rpc_id(i,"create_markers", nickname,color,i)
			main.editor_events.rpc_id(i,"create_markers", host_nickname,host_color,1)
			main.editor_events.create_markers(nickname,color,i)
	else:
		yield(get_tree(),"idle_frame")
		kick(id,error)

master func download_from_server(path):
	var id = get_tree().get_rpc_sender_id()
	rpc_id(id,"store_file",path)
	

remote func server_message(message:String,title:String="Server message"):
	main.menu.alert(message,title)

func _user_connected(id):
	connected_ids.append(id)
	print(network.get_peer_address(id)," connected with ID: ",id)
	yield(get_tree().create_timer(3),"timeout")
	if not(get_user_by_id(id)) and (id in connected_ids):
		print(network.get_peer_address(id)," kicked because of no authentication")
		kick(id,"Auth timed out.")
	
func _user_disconnected(id):
	connected_ids.erase(id)
	var data = get_user_by_id(id)
	print("user: ",id," ",data," disconnected")
	for i in connected_ids:
		rpc_id(i,"remove_markers",id)
	main.editor_events.remove_markers(id)
	if data and data in connected:
		connected.erase(data)
	

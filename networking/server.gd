tool
extends Node

signal gui_alert

signal server_started
signal server_stopped
signal server_start_failed

signal user_connected
signal user_disconnected

onready var network = NetworkedMultiplayerENet.new()

var host_nickname = ""
var server_password = ""
#var pending_connection = []
var connected_ids = []
var connected = []

onready var main = get_parent()
onready var client = main.client
onready var menu = main.menu

var colors = [
	Color(1,0,0), #red
	Color(0,1,0), #green
	Color(0,0,1), #blue,
	Color(1,1,1), #white
	Color("#00F7FF"), #aqua
	Color("#FFD600"), #yellow
	Color("#FF6700"), #orange
	Color("#C208FF"), #purple
	Color("#FF009A") #pink
]

func _ready():
	network.connect("peer_connected",self,"_user_connected")
	network.connect("peer_disconnected",self,"_user_disconnected")
	name = "server"

var server_running = false
func start_server(port:int,max_users:int,password:String="",manual_join_aproval=false):
	if server_running:
		printerr("Cannot start server. Already running.")
		return
	var err = network.create_server(port,max_users)
	if err == OK:
		server_password = password
		get_tree().network_peer = network
		print("Server started at port: ",port)
		print("Max users: ",max_users)
		print("Password: ",password)
		print("Manual join aproval: ",manual_join_aproval)
		server_running = true
	else:
		emit_signal("server_start_failed",err)
		emit_signal("gui_alert","Something might be already using this port, try changing it.\nError code: "+String(err),"Server start failed")

func stop_server():
	if not network: return
	if not server_running: return
	print("Server stopped")
	for i in connected_ids:
		kick(i,"Server stopped by host.")
	yield(get_tree(),"idle_frame")
	network.close_connection()
	server_running = false
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
		yield(get_tree(),"idle_frame")
	network.disconnect_peer(id,true)
	print("Kicked: ",id," Reason: ",reason)

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
		client.rpc_id(id, "server_response",main.version,host_nickname,random_color(),id)
	else:
		yield(get_tree(),"idle_frame")
		kick(id,error)


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
	if data and data in connected:
		connected.erase(data)
	

tool
extends Node

signal gui_alert

signal server_started
signal server_stopped
signal server_start_failed

signal user_connected
signal user_disconnected

onready var network = NetworkedMultiplayerENet.new()

var pending_connection = []
var connected = []

onready var main = get_parent()

func _ready():
	network.connect("peer_connected",self,"_user_connected")
	network.connect("peer_disconnected",self,"_user_disconnected")
	

var server_running = false
func start_server(port:int,max_users:int,password:String="",manual_join_aproval=false):
	if server_running:
		printerr("Cannot start server. Already running.")
		return
	var err = network.create_server(port,max_users)
	if err == OK:
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
	print("Server stopped")
	network.close_connection()
	server_running = false
	emit_signal("server_stopped")

remote func register_client(info):
	var id = get_tree().get_rpc_sender_id()
	connected.append({"id":id})
	
remote func server_message(message:String,title:String=""):
	main.menu.alert(message,title)

func _user_connected(id):
	rpc_id(int(id),"server_message","hello there")
	pass
	
func _user_disconnected(id):
	pass

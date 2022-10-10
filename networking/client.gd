tool
extends Node

signal connection_failed
signal connection_success
signal server_responded
signal disconnected
signal gui_alert

var disconnect_on_version_mismatch = false

var nickname:String = "Guest"
var network = NetworkedMultiplayerENet.new()
var connected = false

var current_ip = ""
var current_port = 0
var used_password = ""
var client_id = -1

onready var main = get_parent()

func _ready():
	network.connect("connection_succeeded",self,"_connected")
	network.connect("connection_failed",self,"_failed")
	network.connect("server_disconnected",self,"_disconnected")
	name = "client"

func get_id():
	return get_tree().get_network_unique_id()

func connect_to_server(ip:String,port:int,password:String=""):
	if connected:
		printerr("Client is already connected!")
		return

	print("Connecting to: ",ip,":",port)
	network.refuse_new_connections = false
	var err = network.create_client(ip,port)
	get_tree().network_peer = network
	print("Error status: ",err)
	current_ip = ip
	current_port = port
	if err == OK:
		used_password = password
		yield(get_tree().create_timer(5),"timeout")
		if not connected:
			print("Connection timed out")
			emit_signal("gui_alert"
			,"Timed out.\nCheck the host's IP adress, port and your internet connection.\nMake sure the hosts has opened ports."
			,"Connection failed.")
			disconnect_from_server()
	else:
		emit_signal("connection_failed",err)
		emit_signal("gui_alert","Could not connect to server.\nError code: "+String(err),"Connection failed")

func disconnect_from_server():
	connected = false
	network.close_connection()
	_disconnected()

func _connected():
	print("Successfuly connected")
	print("Requesting client authentication on server...")
	main.server.rpc_id(1,"auth_client",nickname,used_password)
	connected = true
	emit_signal("connection_success")

func _failed():
	connected = false
	printerr("Could not connect to: ",current_ip,":",current_port)
	current_ip = ""
	current_port = 0

func _disconnected():
	connected = false
	get_tree().network_peer = null
	print("Disconnected from: ",current_ip,":",current_port)
	current_ip = ""
	current_port = 0
	emit_signal("disconnected")

#####################################################################
var other_clients = []

puppet func server_response(version:float,host_nickname:String,color:Color,id:int):
	emit_signal("server_responded")
	print("Server accepted connection.")
	print("Host nickname: ",host_nickname)
	print("Server version: ",version," Client version: ",main.version)
	if version != main.version:
		if disconnect_on_version_mismatch:
			disconnect_from_server()
		else:
			emit_signal("gui_alert",
			"Server version is: "+String(version)+" client is: "+String(main.version)+\
			"\nThis might cause major issues (including project file corruption).",
			"WARNING")

remote func update_self(currentScene,mousePos:Vector2,cameraPos:Vector3):
	pass










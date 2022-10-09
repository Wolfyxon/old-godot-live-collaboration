tool
extends Node

signal connection_failed
signal connection_success
signal disconnected

signal gui_alert

var network = NetworkedMultiplayerENet.new()
var connected = false

var current_ip = ""
var current_port = 0

func _ready():
	network.connect("connection_succeeded",self,"_connected")
	network.connect("connection_failed",self,"_failed")
	network.connect("server_disconnected",self,"_disconnected")

func connect_to_server(ip:String,port:int):
	print("Connecting to: ",ip,":",port)
	var err = network.create_client(ip,port)
	get_tree().network_peer = network
	print("Error status: ",err)
	current_ip = ip
	current_port = port
	if err != OK:
		emit_signal("connection_failed",err)
		emit_signal("gui_alert","Something might be already using this port, try changing it.\nError code: "+String(err),"Server start failed")

func disconnect_from_server():
	network.close_connection()

func _connected():
		print("Successfuly connected")
		connected = true
		emit_signal("connection_success")
	
func _failed():
	connected = false
	printerr("Could not connect to: ",current_ip,":",current_port)
	current_ip = ""
	current_port = 0

func _disconnected():
	connected = false
	print("Disconnected from: ",current_ip,":",current_port)
	current_ip = ""
	current_port = 0

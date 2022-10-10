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

onready var main = get_parent()

func _ready():
	network.connect("connection_succeeded",self,"_connected")
	network.connect("connection_failed",self,"_failed")
	network.connect("server_disconnected",self,"_disconnected")

func get_id():
	return get_tree().get_network_unique_id()

func connect_to_server(ip:String,port:int,password:String=""):
	print("Connecting to: ",ip,":",port)
	var err = network.create_client(ip,port)
	get_tree().network_peer = network
	print("Error status: ",err)
	current_ip = ip
	current_port = port
	if err == OK:
		used_password = password
		yield(get_tree().create_timer(5),"timeout")
		emit_signal("gui_alert"
		,"Timed out.\nCheck the host's IP adress, port and your internet connection.\nMake sure the hosts has opened ports."
		,"Connection failed.")
	else:
		emit_signal("connection_failed",err)
		emit_signal("gui_alert","Could not connect to server.\nError code: "+String(err),"Connection failed")

func disconnect_from_server():
	connected = false
	network.close_connection()

func _connected():
		main.server.rpc_id(1,"auth_client",nickname,used_password)
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
	emit_signal("disconnected")


puppet func server_response(version:float,host_nickname:String):
	emit_signal("server_responded")
	print("Server accepted connection.")
	print("Host nickname: ",host_nickname)
	print("Server version: ",version," Client version: ",main.version)
	if disconnect_on_version_mismatch:
		disconnect_from_server()
	else:
		emit_signal("gui_alert",
		"Server version is: "+String(version)+" client is: "+String(main.version)+\
		"\nThis might cause major issues (including project file corruption).",
		"WARNING")















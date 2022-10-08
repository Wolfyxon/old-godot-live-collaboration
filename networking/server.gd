tool
extends Node

signal server_started
signal server_stopped
signal user_connected
signal user_disconnected

onready var network = NetworkedMultiplayerENet.new()

var pending_connection = {
	#"ip":{"nickname":"","permission_level":1}
}
var connected = {
	#"ip":{"nickname":"","permission_level":1}
}

func _ready():
	pass

func start_server(port:int,max_users:int,password:String="",manual_join_aproval=false):
	network.create_server(port,max_users)
	get_tree().network_peer = network
	print("Server started at port: ",port)
	print("Max users: ",max_users)
	print("Password: ",password)
	print("Manual join aproval: ",manual_join_aproval)
	
	
	network.connect("peer_connected",self,"_user_connected")
	network.connect("peer_disconnected",self,"_user_disconnected")
	

func _user_connected(id):
	pass
	
func _user_disconnected(id):
	pass

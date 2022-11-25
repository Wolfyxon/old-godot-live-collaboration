tool
extends Node

signal connection_failed
signal connection_success
signal server_responded
signal disconnected
signal gui_alert

signal action_finished
signal action_accepted
signal action_rejected

var disconnect_on_version_mismatch = false

var nickname:String = "Guest"
var network = NetworkedMultiplayerENet.new()
var connected = false

var current_ip = ""
var current_port = 0
var used_password = ""
var client_id = -1

onready var main:EditorPlugin = get_parent()
onready var editor_interface:EditorInterface = main.get_editor_interface()
var validators = preload("../validators.gd").new()
var utils = preload("../utils.gd").new()

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
	main.editor_events.remove_all_markers()
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

master func done():
	emit_signal("action_finished")

puppet func create_dirs(dirs:Array):
	print("Creating directories")
	utils.create_dirs(dirs)
	print("Directories created")
	rpc_id(1,"done")

puppet func store_file(path:String,buffer:PoolByteArray):
	var id = get_tree().get_rpc_sender_id()
	if id == get_tree().get_network_unique_id(): return
	if not validators.validate_path(path): return
	if ProjectSettings.localize_path(path).begins_with(main.plugin_dir): return
	if id != 1: return #just for sure
	var d = Directory.new()
	if not d.dir_exists(path.get_base_dir()):
		d.make_dir_recursive(path.get_base_dir())
	var f = File.new()
	var err = f.open(path,f.WRITE)
	if err != OK:
		printerr("Error downloading ",path," err: ",err)
		return
	f.store_buffer(buffer)
	f.close()
	print("Received ",path)

puppetsync func reload():
	editor_interface.reload_scene_from_path(editor_interface.get_current_path())
	print("Server has reloaded your current scene")


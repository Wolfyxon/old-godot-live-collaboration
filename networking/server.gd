tool
extends Node

signal gui_alert

signal server_started
signal server_stopped
signal server_start_failed

signal user_auth
signal user_connected
signal user_disconnected


onready var network = NetworkedMultiplayerENet.new()
var validators = preload("../validators.gd").new()
var utils = preload("../utils.gd").new()

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

func _ready():
	network.connect("peer_connected",self,"_user_connected")
	network.connect("peer_disconnected",self,"_user_disconnected")
	name = "server"
	

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
	get_tree().network_peer = null
	emit_signal("server_stopped")

func is_user_authenticated(id:int):
	return get_user_by_id(id) != null

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

func send_project_files(id:int):
	print("Sending files to user ",id)
	client.rpc_id(id,"create_dirs",utils.scan_dirs("res://"))
	yield(client,"action_finished")
	print("Client responded with finish signal, sending files.")
	yield(get_tree(),"idle_frame")
	
	var limitter_max = 20 #every X files, plugin will wait for few ms to prevent overload
	var limitter = 0
	var files = utils.scan_files("res://")
	client.rpc_id(id,"create_progress","project_download","Downloading project files, go get some coffe",files.size())
	yield(get_tree(),"idle_frame")
	var f = File.new()
	for i in files:
		if (not(main.plugin_dir) in i) and validators.validate_path(i) and not(i.begins_with(main.plugin_dir)): #replicating plugin files may lead to major issues
			if limitter >= limitter_max:
				limitter = 0
				yield(get_tree(),"idle_frame")
				
			var err = f.open(i,f.READ)
			if err == OK:
				var bytes = f.get_len()
				var b = f.get_buffer(bytes)
				#prints(i,"\n",b.get_string_from_utf8(),"\n")
				print("Sent ",i," -> ",id)
				client.rpc_id(id,"store_file",i,b,"project_download")
			else:
				printerr("Failed to send ",i," err: ",err)
	print("files sent, sending reload packet")
	client.rpc_id(id,"reload")

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
		emit_signal("user_auth",data)
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
		yield(get_tree(),"idle_frame")
		#send_project_files(id)
	else:
		yield(get_tree(),"idle_frame")
		kick(id,error)

master func request_file(path:String):
	var id = get_tree().get_rpc_sender_id()
	if not is_user_authenticated(id): return
	if not validators.validate_path(path): 
		rpc_id(id,"server_message","Invalid/insecure path")
		return
	if not utils.file_exists(path): 
		rpc_id(id,"server_message","Server is unable to locate path of the file")
		return
	
	var f = File.new()
	var err = f.open(path,f.READ)
	if err != OK:
		rpc_id(id,"server_message","Server is unable to open the file.\nError code: "+String(err))
	var b = f.get_buffer(f.get_len())
	client.rpc_id(id,"store_file",path,b)
	

remote func upload_file(path,buffer):
	pass

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
	

tool
extends GridContainer

signal kick
signal ban
signal user_log

var utils = preload("../../utils.gd").new()

onready var key_columns = [
	$nick,
	$ip,
	$permission,
	$log,
	$kick,
	$ban
]
onready var template_columns = [
	$_id,
	$_nick,
	$_ip,
	$_permission,
	$_log,
	$_kick,
	$_ban
]

var rows = []

func _ready():
	for i in template_columns: i.visible = false
	$_permission.disabled = true

func add_row(id:int,nickname:String,ip:String,lvl:int):
	var clms = [] #id,nick,ip,perm,log,kick,ban
	for i in template_columns:
		var d = i.duplicate()
		d.name = String(id)+d.name
		clms.append(d)
		add_child(d)
	
	var cid:Label = utils.get_node_from_array(clms,String(id)+"_id")
	var cnick:Label = utils.get_node_from_array(clms,String(id)+"_nick")
	var cip:MenuButton = utils.get_node_from_array(clms,String(id)+"_ip")
	var cperm:OptionButton = utils.get_node_from_array(clms,String(id)+"_permission")
	var clog:Button = utils.get_node_from_array(clms,String(id)+"_log")
	var ckick:Button = utils.get_node_from_array(clms,String(id)+"_kick")
	var cban:Button = utils.get_node_from_array(clms,String(id)+"_ban")
	
	
	ckick.connect("pressed",self,"_disconnect")
	cid.text = String(id)
	cnick.text = nickname
	cip.get_popup().add_item(ip)
	cperm.select(lvl)
	
	for i in clms:
		i.set_meta("id",id)
		i.set_meta("nick",nickname)
		i.set_meta("nickname",nickname)
		i.visible = true
		
		
func _disconnect():
	for i in get_children():
		if (i is Button) and i.name.ends_with("_kick"):
			if i.pressed:
				kick_button(i)
		
func log_button(button:Button):
	emit_signal("user_log",button.get_meta("id"))
func kick_button(button:Button):
	var id = button.get_meta("id")
	delete_row(id)
	emit_signal("kick",id)
func ban_button(button:Button):
	emit_signal("ban",button.get_meta("id"))

func delete_row(id:int):
	for i in get_children():
		if i.name.begins_with(String(id)+"_"):
			i.queue_free()
	
func get_columns():
	var r = get_children()
	for i in key_columns:
		r.remove(r.find(i))
	for i in template_columns:
		r.remove(r.find(i))
	return r



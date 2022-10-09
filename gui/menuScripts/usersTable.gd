tool
extends GridContainer

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


func add_row(id,nickname,ip,lvl):
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
	
	cid.text = String(id)
	cnick.text = nickname
	#cip
	cperm.select(lvl)
	
	for i in clms:
		i.set_meta("id",id)
		i.set_meta("nick",nickname)
		i.set_meta("nickname",nickname)
		i.visible = true
		
	
func get_columns():
	var r = get_children()
	for i in key_columns:
		r.remove(r.find(i))
	for i in template_columns:
		r.remove(r.find(i))
	return r



tool
extends VBoxContainer

signal request_added
signal request_removed
signal requests_changed
signal aproved
signal denied

func _ready():
	$template.visible = false


func get_pressed_button(path:NodePath):
	for i in get_children():
		if i is Panel:
			var button:Button = i.get_node("hbox/"+path)
			if button.pressed:
				return button

func _aproved():
	var button = get_pressed_button("btn_aprove")
	if not button: return
	button.get_parent().get_parent().queue_free()
	var ip = button.get_meta("ip")
	var nick = button.get_meta("nick")
	emit_signal("aproved",ip,nick)
	emit_signal("requests_changed")

func _denied():
	var button = get_pressed_button("btn_deny")
	if not button: return
	button.get_parent().get_parent().queue_free()
	var ip = button.get_meta("ip")
	var nick = button.get_meta("nick")
	emit_signal("denied",ip,nick)
	emit_signal("requests_changed")

func get_list_items() -> Array:
	var r = []
	for i in get_children():
		if (i is Panel) and (i != $template):
			r.append(i)
	return r

func add(nickname,ip):
	var d = $template.duplicate()
	d.name = nickname+"_"+d.name
	
	var hbox = d.get_node("hbox")
	var aprove = hbox.get_node("btn_aprove")
	var deny = hbox.get_node("btn_deny")
	
	var info = hbox.get_node("info")
	info.get_node("nick").text = nickname
	info.get_node("ip").text = ip
	
	aprove.set_meta("ip",ip)
	aprove.set_meta("nick",nickname)
	aprove.set_meta("nickname",nickname)
	aprove.connect("pressed",self,"_aproved")
	deny.set_meta("ip",ip)
	deny.set_meta("nick",nickname)
	deny.set_meta("nickname",nickname)
	deny.connect("pressed",self,"_denied")
	
	add_child(d)
	d.visible = true
	emit_signal("request_added",nickname,ip)
	emit_signal("requests_changed")


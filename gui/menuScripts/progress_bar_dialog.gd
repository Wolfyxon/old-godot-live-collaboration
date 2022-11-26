extends PopupDialog
tool

var max_progresses = 5

onready var template_lbl = $vbox/lbl_progress_id
onready var template_pb = $vbox/pb_progress_id

func _ready():
	template_lbl.visible = false
	template_pb.visible = false

func get_bars() -> Array:
	var r = []
	for i in $vbox.get_children():
		if (i is ProgressBar) and i.visible:
			r.append(i)
	return r

func get_by_id(id:String) -> Array:
	var l:Label
	var pb:ProgressBar
	for i in $vbox.get_children():
		if i.visible:
			if (i is Label) and i.name=="lbl_"+id:
				l = i
			if (i is ProgressBar) and i.name=="pb_"+id:
				pb = i
			
	return [l,pb]

func get_bar(id:String) -> ProgressBar:
	return get_by_id(id)[1]
func get_label(id:String) -> Label:
	return get_by_id(id)[0]

func create_progress(id:String,title:="Please wait",max_value:=100,initial_value:=0):
	popup_centered()
	var l = template_lbl.duplicate()
	var pb = template_pb.duplicate()
	
	l.name = "lbl_"+id
	pb.name = "pb_"+id
	l.text = title
	pb.max_value = max_value
	pb.value = initial_value
	l.visible = true
	pb.visible = true
	
	l.set_meta("id",id)
	pb.set_meta("id",id)

	$vbox.add_child(l)
	$vbox.add_child(pb)
	
func update_progress(id:String,amount:=1):
	var pb = get_bar(id)
	if not pb: printerr("progress bar ",id," not found")
	pb.value += amount
	if pb.value == pb.max_value:
		remove_progress(id)

func remove_progress(id:String):
	for i in get_by_id(id):
		i.queue_free()
	yield(get_tree(),"idle_frame")
	if get_bars().size() == 0: hide()

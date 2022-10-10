tool
extends PopupDialog

signal closed

var current_popup_id = 0

func wait_popup(signal_owner:Node,signal_name:String,text:String,title:String=""):
	var id = current_popup_id + 1
	current_popup_id += 1
	$progress_label.text = text
	$title.text = title
	popup_centered()
	yield(signal_owner,signal_name)
	if visible and (current_popup_id == id): #this will prevent issues if dialog was closed during waiting
		hide()
		emit_signal("closed")
	
func progress_popup():
	pass

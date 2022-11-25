extends Tabs
tool

var utils = preload("../../utils.gd").new()
onready var main = get_parent().get_parent().main

func _process(delta):
	$scroll/VBoxContainer/ngrok/token.secret = $scroll/VBoxContainer/ngrok/btn_hide.pressed
	$scroll/VBoxContainer/ngrok/btn_ngrok_auth.disabled = (
		$scroll/VBoxContainer/ngrok/path.text == "" or
		$scroll/VBoxContainer/ngrok/token.text == ""
	)

func alert(text:String,title:=""):
	get_parent().get_parent().alert(text,title)

func _on_btn_ngrok_auth_pressed():
	var path = $scroll/VBoxContainer/ngrok/path.text
	if not utils.file_exists(path): 
		alert("Ngrok executable not found at: "+path)
		return

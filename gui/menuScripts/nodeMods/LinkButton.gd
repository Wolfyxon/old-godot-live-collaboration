tool
extends LinkButton

var utils = preload("../../../utils.gd").new()

export (bool) var open_url = true
export (bool) var copy_text = false
export (String) var url = ""

func _pressed():
	if copy_text:
		OS.clipboard = text
	
	if open_url:
		if url:
			openUrl(url)
		else:
			openUrl(text)

func openUrl(url:String):
	if utils.is_valid_url(url):
		OS.shell_open(url)

tool
extends LinkButton

var utils = preload("../../../utils.gd").new()
export (String) var url = ""

func _pressed():
	if url:
		openUrl(url)
	else:
		openUrl(text)

func openUrl(url:String):
	if utils.is_valid_url(url):
		OS.shell_open(url)

extends LinkButton

export (String) var url = ""

func _pressed():
	if url:
		OS.shell_open(url)
	else:
		OS.shell_open(text)


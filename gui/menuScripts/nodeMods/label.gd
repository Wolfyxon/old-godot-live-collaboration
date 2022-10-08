tool
extends Label

export (int) var character_limit = -1

var last_text = ""
func _physics_process(delta):
	if character_limit == -1: return
	if last_text != text:
		if text.length() > character_limit:
			var fulltext = text
			text = ""
			for i in character_limit:
				text += fulltext[i]
			text += "..."
			
		last_text = text

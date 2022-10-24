tool
extends Spatial

var id = -1

func _ready():
	for i in get_children()+[self]+$arrow.get_children():
		i.set_meta("_edit_lock_", true)

func set_nickname(nickname:String):
	$Viewport/nickname.text = nickname

func set_color(color:Color):
	color.a = 0.5
	$main.get_active_material(0).albedo_color = color


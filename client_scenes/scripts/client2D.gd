tool
extends Node2D

var id = -1

func set_nickname(nick:String):
	$nick.text = nick

func set_color(color:Color):
	modulate = color

extends Control
class_name RevealDebugOnKeyPress

func _ready():
	visible = false

func _input(event):
	if event is InputEventKey and event.keycode == KEY_F7 and event.is_pressed():
		visible = true

extends BaseButton
class_name UIVisibilityTogglerButton

@export var target_controls : Array[Control] = []

func _ready():
	pressed.connect(_button_pressed_callback)
	
	for control in target_controls:
		control.visible = button_pressed


func _button_pressed_callback():
	for control in target_controls:
		control.visible = button_pressed

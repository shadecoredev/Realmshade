extends BaseButton
class_name UIFullscreenToggleButton

func _ready():
	pressed.connect(_button_pressed_callback)

func _button_pressed_callback():
	var window: Window = get_tree().get_root()
	if window.mode == Window.Mode.MODE_FULLSCREEN:
		window.mode = Window.Mode.MODE_WINDOWED
	else:
		window.mode = Window.Mode.MODE_FULLSCREEN

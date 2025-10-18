extends Button
class_name UIDebugEventSelector

@export var item_name_lineedit : LineEdit
@export var event_manager : EventManager

func _ready():
	pressed.connect(_pressed_callback)

func _pressed_callback():
	event_manager.clear()
	event_manager.enemy_inventory.clear()
	event_manager._selected_event = item_name_lineedit.text
	event_manager._handle_event()

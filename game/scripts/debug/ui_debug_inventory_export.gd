extends Button
class_name UIDebugInventoryExport

@export var target_inventory : UIInventory

func _ready():
	pressed.connect(_button_pressed_callback)

func _button_pressed_callback():
	print(target_inventory.inventory.stringify("\t"))

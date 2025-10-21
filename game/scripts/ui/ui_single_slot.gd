extends UIInventory
class_name UISingleSlot

var slotted_item : InventoryItem

signal contents_changed_signal

func can_add_item(_item : UIItem, _is_rotated : bool, _pos : Vector2i) -> bool:
	return slotted_item == null

func add_item(inventory_item : InventoryItem, _is_rotated : bool, _pos : Vector2i):
	slotted_item = inventory_item
	contents_changed_signal.emit()

func remove_item(item : UIItem):
	if slotted_item != item.get_inventory_item():
		printerr("Removed item is not matching slotted item.")
	
	slotted_item = null
	contents_changed_signal.emit()

func clear():
	super.clear()
	slotted_item = null

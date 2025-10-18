extends TextureRect
class_name UIItem

var _rotated : bool = false

var _disabled : bool = false

var _initialized : bool = false

var _inventory_item : InventoryItem

signal item_rotated_signal(is_rotated : bool)

signal item_changed_inventory(new_inventory : UIInventory)

func initialize(item_name : String, metadata : Dictionary = {}):
	var item = Item.load(item_name)

	if item:
		texture = item.texture
		size = texture.get_size()
	else:
		printerr("Item \"%s\" not recognized." % item_name)
		queue_free()
		return

	_inventory_item = InventoryItem.new(item, metadata)

	_initialized = true

func emit_item_changed_inventory(new_inventory : UIInventory):
	item_changed_inventory.emit(new_inventory)

func _ready():
	mouse_entered.connect(_mouse_entered_callback)
	mouse_exited.connect(_mouse_exited_callback)

func _mouse_exited_callback():
	if UIItemManager.get_instance() != null:
		UIItemManager.get_instance().clear_hovered_item_info_box()

func _mouse_entered_callback():
	if UIItemManager.get_instance() != null:
		UIItemManager.get_instance().set_hovered_item(self)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and !_disabled:
		UIItemManager.get_instance().start_dragging(self)

func rotate():
	if _inventory_item.get_item().texture.get_width() == _inventory_item.get_item().texture.get_height():
		return
	
	if !_rotated:
		rotation = -PI / 2.0
		_rotated = true
	else:
		rotation = 0.0
		_rotated = false

	_inventory_item.set_rotated(_rotated)
	item_rotated_signal.emit(_rotated)

func is_rotated():
	return _rotated

func get_item() -> Item:
	return _inventory_item.get_item()

func get_inventory_item() -> InventoryItem:
	return _inventory_item

func disable():
	_disabled = true

func enable():
	_disabled = false

func is_disabled() -> bool:
	return _disabled

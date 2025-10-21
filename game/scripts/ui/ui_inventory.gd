extends Control
class_name UIInventory

@export var container_size : Vector2i = Vector2i(5, 3)

var _item_manager : UIItemManager

var inventory : Inventory = Inventory.new()

func set_inventory_size(new_size : Vector2i) -> void:
	container_size = new_size
	update_size()

func update_size():
	inventory.resize(container_size)
	size = container_size * 16.0

func _ready():
	update_size()
	
	mouse_entered.connect(_mouse_entered_callback)
	mouse_exited.connect(_mouse_exited_callback)

func _mouse_exited_callback():
	if _item_manager == null:
		_item_manager = UIItemManager.get_instance()
	_item_manager.unselect_hovered_inventory()

func _mouse_entered_callback():
	if _item_manager == null:
		_item_manager = UIItemManager.get_instance()
	_item_manager.set_hovered_inventory(self)

func can_add_item(item : UIItem, is_rotated : bool, pos : Vector2i) -> bool:
	return inventory.can_add_item(item.get_item(), is_rotated, pos)

func add_item(inventory_item : InventoryItem, is_rotated : bool, pos : Vector2i):
	return inventory.add_item(inventory_item, is_rotated, pos)

func remove_item(item : UIItem):
	inventory.remove_item(item.get_inventory_item())

func _on_game_manager_level_increased_signal(source : GameManager):
	set_inventory_size(source.get_inventory_size_by_level(source.get_level()))

func load_from_json(items : Array):
	for item in items:
		var encoded_position = int(item["position"])

		var ui_item = UIItemManager.get_instance().spawn_item(item["name"])
		ui_item.initialize(item["name"])
		if ((encoded_position >> 8) & 1 != 0):
			ui_item.rotate()
		ui_item.disable()
		
		add_child(ui_item)
		UIItemManager.get_instance().add_item_to_inventory(
			ui_item,
			((encoded_position >> 8) & 1 != 0),
			Vector2i(
				(encoded_position >> 4) & 15,
				(encoded_position & 15)
			),
			self
		)

func clear():
	inventory.clear()
		
	for child in get_children():
		if child is UIItem:
			child.queue_free()

func clear_visuals():
	for child in get_children():
		if child is UIItem:
			child.material = null

func disable():
	for child in get_children():
		if child is UIItem:
			child.disable()
			
func enable():
	for child in get_children():
		if child is UIItem:
			child.enable()

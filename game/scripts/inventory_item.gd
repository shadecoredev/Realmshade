extends RefCounted
class_name InventoryItem

var _item : Item
var _is_rotated : bool = false
var _position : Vector2i

var _metadata : Dictionary = {}

var _parent_inventory : Inventory

func _init(item : Item, metadata : Dictionary):
	_item = item
	_metadata = metadata

func get_metadata():
	var meta_duplicate = _metadata.duplicate(true)
	meta_duplicate["name"] = _item.name
	meta_duplicate["position"] = \
		(int(is_rotated()) << 8) + \
		(get_position().x << 4) + \
		(get_position().y)
	return meta_duplicate

func update_position(position : Vector2i):
	_position= position

func set_rotated(rotated : bool):
	_is_rotated = rotated

func set_parent_inventory(inventory : Inventory):
	_parent_inventory = inventory

func get_parent_inventory() -> Inventory:
	return _parent_inventory

func is_rotated() -> bool:
	return _is_rotated
	
func get_position() -> Vector2i:
	return _position

func set_position(position : Vector2i):
	_position = position

func get_item() -> Item:
	return _item

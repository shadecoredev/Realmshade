extends RefCounted
class_name Inventory

var _inventory_items : Array[InventoryItem] = []
var _slots : Array[Array] = [[null]]

var _size : Vector2i = Vector2i.ONE

func resize(size : Vector2i):
	var container_size = Vector2i(_slots.size(), _slots[0].size())
	
	if container_size.x < size.x:
		var difference = size.x - container_size.x
		_slots.resize(size.x)
		for i in range(size.x - difference, size.x):
			_slots[i] = []

	for container in _slots:
		if container.size() < size.y:
			container.resize(size.y)
	
	_size = size

func can_add_item(item : Item, is_rotated : bool, position : Vector2i) -> bool:
	var item_size : Vector2i = item.get_size(is_rotated)

	for i in range(item_size.x):
		for j in range(item_size.y):
			if position.x + i >= _size.x or position.x < 0:
				return false
			if position.y + j >= _size.y or position.y < 0:
				return false 
			if _slots[position.x + i][position.y + j] != null:
				return false

	return true

func add_item(inventory_item : InventoryItem, is_rotated : bool, position : Vector2i):
	var item_size : Vector2i = inventory_item.get_item().get_size(is_rotated)

	inventory_item.set_rotated(is_rotated)
	inventory_item.set_position(position)
	inventory_item.set_parent_inventory(self)
	
	_inventory_items.append(inventory_item)
	
	for i in range(item_size.x):
		for j in range(item_size.y):
			if position.x + i >= _size.x or position.y + j >= _size.y:
				printerr("Invalid item placement (%s)." % str(position))
				continue 
			_slots[position.x + i][position.y + j] = inventory_item


func remove_item(position : Vector2i) -> InventoryItem:
	var inventory_item : InventoryItem = _slots[position.x][position.y]

	if inventory_item == null:
		return
		
	var array_index = _inventory_items.find(inventory_item)
	if array_index == -1:
		print("Removed item was not present in the inventory.")
		return

	_inventory_items.remove_at(array_index)
	
	var item_size : Vector2i = inventory_item.get_item().get_size(inventory_item.is_rotated())
	var origin = inventory_item.get_position()
	
	for i in range(origin.x, origin.x + item_size.x):
		for j in range(origin.y, origin.y + item_size.y):
			if i >= _size.x or i < 0 or j >= _size.y or j < 0:
				printerr("Invalid item removal (%s)." % str(position))
				continue
			_slots[i][j] = null
			
	return inventory_item

func stringify(indent: String = "") -> String:
	var inventory_json = {}

	inventory_json["items"] = []

	for item in _inventory_items:
		var item_json = item.get_metadata()

		inventory_json["items"].append(item_json)

	return JSON.stringify(inventory_json, indent)

func get_items() -> Array[InventoryItem]:
	return _inventory_items

func clear():
	for item in _inventory_items:
		remove_item(item.get_position())
	_inventory_items.clear()

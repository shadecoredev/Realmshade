extends Control
class_name CraftingStationEvent

@export var label : Label

@export var slot_1 : UISingleSlot
@export var slot_2 : UISingleSlot

@export var result_container : Control

var search_inventories : Array[UIInventory] = []

var recipes : Dictionary

var _markers : Array[UIMarker]

signal contents_changed_signal

func add_recipe_search_inventory(inventory : UIInventory):
	search_inventories.append(inventory)

func is_empty():
	return slot_1.slotted_item == null and slot_2.slotted_item == null

func initialize_recipes(station_name : String, recipes_array : Array):
	label.text = station_name.capitalize()
	
	if recipes_array == null:
		printerr("Invalid crafting station recipes array.")

	for entry in recipes_array:
		var value_splitted = entry.split("=")
		var items = value_splitted[0]
		var result = value_splitted[1]
		var items_splitted = items.split("+")
		var ingredient1 = items_splitted[0]
		var ingredient2 = items_splitted[1]
		
		if ingredient1 not in recipes:
			recipes[ingredient1] = {}
		if ingredient2 not in recipes[ingredient1]:
			recipes[ingredient1][ingredient2] = PackedStringArray()
		recipes[ingredient1][ingredient2].append(result)
			
		if ingredient2 not in recipes:
			recipes[ingredient2] = {}
		if ingredient1 not in recipes[ingredient2]:
			recipes[ingredient2][ingredient1] = PackedStringArray()
		recipes[ingredient2][ingredient1].append(result)

func _ready():
	slot_1.contents_changed_signal.connect(_contents_changed_callback)
	slot_2.contents_changed_signal.connect(_contents_changed_callback)
	
	_contents_changed_callback.call_deferred()

func _contents_changed_callback():
	contents_changed_signal.emit()
	clear_markers()
	
	for child in result_container.get_children():
		child.queue_free()

	var slot_1_item : InventoryItem = slot_1.slotted_item
	var slot_2_item : InventoryItem = slot_2.slotted_item

	if slot_1_item == null and slot_2_item == null:
		for inventory in search_inventories:
			if inventory:
				for item in inventory.get_children():
					if item.get_item().name in recipes:
						create_marker(item)
		var dragged_item = UIItemManager.get_instance().get_dragged_item()
		if dragged_item != null:
			if dragged_item.get_item().name in recipes:
				create_marker(dragged_item)
		return
	
	if slot_1_item == null and slot_2_item != null:
		slot_1_item = slot_2_item
		slot_2_item = null
	
	if slot_1_item != null and slot_2_item == null:
		if slot_1_item.get_item().name in recipes:
			var recipe_dictionary = recipes[slot_1_item.get_item().name]
			for inventory in search_inventories:
				if inventory:
					for item in inventory.get_children():
						if item.get_item().name in recipe_dictionary:
							create_marker(item)
		var dragged_item = UIItemManager.get_instance().get_dragged_item()
		if dragged_item != null:
			if slot_1_item.get_item().name in recipes:
				var recipe_dictionary = recipes[slot_1_item.get_item().name]
				if dragged_item.get_item().name in recipe_dictionary:
					create_marker(dragged_item)
		return
	
	elif slot_1_item != null and slot_2_item != null:
		if slot_1_item.get_item().name in recipes:
			var recipe_dictionary = recipes[slot_1_item.get_item().name]
			var item_2_name = slot_2_item.get_item().name
			if item_2_name in recipe_dictionary:
				var result_array : PackedStringArray = recipe_dictionary[item_2_name]
				for i in result_array.size():
					var game_manager = GameManager.get_instance()
					var metadata = {
						"level" : game_manager.get_level(),
						"event" : game_manager.get_event(),
						"ingredient_1" : slot_1_item.get_metadata(),
						"ingredient_2" : slot_2_item.get_metadata()
					}
					var result_item = UIItemManager.get_instance().spawn_item(result_array[i], metadata)
					result_container.add_child(result_item)
					result_item.position = Vector2(0, i * 48 - result_array.size() * 0.5) - result_item.size * 0.5
					result_item.item_changed_inventory.connect(
						_result_item_changed_inventory_callback,
						CONNECT_ONE_SHOT
					)
					
					

func create_marker(ui_item : UIItem):
	var marker = load("res://scenes/templates/marker_template.tscn").instantiate() as UIMarker
	ui_item.add_child(marker)
	marker.initialize(ui_item)
	_markers.append(marker)

func _result_item_changed_inventory_callback(_new_inventory : UIInventory):
	slot_1.clear()
	slot_2.clear()
	_contents_changed_callback()

func clear_markers():
	for marker in _markers:
		marker.queue_free()
	_markers.clear()

func _exit_tree():
	clear_markers()

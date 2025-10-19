extends Node2D
class_name UIItemManager

static var _instance : UIItemManager

@export var outline_material : ShaderMaterial

@export var item_template : PackedScene

@export var trash_inventory : UIInventory

var _item_drag_start_position : Vector2
var _item_drag_start_rotated : bool
var _item_drag_start_inventory : UIInventory

var _dragged_item : UIItem
var _hovered_item : UIItem
var _hovered_inventory : UIInventory
var _hovered_inventory_position : Vector2i
var _last_hovered_inventory_position : Vector2i

var _item_info : UIInfoBox

func _ready() -> void:
	_instance = self

static func get_instance() -> UIItemManager:
	return _instance
	
func get_dragged_item() -> UIItem:
	return _dragged_item

func start_dragging(item : UIItem):
	if _item_info:
		_item_info.remove()

	_dragged_item = item
	var global_pos = _dragged_item.global_position
	_dragged_item.top_level = true
	_item_drag_start_position = _dragged_item.position
	_item_drag_start_rotated = _dragged_item.is_rotated()
	_dragged_item.material = outline_material
	_dragged_item.z_index = 10
	_dragged_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _dragged_item.get_parent() is UISingleSlot:
		var inventory = _dragged_item.get_parent() as UIInventory
		inventory.remove_item(Vector2.ZERO)
	elif _dragged_item.get_parent() is UIInventory:
		var inventory = _dragged_item.get_parent() as UIInventory
		var inventory_pos = Vector2i.ZERO
		
		_item_drag_start_inventory = inventory
		
		inventory_pos.x = roundf(_item_drag_start_position.x / 16.0) * 16.0
		inventory_pos.y = roundf((_item_drag_start_position.y) / 16.0) * 16.0
		
		if item.is_rotated():
			inventory.remove_item((_item_drag_start_position - Vector2(0.0, item.size.x)) / 16.0)
		else:
			inventory.remove_item(_item_drag_start_position / 16.0)

	trash_inventory.visible = true
	
	_dragged_item.global_position = global_pos

func _input(event):
	if event.is_action("rotate") and event.is_pressed():
		if _dragged_item:
			_dragged_item.rotate()
			_process_dragged_item() ## Processes new rotatated state
			_process_dragged_item() ## Checks if slots are free
	
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_F1:
			if _hovered_item != null:
				print(
					JSON.stringify(_hovered_item.get_inventory_item().get_metadata(), "\t")
				)
		elif event.keycode == KEY_F2:
			if _hovered_inventory != null:
				for item in _hovered_inventory.inventory.get_items():
					printt(
						item.get_metadata()
					)

	if _dragged_item:
		if event is InputEventMouseMotion:
			_process_dragged_item()
		if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			_release_dragged_item()

func _process_dragged_item():
	if _dragged_item == null:
		return

	var pos = get_global_mouse_position() 
	if _hovered_inventory == null:
		if _dragged_item.is_rotated():
			_dragged_item.global_position = get_global_mouse_position() - Vector2(_dragged_item.size.y, -_dragged_item.size.x) * 0.5
		else:
			_dragged_item.global_position = get_global_mouse_position() - _dragged_item.size * 0.5
	elif _hovered_inventory is UISingleSlot:
		var can_add_item = _hovered_inventory.can_add_item(_dragged_item, false, Vector2i.ZERO)
		outline_material.set_shader_parameter(
			"outline_color",
			Color.WHITE if can_add_item
			else 
			Color.RED
		)
		if can_add_item:
			_dragged_item.global_position = _hovered_inventory.global_position + _hovered_inventory.size * 0.5 
			if _dragged_item.is_rotated():
				_dragged_item.global_position -= Vector2(_dragged_item.size.y, -_dragged_item.size.x) * 0.5 + Vector2(8.0, 8.0)
			else:
				_dragged_item.global_position -= _dragged_item.size * 0.5 + Vector2(8.0, 8.0)
		else:
			if _dragged_item.is_rotated():
				_dragged_item.global_position = get_global_mouse_position() - Vector2(_dragged_item.size.y, -_dragged_item.size.x) * 0.5
			else:
				_dragged_item.global_position = get_global_mouse_position() - _dragged_item.size * 0.5
	else:
		if _dragged_item.is_rotated():
			pos -= Vector2(_dragged_item.size.y, -_dragged_item.size.x) * 0.5
			pos.x = clamp(pos.x, _hovered_inventory.global_position.x,  _hovered_inventory.global_position.x + _hovered_inventory.size.x - _dragged_item.size.y)
			pos.y = clamp(pos.y, _hovered_inventory.global_position.y + _dragged_item.size.x,  _hovered_inventory.global_position.y + _hovered_inventory.size.y)

			_hovered_inventory_position.x = round((_dragged_item.global_position.x - _hovered_inventory.global_position.x) / 16.0)
			_hovered_inventory_position.y = round((_dragged_item.global_position.y - _hovered_inventory.global_position.y - _dragged_item.size.x) / 16.0)
		else:
			pos -= _dragged_item.size * 0.5
			pos.x = clamp(pos.x, _hovered_inventory.global_position.x,  _hovered_inventory.global_position.x + _hovered_inventory.size.x - _dragged_item.size.x)
			pos.y = clamp(pos.y, _hovered_inventory.global_position.y,  _hovered_inventory.global_position.y + _hovered_inventory.size.y - _dragged_item.size.y)

			_hovered_inventory_position.x = round((_dragged_item.global_position.x - _hovered_inventory.global_position.x) / 16.0)
			_hovered_inventory_position.y = round((_dragged_item.global_position.y - _hovered_inventory.global_position.y) / 16.0)

		if _last_hovered_inventory_position != _hovered_inventory_position:
			_last_hovered_inventory_position = _hovered_inventory_position
			outline_material.set_shader_parameter(
				"outline_color",
				Color.WHITE if _hovered_inventory.can_add_item(_dragged_item, _dragged_item.is_rotated(), _hovered_inventory_position)
				else 
				Color.RED
			)

		_dragged_item.global_position = pos
		
		pos.x = roundf(pos.x / 16.0) * 16.0
		pos.y = roundf((pos.y) / 16.0) * 16.0

		_dragged_item.global_position = pos

func _release_dragged_item():
	_dragged_item.top_level = false
	_dragged_item.z_index = 3
	if _hovered_inventory == null:
		return_dragged_item()
	if _hovered_inventory is UISingleSlot:
		if _hovered_inventory.can_add_item(_dragged_item, _dragged_item.is_rotated(), Vector2.ZERO):	
			_dragged_item.reparent(_hovered_inventory)
			_hovered_inventory.add_item(_dragged_item.get_inventory_item(), _dragged_item.is_rotated(), Vector2.ZERO)
			_dragged_item.emit_item_changed_inventory(_hovered_inventory)
			if _dragged_item.is_rotated():
				_dragged_item.position = _hovered_inventory.size * 0.5 - Vector2(_dragged_item.size.y, -_dragged_item.size.x) * 0.5 - Vector2(8.0, 8.0)
			else:
				_dragged_item.position = _hovered_inventory.size * 0.5 - _dragged_item.size * 0.5 - Vector2(8.0, 8.0)
		else:
			return_dragged_item()
	else:
		#print("Releasing item to", _hovered_inventory_position)
		if _hovered_inventory and _hovered_inventory.can_add_item(_dragged_item, _dragged_item.is_rotated(), _hovered_inventory_position):	
			add_item_to_inventory(_dragged_item, _dragged_item.is_rotated(), _hovered_inventory_position, _hovered_inventory)
		else:
			return_dragged_item()
	
	_dragged_item.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_dragged_item.material = null
	_dragged_item = null
	
	if trash_inventory.inventory.get_items().is_empty():
		trash_inventory.visible = false

func return_dragged_item():
	if _item_drag_start_rotated != _dragged_item.is_rotated():
		_dragged_item.rotate()
	if _item_drag_start_inventory:
		var pos : Vector2i = _item_drag_start_position / 16.0
		if _item_drag_start_rotated:
			pos.y -= round(_dragged_item.size.x / 16.0)
	
		#print("Returning item to", pos)
	
		_item_drag_start_inventory.add_item(_dragged_item.get_inventory_item(), _item_drag_start_rotated, pos)
	_dragged_item.position = _item_drag_start_position

func set_hovered_inventory(inventory : UIInventory):
	_hovered_inventory = inventory
	if _dragged_item:
		_dragged_item.material = outline_material

func set_hovered_item(ui_item : UIItem):
	_hovered_item = ui_item
	
	if _dragged_item == null:
		if _item_info != null:
			_item_info.queue_free()
			_item_info = null
		_item_info = UIInfoBox.create_info_box(_hovered_item, _hovered_item.global_position + Vector2(16.0, 0.0))
		_item_info.display_item_info(ui_item)

func clear_hovered_item_info_box():
	if _item_info != null:
		_item_info.queue_free()
		_item_info = null

func unselect_hovered_inventory():
	_hovered_inventory = null
	if _dragged_item:
		_dragged_item.material = null

func add_item_to_inventory(ui_item : UIItem, is_rotated : bool, pos : Vector2i, inventory : UIInventory):
	ui_item.reparent(inventory)
	inventory.add_item(ui_item.get_inventory_item(), is_rotated, pos)
	(
		func():
			ui_item.global_position = inventory.global_position + pos * 16.0
			if ui_item.is_rotated():
				ui_item.global_position.y += ui_item.size.x
				ui_item.rotation = -PI / 2
	).call_deferred()
	ui_item.name = "%s-%d-%d" % [ui_item.get_item().name, pos.x, pos.y]
	ui_item.emit_item_changed_inventory(inventory)

func spawn_item(item_name : String, metadata : Dictionary = {}) -> UIItem:
	var ui_item = item_template.instantiate() as UIItem
	ui_item.initialize(item_name, metadata)
	
	return ui_item

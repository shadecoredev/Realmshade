extends RefCounted
class_name Item

static var _loaded_items : Dictionary[String, Item] = {}

@export var name : String
@export var texture : Texture2D

var _path : String

static func load(item_name : String, data_source_paths : PackedStringArray = GameManager.data_source_paths) -> Item:
	if item_name.is_empty():
		return null

	if item_name in _loaded_items:
		return _loaded_items[item_name]
		
	for source_path in data_source_paths:
		if DirAccess.open(source_path + "items/" + item_name) != null:
			var item = Item.new()
			item.set_path(source_path + "items/" + item_name + "/" + item_name + ".json")
			item.name = item_name
			item.texture = load(source_path + "items/" + item_name + "/" + item_name + ".png")
			
			_loaded_items[item_name] = item
			
			return item
	
	return null

func get_size(is_rotated : bool) -> Vector2i:
	var item_size : Vector2i = Vector2i.ZERO
	var texture_size = texture.get_size()
	
	if is_rotated:
		item_size = Vector2i(
			round(texture_size.y / 16.0),
			round(texture_size.x / 16.0),
		)
	else:
		item_size = Vector2i(
			round(texture_size.x / 16.0),
			round(texture_size.y / 16.0),
		)

	return item_size

func set_path(path : String):
	_path = path

func get_path() -> String:
	return _path

@tool
extends Node
class_name GameFileVerifier

@export_tool_button("Verify") var verify = _verify

var _item_pool : PackedStringArray = []

var _valid_event_types : PackedStringArray = [
			"free_reward",
			"fight",
			"crafting_station"
		]

var _valid_item_tags : PackedStringArray = [
	"melee",
	"magic",
	"ranged",
	"explosive",
	"plant",
	"currency",
	"gem",
	"jewelry",
	"apparel",
	"armor",
	"rune",
	"potion"
]

var _unused_items : PackedStringArray = []

var _events_by_levels : Array[PackedStringArray] = []
var _events_range_start : Array[PackedStringArray] = []
var _events_range_end : Array[PackedStringArray] = []

var _fights_by_levels : Array[PackedStringArray] = []
var _fights_range_start : Array[PackedStringArray] = []
var _fights_range_end : Array[PackedStringArray] = []

func _ready():
	_verify()

func _verify():
	for source_path in GameManager.data_source_paths:
		_verify_items(source_path)
	_unused_items = _item_pool.duplicate()
	for source_path in GameManager.data_source_paths:
		_verify_events(source_path)
	
	if !_unused_items.is_empty():
		print("Detected %d unobtainable items: " % [_unused_items.size()])
		print("\n".join(_unused_items))

func _verify_items(source_path : String):
	var item_root_path = source_path + "items/"

	var item_root_dir = DirAccess.open(item_root_path)
	
	var item_dirs = item_root_dir.get_directories()
	
	for item_dir in item_dirs:
		_verify_item(item_root_path + item_dir + "/", item_dir)

func _verify_item(path : String, item_name : String):
	var item_json_path = path + item_name + ".json"
	
	var file = FileAccess.open(item_json_path, FileAccess.READ)
	
	if file == null:
		printerr("Error opening data json for item %s." % path)
		return

	var json = JSON.parse_string(file.get_as_text())
	
	if json == null:
		printerr("Error parsing json for item %s" % path)
		return

	if "name" not in json:
		printerr("Key \"name\" not found for item %s" % path)
	elif json.name != item_name:
		printerr("Key \"name\" (%s) doesn't match file name for item %s" % [json.name, path + item_name])
	
	var texture = load(path + item_name + ".png") as Texture2D

	if texture == null:
		printerr("Error opening texture for item %s." % path)
		return

	if texture.get_width() % 16 != 0:
		printerr("Texture width doesn't match 16x16 dimensions for item %s" % path)
	if texture.get_height() % 16 != 0:
		printerr("Texture width doesn't match 16x16 dimensions for item %s" % path)
	
	if "width" not in json:
		printerr("Key \"width\" not found for item %s" % path)
	elif json.width != floor(float(texture.get_width()) / 16.0):
		printerr("Key \"width\" doesn't match texture width for item %s" % path)
		
	if "height" not in json:
		printerr("Key \"height\" not found for item %s" % path)
	elif json.height != floor(float(texture.get_height()) / 16.0):
		printerr("Key \"height\" doesn't match texture width for item %s" % path)
	
	if "tags" in json:
		for tag in json["tags"]:
			if tag not in _valid_item_tags:
				printerr("Item tag \"%s\" is not present in valid tags list for item %s" % [tag, path])
	
	_item_pool.append(item_name)


func _verify_events(source_path : String):
	var event_root_path = source_path + "events/"

	var event_root_dir = DirAccess.open(event_root_path)
	
	var event_dirs = event_root_dir.get_directories()
	
	for event_dir in event_dirs:
		if event_dir not in _valid_event_types:
			printerr("Event directory doesn't match valid event types for event %s" % (event_root_path + event_dir + "/"))
			
		var events_subdir = DirAccess.open(event_root_path + event_dir + "/")
		for event in events_subdir.get_files():
			_verify_event(event_root_path + event_dir + "/" + event, event_dir)

func _verify_event(source_path : String, event_dir : String):
	var file = FileAccess.open(source_path, FileAccess.READ)
	
	if file == null:
		printerr("Error opening data json for event %s." % source_path)
		return

	var json = JSON.parse_string(file.get_as_text())
	
	if json == null:
		printerr("Error parsing json for event %s" % source_path)
		return

	var filename = source_path.get_file().get_basename()
	if "name" not in json:
		printerr("Key \"name\" not found for event %s" % source_path)
	elif json.name != filename:
		printerr("Key \"name\" doesn't match file name \"%s\" for event %s" % [json.name, filename])
	
	if "type" not in json:
		printerr("Key \"type\" not found for event %s" % source_path)
		return
	elif json.type != event_dir:
		printerr("Event type doesn't match directory name %s" % source_path)
		return

	if json.type == "free_reward":
		if "rewards" not in json:
			printerr("Key \"rewards\" not found for event %s" % source_path)
			return

		if json.rewards is not Array:
			printerr("Key \"rewards\" must be an array for event %s" % source_path)
			return
		
		for reward in json.rewards:
			if reward not in _item_pool:
				printerr("Event reward \"%s\" not recognized for event %s" % [reward, source_path])
				return
			_item_used(reward)

	elif json.type == "fight":
		if "inventory" not in json:
			printerr("Key \"inventory\" not found for event %s" % source_path)
			return
		if "items" not in json["inventory"]:
			printerr("Key \"inventory\" not found for event %s" % source_path)
			return
		for item in json["inventory"]["items"]:
			if item.name not in _item_pool:
				printerr("Fight item \"%s\" not recognized for event %s" % [item, source_path])
				return
			_item_used(item.name)

	if "level_range_start" in json:
		if "level_range_end" in json:
			if _events_by_levels.size() < json.level_range_end + 1:
				_events_by_levels.resize(json.level_range_end + 1)
			for i in range(json.level_range_start, json.level_range_end + 1):
				if _events_by_levels[i] == null:
					_events_by_levels[i] = PackedStringArray()
				_events_by_levels[i].append(source_path)
				
			if json.type == "fight":
				if _fights_by_levels.size() < json.level_range_end + 1:
					_fights_by_levels.resize(json.level_range_end + 1)
				for i in range(json.level_range_start, json.level_range_end + 1):
					if _fights_by_levels[i] == null:
						_fights_by_levels[i] = PackedStringArray()
					_fights_by_levels[i].append(source_path)
				
		else:
			if _events_range_start.size() < json.level_range_start + 1:
				_events_range_start.resize(json.level_range_start + 1)
			if _events_range_start[json.level_range_start] == null:
				_events_range_start[json.level_range_start] = PackedStringArray()
			_events_range_start[json.level_range_start].append(source_path)
			
			if json.type == "fight":
				if _fights_range_start.size() < json.level_range_start + 1:
					_fights_range_start.resize(json.level_range_start + 1)
				if _fights_range_start[json.level_range_start] == null:
					_fights_range_start[json.level_range_start] = PackedStringArray()
				_fights_range_start[json.level_range_start].append(source_path)
			

	elif "level_range_end" in json and not "level_range_start" not in json:
		if _events_range_end.size() < json.level_range_end + 1:
			_events_range_end.resize(json.level_range_end + 1)
		if _events_range_end[json.level_range_end] == null:
			_events_range_end[json.level_range_end] = PackedStringArray()
		_events_range_end[json.level_range_end].append(source_path)
		
		if json.type == "fight":
			if _fights_range_end.size() < json.level_range_end + 1:
				_fights_range_end.resize(json.level_range_end + 1)
			if _fights_range_end[json.level_range_end] == null:
				_fights_range_end[json.level_range_end] = PackedStringArray()
			_fights_range_end[json.level_range_end].append(source_path)

func _item_used(item_name : String):
	var unused_item_id = _unused_items.find(item_name)
	if unused_item_id != -1:
		_unused_items.remove_at(unused_item_id)

func get_event_list_by_level(level : int) -> PackedStringArray:
	var events = PackedStringArray()
	
	if level < _events_by_levels.size() and _events_by_levels[level] != null:
		events.append_array(_events_by_levels[level])
	
	for i in range(0, level):
		if i >= _events_range_start.size() or _events_range_start[i] == null:
			continue
		
		events.append_array(_events_range_start[i])
		
	for i in range(level, _events_range_end.size()):
		if i >= _events_range_end.size() or _events_range_end[i] == null:
			continue
		events.append_array(_events_range_end[i])
	
	return events
	
func get_fight_list_by_level(level : int) -> PackedStringArray:
	var fights = PackedStringArray()
	
	if level < _fights_by_levels.size() and _fights_by_levels[level] != null:
		fights.append_array(_fights_by_levels[level])
	
	for i in range(0, level):
		if i >= _fights_range_start.size() or _fights_range_start[i] == null:
			continue
		
		fights.append_array(_fights_range_start[i])
		
	for i in range(level, _fights_range_end.size()):
		if i >= _fights_range_end.size() or _fights_range_end[i] == null:
			continue
		fights.append_array(_fights_range_end[i])
	
	return fights
	
	
func list_valid_items() -> PackedStringArray:
	return _item_pool

func list_valid_events() -> PackedStringArray:
	var result = PackedStringArray()
	for event_pool in _events_by_levels:
		for event in event_pool:
			if event not in result:
				result.append(event)
	for event_pool in _events_range_end:
		for event in event_pool:
			if event not in result:
				result.append(event)
	for event_pool in _events_range_start:
		for event in event_pool:
			if event not in result:
				result.append(event)
	return result

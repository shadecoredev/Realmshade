extends RefCounted
class_name InstantiateByName

static var _saved_script_paths : Dictionary[String, String] = {}

static func get_class_by_name(class_name_string : String):
	if class_name_string in _saved_script_paths:
		var script = load(_saved_script_paths[class_name_string]) as Script
		if script:
			return script

	for global_class_info in ProjectSettings.get_global_class_list():
		if str(global_class_info["class"]) == class_name_string:
			var script_path = global_class_info["path"]
			var script = load(script_path) as Script
			_saved_script_paths[class_name_string] = script_path
			if script:
				return script

static func instantiate(class_name_string : String):
	return get_class_by_name(class_name_string).new()

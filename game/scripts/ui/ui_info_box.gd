extends Control
class_name UIInfoBox

@export var title_label : Label
@export var main_label : RichTextLabel

static var _info_boxes : Array[UIInfoBox] = []

static func clear_info_boxes():
	for box in _info_boxes:
		box.queue_free()

static func create_info_box(parent : Node, spawn_position : Vector2) -> UIInfoBox:
	var info_box = load("res://scenes/templates/info_box.tscn").instantiate() as UIInfoBox
	info_box.top_level = true
	parent.add_child(info_box)
	if parent is Control:
		var offset = (parent.size.x) * cos(parent.rotation) - (parent.size.y) * sin(parent.rotation) - 16.0
		
		info_box.global_position = spawn_position + Vector2(
			offset - (info_box.size.x + offset + 16.0) * float(spawn_position.x > parent.get_viewport().get_camera_2d().global_position.x),
			(parent.size.x) * sin(parent.rotation)
		)
	else:
		info_box.global_position = spawn_position

	_info_boxes.append(info_box)
	return info_box

func display_item_info(ui_item : UIItem):
	if ui_item == null:
		return
	if title_label:
		title_label.text = ui_item.get_item().name.capitalize()

	var path = ui_item.get_item().get_path()
	var item_file = FileAccess.open(path, FileAccess.READ)
	if item_file == null:
		printerr("Error reading item json: %s" % path)
		return

	var item_json = JSON.parse_string(item_file.get_as_text())

	if main_label:
		var fight_instance : FightInventoryInstance = null
		if FightManager.get_instance().is_currently_fighting():
			fight_instance = FightManager.get_instance().get_item_source_instance(ui_item.get_inventory_item())
		main_label.text = parse_item_description_from_json(item_json, fight_instance)
	
	var rect = get_camera_zoomed_bounds_rect()
	global_position = global_position.clamp(rect.position, rect.end - size + Vector2.UP * 14 * (main_label.text.split("\n", false).size() - 1))

func parse_item_description_from_json(item_json : Dictionary, fight_instance : FightInventoryInstance) -> String:
	var text = ""
	
	if "effects" not in item_json:
		return "No effects"
		
	if item_json["effects"] is not Array:
		return "No effects"

	for effect_json in item_json["effects"]:
		match effect_json["type"]:
			"cooldown":
				if "time" in effect_json:
					if abs(fmod(effect_json["time"], 1.0)) < 0.1:
						text += "Cooldown %ds" % effect_json["time"]
					else:
						text += "Cooldown %.1fs" % effect_json["time"]
					if "charges" in effect_json:
						text += " with [color=#71413b]%d[/color][img]res://assets/textures/icons/charges.png[/img] %s" % [effect_json["charges"], "charge" if effect_json["charges"] == 1 else "charges"]
					text += ":\n"
				text += get_effects_text(effect_json, fight_instance)
			"start":
				text += "Start:\n"
				text += get_effects_text(effect_json, fight_instance)

	if "tags" in item_json:
		text += "[right][color=#333941]"
		for tag in item_json["tags"]:
			text += "%s " % str(tag).capitalize()
		text += "[/color][/right]"
	
	return text

func get_effects_text(effect_json : Dictionary, fight_instance : FightInventoryInstance) -> String:
	var text = ""
	
	var fury = fight_instance.get_status_effect_value("fury") if fight_instance else 0.0

	if "shock" in effect_json:
		text += "\tInflict [color=#fef3c0]%d[/color][img]res://assets/textures/icons/shock.png[/img] shock\n" % effect_json["shock"]
	if "self_shock" in effect_json:
		text += "\tSuffer [color=#fef3c0]%d[/color][img]res://assets/textures/icons/shock.png[/img] shock\n" % effect_json["self_shock"]

	if "fire" in effect_json:
		text += "\tInflict [color=#f9a31b]%d[/color][img]res://assets/textures/icons/fire.png[/img] fire\n" % effect_json["fire"]
	if "self_fire" in effect_json:
		text += "\tSuffer [color=#f9a31b]%d[/color][img]res://assets/textures/icons/fire.png[/img] fire\n" % effect_json["self_fire"]

	if "poison" in effect_json:
		text += "\tInflict [color=#1a7a3e]%d[/color][img]res://assets/textures/icons/poison.png[/img] poison\n" % effect_json["poison"]
	if "self_poison" in effect_json:
		text += "\tSuffer [color=#1a7a3e]%d[/color][img]res://assets/textures/icons/poison.png[/img] poison\n" % effect_json["self_poison"]

	if "doom" in effect_json:
		text += "\tInflict [color=#403353]%d[/color][img]res://assets/textures/icons/doom.png[/img] doom\n" % effect_json["doom"]
	if "self_doom" in effect_json:
		text += "\tSuffer [color=#403353]%d[/color][img]res://assets/textures/icons/doom.png[/img] doom\n" % effect_json["self_doom"]

	if "damage" in effect_json:
		if fury > 0.0:
			text += "\tDeal [color=#73172d]%d(%d)[/color][img]res://assets/textures/icons/damage.png[/img] damage\n" % [effect_json["damage"] * (1.0 + fury / 100.0), effect_json["damage"]]
		else:
			text += "\tDeal [color=#73172d]%d[/color][img]res://assets/textures/icons/damage.png[/img] damage\n" % effect_json["damage"]

	if "block" in effect_json:
		text += "\tGain [color=#8b93af]%d[/color][img]res://assets/textures/icons/block.png[/img] block\n" % effect_json["block"]

	if "heal" in effect_json:
		text += "\tHeal [color=#59c135]%d[/color][img]res://assets/textures/icons/heal.png[/img] health\n" % effect_json["heal"]

	if "health" in effect_json:
		text += "\tGain [color=#b4202a]%d[/color][img]res://assets/textures/icons/health.png[/img] health\n" % effect_json["health"]
	if "self_damage" in effect_json:
		text += "\tSuffer [color=#b4202a]%d[/color][img]res://assets/textures/icons/health.png[/img] damage\n" % effect_json["self_damage"]

	if "regeneration" in effect_json:
		text += "\tGain [color=#e86a73]%d[/color][img]res://assets/textures/icons/regeneration.png[/img] regeneration\n" % effect_json["regeneration"]
		
	if "purity" in effect_json:
		text += "\tGain [color=#20d6c7]%d[/color][img]res://assets/textures/icons/purity.png[/img] purity\n" % effect_json["purity"]
		
	if "fury" in effect_json:
		text += "\tGain [color=#df3e23]%d[/color][img]res://assets/textures/icons/fury.png[/img] fury\n" % effect_json["fury"]
		
	if "thorns" in effect_json:
		text += "\tGain [color=#5a4e44]%d[/color][img]res://assets/textures/icons/thorns.png[/img] thorns\n" % effect_json["thorns"]

	return text


func get_camera_zoomed_bounds_rect() -> Rect2:
	var camera = get_viewport().get_camera_2d()
	var viewport_size = get_viewport_rect().size
	var camera_zoom = camera.zoom
	var zoomed_visible_size = viewport_size / camera_zoom
	var camera_center = camera.get_screen_center_position()
	var top_left = camera_center - (zoomed_visible_size / 2.0)
	return Rect2(top_left, zoomed_visible_size)

func remove():
	_info_boxes.remove_at(_info_boxes.find(self))
	queue_free()

extends Control
class_name UIInfoBox

@export var title_label : Label
@export var main_label : RichTextLabel

static var _info_boxes : Array[UIInfoBox] = []

var initial_size : Vector2

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
				text += "[center]" + get_effects_text(effect_json, fight_instance) + "[/center]"
			"start":
				text += "Start:\n"
				text += "[center]" + get_effects_text(effect_json, fight_instance) + "[/center]"

	if "tags" in item_json:
		text += "[right][color=#333941]"
		for tag in item_json["tags"]:
			text += "%s " % str(tag).capitalize()
		text += "[/color][/right]"
	
	return text

func make_wider(new_width : float):
	custom_minimum_size.x = new_width

func _get_modified_value_text(value : float, effect_name : String, fight_instance : FightInventoryInstance) -> String:
	if fight_instance == null:
		return "%d" % value
	
	var modified_value : float = value
	if effect_name == "damage":
		modified_value += fight_instance.get_status_effect_value("fury")

	if effect_name.begins_with("self_"):
		effect_name = effect_name.right(effect_name.length() - 5)
		modified_value *= 100/(100.0 + fight_instance.get_status_effect_value(effect_name+"_resistance"))
	else:
		modified_value *= (1.0 + fight_instance.get_status_effect_value(effect_name + "_power")/100.0)
	
	if int(modified_value) == int(value):
		return "%d" % value
	else:
		return "%d(%d)" % [modified_value, value]

func get_effects_text(effect_json : Dictionary, fight_instance : FightInventoryInstance) -> String:
	var text = ""

	for key in effect_json:
		if key.ends_with("_resistance"):
			var effect_name = key.left(key.length() - 11)
			text += "Gain [color=#c7b08b]%d[/color][img]res://assets/textures/icons/resistance.png[/img][img]res://assets/textures/icons/%s.png[/img] %s resistance\n" % [effect_json[key], effect_name, effect_name]
			#make_wider(240)
			continue
		if key.ends_with("_power"):
			var effect_name = key.left(key.length() - 6)
			text += "Gain [color=#477d85]%d[/color][img]res://assets/textures/icons/power.png[/img][img]res://assets/textures/icons/%s.png[/img] %s power \n" % [effect_json[key], effect_name, effect_name]
			continue

		match key:
			"shock":
				text += "Inflict [color=#fef3c0]%s[/color][img]res://assets/textures/icons/shock.png[/img] shock\n" % _get_modified_value_text(effect_json["shock"], "shock", fight_instance)
			"self_shock":
				text += "Suffer [color=#fef3c0]%s[/color][img]res://assets/textures/icons/shock.png[/img] shock\n" % _get_modified_value_text(effect_json["self_shock"], "self_shock", fight_instance)

			"fire":
				text += "Inflict [color=#f9a31b]%s[/color][img]res://assets/textures/icons/fire.png[/img] fire\n" % _get_modified_value_text(effect_json["fire"], "fire", fight_instance)
			"self_fire":
				text += "Suffer [color=#f9a31b]%s[/color][img]res://assets/textures/icons/fire.png[/img] fire\n" % _get_modified_value_text(effect_json["self_fire"], "self_fire", fight_instance)

			"poison":
				text += "Inflict [color=#1a7a3e]%s[/color][img]res://assets/textures/icons/poison.png[/img] poison\n" % _get_modified_value_text(effect_json["poison"], "poison", fight_instance)
			"self_poison":
				text += "Suffer [color=#1a7a3e]%s[/color][img]res://assets/textures/icons/poison.png[/img] poison\n" % _get_modified_value_text(effect_json["self_poison"], "self_poison", fight_instance)

			"acid":
				text += "Inflict [color=#9cdb43]%s[/color][img]res://assets/textures/icons/acid.png[/img] acid\n" % _get_modified_value_text(effect_json["acid"], "acid", fight_instance)
			"self_acid":
				text += "Suffer [color=#9cdb43]%s[/color][img]res://assets/textures/icons/acid.png[/img] acid\n" % _get_modified_value_text(effect_json["self_acid"], "self_acid", fight_instance)

			"doom":
				text += "Inflict [color=#403353]%s[/color][img]res://assets/textures/icons/doom.png[/img] doom\n" % _get_modified_value_text(effect_json["doom"], "doom", fight_instance)
			"self_doom":
				text += "Suffer [color=#403353]%s[/color][img]res://assets/textures/icons/doom.png[/img] doom\n" % _get_modified_value_text(effect_json["self_doom"], "self_doom", fight_instance)

			"damage":
				text += "Deal [color=#73172d]%s[/color][img]res://assets/textures/icons/damage.png[/img] damage\n" % _get_modified_value_text(effect_json["damage"], "damage", fight_instance)

			"block":
				text += "Gain [color=#8b93af]%s[/color][img]res://assets/textures/icons/block.png[/img] block\n" % _get_modified_value_text(effect_json["block"], "block", fight_instance)

			"absorption":
				text += "Gain [color=#ffd541]%s[/color][img]res://assets/textures/icons/absorption.png[/img] absorption\n" % _get_modified_value_text(effect_json["absorption"], "absorption", fight_instance)

			"barrier":
				text += "Gain [color=#a6fcdb]%s[/color][img]res://assets/textures/icons/barrier.png[/img] barrier\n" % _get_modified_value_text(effect_json["barrier"], "barrier", fight_instance)

			"restore_barrier":
				text += "Restore [color=#a6fcdb]%d[/color][img]res://assets/textures/icons/barrier.png[/img] barrier\n" % int(effect_json["restore_barrier"])

			"restore_barrier_percent":
				text += "Restore [color=#a6fcdb]%d%%[/color][img]res://assets/textures/icons/barrier.png[/img] barrier\n" % int(effect_json["restore_barrier_percent"])

			"heal":
				text += "Heal [color=#59c135]%s[/color][img]res://assets/textures/icons/heal.png[/img] health\n" % _get_modified_value_text(effect_json["heal"], "heal", fight_instance)

			"health":
				text += "Gain [color=#b4202a]%d[/color][img]res://assets/textures/icons/health.png[/img] health\n" % effect_json["health"]
			"self_damage":
				text += "Suffer [color=#b4202a]%d[/color][img]res://assets/textures/icons/health.png[/img] damage\n" % effect_json["self_damage"]

			"regeneration":
				text += "Gain [color=#e86a73]%s[/color][img]res://assets/textures/icons/regeneration.png[/img] regeneration\n" % _get_modified_value_text(effect_json["regeneration"], "regeneration", fight_instance)

			"purity":
				text += "Gain [color=#20d6c7]%s[/color][img]res://assets/textures/icons/purity.png[/img] purity\n" % _get_modified_value_text(effect_json["purity"], "purity", fight_instance)

			"fury":
				text += "Gain [color=#df3e23]%s[/color][img]res://assets/textures/icons/fury.png[/img] fury\n" % _get_modified_value_text(effect_json["fury"], "fury", fight_instance)

			"thorns":
				text += "Gain [color=#5a4e44]%s[/color][img]res://assets/textures/icons/thorns.png[/img] thorns\n" % _get_modified_value_text(effect_json["thorns"], "thorns", fight_instance)


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

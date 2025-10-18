extends Node
class_name FightInventoryInstance

var enemy : FightInventoryInstance

var _valid_effects : PackedStringArray = [
	"cooldown",
	"start"
]

var health : float = 100.0
var current_health : float = 100.0

var defences : Array[Defence] = []
var ailments : Array[Ailment] = []
var status_effects : Array[StatusEffect] = []

var cooldown_effects : Array = []
var start_effects : Array = []

var _source_inventory : Inventory

func _init():
	health = 100.0
	current_health = 100.0
	defences.clear()
	ailments.clear()
	status_effects.clear()
	cooldown_effects.clear()
	start_effects.clear()

func start():
	for effect in start_effects:
		_apply_effect(effect)

func tick():
	for effect in cooldown_effects:
		if "charges" not in effect or int(effect["charges"]) > 0:
			effect["cooldown"] += 0.05
		else:
			effect["cooldown"] = 0.0

		if effect["cooldown"] >= effect["time"]:
			effect["cooldown"] -= effect["time"]
			if "charges" in effect:
				if int(effect["charges"]) > 0:
					effect["charges"] -= 1
					_apply_effect(effect)
			else:
				_apply_effect(effect)

	for i in range(status_effects.size()-1, -1, -1):
		var status_effect = status_effects[i]
		status_effect.tick(self, enemy)
		
		if status_effect.value <= 0.0:
			status_effects.remove_at(i)

	for i in range(ailments.size()-1, -1, -1):
		var ailment = ailments[i]
		ailment.tick(self, enemy)
		
		if ailment.value <= 0.0:
			ailments.remove_at(i)

func get_source_inventory() -> Inventory:
	return _source_inventory

func initialize(inventory : Inventory):
	_source_inventory = inventory
	
	for item in inventory.get_items():
		var path = item.get_item().get_path()
		var item_file = FileAccess.open(path, FileAccess.READ)
		if item_file == null:
			printerr("Error reading item json: %s" % path)
			continue

		var item_json = JSON.parse_string(item_file.get_as_text())
		
		if item_json == null:
			printerr("Error parsing item json: %s" % path)
			continue

		if "effects" not in item_json:
			continue

		if item_json["effects"] is not Array:
			printerr("Item effects value is not array: %s" % path)
			continue

		for effect in item_json["effects"]:
			effect["source"] = item
			_parse_effect(effect)

func _parse_effect(effect_json : Dictionary):
	if "type" not in effect_json:
		printerr("Key \"type\" not found in item json: %s" % str(effect_json))
		return

	if effect_json["type"] not in _valid_effects:
		printerr("Invalid \"type\" found in item json: %s" % str(effect_json))
		return

	match effect_json["type"]:
		"cooldown":
			effect_json["cooldown"] = 0.0
			cooldown_effects.append(effect_json)
			
		"start":
			start_effects.append(effect_json)

func _apply_effect(effect_json : Dictionary):
	# Item effects

	if "damage" in effect_json:
		enemy.recieve_damage(effect_json["damage"] * (1.0 + get_status_effect_value("fury") / 100.0), "damage")
	if "self_damage" in effect_json:
		recieve_damage(effect_json["self_damage"], "self_damage")

	if "shock" in effect_json:
		enemy.recieve_ailment("shock", effect_json["shock"])
		enemy.recieve_damage(effect_json["shock"], "shock")
	if "self_shock" in effect_json:
		recieve_ailment("shock", effect_json["self_shock"])
		recieve_damage(effect_json["self_shock"], "shock")

	if "fire" in effect_json:
		enemy.recieve_ailment("fire", effect_json["fire"])
	if "self_fire" in effect_json:
		recieve_ailment("fire", effect_json["self_fire"])

	if "poison" in effect_json:
		enemy.recieve_ailment("poison", effect_json["poison"])
	if "self_poison" in effect_json:
		recieve_ailment("poison", effect_json["self_poison"])
		
	if "doom" in effect_json:
		enemy.recieve_status_effect("doom", effect_json["doom"])
	if "self_doom" in effect_json:
		recieve_status_effect("doom", effect_json["self_doom"])

	if "block" in effect_json:
		increase_defence("block", effect_json["block"])

	if "heal" in effect_json:
		heal(effect_json["heal"])

	if "health" in effect_json:
		health += effect_json["health"]
		current_health += effect_json["health"]

	if "regeneration" in effect_json:
		recieve_status_effect("regeneration", effect_json["regeneration"])
		
	if "purity" in effect_json:
		recieve_status_effect("purity", effect_json["purity"])
		
	if "fury" in effect_json:
		recieve_status_effect("fury", effect_json["fury"])

func increase_defence(defence_name : String, value : float):
	var index = defences.find_custom(func(d): return d.name == defence_name)
	if index == -1:
		var defence = InstantiateByName.instantiate(defence_name.capitalize())
		if defence != null and defence is Defence:
			defence.value = value
			defences.append(defence)
			defences.sort_custom(func(a, b): return a.priority < b.priority)
	else:
		defences[index].value += value

func recieve_ailment(ailment_name : String, value : float):
	var index = ailments.find_custom(func(d): return d.name == ailment_name)
	if index == -1:
		var ailment = InstantiateByName.instantiate(ailment_name.capitalize())
		if ailment != null and ailment is Ailment:
			ailment.value = value
			ailments.append(ailment)
	else:
		ailments[index].value += value

func recieve_status_effect(status_effect_name : String, value : float):
	var index = status_effects.find_custom(func(d): return d.name == status_effect_name)
	if index == -1:
		var status_effect = InstantiateByName.instantiate(status_effect_name.capitalize())
		if status_effect != null and status_effect is StatusEffect:
			status_effect.value = value
			status_effects.append(status_effect)
	else:
		status_effects[index].value += value

func heal(value : float):
	current_health += value
	
	if current_health > health:
		current_health = health

func get_defence_value(defence_name : String) -> float:
	var index = defences.find_custom(func(d): return d.name == defence_name)
	if index != -1:
		return defences[index].value
	return 0.0

func get_ailment_value(ailment_name : String) -> float:
	var index = ailments.find_custom(func(d): return d.name == ailment_name)
	if index != -1:
		return ailments[index].value
	return 0.0

func get_status_effect_value(status_effect_name : String) -> float:
	var index = status_effects.find_custom(func(d): return d.name == status_effect_name)
	if index != -1:
		return status_effects[index].value
	return 0.0

func recieve_damage(incoming_damage : float, damage_source : String):
	if damage_source == "damage":
		var thorns = get_status_effect_value("thorns")
		if thorns > 0.0:
			enemy.recieve_damage(thorns, "thorns")
	
	if defences.is_empty():
		current_health -= incoming_damage
		return
	
	for i in range(defences.size()-1, -1, -1):
		var defence = defences[i]
		incoming_damage = defence.apply_defence(incoming_damage, damage_source)

		if defence.value <= 0.0:
			defences.remove_at(i)

		if is_zero_approx(incoming_damage):
			return


	current_health -= incoming_damage

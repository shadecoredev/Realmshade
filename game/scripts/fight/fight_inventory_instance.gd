extends Node
class_name FightInventoryInstance

var enemy : FightInventoryInstance

static var valid_effects : PackedStringArray = [
	"cooldown",
	"start"
]

static var valid_suffixes : PackedStringArray = [
	"resistance",
	"power"
]

var health : float = 100.0
var current_health : float = 100.0

var defenses : Array[Defense] = []
var ailments : Array[Ailment] = []
var status_effects : Array[StatusEffect] = []

var cooldown_effects : Array = []
var start_effects : Array = []

var _source_inventory : Inventory

func _init():
	health = 100.0
	current_health = 100.0
	defenses.clear()
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
		
		if status_effect.value <= 0.5:
			status_effects.remove_at(i)

	for i in range(ailments.size()-1, -1, -1):
		var ailment = ailments[i]
		ailment.tick(self, enemy)
		
		if ailment.value <= 0.5:
			ailments.remove_at(i)
			
	for i in range(defenses.size()-1, -1, -1):
		var defense = defenses[i]
		defense.tick(self, enemy)
		
		if defense.value <= 0.5:
			defense.remove_at(i)

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

	if effect_json["type"] not in valid_effects:
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

	for key in effect_json.keys():
		match(key):
			"damage":
				enemy.recieve_damage(effect_json["damage"] + get_status_effect_value("fury"), "damage")
				continue

			"self_damage":
				recieve_damage(effect_json["self_damage"], "self_damage")
				continue

			"shock":
				enemy.recieve_ailment("shock", effect_json["shock"])
				enemy.recieve_damage(effect_json["shock"], "shock")
				continue

			"self_shock":
				recieve_ailment("shock", effect_json["self_shock"])
				recieve_damage(effect_json["self_shock"], "shock")
				continue

			"fire":
				enemy.recieve_ailment("fire", effect_json["fire"])
				continue

			"self_fire":
				recieve_ailment("fire", effect_json["self_fire"])
				continue

			"poison":
				enemy.recieve_ailment("poison", effect_json["poison"])
				continue
			"self_poison":
				recieve_ailment("poison", effect_json["self_poison"])
				continue
				
			"acid":
				enemy.recieve_ailment("acid", effect_json["acid"])
				continue

			"self_acid":
				recieve_ailment("acid", effect_json["self_acid"])
				continue

			"doom":
				enemy.recieve_status_effect("doom", effect_json["doom"])
				continue

			"self_doom":
				recieve_status_effect("doom", effect_json["self_doom"])
				continue

			"block":
				increase_defence("block", effect_json["block"])
				continue
				
			"absorption":
				increase_defence("absorption", effect_json["absorption"])
				continue
				
			"barrier":
				recieve_status_effect("maximum_barrier", effect_json["barrier"])
				increase_defence("barrier", effect_json["barrier"])
				continue
			
			"restore_barrier":
				var current_barrier = get_defence_value("barrier")
				var maximum_barrier = get_status_effect_value("maximum_barrier")
				increase_defence(
					"barrier",
					min(
						effect_json["restore_barrier"],
						maximum_barrier - current_barrier
					)
				)
				continue
			
			"restore_barrier_percent":
				var current_barrier = get_defence_value("barrier")
				var maximum_barrier = get_status_effect_value("maximum_barrier")
				increase_defence(
					"barrier",
					min(
						maximum_barrier * effect_json["restore_barrier_percent"] * 0.01,
						maximum_barrier - current_barrier
					)
				)
				continue

			"heal":
				heal(effect_json["heal"])
				continue

			"health":
				health += effect_json["health"]
				current_health += effect_json["health"]
				continue

			"regeneration":
				recieve_status_effect("regeneration", effect_json["regeneration"])
				continue

			"purity":
				recieve_status_effect("purity", effect_json["purity"])
				continue

			"fury":
				recieve_status_effect("fury", effect_json["fury"])
				continue
		
		for suffix in valid_suffixes:
			if key.ends_with(suffix):
				recieve_suffix_status_effect(suffix, key.left(key.length()-suffix.length()-1), effect_json[key])
				continue

func increase_defence(defence_name : String, value : float):
	value *= (100.0 + get_status_effect_value(defence_name+"_power"))/100.0

	var index = defenses.find_custom(func(d): return d.name == defence_name)
	if index == -1:
		var defense = InstantiateByName.instantiate(defence_name.capitalize().replace(" ", ""))
		if defense != null and defense is Defense:
			defense.value = value
			defenses.append(defense)
			defenses.sort_custom(func(a, b): return a.priority < b.priority)
	else:
		defenses[index].value += value

func recieve_ailment(ailment_name : String, value : float):
	value *= 100/(100.0 + get_status_effect_value(ailment_name+"_resistance"))
	value *= (100.0 + enemy.get_status_effect_value(ailment_name+"_power"))/100.0
	
	var index = ailments.find_custom(func(a): return a.name == ailment_name)
	if index == -1:
		var ailment = InstantiateByName.instantiate(ailment_name.capitalize().replace(" ", ""))
		if ailment != null and ailment is Ailment:
			ailment.value = value
			ailments.append(ailment)
	else:
		ailments[index].value += value

func recieve_status_effect(status_effect_name : String, value : float):
	value *= 100/(100.0 + get_status_effect_value(status_effect_name+"_resistance"))
	value *= (100.0 + enemy.get_status_effect_value(status_effect_name+"_power"))/100.0

	var index = status_effects.find_custom(func(s): return s.name == status_effect_name)
	if index == -1:
		var status_effect = InstantiateByName.instantiate(status_effect_name.capitalize().replace(" ", ""))
		if status_effect != null and status_effect is StatusEffect:
			status_effect.value = value
			status_effects.append(status_effect)
	else:
		status_effects[index].value += value

func recieve_suffix_status_effect(suffix : String, effect_name : String, value : float):
	var index = status_effects.find_custom(func(s): return s.name == effect_name + "_" + suffix)
	if index == -1:
		var status_effect = InstantiateByName.instantiate(suffix.capitalize().replace(" ", ""))
		if status_effect != null and status_effect is StatusEffect:
			status_effect.value = value
			status_effect.name = effect_name + "_" + suffix
			status_effects.append(status_effect)
	else:
		status_effects[index].value += value

func heal(value : float):
	value *= get_status_effect_value("heal_power")/100.0

	current_health += value
	
	if current_health > health:
		current_health = health

func get_defence_value(defense_name : String) -> float:
	var index = defenses.find_custom(func(d): return d.name == defense_name)
	if index != -1:
		return defenses[index].value
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
	incoming_damage *= 100/(100.0 + get_status_effect_value(damage_source+"_resistance"))
	incoming_damage *= (100.0 + enemy.get_status_effect_value(damage_source+"_power"))/100.0
	
	if damage_source == "damage":
		var thorns = get_status_effect_value("thorns")
		if thorns > 0.0:
			enemy.recieve_damage(thorns, "thorns")
	
	if defenses.is_empty():
		current_health -= incoming_damage * (1.0 - 0.5 * float(damage_source == "acid"))
		return
	
	for i in range(defenses.size()-1, -1, -1):
		var defense = defenses[i]
		if damage_source == "acid":
			incoming_damage = defense.apply_defence(incoming_damage * 2.0, damage_source) / 2.0
		else:
			incoming_damage = defense.apply_defence(incoming_damage, damage_source)

		if defense.value < 0.5:
			defenses.remove_at(i)

		if is_zero_approx(incoming_damage):
			return

	current_health -= incoming_damage * (1.0 - 0.5 * float(damage_source == "acid"))

extends Control
class_name UIHealthDisplay

@export var health_bar : TextureRect
@export var current_health_bar : TextureRect

@export var block_bar : TextureRect
@export var barrier_bar : TextureRect
@export var current_barrier_bar : TextureRect
@export var absorption_bar : TextureRect

@export var shock_bar : TextureRect
@export var fire_bar : TextureRect
@export var poison_bar : TextureRect
@export var acid_bar : TextureRect
@export var doom_bar : TextureRect

@export var status_effect_container : HFlowContainer
@export var ailment_container : HFlowContainer
@export var defense_container : HFlowContainer

func initialize(inventory : UIInventory, inventory_effects : FightInventoryInstance):
	for effect in inventory_effects.cooldown_effects:
		if "source" in effect:
			var pos = effect["source"].get_position()
			var source_item : UIItem = inventory.get_node("%s-%d-%d" % [effect["source"].get_item().name, pos.x, pos.y])
			if source_item:
				source_item.set_material(load("res://assets/materials/outline/partial_outline_shader.tres").duplicate())
				source_item.material.set_shader_parameter("rotation", 1.57079632679 * float(source_item.is_rotated()))
			else:
				printerr("Unable to initialize effect visual for item %s at %d, %d." % [effect["source"].get_item().name, pos.x, pos.y])
	
	var new_visual = load("res://scenes/templates/status_effect_template.tscn").instantiate()
	new_visual.get_child(0).modulate = Color("b4202a")
	new_visual.get_child(1).texture = load("res://assets/textures/icons/health.png")
	new_visual.name = "health"
	defense_container.add_child(new_visual)
	

func update_visuals(inventory : UIInventory, fight_inventory_instance : FightInventoryInstance):
	for effect in fight_inventory_instance.cooldown_effects:
		if "source" in effect:
			var pos = effect["source"].get_position()
			var source_item : UIItem = inventory.get_node("%s-%d-%d" % [effect["source"].get_item().name, pos.x, pos.y])
			if source_item and source_item.material:
				source_item.material.set_shader_parameter("progress", effect["cooldown"]/effect["time"])
	
	for status_effect in fight_inventory_instance.status_effects:
		if status_effect.is_hidden:
			continue
		if !status_effect_container.has_node(status_effect.name):
			var new_visual = load("res://scenes/templates/status_effect_template.tscn").instantiate()
			new_visual.get_child(0).modulate = status_effect.get_color()
			new_visual.get_child(1).texture = load("res://assets/textures/icons/" + status_effect.name + ".png")
			new_visual.name = status_effect.name
			status_effect_container.add_child(new_visual)
		var visual = status_effect_container.get_node(status_effect.name)
		visual.get_child(0).text = str(int(ceil(status_effect.value)))
	
	for status_effect_visual in status_effect_container.get_children():
		if fight_inventory_instance.status_effects.find_custom(func(s): return s.name == status_effect_visual.name) == -1:
			status_effect_visual.queue_free()
	
	for ailment in fight_inventory_instance.ailments:
		if ailment.is_hidden:
			continue
		if !ailment_container.has_node(ailment.name):
			var new_visual = load("res://scenes/templates/status_effect_template.tscn").instantiate()
			new_visual.get_child(0).modulate = ailment.get_color()
			new_visual.get_child(1).texture = load("res://assets/textures/icons/" + ailment.name + ".png")
			new_visual.name = ailment.name
			ailment_container.add_child(new_visual)
		var visual = ailment_container.get_node(ailment.name)
		visual.get_child(0).text = str(int(ceil(ailment.value)))
	
	for ailment_visual in ailment_container.get_children():
		if fight_inventory_instance.ailments.find_custom(func(s): return s.name == ailment_visual.name) == -1:
			ailment_visual.queue_free()
	
	for defense in fight_inventory_instance.defenses:
		if !defense_container.has_node(defense.name):
			var new_visual = load("res://scenes/templates/status_effect_template.tscn").instantiate()
			new_visual.get_child(0).modulate = defense.get_color()
			new_visual.get_child(1).texture = load("res://assets/textures/icons/" + defense.name + ".png")
			new_visual.name = defense.name
			defense_container.add_child(new_visual)
		var visual = defense_container.get_node(defense.name)
		visual.get_child(0).text = str(int(ceil(defense.value)))
	
	var maximum_barrier = fight_inventory_instance.get_status_effect_value("maximum_barrier")
	var barrier = fight_inventory_instance.get_defence_value("barrier")

	for defense_visual in defense_container.get_children():
		if defense_visual.name == "health":
			defense_visual.get_child(0).text = "%d/%d" % [ceil(fight_inventory_instance.current_health), ceil(fight_inventory_instance.health)]
		elif defense_visual.name == "barrier":
			defense_visual.get_child(0).text = "%d/%d" % [ceil(barrier), ceil(maximum_barrier)]
		elif fight_inventory_instance.defenses.find_custom(func(s): return s.name == defense_visual.name) == -1:
			defense_visual.queue_free()

	var block = fight_inventory_instance.get_defence_value("block")
	var absorption = fight_inventory_instance.get_defence_value("absorption")
	var defence_sum = fight_inventory_instance.health + block + maximum_barrier + absorption

	var health_bar_width = 192.0 * fight_inventory_instance.health / defence_sum
	var barrier_bar_width = 192.0 * maximum_barrier / defence_sum

	health_bar.size.x = health_bar_width
	current_health_bar.size.x = 192.0 * fight_inventory_instance.current_health / defence_sum
	current_barrier_bar.size.x = 192.0 * barrier / defence_sum + block_bar.size.x
	current_barrier_bar.position.x = health_bar_width
	block_bar.size.x = 192.0 * block / defence_sum
	block_bar.position.x = health_bar_width
	barrier_bar.size.x = barrier_bar_width
	barrier_bar.position.x = health_bar_width + block_bar.size.x
	absorption_bar.size.x = 192.0 * absorption / defence_sum
	absorption_bar.position.x = barrier_bar.position.x + barrier_bar.size.x
	
	var fire = fight_inventory_instance.get_ailment_value("fire")
	var poison = fight_inventory_instance.get_ailment_value("poison")
	var shock = fight_inventory_instance.get_ailment_value("shock")
	var acid = fight_inventory_instance.get_ailment_value("acid")
	var doom = fight_inventory_instance.get_status_effect_value("doom")
	
	fire_bar.size.x = 192.0 * fire / defence_sum
	if absorption > 0.0:
		fire_bar.position.x = absorption_bar.position.x + absorption_bar.size.x - fire_bar.size.x
	else:
		fire_bar.position.x = current_health_bar.position.x + current_health_bar.size.x - fire_bar.size.x

	poison_bar.size.x = 192.0 * poison / defence_sum
	poison_bar.position.x = fire_bar.position.x - poison_bar.size.x
	
	if block + absorption + barrier > 0.0:
		acid_bar.size.x = min(
			384.0 * acid * 2.0 / defence_sum,
			192.0 * (defence_sum - fight_inventory_instance.health) / defence_sum
		) # Double effectiveness
		acid_bar.position.x = absorption_bar.position.x + absorption_bar.size.x - acid_bar.size.x
	else:
		acid_bar.size.x = 96.0 * acid / defence_sum # Half effectiveness
		acid_bar.position.x = poison_bar.position.x - acid_bar.size.x
	
	shock_bar.size.x = 192.0 * shock / defence_sum
	shock_bar.position.x = poison_bar.position.x - shock_bar.size.x
	
	if is_zero_approx(fight_inventory_instance.current_health * current_health_bar.size.x):
		doom_bar.size.x = current_health_bar.size.x
	else:
		doom_bar.size.x = doom / fight_inventory_instance.current_health * current_health_bar.size.x
	
	for bar in [health_bar, current_health_bar, block_bar, fire_bar, poison_bar, shock_bar, acid_bar, doom_bar]:
		bar.size.x = ceil(bar.size.x)

func clear_visuals():
	for bar in [
		current_health_bar, health_bar, block_bar, poison_bar, 
		fire_bar, shock_bar, acid_bar, doom_bar,
		absorption_bar, barrier_bar, current_barrier_bar]:
		bar.size.x = 0.0
	
	for child in status_effect_container.get_children():
		child.queue_free()

	for child in ailment_container.get_children():
		child.queue_free()
	
	for child in defense_container.get_children():
		child.queue_free()

extends Defense
class_name Barrier

func _init(input_value : float = 0.0):
	name = "barrier"
	priority = 20
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func apply_defence(incoming_damage : float, damage_source : String) -> float:
	if value <= 0.0 or (damage_source != "acid" and damage_source != "damage"):
		return incoming_damage
	
	if value >= incoming_damage:
		value -= incoming_damage
		incoming_damage = 0.0
	else:
		incoming_damage -= value
		value = 0.0

	return incoming_damage

func get_info() -> String:
	return ""

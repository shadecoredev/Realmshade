extends Defense
class_name Absorption

func _init(input_value : float = 0.0):
	name = "absorption"
	priority = 30
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	value -= value * 0.01

func apply_defence(incoming_damage : float, _damage_source : String) -> float:
	if value >= incoming_damage:
		value -= incoming_damage
		incoming_damage = 0.0
	else:
		incoming_damage -= value
		value = 0.0

	return incoming_damage

func get_info() -> String:
	return ""

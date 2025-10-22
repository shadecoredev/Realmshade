extends StatusEffect
class_name Power

var effect_name : String

func _init(input_value : float = 0.0):
	name = "power"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	pass

func get_info() -> String:
	return ""

func get_value() -> float:
	return  value

extends Ailment
class_name Shock

func _init(input_value : float = 0.0):
	name = "shock"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	value -= value * 0.01

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color("fef3c0")

extends Ailment
class_name Fire

func _init(input_value : float = 0.0):
	name = "fire"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	_player_instance.recieve_damage(value * 0.05, "fire")
	value -= value * 0.01

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color("fa6a0a")

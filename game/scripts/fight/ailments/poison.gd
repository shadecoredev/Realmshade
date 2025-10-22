extends Ailment
class_name Poison

func _init(input_value : float = 0.0):
	name = "poison"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	_player_instance.recieve_damage(value * 0.05, "poison")

func get_info() -> String:
	return ""

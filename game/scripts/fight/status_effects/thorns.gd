extends StatusEffect
class_name Thorns

func _init(input_value : float = 0.0):
	name = "thorns"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func get_info() -> String:
	return ""

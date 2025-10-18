extends StatusEffect
class_name Thorns

func _init(input_value : float = 0.0):
	name = "thorns"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color("5a4e44")

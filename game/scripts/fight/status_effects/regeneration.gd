extends StatusEffect
class_name Regeneration

func _init(input_value : float = 0.0):
	name = "regeneration"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	_player_instance.heal(value * 0.05)
	value -= value * 0.01

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color("e86a73")

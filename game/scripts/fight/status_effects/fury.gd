extends StatusEffect
class_name Fury

func _init(input_value : float = 0.0):
	name = "fury"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color("df3e23")

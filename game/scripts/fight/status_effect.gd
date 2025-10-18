extends RefCounted
class_name StatusEffect

var name : String
var value : float

func _init(input_value : float = 0.0):
	value = input_value

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color.WHITE

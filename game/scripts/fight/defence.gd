extends RefCounted
class_name Defence

var name : String
var value : float
var priority : int = 0

func _init(input_value : float = 0.0):
	value = input_value

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func apply_defence(incoming_damage : float, _damage_source : String) -> float:
	return incoming_damage

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color.WHITE

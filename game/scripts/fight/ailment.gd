@abstract 
extends RefCounted
class_name Ailment

var name : String
var value : float

var is_hidden : bool = false

func _init(input_value : float = 0.0):
	value = input_value

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func get_info() -> String:
	return ""

func get_value() -> float:
	return value

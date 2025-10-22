extends StatusEffect
class_name Doom

func _init(input_value : float = 0.0):
	name = "doom"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	if _player_instance.current_health <= value:
		_player_instance.current_health -= value
		value = 0.0

func get_info() -> String:
	return ""

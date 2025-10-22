extends StatusEffect
class_name Purity

func _init(input_value : float = 0.0):
	name = "purity"
	super._init(input_value)

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	while !_player_instance.ailments.is_empty():
		var ailment_id = randi_range(0, _player_instance.ailments.size() - 1)
		var ailment = _player_instance.ailments[ailment_id]
		if value >= ailment.value:
			value -= ailment.value
			ailment.value = 0.0
			_player_instance.ailments.remove_at(ailment_id)
			if is_zero_approx(value):
				value = 0.0
				return
		else:
			ailment.value -= value
			value = 0.0
			return

func get_info() -> String:
	return ""

extends StatusEffect
class_name MaximumBarrier

func _init(input_value : float = 0.0):
	name = "maximum_barrier"
	super._init(input_value)
	is_hidden = true

func tick(_player_instance : FightInventoryInstance, _enemy_instance : FightInventoryInstance):
	return

func get_info() -> String:
	return ""

func get_color() -> Color:
	return Color("a6fcdb")

extends Label
class_name UILevelDisplay

func _level_increased_callback(game_manager : GameManager):
	text = str(game_manager.get_level())

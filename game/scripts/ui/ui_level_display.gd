extends Label
class_name UILevelDisplay

func _ready():
	GameManager.get_instance().level_increased_signal.connect(_level_increased_callback)

func _level_increased_callback(game_manager : GameManager):
	text = str(game_manager.get_level())

extends Button
class_name UIChangeSceneButton

@export var scene : PackedScene

func _ready():
	pressed.connect(get_tree().change_scene_to_packed.bind(scene))

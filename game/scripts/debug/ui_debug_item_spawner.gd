extends Button
class_name UIDebugItemSpawner

@export var item_name_lineedit : LineEdit
@export var item_origin : Control

func _ready():
	pressed.connect(_pressed_callback)

func _pressed_callback():
	var item = UIItemManager.get_instance().spawn_item(
		item_name_lineedit.text
	)
	get_tree().root.add_child(item)
	item.position = item_origin.global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)) - item.texture.get_size() * 0.5

extends Control
class_name UIMarker

var source_item : UIItem

func initialize(ui_item : UIItem):
	source_item = ui_item
	source_item.item_rotated_signal.connect(_item_rotated_callback)
	_item_rotated_callback(source_item.is_rotated())
	
func _item_rotated_callback(is_rotated : bool):
	if is_rotated:
		rotation = PI / 2.0
		position.x = source_item.get_item().texture.get_width()
		position.y = source_item.get_item().texture.get_height() - 7.0
	else:
		rotation = 0.0
		position.x = source_item.get_item().texture.get_width() - 7.0
		position.y = 0

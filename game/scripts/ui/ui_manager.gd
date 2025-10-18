extends Node
class_name UIManager

@export var player_label : Label

@export var event_container : HBoxContainer

@export var event_connection_1 : TextureRect
@export var event_icon_1 : TextureRect
@export var event_connection_2 : TextureRect
@export var event_icon_2 : TextureRect
@export var event_connection_3 : TextureRect
@export var event_icon_3 : TextureRect


func _ready():
	player_label.text = GameManager.get_player_name()
	
	event_container.alignment = BoxContainer.ALIGNMENT_CENTER
	event_connection_3.visible = false
	event_icon_3.visible = false
	
	var event_indicators = [
		event_connection_1,
		event_icon_1,
		event_connection_2,
		event_icon_2,
		event_connection_3,
		event_icon_3,
	]
	for i in range(event_indicators.size()):
		event_indicators[i].modulate = (
			Color.WHITE.darkened(
				0.75 * float(i > 0)
			)
		)

func _event_changed_callback(game_manager : GameManager):
	if game_manager.get_level() > 0:
		event_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		event_connection_3.visible = true
		event_icon_3.visible = true

	var event_indicators = [
		event_connection_1,
		event_icon_1,
		event_connection_2,
		event_icon_2,
		event_connection_3,
		event_icon_3,
	]
	var current_event : int = game_manager.get_event()
	for i in range(event_indicators.size()):
		event_indicators[i].modulate = (
			Color.WHITE.darkened(
				0.75 * float(i > current_event)
			)
		)

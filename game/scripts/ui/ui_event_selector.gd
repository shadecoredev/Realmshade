extends LineEdit
class_name UIEventSelector

@export var game_file_verifier : GameFileVerifier
@export var option_list : VBoxContainer

func _ready():
	text_changed.connect(_text_changed_callback)
	text_submitted.connect(_text_submitted_callback)

func _text_changed_callback(new_text : String):
	var events = game_file_verifier.list_valid_events()
	
	for child in option_list.get_children():
		child.queue_free()
		
	if new_text.is_empty():
		return
	
	var option_count = 0
	
	for event in events:
		var fight_capitalized = event.get_file().get_basename().capitalize()
		if fight_capitalized.contains(new_text.capitalize()):
			var button = Button.new()
			button.set_meta("path", event)
			button.text = fight_capitalized
			button.pressed.connect(
				func():
					text = button.get_meta("path")
					for child in option_list.get_children():
						child.queue_free()
			)
			option_list.add_child(button)
			option_list.move_child(button, 0)
			
			option_count += 1
			if option_count >= 8:
				break

func _text_submitted_callback(_new_text : String):
	var child_count = option_list.get_child_count()

	if child_count == 0:
		return
	
	var button = option_list.get_child(child_count - 1)
	
	text = button.text.to_lower().replace(" ", "_")
	for child in option_list.get_children():
		child.queue_free()
	

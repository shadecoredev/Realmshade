extends Node2D
class_name EventManager

@export var camera : Camera2D

@export var api_manager : APIManager
@export var game_manager : GameManager
@export var fight_manager : FightManager

@export var event_choice_container : Container

@export var event_reward_container : Control
@export var event_reward_center : Control
@export var event_reward_roll_parent : Control

@export var event_reward_take_button : Button
@export var event_reward_gamble_button : Button

@export var event_button_1 : Button
@export var event_button_2 : Button
@export var event_button_3 : Button

@export var proceed_button : Button

@export var trash_inventory : UIInventory

@export var player_inventory : UIInventory
@export var player_storage : UIInventory

@export var enemy_inventory : UIInventory
@export var enemy_label : Label

@export var default_camera_position : Control
@export var fight_camera_position : Control

@export var fight_label : RichTextLabel

@export var event_parent : Control

@export var background : ColorRect

var _selected_event : String

var _reward_roll_distance : float = 0.0
var _roll_offset : float = 0.0

var _reward_pool : Array
var _reward_item : UIItem
var _reward_gamble_count : int

func _process(delta):
	if _reward_roll_distance > 0.5:
		_reward_roll_distance -= _reward_roll_distance * delta * 5.0 # Roll speed
		event_reward_roll_parent.position.x = _reward_roll_distance + 73.0 + _roll_offset
	else:
		_reward_roll_distance = 0.0
		event_reward_roll_parent.position.x = lerp(event_reward_roll_parent.position.x, 73.0, 0.25)
		
		if abs(event_reward_roll_parent.position.x - 73.0) < 0.01:
			_roll_offset = 0.0
			set_process(false)
			_reward_roll_finished_callback()
			

func _ready():
	api_manager.enemy_rolled_signal.connect(_enemy_rolled_callback)
	fight_manager.fight_finished_signal.connect(_fight_finished_callback)
	
	for button in [event_button_1, event_button_2, event_button_3]:
		button.pressed.connect(_event_button_pressed_callback.bind(button))
	
	set_process(false)
	
	event_reward_take_button.pressed.connect(_reward_take_button_pressed_callback)
	event_reward_gamble_button.pressed.connect(_reward_gamble_button_pressed_callback)

	proceed_button.disabled = true
	event_reward_take_button.visible = false
	event_reward_gamble_button.visible = false

func clear():
	trash_inventory.visible = false
	event_reward_container.visible = false
	event_choice_container.visible = false
	enemy_inventory.visible = false
	proceed_button.disabled = true
	fight_label.text = ""
	_reward_item = null
	fight_label.visible = false
	trash_inventory.clear()
	_reward_gamble_count = 0
	
	for child in event_parent.get_children():
		child.queue_free()

func _event_changed_callback(_game_manager : GameManager):
	clear()
	enemy_inventory.clear()
	
	if game_manager.get_event() % 2 == 1:
		_update_background()
	
	for button in [event_button_1, event_button_2, event_button_3]:
		button.button_pressed = false
	
	if game_manager.get_event() == 0 or game_manager.get_event() == 2:
		_handle_event_choice()
		
	elif game_manager.get_event() == 1 or game_manager.get_event() == 3:
		_handle_event()
		
	elif game_manager.get_event() == 4:
		_handle_pvp_info()
		
	elif game_manager.get_event() == 5:
		if _selected_event != "":
			enemy_label.text = _selected_event.get_file().get_basename().capitalize()
			var event_file = FileAccess.open(_selected_event, FileAccess.READ)
			var event = JSON.parse_string(event_file.get_as_text())
			_handle_fight(event)

func _update_background():
	var color_pool : PackedColorArray = [
		# AAP-64
		Color("060608"),Color("141013"),Color("3b1725"),Color("73172d"),
		Color("b4202a"),Color("df3e23"),Color("fa6a0a"),Color("f9a31b"),
		Color("ffd541"),Color("fffc40"),Color("d6f264"),Color("9cdb43"),
		Color("59c135"),Color("14a02e"),Color("1a7a3e"),Color("24523b"),
		Color("122020"),Color("143464"),Color("285cc4"),Color("249fde"),
		Color("20d6c7"),Color("a6fcdb"),Color("ffffff"),Color("fef3c0"),
		Color("fad6b8"),Color("f5a097"),Color("e86a73"),Color("bc4a9b"),
		Color("793a80"),Color("403353"),Color("242234"),Color("221c1a"),
		Color("322b28"),Color("71413b"),Color("bb7547"),Color("dba463"),
		Color("f4d29c"),Color("dae0ea"),Color("b3b9d1"),Color("8b93af"),
		Color("6d758d"),Color("4a5462"),Color("333941"),Color("422433"),
		Color("5b3138"),Color("8e5252"),Color("ba756a"),Color("e9b5a3"),
		Color("e3e6ff"),Color("b9bffb"),Color("849be4"),Color("588dbe"),
		Color("477d85"),Color("23674e"),Color("328464"),Color("5daf8d"),
		Color("92dcba"),Color("cdf7e2"),Color("e4d2aa"),Color("c7b08b"),
		Color("a08662"),Color("796755"),Color("5a4e44"),Color("423934")
	]
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(_selected_event)
	
	var color_low_index = rng.randi() % color_pool.size()
	var color_low = color_pool[color_low_index].darkened(0.8)
	color_pool.remove_at(color_low_index)

	
	var color_high_index = rng.randi() % color_pool.size()
	var color_high = color_pool[color_high_index].darkened(0.7)
	color_pool.remove_at(color_high_index)

	var color_func = func(color, shader_parameter):
		background.material.set_shader_parameter(shader_parameter, color)

	var tween = create_tween().set_parallel(true)
	tween.tween_method(
		color_func.bind("color_low"),
		background.material.get_shader_parameter("color_low"),
		color_low,
		2.0
	)
	tween.tween_method(
		color_func.bind("color_mid"),
		background.material.get_shader_parameter("color_mid"),
		color_low.lerp(color_high, 0.5),
		2.0
	)
	tween.tween_method(
		color_func.bind("color_high"),
		background.material.get_shader_parameter("color_high"),
		color_high,
		2.0
	)
func _handle_event():
	var event_file = FileAccess.open(_selected_event, FileAccess.READ)
	if !event_file:
		printerr("Error reading event: %s" % _selected_event)
		return
	
	var event = JSON.parse_string(event_file.get_as_text())
	
	if event.type == "free_reward":
		_reward_pool = event.rewards
		_handle_reward(_reward_pool, 0)
	elif event.type == "fight":
		enemy_label.text = _selected_event.get_file().get_basename().capitalize()
		_handle_fight(event)
	elif event.type == "crafting_station":
		if "recipes" not in event:
			printerr("Recipes key not found in crafting station event json.")
			return
		
		var crafting_scene = load("res://scenes/event_scenes/crafting_station_event.tscn").instantiate() as CraftingStationEvent
		event_parent.add_child(crafting_scene)
		if player_storage:
			crafting_scene.add_recipe_search_inventory(player_storage)
		if player_inventory:
			crafting_scene.add_recipe_search_inventory(player_inventory)
		if trash_inventory:
			crafting_scene.add_recipe_search_inventory(trash_inventory)
		crafting_scene.initialize_recipes(event["name"], event["recipes"])
		crafting_scene.contents_changed_signal.connect(
			func():
				proceed_button.disabled = !crafting_scene.is_empty()
		)
		

func _handle_event_choice():
	event_choice_container.visible = true

	var events = game_manager.roll_events(game_manager.get_level(), game_manager.get_event())
	
	update_event_button(
			event_button_1, 
			events[0]
		)
	
	update_event_button(
			event_button_2,
			events[1]
		)
	
	update_event_button(
			event_button_3, 
			events[2]
		)

func _handle_reward(reward_pool : Array, gamble_count : int = 0):
	for child in event_reward_roll_parent.get_children():
		child.queue_free()
	
	event_reward_container.visible = true
	
	var fake_items = randi_range(17, 28)
	
	for i in fake_items:
		var fake_reward = game_manager.roll_fake_reward(game_manager.get_level(), game_manager.get_event(), reward_pool, gamble_count)
		if fake_reward == "":
			continue
		var fake_item = UIItemManager.get_instance().spawn_item(fake_reward)
		event_reward_roll_parent.add_child(fake_item)
		fake_item.z_index = -1
		fake_item.position = Vector2(-40.0 * (i+1), 0.0) - fake_item.texture.get_size() * 0.5
		fake_item.disable()
	
	for i in range(3):
		var fake_reward = game_manager.roll_fake_reward(game_manager.get_level(), game_manager.get_event(), reward_pool, gamble_count)
		if fake_reward == "":
			continue
		var fake_item = UIItemManager.get_instance().spawn_item(fake_reward)
		event_reward_roll_parent.add_child(fake_item)
		fake_item.z_index = -1
		fake_item.position = Vector2(40.0 * (i+1), 0.0) - fake_item.texture.get_size() * 0.5
		fake_item.disable()

	var reward = game_manager.roll_reward(game_manager.get_level(), game_manager.get_event(), reward_pool, gamble_count)
	if reward != "":
		var metadata = {
			"level" : game_manager.get_level(),
			"event" : game_manager.get_event(),
			"rerolls" : gamble_count
		}
		_reward_item = UIItemManager.get_instance().spawn_item(reward, metadata)
		event_reward_roll_parent.add_child(_reward_item)
		_reward_item.z_index = -1
		_reward_item.position = -_reward_item.texture.get_size() * 0.5
		_reward_item.disable()
		
	_reward_roll_distance = (fake_items - 1) * 40.0
	_roll_offset = randf_range(-19.5, 19.5)
	
	event_reward_take_button.visible = false
	event_reward_gamble_button.visible = false

	set_process(true)

func _reward_roll_finished_callback():
	if _reward_item == null:
		event_reward_take_button.visible = false
		event_reward_gamble_button.visible = false
		proceed_button.disabled = false
	else:
		if game_manager.get_item_pool(
				game_manager.get_level(),
				game_manager.get_event(),
				_reward_pool,
				_reward_gamble_count
			).size() <= 1:
				_reward_take_button_pressed_callback()
				proceed_button.disabled = false
		else:
			event_reward_gamble_button.visible = _reward_gamble_count < 5
			event_reward_take_button.visible = true
			proceed_button.disabled = true


func update_event_button(button : Button, event_filepath : String):
	button.text = event_filepath.get_file().get_basename().capitalize()
	button.set_meta("event_filepath", event_filepath)

func _event_button_pressed_callback(button : Button):
	var any_event_button_pressed = false
	for event_button in [event_button_1, event_button_2, event_button_3]:
		if event_button.button_pressed:
			any_event_button_pressed = true
			
	if !any_event_button_pressed:
		proceed_button.disabled = true
		return
	
	for event_button in [event_button_1, event_button_2, event_button_3]:
		if event_button != button:
			event_button.button_pressed = false
	
	_selected_event = button.get_meta("event_filepath")
	
	proceed_button.disabled = false

func select_event(event_filepath : String):
	_selected_event = event_filepath

func _reward_take_button_pressed_callback():
	if _reward_item:
		_reward_item.reparent(event_reward_container)
		_reward_item.enable()
		_reward_item.z_index = 3
		_reward_item.create_tween().tween_property(_reward_item, "position", _reward_item.position + Vector2(0.0, 80.0), 0.2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)

	event_reward_take_button.visible = false
	event_reward_gamble_button.visible = false
	proceed_button.disabled = false

func _reward_gamble_button_pressed_callback():
	_reward_gamble_count += 1
	_handle_reward(_reward_pool, _reward_gamble_count)

func _handle_fight(event : Dictionary):
	enemy_inventory.set_inventory_size(Vector2i(event["inventory"]["size_x"], event["inventory"]["size_y"]))
	enemy_inventory.load_from_json(event["inventory"]["items"])
	enemy_inventory.visible = true
	enemy_label.visible = true
	
	player_inventory.disable()
	trash_inventory.disable()
	
	var tween = create_tween()
	tween.tween_property(camera, "global_position", fight_camera_position.global_position, 0.5)
	tween.tween_callback(fight_manager.start_fight)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
func _handle_pvp_info():
	_selected_event = ""
	api_manager.roll_enemy()

func _enemy_rolled_callback(data : Dictionary):
	fight_label.visible = true
	
	if data == null or "build_id" not in data or data["build_id"] == null:
		_selected_event = game_manager.roll_fight(game_manager.get_level())
		fight_label.text ="No matching players found.\nYour opponent:\n%s" % _selected_event.get_file().get_basename().capitalize()
		proceed_button.disabled = false
		return
	else:
		print("Pvp fight found: %d" % data["build_id"])

func _fight_finished_callback(victory : bool):
	player_inventory.enable()
	trash_inventory.enable()
	var tween = create_tween()
	tween.tween_property(camera, "global_position", default_camera_position.global_position, 0.5).set_delay(1.0)
	tween.tween_callback(
		func():
			proceed_button.disabled = false
			enemy_inventory.clear()
			enemy_inventory.visible = false
			enemy_label.visible = false
			if victory:
				_handle_fight_reward.bind(_selected_event)
			else:
				fight_label.visible = true
				fight_label.text = "You have been defeated.\nYou gain no reward."
	)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_IN_OUT)

func _handle_fight_reward(event_path):
	if event_path.is_empty():
		print("Event path is empty.")
	
	var event_file = FileAccess.open(_selected_event, FileAccess.READ)
	var event = JSON.parse_string(event_file.get_as_text())
	
	_reward_pool.clear()
	
	for item in event["inventory"]["items"]:
		if item["name"] not in _reward_pool:
			_reward_pool.append(item["name"])
	
	_handle_reward(_reward_pool)
	

extends Node
class_name FightValidator

@export var key_lineedit : LineEdit

@export var api_manager : APIManager
@export var game_manager : GameManager
@export var game_file_verifier : GameFileVerifier

@export var fight_manager : FightManager

var _player_inventory : Inventory
var _enemy_inventory : Inventory

var _raw_build_id : int
var _player_name : String
var _data_string : String
var _received_seed : int
var _received_level : int

var _received_enemy_build_id : Variant = null

var _level_event_sources : PackedStringArray = []

func _ready():
	fight_manager._instant = true
	api_manager.enemy_raw_build_recieved.connect(_enemy_build_recieved_callback)
	api_manager.enemy_rolled_signal.connect(_enemy_rolled_callback)
	api_manager.insert_build_error.connect(invalidate_received_build)
	api_manager.insert_build_success.connect(invalidate_received_build)
	fight_manager.fight_finished_signal.connect(_fight_finished_callback)

func _reset():
	_raw_build_id = 0
	_received_seed = 0
	_received_level = 0
	_data_string = ""
	_received_enemy_build_id = null
	_level_event_sources.clear()

func _enemy_build_recieved_callback(result : Dictionary):
	_reset()

	if "id" not in result:
		printerr("Raw build id is missing")
		invalidate_received_build()
		return
	_raw_build_id = int(result["id"])
	
	print("Validating build %d" % _raw_build_id)

	if "player_name" not in result:
		printerr("Player name is missing")
		invalidate_received_build()
		return
	_player_name = str(result["player_name"])

	if _player_name.length() > 32:
		printerr("Player name too big")
		invalidate_received_build()
		return

	for character_id in range(_player_name.length()):
		if _player_name[character_id] not in UIPlayerNameEdit.allowed_characters:
			printerr("Invalid character detected in player name: %s" % _player_name[character_id])
			invalidate_received_build()
			return

	if "patch" not in result:
		printerr("Raw build patch is missing")
		invalidate_received_build()
		return

	var patch = str(result["patch"])
	if patch != GameManager.get_patch():
		printerr("Raw build patch mismatch")
		invalidate_received_build()
		return

	if "seed" not in result:
		printerr("Raw build seed is missing")
		invalidate_received_build()
		return
	_received_seed = int(result["seed"])
	game_manager._seed = _received_seed
	
	if "level" not in result:
		printerr("Raw build level is missing")
		invalidate_received_build()
		return
	_received_level = int(result["level"])

	if "data" not in result:
		printerr("Raw build data is missing")
		invalidate_received_build()
		return
	_data_string = str(result["data"])
	
	if _data_string.length() > 100000:
		printerr("Enemy build data too big")
		invalidate_received_build()

	if "enemy_build_id" not in result:
		printerr("Enemy build id is missing")
		invalidate_received_build()
		return
	_received_enemy_build_id = result["enemy_build_id"]

	if "enemy_pool_timestamp" not in result:
		printerr("Enemy pool timestamp is missing")
		invalidate_received_build()
		return
	var enemy_pool_timestamp : String = str(result["enemy_pool_timestamp"])

	api_manager._invoke_roll_enemy_function(
		enemy_pool_timestamp,
		_received_seed,
		_received_level,
		patch
	)

func _enemy_rolled_callback(result : Dictionary):
	if "build_id" not in result:
		printerr("Build id mising in rolled enemy")
		invalidate_received_build()
		return
	
	if _received_enemy_build_id != result["build_id"]:
		printerr("Rolled enemy build_id mismatch")
		invalidate_received_build()
		return
	
	print("Enemy build id is valid")
	
	var item_load_result = validate_and_load_items()

	if !item_load_result:
		invalidate_received_build()
		return
	
	var json_dict = JSON.parse_string(_data_string)
	var items_array = json_dict["items"]
	if _received_enemy_build_id == null:
		_simulate_pve_fight(items_array)
	else:
		_simulate_pvp_fight(items_array, result["items"])
		

func validate_and_load_items() -> bool:
	var json_dict = JSON.parse_string(_data_string)

	if json_dict == null:
		printerr("Failed to parse raw build data")
		return false

	if "items" not in json_dict or json_dict["items"] is not Array:
		printerr("Missing items array in raw build data")
		return false

	var items_array = json_dict["items"]
	
	if items_array.is_empty():
		printerr("Empty inventory in raw build data")
		return false

	for item_json in items_array:
		var validation_successful = validate_item(item_json)
		if !validation_successful:
			return false

	return true

func validate_item(item_json : Dictionary) -> bool:
	if "name" not in item_json:
		printerr("Missing item name")
		return false

	if item_json["name"] not in game_file_verifier.list_valid_items():
		printerr("Item name not recognized: %s" % item_json["name"])
		return false
	
	if "position" not in item_json:
		printerr("Missing item position")
		return false

	if "event_name" not in item_json:
		printerr("Missing item event name")
		return false

	if "event" not in item_json:
		printerr("Missing item event")
		return false

	if "level" not in item_json:
		printerr("Missing item level")
		return false
	
	if item_json["level"] > _received_level:
		printerr("Item has higher level than build level")
		return false
		
	var level_event_pair = "%d_%d" % [int(item_json["level"]), int(item_json["event"])]
	if level_event_pair in _level_event_sources:
		printerr("Item level event duplicate detected")
		return false
	_level_event_sources.append(level_event_pair)

	var events = game_manager.roll_events(
		int(item_json["level"]),
		int(item_json["event"]) - 1 # Previous event selection
	)
	for i in range(events.size()):
		events[i] = events[i].get_file().get_basename()
	if item_json["event_name"] not in events:
		printerr("Event mismatch: %s not found in %s" % [item_json["event_name"], events])
		return false
	
	var event_file = FileAccess.open(
		game_file_verifier._events_by_name[item_json["event_name"]], 
		FileAccess.READ
	)
	if !event_file:
		printerr("Error reading item source event: %s" % item_json["event_name"])
		return false
	
	var event = JSON.parse_string(event_file.get_as_text())
	if !event:
		printerr("Error parsing item source event: %s" % item_json["event_name"])
		return false
	
	match (event["type"]):
		"free_reward":
			if "rerolls" not in item_json:
				printerr("Missing gamble count")
				return false
			var real_reward = game_manager.roll_reward(
				int(item_json["level"]),
				int(item_json["event"]),
				event["rewards"],
				int(item_json["rerolls"])
			)
			if item_json["name"] != real_reward:
				printerr("Item not matching real reward: %s != %s" % [item_json["name"], real_reward])
				return false
		"fight":
			var reward_pool : PackedStringArray = []
			for item in event["inventory"]["items"]:
				if item["name"] not in reward_pool:
					reward_pool.append(item["name"])
			
			if "rerolls" not in item_json:
				printerr("Missing gamble count")
				return false
			var real_reward = game_manager.roll_reward(
				int(item_json["level"]),
				int(item_json["event"]),
				event["rewards"],
				int(item_json["rerolls"])
			)
			if item_json["name"] != real_reward:
				printerr("Item not matching real reward: %s != %s" % [item_json["name"], real_reward])
				return false
		_:
			printerr("Event type \"%s\" not recognized during item validation: %s" % event["type"])
			return false

	return true

func _simulate_pve_fight(items_array : Array):
	_player_inventory = Inventory.new()
	_player_inventory.resize(GameManager.get_inventory_size_by_level(_received_level))
	var player_inventory_load_success = _player_inventory.load_from_json(items_array)
	
	if !player_inventory_load_success:
		printerr("Unable to load player inventory")
		return

	_enemy_inventory = Inventory.new()

	var event_path = GameManager.get_instance().roll_fight(_received_level)
	print("Simulating fight against: ", event_path.get_file().get_basename().capitalize())

	var event_file = FileAccess.open(
		event_path, 
		FileAccess.READ
	)

	var event = JSON.parse_string(event_file.get_as_text())
	_enemy_inventory.resize(
		Vector2i(
			event["inventory"]["width"],
			event["inventory"]["height"]
		)
	)
	_enemy_inventory.load_from_json(event["inventory"]["items"])

	fight_manager.start_fight(
		_player_inventory,
		_enemy_inventory
	)

func _simulate_pvp_fight(items_array : Array, enemy_items : Array):
	_player_inventory = Inventory.new()
	_player_inventory.resize(GameManager.get_inventory_size_by_level(_received_level))
	var player_inventory_load_success = _player_inventory.load_from_json(items_array)
	
	if !player_inventory_load_success:
		printerr("Unable to load player inventory")
		return false

	_enemy_inventory = Inventory.new()
	_enemy_inventory.resize(GameManager.get_inventory_size_by_level(_received_level))
	var enemy_inventory_load_success = _enemy_inventory.load_from_json(enemy_items)

	if !enemy_inventory_load_success:
		printerr("Unable to load enemy inventory")
		return false

	fight_manager.start_fight(
		_player_inventory,
		_enemy_inventory
	)

	return true
	
func insert_valid_build(is_victory : bool):
	api_manager.post_valid_build(
		_player_name,
		str(_received_seed),
		_received_level,
		_data_string,
		is_victory,
		key_lineedit.text
	)

func invalidate_received_build():
	print("Deleting run %d" % _raw_build_id)
	api_manager._delete_raw_build(_raw_build_id, key_lineedit.text)

func _fight_finished_callback(is_victory : bool):
	insert_valid_build(is_victory)

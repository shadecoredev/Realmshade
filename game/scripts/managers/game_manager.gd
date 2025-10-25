extends Node
class_name GameManager

@export var game_file_verifier : GameFileVerifier

const _patch : String = "7c4a89d1-f4a3-4d14-90b4-d597cdec5de1"

static var data_source_paths : PackedStringArray = ["res://data/"]

static var player_name : String = ""

signal level_increased_signal(game_manager : GameManager)
signal event_changed_singal(game_manager : GameManager)
signal seed_changed_signal(seed : int)

var _current_level : int = 0
var _current_event : int = 0

var _seed : int = 0

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

static var _instance : GameManager

static func get_instance() -> GameManager:
	return _instance

func _ready():
	_instance = self

	reset_seed()
	
	event_changed_singal.emit(self)

func advance_event():
	_current_event += 1
	if _current_event > 5 or (_current_level == 0 and _current_event > 3):
		reset_event()
		advance_level()

	event_changed_singal.emit(self)

static func set_player_name(text : String):
	player_name = text

static func get_player_name():
	return player_name

func advance_level():
	_current_level += 1
	level_increased_signal.emit(self)
	
func reset_level():
	_current_level = 0
	
func reset_event():
	_current_event = 0

func get_level() -> int:
	return _current_level

func get_event() -> int:
	return _current_event

func get_seed() -> int:
	return _seed

static func get_patch() -> String:
	return _patch

func reset_seed() -> void:
	_seed = (randi() << 32) | randi()
	
	seed_changed_signal.emit(_seed)

static func get_inventory_size_by_level(level : int) -> Vector2i:
	match level:
		0: return Vector2i( 5,  3 )
		1: return Vector2i( 5,  3 )
		2: return Vector2i( 7,  3 )
		3: return Vector2i( 7,  4 )
		4: return Vector2i( 9,  4 )
		5: return Vector2i( 9,  5 )
		6: return Vector2i( 11, 5 )
		_: return Vector2i( 12, 5 )

func roll_events(level : int, event : int) -> PackedStringArray:
	var result = PackedStringArray()

	var event_pool = game_file_verifier.get_event_list_by_level(level)

	for i in range(3):
		if event_pool.is_empty():
			printerr("Event pool is empty for level %d, event %d, index %d." % [level, event, i])
			result.append("")
			continue

		_rng.seed = hash(String.num_uint64(_seed) + "event" + str(level) + str(event) + str(i))

		var rolled_event_index = _rng.randi() % (event_pool.size())

		var rolled_event = event_pool[rolled_event_index]
		result.append(rolled_event)

		event_pool.remove_at(event_pool.find(rolled_event)) # Prevent duplicates

	#printt("Event", level, event, result)

	return result

func roll_fight(level : int) -> String:
	var fight_pool = game_file_verifier.get_fight_list_by_level(level)

	if fight_pool.is_empty():
		printerr("Fight pool is empty for level %d." % [level])
		return ""

	_rng.seed = hash(String.num_uint64(_seed) + "fight" + str(level))

	var rolled_fight_index = _rng.randi() % (fight_pool.size())

	return fight_pool[rolled_fight_index]

func get_item_pool(level : int, event : int, reward_pool : Array, gamble_count : int) -> Array:
	reward_pool = reward_pool.duplicate()
	for i in range(gamble_count):
		if reward_pool.is_empty():
			printerr("Reward pool is empty")
			return []
		_rng.seed = hash(String.num_uint64(_seed) + "pool" + str(level) + str(event) + str(i))

		reward_pool.remove_at(_rng.randi() % (reward_pool.size()))
	return reward_pool

func roll_reward(level : int, event : int, reward_pool : Array, gamble_count : int) -> String:
	reward_pool = get_item_pool(level, event, reward_pool, gamble_count)
	if reward_pool.is_empty():
		printerr("Reward pool is empty")
		return ""
	
	_rng.seed = hash(String.num_uint64(_seed) + "reward" + str(level) + str(event) + str(gamble_count))
	
	if _rng.randf() <= get_gamble_failure_chance(gamble_count):
		return ""

	var rolled_reward_index = _rng.randi() % (reward_pool.size())
	#printt("Event", level, event, reward_pool, gamble_count, reward_pool[rolled_reward_index])
	
	return reward_pool[rolled_reward_index]

func roll_fake_reward(level : int, event : int, reward_pool : Array, gamble_count : int) -> String:
	reward_pool = get_item_pool(level, event, reward_pool, gamble_count)
	if reward_pool.is_empty():
		printerr("Reward pool is empty")
		return ""

	if randf() <= get_gamble_failure_chance(gamble_count):
		return ""
	var rolled_reward_index = randi() % (reward_pool.size())

	return reward_pool[rolled_reward_index]

func get_gamble_failure_chance(gamble_count : int) -> float:
	return [-1.0, 0.2, 0.4, 0.6, 0.8, 1.0][gamble_count]

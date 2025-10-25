extends Node
class_name APIManager

const url = "https://thsehavdbsyfsoqpltnh.supabase.co"
const public_api_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoc2VoYXZkYnN5ZnNvcXBsdG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzOTUzNjAsImV4cCI6MjA3Mzk3MTM2MH0.AkKPSb9ULSh0FbchOo-ku0kpFAkFZ8q1J0Y66UHQsTA"

@export var validator : bool = false

@export var game_manager : GameManager
@export var player_inventory : UIInventory

var http_roll_enemy_request : HTTPRequest
var http_post_build_request : HTTPRequest
var http_get_raw_build_request : HTTPRequest
var http_delete_raw_build_request : HTTPRequest

var http_create_or_get_player_request : HTTPRequest
var http_insert_build_request : HTTPRequest
var http_insert_items_request : HTTPRequest
var http_fetch_item_ids_request : HTTPRequest
var http_insert_inventory_items_request : HTTPRequest

var enemy_pool_timestamp : String = ""
var enemy_build_id = null

signal enemy_rolled_signal(result : Dictionary)
signal enemy_raw_build_recieved(result : Dictionary)
signal enemy_raw_build_deleted()

signal insert_build_error()
signal insert_build_success()

var _key : String
var _build_id : int
var _received_seed : String
var _received_level : int
var _received_data : String
var _victory : bool

func _ready():
	http_roll_enemy_request = HTTPRequest.new()
	add_child(http_roll_enemy_request)
	http_roll_enemy_request.request_completed.connect(_http_roll_enemy_request_completed_callback)
	
	http_post_build_request = HTTPRequest.new()
	add_child(http_post_build_request)
	http_post_build_request.request_completed.connect(_http_post_build_request_completed_callback)
	
	http_get_raw_build_request = HTTPRequest.new()
	add_child(http_get_raw_build_request)
	http_get_raw_build_request.request_completed.connect(_http_get_raw_build_request_completed_callback)

	if validator:
		http_delete_raw_build_request = HTTPRequest.new()
		add_child(http_delete_raw_build_request)
		http_delete_raw_build_request.request_completed.connect(_http_delete_raw_build_request_completed_callback)

		http_create_or_get_player_request = HTTPRequest.new()
		add_child(http_create_or_get_player_request)
		http_create_or_get_player_request.request_completed.connect(_http_create_or_get_player_callback)
		
		http_insert_build_request = HTTPRequest.new()
		add_child(http_insert_build_request)
		http_insert_build_request.request_completed.connect(_http_insert_build_callback)
		
		http_insert_items_request = HTTPRequest.new()
		add_child(http_insert_items_request)
		http_insert_items_request.request_completed.connect(_http_insert_items_callback)
		
		http_fetch_item_ids_request = HTTPRequest.new()
		add_child(http_fetch_item_ids_request)
		http_fetch_item_ids_request.request_completed.connect(_http_fetch_item_ids_callback)
		
		http_insert_inventory_items_request = HTTPRequest.new()
		add_child(http_insert_inventory_items_request)
		http_insert_inventory_items_request.request_completed.connect(_http_insert_inventory_items_callback)

func _delete_raw_build(build_id : int, key : String):
	http_get_raw_build_request.request(
		url + "/rest/v1/rpc/delete_raw_build",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key,
			"Authorization: Bearer %s" % key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"build_id" : build_id
		})
	)

func _http_delete_raw_build_request_completed_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or response_code != 204:
		printerr("Unable to delete raw build from the server.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : JSON.parse_string(body.get_string_from_utf8())
		}, "\t"))
		return
	
	print("Build invalidated successfully")
	
	enemy_raw_build_deleted.emit()

func get_raw_build():
	http_get_raw_build_request.request(
		url + "/rest/v1/rpc/get_raw_build",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"_patch" : GameManager.get_patch()
		})
	)

func _http_get_raw_build_request_completed_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if body.size() > 100000:
		printerr("Raw build response reading rawtoo big")
		return
	
	if result != 0 or response_code != 200:
		printerr("Unable to get a raw build from the server.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : JSON.parse_string(body.get_string_from_utf8())
		}, "\t"))
		return

	var body_json = JSON.parse_string(body.get_string_from_utf8())
	if body_json == null:
		printerr("Error reading raw build data or there are no raw builds in database")
		return

	enemy_raw_build_recieved.emit(body_json)

func roll_enemy():
	enemy_pool_timestamp = Time.get_datetime_string_from_system(true)
	_invoke_roll_enemy_function(
		enemy_pool_timestamp,
		game_manager.get_seed(),
		game_manager.get_level(),
		GameManager.get_patch()
	)

func _invoke_roll_enemy_function(timestamp : String, game_seed : int, enemy_level : int, patch : String):
	http_roll_enemy_request.request(
		url + "/rest/v1/rpc/roll_enemy",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"enemy_pool_timestamp" : timestamp,
			"seed" : game_seed,
			"enemy_level" : enemy_level,
			"patch" : patch
		})
	)

func _http_roll_enemy_request_completed_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or response_code != 200:
		printerr("Unable to get an enemy player from the server.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : JSON.parse_string(body.get_string_from_utf8())
		}, "\t"))
		return
	
	
	var body_json = JSON.parse_string(body.get_string_from_utf8())
	if body_json and "build_id" in body_json and body_json["build_id"] != null:
		enemy_build_id = int(body_json["build_id"])
	else:
		enemy_build_id = null
	
	enemy_rolled_signal.emit(body_json)

func post_build():
	if enemy_pool_timestamp.is_empty():
		printerr("Invalid timestamp.")
		return
	
	http_post_build_request.request(
		url + "/rest/v1/raw_build",
		["Content-Type: application/json", "apikey: %s" % public_api_key],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"data" : player_inventory.inventory.stringify(),
			"player_name" : GameManager.get_player_name(),
			"seed": String.num_int64(game_manager.get_seed()),
			"level" : game_manager.get_level(),
			"enemy_build_id" : enemy_build_id,
			"patch": GameManager.get_patch(),
			"enemy_pool_timestamp" : enemy_pool_timestamp
		})
	)

func _http_post_build_request_completed_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or response_code != 201:
		printerr("Unable to post a build to the server.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : JSON.parse_string(body.get_string_from_utf8())
		}, "\t"))
		return
	
	print("Build posted successfully.")

func post_valid_build(
		player_name : String,
		received_seed : String,
		received_level : int,
		data_string : String,
		victory : bool,
		key : String
	):
	_received_seed = received_seed
	_received_level = received_level
	_victory = victory
	_received_data = data_string
	_key = key
	create_or_get_player(player_name, key)

func create_or_get_player(player_name : String, key : String):
	http_create_or_get_player_request.request(
		url + "/rest/v1/rpc/create_or_get_player",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key,
			"Authorization: Bearer %s" % key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"p_player_name" : player_name,
		})
	)

func _http_create_or_get_player_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or response_code != 200:
		printerr("Unable to create a player.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : body.get_string_from_utf8()
		}, "\t"))
		return
	
	var player_id = int(body.get_string_from_utf8())
	
	print("Created player with ID: ", player_id)
	
	http_insert_build(
		_received_seed,
		_received_level,
		player_id,
		GameManager.get_patch(),
		_victory,
		_key
	)


func http_insert_build(
	input_seed : String,
	level : int,
	player_id : int,
	patch : String,
	victory : bool,
	key : String
):
	http_insert_build_request.request(
		url + "/rest/v1/rpc/insert_build",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key,
			"Authorization: Bearer %s" % key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"_seed" : input_seed,
			"_level" : level,
			"_player_id" : player_id,
			"_patch" : patch,
			"_victory" : victory
		})
	)

func _http_insert_build_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or response_code != 200:
		printerr("Unable to create a player.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : body.get_string_from_utf8()
		}, "\t"))
		return
	
	_build_id = int(body.get_string_from_utf8())
	
	if _build_id == 0:
		printerr("Build with this seed already exists.")
		insert_build_error.emit()
		return

	print("Created build with ID: ", _build_id)

	var data_json = JSON.parse_string(_received_data)
	var items_json = data_json["items"]
	var items : Array[Dictionary] = []
	for item in items_json:
		items.append(
			{"name" : item["name"]}
		)

	insert_items(items, _key)

func insert_items(items : Array[Dictionary], key):
	http_insert_items_request.request(
		url + "/rest/v1/item?on_conflict=name",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key,
			"Authorization: Bearer %s" % key,
			'Prefer: resolution=ignore-duplicates'
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify(
			items
		)
	)

func _http_insert_items_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or (response_code != 200 and response_code != 201):
		printerr("Unable to insert items.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : body.get_string_from_utf8()
		}, "\t"))
		return
	
	var data_json = JSON.parse_string(_received_data)
	var items_json = data_json["items"]
	var items : Array[String] = []
	for item in items_json:
		if item["name"] not in items:
			items.append(item["name"])
	
	fetch_item_ids(items, _key)

func fetch_item_ids(items : Array[String], key : String):
	http_fetch_item_ids_request.request(
		url + "/rest/v1/item?name=in.(%s)" % [",".join(items)],
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key,
			"Authorization: Bearer %s" % key
		],
		HTTPClient.Method.METHOD_GET
	)

func _http_fetch_item_ids_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or (response_code != 200 and response_code != 201):
		printerr("Unable to insert items.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : body.get_string_from_utf8()
		}, "\t"))
		return
	
	var response_json = JSON.parse_string(body.get_string_from_utf8())
	var item_ids_dict : Dictionary[String, int] = {}
	
	for entry in response_json:
		item_ids_dict[entry["name"]] = int(entry["id"])
	
	var data_json = JSON.parse_string(_received_data)
	var items_json = data_json["items"]
	var items : Array[Dictionary] = []
	for item in items_json:
		items.append({
			"item_id" : item_ids_dict[item["name"]],
			"build_id" : _build_id,
			"position" : int(item["position"])
		})

	insert_inventory_items(items, _key)

func insert_inventory_items(items : Array[Dictionary], key):
	http_insert_inventory_items_request.request(
		url + "/rest/v1/inventory_item",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key,
			"Authorization: Bearer %s" % key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify(
			items
		)
	)

func _http_insert_inventory_items_callback(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != 0 or (response_code != 200 and response_code != 201):
		printerr("Unable to insert inventory items.\n", JSON.stringify({
			"result" : result,
			"response_code" : response_code,
			"headers" : headers,
			"body" : body.get_string_from_utf8()
		}, "\t"))
		return
	
	print("Inventory items inserted successfully")
	
	insert_build_success.emit()

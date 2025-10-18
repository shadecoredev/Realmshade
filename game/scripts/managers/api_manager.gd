extends Node
class_name APIManager

const url = "https://thsehavdbsyfsoqpltnh.supabase.co"
const public_api_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoc2VoYXZkYnN5ZnNvcXBsdG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzOTUzNjAsImV4cCI6MjA3Mzk3MTM2MH0.AkKPSb9ULSh0FbchOo-ku0kpFAkFZ8q1J0Y66UHQsTA"

@export var game_manager : GameManager
@export var player_inventory : UIInventory

var http_roll_enemy_request : HTTPRequest
var http_post_build_request : HTTPRequest

var enemy_pool_timestamp : String = ""
var enemy_build_id = null

signal enemy_rolled_signal(result : Dictionary)

func _ready():
	http_roll_enemy_request = HTTPRequest.new()
	add_child(http_roll_enemy_request)
	http_roll_enemy_request.request_completed.connect(_http_roll_enemy_request_completed_callback)
	
	http_post_build_request = HTTPRequest.new()
	add_child(http_post_build_request)
	http_post_build_request.request_completed.connect(_http_post_build_request_completed_callback)

func roll_enemy():
	enemy_pool_timestamp = Time.get_datetime_string_from_system(true)
	http_roll_enemy_request.request(
		url + "/rest/v1/rpc/roll_enemy",
		[
			"Content-Type: application/json",
			"apikey: %s" % public_api_key
		],
		HTTPClient.Method.METHOD_POST,
		JSON.stringify({
			"enemy_pool_timestamp" : enemy_pool_timestamp,
			"seed" : game_manager.get_seed(),
			"enemy_level" : game_manager.get_level(),
			"patch" : game_manager.get_patch()
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
			"seed": game_manager.get_seed(),
			"level" : game_manager.get_level(),
			"enemy_build_id" : enemy_build_id,
			"patch": game_manager.get_patch(),
			"enemy_pool_timestamp" : enemy_pool_timestamp,
		})
	)
	

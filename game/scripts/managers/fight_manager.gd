extends Node
class_name FightManager

@export var player_inventory : UIInventory
@export var enemy_inventory : UIInventory

@export var player_health_display : UIHealthDisplay
@export var enemy_health_display : UIHealthDisplay

static var _instance : FightManager

var _player_inventory_effects : FightInventoryInstance
var _enemy_inventory_effects : FightInventoryInstance

var time : float

signal fight_finished_signal(victory : bool)

static func get_instance() -> FightManager:
	return _instance

func is_currently_fighting() -> bool:
	return _player_inventory_effects != null and _enemy_inventory_effects != null

func get_item_source_instance(inventory_item : InventoryItem) -> FightInventoryInstance:
	var parent_inventory = inventory_item._parent_inventory
	
	if _player_inventory_effects and _player_inventory_effects.get_source_inventory() == parent_inventory:
		return _player_inventory_effects
	
	if _enemy_inventory_effects and _enemy_inventory_effects.get_source_inventory() == parent_inventory:
		return _enemy_inventory_effects
	
	return null

func _ready():
	_instance = self
	set_process(false)

func start_fight():
	time = 0.0
	
	if _player_inventory_effects:
		_player_inventory_effects.queue_free()
		_player_inventory_effects = null

	_player_inventory_effects = FightInventoryInstance.new()
	_player_inventory_effects.initialize(player_inventory.inventory)
	add_child(_player_inventory_effects)

	if _enemy_inventory_effects:
		_enemy_inventory_effects.queue_free()
		_enemy_inventory_effects = null

	_enemy_inventory_effects = FightInventoryInstance.new()
	_enemy_inventory_effects.initialize(enemy_inventory.inventory)
	add_child(_enemy_inventory_effects)

	_player_inventory_effects.enemy = _enemy_inventory_effects
	_enemy_inventory_effects.enemy = _player_inventory_effects
	
	_player_inventory_effects.start()
	_enemy_inventory_effects.start()
	
	player_health_display.initialize(player_inventory, _player_inventory_effects)
	enemy_health_display.initialize(enemy_inventory, _enemy_inventory_effects)

	player_health_display.visible = true
	enemy_health_display.visible = true
	
	set_process(true)

func _process(delta : float):
	time += delta
	
	if time > 0.05:
		time -= 0.05

		_player_inventory_effects.tick()
		player_health_display.update_visuals(player_inventory, _player_inventory_effects)
		enemy_health_display.update_visuals(enemy_inventory, _enemy_inventory_effects)
		_check_death(_enemy_inventory_effects, true)

		_enemy_inventory_effects.tick()
		player_health_display.update_visuals(player_inventory, _player_inventory_effects)
		enemy_health_display.update_visuals(enemy_inventory, _enemy_inventory_effects)
		_check_death(_player_inventory_effects, false)

func _check_death(effects : FightInventoryInstance, victory : bool):
	if effects.current_health > 0.0:
		return

	set_process(false)
	fight_finished_signal.emit(victory)

	player_inventory.clear_visuals()
	enemy_inventory.clear_visuals()

	player_health_display.clear_visuals()
	enemy_health_display.clear_visuals()

	await get_tree().process_frame

	if _player_inventory_effects:
		_player_inventory_effects.queue_free()
		_player_inventory_effects = null
	if _enemy_inventory_effects:
		_enemy_inventory_effects.queue_free()
		_enemy_inventory_effects = null

	time = 0.0

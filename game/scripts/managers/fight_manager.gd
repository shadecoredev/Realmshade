extends Node
class_name FightManager

@export var player_ui_inventory : UIInventory
@export var enemy_ui_inventory : UIInventory

@export var player_health_display : UIHealthDisplay
@export var enemy_health_display : UIHealthDisplay

static var _instance : FightManager

var _instant : bool = false

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

func initialize_ui(input_player_ui_inventory : UIInventory, input_enemy_ui_inventory : UIInventory):
	player_ui_inventory = input_player_ui_inventory
	enemy_ui_inventory = input_enemy_ui_inventory
	
	if player_health_display:
		player_health_display.initialize(player_ui_inventory, _player_inventory_effects)
		player_health_display.visible = true

	if enemy_health_display:
		enemy_health_display.initialize(enemy_ui_inventory, _enemy_inventory_effects)
		enemy_health_display.visible = true

func start_fight(player_inventory : Inventory, enemy_inventory : Inventory):
	time = 0.0
	
	if _player_inventory_effects:
		_player_inventory_effects.queue_free()
		_player_inventory_effects = null

	_player_inventory_effects = FightInventoryInstance.new()
	_player_inventory_effects.initialize(player_inventory)
	add_child(_player_inventory_effects)

	if _enemy_inventory_effects:
		_enemy_inventory_effects.queue_free()
		_enemy_inventory_effects = null

	_enemy_inventory_effects = FightInventoryInstance.new()
	_enemy_inventory_effects.initialize(enemy_inventory)
	add_child(_enemy_inventory_effects)

	_player_inventory_effects.enemy = _enemy_inventory_effects
	_enemy_inventory_effects.enemy = _player_inventory_effects
	
	_player_inventory_effects.start()
	_enemy_inventory_effects.start()
	
	set_process(true)

func _process(delta : float):
	time += delta
	
	if time > 0.05 or _instant:
		time -= 0.05

		_player_inventory_effects.tick()
		if player_health_display:
			player_health_display.update_visuals(player_ui_inventory, _player_inventory_effects)
		if enemy_health_display:
			enemy_health_display.update_visuals(enemy_ui_inventory, _enemy_inventory_effects)
		_check_death(_enemy_inventory_effects, true)

		_enemy_inventory_effects.tick()
		if player_health_display:
			player_health_display.update_visuals(player_ui_inventory, _player_inventory_effects)
		if enemy_health_display:
			enemy_health_display.update_visuals(enemy_ui_inventory, _enemy_inventory_effects)
		_check_death(_player_inventory_effects, false)

func _check_death(effects : FightInventoryInstance, victory : bool):
	if effects.current_health > 0.0:
		return
		
	print("Victory: ", victory)

	set_process(false)
	fight_finished_signal.emit(victory)

	if player_ui_inventory:
		player_ui_inventory.clear_visuals()
	if enemy_ui_inventory:
		enemy_ui_inventory.clear_visuals()

	if player_health_display:
		player_health_display.clear_visuals()
	if enemy_health_display:
		enemy_health_display.clear_visuals()

	await get_tree().process_frame

	if _player_inventory_effects:
		_player_inventory_effects.queue_free()
		_player_inventory_effects = null
	if _enemy_inventory_effects:
		_enemy_inventory_effects.queue_free()
		_enemy_inventory_effects = null

	time = 0.0

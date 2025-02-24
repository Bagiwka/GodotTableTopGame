extends Node

var selected_unit: CharacterBody2D
enum PHASES {SETUP, COMMAND, MOVEMENT, SHOOTING, CHARGE, FIGHT}
var current_phase: PHASES = PHASES.SETUP
var amount_of_units: int = 0
var game_node
var units
var to_unify: Array[CharacterBody2D]
var to_unify_group: String = ""

func _ready() -> void:
	game_node = get_node("/root/Game")
	units = game_node.get_node("Map").get_node("Units")

func find_next_enemy(groups: Array, unit:CharacterBody2D) -> CharacterBody2D:
	var enemy_unit: Array
	var failsafe
	for model in units.get_children():
		model = model.get_child(0)
		if (model and model.get_groups() == groups):
			enemy_unit.append(model)
			failsafe = model
		
	if not failsafe:
		return null
		
	var lowest = failsafe
	for model in enemy_unit:
		if (unit.global_position.distance_to(lowest.global_position) > unit.global_position.distance_to(model.global_position)):
			print(unit.global_position)
			print(model.global_position)
			print(lowest.global_position)
			lowest = model
		
	return lowest

func shoot(unit: CharacterBody2D):
	if (current_phase != PHASES.SHOOTING):
		return

	var result: Array
	var all_units = selected_unit.whole_unit
	all_units.append(selected_unit)

	for unit1 in all_units:
		for weapon in unit1.ranged:	
			var groups: Array = unit.get_groups()
			var returned = game_node.shoot_at(unit1, unit, weapon)
			var found:bool = false

			for find in units.get_children():
				if find.get_child(0) == unit: 
					found = true
					break
			if (not found):
				unit = find_next_enemy(groups, unit1)
				if (unit == null):
					result.append(returned)
					break

			if (len(returned) < 5):
				game_node.parse_shoot_at_result(returned)
				deselect()
				deselect_proxy(all_units)
				return
				
			result.append(returned)
		
	deselect_proxy(all_units)
	game_node.parse_shoot_at_result(result)
	deselect()
		
func charge(unit: CharacterBody2D):
	if (current_phase != PHASES.CHARGE):
		return
	var all_units = selected_unit.whole_unit
	all_units.append(selected_unit)
	var result = game_node.charge_at(selected_unit, unit)
	if result == [-1] or result == [-2] or result == [-3] or result == [-4] or result == [-5]:
		reset_charge(unit)
		game_node.parse_charge_at_result(result)
		return
	game_node.parse_charge_at_result([0])
	game_node.move_after_charge(selected_unit, unit)

func fight(unit: CharacterBody2D):
	if (current_phase != PHASES.FIGHT):
		return

	var result: Array
	var all_units = selected_unit.whole_unit
	all_units.append(selected_unit)

	for unit1 in all_units:

		var groups: Array = unit.get_groups()
		var returned = game_node.fight(unit1, unit)
		var found:bool = false

		for find in units.get_children():
			if find.get_child(0) == unit: 
				found = true
				break
		if (not found):
			unit = find_next_enemy(groups, unit1)
			if (unit == null):
				result.append(returned)
				break

		if (len(returned) < 5):
			game_node.parse_fight_result(returned)
			deselect()
			deselect_proxy(all_units)
			return
			
		result.append(returned)
		
	deselect_proxy(all_units)
	game_node.parse_fight_result(result)
	deselect()
	

func reset_charge(unit:CharacterBody2D):
	for model in get_node("/root/Game/Map/Units").get_children():
		model = model.get_child(0)
		model.fights_first = false
		model.got_charged = false
		
func set_selected(unit: CharacterBody2D):
	if (selected_unit and selected_unit != unit):
		shoot(unit)
		charge(unit)
		fight(unit)
	else: 
		selected_unit = unit
		selected_unit.select()

func deselect_proxy(all_units: Array):
	for unit1 in all_units:
		unit1.deselect()

func deselect():
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null

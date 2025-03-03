extends Node2D

@export var unit_scene: PackedScene
@export var Plague_Marine: UnitData
@export var Blightlord_Terminator: UnitData
var selected_model: CharacterBody2D
var nodes_in_detector: Array = []
var log: Label

func _ready() -> void:
	log = $HUD/Log

func _process(delta: float) -> void:
	if selected_model:
		selected_model.get_node("Sprite2D").modulate = Color(0, 5, 0)
		selected_model.start_position = global_position
		selected_model.movement_ghost.global_position = get_global_mouse_position()

func spawn(name: String, ranged: Array[RangedWeaponResource], melee: Array[MeleeWeaponResource]):
	spawn_loop(name, GameManager.amount_of_units, ranged, melee)
	GameManager.amount_of_units += 1
	
func spawn_loop(name: String, group: int, ranged: Array[RangedWeaponResource], melee: Array[MeleeWeaponResource]):
	var unit = unit_scene.instantiate()
	var character_body = unit.get_child(0)  
	character_body.unit_data = load("res://Resources/"+name+"/"+name+".tres")
	# Check if the button is disabled correctly
	if $HUD/SelectorButton/Side.button_pressed:
		character_body.add_to_group("Player Two")
	else: 
		character_body.add_to_group("Player One")
	$Map/Units.add_child(unit)

	character_body.add_to_group("Unit: " + str(group))
		
	var counter : int = 0
	var position : Vector2 = character_body.global_position
	
	character_body.spawning = true
	selected_model = character_body

	while not can_move_to(position):
		if (counter > 1000): 
			$HUD/Log.text = "Couldn't find a position."
			character_body.queue_free()
			break	
		position = Vector2(randi_range(-100, 100), randi_range(-100, 100))
		counter += 1

	character_body.ranged = ranged
	character_body.melee = melee
	character_body.spawning = false
	selected_model = null
	character_body.position = position
	
func fight(attacker:CharacterBody2D, enemy: CharacterBody2D) -> Array:
	
	#check groups
	if (&"Player One" in attacker.get_groups() and &"Player One" in enemy.get_groups()) or (&"Player Two" in attacker.get_groups() and &"Player Two" in enemy.get_groups()):
		return [-1]
	
	if attacker.charged_at != enemy:
		return [-2]
		
	#check acted
	if (attacker.acted_this_phase):
		return [-5]
	attacker.acted_this_phase = true
		
	var damage_done:int = 0
	var succeded_hits: int = 0
	var succeded_wounds: int = 0
	var failed_saves: int = 0
	
	for i in range(0, attacker.unit_data.A):
		#check HIT ROLL
		if (randi_range(1, 7) >= attacker.unit_data.WS):
			succeded_hits+=1
		else: continue

		#check WOUND ROLL

		var needed_to_wound:int = 4
		if (attacker.unit_data.S >= 2 * enemy.unit_data.T):
			needed_to_wound = 2
		else: if (attacker.unit_data.S > enemy.unit_data.T):
			needed_to_wound = 3
		else: if (attacker.unit_data.S <= 0.5 * enemy.unit_data.T):
			needed_to_wound = 6
		else: if (attacker.unit_data.S < enemy.unit_data.T):
			needed_to_wound = 5
		if (randi_range(1, 7) >= needed_to_wound):
			succeded_wounds+=1
		else: continue

		if (randi_range(1, 7)-attacker.unit_data.AP < enemy.unit_data.SV):
			failed_saves+=1

	damage_done = failed_saves * attacker.unit_data.D
	enemy.WOUNDS -= damage_done + 10

	if (enemy.WOUNDS <= 0): 
		enemy.queue_free()
		get_node("/root/Game/Map/Units").remove_child(enemy.get_parent())

	var result: Array = []
	result.append(succeded_hits)
	result.append(succeded_wounds)
	result.append(failed_saves)
	result.append(damage_done)
	result.append(attacker.unit_data.A)
	return result
	
func parse_fight_result(array: Array):
	return
	
func charge_at(charger: CharacterBody2D, enemy: CharacterBody2D) -> Array:
	
	if (charger.got_charged):
		return [-4]
	
	var move_distance: int = 0
	move_distance = randi_range(1, 13) * 10
	
	#check groups
	if (&"Player One" in charger.get_groups() and &"Player One" in enemy.get_groups()) or (&"Player Two" in charger.get_groups() and &"Player Two" in enemy.get_groups()):
		return [-1]
		
	var all = charger.whole_unit
	all.append(charger)
	for model in all:
		#check distance
		if (move_distance + 1 + charger.unit_data.SIZE/2 + enemy.unit_data.SIZE/2 < model.global_position.distance_to(enemy.global_position)):
			return [-3]
		#check line of sight
		if not check_line_of_sight(charger, enemy):
			return [-2]
		if (charger.acted_this_phase):
			return [-5]
	
		model.fights_first = true
		
	for model in enemy.whole_unit:
		model.got_charged = true
	enemy.got_charged = true
	
	charger.charged_at = enemy
	
	return [0]

func move_after_charge(charger: CharacterBody2D, enemy: CharacterBody2D):
	var all = charger.whole_unit.duplicate()
	all.append(charger)  # Include the leader in movement
	var temp = selected_model  # Save selected model

	var max_attempts = 30  # Prevent infinite looping
	var used_positions = []  # Track occupied spots

	for model in all:
		var attempts = 0
		var found_valid_position = false

		# Calculate the direction vector from the model's original position to the enemy
		var direction = (enemy.global_position - model.global_position).normalized()
		var step_back = 10 + model.unit_data.SIZE / 2  # Initial step back distance
		var target_pos = enemy.global_position - (direction * step_back)

		while attempts < max_attempts:
			# Check if the position is free
			if can_move_to(target_pos) and target_pos not in used_positions:
				model.global_position = target_pos
				used_positions.append(target_pos)
				found_valid_position = true
				break

			# Move further back along the direction vector
			step_back += 5  # Increase distance back each time
			target_pos = enemy.global_position - (direction * step_back)
			attempts += 1

		# If no valid position was found, try slight side adjustments
		if not found_valid_position:
			for _i in range(5):
				var side_offset = Vector2(randi_range(-5, 5), randi_range(-5, 5))
				var new_pos = target_pos + side_offset
				if can_move_to(new_pos):
					model.global_position = new_pos
					used_positions.append(new_pos)
					break

		selected_model = temp  # Restore selected model


func parse_charge_at_result(array: Array):
	if (array == [-1]):
		log.text = "Can't attack own models"
		return
	if (array == [-2]):
		log.text = "No line of sight"
		return
	if (array == [-3]):
		log.text = "Charge failed"
		return
	if (array == [-4]):
		log.text = "Model already got charged"
		return
	if (array == [-5]):
		log.text = "Already acted"
		return
	log.text = "Charge successful"
	return

func shoot_at(shooter:CharacterBody2D, enemy: CharacterBody2D, weapon: RangedWeaponResource) -> Array:
	
	#check groups
	if (&"Player One" in shooter.get_groups() and &"Player One" in enemy.get_groups()) or (&"Player Two" in shooter.get_groups() and &"Player Two" in enemy.get_groups()):
		return [-1]
	
	#check line of sight
	if (not check_line_of_sight(shooter, enemy)):
		return [-2]
	
	#check distance
	if (enemy.global_position.distance_to(shooter.global_position) > weapon.R):
		return [-3]
		
	#check acted
	if (shooter.acted_this_phase):
		return [-5]
	shooter.acted_this_phase = true
		
	var damage_done:int = 0
	var succeded_hits: int = 0
	var succeded_wounds: int = 0
	var failed_saves: int = 0
	
	
	var A = weapon.A
	if ("D" in A):
		var split = A.split("D")
		A = randi_range(1, int(split[1])+1)
		for i in range(0, int(split[0]) * A):
			#check HIT ROLL
			if (randi_range(1, 7) >= weapon.BS):
				succeded_hits+=1
			else: continue
	else:
		for i in range(0, int(A)):
			#check HIT ROLL
			if (randi_range(1, 7) >= weapon.BS):
				succeded_hits+=1
			else: continue

	for i in range(0, succeded_hits):
		var T = enemy.unit_data.T
		var S = weapon.S
		#check WOUND ROLL
		var needed_to_wound:int = 4
		if (S >= 2 * T):
			needed_to_wound = 2
		elif (S > T):
			needed_to_wound = 3
		elif (S <= 0.5 * T):
			needed_to_wound = 6
		elif (S < T):
			needed_to_wound = 5
		if (S >= 999):
			needed_to_wound = 0
		if (randi_range(1, 7) >= needed_to_wound):
			succeded_wounds+=1
		else: continue
		if (randi_range(1, 7) - weapon.AP < enemy.unit_data.SV):
			failed_saves+=1

	if "D" not in weapon.D:
		damage_done = failed_saves * int(weapon.D)
	else:
		var split = weapon.D.split("D")
		print(split)
		damage_done = int(split[0]) * randi_range(1, int(split[1])+1)
	enemy.WOUNDS -= damage_done

	if (enemy.WOUNDS <= 0): 
		enemy.queue_free()
		get_node("/root/Game/Map/Units").remove_child(enemy.get_parent())

	

	var result: Array = []
	result.append(succeded_hits)
	result.append(succeded_wounds)
	result.append(failed_saves)
	result.append(damage_done)
	result.append(int(A))
	return result

func parse_shoot_at_result(array: Array):

	if (array == [-1]): 
		log.text = "Can't attack your own models."
		return
	elif (array == [-2]): 
		log.text = "No line of sight!"
		return
	elif (array == [-3]): 
		log.text = "Distance too large!" 
		return
	elif (array == [-5]): 
		log.text = "Model already acted this phase!" 
		return
		
	var to_parse: Array = [0,0,0,0,0]
	if (typeof(array[0]) == TYPE_INT):
		array = [[array[0],array[1],array[2],array[3],array[4]]]
	
	for array1 in array:
		to_parse[0] += array1[0]
		to_parse[1] += array1[1]
		to_parse[2] += array1[2]
		to_parse[3] += array1[3]
		to_parse[4] += array1[4]
		
	log.text = (str(to_parse[0]) + " shots hit out of " + str(to_parse[4])+ ".\n" +
		str(to_parse[1]) + " shots wounded out of " + str(to_parse[0])+ ".\n" +
		str(to_parse[1] - to_parse[2]) + " successful saves out of " + str(to_parse[1]) + ".\n" +
		str(to_parse[3]) + " damage done.")

func can_move_to(target_position: Vector2) -> bool:
	
	var distance: float = selected_model.global_position.distance_to(target_position)
	
	if (distance + selected_model._moved_this_turn > selected_model.unit_data.M):
		if (not GameManager.current_phase == GameManager.PHASES.SETUP):
			log.text = "Distance too large to move"
			return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	query.shape = selected_model.get_node("CollisionShape2D").shape
	query.transform = Transform2D(0, target_position)
	query.exclude = [selected_model.get_rid()]

	var result = space_state.intersect_shape(query)
	
	if not result.is_empty():
		log.text = "Space occupied"
		return false
	
	return true

	
func check_line_of_sight(shooter: CharacterBody2D, enemy: CharacterBody2D):
	return true

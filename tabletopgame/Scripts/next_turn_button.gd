extends Button

func _ready() -> void:
	text = "START GAME"

# Stores phase transitions in a dictionary for readability
var phase_transitions = {
	GameManager.PHASES.SETUP_ONE: GameManager.PHASES.SETUP_TWO,
	GameManager.PHASES.SETUP_TWO: GameManager.PHASES.COMMAND,
	GameManager.PHASES.COMMAND: GameManager.PHASES.MOVEMENT,
	GameManager.PHASES.MOVEMENT: GameManager.PHASES.SHOOTING,
	GameManager.PHASES.SHOOTING: GameManager.PHASES.CHARGE,
	GameManager.PHASES.CHARGE: GameManager.PHASES.FIGHT,
	GameManager.PHASES.FIGHT: GameManager.PHASES.COMMAND
}

func _on_pressed() -> void:
	transition_phase()
	reset_unit_actions()

func transition_phase() -> void:
	var previous_phase = GameManager.current_phase
	GameManager.current_phase = phase_transitions.get(previous_phase, GameManager.PHASES.SETUP_ONE)

	if previous_phase == GameManager.PHASES.FIGHT:
		if GameManager.player_turn == 1:
			GameManager.player_turn = 2
		else:
			GameManager.player_turn = 1
		reset_unit_charges()
	if previous_phase == GameManager.PHASES.SETUP_ONE:
		initiate()
	if previous_phase == GameManager.PHASES.SETUP_TWO:
		start_game()
	text = "PLAYER " + str(GameManager.player_turn) +", PHASE: " + GameManager.PHASES.find_key(GameManager.current_phase)

func initiate() -> void:
	visible = false
	$"../StartFirst".visible = true
	$"../StartSecond".visible = true
	GameManager.player_turn = randi_range(1, 2)
	$"../ExplanationLabel".text += "\nPlayer " + str(GameManager.player_turn) + " gets to choose who starts"
	
func start_game() -> void:
	visible = true
	$"../StartFirst".visible = false
	$"../StartSecond".visible = false
	$"../SelectorButton".visible = false
	$"../ExplanationLabel".visible = false
	return

func reset_unit_charges() -> void:
	for unit in $"../../Map/Units".get_children():
		GameManager.reset_charge(unit.get_child(0))

func reset_unit_actions() -> void:
	for unit in $"../../Map/Units".get_children():
		var unit_node = unit.get_node("Unit")
		unit_node.acted_this_phase = false
		unit_node._moved_this_turn = 0

func _on_start_second_pressed() -> void:
	if (GameManager.player_turn == 1):
		GameManager.player_turn = 2
	if (GameManager.player_turn == 2):
		GameManager.player_turn = 1
	transition_phase()

func _on_start_first_pressed() -> void:
	transition_phase()

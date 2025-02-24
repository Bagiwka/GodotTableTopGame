extends Button

func _ready() -> void:
	text = "START GAME"
	
func _on_pressed() -> void:
	match GameManager.current_phase:
		GameManager.PHASES.SETUP:
			$"../SelectorButton".visible = false
			GameManager.current_phase = GameManager.PHASES.COMMAND
			text = "CURRENT PHASE: COMMAND"
		GameManager.PHASES.COMMAND:
			GameManager.current_phase = GameManager.PHASES.MOVEMENT
			text = "CURRENT PHASE: MOVEMENT"
		GameManager.PHASES.MOVEMENT:
			GameManager.current_phase = GameManager.PHASES.SHOOTING
			text = "CURRENT PHASE: SHOOTING"
		GameManager.PHASES.SHOOTING:
			GameManager.current_phase = GameManager.PHASES.CHARGE
			text = "CURRENT PHASE: CHARGE"
		GameManager.PHASES.CHARGE:
			GameManager.current_phase = GameManager.PHASES.FIGHT
			text = "CURRENT PHASE: FIGHT"
		GameManager.PHASES.FIGHT:
			GameManager.current_phase = GameManager.PHASES.COMMAND
			for unit in $"../../Map/Units".get_children():
				GameManager.reset_charge(unit.get_child(0))
			text = "CURRENT PHASE: COMMAND"
	reset_actions()

		
func reset_actions():
	for unit in $"../../Map/Units".get_children():
		unit = unit.get_node("Unit")
		unit.acted_this_phase = false
		unit._moved_this_turn = 0

extends Label

var selected: CharacterBody2D
var game_node: Node2D

func _ready() -> void:
	game_node = $"../.."
	
func _process(delta: float) -> void:
	if selected:
		var text1 = "Movement: " + str(selected.get_distance())
		if (GameManager.current_phase == GameManager.PHASES.MOVEMENT or GameManager.current_phase == GameManager.PHASES.CHARGE):
			text = text1 + " / " + str(snapped(selected.unit_data.M-selected._moved_this_turn,0.1))
		else:
			text = text1
		global_position = get_global_mouse_position() + Vector2(20,20)

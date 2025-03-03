extends CharacterBody2D

@export var unit_data: UnitData

var _moved_this_turn: float = 0.0
var _selected:bool = false
var movement_label: Label
var movement_ghost: Sprite2D
var start_position: Vector2
var log: Label
var WOUNDS: int
var color = Color(1,1,1)
var whole_unit: Array = []
var spawning: bool = false
var acted_this_phase: bool = false
var got_charged: bool = false
var fights_first: bool = false
var charged_at : CharacterBody2D = null
var melee: Array[MeleeWeaponResource] = []
var ranged: Array[RangedWeaponResource] = []

func _ready():
	movement_ghost = $Ghost
	movement_label = (get_node("/root/Game/HUD/Distance"))
	log = (get_node("/root/Game/HUD/Log"))
	WOUNDS = unit_data.duplicate().W
	
	set_unit_size(unit_data.SIZE)
	
	if &"Player 1" in get_groups():
		color = Color(5, 0, 0)
	else:
		color = Color(0, 0, 5)
	$Sprite2D.modulate = color

func get_distance()-> float:
	var start_position = global_position
	var distance = start_position.distance_to(get_global_mouse_position())
	return (snapped(distance, 0.1))
	
func set_unit_size(size: float):
	var sprite := $Sprite2D
	var texture_size = sprite.texture.get_size()
	var texture_size_ghost = movement_ghost.texture.get_size()

	if texture_size.x > 0 and texture_size.y > 0:
		var scale_factor = size / max(texture_size.x, texture_size.y)
		sprite.scale = Vector2(scale_factor, scale_factor)
		
	if texture_size_ghost.x > 0 and texture_size_ghost.y > 0:
		var scale_factor_ghost = size / max(texture_size_ghost.x, texture_size_ghost.y)
		movement_ghost.scale = Vector2(scale_factor_ghost, scale_factor_ghost)
		
	var collider := $CollisionShape2D
	if collider.shape is CircleShape2D:
		collider.shape.radius = size/2

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not GameManager.selected_unit:
			var current_player_group = "Player " + str(GameManager.player_turn)
			if not GameManager.current_phase == GameManager.PHASES.SETUP_ONE and not GameManager.current_phase == GameManager.PHASES.SETUP_TWO:
				if not current_player_group in get_groups():
					log.text = "It's not your turn to select this unit!"
					return
		if not self in GameManager.to_unify:
			if (GameManager.current_phase == GameManager.PHASES.SETUP_ONE or GameManager.current_phase == GameManager.PHASES.SETUP_TWO):
				if (GameManager.to_unify_group == "" or GameManager.to_unify_group in self.get_groups()):
					$Sprite2D.modulate = Color(0, 5, 0)
					GameManager.to_unify.append(self)
					for group in get_groups():
						if group.begins_with("Player "):
							GameManager.to_unify_group = group
					if (GameManager.to_unify.size() > 1):
						get_node("/root/Game/HUD/SelectorButton/UnifyButton").visible = true
				else:
					log.text = "Deselect before selecting units of the opposite player"
		
		if GameManager.selected_unit != self:
			GameManager.set_selected(self)
		else:
			log.text = ""
			deselect()
			GameManager.deselect()


func proxy_select():
	$Sprite2D.modulate = Color(0, 2, 0)

func select():
	for unit in $"..".get_parent().get_children():
		var model = unit.get_child(0)
		if (model != self and model != null):
			if (model.get_groups() == get_groups()):
				if (not GameManager.current_phase == GameManager.PHASES.SETUP_ONE and not GameManager.current_phase == GameManager.PHASES.SETUP_TWO):
					model.proxy_select()
				if not model in whole_unit:
					whole_unit.append(model)
	
	_selected = true
	start_position = global_position
	movement_label.visible = true
	movement_ghost.visible = true
	log.text = "Selected: " + unit_data.NAME
	get_node("/root/Game").selected_model = self
	get_node("/root/Game/HUD/Distance").selected = self

func deselect():
	whole_unit.erase(self)
	for model in whole_unit:
		model.deselect()
	whole_unit = []
	$Sprite2D.modulate = color
	_selected = false
	movement_label.visible = false
	movement_ghost.visible = false
	get_node("/root/Game").selected_model = null
	get_node("/root/Game/HUD/Distance").selected = null
	get_node("/root/Game/HUD/SelectorButton/UnifyButton").visible = false
	

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _selected:
				return
			if (GameManager.current_phase != GameManager.PHASES.MOVEMENT and GameManager.current_phase != GameManager.PHASES.SETUP_ONE and GameManager.current_phase != GameManager.PHASES.SETUP_TWO):
				log.text = "Can't Move in the current phase."
				return
			var target_position = get_global_mouse_position()
			if _selected and get_node("/root/Game").can_move_to(target_position):
				if GameManager.current_phase == GameManager.PHASES.MOVEMENT:
					_moved_this_turn += global_position.distance_to(target_position)
				global_position = target_position
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			GameManager.to_unify_group = ""
			GameManager.to_unify = []
			log.text = ""
			_selected = false
			movement_label.visible = false
			movement_ghost.visible = false
			deselect()
			GameManager.deselect()

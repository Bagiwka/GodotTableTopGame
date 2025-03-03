extends MenuButton

var unit_data = {}  # Dictionary to store loaded unit data
var selection_menu
var weapon_selection_menu = PopupMenu.new()
var spawn_button: Button
var selected_unit_name = ""
var selected_weapons = []
var selected_melee = []
var log: Label

func _ready() -> void:
	log = $"../Log"
	spawn_button = $FinishSpawningButton
	selection_menu = $'.'
	selection_menu.text = "Model Selection"

	# Load unit data from JSON file
	var json_path = "res://Data/Units.json"  # Adjust the path if needed
	unit_data = load_json(json_path)

	if unit_data.is_empty():
		log.text=("Error: Failed to load unit data!")
		return

	setup_menus()

func load_json(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			return json.data
		else:
			log.text=("JSON Parse Error: "+ error)
	else:
		log.text=("Error: Failed to open JSON file: "+ file_path)

	return {}

func setup_menus():
	for alliance in unit_data:
		var alliance_submenu = PopupMenu.new()
		alliance_submenu.name = alliance
		get_popup().add_submenu_node_item(alliance_submenu.name, alliance_submenu)
		
		for faction in unit_data[alliance]:
			var faction_submenu = PopupMenu.new()
			faction_submenu.name = faction
			alliance_submenu.add_submenu_node_item(faction_submenu.name, faction_submenu)
			
			for model in unit_data[alliance][faction]:
				var model_name = model
				var model_id = faction_submenu.get_item_count()
				faction_submenu.add_item(model_name, model_id)
				
				if not faction_submenu.id_pressed.is_connected(_on_unit_selected):
					faction_submenu.id_pressed.connect(_on_unit_selected.bind(faction_submenu))

	# Set up weapon selection menu
	weapon_selection_menu.name = "Weapon Selection"
	weapon_selection_menu.id_pressed.connect(_on_weapon_selected)
	add_child(weapon_selection_menu)

	# Create Spawn Button
	spawn_button.text = "Spawn Unit"
	spawn_button.visible = false
	spawn_button.pressed.connect(_on_spawn_pressed)

func _on_unit_selected(id: int, submenu: PopupMenu):
	selected_unit_name = submenu.get_item_text(id)

	# Find selected unit in loaded JSON data
	for alliance in unit_data:
		for faction in unit_data[alliance]:
			if selected_unit_name in unit_data[alliance][faction]:
				var unit_info = unit_data[alliance][faction][selected_unit_name]

				# Show weapon selection menu
				weapon_selection_menu.clear()
				selected_weapons.clear()
				selected_melee.clear()

				weapon_selection_menu.add_separator("Ranged")
				for weapon in unit_info["ranged"]:
					weapon_selection_menu.add_check_item(weapon)

				weapon_selection_menu.add_separator("Melee")
				for weapon in unit_info["melee"]:
					weapon_selection_menu.add_check_item(weapon)
				
				weapon_selection_menu.hide_on_checkable_item_selection = false
				weapon_selection_menu.popup()

				# Show Spawn Button
				spawn_button.visible = true
				return

func _on_weapon_selected(id: int):
	var weapon_name = weapon_selection_menu.get_item_text(id)
	weapon_selection_menu.toggle_item_checked(id)
	
	if weapon_selection_menu.is_item_checked(id):
		for alliance in unit_data:
			for faction in unit_data[alliance]:
				if selected_unit_name in unit_data[alliance][faction]:
					var unit_info = unit_data[alliance][faction][selected_unit_name]
					if weapon_name in unit_info["ranged"]:
						selected_weapons.append(weapon_name)
					else: 
						selected_melee.append(weapon_name)
	else:
		selected_weapons.erase(weapon_name)
		selected_melee.erase(weapon_name)

func _on_spawn_pressed():
	if selected_unit_name == "":
		log.text=("Error: No unit selected!")
		return

	if selected_weapons.size() == 0 and selected_melee.size() == 0:
		log.text=("Error: No weapons selected!")
		return

	var spawn_function = ""
	for alliance in unit_data:
		for faction in unit_data[alliance]:
			if selected_unit_name in unit_data[alliance][faction]:
				spawn_function = unit_data[alliance][faction][selected_unit_name]["spawn_function"]
				break

	if spawn_function == "":
		log.text=("Error: Spawn function not found!")
		return

	selected_unit_name = selected_unit_name.replace(" ", "_")
	var unit_resource = load("res://Resources/"+selected_unit_name+"/"+selected_unit_name+".tres")

	var game = get_node_or_null("/root/Game")
	
	var new_melee: Array[MeleeWeaponResource]
	var new_ranged: Array[RangedWeaponResource]
	
	for melee in selected_melee:
		melee = melee.replace(" ", "_").replace("-","_")
		new_melee.append(load("res://Resources/"+selected_unit_name+"/Melee/" + melee + ".tres"))
	for ranged in selected_weapons:
		ranged = ranged.replace(" ", "_").replace("-","_")
		new_ranged.append(load("res://Resources/"+selected_unit_name+"/Ranged/" + ranged + ".tres"))
	
	if game:
		game.spawn(selected_unit_name, new_ranged, new_melee)

	spawn_button.visible = false
	selected_unit_name = ""
	selected_weapons.clear()
	selected_melee.clear()


func _on_unify_button_pressed() -> void:
	for model in GameManager.to_unify:
		for group in model.get_groups():
			if group.begins_with("Unit: "):
				model.remove_from_group(group)
		model.add_to_group("Unit: " + str(GameManager.amount_of_units))
	GameManager.amount_of_units += 1
	log.text = "Unified to one unit"

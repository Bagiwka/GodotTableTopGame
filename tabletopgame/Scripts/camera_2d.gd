extends Camera2D

@export var move_speed: float = 250.0  # Adjust movement speed
var dragging = false
var previous: Vector2

func _process(delta: float):
	# Keyboard movement
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	# Normalize to avoid faster diagonal movement
	if direction.length() > 0:
		position += direction.normalized() * move_speed * delta

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = true
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		var mouse_pos = get_global_mouse_position()
		var direction = previous.direction_to(mouse_pos)  # Get direction vector
		position -= direction / zoom  # Adjust move speed factor 

	previous = get_global_mouse_position()

	# Zoom functionality
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if zoom.x > 1:
				zoom -= Vector2(0.1, 0.1)  # Adjust zoom scale
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if zoom.x < 5:
				zoom += Vector2(0.1, 0.1)

extends Node2D

var dragging = false
var selected = []
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var drag_stop = Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start = event.position
			queue_redraw()
		elif dragging:
			dragging = false	
			queue_redraw()
			drag_stop = event.position
			var space = get_world_2d().direct_space_state
			var query = PhysicsShapeQueryParameters2D.new()
			query.shape = select_rect
			query.collision_mask = 1
			query.transform = Transform2D(0, (drag_stop + drag_start) / 2)
			selected = space.intersect_shape(query)

	elif event is InputEventMouseMotion and dragging:
		queue_redraw()

func _draw():
	if dragging:
		var mouse_pos = get_global_mouse_position()
		var rect = Rect2(drag_start, mouse_pos - drag_start)
		draw_rect(rect, Color(.5, .5, .5), false)

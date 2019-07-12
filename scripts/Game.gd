extends Node2D


export(String, FILE, "*.tscn") var menu


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			var error = get_tree().change_scene(menu)
			if error != OK:
				print("Error while attempting to change scenes: " + str(error))
			get_tree().set_input_as_handled()

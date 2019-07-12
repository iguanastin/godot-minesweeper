extends Control


export(String, FILE, "*.tscn") var game


func _on_Exit_button_up():
	get_tree().quit()

func _start_game(difficulty):
	GameSettings.difficulty = difficulty
	var error = get_tree().change_scene(game)
	if error != OK:
		print("Error while attempting to change scenes: " + str(error))

func _on_Easy_button_up():
	_start_game("easy")

func _on_Medium_button_up():
	_start_game("medium")

func _on_Hard_button_up():
	_start_game("hard")
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()

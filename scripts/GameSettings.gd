extends Node


# warning-ignore:unused_class_variable
export var difficulty = "easy"
# warning-ignore:unused_class_variable
export(String, FILE, "*.json") var save_file = "user://minesweeper.json"


func _unhandled_key_input(event):
	if event.pressed:
		if event.scancode == KEY_F11 or (event.scancode == KEY_ENTER and event.alt):
			OS.window_fullscreen = !OS.window_fullscreen

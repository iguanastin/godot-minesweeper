extends TileMap

export(int) var width = 9
export(int) var height = 9
export(int) var mines = 10
export(String) var difficulty = "easy"

export(int) var hidden_tile = 0
export(int) var marked_tile = 1
export(int) var bomb_tile = 2
export(int) var count_tile_offset = 3

export(NodePath) onready var time_label = get_node(time_label)
export(NodePath) onready var game_over_label = get_node(game_over_label)

var map
var time = 0
var game_over = false


func _ready():
	randomize()
	
	self.difficulty = GameSettings.difficulty
	width = 9
	height = 9
	mines = 10
	if GameSettings.difficulty == "medium":
		width = 16
		height = 16
		mines = 40
	if GameSettings.difficulty == "hard":
		width = 24
		height = 24
		mines = 99
	
	_init_tiles()
	_init_map()
	_init_bombs()
	_init_counts()
	
	# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, "_on_size_changed")
	_on_size_changed()

func _on_size_changed():
	position.x = get_viewport().size.x / 2 - (width * cell_size.x) / 2
	position.y = get_viewport().size.y / 2 - (height * cell_size.y) / 2

func _init_counts():
	for x in range(width):
		for y in range(height):
			if map[x][y] == -1:
				continue
				
			var count = 0
			if x > 0 and map[x-1][y] == -1:
				count += 1
			if x > 0 and y > 0 and map[x-1][y-1] == -1:
				count += 1
			if x > 0 and y < height-1 and map[x-1][y+1] == -1:
				count += 1
			if y > 0 and map[x][y-1] == -1:
				count += 1
			if y < height-1 and map[x][y+1] == -1:
				count += 1
			if x < width-1 and map[x+1][y] == -1:
				count += 1
			if x < width-1 and y > 0 and map[x+1][y-1] == -1:
				count += 1
			if x < width-1 and y < height-1 and map[x+1][y+1] == -1:
				count += 1
			
			map[x][y] = count
	
func _init_bombs():
	var m = mines
	while m > 0:
		var x = randi() % width
		var y = randi() % height
		if map[x][y] == 0:
			map[x][y] = -1
			m -= 1

func _init_map():
	map = []
	for x in range(width):
		map.append([])
		# warning-ignore:unused_variable
		for y in range(height):
			map[x].append(0)

func _init_tiles():
	for x in range(width):
		for y in range(height):
			set_cell(x, y, hidden_tile)

func _reveal_tile(x, y):
	var tile = map[x][y]
	
	if tile >= 0:
		set_cell(x, y, count_tile_offset + tile)
		
	if tile == 0:
		if x > 0 and get_cell(x-1, y) == hidden_tile:
			_reveal_tile(x-1, y)
		if x > 0 and y > 0 and get_cell(x-1, y-1) == hidden_tile:
			_reveal_tile(x-1, y-1)
		if x > 0 and y < height-1 and get_cell(x-1, y+1) == hidden_tile:
			_reveal_tile(x-1, y+1)
		if y > 0 and get_cell(x, y-1) == hidden_tile:
			_reveal_tile(x, y-1)
		if y < height-1 and get_cell(x, y+1) == hidden_tile:
			_reveal_tile(x, y+1)
		if x < width-1 and get_cell(x+1, y) == hidden_tile:
			_reveal_tile(x+1, y)
		if x < width-1 and y > 0 and get_cell(x+1, y-1) == hidden_tile:
			_reveal_tile(x+1, y-1)
		if x < width-1 and y < height-1 and get_cell(x+1, y+1) == hidden_tile:
			_reveal_tile(x+1, y+1)
	
	if tile == -1:
		_game_over("Game Over")
		for x in range(width):
			for y in range(height):
				if map[x][y] == -1:
					set_cell(x, y, bomb_tile)
	
	if _is_game_win() and not game_over:
		_game_over("You win!")
		_save_time(stepify(time, 0.01))

func _save_time(time):
	var file = File.new()
	if file.file_exists(GameSettings.save_file):
		file.open(GameSettings.save_file, File.READ)
		var json = JSON.parse(file.get_as_text())
		file.close()
		
		if json.error == OK:
			json = json.result
			
			var a = json["leaderboard"][difficulty]
			a.append(time)
			a.sort()
			if a.size() > 10:
				a.pop_back()
			
			file = File.new()
			file.open(GameSettings.save_file, File.WRITE)
			file.store_line(to_json(json))
			file.close()
		else:
			print("Error reading JSON: " + GameSettings.save_file)
			_init_save_file(difficulty, time)
	else:
		print("No JSON file found: " + GameSettings.save_file)
		_init_save_file(difficulty, time)

func _init_save_file(difficulty, time):
	var json = {"leaderboard": {"easy": [], "medium": [], "hard": []}}
	json["leaderboard"][difficulty].append(time)
	
	var file = File.new()
	file.open(GameSettings.save_file, File.WRITE)
	file.store_line(to_json(json))
	file.close()

func _game_over(text):
	game_over = true
	game_over_label.set_text(text)
	game_over_label.show()
	game_over_label.rect_position.x = (width * cell_size.x) / 2 - game_over_label.rect_size.x / 2
	game_over_label.rect_position.y = (height * cell_size.y) / 2 + game_over_label.rect_size.y
	time_label.set_text("Time: " + str(stepify(time, 0.01)) + "s")

func _is_game_win():
	for x in range(width):
		for y in range(height):
			var cell = get_cell(x, y)
			if (cell == hidden_tile or cell == marked_tile) and map[x][y] != -1:
				return false
	
	return true

func _cell_clicked(x, y, button):
	var cell = get_cell(x, y)
	if cell == hidden_tile:
		if button == BUTTON_LEFT:
			_reveal_tile(x, y)
		elif button == BUTTON_RIGHT:
			set_cell(x, y, marked_tile)
	elif cell == marked_tile:
		if button == BUTTON_RIGHT:
			set_cell(x, y, hidden_tile)

func _process(delta):
	if not game_over:
		time += delta
		time_label.set_text("Time: " + str(int(time)) + "s")

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var pos = event.global_position - position
		if not game_over and pos.x > 0 and pos.y > 0 and pos.x < width * cell_size.x and pos.y < height * cell_size.y:
			_cell_clicked(int(pos.x / cell_size.x), int(pos.y / cell_size.y), event.button_index)


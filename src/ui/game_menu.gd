class_name GameMenu
extends PanelContainer
## In-game menu (F10 or the Menu button): pauses a local or hosted game while open; resume,
## save, load, restart, back to the main menu, quit.

var game: Game
var _speed_before := 1.0


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "GameMenu"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(260, 0)
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(HudStyle.header("Paused" if not game.is_client() else "Menu"))
	var hosting := not game.is_client()
	_add(column, "Resume", close)
	_add(column, "Save game", func() -> void: game.quicksave(); close(), hosting)
	_add(column, "Load game", func() -> void: game.quickload(), hosting and FileAccess.file_exists(Game.QUICKSAVE))
	_add(column, "Restart match", game.restart, hosting)
	_add(column, "Main menu", game.quit_to_menu)
	_add(column, "Quit game", func() -> void: get_tree().quit())


func open() -> void:
	if visible:
		return
	visible = true
	if not game.is_client():
		_speed_before = game.speed if game.speed > 0.0 else 1.0
		game.speed = 0.0


func close() -> void:
	if not visible:
		return
	visible = false
	if not game.is_client():
		game.speed = _speed_before


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _add(column: VBoxContainer, text: String, action: Callable, enabled := true) -> void:
	var button := HudStyle.button(text)
	button.name = text.replace(" ", "")
	button.custom_minimum_size.y = 36
	button.disabled = not enabled
	button.pressed.connect(action)
	column.add_child(button)

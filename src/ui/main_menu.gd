class_name MainMenu
extends Control
## Entry scene: pick a map and how to play (single player, host co-op, join co-op), then
## start. Any game option on the command line (--map, --demo, --host, --join, ...) skips the
## menu and goes straight into the game.

const GAME_SCENE := "res://scenes/main.tscn"
const MAPS_DIR := "res://data/maps"
## User args that mean "start the game right away".
const DIRECT_ARGS: Array[String] = ["map", "demo", "host", "join", "screenshot", "no-waves"]

enum Mode { SINGLE, HOST, JOIN }

var map_id := "test_map"
var mode := Mode.SINGLE
var waves := true
var address := "127.0.0.1"
var port := NetProtocol.DEFAULT_PORT
var _address_row: HBoxContainer
var _port_row: HBoxContainer


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.substr(2).get_slice("=", 0) in DIRECT_ARGS:
			get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
			return
	_build()


## The Game options for the current choices.
func game_options() -> Dictionary:
	var out := {"map": map_id}
	if not waves:
		out["no-waves"] = true
	match mode:
		Mode.HOST:
			out["host"] = str(port)
		Mode.JOIN:
			out = {"join": "%s:%d" % [address, port]}
	return out


func start() -> void:
	Game.options = game_options()
	get_tree().change_scene_to_file(GAME_SCENE)


## Map ids and names found in data/maps.
static func available_maps() -> Array[Array]:
	var out: Array[Array] = []
	for file in DirAccess.get_files_at(MAPS_DIR):
		if file.ends_with(".json"):
			var layout := MapLayout.load_file(MAPS_DIR.path_join(file))
			out.append([layout.id, layout.display_name])
	return out


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.07, 0.07, 0.09)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := HudStyle.panel("Menu")
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(380, 0)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := HudStyle.label("Fortress Survival 2", 32, HudStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	column.add_child(HudStyle.label("Map", 13, HudStyle.TEXT_DIM))
	var map_group := ButtonGroup.new()
	for entry in available_maps():
		var id: String = entry[0]
		var button := SandboxSpawnPanel._choice(column, map_group, entry[1], id == map_id)
		button.name = "map_%s" % id
		button.pressed.connect(func() -> void: map_id = id)

	column.add_child(HudStyle.label("Play", 13, HudStyle.TEXT_DIM))
	var modes := SandboxSpawnPanel._grid(column, 3)
	var mode_group := ButtonGroup.new()
	for entry: Array in [[Mode.SINGLE, "Single player"], [Mode.HOST, "Host co-op"], [Mode.JOIN, "Join co-op"]]:
		var value: Mode = entry[0]
		var button := SandboxSpawnPanel._choice(modes, mode_group, entry[1], value == mode)
		button.name = "mode_%d" % value
		button.pressed.connect(func() -> void: _set_mode(value))
	_address_row = _field(column, "Host address", address, func(text: String) -> void: address = text)
	_port_row = _field(column, "Port", str(port), func(text: String) -> void:
		if text.is_valid_int():
			port = int(text))

	var waves_toggle := HudStyle.button("Waves on (off = sandbox)", "Without waves nothing attacks unless you spawn it", true)
	waves_toggle.name = "Waves"
	waves_toggle.button_pressed = waves
	waves_toggle.toggled.connect(func(on: bool) -> void: waves = on)
	column.add_child(waves_toggle)

	var start_button := HudStyle.button("Start")
	start_button.name = "Start"
	start_button.custom_minimum_size.y = 42
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(start)
	column.add_child(start_button)
	var quit := HudStyle.button("Quit")
	quit.name = "Quit"
	quit.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit)
	_set_mode(mode)


func _set_mode(value: Mode) -> void:
	mode = value
	_address_row.visible = mode == Mode.JOIN
	_port_row.visible = mode != Mode.SINGLE


func _field(parent: Control, label_text: String, value: String, changed: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(HudStyle.label(label_text, 13, HudStyle.TEXT_DIM))
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(changed)
	row.add_child(edit)
	parent.add_child(row)
	return row

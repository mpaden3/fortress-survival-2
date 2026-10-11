class_name EndScreen
extends PanelContainer
## Shown when the match is over (or the local Survivor fell): the result and a few numbers,
## then restart, main menu, or keep watching.

var game: Game
var title: Label
var stats: Label
## Enemies killed and buildings lost since the scene started (counted from events).
var kills := 0
var buildings_lost := 0
var _dismissed := false


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "EndScreen"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(340, 0)
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	title = HudStyle.label("", 34, HudStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	stats = HudStyle.label("", 15)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(stats)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	for entry: Array in [["Restart", game.restart], ["Main menu", game.quit_to_menu],
			["Keep watching", func() -> void: _dismissed = true; visible = false]]:
		var button := HudStyle.button(entry[0])
		button.name = String(entry[0]).replace(" ", "")
		button.custom_minimum_size = Vector2(100, 34)
		button.disabled = entry[0] == "Restart" and game.is_client()
		button.pressed.connect(entry[1])
		row.add_child(button)
	game.world.stepped.connect(_count)


## The headline for the local player, or "" while still playing.
func outcome() -> String:
	var world := game.world
	var result := world.match_system.result
	var alive: bool = world.players[game.local_player].alive
	if result == MatchSystem.Result.WON:
		return "Victory" if alive else "Your allies survived"
	if result == MatchSystem.Result.LOST or not alive:
		return "Defeat"
	return ""


func _process(_delta: float) -> void:
	if game == null or game.world == null:
		return
	var text := outcome()
	if text == "" or _dismissed:
		visible = false
		return
	visible = true
	title.text = text
	title.add_theme_color_override("font_color", HudStyle.HP_GOOD if text != "Defeat" else HudStyle.HP_LOW)
	var match_system := game.world.match_system
	var seconds := int(match_system.elapsed(game.world)) if match_system.active else game.world.tick / SimConstants.TICK_RATE
	stats.text = "Survived %02d:%02d\nEnemies killed: %d\nBuildings lost: %d" % [seconds / 60, seconds % 60, kills,
		buildings_lost]


func _count() -> void:
	var events := game.world.events
	kills += events.of_kind(SimEvents.Kind.ENEMY_KILLED).size()
	buildings_lost += events.of_kind(SimEvents.Kind.BUILDING_DESTROYED).size()

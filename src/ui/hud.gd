class_name Hud
extends CanvasLayer
## Classic RTS HUD: a top bar (resource, income, timer, enemies, speed), a bottom bar
## (minimap, selection, command card) and, in development builds, sandbox panels on the left
## (spawning) and right (speed, resource, god mode, view, performance). Plus the announcement
## banner, the last rejected command and the unit selection box.

var game: Game
var top_bar: HBoxContainer
var resource_label: Label
var clock_label: Label
var enemies_label: Label
var speed_label: Label
var minimap: Minimap
var selection: SelectionPanel
var command_card: CommandCard
var sandbox_spawn: SandboxSpawnPanel
var sandbox: SandboxPanel

const TOP_HEIGHT := 40.0
const BOTTOM_HEIGHT := 214.0
const SIDE_WIDTH := 196.0
const SIDE_MARGIN := 6.0

var _root: Control
var _left_scroll: ScrollContainer
var _right_scroll: ScrollContainer
var _banner: Label
var _message: Label
var _hint: Label
var _box: Panel
var _message_until := 0


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_top_bar()
	_build_bottom_bar()
	if OS.is_debug_build():
		_build_sandbox()

	_banner = HudStyle.label("", 52)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 70)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.visible = false
	_root.add_child(_banner)
	_message = _floating_label(-232)
	_hint = _floating_label(-256)
	_hint.add_theme_color_override("font_color", HudStyle.TEXT_DIM)

	_box = Panel.new()
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.3, 1.0, 0.4, 0.12)
	box_style.border_color = Color(0.3, 1.0, 0.4, 0.9)
	box_style.set_border_width_all(1)
	_box.add_theme_stylebox_override("panel", box_style)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.visible = false
	_root.add_child(_box)


func toggle_sandbox() -> void:
	if sandbox:
		_left_scroll.visible = not _left_scroll.visible
		_right_scroll.visible = _left_scroll.visible


## Called after each simulation step with that step's command results.
func show_results(results: Array[Dictionary]) -> void:
	for result in results:
		if not result["ok"] and result["command"].get("player") == game.builder.player_id:
			_message.text = "Can't %s: %s" % [String(result["command"]["type"]).replace("_", " "),
				String(result["reason"]).replace("_", " ")]
			_message_until = game.world.tick + 2 * SimConstants.TICK_RATE


func _process(_delta: float) -> void:
	if game == null or game.world == null:
		return
	var world := game.world
	var player := world.players[game.builder.player_id]
	var rules := world.defs.rules
	resource_label.text = "%s  %d   (+%d / min)" % [rules.primary_resource_name.capitalize(), player.resource,
		roundi(world.economy.income_per_minute(world, player.id))]
	if sandbox:
		_fit_side(_left_scroll, sandbox_spawn)
		_fit_side(_right_scroll, sandbox)
	var match_system := world.match_system
	if match_system.active:
		var left := ceili(match_system.remaining(world))
		clock_label.text = "Survive  %02d:%02d" % [left / 60, left % 60]
	else:
		var seconds := world.tick / SimConstants.TICK_RATE
		clock_label.text = "%02d:%02d  (no waves)" % [seconds / 60, seconds % 60]
	enemies_label.text = "Enemies  %d" % world.enemies.count()
	speed_label.text = "PAUSED" if game.speed == 0.0 else ("x%d" % game.speed if game.speed != 1.0 else "")
	_message.visible = world.tick < _message_until
	_hint.text = _mode_hint()
	_box.visible = game.builder.drag_rect.has_area()
	_box.position = game.builder.drag_rect.position
	_box.size = game.builder.drag_rect.size
	if match_system.result == MatchSystem.Result.WON and player.alive:
		_show_banner("VICTORY - you survived!", Color(0.4, 0.95, 0.4))
	elif not player.alive and match_system.result == MatchSystem.Result.RUNNING:
		_show_banner("Your Survivor died - spectating", HudStyle.HP_LOW)
	elif not player.alive:
		_show_banner("DEFEAT - your Survivor died", HudStyle.HP_LOW)
	elif match_system.announcement_tick >= 0 and world.tick - match_system.announcement_tick < 4 * SimConstants.TICK_RATE:
		_show_banner(match_system.announcement, HudStyle.GOLD)
	else:
		_banner.visible = false


func _mode_hint() -> String:
	var builder := game.builder
	if builder.selected_def:
		return "Placing %s: LMB place (drag paints walls, Shift queues), RMB / Esc cancel" \
			% game.world.defs.building(builder.selected_def).display_name
	if builder.attack_move_armed:
		return "Attack-move: click the target spot"
	if builder.blink_armed:
		return "Blink: click a free spot in range"
	return ""


func _build_top_bar() -> void:
	var bar := HudStyle.panel("TopBar")
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var box := bar.get_theme_stylebox("panel") as StyleBoxFlat
	box.set_content_margin_all(5)
	_root.add_child(bar)
	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 28)
	bar.add_child(top_bar)
	resource_label = HudStyle.label("", 16, HudStyle.GOLD)
	clock_label = HudStyle.label("", 16)
	enemies_label = HudStyle.label("", 16, Color(0.95, 0.5, 0.45))
	speed_label = HudStyle.label("", 16, HudStyle.GOLD)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var map_label := HudStyle.label(game.world.map.display_name, 14, HudStyle.TEXT_DIM)
	for control: Control in [resource_label, clock_label, enemies_label, speed_label, spacer, map_label]:
		top_bar.add_child(control)
	if OS.is_debug_build():
		top_bar.add_child(HudStyle.label("F1 sandbox", 12, HudStyle.TEXT_DIM))


func _build_bottom_bar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "BottomBar"
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -BOTTOM_HEIGHT
	bar.add_theme_constant_override("separation", 4)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	minimap = Minimap.new()
	minimap.setup(game)
	bar.add_child(minimap)
	selection = SelectionPanel.new()
	selection.setup(game)
	selection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(selection)
	command_card = CommandCard.new()
	command_card.setup(game)
	bar.add_child(command_card)


func _build_sandbox() -> void:
	sandbox_spawn = SandboxSpawnPanel.new()
	sandbox_spawn.setup(game)
	_left_scroll = _side_scroll("SandboxLeft", sandbox_spawn, false)
	sandbox = SandboxPanel.new()
	sandbox.setup(game)
	_right_scroll = _side_scroll("SandboxRight", sandbox, true)


## A scroll area between the top and bottom bars at one side of the screen, holding `panel`.
func _side_scroll(scroll_name: String, panel: Control, right: bool) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = scroll_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_left = 1.0 if right else 0.0
	scroll.anchor_right = scroll.anchor_left
	scroll.offset_left = -SIDE_WIDTH - SIDE_MARGIN if right else SIDE_MARGIN
	scroll.offset_right = -SIDE_MARGIN if right else SIDE_MARGIN + SIDE_WIDTH
	scroll.offset_top = TOP_HEIGHT
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	_root.add_child(scroll)
	return scroll


## Side panels end where their content does (so they don't cover the map below them), or
## scroll if the screen is too short.
func _fit_side(scroll: ScrollContainer, panel: Control) -> void:
	var room := get_viewport().get_visible_rect().size.y - TOP_HEIGHT - BOTTOM_HEIGHT - SIDE_MARGIN
	scroll.offset_bottom = scroll.offset_top + minf(panel.get_combined_minimum_size().y, room)


func _floating_label(from_bottom: float) -> Label:
	var lbl := HudStyle.label("", 15)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	lbl.offset_top = from_bottom
	lbl.offset_bottom = from_bottom + 22
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(lbl)
	return lbl


func _show_banner(text: String, colour: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", colour)
	_banner.visible = true

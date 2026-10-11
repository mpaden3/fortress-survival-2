class_name Hud
extends CanvasLayer
## Minimal text HUD: resource, time, build hotkeys, selection and the last rejection.

var world: World
var builder: BuildController
var player_id := 0

var _top: Label
var _bottom: Label
var _message := ""
var _message_until := 0


func setup(target_world: World, build_controller: BuildController, local_player: int) -> void:
	world = target_world
	builder = build_controller
	player_id = local_player


var _banner: Label
var _box: Panel


func _ready() -> void:
	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.visible = false
	add_child(_banner)
	_box = Panel.new()
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.3, 1.0, 0.4, 0.12)
	box_style.border_color = Color(0.3, 1.0, 0.4, 0.9)
	box_style.set_border_width_all(1)
	_box.add_theme_stylebox_override("panel", box_style)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.visible = false
	add_child(_box)
	_top = _label(Control.PRESET_TOP_LEFT)
	_bottom = _label(Control.PRESET_BOTTOM_LEFT)
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN


## Called after each simulation step with that step's command results.
func show_results(results: Array[Dictionary]) -> void:
	for result in results:
		if not result["ok"] and result["command"].get("player") == player_id:
			_message = "Can't %s: %s" % [String(result["command"]["type"]).replace("_", " "), result["reason"]]
			_message_until = world.tick + 2 * SimConstants.TICK_RATE


func _process(_delta: float) -> void:
	if world == null:
		return
	var player := world.players[player_id]
	var lines := PackedStringArray()
	var clock := ""
	var match_system := world.match_system
	if match_system.active:
		var left := ceili(match_system.remaining(world))
		clock = "Survive %02d:%02d" % [left / 60, left % 60]
	else:
		var seconds := world.tick / SimConstants.TICK_RATE
		clock = "Time %02d:%02d (no waves)" % [seconds / 60, seconds % 60]
	var game := get_parent() as Game
	var speed := "   x%d" % game.speed if game and game.speed > 1.0 else ""
	lines.append("%s: %d (+%d/min)    %s%s    Map: %s" % [world.defs.rules.primary_resource_name.capitalize(),
		player.resource, roundi(world.economy.income_per_minute(world, player_id)), clock, speed, world.map.display_name])
	var keys := PackedStringArray()
	for key: Key in BuildController.HOTKEYS:
		var def := world.defs.building(BuildController.HOTKEYS[key])
		var mark := ">" if def.id == builder.selected_def else " "
		keys.append("%s[%s] %s (%d)" % [mark, OS.get_keycode_string(key), def.display_name, def.cost])
	lines.append("  ".join(keys))
	lines.append("LMB place/select   drag: walls / select units   Esc cancel   X sell   RMB move/repair   F blink   H haste   Shift queue")
	lines.append("WASD/edge pan   wheel zoom   Q/E rotate   Space centre   L follow   P plots")
	var survivor := world.survivors.survivor_of(player_id)
	if survivor:
		var blink := maxi(0, survivor.blink_ready_tick - world.tick) / SimConstants.TICK_RATE
		var haste := maxi(0, survivor.haste_ready_tick - world.tick) / SimConstants.TICK_RATE
		lines.append("Survivor HP %d/%d    Blink %s    Haste %s    Orders %d" % [survivor.hp, survivor.def.max_hp,
			"ready" if blink == 0 else "%ds" % blink, "ready" if haste == 0 else "%ds" % haste, survivor.orders.size()])
	lines.append("Enemies: %d (sim %.1f ms)    debug: G grunts  B brutes  R runners  [ ] speed" % [world.enemies.count(),
		world.enemies.update_usec / 1000.0])
	_top.text = "\n".join(lines)
	var bottom := PackedStringArray()
	var building := world.entities.get(builder.selected_entity) as BuildingState
	if building:
		var state := "building %d%%" % (100 * building.build_progress / building.def.build_ticks()) \
			if building.constructing else "ready"
		if building.upgrading_to:
			state = "upgrading to %s %d%%" % [building.upgrading_to.display_name,
				100 * building.upgrade_progress / building.upgrading_to.build_ticks()]
		bottom.append("Selected: %s #%d  HP %d/%d  %s" % [building.def.display_name, building.id, building.hp,
			building.def.max_hp, state])
		if building.def.is_armed():
			bottom.append("Attack: %.0f %s dmg every %.1fs, range %.1f%s%s" % [building.def.attack_damage,
				building.def.damage_type, building.def.attack_cooldown, building.def.attack_range,
				", splash %.1f" % building.def.splash_radius if building.def.splash_radius > 0 else "",
				", slows to %d%%" % (building.def.slow_multiplier * 100) if building.def.slow_multiplier < 1 else ""])
		var options := PackedStringArray()
		var actions := BuildController.building_actions(building)
		for k in mini(actions.size(), BuildController.ACTION_KEYS.size()):
			var key := OS.get_keycode_string(BuildController.ACTION_KEYS[k])
			if k < building.def.upgrades.size():
				var target := world.defs.building(actions[k])
				options.append("[%s] upgrade: %s (%d)" % [key, target.display_name, target.cost])
			else:
				var unit_def := world.defs.unit(actions[k])
				options.append("[%s] train: %s (%d)" % [key, unit_def.display_name, unit_def.cost])
		if not options.is_empty():
			bottom.append("  ".join(options))
		if not building.train_queue.is_empty():
			var training := world.defs.unit(building.train_queue[0])
			bottom.append("Training: %s %d%%%s" % [training.display_name,
				100 * building.train_progress / training.train_ticks(),
				"  (+%d queued)" % (building.train_queue.size() - 1) if building.train_queue.size() > 1 else ""])
	var units := _selected_units()
	if not units.is_empty():
		var counts := {}
		for unit in units:
			counts[unit.def.display_name] = counts.get(unit.def.display_name, 0) + 1
		var parts := PackedStringArray()
		for unit_name: String in counts:
			parts.append("%d %s" % [counts[unit_name], unit_name])
		var line := "Selected: " + ", ".join(parts)
		if units.size() == 1:
			line += "  HP %d/%d%s" % [units[0].hp, units[0].def.max_hp, "  holding" if units[0].holding else ""]
		bottom.append(line)
		bottom.append("RMB move   [T] attack-move%s   [Z] stop   [V] hold   Esc deselect"
			% (" (click target)" if builder.attack_move_armed else ""))
	bottom.append("Cell %s" % builder.hover_cell)
	_box.visible = builder.drag_rect.has_area()
	_box.position = builder.drag_rect.position
	_box.size = builder.drag_rect.size
	if world.tick < _message_until:
		bottom.append(_message)
	_bottom.text = "\n".join(bottom)
	if match_system.result == MatchSystem.Result.WON and player.alive:
		_show_banner("VICTORY - you survived!", Color(0.4, 0.95, 0.4))
	elif not player.alive and match_system.result == MatchSystem.Result.RUNNING:
		_show_banner("Your Survivor died - spectating", Color(0.95, 0.25, 0.2))
	elif not player.alive:
		_show_banner("DEFEAT - your Survivor died", Color(0.95, 0.25, 0.2))
	elif match_system.announcement_tick >= 0 and world.tick - match_system.announcement_tick < 4 * SimConstants.TICK_RATE:
		_show_banner(match_system.announcement, Color(1.0, 0.8, 0.3))
	else:
		_banner.visible = false


func _selected_units() -> Array[UnitState]:
	var out: Array[UnitState] = []
	for unit_id in builder.selected_units:
		var unit := world.entities.get(unit_id) as UnitState
		if unit:
			out.append(unit)
	return out


func _show_banner(text: String, colour: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", colour)
	_banner.visible = true


func _label(preset: Control.LayoutPreset) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

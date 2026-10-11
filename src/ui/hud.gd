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


func _ready() -> void:
	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.visible = false
	add_child(_banner)
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
	var seconds := world.tick / SimConstants.TICK_RATE
	var lines := PackedStringArray()
	lines.append("%s: %d    Time %02d:%02d    Map: %s" % [world.defs.rules.primary_resource_name.capitalize(),
		player.resource, seconds / 60, seconds % 60, world.map.display_name])
	var keys := PackedStringArray()
	for key: Key in BuildController.HOTKEYS:
		var def := world.defs.building(BuildController.HOTKEYS[key])
		var mark := ">" if def.id == builder.selected_def else " "
		keys.append("%s[%s] %s (%d)" % [mark, OS.get_keycode_string(key), def.display_name, def.cost])
	lines.append("  ".join(keys))
	lines.append("LMB place/select   drag: walls   Esc cancel   X sell   RMB move/repair   F blink   H haste   Shift queue")
	lines.append("WASD/edge pan   wheel zoom   Q/E rotate   Space centre   L follow   P plots")
	var survivor := world.survivors.survivor_of(player_id)
	if survivor:
		var blink := maxi(0, survivor.blink_ready_tick - world.tick) / SimConstants.TICK_RATE
		var haste := maxi(0, survivor.haste_ready_tick - world.tick) / SimConstants.TICK_RATE
		lines.append("Survivor HP %d/%d    Blink %s    Haste %s    Orders %d" % [survivor.hp, survivor.def.max_hp,
			"ready" if blink == 0 else "%ds" % blink, "ready" if haste == 0 else "%ds" % haste, survivor.orders.size()])
	lines.append("Enemies: %d (sim %.1f ms)    debug: G grunts  B brutes  R runners" % [world.enemies.count(),
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
			bottom.append("Attack: %.0f dmg every %.1fs, range %.1f%s%s" % [building.def.attack_damage,
				building.def.attack_cooldown, building.def.attack_range,
				", splash %.1f" % building.def.splash_radius if building.def.splash_radius > 0 else "",
				", slows to %d%%" % (building.def.slow_multiplier * 100) if building.def.slow_multiplier < 1 else ""])
		var options := PackedStringArray()
		for k in building.def.upgrades.size():
			var target := world.defs.building(building.def.upgrades[k])
			options.append("[%s] %s (%d)" % [OS.get_keycode_string(BuildController.UPGRADE_KEYS[k]), target.display_name, target.cost])
		if not options.is_empty():
			bottom.append("Upgrade: " + "  ".join(options))
	bottom.append("Cell %s" % builder.hover_cell)
	if world.tick < _message_until:
		bottom.append(_message)
	_bottom.text = "\n".join(bottom)
	if not player.alive:
		_banner.text = "DEFEAT - your Survivor died"
		_banner.add_theme_color_override("font_color", Color(0.95, 0.25, 0.2))
		_banner.visible = true


func _label(preset: Control.LayoutPreset) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

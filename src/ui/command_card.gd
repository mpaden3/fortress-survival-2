class_name CommandCard
extends PanelContainer
## The grid of command buttons (bottom right), for the current selection:
## - nothing / the Survivor: build the root buildings, Blink, Haste;
## - a building: its upgrades and units to train, then Sell;
## - units: attack-move, stop, hold.
## Buttons call the same BuildController requests as the hotkeys shown on them.

const COLUMNS := 4

var game: Game
var _grid: GridContainer
var _buttons: Array[Button] = []
var _signature := ""


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "CommandCard"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	var column := VBoxContainer.new()
	add_child(column)
	column.add_child(HudStyle.header("Commands"))
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(_grid)


## The commands for the current selection, in grid order: {id, text, key, tooltip, enabled,
## active, action}.
func entries() -> Array[Dictionary]:
	var builder := game.builder
	if not builder.selected_units.is_empty():
		return _unit_entries()
	var building := game.world.entities.get(builder.selected_entity) as BuildingState
	if building and building.owner == builder.player_id:
		return _building_entries(building)
	return _survivor_entries()


## Runs the command `id` as if its button was pressed (tests). Returns false if it's absent
## or disabled.
func press(id: String) -> bool:
	for entry in entries():
		if entry["id"] == id and entry["enabled"]:
			(entry["action"] as Callable).call()
			return true
	return false


func _process(_delta: float) -> void:
	if game == null or game.world == null:
		return
	var list := entries()
	var signature := ",".join(list.map(func(e: Dictionary) -> String: return e["id"]))
	if signature != _signature:
		_rebuild(list)
		_signature = signature
	for k in list.size():
		var entry := list[k]
		var button := _buttons[k]
		button.disabled = not entry["enabled"]
		button.set_pressed_no_signal(entry.get("active", false))
		button.text = "%s\n[%s]" % [entry["text"], entry["key"]]
		button.tooltip_text = entry["tooltip"]


func _rebuild(list: Array[Dictionary]) -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	for entry in list:
		var button := HudStyle.button("", "", true)
		button.name = String(entry["id"]).replace(":", "_")
		button.custom_minimum_size = HudStyle.BUTTON_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var id: String = entry["id"]
		button.pressed.connect(func() -> void: press(id))
		_grid.add_child(button)
		_buttons.append(button)


func _survivor_entries() -> Array[Dictionary]:
	var builder := game.builder
	var world := game.world
	var out: Array[Dictionary] = []
	var survivor := world.survivors.survivor_of(builder.player_id)
	var alive := survivor != null and survivor.alive
	for key: Key in BuildController.HOTKEYS:
		var def := world.defs.building(BuildController.HOTKEYS[key])
		var def_id := def.id
		out.append({"id": "build:%s" % def.id, "text": def.display_name, "key": OS.get_keycode_string(key),
			"tooltip": "Build %s\n%s" % [def.display_name, _building_stats(def)],
			"enabled": alive and _affordable(def.cost), "active": builder.selected_def == def.id,
			"action": func() -> void: builder.select_def(&"" if builder.selected_def == def_id else def_id)})
	var blink_left := maxi(0, survivor.blink_ready_tick - world.tick) if survivor else 0
	var haste_left := maxi(0, survivor.haste_ready_tick - world.tick) if survivor else 0
	out.append({"id": "blink", "text": "Blink" if blink_left == 0 else "Blink %ds" % ceili(blink_left / float(SimConstants.TICK_RATE)),
		"key": "F", "tooltip": "Blink: teleport over walls to a free spot (click the target)",
		"enabled": alive and blink_left == 0, "active": builder.blink_armed, "action": builder.arm_blink})
	out.append({"id": "haste", "text": "Haste" if haste_left == 0 else "Haste %ds" % ceili(haste_left / float(SimConstants.TICK_RATE)),
		"key": "H", "tooltip": "Haste: run faster for a few seconds",
		"enabled": alive and haste_left == 0, "action": builder.request_haste})
	out.append({"id": "cancel", "text": "Cancel", "key": "Esc", "tooltip": "Leave build or targeting mode",
		"enabled": builder.selected_def != &"" or builder.blink_armed, "action": builder.cancel_modes})
	return out


func _building_entries(building: BuildingState) -> Array[Dictionary]:
	var builder := game.builder
	var world := game.world
	var out: Array[Dictionary] = []
	var actions := BuildController.building_actions(building)
	var busy := building.constructing or building.upgrading_to != null
	for k in mini(actions.size(), BuildController.ACTION_KEYS.size()):
		var key := OS.get_keycode_string(BuildController.ACTION_KEYS[k])
		var option := k
		if k < building.def.upgrades.size():
			var target := world.defs.building(actions[k])
			out.append({"id": "upgrade:%s" % target.id, "text": target.display_name, "key": key,
				"tooltip": "Upgrade to %s\n%s" % [target.display_name, _building_stats(target)],
				"enabled": not busy and _affordable(target.cost),
				"action": func() -> void: builder.request_action_selected(option)})
		else:
			var unit := world.defs.unit(actions[k])
			out.append({"id": "train:%s" % unit.id, "text": unit.display_name, "key": key,
				"tooltip": "Train %s\n%s" % [unit.display_name, _unit_stats(unit)],
				"enabled": not building.constructing and _affordable(unit.cost)
					and building.train_queue.size() < world.defs.rules.max_train_queue,
				"action": func() -> void: builder.request_action_selected(option)})
	out.append({"id": "sell", "text": "Sell", "key": "X",
		"tooltip": "Sell for %d (%d%% of what was spent)" % [floori(building.invested * world.defs.rules.sell_refund_ratio),
			roundi(world.defs.rules.sell_refund_ratio * 100)],
		"enabled": true, "action": builder.request_sell_selected})
	return out


func _unit_entries() -> Array[Dictionary]:
	var builder := game.builder
	return [
		{"id": "attack_move", "text": "Attack", "key": "T", "tooltip": "Attack-move: click a spot; fight on the way",
			"enabled": true, "active": builder.attack_move_armed, "action": builder.arm_attack_move},
		{"id": "stop", "text": "Stop", "key": "Z", "tooltip": "Stop and guard this spot",
			"enabled": true, "action": func() -> void: builder.request_unit_order("stop")},
		{"id": "hold", "text": "Hold", "key": "V", "tooltip": "Hold position: never move, attack only in range",
			"enabled": true, "action": func() -> void: builder.request_unit_order("hold")},
	] as Array[Dictionary]


func _affordable(cost: int) -> bool:
	return game.world.players[game.builder.player_id].resource >= cost


func _building_stats(def: BuildingDef) -> String:
	var lines := PackedStringArray(["Cost %d   HP %d   Build %.0fs" % [def.cost, def.max_hp, def.build_time]])
	if def.is_armed():
		lines.append("Attack %.0f %s every %.1fs, range %.1f" % [def.attack_damage, def.damage_type,
			def.attack_cooldown, def.attack_range])
		if def.splash_radius > 0.0:
			lines.append("Splash %.1f" % def.splash_radius)
		if def.slow_multiplier < 1.0:
			lines.append("Slows to %d%% for %.1fs" % [roundi(def.slow_multiplier * 100), def.slow_duration])
	if def.income_per_minute > 0.0:
		lines.append("+%.0f %s per minute" % [def.income_per_minute, game.world.defs.rules.primary_resource_name])
	if not def.trains.is_empty():
		lines.append("Trains units")
	return "\n".join(lines)


func _unit_stats(def: UnitDef) -> String:
	var lines := PackedStringArray(["Cost %d   HP %.0f   Train %.0fs" % [def.cost, def.max_hp, def.train_time]])
	if def.is_fighter():
		lines.append("Attack %.0f %s every %.1fs, range %.1f" % [def.attack_damage, def.damage_type,
			def.attack_cooldown, def.attack_range])
	if def.is_repairer():
		lines.append("Repairs %.0f HP/s, free" % def.repair_rate)
	return "\n".join(lines)

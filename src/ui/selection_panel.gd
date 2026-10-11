class_name SelectionPanel
extends PanelContainer
## Bottom centre: what's selected. A building (HP, state, stats, training queue), units (one
## in detail, a group as counts), or with nothing selected, the player's Survivor.

var game: Game
var title: Label
var hp_bar: ProgressBar
var hp_label: Label
var details: Label
var progress_bar: ProgressBar
var progress_label: Label


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "Selection"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	title = HudStyle.label("", 18, HudStyle.GOLD)
	column.add_child(title)
	var hp_row := HBoxContainer.new()
	column.add_child(hp_row)
	hp_bar = HudStyle.bar(HudStyle.HP_GOOD)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_bar)
	hp_label = HudStyle.label("", 13)
	hp_label.custom_minimum_size.x = 90
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(hp_label)
	details = HudStyle.label("", 13)
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(details)
	var progress_row := HBoxContainer.new()
	column.add_child(progress_row)
	progress_bar = HudStyle.bar(HudStyle.PROGRESS, 12.0)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(progress_bar)
	progress_label = HudStyle.label("", 12, HudStyle.TEXT_DIM)
	progress_label.custom_minimum_size.x = 200
	progress_row.add_child(progress_label)


func _process(_delta: float) -> void:
	if game == null or game.world == null:
		return
	var units := _selected_units()
	var building := game.world.entities.get(game.builder.selected_entity) as BuildingState
	_set_progress(-1.0, "")
	if not units.is_empty():
		_show_units(units)
	elif building:
		_show_building(building)
	else:
		_show_survivor(game.world.survivors.survivor_of(game.builder.player_id))


func _show_building(building: BuildingState) -> void:
	var def := building.def
	title.text = def.display_name
	_set_hp(building.hp, def.max_hp)
	var lines := PackedStringArray()
	if def.is_armed():
		lines.append("Attack: %.0f %s every %.1fs   Range: %.1f" % [def.attack_damage, def.damage_type,
			def.attack_cooldown, def.attack_range])
		var extras := PackedStringArray()
		if def.splash_radius > 0.0:
			extras.append("splash %.1f" % def.splash_radius)
		if def.slow_multiplier < 1.0:
			extras.append("slows to %d%%" % roundi(def.slow_multiplier * 100))
		if not extras.is_empty():
			lines.append(", ".join(extras).capitalize())
	if def.income_per_minute > 0.0:
		lines.append("Income: +%.0f %s / min" % [def.income_per_minute, game.world.defs.rules.primary_resource_name])
	if building.owner != game.builder.player_id:
		lines.append("(another player's)")
	details.text = "\n".join(lines)
	if building.constructing:
		_set_progress(float(building.build_progress) / def.build_ticks(), "Constructing")
	elif building.upgrading_to:
		_set_progress(float(building.upgrade_progress) / building.upgrading_to.build_ticks(),
			"Upgrading to %s" % building.upgrading_to.display_name)
	elif not building.train_queue.is_empty():
		var unit := game.world.defs.unit(building.train_queue[0])
		var queued := building.train_queue.size() - 1
		_set_progress(float(building.train_progress) / unit.train_ticks(),
			"Training %s%s" % [unit.display_name, " (+%d)" % queued if queued > 0 else ""])


func _show_units(units: Array[UnitState]) -> void:
	if units.size() == 1:
		var unit := units[0]
		title.text = unit.def.display_name
		_set_hp(unit.hp, unit.def.max_hp)
		var lines := PackedStringArray()
		if unit.def.is_fighter():
			lines.append("Attack: %.0f %s every %.1fs   Range: %.1f" % [unit.def.attack_damage, unit.def.damage_type,
				unit.def.attack_cooldown, unit.def.attack_range])
		if unit.def.is_repairer():
			lines.append("Repairs %.0f HP/s" % unit.def.repair_rate)
		lines.append("Holding position" if unit.holding else ("Orders: %d" % unit.orders.size() if not unit.orders.is_empty() else "Guarding"))
		details.text = "\n".join(lines)
		return
	title.text = "%d units" % units.size()
	var hp := 0.0
	var max_hp := 0.0
	var counts := {}
	for unit in units:
		hp += unit.hp
		max_hp += unit.def.max_hp
		counts[unit.def.display_name] = counts.get(unit.def.display_name, 0) + 1
	_set_hp(hp, max_hp)
	var parts := PackedStringArray()
	for unit_name: String in counts:
		parts.append("%d x %s" % [counts[unit_name], unit_name])
	details.text = "\n".join(parts)


func _show_survivor(survivor: SurvivorState) -> void:
	if survivor == null:
		title.text = ""
		details.text = ""
		hp_bar.visible = false
		hp_label.text = ""
		return
	title.text = "Survivor" + ("  (fallen)" if not survivor.alive else "")
	_set_hp(survivor.hp, survivor.def.max_hp)
	var world := game.world
	var blink := ceili(maxi(0, survivor.blink_ready_tick - world.tick) / float(SimConstants.TICK_RATE))
	var haste := ceili(maxi(0, survivor.haste_ready_tick - world.tick) / float(SimConstants.TICK_RATE))
	var lines := PackedStringArray([
		"Blink: %s   Haste: %s%s" % ["ready" if blink == 0 else "%ds" % blink, "ready" if haste == 0 else "%ds" % haste,
			"   (hasted)" if world.tick < survivor.haste_until_tick else ""],
		"Orders queued: %d" % survivor.orders.size(),
	])
	if survivor.invulnerable:
		lines.append("God mode")
	details.text = "\n".join(lines)
	if not survivor.orders.is_empty() and survivor.orders[0]["kind"] == "build":
		var def := world.defs.building(survivor.orders[0]["def"])
		_set_progress(0.0, "Walking to build %s" % def.display_name)


func _set_hp(hp: float, max_hp: float) -> void:
	hp_bar.visible = true
	HudStyle.set_hp(hp_bar, hp, max_hp)
	hp_label.text = "%d / %d" % [ceili(hp), roundi(max_hp)]


func _set_progress(ratio: float, text: String) -> void:
	progress_bar.visible = ratio >= 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = maxf(ratio, 0.0)
	progress_label.text = text


func _selected_units() -> Array[UnitState]:
	var out: Array[UnitState] = []
	for unit_id in game.builder.selected_units:
		var unit := game.world.entities.get(unit_id) as UnitState
		if unit:
			out.append(unit)
	return out

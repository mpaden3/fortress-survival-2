class_name SandboxSpawnPanel
extends PanelContainer
## Sandbox, left side: spawn any enemy type, in any amount, at any spawn point (or a random
## one), and clear them all. Development builds only; F1 hides the sandbox panels.

const AMOUNTS: Array[int] = [1, 10, 50, 200]
const RANDOM_SPAWN := ""

var game: Game
var enemy_id: StringName
var amount := 10
var spawn_id := RANDOM_SPAWN


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "SandboxSpawn"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(HudStyle.header("Spawn enemies"))

	var world := game.world
	# Weakest first; the first one is the default.
	var defs := world.defs.enemy_list.duplicate()
	defs.sort_custom(func(a: EnemyDef, b: EnemyDef) -> bool: return a.max_hp < b.max_hp)
	enemy_id = &"grunt" if world.defs.enemy(&"grunt") else defs[0].id
	column.add_child(HudStyle.label("Enemy", 12, HudStyle.TEXT_DIM))
	var enemies := _grid(column, 2)
	var enemy_group := ButtonGroup.new()
	for def: EnemyDef in defs:
		var def_id := def.id
		var button := _choice(enemies, enemy_group, def.display_name, def_id == enemy_id,
			"%s\nHP %.0f   speed %.1f   %s armor" % [def.display_name, def.max_hp, def.speed, def.armor_type])
		button.name = "enemy_%s" % def.id
		button.pressed.connect(func() -> void: enemy_id = def_id)

	column.add_child(HudStyle.label("Amount", 12, HudStyle.TEXT_DIM))
	var amounts := _grid(column, 4)
	var amount_group := ButtonGroup.new()
	for value in AMOUNTS:
		var button := _choice(amounts, amount_group, str(value), value == amount)
		button.name = "amount_%d" % value
		button.pressed.connect(func() -> void: amount = value)

	column.add_child(HudStyle.label("Spawn point", 12, HudStyle.TEXT_DIM))
	var spawns := _grid(column, 2)
	var spawn_group := ButtonGroup.new()
	var random := _choice(spawns, spawn_group, "Random", true)
	random.name = "spawn_random"
	random.pressed.connect(func() -> void: spawn_id = RANDOM_SPAWN)
	for spawn in world.map.spawns:
		var id := spawn.id
		var button := _choice(spawns, spawn_group, id.capitalize(), false)
		button.name = "spawn_%s" % id
		button.pressed.connect(func() -> void: spawn_id = id)

	var go := HudStyle.button("Spawn", "Spawn the chosen enemies (they hunt a random Survivor)")
	go.name = "Spawn"
	go.custom_minimum_size.y = 34
	go.pressed.connect(spawn)
	column.add_child(go)
	var clear := HudStyle.button("Clear all enemies")
	clear.name = "Clear"
	clear.pressed.connect(func() -> void:
		game.world.submit(Commands.debug_clear_enemies(game.builder.player_id)))
	column.add_child(clear)


## Submits the spawn for the current choices.
func spawn() -> void:
	var world := game.world
	var id := spawn_id
	if id == RANDOM_SPAWN:
		id = (world.map.spawns.pick_random() as MapLayout.Spawn).id
	world.submit(Commands.debug_spawn(game.builder.player_id, enemy_id, id, amount, &""))


static func _grid(parent: Control, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)
	return grid


static func _choice(parent: Control, group: ButtonGroup, text: String, pressed: bool, tooltip := "") -> Button:
	var button := HudStyle.button(text, tooltip, true)
	button.button_group = group
	button.button_pressed = pressed
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button

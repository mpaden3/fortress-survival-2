class_name SandboxPanel
extends PanelContainer
## Sandbox, right side: game speed (and pause), resource, god mode, view toggles, restart and
## live performance numbers. Development builds only; F1 hides the sandbox panels.

const SPEEDS: Array[float] = [0.0, 1.0, 2.0, 4.0, 8.0, 16.0]

var game: Game
var stats: Label
var _speed_buttons: Array[Button] = []
var _god: Button
var _plots: Button
var _follow: Button
var _mute: Button


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "Sandbox"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(HudStyle.header("Sandbox"))

	column.add_child(HudStyle.label("Game speed", 12, HudStyle.TEXT_DIM))
	var speeds := SandboxSpawnPanel._grid(column, 3)
	var speed_group := ButtonGroup.new()
	for value in SPEEDS:
		var button := SandboxSpawnPanel._choice(speeds, speed_group, "Pause" if value == 0.0 else "%dx" % value,
			value == game.speed)
		button.name = "speed_%d" % value
		button.pressed.connect(func() -> void: game.speed = value)
		_speed_buttons.append(button)

	var resource_name := game.world.defs.rules.primary_resource_name.capitalize()
	column.add_child(HudStyle.label(resource_name, 12, HudStyle.TEXT_DIM))
	var wood := SandboxSpawnPanel._grid(column, 3)
	for value: int in [100, 1000, -1000000]:
		var button := HudStyle.button("+%d" % value if value > 0 else "Empty")
		button.name = "resource_%d" % value
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			game.world.submit(Commands.debug_add_resource(game.builder.player_id, value)))
		wood.add_child(button)

	column.add_child(HudStyle.label("Survivor", 12, HudStyle.TEXT_DIM))
	_god = HudStyle.button("God mode", "The Survivor takes no damage", true)
	_god.name = "God"
	_god.toggled.connect(func(on: bool) -> void:
		game.world.submit(Commands.debug_god(game.builder.player_id, on)))
	column.add_child(_god)

	column.add_child(HudStyle.label("View", 12, HudStyle.TEXT_DIM))
	var view := SandboxSpawnPanel._grid(column, 3)
	_plots = _toggle(view, "Plots", "Show the plot outlines [P]", game.toggle_plots)
	_follow = _toggle(view, "Follow", "Camera follows the Survivor [L]",
		func() -> void: game.follow_survivor = not game.follow_survivor)
	_mute = _toggle(view, "Mute", "Mute all sound [M]", func() -> void: game.set_muted(not game.is_muted()))

	var restart := HudStyle.button("Restart match", "Start over with the same options")
	restart.name = "Restart"
	restart.pressed.connect(game.restart)
	column.add_child(restart)

	column.add_child(HudStyle.label("Performance", 12, HudStyle.TEXT_DIM))
	stats = HudStyle.label("", 12)
	column.add_child(stats)


func _process(_delta: float) -> void:
	if game == null or game.world == null:
		return
	var world := game.world
	for k in SPEEDS.size():
		_speed_buttons[k].set_pressed_no_signal(is_equal_approx(SPEEDS[k], game.speed))
	var survivor := world.survivors.survivor_of(game.builder.player_id)
	_god.set_pressed_no_signal(survivor != null and survivor.invulnerable)
	_plots.set_pressed_no_signal(game.map_view.show_plots)
	_follow.set_pressed_no_signal(game.follow_survivor)
	_mute.set_pressed_no_signal(game.is_muted())
	var buildings := 0
	for entity: SimEntity in world.entities.values():
		buildings += 1 if entity is BuildingState else 0
	stats.text = "FPS %d\nEnemies %d  (%.1f ms)\nCombat %.1f ms   Units %.1f ms\nBuildings %d   Units %d\nProjectiles %d   Tick %d" % [
		Engine.get_frames_per_second(), world.enemies.count(), world.enemies.update_usec / 1000.0,
		world.combat.update_usec / 1000.0, world.units.update_usec / 1000.0, buildings, world.units.living().size(),
		world.combat.projectile_count(), world.tick]


func _toggle(parent: Control, text: String, tooltip: String, action: Callable) -> Button:
	var button := HudStyle.button(text, tooltip, true)
	button.name = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

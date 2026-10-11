extends RefCounted
## Implementation of tools/sim_match.gd (see there).


func run(tree: SceneTree, user_args: PackedStringArray) -> void:
	var args := {}
	for arg in user_args:
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	DebugLog.active = false
	var layout := MapLayout.load_file("res://data/maps/%s.json" % args.get("map", "mvp_map"))
	var world := World.new(layout, DefRegistry.load_default(), int(args.get("seed", "1")))
	world.add_player(0)
	var survivor := world.survivors.spawn(world, 0, SurvivorSystem.start_cell(world, 0))
	if args.has("immortal"):
		survivor.hp = 1e15
	var bot: DefenceBot = DefenceBot.new(world, 0, args.get("plot", "")) if args.has("bot") else null
	if bot:
		print("bot defends plot '%s'" % bot.plot.id)
	var kills := [0]
	var lost := [0]
	var count_events := func() -> void:
		kills[0] += world.events.of_kind(SimEvents.Kind.ENEMY_KILLED).size()
		lost[0] += world.events.of_kind(SimEvents.Kind.BUILDING_DESTROYED).size()
	world.stepped.connect(count_events)
	world.match_system.start(world, world.defs.schedule)
	# One extra minute so the match's own end (timer or defeat) is reported.
	var minutes := int(args.get("minutes", "21"))
	print("minute | enemies | killed | bldgs | lost | units | wood | survivor hp | avg ms | max ms | result")
	for minute in minutes:
		var total := 0
		var worst := 0
		for i in 60 * SimConstants.TICK_RATE:
			var started := Time.get_ticks_usec()
			if bot:
				bot.update(world)
			world.step()
			var used := Time.get_ticks_usec() - started
			total += used
			worst = maxi(worst, used)
			if world.match_system.result != MatchSystem.Result.RUNNING:
				break
		var buildings := 0
		for entity: SimEntity in world.entities.values():
			buildings += 1 if entity is BuildingState else 0
		print("%6d | %7d | %6d | %5d | %4d | %5d | %4d | %11.0f | %6.2f | %6.2f | %s" % [minute + 1,
			world.enemies.count(), kills[0], buildings, lost[0], world.units.living().size(),
			world.players[0].resource, minf(survivor.hp, 1e9), total / 1000.0 / (60 * SimConstants.TICK_RATE),
			worst / 1000.0, MatchSystem.Result.keys()[world.match_system.result]])
		if world.match_system.result != MatchSystem.Result.RUNNING:
			break
	world.stepped.disconnect(count_events)  # the closure holds the world: break the cycle

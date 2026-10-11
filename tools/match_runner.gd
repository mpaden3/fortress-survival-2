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
	var survivor := world.survivors.spawn(world, 0, layout.start)
	if args.has("immortal"):
		survivor.hp = 1e15
	world.match_system.start(world, world.defs.schedule)
	var minutes := int(args.get("minutes", "20"))
	print("minute | enemies | survivor hp | avg tick ms | max tick ms | result")
	for minute in minutes:
		var total := 0
		var worst := 0
		for i in 60 * SimConstants.TICK_RATE:
			var started := Time.get_ticks_usec()
			world.step()
			var used := Time.get_ticks_usec() - started
			total += used
			worst = maxi(worst, used)
		print("%6d | %7d | %11.0f | %11.2f | %11.2f | %s" % [minute + 1, world.enemies.count(), minf(survivor.hp, 1e9),
			total / 1000.0 / (60 * SimConstants.TICK_RATE), worst / 1000.0, MatchSystem.Result.keys()[world.match_system.result]])
		if world.match_system.result != MatchSystem.Result.RUNNING:
			break

extends GutTest
## DefenceBot (scripted player for headless match runs): it fortifies a plot through commands.


func test_walls_its_plot_and_builds_inside() -> void:
	DebugLog.active = false
	var world := World.new(MapLayout.load_file("res://data/maps/test_map.json"), DefRegistry.load_default(), 1)
	world.add_player(0)
	world.survivors.spawn(world, 0, SurvivorSystem.start_cell(world, 0))
	var bot := DefenceBot.new(world, 0, "keep")
	for i in 3 * 60 * SimConstants.TICK_RATE:
		bot.update(world)
		world.step()
	DebugLog.active = true
	var area := MapAnalysis.area_cells(bot.plot.rects)
	for entrance in MapAnalysis.entrances(world.map, bot.plot.rects):
		for cell: Vector2i in entrance["cells"]:
			assert_ne(world.grid.occupant(cell), BuildGrid.NONE, "entrance cell %s walled" % cell)
	var inside := 0
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building and building.def.id != &"wall" and area.has(building.rect.position):
			inside += 1
	assert_gt(inside, 3, "towers and mills inside the plot")

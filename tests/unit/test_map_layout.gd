extends GutTest
## Map data integrity: authored plot expectations hold and every plot and spawn is reachable.

const MAPS := ["res://data/maps/test_map.json", "res://data/maps/mvp_map.json"]


func test_maps_load() -> void:
	for path in MAPS:
		var layout := MapLayout.load_file(path)
		assert_not_null(layout, path)
		if layout:
			assert_gt(layout.plots.size(), 0, "%s has plots" % path)
			assert_eq(layout.spawns.size(), 5, "%s has centre + 4 edge spawns" % path)


func test_plot_buildable_cells_match_expected() -> void:
	for path in MAPS:
		var layout := MapLayout.load_file(path)
		for plot in layout.plots:
			assert_eq(MapAnalysis.buildable_cells(layout, plot.rects), plot.expected_buildable_cells,
				"%s / %s buildable cells" % [layout.id, plot.id])


func test_plot_entrances_match_expected() -> void:
	for path in MAPS:
		var layout := MapLayout.load_file(path)
		for plot in layout.plots:
			assert_eq(MapAnalysis.entrance_widths(layout, plot.rects), plot.expected_entrance_widths,
				"%s / %s entrance widths" % [layout.id, plot.id])


func test_start_spawns_and_plots_are_reachable_from_start() -> void:
	for path in MAPS:
		var layout := MapLayout.load_file(path)
		assert_true(layout.is_walkable(layout.start), "%s start is walkable" % layout.id)
		var distances := MapAnalysis.walk_distances(layout, [layout.start])
		for spawn in layout.spawns:
			var reachable := MapAnalysis.walkable_cells(layout, spawn.rect).any(
				func(c: Vector2i) -> bool: return distances[c.y * layout.size.x + c.x] >= 0)
			assert_true(reachable, "%s spawn %s reachable" % [layout.id, spawn.id])
		for plot in layout.plots:
			var cells := MapAnalysis.area_cells(plot.rects).keys().filter(
				func(c: Vector2i) -> bool: return layout.is_walkable(c))
			var reachable := cells.any(
				func(c: Vector2i) -> bool: return distances[c.y * layout.size.x + c.x] >= 0)
			assert_true(reachable, "%s plot %s reachable" % [layout.id, plot.id])


func test_entrances_of_a_walled_room() -> void:
	# 7x5 map: a 3x1 room at (2,2) walled in, with one door on its east side.
	var layout := MapLayout.from_dict({
		"format": 1, "id": "room", "size": [7, 5], "start": [0, 0],
		"rows": [
			".......",
			".#####.",
			".#.....",
			".#####.",
			".......",
		],
	})
	var room: Array[Rect2i] = [Rect2i(2, 2, 3, 1)]
	assert_eq(MapAnalysis.buildable_cells(layout, room), 3)
	assert_eq(MapAnalysis.entrance_widths(layout, room), [1] as Array[int])


func test_multi_rect_plot_counts_overlap_once() -> void:
	var layout := MapLayout.from_dict({
		"format": 1, "id": "open", "size": [4, 4], "start": [0, 0],
		"rows": ["....", "....", "....", "...."],
	})
	var rects: Array[Rect2i] = [Rect2i(0, 0, 2, 2), Rect2i(1, 1, 2, 2)]
	assert_eq(MapAnalysis.buildable_cells(layout, rects), 7)


func test_out_of_bounds_is_blocked() -> void:
	var layout := MapLayout.load_file(MAPS[0])
	assert_false(layout.is_walkable(Vector2i(-1, 0)))
	assert_false(layout.is_walkable(layout.size))

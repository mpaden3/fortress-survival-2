class_name MapAnalysis
## Measures map plots: buildable area, entrances and walking distances.
## Must match tools/maps/maplib.py, which writes the authored expectations.

const NEIGHBOURS_4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## Cells covered by a union of rects (a plot area), without duplicates.
static func area_cells(rects: Array[Rect2i]) -> Dictionary:
	var cells := {}
	for rect in rects:
		for z in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				cells[Vector2i(x, z)] = true
	return cells


static func buildable_cells(layout: MapLayout, rects: Array[Rect2i]) -> int:
	var count := 0
	for cell: Vector2i in area_cells(rects):
		if layout.is_buildable(cell):
			count += 1
	return count


## Openings of an area: walkable cells inside it that touch walkable ground outside it,
## grouped 8-connected. Width = longest side of the group, in cells. Widest first.
static func entrances(layout: MapLayout, rects: Array[Rect2i]) -> Array[Dictionary]:
	var area := area_cells(rects)
	var edge := {}
	for cell: Vector2i in area:
		if not layout.is_walkable(cell):
			continue
		for offset in NEIGHBOURS_4:
			var outside := cell + offset
			if not area.has(outside) and layout.is_walkable(outside):
				edge[cell] = true
				break
	var result: Array[Dictionary] = []
	var seen := {}
	for start: Vector2i in edge:
		if seen.has(start):
			continue
		var group: Array[Vector2i] = []
		var queue: Array[Vector2i] = [start]
		seen[start] = true
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			group.append(cell)
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var next := cell + Vector2i(dx, dz)
					if edge.has(next) and not seen.has(next):
						seen[next] = true
						queue.append(next)
		var lo := group[0]
		var hi := group[0]
		for cell in group:
			lo = lo.min(cell)
			hi = hi.max(cell)
		result.append({"width": maxi(hi.x - lo.x, hi.y - lo.y) + 1, "cells": group})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["width"] > b["width"])
	return result


static func entrance_widths(layout: MapLayout, rects: Array[Rect2i]) -> Array[int]:
	var widths: Array[int] = []
	for entrance in entrances(layout, rects):
		widths.append(entrance["width"])
	return widths


## Walking distance in cells (4-neighbour steps) from the nearest of `origins`; -1 = unreachable.
static func walk_distances(layout: MapLayout, origins: Array[Vector2i]) -> PackedInt32Array:
	var distances := PackedInt32Array()
	distances.resize(layout.size.x * layout.size.y)
	distances.fill(-1)
	var frontier: Array[Vector2i] = []
	for origin in origins:
		if layout.is_walkable(origin):
			distances[origin.y * layout.size.x + origin.x] = 0
			frontier.append(origin)
	var head := 0
	while head < frontier.size():
		var cell := frontier[head]
		head += 1
		var next_distance := distances[cell.y * layout.size.x + cell.x] + 1
		for offset in NEIGHBOURS_4:
			var next := cell + offset
			if layout.is_walkable(next) and distances[next.y * layout.size.x + next.x] < 0:
				distances[next.y * layout.size.x + next.x] = next_distance
				frontier.append(next)
	return distances


## Walkable cells of a rect, e.g. a spawn area.
static func walkable_cells(layout: MapLayout, rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for z in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if layout.is_walkable(Vector2i(x, z)):
				cells.append(Vector2i(x, z))
	return cells

class_name MapView
extends Node3D
## Draws a MapLayout with primitives: ground plane, blocked/water/tree cells as instanced
## boxes, spawn areas and plot outlines as flat translucent overlays.

var show_plots := true:
	set(value):
		show_plots = value
		if _plots:
			_plots.visible = value

var _plots: Node3D


func build(layout: MapLayout) -> void:
	var size := Vector3(layout.size.x * Coords.CELL, 0.0, layout.size.y * Coords.CELL)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.z)
	ground.mesh = plane
	ground.material_override = PlaceholderStyle.material(PlaceholderStyle.GROUND)
	ground.position = size * 0.5
	ground.name = "Ground"
	add_child(ground)

	var cells_by_terrain := {}
	for z in layout.size.y:
		for x in layout.size.x:
			var terrain := layout.terrain_at(Vector2i(x, z))
			if terrain != MapLayout.Terrain.GROUND:
				cells_by_terrain.get_or_add(terrain, []).append(Vector2i(x, z))
	_add_cells("Blocked", cells_by_terrain.get(MapLayout.Terrain.BLOCKED, []), PlaceholderStyle.BLOCKED,
		PlaceholderStyle.BLOCKED_HEIGHT, 1.0)
	_add_cells("Trees", cells_by_terrain.get(MapLayout.Terrain.TREE, []), PlaceholderStyle.TREE,
		PlaceholderStyle.TREE_HEIGHT, 0.7)
	_add_cells("Water", cells_by_terrain.get(MapLayout.Terrain.WATER, []), PlaceholderStyle.WATER, 0.05, 1.0)

	var spawns := Node3D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	for spawn in layout.spawns:
		spawns.add_child(_overlay(spawn.rect, PlaceholderStyle.SPAWN, 0.06))
	_plots = Node3D.new()
	_plots.name = "Plots"
	_plots.visible = show_plots
	add_child(_plots)
	for plot in layout.plots:
		for rect in plot.rects:
			_plots.add_child(_overlay(rect, PlaceholderStyle.PLOT, 0.04))


func _add_cells(node_name: String, cells: Array, colour: Color, height: float, width: float) -> void:
	if cells.is_empty():
		return
	var box := BoxMesh.new()
	box.size = Vector3(Coords.CELL * width, height, Coords.CELL * width)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = box
	multimesh.instance_count = cells.size()
	for i in cells.size():
		multimesh.set_instance_transform(i, Transform3D(Basis(), Coords.cell_centre(cells[i]) + Vector3.UP * height * 0.5))
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = PlaceholderStyle.material(colour)
	add_child(instance)


func _overlay(rect: Rect2i, colour: Color, lift: float) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(rect.size.x, rect.size.y) * Coords.CELL
	quad.mesh = plane
	quad.material_override = PlaceholderStyle.material(colour)
	quad.position = Coords.rect_centre(rect) + Vector3.UP * lift
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return quad

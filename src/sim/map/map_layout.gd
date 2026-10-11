class_name MapLayout
extends RefCounted
## Static terrain of a handcrafted map, authored in build-grid cells.
## File format: data/maps/README.md. Cell (x, z): x grows east, z grows south; row 0 is north.

enum Terrain { GROUND, BLOCKED, WATER, TREE }

const LEGEND := {
	".": Terrain.GROUND,
	"#": Terrain.BLOCKED,
	"~": Terrain.WATER,
	"T": Terrain.TREE,
}
const FORMAT_VERSION := 1


class Spawn:
	var id: String
	var rect: Rect2i


class Plot:
	var id: String
	var display_name: String
	## Union of rects; most plots are a single rect.
	var rects: Array[Rect2i] = []
	## Authored expectations, verified by tests against MapAnalysis.
	var expected_buildable_cells: int
	var expected_entrance_widths: Array[int] = []


var id: String
var display_name: String
var size: Vector2i
var start: Vector2i
var spawns: Array[Spawn] = []
var plots: Array[Plot] = []
var _terrain := PackedByteArray()


static func load_file(path: String) -> MapLayout:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("MapLayout: cannot read %s" % path)
		return null
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("MapLayout: %s is not a JSON object" % path)
		return null
	return from_dict(data)


static func from_dict(data: Dictionary) -> MapLayout:
	if int(data.get("format", 0)) != FORMAT_VERSION:
		push_error("MapLayout: unsupported format %s" % data.get("format"))
		return null
	var layout := MapLayout.new()
	layout.id = data["id"]
	layout.display_name = data.get("name", layout.id)
	layout.size = _vec2i(data["size"])
	var rows: Array = data["rows"]
	if rows.size() != layout.size.y:
		push_error("MapLayout %s: %d rows, expected %d" % [layout.id, rows.size(), layout.size.y])
		return null
	layout._terrain.resize(layout.size.x * layout.size.y)
	for z in rows.size():
		var row: String = rows[z]
		if row.length() != layout.size.x:
			push_error("MapLayout %s: row %d has %d cells, expected %d" % [layout.id, z, row.length(), layout.size.x])
			return null
		for x in row.length():
			var symbol := row[x]
			if not LEGEND.has(symbol):
				push_error("MapLayout %s: unknown symbol '%s' at (%d,%d)" % [layout.id, symbol, x, z])
				return null
			layout._terrain[z * layout.size.x + x] = LEGEND[symbol]
	layout.start = _vec2i(data["start"])
	for entry: Dictionary in data.get("spawns", []):
		var spawn := Spawn.new()
		spawn.id = entry["id"]
		spawn.rect = _rect2i(entry["rect"])
		layout.spawns.append(spawn)
	for entry: Dictionary in data.get("plots", []):
		var plot := Plot.new()
		plot.id = entry["id"]
		plot.display_name = entry.get("name", plot.id)
		for rect: Array in entry["rects"]:
			plot.rects.append(_rect2i(rect))
		var expected: Dictionary = entry.get("expected", {})
		plot.expected_buildable_cells = int(expected.get("buildable_cells", -1))
		for width in expected.get("entrance_widths", []):
			plot.expected_entrance_widths.append(int(width))
		layout.plots.append(plot)
	return layout


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func terrain_at(cell: Vector2i) -> Terrain:
	if not in_bounds(cell):
		return Terrain.BLOCKED
	return _terrain[cell.y * size.x + cell.x] as Terrain


func is_walkable(cell: Vector2i) -> bool:
	return terrain_at(cell) == Terrain.GROUND


func is_buildable(cell: Vector2i) -> bool:
	return terrain_at(cell) == Terrain.GROUND


func get_plot(plot_id: String) -> Plot:
	for plot in plots:
		if plot.id == plot_id:
			return plot
	return null


static func _vec2i(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))


static func _rect2i(value: Array) -> Rect2i:
	return Rect2i(int(value[0]), int(value[1]), int(value[2]), int(value[3]))

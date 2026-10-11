class_name Coords
## Build-grid cells <-> 3D world positions. Cell (x, z) spans [x, x+1) * CELL_SIZE on X and
## [z, z+1) * CELL_SIZE on Z; the ground is the y = 0 plane.

const CELL := SimConstants.CELL_SIZE


static func cell_centre(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * CELL, 0.0, (cell.y + 0.5) * CELL)


static func rect_centre(rect: Rect2i) -> Vector3:
	return Vector3((rect.position.x + rect.size.x * 0.5) * CELL, 0.0, (rect.position.y + rect.size.y * 0.5) * CELL)


static func world_to_cell(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / CELL), floori(position.z / CELL))


## Top-left cell of a footprint centred under `cell` (even sizes lean up-left).
static func footprint_origin(cell: Vector2i, footprint: Vector2i) -> Vector2i:
	return cell - (footprint - Vector2i.ONE) / 2

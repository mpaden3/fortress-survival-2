class_name PlaceholderStyle
## Colours and heights for primitive placeholder art. Replaced when real art exists.

const GROUND := Color(0.76, 0.70, 0.55)
const BLOCKED := Color(0.22, 0.22, 0.25)
const WATER := Color(0.25, 0.45, 0.78)
const TREE := Color(0.16, 0.42, 0.18)
const SPAWN := Color(0.85, 0.15, 0.15, 0.45)
const PLOT := Color(0.95, 0.35, 0.75, 0.18)
const GHOST_OK := Color(0.2, 0.9, 0.3, 0.5)
const GHOST_BAD := Color(0.95, 0.2, 0.2, 0.5)

const BLOCKED_HEIGHT := 3.0
const TREE_HEIGHT := 4.0

## By building id prefix: [colour, height in meters].
const BUILDINGS := {
	"wall": [Color(0.55, 0.52, 0.48), 2.5],
	"basic_tower": [Color(0.62, 0.58, 0.50), 5.0],
	"arrow_tower": [Color(0.55, 0.40, 0.25), 6.0],
	"cannon_tower": [Color(0.30, 0.30, 0.33), 5.5],
	"frost_tower": [Color(0.55, 0.80, 0.95), 6.0],
	"mill": [Color(0.60, 0.42, 0.22), 3.5],
	"barracks": [Color(0.55, 0.20, 0.18), 4.0],
}


static func building(def_id: StringName) -> Array:
	var id := String(def_id)
	var best := ""
	for prefix: String in BUILDINGS:
		if id.begins_with(prefix) and prefix.length() > best.length():
			best = prefix
	return BUILDINGS.get(best, [Color.MAGENTA, 3.0])


static func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	if colour.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

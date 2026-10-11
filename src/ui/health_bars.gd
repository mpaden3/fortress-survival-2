class_name HealthBars
extends Control
## HP bars floating above whatever is selected (units, the Survivor, a building), drawn in
## screen space over the 3D view.

const UNIT_WIDTH := 34.0
const BUILDING_WIDTH := 64.0
const HEIGHT := 5.0
## Meters above the ground the bar sits for movers.
const MOVER_TOP := 2.0

var game: Game


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "HealthBars"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Bars to draw: {centre (screen), width, ratio}.
func bars() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if game == null or game.selection_views == null:
		return out
	var camera := game.camera.camera
	var alpha := game.clock.alpha()
	for mover in game.selection_views.selected_movers():
		var at: Vector2 = mover.position_at(alpha)
		_add(out, camera, Vector3(at.x * Coords.CELL, MOVER_TOP, at.y * Coords.CELL), UNIT_WIDTH,
			mover.hp / mover.def.max_hp)
	var building := game.world.entities.get(game.builder.selected_entity) as BuildingState
	if building:
		var top: float = PlaceholderStyle.building(building.def.id)[1] + 0.6
		_add(out, camera, Coords.rect_centre(building.rect) + Vector3.UP * top, BUILDING_WIDTH,
			float(building.hp) / building.def.max_hp)
	return out


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for bar in bars():
		var width: float = bar["width"]
		var rect := Rect2(bar["centre"] - Vector2(width * 0.5, HEIGHT * 0.5), Vector2(width, HEIGHT))
		draw_rect(rect.grow(1.0), Color(0, 0, 0, 0.8))
		var ratio: float = clampf(bar["ratio"], 0.0, 1.0)
		var colour := HudStyle.HP_GOOD if ratio > 0.6 else (HudStyle.HP_MID if ratio > 0.3 else HudStyle.HP_LOW)
		draw_rect(Rect2(rect.position, Vector2(width * ratio, HEIGHT)), colour)


static func _add(out: Array[Dictionary], camera: Camera3D, at: Vector3, width: float, ratio: float) -> void:
	if camera.is_position_behind(at):
		return
	out.append({"centre": camera.unproject_position(at), "width": width, "ratio": ratio})

class_name SimFixtures
## Small, explicit worlds for tests.


## Open map of the given size; `blocked` cells are walls ('#').
static func open_map(width: int, height: int, blocked: Array[Vector2i] = []) -> MapLayout:
	var rows: Array[String] = []
	for z in height:
		var row := ""
		for x in width:
			row += "#" if Vector2i(x, z) in blocked else "."
		rows.append(row)
	return MapLayout.from_dict({"format": 1, "id": "fixture", "size": [width, height], "start": [0, 0], "rows": rows})


static func rules(starting_resource := 100) -> GameRules:
	var game_rules := GameRules.new()
	game_rules.starting_resource = starting_resource
	game_rules.sell_refund_ratio = 0.5
	game_rules.construction_start_hp_ratio = 0.1
	return game_rules


static func building(id: StringName, footprint := Vector2i.ONE, cost := 10, build_time := 1.0, max_hp := 100,
		placeable := true, upgrades: Array[StringName] = []) -> BuildingDef:
	var def := BuildingDef.new()
	def.id = id
	def.display_name = String(id)
	def.footprint = footprint
	def.cost = cost
	def.build_time = build_time
	def.max_hp = max_hp
	def.placeable = placeable
	def.upgrades = upgrades
	return def


## Registry with a 1x1 `wall`, a 2x2 `tower` and a non-placeable `tower_2`.
static func defs(starting_resource := 100) -> DefRegistry:
	var registry := DefRegistry.new()
	registry.rules = rules(starting_resource)
	registry.add_building(building(&"wall", Vector2i.ONE, 5, 1.0, 100))
	registry.add_building(building(&"tower", Vector2i(2, 2), 20, 2.0, 300, true, [&"tower_2"] as Array[StringName]))
	registry.add_building(building(&"tower_2", Vector2i(2, 2), 30, 2.0, 500, false))
	return registry


static func world(map: MapLayout = null, registry: DefRegistry = null, seed_value := 1) -> World:
	var w := World.new(map if map else open_map(16, 16), registry if registry else defs(), seed_value)
	w.add_player(0)
	return w

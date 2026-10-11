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
	game_rules.passive_income_per_minute = 0.0
	game_rules.sell_refund_ratio = 0.5
	game_rules.construction_start_hp_ratio = 0.1
	game_rules.path_cost_per_building_hp = 0.5
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


static func enemy(id: StringName, max_hp := 50.0, speed := 4.0, damage := 10.0, cooldown := 0.5,
		radius := 0.4) -> EnemyDef:
	var def := EnemyDef.new()
	def.id = id
	def.max_hp = max_hp
	def.speed = speed
	def.damage = damage
	def.attack_cooldown = cooldown
	def.radius = radius
	return def


## Registry with a 1x1 `wall`, a 2x2 `tower`, a non-placeable `tower_2`, and a `grunt` enemy.
static func defs(starting_resource := 100) -> DefRegistry:
	var registry := DefRegistry.new()
	registry.rules = rules(starting_resource)
	registry.survivor = SurvivorDef.new()
	registry.add_building(building(&"wall", Vector2i.ONE, 5, 1.0, 100))
	registry.add_building(building(&"tower", Vector2i(2, 2), 20, 2.0, 300, true, [&"tower_2"] as Array[StringName]))
	registry.add_building(building(&"tower_2", Vector2i(2, 2), 30, 2.0, 500, false))
	registry.add_enemy(enemy(&"grunt"))
	return registry


static func world(map: MapLayout = null, registry: DefRegistry = null, seed_value := 1) -> World:
	var w := World.new(map if map else open_map(16, 16), registry if registry else defs(), seed_value)
	w.add_player(0)
	return w


## Map from rows of '.', '#', '~', 'T'.
static func map_from_rows(rows: Array[String]) -> MapLayout:
	return MapLayout.from_dict({"format": 1, "id": "fixture", "size": [rows[0].length(), rows.size()],
		"start": [0, 0], "rows": rows})


## Places a building and finishes its construction instantly (no Survivor walking, free).
static func build_now(world: World, def_id: StringName, cell: Vector2i, player := 0) -> BuildingState:
	world.players[player].resource += world.defs.building(def_id).cost
	var reason := world.buildings.start_construction(world, player, def_id, cell)
	assert(reason.is_empty(), "build_now %s at %s: %s" % [def_id, cell, reason])
	world.step()
	var building := world.entities.get(world.grid.occupant(cell)) as BuildingState
	building.constructing = false
	building.hp = building.def.max_hp
	world.buildings._constructing.erase(building)
	return building


## Gives a building def an attack (ranges in cells, speeds in m/s; projectile 0 = instant).
static func armed(def: BuildingDef, attack_range := 5.0, damage := 10.0, cooldown := 1.0, projectile_speed := 0.0,
		splash := 0.0, slow := 1.0, slow_duration := 0.0) -> BuildingDef:
	def.attack_range = attack_range
	def.attack_damage = damage
	def.attack_cooldown = cooldown
	def.projectile_speed = projectile_speed
	def.splash_radius = splash
	def.slow_multiplier = slow
	def.slow_duration = slow_duration
	return def

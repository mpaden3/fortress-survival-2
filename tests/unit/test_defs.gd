extends GutTest
## Integrity of the shipped definitions in data/defs.

var registry: DefRegistry


func before_all() -> void:
	registry = DefRegistry.load_default()


func test_rules_and_buildings_load() -> void:
	assert_not_null(registry.rules)
	assert_eq(registry.rules.primary_resource_name, "wood")
	assert_gt(registry.buildings.size(), 0)


func test_mvp_roots_are_placeable() -> void:
	for id: StringName in [&"wall", &"basic_tower", &"mill", &"barracks"]:
		assert_not_null(registry.building(id), "%s exists" % id)
		assert_true(registry.building(id).placeable, "%s placeable" % id)


func test_basic_tower_branches() -> void:
	assert_eq(registry.building(&"basic_tower").upgrades,
		[&"arrow_tower", &"cannon_tower", &"frost_tower"] as Array[StringName])


func test_sane_values() -> void:
	for def: BuildingDef in registry.buildings.values():
		assert_true(def.footprint.x > 0 and def.footprint.y > 0, "%s footprint" % def.id)
		assert_true(def.cost >= 0 and def.max_hp > 0 and def.build_time > 0, "%s stats" % def.id)


## Every upgrade target exists, keeps the footprint, and each non-root building is reached
## from exactly one parent: the upgrade graph is a forest of trees.
func test_upgrade_graph_is_a_forest() -> void:
	var parents := {}
	for def: BuildingDef in registry.buildings.values():
		for target in def.upgrades:
			var child := registry.building(target)
			assert_not_null(child, "%s -> %s exists" % [def.id, target])
			if child == null:
				continue
			assert_eq(child.footprint, def.footprint, "%s -> %s keeps footprint" % [def.id, target])
			assert_false(child.placeable, "%s is upgrade-only" % target)
			parents[target] = parents.get(target, 0) + 1
	for def: BuildingDef in registry.buildings.values():
		if not def.placeable:
			assert_eq(parents.get(def.id, 0), 1, "%s has exactly one parent" % def.id)


## Every damage and armor type used is in the multiplier table, and the tower branches have
## distinct jobs (arrows for light enemies, cannons for heavy ones).
func test_damage_and_armor_types() -> void:
	var rules := registry.rules
	var armors := {}
	for def in registry.enemy_list:
		armors[def.armor_type] = true
	for def: BuildingDef in registry.buildings.values():
		if def.is_armed():
			assert_true(def.damage_type == &"normal" or rules.damage_multipliers.has(def.damage_type),
				"%s damage type %s in the table" % [def.id, def.damage_type])
	for damage_type: StringName in rules.damage_multipliers:
		for armor: StringName in rules.damage_multipliers[damage_type]:
			assert_true(armors.has(armor), "%s vs %s: armor type in use" % [damage_type, armor])
	assert_gt(rules.damage_multiplier(&"pierce", &"light"), rules.damage_multiplier(&"siege", &"light"))
	assert_gt(rules.damage_multiplier(&"siege", &"heavy"), rules.damage_multiplier(&"pierce", &"heavy"))


func test_units_and_what_trains_them() -> void:
	assert_true(registry.unit(&"fighter").is_fighter())
	assert_true(registry.unit(&"repairman").is_repairer())
	for def: BuildingDef in registry.buildings.values():
		for unit_id in def.trains:
			assert_not_null(registry.unit(unit_id), "%s trains %s, which exists" % [def.id, unit_id])
	assert_eq(registry.building(&"barracks").trains, [&"fighter", &"repairman"] as Array[StringName])

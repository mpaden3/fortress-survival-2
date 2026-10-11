class_name EnemyManager
extends RefCounted
## All enemies as flat arrays (no object per enemy) so hordes of thousands stay cheap.
## Index = dense slot (swap-removed on death); `ids` holds each enemy's stable entity id.
## Positions are in cell units (1.0 = one build cell); views multiply by SimConstants.CELL_SIZE.
##
## Per tick each enemy: follows its target's FlowField (blended, continuous), keeps apart
## from neighbours, can't enter blocked terrain or building cells, and attacks the building
## blocking its way.

## How far ahead (cells, beyond the body) an enemy looks for a building to attack.
const ATTACK_REACH := 0.35
## Most neighbours considered for separation per enemy per tick (caps worst-case cost).
const MAX_NEIGHBOURS := 10
## Flow cost under which an enemy counts as arrived and stops pressing forward
## (just over one diagonal step), so crowds at the target don't compress.
const ARRIVED_COST := 15

var ids := PackedInt32Array()
var types := PackedInt32Array()
var positions := PackedVector2Array()
var hp := PackedFloat32Array()
var cooldowns := PackedInt32Array()
## Index into target_keys of each enemy's hunt target.
var targets := PackedInt32Array()
## Building id each enemy is attacking this tick, 0 if none.
var attacking := PackedInt32Array()
var target_keys: Array[StringName] = []
## Microseconds the last update took.
var update_usec := 0

var _bucket_head := PackedInt32Array()
var _bucket_next := PackedInt32Array()
## Per enemy type: cells moved per tick, body radius in cells.
var _type_step := PackedFloat32Array()
var _type_radius := PackedFloat32Array()


func register(world: World) -> void:
	world.register_command(Commands.DEBUG_SPAWN, _debug_spawn)


func count() -> int:
	return ids.size()


func _debug_spawn(world: World, command: Dictionary) -> String:
	if world.defs.enemy(command["def"]) == null:
		return "unknown_def"
	for spawn in world.map.spawns:
		if spawn.id == command["spawn"]:
			spawn(world, command["def"], spawn.rect, command["amount"], command["target"])
			return ""
	return "unknown_spawn"


## Spawns `amount` enemies of `def_id` on random walkable cells of `area`, hunting `target`.
func spawn(world: World, def_id: StringName, area: Rect2i, amount: int, target: StringName) -> Array[int]:
	var type_index := world.defs.enemy_index(def_id)
	assert(type_index >= 0, "unknown enemy %s" % def_id)
	var def := world.defs.enemy_list[type_index]
	var cells := MapAnalysis.walkable_cells(world.map, area).filter(
		func(c: Vector2i) -> bool: return world.grid.occupant(c) == BuildGrid.NONE)
	var spawned: Array[int] = []
	if cells.is_empty():
		return spawned
	var target_index := target_keys.find(target)
	if target_index < 0:
		target_keys.append(target)
		target_index = target_keys.size() - 1
	for i in amount:
		var cell: Vector2i = world.rng.pick(cells)
		var entity_id := world.new_id()
		ids.append(entity_id)
		types.append(type_index)
		positions.append(Vector2(cell.x + 0.2 + world.rng.randf() * 0.6, cell.y + 0.2 + world.rng.randf() * 0.6))
		hp.append(def.max_hp)
		cooldowns.append(0)
		targets.append(target_index)
		attacking.append(0)
		spawned.append(entity_id)
	if DebugLog.on(&"waves"):
		DebugLog.event(&"waves", {"spawned": amount, "def": def_id, "area": area.position, "target": target})
	return spawned


func index_of(entity_id: int) -> int:
	return ids.find(entity_id)


## Damages enemy slot `index`; returns true if it died (it's removed immediately).
func damage(index: int, amount: float) -> bool:
	hp[index] -= amount
	if hp[index] > 0.0:
		return false
	if DebugLog.on(&"combat"):
		DebugLog.event(&"combat", {"enemy_killed": ids[index], "pos": positions[index]})
	_remove(index)
	return true


func update(world: World) -> void:
	var started := Time.get_ticks_usec()
	var n := ids.size()
	if n == 0:
		update_usec = 0
		return
	# Hot loop: everything read through local packed arrays, no per-enemy function calls.
	var width := world.map.size.x
	var height := world.map.size.y
	var blocked := world.grid.blocked
	var occupants := world.grid.occupants()
	_cache_types(world)
	var step_of := _type_step
	var radius_of := _type_radius
	_fill_buckets(width, height)
	var heads := _bucket_head
	var nexts := _bucket_next
	var old := positions.duplicate()
	var dir_fields: Array[PackedVector2Array] = []
	var cost_fields: Array[PackedInt64Array] = []
	for key in target_keys:
		var flow := world.pathing.field(key)
		dir_fields.append(flow.direction if flow else PackedVector2Array())
		cost_fields.append(flow.cost if flow else PackedInt64Array())
	# Separation runs for half the enemies each tick (alternating), at double strength.
	var parity := world.tick & 1
	var log_collision := DebugLog.on(&"collision")
	var log_combat := DebugLog.on(&"combat")

	for i in n:
		var t := types[i]
		var radius := radius_of[t]
		var pos := old[i]
		var cx := floori(pos.x)
		var cz := floori(pos.y)

		# Flow direction: bilinear blend of the 4 nearest cell directions.
		var dir := Vector2.ZERO
		var dirs := dir_fields[targets[i]]
		if not dirs.is_empty() and cost_fields[targets[i]][cz * width + cx] > ARRIVED_COST:
			var fx := pos.x - 0.5
			var fz := pos.y - 0.5
			var x0 := floori(fx)
			var z0 := floori(fz)
			var tx := fx - x0
			var tz := fz - z0
			var x1 := mini(x0 + 1, width - 1)
			var z1 := mini(z0 + 1, height - 1)
			x0 = maxi(x0, 0)
			z0 = maxi(z0, 0)
			dir = dirs[z0 * width + x0] * ((1.0 - tx) * (1.0 - tz)) + dirs[z0 * width + x1] * (tx * (1.0 - tz)) \
				+ dirs[z1 * width + x0] * ((1.0 - tx) * tz) + dirs[z1 * width + x1] * (tx * tz)
			if dir.length_squared() < 0.04:
				dir = dirs[cz * width + cx]
			else:
				dir = dir.normalized()

		var desired := dir * step_of[t]
		attacking[i] = 0
		if dir != Vector2.ZERO:
			var ahead := pos + dir * (radius + ATTACK_REACH)
			var ax := floori(ahead.x)
			var az := floori(ahead.y)
			var blocker := 0
			if (ax != cx or az != cz) and ax >= 0 and az >= 0 and ax < width and az < height:
				blocker = occupants[az * width + ax]
			if blocker != 0:
				desired = Vector2.ZERO
				attacking[i] = blocker
				if cooldowns[i] > 0:
					cooldowns[i] -= 1
				else:
					var def := world.defs.enemy_list[t]
					cooldowns[i] = def.cooldown_ticks()
					var amount := def.damage * def.building_damage_multiplier
					if log_combat:
						DebugLog.event(&"combat", {"enemy": ids[i], "hits_building": blocker, "damage": amount})
					world.buildings.damage(world, blocker, amount)
					occupants = world.grid.occupants()
			elif cooldowns[i] > 0:
				cooldowns[i] -= 1

		# Separation from neighbours in the 3x3 surrounding buckets.
		var push := Vector2.ZERO
		var checked := 0 if (i & 1) == parity else MAX_NEIGHBOURS
		for bz in range(maxi(cz - 1, 0), mini(cz + 2, height)):
			if checked >= MAX_NEIGHBOURS:
				break
			for bx in range(maxi(cx - 1, 0), mini(cx + 2, width)):
				var j := heads[bz * width + bx]
				while j >= 0 and checked < MAX_NEIGHBOURS:
					if j != i:
						var offset := pos - old[j]
						var min_dist := radius + radius_of[types[j]]
						var dist_sq := offset.length_squared()
						if dist_sq < min_dist * min_dist:
							if dist_sq > 0.000001:
								var dist := sqrt(dist_sq)
								push += offset * ((min_dist - dist) / dist)
							else:
								push += Vector2(0.01 * ((i & 1) * 2 - 1), 0.01)
							checked += 1
					j = nexts[j]

		# Move without ending in a blocked cell; slide along walls one axis at a time.
		var moved := pos + desired + push
		if _open(blocked, width, height, moved):
			positions[i] = moved
		elif _open(blocked, width, height, Vector2(moved.x, pos.y)):
			positions[i] = Vector2(moved.x, pos.y)
		elif _open(blocked, width, height, Vector2(pos.x, moved.y)):
			positions[i] = Vector2(pos.x, moved.y)
		elif log_collision:
			DebugLog.event(&"collision", {"enemy": ids[i], "blocked_at": moved})
	update_usec = Time.get_ticks_usec() - started


func snapshot() -> Array:
	var out := []
	for i in ids.size():
		out.append({"id": ids[i], "type": types[i], "pos": [snappedf(positions[i].x, 0.01), snappedf(positions[i].y, 0.01)],
			"hp": hp[i], "attacking": attacking[i]})
	return out


static func _open(blocked: PackedByteArray, width: int, height: int, pos: Vector2) -> bool:
	var x := floori(pos.x)
	var z := floori(pos.y)
	return x >= 0 and z >= 0 and x < width and z < height and blocked[z * width + x] == 0


func _cache_types(world: World) -> void:
	var defs := world.defs.enemy_list
	if _type_step.size() == defs.size():
		return
	_type_step.resize(defs.size())
	_type_radius.resize(defs.size())
	for t in defs.size():
		_type_step[t] = defs[t].speed / SimConstants.CELL_SIZE / SimConstants.TICK_RATE
		_type_radius[t] = defs[t].radius / SimConstants.CELL_SIZE


func _fill_buckets(width: int, height: int) -> void:
	if _bucket_head.size() != width * height:
		_bucket_head.resize(width * height)
	_bucket_head.fill(-1)
	_bucket_next.resize(ids.size())
	for i in ids.size():
		var p := positions[i]
		var bucket := floori(p.y) * width + floori(p.x)
		_bucket_next[i] = _bucket_head[bucket]
		_bucket_head[bucket] = i


func _remove(index: int) -> void:
	var last := ids.size() - 1
	if index != last:
		ids[index] = ids[last]
		types[index] = types[last]
		positions[index] = positions[last]
		hp[index] = hp[last]
		cooldowns[index] = cooldowns[last]
		targets[index] = targets[last]
		attacking[index] = attacking[last]
	ids.resize(last)
	types.resize(last)
	positions.resize(last)
	hp.resize(last)
	cooldowns.resize(last)
	targets.resize(last)
	attacking.resize(last)

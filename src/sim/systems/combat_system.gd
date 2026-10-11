class_name CombatSystem
extends RefCounted
## Towers acquire the nearest enemy in range and fire; projectiles home in on their target and
## apply damage, splash and slow on impact. Projectiles are flat arrays like enemies.

var proj_pos := PackedVector2Array()
## Target's stable enemy id; the projectile keeps flying to its last position if it dies.
var proj_target := PackedInt32Array()
var proj_aim := PackedVector2Array()
## Cells per tick.
var proj_speed := PackedFloat32Array()
var proj_def: Array[BuildingDef] = []
var proj_source := PackedInt32Array()
## Microseconds the last update took.
var update_usec := 0


func projectile_count() -> int:
	return proj_pos.size()


func update(world: World) -> void:
	var started := Time.get_ticks_usec()
	world.enemies.begin_batch()
	_fire(world)
	_move_projectiles(world)
	world.enemies.end_batch()
	update_usec = Time.get_ticks_usec() - started


func _fire(world: World) -> void:
	var enemies := world.enemies
	var log_combat := DebugLog.on(&"combat")
	for entity: SimEntity in world.entities.values():
		var tower := entity as BuildingState
		if tower == null or not tower.can_attack():
			continue
		if tower.attack_cooldown > 0:
			tower.attack_cooldown -= 1
			continue
		var origin := tower.centre()
		var target := enemies.nearest_in_range(origin, tower.def.attack_range)
		if target < 0:
			continue
		tower.attack_cooldown = tower.def.cooldown_ticks() - 1
		if log_combat:
			DebugLog.event(&"combat", {"tower": tower.id, "def": tower.def.id, "fires_at": enemies.ids[target],
				"distance": origin.distance_to(enemies.positions[target])})
		if tower.def.projectile_speed <= 0.0:
			_impact(world, tower.def, tower.id, enemies.positions[target], enemies.ids[target])
		else:
			proj_pos.append(origin)
			proj_target.append(enemies.ids[target])
			proj_aim.append(enemies.positions[target])
			proj_speed.append(tower.def.projectile_speed / SimConstants.CELL_SIZE / SimConstants.TICK_RATE)
			proj_def.append(tower.def)
			proj_source.append(tower.id)


func _move_projectiles(world: World) -> void:
	var enemies := world.enemies
	for i in range(proj_pos.size() - 1, -1, -1):
		var index := enemies.index_of(proj_target[i])
		if enemies.is_alive(index):
			proj_aim[i] = enemies.positions[index]
		var to := proj_aim[i] - proj_pos[i]
		var distance := to.length()
		if distance > proj_speed[i]:
			proj_pos[i] += to / distance * proj_speed[i]
			continue
		_impact(world, proj_def[i], proj_source[i], proj_aim[i], proj_target[i])
		_remove_projectile(i)


func _impact(world: World, def: BuildingDef, source: int, point: Vector2, target_id: int) -> void:
	var enemies := world.enemies
	var hit := PackedInt32Array()
	if def.splash_radius > 0.0:
		hit = enemies.indices_in_radius(point, def.splash_radius)
	else:
		var index := enemies.index_of(target_id)
		if enemies.is_alive(index):
			hit.append(index)
	var slow_until := world.tick + roundi(def.slow_duration * SimConstants.TICK_RATE)
	for index in hit:
		if def.slow_multiplier < 1.0:
			enemies.apply_slow(index, def.slow_multiplier, world.tick, slow_until)
		enemies.damage(index, def.attack_damage)
	if DebugLog.on(&"combat"):
		DebugLog.event(&"combat", {"impact_from": source, "at": point, "hits": hit.size(), "damage": def.attack_damage})


func _remove_projectile(i: int) -> void:
	var last := proj_pos.size() - 1
	if i != last:
		proj_pos[i] = proj_pos[last]
		proj_target[i] = proj_target[last]
		proj_aim[i] = proj_aim[last]
		proj_speed[i] = proj_speed[last]
		proj_def[i] = proj_def[last]
		proj_source[i] = proj_source[last]
	proj_pos.resize(last)
	proj_target.resize(last)
	proj_aim.resize(last)
	proj_speed.resize(last)
	proj_def.resize(last)
	proj_source.resize(last)

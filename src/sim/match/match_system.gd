class_name MatchSystem
extends RefCounted
## Runs a match: the wave schedule, the timer and the result.
## Won when the timer runs out with a Survivor alive; lost when every Survivor is dead.
## Inactive until start() (tests that don't need waves never call it).

enum Result { RUNNING, WON, LOST }

var schedule: WaveSchedule
var result := Result.RUNNING
var start_tick := 0
var active := false
## Latest announcement and the tick it was made, for the HUD.
var announcement := ""
var announcement_tick := -1

var _carry := PackedFloat32Array()
var _events: Array[SpawnEvent] = []
var _next_event := 0


func start(world: World, wave_schedule: WaveSchedule) -> void:
	schedule = wave_schedule
	start_tick = world.tick
	active = true
	result = Result.RUNNING
	_carry.resize(schedule.streams.size())
	_carry.fill(0.0)
	_next_event = 0
	_events = schedule.events.duplicate()
	_events.sort_custom(func(a: SpawnEvent, b: SpawnEvent) -> bool: return a.time < b.time)
	if DebugLog.on(&"state"):
		DebugLog.event(&"state", {"match_started": schedule.resource_path, "duration": schedule.duration})


func elapsed(world: World) -> float:
	return float(world.tick - start_tick) / SimConstants.TICK_RATE


func remaining(world: World) -> float:
	return maxf(0.0, schedule.duration - elapsed(world)) if schedule else 0.0


func update(world: World) -> void:
	if not active or result != Result.RUNNING:
		return
	if world.survivors.living().is_empty():
		_end(world, Result.LOST)
		return
	var seconds := elapsed(world)
	if seconds >= schedule.duration:
		_end(world, Result.WON)
		return
	if seconds < schedule.grace_period:
		return
	for i in schedule.streams.size():
		var stream := schedule.streams[i]
		_carry[i] += stream.rate_at(seconds) / 60.0 / SimConstants.TICK_RATE
		while _carry[i] >= stream.group_size:
			_carry[i] -= stream.group_size
			_spawn(world, stream.enemy, stream.group_size, "")
	while _next_event < _events.size() and _events[_next_event].time <= seconds:
		var event := _events[_next_event]
		_next_event += 1
		_spawn(world, event.enemy, event.count, event.spawn)
		if not event.announcement.is_empty():
			announcement = event.announcement
			announcement_tick = world.tick
			if DebugLog.on(&"waves"):
				DebugLog.message(&"waves", "announce: %s" % event.announcement)


func _spawn(world: World, enemy: StringName, count: int, spawn_id: String) -> void:
	var spawns := world.map.spawns
	var spawn: MapLayout.Spawn = null
	for candidate in spawns:
		if candidate.id == spawn_id:
			spawn = candidate
	if spawn == null:
		spawn = world.rng.pick(spawns)
	world.enemies.spawn(world, enemy, spawn.rect, count)


func _end(world: World, how: Result) -> void:
	result = how
	if DebugLog.on(&"state"):
		DebugLog.event(&"state", {"match_over": Result.keys()[how], "elapsed": elapsed(world)})
	world.match_ended.emit(how)


## Save/load (WorldState). The schedule is saved by path (the default one if it has none).
func save_state() -> Dictionary:
	var data := ObjectState.dump(self, ["schedule", "_events"] as Array[String])
	data["schedule_path"] = schedule.resource_path if schedule else ""
	return data


func load_state(world: World, data: Dictionary) -> void:
	ObjectState.load_into(self, data, world.defs)
	schedule = null
	_events.clear()
	if data.has("schedule_path") and (active or data["schedule_path"] != ""):
		var path: String = data["schedule_path"]
		schedule = load(path) if path != "" else world.defs.schedule
		_events = schedule.events.duplicate()
		_events.sort_custom(func(a: SpawnEvent, b: SpawnEvent) -> bool: return a.time < b.time)

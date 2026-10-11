class_name SfxViews
extends Node3D
## Plays a sound for simulation events (shots, impacts, kills, destroyed buildings, unit hits
## and deaths) from a pool of positional players. Hordes make hundreds of events a second, so
## each sound plays at most `PER_TICK` times per tick and the pool caps the voices.

enum Sound { SHOT, HIT, EXPLOSION, FROST, ENEMY_DEATH, BUILDING_DOWN, UNIT_HIT, UNIT_DEATH }

const POOL_SIZE := 24
const PER_TICK := 2

var _world: World
var _streams: Array[AudioStreamWAV] = []
var _pool: Array[AudioStreamPlayer3D] = []
var _next := 0
var _plays: Array[int] = []
var _this_tick := PackedInt32Array()


func attach(world: World) -> void:
	_world = world
	world.stepped.connect(_on_stepped)


func _ready() -> void:
	# [seconds, tone, tone_end, noise, smooth, decay, volume] per Sound.
	var recipes := [
		[0.08, 900.0, 500.0, 0.6, 0.2, 6.0, 0.35],   # SHOT: short twang
		[0.07, 220.0, 120.0, 0.5, 0.5, 7.0, 0.45],   # HIT: dull thud
		[0.55, 70.0, 35.0, 0.85, 0.85, 4.0, 0.9],    # EXPLOSION: low rumble
		[0.30, 1800.0, 2600.0, 0.3, 0.1, 5.0, 0.3],  # FROST: icy shimmer
		[0.18, 420.0, 160.0, 0.25, 0.3, 5.0, 0.35],  # ENEMY_DEATH: falling grunt
		[0.90, 55.0, 30.0, 0.9, 0.9, 3.0, 1.0],      # BUILDING_DOWN: heavy crash
		[0.05, 1200.0, 900.0, 0.4, 0.1, 8.0, 0.3],   # UNIT_HIT: click
		[0.30, 300.0, 110.0, 0.2, 0.3, 4.0, 0.45],   # UNIT_DEATH: low fall
	]
	for k in recipes.size():
		var r: Array = recipes[k]
		_streams.append(SfxSynth.make(r[0], r[1], r[2], r[3], r[4], r[5], r[6], k + 1))
	_plays.resize(Sound.size())
	_plays.fill(0)
	_this_tick.resize(Sound.size())
	for i in POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		player.unit_size = 25.0
		player.max_distance = 220.0
		add_child(player)
		_pool.append(player)


## Times `sound` was played (tests).
func play_count(sound: Sound) -> int:
	return _plays[sound]


func play(sound: Sound, at: Vector3) -> void:
	if _this_tick[sound] >= PER_TICK:
		return
	_this_tick[sound] += 1
	_plays[sound] += 1
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = _streams[sound]
	player.position = at
	player.pitch_scale = 0.9 + 0.2 * randf()
	player.play()


func _on_stepped() -> void:
	_this_tick.fill(0)
	var events := _world.events
	var cell := SimConstants.CELL_SIZE
	for i in events.count():
		var at := Vector3(events.positions[i].x * cell, 1.0, events.positions[i].y * cell)
		match events.kinds[i]:
			SimEvents.Kind.FIRED:
				play(Sound.SHOT, at)
			SimEvents.Kind.IMPACT:
				var def := _world.defs.building(events.defs[i])
				if def and def.slow_multiplier < 1.0:
					play(Sound.FROST, at)
				elif def and def.splash_radius > 0.0:
					play(Sound.EXPLOSION, at)
				else:
					play(Sound.HIT, at)
			SimEvents.Kind.ENEMY_KILLED:
				play(Sound.ENEMY_DEATH, at)
			SimEvents.Kind.BUILDING_DESTROYED:
				play(Sound.BUILDING_DOWN, at)
			SimEvents.Kind.UNIT_ATTACK:
				play(Sound.UNIT_HIT, at)
			SimEvents.Kind.UNIT_KILLED:
				play(Sound.UNIT_DEATH, at)

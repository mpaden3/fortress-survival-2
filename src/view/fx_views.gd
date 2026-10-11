class_name FxViews
extends Node3D
## Visual effects driven by the simulation: muzzle flashes, impacts, enemy deaths and
## explosions from `world.events` after each step, and fires on damaged buildings from their
## HP. Observes only. One-shot effects come from fixed-size pools: in a huge wave the oldest
## effect is reused instead of adding nodes without limit.

const MUZZLE_FLASH := preload("res://scenes/vfx/muzzle_flash.tscn")
const HIT_SPARK := preload("res://scenes/vfx/hit_spark.tscn")
const EXPLOSION := preload("res://scenes/vfx/explosion.tscn")
const FROST_BURST := preload("res://scenes/vfx/frost_burst.tscn")
const ENEMY_DEATH := preload("res://scenes/vfx/enemy_death.tscn")
const BUILDING_FIRE := preload("res://scenes/vfx/building_fire.tscn")

const POOL_SIZES := {MUZZLE_FLASH: 32, HIT_SPARK: 48, EXPLOSION: 16, FROST_BURST: 24, ENEMY_DEATH: 64}
## A building burns below this HP fraction; the fire grows as HP drops further.
const BURN_BELOW := 0.6
## Meters above the tower top where shots leave, and above the ground where they land.
const MUZZLE_OFFSET := 0.3
const IMPACT_HEIGHT := 1.0
## Effect scale = radius (m) / the radius the scene was authored at.
const EXPLOSION_RADIUS := 3.5
const FROST_RADIUS := 2.0
const ENEMY_RADIUS := 0.4


class Pool:
	var scene: PackedScene
	var size := 0
	var effects: Array[VfxBurst] = []
	var next := 0


var _world: World
## Whose fog of war applies (set by Game): events in hidden cells make no effect or sound.
var player_id := 0
var _pools: Dictionary[PackedScene, Pool] = {}
var _fires: Dictionary[int, VfxLoop] = {}


func attach(world: World) -> void:
	_world = world
	for scene: PackedScene in POOL_SIZES:
		var pool := Pool.new()
		pool.scene = scene
		pool.size = POOL_SIZES[scene]
		_pools[scene] = pool
	world.stepped.connect(_on_stepped)
	world.entity_removed.connect(_on_entity_removed)


## Plays a pooled one-shot effect at `point` (meters).
func play(scene: PackedScene, point: Vector3, size := 1.0) -> VfxBurst:
	var pool := _pools[scene]
	var effect: VfxBurst
	if pool.effects.size() < pool.size:
		effect = scene.instantiate()
		add_child(effect)
		pool.effects.append(effect)
	else:
		effect = pool.effects[pool.next]
		pool.next = (pool.next + 1) % pool.size
	effect.position = point
	effect.scale = Vector3.ONE * size
	effect.play()
	return effect


func playing_count(scene: PackedScene) -> int:
	var count := 0
	for effect in _pools[scene].effects:
		if effect.is_playing():
			count += 1
	return count


func fire_of(building_id: int) -> VfxLoop:
	return _fires.get(building_id)


func _on_stepped() -> void:
	var events := _world.events
	var cell := SimConstants.CELL_SIZE
	var fog := _world.visibility.mask(player_id)
	for i in events.count():
		if not VisibilitySystem.shown(fog, _world.map.size.x, events.positions[i]):
			continue
		var at := Vector3(events.positions[i].x * cell, 0.0, events.positions[i].y * cell)
		match events.kinds[i]:
			SimEvents.Kind.FIRED:
				at.y = PlaceholderStyle.building(events.defs[i])[1] + MUZZLE_OFFSET
				play(MUZZLE_FLASH, at)
			SimEvents.Kind.IMPACT:
				_play_impact(_world.defs.building(events.defs[i]), at)
			SimEvents.Kind.ENEMY_KILLED:
				var enemy := _world.defs.enemy(events.defs[i])
				play(ENEMY_DEATH, at, maxf(enemy.radius / ENEMY_RADIUS, 1.0) if enemy else 1.0)
			SimEvents.Kind.BUILDING_DESTROYED:
				var building := _world.defs.building(events.defs[i])
				var footprint := maxi(building.footprint.x, building.footprint.y) if building else 1
				play(EXPLOSION, at, 0.6 + 0.4 * footprint)
			SimEvents.Kind.UNIT_ATTACK:
				at.y = IMPACT_HEIGHT
				play(HIT_SPARK, at)
			SimEvents.Kind.UNIT_KILLED:
				play(ENEMY_DEATH, at)


func _play_impact(def: BuildingDef, at: Vector3) -> void:
	var radius := def.splash_radius * SimConstants.CELL_SIZE if def else 0.0
	if def and def.slow_multiplier < 1.0:
		play(FROST_BURST, at, maxf(radius / FROST_RADIUS, 1.0))
	elif radius > 0.0:
		play(EXPLOSION, at, radius / EXPLOSION_RADIUS)
	else:
		at.y = IMPACT_HEIGHT
		play(HIT_SPARK, at)


func _process(_delta: float) -> void:
	if _world == null:
		return
	for entity: SimEntity in _world.entities.values():
		var building := entity as BuildingState
		if building == null:
			continue
		var health := float(building.hp) / building.def.max_hp
		var burning := not building.constructing and health < BURN_BELOW
		var fire: VfxLoop = _fires.get(building.id)
		if burning and fire == null:
			fire = BUILDING_FIRE.instantiate()
			var top: float = PlaceholderStyle.building(building.def.id)[1]
			fire.position = Coords.rect_centre(building.rect) + Vector3.UP * top
			fire.scale = Vector3.ONE * (0.5 + 0.5 * maxi(building.rect.size.x, building.rect.size.y))
			add_child(fire)
			_fires[building.id] = fire
		elif not burning and fire:
			_remove_fire(building.id)
			continue
		if fire:
			fire.intensity = 1.0 - health / BURN_BELOW


func _on_entity_removed(entity: SimEntity) -> void:
	_remove_fire(entity.id)


func _remove_fire(building_id: int) -> void:
	var fire: VfxLoop = _fires.get(building_id)
	if fire:
		fire.queue_free()
		_fires.erase(building_id)

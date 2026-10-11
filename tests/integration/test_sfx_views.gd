extends GutTest
## SfxViews: a sound per simulation event, capped per tick so hordes don't flood the mixer.

var world: World
var sfx: SfxViews
var tower_def: BuildingDef


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(40, 20))
	tower_def = world.defs.building(&"tower")
	world.pathing.set_target(&"stay", [Vector2i(13, 11)] as Array[Vector2i])
	sfx = SfxViews.new()
	add_child_autofree(sfx)
	sfx.attach(world)


func test_shot_and_hit_play_sounds() -> void:
	SimFixtures.armed(tower_def, 5.0, 10.0, 1.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")
	world.step()
	assert_eq(sfx.play_count(SfxViews.Sound.SHOT), 1)
	assert_eq(sfx.play_count(SfxViews.Sound.HIT), 1)


func test_splash_and_frost_and_kills_have_their_own_sounds() -> void:
	SimFixtures.armed(tower_def, 5.0, 100.0, 1.0, 0.0, 1.5, 0.5, 1.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")
	world.step()
	assert_eq(sfx.play_count(SfxViews.Sound.FROST), 1, "slowing shots sound frosty")
	assert_eq(sfx.play_count(SfxViews.Sound.ENEMY_DEATH), 1)


func test_each_sound_is_capped_per_tick() -> void:
	SimFixtures.armed(tower_def, 5.0, 1.0, 1.0)
	for x in [4, 8, 12, 16, 20]:
		SimFixtures.build_now(world, &"tower", Vector2i(x, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(4, 12, 18, 1), 20, &"stay")
	world.step()
	assert_eq(world.events.of_kind(SimEvents.Kind.FIRED).size(), 5, "five towers fired")
	assert_eq(sfx.play_count(SfxViews.Sound.SHOT), SfxViews.PER_TICK, "but only a few shots are heard")


func test_synth_makes_audible_clips() -> void:
	var clip := SfxSynth.make(0.1, 440.0, 440.0, 0.0, 0.0, 1.0)
	assert_eq(clip.data.size(), int(0.1 * SfxSynth.MIX_RATE) * 2, "16-bit mono")
	var loudest := 0
	for i in range(0, clip.data.size(), 2):
		loudest = maxi(loudest, absi(clip.data.decode_s16(i)))
	assert_gt(loudest, 10000)

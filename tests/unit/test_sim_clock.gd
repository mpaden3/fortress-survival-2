extends GutTest


func test_whole_ticks_from_frame_time() -> void:
	var clock := SimClock.new()
	assert_eq(clock.consume(SimConstants.TICK_DELTA * 0.5), 0)
	assert_eq(clock.consume(SimConstants.TICK_DELTA * 0.5), 1)
	assert_eq(clock.consume(SimConstants.TICK_DELTA * 3), 3)


func test_leftover_time_carries_over() -> void:
	var clock := SimClock.new()
	assert_eq(clock.consume(SimConstants.TICK_DELTA * 1.75), 1)
	assert_almost_eq(clock.alpha(), 0.75, 0.001)
	assert_eq(clock.consume(SimConstants.TICK_DELTA * 0.25), 1)


func test_long_hitch_is_capped() -> void:
	var clock := SimClock.new()
	assert_eq(clock.consume(10.0), SimClock.MAX_TICKS_PER_FRAME)
	assert_eq(clock.consume(0.0), 0, "backlog dropped after a hitch")

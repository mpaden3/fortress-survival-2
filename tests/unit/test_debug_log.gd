extends GutTest


func before_each() -> void:
	DebugLog.clear_captured()
	for category in DebugLog.CATEGORIES:
		DebugLog.set_category(category, true)


func test_active_under_tests() -> void:
	assert_true(DebugLog.active, "logging is on in test runs of debug builds")


func test_format_line() -> void:
	var line := DebugLog.format_line(120, &"units", {
		"id": 17, "type": "grunt", "pos": Vector3(12, 0, 4.5), "hp": 40, "speed": 1.25,
	})
	assert_eq(line, "[t=120][units] id=17 type=grunt pos=(12.00,0.00,4.50) hp=40 speed=1.25")


func test_event_is_captured_with_current_tick() -> void:
	DebugLog.tick = 7
	DebugLog.event(&"combat", {"attacker": 3, "target": 9, "damage": 12})
	assert_eq(DebugLog.captured_in(&"combat"),
		PackedStringArray(["[t=7][combat] attacker=3 target=9 damage=12"]))


func test_disabled_category_is_not_logged() -> void:
	DebugLog.set_category(&"pathing", false)
	DebugLog.event(&"pathing", {"request": 1})
	assert_false(DebugLog.on(&"pathing"))
	assert_eq(DebugLog.captured().size(), 0)


func test_snapshot_is_json() -> void:
	DebugLog.tick = 3
	DebugLog.snapshot("after_wave", {"wood": 120})
	var lines := DebugLog.captured_in(&"state")
	assert_eq(lines.size(), 1)
	assert_string_starts_with(lines[0], "[t=3][state] snapshot=after_wave {")

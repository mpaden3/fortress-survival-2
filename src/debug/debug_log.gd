extends Node
## Structured event log for tests and debug builds (autoload: DebugLog).
##
## One machine-readable line per event, prefixed with the simulation tick:
##   [t=120][units] id=17 type=grunt pos=(12.00,0.00,4.50) hp=40
## Inactive (a no-op) in release builds. Callers on hot paths guard with `on()` so no
## formatting work happens when logging is off:
##   if DebugLog.on(&"units"): DebugLog.event(&"units", {"id": id, "pos": pos})
##
## Activation (debug builds only): running under GUT, the `--debug-log` user arg,
## env FS_DEBUG_LOG=1, or project setting `debug/fortress/log_enabled`.
## Env FS_LOG_ECHO=1/0 forces printing to stdout (default: on in game, off in tests).

const CATEGORIES: Array[StringName] = [
	&"state", &"units", &"pathing", &"collision", &"combat", &"build", &"waves", &"map",
]
const MAX_CAPTURED_LINES := 200_000

var active := false
var echo := true
## Set by the simulation each tick; stamped on every line.
var tick := 0

var _enabled: Dictionary[StringName, bool] = {}
var _captured := PackedStringArray()


func _init() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	var under_test := _is_test_run(args)
	active = OS.is_debug_build() and (
		under_test
		or "--debug-log" in args
		or OS.get_environment("FS_DEBUG_LOG") == "1"
		or ProjectSettings.get_setting("debug/fortress/log_enabled", false)
	)
	echo = not under_test
	var echo_env := OS.get_environment("FS_LOG_ECHO")
	if echo_env != "":
		echo = echo_env == "1"
	for category in CATEGORIES:
		_enabled[category] = true


func on(category: StringName) -> bool:
	return active and _enabled.get(category, false)


func set_category(category: StringName, enabled: bool) -> void:
	_enabled[category] = enabled


func event(category: StringName, fields: Dictionary) -> void:
	if not on(category):
		return
	_emit(format_line(tick, category, fields))


func message(category: StringName, text: String) -> void:
	if not on(category):
		return
	_emit("[t=%d][%s] %s" % [tick, category, text])


## Full state dump (entities, economy, waves...) under the `state` category.
func snapshot(label: String, state: Dictionary) -> void:
	if not on(&"state"):
		return
	_emit("[t=%d][state] snapshot=%s %s" % [tick, label, JSON.stringify(state, "", true)])


func captured() -> PackedStringArray:
	return _captured


## Captured lines of one category, e.g. for asserting on `combat` events in a test.
func captured_in(category: StringName) -> PackedStringArray:
	var tag := "][%s] " % category
	var out := PackedStringArray()
	for line in _captured:
		if tag in line:
			out.append(line)
	return out


func clear_captured() -> void:
	_captured.clear()


## Prints everything captured so far; call from a test when it fails.
func dump_captured(header := "debug log") -> void:
	print("---- %s (%d lines) ----" % [header, _captured.size()])
	for line in _captured:
		print(line)


static func format_line(at_tick: int, category: StringName, fields: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in fields:
		parts.append("%s=%s" % [key, format_value(fields[key])])
	return "[t=%d][%s] %s" % [at_tick, category, " ".join(parts)]


static func format_value(value: Variant) -> String:
	match typeof(value):
		TYPE_FLOAT:
			return "%.2f" % value
		TYPE_VECTOR2:
			return "(%.2f,%.2f)" % [value.x, value.y]
		TYPE_VECTOR3:
			return "(%.2f,%.2f,%.2f)" % [value.x, value.y, value.z]
		TYPE_VECTOR2I:
			return "(%d,%d)" % [value.x, value.y]
		TYPE_VECTOR3I:
			return "(%d,%d,%d)" % [value.x, value.y, value.z]
		TYPE_STRING, TYPE_STRING_NAME:
			return value if not " " in value else '"%s"' % value
		_:
			return str(value)


func _emit(line: String) -> void:
	if _captured.size() < MAX_CAPTURED_LINES:
		_captured.append(line)
	if echo:
		print(line)


static func _is_test_run(args: PackedStringArray) -> bool:
	for arg in args:
		if arg.ends_with("gut_cmdln.gd"):
			return true
	return false

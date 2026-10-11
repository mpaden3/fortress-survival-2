class_name SimRng
extends RefCounted
## The only randomness game logic may use. Seeded, so a match replays identically.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf() -> float:
	return _rng.randf()


func pick(items: Array) -> Variant:
	return null if items.is_empty() else items[_rng.randi_range(0, items.size() - 1)]


func get_state() -> int:
	return _rng.state


func set_state(state: int) -> void:
	_rng.state = state

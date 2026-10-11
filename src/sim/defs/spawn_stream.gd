class_name SpawnStream
extends Resource
## A continuous trickle of one enemy type whose rate ramps linearly between two times.
## Groups spawn at a random spawn point and hunt a random living Survivor.

@export var enemy: StringName
@export var start_time := 0.0
@export var end_time := 1200.0
## Enemies per minute at `start_time` and at `end_time`.
@export var rate_start := 6.0
@export var rate_end := 60.0
## Enemies released together.
@export var group_size := 5


func rate_at(seconds: float) -> float:
	if seconds < start_time or seconds >= end_time:
		return 0.0
	return lerpf(rate_start, rate_end, (seconds - start_time) / maxf(end_time - start_time, 0.001))

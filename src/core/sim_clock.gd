class_name SimClock
extends RefCounted
## Turns variable frame time into a whole number of fixed simulation ticks.
## Tests skip this entirely and advance the simulation tick by tick.

## Upper bound per frame so a long hitch can't snowball into ever longer frames.
const MAX_TICKS_PER_FRAME := 8

var _accumulator := 0.0


## Returns how many ticks the simulation should run for this frame.
func consume(frame_delta: float) -> int:
	_accumulator += frame_delta
	var ticks := floori(_accumulator / SimConstants.TICK_DELTA)
	if ticks > MAX_TICKS_PER_FRAME:
		_accumulator = 0.0
		return MAX_TICKS_PER_FRAME
	_accumulator -= ticks * SimConstants.TICK_DELTA
	return ticks


## Fraction of a tick elapsed since the last one, for render interpolation.
func alpha() -> float:
	return _accumulator / SimConstants.TICK_DELTA

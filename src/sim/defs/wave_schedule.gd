class_name WaveSchedule
extends Resource
## Everything that attacks during a match, and how long the match lasts. File:
## data/defs/waves/<id>.tres.

## Seconds the Survivors must last to win.
@export var duration := 1200.0
## Seconds before the first enemies, to start building.
@export var grace_period := 20.0
@export var streams: Array[SpawnStream] = []
@export var events: Array[SpawnEvent] = []

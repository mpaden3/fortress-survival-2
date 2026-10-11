extends SceneTree
## Headless full-match runner for balancing and performance checks.
##   godot --headless -s tools/sim_match.gd -- [--map=mvp_map] [--minutes=20] [--immortal] [--seed=1]
## Prints one line per simulated minute: enemies alive, survivor HP, tick cost.
## --immortal keeps the Survivor alive so the whole schedule runs (measures load, not balance).
##
## Game classes reference the DebugLog autoload, which doesn't exist yet when a -s script is
## compiled, so the runner is loaded on the first frame instead of referenced here.


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var runner: RefCounted = load("res://tools/match_runner.gd").new()
	runner.run(self, OS.get_cmdline_user_args())
	quit()

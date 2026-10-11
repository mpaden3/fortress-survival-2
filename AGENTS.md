# Agent Rules — Fortress Survival

Rules for any AI agent (and human) working on this repo. Read [ROADMAP.md](ROADMAP.md) for scope.

## Project
- Engine: **Godot 4.7** (`godot` on PATH), GDScript, Jolt physics, Forward+.
- 3D, RTS-like but minimal: building, pathfinding, unit movement. The focus is defensive
  buildings vs hordes.
- Art is placeholder (primitives) until the art direction is chosen. Don't invest in visuals
  unless the task asks for it.

## Core rule: everything is testable headlessly
Every gameplay mechanic must be verifiable with **no window, no GPU, no human**:

Tests use **GUT 9.7** (vendored in `addons/gut`), config in `.gutconfig.json`:

```sh
tools/run_tests.sh                              # full suite, headless; exit code 0 = all passed
tools/run_tests.sh -gselect=test_map_layout     # one test script
tools/run_tests.sh -gunit_test_name=entrances   # tests whose name contains the text
FS_LOG_ECHO=1 tools/run_tests.sh                # also print the debug log to stdout
```

- Tests live in `tests/unit/` (pure logic), `tests/integration/` (scenarios that run the
  simulation for N ticks) and `tests/benchmark/` (performance budgets). Files are named
  `test_*.gd` and extend `GutTest`.

- **Separate simulation from presentation.** Game logic (economy, building, placement,
  pathfinding, movement, combat, waves, win/lose) lives in plain scripts and nodes that run
  without rendering, input or audio. Visual nodes only *observe* the simulation and never own
  game state.
- **Deterministic fixed tick.** The simulation advances in fixed steps (`tick(delta)`) that tests
  can call directly or run N times. Seeded RNG only. Never use wall-clock time in game logic.
- **No input in logic.** Player actions go through command functions (`place_building`,
  `move_units`, `start_wave`, …). Input handlers and tests both call the same commands.
- **Co-op ready (host-authoritative).**
  - Commands are serializable (plain dictionaries or resources) and carry the issuing player's
    ID.
  - Entities have stable integer IDs.
  - Game state can be snapshotted and serialized.
  - Nothing in the simulation assumes a single local player.
- **Hordes don't use Nodes per enemy.** Enemies live in a central manager (data arrays) and are
  rendered with MultiMesh. Movement is continuous and steered by a grid flowfield, not
  cell-to-cell hopping.
- **Data-driven.** Stats for buildings, units, enemies and waves live in resources or data
  files. Tests can build small custom definitions.
- **Every feature ships with tests.** A mechanic is not done until a headless test runs a
  scenario and checks the outcome. Examples: an enemy reaches the wall and attacks it; a tower
  kills an enemy in range and ignores one out of range; placement is rejected on an occupied
  cell; the wave timer spawns the expected count; the core dying triggers a loss.
- **Bug fixes start with a failing test** that reproduces the bug.
- Run the full suite before you say a task is done, and report real results. Never claim a pass
  without running the suite.

## Running the game
```sh
godot --path .                                   # play the test map
godot --path . -- --map=mvp_map                  # full-size map
godot --path . -- --demo --screenshot=/tmp/s.png # place sample buildings, save a frame, quit
```
- `godot --headless -s tools/sim_match.gd -- [--map=mvp_map] [--minutes=20] [--immortal]`
  runs a whole match headless and prints per-minute load (enemies alive, tick ms). Use it for
  balance and performance checks.
- Use `--screenshot` to check visual changes yourself: it opens a window briefly, then read
  the PNG. Gameplay must still be verified by headless tests, not screenshots.
- `src/view/game.gd` (`Game`) wires the World to the views, camera, build input and HUD. Input
  code only submits commands, just like the tests do.

## Debug logging (tests + debug builds only)
A central logging autoload, `DebugLog` (`src/debug/debug_log.gd`), is the agent's "eyes" on the
game.

- **API:**
  - Write: `DebugLog.on(&"units")` (guard), `DebugLog.event(&"units", {...})`,
    `DebugLog.message(cat, text)`, `DebugLog.snapshot(label, state)`.
  - In tests: `DebugLog.captured()`, `captured_in(cat)`, `clear_captured()`,
    `dump_captured()`.
  - The simulation sets `DebugLog.tick` each tick.
- **Activation:** always on under GUT. Elsewhere it needs `--debug-log`, `FS_DEBUG_LOG=1` or the
  project setting `debug/fortress/log_enabled`. `FS_LOG_ECHO=1/0` controls printing to stdout
  (off in tests by default; lines are still captured).

- **Active only when** running tests, or in a debug build (`OS.is_debug_build()`) with logging
  enabled. In release/export builds it's a complete no-op with no cost on the hot path.
  Guard calls so string formatting doesn't run when logging is off.
- **Categories** (toggle each one separately):
  - `state`: tick, time, wave, resources, core HP, win/lose
  - `units`: id, type, position, HP, current order or target
  - `pathing`: path requests, results, blocked or stuck detection
  - `collision`: contacts, blocking, wall hits
  - `combat`: attacks, projectiles, damage, deaths
  - `build`: placement attempts (accepted or rejected, and why), construction progress
  - `waves`: spawns
- **Format:** one line per event, machine-readable (key=value or JSON), and prefixed with the
  tick, e.g. `[t=120][units] id=17 type=grunt pos=(12.0,0,4.5) hp=40 order=attack target=wall#3`.
- **Snapshots:** you can dump the full game state (all entities with positions and HP, the
  economy, wave info) on demand and at test failure.
- Tests can capture the log and assert on it as well as on state.
- Use it: when you implement or debug a mechanic, run it headlessly, read the log, and verify
  the behavior (positions change, collisions happen, units don't get stuck) instead of guessing.

## Project structure
```
addons/gut/      vendored test framework (don't edit)
data/maps/       map JSON files (format: data/maps/README.md)
docs/            generated previews and tables (Godot-ignored)
reference/       original WC3 map data, inspiration only (Godot-ignored)
scenes/          Godot scenes (presentation); main.tscn is the entry scene
src/core/        simulation basics: constants, fixed-tick clock, ids, commands, rng
src/debug/       DebugLog autoload
src/sim/         simulation (no rendering/input): map/, and later pathing/, buildings/,
                 units/, enemies/, combat/, economy/, waves/
src/view/        presentation that observes the simulation (renderers, camera) - later
src/ui/          HUD and menus - later
tests/           GUT tests (unit/, integration/, benchmark/)
tools/           dev scripts: run_tests.sh, maps/ (map builders, Python 3, stdlib only)
```
- Simulation code goes in `src/sim/` or `src/core/` and must never depend on `src/view/`,
  `src/ui/`, scenes, input or rendering.
- Shared value types and constants use `class_name`. Autoloads are kept to a minimum
  (currently only `DebugLog`).

### Simulation architecture
- `World` (`src/sim/world.gd`) owns everything: map, build grid, players, entities and
  systems. `world.step()` runs one tick: the queued commands in order, then each system's
  `update(world)`. Tests use `step()`, `run(n)` and `run_seconds(s)`.
- **Entities** (`src/sim/entities/`) are plain `RefCounted` data with a stable `id` and an
  `owner`. They are created through `world.add_entity()` and have `snapshot()`.
- **Systems** (`src/sim/systems/`) hold logic and their own indexes. They **never store a
  reference to the World**; it's passed into `update(world)` and the command handlers. This
  avoids RefCounted cycles, which leak.
- **Commands** (`src/core/commands.gd`) are dictionaries built by static helpers. A system
  registers a handler with `world.register_command()`. The handler returns `""` or a
  rejection reason, which ends up in `world.last_results` and the `build`/`state` log.
- **Survivors** (`src/sim/systems/survivor_system.gd`): each player's builder hero, an
  entity (`SurvivorState`) with an order queue (move/build/repair), A* movement
  (`AStarGrid2D` mirroring `grid.blocked`), Blink and Haste. A place command from a player with
  a living Survivor becomes a build order (it walks there first). Without one, placement is
  instant, which tests rely on: `SimFixtures.build_now()` builds instantly. When a Survivor
  dies, its player is defeated (`world.player_defeated`).
- **Pathing** (`src/sim/pathing/`): `PathingSystem` keeps one `FlowField` per hunt target
  (`set_target(key, cells)`). It rebuilds the field when buildings appear or disappear, or
  when the target changes cell. Building cells are passable at
  `max_hp * rules.path_cost_per_building_hp`, so blocked enemies break the cheapest wall.
- **Enemies** (`src/sim/enemies/enemy_manager.gd`) are flat packed arrays (SoA) indexed by
  a dense slot, with stable ids in `ids`. Positions are in **cell units**. The update loop is
  the hottest code in the game: keep it free of per-enemy function calls and allocations,
  read the grid through `grid.blocked` / `grid.occupants()`, and re-run the benchmark
  (`tests/benchmark/`) after any change to it.
- **Combat** (`src/sim/systems/combat_system.gd`): armed buildings (`BuildingDef`
  attack fields) pick the nearest enemy via `EnemyManager.nearest_in_range()`, which uses the
  spatial buckets from that tick's enemy update. They fire homing projectiles (flat arrays)
  that apply damage, splash and slow. Combat runs inside `enemies.begin_batch()` /
  `end_batch()`, so kills are removed at the end and enemy slot indices stay valid.
- **Upgrades** are in place: `upgrade_building` sets `upgrading_to`. On completion `def` is
  swapped, HP keeps its damage, and `world.entity_changed` fires (pathing and views refresh).
- **Match** (`src/sim/match/match_system.gd`): `world.match_system.start(world, schedule)`
  runs a `WaveSchedule` (`data/defs/waves/`): a grace period, then continuous `SpawnStream`s
  whose rate ramps linearly, plus timed `SpawnEvent`s (bosses, with announcements). It's won
  when the timer runs out with a Survivor alive, and lost when all are dead
  (`world.match_ended`). Tests that don't call `start()` have no waves.
- **Events** (`src/sim/sim_events.gd`): `world.events` holds what happened during the last
  tick (shots, impacts, kills, destroyed buildings) as flat arrays, cleared at the start of each
  step. `world.stepped` fires after each tick. They exist for presentation only; game logic
  never reads them.
- **VFX** (`src/view/fx_views.gd`, scenes in `scenes/vfx/`, shaders in `scenes/vfx/shaders/`):
  `FxViews` plays pooled one-shot `VfxBurst` scenes for events and puts a `VfxLoop` fire on
  buildings below 60% HP. Effects are `@tool`, so they loop in the editor while you tune them.
  `scenes/vfx/vfx_gallery.tscn` shows them all; run it with `-- --screenshot=/tmp/v.png
  --at=0.1,0.5` to capture frames at those seconds after a replay.
- **Economy** (`src/sim/systems/economy_system.gd`): passive income per living player plus
  `BuildingDef.income_per_minute`, accumulated exactly per tick.
- **Definitions** (`src/sim/defs/`, data in `data/defs/`) are `Resource` classes loaded by
  `DefRegistry.load_default()`. Tests build small registries in code with
  `tests/helpers/sim_fixtures.gd`.

## Code conventions
- Follow the surrounding code; static typing in GDScript (`var hp: int`, typed function
  signatures).
- `snake_case` files, functions and variables; `PascalCase` `class_name`s and nodes.
- Small focused scripts. Prefer composition (components or child nodes) over deep inheritance.
- No magic numbers in logic. Put them in the definition resources.
- Keep comments sparse and explain *why*.
- Performance matters (hordes): avoid per-frame allocations in hot loops, and avoid a
  physics body per enemy if it doesn't scale. Measure before you optimize.

## Reference material
- `reference/fortress-survival-6.76/` holds the original WC3 map's extracted data: units, buildings,
  abilities, auras, buffs, research and the map layout, plus the learnings (`README.md`).
- Use it for **inspiration only**. Don't copy names, numbers or content one-to-one. Our design
  is in ROADMAP.md.
- `reference/` has a `.gdignore`, so Godot doesn't import it. Never load it from game code.
- **One deliberate exception:** `data/maps/mvp_map.json` replicates the original map's layout
  (terrain and the 39 fixed plots), converted by `tools/maps/convert_original.py`. Plot names
  are placeholders until our own lore exists.

## Workflow
- Small, focused commits **directly on `master`**. No PRs or CI yet; tests run locally.
  Remote is `origin` (GitHub, SSH).
- Commit or push only when the user asks.
- Update ROADMAP.md checkboxes when a milestone item is completed and tested.
- Don't edit `.godot/` (generated). Commit `.import` files, `project.godot` and `.uid` files.

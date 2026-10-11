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

Tests use **GUT** (vendored in `addons/gut`). Exact command is documented here once the runner exists.

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

## Debug logging (tests + debug builds only)
A central logging autoload is the agent's "eyes" on the game.

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

## Workflow
- Small, focused commits **directly on `master`**. No PRs or CI yet; tests run locally.
  Remote is `origin` (GitHub, SSH).
- Commit or push only when the user asks.
- Update ROADMAP.md checkboxes when a milestone item is completed and tested.
- Don't edit `.godot/` (generated). Commit `.import` files, `project.godot` and `.uid` files.

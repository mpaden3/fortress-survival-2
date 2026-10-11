# Fortress Survival — Roadmap

A modern 3D take on the Warcraft III custom map **Fortress Survival**: build a fortress,
wall it in, stack defenses, and survive a timed horde. Fantasy medieval castle setting.
Placeholder art first; ship a playable MVP, then grow building/unit variety, art, audio and VFX.

## Reference: the original WC3 mod

What we know about the original (sources at the bottom; much of it is old/unverified):

- **Creator:** Maddawg101 (Clan Fortress Survival Elite). Later versions (Alpha 6.x, 7.00)
  were made by the "Fortress Survival Team". A Reforged remake, *Fortress Survival Classic*,
  is based on v4.3.
- **Genre:** a mix of survival, tower defense and base building. You build your own base,
  and monsters attack it instead of walking a fixed lane.
- **Goal:** survive a **45-minute** timed horde. You get **one life**: if your base is
  destroyed, you're out. It's co-op multiplayer and solo survival is hard. Some games ended
  "last player standing".
- **Difficulty:** Beginner / Easy / Normal / Mad / Impossible. Difficulty mainly scales
  monster HP.
- **Resources:** gold and lumber (from lumber mills that upgrade to L4), plus food (supply cap).
  Teammates can send each other lumber.
- **Base:** a small base in a corner of the map, which monsters enter from limited sides.
  Players build walls and barricades (some open with roughly 100 cheap barricades to buy
  time) and life walls at the corners against ranged attackers.
- **Defenses** (the original was sci-fi themed):
  - damage towers (gravity accelerator, sentry post)
  - slow and debuff towers (ice glacier, which slows attack speed)
  - healing towers (life tower)
  - aura statues (armor, damage) whose aura range grows with upgrades
  - a bunker
- **Units:** builders and technicians (they repair, and have a blink upgrade to reach the top
  of walls), repairers, marines, medics. Units are trained from unlocked buildings.
- **Upgrades:** an upgrade center unlocks research such as blink, advanced repair, more food,
  marine training and a gold-wall shortcut. Tower range grows with upgrades, and range is a key
  stat.
- **Enemies:** melee and ranged monsters, plus named threats that escalate over time:
  - Shraakka: a strong early/mid enemy
  - Scraash: a large unit that hits a random base
  - Vices: deal chaos damage and spawn on a timer
  - the **Trojan**: the final boss, which breaks any wall
  - A final explosion ends the match.
- **Lessons from its history:**
  - Monsters got stuck at spawns and mid-map, so we need robust pathfinding.
  - The game lagged late in a match, so performance matters with hordes.
  - Some balance swings felt unfair, so we want data-driven tuning.

## Our pillars

1. **Defense + hordes.** Walls, towers and auras against large waves. RTS mechanics
   (building, pathfinding, unit control) stay minimal and serve the defense.
2. **Variety.** Many buildings and units with distinct roles and synergies. This is the main
   way we beat the original.
3. **Feel.** Art style, sound and VFX are first-class. Placeholders until the style is chosen.
4. **Testable.** Every mechanic is verifiable headlessly (see [AGENTS.md](AGENTS.md)).

## Design decisions (updated 2026-10-11)

### Core loop
- **You are the Survivor**, the builder hero. The Survivor can't really fight. Its abilities
  are:
  - **Repair**
  - **Blink**: a short teleport *over* walls to a free ground spot. Survivors can't stand on
    walls (no wall-top height layer).
  - **Haste**: a speed burst to escape

  **One life: if the Survivor dies, you lose.** In co-op, a dead player is out and can only
  spectate while the team keeps going. **Only Survivors still alive when the timer ends win.**
- **Hordes hunt Survivors.**
  - Each spawned enemy group picks a **random living Survivor** as its target. This spreads
    pressure randomly in co-op; in single player every group hunts you.
  - If a group can see its target but the path is blocked, it breaks buildings to clear the way.
  - If its target isn't in sight, it attacks the buildings and units it does see.
- **Waves:** a continuous, timed stream that ramps up in intensity over the match. Named
  mini-bosses and bosses arrive at set times. The MVP match lasts about **20 minutes** (set in
  data). Win by surviving the timer.
- **Build anywhere** that's free and walkable. Choosing and fortifying a plot is the first
  strategic decision. There's **no plot claiming** for now.
- **Walls block everyone, your own units included.** There are no gates. Units inside a walled
  base stay inside.
- **No unit cap** for now.

### Map
- **Handcrafted maps**; layouts may change later, but they stay handcrafted.
  - **Test map:** small, about 64×64 cells, with 4–6 plots and centre + 4 edge spawns. It's for
    development and headless tests.
  - **MVP map:** full size, comparable to the original's 160×160 cells.
- **Fixed plots, replicating the original's plot design.** Players fortify hand-placed plots
  (districts) that differ in:
  - size
  - entrances: count and width
  - walking distance from the spawns
  - terrain inside: water, trees, obstacles
  - trade-offs, such as big with several doors vs small with one door

  Walls close off the entrances. The original's numbers, from
  [plots.md](reference/fortress-survival-6.76/map/plots.md):
  - 39 plots of 51–457 buildable cells
  - mostly 1 entrance, 2–4 cells wide
  - nearest spawn 15–85 cells away

  Our full-size map follows the same profile. The test map uses a few plots with contrasting
  profiles.
- **Spawns follow the original:** one in the **centre**, which is also where players start,
  plus four at the **edges** (N/E/S/W) at the ends of the main routes. The opening is a scramble
  out of the middle to claim a plot.
- See [reference/fortress-survival-6.76/map](reference/fortress-survival-6.76/map) for the
  original layout.

### Economy
- **A single primary resource.** Its name and lore are undecided; **"wood"** is the placeholder
  name in code and UI. Keep the name data-driven so renaming it is trivial.
- **No gold and no kill bounty.** Income comes from **passive income + income buildings**
  (placeholder: mill, upgradable).
- You can **sell** buildings for a partial refund (around 50–75%, set in data).
- **Repair is free.** It costs time, not resources.
- **No sharing or sending resources** between co-op players yet.

### Building model (the original's model)
- **A few cheap root buildings, each with a deep in-place upgrade tree that can branch.**
  Example: Basic Tower → Arrow / Cannon / Frost lines, each with several levels.
- Every upgrade step costs wood, takes build time and changes stats and abilities. It should
  also change visuals once we have art.
- Fewer, more meaningful levels than the original (its wall chain had 20 steps), and smaller,
  readable numbers.

### MVP content
- **Root buildings and their trees:**

| Root building | Upgrades into |
|---|---|
| Wall | HP wall line |
| Basic Tower | Arrow line (single target), Cannon line (splash), Frost line (slow) |
| Mill | Income line |
| Barracks | Trains repairmen and fighters |

- **Units:**
  - Repairmen auto-repair nearby buildings.
  - Fighters can be commanded.
  - Trained units don't affect winning or losing.
- **Enemies:**
  - Melee grunt (swarm)
  - Brute/siege (slow, tanky, bonus damage against buildings)
  - Fast runner (low HP, chases the Survivor)
  - At least one mini-boss

### Controls
- **Full RTS control:** box select, move, attack-move, stop, hold.
- **Camera:** WC3-style RTS camera (angled, edge/WASD pan, zoom, rotate) plus a hotkey to
  lock it onto the Survivor.

### Platform
- PC, mouse and keyboard. Target: **Steam**. Builds for **Linux, Windows and macOS**.
- **English only.**
- **Performance target:** 60 FPS with about 2,000 enemies on mid-range hardware, verified by a
  headless benchmark test.
- **Engine:** stay on Godot 4.7.x. Upgrade only on purpose.

### Tech
- **Engine:** Godot 4.7 (GDScript). Tests use **GUT**, run headless.
- **Simulation architecture (hybrid):**
  - **The simulation is plain data, not Nodes.** A `World` holds the entities (buildings,
    Survivors, units) as plain objects and advances in fixed ticks. Nodes in the scene only
    *draw* the world. This keeps it headless-testable and easy to snapshot for co-op.
  - **Enemies are simulated in a central manager** (data arrays) and drawn with MultiMesh,
    so the game can scale to thousands of enemies.
- **Buildings** snap to a **strict grid** with footprints (1x1, 2x2, 3x3), like WC3.
- **Pathfinding:**
  - A **grid flowfield** toward each living Survivor; there are only a few, so we keep one
    field per Survivor. Each cell's cost includes the HP of any wall on it, so enemies choose
    to break the cheapest wall when they're fully blocked.
  - The grid is only for *pathing data*. **Movement is continuous and free:** units sample the
    flowfield direction at their exact position (interpolated) and steer with
    separation/avoidance. They don't hop from cell center to cell center. This is not a tower
    defense game.
- **Fog of war comes later, so plan for it now.** Keep a per-player visibility query in the
  simulation (for now everything is visible). Renderers and UI ask it instead of assuming full
  vision. AI "sight" is separate and already in the MVP.
- **Co-op ready from day one: host-authoritative.**
  - The host runs the simulation. Clients send commands and receive state snapshots.
  - Single player is the same thing with the host running locally.
  - So all game actions are serializable commands, entities have stable IDs, and state can be
    snapshotted.

## Milestones

### M0 — Foundation
- [x] Git repo, Godot 4.7 project
- [x] Roadmap, agent rules (AGENTS.md / CLAUDE.md)
- [x] Project folder structure and conventions
- [x] Headless test runner (`tools/run_tests.sh`, GUT 9.7), first passing tests
- [x] Debug/test-only logging autoload (`DebugLog`); entity/collision events come with those systems
- [x] Deterministic fixed-tick simulation loop, decoupled from rendering (`World`, `SimClock`, `SimRng`)
- [x] Data-driven definitions as resources: buildings + game rules (`data/defs/`); units, enemies and waves follow with their systems

### M1 — Playable MVP (single player on host-authoritative architecture)
- [x] Small handcrafted test map (64×64): 6 plots, centre start, centre + 4 edge spawns (data + tests)
- [x] Full-size MVP map data (142×145): original layout, 39 fixed plots (data + tests)
- [x] Map loading into the running game (placeholder terrain, plots, spawns; build grid)
- [x] Build input: hotkeys, ghost preview, click/drag placement, select, sell
- [x] Command layer: all player actions as serializable commands with stable entity IDs
- [x] RTS camera (pan, zoom, rotate)
- [x] Camera: centre on / follow the Survivor
- [x] Selection (click, box), move / attack-move / stop / hold
- [x] Survivor (builder hero): free movement, build orders, Repair (free), Blink (over walls), Haste; death = defeat
- [x] Spectate after defeat (commands rejected, free camera); co-op Survivors spawn spread around the start
- [x] Grid placement with footprints + validity checks; construction time; sell (partial refund)
- [x] Survivor walks to the site before construction starts (queued orders with Shift)
- [x] Upgrade-tree system: root buildings with branching in-place upgrades (data-driven)
- [x] Buildings: wall line; Basic Tower → arrow / cannon (splash) / frost (slow) lines (placeholder stats)
- [x] Resource "wood" (placeholder name): passive income + mill line
- [x] Barracks training (queue, paid on queue)
- [x] Barracks units: repairman (auto-repairs damaged buildings in sight), fighter (guards its spot with a leash)
- [x] Flowfield per hunt target (wall HP as cost) + continuous steering/separation; never inside terrain (tested)
- [x] Horde benchmark: 2000 enemies on the MVP map ≈ 7 ms/tick (budget 8), field build ≈ 13 ms, sliced into ≤ 2.5 ms per tick on rebuilds
- [x] Render interpolation between ticks for enemies, projectiles and Survivors (30 Hz sim, 60+ FPS render)
- [x] Enemies break the building blocking their path (cheapest wall), buildings take damage and get destroyed
- [x] Enemy groups hunt a random living Survivor, chase it when close, attack it; retarget when it dies
- [x] Enemies attack the buildings they see (walking distance, outer layer only) while their Survivor is out of sight (`EnemyDef.sight_range`)
- [x] Enemies attack player units they see (trained units, other Survivors in co-op)
- [x] Enemies: grunt, brute/siege, runner, mini-boss (Warlord), final boss (Behemoth); continuous timed spawner with ramp + boss timings (`data/defs/waves/default.tres`)
- [x] Combat: targeting, homing projectiles, splash, slow, death (benchmark: 32 towers + 2000 enemies ≈ 5 ms/tick)
- [x] Armor / damage types: normal / pierce / siege / magic vs light / medium / heavy / boss (`GameRules.damage_multipliers`)
- [x] Win = survive 20 min timer; lose = your Survivor dies (victory/defeat banners)
- [x] Minimal HUD (text): wood + income, timer, selection info, build/upgrade/sell keys, ability cooldowns, announcements
- [x] Placeholder art (primitives)
- [x] Sim events for presentation (shots, impacts, kills, destroyed buildings) + placeholder VFX: muzzle flash, hit spark, explosion, frost burst, enemy death, building fire; glow
- [x] Basic SFX on the same events (synthesized placeholders, capped per tick; M mutes)

- [x] Save / restore the whole world (identical continuation; quick save/load); co-op view snapshots
- [x] Co-op spike: host-authoritative over ENet (join, own player + Survivor, commands, snapshots); tested headless on localhost
- [ ] Co-op: Steam networking, lobby, reconnect, client-side prediction for own orders, snapshot deltas
- [x] Fog-of-war hook: per-player visibility query used by all views (fog off by default)
- [x] Enemies are blocked by Survivors and units; smooth spreading of packed spawns
- [x] Routes hug corners (corner candidates + shortest combination)
- [x] Main menu (map, single / host / join, waves), in-game menu (pause, save, load, restart), end screen

### M2 — Depth
- [ ] Research building + research tree; more tower branches (crit/anti-boss, long-range, bash, anti-air)
- [ ] Aura statues (armor, damage, attack speed)
- [ ] Support buildings: healing tower, barracks/trainable defenders, bunker
- [ ] Regenerating wall line; repair buildings; Survivor ability upgrades
- [ ] Possible second (premium) resource, supply cap — TBD with resource lore
- [ ] Enemy variety: ranged, armored, flying, wall-breaker; mini-bosses on timer
- [ ] Final boss (our "Trojan") + finale event
- [ ] Difficulty levels (Easy → Nightmare) and boss multiplier (1×–4×); endless mode; side events

### M3 — Identity & polish
- [ ] Choose art direction; replace placeholders
- [ ] Audio: SFX set, music, adaptive intensity
- [ ] VFX: final art for hits/deaths (placeholders in M1); construction, auras, boss
- [ ] Performance: 1000+ enemies on screen (MultiMesh / batching, sim LOD)
- [ ] Main menu, settings, pause, game-over/victory screens

### M4 — Beyond
- [ ] Co-op multiplayer, host-authoritative (2–4 players, resource sharing); can be pulled
  earlier once MVP is stable
- [ ] Multiple maps, multiple builder "races" / factions
- [ ] Meta progression, achievements, Steam

## Backlog (not scheduled)
- Fog of war (architecture hook in M1, feature later)
- Day/night cycle (vision, enemy behaviour, day-only abilities like the original's Solar
  Batteries)
- Gates (let your own units through walls)
- Wall-top standing (a height layer for Survivors and units on walls)
- Plot claiming with pre-placed defenders (like the original's `-claim` districts)
- Unit cap / supply
- Resource sharing and sending in co-op
- Repair costing resources (if balance needs it)
- CI: GitHub Actions running the headless tests on every push, then export builds
- PR-based workflow (for now we commit directly to `master`)
- Localization

## Open questions
- Art style direction (stylized low-poly? painterly? realistic?)
- Final match length (MVP ~20 min; original was 45)
- Primary resource name & lore (placeholder "wood")

## Sources
- [Fortress Survival — Hive Workshop thread](https://www.hiveworkshop.com/threads/fortress-survival.50919/)
- [Complete Guide to winning Fortress Survival (2009 blog)](http://fortresssurvivalguide.blogspot.com/)
- [Fortress Survival Classic (Reforged)](https://maps.w3reforged.com/maps/categories/hero-defense-and-survival/Fortress%20Survival%20Classic)
- [Fortress Survival Alpha 7.00 BETA 41](https://www.wc3maps.com/map/184850)
- [Fortress Survival Advanced Guide (fortress-survival.com)](https://fortress-survival.com/topic/182104-an-advanced-guide/)
- [Walkthrough video](https://www.youtube.com/watch?v=kJO6KN0DoMM)

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

## Design decisions (2026-10-10)

### Core loop
- **You are the builder hero.** The builder can't really fight. Its abilities are **Blink**
  (a short teleport over or onto walls) and **Haste** (a speed burst to escape).
  **One life: if the builder dies, you lose.** In co-op, a dead player is out and the team
  keeps going.
- **Hordes hunt the builder.** Enemies always head for the builder. If they can see the
  builder but the path is blocked, they break buildings to clear it. If the builder isn't in
  their sight radius, they attack buildings and units they do see.
- **Waves:** a continuous, timed stream that ramps up in intensity over the match, with bosses
  at set times. The MVP match lasts about **20 minutes** (set in data). Win by surviving the
  timer.
- **Build anywhere** on the map that's free. Choosing and fortifying a spot is part of the
  strategy.

### Economy
- **Gold only** for the MVP. Income comes from **passive income + income buildings**
  (mine/market). There's **no kill bounty**.
- Buildings have **simple upgrade levels** (L1→L3) that cost gold and raise their stats.
- You can **sell** buildings for a partial refund (around 50–75%, set in data).

### MVP content
- **Buildings:**
  - Wall (no gate)
  - Arrow tower (single target)
  - Cannon tower (splash)
  - Frost tower (slow)
  - Gold mine/market (income)
  - Barracks, which trains repairmen and fighters
- **Units:** repairmen auto-repair nearby buildings. Fighters can be commanded. Trained units
  don't affect win/lose.
- **Enemies:**
  - Melee grunt (swarm)
  - Brute/siege (slow, tanky, bonus damage against buildings)
  - Fast runner (low HP, chases the builder)

### Controls
- **Full RTS control:** box select, move, attack-move, stop, hold.
- **Camera:** WC3-style RTS camera (angled, edge/WASD pan, zoom, rotate) plus a hotkey to
  lock it onto the builder.

### Map
- **Flat map + obstacles** (trees, rocks) for the MVP, with spawn points on the map edges.

### Tech
- **Engine:** Godot 4.7 (GDScript). Tests use **GUT**, run headless.
- **Simulation architecture (hybrid):**
  - Buildings, the builder and player units are Nodes.
  - **Enemies are simulated in a central manager** (data arrays) and drawn with MultiMesh,
    so the game can scale to thousands of enemies.
- **Buildings** snap to a **strict grid** with footprints (1x1, 2x2, 3x3), like WC3.
- **Pathfinding:**
  - A **grid flowfield** toward the builder. Each cell's cost includes the HP of any wall on
    it, so enemies choose to break the cheapest wall when they're fully blocked.
  - The grid is only for *pathing data*. **Movement is continuous and free:** units sample the
    flowfield direction at their exact position (interpolated) and steer with
    separation/avoidance. They don't hop from cell center to cell center. This is not a tower
    defense game.
- **Co-op ready from day one: host-authoritative.**
  - The host runs the simulation. Clients send commands and receive state snapshots.
  - Single player is the same thing with the host running locally.
  - So all game actions are serializable commands, entities have stable IDs, and state can be
    snapshotted.

## Milestones

### M0 — Foundation
- [x] Git repo, Godot 4.7 project
- [x] Roadmap, agent rules (AGENTS.md / CLAUDE.md)
- [ ] Project folder structure and conventions
- [ ] Headless test runner (`godot --headless`), first passing test
- [ ] Debug/test-only logging autoload (state, positions, collisions)
- [ ] Deterministic fixed-tick simulation loop, decoupled from rendering
- [ ] Data-driven definitions (buildings, units, enemies, waves) as resources

### M1 — Playable MVP (single player on host-authoritative architecture)
- [ ] Map: flat ground, obstacles (trees/rocks), edge spawn points, build grid
- [ ] Command layer: all player actions as serializable commands with stable entity IDs
- [ ] RTS camera (pan, zoom, rotate) + lock-on-builder hotkey
- [ ] Selection (click, box), move / attack-move / stop / hold
- [ ] Builder hero: free movement, build orders, Blink, Haste; death = defeat
- [ ] Grid placement with footprints + validity checks; construction time; sell (partial refund)
- [ ] Gold: passive income + gold mine/market
- [ ] Buildings: wall, arrow tower, cannon (splash), frost (slow), gold mine, barracks
- [ ] Building upgrades L1→L3
- [ ] Barracks units: repairman (auto-repair), fighter
- [ ] Flowfield to builder (wall HP as cost) + continuous steering/separation; no stuck units
- [ ] Enemy AI: chase builder; clear blocking buildings; attack visible buildings/units when builder not in sight
- [ ] Enemies: grunt, brute/siege, runner; continuous timed spawner with ramp + boss timings
- [ ] Combat: targeting, projectiles, splash, slow, damage/armor, death
- [ ] Win = survive ~20 min timer; lose = builder dies
- [ ] Minimal HUD: gold, timer, selection info, build/upgrade/sell menu, ability buttons
- [ ] Placeholder art (primitives), basic SFX hooks

### M2 — Depth
- [ ] Upgrade center + research tree; per-building upgrade levels (range/damage grow)
- [ ] Aura statues (armor, damage, attack speed)
- [ ] Support buildings: healing tower, barracks/trainable defenders, bunker
- [ ] Builder abilities (blink onto walls, advanced repair)
- [ ] Lumber (mills) and food/supply cap
- [ ] Enemy variety: ranged, armored, flying, wall-breaker; mini-bosses on timer
- [ ] Final boss (our "Trojan") + finale event
- [ ] Difficulty levels (Beginner → Impossible)

### M3 — Identity & polish
- [ ] Choose art direction; replace placeholders
- [ ] Audio: SFX set, music, adaptive intensity
- [ ] VFX: hits, deaths, construction, auras, boss
- [ ] Performance: 1000+ enemies on screen (MultiMesh / batching, sim LOD)
- [ ] Main menu, settings, pause, game-over/victory screens

### M4 — Beyond
- [ ] Co-op multiplayer, host-authoritative (2–4 players, resource sharing); can be pulled
      earlier once MVP is stable
- [ ] Multiple maps, multiple builder "races" / factions
- [ ] Meta progression, achievements, Steam

## Open questions
- Art style direction (stylized low-poly? painterly? realistic?)
- Final match length (MVP ~20 min; original was 45)
- Co-op: shared or separate gold; can enemies target any builder (nearest)?

## Sources
- [Fortress Survival — Hive Workshop thread](https://www.hiveworkshop.com/threads/fortress-survival.50919/)
- [Complete Guide to winning Fortress Survival (2009 blog)](http://fortresssurvivalguide.blogspot.com/)
- [Fortress Survival Classic (Reforged)](https://maps.w3reforged.com/maps/categories/hero-defense-and-survival/Fortress%20Survival%20Classic)
- [Fortress Survival Alpha 7.00 BETA 41](https://www.wc3maps.com/map/184850)
- [Fortress Survival Advanced Guide (fortress-survival.com)](https://fortress-survival.com/topic/182104-an-advanced-guide/)
- [Walkthrough video](https://www.youtube.com/watch?v=kJO6KN0DoMM)

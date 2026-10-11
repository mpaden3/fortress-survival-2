# Fortress Survival Alpha 6.76 — units & buildings

Extracted from `Fortress Survival Alpha 6.76P.w3x` (by Maddawg101 & Nevo, WC3 1.27a). Values = map overrides merged with WC3 TFT custom-game defaults. Reference only — do not copy content.

**Reading the tables**
- Costs are gold / lumber. For upgrades (↳) the listed cost is what the upgrade step costs (WC3 charges the target's cost).
- Damage = min–max per hit. Cooldown in seconds. Range / speed in WC3 units (1 build cell = 128, a footman is ~270 speed).
- Armor = value + armor type. Attack types: normal/pierce/siege/magic/chaos/spells/hero.
- HP/damage of enemies is the **base**; difficulty scales it (mainly HP) at runtime via triggers.

## Builder

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Survivor | `h001` | 350 | 0 medium | 25001–25002 | 2 | 90 | normal | 300 | 75 / 0 | 0 | SpellBook, Repair (Human) | Surviving? |

The ~280 other builder variants are identical cosmetic skins (named after community members/VIPs).

## Walls

### Barricade line (cheap HP walls)

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Barricade | `h003` | 75 | 5 fort | – | – | – | – | 0 / 0 | 1 | Stats Checker, Solar Batteries, Lunar Mist | Level 1 Defense / Health: 75 |
| ↳ Weak Barricade | `h004` | 150 | 5 fort | – | – | – | – | 0 / 0 | 4 | Stats Checker, Solar Batteries, Lunar Mist | Level 2 Defense / Health: 150 |
| ↳ Inferior Barricade | `h005` | 300 | 5 fort | – | – | – | – | 0 / 0 | 7 | Stats Checker, Solar Batteries, Lunar Mist | Level 3 Defense / Health: 300 |
| ↳ Superior Barricade | `h006` | 500 | 5 fort | – | – | – | – | 0 / 0 | 14 | Stats Checker, Solar Batteries, Lunar Mist | Level 4 Defense / Health: 500 |
| ↳ Reinforced Barricade | `h007` | 800 | 5 fort | – | – | – | – | 0 / 0 | 16 | Stats Checker, Solar Batteries, Lunar Mist | Level 5 Defense / Health: 800 |
| ↳ Copper Barricade | `h00C` | 1200 | 5 fort | – | – | – | – | 0 / 0 | 20 | Stats Checker, Solar Batteries, Lunar Mist | Level 6 Defense / Health: 1200 |
| ↳ Iron Barricade | `h00E` | 2000 | 5 fort | – | – | – | – | 0 / 0 | 24 | Stats Checker, Solar Batteries, Lunar Mist | Level 7 Defense / Health: 2000 |
| ↳ Bronze Barricade | `h00R` | 4000 | 5 fort | – | – | – | – | 0 / 0 | 28 | Stats Checker, Solar Batteries, Lunar Mist, Spiked Barricades | Level 8 Defense / Health: 4000 |
| ↳ Silver Barricade | `h00V` | 8000 | 5 fort | – | – | – | – | 0 / 0 | 36 | Stats Checker, Solar Batteries, Lunar Mist, Spiked Barricades | Level 9 Defense / Health: 8000 |
| ↳ Gold Barricade | `h00W` | 16000 | 5 fort | – | – | – | – | 0 / 5 | 36 | Stats Checker, Solar Batteries, Lunar Mist, Spiked Barricades | Level 10 Defense / Health: 16,000 |
| ↳ Obsidian Barricade | `h06Y` | 28000 | 5 fort | – | – | – | – | 0 / 10 | 35 | Stats Checker, Solar Batteries, Lunar Mist, Spiked Barricades | Level 11 Defense / Health: 28,000 |
| ↳ Onyx Barricade | `h016` | 42000 | 5 fort | – | – | – | – | 0 / 25 | 45 | Stats Checker, Solar Batteries, Lunar Mist, Spiked Barricades | Level 12 Defense / Health: 42,000 |
| ↳ Granite Barricade | `h04V` | 60000 | 5 fort | – | – | – | – | 0 / 50 | 65 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 13 Defense / Health: 60,000 / +1 Item Slot |
| ↳ Dark Barricade | `h01A` | 75000 | 5 fort | – | – | – | – | 0 / 100 | 70 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 14 Defense / Health: 75,000 |
| ↳ Light Barricade | `h03F` | 90000 | 5 fort | – | – | – | – | 0 / 200 | 75 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 15 Defense / Health: 90,000 |
| ↳ Diamond Barricade | `h04Y` | 105000 | 5 fort | – | – | – | – | 1 / 400 | 80 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 16 Defense / Health: 105,000 |
| ↳ Mithril Barricade | `h05K` | 120000 | 5 fort | – | – | – | – | 2 / 500 | 90 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 17 Defense / Health: 120,000 |
| ↳ God's Seal Barricade | `h06X` | 135000 | 5 fort | – | – | – | – | 4 / 600 | 90 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 18 Defense / Health: 135,000 |
| ↳ Cursed Barricade | `h06L` | 160000 | 5 fort | – | – | – | – | 10 / 1000 | 100 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Level 19 Defense / Health: 160,000 |
| ↳ Devil's Barricade | `h0C1` | 200000 | 10 fort | – | – | – | – | 20 / 2000 | 110 | Electric Defense, Stats Checker, 1 Slot Inventory, Solar Batteries, Lunar Mist, Spiked Barricades | Ultimate Final Defense / Health: 190,000 |

### Energy Wall line ("life walls")

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Energy Wall | `h01Y` | 450 | 4 fort | – | – | – | – | 0 / 0 | 5 | Stats Checker, Solar Batteries, Lunar Mist | Level 1 Regenerating Defense / Health: 450 / Regeneration: 40 health per second |
| ↳ Essence Wall | `h01R` | 825 | 5 fort | – | – | – | – | 0 / 0 | 20 | Stats Checker, Solar Batteries, Lunar Mist | Level 2 Regenerating Defense / Health: 825 / Regeneration: 75 health per second |
| ↳ Growth Wall | `h01S` | 1750 | 6 fort | – | – | – | – | 0 / 0 | 30 | Lunar Mist, Stats Checker, Solar Batteries | Level 3 Regenerating Defense / Health: 1750 / Regeneration: 175 health per second |
| ↳ Spirit Wall | `h01T` | 3500 | 7 fort | – | – | – | – | 0 / 2 | 40 | Stats Checker, Solar Batteries, Lunar Mist | Level 4 Regenerating Defense / Health: 3500 / Regeneration: 325 health per second |
| ↳ Life Wall | `h01U` | 7500 | 8 fort | – | – | – | – | 0 / 3 | 50 | Stats Checker, Solar Batteries, Lunar Mist | Level 5 Regenerating Defense / Health: 7500 / Regeneration: 400 health per second |
| ↳ Vitality Wall | `h01Z` | 15000 | 9 fort | – | – | – | – | 0 / 10 | 50 | Stats Checker, Solar Batteries, Lunar Mist | Level 6 Regenerating Defense / Health: 15,000 / Regeneration: 550 health per second |
| ↳ Eternal Wall | `h01V` | 20000 | 10 fort | – | – | – | – | 0 / 30 | 55 | Stats Checker, Solar Batteries, Lunar Mist | Level 7 Regenerating Defense / Health: 20,000 / Regeneration: 775 health per second |
| ↳ Everlasting Wall | `h03X` | 25000 | 11 fort | – | – | – | – | 0 / 60 | 60 | Electric Defense, 1 Slot Inventory, Stats Checker, Lunar Mist, Solar Batteries | Level 8 Regenerating Defense / Health: 25,000 / Regeneration: 1050 health per second / +1 Item Slot |
| ↳ Magical Rune Wall | `h02A` | 35000 | 12 fort | – | – | – | – | 0 / 120 | 65 | Electric Defense, 1 Slot Inventory, Stats Checker, Lunar Mist, Solar Batteries | Level 9 Regenerating Defense / Health: 35,000 / Regeneration: 1450 health per second |
| ↳ Force Field Wall | `h04Z` | 45000 | 12 fort | – | – | – | – | 1 / 200 | 70 | Electric Defense, 1 Slot Inventory, Stats Checker, Lunar Mist, Solar Batteries | Level 10 Regenerating Defense / Health: 45,000 / Regeneration: 1900 health per second |
| ↳ Extortion Field Wall | `h05S` | 50000 | 13 fort | – | – | – | – | 2 / 400 | 75 | Electric Defense, 1 Slot Inventory, Stats Checker, Lunar Mist, Solar Batteries | Level 11 Regenerating Defense / Health: 50,000 / Regeneration: 2400 health per second |
| ↳ Gaia's Shield Wall | `h075` | 55000 | 14 fort | – | – | – | – | 3 / 600 | 80 | Electric Defense, 1 Slot Inventory, Stats Checker, Lunar Mist, Solar Batteries | Level 12 Regenerating Defense / Health: 55,000 / Regeneration: 3000 health per second |
| ↳ Natures Spirit | `h0C2` | 80000 | 20 fort | – | – | – | – | 10 / 2000 | 90 | Electric Defense, 1 Slot Inventory, Stats Checker, Lunar Mist, Solar Batteries | Level 13 Regenerating Defense / Health: 80,000 / Regeneration: 3000 health per second |

## Towers

Everything starts as **Basic Tower** and branches into 10 lines of 6 levels.

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Basic Tower | `h0ES` | 1000 | 5 large | – | – | – | – | 0 / 0 | 4 | Stats Checker, 1Regen | Level 1 Basic Offensive Building / Upgradable into various Towers including Anti-Air! |
| Diffusal Burner | `h067` | 2000 | 5 large | 72–84 | 0.7 | 550 | magic | 0 / 0 | 35 | 1Regen, Feedback(Arcane Tower), Stats Checker | Level 1 Mana Burn Tower |
| ↳ Mystic Burner | `h068` | 3000 | 5 large | 87–99 | 0.7 | 575 | magic | 0 / 5 | 35 | 1Regen, Feedback(Arcane Tower), Stats Checker | Level 2 Mana Burn Tower |
| ↳ Enigmatic Burner | `h069` | 4000 | 5 large | 112–124 | 0.7 | 600 | magic | 0 / 15 | 40 | 1Regen, Feedback(Arcane Tower), Stats Checker | Level 3 Magic Specialist Tower |
| ↳ Enchanted Burner | `h06A` | 5000 | 5 large | 137–149 | 0.7 | 625 | magic | 0 / 30 | 40 | 1Regen, Feedback(Arcane Tower), Stats Checker | Level 4 Magic Specialist Tower |
| ↳ Wicked Burner | `h06B` | 6000 | 5 large | 172–184 | 0.7 | 650 | magic | 0 / 60 | 45 | 1Regen, Feedback(Arcane Tower), Stats Checker | Level 5 Mana Burn Tower |
| ↳ Diabolic Burner | `h03P` | 7000 | 5 large | 181–185 | 0.3 | 675 | pierce | 1 / 50 | 50 | 1Regen, Feedback(Arcane Tower), Stats Checker | Level 6 Ultimate Mana Burn Tower |
| Arrow Tower | `h008` | 2000 | 5 large | 16–20 | 1.3 | 500 | pierce | 0 / 0 | 5 | Stats Checker, 1Regen | Level 1 Basic Offensive Tower |
| ↳ Spear Tower | `h02Q` | 3000 | 5 large | 83–95 | 0.95 | 500 | pierce | 0 / 15 | 25 | Stats Checker, 1Regen | Level 2 Basic Offensive Tower |
| ↳ Lance Tower | `h00M` | 4000 | 5 large | 93–105 | 0.95 | 500 | pierce | 0 / 30 | 25 | Stats Checker, 1Regen | Level 3 Basic Offensive Tower |
| ↳ Javelin Tower | `h02R` | 5000 | 5 large | 102–114 | 0.85 | 550 | pierce | 0 / 60 | 25 | Stats Checker, 1Regen | Level 4 Basic Offensive Tower |
| ↳ Harpoon Tower | `h01B` | 6000 | 5 large | 102–114 | 0.7 | 500 | pierce | 0 / 120 | 25 | Stats Checker, 1Regen | Level 5 Basic Offensive Tower |
| ↳ Arrowstorm Tower | `h05M` | 7000 | 5 large | 122–134 | 0.75 | 600 | pierce | 1 / 100 | 30 | 1Regen, Stats Checker, Multiple Shots | Level 6 Ultimate Offensive Tower |
| Rock Impaler | `h00N` | 2000 | 5 large | 198–202 | 2.1 | 625 | siege | 0 / 0 | 35 | Critical Strike (creep), 1Regen, Stats Checker, Bash (creep) | Level 1 Bashing Tower |
| ↳ Stone Impaler | `h00O` | 3000 | 5 large | 224–228 | 2 | 650 | siege | 0 / 5 | 35 | Critical Strike (creep), 1Regen, Stats Checker, Bash (creep) | Level 2 Bashing Tower |
| ↳ Boulder Impaler | `h00P` | 4000 | 5 large | 274–278 | 1.9 | 675 | siege | 0 / 15 | 40 | Critical Strike (creep), 1Regen, Stats Checker, Bash (creep) | Level 3 Bashing Tower |
| ↳ Gravel Impaler | `h01P` | 5000 | 5 large | 328–332 | 1.8 | 700 | siege | 0 / 30 | 45 | Critical Strike (creep), 1Regen, Stats Checker, Bash (creep) | Level 4 Bashing Tower |
| ↳ Mountain Impaler | `h02P` | 6000 | 5 large | 372–376 | 1.7 | 725 | siege | 0 / 60 | 50 | Critical Strike (creep), 1Regen, Stats Checker, Bash (creep) | Level 5 Bashing Tower |
| ↳ Earth Impaler | `h03O` | 7000 | 5 large | 427–431 | 1.6 | 800 | siege | 1 / 50 | 50 | Critical Strike (creep), 1Regen, Stats Checker, Bash (creep) | Level 5 Ultimate Bashing Tower |
| Tesla Coil | `h00A` | 2000 | 5 large | 19–23 | 0.35 | 425 | pierce | 0 / 0 | 20 | Stats Checker, 1Regen | Level 1 Shocking Tower |
| ↳ Fusion Coil | `h00F` | 3000 | 5 large | 34–38 | 0.35 | 450 | pierce | 0 / 2 | 25 | Stats Checker, 1Regen | Level 2 Shocking Tower |
| ↳ Voltage Coil | `h02S` | 4000 | 5 large | 59–63 | 0.35 | 475 | pierce | 0 / 5 | 30 | Stats Checker | Level 3 Shocking Tower |
| ↳ Shocking Coil | `h00H` | 5000 | 5 large | 90–94 | 0.35 | 500 | pierce | 0 / 15 | 35 | Stats Checker, 1Regen | Level 4 Shocking Tower |
| ↳ Thunder Coil | `h013` | 6000 | 5 large | 116–120 | 0.35 | 525 | pierce | 0 / 30 | 40 | Stats Checker, 1Regen | Level 5 Shocking Tower |
| ↳ Sky-Fury Coil | `h01H` | 7000 | 5 large | 149–153 | 0.35 | 550 | pierce | 1 / 50 | 45 | Stats Checker, 1Regen | Level 6 Ultimate Shocking Tower |
| Slow Freezer | `h00D` | 2000 | 5 large | 96–120 | 1.8 | 600 | magic / msplash 50 | 0 / 0 | 35 | 1Regen, Stats Checker, Frost Attack (1,2) | Level 1 Slowing Tower |
| ↳ Ice Freezer | `h012` | 3000 | 5 large | 158–182 | 1.7 | 650 | magic / msplash 50 | 0 / 5 | 45 | 1Regen, Stats Checker, Frost Attack (1,2) | Level 2 Slowing Tower |
| ↳ Chill Freezer | `h01F` | 4000 | 5 large | 174–198 | 1.6 | 700 | magic / msplash 50 | 0 / 15 | 55 | 1Regen, Stats Checker, Frost Attack (1,2) | Level 3 Slowing Tower |
| ↳ Glacial Freezer | `h01O` | 5000 | 5 large | 216–240 | 1.5 | 750 | magic / msplash 50 | 0 / 30 | 65 | 1Regen, Stats Checker, Frost Attack (1,2) | Level 4 Slowing Tower |
| ↳ Arctic Freezer | `h09A` | 6000 | 5 large | 256–280 | 1 | 750 | magic / msplash 50 | 0 / 60 | 75 | 1Regen, Stats Checker, Frost Attack (1,2) | Level 5 Slow Tower |
| ↳ Ice Age Freezer | `h03I` | 7000 | 5 large | 254–278 | 1.5 | 750 | magic / msplash 60 | 1 / 50 | 85 | 1Regen, Stats Checker, Frost Attack (1,2) | Level 6 Ultimate Slowing Tower |
| Bursting Flamer | `h00J` | 2000 | 5 large | 184–208 | 1.2 | 525 | chaos | 0 / 0 | 35 | Stats Checker, 1Regen | Level 1 High Damage Tower |
| ↳ Ember Flamer | `h011` | 3000 | 5 large | 229–253 | 1.1 | 550 | chaos | 0 / 5 | 35 | 1Regen, Stats Checker | Level 2 High Damage Tower |
| ↳ Lava Flamer | `h01E` | 4000 | 5 large | 268–292 | 1 | 575 | chaos | 0 / 15 | 40 | Stats Checker, 1Regen | Level 3 High Damage Tower |
| ↳ Volcano Flamer | `h01N` | 5000 | 5 large | 302–326 | 0.9 | 600 | chaos | 0 / 30 | 55 | Stats Checker, 1Regen | Level 4 High Damage Tower |
| ↳ Inferno Flamer | `h02X` | 6000 | 5 large | 339–363 | 0.8 | 625 | chaos | 0 / 60 | 55 | Stats Checker, 1Regen | Level 5 High Damage Tower |
| ↳ Hell Gate Flamer | `h03H` | 7000 | 5 large | 414–438 | 0.75 | 650 | chaos | 1 / 50 | 70 | Stats Checker, 1Regen | Level 6 Ultimate High Damage Tower |
| Peasant Launcher | `h07J` | 2000 | 5 large | 308–316 | 3.7 | 650 | siege / msplash | 0 / 0 | 25 | Critical Strike (creep), Stats Checker, 1Regen | Level 1 High Splash Tower / Deals massive splash damage to mobs. / Bosses receive 50% of that damage. |
| ↳ Peon Launcher | `h07K` | 3000 | 5 large | 398–406 | 3.6 | 650 | siege / msplash | 0 / 5 | 30 | Critical Strike (creep), Stats Checker, 1Regen | Level 2 High Splash Tower |
| ↳ Night Elf Launcher | `h07L` | 4000 | 5 large | 518–526 | 3.5 | 650 | siege / msplash | 0 / 15 | 35 | Critical Strike (creep), Stats Checker, 1Regen | Level 3 High Splash Tower |
| ↳ Sheep Launcher | `h07M` | 5000 | 5 large | 653–661 | 3.4 | 650 | siege / msplash | 0 / 30 | 40 | Critical Strike (creep), Stats Checker, 1Regen | Level 4 High Splash Tower |
| ↳ Nether Launcher | `h07N` | 6000 | 5 large | 818–826 | 3.3 | 700 | siege / msplash | 0 / 60 | 45 | Critical Strike (creep), Stats Checker, 1Regen | Level 5 High Splash Tower |
| ↳ Pheonix Launcher | `h07O` | 7000 | 5 large | 988–996 | 3.2 | 750 | siege / msplash | 1 / 100 | 50 | Critical Strike (creep), Stats Checker, 1Regen | Level 6 Ultimate High Splash Tower |
| Gravity Disruptor | `h00K` | 2000 | 5 large | 28–92 | 1.6 | 750 | normal | 0 / 0 | 35 | Stats Checker, 1Regen | Level 1 Long Range Homing Tower |
| ↳ Gravity Shifter | `h01D` | 3000 | 5 large | 31–121 | 1.5 | 800 | normal | 0 / 2 | 40 | Stats Checker, 1Regen | Level 2 Long Range Homing Tower |
| ↳ Gravity Spire | `h017` | 4000 | 5 large | 52–195 | 1.4 | 850 | normal | 0 / 5 | 45 | Stats Checker, 1Regen | Level 3 Long Range Homing Tower |
| ↳ Gravity Splicer | `h01G` | 5000 | 5 large | 65–353 | 1.3 | 900 | normal | 0 / 15 | 50 | Stats Checker, 1Regen | Level 4 Long Range Homing Tower |
| ↳ Gravity Accelerator | `h03N` | 6000 | 5 large | 78–561 | 1.2 | 950 | normal | 0 / 30 | 55 | Stats Checker, 1Regen | Level 5 Long Range Homing Tower |
| ↳ Gravity Fabricator | `h05Q` | 7000 | 5 large | 89–639 | 1.1 | 1000 | normal | 1 / 50 | 60 | Stats Checker, 1Regen | Level 6 Ultimate Range Homing Tower |
| Novice Assassin | `h02C` | 2000 | 5 large | 22–22 | 0.25 | 500 | hero | 0 / 0 | 35 | 1Regen, Slow Poison, Stats Checker, Tank Turret, Critical Strike (creep) | Level 1 Critical Strike Tower / 60% damage vs. normal enemies / 130% damage vs. Hero Armor (Bosses) |
| ↳ Accomplished Assassin | `h015` | 3000 | 5 large | 25–25 | 0.25 | 500 | hero | 0 / 15 | 40 | Stats Checker, Slow Poison, Tank Turret, Critical Strike (creep), 1Regen | Level 2 Critical Strike Tower |
| ↳ Adept Assassin | `h018` | 4000 | 5 large | 31–31 | 0.25 | 500 | hero | 0 / 30 | 45 | Stats Checker, Slow Poison, 1Regen, Critical Strike (creep) | Level 3 Critical Strike Tower |
| ↳ Skilled Assassin | `h019` | 5000 | 5 large | 37–37 | 0.25 | 500 | hero | 0 / 60 | 50 | 1Regen, Slow Poison, Stats Checker, Tank Turret, Critical Strike (creep) | Level 4 Critical Strike Tower |
| ↳ Master Assassin | `h02B` | 6000 | 5 large | 49–49 | 0.25 | 525 | hero | 0 / 120 | 55 | 1Regen, Slow Poison, Stats Checker, Tank Turret, Critical Strike (creep) | Level 5 Critical Strike Tower |
| ↳ Shadow Assassin | `h05N` | 7000 | 5 large | 76–76 | 0.25 | 575 | hero | 1 / 100 | 60 | 1Regen, Slow Poison, Stats Checker, Tank Turret, Critical Strike (creep) | Level 6 Ultimate Critical Strike Tower |
| AK-630 Minigun | `h030` | 4000 | 5 large | 62–66 | 1.75 | 600 | pierce | 0 / 0 | 15 | Stats Checker, 1Regen | Level 1 Anti Air Tower |
| ↳ AK-630M Minigun | `h02U` | 6000 | 5 large | 71–75 | 1.5 | 700 | pierce | 0 / 15 | 20 | Stats Checker, 1Regen | Level 2 Anti Air Tower |
| ↳ AK-630M1-2 Minigun | `h036` | 8000 | 5 large | 80–84 | 1.25 | 800 | pierce | 0 / 45 | 25 | Stats Checker, 1Regen | Level 3 Anti Air Tower |
| ↳ AK-640 Minigun | `h0E2` | 10000 | 5 large | 156–160 | 1 | 900 | pierce | 0 / 90 | 30 | Stats Checker, 1Regen | Level 4 Anti Air Tower |
| ↳ AK-640M Minigun | `h014` | 12000 | 5 large | 256–260 | 0.75 | 1000 | pierce | 1 / 50 | 35 | Stats Checker, 1Regen | Level 5 Anti Air Tower |
| ↳ AK-640M1-2 Minigun | `h05L` | 14000 | 5 large | 414–438 | 0.5 | 1100 | pierce | 2 / 100 | 40 | Stats Checker, 1Regen | Level 6 Ultimate Anti Air Tower |

## Aura statues

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Aura Statue | `h023` | 1000 | 5 fort | – | – | – | – | 0 / 0 | 35 | Stats Checker | Level 1 Aura Building / Automatically uses Repair Keys on weakened walls |
| Heroic Statue | `h02D` | 2000 | 5 fort | – | – | – | – | 0 / 0 | 50 | Stats Checker | Level 2 Offensive Aura Building / (+20% increased tower damage) |
| ↳ Legendary Statue | `h02G` | 4000 | 5 fort | – | – | – | – | 0 / 5 | 60 | Stats Checker | Level 3 Offensive Aura Building / (+30% increased tower damage) |
| ↳ Valiant Statue | `h055` | 8000 | 5 fort | – | – | – | – | 1 / 25 | 60 | Stats Checker | Level 4 Offensive Aura Building / (+40% increased tower damage) |
| ↳ Commanding Statue | `h099` | 16000 | 5 fort | – | – | – | – | 2 / 50 | 60 | Stats Checker | Level 5 Offensive Aura Building / (+50% increased tower damage) |
| Guardian Statue | `h02H` | 2000 | 5 fort | – | – | – | – | 0 / 0 | 50 | Stats Checker | Level 2 Defensive Aura Building / (+3 armor aura) |
| ↳ Champion Statue | `h040` | 4000 | 5 fort | – | – | – | – | 0 / 5 | 60 | Stats Checker | Level 3 Defensive Aura Building / (+6 armor aura) |
| ↳ Gallant Statue | `h02I` | 8000 | 5 fort | – | – | – | – | 1 / 25 | 60 | Stats Checker | Level 4 Defensive Aura Building / (+9 armor aura) |
| ↳ Lionheart Statue | `h07D` | 16000 | 5 fort | – | – | – | – | 2 / 50 | 60 | Stats Checker | Level 5 Defensive Aura Building / (+18 armor aura) |
| Sentry Statue | `h01J` | 1000 | 5 large | – | – | – | – | 0 / 0 | 20 | Deliver Item, Detect (Magic Sentinel), Stats Checker | Level 2 Vision Aura Building / (reveals nearby invisible units) |
| ↳ Sentry Recon Statue | `h027` | 4000 | 5 large | – | – | – | – | 0 / 10 | 50 | Deliver Item, Detect (Magic Sentinel), Call Reinforcements, Stats Checker | Level 3 Vision Aura Building / (reveals nearby invisible units) |
| ↳ Sentry Radar Statue | `h02Y` | 6000 | 5 large | – | – | – | – | 0 / 25 | 80 | Deliver Item, Detect (Magic Sentinel), Call Reinforcements, Stats Checker | Level 4 Vision Aura Building / (reveals nearby invisible units) |
| ↳ Sentry Radio Statue | `h03Z` | 8000 | 5 large | – | – | – | – | 0 / 50 | 80 | Deliver Item, Reveal(Arcane Tower), Detect (Magic Sentinel), Call Reinforcements, Stats Checker | Level 5 Vision Aura Building / (reveals nearby invisible units and includes reveal) |

## Economy

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Lumber Mill | `h00Q` | 1500 | 5 fort | – | – | – | – | 0 / 0 | 35 | Add Lumber | Level 1 Wood Income Building / Income: 0.025 Lumber per second |
| ↳ Lumber Mill Lvl 2 | `h00X` | 3000 | 5 fort | – | – | – | – | 0 / 5 | 55 | Add Lumber | Level 2 Wood Income Building / Income: 0.050 Lumber per second |
| ↳ Lumber Mill Lvl 3 | `h00Z` | 6000 | 5 fort | – | – | – | – | 0 / 10 | 85 | Add Lumber | Level 3 Wood Income Building / Income: 0.100 Lumber per second |
| ↳ Lumber Mill Lvl 4 | `h024` | 12000 | 5 fort | – | – | – | – | 0 / 40 | 110 | Add Lumber, Lumbering Tip | Level 4 Wood Income Building / Income: 0.250 Lumber per second |
| ↳ Gold Mine | `h057` | 9000 | 5 fort | – | – | – | – | 0 / 180 | 110 | Add Gold | Level 1 Gold Income Building / Income: 0.033 Gold per second / Maximum Limit: 1 per player |
| ↳ Gold Mine Lvl 2 | `h074` | 12000 | 5 fort | – | – | – | – | 0 / 260 | 110 | Add Gold | Level 2 Gold Income Building / Income: 0.066 Gold per second / Maximum Limit: 1 per player |

## Repair

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Repair Mechanic | `h00I` | 500 | 5 fort | – | – | – | – | 0 / 0 | 15 | Repair (Human) | Level 1 Repair Building 33% Efficiency |
| ↳ Skilled Mechanic | `h02J` | 1000 | 5 fort | – | – | – | – | 0 / 0 | 10 | Repair (Human) | Level 2 Repair Building 40% Efficiency |
| ↳ Master Mechanic | `h04X` | 1500 | 5 fort | – | – | – | – | 0 / 0 | 10 | Repair (Human) | Level 3 Repair Building 50% Efficiency |
| ↳ Mechanical Engineer | `h02O` | 2000 | 5 fort | – | – | – | – | 0 / 2 | 10 | Repair (Human) | Level 4 Repair Building 67% Efficiency |
| ↳ Electrical Engineer | `h02K` | 2500 | 5 fort | – | – | – | – | 0 / 10 | 10 | Repair (Human) | Level 5 Repair Building 80% Efficiency |
| ↳ Engineering Technician | `h03W` | 3500 | 5 fort | – | – | – | – | 0 / 20 | 10 | Repair (Human) | Level 6 Repair Building 87% Efficiency |
| ↳ Master Technician | `h05J` | 4500 | 5 fort | – | – | – | – | 1 / 30 | 10 | Repair (Human) | Level 7 Repair Building 100% Efficiency |
| ↳ Repair Technologist | `h07G` | 6000 | 5 fort | – | – | – | – | 2 / 40 | 10 | Repair (Human) | Level 8 Repair Building 110% Efficiency |
| Repair Factory | `h00L` | 500 | 5 fort | – | – | – | – | 0 / 0 | 20 | Repair Factory Tip, Repair (Human), Rally | Repair Factory Building 33% Efficiency / Trains Repair Bots to assist with repairing |
| Advanced Repair Factory | `h03Y` | 1500 | 5 fort | – | – | – | – | 0 / 0 | 20 | Repair Factory Tip, Repair (Human), Rally | Advanced Repair Factory Building 50% Efficiency / Trains Repair Bots to assist with repairing |

### Repair bots

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Repair Bot | `n008` | 1000 | 5 large | – | – | – | – | 270 | 0 / 2 | 2 | Warden - Blink, Repair (Human) | Robot that can help repair damaged defenses and towers with 40% Efficiency. |
| Advanced Repair Bot | `n01V` | 2000 | 5 large | – | – | – | – | 270 | 0 / 15 | 2 | Warden - Blink, Repair (Human) | Robot that can help repair damaged defenses and towers advancely fast with 50% Efficiency. |
| Extreme Repair Bot | `n01W` | 3000 | 5 large | – | – | – | – | 270 | 0 / 20 | 2 | Warden - Blink, Repair (Human) | Robot that can help repair damaged defenses and towers extremely fast with 60% Efficiency. |
| Supreme Repair Bot | `n00V` | 4000 | 5 large | – | – | – | – | 270 | 0 / 40 | 2 | Warden - Blink, Repair (Human) | Robot that can help repair damaged defenses and towers supremely fast with 70% Efficiency. |
| Master Repair Bot | `n02A` | 5000 | 5 large | – | – | – | – | 270 | 1 / 80 | 2 | Warden - Blink, Repair (Human) | Robot that can help repair damaged defenses and towers extraordinarily fast with 80% Efficiency. |
| Chief Repair Bot | `n02N` | 6000 | 5 large | – | – | – | – | 270 | 1 / 60 | 2 | Warden - Blink, Repair (Human) | Robot that can help repair damaged defenses and towers exclusively fast with 80% Efficiency. |

## Utility buildings

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Cost (g/l) | Build time | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Mercenary HQ | `h00T` | 1400 | 5 large | – | – | – | – | 0 / 0 | 40 | Mercenary HQ, Mercenary HQ, Mercenary HQ, Mercenary HQ | Main unit training facilty containing Melee, Range, and Support Mercenaries. |
| Command Center | `h01L` | 3000 | 5 fort | – | – | – | – | 0 / 0 | 15 | Command Center, Command Center, Command Center, Command Center, Command Center | Main base structure containing upgrades for Units, Towers and Buildings. Additionally offers Hero selection. |
| Item Vendor | `h05R` | 1250 | 5 fort | – | – | – | – | 0 / 0 | 50 | Allied Building, Purchase Item, Item Vendor, Item Vendor, Item Vendor, Item Vendor, Item Vendor, Item Vendor | Purchase Offensive, Defensive and Emergency equipment and stay ahead of your enemies! |
| Bookshelf | `h07B` | 4000 | 5 fort | – | – | – | – | 0 / 0 | 45 | Purchase 100 Normal Books, Sorting Magic, Production Chances | Techtree Knowledge & Production Building / Maximum Bookshelves Limit: 8 per player |

## Mercenaries (Mercenary HQ tabs)

### Marines (rank promotions ↳)

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Private | `z00Q` | 3500 | 1 small | 101–101 | 1 | 350 | pierce | 250 | 0 / 0 | 5 | Warden - Blink | The Marine Corps rank of Private (E-1) / Health: 3,500 |
| ↳ Private First Class | `z01F` | 4500 | 2 small | 157–159 | 1 | 400 | pierce | 250 | 0 / 2 | 5 | Warden - Blink, Unit Inventory [unit / new] | The Marine Corps rank of PFC (E-2) / Health: 4,500 |
| ↳ Lance Corporal | `z019` | 5500 | 3 small | 207–213 | 1 | 450 | pierce | 250 | 0 / 3 | 5 | Warden - Blink, Unit Inventory [unit / new] | The Marine Corps rank of Lance Corporal (E-3) / Health: 5,500 |
| ↳ Corporal | `z011` | 6500 | 4 medium | 257–263 | 1 | 500 | pierce | 250 | 0 / 5 | 5 | Warden - Blink, Unit Inventory [unit / new] | The Marine Corps rank of Corporal (E-4) / Health: 5,500 |
| ↳ Sergeant | `z00X` | 7500 | 5 medium | 307–313 | 1 | 550 | pierce | 270 | 0 / 40 | 5 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | The Marine Corps rank of Sergeant (E-5) / +Poisonous Bullets / Health: 7,500 |
| ↳ Staff Sergeant | `z00R` | 8500 | 6 medium | 357–363 | 1 | 600 | pierce | 270 | 0 / 40 | 5 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | The Marine Corps rank of Staff Sergeant (E-6) / +Poisonous Bullets / Health: 8,500 |
| ↳ Gunnery Sergeant | `z00Z` | 9500 | 7 medium | 409–421 | 1 | 650 | pierce | 270 | 1 / 60 | 5 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | The Marine Corps rank of Gunnery Sergeant (E-7) / +Poisonous Bullets / Health: 9,500 |
| Private First Class | `z01G` | 4500 | 2 small | 157–159 | 1 | 400 | pierce | 250 | 0 / 2 | 5 | Warden - Blink, Unit Inventory [unit / new] | The Marine Corps rank of PFC (E-2) / Health: 4,500 |
| Lance Corporal | `z018` | 5500 | 3 small | 207–213 | 1 | 450 | pierce | 250 | 0 / 5 | 5 | Warden - Blink, Unit Inventory [unit / new] | The Marine Corps rank of Lance Corporal (E-3) / Health: 5,500 |
| Corporal | `z01A` | 6500 | 4 medium | 257–263 | 1 | 500 | pierce | 250 | 0 / 10 | 5 | Warden - Blink, Unit Inventory [unit / new] | The Marine Corps rank of Corporal (E-4) / Health: 6,500 |
| Sergeant | `z01B` | 7500 | 5 medium | 307–313 | 1 | 550 | pierce | 270 | 0 / 50 | 5 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | The Marine Corps rank of Sergeant (E-5) / +Poisonous Bullets / Health: 7,500 |
| Staff Sergeant | `z01C` | 8500 | 6 medium | 357–363 | 1 | 600 | pierce | 270 | 1 / 100 | 5 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | The Marine Corps rank of Staff Sergeant (E-6) / +Poisonous Bullets / Health: 8,500 |
| Gunnery Sergeant | `z01D` | 9500 | 7 medium | 409–421 | 1 | 650 | pierce | 270 | 1 / 200 | 5 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | The Marine Corps rank of Gunnery Sergeant (E-7) / +Poisonous Bullets / Health: 9,500 |

### Melee

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Firebat | `z009` | 16000 | 6 medium | 370–394 | 1.6 | 400 | chaos / msplash | 270 | 0 / 50 | 10 | Warden - Blink, Unit Inventory [unit / new], Poisonous Bullets | Effective short ranged defender. / Health: 16,000 |
| Swordsman | `o002` | 8000 | 10 large | 504–528 | 0.5 | 100 | normal | 320 | 0 / 15 | 5 | Warden - Blink, Unit Inventory [unit / new] | Basic attacking unit with good damage and speed. / Health: 8,000 |
| Gladiator | `o005` | 12000 | 7 large | 723–741 | 0.5 | 100 | normal | 320 | 0 / 30 | 5 | Warden - Blink, Unit Inventory [unit / new] | Fast attacking unit with great damage and speed. / Health: 12,000 |
| Siege Machine | `o003` | 20000 | 10 large | 353–371 | 0.75 | 100 | siege | 220 | 0 / 50 | 10 | Warden - Blink, Unit Inventory [unit / new] | Powerful attacking unit with high health and damage! / Health: 20,000 |
| Bodyguard | `o001` | 35000 | 10 large | 25–25 | 1.5 | 100 | normal | 200 | 0 / 20 | 5 | Warden - Blink, Unit Inventory [unit / new] | Defending unit with high health and great blocking! / Health: 35,000 |

### Range

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Potions Master | `o000` | 2050 | 0 medium | 201–201 | 1 | 600 | chaos | 270 | 0 / 4 | 5 | Warden - Blink, Unit Inventory [unit / new], Poison Attack | Effective poison specialist medium ranged defender. / Health: 2,050 |
| Rocketeer | `z00G` | 5550 | 0 medium | 400–406 | 1.05 | 600 | siege / msplash | 260 | 0 / 75 | 10 | Warden - Blink, Unit Inventory [unit / new], Critical Strike (creep) | Expensive but effective splash damage defender. / Health: 5,500 |
| Exterminator | `z00C` | 6500 | 2 fort | 549–555 | 0.2 | 800 | pierce | 270 | 1 / 100 | 5 | Warden - Blink, Unit Inventory [unit / new] | Effective medium ranged defender against air. / Health: 6,500 |
| Sniper | `e001` | 6500 | 5 medium | 615–625 | 2.75 | 1200 | pierce | 270 | 1 / 75 | 10 | Warden - Blink, Unit Inventory [unit / new], Critical Strike (creep) | Expensive but effective long ranged defender. / Health: 6,500 |
| Abrams Tank | `u01I` | 9500 | 48 fort | 2510–2550 | 2.5 | 1600 | chaos | 140 | 10 / 500 | 5 | Warden - Blink, Unit Inventory [unit / new] | Expensive highly effective long ranged killing machine. / Health: 9,500 |

### Support

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Alchemist | `h050` | 3675 | 1 fort | – | – | – | – | 270 | 0 / 55 | 10 | Warden - Blink, Area Transmutation, Transmute | Transmutational alchemist making lumber mill' smaller. / +Area Transmutation / +Transmute / Health: 3,675 |
| Wizard | `h02T` | 4475 | 1 small | 145–150 | 1.55 | 600 | magic | 270 | 0 / 55 | 10 | Warden - Blink, Slow, Shadow Hunter - Hex, Unit Inventory [unit / new] | Spellcaster with unique defensive abilities. / +Slow (Autocast) / +Hex / Health: 4,475 |
| Mine Layer | `n00B` | 2500 | 1 large | – | – | – | – | 270 | 0 / 3 | 5 | Warden - Blink, Unit Inventory [unit / new], Set Venom Trap, Deploy Mine | Defender that can deploy mines to damage invaders. / +Set Venom Trap / +Deploy Mine / Health: 2,500 |
| Light Scout | `n00C` | 500 | 1 large | – | – | – | – | 330 | 0 / 5 | 5 | Warden - Blink, Detect (general) | Scouting Unit with fast speed and good vision. / +True Sight / Health: 500 |
| ↳ Swift Scout | `n05D` | 2000 | 1 fort | – | – | – | – | 420 | 0 / 25 | 0 | Warden - Blink, Unit Inventory [unit / new], Detect (general) | Very fast speed, true sight and excellent vision. / Can Upgrade Inventory Slots |
| Brigadier General | `h0EA` | 8475 | 1 divine | – | – | – | – | 210 | 5 / 500 | 10 | Warden - Blink, Unit Inventory [unit / new], General's Devotion Aura, General's Chaotic Roar, General's Command Aura, General's Endurance Aura | Troop commander. / +Chaotic Roar / +10 Unit Armor Aura / +50% Extra Tower Damage Aura / +30% Attack Speed Increase Aura / +25% Movement Speed Increase Aura / Health: 8,475 |
| Captain | `z00I` | 42500 | 8 medium | 160–184 | 0.55 | 500 | chaos / msplash | 300 | 3 / 300 | 10 | Warden - Blink, Unit Inventory [unit / new], Aura - Devotion (Creep), Inner Fire | Troop Captain. / +Inner Fire / +10 Unit Armor Aura / Health: 42,500 |
| Medic | `h000` | 4500 | 1 none | – | – | – | – | 270 | 0 / 30 | 10 | Warden - Blink, Unit Inventory [unit / new], Forbidden Regeneration, Healing Mist, Heal | Unit that can heal friendly defenders and structures. / +Forbidden Regeneration / +Heal (Autocast) / +Healing Mist / Health: 4,500 |

## Heroes (Command Center → Hero Management, pick 1)

Map constants: **+18 HP per STR**, +0.03 armor per AGI (base −5), +3 mana per INT, +1 damage per primary stat. Lvl 1 HP = base HP + 18 × STR.

| Name | ID | Lvl 1 HP | Armor | Damage | Cooldown | Range | Attack type | Speed | STR / AGI / INT (+per lvl) | Primary | Abilities |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Scientist | `H0DT` | 642 | 2 medium | 49–67 | 1 | 650 | hero | 300 | 29 / 36 / 42 (+6 / +7 / +12) | INT | Regenative Rays |
| Marine | `H03J` | 802 | 3 medium | 47–65 | 1 | 650 | pierce | 315 | 39 / 36 / 27 (+6 / +9 / +5) | AGI | Laser Strike |
| Rocketeer | `H06C` | 956 | 3 medium | 80–108 | 1.5 | 700 | siege / msplash 10 | 315 | 42 / 28 / 26 (+11 / +3 / +4) | STR |  |
| Shadow Sniper | `H08R` | 1604 | 3 medium | 89–90 | 1.75 | 900 | pierce | 300 | 28 / 57 / 16 (+4 / +13 / +3) | AGI | Dark Blink, Attach - Black / Purple Hands |
| Medic | `H0I3` | 642 | 2 medium | 49–67 | 1 | 650 | hero | 350 | 29 / 36 / 42 (+6 / +7 / +12) | INT |  |
| Specialist | `H0JX` | 1604 | 3 medium | 89–90 | 1.75 | 900 | pierce | 300 | 28 / 57 / 16 (+4 / +13 / +3) | AGI |  |
| Paratrooper | `H0JY` | 1604 | 3 medium | 89–90 | 1.75 | 900 | pierce | 300 | 28 / 57 / 16 (+4 / +13 / +3) | AGI |  |
| Tinker | `H07U` | 574 | 2 medium | 89–101 | 1.25 | 650 | hero | 400 | 18 / 21 / 46 (+3 / +4 / +14) | INT | Tinkerer - Cluster Rockets (Level 0), Repair (Human), SpellBook |
| Alchemist | `H06H` | 4336 | 4 medium | 99–111 | 1 | 625 | hero | 315 | 27 / 24 / 40 (+3 / +4 / +14) | INT | Reinforce |
| Commander | `H08S` | 838 | 3 medium | 47–65 | 1.2 | 750 | pierce | 315 | 41 / 34 / 26 (+14 / +6 / +5) | STR | Battle Cry |
| Techies | `H0JV` | 946 | 10 fort | – | – | – | – | 325 | 47 / 34 / 60 (+4 / +4 / +14) | INT |  |
| Astronomer | `H0C8` | 714 | 3 medium | 107–119 | 1 | 600 | hero | 320 | 23 / 21 / 45 (+3 / +4 / +15) | INT |  |
| Shaman | `H0I1` | 2360 | 4 fort | 102–174 | 0.2 | 750 | magic | 325 | 20 / 23 / 44 (+3 / +4 / +14) | INT |  |
| Windrunner | `H0JW` | 1604 | 3 medium | 89–90 | 1.75 | 900 | pierce | 300 | 28 / 57 / 16 (+4 / +13 / +3) | AGI | Warden - Blink, Multi Shot |
| Juggernaut | `H0JZ` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Armored Tank | `H0I0` | 686 | 3 large | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Crystal Maiden | `H0JU` | 1946 | 3 medium | 89–90 | 1 | 800 | magic | 300 | 47 / 34 / 60 (+4 / +4 / +14) | INT | Attach - Frost |
| Assassin | `H0GU` | 2306 | 4 large | 102–174 | 0.8 | 128 | chaos | 300 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Witch | `H0I2` | 714 | 3 medium | 107–119 | 1 | 850 | hero | 320 | 23 / 21 / 45 (+3 / +4 / +15) | INT |  |
| Snowman | `H0IP` | 5056 | 4 large | 103–115 | 1 | 180 | chaos | 300 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Skeleton | `H0K0` | 2306 | 3 large | 89–90 | 0.2 | 128 | siege | 300 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| AzZ | `H0FF` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation, Attach - Freezing Attack, Attach - Bright Light, Attach - Flash Move |
| AzZ | `H0G0` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation, Attach - Shadow, Attach - Phoenix |
| AzZ | `H0GZ` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR | Attach - Burning Hands |
| Aazensnow | `H0L2` | 1838 | 4 medium | 85–157 | 0.9 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |
| akdwnvkx | `H0JH` | 938 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |
| ant1000123 | `H0I6` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI |  |
| Angkemmoti | `H0KS` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| AngKemmoti | `H0KY` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Baby Michael | `H09U` | 1676 | 2 medium | 83–125 | 1 | 950 | chaos | 400 | 32 / 64 / 27 (+4 / +20 / +3.2) | AGI | Transmute, Area Transmutation, SpellBook, SpellBook |
| Bazilla10 | `H0FM` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation, Transmute |
| bi_a_op | `H0GD` | 1838 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation |
| BlueBerryMuffin | `H0F1` | 4336 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Transmute, Area Transmutation |
| BlueBerryMuffin | `H0FN` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR | Attach - Frost |
| BlueBerryMuffin | `H0HA` | 1946 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 47 / 27 / 67 (+14 / +6 / +20) | INT | Attach - Mana Flare |
| Cidiaus | `H0E4` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| Cidiaus | `H0E9` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Cidiaus | `H0H9` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI |  |
| Dapains | `H0FY` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation, Transmute |
| DarkHero | `H0FH` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Deadmau5 | `H0C0` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| DemonicKing | `H0F5` | 4336 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+14 / +6 / +5) | STR | Area Transmutation |
| djviro | `H0FL` | 1586 | 2 medium | 77–78 | 1.75 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Transmute, Area Transmutation |
| BLinkY | `H09N` | 1838 | 2 medium | 83–125 | 1.1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Ion Cannon, Charm, Area Transmutation |
| Fattony | `H0A0` | 1838 | 2 medium | 83–153 | 1 | 850 | chaos / msplash | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Charm, Cleave, Area Transmutation, Attach - Flameshot Aura, Attach - Burning Flame, Attach - AuraOfDeath |
| E.K.2. | `H0H3` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| E.K.2. | `H0FI` | 988 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |
| E.K.2. | `H0IG` | 988 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |
| Elo- | `H0J5` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 375 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| emeldjrngksp | `H0HV` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Emperor000 | `H0LC` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Charm |
| Ethaw | `H0GP` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI |  |
| Feud999 | `H0J9` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Ion Cannon |
| Ginfire | `H0GJ` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| GhosTz | `H0HX` | 1586 | 3 medium | 77–78 | 1.75 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Gnoix | `H0GX` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Gnoix | `H0K3` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Guambaybee420 | `H0CF` | 1838 | 4 medium | 85–157 | 0.9 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation, Battle Cry |
| HatoNoIke | `H0JF` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| Hawthorne | `H0GA` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| I_vErY_nOoD69 | `H0GO` | 1586 | 3 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Icedup | `H0KX` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Liebe | `H0FD` | 1586 | 4 medium | 82–94 | 0.8 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Ion Cannon |
| Liebe | `H0FG` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Liebe | `H0GT` | 1586 | 4 medium | 82–94 | 0.8 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| LieToMe | `H0IA` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| Jaec | `H0H1` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Jasieknms | `H09V` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Jackeroo | `H0CZ` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Jackeroo | `H0IN` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI | Attach - Burning Hands |
| KeXi | `H0JL` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Kurom | `H0KK` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI |  |
| Jon54 | `H0BP` | 1738 | 3 medium | 82–100 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Battle Cry |
| Jonas1112 | `H0K1` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| KILLAGUNFISH | `H0FR` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Transmute, Area Transmutation |
| Kimimaro | `H0D6` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation, Transmute |
| Krehara | `H0JS` | 1838 | 4 medium | 85–157 | 0.9 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |
| Kiyoshi | `H0IB` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | AGI |  |
| Lt_Storm | `H0EN` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Miavita | `H0IJ` | 1586 | 3 medium | 77–78 | 1.75 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation, Attach - Black / Purple Hands |
| Miavita | `H0IO` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 375 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Mindless03 | `H0FC` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Mindless03 | `H0GR` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Mindless03 | `H0HD` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI | Unholy Aura |
| Miraksy | `H0L8` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Missouri | `H0FK` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Missouri | `H0IH` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Missouri | `H0KM` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Missouri | `H0HC` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR | Unholy Aura |
| Destroyer | `H0H0` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR | Attach - Burning Hands |
| Renegade | `H04W` | 1856 | 0 fort | 82–112 | 0.65 | 1100 | chaos | 500 | 42 / 52 / 32 (+15 / +18 / +12) | AGI | SpellBook |
| Wizard | `H0E7` | 1856 | 0 fort | 82–112 | 0.65 | 1100 | chaos | 500 | 42 / 52 / 32 (+15 / +18 / +12) | AGI | SpellBook, Attach - Shadow |
| Fearless Beast | `H0I4` | 2306 | 4 fort | 108–180 | 0.2 | 158 | chaos | 400 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| Scarlet-Scar | `H0JO` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI |  |
| sRy_I_jUsT_oWn | `H0C5` | 1586 | 3 medium | 77–78 | 1.75 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Charm, Transmute, Area Transmutation |
| Soulshot | `H0IM` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Starwolfff | `H0IS` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Sieghart93 | `H0IC` | 1946 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 47 / 27 / 67 (+14 / +6 / +20) | INT |  |
| nathancoolio | `H0E3` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Transmute, Area Transmutation |
| NinjaCat | `H0KW` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| Niwa | `H0FJ` | 838 | 3 medium | 82–100 | 1.2 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation |
| nonoahno | `H0HR` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Attach - Freezing Attack, Attach - Soul Theft [Right Hand] |
| nonoahno | `H0HS` | 2306 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR |  |
| nonoahno | `H0HT` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| nonoahno | `H0L9` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Okami_Prince | `H0IW` | 1586 | 4 fort | 102–174 | 0.8 | 128 | chaos | 315 | 27 / 66 / 24 (+8 / +20 / +5) | AGI |  |
| Pwnage | `H0GH` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+3 / +14 / +4) | AGI |  |
| Rengate | `H0E6` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Transmute, Area Transmutation |
| Rodo | `H0IF` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 40 / 24 (+3 / +14 / +4) | AGI |  |
| Sniper Revol | `H0BN` | 1586 | 3 large | 77–78 | 1.75 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Attach - Black / Purple Hands |
| Nerubian Spider of the Cold | `H0E1` | 1506 | 0 fort | 82–112 | 0.65 | 1200 | chaos / mbounce 450 | 500 | 42 / 52 / 32 (+17 / +16 / +9) | STR | SpellBook, SpellBook, SpellBook |
| The judgemental | `H0CY` | 1406 | 0 fort | 82–112 | 0.68 | 1200 | chaos / mbounce 450 | 500 | 42 / 52 / 32 (+18 / +16 / +8) | STR | SpellBook, SpellBook, SpellBook |
| Snowman | `H0GE` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Shtroumf | `H0H2` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| Sleeper707 | `H0CE` | 1838 | 4 medium | 85–157 | 0.9 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation, Battle Cry |
| SoiSoiSoiSoiSoi | `H0DO` | 736 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation, Transmute |
| somewhiteguy | `H0GY` | 838 | 3 medium | 82–100 | 1.2 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |
| SoulSurvivor | `H0EI` | 988 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation |
| Stormvalor | `H0BO` | 2306 | 4 fort | 102–174 | 0.7 | 128 | chaos | 315 | 67 / 47 / 27 (+20 / +11 / +6) | STR | Charm, Area Transmutation |
| Strangedoll | `H09W` | 1838 | 2 medium | 83–125 | 1.1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Detect (general), Area Transmutation |
| Streets Of Rage | `H07P` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Charm, Attach - Black / Purple Hands, Bloodlust |
| Sworeshewaslvl18 | `H0GM` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| Takla | `H0GV` | 686 | 3 medium | 83–111 | 1.5 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT | Area Transmutation |
| SmallTeddyBear | `H09I` | 2018 | 2 medium | 83–125 | 0.95 | 850 | chaos | 350 | 51 / 44 / 34 (+14 / +6 / +5) | STR | Charm, Area Transmutation |
| Warrior of Sunlight | `H0CW` | 988 | 3 medium | 82–94 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation, Transmute |
| TheFallenOne | `H09X` | 1676 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 32 / 27 / 64 (+4 / +4 / +14) | INT | Area Transmutation |
| TheFilthyRat | `H08I` | 1838 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Transmute, Area Transmutation |
| TheShinysSun | `H0JN` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 24 / 40 (+4 / +4 / +14) | INT |  |
| Ve1ro | `H08U` | 1586 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 27 / 40 / 24 (+4 / +14 / +4) | AGI | Area Transmutation |
| Waffle | `H0CG` | 646 | 0 fort | 78–84 | 1.5 | 850 | chaos | 315 | 22 / 24 / 33 (+9 / +8 / +18) | INT | Area Transmutation, Transmute |
| War-G0DS | `H0IT` | 1946 | 4 fort | 99–111 | 0.8 | 128 | chaos | 315 | 47 / 27 / 67 (+14 / +6 / +20) | INT | Area Transmutation |
| Weapons Platform | `H0HO` | 2036 | 3 fort | 89–119 | 0.6 | 1000 | chaos | 1 | 52 / 42 / 32 (+18 / +15 / +12) | STR |  |
| Xlili | `H0KB` | 1838 | 2 medium | 83–125 | 1 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Area Transmutation |
| yungyungyung | `H09R` | 1838 | 3 medium | 77–78 | 1.75 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR | Transmute, Area Transmutation, Unholy Aura |
| ZeroFlotsie | `H0L7` | 1838 | 4 medium | 85–157 | 0.9 | 850 | chaos | 315 | 41 / 34 / 24 (+14 / +6 / +5) | STR |  |

## Enemies (spawned for the hostile player)

Sorted by base HP. Includes wave units, mini-bosses and bosses (e.g. The Trojan).

| Name | ID | HP | Armor | Damage | Cooldown | Range | Attack type | Speed | Cost (g/l) | Food | Abilities | Tooltip |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Shadow of Chaos Ion | `n04B` | 50 | 6 hero | 7500–7500 | 0.8 | 60 | chaos | 350 | 595 / 200 | 0 |  |  |
| Assassin | `n04I` | 240 | 0 large | 9–10 | 0.1 | 100 | normal | 420 | 85 / 0 | 1 |  |  |
| Rock Abomination | `n024` | 450 | 2 none | 125–129 | 0.9 | 60 | normal | 455 | 290 / 80 | 0 | Critical Strike (creep) |  |
| Euxo | `n00S` | 540 | 1 medium | 120–126 | 1.2 | 60 | pierce | 415 | 170 / 20 | 0 |  |  |
| Lesser G'rak | `z003` | 780 | 1 small | 45–50 | 0.9 | 60 | normal | 270 | 85 / 0 | 0 |  |  |
| Nightstriker | `n016` | 875 | 3 medium | 332–337 | 1.75 | 60 | pierce | 375 | 170 / 20 | 0 |  |  |
| Greater G'rak | `n006` | 1100 | 3 medium | 263–273 | 1 | 70 | chaos | 350 | 255 / 50 | 0 |  |  |
| G'yex Jre | `z004` | 1190 | 2 medium | 100–100 | 0.65 | 60 | normal | 270 | 280 / 30 | 0 |  |  |
| Obnoxious G'rak | `n041` | 1300 | 3 medium | 383–393 | 0.8 | 70 | chaos | 350 | 255 / 50 | 0 |  |  |
| Bloodstained G'rak | `z00O` | 1340 | 1 small | 105–110 | 0.5 | 60 | normal | 270 | 85 / 0 | 0 | Venom Spears (Creep) |  |
| Muur Otu | `n037` | 1375 | 1 small | 285–286 | 1.25 | 70 | normal | 270 | 170 / 20 | 0 | Venom Spears (Creep) |  |
| Muur Oti | `n007` | 1525 | 1 small | 125–130 | 1.3 | 70 | normal | 270 | 170 / 20 | 0 | Venom Spears (Creep) |  |
| Muur Uta | `n040` | 1675 | 1 small | 440–441 | 1.1 | 70 | normal | 270 | 170 / 20 | 0 | Venom Spears (Creep) |  |
| Cobalt Phantom | `n02F` | 1780 | 2 none | 1714–1738 | 0.65 | 60 | chaos | 320 | 290 / 80 | 0 |  |  |
| Venomous G'rak | `z00H` | 2180 | 1 small | 60–65 | 0.65 | 60 | normal | 270 | 85 / 0 | 0 | Venom Spears (Creep) |  |
| Tun Yremji | `n00A` | 2270 | 1 small | 115–125 | 0.7 | 70 | chaos | 300 | 205 / 30 | 0 | Slow (Creep) |  |
| Tun Komji | `n004` | 2370 | 1 small | 190–205 | 0.7 | 70 | chaos | 270 | 170 / 20 | 0 |  |  |
| Tun Rioji | `n03U` | 2470 | 2 small | 325–335 | 0.6 | 70 | chaos | 270 | 170 / 20 | 0 |  |  |
| Undead Boberto | `n05S` | 2500 | 4 medium | 102–104 | 0.6 | 100 | normal | 300 | 170 / 20 | 0 |  |  |
| Undead Mr Shinkel | `n05U` | 2500 | 4 medium | 102–104 | 0.6 | 100 | normal | 300 | 170 / 20 | 0 |  |  |
| Undead Scurvy Pirate | `n05V` | 2500 | 4 medium | 102–104 | 0.6 | 100 | normal | 300 | 170 / 20 | 0 | Attach - Pirate Hat |  |
| Undead Wizard Cidiaus | `n05W` | 2500 | 4 medium | 102–104 | 0.6 | 100 | normal | 300 | 170 / 20 | 0 | Attach - Mana Flare |  |
| Undead Warrant Officer | `n05X` | 2500 | 4 medium | 102–104 | 0.6 | 100 | normal | 300 | 170 / 20 | 0 | Attach - Military Hat |  |
| Wekaleng | `n00Y` | 2590 | 2 none | 324–328 | 1 | 60 | normal | 310 | 290 / 80 | 0 |  |  |
| Meirg Phantom | `n01K` | 2680 | 2 none | 1314–1338 | 0.75 | 60 | chaos | 320 | 290 / 80 | 0 |  |  |
| Undead Mr Saunders | `n01M` | 2750 | 4 small | 54–58 | 2 | 100 | siege | 250 | 170 / 20 | 0 | Attach - Far Seer Lightning |  |
| Undead Lt Vince | `n05E` | 2750 | 4 small | 54–58 | 2 | 100 | siege | 250 | 170 / 20 | 0 |  |  |
| Har'yaz | `n03O` | 2800 | 2 none | 665–675 | 0.75 | 60 | normal | 350 | 290 / 80 | 0 |  |  |
| Torn Wretch | `n01E` | 3100 | 3 medium | 649–663 | 1.3 | 60 | pierce | 415 | 170 / 20 | 0 |  |  |
| Blood Welik | `n00D` | 3325 | 2 medium | 370–371 | 0.9 | 70 | siege | 270 | 170 / 20 | 0 | Immolation (creep), Devour (Dragon Creep) |  |
| Illicit Minion | `n022` | 3400 | 10 large | 2570–2590 | 0.3 | 60 | siege | 320 | 205 / 30 | 0 | Ghost |  |
| Fher'Vlarr | `n00T` | 3500 | 2 small | 140–145 | 1.35 | 400 | magic | 300 | 205 / 30 | 0 |  |  |
| Jumendo Fuo | `n00O` | 3600 | 0 medium | 766–774 | 1.35 | 60 | spells | 290 | 155 / 15 | 0 | Heal (Creep Normal) |  |
| Fher'Vek | `n00I` | 3625 | 1 large | 240–250 | 0.8 | 60 | chaos | 300 | 205 / 30 | 0 | Inner Fire (Creep) |  |
| Vice | `n003` | 3666 | 4 hero | 495–505 | 1.35 | 60 | chaos | 320 | 385 / 120 | 0 | Bloodlust (Creep), Unholy Aura (creep) |  |
| Noragore | `n01Q` | 3715 | 3 medium | 350–364 | 1.8 | 400 | chaos | 220 | 170 / 20 | 0 | Venom Spears (Creep) |  |
| Jamendo Fuo | `n036` | 3800 | 1 medium | 1255–1263 | 1.35 | 60 | spells | 290 | 155 / 15 | 0 | Heal |  |
| Asyyd | `n01F` | 4050 | 1 large | 275–280 | 1.65 | 400 | chaos | 300 | 205 / 30 | 0 |  |  |
| Blood Manifest | `n002` | 4200 | 6 large | 865–875 | 1.5 | 60 | chaos | 270 | 595 / 200 | 0 | Immolation (creep) |  |
| Dreadbane | `n005` | 4250 | 2 large | 1215–1225 | 1.7 | 80 | normal | 270 | 270 / 15 | 0 | Cleaving Attack (Creep) |  |
| Wicked G'rak | `n00X` | 4450 | 3 large | 785–795 | 1.15 | 70 | chaos | 350 | 255 / 50 | 0 |  |  |
| Tajiikosh Sage | `n00M` | 4600 | 8 large | 1633–1640 | 1.25 | 450 | pierce | 320 | 290 / 80 | 0 | Aura - Trueshot (Creep) |  |
| Alpha Vice | `n032` | 4667 | 4 hero | 690–696 | 1.35 | 60 | chaos | 320 | 385 / 120 | 0 | Evasion (creep), Attach - Mana Flare, Bloodlust (Creep), Unholy Aura (creep) |  |
| Dark Manifest | `n045` | 4750 | 6 large | 1235–1245 | 1.35 | 60 | chaos | 300 | 595 / 200 | 0 | Attach - Shadow Orb, Immolation (creep) |  |
| Dreadbane Ancestor | `n033` | 4850 | 2 large | 1405–1415 | 1.7 | 80 | normal | 270 | 270 / 15 | 0 | Cleaving Attack (Creep) |  |
| Choragus | `n018` | 4950 | 3 medium | 660–667 | 1.5 | 60 | normal | 250 | 170 / 20 | 0 |  |  |
| Callahan | `n03V` | 4950 | 4 large | 705–715 | 0.5 | 70 | chaos | 350 | 255 / 50 | 0 | Attach - Shadow Orb |  |
| Jumendo Jwa | `n00P` | 5000 | 0 large | 900–912 | 1.35 | 60 | spells | 300 | 210 / 30 | 0 | Aura - Brilliance (creep), Healing Wave(Creep) |  |
| Bubbles | `n03W` | 5000 | 4 medium | 420–434 | 0.75 | 400 | chaos | 220 | 170 / 20 | 0 |  |  |
| Malevolent Vice | `n047` | 5400 | 4 hero | 1680–1686 | 0.9 | 60 | chaos | 320 | 385 / 120 | 0 | Evasion (creep), Attach - Mana Flare, Bloodlust (Creep), Unholy Aura (creep) |  |
| Dnemtowq | `n001` | 5842 | 2 none | 65–69 | 0.1 | 60 | normal | 450 | 290 / 80 | 0 | Ghost, Critical Strike (creep) |  |
| Dual Mantis Beast | `n038` | 5850 | 2 large | 480–498 | 0.8 | 60 | siege | 300 | 205 / 30 | 0 | Attach - Freezing Attack, Critical Strike (creep) |  |
| Mantis Beast | `n010` | 5900 | 1 large | 500–518 | 0.85 | 60 | siege | 300 | 205 / 30 | 0 | Critical Strike (creep) |  |
| Zul'Aman | `n03H` | 6000 | 4 hero | 1687–1701 | 0.95 | 60 | normal | 320 | 385 / 120 | 0 | Bloodlust (Creep), Unholy Aura (creep) |  |
| Undead Human | `n00W` | 6200 | 2 medium | 341–343 | 1 | 100 | normal | 280 | 170 / 20 | 0 |  |  |
| Cerberus | `n028` | 6200 | 10 hero | 200–200 | 0.55 | 60 | chaos | 400 | 290 / 80 | 0 | Boss Marker, Critical Strike (creep), Evasion (creep), Attack Bonus, Mountain King - Avatar, Roar, Cerberus Tip | You shouldn't be able to see this! WTF? |
| Torrential Mantis Beast | `n046` | 6200 | 3 large | 585–603 | 0.7 | 60 | siege | 325 | 205 / 30 | 0 | Attach - Freezing Attack, Critical Strike (creep) |  |
| Greater Blood Welik | `n068` | 6225 | 2 medium | 480–481 | 0.8 | 70 | siege | 270 | 170 / 20 | 0 | Rage, Immolation (creep), Devour (Dragon Creep) |  |
| Slujj | `n01D` | 6250 | 4 small | 1415–1425 | 1.3 | 70 | chaos | 250 | 170 / 20 | 0 | Resistant Skin (creep) |  |
| Kethkyhh | `n01J` | 6290 | 2 medium | 1638–1650 | 2.2 | 60 | pierce | 290 | 170 / 20 | 0 |  |  |
| Mantis Slicer | `n015` | 6300 | 1 large | 549–564 | 1.3 | 60 | siege | 300 | 205 / 30 | 0 | Critical Strike (creep) |  |
| Abyssal G'rak | `n03I` | 6300 | 5 hero | 1001–1013 | 2.5 | 60 | chaos | 400 | 255 / 50 | 0 | Boss Marker, Evasion (creep), Unholy Frenzy (creep) | You shouldn't be able to see this! WTF? |
| Slujjie | `n039` | 6750 | 4 small | 1580–1590 | 1.3 | 70 | chaos | 270 | 170 / 20 | 0 | Resistant Skin (creep) |  |
| Doombringer | `n030` | 6825 | 4 large | 1378–1402 | 0.9 | 70 | chaos | 350 | 255 / 50 | 0 | Attach - Phoenix |  |
| Skrassh Zir | `n009` | 6925 | 15 hero | 340–352 | 0.4 | 60 | normal | 300 | 205 / 30 | 0 | Ensnare (Creep) |  |
| Dreadbane Sire | `n00R` | 7000 | 2 large | 1451–1457 | 1.55 | 80 | normal | 270 | 270 / 15 | 0 | Cleaving Attack (Creep) |  |
| Baby Radioactive Worm | `n04N` | 7000 | 130 normal | 4211–5300 | 0.5 | 70 | chaos | 425 | 0 / 50 | 0 |  | Radiactive Worm |
| Muur Vu | `n01A` | 7500 | 4 small | 1970–1988 | 1.2 | 70 | normal | 270 | 170 / 20 | 0 | Venom Spears (Creep) |  |
| Jungle Dnemtowq | `n023` | 7560 | 2 normal | 80–84 | 0.1 | 60 | normal | 455 | 290 / 80 | 0 | Ghost, Critical Strike (creep) |  |
| Lesser Hydra | `n02Q` | 8640 | 9 large | 4761–4789 | 1.05 | 70 | chaos | 260 | 170 / 20 | 0 |  |  |
| Rebel Marine | `n00G` | 8745 | 4 large | 670–675 | 0.5 | 60 | siege | 270 | 170 / 20 | 0 |  |  |
| Undead Human | `n01B` | 8750 | 3 medium | 698–700 | 0.8 | 100 | normal | 290 | 170 / 20 | 0 |  |  |
| Brutefist | `n019` | 8900 | 7 fort | 2600–2618 | 1.45 | 60 | siege | 260 | 205 / 30 | 0 |  |  |
| Valiant Muur Va | `n02D` | 9000 | 4 small | 2145–2163 | 1.15 | 70 | normal | 350 | 170 / 20 | 0 | Venom Spears (Creep) |  |
| Mutated Muur Vu | `n031` | 9500 | 5 small | 2515–2533 | 1.15 | 70 | normal | 270 | 170 / 20 | 0 | Attach - Soul Theft [Right Hand], Venom Spears (Creep) |  |
| Demonic Artillery | `u017` | 9500 | 8 medium | 1469–1509 | 3 | 1000 | chaos / artillery 75 | 140 | 0 / 0 | 0 |  |  |
| Wretched Muur Vak | `n03J` | 10000 | 6 small | 3040–3064 | 1.15 | 70 | normal | 270 | 170 / 20 | 0 | Attach - Soul Theft [Right Hand], Venom Spears (Creep) |  |
| Ethernal Light | `n03S` | 10000 | 4 none | 10000–10000 | 2.5 | 70 | chaos | 260 | 170 / 20 | 0 |  |  |
| Ancient Dnemtowq | `n03E` | 10257 | 2 small | 230–240 | 0.1 | 60 | normal | 450 | 290 / 80 | 0 | Ghost, Critical Strike (creep) |  |
| Muur Ota | `n03Q` | 10500 | 7 small | 3445–3469 | 1.15 | 70 | normal | 280 | 170 / 20 | 0 | Attach - Spirit Link [Right Hand], Venom Spears (Creep) |  |
| Giga Brutefist | `n02G` | 10800 | 8 fort | 3160–3178 | 1.15 | 60 | siege | 260 | 205 / 30 | 0 |  |  |
| Corrupt Marine | `n03A` | 10875 | 4 large | 1033–1038 | 0.45 | 60 | siege | 270 | 170 / 20 | 0 |  |  |
| Undead Human | `n01P` | 10900 | 4 medium | 966–968 | 0.6 | 100 | normal | 300 | 170 / 20 | 0 |  |  |
| Erinyes | `n03D` | 11420 | 6 medium | 2265–2289 | 2 | 200 | pierce | 300 | 170 / 20 | 0 |  |  |
| Birnes | `n03N` | 12000 | 7 large | 4860–4870 | 1.2 | 70 | normal | 225 | 170 / 20 | 0 |  |  |
| Wyrg Shard | `n01N` | 12050 | 60 small | 1943–1976 | 1.4 | 60 | magic | 350 | 595 / 200 | 0 | Unholy Frenzy (creep) |  |
| Dyysa | `n03L` | 12050 | 1 large | 395–405 | 1.35 | 400 | chaos | 300 | 205 / 30 | 0 |  |  |
| Garganta | `n042` | 13000 | 7 large | 5830–5840 | 1.1 | 70 | normal | 225 | 170 / 20 | 0 |  |  |
| Yothre | `n01S` | 13600 | 5 large | 5383–5399 | 1.15 | 70 | normal | 260 | 170 / 20 | 0 |  |  |
| Arctic Mammoth | `n034` | 13800 | 9 fort | 4065–4089 | 0.9 | 60 | siege | 260 | 205 / 30 | 0 | Attach - Freezing Breath |  |
| Blood Scarab | `n035` | 14000 | 6 large | 6540–6545 | 0.8 | 70 | normal | 260 | 170 / 20 | 0 |  |  |
| Pheng | `n00Q` | 14800 | 20 hero | 2006–2024 | 0.15 | 60 | normal | 300 | 205 / 30 | 0 | Boss Marker, Critical Strike (creep), Evasion (creep), Reincarnation (creep), Attach - Gul'dan Attack Fire | You shouldn't be able to see this! WTF? |
| Spitebringer | `n014` | 15000 | 4 large | 958–970 | 1.35 | 70 | spells | 350 | 255 / 50 | 0 | Critical Strike (creep), Frost Armor (Autocast, Naga) |  |
| Zearot | `n043` | 15000 | 3 small | 6875–6885 | 0.95 | 70 | normal | 350 | 170 / 20 | 0 | Pulverize (Sea Giant) |  |
| Hydra | `n02M` | 15640 | 105 large | 6191–6219 | 1 | 70 | chaos | 260 | 170 / 20 | 0 | Corrosive Breath |  |
| Zothre | `n02E` | 15800 | 7 large | 6137–6153 | 1.1 | 70 | normal | 260 | 170 / 20 | 0 |  |  |
| Zonic | `n03M` | 16400 | 3 small | 6325–6335 | 1 | 70 | normal | 350 | 170 / 20 | 0 | Pulverize (Sea Giant) |  |
| Demonic Dragon | `n04F` | 18200 | 9 small | 4758–4791 | 1.6 | 250 | chaos | 280 | 0 / 0 | 8 |  |  |
| Water Revenant | `n01T` | 20000 | 65 hero | 6192–6210 | 0.55 | 60 | chaos / msplash 75 | 300 | 595 / 200 | 0 | Boss Marker, Critical Strike (creep), Ice Age, Evasion (creep), Frost | You shouldn't be able to see this! WTF? |
| Fire Shrieker | `n01X` | 20000 | 65 hero | 48–81 | 0.5 | 500 | chaos / msplash 75 | 300 | 595 / 200 | 0 | Boss Marker, Critical Strike (creep), War Stomp (creep), Fire Bolt (creep), Self Destruct (Clockwerk Goblins), Evasion (creep) | You shouldn't be able to see this! WTF? |
| Enygma | `n01O` | 21000 | 5 medium | 6740–6747 | 0.85 | 60 | chaos | 300 | 435 / 150 | 0 | Attach - AuraOfDeath, Howl of Terror |  |
| Demonic Mage | `u01A` | 21750 | 12 none | 3833–3845 | 1 | 300 | chaos | 340 | 0 / 0 | 0 |  |  |
| The Tormentor | `n02L` | 22000 | 6 large | 13289–13317 | 1.2 | 70 | normal | 270 | 170 / 20 | 0 | Attach - Building Damage, War Stomp (creep) |  |
| Failed Nevo Clone | `n02J` | 22400 | 50 fort | 8100–8128 | 1.1 | 70 | chaos | 260 | 170 / 20 | 0 |  |  |
| Cinoz | `n03Y` | 23000 | 5 medium | 6590–6595 | 1.15 | 60 | siege | 275 | 435 / 150 | 0 | Pulverize (Sea Giant) |  |
| Lady Witch | `n02K` | 23600 | 6 large | 5762–5790 | 1.1 | 70 | siege | 270 | 170 / 20 | 0 | Attach - Banish |  |
| Hanulla | `n00Z` | 24500 | 35 hero | 2420–2453 | 2 | 60 | chaos | 300 | 595 / 200 | 8 | Boss Marker, Freezing Breath, Frost Breath | You shouldn't be able to see this! WTF? |
| Defiled Marine | `n03C` | 24500 | 8 large | 7465–7475 | 0.7 | 60 | siege | 300 | 170 / 20 | 0 |  |  |
| Skeleton King | `n025` | 25000 | 4 small | 300–300 | 0.55 | 60 | chaos | 240 | 170 / 20 | 0 | Boss Marker, Attach - Burning Hands | You shouldn't be able to see this! WTF? |
| Baby Cursed Arthus | `n04P` | 25000 | 45 normal | 6434–7523 | 0.3 | 70 | chaos | 425 | 0 / 50 | 0 | Cursed Arthus Helmet, Attach - Black / Purple Hands, Attach - Shadow Aura, Attach - Grudge Aura, Attach - Shade Aura | Baby Cursed Arthus |
| Nawg | `n03P` | 26500 | 14 medium | 7272–7300 | 0.8 | 70 | chaos | 260 | 170 / 20 | 0 |  |  |
| Asudem | `n044` | 26800 | 6 large | 6936–6964 | 1.1 | 70 | siege | 270 | 170 / 20 | 0 | Attach - Banish |  |
| Zayrahr | `n03R` | 27200 | 12 small | 8985–8995 | 1.05 | 70 | chaos | 260 | 170 / 20 | 0 |  |  |
| Baba Yaga | `n03K` | 28000 | 11 medium | 15130–15130 | 2.5 | 60 | chaos | 270 | 290 / 80 | 0 | Heal Baba |  |
| Pawg | `n03X` | 29500 | 18 medium | 9120–9148 | 0.7 | 70 | chaos | 260 | 170 / 20 | 0 |  |  |
| Korruption | `n017` | 34050 | 70 hero | 5550–5583 | 1.2 | 60 | chaos | 300 | 595 / 200 | 8 | Boss Marker | You shouldn't be able to see this! WTF? |
| Skrassh | `n00E` | 35259 | 15 hero | 3190–3202 | 1 | 70 | normal | 150 | 205 / 30 | 0 | Boss Marker, Evasion (creep), Ensnare (Creep) | You shouldn't be able to see this! WTF? |
| Baby Trojan | `n02C` | 40000 | 25 medium | 6212–6220 | 0.5 | 60 | chaos | 380 | 340 / 100 | 0 | Magic Immunity (Creep), Raven Form (Druid) |  |
| Tyura | `n03G` | 40000 | 145 hero | 16500–16510 | 0.7 | 80 | normal | 350 | 595 / 200 | 0 | Attach - Red Eyes, Evasion (creep) |  |
| Wyrg | `n00J` | 42000 | 60 hero | 6701–6734 | 1.1 | 60 | magic | 350 | 595 / 200 | 0 | Boss Marker, Unholy Frenzy (creep) | You shouldn't be able to see this! WTF? |
| Grumus | `n02W` | 42000 | 30 hero | 7570–7580 | 0.65 | 80 | chaos | 400 | 595 / 200 | 0 | Boss Marker, Critical Strike (creep), War Stomp (creep) | You shouldn't be able to see this! WTF? |
| Dreadbane Khan | `n00H` | 45188 | 38 hero | 7864–7867 | 1.65 | 60 | chaos | 260 | 270 / 15 | 0 | Boss Marker, Critical Strike (creep), Evasion (creep), Pulverize (Sea Giant) | You shouldn't be able to see this! WTF? |
| Three-Headed Hydra | `n02I` | 46000 | 85 hero | 22190–22200 | 0.11 | 60 | chaos | 250 | 595 / 200 | 0 | Boss Marker, Critical Strike (creep), Divine Shield (creep), Roar | You shouldn't be able to see this! WTF? |
| Granite Brutefist | `n02Y` | 46600 | 85 hero | 6180–6222 | 0.8 | 60 | siege | 260 | 205 / 30 | 0 | Boss Marker, Evasion (creep), Critical Strike (creep), Pulverize (Sea Giant) | You shouldn't be able to see this! WTF? |
| Illicit | `n01G` | 47300 | 50 hero | 9300–9363 | 1 | 60 | siege | 325 | 205 / 30 | 0 | Boss Marker, Lunar Mist, Ghost | You shouldn't be able to see this! WTF? |
| Sheep Of Rage | `n03Z` | 48000 | 85 hero | 9850–9860 | 1.5 | 60 | chaos | 350 | 595 / 200 | 0 | Boss Marker, Critical Strike (creep), Evasion (creep), Immolation (creep), Attach - AdvDeathTower Skull | You shouldn't be able to see this! WTF? |
| Avatar Askori | `n020` | 49300 | 45 small | 3980–4001 | 0.2 | 60 | chaos | 270 | 170 / 20 | 0 | Boss Marker, Critical Strike (creep), Evasion (creep), Attach - Purple Eyes, Ghost | You shouldn't be able to see this! WTF? |
| Quetzasnare | `n03F` | 56000 | 135 hero | 7425–7435 | 0.4 | 200 | chaos | 300 | 170 / 20 | 0 | Boss Marker | You shouldn't be able to see this! WTF? |
| Tyura | `n02H` | 59500 | 155 hero | 20000–20000 | 0.25 | 80 | siege | 350 | 595 / 200 | 0 | Boss Marker, Critical Strike (creep), Attach - Red Eyes, Evasion (creep) | You shouldn't be able to see this! WTF? |
| Shadow Of Chaos | `n01U` | 62000 | 80 hero | 8777–8777 | 0.4 | 60 | chaos | 350 | 595 / 200 | 0 | Boss Marker, Cleaving Attack (Creep), Divine Shield (creep), Immolation (creep) | You shouldn't be able to see this! WTF? |
| Demonic Assassin | `u018` | 62200 | 14 small | 9845–9941 | 0.6 | 128 | chaos | 440 | 0 / 0 | 0 | Ghost |  |
| Snowman Of Rage | `n04H` | 68000 | 75 hero | 4750–4750 | 0.55 | 60 | chaos | 360 | 595 / 200 | 0 | Boss Marker, Bladestorm [Sno], Pulverize (Sea Giant) | You shouldn't be able to see this! WTF? |
| Lt Stealer | `n00N` | 77650 | 35 hero | 3142–3172 | 0.3 | 80 | siege | 270 | 170 / 20 | 0 | Boss Marker, Critical Strike (creep), Evasion (creep), Divine Shield (creep), Vampiric Aura (creep) | You shouldn't be able to see this! WTF? |
| Demonic General | `u019` | 78750 | 24 large | 20619–20703 | 0.85 | 128 | chaos | 340 | 0 / 0 | 0 | Aura - War Drums |  |
| Mozaic Golem | `n01C` | 82000 | 120 hero | 23645–23675 | 0.4 | 60 | chaos | 270 | 85 / 0 | 0 | Boss Marker, Bash (creep), Critical Strike (creep), Evasion (creep), Mana Shield(Creep) | You shouldn't be able to see this! WTF? |
| Archfiend Hellion | `n04C` | 82000 | 20 medium | 19350–19360 | 0.85 | 60 | chaos | 500 | 435 / 150 | 0 | Attach - Black / Purple Hands, Attach - AuraOfDeath |  |
| Elder Muur Vu | `n02P` | 82500 | 100 hero | 12918–12936 | 0.11 | 60 | chaos | 360 | 170 / 20 | 0 | Boss Marker, Critical Strike (creep), Venom Spears (Creep) | You shouldn't be able to see this! WTF? |
| Baneful Angel | `n021` | 85415 | 95 hero | 10000–10000 | 1.75 | 60 | magic | 300 | 595 / 200 | 8 | Boss Marker, Ghost | You shouldn't be able to see this! WTF? |
| Divine | `n01Y` | 87000 | 125 hero | 21005–21035 | 0.45 | 60 | chaos | 270 | 85 / 0 | 0 | Boss Marker, Evasion (creep), Divine Shield (creep), Mana Shield(Creep), Attach - Rainbow Staff, Bash (creep) | You shouldn't be able to see this! WTF? |
| Voortr'hal | `n011` | 87532 | 115 hero | 48–81 | 1.5 | 500 | chaos / msplash 75 | 300 | 595 / 200 | 0 | Boss Marker, Evasion (creep), Divine Shield (creep), Pulverize (Sea Giant), Mountain King - Avatar | You shouldn't be able to see this! WTF? |
| Radioactive Worm | `n04M` | 88888 | 130 hero | 30008–30616 | 0.44 | 70 | chaos | 350 | 255 / 0 | 0 | Boss Marker, Evasion (creep) | You shouldn't be able to see this! WTF? |
| Demonic Siege Golem | `u01B` | 94000 | 21 fort | 56741–56877 | 2.6 | 128 | siege | 240 | 0 / 0 | 0 |  |  |
| Jasfal | `n02B` | 98500 | 115 hero | 9015–9048 | 0.7 | 80 | siege | 350 | 595 / 200 | 0 | Critical Strike (creep), Pulverize (Sea Giant), Boss Marker | You shouldn't be able to see this! WTF? |
| Cursed Arthus | `n04O` | 100000 | 140 hero | 24873–25481 | 0.1 | 70 | chaos | 350 | 255 / 0 | 0 | Boss Marker, Cursed Arthus Helmet, Attach - Black / Purple Hands, Attach - Shadow Aura, Attach - AuraOfDeath, Attach - Grudge Aura, Attach - Shade Aura, Evasion (creep) | You shouldn't be able to see this! WTF? |
| Blooded Abomination | `n01Z` | 120000 | 110 small | 14860–14881 | 0.45 | 60 | chaos | 270 | 170 / 20 | 0 | Boss Marker, Endurance Aura, Unholy Frenzy (creep), Raise Abominations, Aura - Regeneration (Statue), Attach - Disease, Reincarnation (creep) | You shouldn't be able to see this! WTF? |
| The Trojan | `n00L` | 155000 | 150 hero | 12407–12784 | 0.3 | 100 | chaos | 522 | 340 / 100 | 0 | Boss Marker, Evasion (creep), Burning Fury | You shouldn't be able to see this! WTF? |
| The Najort | `n04E` | 205000 | 155 hero | 12012–12360 | 0.25 | 100 | chaos | 522 | 340 / 100 | 0 | Boss Marker, Evasion (creep), Attach - Devil's Aura, Pulverize (Sea Giant), Burning Fury | You shouldn't be able to see this! WTF? |
| Tyrant Commander Behemoth | `n03B` | 280000 | 160 hero | 19425–19435 | 0.25 | 75 | siege | 522 | 170 / 20 | 0 | Boss Marker, Magic Immunity, Critical Strike (creep), Evasion (creep), Burning Fury, Pulverize (Sea Giant), Tyrant Aura, Attach - Behemoth Wings, Attach - Black / Purple Hands, DefenseBonus (+10), Height | You shouldn't be able to see this! WTF? |
| Demonic Eternia | `n04G` | 450000 | 165 hero | 35000–35000 | 0.5 | 350 | normal / msplash | 425 | 0 / 0 | 8 | Boss Marker, Spell Damage Reduction 98%, Evasion (creep), Ghost | You shouldn't be able to see this! WTF? |

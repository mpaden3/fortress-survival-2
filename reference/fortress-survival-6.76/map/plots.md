# Original plots (districts) — analysis

Approximate, computed from the pathing grid + rasterized destructible blockers. Cells are 128×128 world units. Distance = walking route in cells to the nearest edge of each main spawn (centre/N/E/S/W). See `plots.json` for entrance coordinates.

| Plot | Rect cells | Buildable | Entrances | Widths (cells) | Nearest spawn (cells) | Centre | N | E | S | W | Water | Trees | Garrison |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| The Storage Room | 622 | 457 | 2 | 4.0, 4.0 | south (23.8) | 41.2 | 108.5 | 108.5 | 23.8 | 68.0 | 0.0 | 0.5 | 4× Civilan Recruit, 2× Paratrooper, 2× Sniper, 1× Item Vendor, 1× Medic, 1× Wizard |
| Summer Cottage Garden | 593 | 347 | 3 | 3.0, 3.0, 0.5 | east (43.2) | 92.8 | 50.0 | 43.2 | 161.8 | 161.0 | 27.2 | 3.8 | 2× Water Protector - [1], 2× Rocketeer, 1× Item Vendor, 1× Galadriel |
| The Courtyard | 462 | 334 | 1 | 4.0 | centre (59.0) | 59.0 | 76.2 | 62.5 | 128.0 | 127.2 | 0.0 | 0.2 | 2× Rocketeer, 2× Sniper, 1× Lt Barathrum, 1× Medic |
| Main Library | 480 | 321 | 2 | 3.0, 3.0 | centre (18.0) | 18.0 | 85.2 | 51.5 | 46.5 | 85.8 | 63.5 | 0.0 | 2× Sniper, 2× Rocketeer, 2× Civilan Recruit, 1× Alchemist, 1× Wizard, 1× z001 |
| The Security Room | 448 | 301 | 1 | 6.0 | east (45.8) | 47.8 | 85.5 | 45.8 | 116.8 | 116.0 | 0.0 | 0.0 | 9× Civilan Recruit, 6× Weak Barricade, 2× z001, 2× Medic, 2× Rocketeer, 1× Command Center |
| Military Garrison | 440 | 259 | 1 | 6.0 | south (50.2) | 101.8 | 167.5 | 169.0 | 50.2 | 71.0 | 0.0 | 0.0 | 4× Manned Turret - [1], 4× z001, 2× Paratrooper, 2× Medic, 2× Rocketeer, 1× Command Center |
| The Fort Harbor | 345 | 204 | 3 | 15.0, 4.0, 2.0 | east (54.5) | 94.2 | 162.0 | 54.5 | 63.0 | 162.5 | 16.1 | 2.0 | 6× Little Pirate, 1× Mercenary Tavern, 1× Brute Pirate, 1× Rocketeer, 1× z001, 1× Scurvy Pirate |
| Dominion Bank | 416 | 203 | 1 | 5.0 | east (18.5) | 43.8 | 111.5 | 18.5 | 109.0 | 112.0 | 0.0 | 0.0 | 9× Repair Mechanic, 5× Weak Barricade, 4× Security Enforcer, 4× Bank Merchant, 2× Sniper, 2× z001 |
| Broadfall Enclave | 230 | 194 | 1 | 4.0 | south (23.8) | 41.2 | 108.5 | 104.8 | 23.8 | 107.2 | 0.0 | 0.0 | 2× Sniper, 1× Medic, 1× Rocketeer |
| The Abandoned Village | 401 | 193 | 2 | 6.0, 4.0 | north (54.2) | 93.8 | 54.2 | 161.5 | 162.8 | 61.5 | 0.0 | 0.0 | 2× Medic, 2× Rocketeer, 2× Firebat, 1× Command Center, 1× Wizard |
| Elysium Square | 221 | 192 | 2 | 4.0, 2.0 | centre (18.2) | 18.2 | 85.5 | 85.5 | 46.8 | 82.2 | 0.0 | 0.0 | – |
| Malicious Den | 217 | 156 | 1 | 3.0 | centre (19.8) | 19.8 | 83.8 | 87.5 | 88.8 | 45.0 | 0.0 | 0.0 | 1× Rocketeer, 1× Medic |
| The Mail Room | 247 | 148 | 1 | 4.0 | west (41.0) | 48.5 | 114.2 | 116.2 | 87.5 | 41.0 | 0.0 | 0.5 | 3× z001, 2× Sniper, 1× Item Vendor, 1× Wizard, 1× Rocketeer, 1× Firebat |
| Bear Cave | 264 | 120 | 1 | 9.0 | north (23.5) | 80.2 | 23.5 | 86.2 | 149.0 | 145.8 | 0.0 | 50.8 | 1× Beorn |
| Woodlands | 152 | 112 | 2 | 9.5, 5.25 | south (32.8) | 89.5 | 156.8 | 154.2 | 32.8 | 76.2 | 12.8 | 0.0 | 2× Sniper |
| The Sanctum | 152 | 104 | 1 | 3.0 | east (22.8) | 80.2 | 145.5 | 22.8 | 96.8 | 148.5 | 0.0 | 0.0 | 2× Firebat, 1× Cidiaus The Wizard, 1× Rocketeer, 1× Medic |
| The Torture Chamber | 222 | 103 | 1 | 3.0 | centre (15.5) | 15.5 | 79.5 | 48.2 | 84.5 | 83.8 | 0.0 | 0.0 | 1× Torturer Kael, 1× Rocketeer, 1× Medic, 1× z001 |
| Shinkel Brewery | 126 | 93 | 1 | 2.0 | north (19.0) | 68.2 | 19.0 | 105.2 | 137.0 | 133.8 | 0.0 | 0.0 | 3× Rocketeer, 1× Mr. Shinkel, 1× Medic, 1× Boberto, 1× Firebat |
| The Hold | 112 | 91 | 1 | 3.0 | west (53.5) | 61.0 | 92.5 | 128.8 | 130.0 | 53.5 | 0.0 | 0.0 | 2× Sniper, 1× Flamer Fox |
| Acropolis | 110 | 90 | 1 | 3.0 | centre (24.8) | 24.8 | 92.5 | 92.5 | 90.0 | 40.0 | 0.0 | 0.0 | – |
| Sanctuary | 120 | 90 | 1 | 2.0 | north (50.2) | 60.5 | 50.2 | 128.0 | 129.2 | 79.5 | 0.0 | 0.0 | 3× Civilan Recruit, 1× Rocketeer, 1× Medic, 1× Firebat |
| The Nest | 120 | 88 | 1 | 2.0 | north (21.2) | 75.0 | 21.2 | 140.0 | 143.8 | 104.5 | 1.0 | 0.0 | – |
| Post Encampment | 104 | 87 | 1 | 3.0 | west (53.8) | 55.8 | 76.5 | 123.5 | 124.8 | 53.8 | 0.0 | 0.0 | 5× z001, 1× Sniper, 1× Medic, 1× Firebat |
| Deep Abyss | 135 | 84 | 1 | 3.0 | west (21.8) | 79.5 | 145.2 | 147.2 | 100.0 | 21.8 | 78.0 | 2.4 | – |
| Temple Of Boom | 117 | 84 | 1 | 2.0 | north (68.5) | 70.8 | 68.5 | 70.0 | 139.8 | 139.0 | 0.0 | 2.0 | 6× Repair Factory, 1× Alchemist |
| Terminal | 100 | 81 | 2 | 4.0, 3.0 | centre (65.0) | 65.0 | 132.8 | 68.5 | 70.5 | 133.2 | 0.0 | 0.0 | 1× z001, 1× Firebat, 1× Medic |
| A-20 Bravo | 99 | 80 | 1 | 2.0 | north (35.8) | 46.0 | 35.8 | 113.5 | 114.8 | 92.0 | 0.0 | 0.0 | – |
| Harborage | 98 | 78 | 1 | 3.0 | north (40.8) | 45.5 | 40.8 | 113.0 | 114.2 | 88.5 | 0.0 | 0.0 | – |
| Isolated Quarters | 90 | 72 | 1 | 2.0 | centre (41.2) | 41.2 | 108.5 | 108.5 | 66.0 | 105.2 | 0.0 | 0.0 | – |
| The Waterfall | 165 | 72 | 1 | 3.0 | west (54.8) | 62.2 | 88.2 | 130.0 | 131.2 | 54.8 | 80.2 | 0.0 | 1× Alchemist |
| The Retreat | 96 | 71 | 1 | 3.0 | south (22.8) | 80.0 | 147.2 | 97.8 | 22.8 | 145.5 | 0.0 | 0.5 | – |
| Haven | 90 | 70 | 2 | 3.0, 3.0 | centre (78.2) | 78.2 | 146.0 | 79.2 | 80.0 | 146.5 | 0.0 | 0.0 | – |
| Deserted Pit | 88 | 67 | 1 | 2.0 | south (40.2) | 97.0 | 164.8 | 83.2 | 40.2 | 163.0 | 0.0 | 0.0 | – |
| The Hideout | 110 | 67 | 1 | 2.0 | north (16.8) | 73.5 | 16.8 | 102.5 | 142.2 | 139.0 | 0.0 | 0.0 | 2× Sniper, 1× Sgt Zim |
| Desolated Refuge | 70 | 63 | 1 | 3.0 | south (20.2) | 77.0 | 144.2 | 141.8 | 20.2 | 105.5 | 0.0 | 0.0 | – |
| The Cemetery | 98 | 61 | 1 | 1.0 | west (42.0) | 99.8 | 165.5 | 167.5 | 81.2 | 42.0 | 0.0 | 1.8 | 1× Dead Warrior |
| The Tavern | 77 | 56 | 1 | 1.0 | east (26.0) | 83.5 | 94.8 | 26.0 | 150.0 | 151.8 | 0.0 | 0.0 | – |
| The Loft | 70 | 52 | 1 | 3.0 | centre (85.2) | 85.2 | 153.0 | 86.2 | 87.0 | 153.5 | 0.0 | 0.0 | – |
| Death Point | 72 | 51 | 1 | 2.0 | west (64.2) | 71.8 | 137.5 | 139.5 | 73.2 | 64.2 | 0.0 | 0.0 | 1× Rocketeer, 1× Medic |

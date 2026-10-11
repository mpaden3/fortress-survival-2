class_name SimConstants
## Fixed simulation settings shared by the simulation, presentation and tests.

## Simulation ticks per second. Game logic only ever advances in whole ticks.
const TICK_RATE := 30
const TICK_DELTA := 1.0 / TICK_RATE
## World units (meters) per build-grid cell. Maps are authored in cells.
const CELL_SIZE := 2.0

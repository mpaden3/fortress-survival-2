class_name BuildingDef
extends Resource
## Static data for one building type (one node of an upgrade tree). Files: data/defs/buildings/.

@export var id: StringName
@export var display_name: String
## Size in build cells; the placement cell is the footprint's top-left corner.
@export var footprint := Vector2i.ONE
## Root of an upgrade tree: the Survivor can place it directly. Others only via upgrades.
@export var placeable := false
@export var cost := 0
## Seconds to construct (or to upgrade into this building).
@export var build_time := 1.0
@export var max_hp := 100
## Buildings this one can be upgraded into, in place. More than one = a branch.
@export var upgrades: Array[StringName] = []

## Resource per minute this building earns its owner once built (mills).
@export var income_per_minute := 0.0
## Units this building can train (barracks), by UnitDef id.
@export var trains: Array[StringName] = []

@export_group("Attack")
## Attack range in cells (from the footprint centre); 0 = doesn't attack.
@export var attack_range := 0.0
@export var attack_damage := 0.0
## Scaled per enemy armor type by GameRules.damage_multipliers.
@export var damage_type := &"normal"
## Seconds between shots.
@export var attack_cooldown := 1.0
## Projectile speed in m/s; 0 = hits instantly.
@export var projectile_speed := 20.0
## Splash radius in cells around the impact; 0 = single target.
@export var splash_radius := 0.0
## Slow on hit: enemy speed multiplier (e.g. 0.5) for `slow_duration` seconds; 1 = none.
@export var slow_multiplier := 1.0
@export var slow_duration := 0.0


func build_ticks() -> int:
	return maxi(1, roundi(build_time * SimConstants.TICK_RATE))


func is_armed() -> bool:
	return attack_range > 0.0 and attack_damage > 0.0


func cooldown_ticks() -> int:
	return maxi(1, roundi(attack_cooldown * SimConstants.TICK_RATE))

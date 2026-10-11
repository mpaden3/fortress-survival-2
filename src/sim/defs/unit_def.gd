class_name UnitDef
extends Resource
## Static data for one trainable player unit (fighter, repairman). Files: data/defs/units/.
## Ranges are in cells, like towers.

@export var id: StringName
@export var display_name: String
@export var cost := 0
## Seconds to train at a building that lists it in `trains`.
@export var train_time := 5.0
@export var max_hp := 100.0
## Meters per second.
@export var speed := 4.0
## Body radius in meters.
@export var radius := 0.35
## For when enemies get damage types (shown in the HUD meanwhile).
@export var armor_type := &"medium"
## Idle units notice enemies (fighters) or damaged buildings (repairmen) this far away.
@export var sight_range := 6.0
## How far from its guard spot an idle fighter chases before giving up and walking back.
@export var leash_range := 8.0

@export_group("Attack")
## 0 = doesn't attack.
@export var attack_range := 0.0
@export var attack_damage := 0.0
@export var damage_type := &"normal"
## Seconds between hits.
@export var attack_cooldown := 1.0

@export_group("Repair")
## HP per second restored to own buildings (free); 0 = can't repair.
@export var repair_rate := 0.0


func is_fighter() -> bool:
	return attack_range > 0.0 and attack_damage > 0.0


func is_repairer() -> bool:
	return repair_rate > 0.0


func cooldown_ticks() -> int:
	return maxi(1, roundi(attack_cooldown * SimConstants.TICK_RATE))


func train_ticks() -> int:
	return maxi(1, roundi(train_time * SimConstants.TICK_RATE))

class_name ObjectState
## Generic save/load of an object's script variables as plain Variant data (var_to_bytes
## friendly): definition resources become {"@def": class, "id": id}, arrays and dictionaries
## are deep-copied. Used for entities and other plain-data simulation objects, so fields added
## later are saved without extra code.


## Script variables of `obj`, encoded. `skip` names are left out.
static func dump(obj: Object, skip: Array[String] = []) -> Dictionary:
	var out := {}
	for prop in obj.get_property_list():
		if not prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE or prop["name"] in skip:
			continue
		out[prop["name"]] = encode(obj.get(prop["name"]))
	return out


## Writes `data` (from dump) back into `obj`'s script variables, resolving defs via `defs`.
## Typed arrays and dictionaries are filled in place so their element types are kept.
static func load_into(obj: Object, data: Dictionary, defs: DefRegistry) -> void:
	for prop in obj.get_property_list():
		var name: String = prop["name"]
		if not prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE or not data.has(name):
			continue
		var value: Variant = decode(data[name], defs)
		var current: Variant = obj.get(name)
		if current is Array:
			(current as Array).assign(value)
		elif current is Dictionary:
			(current as Dictionary).assign(value)
		else:
			obj.set(name, value)


static func encode(value: Variant) -> Variant:
	if value is Resource:
		var script: Script = value.get_script()
		assert(script != null, "only definition resources can be saved")
		return {"@def": String(script.get_global_name()), "id": value.get("id") if "id" in value else &""}
	if value is Array:
		return (value as Array).map(func(v: Variant) -> Variant: return encode(v))
	if value is Dictionary:
		var out := {}
		for key: Variant in value:
			out[key] = encode(value[key])
		return out
	assert(not value is Object, "can't save object %s" % value)
	if typeof(value) >= TYPE_PACKED_BYTE_ARRAY:
		return value.duplicate()
	return value


static func decode(value: Variant, defs: DefRegistry) -> Variant:
	if value is Dictionary and value.has("@def"):
		var id: StringName = value["id"]
		match value["@def"]:
			"BuildingDef":
				return defs.building(id)
			"UnitDef":
				return defs.unit(id)
			"EnemyDef":
				return defs.enemy(id)
			"SurvivorDef":
				return defs.survivor
		assert(false, "unknown def type %s" % value["@def"])
		return null
	if value is Array:
		return (value as Array).map(func(v: Variant) -> Variant: return decode(v, defs))
	if value is Dictionary:
		var out := {}
		for key: Variant in value:
			out[key] = decode(value[key], defs)
		return out
	if typeof(value) >= TYPE_PACKED_BYTE_ARRAY:
		return value.duplicate()
	return value

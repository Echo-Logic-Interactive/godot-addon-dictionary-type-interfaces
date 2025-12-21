class_name ExtendableInterface

extends TypedDict

## Base class for all mod-friendly typed dictionary interfaces
##
## Extends TypedDict to support:[br]
## - Schema extension for mod compatibility[br]
## - Mod-specific data namespacing[br]
## - Configurable validation modes (STRICT/LOOSE)[br]
##
## [b]For Modders:[/b][br]
## - Use [method set_mod_data] and [method get_mod_data] to safely store custom data[br]
## - Call [method extend_schema] to register additional validated fields[br]
## - Access [member _data] directly in LOOSE mode for maximum flexibility[br]
##
## [b]For Game Developers:[/b][br]
## - Override [method _get_base_schema] instead of [method _get_schema][br]
## - Use LOOSE mode for player-facing data, STRICT for save integrity[br]
## - Export schemas with [SchemaExporter] for mod documentation[br]
##
## @tutorial(Modding Guide): res://docs/MODDING_API.md

## Dictionary of additional schema fields registered by mods or extensions
var _extended_schema: Dictionary = {}

## Validation mode for this interface instance
var _validation_mode: TypeInterfaces.ValidationMode = TypeInterfaces.ValidationMode.LOOSE


## Initialize with optional data and validation mode
## [br][br]
## [param initial_data]: Dictionary containing initial field values
## [param validation_mode]: STRICT (exact schema match) or LOOSE (allows extra fields)
func _init(
	initial_data: Dictionary = {},
	validation_mode: TypeInterfaces.ValidationMode = TypeInterfaces.ValidationMode.LOOSE
) -> void:
	_validation_mode = validation_mode
	var schema = _get_schema()

	if schema and not schema.is_empty():
		var is_strict = validation_mode == TypeInterfaces.ValidationMode.STRICT
		if not TypeInterfaces.validate(initial_data, schema, is_strict):
			push_error("Invalid data for %s" % get_class())
			return

	_data = initial_data.duplicate()


## Get the complete schema including base and extended fields
## [br][br]
## Returns a Dictionary where keys are field names and values are type strings
## (e.g., {"name": "String", "level": "int", "health": "float?"})
func _get_schema() -> Dictionary:
	var base_schema = _get_base_schema()
	base_schema.merge(_extended_schema)
	return base_schema


## Override this in child classes to define the base schema
## [br][br]
## This replaces the [method _get_schema] override pattern from TypedDict.
## Define your core interface fields here - extended fields are merged automatically.
## [br][br]
## [b]Example:[/b]
## [codeblock]
## func _get_base_schema() -> Dictionary:
##     return {
##         "name": "String",
##         "level": "int",
##         "health": "float?",  # Nullable for optional fields
##         "tags": "Array<String>"
##     }
## [/codeblock]
func _get_base_schema() -> Dictionary:
	return {}


## Extend the schema with additional fields (primarily for mods)
## [br][br]
## Allows mods to register new validated fields without modifying core code.
## Fields must follow the type string format (e.g., "String", "int", "float?", "Array<String>")
## [br][br]
## [b]Nested Interface Support:[/b]
## [br]
## You can use interface class names to create validated nested structures:
## [codeblock]
## player_data.extend_schema({
##     "custom_stats": "ICustomStats",  # Single nested interface
##     "abilities": "Array<IAbility>"   # Array of interfaces
## })
## [/codeblock]
## [br]
## [b]Using Dictionary Instead of Interfaces:[/b]
## [br]
## While you [i]can[/i] use "Dictionary" as a type, this opts out of type validation
## and provides less developer convenience. Other mods extending your data won't
## benefit from schema validation or auto-completion:
## [codeblock]
## # Less recommended - no validation for nested data
## player_data.extend_schema({
##     "custom_stats": "Dictionary"  # Unvalidated, loose structure
## })
##
## # Better - validated, extensible, auto-complete friendly
## player_data.extend_schema({
##     "custom_stats": "ICustomStats"  # Validated nested interface
## })
## [/codeblock]
## [br]
## [b]Trade-offs:[/b]
# JJDEV: [list] is not rendering properly in Godot docs, so using [br] for line breaks
## [list]
## [b]Dictionary type:[/b] ✓ Maximum flexibility, ✗ No validation,
## ✗ No auto-complete, ✗ Hard for other mods to extend[br]
## [b]Interface type:[/b] ✓ Validated, ✓ Auto-complete,
## ✓ Extensible by other mods, ✗ Requires interface definition[br]
## [/list]
## [br][br]
## [param additional_fields]: Dictionary mapping field names to type strings
func extend_schema(additional_fields: Dictionary) -> void:
	_extended_schema.merge(additional_fields)


## Safely store mod-specific data in a namespaced container
## [br][br]
## Prevents conflicts between mods and avoids validation errors in STRICT mode.
## Mod data is stored under a reserved "_mod_data" field that bypasses schema validation.
## [br][br]
## [param mod_id]: Unique identifier for your mod (e.g., "com.author.modname")
## [param key]: Data key within your mod's namespace
## [param value]: Any value to store
## [br][br]
## [b]Example:[/b]
## [codeblock]
## # Mod stores custom stat
## player_data.set_mod_data("com.coolmod.rpg", "mana", 100.0)
## player_data.set_mod_data("com.coolmod.rpg", "spells", ["fireball", "ice"])
## [/codeblock]
func set_mod_data(mod_id: String, key: String, value) -> void:
	# Initialize mod data container if it doesn't exist
	if not _data.has("_mod_data"):
		_data["_mod_data"] = {}

	var mod_data = _data["_mod_data"] as Dictionary

	# Initialize this mod's namespace if it doesn't exist
	if not mod_data.has(mod_id):
		mod_data[mod_id] = {}

	# Store the value
	mod_data[mod_id][key] = value


## Retrieve mod-specific data from the namespaced container
## [br][br]
## [param mod_id]: Unique identifier for the mod
## [param key]: Data key within the mod's namespace
## [param default]: Value to return if the key doesn't exist
## [br][br]
## [b]Example:[/b]
## [codeblock]
## var mana = player_data.get_mod_data("com.coolmod.rpg", "mana", 0.0)
## var spells = player_data.get_mod_data("com.coolmod.rpg", "spells", [])
## [/codeblock]
func get_mod_data(mod_id: String, key: String, default = null):
	var mod_data = _data.get("_mod_data", {}) as Dictionary
	return mod_data.get(mod_id, {}).get(key, default)


## Check if a mod has stored any data
## [br][br]
## [param mod_id]: Unique identifier for the mod
func has_mod_data(mod_id: String) -> bool:
	var mod_data = _data.get("_mod_data", {}) as Dictionary
	return mod_data.has(mod_id)


## Get all data for a specific mod
## [br][br]
## [param mod_id]: Unique identifier for the mod
## Returns a Dictionary of all key-value pairs stored by that mod
func get_all_mod_data(mod_id: String) -> Dictionary:
	var mod_data = _data.get("_mod_data", {}) as Dictionary
	return mod_data.get(mod_id, {}).duplicate()


## Clear all data for a specific mod
## [br][br]
## [param mod_id]: Unique identifier for the mod
func clear_mod_data(mod_id: String) -> void:
	var mod_data = _data.get("_mod_data", {}) as Dictionary
	if mod_data.has(mod_id):
		mod_data.erase(mod_id)


## Get a list of all mod IDs that have stored data
func get_registered_mods() -> Array[String]:
	var mod_data = _data.get("_mod_data", {}) as Dictionary
	var result: Array[String] = []
	for mod_id in mod_data.keys():
		result.append(mod_id)
	return result


## Override set_value to respect validation mode
## [br][br]
## In LOOSE mode, validation only warns. In STRICT mode, validation fails with assertion.
## Automatically converts Dictionaries to interface instances when the schema specifies an interface type.
func set_value(key: String, value) -> void:
	var schema = _get_schema()

	# Check if this field expects an interface type and convert if needed
	if schema.has(key):
		var type_string = schema[key] as String
		var clean_type = type_string.replace("?", "").strip_edges()

		# Handle nested interface conversion
		if _is_interface_type(clean_type) and value is Dictionary:
			value = _convert_to_interface(clean_type, value)
		# Handle Array<InterfaceType>
		elif clean_type.begins_with("Array<") and clean_type.ends_with(">"):
			var element_type = clean_type.substr(6, clean_type.length() - 7)
			if _is_interface_type(element_type) and value is Array:
				value = _convert_array_to_interfaces(element_type, value)

	_data[key] = value

	if schema and not schema.is_empty():
		var is_strict = _validation_mode == TypeInterfaces.ValidationMode.STRICT
		var is_valid = TypeInterfaces.validate(_data, schema, is_strict)

		if not is_valid:
			if _validation_mode == TypeInterfaces.ValidationMode.STRICT:
				ErrorHandler.push_error("Invalid data after setting %s in STRICT mode" % key)
				_data.erase(key)  # Rollback change
			else:
				ErrorHandler.push_warning("Validation warning after setting %s in LOOSE mode" % key)


## Override update to respect validation mode
## [br][br]
## In LOOSE mode, validation only warns. In STRICT mode, validation fails with assertion.
func update(data: Dictionary) -> void:
	var backup = _data.duplicate()
	_data.merge(data, true)

	var schema = _get_schema()
	if schema and not schema.is_empty():
		var is_strict = _validation_mode == TypeInterfaces.ValidationMode.STRICT
		var is_valid = TypeInterfaces.validate(_data, schema, is_strict)

		if not is_valid:
			if _validation_mode == TypeInterfaces.ValidationMode.STRICT:
				ErrorHandler.push_error("Invalid data after update in STRICT mode")
				_data = backup  # Rollback changes
			else:
				ErrorHandler.push_warning("Validation warning after update in LOOSE mode")


# ==============================================================================
# NESTED INTERFACE SUPPORT
# ==============================================================================


## Check if a type string represents an interface class
## [br][br]
## [param type_string]: Type name to check (e.g., "IPlayerData", "ICustomStats")
## [br]
## Returns true if the type appears to be an interface class
func _is_interface_type(type_string: String) -> bool:
	# Check if it starts with 'I' (interface naming convention)
	if not type_string.begins_with("I"):
		return false

	# Try to verify the interface file exists
	var script_path = "res://scripts/interfaces/%s.gd" % type_string
	return FileAccess.file_exists(script_path)


## Convert a Dictionary to an interface instance
## [br][br]
## [param interface_name]: Name of the interface class (e.g., "ICustomStats")
## [param data]: Dictionary data to initialize the interface with
## [br]
## Returns an instance of the interface, or null if conversion fails
func _convert_to_interface(interface_name: String, data: Dictionary):
	var script_path = "res://scripts/interfaces/%s.gd" % interface_name

	if not FileAccess.file_exists(script_path):
		ErrorHandler.push_error(
			"[ExtendableInterface] Interface class not found: %s" % interface_name
		)
		return null

	var interface_script = load(script_path)
	if not interface_script:
		ErrorHandler.push_error(
			"[ExtendableInterface] Failed to load interface: %s" % interface_name
		)
		return null

	# Create instance with same validation mode as parent
	var instance = interface_script.new(data, _validation_mode)
	return instance


## Convert an Array of Dictionaries to an Array of interface instances
## [br][br]
## [param interface_name]: Name of the interface class for array elements
## [param array]: Array containing Dictionaries or interface instances
## [br]
## Returns an Array of interface instances
func _convert_array_to_interfaces(interface_name: String, array: Array) -> Array:
	var result: Array = []

	for item in array:
		if item is Dictionary:
			var instance = _convert_to_interface(interface_name, item)
			if instance:
				result.append(instance)
		elif _is_interface_instance(item, interface_name):
			# Already an interface instance
			result.append(item)
		else:
			ErrorHandler.push_warning(
				"[ExtendableInterface] Invalid item type in Array<%s>" % interface_name
			)

	return result


## Check if a value is an instance of a specific interface
## [br][br]
## [param value]: The value to check
## [param interface_name]: Expected interface class name
## [br]
## Returns true if the value is an instance of the specified interface
func _is_interface_instance(value, interface_name: String) -> bool:
	if not is_instance_valid(value):
		return false

	# Check if it's an object with the expected class name
	if value is Object:
		return value.get_class() == interface_name

	return false

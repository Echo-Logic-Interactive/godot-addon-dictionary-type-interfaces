extends Node

## Modding API for third-party extensions
##
## Provides utilities for mods to:
## - Register custom validators
## - Extend game interfaces
## - Hook into game events
## - Register custom content
##
## [b]Usage for Modders:[/b]
## [codeblock]
## # In your mod's initialization
## func _ready():
##     # Register a custom validator
##     ModdingAPI.register_validator("IPlayerData", _validate_player_mod_data)
##
##     # Extend an interface schema
##     ModdingAPI.extend_interface_schema("IPlayerData", {
##         "stamina": "float",
##         "mana": "float"
##     })
##
## func _validate_player_mod_data(data: Dictionary) -> bool:
##     # Custom validation logic
##     if data.has("stamina"):
##         return data["stamina"] >= 0.0
##     return true
## [/codeblock]
##
## @tutorial(Modding Guide): res://docs/MODDING_API.md

## Dictionary of interface schema extensions:
## interface_name -> Dictionary[field_name -> type_string]
var _interface_extensions: Dictionary = {}

## Dictionary of custom validators: interface_name -> Array[Callable]
var _custom_validators: Dictionary = {}

## Dictionary of registered interface schema extensions
var _schema_extensions: Dictionary = {}

## Dictionary of mod metadata
var _registered_mods: Dictionary = {}


## Register a custom validator for an interface
## [br][br]
## Validators are called after the base interface validation.
## Multiple validators can be registered for the same interface.
## [br][br]
## [param interface_name]: Name of the interface class (e.g., "IPlayerData")
## [param validator]: Callable that takes (data: Dictionary) and returns bool
## [br][br]
## [b]Example:[/b]
## [codeblock]
## ModdingAPI.register_validator("IPlayerData", func(data: Dictionary) -> bool:
##     if data.has("custom_field"):
##         return data["custom_field"] > 0
##     return true
## )
## [/codeblock]
func register_validator(interface_name: String, validator: Callable) -> void:
	if not _custom_validators.has(interface_name):
		_custom_validators[interface_name] = []

	_custom_validators[interface_name].append(validator)
	print("[ModdingAPI] Registered validator for %s" % interface_name)


## Validate data with registered custom validators
## [br][br]
## [param interface_name]: Name of the interface class
## [param data]: Data dictionary to validate
## [br]
## Returns true if all custom validators pass, false otherwise
func validate_with_mods(interface_name: String, data: Dictionary) -> bool:
	if not _custom_validators.has(interface_name):
		return true  # No custom validators, validation passes

	for validator in _custom_validators[interface_name]:
		if not validator.call(data):
			push_error("[ModdingAPI] Custom validator failed for %s" % interface_name)
			return false

	return true


## Extend an interface schema globally (affects all new instances)
## [br][br]
## This registers fields that will be added to all new instances of the interface.
## Useful for mods that want to add fields to core game data structures.
## [br][br]
## [b]Nested Interface Support:[/b]
## [br]
## You can use interface class names for validated nested structures:
## [codeblock]
## ModdingAPI.extend_interface_schema("IPlayerData", {
##     "custom_stats": "ICustomStats",  # Nested interface
##     "abilities": "Array<IAbility>"   # Array of interfaces
## })
## [/codeblock]
## [br]
## [b]Dictionary vs Interface Types:[/b]
## [br]
## While "Dictionary" is valid, using interface types provides better validation
## and allows other mods to safely extend your data:
## [codeblock]
## # Works, but less recommended
## ModdingAPI.extend_interface_schema("IPlayerData", {
##     "custom_stats": "Dictionary"  # Unvalidated
## })
##
## # Better - validated and extensible
## ModdingAPI.extend_interface_schema("IPlayerData", {
##     "custom_stats": "ICustomStats"  # Validated, auto-complete friendly
## })
## [/codeblock]
## [br][br]
## [param interface_name]: Name of the interface to extend (e.g., "IPlayerData")
## [param schema_fields]: Dictionary mapping field names to type strings
func extend_interface_schema(interface_name: String, schema_fields: Dictionary) -> void:
	if not _interface_extensions.has(interface_name):
		_interface_extensions[interface_name] = {}

	_interface_extensions[interface_name].merge(schema_fields)

	print(
		(
			"[ModdingAPI] Extended schema for %s with %d fields"
			% [interface_name, schema_fields.size()]
		)
	)


## Get schema extensions for an interface
## [br][br]
## [param interface_name]: Name of the interface class
## Returns a Dictionary of extended fields
func get_schema_extensions(interface_name: String) -> Dictionary:
	return _schema_extensions.get(interface_name, {}).duplicate()


## Register mod metadata for tracking and compatibility
## [br][br]
## [param mod_id]: Unique identifier for the mod (e.g., "com.author.modname")
## [param metadata]: Dictionary containing mod info (name, version, author, dependencies, etc.)
## [br][br]
## [b]Example:[/b]
## [codeblock]
## ModdingAPI.register_mod("com.coolauthor.awesomemod", {
##     "name": "Awesome Mod",
##     "version": "1.0.0",
##     "author": "CoolAuthor",
##     "description": "Adds cool features",
##     "dependencies": ["com.another.requiredmod"]
## })
## [/codeblock]
func register_mod(mod_id: String, metadata: Dictionary) -> void:
	_registered_mods[mod_id] = metadata
	print(
		(
			"[ModdingAPI] Registered mod: %s v%s"
			% [metadata.get("name", mod_id), metadata.get("version", "unknown")]
		)
	)


## Get metadata for a registered mod
## [br][br]
## [param mod_id]: Unique identifier for the mod
func get_mod_metadata(mod_id: String) -> Dictionary:
	return _registered_mods.get(mod_id, {}).duplicate()


## Get all registered mod IDs
func get_registered_mod_ids() -> Array[String]:
	var result: Array[String] = []
	for mod_id in _registered_mods.keys():
		result.append(mod_id)
	return result


## Check if a mod is registered
## [br][br]
## [param mod_id]: Unique identifier for the mod
func is_mod_registered(mod_id: String) -> bool:
	return _registered_mods.has(mod_id)


## Check if all dependencies for a mod are met
## [br][br]
## [param mod_id]: Unique identifier for the mod
## Returns true if all dependencies are registered, false otherwise
func check_dependencies(mod_id: String) -> bool:
	var metadata = get_mod_metadata(mod_id)
	var dependencies = metadata.get("dependencies", []) as Array

	for dependency in dependencies:
		if not is_mod_registered(dependency):
			push_warning(
				(
					"[ModdingAPI] Mod '%s' missing dependency: %s"
					% [metadata.get("name", mod_id), dependency]
				)
			)
			return false

	return true


## Export all registered mod information to JSON
## [br][br]
## [param output_path]: File path to write the JSON data
func export_mod_registry(output_path: String) -> bool:
	var registry = {"mods": _registered_mods, "schema_extensions": _schema_extensions}

	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("[ModdingAPI] Failed to open file for writing: %s" % output_path)
		return false

	file.store_string(JSON.stringify(registry, "\t"))
	file.close()

	print("[ModdingAPI] Exported mod registry to %s" % output_path)
	return true

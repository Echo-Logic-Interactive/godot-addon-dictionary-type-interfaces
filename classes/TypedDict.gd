@tool
class_name TypedDict

extends RefCounted

## Base class for all typed dictionary interfaces
## Provides automatic validation and type safety for dictionary-based data structures

var _data: Dictionary = {}


## Get TypeInterfaces singleton (handles both editor and headless mode)
static func _get_type_interfaces():
	if Engine.has_singleton("TypeInterfaces"):
		return Engine.get_singleton("TypeInterfaces")

		# In headless/CI mode, load manually
	var runtime_script = load("res://src/type_interfaces_runtime.gd")
	if runtime_script:
		return runtime_script.new()

	return null


func _init(initial_data: Dictionary = {}) -> void:
	var schema = _get_schema()
	if schema and not schema.is_empty():
		if not _validate(initial_data):
			# Validation already logged the specific error
			return
	_data = initial_data.duplicate()


## Override this in child classes to define the schema
func _get_schema() -> Dictionary:
	return {}


## Validate a dictionary where keys are dynamic but values must match a type/interface
func _validate_dynamic_dict(data: Dictionary, value_type) -> bool:
	var type_interfaces = _get_type_interfaces()

	for key in data:
		var value = data[key]

		# If value_type is a string, it's an interface name
		if value_type is String:
			if type_interfaces:
				var result = type_interfaces.validate_interface(value, value_type)
				if not result.is_valid:
					push_warning("Key '%s': %s" % [key, result.message])
					return false
			continue

		# If value_type is a TYPE_* constant
		if value_type is int:
			if typeof(value) != value_type:
				push_warning(
					(
						"Key '%s': Expected type %s, got %s"
						% [key, type_string(value_type), type_string(typeof(value))]
					)
				)
				return false
			continue

	return true


## Internal validation method that handles both static and dynamic schemas
func _validate(data: Dictionary) -> bool:
	var schema = _get_schema()

	# Check if this is a dynamic dictionary schema (single key that's a TYPE_* constant)
	if schema.size() == 1:
		var key_type = schema.keys()[0]
		var value_type = schema[key_type]

		# Dynamic dict patterns: {TYPE_STRING: "InterfaceName"} or {TYPE_INT: TYPE_STRING}
		# Check if key_type is a Variant.Type constant (0-27 range)
		if typeof(key_type) == TYPE_INT and key_type >= TYPE_NIL and key_type <= TYPE_MAX:
			return _validate_dynamic_dict(data, value_type)

	# Otherwise, use normal TypeInterfaces validation
	var type_interfaces = _get_type_interfaces()
	if type_interfaces:
		var context = get_script().resource_path.get_file()
		return type_interfaces.validate(data, schema, false, context)
	return true


## Get a value with type safety
func get_value(key: String, default_value = null):
	if _data.has(key):
		return _data[key]
	return default_value


## Get the entire data dictionary
func to_dict() -> Dictionary:
	return _data.duplicate()


## Set a value and validate
func set_value(key: String, value) -> void:
	_data[key] = value
	var schema = _get_schema()
	if schema and not schema.is_empty():
		if not _validate(_data):
			# Validation failed, rollback
			_data.erase(key)


## Update multiple fields at once
func update(data: Dictionary) -> void:
	var backup = _data.duplicate()
	_data.merge(data, true)
	var schema = _get_schema()
	if schema and not schema.is_empty():
		if not _validate(_data):
			# Validation failed, rollback
			_data = backup

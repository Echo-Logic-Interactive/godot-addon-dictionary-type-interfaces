@tool
class_name TypedDict

extends RefCounted

## Base class for all typed dictionary interfaces
## Provides automatic validation and type safety for dictionary-based data structures

var _data: Dictionary = {}


func _init(initial_data: Dictionary = {}) -> void:
	var schema = _get_schema()
	if schema and not schema.is_empty():
		assert(TypeInterfaces.validate(initial_data, schema), "Invalid data for " + get_class())
	_data = initial_data.duplicate()


## Override this in child classes to define the schema
func _get_schema() -> Dictionary:
	return {}


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
		assert(TypeInterfaces.validate(_data, schema), "Invalid data after setting " + key)


## Update multiple fields at once
func update(data: Dictionary) -> void:
	_data.merge(data, true)
	var schema = _get_schema()
	if schema and not schema.is_empty():
		assert(TypeInterfaces.validate(_data, schema), "Invalid data after update")

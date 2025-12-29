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


## Internal validation method
func _validate(data: Dictionary) -> bool:
	var schema = _get_schema()
	var type_interfaces = _get_type_interfaces()
	if type_interfaces:
		var context = get_script().resource_path.get_file()
		return type_interfaces.validate(data, schema, false, context)
	return true


## Get a value with type safety
## Automatically converts dictionaries to Vector types when needed (e.g., from JSON)
## Also wraps plain dictionaries in interface classes when schema expects them
func get_value(key: String, default_value = null):
	if _data.has(key):
		var value = _data[key]
		var schema = _get_schema()
		var expected_type = schema.get(key, "")

		# Auto-convert dictionaries to Vector types (handles JSON deserialization)
		if (
			value is Dictionary
			and (
				expected_type
				in ["Vector2i", "Vector2", "Vector3i", "Vector3", "Vector4", "Vector4i", "Color"]
			)
		):
			return _dict_to_vector(value, expected_type)

		# Auto-wrap dictionaries in interface classes
		if value is Dictionary and _is_interface_type(expected_type):
			return _wrap_in_interface(value, expected_type)

		# Auto-wrap arrays of dictionaries in interface classes
		if value is Array and _is_array_of_interfaces(expected_type):
			return _wrap_array_in_interfaces(value, expected_type)

		return value
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


## Convert a dictionary to a Vector type (handles JSON deserialization)
func _dict_to_vector(dict: Dictionary, type_string: String):
	match type_string:
		"Vector2i":
			return Vector2i(dict.get("x", 0), dict.get("y", 0))
		"Vector2":
			return Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
		"Vector3i":
			return Vector3i(dict.get("x", 0), dict.get("y", 0), dict.get("z", 0))
		"Vector3":
			return Vector3(dict.get("x", 0.0), dict.get("y", 0.0), dict.get("z", 0.0))
		"Vector4":
			return Vector4(
				dict.get("x", 0.0), dict.get("y", 0.0), dict.get("z", 0.0), dict.get("w", 0.0)
			)
		"Vector4i":
			return Vector4i(dict.get("x", 0), dict.get("y", 0), dict.get("z", 0), dict.get("w", 0))
		"Color":
			return Color(
				dict.get("r", 1.0), dict.get("g", 1.0), dict.get("b", 1.0), dict.get("a", 1.0)
			)
		_:
			# gdlint: ignore=max-returns
			return dict


## Check if a type string represents an interface class (starts with I and is a valid class)
func _is_interface_type(type_string: String) -> bool:
	if type_string.is_empty():
		return false
	# Remove nullable marker
	var clean_type = type_string.trim_suffix("?")
	# Check if it's a class name (starts with I or is a known interface)
	return ClassDB.class_exists(clean_type) or _try_load_class(clean_type) != null


## Check if type string represents Array<IInterfaceName>
func _is_array_of_interfaces(type_string: String) -> bool:
	if not type_string.begins_with("Array"):
		return false
	# Extract inner type: Array<ITileInstance> -> ITileInstance
	var regex = RegEx.new()
	regex.compile("Array<(.+?)>")
	var result = regex.search(type_string)
	if result:
		var inner_type = result.get_string(1)
		return _is_interface_type(inner_type)
	return false


## Wrap a dictionary in the appropriate interface class
func _wrap_in_interface(dict: Dictionary, type_string: String):
	var clean_type = type_string.trim_suffix("?")
	var interface_class = _try_load_class(clean_type)
	if interface_class:
		return interface_class.new(dict)
	return dict


## Wrap an array of dictionaries in interface classes
func _wrap_array_in_interfaces(array: Array, type_string: String) -> Array:
	# Extract inner type: Array<ITileInstance> -> ITileInstance
	var regex = RegEx.new()
	regex.compile("Array<(.+?)>")
	var result = regex.search(type_string)
	if not result:
		return array

	var inner_type = result.get_string(1)
	var interface_class = _try_load_class(inner_type)
	if not interface_class:
		return array

	var wrapped_array: Array = []
	for item in array:
		if item is Dictionary:
			wrapped_array.append(interface_class.new(item))
		else:
			wrapped_array.append(item)

	return wrapped_array


## Try to load a class by name (handles both built-in and custom classes)
func _try_load_class(class_name_str: String):
	# First check if it's already loaded as a class_name
	if ClassDB.class_exists(class_name_str):
		return ClassDB.instantiate(class_name_str)

	# Try to load as a script resource
	var script_path = "res://scripts/interfaces/%s.gd" % class_name_str
	if ResourceLoader.exists(script_path):
		return load(script_path)

	# Try common subdirectories
	var subdirs = ["tiles", "world", "entities", "player", "ui"]
	for subdir in subdirs:
		script_path = "res://scripts/interfaces/%s/%s.gd" % [subdir, class_name_str]
		if ResourceLoader.exists(script_path):
			return load(script_path)

	return null

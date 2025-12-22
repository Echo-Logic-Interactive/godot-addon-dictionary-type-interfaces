@tool
extends Node

## Runtime type interface validation and helpers
## Accessible via TypeInterfaces singleton

enum ValidationMode {
	STRICT,  # All fields must match exactly
	LOOSE,  # Dictionary can have extra fields
}

## Get the interfaces directory from project settings
var interface_dir = (
	preload("res://addons/type_interfaces/classes/SchemaExporter.gd").get_interfaces_directory()
)


## Validate a dictionary against an interface definition
## [br][br]
## [param context]: Optional context string (e.g., class name or file path) to include in
## error messages
# gdLint: ignore=max-returns
func validate(
	data: Dictionary, interface_def: Dictionary, strict: bool = false, context: String = ""
) -> bool:
	# Skip validation entirely in release builds for zero overhead
	if not OS.is_debug_build():
		return true

	if interface_def.is_empty():
		push_warning("Interface definition is empty")
		return false

	var mode = ValidationMode.STRICT if strict else ValidationMode.LOOSE
	var ctx_prefix = (" in %s" % context) if context else ""

	# Get calling location from stack trace
	var stack = get_stack()
	var caller_info = ""
	if stack.size() > 2:  # Skip validate() and its caller, get the actual source
		var caller = stack[2]
		var line_num = caller.get("line", 0)
		var source_file = caller.get("source", "").get_file()
		if source_file:
			caller_info = "\n  Called from: %s:%d" % [source_file, line_num]

	# Check all required fields exist
	for field_name in interface_def.keys():
		if not data.has(field_name):
			var data_snippet = _get_data_snippet(data, field_name)
			push_error(
				(
						"Missing required field: %s%s%s\n  Data: %s"
						% [field_name, ctx_prefix, caller_info, data_snippet]
					)
				)
			return false

		# Type check
		var expected_type = interface_def[field_name]
		var actual_value = data[field_name]

		if not _check_type(actual_value, expected_type):
			var data_snippet = _get_data_snippet(data, field_name)
			push_error(
				(
					"Type mismatch for field '%s': expected %s, got %s%s%s\n  Data: %s"
					% [
						field_name,
						expected_type,
						_get_type_name(actual_value),
						ctx_prefix,
						caller_info,
						data_snippet
					]
				)
			)
			return false

	# In strict mode, check for extra fields
	if mode == ValidationMode.STRICT:
		for field_name in data.keys():
			if not interface_def.has(field_name):
				var data_snippet = _get_data_snippet(data, field_name)
				push_error(
					(
						"Unexpected field in strict mode: %s%s%s\n  Data: %s"
						% [field_name, ctx_prefix, caller_info, data_snippet]
					)
				)
				return false

	return true


## Create a typed dictionary helper
func create(interface_def: Dictionary) -> Dictionary:
	var result = {}
	for field_name in interface_def.keys():
		result[field_name] = null
	return result


## Check if a value matches the expected type
# gdLint: ignore=max-returns
func _check_type(value: Variant, expected_type: String) -> bool:
	# Handle nullable types (Type?)
	if expected_type.ends_with("?"):
		if value == null:
			return true
		expected_type = expected_type.substr(0, expected_type.length() - 1)
	elif value == null:
		return false

	# Array types (Array<Type>)
	if expected_type.begins_with("Array<") and expected_type.ends_with(">"):
		if typeof(value) != TYPE_ARRAY:
			return false

		var element_type = expected_type.substr(6, expected_type.length() - 7)
		for item in value:
			if not _check_type(item, element_type):
				return false
		return true

	# Dictionary types
	if expected_type == "Dictionary":
		return typeof(value) == TYPE_DICTIONARY

	# Interface types (e.g., IPlayerData, ICustomStats)
	if _is_interface_type(expected_type):
		return _is_interface_instance(value, expected_type)

	# Basic type matching
	var type_name = _get_type_name(value)

	# gdlint: disable=max-returns
	return type_name == expected_type or _is_compatible_type(type_name, expected_type)


## Get the type name of a value
func _get_type_name(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR2I:
			return "Vector2i"
		TYPE_RECT2:
			return "Rect2"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_TRANSFORM2D:
			return "Transform2D"
		TYPE_VECTOR4:
			return "Vector4"
		TYPE_PLANE:
			return "Plane"
		TYPE_QUATERNION:
			return "Quaternion"
		TYPE_AABB:
			return "AABB"
		TYPE_BASIS:
			return "Basis"
		TYPE_TRANSFORM3D:
			return "Transform3D"
		TYPE_PROJECTION:
			return "Projection"
		TYPE_COLOR:
			return "Color"
		TYPE_STRING_NAME:
			return "StringName"
		TYPE_NODE_PATH:
			return "NodePath"
		TYPE_RID:
			return "RID"
		TYPE_OBJECT:
			if value == null:
				return "null"
			return value.get_class()
		TYPE_CALLABLE:
			return "Callable"
		TYPE_SIGNAL:
			return "Signal"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_ARRAY:
			return "Array"
		TYPE_PACKED_BYTE_ARRAY:
			return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY:
			return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY:
			return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY:
			return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY:
			return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY:
			return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY:
			return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY:
			return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY:
			return "PackedColorArray"
		_:
			# gdlint: disable=max-returns
			return "Unknown"


## Get a snippet of data around a specific field for error messages
func _get_data_snippet(data: Dictionary, focus_field: String) -> String:
	var keys = data.keys()
	var focus_idx = keys.find(focus_field)

	if focus_idx == -1:
		# Field doesn't exist, show first few fields
		var snippet_keys = keys.slice(0, 3)
		var parts: Array[String] = []
		for key in snippet_keys:
			parts.append('"%s": %s' % [key, _value_to_string(data[key])])
		return "{%s, ...}" % ", ".join(parts)

	# Show field before, the focus field, and field after
	var start_idx = max(0, focus_idx - 1)
	var end_idx = min(keys.size() - 1, focus_idx + 1)

	var parts: Array[String] = []
	if start_idx > 0:
		parts.append("...")

	for i in range(start_idx, end_idx + 1):
		var key = keys[i]
		var prefix = ">> " if key == focus_field else "   "
		parts.append('%s"%s": %s' % [prefix, key, _value_to_string(data[key])])

	if end_idx < keys.size() - 1:
		parts.append("...")

	return "{\n    %s\n  }" % "\n    ".join(parts)


## Convert a value to a short string representation for error messages
func _value_to_string(value) -> String:
	if value == null:
		return "null"

	if value is String:
		var s = str(value)
		if s.length() > 20:
			return '"%s..."' % s.substr(0, 17)
		return '"%s"' % s

	if value is Array:
		return "[...%d items]" % value.size()

	if value is Dictionary:
		return "{...%d keys}" % value.size()

	var s = str(value)
	if s.length() > 20:
		return "%s..." % s.substr(0, 17)
	return s


## Check if types are compatible (e.g., int can be float)
func _is_compatible_type(actual: String, expected: String) -> bool:
	# int can be used as float
	if actual == "int" and expected == "float":
		return true

	# Int/Float alternative capitalization
	if actual.to_lower() == expected.to_lower():
		return true

	return false


## Check if a type string represents an interface class
## [br][br]
## [param type_string]: Type name to check (e.g., "IPlayerData")
## [br]
## Returns true if the type appears to be an interface class
func _is_interface_type(type_string: String) -> bool:
	# Interface naming convention: starts with 'I'
	if not type_string.begins_with("I"):
		return false

	# Verify the interface file exists
	var script_path = interface_dir + "%s.gd" % type_string
	return FileAccess.file_exists(script_path)


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

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
# gdLint: ignore=max-returns
func validate(data: Dictionary, interface_def: Dictionary, strict: bool = false) -> bool:
	if interface_def.is_empty():
		push_warning("Interface definition is empty")
		return false

	var mode = ValidationMode.STRICT if strict else ValidationMode.LOOSE

	# Check all required fields exist
	for field_name in interface_def.keys():
		if not data.has(field_name):
			push_error("Missing required field: %s" % field_name)
			return false

		# Type check
		var expected_type = interface_def[field_name]
		var actual_value = data[field_name]

		if not _check_type(actual_value, expected_type):
			push_error(
				(
					"Type mismatch for field '%s': expected %s, got %s"
					% [field_name, expected_type, _get_type_name(actual_value)]
				)
			)
			return false

	# In strict mode, check for extra fields
	if mode == ValidationMode.STRICT:
		for field_name in data.keys():
			if not interface_def.has(field_name):
				push_error("Unexpected field in strict mode: %s" % field_name)
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

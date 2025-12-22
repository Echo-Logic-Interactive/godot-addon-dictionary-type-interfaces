class_name SchemaExporter

extends RefCounted

## Utility for exporting interface schemas to JSON for mod documentation
##
## Provides tools to export schema definitions in a format that's easy for
## modders to reference. Includes type information, optional fields, and
## base vs. extended schema separation.
##
## [b]Configuration:[/b][br]
## Set your interfaces directory in Project Settings:[br]
## Project → Project Settings → General → Application → Type Interfaces → Interfaces Directory[br]
## Or set it directly: [code]ProjectSettings.set_setting("application/type_interfaces/
## interfaces_directory", "res://your/path/")[/code]
##
## [b]Usage:[/b]
## [codeblock]
## # Export all schemas
## SchemaExporter.export_all_schemas("res://docs/schemas.json")
##
## # Export with custom interface directory
## SchemaExporter.export_all_schemas("res://docs/schemas.json", "res://custom/interfaces/")
##
## # Export a single schema
## SchemaExporter.export_schema("IPlayerData", "res://docs/player_schema.json")
##
## # Get schema as Dictionary for programmatic use
## var schema = SchemaExporter.get_schema_info("IPlayerData")
## [/codeblock]
##
## @tutorial(Modding Guide): res://docs/MODDING_API.md

## Default interfaces directory - can be overridden via project settings or method parameters
const DEFAULT_INTERFACES_DIR := "res://interfaces/"


## Get the configured interfaces directory
## [br]
## Checks project settings first, falls back to default
static func get_interfaces_directory() -> String:
	var project_setting = "application/type_interfaces/interfaces_directory"
	if ProjectSettings.has_setting(project_setting):
		return ProjectSettings.get_setting(project_setting)
	return DEFAULT_INTERFACES_DIR


## Export all registered interface schemas to a JSON file
## [br][br]
## Creates a comprehensive schema document including base schemas,
## extensions, and type information for all interfaces.
## [br][br]
## [param output_path]: File path to write the JSON schema document[br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns true if export succeeds, false otherwise
static func export_all_schemas(output_path: String, interfaces_dir: String = "") -> bool:
	var dir = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var schemas = _create_json_metadata()
	schemas["interfaces"] = {}

	# Get all available interfaces dynamically
	var interface_classes = get_available_interfaces(dir)

	for interface_name in interface_classes:
		var schema_info = get_schema_info(interface_name, dir)
		if schema_info:
			schemas["interfaces"][interface_name] = schema_info

	return _write_json_to_file(output_path, schemas)


## Export a single interface schema to a JSON file
## [br][br]
## [param interface_name]: Name of the interface class (e.g., "IPlayerData")[br]
## [param output_path]: File path to write the JSON schema[br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns true if export succeeds, false otherwise
static func export_schema(
	interface_name: String, output_path: String, interfaces_dir: String = ""
) -> bool:
	var dir = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var schema_info = get_schema_info(interface_name, dir)
	if not schema_info:
		push_error("[SchemaExporter] Failed to get schema for %s" % interface_name)
		return false

	var schema_doc = _create_json_metadata()
	schema_doc["interface"] = interface_name
	schema_doc["schema"] = schema_info

	return _write_json_to_file(output_path, schema_doc)


## Get comprehensive schema information for an interface
## [br][br]
## [param interface_name]: Name of the interface class[br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns a Dictionary containing schema, field info, and metadata, or null if not found
static func get_schema_info(interface_name: String, interfaces_dir: String = "") -> Dictionary:
	var dir = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var instance = _create_interface_instance(interface_name, dir)
	if not instance:
		return {}

	var base_schema = {}
	var full_schema = {}

	# Get schemas if the instance is ExtendableInterface
	if instance.has_method("_get_base_schema"):
		base_schema = instance._get_base_schema()
		full_schema = instance._get_schema()
	elif instance.has_method("_get_schema"):
		# Fallback for TypedDict instances
		full_schema = instance._get_schema()
		base_schema = full_schema.duplicate()

	# Parse field information
	var fields = {}
	for field_name in full_schema.keys():
		var type_string_value = full_schema[field_name]
		fields[field_name] = _parse_type_info(type_string_value, base_schema.has(field_name), dir)

	return {
		"base_schema": base_schema,
		"full_schema": full_schema,
		"fields": fields,
		"is_extendable": instance is ExtendableInterface,
		"description": _get_class_description(interface_name, dir)
	}


## Get a list of all available interfaces
## [br]
## Dynamically scans the interfaces directory to find all interface classes.
## [br][br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns an Array[String] of interface class names
static func get_available_interfaces(interfaces_dir: String = "") -> Array[String]:
	var dir_path = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var interface_classes: Array[String] = []

	var dir = DirAccess.open(dir_path)
	if not dir:
		push_warning("[SchemaExporter] Failed to open interfaces directory: %s" % dir_path)
		return interface_classes

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Only process .gd files, skip directories
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var raw_class_name = file_name.get_basename()
			# Only include interfaces (files starting with 'I' prefix)
			# ExtendableInterface is now in the addon, not here
			if raw_class_name.begins_with("I"):
				if raw_class_name not in interface_classes:
					interface_classes.append(raw_class_name)

		file_name = dir.get_next()

	dir.list_dir_end()
	interface_classes.sort()

	return interface_classes


## Parse type string into detailed type information
## [br][br]
## [param type_string_value]: Type string from schema (e.g., "String", "float?",
## "Array<int>", "ICustomStats")[br]
## [param is_base_field]: Whether this field is in the base schema (vs. extended)[br]
## [param interfaces_dir]: Interfaces directory path for checking interface types
## [br]
## Returns a Dictionary with parsed type information
static func _parse_type_info(
	type_string_value: String, is_base_field: bool, interfaces_dir: String
) -> Dictionary:
	var info = {
		"type": type_string_value,
		"is_nullable": false,
		"is_array": false,
		"is_interface": false,
		"element_type": "",
		"is_base_field": is_base_field,
		"is_extended": not is_base_field
	}

	var dir_path = interfaces_dir if interfaces_dir else get_interfaces_directory()

	# Check for nullable type
	if type_string_value.ends_with("?"):
		info.is_nullable = true
		type_string_value = type_string_value.substr(0, type_string_value.length() - 1)
		info.type = type_string_value

	# Check for Array<Type> syntax
	if type_string_value.begins_with("Array<") and type_string_value.ends_with(">"):
		info.is_array = true
		info.element_type = type_string_value.substr(6, type_string_value.length() - 7)

		# Check if element type is an interface
		if _is_interface_type(info.element_type, dir_path):
			info.is_interface = true

	# Check if type is an interface (starts with 'I' and file exists)
	elif _is_interface_type(type_string_value, dir_path):
		info.is_interface = true

	return info


## Check if a type string represents an interface class
static func _is_interface_type(type_string_value: String, interfaces_dir: String) -> bool:
	if not type_string_value.begins_with("I"):
		return false

	var dir_path = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var script_path = dir_path + "%s.gd" % type_string_value
	return FileAccess.file_exists(script_path)


## Create an instance of an interface for schema extraction
## [br][br]
## Dynamically loads and instantiates the interface class from its script file.
## [br][br]
## [param interface_name]: Name of the interface class[br]
## [param interfaces_dir]: Interfaces directory path
## [br]
## Returns an instance of the interface, or null if creation fails
static func _create_interface_instance(interface_name: String, interfaces_dir: String):
	var dir_path = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var script_path = dir_path + "%s.gd" % interface_name

	if not ResourceLoader.exists(script_path):
		push_error("[SchemaExporter] Interface script not found: %s" % script_path)
		return null

	var script = load(script_path)
	if not script:
		push_error("[SchemaExporter] Failed to load interface script: %s" % script_path)
		return null

	# Create an instance of the loaded script
	var instance = script.new()

	# Verify it's a valid interface (has schema methods)
	if not instance.has_method("_get_schema") and not instance.has_method("_get_base_schema"):
		push_warning(
			"[SchemaExporter] Class %s doesn't appear to be a valid interface" % interface_name
		)
		return null

	return instance


## Get class description from documentation comments
## [br][br]
## Dynamically parses the actual GDScript file to extract the class documentation.
## Looks for ## comments that appear after the extends statement.
static func _get_class_description(interface_name: String, interfaces_dir: String) -> String:
	var dir_path = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var file_path = dir_path + "%s.gd" % interface_name

	if not FileAccess.file_exists(file_path):
		push_warning("[SchemaExporter] File not found: %s" % file_path)
		return ""

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("[SchemaExporter] Failed to open file: %s" % file_path)
		return ""

	var description_lines: Array[String] = []
	var found_extends = false
	var in_doc_block = false

	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		# Track when we've passed the extends statement
		if line.begins_with("extends "):
			found_extends = true
			continue

		# After extends, look for documentation comments
		if found_extends:
			if line.begins_with("##"):
				in_doc_block = true
				# Extract the comment text (remove ## and any leading/trailing whitespace)
				var comment_text = line.substr(2).strip_edges()
				if comment_text != "":
					description_lines.append(comment_text)
			elif in_doc_block and not line.is_empty() and not line.begins_with("#"):
				# End of documentation block
				break

		# Stop if we hit actual code after finding docs
		if found_extends and in_doc_block and line.begins_with("var ") or line.begins_with("func "):
			break

	file.close()

	# Join all description lines with spaces
	var full_description = " ".join(description_lines)

	# Clean up common documentation markup
	# Remove [b] and [/b] tags
	full_description = full_description.replace("[b]", "").replace("[/b]", "")
	# Remove [br] tags
	full_description = full_description.replace("[br]", " ")
	# Remove extra whitespace
	full_description = full_description.strip_edges()

	# Take only the first sentence/line for brevity
	var first_sentence_end = full_description.find(".")
	if first_sentence_end > 0 and first_sentence_end < 150:
		full_description = full_description.substr(0, first_sentence_end + 1)
	elif full_description.length() > 150:
		# Truncate long descriptions
		var truncate_pos = full_description.substr(0, 147).rfind(" ")
		if truncate_pos > 0:
			full_description = full_description.substr(0, truncate_pos) + "..."

	return full_description


## Export a TypeScript definition file for web-based mod tools
## [br][br]
## Generates TypeScript interfaces that match the GDScript schemas,
## useful for creating web-based mod configuration tools.
## [br][br]
## [param output_path]: File path to write the .ts file[br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns true if export succeeds, false otherwise
static func export_typescript_definitions(output_path: String, interfaces_dir: String = "") -> bool:
	var dir = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var ts_content = _generate_typescript_content(dir)
	return _write_text_to_file(output_path, ts_content)


## Convert GDScript type to TypeScript type
static func _gdscript_type_to_typescript(field_info: Dictionary) -> String:
	var base_type = field_info.get("type", "any")

	# Handle arrays
	if field_info.get("is_array", false):
		var element_type = field_info.get("element_type", "any")
		return "%s[]" % _map_type_to_typescript(element_type)

	return _map_type_to_typescript(base_type)


## Map GDScript type names to TypeScript type names
static func _map_type_to_typescript(gdscript_type: String) -> String:
	match gdscript_type:
		"String":
			return "string"
		"int", "float":
			return "number"
		"bool":
			return "boolean"
		"Vector2", "Vector2i", "Vector3", "Vector4":
			return "{ x: number; y: number; z?: number; w?: number }"
		"Color":
			return "{ r: number; g: number; b: number; a: number }"
		"Dictionary":
			return "Record<string, any>"
		"Array":
			return "any[]"
		_:
			return "any"


# ==============================================================================
# PRIVATE HELPER METHODS
# ==============================================================================


## Create standard JSON metadata for exports
## [br]
## Returns a Dictionary with version and generation timestamp
static func _create_json_metadata() -> Dictionary:
	return {"version": "1.0.0", "generated": Time.get_datetime_string_from_system()}


## Write JSON data to a file
## [br][br]
## [param output_path]: File path to write to
## [param data]: Dictionary to serialize as JSON
## [br]
## Returns true if successful, false otherwise
static func _write_json_to_file(output_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("[SchemaExporter] Failed to open file for writing: %s" % output_path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("[SchemaExporter] Successfully exported to %s" % output_path)
	return true


## Write text content to a file
## [br][br]
## [param output_path]: File path to write to
## [param content]: Text content to write
## [br]
## Returns true if successful, false otherwise
static func _write_text_to_file(output_path: String, content: String) -> bool:
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("[SchemaExporter] Failed to open file for writing: %s" % output_path)
		return false

	file.store_string(content)
	file.close()

	print("[SchemaExporter] Successfully exported to %s" % output_path)
	return true


## Generate TypeScript definition content
## [br][br]
## [param interfaces_dir]: Interfaces directory path
## [br]
## Returns the complete TypeScript file content as a String
static func _generate_typescript_content(interfaces_dir: String) -> String:
	var ts_content = "// Auto-generated TypeScript definitions for game interfaces\n"
	ts_content += "// Generated: %s\n\n" % Time.get_datetime_string_from_system()

	var dir_path = interfaces_dir if interfaces_dir else get_interfaces_directory()
	var interface_classes = get_available_interfaces(dir_path)

	for interface_name in interface_classes:
		var schema_info = get_schema_info(interface_name, dir_path)
		if not schema_info:
			continue

		ts_content += "/**\n * %s\n */\n" % schema_info.get("description", "")
		ts_content += "export interface %s {\n" % interface_name

		var fields = schema_info.get("fields", {})
		for field_name in fields.keys():
			var field_info = fields[field_name]
			var ts_type = _gdscript_type_to_typescript(field_info)
			var optional = "?" if field_info.get("is_nullable", false) else ""
			ts_content += "  %s%s: %s;\n" % [field_name, optional, ts_type]

		ts_content += "}\n\n"

	return ts_content

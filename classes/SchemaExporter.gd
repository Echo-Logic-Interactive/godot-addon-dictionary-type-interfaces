@tool
class_name SchemaExporter

extends RefCounted

# Directory for schema viewer JSON files
const VIEWER_SCHEMAS_DIR = "res://addons/godot-addon-dictionary-type-interfaces/schema_viewer/schemas/"

# Load the utility class to get interfaces directory
static var GetInterfacesDir = preload("../src/utils/get_interfaces_dir.gd")

# Call it to get the default directory
static var default_interface_dir: String = GetInterfacesDir.get_interfaces_directory()

## Utility for exporting interface schemas to JSON for mod documentation
##
## Provides tools to export schema definitions in a format that's easy for
## modders to reference. Includes type information, optional fields, and
## base vs. extended schema separation.
##
## [b]Usage:[/b]
## [codeblock]
## # Export all schemas (interfaces + classes) to viewer directory
## SchemaExporter.export_all_to_viewer()
##
## # Export all schemas to custom location
## SchemaExporter.export_all_schemas("res://docs/schemas.json")
##
## # Export with custom interface directory
## SchemaExporter.export_all_schemas("res://docs/schemas.json", "res://custom/interfaces/")
##
## # Export individual schemas to viewer
## SchemaExporter.export_to_viewer("IPlayerData")
##
## # Export regular class schemas
## SchemaExporter.export_class_to_viewer("Player")
##
## # Get schema as Dictionary for programmatic use
## var schema = SchemaExporter.get_schema_info("IPlayerData")
## [/codeblock]
##
## @tutorial(Modding Guide): res://docs/MODDING_API.md


## Export all interface schemas to the schema viewer directory
## [br][br]
## Exports individual JSON files for each interface AND regular class to the schema viewer,
## which can then be viewed using the web-based schema viewer app.
## [br][br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [param include_classes]: Whether to also export regular GDScript classes (default: true)
## [br]
## Returns true if all exports succeed, false if any fail
static func export_all_to_viewer(interfaces_dir: String = "", include_classes: bool = true) -> bool:
	var dir = interfaces_dir if interfaces_dir else default_interface_dir

	# Ensure viewer schemas directory exists
	var viewer_dir_path = VIEWER_SCHEMAS_DIR.replace("res://", "")
	if not DirAccess.dir_exists_absolute(viewer_dir_path):
		var result = DirAccess.make_dir_recursive_absolute(viewer_dir_path)
		if result != OK:
			push_error(
				"[SchemaExporter] Failed to create viewer schemas directory: %s" % viewer_dir_path
			)
			return false

	var interface_classes = get_available_interfaces(dir)
	print(
		(
			"[SchemaExporter] DEBUG: Found %d interfaces: %s"
			% [interface_classes.size(), interface_classes]
		)
	)
	var success = true
	var total_count = 0

	# Export interfaces
	for interface_name in interface_classes:
		print("[SchemaExporter] DEBUG: Attempting to export interface: %s" % interface_name)
		if not export_to_viewer(interface_name, dir):
			success = false
			print("[SchemaExporter] DEBUG: Failed to export interface: %s" % interface_name)
		else:
			total_count += 1
			print("[SchemaExporter] DEBUG: Successfully exported interface: %s" % interface_name)

	# Export regular classes if requested
	var regular_classes: Array[String] = []
	if include_classes:
		regular_classes = get_available_classes()
		print(
			(
				"[SchemaExporter] DEBUG: Found %d classes: %s"
				% [regular_classes.size(), regular_classes]
			)
		)
		for class_name_str in regular_classes:
			if not export_class_to_viewer(class_name_str):
				success = false
			else:
				total_count += 1

	# Create an index file listing all types
	var index = {
		"version": "1.0.0",
		"generated": Time.get_datetime_string_from_system(),
		"interfaces": interface_classes,
		"classes": regular_classes,
		"total_count": total_count
	}

	var index_path = VIEWER_SCHEMAS_DIR + "_index.json"
	if not _write_json_to_file(index_path, index):
		success = false

	# Generate a single JavaScript file with all schemas embedded (for file:// protocol)
	if not _generate_schemas_js_file(interface_classes, regular_classes, dir):
		success = false

	print(
		(
			"[SchemaExporter] Exported %d schemas to viewer (%d interfaces, %d classes)"
			% [total_count, interface_classes.size(), regular_classes.size()]
		)
	)
	return success


## Export a single interface schema to the schema viewer directory
## [br][br]
## [param interface_name]: Name of the interface class (e.g., "IPlayerData")[br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns true if export succeeds, false otherwise
static func export_to_viewer(interface_name: String, interfaces_dir: String = "") -> bool:
	var dir = interfaces_dir if interfaces_dir else default_interface_dir
	var schema_info = get_schema_info(interface_name, dir)

	if not schema_info:
		push_error("[SchemaExporter] Failed to get schema for %s" % interface_name)
		return false

	var schema_doc = {
		"version": "1.0.0",
		"generated": Time.get_datetime_string_from_system(),
		"type": "interface",
		"interface": interface_name,
		"schema": schema_info
	}

	var output_path = VIEWER_SCHEMAS_DIR + interface_name + ".json"
	return _write_json_to_file(output_path, schema_doc)


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
	var dir = interfaces_dir if interfaces_dir else default_interface_dir
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
	var dir = interfaces_dir if interfaces_dir else default_interface_dir
	var schema_info = get_schema_info(interface_name, dir)
	if not schema_info:
		push_error("[SchemaExporter] Failed to get schema for %s" % interface_name)
		return false

	var schema_doc = _create_json_metadata()
	schema_doc["interface"] = interface_name
	schema_doc["schema"] = schema_info

	return _write_json_to_file(output_path, schema_doc)


## Export a single regular class schema to the schema viewer directory
## [br][br]
## [param class_name]: Name of the class (e.g., "Player")[br]
## [br]
## Returns true if export succeeds, false otherwise
static func export_class_to_viewer(class_name_str: String) -> bool:
	var class_info = get_class_info(class_name_str)

	if not class_info or class_info.is_empty():
		push_error("[SchemaExporter] Failed to get class info for %s" % class_name_str)
		return false

	var schema_doc = {
		"version": "1.0.0",
		"generated": Time.get_datetime_string_from_system(),
		"type": "class",
		"class": class_name_str,
		"schema": class_info
	}

	var output_path = VIEWER_SCHEMAS_DIR + class_name_str + ".json"
	return _write_json_to_file(output_path, schema_doc)


## Get comprehensive information for a regular class
## [br][br]
## Parses the GDScript file to extract variables, exports, and type information
## [br][br]
## [param class_name_str]: Name of the class
## [br]
## Returns a Dictionary containing class info, or empty if not found
static func get_class_info(class_name_str: String) -> Dictionary:
	# Find the script file for this class
	var script_path = _find_class_script(class_name_str)
	if script_path.is_empty():
		return {}

	# Parse the script file
	return _parse_class_file(script_path, class_name_str)


## Get comprehensive schema information for an interface
## [br][br]
## [param interface_name]: Name of the interface class[br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns a Dictionary containing schema, field info, and metadata, or null if not found
static func get_schema_info(interface_name: String, interfaces_dir: String = "") -> Dictionary:
	var dir = interfaces_dir if interfaces_dir else default_interface_dir
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
## Dynamically scans the interfaces directory recursively to find all interface classes.
## [br][br]
## [param interfaces_dir]: Optional custom interfaces directory (uses project settings if omitted)
## [br]
## Returns an Array[String] of interface class names
static func get_available_interfaces(interfaces_dir: String = "") -> Array[String]:
	var dir_path = interfaces_dir if interfaces_dir else default_interface_dir
	var interface_classes: Array[String] = []

	_scan_interfaces_recursive(dir_path, interface_classes)

	interface_classes.sort()
	return interface_classes


## Recursively scan directory for interface files
## [br][br]
## [param dir_path]: Directory path to scan[br]
## [param interfaces]: Array to append found interface names to
static func _scan_interfaces_recursive(dir_path: String, interfaces: Array[String]) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_warning("[SchemaExporter] Failed to open directory: %s" % dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Skip hidden files and directories
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = dir_path.path_join(file_name)

		# If it's a directory, scan it recursively
		if dir.current_is_dir():
			_scan_interfaces_recursive(full_path, interfaces)
		# If it's a .gd file starting with "I", it's an interface
		elif file_name.ends_with(".gd") and file_name.begins_with("I"):
			var class_name_str = file_name.get_basename()
			if class_name_str not in interfaces:
				interfaces.append(class_name_str)

		file_name = dir.get_next()

	dir.list_dir_end()


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

	var dir_path = interfaces_dir if interfaces_dir else default_interface_dir

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

	var dir_path = interfaces_dir if interfaces_dir else default_interface_dir
	var script_path = _find_interface_script_path(type_string_value, dir_path)
	return script_path != ""


## Create an instance of an interface for schema extraction
## [br][br]
## Dynamically loads and instantiates the interface class from its script file.
## [br][br]
## [param interface_name]: Name of the interface class[br]
## [param interfaces_dir]: Interfaces directory path
## [br]
## Returns an instance of the interface, or null if creation fails
static func _create_interface_instance(interface_name: String, interfaces_dir: String):
	var dir_path = interfaces_dir if interfaces_dir else default_interface_dir
	var script_path = _find_interface_script_path(interface_name, dir_path)

	if script_path.is_empty() or not ResourceLoader.exists(script_path):
		push_error(
			(
				"[SchemaExporter] Interface script not found: %s (searched in %s)"
				% [interface_name, dir_path]
			)
		)
		return null

	var script = load(script_path)
	if not script:
		push_error("[SchemaExporter] Failed to load interface script: %s" % script_path)
		return null

	# Create dummy data based on the schema to avoid validation errors
	# First, we need to peek at the schema without validation
	var temp_instance = script.new({})

	# Extract the schema to see what fields we need
	var schema = {}
	if temp_instance.has_method("_get_base_schema"):
		schema = temp_instance._get_base_schema()
	elif temp_instance.has_method("_get_schema"):
		schema = temp_instance._get_schema()

	# Create dummy data for all required fields
	var dummy_data = {}
	for field_name in schema.keys():
		var type_str = schema[field_name]
		dummy_data[field_name] = _create_dummy_value(type_str)

	# Now create the actual instance with valid dummy data
	var instance = script.new(dummy_data)

	if not instance:
		push_error("[SchemaExporter] Failed to create instance of %s" % interface_name)
		return null

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
	var dir_path = interfaces_dir if interfaces_dir else default_interface_dir
	var file_path = _find_interface_script_path(interface_name, dir_path)

	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		push_warning("[SchemaExporter] File not found for %s in %s" % [interface_name, dir_path])
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
	var dir = interfaces_dir if interfaces_dir else default_interface_dir
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

	var dir_path = interfaces_dir if interfaces_dir else default_interface_dir
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


## Generate schemas.js file with embedded data
static func _generate_schemas_js_file(
	interface_classes: Array[String], regular_classes: Array[String], interfaces_dir: String
) -> bool:
	var dir_to_use = interfaces_dir if interfaces_dir else default_interface_dir

	print("[SchemaExporter] Starting schema export...")
	print("[SchemaExporter] Interfaces directory: ", dir_to_use)

	var all_schemas = []

	# Get interfaces
	var interfaces = interface_classes
	print("[SchemaExporter] Found %d interfaces: %s" % [interfaces.size(), interfaces])

	for interface_name in interfaces:
		print("[SchemaExporter] Processing interface: ", interface_name)
		var schema_info = get_schema_info(interface_name, dir_to_use)
		print("[SchemaExporter]   Schema info keys: ", schema_info.keys())

		if not schema_info.is_empty():
			schema_info["type"] = "interface"
			schema_info["interface"] = interface_name

			# Add file path information for web viewer
			var script_path = _find_interface_script_path(interface_name, dir_to_use)
			if not script_path.is_empty():
				# Extract relative path from interfaces directory
				var relative_path = (
					script_path.replace(dir_to_use, "").trim_prefix("/").trim_prefix("\\")
				)
				schema_info["file_path"] = relative_path

				# Extract subdirectory (if any)
				var path_parts = relative_path.split("/")
				if path_parts.size() > 1:
					path_parts.remove_at(path_parts.size() - 1)  # Remove filename
					schema_info["subdirectory"] = "/".join(path_parts)
				else:
					schema_info["subdirectory"] = ""

			all_schemas.append(schema_info)
			print("[SchemaExporter]   ✓ Added interface: ", interface_name)
		else:
			print("[SchemaExporter]   ✗ Empty schema for: ", interface_name)

	# Get classes
	var classes = regular_classes
	print("[SchemaExporter] Found %d classes: %s" % [classes.size(), classes])

	for class_name_str in classes:
		print("[SchemaExporter] Processing class: ", class_name_str)
		var class_info = get_class_info(class_name_str)
		print("[SchemaExporter]   Class info keys: ", class_info.keys())

		if not class_info.is_empty():
			class_info["type"] = "class"
			class_info["class"] = class_name_str
			all_schemas.append(class_info)
			print("[SchemaExporter]   ✓ Added class: ", class_name_str)
		else:
			print("[SchemaExporter]   ✗ Empty info for: ", class_name_str)

	print("[SchemaExporter] Total schemas to export: ", all_schemas.size())

	# Build the JavaScript file content
	var js_content = "// Auto-generated schemas for viewer\n"
	js_content += "// Generated: %s\n\n" % Time.get_datetime_string_from_system()
	js_content += "window.SCHEMAS_DATA = {\n"
	js_content += '  "version": "1.0.0",\n'
	js_content += '  "generated": "%s",\n' % Time.get_datetime_string_from_system()
	js_content += '  "schemas": [\n'

	var schema_json_strings: Array[String] = []
	for schema in all_schemas:
		var schema_type = schema.get("type", "unknown")
		var schema_name = schema.get("interface", schema.get("class", "Unknown"))
		var schema_doc = {
			"name": schema_name,
			"type": schema_type,
			"data":
			{"version": "1.0.0", "type": schema_type, schema_type: schema_name, "schema": schema}
		}
		schema_json_strings.append("    " + JSON.stringify(schema_doc))

	js_content += ",\n".join(schema_json_strings)
	js_content += "\n  ]\n"
	js_content += "};\n"

	# gdlint: disable=max-line-length
	var output_path = "res://addons/godot-addon-dictionary-type-interfaces/schema_viewer/app/schemas.js"
	var success = _write_text_to_file(output_path, js_content)

	if success:
		print(
			"[SchemaExporter] ✓ Successfully wrote schemas.js with %d schemas" % all_schemas.size()
		)
	else:
		push_error("[SchemaExporter] ✗ Failed to write schemas.js")

	return success


## Get all available regular classes with class_name declarations
## [br]
## Returns an Array[String] of class names
static func get_available_classes() -> Array[String]:
	var classes: Array[String] = []
	var cache_file = ".godot/global_script_class_cache.cfg"

	if not FileAccess.file_exists(cache_file):
		push_warning("[SchemaExporter] Global class cache not found")
		return classes

	var config = ConfigFile.new()
	var err = config.load(cache_file)
	if err != OK:
		push_warning("[SchemaExporter] Failed to load global class cache")
		return classes

	if not config.has_section_key("", "list"):
		return classes

	var class_list = config.get_value("", "list", [])
	for class_entry in class_list:
		if class_entry is Dictionary and class_entry.has("class"):
			var class_name_str = class_entry["class"]
			var class_path = class_entry.get("path", "")

			# Exclude interfaces:
			# - Class name starts with I
			# - OR file is in the interfaces directory
			# - OR file extends ExtendableInterface/TypedDict
			if (
				class_name_str.begins_with("I")
				or "/" + default_interface_dir + "/" in class_path
				or "\\" + default_interface_dir + "\\" in class_path
			):
				continue

			classes.append(class_name_str)

	classes.sort()
	return classes


## Find the script file path for a class name
static func _find_class_script(class_name_str: String) -> String:
	var cache_file = ".godot/global_script_class_cache.cfg"

	if not FileAccess.file_exists(cache_file):
		return ""

	var config = ConfigFile.new()
	if config.load(cache_file) != OK:
		return ""

	if not config.has_section_key("", "list"):
		return ""

	var class_list = config.get_value("", "list", [])
	for class_entry in class_list:
		if class_entry is Dictionary and class_entry.get("class") == class_name_str:
			return class_entry.get("path", "")

	return ""


## Parse a GDScript class file to extract variable information
static func _parse_class_file(script_path: String, class_name_str: String) -> Dictionary:
	if not FileAccess.file_exists(script_path):
		push_warning("[SchemaExporter] File not found: %s" % script_path)
		return {}

	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("[SchemaExporter] Failed to open file: %s" % script_path)
		return {}

	var content = file.get_as_text()
	file.close()

	var result = {
		"class_name": class_name_str,
		"script_path": script_path,
		"extends": "",
		"description": "",
		"fields": {},
		"exports": {},
		"signals": []
	}

	# Split into lines and handle multi-line statements
	var lines = content.split("\n")
	var i = 0
	var in_class_doc = false
	var doc_lines: Array[String] = []
	var pending_export = false

	while i < lines.size():
		var line = lines[i]
		var trimmed = line.strip_edges()

		# Handle line continuation (backslash)
		while trimmed.ends_with("\\") and i < lines.size() - 1:
			i += 1
			trimmed = trimmed.trim_suffix("\\") + " " + lines[i].strip_edges()

		# Get extends information
		if trimmed.begins_with("extends "):
			result["extends"] = trimmed.substr(8).strip_edges()
			i += 1
			continue

		# Collect documentation
		if trimmed.begins_with("##"):
			in_class_doc = true
			var comment = trimmed.substr(2).strip_edges()
			if not comment.is_empty():
				doc_lines.append(comment)
			i += 1
			continue
		elif in_class_doc and not trimmed.begins_with("#") and not trimmed.is_empty():
			in_class_doc = false
			result["description"] = " ".join(doc_lines)
			doc_lines.clear()

		# Parse signals
		if trimmed.begins_with("signal "):
			var signal_decl = trimmed.substr(7)
			var signal_name = signal_decl.split("(")[0].strip_edges()
			if not signal_name.is_empty():
				result["signals"].append(signal_name)
			i += 1
			continue

		# Track @export annotations
		if trimmed.begins_with("@export"):
			pending_export = true
			i += 1
			continue

		# Parse variables
		if trimmed.begins_with("var "):
			var var_line = trimmed.substr(4)
			var var_info = _extract_var_info(var_line, pending_export)

			if var_info and not var_info["name"].is_empty():
				if not var_info["name"].begins_with("_"):
					var field_info = {"type": var_info["type"], "is_export": var_info["is_export"]}
					result["fields"][var_info["name"]] = field_info
					if var_info["is_export"]:
						result["exports"][var_info["name"]] = field_info

			pending_export = false
			i += 1
			continue

		# Reset export flag if we hit non-var line
		if not trimmed.is_empty() and not trimmed.begins_with("#"):
			pending_export = false

		i += 1

	return result


## Recursively find the script path for an interface in subdirectories
## [br][br]
## [param interface_name]: Name of the interface (e.g., "IWorldEntity")[br]
## [param base_dir]: Base directory to search from
## [br]
## Returns the full script path, or empty string if not found
static func _find_interface_script_path(interface_name: String, base_dir: String) -> String:
	var filename = "%s.gd" % interface_name
	return _search_for_file_recursive(base_dir, filename)


## Recursively search for a file in a directory tree
static func _search_for_file_recursive(dir_path: String, filename: String) -> String:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return ""

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = dir_path.path_join(file_name)

		if dir.current_is_dir():
			# Search subdirectories
			var result = _search_for_file_recursive(full_path, filename)
			if not result.is_empty():
				dir.list_dir_end()
				return result
		elif file_name == filename:
			# Found it!
			dir.list_dir_end()
			return full_path

		file_name = dir.get_next()

	dir.list_dir_end()
	return ""


## Create a dummy value for a given type string (for schema extraction)
static func _create_dummy_value(type_str: String) -> Variant:
	# Handle nullable types
	if type_str.ends_with("?"):
		type_str = type_str.substr(0, type_str.length() - 1)

	# Handle arrays
	if type_str.begins_with("Array<") and type_str.ends_with(">"):
		return []

	# Handle basic types
	match type_str:
		"String":
			return ""
		"int":
			return 0
		"float":
			return 0.0
		"bool":
			return false
		"Vector2":
			return Vector2.ZERO
		"Vector2i":
			return Vector2i.ZERO
		"Vector3":
			return Vector3.ZERO
		"Vector4":
			return Vector4.ZERO
		"Color":
			return Color.WHITE
		"Dictionary":
			return {}
		"Array":
			return []
		_:
			# For interface types or unknown types, use empty dict
			return {}


## Extract variable information from a var declaration line
static func _extract_var_info(var_line: String, is_export: bool) -> Dictionary:
	var info = {"name": "", "type": "Variant", "is_export": is_export}

	# Remove comments
	var line_no_comment = var_line
	if "#" in var_line:
		line_no_comment = var_line.split("#")[0]

	# Handle type annotation: name: Type = value
	if ":" in line_no_comment and not ":=" in line_no_comment:
		var parts = line_no_comment.split(":", false, 1)
		info["name"] = parts[0].strip_edges()

		if parts.size() > 1:
			# Extract type (before = or end of line)
			var type_part = parts[1]
			if "=" in type_part:
				type_part = type_part.split("=")[0]
			info["type"] = type_part.strip_edges()

	# Handle inferred type: name := value
	elif ":=" in line_no_comment:
		info["name"] = line_no_comment.split(":=")[0].strip_edges()
		info["type"] = "Inferred"

	# Handle untyped: name = value or just name
	else:
		if "=" in line_no_comment:
			info["name"] = line_no_comment.split("=")[0].strip_edges()
		else:
			info["name"] = line_no_comment.strip_edges()

	return info

# gdlint: disable=max-file-lines

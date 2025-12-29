@tool
class_name GetInterfacesDir

extends RefCounted

## Get the configured interfaces directory
##
## [b]Configuration:[/b][br]
## Set your interfaces directory in Project Settings:[br]
## Project → Project Settings → General → Application → Type Interfaces → Interfaces Directory[br]
## Or set it directly: [code]ProjectSettings.set_setting("application/
## godot-addon-dictionary-type-interfaces/
## interfaces_directory", "res://your/path/")[/code]

## Default interfaces directory - can be overridden via project settings or method parameters
## This must have a trailing slash
const DEFAULT_INTERFACES_DIR: String = "res://interfaces/"


## Get the configured interfaces directory
## [br]
## Checks project settings first, falls back to default
static func get_interfaces_directory() -> String:
	var plugin_name: String = "godot-addon-dictionary-type-interfaces"
	var project_setting: String = "application/" + plugin_name + "/interfaces_directory"
	var setting_value = ProjectSettings.get_setting(project_setting, DEFAULT_INTERFACES_DIR)

	# Ensure it ends with a slash
	if not setting_value.ends_with("/"):
		setting_value += "/"

	print("[GetInterfacesDir] Using interfaces directory: %s" % setting_value)

	return setting_value

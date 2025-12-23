class_name GetInterfacesDir

extends RefCounted

## Get the configured interfaces directory
##
## [b]Configuration:[/b][br]
## Set your interfaces directory in Project Settings:[br]
## Project → Project Settings → General → Application → Type Interfaces → Interfaces Directory[br]
## Or set it directly: [code]ProjectSettings.set_setting("application/type_interfaces/
## interfaces_directory", "res://your/path/")[/code]

## Default interfaces directory - can be overridden via project settings or method parameters
## This must have a trailing slash
const DEFAULT_INTERFACES_DIR := "res://interfaces/"


## Get the configured interfaces directory
## [br]
## Checks project settings first, falls back to default
static func get_interfaces_directory() -> String:
	var setting_value := DEFAULT_INTERFACES_DIR
	var project_setting := "application/type_interfaces/interfaces_directory"

	if ProjectSettings.has_setting(project_setting):
		setting_value = ProjectSettings.get_setting(project_setting)

	# Ensure it ends with a slash
	if not setting_value.ends_with("/"):
		setting_value += "/"

	return setting_value

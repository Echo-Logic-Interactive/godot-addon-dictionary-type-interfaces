@tool
extends EditorPlugin

## Dictionary Type Interfaces Plugin
## Provides ORM-style type-safe data objects for Godot


func _enter_tree() -> void:
	print("Dictionary Type Interfaces plugin activated")

	# Register project settings for configuration
	_register_project_settings()

	# Register autoload singleton for runtime validation
	add_autoload_singleton(
		"TypeInterfaces", "res://addons/type_interfaces/src/type_interfaces_runtime.gd"
	)

	# Register ModdingAPI singleton for mod support
	add_autoload_singleton(
		"ModdingAPI", "res://addons/type_interfaces/src/interface_modding_api.gd"
	)


func _exit_tree() -> void:
	print("Dictionary Type Interfaces plugin deactivated")
	remove_autoload_singleton("TypeInterfaces")
	remove_autoload_singleton("ModdingAPI")


## Register project settings for the addon
func _register_project_settings() -> void:
	var setting_name = "application/type_interfaces/interfaces_directory"
	var default_value = "res://interfaces/"

	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, default_value)
		ProjectSettings.set_initial_value(setting_name, default_value)

	# Set property info for the editor
	ProjectSettings.add_property_info(
		{
			"name": setting_name,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
			"hint_string": "Directory containing your interface files (e.g., IPlayerData.gd)"
		}
	)

	# Save the project settings
	ProjectSettings.save()

@tool
extends EditorPlugin

## Dictionary Type Interfaces Plugin
## Provides ORM-style type-safe data objects for Godot


func _enter_tree() -> void:
	print("Dictionary Type Interfaces plugin activated")

	# Register autoload singleton for runtime validation
	add_autoload_singleton(
		"TypeInterfaces", "res://addons/type_interfaces/src/type_interfaces_runtime.gd"
	)


func _exit_tree() -> void:
	print("Dictionary Type Interfaces plugin deactivated")
	remove_autoload_singleton("TypeInterfaces")

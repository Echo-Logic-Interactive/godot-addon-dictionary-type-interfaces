class_name IExamplePlayer

extends ExtendableInterface

## Example player data interface demonstrating addon usage
##
## This is a reference implementation showing best practices for creating
## mod-friendly interfaces. Copy and modify for your own game's needs.
##
## Features demonstrated:
## - Property accessors for IDE autocomplete
## - Nullable types (position?)
## - Extendable schema for mods
## - LOOSE validation by default

# Typed property accessors for IDE support
var name: String:
	get:
		return get_value("name", "")
	set(value):
		set_value("name", value)

var level: int:
	get:
		return get_value("level", 1)
	set(value):
		set_value("level", value)

var health: float:
	get:
		return get_value("health", 100.0)
	set(value):
		set_value("health", value)

var max_health: float:
	get:
		return get_value("max_health", 100.0)
	set(value):
		set_value("max_health", value)

var position: Vector2:
	get:
		return get_value("position", Vector2.ZERO)
	set(value):
		set_value("position", value)


# Define the base schema (what fields are valid and their types)
func _get_base_schema() -> Dictionary:
	return {
		"name": "String",
		"level": "int",
		"health": "float",
		"max_health": "float",
		"position": "Vector2?",  # Nullable - can be null
		"experience": "int"
	}

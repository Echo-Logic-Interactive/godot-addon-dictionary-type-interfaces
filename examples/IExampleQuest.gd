@tool
class_name IExampleQuest

extends ExtendableInterface

## Example quest/mission tracking interface
##
## Demonstrates:
## - Nested interfaces (IExampleQuestObjective)
## - Arrays of custom interfaces
## - Enum-like string validation
## - Complex data structures

var quest_id: String:
	get:
		return get_value("quest_id", "")
	set(value):
		set_value("quest_id", value)

var title: String:
	get:
		return get_value("title", "")
	set(value):
		set_value("title", value)

var status: String:
	get:
		return get_value("status", "not_started")
	set(value):
		set_value("status", value)

var objectives: Array:
	get:
		return get_value("objectives", [])
	set(value):
		set_value("objectives", value)


func _get_base_schema() -> Dictionary:
	return {
		"quest_id": "String",
		"title": "String",
		"description": "String",
		"status": "String",  # Values: "not_started", "active", "completed", "failed"
		"objectives": "Array<Dictionary>",  # Could use Array<IExampleQuestObjective> for validation
		"rewards": "Dictionary?",
		"required_level": "int?"
	}

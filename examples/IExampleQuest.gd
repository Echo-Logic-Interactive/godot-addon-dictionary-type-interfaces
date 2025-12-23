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
##
## Types:[br]
## [codeblock]
## {
## 	 "quest_id": "String",
## 	 "title": "String",
## 	 "description": "String",
## 	 "status": "String",
## 	 "objectives": "Array<Dictionary>",
## 	 "rewards": "Dictionary?",
## 	 "required_level": "int?"
## }
## [/codeblock]
##
## Example:[br]
## [codeblock]
## {
##     "quest_id": "quest_001",
##     "title": "Find the Lost Sword",
##     "description": "Retrieve the legendary sword from the ancient ruins.",
##     "status": "active",
##     "objectives": [
##         {
##             "objective_id": "obj_001",
##             "description": "Enter the ancient ruins.",
##             "is_completed": true
##         }
##     ],
##     "rewards": {
##         "experience": 500,
##         "items": ["item_1001", "item_1002"]
##     },
##     "required_level": 5
## }
## [/codeblock]

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

var required_level: int:
	get:
		return get_value("required_level", 1)
	set(value):
		set_value("required_level", value)


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

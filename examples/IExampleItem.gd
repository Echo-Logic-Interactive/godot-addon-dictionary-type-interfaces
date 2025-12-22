class_name IExampleItem

extends ExtendableInterface

## Example inventory item interface
##
## Demonstrates common patterns for game item data:
## - Unique identifiers
## - Item metadata (name, description, weight)
## - Quantity tracking
## - Nullable optional fields
## - Array types for tags/categories

var id: String:
	get:
		return get_value("id", "")
	set(value):
		set_value("id", value)

var item_name: String:
	get:
		return get_value("item_name", "")
	set(value):
		set_value("item_name", value)

var quantity: int:
	get:
		return get_value("quantity", 1)
	set(value):
		set_value("quantity", value)

var weight: float:
	get:
		return get_value("weight", 0.0)
	set(value):
		set_value("weight", value)

var tags: Array:
	get:
		return get_value("tags", [])
	set(value):
		set_value("tags", value)


func _get_base_schema() -> Dictionary:
	return {
		"id": "String",
		"item_name": "String",
		"quantity": "int",
		"weight": "float?",  # Optional weight
		"description": "String?",  # Optional description
		"tags": "Array<String>",  # Array of string tags
		"icon_path": "String?"  # Optional icon resource path
	}

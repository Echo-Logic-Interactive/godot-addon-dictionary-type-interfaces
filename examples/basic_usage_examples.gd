extends Node

var IExamplePlayer = load(get_script().resource_path.base_dir() + "/IExamplePlayer.gd")
var IExampleItem = load(get_script().resource_path.base_dir() + "/IExampleItem.gd")
var IExampleQuest = load(get_script().resource_path.base_dir() + "/IExampleQuest.gd")

## Basic Usage Examples for Type Interfaces Addon
##
## Demonstrates core functionality using the included example interfaces:
## - IExamplePlayer: Player data management
## - IExampleItem: Inventory/item system
## - IExampleQuest: Quest tracking
##
## Run this scene to see the addon in action!

# ==============================================================================
# EXAMPLE 1: Creating and Using Player Data
# ==============================================================================


func example_creating_player() -> void:
	print("\n=== Example 1: Creating Player Data ===")

	# Create a new player using the typed interface
	var player = IExamplePlayer.new(
		{
			"name": "Hero",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2.ZERO
		}
	)

	# Access data via typed properties (with IDE autocomplete!)
	print("Player: %s (Level %d)" % [player.name, player.level])
	print("Health: %.1f / %.1f" % [player.health, player.max_health])
	print("Position: %s" % player.position)


# ==============================================================================
# EXAMPLE 2: Modifying Data with Type Safety
# ==============================================================================


func example_typed_properties() -> void:
	print("\n=== Example 2: Typed Properties ===")

	var player = IExamplePlayer.new(
		{
			"name": "Warrior",
			"level": 5,
			"experience": 1000,
			"health": 85.0,
			"max_health": 100.0,
			"position": Vector2(100, 200)
		}
	)

	# Modify via properties (validates automatically in debug builds)
	player.level = 6
	player.experience = 1500
	player.health = 90.0

	print("Updated player level: %d" % player.level)
	print("Experience: %d" % player.experience)
	print("Health: %.1f" % player.health)


# ==============================================================================
# EXAMPLE 3: Functions with Typed Parameters and Returns
# ==============================================================================


## Create a player with default stats
func create_new_player(player_name: String) -> IExamplePlayer:
	# Return type ensures correct structure
	return IExamplePlayer.new(
		{
			"name": player_name,
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2.ZERO
		}
	)


## Level up a player and increase stats
func level_up_player(player: IExamplePlayer) -> void:
	player.level += 1
	player.max_health += 10.0
	player.health = player.max_health  # Full heal on level up
	player.experience = 0  # Reset experience

	print("Level up! %s is now level %d" % [player.name, player.level])


func example_typed_functions() -> void:
	print("\n=== Example 3: Typed Functions ===")

	var new_player = create_new_player("Adventurer")
	print("Created: %s" % new_player.name)

	# Gain some experience
	new_player.experience = 1000

	level_up_player(new_player)
	print("Max Health: %.1f" % new_player.max_health)


# ==============================================================================
# EXAMPLE 4: Working with Items and Inventory
# ==============================================================================


func example_items() -> void:
	print("\n=== Example 4: Items ===")

	# Create items with different properties
	var sword = IExampleItem.new(
		{
			"id": "sword_001",
			"item_name": "Iron Sword",
			"quantity": 1,
			"weight": 5.0,
			"description": "A basic iron sword",
			"tags": ["weapon", "melee"],
			"icon_path": "res://icons/sword.png"
		}
	)

	var potion = IExampleItem.new(
		{
			"id": "potion_hp",
			"item_name": "Health Potion",
			"quantity": 5,
			"weight": 0.5,
			"description": "Restores 50 HP",
			"tags": ["consumable", "healing"]
		}
	)

	# Some fields are nullable (optional)
	print("Sword: %s (x%d) - Weight: %.1f kg" % [sword.item_name, sword.quantity, sword.weight])
	print("  Tags: %s" % sword.tags)
	print("  Icon: %s" % sword.icon_path)

	print("Potion: %s (x%d)" % [potion.item_name, potion.quantity])
	print("  Description: %s" % potion.description)


# ==============================================================================
# EXAMPLE 5: Quest System with Complex Data
# ==============================================================================


func create_quest(quest_id: String, title: String, description: String) -> IExampleQuest:
	return IExampleQuest.new(
		{
			"quest_id": quest_id,
			"title": title,
			"description": description,
			"status": "not_started",
			"objectives": [],
			"required_level": 1
		}
	)


func example_quests() -> void:
	print("\n=== Example 5: Quests ===")

	var quest = create_quest("quest_001", "First Steps", "Complete your first quest")

	# Add objectives
	quest.objectives = [
		{"description": "Talk to the elder", "completed": false},
		{"description": "Collect 5 herbs", "completed": false, "current": 0, "required": 5}
	]

	# Add rewards
	quest.rewards = {"gold": 100, "experience": 50}

	print("Quest: %s" % quest.title)
	print("Description: %s" % quest.description)
	print("Status: %s" % quest.status)
	print("Objectives: %d" % quest.objectives.size())

	# Update quest progress
	quest.status = "active"
	print("Quest started!")

	# Complete quest
	quest.status = "completed"
	print("Quest completed! Rewards: %s" % quest.rewards)


# ==============================================================================
# EXAMPLE 6: Serialization - Save and Load
# ==============================================================================


func example_serialization() -> void:
	print("\n=== Example 6: Serialization (Save/Load) ===")

	# Create a player
	var player = IExamplePlayer.new(
		{
			"name": "SavedHero",
			"level": 10,
			"experience": 5000,
			"health": 95.0,
			"max_health": 120.0,
			"position": Vector2(500, 300)
		}
	)

	# Convert to dictionary for saving to file
	var save_dict = player.to_dict()
	print("Saving player data: %s" % save_dict)

	# Simulate saving to JSON
	var json_string = JSON.stringify(save_dict)
	print("JSON: %s" % json_string)

	# Simulate loading from JSON
	var loaded_dict = JSON.parse_string(json_string)
	var loaded_player = IExamplePlayer.new(loaded_dict)

	print("Loaded player: %s (Level %d)" % [loaded_player.name, loaded_player.level])
	print("Position restored: %s" % loaded_player.position)


# ==============================================================================
# EXAMPLE 7: Modding - Extending Interfaces
# ==============================================================================


func example_modding_support() -> void:
	print("\n=== Example 7: Modding Support ===")

	var player = IExamplePlayer.new(
		{
			"name": "Modded Player",
			"level": 5,
			"experience": 2000,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2.ZERO
		}
	)

	# Mods can safely add custom data without conflicts
	player.set_mod_data("com.example.rpgmod", "mana", 100.0)
	player.set_mod_data("com.example.rpgmod", "stamina", 50.0)
	player.set_mod_data("com.other.mod", "custom_stat", 42)

	# Retrieve mod data
	var mana = player.get_mod_data("com.example.rpgmod", "mana", 0.0)
	var stamina = player.get_mod_data("com.example.rpgmod", "stamina", 0.0)

	print("Player: %s" % player.name)
	print("Mod Data - Mana: %.1f, Stamina: %.1f" % [mana, stamina])

	# Check what mods have added data
	var registered_mods = player.get_registered_mods()
	print("Mods with data: %s" % registered_mods)


# ==============================================================================
# EXAMPLE 8: Schema Extension (Advanced Modding)
# ==============================================================================


func example_schema_extension() -> void:
	print("\n=== Example 8: Schema Extension ===")

	var player = IExamplePlayer.new(
		{
			"name": "Extended Player",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0
		}
	)

	# Extend the schema with new validated fields
	player.extend_schema({"mana": "float", "stamina": "float", "class_name": "String"})

	# Now these fields are validated!
	player.set_value("mana", 100.0)
	player.set_value("stamina", 50.0)
	player.set_value("class_name", "Warrior")

	print("Player: %s (Level %d)" % [player.name, player.level])
	print("Class: %s" % player.get_value("class_name"))
	print("Mana: %.1f, Stamina: %.1f" % [player.get_value("mana"), player.get_value("stamina")])


# ==============================================================================
# EXAMPLE 9: Validation Modes
# ==============================================================================


func example_validation_modes() -> void:
	print("\n=== Example 9: Validation Modes ===")

	# LOOSE mode (default) - allows extra fields
	var loose_player = IExamplePlayer.new(
		{
			"name": "Loose Player",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"custom_field": "This is allowed in LOOSE mode"  # Extra field OK
		},
		TypeInterfaces.ValidationMode.LOOSE
	)

	print("Loose mode player created successfully")
	print("Custom field: %s" % loose_player.get_value("custom_field", ""))

	# STRICT mode - no extra fields allowed
	# This would fail in debug builds with extra fields:
	var strict_player = (
		IExamplePlayer
		. new(
			{
				"name": "Strict Player",
				"level": 1,
				"experience": 0,
				"health": 100.0,
				"max_health": 100.0
				# No extra fields!
			},
			TypeInterfaces.ValidationMode.STRICT
		)
	)

	print("Strict mode player created successfully")


# ==============================================================================
# Run All Examples
# ==============================================================================


func _ready() -> void:
	print("========================================")
	print("Type Interfaces - Basic Usage Examples")
	print("========================================")

	example_creating_player()
	example_typed_properties()
	example_typed_functions()
	example_items()
	example_quests()
	example_serialization()
	example_modding_support()
	example_schema_extension()
	example_validation_modes()

	print("\n========================================")
	print("All examples completed!")
	print("========================================")
	print("\nTip: Check the console output above to see each example in action.")
	print("Tip: Examine this file's source code to learn the patterns.")

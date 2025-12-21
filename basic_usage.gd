extends Node

## Basic TypedDict Usage Examples
## Demonstrates how to use the ORM-style interface system

# ==============================================================================
# EXAMPLE 1: Creating Simple Data Objects
# ==============================================================================


func example_creating_player() -> void:
	print("\n=== Example 1: Creating Player Data ===")

	# Create a new player using the typed interface
	var player = IPlayerData.new(
		{
			"name": "Hero",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2.ZERO
		}
	)

	# Access data via typed properties
	print("Player: %s (Level %d)" % [player.name, player.level])
	print("Health: %.1f / %.1f" % [player.health, player.max_health])


# ==============================================================================
# EXAMPLE 2: Using Typed Properties
# ==============================================================================


func example_typed_properties() -> void:
	print("\n=== Example 2: Typed Properties ===")

	var player = IPlayerData.new(
		{
			"name": "Warrior",
			"level": 5,
			"experience": 1000,
			"health": 85.0,
			"max_health": 100.0,
			"position": Vector2(100, 200)
		}
	)

	# Modify via properties (validates automatically)
	player.level = 6
	player.experience = 1500
	player.health = 90.0

	print("Updated player level: %d" % player.level)
	print("Experience: %d" % player.experience)


# ==============================================================================
# EXAMPLE 3: Functions with Typed Returns
# ==============================================================================


func get_player_data(player_id: String) -> IPlayerData:
	# Create and return typed data - validates on construction
	return IPlayerData.new(
		{
			"name": "Fisher %s" % player_id,
			"level": 5,
			"experience": 1250,
			"health": 85.5,
			"max_health": 100.0,
			"position": Vector2(100, 200)
		}
	)


func save_player(player: IPlayerData) -> void:
	# Type system ensures correct structure
	print("Saving player: %s" % player.name)

	# Convert to dictionary for file I/O
	var save_data = player.to_dict()
	# Save to file...
	print("Save data: %s" % save_data)


# ==============================================================================
# EXAMPLE 4: Working with Items
# ==============================================================================


func example_items() -> void:
	print("\n=== Example 4: Items ===")

	# Create items
	var sword = IItem.new(
		{
			"id": "sword_001",
			"name": "Iron Sword",
			"description": "A basic sword",
			"quantity": 1,
			"weight": 5.0,
			"value": 150
		}
	)

	var potion = IItem.new(
		{
			"id": "potion_001",
			"name": "Health Potion",
			"description": "Restores 50 HP",
			"quantity": 5,
			"weight": 0.5,
			"value": 25
		}
	)

	print("Item 1: %s (x%d) - Value: %d" % [sword.name, sword.quantity, sword.value])
	print("Item 2: %s (x%d) - Value: %d" % [potion.name, potion.quantity, potion.value])


# ==============================================================================
# EXAMPLE 5: Catching Fish
# ==============================================================================


func catch_fish(species: String, weight: float) -> IFish:
	var fish = IFish.new()
	fish.species = species
	fish.weight = weight
	fish.length = weight * 1.5  # Simple calculation
	fish.rarity = _calculate_rarity(weight)
	fish.caught_time = Time.get_unix_time_from_system()
	fish.location = Vector2(150, 300)

	return fish


func example_fishing() -> void:
	print("\n=== Example 5: Fishing ===")

	var bass = catch_fish("Bass", 8.5)
	var salmon = catch_fish("Salmon", 15.2)
	var tuna = catch_fish("Tuna", 25.0)

	print("Caught %s: %.1f kg (%s)" % [bass.species, bass.weight, bass.rarity])
	print("Caught %s: %.1f kg (%s)" % [salmon.species, salmon.weight, salmon.rarity])
	print("Caught %s: %.1f kg (%s)" % [tuna.species, tuna.weight, tuna.rarity])


# ==============================================================================
# EXAMPLE 6: Quest System
# ==============================================================================


func example_quests() -> void:
	print("\n=== Example 6: Quests ===")

	var quest = IQuest.new()
	quest.id = "quest_001"
	quest.title = "First Catch"
	quest.description = "Catch your first fish"
	quest.progress = 0
	quest.max_progress = 1
	quest.rewards = ["Gold Coin", "Experience Points"]

	print("Quest: %s" % quest.title)
	print("Progress: %d/%d" % [quest.progress, quest.max_progress])

	# Complete the quest
	quest.progress = 1
	quest.is_completed = true

	print("Quest completed! Rewards: %s" % quest.rewards)


# ==============================================================================
# EXAMPLE 7: Weather System
# ==============================================================================


func update_weather() -> IWeatherData:
	var weather = IWeatherData.new()
	weather.temperature = randf_range(-10.0, 35.0)
	weather.precipitation = randf_range(0.0, 100.0)
	weather.wind_speed = randf_range(0.0, 50.0)
	weather.cloud_cover = randf_range(0.0, 100.0)
	weather.time_of_day = "afternoon"

	return weather


func apply_weather(weather: IWeatherData) -> void:
	print("Weather Update:")
	print("  Temperature: %.1f°C" % weather.temperature)
	print("  Wind Speed: %.1f km/h" % weather.wind_speed)
	print("  Precipitation: %.1f%%" % weather.precipitation)
	print("  Cloud Cover: %.1f%%" % weather.cloud_cover)


# ==============================================================================
# EXAMPLE 8: Converting to/from Dictionaries
# ==============================================================================


func example_serialization() -> void:
	print("\n=== Example 8: Serialization ===")

	# Create typed object
	var player = IPlayerData.new(
		{
			"name": "Serialized Hero",
			"level": 10,
			"experience": 5000,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2(50, 50)
		}
	)

	# Convert to dictionary for saving
	var save_dict = player.to_dict()
	print("Serialized: %s" % save_dict)

	# Load from dictionary
	var loaded_player = IPlayerData.new(save_dict)
	print("Loaded player: %s (Level %d)" % [loaded_player.name, loaded_player.level])


# ==============================================================================
# Utility Functions
# ==============================================================================


func _calculate_rarity(weight: float) -> String:
	if weight > 20.0:
		return "legendary"
	elif weight > 10.0:
		return "rare"
	elif weight > 5.0:
		return "uncommon"
	else:
		return "common"


# ==============================================================================
# Run All Examples
# ==============================================================================


func _ready() -> void:
	print("========================================")
	print("TypedDict Basic Usage Examples")
	print("========================================")

	example_creating_player()
	example_typed_properties()

	var player = get_player_data("001")
	save_player(player)

	example_items()
	example_fishing()
	example_quests()

	print("\n=== Example 7: Weather ===")
	var weather = update_weather()
	apply_weather(weather)

	example_serialization()

	print("\n========================================")
	print("All examples completed!")
	print("========================================")

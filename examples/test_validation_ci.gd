extends SceneTree

var IExamplePlayer = load("res://addons/type_interfaces/examples/IExamplePlayer.gd")
var IExampleItem = load("res://addons/type_interfaces/examples/IExampleItem.gd")
var IExampleQuest = load("res://addons/type_interfaces/examples/IExampleQuest.gd")

## CI-compatible test runner for Type Interfaces validation
## This script can run in headless mode without the editor
var TypeInterfaces = load("res://addons/type_interfaces/src/type_interfaces_runtime.gd").new()
var ValidationMode = TypeInterfaces.ValidationMode


func _init() -> void:
	print("\n" + "=".repeat(70))
	print("TYPE INTERFACES - CI VALIDATION TEST")
	print("=".repeat(70))

	test_valid_player()
	test_invalid_type()
	test_missing_required_field()
	test_nullable_fields()
	test_strict_vs_loose_mode()
	test_valid_item()
	test_valid_quest()
	test_nested_interfaces()

	print("\n" + "=".repeat(70))
	print("CI VALIDATION TEST COMPLETE")
	print("=".repeat(70))
	print("\n✓ All tests ran successfully!")
	print("  Check above for validation errors (expected in some tests)")

	quit(0)  # Exit with success code


# ==============================================================================
# TEST 1: Valid Player Data
# ==============================================================================


func test_valid_player() -> void:
	print("\n--- Test 1: Valid Player (Should Succeed) ---")

	var player = IExamplePlayer.new(
		{
			"name": "CIPlayer",
			"level": 5,
			"experience": 1000,
			"health": 85.0,
			"max_health": 100.0,
			"position": Vector2(100, 200)
		}
	)

	print("✓ Created player: %s (Level %d)" % [player.name, player.level])


# ==============================================================================
# TEST 2: Invalid Type (Should Show Error in Debug Builds)
# ==============================================================================


func test_invalid_type() -> void:
	print("\n--- Test 2: Invalid Type (Expect Validation Error) ---")

	var player = IExamplePlayer.new(
		{
			"name": "InvalidPlayer",
			"level": "not_a_number",  # Should be int, but is String
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0
		}
	)

	print("  Player created despite invalid level type")


# ==============================================================================
# TEST 3: Missing Required Field
# ==============================================================================


func test_missing_required_field() -> void:
	print("\n--- Test 3: Missing Required Field (Expect Warning) ---")

	var player = IExamplePlayer.new(
		{
			# Missing 'name' field
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0
		}
	)

	print("  Created player without 'name' field")


# ==============================================================================
# TEST 4: Nullable Fields
# ==============================================================================


func test_nullable_fields() -> void:
	print("\n--- Test 4: Nullable Fields (Should Succeed) ---")

	var player = IExamplePlayer.new(
		{
			"name": "NoPosition",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"position": null  # Nullable field - this is OK
		}
	)

	print("✓ Created player with null position")


# ==============================================================================
# TEST 5: STRICT vs LOOSE Validation Modes
# ==============================================================================


func test_strict_vs_loose_mode() -> void:
	print("\n--- Test 5: STRICT vs LOOSE Validation ---")

	# LOOSE mode (default) - extra fields allowed
	print("\nLOOSE mode (extra fields = allowed):")
	var loose_player = IExamplePlayer.new(
		{
			"name": "LoosePlayer",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2.ZERO,
			"custom_field": "Extra data is OK"
		},
		ValidationMode.LOOSE
	)

	print("✓ LOOSE mode: Created player with extra fields")

	# STRICT mode - extra fields would cause error
	print("\nSTRICT mode (extra fields = error):")
	var strict_player = IExamplePlayer.new(
		{
			"name": "StrictPlayer",
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"position": Vector2.ZERO
		},
		ValidationMode.STRICT
	)

	print("✓ STRICT mode: Created player without extra fields")


# ==============================================================================
# TEST 6: Valid Item
# ==============================================================================


func test_valid_item() -> void:
	print("\n--- Test 6: Valid Item (Should Succeed) ---")

	var sword = IExampleItem.new(
		{
			"id": "sword_001",
			"item_name": "CI Sword",
			"quantity": 1,
			"weight": 5.0,
			"description": "A sword created in CI",
			"tags": ["weapon", "melee", "test"],
			"icon_path": "res://icons/test_sword.png"
		}
	)

	print("✓ Created item: %s" % sword.item_name)
	print("  Weight: %.1f kg" % sword.weight)
	print("  Tags: %s" % str(sword.tags))


# ==============================================================================
# TEST 7: Valid Quest
# ==============================================================================


func test_valid_quest() -> void:
	print("\n--- Test 7: Valid Quest (Should Succeed) ---")

	var quest = IExampleQuest.new(
		{
			"quest_id": "ci_quest_001",
			"title": "CI Test Quest",
			"description": "Complete this quest in CI",
			"status": "active",
			"objectives": [{"description": "Test objective 1", "completed": false}],
			"required_level": 5,
			"rewards": {"gold": 500, "experience": 250}
		}
	)

	print("✓ Created quest: %s" % quest.title)
	print("  Status: %s" % quest.status)
	print("  Required Level: %d" % quest.required_level)


# ==============================================================================
# TEST 8: Nested Interfaces
# ==============================================================================


func test_nested_interfaces() -> void:
	print("\n--- Test 8: Nested Interfaces (Should Succeed) ---")

	var complex_quest = IExampleQuest.new(
		{
			"quest_id": "nested_quest",
			"title": "Complex Quest",
			"description": "Tests nested data structures",
			"status": "not_started",
			"objectives": [
				{
					"description": "Kill 10 monsters",
					"completed": false,
					"progress": {"current": 3, "required": 10}
				},
				{
					"description": "Collect 5 herbs",
					"completed": false,
					"progress": {"current": 2, "required": 5}
				}
			],
			"required_level": 1,
			"rewards": {"gold": 100, "experience": 50, "items": ["potion", "scroll"]}
		}
	)

	print("✓ Created complex quest with nested data")
	print("  Objectives: %d" % complex_quest.objectives.size())
	print("  Rewards: %s" % str(complex_quest.rewards))

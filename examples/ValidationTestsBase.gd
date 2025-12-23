class_name ValidationTestsBase

extends RefCounted

## Shared test logic for both editor and CI validation
## This base class contains all test implementations to avoid duplication

var IExamplePlayer
var IExampleItem
var IExampleQuest
var TypeInterfaces
var validation_mode


func _init() -> void:
	# Load base classes first - required for headless CI mode where class_name isn't auto-registered
	# Load in dependency order: TypedDict -> ExtendableInterface -> Example Interfaces
	load("res://addons/type_interfaces/classes/TypedDict.gd")
	load("res://addons/type_interfaces/classes/ExtendableInterface.gd")

	# Now load example interfaces (they extend ExtendableInterface)
	IExamplePlayer = load("res://addons/type_interfaces/examples/IExamplePlayer.gd")
	IExampleItem = load("res://addons/type_interfaces/examples/IExampleItem.gd")
	IExampleQuest = load("res://addons/type_interfaces/examples/IExampleQuest.gd")

	# Load TypeInterfaces manually - autoloads don't work in headless CI mode
	var TypeInterfacesScript = load("res://addons/type_interfaces/src/type_interfaces_runtime.gd")
	validation_mode = TypeInterfacesScript.new().ValidationMode


func run_all_tests() -> void:
	print("\n" + "=".repeat(70))
	print("TYPE INTERFACES - VALIDATION TEST")
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
	print("VALIDATION TEST COMPLETE")
	print("=".repeat(70))
	print("\n✓ All tests ran successfully!")
	print("  Check above for validation errors (expected in some tests)")


# ==============================================================================
# TEST 1: Valid Player Data
# ==============================================================================


func test_valid_player() -> void:
	print("\n--- Test 1: Valid Player (Should Succeed) ---")

	var player = IExamplePlayer.new(
		{
			"name": "TestPlayer",
			"level": 5,
			"experience": 1000,
			"health": 85.0,
			"max_health": 100.0,
			"position": Vector2(100, 200)
		}
	)

	print("✓ Created player: %s (Level %d)" % [player.name, player.level])
	print("  Health: %.1f/%.1f" % [player.health, player.max_health])
	print("  Position: %s" % player.position)


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
	print("  (In debug builds, you should see a validation error above)")


# ==============================================================================
# TEST 3: Missing Required Field
# ==============================================================================


func test_missing_required_field() -> void:
	print("\n--- Test 3: Missing Required Field (Expect Warning) ---")

	var player = (
		IExamplePlayer
		. new(
			{
				# Missing 'name' field
				"level": 1,
				"experience": 0,
				"health": 100.0,
				"max_health": 100.0
			}
		)
	)

	print("  Created player without 'name' field")
	print("  Name falls back to default: '%s'" % player.name)


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
	print("  Position: %s (falls back to Vector2.ZERO)" % player.position)


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
			"custom_field": "Extra data is OK",
			"another_field": 42
		},
		validation_mode.LOOSE
	)

	print("✓ LOOSE mode: Created player with extra fields")
	print("  Custom field: %s" % loose_player.get_value("custom_field", ""))

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
		validation_mode.STRICT
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
			"item_name": "Test Sword",
			"quantity": 1,
			"weight": 5.0,
			"description": "A test sword",
			"tags": ["weapon", "melee", "test"],
			"icon_path": "res://icons/test_sword.png"
		}
	)

	print("✓ Created item: %s (x%d)" % [sword.item_name, sword.quantity])
	print("  ID: %s" % sword.id)
	print("  Weight: %.1f kg" % sword.weight)
	print("  Tags: %s" % [sword.tags])


# ==============================================================================
# TEST 7: Valid Quest
# ==============================================================================


func test_valid_quest() -> void:
	print("\n--- Test 7: Valid Quest (Should Succeed) ---")

	var quest = IExampleQuest.new(
		{
			"quest_id": "test_quest_001",
			"title": "Test Quest",
			"description": "Complete this test quest",
			"status": "active",
			"objectives":
			[
				{"description": "Test objective 1", "completed": false},
				{"description": "Test objective 2", "completed": true}
			],
			"required_level": 5,
			"rewards": {"gold": 500, "experience": 250}
		}
	)

	print("✓ Created quest: %s" % quest.title)
	print("  Quest ID: %s" % quest.quest_id)
	print("  Status: %s" % quest.status)
	print("  Objectives: %d" % quest.objectives.size())
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
			"objectives":
			[
				{
					"description": "Kill 10 monsters",
					"completed": false,
					"progress": {"current": 3, "required": 10}
				},
				{
					"description": "Collect 5 herbs",
					"completed": false,
					"progress": {"current": 5, "required": 5}
				}
			],
			"required_level": 1,
			"rewards": {"gold": 100, "experience": 50}
		}
	)

	print("✓ Created complex quest with nested data")
	print("  Objectives with progress tracking:")
	for obj in complex_quest.objectives:
		var progress_str = ""
		if "progress" in obj:
			progress_str = " (%d/%d)" % [obj.progress.current, obj.progress.required]
		print("    - %s%s" % [obj.description, progress_str])

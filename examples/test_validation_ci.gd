# We need to extend SceneTree to run this in the CI environment hence the 2 files calling VTB
extends SceneTree

## CI-compatible wrapper for validation tests
## Uses shared test logic from ValidationTestsBase


func _init() -> void:
	var tests = (
		preload(
			"res://addons/godot-addon-dictionary-type-interfaces/examples/ValidationTestsBase.gd"
		)
		. new()
	)
	tests.run_all_tests()
	quit(0)

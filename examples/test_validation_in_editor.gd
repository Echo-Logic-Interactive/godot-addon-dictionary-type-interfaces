@tool
extends EditorScript

## EditorScript wrapper for validation tests
## Uses shared test logic from ValidationTestsBase
##
## HOW TO USE:
## 1. Open this file in the Godot editor
## 2. Go to: File > Run
## 3. Watch the Output panel for validation results
##
## This script demonstrates:
## - Creating interfaces in the editor
## - Type validation errors and warnings
## - STRICT vs LOOSE validation modes
## - Correct and incorrect data patterns


func _run() -> void:
	var tests = (
		preload(
			"res://addons/godot-addon-dictionary-type-interfaces/examples/ValidationTestsBase.gd"
		)
		. new()
	)
	tests.run_all_tests()

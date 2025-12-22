extends SceneTree

## CI-compatible wrapper for validation tests
## Uses shared test logic from ValidationTestsBase


func _init() -> void:
	var tests = preload("./ValidationTestsBase.gd").new()
	tests.run_all_tests()
	quit(0)
